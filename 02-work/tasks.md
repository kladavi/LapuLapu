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
- **Tags:** #project:lapu-lapu #dashboard #employee-experience #japan
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
- **Tags:** #project:lapu-lapu #dashboard #developer-experience #nonprod
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
- **Tags:** #project:lapu-lapu #synthetics #end-user-monitoring #japan
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
- **Tags:** #project:lapu-lapu #synthetics #japan-hosting #observability
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
- **Tags:** #project:lapu-lapu #omm #gold-apps #japan
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
- **Tags:** #project:lapu-lapu #apm #distributed-tracing #aks
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
- **Tags:** #project:lapu-lapu #tagging #data-quality #japan
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
- **Tags:** #project:lapu-lapu #coverage-report #powerbi #japan
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
- **Tags:** #project:lapu-lapu #observability-as-code #innersource #automation
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
- **Tags:** #project:lapu-lapu #alerts #gap-analysis #japan
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
- **Tags:** #project:lapu-lapu #docker #automation #synthetics
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
- **Tags:** #project:lapu-lapu #epos #health-check #dependencies
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
- **Tags:** #project:lapu-lapu #governance #cadence #japan
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

---

## T044 — Investigate Capacity Alerts on Employee Experience Dashboard Servers
- **Status:** Open
- **Created:** 2026-04-06
- **Objective Chain:** B-1 (Endpoint Monitoring & Post-Change Verification) → O4 (Robust Technical Core)
- **Team:** #team:gocc-monitoring
- **Assigned:** Jonan Tan Pangan
- **Systems:** #system:newrelic #system:azure
- **Relevance:** 92/100
- **Tags:** #project:lapu-lapu #tier:3 #worktype:monitoring #domain:colleague #outcome:resilience #system:newrelic #system:azure
- **Description:** Analyze recurring capacity alerts on the Employee Experience dashboard to identify timing patterns and isolate impacted servers or Azure components. Confirm whether the alerts correlate with measurable performance degradation such as latency or error spikes, then summarize recommended actions such as threshold tuning, right-sizing, or workload/process changes.

---

## T045 — Ingenium BAU Stability Maintained During Transition
- **Status:** Approved
- **Created:** 2026-04-06
- **Objective Chain:** B-7 (PPS Service Improvement) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Birger Fjaellman
- **Systems:** #system:ingenium #system:cmdb
- **Relevance:** 88/100
- **Tags:** #project:lapu-lapu #bau #stability #transition
- **Description:** Maintain current Ingenium Infra team BAU support to ensure operational stability and close non‑business‑hours support gaps while transition activities progress. **Plan reviewed and explicitly approved by Birger Fjaellman.**

---

## T046 — Standardise and Automate High‑Frequency Ingenium BAU Tasks
- **Status:** Approved
- **Created:** 2026-04-06
- **Objective Chain:** B-7 (PPS Service Improvement) → O4 (Robust Technical Core)
- **Team:** #team:gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #system:newrelic #system:ingenium #system:cmdb
- **Relevance:** 94/100
- **Tags:** #project:lapu-lapu #automation #runbooks #omm
- **Description:** Identify and automate high‑frequency repeatable Ingenium BAU tasks across WAS and DB layers, reducing manual intervention and engineering dependency. **Approach confirmed as reasonable and approved by ETS Japan lead.**

---

## T047 — Finalise and Validate Ingenium Runbooks for GOCC Handover
- **Status:** Approved
- **Created:** 2026-04-06
- **Objective Chain:** H-4 (Unified Support) → O4 (Robust Technical Core)
- **Team:** #team:gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #system:newrelic #system:xmatters #system:ingenium
- **Relevance:** 91/100
- **Tags:** #project:lapu-lapu #runbooks #incident-response #go-live
- **Description:** Create, standardise, and validate end‑to‑end Ingenium operational runbooks to support incident detection, recovery, and escalation by GOCC. **Plan acknowledged and approved by Birger Fjaellman.**

---

## T048 — Establish Weekly Ingenium Transition Review Cadence
- **Status:** Approved
- **Created:** 2026-04-06
- **Objective Chain:** B-7 (PPS Service Improvement) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Birger Fjaellman
- **Systems:** #system:ingenium
- **Relevance:** 76/100
- **Tags:** #project:lapu-lapu #governance #tracking #transition
- **Description:** Set up and run a weekly review forum to track Ingenium KT progress, automation delivery, runbook readiness, and transition risks. **Cadence and governance approach approved by ETS Japan leadership.**

---

## T049 — Progressive GOCC KT for Ingenium Operations
- **Status:** Approved
- **Created:** 2026-04-06
- **Objective Chain:** H-4 (Unified Support) → O4 (Robust Technical Core)
- **Team:** #team:gocc-monitoring
- **Assigned:** Jonan Tan Pangan
- **Systems:** #system:newrelic #system:moogsoft #system:ingenium
- **Relevance:** 85/100
- **Tags:** #project:lapu-lapu #kt #capability-building #gocc
- **Description:** Involve ~6 core GOCC members in ongoing Ingenium KT sessions to build system knowledge in parallel with automation and documentation. **Phased KT approach explicitly endorsed by Birger Fjaellman.**

---

## T050 — Execute Reverse-Shadow Linux Patching Validation (Non‑Prod)
- **Status:** Open
- **Created:** 2026-04-06
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team:gocc-monitoring
- **Assigned:** Jonan Tan Pangan
- **Systems:** #system:azure #system:ingenium #system:cmdb
- **Relevance:** 92/100
- **Tags:** #project:lapu-lapu #linux #patching #kt #r2r #resilience
- **Description:** Execute the reverse‑shadow Linux patching pre‑ and post‑validation in the Non‑Production environment under guidance of the Ingenium Infra team. This activity builds operational readiness and strengthens recovery and control validation capabilities aligned to R2R objectives.
-----------------------

