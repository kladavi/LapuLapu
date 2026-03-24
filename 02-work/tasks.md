# Tasks

## T001 — Audit Moogsoft Correlation Rules for Payment Services
- **Status:** Open
- **Created:** 2026-03-20
- **Objective Chain:** O6 (Monitoring Quality) → O3 (Platform Stability) → O1 (Operational Resilience)
- **Team:** #team-obs
- **Assigned:** J. Santos
- **Systems:** #moogsoft #newrelic
- **Relevance:** 92/100
- **Tags:** #resilience #monitoring #p1-followup
- **Description:** Review and update Moogsoft correlation rules for all payment-related services. Validate that New Relic alerts for the payment gateway are correctly ingested and correlated. Deliver post-incident brief by 2026-03-28.

---

## T002 — Investigate Orphan Azure VMs and CMDB Gaps
- **Status:** Open
- **Created:** 2026-03-22
- **Objective Chain:** O8 (IaC Adoption) → O3 (Platform Stability) → O1 (Operational Resilience)
- **Team:** #team-infra
- **Assigned:** A. Delgado
- **Systems:** #azure #cmdb
- **Relevance:** 78/100
- **Tags:** #azure #cmdb #cost #hygiene
- **Description:** Identify orphan VMs flagged in Q2 Azure cost report. Cross-reference with CMDB records. Decommission or onboard to Terraform state as appropriate. Report cost impact.
