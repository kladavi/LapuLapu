// ── Markdown parsers for each PM data file ──

import type {
  Objective,
  Team,
  SystemOfRecord,
  Task,
  Decision,
  WeeklySummary,
} from "./types";

// ────────────────────────────────────────────
// Utility helpers
// ────────────────────────────────────────────

function extractField(block: string, label: string): string {
  const regex = new RegExp(
    `\\*\\*${label}:?\\*\\*\\s*(.+?)(?=\\n\\*\\*|\\n##|\\n---|$)`,
    "s"
  );
  const m = block.match(regex);
  return m ? m[1].trim() : "";
}

/**
 * Extract a field from a bullet-formatted block like:
 *   - **Status:** Open
 *   - **Created:** 2026-03-20
 * Returns just the value after the label on the same line.
 */
function extractBulletField(block: string, label: string): string {
  const regex = new RegExp(
    `^\\s*-\\s*\\*\\*${label}:?\\*\\*\\s*(.+)$`,
    "m"
  );
  const m = block.match(regex);
  return m ? m[1].trim() : "";
}

function extractBulletList(block: string, label: string): string[] {
  const regex = new RegExp(
    `\\*\\*${label}\\*\\*\\s*\\n((?:[ \\t]*-\\s+.+\\n?)*)`,
    "m"
  );
  const m = block.match(regex);
  if (!m) return [];
  return m[1]
    .split("\n")
    .map((l) => l.replace(/^\s*-\s+/, "").trim())
    .filter(Boolean);
}

function extractTags(block: string): string[] {
  const m = block.match(/tags:\s*(.+)/i);
  if (!m) return [];
  return [
    ...new Set(
      m[1]
        .split(/\s+/)
        .map((t) => t.trim())
        .filter((t) => t.startsWith("#") && t.length > 1)
    ),
  ];
}

function extractHashtags(line: string): string[] {
  const tags = new Set<string>();
  const re = /#[\w-]+(?::[\w-]+)*/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(line)) !== null) {
    tags.add(m[0]);
  }
  return [...tags];
}

// ────────────────────────────────────────────
// Objectives parser
// ────────────────────────────────────────────