---

## T051 — Prepare PROD Reverse-Shadow Linux Patching Change
- **Status:** Open
- **Created:** 2026-04-06
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Birger Fjaellman
- **Systems:** #system:ingenium #system:cmdb #system:azure
- **Relevance:** 85/100
- **Tags:** #project:lapu-lapu #linux #patching #change-management #prod #kt
- **Description:** Finalise preparation for the PROD reverse‑shadow Linux patching validation, including receipt and review of the PROD CHG ticket, access confirmation, and alignment of validation checkpoints. Note: PROD change date is tentative and pending formal CHG details.

---

## T052 — Rename Japan Non‑Prod Dashboard to Developer Experience
- **Status:** Open
- **Created:** 2026-04-06
- **Objective Chain:** B-1 (Endpoint Monitoring & Post-Change Verification) → O4 (Robust Technical Core)
- **Team:** #team:gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #system:newrelic
- **Relevance:** 92/100
- **Tags:** #project:lapu-lapu #dashboard #developer-experience #naming #non-prod
- **Description:** Rename the current “GOCC Japan Employee Experience Dashboard” for non‑production workloads to “GOCC Japan Developer Experience Dashboard” to accurately reflect audience and intent. Ensure consistency across dashboard titles, descriptions, and references for the 16 listed non‑prod systems.

---

## T053 — Introduce Grouped & Pivoted Views for Japan Non‑Prod Monitoring
- **Status:** Open
- **Created:** 2026-04-06
- **Objective Chain:** B-1 (Endpoint Monitoring & Post-Change Verification) → O4 (Robust Technical Core)
- **Team:** #team:gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #system:newrelic
- **Relevance:** 90/100
- **Tags:** #project:lapu-lapu #dashboard #observability #filtering #ux
- **Description:** Enhance the Japan non‑prod dashboards to support grouping and pivoting by environment, application, and alert status. Enable multiple filtered views to manage scale across many environments and improve rapid situational awareness.

---

## T054 — Evaluate & Apply Team Ownership Metadata in Honeycomb Views
- **Status:** Open
- **Created:** 2026-04-06
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O4 (Robust Technical Core)
- **Team:** #team:gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #system:newrelic
- **Relevance:** 78/100
- **Tags:** #project:lapu-lapu #metadata #ownership #honeycomb #governance
- **Description:** Assess the “Team Ownership” setting available in honeycomb views and determine standard usage guidelines. If viable, implement ownership tagging to improve accountability, filtering, and collaboration across GOCC and ETS Japan teams.

---

## T055 — Define KT Scope for Ingenium Transition
- **Status:** Open
- **Created:** 2026-04-07
- **Objective Chain:** H-4 (Unified Support) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Birger Fjaellman
- **Systems:** #system:ingenium #system:cmdb
- **Relevance:** 92/100
- **Tags:** #project:lapu-lapu #kt #transition #support-model
- **Description:** Define the Knowledge Transfer (KT) scope for Ingenium based on the approved WBS and project schedule to ensure aligned expectations between ETS Asia and GOCC. Scope definition will act as the baseline for transition planning and acceptance.

---

## T056 — Execute Shadow and Reverse-Shadow Support Transition (Apr–Jun)
- **Status:** Open
- **Created:** 2026-04-07
- **Objective Chain:** H-4 (Unified Support) → O4 (Robust Technical Core)
- **Team:** #team:gocc-monitoring
- **Assigned:** Jonan Tan Pangan
- **Systems:** #system:ingenium #system:xmatters
- **Relevance:** 95/100
- **Tags:** #project:lapu-lapu #kt #handover #lifecycle
- **Description:** Execute a 3‑month shadow and reverse‑shadow support transition with GOCC from April to June to validate readiness for full L0–L2 ownership. Track issues and gaps during the transition for remediation.

---

## T057 — Finalize Ingenium KT Documentation
- **Status:** Open
- **Created:** 2026-04-07
- **Objective Chain:** H-4 (Unified Support) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Birger Fjaellman
- **Systems:** #system:ingenium #system:cmdb
- **Relevance:** 88/100
- **Tags:** #project:lapu-lapu #documentation #kt
- **Description:** Finalize all Ingenium KT documentation, covering operational procedures, DB2, and middleware, with clear responsibility split between ETS Asia and GOCC. Documentation will be used as the formal handover artifact.

---

## T058 — Confirm GOCC Leads for Ingenium KT Target Audience
- **Status:** Open
- **Created:** 2026-04-07
- **Objective Chain:** H-4 (Unified Support) → O4 (Robust Technical Core)
- **Team:** #team:gocc
- **Assigned:** Hari Pothakamuri
- **Systems:** #system:ingenium
- **Relevance:** 75/100
- **Tags:** #project:lapu-lapu #governance #roles
- **Description:** Confirm the six GOCC core leads assigned to the Japan segment for the Ingenium KT to establish the official target audience. This ensures accountability and effective knowledge absorption.

---

## T059 — Establish KT Governance Cadence
- **Status:** Open
- **Created:** 2026-04-07
- **Objective Chain:** H-4 (Unified Support) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Birger Fjaellman
- **Systems:** #system:ingenium
- **Relevance:** 70/100
- **Tags:** #project:lapu-lapu #governance #cadence
- **Description:** Set up weekly progress calls to address KT issues and concerns, and a monthly deliverable review to track transition health. Governance ensures risks are surfaced early and resolved.

---

