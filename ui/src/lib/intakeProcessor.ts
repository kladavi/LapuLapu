// ── Intake processor: builds LLM prompts and parses LLM responses ──

import type { PMData } from "./types";
import type { RelationshipAdvisory } from "./types";
import type { LintResult } from "./linter";
import { parseTasks, parseDecisions } from "./parsers";
import { buildRelationshipMap } from "./relationships";
import { lintRepo } from "./linter";

/**
 * A parsed result item from LLM output — either a task or a decision.
 */
export interface IntakeResult {
  id: string;            // e.g. "T025" or "D004"
  type: "task" | "decision";
  title: string;
  raw: string;           // full markdown block
  approved: boolean;     // user toggle — default true
}

export interface IntakePreflightResult {
  lintResult: LintResult;
  relationshipViolations: RelationshipAdvisory[];
  approvedTaskCount: number;
  approvedDecisionCount: number;
}

export function validateApprovedIntakeResults(
  results: IntakeResult[],
  data: PMData
): IntakePreflightResult {
  const approvedTasks = results
    .filter((r) => r.approved && r.type === "task")
    .map((r) => r.raw)
    .join("\n\n---\n\n");

  const approvedDecisions = results
    .filter((r) => r.approved && r.type === "decision")
    .map((r) => r.raw)
    .join("\n\n---\n\n");

  const parsedTasks = approvedTasks.trim()
    ? parseTasks(approvedTasks)
    : [];

  const parsedDecisions = approvedDecisions.trim()
    ? parseDecisions(approvedDecisions)
    : [];

  const stagedTasks = [...data.tasks, ...parsedTasks];
  const stagedDecisions = [...data.decisions, ...parsedDecisions];
  const stagedRelationships = buildRelationshipMap(data.objectives, stagedTasks);

  const stagedData: PMData = {
    ...data,
    tasks: stagedTasks,
    decisions: stagedDecisions,
    relationships: stagedRelationships,
  };

  return {
    lintResult: lintRepo(stagedData, data.settings),
    relationshipViolations: stagedRelationships.violations,
    approvedTaskCount: parsedTasks.length,
    approvedDecisionCount: parsedDecisions.length,
  };
}

// ────────────────────────────────────────────
// Prompt builder
// ────────────────────────────────────────────

/**
 * Build a full LLM prompt for intake processing.
 * Incorporates all context the LLM needs: objectives, teams, systems,
 * existing tasks/decisions (for ID numbering), and the raw input.
 */
export function buildIntakePrompt(
  rawInput: string,
  data: PMData
): string {
  const sections: string[] = [];

  sections.push("# Intake — Inbox to Tasks\n");
  sections.push("## Role\n");
  sections.push(
    "You are a work-intake analyst for a technology operations leader. " +
    "Your job is to extract actionable work from raw inputs, align each item " +
    "to the organisation's objectives, and produce structured task records.\n"
  );

  // ── Context: Objectives ──
  const objectivesMd = findRaw(data, "00-context/objectives.md");
  if (objectivesMd) {
    sections.push("## Objectives (Tier 1 → Tier 3)\n");
    sections.push(trimContext(objectivesMd, 6000));
    sections.push("");
  }

  // ── Context: Teams ──
  const teamsMd = findRaw(data, "00-context/teams.md");
  if (teamsMd) {
    sections.push("## Teams\n");
    sections.push(trimContext(teamsMd, 3000));
    sections.push("");
  }

  // ── Context: Systems ──
  const systemsMd = findRaw(data, "00-context/systems.md");
  if (systemsMd) {
    sections.push("## Systems of Record\n");
    sections.push(trimContext(systemsMd, 2000));
    sections.push("");
  }

  // ── Context: Existing task & decision IDs ──
  const nextTaskId = nextId(data.tasks.map((t) => t.id), "T");
  const nextDecisionId = nextId(data.decisions.map((d) => d.id), "D");

  sections.push("## Existing ID Ranges\n");
  sections.push(`- Tasks: ${data.tasks.length} existing. Next available: **${nextTaskId}**`);
  sections.push(`- Decisions: ${data.decisions.length} existing. Next available: **${nextDecisionId}**`);
  sections.push("");

  // ── Instructions ──
  sections.push("## Instructions\n");
  sections.push("For each discrete work item in the raw input below:\n");
  sections.push("1. **Extract** discrete work items. A single input may yield 0, 1, or multiple tasks.");
  sections.push("2. **Match** each work item to the most relevant Tier-3 objective. Trace the chain: Tier 3 → Tier 2 → Tier 1.");
  sections.push("3. **Assign** a team based on which team owns the relevant systems and has matching work types.");
  sections.push("4. **Score** relevance from 0–100:");
  sections.push("   - 90–100: Directly advances a Tier-3 objective with measurable impact.");
  sections.push("   - 70–89: Supports an objective indirectly or addresses a gap.");
  sections.push("   - 50–69: Loosely related; may need reframing.");
  sections.push("   - 0–49: Unaligned. Flag for decision log.");
  sections.push("5. **Flag** any item scoring below 50. Do not create a task — instead, draft a decision-log entry.\n");

  // ── Output format ──
  sections.push("## Output Format\n");
  sections.push("For each aligned work item, produce **exactly** this markdown block:\n");
  sections.push("```markdown");
  sections.push("## T[NNN] — [Short Title]");
  sections.push("- **Status:** Open");
  sections.push("- **Created:** [YYYY-MM-DD]");
  sections.push("- **Objective Chain:** [O# (Tier 3 name)] → [O# (Tier 2 name)] → [O# (Tier 1 name)]");
  sections.push("- **Team:** #team-[tag]");
  sections.push("- **Assigned:** [Team Lead from teams.md]");
  sections.push("- **Systems:** #[system1] #[system2]");
  sections.push("- **Relevance:** [Score]/100");
  sections.push("- **Tags:** [relevant tags]");
  sections.push("- **Description:** [2–3 sentences. Concrete, actionable, measurable.]");
  sections.push("```\n");
  sections.push("For unaligned items, produce:\n");
  sections.push("```markdown");
  sections.push("## D[NNN] — Deferred: [Short Title]");
  sections.push("- **Date:** [YYYY-MM-DD]");
  sections.push("- **Requestor:** [Source]");
  sections.push("- **Request:** [What was asked]");
  sections.push("- **Decision:** Deferred");
  sections.push("- **Reason:** [Why it does not map to any Tier-3 objective]");
  sections.push("- **Tags:** #rejected #unaligned");
  sections.push("```\n");

  // ── Rules ──
  sections.push("## Rules\n");
  sections.push(`- Start task numbering at **${nextTaskId}**. Start decision numbering at **${nextDecisionId}**.`);
  sections.push("- Never invent objectives. Only use IDs from the objectives list above.");
  sections.push("- Never assign a team to a system they do not own.");
  sections.push("- If an item is ambiguous, still process it but note the ambiguity in the description.");
  sections.push("- Output ONLY the markdown blocks. No preamble, no commentary.\n");

  // ── Raw input ──
  sections.push("## Raw Input to Process\n");
  sections.push("```");
  sections.push(rawInput.trim());
  sections.push("```");

  return sections.join("\n");
}

