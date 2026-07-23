You are working inside the LapuLapu project.

Objective:
Refactor the Matryoshka system to eliminate ambiguity and enforce the North Star:

"Any workstream member should be able to understand what needs to be done, why it matters, what decisions have been made, who owns it, and what the next action is—without requiring David to explain it."

Use the feedback from:
05-memory/feedback/2026-07-live-test.md

---

# 🔴 PHASE 1 — Define a Strict Item Contract (MANDATORY)

Create a canonical schema for ALL surfaced items:

Required fields:
- id
- title (clear, human-readable)
- type (task / decision / follow-up / risk)
- owner (must NOT default; allow "Unassigned")
- why_it_matters (1 sentence)
- next_action (imperative verb)
- source (meeting / chat / file reference)
- last_updated (timestamp)
- status (green / amber / red with clear rules)
- activity_log (list of updates)

Enforce:
- If any required field is missing → item is excluded from dashboard

---

# 🟠 PHASE 2 — Action Classification (REMOVE “ESCALATE” DEFAULT)

Replace "Escalate" with a structured action system:

Allowed actions:
- DO
- DECIDE
- FOLLOW_UP
- INVESTIGATE
- BLOCKED

Implement logic:
- Classify each item into one of these categories
- If none applies → mark item invalid

---

# 🟡 PHASE 3 — Aging + Relevance Filtering

Implement rules:
- Items >30 days old are hidden unless:
  - explicitly active
  - recently updated

Add:
- aging_days field
- stale flag (true/false)

---

# 🟢 PHASE 4 — Daily Delta System

Add change tracking:
- Compare today vs yesterday snapshot

Surface:
- new items
- updated items
- unchanged items (stale)

Each item must show:
- "Last touched: X days ago"
- "Updated since yesterday: YES/NO"

---

# 🔵 PHASE 5 — Context Linking (Critical)

For every item:
- Link to source artifacts:
  - meeting notes
  - Teams chats
  - files

Add:
- context_summary (auto-generated)
- related_items (IDs)

Goal:
- enable click-through drill-down

---

# 🟣 PHASE 6 — De-duplication + Confidence

Detect duplicate signals:
- merge similar items

Add:
- confidence_score (based on frequency of mentions)
- merged_from (list of IDs)

---

# ⚫ PHASE 7 — Ownership Correction Logic

Remove default ownership behavior.

Rules:
- If owner not explicitly known:
  → set owner = "Unassigned"

Add:
- suggested_owner (if inferred)
- owner_confidence (low/medium/high)

---

# ⚪ PHASE 8 — Reporting Pipeline Fix

Fix weekly reporting workflow:

Eliminate:
- manual file creation
- copy/paste steps

Ensure:
- recap files persist correctly (fix 0-byte issue)
- weekly report is generated directly from structured data

---

# ✅ OUTPUT REQUIREMENTS

Provide:

1. Updated schema definition (JSON or TypeScript)
2. Transformation logic (how raw signals become valid items)
3. Filtering rules implementation
4. Delta tracking implementation approach
5. Example before/after for 3 items
6. Any assumptions clearly stated

Focus on:
- determinism
- clarity
- enforcement (not suggestion)

Do NOT produce high-level ideas only — produce implementable structure and logic.