## T060 — Prepare and Publish Ingenium KT Plan and Schedule
- **Status:** Open
- **Created:** 2026-04-07
- **Objective Chain:** H-4 (Unified Support) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Birger Fjaellman
- **Systems:** #system:ingenium
- **Relevance:** 90/100
- **Tags:** #project:lapu-lapu #planning #kt
- **Description:** Prepare and publish the detailed Ingenium KT plan and schedule in coordination with GOCC Monitoring, covering sequencing, milestones, and acceptance criteria to support full L0–L2 ownership.

---

## T061 — Define Operations-Focused Application & Capacity Dashboard (New Relic)
- **Status:** Open
- **Created:** 2026-04-08
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team-gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #system:newrelic #system:azure #system:apm
- **Relevance:** 95/100
- **Tags:** #project:lapu-lapu #observability #capacity #apm #dashboarding #operations
- **Description:** Design and validate an operations-focused New Relic dashboard that correlates Azure infrastructure components, capacity saturation signals, and application performance (latency, errors, Apdex). The dashboard will support pattern analysis (daily/weekly, batch vs workload-driven) and serve as the primary tool for root cause and performance correlation for Japan operations.

---

## T062 — Executive Trend Summary for Capacity & Performance (Power BI)
- **Status:** Open
- **Created:** 2026-04-08
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team-ets-japan
- **Assigned:** Birger Fjaellman
- **Systems:** #system:powerbi #system:newrelic
- **Relevance:** 82/100
- **Tags:** #project:lapu-lapu #executive-reporting #trends #capacity #colleague-experience
- **Description:** Produce a Power BI summary view that distills insights from New Relic capacity and performance analysis into clear trends for leadership consumption. This dashboard will complement (not replace) New Relic, enabling business users and executives to understand recurring capacity risks and their impact without deep operational tooling knowledge.

---

## T063 — GOCC Shadow Session for Windows Patching Validation (JP Non-Prod)
- **Status:** Open
- **Created:** 2026-04-08
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Birger Fjaellman
- **Systems:** #system:azure #system:cmdb
- **Relevance:** 88/100
- **Tags:** #project:lapu-lapu #worktype:kt #worktype:patching #outcome:resilience #domain:operations
- **Description:** Conduct a GOCC shadow session for Windows patching pre- and post-validation activities in the Japan Non-Production environment to reinforce operational controls and validation checkpoints. Session will support R2R readiness and operational resilience, aligned to CHG01354108 scheduled for 2026-04-16.

---

## T064 — Prepare Ingenium KT Plan and Phased Schedule
- **Status:** Open
- **Created:** 2026-04-08
- **Objective Chain:** H-4 (Unified Support) → O4 (Robust Technical Core)
- **Team:** #team-ets-japan
- **Assigned:** Birger Fjaellman
- **Systems:** #system:ingenium #system:cmdb
- **Relevance:** 95/100
- **Tags:** #project:lapu-lapu #kt #transition #risk-managed #lapu-lapu
- **Description:** Develop and publish a detailed, phase-wise Ingenium knowledge transfer plan covering non-production, production readiness, and full BAU operations. The plan must define clear KT targets, milestones, and risk controls to ensure a controlled transition to GOCC support.

---

## T065 — Enable GOCC L2 Support Readiness for Ingenium by End of Q2
- **Status:** Open
- **Created:** 2026-04-08
- **Objective Chain:** H-4 (Unified Support) → O1 (Frictionless Customer Experience)
- **Team:** #team-gocc
- **Assigned:** Hari Pothakamuri
- **Systems:** #system:ingenium #system:newrelic #system:moogsoft
- **Relevance:** 92/100
- **Tags:** #project:lapu-lapu #l2-readiness #support-model #kt
- **Description:** Coordinate onboarding or alignment of GOCC resources to achieve L2 support capability for Ingenium by end of June. Readiness must be validated against defined production incident scenarios and escalation workflows.

---

## T066 — Establish Ingenium KT Governance and Cadence
- **Status:** Open
- **Created:** 2026-04-08
- **Objective Chain:** H-4 (Unified Support) → O1 (Frictionless Customer Experience)
- **Team:** #team-gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #system:jira #system:cmdb
- **Relevance:** 85/100
- **Tags:** #project:lapu-lapu #governance #kt #milestones
- **Description:** Formalise and run the agreed KT governance model, including weekly status calls, monthly milestone reviews, and a final Q2 takeover readiness review. Track risks, dependencies, and readiness feedback via a central JIRA tracker.

---

## T067 — Align GOCC 24x7 Support Coverage to Ingenium KT Schedule
- **Status:** Open
- **Created:** 2026-04-08
- **Objective Chain:** H-4 (Unified Support) → O1 (Frictionless Customer Experience)
- **Team:** #team-gocc
- **Assigned:** Hari Pothakamuri
- **Systems:** #system:xmatters #system:ingenium
- **Relevance:** 78/100
- **Tags:** #project:lapu-lapu #support-coverage #kt #operations
- **Description:** Confirm and align 24x7 GOCC DB, Middleware, and Infrastructure support availability with the approved Ingenium KT plan. Ensure on-call coverage and escalation paths are validated for each KT phase.

---

## T068 — Review and Sign Off AWS IACB/OSCS Follow-Up Report (v0.2)
- **Status:** Open
- **Created:** 2026-04-13
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Birger Fjaellman
- **Systems:** #system:aws #system:powerbi
- **Relevance:** 78/100
- **Tags:** #project:lapu-lapu #architecture-review #reporting #priority-alignment #r2r
- **Description:** Review the AWS-updated JP IACB/OSCS follow-up report package (v0.2), capture any architecture/priority concerns, and provide formal sign-off or change feedback to AWS and stakeholders so final recommendations can be actioned without schedule slippage.