export function parseObjectives(md: string): Objective[] {
  const objectives: Objective[] = [];

  // Normalise line endings
  md = md.replace(/\r\n/g, "\n").replace(/\r/g, "\n");

  // Split by ### headings
  const blocks = md.split(/(?=^### )/m);

  let currentTierSection = 1;
  let currentOwner = "";

  // Also scan for tier section headings to track context
  const lines = md.split("\n");
  const tierSections: { line: number; tier: number; owner: string }[] = [];
  lines.forEach((l, i) => {
    const tierMatch = l.match(/^## Tier-(\d)/);
    if (tierMatch) {
      const tier = parseInt(tierMatch[1]);
      // Extract owner from heading like "## Tier-2 — Head of Technology Objectives (Hari Pothakamuri)"
      const ownerMatch = l.match(/\(([^)]+)\)/);
      tierSections.push({
        line: i,
        tier,
        owner: ownerMatch ? ownerMatch[1] : "",
      });
    }
  });

  for (const block of blocks) {
    const headingMatch = block.match(
      /^### ([A-Z]-?\d+)\s*[—–-]\s*(.+?)(?:\n|$)/
    );
    if (!headingMatch) continue;

    const id = headingMatch[1].trim();
    const title = headingMatch[2].trim();

    // Determine tier from ID prefix
    let tier: 1 | 2 | 3 = 1;
    if (id.match(/^O\d/)) tier = 1;
    else if (id.match(/^[A-Z]-\d/)) {
      // Check if we have tier-3 markers
      const blockLineIndex = md.indexOf(block);
      const precedingText = md.substring(0, blockLineIndex);
      if (precedingText.match(/## Tier-3/)) tier = 3;
      else tier = 2;
    }

    // Determine owner from preceding tier section heading
    const blockStart = md.indexOf(block);
    const precedingMd = md.substring(0, blockStart);
    const precedingLines = precedingMd.split("\n");
    for (let i = precedingLines.length - 1; i >= 0; i--) {
      const tierMatch = precedingLines[i].match(/^## Tier-(\d)/);
      if (tierMatch) {
        currentTierSection = parseInt(tierMatch[1]);
        const ownerMatch = precedingLines[i].match(/\(([^)]+)\)/);
        currentOwner = ownerMatch ? ownerMatch[1] : "";
        break;
      }
    }

    const tags = extractTags(block);

    // Source lines
    const sourceLines = extractBulletList(block, "Source");

    // Source file
    const sourceFileMatch = block.match(
      /\*\*Source Files?:?\*\*[:\s]*(?:\n\s*-\s*)?(?:\[([^\]]+)\])?/
    );
    const sourceFile = sourceFileMatch ? sourceFileMatch[1] || "" : "";

    // Parent objective — only match registered objective ID formats:
    //   Tier-1: O followed by digits (O1, O6)
    //   Tier-2: single letter + dash + digits (H-1, B-3, KL-1)
    const parentLines = extractBulletList(block, "Parent Objective");
    const parentIds: string[] = [];
    for (const pl of parentLines) {
      const idMatches = pl.match(/\bO\d+\b|\b[A-Z]{1,2}-\d+\b/g);
      if (idMatches) parentIds.push(...idMatches);
    }

    // Description
    const description = extractField(block, "Description");

    // Commitments (supports both legacy and new field names)
    let commitments = extractBulletList(
      block,
      "Explicit Commitments / Outcomes"
    );
    if (commitments.length === 0) {
      commitments = extractBulletList(block, "Commitments");
    }

    objectives.push({
      id,
      title,
      tier: currentTierSection as 1 | 2 | 3,
      tags,
      source: sourceLines,
      sourceFile,
      parentObjectiveIds: parentIds,
      description,
      commitments,
      ownerSection: currentOwner,
      raw: block.trim(),
    });
  }

  return objectives;
}

// ────────────────────────────────────────────
// Teams parser
// ────────────────────────────────────────────

export function parseTeams(md: string): Team[] {
  const teams: Team[] = [];

  // Normalise line endings
  md = md.replace(/\r\n/g, "\n").replace(/\r/g, "\n");

  const blocks = md.split(/(?=^## )/m);

  for (const block of blocks) {
    const headingMatch = block.match(/^## (.+?)(?:\n|$)/);
    if (!headingMatch || headingMatch[1].match(/^#|Teams/i)) continue;

    const topTeam = parseTeamBlock(block, 2);
    if (topTeam) {
      // Find sub-teams (### headings within this block)
      const subBlocks = block.split(/(?=^### )/m);
      const subTeams: Team[] = [];
      for (const sb of subBlocks) {
        if (sb.match(/^### /)) {
          const sub = parseTeamBlock(sb, 3);
          if (sub) subTeams.push(sub);
        }
      }
      topTeam.subTeams = subTeams;
      teams.push(topTeam);
    }
  }

  return teams;
}

function parseTeamBlock(block: string, headingLevel: number): Team | null {
  const prefix = "#".repeat(headingLevel);
  const regex = new RegExp(`^${prefix} (.+?)(?:\\n|$)`);
  const headingMatch = block.match(regex);
  if (!headingMatch) return null;

  const nameRaw = headingMatch[1].trim();
  // Remove parenthetical descriptions
  const name = nameRaw.replace(/\s*\(.+?\)\s*$/, "").trim();

  const lead = extractBulletField(block, "Lead") || "";
  const reportsTo = extractBulletField(block, "Reports to") || undefined;
  const membersLine = extractBulletField(block, "Members") || "";
  const members = membersLine
    ? membersLine.split(",").map((m) => m.trim()).filter(Boolean)
    : undefined;
  const systemsLine = extractBulletField(block, "Primary Systems") || "";
  const primarySystems = systemsLine ? extractHashtags(systemsLine) : undefined;
  const workTypes = extractBulletField(block, "Work Types") || undefined;
  const objectiveAlignment =
    extractBulletField(block, "Objective Alignment") || undefined;
  const tags = extractHashtags(
    block
      .split("\n")
      .find((l) => l.match(/^\s*-\s*\*\*Tags/i) || l.match(/\*\*Tags/i)) || ""
  );

  return {
    name,
    lead,
    reportsTo,
    members,
    primarySystems,
    workTypes,
    objectiveAlignment,
    tags,
    subTeams: [],
    raw: block.trim(),
  };
}

// ────────────────────────────────────────────
// Systems parser
// ────────────────────────────────────────────

export function parseSystems(md: string): SystemOfRecord[] {
  const systems: SystemOfRecord[] = [];

  // Normalise line endings
  md = md.replace(/\r\n/g, "\n").replace(/\r/g, "\n");

  const lines = md.split("\n");

  for (const line of lines) {
    // Match table rows: | Name | #tag | Purpose | (supports namespaced tags like #system:azure)
    const m = line.match(/^\|\s*([^|]+?)\s*\|\s*(#[\w:-]+)\s*\|\s*(.+?)\s*\|$/);
    if (m && !m[1].match(/^-+$/) && m[1] !== "System") {
      systems.push({
        name: m[1].trim(),
        tag: m[2].trim(),
        purpose: m[3].trim(),
      });
    }
  }

  return systems;
}

// ────────────────────────────────────────────
// Tasks parser
// ────────────────────────────────────────────

export function parseTasks(md: string): Task[] {
  const tasks: Task[] = [];

  // Normalise line endings
  md = md.replace(/\r\n/g, "\n").replace(/\r/g, "\n");

  const blocks = md.split(/(?=^## T\d)/m);

  for (const block of blocks) {
    const headingMatch = block.match(/^## (T\d+)\s*[—–-]\s*(.+?)(?:\n|$)/);
    if (!headingMatch) continue;

    const id = headingMatch[1].trim();
    const title = headingMatch[2].trim();
    const status = extractBulletField(block, "Status") || "Open";
    const created = extractBulletField(block, "Created") || "";
    const objectiveChain = extractBulletField(block, "Objective Chain") || "";
    const team = extractBulletField(block, "Team") || "";
    const assigned = extractBulletField(block, "Assigned") || "";
    const systemsLine = extractBulletField(block, "Systems") || "";
    const systems = extractHashtags(systemsLine);
    const relevanceStr = extractBulletField(block, "Relevance") || "";
    const relevanceMatch = relevanceStr.match(/(\d+)/);
    const relevance = relevanceMatch ? parseInt(relevanceMatch[1]) : undefined;
    const tags = extractHashtags(extractBulletField(block, "Tags") || "");
    const description = extractBulletField(block, "Description") || "";

    // Extract all objective IDs from the chain
    const objIds: string[] = [];
    const objIdMatches = objectiveChain.match(/\bO\d+\b|\b[A-Z]{1,2}-\d+\b/g);
    if (objIdMatches) objIds.push(...objIdMatches);

    tasks.push({
      id,
      title,
      status,
      created,
      objectiveChain,
      objectiveIds: objIds,
      team,
      assigned,
      systems,
      relevance,
      tags,
      description,
      raw: block.trim(),
    });
  }

  return tasks;
}

// ────────────────────────────────────────────
// Decisions parser
// ────────────────────────────────────────────

export function parseDecisions(md: string): Decision[] {
  const decisions: Decision[] = [];

  // Normalise line endings
  md = md.replace(/\r\n/g, "\n").replace(/\r/g, "\n");

  const blocks = md.split(/(?=^## D\d)/m);

  for (const block of blocks) {
    const headingMatch = block.match(/^## (D\d+)\s*[—–-]\s*(.+?)(?:\n|$)/);
    if (!headingMatch) continue;

    const id = headingMatch[1].trim();
    const title = headingMatch[2].trim();
    const date = extractField(block, "Date") || "";
    const requestor = extractField(block, "Requestor") || "";
    const request = extractField(block, "Request") || "";
    const decision = extractField(block, "Decision") || "";
    const reason = extractField(block, "Reason") || "";
    // Support both **Tags:** field and tags: line format
    let tags = extractHashtags(extractField(block, "Tags") || "");
    if (tags.length === 0) {
      tags = extractTags(block);
    }

    decisions.push({
      id,
      title,
      date,
      requestor,
      request,
      decision,
      reason,
      tags,
      raw: block.trim(),
    });
  }

  return decisions;
}

// ────────────────────────────────────────────
// Weekly summary parser
// ────────────────────────────────────────────

export function parseWeeklySummaries(
  files: Record<string, string>
): WeeklySummary[] {
  const summaries: WeeklySummary[] = [];

  for (const [path, content] of Object.entries(files)) {
    const normalised = path.replace(/\\/g, "/");
    if (
      normalised.includes("03-reporting/weekly/") &&
      normalised.endsWith(".md") &&
      !normalised.endsWith(".gitkeep")
    ) {
      const filename = normalised.split("/").pop() || path;
      summaries.push({ filename, content });
    }
  }

  // Sort by filename descending (newest first)
  summaries.sort((a, b) => b.filename.localeCompare(a.filename));
  return summaries;
}
