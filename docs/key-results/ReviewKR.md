# Key Results Review — Tier-1 Suggestions

**Date:** 2026-04-06
**Reviewer:** LapuLapu PM System
**Scope:** All 54 registered tasks, 6 Tier-1 objectives, 11 Tier-2 objectives

---

## Current Registered KRs

| ID | Title | Objective | Metric | Target | Current | Progress |
|----|-------|-----------|--------|--------|---------|----------|
| KR001 | Employee Experience Dashboard | O1 | Numeric | 88 | 58 | ~66% |
| KR002 | Developer Experience Dashboard | O4 | Numeric | 180 | 16 | ~9% |

Both existing KRs are task-level measures (dashboard URL counts) linked to Tier-1. Good operational KRs but narrow in scope — they track one deliverable each rather than the broader Tier-1 completion criteria.

---

## Suggested Tier-1 Key Results

### O1 — Frictionless Customer Experience (21 tasks)

**Existing KRs:** KR001 (Employee Experience Dashboard)

| Suggested KR | Type | Start | Target | Rationale | Related Tasks |
|-------------|------|-------|--------|-----------|---------------|
| **Japan OMM L2 Application Coverage** — Number of major Japan applications achieving OMM Level 2 maturity | Numeric | 0 | 8 | O1 completion criteria: "360 customer experience monitoring live for all top digital properties." OMM L2 is the concrete path to get there. | T005, T027 |
| **Moogsoft Correlation Rule Coverage** — % of payment-related services with validated correlation rules | Numeric | 0 | 100 | O1 criteria: "Predictive monitoring with dynamic thresholding deployed for critical services." Correlation rules are the foundation. | T001, T012, T034 |
| **Japan Monitoring Governance Cadence Established** — Recurring governance review operational with documented cadence | Boolean | 0 | 1 | Ensures sustained monitoring quality. Without governance, monitoring gains decay. | T022, T035 |
| **Japan Alert Coverage Gap Remediation** — % of identified alert gaps with remediation applied | Numeric | 0 | 100 | Directly measures proactive issue detection capability — core to "frictionless." | T032, T026, T028, T030 |
| **Incident Process Standardization** — Number of standardised incident artefacts delivered (templates, escalation procedures, problem tickets) | Numeric | 0 | 4 | Reduces MTTR through consistent process — supports P1 MTTR <2.5 hrs target. | T039, T040, T042, T043 |

---

### O4 — Robust Technical Core (33 tasks)

**Existing KRs:** KR002 (Developer Experience Dashboard)

| Suggested KR | Type | Start | Target | Rationale | Related Tasks |
|-------------|------|-------|--------|-----------|---------------|
| **Japan Patching Cycle Achievement** — Patching cadence reduced to ≤14 days for non-batch applications | Boolean | 0 | 1 | O4 criteria: "Cloud Evergreen program completed." 14-day patching is the regional commitment. | T017, T019, T020, T050, T051 |
| **Rapid Recovery Plan Coverage** — Number of Japan Gold applications with documented recovery plans | Numeric | 0 | 5 | O4 criteria: "Portfolio Health for Gold Apps ≥80%." Recovery plans are a prerequisite. | T003, T041 |
| **Epsilon POT Milestone Completion** — Number of POT milestones completed (provision, DB/MW install, validation, failover, VCS, access) | Numeric | 0 | 6 | B-7 is the largest task cluster under O4 (7 tasks). POT is a gate to the full upgrade. | T008, T009, T010, T036, T037, T038 |
| **Ingenium GOCC Transition Readiness** — % of Ingenium runbooks validated and handed over to GOCC | Numeric | 0 | 100 | O4 criteria: "Incidents reported by Monitoring >60%." GOCC handover is the enabler. | T045, T046, T047, T048, T049 |
| **Observability-as-Code Adoption** — Number of monitoring-as-code policies/repos operationalised | Numeric | 0 | 3 | O4 criteria: "Excel at architectural basics at scale, build software for re-use." | T029, T031, T033, T054 |
| **Orphan VM & CMDB Gap Remediation** — Number of orphan VMs decommissioned or onboarded to Terraform | Numeric | 0 | 20 | O4 criteria: "IRM Composite Score ≥95%." Asset hygiene is foundational to IRM. | T002, T018 |

---