---

## T069 — Submit Time-Bound Feedback on AWS SSW Follow-Up Report
- **Status:** Open
- **Created:** 2026-04-13
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Birger Fjaellman
- **Systems:** #system:aws
- **Relevance:** 80/100
- **Tags:** #project:lapu-lapu #reporting #deadline #r2r #stakeholder-alignment
- **Description:** Coordinate and submit consolidated feedback on the JP SSW follow-up report before AWS month-end support cut-off, ensuring key comments are incorporated into the final report and downstream remediation planning remains accurate and executable.

---

## T070 — Publish Weekly PS-to-GOCC Transition Coverage List
- **Status:** Open
- **Created:** 2026-04-16
- **Objective Chain:** H-4 (Unified Support) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** David Klan
- **Systems:** #system:newrelic
- **Relevance:** 79/100
- **Tags:** #project:lapu-lapu #domain:gocc-handover #reporting #coverage
- **Description:** Publish a weekly application-by-application PS-to-GOCC transition list using the accepted Phase-1 checklist as the source of truth. Track fully transitioned and in-progress applications, include notable schedule risks such as Japan holiday slippage, and use the list as the handover status artifact for weekly reporting.
- **Source:** Inbox — 20260416+-+Lapu-Lapu+GOCC+and+Japan.doc

---

## T071 — Define Credential Management Standards for Synthetic Monitoring
- **Status:** Open
- **Created:** 2026-04-16
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team:gocc-observability
- **Assigned:** Joan Lee
- **Systems:** #system:newrelic #system:azure
- **Relevance:** 77/100
- **Tags:** #project:lapu-lapu #synthetics #credential-management #security #domain:gocc-handover
- **Description:** Define audit-compliant credential management standards for synthetic monitoring and customer journey checks, including storage, rotation, ownership, and evidence requirements. The standard must support PS-to-GOCC handover without leaving customer-impact monitoring dependent on unmanaged credentials.
- **Source:** Inbox — 20260416+-+Lapu-Lapu+GOCC+and+Japan.doc

---

## T072 — Implement New Relic Workload Status Noise-Reduction Policy
- **Status:** Open
- **Created:** 2026-04-16
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team:gocc-monitoring
- **Assigned:** Rae Judavar
- **Systems:** #system:newrelic #system:moogsoft
- **Relevance:** 86/100
- **Tags:** #project:lapu-lapu #alerting #noise-reduction #workload-health
- **Description:** Create and apply workload-status rules that prevent non-impactful host alerts from marking application workloads as unhealthy. Validate the policy against the current false-red cases and align downstream New Relic-to-Moogsoft alert handling with the updated workload health logic.
- **Source:** Inbox — 20260416+-+Lapu-Lapu+GOCC+and+Japan.doc

---

## T073 — Escalate Non-Prod ePOS HTTP 500 Errors with Evidence
- **Status:** Open
- **Created:** 2026-04-16
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team:gocc-monitoring
- **Assigned:** Rae Judavar
- **Systems:** #system:newrelic #system:apm
- **Relevance:** 81/100
- **Tags:** #project:lapu-lapu #nonprod #epos #error-management
- **Description:** Consolidate evidence for recurring non-production HTTP 500 errors, engage the ePOS application team, and drive resolution or explicit ownership confirmation. The escalation pack must include affected URLs or environments, supporting evidence, and the latest observed operational impact.
- **Source:** Inbox — 20260416+-+Lapu-Lapu+GOCC+and+Japan.doc

---

## T074 — Run Bilingual Rapid Recovery Enablement Session for Japan Support
- **Status:** Open
- **Created:** 2026-04-16
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team:gocc-monitoring
- **Assigned:** Jonan Tan Pangan
- **Systems:** #system:ingenium #system:cmdb
- **Relevance:** 80/100
- **Tags:** #project:lapu-lapu #rapid-recovery #program:r2r #knowledge-transfer
- **Description:** Execute a 90-minute bilingual rapid recovery enablement session with Japan Production Support, using Ingenium as the reference implementation and circulating materials in advance. The session must align invocation criteria, responsibilities, and information flow between Prod Support, GOCC, and incident coordination roles.
- **Source:** Inbox — 20260416+-+Lapu-Lapu+GOCC+and+Japan.doc

---

## T075 — Document New Relic-to-Moogsoft Alert Routing and Support-Team Registration
- **Status:** Open
- **Created:** 2026-04-16
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team:gocc-monitoring
- **Assigned:** Jonan Tan Pangan
- **Systems:** #system:newrelic #system:moogsoft
- **Relevance:** 82/100
- **Tags:** #project:lapu-lapu #alert-routing #support-model #monitoring-config
- **Description:** Identify and document where New Relic alerts and incidents route into Moogsoft and which setting controls support-team registration. Use the result to remove ambiguity in alert ownership and escalation for Japan monitoring.
- **Source:** Inbox — 20260416+-+LapuLapu+Team+Direction+and+Execution.doc

---

## T076 — Burn Down Orphaned Asset Inventory Starting with Servers
- **Status:** Open
- **Created:** 2026-04-16
- **Objective Chain:** B-6 (IT Asset Management & Evergreen Migration) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Yegor Pomozoff
- **Systems:** #system:cmdb #system:leanix
- **Relevance:** 76/100
- **Tags:** #project:lapu-lapu #asset-management #cleanup #servers
- **Description:** Break down the orphaned asset inventory by category, start with servers, and work through ownership validation and cleanup in a structured sequence. The goal is to reduce unmanaged assets that block accurate service mapping and evergreen migration decisions.
- **Source:** Inbox — 20260416+-+LapuLapu+Team+Direction+and+Execution.doc

