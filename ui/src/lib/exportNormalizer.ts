// ── Export normalization utilities ──
// Fixes: Issue 2 (parentObjectiveIds), Issue 3 (task normalization),
//        Issue 4 (weekly summaries), Issue 5 (tag standardization)

import type { Objective, Task, Team, SystemOfRecord, WeeklySummary, ExportWarning } from "./types";

// ────────────────────────────────────────────
// ISSUE 2 — Objective ID validation & marker normalization
// ────────────────────────────────────────────

/** Valid exported objective ID patterns (Tier-1 + all Tier-2 owners) */
const VALID_OBJ_ID_RE = /^(O\d+|[A-Z]{1,2}-\d+)$/;

/** Check if a string is a valid objective ID present in the allowed set */
export function validateObjectiveId(id: string, allowedIds: Set<string>): boolean {
  return VALID_OBJ_ID_RE.test(id) && allowedIds.has(id);
}

/** Convert non-objective markers into normalized tags */
export function normalizeMarkerToTag(marker: string): string | null {
  const s = marker.trim();
  if (!s) return null;

  // Support levels: L0, L1, L2, L3
  if (/^L[0-3]$/i.test(s)) return `#support:${s.toLowerCase()}`;

  // R2 / R2R -> program tag
  if (/^R2R?$/i.test(s)) return "#program:r2r";

  // Fiscal year: Y2026, Y2025, etc.
  const yearMatch = s.match(/^Y(\d{4})$/i);
  if (yearMatch) return `#time:fy${yearMatch[1]}`;

  // Quarter: Q1..Q4
  if (/^Q[1-4]$/i.test(s)) return `#time:${s.toLowerCase()}`;

  // Severity: P1, P2, P3, P4
  if (/^P[1-4]$/i.test(s)) return `#severity:${s.toLowerCase()}`;

  // Fallback: if it looks like a short code but isn't a valid obj ID, tag it generically
  if (/^[A-Z][A-Z0-9-]{0,5}$/i.test(s) && !VALID_OBJ_ID_RE.test(s)) {
    return `#marker:${s.toLowerCase()}`;
  }

  return null;
}

/**
 * Separate a list of mixed IDs/markers into valid objective IDs and converted tags.
 */
export function splitIdsAndMarkers(
  ids: string[],
  allowedIds: Set<string>
): { validIds: string[]; convertedTags: string[] } {
  const validIds: string[] = [];
  const convertedTags: string[] = [];

  for (const raw of ids) {
    const id = raw.trim();
    if (!id) continue;

    if (validateObjectiveId(id, allowedIds)) {
      validIds.push(id);
    } else {
      const tag = normalizeMarkerToTag(id);
      if (tag) convertedTags.push(tag);
    }
  }

  return { validIds: [...new Set(validIds)], convertedTags: [...new Set(convertedTags)] };
}

// ────────────────────────────────────────────
// ISSUE 3 — Task normalization
// ────────────────────────────────────────────

/** Strip markdown formatting (bold, italic, links, headings) and collapse whitespace */
export function sanitizeText(text: string): string {
  return text
    .replace(/\*\*([^*]+)\*\*/g, "$1")     // **bold**
    .replace(/\*([^*]+)\*/g, "$1")          // *italic*
    .replace(/__([^_]+)__/g, "$1")          // __bold__
    .replace(/_([^_]+)_/g, "$1")            // _italic_
    .replace(/\[([^\]]+)\]\([^)]+\)/g, "$1") // [text](url)
    .replace(/^#{1,6}\s+/gm, "")           // headings
    .replace(/^[-*]\s+/gm, "")             // bullet markers
    .replace(/\r\n/g, " ")
    .replace(/\n/g, " ")
    .replace(/\s{2,}/g, " ")
    .trim();
}

/** Cap free-text fields to a maximum length */
export function capNotesLength(text: string, maxLen = 500): string {
  const clean = sanitizeText(text);
  if (clean.length <= maxLen) return clean;
  return clean.slice(0, maxLen - 3) + "...";
}

// ────────────────────────────────────────────
// ISSUE 5 — Tag standardization
// ────────────────────────────────────────────

