// ── Export engine: generates copilot-pack.md or .json ──

import type { PMData, ExportOptions } from "./types";

export function generateExport(data: PMData, options: ExportOptions): string {
  if (options.format === "json") {
    return generateJsonExport(data, options);
  }
  return generateMdExport(data, options);
}

function generateMdExport(data: PMData, options: ExportOptions): string {
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

  // 3) DATA section
  const jsonData = buildJsonPayload(data, options);
  const dataSection = `
## DATA (MACHINE-READABLE)

\`\`\`json
${JSON.stringify(jsonData, null, 2)}
\`\`\`
`.trim();

  sections.push(dataSection);

  return sections.join("\n\n");
}

function generateJsonExport(data: PMData, options: ExportOptions): string {
  const jsonData = buildJsonPayload(data, options);
  return JSON.stringify(
    {
      title: "Objective-Driven PM Copilot Pack",
      created: new Date().toISOString(),
      source_repo: data.folderName,
      ...jsonData,
    },
    null,
    2
  );
}

interface ExportPayload {
  objectives?: { id: string; title: string; tier: number; tags: string[]; parentObjectiveIds: string[]; description: string; commitments: string[] }[];
  teams?: { name: string; lead: string; tags: string[]; members?: string[]; primarySystems?: string[] }[];
  systems?: { name: string; tag: string; purpose: string }[];
  tasks?: { id: string; title: string; status: string; objectiveChain: string; objectiveIds: string[]; team: string; assigned: string; systems: string[]; relevance?: number; tags: string[]; description: string }[];
  decisions?: { id: string; title: string; date: string; decision: string; reason: string; tags: string[] }[];
  weekly_summaries?: { filename: string; content: string }[];
  inbox?: string;
}

function buildJsonPayload(data: PMData, options: ExportOptions): ExportPayload {
  const payload: ExportPayload = {};

  if (options.includeObjectives) {
    payload.objectives = data.objectives.map((o) => ({
      id: o.id,
      title: o.title,
      tier: o.tier,
      tags: o.tags,
      parentObjectiveIds: o.parentObjectiveIds,
      description: o.description,
      commitments: o.commitments,
    }));
  }

  if (options.includeTeamsSystems) {
    payload.teams = data.teams.map((t) => ({
      name: t.name,
      lead: t.lead,
      tags: t.tags,
      members: t.members,
      primarySystems: t.primarySystems,
    }));
    payload.systems = data.systems;
  }

  if (options.includeTasks) {
    payload.tasks = data.tasks.map((t) => ({
      id: t.id,
      title: t.title,
      status: t.status,
      objectiveChain: t.objectiveChain,
      objectiveIds: t.objectiveIds,
      team: t.team,
      assigned: t.assigned,
      systems: t.systems,
      relevance: t.relevance,
      tags: t.tags,
      description: t.description,
    }));
  }

  if (options.includeDecisions) {
    payload.decisions = data.decisions.map((d) => ({
      id: d.id,
      title: d.title,
      date: d.date,
      decision: d.decision,
      reason: d.reason,
      tags: d.tags,
    }));
  }

  if (options.includeWeeklySummaries) {
    const count = options.weeklySummaryCount || 1;
    payload.weekly_summaries = data.weeklySummaries
      .slice(0, count)
      .map((w) => ({
        filename: w.filename,
        content: w.content,
      }));
  }

  if (options.includeInbox) {
    payload.inbox = data.inbox;
  }

  return payload;
}

// ────────────────────────────────────────────
// Size estimation
// ────────────────────────────────────────────

export function estimateExportSize(data: PMData, options: ExportOptions): number {
  // Quick estimate by building the payload and measuring
  const payload = buildJsonPayload(data, options);
  const jsonStr = JSON.stringify(payload);
  // Add ~500 bytes for frontmatter + instructions
  return jsonStr.length + 1500;
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
