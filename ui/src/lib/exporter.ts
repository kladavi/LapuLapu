// ── Export engine: generates copilot-pack.md or .json ──

import type { PMData, ExportOptions, ExportWarning, Project } from "./types";
import {
  buildNormalizedPayload,
  validateExportPayload,
  generateHumanSnapshot,
  type NormalizedExportPayload,
  type ValidationError,
} from "./exportNormalizer";
import { lintRepo, type LintResult, type LintViolation } from "./linter";

export type { ValidationError } from "./exportNormalizer";
export type { ExportWarning } from "./types";
export type { LintResult, LintViolation } from "./linter";

export interface ExportResult {
  content: string;
  errors: ValidationError[];
  warnings: ExportWarning[];
  lintResult: LintResult | null;
}

/**
 * Resolve the selected project from PMData.
 * Returns null if the project slug is not found.
 */
function resolveProject(data: PMData, slug: string): Project | null {
  return data.projects.find((p) => p.slug === slug) || null;
}

export interface FilteredProjectData {
  tasks: PMData["tasks"];
  decisions: PMData["decisions"];
  weeklySummaries: PMData["weeklySummaries"];
  teams: PMData["teams"];
  systems: PMData["systems"];
  warnings: ExportWarning[];
}

/**
 * Filter PMData to only include items matching the given project slug.
 * Tasks and decisions must have #project:<slug> in their tags.
 * Weekly summaries must have a matching project field.
 * Teams/systems are filtered to only those referenced by included tasks.
 */
export function filterByProject(data: PMData, slug: string): FilteredProjectData {
  const projectTag = `#project:${slug}`;
  const warnings: ExportWarning[] = [];

  const tasks = data.tasks.filter((t) =>
    t.tags.some((tag) => tag.toLowerCase() === projectTag)
  );

  const decisions = data.decisions.filter((d) =>
    d.tags.some((tag) => tag.toLowerCase() === projectTag)
  );

  // Weekly summaries: match by project field, filename slug, or legacy fallback
  const weeklySummaries = data.weeklySummaries.filter((ws) => {
    if (ws.project) return ws.project.toLowerCase() === slug.toLowerCase();
    // Check if filename contains the project slug (e.g. 2026-W13—epsilon.md)
    if (ws.filename.toLowerCase().includes(slug.toLowerCase())) return true;
    // Legacy files without project field: only include for lapu-lapu (backward compat)
    return slug === "lapu-lapu" && !ws.project;
  });

  // Filter teams to those referenced by included tasks
  const referencedTeams = new Set(
    tasks.map((t) => t.team.toLowerCase()).filter(Boolean)
  );
  const teams = referencedTeams.size > 0
    ? data.teams.filter((t) => referencedTeams.has(t.name.toLowerCase()))
    : data.teams; // If no team refs, include all (safer default)

  // Filter systems to those referenced by included tasks
  const referencedSystems = new Set(
    tasks.flatMap((t) => t.systems.map((s) => s.toLowerCase()))
  );
  const systems = referencedSystems.size > 0
    ? data.systems.filter(
        (s) =>
          referencedSystems.has(s.tag.toLowerCase()) ||
          referencedSystems.has(s.name.toLowerCase()) ||
          referencedSystems.has(`#system:${s.name.toLowerCase().replace(/\s+/g, "")}`)
      )
    : data.systems;

  // Validation: warn about untagged tasks/decisions
  for (const t of data.tasks) {
    const hasAnyProjectTag = t.tags.some((tag) => tag.toLowerCase().startsWith("#project:"));
    if (!hasAnyProjectTag) {
      warnings.push({
        type: "MISSING_PROJECT_TAG",
        taskId: t.id,
        objectiveId: "",
        message: `Task "${t.id}" has no #project: tag — it will be excluded from all project exports.`,
      });
    }
  }
  for (const d of data.decisions) {
    const hasAnyProjectTag = d.tags.some((tag) => tag.toLowerCase().startsWith("#project:"));
    if (!hasAnyProjectTag) {
      warnings.push({
        type: "MISSING_PROJECT_TAG",
        taskId: d.id,
        objectiveId: "",
        message: `Decision "${d.id}" has no #project: tag — it will be excluded from all project exports.`,
      });
    }
  }

  return { tasks, decisions, weeklySummaries, teams, systems, warnings };
}