/** Known system name -> normalized tag mapping */
const SYSTEM_TAG_MAP: Record<string, string> = {
  "azure":     "#system:azure",
  "newrelic":  "#system:newrelic",
  "new relic": "#system:newrelic",
  "moogsoft":  "#system:moogsoft",
  "xmatters":  "#system:xmatters",
  "leanix":    "#system:leanix",
  "cmdb":      "#system:cmdb",
  "adobe":     "#system:adobe",
  "apm":       "#system:apm",
  "adx":       "#system:adx",
  "ingenium":  "#system:ingenium",
};

/** Known team name -> normalized tag mapping */
const TEAM_TAG_MAP: Record<string, string> = {
  "gocc":                "#team:gocc",
  "team-gocc":           "#team:gocc",
  "gocc-monitoring":     "#team:gocc-monitoring",
  "team-gocc-monitoring":"#team:gocc-monitoring",
  "gocc-observability":  "#team:gocc-observability",
  "team-gocc-observability": "#team:gocc-observability",
  "ets-japan":           "#team:ets-japan",
  "team-ets-japan":      "#team:ets-japan",
  "ets-region":          "#team:ets-region",
  "team-ets-region":     "#team:ets-region",
  "team-obs":            "#team:obs",
  "team-infra":          "#team:infra",
};

/** Exact name corrections applied during export */
const NAME_NORMALIZATION_MAP: Record<string, string> = {
  "Kiran Bond": "Kiran Bonde",
};

/** Normalize a team member name using the exact-match correction map */
function normalizeMemberName(name: string): string {
  const trimmed = name.trim();
  return NAME_NORMALIZATION_MAP[trimmed] ?? trimmed;
}

/** Known owner aliases */
const OWNER_TAG_MAP: Record<string, string> = {
  "hari":       "#owner:hari",
  "birger":     "#owner:birger",
  "kelvin":     "#owner:kelvin",
  "jonan":      "#owner:jonan",
  "debamalya":  "#owner:debamalya",
  "david":      "#owner:david",
  "davidklan":  "#owner:david",
};

/**
 * Normalize a single tag from any legacy format to the standardized format.
 * Input may or may not have a leading #.
 */
