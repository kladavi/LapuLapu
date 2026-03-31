# Tasks

## T001 — Audit Moogsoft Correlation Rules for Payment Services
- **Status:** Open
- **Created:** 2026-03-20
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team:obs
- **Assigned:** J. Santos
- **Systems:** #system:moogsoft #system:newrelic
- **Relevance:** 92/100
- **Tags:** #project:lapu-lapu #outcome:resilience #worktype:monitoring #severity:p1-followup
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
- **Tags:** #project:lapu-lapu #system:azure #system:cmdb #domain:cost #worktype:hygiene
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
- **Tags:** #project:lapu-lapu #program:r2r #outcome:resilience #worktype:incident-management
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
- **Tags:** #project:lapu-lapu #program:r2r #domain:digital #worktype:monitoring #artifact:dashboard
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
- **Tags:** #project:lapu-lapu #program:r2r #program:omm #worktype:observability
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
- **Tags:** #project:lapu-lapu #team:ets-japan #artifact:dashboard #worktype:monitoring #worktype:observability
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
- **Tags:** #project:lapu-lapu #team:ets-japan #artifact:dashboard #domain:non-production #worktype:monitoring #outcome:developer-experience
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
- **Tags:** #project:epsilon #program:epsilon #system:ingenium #domain:modernisation #domain:infrastructure #worktype:pot
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
- **Tags:** #project:epsilon #program:epsilon #system:ingenium #domain:modernisation #domain:database #domain:middleware #worktype:pot
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
- **Tags:** #project:epsilon #program:epsilon #system:ingenium #domain:modernisation #worktype:testing #outcome:ha #worktype:pot
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
- **Tags:** #project:epsilon #program:epsilon #system:ingenium #domain:modernisation #worktype:stakeholder #worktype:coordination
- **Description:** Formally announce the Epsilon POT plan to the wider team. Secure stakeholder commitment from ETS Unix, DB Engineering/BAU, and Ingenium Infrastructure teams. Drive alignment on timelines for VM provisioning and resource availability.

---

## T012 — Obtain ePOS Health Check Script Details from PS Team
- **Status:** Open
- **Created:** 2026-03-26
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team:ets-japan
- **Assigned:** David Klan
- **Systems:** #system:newrelic #system:cmdb
- **Relevance:** 85/100
- **Tags:** #project:lapu-lapu #worktype:monitoring #domain:gocc-handover #system:epos #worktype:observability
- **Description:** Obtain details of the ePOS health check script used by PS (Manulink batch process). Follow up with Yamamoto-san, Murata-san, and Nakatsu-san. GOCC will need visibility or access to this process for sustainable monitoring handover. Deliver documentation of script purpose, authentication flow, and frequency.
- **Source:** GOCC 2026-03-26 New Relic Monitoring meeting — Action item for David

---

## T013 — Share Non-Prod Monitoring Status Email and Highlight ePOS Gap
- **Status:** Open
- **Created:** 2026-03-26
- **Objective Chain:** B-1 (Endpoint Monitoring & Post-Change Verification) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Kiran Mohandas
- **Systems:** #system:newrelic
- **Relevance:** 80/100
- **Tags:** #project:lapu-lapu #worktype:monitoring #domain:non-production #system:epos #worktype:observability
- **Description:** Share the daily non-production monitoring status email with David and highlight the ePOS gap. ePOS is not currently included in the daily non-prod monitoring alert email sent by TEM. ePOS alone has ~17 non-prod environments contributing to operational burden. Confirm non-prod monitoring parameters with TEM (Sangram).
- **Source:** GOCC 2026-03-26 New Relic Monitoring meeting — Action items for Kiran Mohandas

---

