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

---

## T023 — JP Employee Experience Dashboard (Prod) Enhancement
- **Status:** Open
- **Created:** 2026-04-01
- **Objective Chain:** B-1 (Endpoint Monitoring & Post-Change Verification) → O1 (Frictionless Customer Experience)
- **Team:** #team:ets-japan
- **Assigned:** Birger Fjaellman
- **Systems:** #system:newrelic #system:powerbi
- **Relevance:** 92/100
- **Tags:** #dashboard #employee-experience #japan
- **Description:** Improve Japan-focused Employee Experience Dashboard in Production by enhancing visibility, impact-driven drilldowns, and Japan-specific filtering aligned to real user experience. Incorporate PS Team Morning Health Check data as an input source.

---

## T024 — Developer Experience Dashboard for Non-Prod Environments
- **Status:** Open
- **Created:** 2026-04-01
- **Objective Chain:** B-1 (Endpoint Monitoring & Post-Change Verification) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Birger Fjaellman
- **Systems:** #system:newrelic #system:apm
- **Relevance:** 88/100
- **Tags:** #dashboard #developer-experience #nonprod
- **Description:** Establish Developer Experience Dashboard coverage for DEV/SIT/UAT environments to improve non-prod health visibility and accelerate troubleshooting for Japan application teams.

---

## T025 — Deploy Branch Office Laptop Monitoring (Japan)
- **Status:** Open
- **Created:** 2026-04-01
- **Objective Chain:** B-1 (Endpoint Monitoring & Post-Change Verification) → O1 (Frictionless Customer Experience)
- **Team:** #team:gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #system:newrelic
- **Relevance:** 85/100
- **Tags:** #synthetics #end-user-monitoring #japan
- **Description:** Deploy and validate monitoring on five Japan branch office laptops to capture real end-user connectivity and experience signals, with defined success criteria and deployment schedule.

---

## T026 — JP East/West Synthetic Monitoring Enablement
- **Status:** Open
- **Created:** 2026-04-01
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team:gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #system:newrelic #system:azure
- **Relevance:** 93/100
- **Tags:** #synthetics #japan-hosting #observability
- **Description:** Enable Japan-hosted synthetic monitoring via Azure JP East/West to close regional visibility gaps and detect Japan-only incidents early.

---

## T027 — Achieve OMM L2 for Major Japan Applications
- **Status:** Open
- **Created:** 2026-04-01
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team:gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #system:newrelic #system:apm
- **Relevance:** 95/100
- **Tags:** #omm #gold-apps #japan
- **Description:** Drive Observability Maturity Model Level 2 compliance for all major Japan applications, including APM installation, tracing enablement, tagging, and alert coverage validation.

---

## T028 — Japan APM & Distributed Tracing Rollout Confirmation
- **Status:** Open
- **Created:** 2026-04-01
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team:gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #system:newrelic #system:apm
- **Relevance:** 90/100
- **Tags:** #apm #distributed-tracing #aks
- **Description:** Confirm APM and distributed tracing rollout status for Japan AKS-hosted applications, with evidence-based install confirmation and documented ownership.

---

## T029 — Japan Tagging Standards & Bulk Tagging Guidance
- **Status:** Open
- **Created:** 2026-04-01
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O4 (Robust Technical Core)
- **Team:** #team:gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #system:newrelic #system:azure #system:cmdb
- **Relevance:** 91/100
- **Tags:** #tagging #data-quality #japan
- **Description:** Define and publish minimum tagging standards (including country=JP) and bulk tagging guidance for Azure and New Relic to enable accurate Japan filtering and reporting.

---

## T030 — JP Monitoring Coverage Power BI Report
- **Status:** Open
- **Created:** 2026-04-01
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team:gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #system:powerbi #system:newrelic
- **Relevance:** 87/100
- **Tags:** #coverage-report #powerbi #japan
- **Description:** Produce a Japan-filtered monitoring coverage report in Power BI, mapping applications to observability criteria and highlighting gaps.

---