export function generateExport(data: PMData, options: ExportOptions): ExportResult {
  // ── Lint gate ──
  const lr = lintRepo(data, data.settings);
  if (lr.blocked) {
    // lint.mode === "fail" and there are error-level violations → block export
    const top10 = lr.violations.slice(0, 10);
    const remaining = lr.violations.length - top10.length;
    const summary = top10
      .map((v) => `[${v.rule}] ${v.entity}: ${v.message}`)
      .join("\n");
    const suffix = remaining > 0 ? `\n… and ${remaining} more issues.` : "";
    return {
      content: "",
      errors: [{
        field: "lint",
        entity: "repo",
        message: `Lint blocked export (${lr.errorCount} errors, ${lr.warningCount} warnings):\n${summary}${suffix}`,
      }],
      warnings: [],
      lintResult: lr,
    };
  }

  // Resolve project
  const project = resolveProject(data, options.projectSlug);
  if (!project) {
    return {
      content: "",
      errors: [{
        field: "projectSlug",
        entity: options.projectSlug,
        message: `Project "${options.projectSlug}" not found in projects registry. Available: ${data.projects.map(p => p.slug).join(", ")}`,
      }],
      warnings: [],
      lintResult: lr,
    };
  }

  // Filter data by project
  const filtered = filterByProject(data, options.projectSlug);

  const payload = buildNormalizedPayload(
    data.objectives,
    filtered.tasks,
    filtered.teams,
    filtered.systems,
    filtered.weeklySummaries,
    filtered.decisions,
    data.inbox,
    options
  );

  // Run pre-export validation (project-scoped)
  const validationWarnings = runPreExportValidation(data, options.projectSlug);

  const errors = validateExportPayload(payload);
  if (errors.length > 0) {
    return { content: "", errors, warnings: [], lintResult: lr };
  }

  const warnings = [
    ...(payload.exportWarnings || []),
    ...validationWarnings,
    ...filtered.warnings,
  ];

  if (options.format === "json") {
    return { content: generateJsonExport(data, payload, project), errors: [], warnings, lintResult: lr };
  }
  return { content: generateMdExport(data, payload, options, project), errors: [], warnings, lintResult: lr };
}