## T014 — Connect David with Chetan for ePOS Environment Refresh Process
- **Status:** Open
- **Created:** 2026-03-26
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Kiran Mohandas
- **Systems:** #system:azure
- **Relevance:** 75/100
- **Tags:** #project:lapu-lapu #worktype:coordination #domain:non-production #system:epos #domain:environment-management
- **Description:** Connect David with Chetan to discuss on-demand ePOS environment refresh and spin-up/spin-down process. Environment and DB scaling is currently ad hoc. Opportunity to improve on-demand enablement, automated refresh to latest codebase, and spin-up/down of environments and databases.
- **Source:** GOCC 2026-03-26 New Relic Monitoring meeting — Action item for Kiran Mohandas

---

## T015 — Confirm Non-Prod Monitoring Parameters with TEM
- **Status:** Open
- **Created:** 2026-03-26
- **Objective Chain:** B-1 (Endpoint Monitoring & Post-Change Verification) → O1 (Frictionless Customer Experience)
- **Team:** #team:ets-japan
- **Assigned:** David Klan
- **Systems:** #system:newrelic
- **Relevance:** 78/100
- **Tags:** #project:lapu-lapu #worktype:monitoring #domain:non-production #worktype:observability
- **Description:** Confirm non-production monitoring parameters with TEM (Sangram). Define the standard set of monitoring checks for non-prod environments to ensure the Developer Experience Dashboard has correct coverage and alerting thresholds. Joint action with Kiran Mohandas.
- **Source:** GOCC 2026-03-26 New Relic Monitoring meeting — Action item for David / Kiran Mohandas

---

## T016 — GOCC ePOS Monitoring Onboarding — Service Account & Authentication Setup
- **Status:** Open
- **Created:** 2026-03-26
- **Objective Chain:** H-4 (Unified Support) → O4 (Robust Technical Core)
- **Team:** #team:gocc-monitoring
- **Assigned:** Jonan Tan Pangan
- **Systems:** #system:newrelic #system:cmdb #system:xmatters
- **Relevance:** 82/100
- **Tags:** #project:lapu-lapu #worktype:monitoring #domain:gocc-handover #system:epos #worktype:observability #domain:authentication
- **Description:** Establish GOCC monitoring for ePOS including: service account provisioning with key-based authentication through Manulink, ServiceNow CMDB relationship mapping (application → application services → components), xMatters registration, and runbook-driven first response procedures. ePOS access path uses SSO/LTPA token + cookie-based authorization via Manulink. PII guardrails confirmed: no PII in New Relic or ADX, debug logging disabled in production.
- **Source:** GOCC 2026-03-26 New Relic Monitoring meeting

---

## T017 — Document End-to-End Patching Process and Challenges for Japan
- **Status:** Open
- **Created:** 2026-03-17
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Kanagaraj Ramasamy
- **Systems:** #system:azure
- **Relevance:** 82/100
- **Tags:** #project:lapu-lapu #worktype:hygiene #domain:patching #domain:documentation #outcome:resilience
- **Description:** Prepare documentation outlining the patching challenges and the end-to-end patching process for Japan servers (Linux). Document the current manpower constraints, Ansible automation gaps, and server categorisation windows. Goal is to simplify the process so it can be handed to GOCC for execution, reducing dependency on ETS engineering resources. Supports the broader objective of achieving 14-day patching cycles on weekdays.
- **Source:** 2026-03-17 Patching Schedule and Possible Standard BAU Transition meeting — Action for Kanagaraj

---

## T018 — Prepare Standard Template and Server List for Japan Production Patching
- **Status:** Open
- **Created:** 2026-03-17
- **Objective Chain:** B-6 (IT Asset Management & Evergreen Migration) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Kanagaraj Ramasamy
- **Systems:** #system:azure #system:cmdb
- **Relevance:** 78/100
- **Tags:** #project:lapu-lapu #worktype:hygiene #domain:patching #domain:asset-management #domain:cmdb
- **Description:** Share updated list of Linux and Windows production servers with Hideo Hasegawa, who will assist in mapping application names. Sreekanth Dogiparthy to provide the Windows server list. Prepare the standard template for Japan production servers to enable transition of patching to Standard BAU Change. Joint effort: Kanagaraj (Linux), Sreekanth (Windows), Hideo (application mapping).
- **Source:** 2026-03-17 Patching Schedule and Possible Standard BAU Transition meeting — Action for Kanagaraj, Sreekanth, Hideo