## T031 — Observability-as-Code Policy & Inner-Source Repo Enablement
- **Status:** Open
- **Created:** 2026-04-01
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O4 (Robust Technical Core)
- **Team:** #team:gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #system:newrelic
- **Relevance:** 82/100
- **Tags:** #observability-as-code #innersource #automation
- **Description:** Enable inner-source collaboration for observability-as-code, including repo access, contribution workflow, and standardized policy structure for APM services.

---

## T032 — Inventory JP Alert Coverage Gaps & Recommendations
- **Status:** Open
- **Created:** 2026-04-01
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team:gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #system:newrelic #system:moogsoft
- **Relevance:** 89/100
- **Tags:** #alerts #gap-analysis #japan
- **Description:** Identify Japan resources lacking alert coverage and provide prioritized remediation recommendations to reduce blind spots and improve incident detection.

---

## T033 — Modularize Monitoring Scripts in Docker
- **Status:** Open
- **Created:** 2026-04-01
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O4 (Robust Technical Core)
- **Team:** #team:gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #system:newrelic
- **Relevance:** 75/100
- **Tags:** #docker #automation #synthetics
- **Description:** Containerize and modularize monitoring scripts using Docker to support scalable deployment and reuse, coordinated with observability counterparts.

---

## T034 — Obtain ePOS Health Check Script Details (PS Team)
- **Status:** Open
- **Created:** 2026-04-01
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team:ets-japan
- **Assigned:** Birger Fjaellman
- **Systems:** #system:ingenium
- **Relevance:** 70/100
- **Tags:** #epos #health-check #dependencies
- **Description:** Obtain details, access path, and ownership of the ePOS health check script used by PS Team to align monitoring and close observability gaps.

---

## T035 — Establish Recurring Japan Monitoring Governance Cadence
- **Status:** Open
- **Created:** 2026-04-01
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team:gocc
- **Assigned:** Hari Pothakamuri
- **Systems:** #system:confluence
- **Relevance:** 78/100
- **Tags:** #governance #cadence #japan
- **Description:** Formalize a recurring Japan monitoring forum with shared artifacts and dashboards as the governance baseline to ensure sustained alignment and progress tracking.

---

## T036 — Prepare Low-Level Implementation Plan for Epsilon POT
- **Status:** Open
- **Created:** 2026-04-06
- **Objective Chain:** B-7 (PPS Service Improvement) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Balaji Ravi
- **Systems:** #system:ingenium #system:azure
- **Relevance:** 88/100
- **Tags:** #project:lapu-lapu #project:epsilon #domain:modernisation #worktype:planning
- **Description:** Derive a low-level implementation plan from the high-level Epsilon POT project plan. Must clearly capture detailed prerequisite steps, ownership and dependencies across teams, sequencing and timelines, and constraints or assumptions requiring validation. Once finalised, update the overall project plan and align all stakeholders on execution expectations. David Klan to facilitate and coordinate the POT execution end-to-end after the plan is firmed up.
- **Source:** Re: Epsilon – POT - Ingenium Modernization email (Balaji Ravi, 2026-04-02)

---

## T037 — Document VCS Setup Process for Epsilon POT
- **Status:** Open
- **Created:** 2026-04-06
- **Objective Chain:** B-7 (PPS Service Improvement) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Kanagaraj Ramasamy
- **Systems:** #system:ingenium
- **Relevance:** 72/100
- **Tags:** #project:lapu-lapu #project:epsilon #domain:modernisation #worktype:documentation
- **Description:** ETS BAU team to share screen with VCS team to complete VCS setup for Epsilon POT. Kanagaraj agreed to create documentation on the VCS setup process, as this has not been handled by the team previously. Documentation to be reusable for future environments.
- **Source:** Re: Epsilon – POT - Ingenium Modernization email (Balaji Ravi, 2026-04-02)

---