function generateMdExport(data: PMData, payload: NormalizedExportPayload, options: ExportOptions, project: Project): string {
  const now = new Date().toISOString();
  const sections: string[] = [];

  // Determine included section names
  const includedSections: string[] = [];
  if (options.includeObjectives) includedSections.push("objectives");
  if (options.includeTeamsSystems) {
    includedSections.push("teams");
    includedSections.push("systems");
  }
  if (options.includeTasks) includedSections.push("tasks");
  if (options.includeDecisions) includedSections.push("decisions");
  if (options.includeWeeklySummaries) includedSections.push("weekly_summaries");
  if (options.includeInbox) includedSections.push("inbox");

  // 1) YAML frontmatter — project-scoped
  const frontmatter = [
    "---",
    `title: "Objective-Driven PM Copilot Pack — ${project.name}"`,
    `project: "${project.slug}"`,
    `projectName: "${project.name}"`,
    `created: "${now}"`,
    `source_repo: "${data.folderName}"`,
    "distribution:",
    ...project.primaryAudience.map((a) => `  - "${a}"`),
    "included_sections:",
    ...includedSections.map((s) => `  - ${s}`),
    "exclusions:",
    '  - "01-inbox/archive/**"',
    '  - "90-assets/**"',
    '  - "99-archive/**"',
    '  - "**/*.pdf"',
    '  - "**/*.pptx"',
    '  - "**/*.xlsx"',
    '  - "**/*.png"',
    '  - "**/*.jpg"',
    "---",
  ].join("\n");

  sections.push(frontmatter);

  // 1.5) Context contract from pack-config.md (if available)
  const contractSection = extractPackConfigContract(data.rawFiles, project);
  if (contractSection) {
    sections.push(contractSection);
  }

  // 1.6) How To Use block (recipient onboarding)
  if (data.settings?.export?.includeHowToUse !== false) {
    sections.push(generateHowToUse());
  }

  // 1.7) Role-based starter prompts
  if (data.settings?.export?.includeRolePrompts !== false) {
    sections.push(generateRolePrompts());
  }

  // 2) Copilot instructions
  const instructions = `
## COPILOT INSTRUCTIONS (READ FIRST)

You are given an exported snapshot of an objective-driven PM system.

1) Produce an executive-ready 1-page Weekly Project Status Report with these sections:
   a) **Executive Summary** — 1–2 sentences per Tier-1 objective with progress (use objective names as bold headings, e.g. **Frictionless Customer Experience:**)
   b) **Key Accomplishments (This Week)** — Top 3–5 outcomes as standalone lines (no bullets)
   c) **Top Risks & Issues** — Format: [Risk] · description | mitigation | owner |
   d) **Planned for Next Week** — Top 2–4 priorities as standalone lines, optionally prefixed with (O#):
   e) **Project Resources** — Standard links footer with emoji prefixes
   f) **Prepared by** line
2) Then ask me 5 clarifying questions to deepen the report.
3) Offer an index of the objectives and top workstreams by relevance.

After that, respond to any user questions by referencing the data in this file.
If information is missing, explicitly say so.

## SUGGESTED QUESTIONS

- "Show me all work mapped to Hari objectives."
- "Which systems of record show up most in tasks?"
- "What work is unaligned to objectives?"
- "Summarize progress by objective tier."
- "What are the top risks emerging this week?"
`.trim();

  sections.push(instructions);

  // 3) DATA section (normalized JSON)
  const dataSection = `
## DATA (MACHINE-READABLE)

\`\`\`json
${JSON.stringify(payload, null, 2)}
\`\`\`
`.trim();

  sections.push(dataSection);

  // 4) Human-readable snapshot
  const snapshot = generateHumanSnapshot(payload);
  sections.push(snapshot);

  // 5) Export diagnostics block (Improvement #5)
  const diagnostics = generateDiagnosticsBlock(payload, now);
  sections.push(diagnostics);

  return sections.join("\n\n");
}

function generateJsonExport(data: PMData, payload: NormalizedExportPayload, project: Project): string {
  return JSON.stringify(
    {
      title: `Objective-Driven PM Copilot Pack — ${project.name}`,
      project: project.slug,
      projectName: project.name,
      created: new Date().toISOString(),
      source_repo: data.folderName,
      ...payload,
    },
    null,
    2
  );
}

// ────────────────────────────────────────────
// Export diagnostics (Improvement #5)
// ────────────────────────────────────────────

function generateDiagnosticsBlock(payload: NormalizedExportPayload, timestamp: string): string {
  const objectives = payload.objectives || [];
  const tasks = payload.tasks || [];
  const warnings = payload.exportWarnings || [];

  const tier1Count = objectives.filter((o) => o.tier === 1).length;
  const tier2Count = objectives.filter((o) => o.tier === 2).length;
  const tier3Count = objectives.filter((o) => o.tier === 3).length;

  const tasksWithExternal = new Set(
    warnings
      .filter((w) => w.type === "TASK_OBJECTIVE_OUT_OF_SCOPE")
      .map((w) => w.taskId)
  ).size;

  const lines: string[] = [];
  lines.push("## EXPORT DIAGNOSTICS\n");
  lines.push("<!-- This section is for debugging. Parsers should ignore it. -->\n");
  lines.push(`- **Export timestamp:** ${timestamp}`);
  lines.push(`- **Objectives:** ${objectives.length} total (Tier-1: ${tier1Count}, Tier-2: ${tier2Count}${tier3Count > 0 ? `, Tier-3: ${tier3Count}` : ""})`);
  lines.push(`- **Tasks:** ${tasks.length}`);
  lines.push(`- **Tasks with external objectives:** ${tasksWithExternal}`);
  lines.push(`- **Warnings:** ${warnings.length}`);

  if (warnings.length > 0) {
    lines.push("");
    lines.push("**Warning details:**");
    for (const w of warnings) {
      lines.push(`- \`${w.type}\` ${w.taskId} → ${w.objectiveId}: ${w.message}`);
    }
  }

  return lines.join("\n");
}

