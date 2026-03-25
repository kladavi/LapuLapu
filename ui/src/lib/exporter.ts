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

  const errors = validateExportPayload(payload);
  if (errors.length > 0) {
    return { content: "", errors, warnings: [] };
  }

  const warnings = payload.exportWarnings || [];

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
