# Copilot Pack Config

## Intended Audience
- Birger Fjaellman — Head of ETS Japan
- Hari Pothakamuri — Head of Technology / GOCC
- Kelvin Leung — Head of ETS Region
- Jonan Tan Pangan — Lead, GOCC Monitoring
- Debamalya Das — Lead, GOCC Observability
- Balaji Ravi — ETS Japan (Ingenium / PPS)

**Author:** David Klan (ETS Japan)

## Context Contract
- **Audience:** Executive and delivery leads for ETS Japan, GOCC, and Observability.
- **Decision authority:** Visibility and prioritisation only — no funding or scope approval.
- **Temporal scope:** Data is current as of the export timestamp in the YAML frontmatter.
- **Data scope:** This pack is a point-in-time snapshot. Missing items should be treated as unknown, not assumed absent. If something is not present, it may simply not have been registered yet.

## Delivery Area Taxonomy (Lapu-Lapu)

Weekly reports for `#project:lapu-lapu` are grouped by **delivery area**. Every task and key result that belongs to a delivery area must carry the matching canonical tag:

| Delivery Area | Canonical Tag | Classification keywords |
|---|---|---|
| ADX Registration | `#area:adx-registration` | "ADX", "Azure Data Explorer" |
| CMDB Mapping | `#area:cmdb-mapping` | "CMDB" (mapping / gap / relationships / CI structure) |
| Employee XP Dashboard | `#area:employee-xp` | "Employee Experience", "Employee XP" |
| Dev XP Dashboard | `#area:dev-xp` | "Developer Experience", "Dev XP", non-prod monitoring |
| GOCC Transition | `#area:gocc-transition` | "PS-to-GOCC", "GOCC handover", "GOCC onboarding", "KT", "Shadow", "Reverse-Shadow", "scaffolding pack" |
| MMM L2 | `#area:mmm-l2` | "MMM", "OMM" (legacy), "Observability Maturity" |
| Patching | `#area:patching` | "patching", "patch cycle" |
| Rapid Recovery | `#area:rapid-recovery` | "Rapid Recovery", "RRP", "R2R", "recovery plan" |

A single task may carry multiple `#area:*` tags when work spans areas (e.g. CMDB Mapping enabling Rapid Recovery). Tasks tagged only `#project:epsilon` (no Lapu-Lapu area) are out of scope for the Lapu-Lapu weekly report.

## How Copilot Should Behave
1. **Start with a 1-page executive weekly report.** Group progress by Tier-1 objective, highlight risks, and list deferred work.
2. **Ask 5 clarifying questions** before expanding or refining any section.
3. **Provide an index** of objectives and top workstreams sorted by relevance.
4. **When information is missing:** Explicitly state "not present in file" and propose what data to request next.
5. **Never invent metrics or facts.** Only reference data contained in this pack.
6. **Respect the objective hierarchy.** Always trace tasks → Tier-2 → Tier-1 when reporting progress.

## Starter Prompts (Copy/Paste)

### For Executives (Birger, Hari, Kelvin)
1. "Produce a 1-page weekly executive summary grouped by Tier-1 objective. Include risks and next-week focus."
2. "Show me all Tier-2 objectives under O4 (Robust Technical Core) with their linked tasks and current status."
3. "Which objectives have no active tasks this week? Flag any gaps."
4. "Summarise the Epsilon Upgrade POT status — tasks, risks, and stakeholder readiness."

### For GOCC Leads (Jonan, Deb)
5. "List all tasks assigned to GOCC-Observability and GOCC-Monitoring with their objective alignment."
6. "What is the current OMM L2 maturity status for Gold applications? What remains to be done?"
7. "Show me all tasks linked to H-3 (AI Ops) and H-4 (Unified Support) with progress notes."

### For ETS Japan (Balaji, David)
8. "List all ETS Japan tasks with their Tier-2 objective alignment and current status."
9. "Summarise the Ingenium modernisation workstream — what has been proposed, what is pending stakeholder alignment?"
10. "Show the Employee Experience and Developer Experience dashboard tasks with completion criteria and blockers."