---

## T077 — Confirm Japan Dashboard Alerting and Incident Workflow
- **Status:** Open
- **Created:** 2026-04-23
- **Objective Chain:** H-4 (Unified Support) → O4 (Robust Technical Core)
- **Team:** #team:gocc-monitoring
- **Assigned:** Jonan Tan Pangan
- **Systems:** #system:newrelic #system:moogsoft #system:xmatters
- **Relevance:** 84/100
- **Tags:** #project:lapu-lapu #alerting #incident-workflow #support-model
- **Description:** Confirm and document the end-to-end alerting and incident workflow for Japan production and non-production monitoring, including how dashboard alerts flow into incident handling and which teams respond at each step. The outcome should remove ambiguity across GOCC, ETS Japan, and TEM-aligned responders before additional applications are onboarded.
- **Source:** Inbox — 20260423+-+Lapu-Lapu+GOCC+and+Japan.doc

---

## T078 — Add Alert Count Context to Japan Business Capability Dashboard
- **Status:** Open
- **Created:** 2026-04-21
- **Objective Chain:** B-1 (Endpoint Monitoring & Post-Change Verification) → O1 (Frictionless Customer Experience)
- **Team:** #team:ets-japan
- **Assigned:** David Klan
- **Systems:** #system:newrelic
- **Relevance:** 69/100
- **Tags:** #project:lapu-lapu #dashboard #leadership-reporting #monitoring
- **Description:** Update the Japan Business Capability dashboard so alert counts explicitly state what is being counted, then circulate the revised view for leadership review with Hari, Kelvin, and Birger. The source notes do not clearly name the producing team, so ETS Japan should close the labeling gap and confirm the final review path with GOCC dashboard contributors.
- **Source:** Inbox — 20260421+-+LapuLapu+ETS+Japan,+GOCC,+and+Obs+Team.doc

---

## T079 — Capture Reboot/Restore Procedures for Japan Rapid Recovery Onboarding
- **Status:** Open
- **Created:** 2026-04-23
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team:gocc-monitoring
- **Assigned:** Jonan Tan Pangan
- **Systems:** #system:cmdb #system:azure
- **Relevance:** 83/100
- **Tags:** #project:lapu-lapu #rapid-recovery #runbooks #domain:gocc-handover
- **Description:** Work with Rohina and the Server Team to document per-application reboot and restore procedures and use the result to register additional applications for Rapid Recovery coverage. The deliverable should clarify recovery actions, ownership, and information flow needed for GOCC-assisted recovery execution.
- **Source:** Inbox — 20260423+-+Lapu-Lapu+GOCC+and+Japan.doc

---

## T080 — Define Non-Production Alert Response Workflow for Japan Monitoring
- **Status:** Open
- **Created:** 2026-04-23
- **Objective Chain:** H-4 (Unified Support) → O4 (Robust Technical Core)
- **Team:** #team:gocc-monitoring
- **Assigned:** Rae Judavar
- **Systems:** #system:newrelic #system:xmatters
- **Relevance:** 80/100
- **Tags:** #project:lapu-lapu #nonprod #incident-workflow #developer-experience
- **Description:** Define the response workflow for non-production monitoring alerts in Japan, with the first decision point on alert handling before environment spin-up or spin-down and rapid recovery follow-up. The workflow must capture cross-team handoffs with Sangram, Rupesh, and GOCC responders so non-prod incidents do not stall in ambiguous ownership.
- **Source:** Inbox — 20260423+-+LapuLapu+Team+Direction+and+Execution.doc

---

## T081 — Publish Japan GOCC Transition Scaffolding Pack
- **Status:** Open
- **Created:** 2026-04-23
- **Objective Chain:** H-4 (Unified Support) → O4 (Robust Technical Core)
- **Team:** #team:gocc-monitoring
- **Assigned:** Jonan Tan Pangan
- **Systems:** #system:cmdb #system:newrelic
- **Relevance:** 78/100
- **Tags:** #project:lapu-lapu #domain:gocc-handover #service-inventory #transition-planning
- **Description:** Publish a reusable Japan transition scaffolding pack covering inventory templates, a sample transition project plan, a support-level definitions dictionary, and a prioritized checklist of services to transition next. The pack should explicitly capture the handover categories Kelvin asked for in the weekly status review: CMDB reconciliation, support-group and xMatters coverage, monitored URLs, infrastructure thresholds, business-operation timing, alert validation by PS, and GOCC ORR sign-off. Co-develop the pack with David so the Japan onboarding backlog can be sequenced by impact, downtime history, and ownership clarity rather than ad hoc requests.
- **Source:** Inbox — 20260423+-+LapuLapu+Team+Direction+and+Execution.doc

---

## T082 — Onboard SRM to Rapid Recovery from Incident Review
- **Status:** Open
- **Created:** 2026-04-24
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** David Klan
- **Systems:** #system:cmdb
- **Relevance:** 88/100
- **Tags:** #project:lapu-lapu #rapid-recovery #runbooks #incident-followup #recovery-readiness
- **Description:** Use the SRM incident as the first focused Rapid Recovery onboarding case by registering SRM for recovery coverage, scheduling follow-up and knowledge-transfer sessions with the application team, and standardizing production validation, restart, and recovery SOPs. The work should also coordinate RCA review and close the operational gap where incidents can stall because restart authority, validation steps, and recovery procedures are unclear.
- **Source:** Inbox — Meeting+Summary_+SRM+Certificate+Incident,+Operational+Gaps,+and+Rapid+Recovery+Onboarding.doc

---