export function normalizeTag(raw: string): string {
  const s = raw.replace(/^#/, "").toLowerCase().trim();
  if (!s) return "";

  // Already namespaced — keep as-is (but lowercase)
  if (s.includes(":")) return `#${s}`;

  // System tags
  if (SYSTEM_TAG_MAP[s]) return SYSTEM_TAG_MAP[s];

  // Team tags
  if (TEAM_TAG_MAP[s]) return TEAM_TAG_MAP[s];

  // Owner tags
  if (OWNER_TAG_MAP[s]) return OWNER_TAG_MAP[s];

  // Tier tags
  if (s === "tier1") return "#tier:1";
  if (s === "tier2") return "#tier:2";
  if (s === "tier3") return "#tier:3";

  // Generic tag → namespaced tag tightening (Issue improvement #4)
  const GENERIC_TAG_MAP: Record<string, string> = {
    "monitoring":  "#worktype:monitoring",
    "resilience":  "#outcome:resilience",
    "dashboard":   "#artifact:dashboard",
    "dashboards":  "#artifact:dashboard",
    "digital":     "#domain:digital",
    "automation":  "#capability:automation",
  };
  if (GENERIC_TAG_MAP[s]) return GENERIC_TAG_MAP[s];

  // "objective" meta-tag — drop it (redundant in objectives array)
  if (s === "objective") return "";

  // Severity
  if (/^p[1-4]$/.test(s)) return `#severity:${s}`;
  if (s === "p1-followup") return "#severity:p1-followup";

  // Support levels
  if (/^l[0-3]$/.test(s)) return `#support:${s}`;

  // Programs
  if (s === "r2r") return "#program:r2r";
  if (s === "omm") return "#program:omm";
  if (s === "odf") return "#program:odf";

  // Pass through with # prefix
  return `#${s}`;
}

/** Normalize and deduplicate a list of tags */
export function normalizeTags(tags: string[]): string[] {
  const result: string[] = [];
  const seen = new Set<string>();
  for (const raw of tags) {
    const t = normalizeTag(raw);
    if (t && !seen.has(t)) {
      seen.add(t);
      result.push(t);
    }
  }
  return result;
}

/**
 * Separate system-only tags from non-system tags.
 * Useful for cleaning up systems fields that contain mixed tag types.
 */
export function partitionSystemTags(tags: string[]): {
  systemTags: string[];
  otherTags: string[];
} {
  const systemTags: string[] = [];
  const otherTags: string[] = [];
  for (const raw of tags) {
    const t = normalizeTag(raw);
    if (!t) continue;
    if (t.startsWith("#system:")) {
      systemTags.push(t);
    } else {
      otherTags.push(t);
    }
  }
  return {
    systemTags: [...new Set(systemTags)],
    otherTags: [...new Set(otherTags)],
  };
}

// ────────────────────────────────────────────
// ISSUE 4 — Weekly summary normalization
// ────────────────────────────────────────────

export interface NormalizedWeeklySummary {
  weekId: string;
  fileName: string;
  project?: string;
  executiveSummary: string[];
  highlights: string[];
  risks: string[];
  nextFocus: string[];
  rawText: string;
}

/**
 * Extract structured sections from a weekly summary markdown file.
 */
export function normalizeWeeklySummary(ws: WeeklySummary): NormalizedWeeklySummary {
  const fileName = ws.filename;
  const weekId = fileName.replace(/\.md$/i, "");
  const md = ws.content.replace(/\r\n/g, "\n").replace(/\r/g, "\n");

  // Executive Summary — bold objective-name paragraphs
  const executiveSummary = extractSectionLines(md, [
    "Executive Summary",
  ]);

  // Key Accomplishments — standalone lines (no bullets)
  const highlights = extractSectionLines(md, [
    "Key Accomplishments",
    "Key Accomplishments (This Week)",
    "Objectives Advanced",
    "Highlights",
    "Key Outcomes",
    "Accomplishments",
    "Progress",
  ]);

  // Top Risks & Issues — pipe-separated format: [Risk] · desc | mitigation | owner |
  const risks = extractSectionLines(md, [
    "Top Risks & Issues",
    "Risks & Issues",
    "Risks & Escalations",
    "Risks",
    "Blockers",
    "Risks / Blockers",
    "Issues",
  ]);

  // Planned for Next Week — standalone lines
  const nextFocus = extractSectionLines(md, [
    "Planned for Next Week",
    "Next-Week Focus",
    "Next Week Focus",
    "Next Week",
    "Focus",
    "Upcoming",
    "Next Steps",
  ]);

  // Raw text fallback: first 1500 chars stripped of markdown
  const rawText = sanitizeText(md).slice(0, 1500);

  // Provide default placeholders if sections were not found
  const finalRisks = risks.length > 0 ? risks : ["No explicit risks captured in weekly file."];
  const finalNextFocus = nextFocus.length > 0 ? nextFocus : ["No explicit next-week focus captured in weekly file."];

  return { weekId, fileName, project: ws.project, executiveSummary, highlights, risks: finalRisks, nextFocus: finalNextFocus, rawText };
}

/**
 * Extract content lines from a section — supports bullets, numbered lists,
 * table rows, pipe-separated risk lines, and plain standalone lines.
 */
function extractSectionLines(md: string, headingNames: string[]): string[] {
  for (const name of headingNames) {
    const escaped = escapeRegExp(name);
    // Match heading, then capture everything until the next heading or horizontal rule.
    // Uses a greedy match that stops at the next ## heading or --- rule boundary.
    const re = new RegExp(
      `^#{1,4}\\s*${escaped}[^\\n]*\\n([\\s\\S]+?)(?=\\n#{1,4}\\s|\\n---\\s*\\n|\\n---\\s*$)`,
      "im"
    );
    let m = md.match(re);
    // Fallback: if no next boundary, capture to end of string
    if (!m) {
      const reFallback = new RegExp(
        `^#{1,4}\\s*${escaped}[^\\n]*\\n([\\s\\S]+)$`,
        "im"
      );
      m = md.match(reFallback);
    }
    if (!m || !m[1]) continue;

    const body = m[1].trim();
    if (!body) continue;

    const items: string[] = [];
    const bodyLines = body.split("\n");

    // Detect if body is a markdown table
    const isTable = bodyLines.some((l) => l.trim().startsWith("|") && l.includes("|"));

    if (isTable) {
      for (const line of bodyLines) {
        const trimmed = line.trim();
        if (!trimmed.startsWith("|")) continue;
        if (/^\|[\s-|]+\|$/.test(trimmed)) continue;
        const cells = trimmed.split("|").map((c) => c.trim()).filter(Boolean);
        if (cells.length === 0) continue;
        if (cells[0].toLowerCase() === "risk" || cells[0].toLowerCase() === "request" || cells[0].toLowerCase() === "objective") continue;
        if (cells[0].toLowerCase().includes("none")) continue;
        const summary = cells.filter((c) => c !== "—" && c !== "-").join(" — ");
        if (summary) items.push(sanitizeText(summary));
      }
    } else {
      for (const line of bodyLines) {
        const trimmed = line.trim();
        if (!trimmed) continue;
        // Skip blockquote footnotes (> lines)
        if (trimmed.startsWith(">")) {
          items.push(sanitizeText(trimmed.replace(/^>\s*/, "")));
          continue;
        }
        // Bullet item
        const bulletMatch = trimmed.match(/^[-*]\s+(.+)/);
        if (bulletMatch) {
          items.push(sanitizeText(bulletMatch[1]));
          continue;
        }
        // Numbered item
        const numberMatch = trimmed.match(/^\d+[.):]\s*(.+)/);
        if (numberMatch) {
          items.push(sanitizeText(numberMatch[1]));
          continue;
        }
        // Pipe-separated risk line: [Risk] · desc | mitigation | owner |
        if (trimmed.startsWith("[Risk]") || trimmed.startsWith("[Issue]")) {
          items.push(sanitizeText(trimmed));
          continue;
        }
        // Bold objective heading line (Executive Summary style)
        if (/^\*\*[^*]+\*\*/.test(trimmed)) {
          items.push(sanitizeText(trimmed));
          continue;
        }
        // Plain standalone line (not empty, not a heading marker)
        if (trimmed.length > 5) {
          items.push(sanitizeText(trimmed));
        }
      }
    }

    if (items.length > 0) return items;
  }
  return [];
}

