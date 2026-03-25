// ── Export engine: generates copilot-pack.md or .json ──

import type { PMData, ExportOptions, ExportWarning } from "./types";
import {
  buildNormalizedPayload,
  validateExportPayload,
  generateHumanSnapshot,
  type NormalizedExportPayload,
  type ValidationError,
} from "./exportNormalizer";

export type { ValidationError } from "./exportNormalizer";
export type { ExportWarning } from "./types";

export interface ExportResult {
  content: string;
  errors: ValidationError[];
  warnings: ExportWarning[];
}

export function generateExport(data: PMData, options: ExportOptions): ExportResult {
  const payload = buildNormalizedPayload(
    data.objectives,
    data.tasks,
    data.teams,
    data.systems,
    data.weeklySummaries,
    data.decisions,
    data.inbox,
    options
  );

  // Run pre-export validation
  const validationWarnings = runPreExportValidation(data);

  const errors = validateExportPayload(payload);
  if (errors.length > 0) {
    return { content: "", errors, warnings: [] };
  }

  const warnings = [...(payload.exportWarnings || []), ...validationWarnings];

  if (options.format === "json") {
    return { content: generateJsonExport(data, payload), errors: [], warnings };
  }
  return { content: generateMdExport(data, payload, options), errors: [], warnings };
}

function generateMdExport(data: PMData, payload: NormalizedExportPayload, options: ExportOptions): string {
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

  // 1) YAML frontmatter
  const frontmatter = [
    "---",
    'title: "Objective-Driven PM Copilot Pack"',
    `created: "${now}"`,
    `source_repo: "${data.folderName}"`,
    "distribution:",
    '  - "Birger"',
    '  - "Hari"',
    '  - "Kelvin"',
    '  - "Jonan"',
    '  - "Deb"',
    '  - "Balaji"',
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
  const contractSection = extractPackConfigContract(data.rawFiles);
  if (contractSection) {
    sections.push(contractSection);
  }

  // 2) Copilot instructions
  const instructions = `
## COPILOT INSTRUCTIONS (READ FIRST)

You are given an exported snapshot of an objective-driven PM system.

1) Produce an executive-ready 1-page weekly report:
   - Objectives advanced (by Tier-1 and Tier-2)
   - Key outcomes delivered
   - Risks / blockers
   - Work deferred or rejected (and why)
   - Next-week focus
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

function generateJsonExport(data: PMData, payload: NormalizedExportPayload): string {
  return JSON.stringify(
    {
      title: "Objective-Driven PM Copilot Pack",
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
  // Quick estimate by building the normalized payload and measuring
  const payload = buildNormalizedPayload(
    data.objectives,
    data.tasks,
    data.teams,
    data.systems,
    data.weeklySummaries,
    data.decisions,
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
// Pack-config contract extraction
// ────────────────────────────────────────────

/**
 * Extract the context contract from pack-config.md and render it
 * as a CONTEXT CONTRACT section for the export.
 */
function extractPackConfigContract(rawFiles: Record<string, string>): string | null {
  // Find the pack-config file
  const key = Object.keys(rawFiles).find((k) =>
    k.replace(/\\/g, "/").endsWith("00-context/pack-config.md")
  );
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
function runPreExportValidation(data: PMData): ExportWarning[] {
  const warnings: ExportWarning[] = [];
  const objectiveIds = new Set(data.objectives.map((o) => o.id));

  // 1. Check tasks reference valid objective IDs
  for (const task of data.tasks) {
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
  for (const task of data.tasks) {
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

  // 4. Check notes/description fields don't exceed 500 chars (warn, don't block)
  for (const task of data.tasks) {
    if (task.description.length > 500) {
      warnings.push({
        type: "VALIDATION_NOTES_LENGTH",
        taskId: task.id,
        objectiveId: "",
        message: `Task description exceeds 500 chars (${task.description.length}). Will be trimmed in export.`,
      });
    }
  }

  return warnings;
}