### O2 — Dynamic Delivery Experience (0 tasks)

**No tasks currently registered.** Tier-2 objective B-3 (Pipeline Standardization) chains to O2 but has no tasks yet.

| Suggested KR | Type | Start | Target | Rationale | Related Tasks |
|-------------|------|-------|--------|-----------|---------------|
| **Pipeline Standardization Completion** — % of deployment pipelines fully parameterised and stored in code repository | Numeric | 0 | 100 | O2 criteria: "Change Success Rate >98.5%." Standardised pipelines reduce change failures. | *(needs tasks from B-3)* |

---

### O3 — Outstanding Colleague Experience (0 tasks)

**No tasks currently registered.** No Tier-2 objectives chain to O3 in the current registry.

| Suggested KR | Type | Start | Target | Rationale | Related Tasks |
|-------------|------|-------|--------|-----------|---------------|
| **Key Technology Irritants Removed** — Number of colleague-reported technology irritants resolved | Numeric | 0 | 5 | O3 criteria: "Key colleague technology irritants removed." | *(needs tasks)* |

> **Note:** KR002 (Developer Experience Dashboard) was originally linked to O3 but was re-linked to O4 because all related tasks chain through B-1 → O4. If you want colleague-experience coverage, consider creating a separate KR under O3 for DX as a colleague satisfaction metric.

---

### O5 — Future-Ready Talent (0 tasks)

**No tasks currently registered.**

| Suggested KR | Type | Start | Target | Rationale | Related Tasks |
|-------------|------|-------|--------|-----------|---------------|
| **Team Upskilling Milestones** — Number of team members completing AI/observability upskilling modules | Numeric | 0 | 10 | O5 criteria: "Manulife University scaled for digital and AI upskilling." | *(needs tasks)* |

---

### O6 — Technology Transformation through AI & Automation (0 direct tasks)

Tasks exist under Tier-2 H-1, H-3, H-4 which chain to O6, but no tasks chain *directly* to O6.

| Suggested KR | Type | Start | Target | Rationale | Related Tasks |
|-------------|------|-------|--------|-----------|---------------|
| **GOCC Automation Use Cases Deployed** — Number of GOCC operational automation use cases live (restart, health check, patching, password cycling) | Numeric | 0 | 4 | O6 criteria: "GOCC incident management automation deployed." H-4 tasks feed this. | T016, T047, T049 |
| **Batch Automation Migration** — Number of manual batch processes migrated to cloud-based solutions | Numeric | 0 | 3 | O6 criteria: "KLO automation operational." H-1 is the key Tier-2. | *(needs tasks from H-1)* |

---

## Priority Recommendations

Based on task density and strategic impact, the recommended first registrations are:

| Priority | Suggested KR | Objective | Why |
|----------|-------------|-----------|-----|
| 🔴 High | Japan OMM L2 Application Coverage | O1 | 16 tasks feed H-3→O1; OMM L2 is the clearest O1 success measure |
| 🔴 High | Japan Patching Cycle Achievement | O4 | 8 tasks on patching; directly maps to O4 Evergreen criteria |
| 🟠 Medium | Epsilon POT Milestone Completion | O4 | 7 tasks, large effort, needs tracking; POT gates the full upgrade |
| 🟠 Medium | Ingenium GOCC Transition Readiness | O4 | 5 approved tasks; time-sensitive handover work |
| 🟡 Lower | Incident Process Standardization | O1 | 4 tasks; important but smaller scope |
| 🟡 Lower | Observability-as-Code Adoption | O4 | 4 tasks; emerging capability, longer horizon |

---

## Coverage Gap Summary

| Objective | Tasks | Existing KRs | Suggested KRs | Gap |
|-----------|-------|-------------|---------------|-----|
| O1 | 21 | 1 (KR001) | 5 | Needs broader coverage beyond dashboards |
| O2 | 0 | 0 | 1 | No tasks yet — pipeline work needs scoping |
| O3 | 0 | 0 | 1 | No tasks or Tier-2 objectives registered |
| O4 | 33 | 1 (KR002) | 6 | Largest task count, most diverse work streams |
| O5 | 0 | 0 | 1 | Talent objectives not yet operationalised |
| O6 | 0 direct | 0 | 2 | H-1/H-4 tasks exist but no direct O6 tracking |
