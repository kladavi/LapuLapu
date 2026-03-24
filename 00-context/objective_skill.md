# Skill: Objectives Registry CRUD

**File under management:** `00-context/objectives.md`
**Applies to:** All agents that read, create, update, or delete content in `objectives.md`

> **MANDATORY:** Read this file in full before performing any operation on `objectives.md`.

---

## 1. Guarding Principles

1. `objectives.md` is the authoritative source of truth. No task, decision, or report may reference an objective that does not exist here.
2. All content must be traceable to a named source document and slide. Do not invent objectives.
3. IDs are permanent. Once assigned, an ID is never reused, renumbered, or reassigned — even after deletion.
4. Tier-2 entries are owner-scoped. Only add Tier-2 objectives for the named owner. Do not infer ownership.
5. Ownership changes must be explicit. You may only update an owner field if the requestor provides a document reference.

---

## 2. ID Conventions

| Tier | Prefix | Format | Example |
|---|---|---|---|
| Tier-1 (Company) | `O` | `O` + sequential integer | `O1`, `O2`, `O7` |
| Tier-2 (Hari Pothakamuri) | `H-` | `H-` + sequential integer | `H-1`, `H-2`, `H-5` |

**Rules:**
- Always check the existing file for the highest current ID before assigning the next one.
- IDs increment globally within their prefix — never reset.
- If an objective is deleted, its ID is retired. Leave a tombstone comment: `<!-- O7 retired YYYY-MM-DD: reason -->` at the point of deletion.

---

## 3. Required Section Format

Every objective block MUST contain all of the following fields in this exact order:

```markdown
### <ID> — <Objective Title>

tags: #objective #tier1|#tier2 [additional tags]

**Source**
- Slide X (document name — section name)

**Parent Objective**
- <ID> (<Title>) [OMIT this field for Tier-1 objectives]

**Description**
[One concise paragraph. Use wording faithful to the source document.]

**Explicit Commitments / Outcomes**
- [Bullet. Source-faithful only.]
- [Bullet.]
```

**Violations that must be rejected:**
- A block missing any required field.
- A `**Parent Objective**` field on a Tier-1 objective.
- A Tier-2 block without a `**Parent Objective**` field.
- A `**Source**` field without a slide number.
- Tags missing `#objective` and either `#tier1` or `#tier2`.

---

## 4. Tagging Rules

| Condition | Required Tags |
|---|---|
| All objectives | `#objective` |
| Tier-1 | `#tier1` |
| Tier-2 (Hari) | `#tier2` `#hari` |
| References Moogsoft | `#moogsoft` |
| References New Relic | `#newrelic` |
| References Batch automation | `#batch` |
| References AIOps | `#aiops` |
| References Unified Support / GOCC | `#unified-support` |
| Discovery-only commitment | `#discovery` |

Add additional system or theme tags only when the source document explicitly names the system or theme.

---

## 5. CREATE — Adding a New Objective

**Pre-conditions:**
1. You have a named source document and slide number.
2. The objective belongs to a tier already represented in the file (`Tier-1` or `Tier-2 — Hari Pothakamuri`).
3. For Tier-2: the owner is explicitly listed in the source document as Hari Pothakamuri (sole or co-owner).

**Steps:**
1. Read `objectives.md` in full.
2. Determine the next available ID for the applicable prefix.
3. Draft the full block using the format in Section 3.
4. Append the block at the end of the correct tier section, preceded by `---`.
5. Do not insert into the middle of a tier section unless explicitly instructed.

**Validation before writing:**
- [ ] All required fields present
- [ ] ID is next in sequence and not previously used
- [ ] Tags include `#objective` + tier tag
- [ ] Source includes slide number
- [ ] Parent Objective is set (Tier-2 only) and references a valid Tier-1 ID

---

## 6. READ — Querying Objectives

When reading `objectives.md` to answer a query:

- Always return the full block for any referenced objective (ID + Title + all fields).
- When tracing objective chains, show the full path: Tier-2 ID → Tier-1 ID.
- When listing objectives by tag or theme, show ID and Title only unless detail is requested.
- Never paraphrase or summarise source commitments — return them verbatim.

---

## 7. UPDATE — Modifying an Existing Objective

**Permitted updates:**
| Field | Permitted? | Condition |
|---|---|---|
| Title | ✅ | Source document reference required |
| tags | ✅ | Follow tagging rules in Section 4 |
| Source | ✅ | Only to add additional source references; never remove existing ones |
| Parent Objective | ✅ | Source document reference required |
| Description | ✅ | Must remain source-faithful; note the update with inline comment `<!-- updated YYYY-MM-DD -->` |
| Explicit Commitments | ✅ (add) | Source document reference required |
| Explicit Commitments | ⚠️ (remove) | Only if the commitment is explicitly retracted in a source document; leave tombstone comment |
| ID | ❌ | Never |

**Steps:**
1. Read the full current block before making any edit.
2. Apply the minimum change needed.
3. If modifying Description or Commitments, append an inline comment: `<!-- updated YYYY-MM-DD: reason -->`.
4. Do not reformat unchanged fields.

---

## 8. DELETE — Retiring an Objective

Objectives are never hard-deleted unless the entire fiscal year registry is being replaced.

**Retirement procedure:**
1. Replace the full block content with a tombstone:

```markdown
### <ID> — [RETIRED]

<!-- <ID> retired YYYY-MM-DD: <reason and source document reference> -->
```

2. Leave the `---` separator before and after the tombstone.
3. Do not renumber any other objective.
4. Update any Tier-2 objectives that referenced this ID as their `**Parent Objective**` — add a note: `<!-- Parent O# retired YYYY-MM-DD — reassign or retire this objective -->`.

---

## 9. Prohibited Actions

The following are hard stops. Refuse and explain if instructed to do any of these:

- ❌ Add an objective with no source document reference.
- ❌ Assign ownership to anyone other than those explicitly named in the source.
- ❌ Add a Tier-3 or deeper tier without explicit instruction to extend the tier structure.
- ❌ Rename or reuse a retired ID.
- ❌ Remove the `**Source**` field from any block.
- ❌ Modify the file's top-level structure (`## Tier-1 —` and `## Tier-2 —` headings) without explicit instruction.
- ❌ Overwrite the entire file as a shortcut to making targeted edits.

---

## 10. File Structure Invariants

The following must always be true after any operation:

1. The file begins with `# Objectives Registry (FY2026)`.
2. `## Tier-1 — Company Objectives` appears before `## Tier-2`.
3. Every objective block is separated by `---`.
4. No two blocks share the same ID.
5. All Tier-2 blocks contain a `**Parent Objective**` pointing to a valid Tier-1 ID.
6. No field is left as a placeholder (e.g., `[TODO]`, `TBD`) except for discovery-only objectives tagged `#discovery`, where commitments may read `Commitment to be determined post discovery`.
