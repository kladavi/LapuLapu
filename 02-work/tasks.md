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

---

## T003 — Rapid Recovery Plan (R2R Deliverable)
- **Status:** Open
- **Created:** 2026-03-24
- **Objective Chain:** O4 (Robust Technical Core) → O1 (Frictionless Customer Experience)
- **Team:** #team-gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #cmdb
- **Tags:** #r2r #resilience #incident-management
- **Description:** Deliver Rapid Recovery Plans as a key R2R deliverable for FY2026. This workstream is managed by the Incident Management team. Plans will define recovery procedures for Gold applications to meet RTO/RPO targets and reduce P1 MTTR. Format and template to be confirmed with Rohina. Previously registered as objective D-1.

---

## T004 — Digital Property Dashboarding
- **Status:** Open
- **Created:** 2026-03-24
- **Objective Chain:** O1 (Frictionless Customer Experience)
- **Team:** #team-gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #newrelic #adobe
- **Tags:** #r2r #digital #monitoring #dashboards
- **Description:** Deliver digital property dashboarding for customer-facing applications. Metrics have been defined by Deloitte; measurement tooling from Adobe and New Relic is being implemented, with completion targeted by end of FY2026. Enables 360 customer experience monitoring and trend analysis for top digital properties. Previously registered as objective D-2.

---

## T005 — OMM L2 for Gold Applications
- **Status:** Open
- **Created:** 2026-03-24
- **Objective Chain:** O4 (Robust Technical Core) → O1 (Frictionless Customer Experience)
- **Team:** #team-gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #newrelic #moogsoft #xmatters #cmdb #apm
- **Tags:** #r2r #omm #observability
- **Description:** Achieve OMM L2 maturity for all Gold applications by mid-FY2027, with implementation activities running through FY2026. OMM L2 requires infrastructure alerts under standard policy with reconciliation in AIOps tools (Moogsoft), application transaction alerts routed through xMatters, synthetics monitoring with login checks, and application logging into ADX with pattern alerts. Measurement via in-house tool being developed by architecture team. Previously registered as objective D-3.

---

## T006 — Employee Experience Dashboard (Production)
- **Status:** Open
- **Created:** 2026-03-24
- **Objective Chain:** O4 (Robust Technical Core) → O3 (Outstanding Colleague Experience)
- **Team:** #team-ets-japan
- **Assigned:** David Klan
- **Systems:** #newrelic
- **Tags:** #ets-japan #dashboard #production #monitoring #observability
- **Description:** Establish a single, authoritative Employee Experience Dashboard providing production application availability and performance visibility from a Japan employee perspective. Coverage spans Bronze, Silver, and Gold applications including critical international dependencies. Daily readiness confirmation before 8:00 AM JST. Success measured by 100% coverage of employee-facing URLs, reduced executive noise, and increased confidence in Japan operational readiness. Previously registered as objective K-1.

---

## T007 — Developer Experience Dashboard (Non-Production)
- **Status:** Open
- **Created:** 2026-03-24
- **Objective Chain:** O3 (Outstanding Colleague Experience) → O4 (Robust Technical Core)
- **Team:** #team-ets-japan
- **Assigned:** David Klan
- **Systems:** #newrelic
- **Tags:** #ets-japan #dashboard #non-production #monitoring #developer-experience
- **Description:** Establish a Developer Experience Dashboard providing holistic visibility into non-production environment health for developers and testers in Japan. Daily pre-8:00 AM JST readiness check ensures issues are surfaced and owned before they block work. Measurable reduction in time lost to environment investigation. Improved developer and tester productivity. Previously registered as objective K-2.

---

## T008 — Epsilon Upgrade POT: Server Provisioning & Environment Setup
- **Status:** Open
- **Created:** 2026-03-25
- **Objective Chain:** B-7 (PPS Service Improvement) → O4 (Robust Technical Core)
- **Team:** #team-ets-japan
- **Assigned:** Balaji Ravi
- **Systems:** #ingenium #azure
- **Relevance:** 85/100
- **Tags:** #epsilon #ingenium #modernisation #infrastructure #pot
- **Description:** Provision POT servers and configure the three-tier architecture (presentation, middleware, database layers) for the Epsilon Upgrade proof of technology. Includes POT subscription and access setup, server provisioning, and base infrastructure readiness. Requires coordination with ETS Unix and DB Engineering teams. Source: 90-assets/epsilon_project.md.

---

## T009 — Epsilon Upgrade POT: Database & Middleware Installation
- **Status:** Open
- **Created:** 2026-03-25
- **Objective Chain:** B-7 (PPS Service Improvement) → O4 (Robust Technical Core)
- **Team:** #team-ets-japan
- **Assigned:** Balaji Ravi
- **Systems:** #ingenium #azure
- **Relevance:** 85/100
- **Tags:** #epsilon #ingenium #modernisation #database #middleware #pot
- **Description:** Install and configure the database layer and all middleware components (WAS, CICS, CTG, COBOL, Batch, SFTP) for the Epsilon three-tier architecture POT. Configure ALB setup and VCS/DB native HA. Deploy application and verify baseline functionality. Source: 90-assets/epsilon_project.md.

---

## T010 — Epsilon Upgrade POT: Validation & Failover Testing
- **Status:** Open
- **Created:** 2026-03-25
- **Objective Chain:** B-7 (PPS Service Improvement) → B-4 (Infrastructure Resilience & DR) → O4 (Robust Technical Core)
- **Team:** #team-ets-japan
- **Assigned:** Balaji Ravi
- **Systems:** #ingenium #azure
- **Relevance:** 88/100
- **Tags:** #epsilon #ingenium #modernisation #testing #ha #pot
- **Description:** Execute the full POT validation plan: application and policy-level workflow testing, zone-level failover testing across presentation, middleware, and data layers, VCS and Pacemaker verification, batch execution testing, and online patching testing. Analyse POT feedback and produce recommendations for Q3/Q4 planning. Source: 90-assets/epsilon_project.md.

---

## T011 — Epsilon Upgrade: Stakeholder Alignment & Formal Announcement
- **Status:** Open
- **Created:** 2026-03-25
- **Objective Chain:** B-7 (PPS Service Improvement) → O4 (Robust Technical Core)
- **Team:** #team-ets-japan
- **Assigned:** David Klan
- **Systems:** #ingenium
- **Relevance:** 75/100
- **Tags:** #epsilon #ingenium #modernisation #stakeholder #coordination
- **Description:** Formally announce the Epsilon POT plan to the wider team. Secure stakeholder commitment from ETS Unix, DB Engineering/BAU, and Ingenium Infrastructure (Modernization) teams. Drive alignment on timelines for VM provisioning and resource availability. Source: 90-assets/epsilon_project.md.