## T083 — Baseline Japan xMatters Rosters and Escalation Model
- **Status:** Open
- **Created:** 2026-05-07
- **Objective Chain:** H-4 (Unified Support) → O4 (Robust Technical Core)
- **Team:** #team:gocc-monitoring
- **Assigned:** Jonan Tan Pangan
- **Systems:** #system:xmatters #system:cmdb
- **Relevance:** 84/100
- **Tags:** #project:lapu-lapu #domain:gocc-handover #xmatters #escalation #support-model
- **Description:** Generate a current roster report for all Japan xMatters groups, reconcile it against ServiceNow support-group routing, and define the target L1, L2, and L3 escalation structure needed for Ingenium onboarding and wider Japan incident handling. Share the baseline with David and Birger so static single-level rosters can be corrected before additional applications go live in GOCC.
- **Source:** Inbox — 20260507+-+Lapu-Lapu+GOCC+and+Japan.doc

---

## T084 — Resolve CMDB Mapping Gaps for Rapid Recovery Plan Automation
- **Status:** Open
- **Created:** 2026-03-17
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team:gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #system:cmdb
- **Relevance:** 87/100
- **Tags:** #project:lapu-lapu #program:r2r #automation #cmdb #data-quality
- **Description:** Resolve CI-number discrepancies between CMDB V9 and the source spreadsheets, confirm field mappings for all six Rapid Recovery Plan sections, and establish a pilot-ready data set for automated plan generation. This is the primary blocker called out in the automation deck and must be closed before generated RRPs can be trusted or scaled.
- **Source:** Inbox — Rapid Recovery Planning Automation Process.pdf

---

## T085 — Pilot Automated Rapid Recovery Plan Generation Workflow
- **Status:** Open
- **Created:** 2026-03-17
- **Objective Chain:** H-4 (Unified Support) → O4 (Robust Technical Core)
- **Team:** #team:gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #system:cmdb
- **Relevance:** 82/100
- **Tags:** #project:lapu-lapu #program:r2r #automation #runbooks #workflow
- **Description:** Build and pilot a workflow that extracts CMDB and ServiceNow data, maps it into the six-section Rapid Recovery Plan template, generates sample RRPs, routes them for SME review, and documents the ongoing generation runbook. Use the pilot to segment the 134-app scope, validate sample outputs, and close remaining gaps in contacts, triage content, and dependency data before scale-out.
- **Source:** Inbox — Rapid Recovery Planning Automation Process.pdf

---

## T086 — Standardize Ingenium Source Control and CI/CD for 3-Tier Delivery
- **Status:** Open
- **Created:** 2026-04-21
- **Objective Chain:** B-7 (PPS Service Improvement) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Balaji Ravi
- **Systems:** #system:ingenium
- **Relevance:** 86/100
- **Tags:** #project:lapu-lapu #project:epsilon #domain:modernisation #cicd #github #automation
- **Description:** Complete the Version Manager to GitHub migration plan and establish standard Jenkins-based CI/CD pipelines for Ingenium services in the new 3-tier architecture. The target state is a repeatable build, test, package, and non-production deployment flow with review discipline, auditability, and lower release risk.
- **Source:** Inbox — Epsilon_Ingenium-Modernization.pdf

---

## T087 — Validate Ingenium 3-Tier Production Rollout Readiness
- **Status:** Open
- **Created:** 2026-04-21
- **Objective Chain:** B-7 (PPS Service Improvement) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Balaji Ravi
- **Systems:** #system:ingenium #system:azure
- **Relevance:** 89/100
- **Tags:** #project:lapu-lapu #project:epsilon #domain:modernisation #production-readiness #testing
- **Description:** Coordinate the DEV and AQA validation needed before promoting the new 3-tier Ingenium platform into production, including end-to-end sanity checks, config and integration verification, rollback readiness, batch and non-functional testing, and pipeline gate evidence. The deliverable is a production-readiness decision backed by validated runbooks, smoke tests, and defect-triage evidence.
- **Source:** Inbox — Epsilon_Ingenium-Modernization.pdf

---

## T088 — Define AQA Testing Scope and Strategy for 3-Tier Architecture
- **Status:** Open
- **Created:** 2026-05-11
- **Objective Chain:** B-7 (PPS Service Improvement) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Balaji Ravi
- **Systems:** #system:ingenium
- **Relevance:** 88/100
- **Tags:** #project:lapu-lapu #project:epsilon #domain:modernisation #testing #aqa
- **Description:** AQA must define the full QA scope and engagement model for the Ingenium 3-tier architecture, covering infrastructure/failover testing, cross-tier integration, regression, and performance validation. QA scope expansion is understood conceptually but not operationally defined; this is the biggest execution blocker identified in the AQA alignment session. Prerequisite for T087.
- **Source:** Inbox — Re: Epsilon Kickoff Review: AQA Information Sharing Session (2026-05-11)

---

## T089 — Validate Load Balancer Impact on Cross-System Integrations
- **Status:** Open
- **Created:** 2026-05-11
- **Objective Chain:** B-7 (PPS Service Improvement) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Balaji Ravi
- **Systems:** #system:ingenium
- **Relevance:** 82/100
- **Tags:** #project:lapu-lapu #project:epsilon #domain:modernisation #testing #integration
- **Description:** Validate load balancer connection changes introduced by the 3-tier architecture against all external system integrations to avoid integration breaks. The LB impact on external systems is currently unclear, and data consistency validation across tiers needs a defined approach. Supports T010 and T087.
- **Source:** Inbox — Re: Epsilon Kickoff Review: AQA Information Sharing Session (2026-05-11)

---