function escapeRegExp(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

// ────────────────────────────────────────────
// Normalized export types
// ────────────────────────────────────────────

export interface NormalizedObjective {
  id: string;
  title: string;
  tier: number;
  tags: string[];
  parentObjectiveIds: string[];
  description: string;
  commitments: string[];
}

export interface NormalizedTask {
  id: string;
  title: string;
  created: string | null;
  status: "Open" | "Closed" | "Deferred" | null;
  objectiveIds: string[];
  assignee: string | null;
  team: string | null;
  systems: string[];
  relevance: number | null;
  tags: string[];
  notes: string;
}

export interface NormalizedTeam {
  name: string;
  lead: string;
  tags: string[];
  members?: string[];
  primarySystems: string[];
}

export interface NormalizedSystem {
  name: string;
  tag: string;
  purpose: string;
}

export interface NormalizedExportPayload {
  objectives?: NormalizedObjective[];
  teams?: NormalizedTeam[];
  systems?: NormalizedSystem[];
  tasks?: NormalizedTask[];
  decisions?: { id: string; title: string; date: string; decision: string; reason: string; tags: string[] }[];
  weekly_summaries?: NormalizedWeeklySummary[];
  inbox?: string;
  exportWarnings?: ExportWarning[];
}

// ────────────────────────────────────────────
// Normalization pipeline
// ────────────────────────────────────────────

/**
 * Build a normalized, validated export payload from raw PMData.
 * Enforces Issue 1 filter (Tier-1 + Hari Tier-2 only) and applies
 * Issues 2–5 normalization.
 */
export function buildNormalizedPayload(
  objectives: Objective[],
  tasks: Task[],
  teams: Team[],
  systems: SystemOfRecord[],
  weeklySummaries: WeeklySummary[],
  decisions: { id: string; title: string; date: string; decision: string; reason: string; tags: string[]; raw: string }[],
  inbox: string,
  options: {
    includeObjectives: boolean;
    includeTeamsSystems: boolean;
    includeTasks: boolean;
    includeDecisions: boolean;
    includeWeeklySummaries: boolean;
    weeklySummaryCount: number;
    includeInbox: boolean;
  }
): NormalizedExportPayload {
  const payload: NormalizedExportPayload = {};

  // ── Filter objectives: Tier-1 (O*) + all Tier-2 owners ──
  const exportedObjectives = objectives.filter(
    (o) => VALID_OBJ_ID_RE.test(o.id)
  );

  // Build allowed-IDs set for validation
  const allowedIds = new Set(exportedObjectives.map((o) => o.id));

  // ── Objectives normalization (Issue 2 + Issue 5) ──
  if (options.includeObjectives) {
    payload.objectives = exportedObjectives.map((o) => {
      const { validIds, convertedTags } = splitIdsAndMarkers(o.parentObjectiveIds, allowedIds);
      const baseTags = normalizeTags(o.tags);
      // Merge converted marker tags into the tags array
      const allTags = normalizeTags([...baseTags, ...convertedTags]);

      return {
        id: o.id,
        title: o.title,
        tier: o.tier,
        tags: allTags,
        parentObjectiveIds: validIds,
        description: sanitizeText(o.description),
        commitments: o.commitments.map((c) => sanitizeText(c)),
      };
    });
  }

  // ── Teams normalization (Issue 5) ──
  if (options.includeTeamsSystems) {
    const flatTeams: Team[] = [];
    for (const t of teams) {
      flatTeams.push(t);
      if (t.subTeams) flatTeams.push(...t.subTeams);
    }

    payload.teams = flatTeams.map((t) => {
      const { systemTags } = partitionSystemTags(t.primarySystems || []);
      return {
        name: t.name,
        lead: normalizeMemberName(t.lead),
        tags: normalizeTags(t.tags),
        members: t.members?.map(normalizeMemberName),
        primarySystems: systemTags,
      };
    });

    // Systems normalization
    payload.systems = systems.map((s) => ({
      name: s.name,
      tag: normalizeTag(s.tag) || `#system:${s.name.toLowerCase().replace(/\s+/g, "")}`,
      purpose: s.purpose,
    }));
  }

  // ── Tasks normalization (Issue 2 + Issue 3 + Issue 5) ──
  // Collect export warnings for tasks referencing out-of-scope objectives
  const exportWarnings: ExportWarning[] = [];

  if (options.includeTasks) {
    payload.tasks = tasks.map((t) => {
      // Split objective IDs vs markers
      const { validIds, convertedTags } = splitIdsAndMarkers(t.objectiveIds, allowedIds);

      // Soft validation: detect objective IDs that are syntactically valid
      // but not present in the exported objective set
      const externalObjTags: string[] = [];
      for (const rawId of t.objectiveIds) {
        const id = rawId.trim();
        if (VALID_OBJ_ID_RE.test(id) && !allowedIds.has(id)) {
          exportWarnings.push({
            type: "TASK_OBJECTIVE_OUT_OF_SCOPE",
            taskId: t.id,
            objectiveId: id,
            message: `Task references an objective not included in this export scope.`,
          });
          externalObjTags.push("#objective:external");
        }
      }

      // Separate system tags from non-system tags in the systems field
      const { systemTags, otherTags: systemFieldOtherTags } = partitionSystemTags(t.systems);

      // Normalize the task's own tags
      const rawTags = normalizeTags(t.tags);

      // Merge: task tags + converted markers + non-system tags + external objective tags
      const allTags = normalizeTags([
        ...rawTags,
        ...convertedTags,
        ...systemFieldOtherTags,
        ...externalObjTags,
      ]);

      // Normalize status
      const statusClean = normalizeStatus(t.status);

      // Normalize assignee: strip markdown and team references
      const assignee = sanitizeText(t.assigned).replace(/^[-*]\s*/, "") || null;

      // Normalize team: extract just the team name
      const teamName = extractTeamName(t.team);

      // Relevance: ensure numeric
      let relevance: number | null = t.relevance ?? null;
      if (relevance !== null && (relevance < 0 || relevance > 100)) relevance = null;

      // Notes: use description, capped
      const notes = capNotesLength(t.description);

      // Created date normalization
      const created = extractDate(t.created);

      // Keep ALL objective IDs (including out-of-scope) in objectiveIds
      // but only validIds are "in-scope"; externalIds are kept for traceability
      const allObjectiveIds = [...new Set([...validIds, ...t.objectiveIds.filter(id => VALID_OBJ_ID_RE.test(id.trim())).map(id => id.trim())])];

      return {
        id: t.id,
        title: sanitizeText(t.title),
        created,
        status: statusClean,
        objectiveIds: allObjectiveIds,
        assignee: assignee && assignee !== "" ? assignee : null,
        team: teamName,
        systems: systemTags,
        relevance,
        tags: allTags,
        notes,
      };
    });
  }

  // ── Decisions ──
  if (options.includeDecisions) {
    payload.decisions = decisions.map((d) => ({
      id: d.id,
      title: d.title,
      date: d.date,
      decision: sanitizeText(d.decision),
      reason: sanitizeText(d.reason),
      tags: normalizeTags(d.tags),
    }));
  }

  // ── Weekly summaries (Issue 4) + auto-seed (Improvement #3) ──
  if (options.includeWeeklySummaries) {
    const count = options.weeklySummaryCount || 1;
    // weeklySummaries are already sorted newest-first by the parser
    const selected = weeklySummaries.slice(0, count);
    const normalized = selected.map(normalizeWeeklySummary);

    if (normalized.length === 0) {
      // Auto-generate a synthetic seed weekly summary
      const seedSummary = generateSeedWeeklySummary(
        payload.tasks || [],
        payload.objectives || [],
        payload.decisions || []
      );
      payload.weekly_summaries = [seedSummary];
    } else {
      payload.weekly_summaries = normalized;
    }
  }

  // ── Inbox ──
  if (options.includeInbox) {
    payload.inbox = inbox;
  }

  // ── Attach export warnings ──
  if (exportWarnings.length > 0) {
    payload.exportWarnings = exportWarnings;
  }

  return payload;
}

// ────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────

const VALID_STATUSES = ["Open", "Closed", "Deferred"] as const;

function normalizeStatus(raw: string): "Open" | "Closed" | "Deferred" | null {
  const s = sanitizeText(raw).trim();
  for (const valid of VALID_STATUSES) {
    if (s.toLowerCase() === valid.toLowerCase()) return valid;
  }
  // Try to find a status word in a longer string
  for (const valid of VALID_STATUSES) {
    if (s.toLowerCase().includes(valid.toLowerCase())) return valid;
  }
  return null;
}

function extractTeamName(raw: string): string | null {
  const clean = sanitizeText(raw).replace(/^#\S+\s*/, "").trim();
  if (!clean) {
    // Try to extract team tag and convert (supports both #team-xxx and #team:xxx)
    const tagMatch = raw.match(/#(team[:\-][\w-]*)/i);
    if (tagMatch) {
      const tag = normalizeTag(tagMatch[1]);
      // Convert #team:gocc back to "GOCC" style name
      const name = tag.replace("#team:", "").replace(/-/g, " ").toUpperCase();
      return name || null;
    }
    return null;
  }
  return clean;
}

function extractDate(raw: string): string | null {
  const m = raw.match(/(\d{4}-\d{2}-\d{2})/);
  return m ? m[1] : null;
}

// ────────────────────────────────────────────
// Validation gate
// ────────────────────────────────────────────

export interface ValidationError {
  field: string;
  entity: string;
  message: string;
}

/**
 * Validate a normalized payload before export.
 * Returns an empty array if valid; otherwise returns list of violations.
 */
export function validateExportPayload(payload: NormalizedExportPayload): ValidationError[] {
  const errors: ValidationError[] = [];
  const objIds = new Set((payload.objectives || []).map((o) => o.id));

  // Validate objective parentObjectiveIds all exist in the exported set
  for (const obj of payload.objectives || []) {
    for (const pid of obj.parentObjectiveIds) {
      if (!objIds.has(pid)) {
        errors.push({
          field: "parentObjectiveIds",
          entity: obj.id,
          message: `Parent "${pid}" not found in exported objectives`,
        });
      }
    }
  }

  // Task objectiveIds referencing out-of-scope objectives are now handled
  // via soft warnings (exportWarnings) rather than blocking validation errors.

  // Validate system tags start with #system:
  for (const sys of payload.systems || []) {
    if (!sys.tag.startsWith("#system:")) {
      errors.push({
        field: "tag",
        entity: sys.name,
        message: `System tag "${sys.tag}" does not start with "#system:"`,
      });
    }
  }

  // Validate no markdown blocks in JSON fields (except rawText/notes)
  for (const obj of payload.objectives || []) {
    if (containsMarkdownBlock(obj.description)) {
      errors.push({
        field: "description",
        entity: obj.id,
        message: "Description contains markdown block formatting",
      });
    }
  }

  for (const task of payload.tasks || []) {
    if (task.assignee && containsMarkdownBlock(task.assignee)) {
      errors.push({
        field: "assignee",
        entity: task.id,
        message: "Assignee contains markdown block formatting",
      });
    }
    if (task.team && containsMarkdownBlock(task.team)) {
      errors.push({
        field: "team",
        entity: task.id,
        message: "Team contains markdown block formatting",
      });
    }
    if (task.status && containsMarkdownBlock(task.status)) {
      errors.push({
        field: "status",
        entity: task.id,
        message: "Status contains markdown block formatting",
      });
    }
  }

  return errors;
}

function containsMarkdownBlock(text: string): boolean {
  // Detect headings, bullet lists, bold/italic blocks, or multi-line content
  return /^#{1,6}\s/m.test(text) || /\n[-*]\s+/m.test(text) || /\*\*[^*]+\*\*/m.test(text);
}

// ────────────────────────────────────────────
// Human-readable snapshot generation
// ────────────────────────────────────────────

export function generateHumanSnapshot(payload: NormalizedExportPayload): string {
  const lines: string[] = [];
  lines.push("## HUMAN-READABLE SNAPSHOT\n");

  // Objectives summary
  if (payload.objectives && payload.objectives.length > 0) {
    lines.push("### Objectives\n");
    const tier1 = payload.objectives.filter((o) => o.tier === 1);
    const tier2 = payload.objectives.filter((o) => o.tier === 2);

    if (tier1.length > 0) {
      lines.push("**Tier-1 (Company)**");
      for (const o of tier1) {
        lines.push(`- ${o.id}: ${o.title}`);
      }
      lines.push("");
    }
    // Show Tier-2 objectives grouped by owner prefix
    if (tier2.length > 0) {
      // Group by ID prefix (e.g. H- = Hari, B- = Birger)
      const ownerGroups: Record<string, NormalizedObjective[]> = {};
      for (const o of tier2) {
        const prefixMatch = o.id.match(/^([A-Z]{1,2})(?=-\d)/);
        const prefix = prefixMatch ? prefixMatch[1] : "Other";
        if (!ownerGroups[prefix]) ownerGroups[prefix] = [];
        ownerGroups[prefix].push(o);
      }

      const OWNER_PREFIX_LABEL: Record<string, string> = {
        "H": "Hari",
        "B": "Birger",
        "KL": "Kelvin",
        "D": "Deb",
        "J": "Jonan",
      };

      for (const [prefix, objs] of Object.entries(ownerGroups)) {
        const ownerLabel = OWNER_PREFIX_LABEL[prefix] || prefix;
        lines.push(`**Tier-2 (${ownerLabel})**`);
        for (const o of objs) {
          lines.push(`- ${o.id}: ${o.title} → ${o.parentObjectiveIds.join(", ") || "none"}`);
        }
        lines.push("");
      }
    }
  }

  // Tasks summary
  if (payload.tasks && payload.tasks.length > 0) {
    lines.push("### Tasks\n");
    for (const t of payload.tasks) {
      const status = t.status || "Unknown";
      lines.push(`- ${t.id}: ${t.title} [${status}] → ${t.objectiveIds.join(", ") || "unaligned"}`);
    }
    lines.push("");
  }

  // Weekly summaries
  if (payload.weekly_summaries) {
    lines.push("### Weekly Status Reports\n");
    if (payload.weekly_summaries.length === 0) {
      lines.push("No weekly report files found under 03-reporting/weekly/.\n");
    } else {
      for (const ws of payload.weekly_summaries) {
        lines.push(`**${ws.weekId}** (${ws.fileName})`);
        if (ws.executiveSummary && ws.executiveSummary.length > 0) {
          lines.push("Executive Summary:");
          for (const s of ws.executiveSummary) {
            lines.push(`  ${s}`);
          }
        }
        if (ws.highlights.length > 0) {
          lines.push("Accomplishments:");
          for (const h of ws.highlights) {
            lines.push(`  ${h}`);
          }
        }
        if (ws.risks.length > 0) {
          lines.push("Risks:");
          for (const r of ws.risks) {
            lines.push(`  ${r}`);
          }
        }
        if (ws.nextFocus.length > 0) {
          lines.push("Next Week:");
          for (const n of ws.nextFocus) {
            lines.push(`  ${n}`);
          }
        }
        lines.push("");
      }
    }
  }

  // Systems
  if (payload.systems && payload.systems.length > 0) {
    lines.push("### Systems of Record\n");
    for (const s of payload.systems) {
      lines.push(`- ${s.tag}: ${s.name} — ${s.purpose}`);
    }
    lines.push("");
  }

  // Export warnings
  if (payload.exportWarnings && payload.exportWarnings.length > 0) {
    lines.push("### Export Warnings\n");
    for (const w of payload.exportWarnings) {
      lines.push(`- ⚠️ ${w.taskId} → ${w.objectiveId}: ${w.message}`);
    }
    lines.push("");
  }

  return lines.join("\n");
}

// ────────────────────────────────────────────
// Auto-seed weekly summary (Improvement #3)
// ────────────────────────────────────────────

/**
 * Generate a synthetic seed weekly summary when no weekly files exist.
 * Uses task and decision data to produce a reasonable starting point.
 * Does NOT hallucinate risks — only infers from decisions.
 */
function generateSeedWeeklySummary(
  tasks: NormalizedTask[],
  objectives: NormalizedObjective[],
  decisions: { id: string; title: string; date: string; decision: string; reason: string; tags: string[] }[]
): NormalizedWeeklySummary {
  // Highlights: top 5 tasks by relevance (or first 5 if no relevance)
  const sortedTasks = [...tasks].sort(
    (a, b) => (b.relevance ?? 0) - (a.relevance ?? 0)
  );
  const topTasks = sortedTasks.slice(0, 5);
  const highlights = topTasks.map(
    (t) => `${t.id}: ${t.title} [${t.status || "Open"}]`
  );

  // Risks: inferred ONLY from decisions (deferred/rejected work)
  const risks = decisions.map(
    (d) => `${d.id}: ${d.title} — ${d.decision || d.reason}`
  );

  // Next focus: top 3 objectives by task count
  const objTaskCount: Record<string, number> = {};
  for (const t of tasks) {
    for (const oid of t.objectiveIds) {
      objTaskCount[oid] = (objTaskCount[oid] || 0) + 1;
    }
  }
  const sortedObjs = objectives
    .map((o) => ({ id: o.id, title: o.title, count: objTaskCount[o.id] || 0 }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 3);
  const nextFocus = sortedObjs.map(
    (o) => `${o.id}: ${o.title} (${o.count} active tasks)`
  );

  // Executive Summary: group top tasks by their Tier-1 objective
  const tier1Objs = objectives.filter((o) => o.tier === 1);
  const execSummary: string[] = [];
  for (const obj of tier1Objs) {
    const relatedTasks = tasks.filter((t) => t.objectiveIds.includes(obj.id));
    if (relatedTasks.length > 0) {
      const taskSummaries = relatedTasks.slice(0, 3).map((t) => t.title).join("; ");
      execSummary.push(`${obj.title}: ${taskSummaries}.`);
    }
  }

  return {
    weekId: "AUTO",
    fileName: "auto-generated-seed.md",
    executiveSummary: execSummary,
    highlights,
    risks,
    nextFocus,
    rawText: "Auto-generated seed summary — no weekly report files were found under 03-reporting/weekly/. This summary was synthesized from current tasks, objectives, and decisions to enable Copilot to produce a report without additional uploads.",
  };
}