// ────────────────────────────────────────────
// Size estimation
// ────────────────────────────────────────────

export function estimateExportSize(data: PMData, options: ExportOptions): number {
  const projectTag = `#project:${options.projectSlug}`;
  const filteredTasks = data.tasks.filter((t) =>
    t.tags.some((tag) => tag.toLowerCase() === projectTag)
  );
  const filteredDecisions = data.decisions.filter((d) =>
    d.tags.some((tag) => tag.toLowerCase() === projectTag)
  );
  const filteredWeeklies = data.weeklySummaries.filter((ws) => {
    if (ws.project) return ws.project.toLowerCase() === options.projectSlug.toLowerCase();
    return options.projectSlug === "lapu-lapu" && !ws.project;
  });

  const payload = buildNormalizedPayload(
    data.objectives,
    filteredTasks,
    data.teams,
    data.systems,
    filteredWeeklies,
    filteredDecisions,
    data.inbox,
    options
  );
  const jsonStr = JSON.stringify(payload);
  // Add ~1500 bytes for frontmatter + instructions + snapshot
  return jsonStr.length + 2000;
}

// ────────────────────────────────────────────
// Download helper
// ────────────────────────────────────────────

export function downloadFile(content: string, filename: string): void {
  const blob = new Blob([content], { type: "text/plain;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

// ────────────────────────────────────────────
// Recipient usability sections
// ────────────────────────────────────────────

function generateHowToUse(): string {
  return `
## HOW TO USE THIS PACK (FOR RECIPIENTS)

1. Open M365 Copilot Chat
2. Upload this file
3. Ask questions about status, risks, owners, and next steps

Copilot will respond only using data in this pack.
`.trim();
}

function generateRolePrompts(): string {
  return `
## STARTER PROMPTS BY ROLE

### For Birger (ETS Japan)
- "Summarize top risks and decisions this week for ETS Japan."
- "What blockers require leadership escalation?"

### For Hari / Jonan (GOCC)
- "What tasks require GOCC onboarding or access changes?"
- "List handover readiness gaps (runbooks, routing, accounts)."

### For Deb (Observability)
- "Which tasks relate to observability maturity and monitoring instrumentation?"
- "Which systems have incomplete coverage?"

### For Kelvin (ETS Region)
- "What cross-region dependencies or escalations exist this week?"
- "Summarize progress by Tier-1 objective."

### For Balaji (Architecture)
- "Summarize Epsilon/POT architecture work and required stakeholders."
- "List tasks requiring infra provisioning or HA validation."
`.trim();
}

// ────────────────────────────────────────────
// Pack-config contract extraction
// ────────────────────────────────────────────

/**
 * Extract the context contract from pack-config.md and render it
 * as a CONTEXT CONTRACT section for the export.
 */
function extractPackConfigContract(rawFiles: Record<string, string>, project: Project): string | null {
  // Try project-specific pack-config first, then fall back to generic
  const findKey = (suffix: string) =>
    Object.keys(rawFiles).find((k) =>
      k.replace(/\\/g, "/").endsWith(suffix)
    );

  const projectKey = findKey(`00-context/pack-config_${project.slug}.md`);
  const genericKey = findKey("00-context/pack-config.md");
  const key = projectKey || genericKey;
  if (!key) return null;

  const md = rawFiles[key].replace(/\r\n/g, "\n");

  // Extract sections by heading (partial match — heading must start with the given text)
  const extractSection = (heading: string): string => {
    const escaped = heading.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const re = new RegExp(
      `^##\\s+${escaped}[^\\n]*\\n([\\s\\S]*?)(?=^## |$)`,
      "m"
    );
    const m = md.match(re);
    return m ? m[1].trim() : "";
  };

  const audience = extractSection("Intended Audience");
  const contract = extractSection("Context Contract");
  const behavior = extractSection("How Copilot Should Behave");
  const prompts = extractSection("Starter Prompts");

  if (!audience && !contract && !behavior) return null;

  const lines: string[] = [];
  lines.push("## CONTEXT CONTRACT (READ FIRST)\n");
  lines.push(`> **This pack is scoped to #project:${project.slug} (${project.name}).** Other projects are excluded.\n`);

  if (audience) {
    lines.push("### Intended Audience\n");
    lines.push(audience);
    lines.push("");
  }
  if (contract) {
    lines.push("### Context Contract\n");
    lines.push(contract);
    lines.push("");
  }
  if (behavior) {
    lines.push("### How Copilot Should Behave\n");
    lines.push(behavior);
    lines.push("");
  }
  if (prompts) {
    lines.push("### Starter Prompts\n");
    lines.push(prompts);
    lines.push("");
  }

  return lines.join("\n");
}

// ────────────────────────────────────────────
// Pre-export validation (Task 9)
// ────────────────────────────────────────────

/**
 * Run pre-export validation on source data. Returns export warnings
 * (soft failures) rather than blocking errors.
 */
function runPreExportValidation(data: PMData, projectSlug: string): ExportWarning[] {
  const warnings: ExportWarning[] = [];
  const objectiveIds = new Set(data.objectives.map((o) => o.id));
  const projectTag = `#project:${projectSlug}`;

  // Filter to only tasks in this project for objective checks
  const projectTasks = data.tasks.filter((t) =>
    t.tags.some((tag) => tag.toLowerCase() === projectTag)
  );

  // 1. Check tasks reference valid objective IDs
  for (const task of projectTasks) {
    for (const oid of task.objectiveIds) {
      if (!objectiveIds.has(oid) && !task.tags.some((t) => t.includes("objective:external"))) {
        warnings.push({
          type: "VALIDATION_MISSING_OBJECTIVE",
          taskId: task.id,
          objectiveId: oid,
          message: `Task references objective "${oid}" which does not exist in objectives.md and is not tagged #objective:external.`,
        });
      }
    }
  }

  // 2. Check systems tags start with #system: (in export normalizer this is already handled,
  //    but warn on source data)
  for (const task of projectTasks) {
    for (const sys of task.systems) {
      const normalized = sys.startsWith("#") ? sys : `#${sys}`;
      if (!normalized.startsWith("#system:") && !normalized.match(/^#(moogsoft|newrelic|azure|cmdb|xmatters|leanix|adobe|apm|adx|ingenium)$/i)) {
        warnings.push({
          type: "VALIDATION_SYSTEM_TAG",
          taskId: task.id,
          objectiveId: "",
          message: `System tag "${sys}" is not namespaced. Expected format: #system:<name>.`,
        });
      }
    }
  }

  // 3. Check decisions have Date and Decision fields
  for (const dec of data.decisions) {
    if (!dec.date) {
      warnings.push({
        type: "VALIDATION_DECISION_FIELD",
        taskId: dec.id,
        objectiveId: "",
        message: `Decision "${dec.id}" is missing a Date field.`,
      });
    }
    if (!dec.decision) {
      warnings.push({
        type: "VALIDATION_DECISION_FIELD",
        taskId: dec.id,
        objectiveId: "",
        message: `Decision "${dec.id}" is missing a Decision field.`,
      });
    }
  }

  // 4. Check notes/description fields don't exceed maxNotesLength (warn, don't block)
  const maxNotes = data.settings?.export?.maxNotesLength ?? 500;
  if (maxNotes > 0) {
    for (const task of projectTasks) {
      if (task.description.length > maxNotes) {
        warnings.push({
          type: "VALIDATION_NOTES_LENGTH",
          taskId: task.id,
          objectiveId: "",
          message: `Task description exceeds ${maxNotes} chars (${task.description.length}). Will be trimmed in export.`,
        });
      }
    }
  }

  return warnings;
}