## T038 — Obtain POT Subscription Contributor Access for Sanjeev
- **Status:** Open
- **Created:** 2026-04-06
- **Objective Chain:** B-7 (PPS Service Improvement) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Balaji Ravi
- **Systems:** #system:azure
- **Relevance:** 65/100
- **Tags:** #project:lapu-lapu #project:epsilon #worktype:access-management
- **Description:** Request Azure contributor access to the Epsilon POT subscription (tagged CC9153) for Sanjeev, so he is ready to support infrastructure work when required. Resource group has already been provisioned.
- **Source:** Re: Epsilon – POT - Ingenium Modernization email (Balaji Ravi, 2026-04-02)

---

## T039 — Create Dedicated Problem Ticket for Recurring Japan Incident Use Cases
- **Status:** Open
- **Created:** 2026-04-06
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team:gocc-monitoring
- **Assigned:** Christopher Bond
- **Systems:** #system:cmdb
- **Relevance:** 80/100
- **Tags:** #project:lapu-lapu #domain:problem-management #worktype:incident-management #outcome:mttr
- **Description:** Create a dedicated problem ticket for recurring Japan incident use cases. Share the problem ticket and Japan use cases with Rohina Emerson and Hans for review and alignment. Enables structured root cause tracking and prevention for Japan-specific repeat incidents.
- **Source:** 2026-03-30 Japan Team - Global Incident Management w/ Rohina meeting (George Fermo minutes)

---

## T040 — Define & Distribute Standardized Japan Incident Template
- **Status:** Open
- **Created:** 2026-04-06
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team:gocc-monitoring
- **Assigned:** Rohina Emerson
- **Systems:** #system:cmdb
- **Relevance:** 85/100
- **Tags:** #project:lapu-lapu #domain:incident-management #worktype:documentation #program:r2r
- **Description:** Share the R2R Knowledge Management deck and standardized structured template for Japan incident documentation. Template must be searchable by Configuration Items (CIs), include Key Contacts and Rapid Response (RR) contacts. Hasegawa-san to distribute template to Incident Management teams once received.
- **Source:** 2026-03-30 Japan Team - Global Incident Management w/ Rohina meeting (George Fermo minutes)

---

## T041 — Finalize Japan CI Structure & Component Mapping for Rapid Recovery
- **Status:** Open
- **Created:** 2026-04-06
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team:gocc-monitoring
- **Assigned:** George Francis Fermo
- **Systems:** #system:cmdb
- **Relevance:** 83/100
- **Tags:** #project:lapu-lapu #program:r2r #outcome:resilience #worktype:incident-management
- **Description:** Finalize Japan CI structure with explicit identification of Primary CI, Supporting CI components, and CI(s) designed for rapid recovery execution. Validate component mapping against CMDB to enable structured incident response and rapid recovery workflows.
- **Source:** 2026-03-30 Japan Team - Global Incident Management w/ Rohina meeting (George Fermo minutes)

---

## T042 — Add ADS & xMatters Groups for Japan Alerting and Escalation
- **Status:** Open
- **Created:** 2026-04-06
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team:gocc-monitoring
- **Assigned:** George Francis Fermo
- **Systems:** #system:xmatters
- **Relevance:** 78/100
- **Tags:** #project:lapu-lapu #worktype:incident-management #outcome:mttd
- **Description:** Add ADS and xMatters groups for enhanced Japan alerting and escalation capabilities. Ensures Japan incidents trigger the correct notification chains and on-call groups for faster response.
- **Source:** 2026-03-30 Japan Team - Global Incident Management w/ Rohina meeting (George Fermo minutes)

---

## T043 — Define Standardized Vendor Escalation Procedure Format
- **Status:** Open
- **Created:** 2026-04-06
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team:gocc-monitoring
- **Assigned:** George Francis Fermo
- **Systems:** #system:cmdb
- **Relevance:** 75/100
- **Tags:** #project:lapu-lapu #worktype:incident-management #worktype:documentation
- **Description:** Define a standardized escalation procedure format for application vendor support to ensure consistent, timely engagement during Japan incidents. Format to be reviewed and operationalized by Incident Management / IT Ops teams.
- **Source:** 2026-03-30 Japan Team - Global Incident Management w/ Rohina meeting (George Fermo minutes)
