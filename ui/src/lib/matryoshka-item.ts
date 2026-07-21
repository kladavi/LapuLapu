// V4.0 Phase 1: Canonical MatryoshkaItem contract.
//
// This is the SINGLE source of truth for what a decision / risk / follow-up
// looks like once it passes through the V4 emission pipeline. The generator
// (scripts/generate-current-focus.ps1) mirrors these types + validation rules
// in PowerShell as `Test-MatryoshkaItem`.
//
// During the migration window V3.x artifacts (decision-registry.json,
// risk-register.json, david-inbox.json) continue to be emitted. This file
// exists so downstream dashboard code can migrate one tab at a time.

export type MatryoshkaItemType = "task" | "decision" | "follow-up" | "risk";
export type MatryoshkaAction   = "DO" | "DECIDE" | "FOLLOW_UP" | "INVESTIGATE" | "BLOCKED";
export type MatryoshkaStatus   = "green" | "amber" | "red";
export type OwnerConfidence    = "high" | "medium" | "low";

export interface MatryoshkaActivityLogEntry {
  timestamp: string;      // ISO 8601
  event: string;          // "created" | "updated" | "merged" | "status-changed" | "owner-changed"
  from?: string;
  to?: string;
  source?: string;        // path or ref that produced this update
}

export interface MatryoshkaContextMetadata {
  last_mention: string;   // ISO — most recent occurrence in corpus
  last_activity: string;  // ISO — most recent update touching this item
  actors: string[];       // people named in the source context
}

export interface MatryoshkaDelta {
  days_since_last_touched: number;
  updated_since_yesterday: boolean;
  change_summary?: string;
}

export interface MatryoshkaItem {
  // --- IDENTITY ---
  id: string;                        // "MAT-{short-hash}" — deterministic from title+workstream+type
  type: MatryoshkaItemType;
  title: string;                     // ≤140 chars, must NOT start with "Escalate:" / "Todo:" / "Fix:"

  // --- OWNERSHIP (Phase 7) ---
  owner: string;                     // MUST be present; "Unassigned" if unknown
  suggested_owner?: string;
  owner_confidence: OwnerConfidence;

  // --- CONTEXT (Phase 1 core) ---
  why_it_matters: string;            // 1 sentence, MANDATORY, must contain impact signal word
  next_action: string;               // imperative verb sentence, MANDATORY, ≥5 words
  action_class: MatryoshkaAction;
  workstream: string;

  // --- LIFECYCLE ---
  status: MatryoshkaStatus;
  status_reason: string;
  aging_days: number;
  stale: boolean;

  // --- SOURCES + CONTEXT LINKING (Phase 5) ---
  source: string;
  source_uri?: string;
  context_summary: string;           // 2-3 sentences
  context_metadata: MatryoshkaContextMetadata;
  related_items: string[];

  // --- CONFIDENCE + DEDUPE (Phase 6) ---
  confidence_score: number;          // [0,1]
  merged_from: string[];

  // --- HISTORY (Phase 4) ---
  first_seen: string;                // ISO
  last_updated: string;              // ISO
  activity_log: MatryoshkaActivityLogEntry[];

  // --- ENGAGEMENT (Phase 9, rev1) ---
  engaged: boolean;
  engagement_reason: string;

  // --- DELTA (Phase 4) ---
  delta: MatryoshkaDelta;
}

export interface MatryoshkaValidationError {
  itemId: string;
  field: string;
  reason: string;
}

export type MatryoshkaValidationResult =
  | { ok: true;  item: MatryoshkaItem }
  | { ok: false; errors: MatryoshkaValidationError[] };

// ---------------------------------------------------------------------------
// Validation rules — canonical implementation.
// The PowerShell generator mirrors these gates in `Test-MatryoshkaItem`.
// ---------------------------------------------------------------------------

const REQUIRED_FIELDS: (keyof MatryoshkaItem)[] = [
  "id", "type", "title", "owner", "owner_confidence",
  "why_it_matters", "next_action", "action_class",
  "status", "status_reason", "aging_days",
  "source", "context_summary", "confidence_score",
  "first_seen", "last_updated",
];

const APPROVED_VERBS = new RegExp(
  "^\\s*(Send|Ask|Confirm|Decide|Investigate|Deploy|Create|Publish|Write|" +
  "Complete|Finish|Implement|Escalate|Contact|Choose|Approve|Assign|Close|" +
  "Draft|Schedule|Present|Review with|Sign|Verify)\\b",
  "i"
);

const VAGUE_VERBS = /\b(look into|handle|touch base|circle back|keep an eye|check on)\b/i;

const IMPACT_SIGNAL_WORDS = new RegExp(
  "\\b(because|so that|otherwise|risk|impact|blocks|delays|prevents|" +
  "enables|requires|deadline|outcome|drives|unblocks|depends on)\\b",
  "i"
);

const BANNED_TITLE_PREFIX = /^\s*(escalate|todo|fix)\s*:/i;

