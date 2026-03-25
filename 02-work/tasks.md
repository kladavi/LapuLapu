# Tasks

## T001 — Audit Moogsoft Correlation Rules for Payment Services
- **Status:** Open
- **Created:** 2026-03-20
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team:obs
- **Assigned:** J. Santos
- **Systems:** #system:moogsoft #system:newrelic
- **Relevance:** 92/100
- **Tags:** #outcome:resilience #worktype:monitoring #severity:p1-followup
- **Description:** Review and update Moogsoft correlation rules for all payment-related services. Validate that New Relic alerts for the payment gateway are correctly ingested and correlated. Deliver post-incident brief by 2026-03-28.

---

## T002 — Investigate Orphan Azure VMs and CMDB Gaps
- **Status:** Open
- **Created:** 2026-03-22
- **Objective Chain:** B-6 (IT Asset Management & Evergreen Migration) → O4 (Robust Technical Core)
- **Team:** #team:infra
- **Assigned:** A. Delgado
- **Systems:** #system:azure #system:cmdb
- **Relevance:** 78/100
- **Tags:** #system:azure #system:cmdb #domain:cost #worktype:hygiene
- **Description:** Identify orphan VMs flagged in Q2 Azure cost report. Cross-reference with CMDB records. Decommission or onboard to Terraform state as appropriate. Report cost impact.

---

## T003 — Rapid Recovery Plan (R2R Deliverable)
- **Status:** Open
- **Created:** 2026-03-24
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team:gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #system:cmdb
- **Relevance:** 80/100
- **Tags:** #program:r2r #outcome:resilience #worktype:incident-management
- **Description:** Deliver Rapid Recovery Plans as a key R2R deliverable for FY2026. Plans will define recovery procedures for Gold applications to meet RTO/RPO targets and reduce P1 MTTR. Format and template to be confirmed with Rohina.

---

## T004 — Digital Property Dashboarding
- **Status:** Open
- **Created:** 2026-03-24
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team:gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #system:newrelic #system:adobe
- **Relevance:** 80/100
- **Tags:** #program:r2r #domain:digital #worktype:monitoring #artifact:dashboard
- **Description:** Deliver digital property dashboarding for customer-facing applications. Metrics defined by Deloitte; measurement tooling from Adobe and New Relic being implemented, targeted for end of FY2026. Enables 360 customer experience monitoring and trend analysis.

---

## T005 — OMM L2 for Gold Applications
- **Status:** Open
- **Created:** 2026-03-24
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team:gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #system:newrelic #system:moogsoft #system:xmatters #system:cmdb #system:apm
- **Relevance:** 85/100
- **Tags:** #program:r2r #program:omm #worktype:observability
- **Description:** Achieve OMM L2 maturity for all Gold applications by mid-FY2027. Requires infrastructure alerts with AIOps reconciliation, application transaction alerts via xMatters, synthetics monitoring with login checks, and application logging into ADX with pattern alerts.

---

## T006 — Employee Experience Dashboard (Production)
- **Status:** Open
- **Created:** 2026-03-24
- **Objective Chain:** B-1 (Endpoint Monitoring & Post-Change Verification) → O1 (Frictionless Customer Experience)
- **Team:** #team:ets-japan
- **Assigned:** David Klan
- **Systems:** #system:newrelic
- **Relevance:** 85/100
- **Tags:** #team:ets-japan #artifact:dashboard #worktype:monitoring #worktype:observability
- **Description:** Establish a single, authoritative Employee Experience Dashboard providing production application availability and performance visibility from a Japan employee perspective. Daily readiness confirmation before 8:00 AM JST. Success measured by 100% coverage of employee-facing URLs.

---

## T007 — Developer Experience Dashboard (Non-Production)
- **Status:** Open
- **Created:** 2026-03-24
- **Objective Chain:** B-1 (Endpoint Monitoring & Post-Change Verification) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** David Klan
- **Systems:** #system:newrelic
- **Relevance:** 80/100
- **Tags:** #team:ets-japan #artifact:dashboard #domain:non-production #worktype:monitoring #outcome:developer-experience
- **Description:** Establish a Developer Experience Dashboard providing holistic visibility into non-production environment health for developers and testers in Japan. Daily pre-8:00 AM JST readiness check. Measurable reduction in time lost to environment investigation.

---

## T008 — Epsilon Upgrade POT: Server Provisioning & Environment Setup
- **Status:** Open
- **Created:** 2026-03-25
- **Objective Chain:** B-7 (PPS Service Improvement) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Balaji Ravi
- **Systems:** #system:ingenium #system:azure
- **Relevance:** 85/100
- **Tags:** #program:epsilon #system:ingenium #domain:modernisation #domain:infrastructure #worktype:pot
- **Description:** Provision POT servers and configure the three-tier architecture for the Epsilon Upgrade proof of technology. Includes POT subscription and access setup, server provisioning, and base infrastructure readiness. Requires coordination with ETS Unix and DB Engineering teams.

---

## T009 — Epsilon Upgrade POT: Database & Middleware Installation
- **Status:** Open
- **Created:** 2026-03-25
- **Objective Chain:** B-7 (PPS Service Improvement) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Balaji Ravi
- **Systems:** #system:ingenium #system:azure
- **Relevance:** 85/100
- **Tags:** #program:epsilon #system:ingenium #domain:modernisation #domain:database #domain:middleware #worktype:pot
- **Description:** Install and configure the database layer and all middleware components (WAS, CICS, CTG, COBOL, Batch, SFTP) for the Epsilon three-tier architecture POT. Configure ALB setup and VCS/DB native HA. Deploy application and verify baseline functionality.

---

## T010 — Epsilon Upgrade POT: Validation & Failover Testing
- **Status:** Open
- **Created:** 2026-03-25
- **Objective Chain:** B-7 (PPS Service Improvement) → B-4 (Infrastructure Resilience & DR) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Balaji Ravi
- **Systems:** #system:ingenium #system:azure
- **Relevance:** 88/100
- **Tags:** #program:epsilon #system:ingenium #domain:modernisation #worktype:testing #outcome:ha #worktype:pot
- **Description:** Execute the full POT validation plan: application and policy-level workflow testing, zone-level failover testing across presentation, middleware, and data layers, VCS and Pacemaker verification, batch execution testing, and online patching testing.

---

## T011 — Epsilon Upgrade: Stakeholder Alignment & Formal Announcement
- **Status:** Open
- **Created:** 2026-03-25
- **Objective Chain:** B-7 (PPS Service Improvement) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** David Klan
- **Systems:** #system:ingenium
- **Relevance:** 75/100
- **Tags:** #program:epsilon #system:ingenium #domain:modernisation #worktype:stakeholder #worktype:coordination
- **Description:** Formally announce the Epsilon POT plan to the wider team. Secure stakeholder commitment from ETS Unix, DB Engineering/BAU, and Ingenium Infrastructure teams. Drive alignment on timelines for VM provisioning and resource availability.