---

## T019 — Schedule Non-Production Patching Follow-Up with HK and Indonesia
- **Status:** Open
- **Created:** 2026-03-17
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Karen Escalona
- **Systems:** #system:azure
- **Relevance:** 70/100
- **Tags:** #project:lapu-lapu #worktype:coordination #domain:patching #domain:non-production
- **Description:** Schedule a meeting with Hong Kong (Karen Leung) and Indonesia (Glenn Jay) representatives to discuss next steps for non-production environment patching alignment. Extends the Japan patching standardisation work to other Asia regions.
- **Source:** 2026-03-17 Patching Schedule and Possible Standard BAU Transition meeting — Action for Karen Escalona

---

## T020 — Enable Thursday Weekday Patching for Non-Batch Applications
- **Status:** Open
- **Created:** 2026-03-26
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Birger Fjaellman
- **Systems:** #system:azure
- **Relevance:** 82/100
- **Tags:** #project:lapu-lapu #domain:patching #outcome:resilience #worktype:hygiene
- **Description:** Applications that do not have batch jobs running can be patched on Thursday night, instead of waiting for the weekend when releases and upgrades are prioritised. Identify and maintain a list of non-batch applications eligible for Thursday patching. Implement the Thursday patching window to relieve pressure on the weekend schedule. Coordinate with Kanagaraj (Linux) and Sreekanth (Windows) for server categorisation.
- **Source:** 2026-03-26 Incident Review Meeting

---

## T021 — Add 3 External/Internal URLs to Employee Experience Dashboard
- **Status:** Open
- **Created:** 2026-03-31
- **Objective Chain:** B-1 (Endpoint Monitoring & Post-Change Verification) → O1 (Frictionless Customer Experience)
- **Team:** #team:gocc-monitoring
- **Assigned:** Mary Kris Cabunilas
- **Systems:** #system:newrelic #system:azure
- **Relevance:** 85/100
- **Tags:** #project:lapu-lapu #artifact:dashboard #worktype:monitoring #worktype:observability
- **Description:** Add three new URLs to the Employee Experience Dashboard URL monitoring list (JIRA: LPLP-99): (1) Azure Databricks — https://adb-290394047047427.7.azuredatabricks.net/ (external service), (2) Pathwise endpoint from Aon — https://manulife.pathwise.aon.com/logon/LogonPoint/index.html (Manulife internal), (3) DORA app from Manulife AI team — https://dora.manulife.com/ (Manulife internal). Confirm all three are in scope before adding. To be included in Employee Experience Dashboard.
- **Source:** Inbox — Add3URLtodashboard.md

---

## T022 — Register GOCC-Monitoring Team Member Assignments for LapuLapu
- **Status:** Open
- **Created:** 2026-03-31
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team:gocc-monitoring
- **Assigned:** Jonan Tan Pangan
- **Systems:** #system:newrelic #system:moogsoft #system:xmatters
- **Relevance:** 78/100
- **Tags:** #project:lapu-lapu #worktype:coordination #domain:gocc-handover
- **Description:** Register and track the GOCC-Monitoring team member assignments for LapuLapu work streams as confirmed by Jonan: Mary Kris, Rae, Yam — Dashboard; Edward and team (12 members) — actual instrumentation; Dennis/Mark — server build implementation of patching for Ingenium; George/Angelo — gathering of rapid recovery items. Update teams.md member roles accordingly and ensure alignment with T003, T006, T016 assignments.
- **Source:** Inbox — TeamUpdate.md (message from Jonan)