// V4.0 Sprint 15: reject vague/placeholder why_it_matters strings.
const GENERIC_WHY = /^(needs attention|important issue|follow[- ]up required|see above|tbd|placeholder|no summary( available)?|refer to (context|source)|to be determined|update required|pending)[.!?\s]*$/i;

export function validateItem(candidate: Partial<MatryoshkaItem>, opts?: { whyFingerprints?: Map<string, number> }): MatryoshkaValidationResult {
  const errors: MatryoshkaValidationError[] = [];
  const id = candidate.id ?? "(no-id)";

  for (const f of REQUIRED_FIELDS) {
    const v = (candidate as Record<string, unknown>)[f];
    if (v === undefined || v === null || v === "") {
      // V4.0 Sprint 15: split the missing-why gap into its own error code.
      const fieldLabel = f === "why_it_matters" ? "missing_why_it_matters" : String(f);
      errors.push({ itemId: id, field: fieldLabel, reason: "missing required field" });
    }
  }

  if (candidate.title && candidate.title.length > 140) {
    errors.push({ itemId: id, field: "title", reason: "exceeds 140 chars" });
  }
  if (candidate.title && BANNED_TITLE_PREFIX.test(candidate.title)) {
    errors.push({
      itemId: id,
      field: "title",
      reason: "title must not start with imperative verb (Escalate/Todo/Fix) — that's what action_class is for",
    });
  }

  if (candidate.why_it_matters) {
    const why = candidate.why_it_matters;
    // V4.0 Sprint 15 validator v2: split single 'why_it_matters' error into
    // generic / weak / duplicate sub-categories so the rejection report
    // pinpoints exactly which quality gate failed.
    const isGeneric = GENERIC_WHY.test(why) || why.trim().length < 15;
    if (isGeneric) {
      errors.push({
        itemId: id,
        field: "generic_why_it_matters",
        reason: "matches generic pattern (needs attention / tbd / follow up required) — replace with concrete impact statement",
      });
    }
    const sentences = why.split(/[.!?]/).filter((s) => s.trim().length > 0);
    if (sentences.length > 1) {
      errors.push({ itemId: id, field: "why_it_matters", reason: "must be exactly 1 sentence" });
    }
    if (!isGeneric && !IMPACT_SIGNAL_WORDS.test(why)) {
      errors.push({
        itemId: id,
        field: "weak_why_it_matters",
        reason: "must contain an impact/dependency signal word (because / so that / otherwise / risk / impact / blocks / delays / outcome)",
      });
    }
    // Duplicate check: was this exact string seen 2+ times in the corpus?
    if (opts?.whyFingerprints) {
      const fp = why.trim().toLowerCase();
      const count = opts.whyFingerprints.get(fp) ?? 0;
      if (count >= 2) {
        errors.push({
          itemId: id,
          field: "duplicate_why_it_matters",
          reason: `shares why_it_matters with ${count - 1} other item(s) — each item needs a specific impact statement`,
        });
      }
    }
  }

  if (candidate.next_action) {
    const words = candidate.next_action.trim().split(/\s+/).filter(Boolean);
    if (words.length < 5) {
      errors.push({ itemId: id, field: "next_action", reason: "must be at least 5 meaningful words" });
    }
    if (!APPROVED_VERBS.test(candidate.next_action)) {
      errors.push({
        itemId: id,
        field: "next_action",
        reason: "must start with an approved imperative verb (Send/Ask/Confirm/Decide/Investigate/Deploy/Create/Publish/Write/Complete/Finish/Implement/Escalate/Contact/Choose/Approve/Assign/Close/Draft/Schedule/Present/Sign/Verify)",
      });
    }
    if (VAGUE_VERBS.test(candidate.next_action)) {
      errors.push({
        itemId: id,
        field: "next_action",
        reason: "contains vague verb (look into / handle / touch base / circle back / keep an eye / check on) — replace with concrete action",
      });
    }
  }

  if (typeof candidate.confidence_score === "number") {
    if (candidate.confidence_score < 0 || candidate.confidence_score > 1) {
      errors.push({ itemId: id, field: "confidence_score", reason: "must be in [0,1]" });
    }
  }

  if (candidate.aging_days !== undefined && candidate.aging_days < 0) {
    errors.push({ itemId: id, field: "aging_days", reason: "must be non-negative" });
  }

  return errors.length === 0
    ? { ok: true,  item: candidate as MatryoshkaItem }
    : { ok: false, errors };
}

// Convenience: shape returned by the generator's rejected-items.json artifact.
export interface RejectedItemsReport {
  generated: string;               // ISO
  generator: string;
  version: string;
  totals: {
    candidates: number;
    accepted: number;
    rejected: number;
    byField: Record<string, number>;
  };
  rejections: Array<{
    itemId: string;
    itemKind: string;              // "decision" | "risk"
    title: string;
    workstream?: string;
    owner?: string;
    errors: MatryoshkaValidationError[];
  }>;
}