## T090 — Onboard AQA Test Automation into Ingenium CI/CD Pipeline
- **Status:** Open
- **Created:** 2026-05-11
- **Objective Chain:** B-7 (PPS Service Improvement) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Balaji Ravi
- **Systems:** #system:ingenium
- **Relevance:** 90/100
- **Tags:** #project:lapu-lapu #project:epsilon #domain:modernisation #cicd #automation #aqa
- **Description:** Integrate AQA automation scripts into the Asia Jenkins pipeline for Ingenium, covering smoke, regression, and performance testing with direct pipeline-to-environment integration. This is a locked decision from the AQA alignment session and a core transformation lever. Delta project test cases will be reused for Epsilon migration testing. Extends T086.
- **Source:** Inbox — Re: Epsilon Kickoff Review: AQA Information Sharing Session (2026-05-11)

---

## T091 — Conduct Test Environment Provisioning Optimization Session
- **Status:** Open
- **Created:** 2026-05-11
- **Objective Chain:** B-7 (PPS Service Improvement) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** David Klan
- **Systems:** #system:ingenium #system:azure
- **Relevance:** 75/100
- **Tags:** #project:lapu-lapu #project:epsilon #domain:modernisation #environment #provisioning
- **Description:** Set up and run a session on test environment optimization to reduce provisioning friction for Epsilon environments. Currently provisioning is partially manual (Terraform + requests) and the Jenkins-to-GitHub-Actions transition path is undefined. Target is to unblock AQA automation and CI/CD integration.
- **Source:** Inbox — Re: Epsilon Kickoff Review: AQA Information Sharing Session (2026-05-11)

---

## T092 — Register Epsilon Modernization in Value Stream Epic for PI Planning
- **Status:** Open
- **Created:** 2026-05-11
- **Objective Chain:** B-7 (PPS Service Improvement) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** David Klan
- **Systems:** #system:ingenium
- **Relevance:** 70/100
- **Tags:** #project:lapu-lapu #project:epsilon #domain:modernisation #planning
- **Description:** Check whether the Epsilon AQA automation and testing work is registered as a Value Stream Epic and include it in PI Planning estimates. Ensures the resourcing and timeline for the expanded QA scope is visible in the planning cycle.
- **Source:** Inbox — Re: Epsilon Kickoff Review: AQA Information Sharing Session (2026-05-11)

---

## T093 — Implement User ID Login Workaround for Dashboards
- **Status:** Open
- **Created:** 2026-05-14
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team-gocc-observability
- **Assigned:** Joan Lee
- **Systems:** #system:newrelic #system:apm
- **Relevance:** 90/100
- **Tags:** #monitoring #dashboard #access
- **Description:** Implement a workaround using existing user IDs for dashboard login to avoid dependency on application endpoint exposure. Ensure compatibility with existing authentication models and validate usability across Japan dashboards.

---

## T094 — Create CI to APM ID Mapping Table
- **Status:** Open
- **Created:** 2026-05-14
- **Objective Chain:** B-6 (IT Asset Management & Evergreen Migration) → O4 (Robust Technical Core)
- **Team:** #team-gocc-observability
- **Assigned:** Joan Lee
- **Systems:** #system:cmdb #system:newrelic #system:leanix
- **Relevance:** 95/100
- **Tags:** #cmdb #mapping #apm
- **Description:** Create a standardized mapping table linking application CIs to APM IDs to resolve inconsistencies caused by LeanIX integration gaps. This will enable accurate service mapping and consistent tagging across monitoring systems.

---

## T095 — Establish Japan-Specific Runbook Repository
- **Status:** Open
- **Created:** 2026-05-14
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team-gocc-monitoring
- **Assigned:** Jonan Tan Pangan
- **Systems:** #system:cmdb
- **Relevance:** 85/100
- **Tags:** #runbook #incident-response #japan
- **Description:** Create a dedicated runbook repository for Japan operations to support localized incident response. Ensure alignment with Rapid Recovery Plan standards and maintain visibility for ETS Japan stakeholders.

---

## T096 — Execute MMM Level 2 Implementation for Japan Applications
- **Status:** Open
- **Created:** 2026-05-14
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team-gocc-observability
- **Assigned:** Joan Lee
- **Systems:** #system:newrelic #system:apm #system:cmdb
- **Relevance:** 100/100
- **Tags:** #mmm #omm #monitoring
- **Description:** Implement Monitoring Maturity Matrix (MMM) Level 2 for Japan applications, including tagging, APM onboarding, and policy setup. Coordinate with application owners to validate entity mappings and ensure monitoring coverage.

---

## T097 — Develop APM Policies for Ingenium System
- **Status:** Open
- **Created:** 2026-05-14
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team-gocc-observability
- **Assigned:** Joan Lee
- **Systems:** #system:apm #system:newrelic
- **Relevance:** 92/100
- **Tags:** #apm #ingenium #policy
- **Description:** Define and implement APM alert policies for the Ingenium system in coordination with infrastructure and engineering teams. Ensure coverage aligns with MMM Level 2 standards and supports proactive monitoring.

---

## T098 — Deploy Minions and Standardize Monitoring Scripts
- **Status:** Open
- **Created:** 2026-05-14
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team-gocc-observability
- **Assigned:** Joan Lee
- **Systems:** #system:newrelic
- **Relevance:** 95/100
- **Tags:** #synthetics #minions #monitoring
- **Description:** Set up synthetic monitoring minions across Japan environments and align PowerShell scripts with GOCC standards. Ensure consistent attribute naming and data formatting to support dashboard integration.

---

## T099 — Resolve APM Configuration Gaps in Ingenium Test Environment
- **Status:** Open
- **Created:** 2026-05-14
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team-gocc-observability
- **Assigned:** Joan Lee
- **Systems:** #system:apm #system:newrelic
- **Relevance:** 90/100
- **Tags:** #apm #troubleshooting #ingenium
- **Description:** Address issues with APM metric collection in the Ingenium test environment across regions. Work with observability teams to resolve configuration gaps and validate end-to-end data visibility.