// ────────────────────────────────────────────
// Response parser
// ────────────────────────────────────────────

/**
 * Parse LLM output to extract task and decision blocks.
 * Returns an array of IntakeResult items, each with its full markdown block.
 */
export function parseIntakeResponse(response: string): IntakeResult[] {
  const results: IntakeResult[] = [];

  // Normalise line endings
  const text = response.replace(/\r\n/g, "\n").replace(/\r/g, "\n");

  // Split on ## headings that start with T or D followed by digits
  const blockRegex = /^## (T\d{3,}|D\d{3,})\s*[—–-]\s*(.+?)$/gm;
  const matches: { index: number; id: string; title: string }[] = [];

  let m: RegExpExecArray | null;
  while ((m = blockRegex.exec(text)) !== null) {
    matches.push({
      index: m.index,
      id: m[1],
      title: m[2].trim(),
    });
  }

  for (let i = 0; i < matches.length; i++) {
    const start = matches[i].index;
    const end = i + 1 < matches.length ? matches[i + 1].index : text.length;
    const rawBlock = text.substring(start, end).trim();
    const type = matches[i].id.startsWith("T") ? "task" : "decision";

    results.push({
      id: matches[i].id,
      type,
      title: matches[i].title,
      raw: rawBlock,
      approved: true,
    });
  }

  return results;
}

// ────────────────────────────────────────────
// Inbox helpers
// ────────────────────────────────────────────

export interface InboxEntry {
  label: string;     // display text (date + title)
  text: string;      // full entry text
  status: "raw" | "processed";
}

/**
 * Parse inbox.md to extract individual entries with their #raw/#processed status.
 */
export function parseInboxEntries(inboxMd: string): InboxEntry[] {
  if (!inboxMd.trim()) return [];

  const entries: InboxEntry[] = [];
  // Each entry starts with `- **YYYY-MM-DD — Title**`
  const entryRegex = /^- \*\*(.+?)\*\*\s*(#raw|#processed)/gm;
  const lines = inboxMd.split("\n");

  let currentEntryStart = -1;
  let currentLabel = "";
  let currentStatus: "raw" | "processed" = "raw";

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const entryMatch = line.match(/^- \*\*(.+?)\*\*\s*(#raw|#processed)/);

    if (entryMatch) {
      // Save previous entry
      if (currentEntryStart >= 0) {
        const entryText = lines.slice(currentEntryStart, i).join("\n").trim();
        entries.push({ label: currentLabel, text: entryText, status: currentStatus });
      }
      currentEntryStart = i;
      currentLabel = entryMatch[1];
      currentStatus = entryMatch[2] === "#raw" ? "raw" : "processed";
    }
  }

  // Save last entry
  if (currentEntryStart >= 0) {
    // Find the end — stop at `---` separator or end of file
    let endIdx = lines.length;
    for (let j = currentEntryStart + 1; j < lines.length; j++) {
      if (lines[j].trim() === "---") {
        endIdx = j;
        break;
      }
    }
    const entryText = lines.slice(currentEntryStart, endIdx).join("\n").trim();
    entries.push({ label: currentLabel, text: entryText, status: currentStatus });
  }

  return entries;
}

// ────────────────────────────────────────────
// Utilities
// ────────────────────────────────────────────

function findRaw(data: PMData, suffix: string): string | undefined {
  const key = Object.keys(data.rawFiles).find(
    (k) => k.replace(/\\/g, "/").endsWith(suffix)
  );
  return key ? data.rawFiles[key] : undefined;
}

function trimContext(text: string, maxChars: number): string {
  if (text.length <= maxChars) return text;
  return text.slice(0, maxChars) + "\n\n[... truncated for token limits ...]";
}

function nextId(existingIds: string[], prefix: string): string {
  let maxNum = 0;
  for (const id of existingIds) {
    const numPart = id.replace(prefix, "");
    const num = parseInt(numPart, 10);
    if (!isNaN(num) && num > maxNum) maxNum = num;
  }
  const next = maxNum + 1;
  return `${prefix}${String(next).padStart(3, "0")}`;
}
