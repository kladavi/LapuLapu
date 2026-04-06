// ── Tag suggestion engine ──
// Scans raw text against keyword maps from settings to suggest tags.

import type { AppSettings } from "./settings";

export interface TagSuggestion {
  tag: string;                        // e.g. "#system:newrelic"
  confidence: "high" | "medium";
  source: string;                     // the keyword that triggered the match
  category: "system" | "project" | "team";
}

/**
 * Scan `text` for keywords defined in `settings.tags.keywordMap` and return
 * de-duplicated tag suggestions sorted by confidence → category → tag.
 */
export function suggestTags(
  text: string,
  settings: AppSettings
): TagSuggestion[] {
  const keywordMap = settings.tags?.keywordMap;
  if (!keywordMap) return [];

  const lower = text.toLowerCase();
  const seen = new Set<string>();
  const results: TagSuggestion[] = [];

  const scan = (
    map: Record<string, string[]> | undefined,
    category: TagSuggestion["category"]
  ) => {
    if (!map) return;
    for (const [tag, keywords] of Object.entries(map)) {
      if (seen.has(tag)) continue;
      for (const kw of keywords) {
        if (matchKeyword(lower, kw.toLowerCase())) {
          seen.add(tag);
          results.push({
            tag,
            confidence: kw.length >= 4 ? "high" : "medium",
            source: kw,
            category,
          });
          break; // one match per tag is enough
        }
      }
    }
  };

  scan(keywordMap.systems, "system");
  scan(keywordMap.projects, "project");
  scan(keywordMap.teams, "team");

  // Sort: high before medium, then by category order, then alphabetical
  const catOrder: Record<string, number> = { project: 0, system: 1, team: 2 };
  results.sort((a, b) => {
    const confDiff = (a.confidence === "high" ? 0 : 1) - (b.confidence === "high" ? 0 : 1);
    if (confDiff !== 0) return confDiff;
    const catDiff = (catOrder[a.category] ?? 9) - (catOrder[b.category] ?? 9);
    if (catDiff !== 0) return catDiff;
    return a.tag.localeCompare(b.tag);
  });

  return results;
}

/**
 * Word-boundary-aware keyword match.
 * For short keywords (≤3 chars) we require word boundaries on both sides
 * to avoid false positives (e.g. "HA" matching "have").
 * For longer keywords we just use includes().
 */
function matchKeyword(haystack: string, needle: string): boolean {
  if (needle.length <= 3) {
    // Use word-boundary regex for short keywords
    const escaped = needle.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    return new RegExp(`\\b${escaped}\\b`).test(haystack);
  }
  return haystack.includes(needle);
}

/**
 * Generate a Copilot-friendly prompt that includes the raw text, objective
 * registry, and tag rules so the user can paste into an AI assistant for
 * more nuanced tagging.
 */
export function generateIntakePrompt(
  rawText: string,
  settings: AppSettings,
  objectivesRaw?: string
): string {
  const lines: string[] = [];
  lines.push("# Intake — Tag & Route This Note\n");
  lines.push("## Raw Input\n");
  lines.push("```");
  lines.push(rawText.trim());
  lines.push("```\n");

  if (objectivesRaw) {
    lines.push("## Objective Registry (for reference)\n");
    lines.push(objectivesRaw.slice(0, 3000)); // cap size
    lines.push("\n");
  }

  lines.push("## Tag Rules\n");
  lines.push("- Every task MUST have exactly one `#project:<slug>` tag.");
  lines.push("- Systems use `#system:<tag>` (see systems.md).");
  lines.push("- Teams use `#team:<tag>` (see teams.md).");
  lines.push(`- Default project: \`#project:${settings.project.defaultProjectSlug}\``);
  lines.push("");

  const keywordMap = settings.tags?.keywordMap;
  if (keywordMap) {
    lines.push("## Known Keywords → Tags\n");
    const dumpMap = (label: string, m: Record<string, string[]> | undefined) => {
      if (!m) return;
      lines.push(`### ${label}\n`);
      for (const [tag, kws] of Object.entries(m)) {
        lines.push(`- \`${tag}\` ← ${kws.join(", ")}`);
      }
      lines.push("");
    };
    dumpMap("Systems", keywordMap.systems);
    dumpMap("Projects", keywordMap.projects);
    dumpMap("Teams", keywordMap.teams);
  }

  lines.push("## Instructions\n");
  lines.push("1. Extract discrete work items from the raw input.");
  lines.push("2. For each item, suggest: project tag, system tags, team tag, and a 1-line title.");
  lines.push("3. If an item does not align to any objective, flag it as unaligned.");
  lines.push("4. Output a markdown list of suggested tags per work item.\n");

  return lines.join("\n");
}