---

## T100 — Onboard Logs to ADX and Integrate with Moogsoft
- **Status:** Open
- **Created:** 2026-05-14
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team-gocc-observability
- **Assigned:** Joan Lee
- **Systems:** #system:adx #system:moogsoft
- **Relevance:** 88/100
- **Tags:** #logs #adx #aiops
- **Description:** Enable centralized log ingestion into Azure Data Explorer (ADX) and integrate with Moogsoft via webhook for incident conversion. Coordinate with GCS team for onboarding and validate ingestion pipeline.

---

## T101 — Resolve Confluence Access Issue for Dashboard Documentation
- **Status:** Open
- **Created:** 2026-05-14
- **Objective Chain:** B-2 (Operational Standards & Procedure Compliance) → O4 (Robust Technical Core)
- **Team:** #team-ets-japan
- **Assigned:** Birger Fjaellman
- **Systems:** #system:jira
- **Relevance:** 70/100
- **Tags:** #access #documentation #confluence
- **Description:** Restore write access to the Confluence page for dashboard documentation to eliminate workflow friction. Ensure proper permissions and prevent future access disruptions.

---

## T102 — Add Missing Applications to LeanIX with Ownership and URLs
- **Status:** Open
- **Created:** 2026-05-14
- **Objective Chain:** B-6 (IT Asset Management & Evergreen Migration) → O4 (Robust Technical Core)
- **Team:** #team-gocc-observability
- **Assigned:** Joan Lee
- **Systems:** #system:leanix #system:cmdb
- **Relevance:** 92/100
- **Tags:** #leanix #cmdb #ownership
- **Description:** Register missing Japan applications (e.g., BPM, EMC) in LeanIX with correct ownership and URLs. Ensure alignment with CMDB and enable accurate service mapping and monitoring onboarding.

---

## T103 — Standardize Script Attributes and Share Integration Logic
- **Status:** Open
- **Created:** 2026-05-14
- **Objective Chain:** B-3 (Pipeline Standardization & Secrets Remediation) → O2 (Dynamic Delivery Experience)
- **Team:** #team-gocc-observability
- **Assigned:** Joan Lee
- **Systems:** #system:newrelic
- **Relevance:** 85/100
- **Tags:** #automation #scripts #integration
- **Description:** Align attribute naming conventions and data formats in monitoring scripts across teams and share integration scripts for dashboard data collection. Improve maintainability and consistency for dashboard pipelines.

---

## T104 — Develop Outbound Messaging Mis-send Runbook
- **Status:** Open
- **Created:** 2026-05-22
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team:gocc-monitoring
- **Assigned:** Jonan Tan Pangan
- **Systems:** #system:moogsoft #system:xmatters
- **Relevance:** 88/100
- **Tags:** #project:lapu-lapu #program:r2r #worktype:incident-management #outcome:resilience
- **Description:** Create a dedicated "Outbound Messaging Mis-send / Mass Notification" runbook covering containment (stop sends, activate suppression), stakeholder notification, and volume-baseline validation. The existing batch failure runbook (KB0033382) does not cover scenarios where the batch succeeded but produced wrong outbound communications. Triggered by INC08574374 incident analysis.

---

## T105 — Implement Batch-to-Notification Volume Anomaly Detection
- **Status:** Open
- **Created:** 2026-05-22
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) → O1 (Frictionless Customer Experience)
- **Team:** #team:gocc-observability
- **Assigned:** Debamalya Das
- **Systems:** #system:newrelic #system:moogsoft
- **Relevance:** 90/100
- **Tags:** #project:lapu-lapu #worktype:monitoring #outcome:mttd #outcome:resilience
- **Description:** Implement automated pre-send validation and volume anomaly detection for batch-to-notification flows. Include outbound message rate and unique-recipient spike alerts, pre-flight recipient count vs historical baseline checks, and batch input delta monitoring. Addresses the detection gap identified in INC08574374 where 70,000 unintended SMS/LINE messages were sent without any automated alert firing.

---

## T106 — Deliver Scenario-Based RRPs for 6 Gold Applications
- **Status:** Open
- **Created:** 2026-05-26
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Balaji Ravi
- **Systems:** #system:cmdb
- **Relevance:** 92/100
- **Tags:** #project:lapu-lapu #program:r2r #worktype:disaster-recovery #outcome:resilience #priority:regulatory
- **Description:** Complete Rapid Recovery Plans for the 6 regulatory-priority Gold applications using the mandatory standard template with 3 scenario types (restart-based, workaround+restart, non-restart). Reboot/restart sequences due June 10; full audit-ready RRP completion due June 30. RRPs must be submitted to Thabani for validation and KB publishing — no self-publishing. RRPs linked via PEM to CIs in Knowledge Base; production readiness gate requires RRP + SRD + DR.

---

## T107 — Integrate Restart Runbooks into RRP Baseline
- **Status:** Open
- **Created:** 2026-05-26
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) → O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Balaji Ravi
- **Systems:** #system:cmdb
- **Relevance:** 85/100
- **Tags:** #project:lapu-lapu #program:r2r #worktype:documentation #outcome:resilience
- **Description:** Pull and integrate restart runbooks from Kanagaraj's team into the RRP baseline for Gold applications. Restart procedures are a critical prerequisite — restart-based recovery scenarios cannot be authored without validated reboot/restart sequences. Identify restart-resolvable failure patterns from existing incident analysis for each Gold app. Dependency for T106.
