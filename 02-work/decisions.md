# Decisions Log

## D001 — Deferred: Ad-Hoc Dashboard Request from Marketing

tags: #project:lapu-lapu #domain:rejected #system:newrelic #outcome:unaligned

**Date:** 2026-03-18
**Decision:** Deferred
**Reason:** Does not map to any Tier-2 or Tier-3 objective. Marketing lacks a defined SLA for landing page performance, and the request does not contribute to H-3 (AI Ops) or any scoped monitoring objective. Recommended Marketing raise a formal demand through the PMO for prioritisation in the next planning cycle.
**Related Objectives:** none
**Owner:** David Klan

---

## D002 — Agreed: GOCC Delivery Model for Japan Monitoring

tags: #project:lapu-lapu #domain:gocc-handover #system:newrelic #system:cmdb #system:xmatters #outcome:resilience

**Date:** 2026-03-26
**Decision:** Approved
**Summary:** Directionally agreed GOCC delivery model for Japan-based monitoring. Top monitoring priorities in order: (a) URL availability, (b) Performance / APM, (c) Rapid Recovery. GOCC handles standardised monitoring and first response. Application teams retain ownership of application logic, auth flows, and runbooks. ServiceNow CMDB must maintain relationships between Applications, Application Services, and Components (DB, middleware, etc.). Support groups and xMatters registration must remain current. Certificate renewals are already automated via GOCC. SPN renewals to adopt Managed Identity + federated credentials. Service account password management identified as a further automation opportunity (vaulting).
**Related Objectives:** H-3 (AI Ops / Incident Troubleshooting), H-4 (Unified Support), B-1 (Endpoint Monitoring & Post-Change Verification), B-4 (Infrastructure Resilience & DR)
**Owner:** David Klan
**Source:** GOCC 2026-03-26 New Relic Monitoring meeting

---

## D003 — Agreed: Simplify Patching for GOCC Handover and Weekday Execution

tags: #project:lapu-lapu #domain:patching #system:azure #outcome:resilience #domain:gocc-handover

**Date:** 2026-03-17
**Decision:** Approved (directional)
**Summary:** Agreed that the Japan patching process should be simplified and documented so that GOCC can execute patching independently, reducing dependency on ETS engineering resources. Weekday patching is the target but currently blocked by manpower constraints (split windows require split engineers) and incomplete Ansible automation. Birger's team is allocating engineers to protect batch operations during patching windows. Kanagaraj to document the end-to-end process and challenges as a prerequisite. Standard BAU Change transition for production patching to be pursued in parallel via a standard server template with application name mapping (Hideo).
**Related Objectives:** B-4 (Infrastructure Resilience & Disaster Recovery), H-4 (Unified Support), O4 (Robust Technical Core)
**Owner:** Birger Fjaellman
**Source:** 2026-03-17 Patching Schedule and Possible Standard BAU Transition meeting

---

## D004 — Agreed: Japan Incident Documentation & CI Standards

tags: #project:lapu-lapu #domain:incident-management #program:r2r #system:cmdb #outcome:mttr

**Date:** 2026-03-30
**Decision:** Approved
**Summary:** Agreed to standardize Japan incident documentation using a structured template from the Knowledge Management / Base R2R deck. All documentation must be searchable by Configuration Items (CIs) and include Key Contacts and Rapid Response (RR) contacts. Japan incidents will explicitly identify Primary CI, Supporting CI components, and CI(s) designed for rapid recovery execution. Employee Experience Dashboard to be completed within 2 weeks in collaboration with OAR team to provide visibility into user impact and incident trends. ADS and xMatters groups to be added for enhanced alerting/escalation. A standardized vendor escalation procedure format will be defined.
**Related Objectives:** H-3 (AI Ops / Incident Troubleshooting), B-4 (Infrastructure Resilience & Disaster Recovery), B-1 (Endpoint Monitoring & Post-Change Verification), O1 (Frictionless Customer Experience)
**Owner:** George Francis Fermo
**Source:** 2026-03-30 Japan Team - Global Incident Management w/ Rohina meeting

---

## D005 — Agreed: Phase-1 Checklist and Impact-Based Alerting Govern PS-to-GOCC Transition

tags: #project:lapu-lapu #domain:gocc-handover #system:newrelic #system:moogsoft #outcome:resilience

**Date:** 2026-04-16
**Decision:** Approved
**Summary:** PS will continue parallel monitoring for a limited post-go-live period while GOCC ramps to full ownership. The Phase-1 checklist is the authoritative tracker for PS-to-GOCC handover status and the source for weekly transition reporting. Alerting must prioritize customer and application impact, and host-level noise must not drive workload health or incident posture. Rapid recovery enablement will include a bilingual alignment session with Japan Production Support.
**Related Objectives:** H-3 (AI Ops / Incident Troubleshooting), H-4 (Unified Support), B-4 (Infrastructure Resilience & Disaster Recovery)
**Owner:** David Klan
**Source:** 2026-04-16 Lapu-Lapu GOCC and Japan meeting

---

## D006 — Deferred: Approval Workflow Automation and ServerF Ownership Side Quests

tags: #project:lapu-lapu #domain:workflow-automation #domain:service-management #outcome:unaligned

**Date:** 2026-04-16
**Decision:** Deferred
**Summary:** April 16 side-quest notes include SNOW or Teams approval reminders, manager escalation after 24 hours, and ownership clarification for ServerF file share and MFT activities. These ideas may be useful, but they are not yet tied to a registered objective, supported system-of-record tag set, or confirmed sponsoring team in this repository.
**Related Objectives:** none
**Owner:** David Klan
**Source:** 2026-04-16 Side Quests and Team Direction notes

---

## D007 — Agreed: Escalate Non-Standard Monitoring Apps Instead of Building Workarounds

tags: #project:lapu-lapu #domain:monitoring #system:newrelic #outcome:resilience

**Date:** 2026-04-23
**Decision:** Approved
**Summary:** For Japan dashboard onboarding, non-standard monitoring applications should be escalated to the owning application or development team instead of creating new ad hoc workaround patterns. If Production Support already has an application ID configured in New Relic, GOCC should reuse it as-is; otherwise the gap is treated as an escalation item. Legacy dashboards may still provide reusable URLs, but workaround creation is no longer the default path.
**Related Objectives:** B-1 (Endpoint Monitoring & Post-Change Verification), H-3 (AI Ops / Incident Troubleshooting), O1 (Frictionless Customer Experience)
**Owner:** David Klan
**Source:** 2026-04-23 Lapu-Lapu GOCC and Japan meeting

---

## D008 — Deferred: Gopher PRD POC Remains Outside the Current Objective-Scoped Workset

tags: #project:lapu-lapu #domain:service-management #outcome:unaligned

**Date:** 2026-04-23
**Decision:** Deferred
**Reason:** The "Gopher" PRD proof-of-concept called out in the Team Direction notes is a live operational ask, but it is not mapped to a registered Tier-2 or Tier-3 objective and the repository does not contain enough system-of-record context to classify or assign it cleanly. Revisit once the sponsoring objective, owning team, and required system tags are explicit.
**Related Objectives:** none
**Owner:** Birger Fjaellman
**Source:** 2026-04-23 Team Direction and Execution notes

---

## D009 — Agreed: SRM Incident Requires Explicit Validation and Recovery Readiness

tags: #project:lapu-lapu #domain:incident-management #program:r2r #outcome:resilience

**Date:** 2026-04-24
**Decision:** Approved
**Summary:** The SRM incident review concluded that production support needs explicit validation steps, enforceable runbooks, and a clear restart or recovery path when incidents require application restart. Rapid Recovery onboarding will be used to close authority, documentation, and recovery-readiness gaps for SRM and similar applications while RCA work continues on the underlying cause.
**Related Objectives:** B-4 (Infrastructure Resilience & Disaster Recovery), H-4 (Unified Support), O4 (Robust Technical Core)
**Owner:** David Klan
**Source:** Meeting Summary: SRM Certificate Incident, Operational Gaps, and Rapid Recovery Onboarding

---

## D010 — Agreed: AQA Automation into Jenkins and Delta Test Case Reuse for Epsilon

tags: #project:lapu-lapu #project:epsilon #domain:modernisation #cicd #automation #aqa

**Date:** 2026-05-11
**Decision:** Approved (locked)
**Summary:** Two key decisions were locked in the AQA Information Sharing Session: (1) AQA automation scripts will be onboarded into the Asia Jenkins pipeline for Ingenium CI/CD, standardizing on Jenkins as the short-term CI/CD platform; (2) Delta project test cases will be reused for Epsilon migration testing, accelerating test coverage without writing from scratch. A planned transition to GitHub Actions is acknowledged but not yet ready or fully functional; the migration path remains unclear.
**Related Objectives:** B-7 (PPS Service Improvement), B-3 (Pipeline Standardization & Secrets Remediation), O4 (Robust Technical Core)
**Owner:** Balaji Ravi
**Source:** Re: Epsilon Kickoff Review: AQA Information Sharing Session (2026-05-11)

---

## D011 — Agreed: Mandatory RRP Template with Controlled Publishing

tags: #project:lapu-lapu #program:r2r #domain:rapid-recovery #outcome:resilience #priority:regulatory

**Date:** 2026-05-26
**Decision:** Approved
**Summary:** All Rapid Recovery Plans must use the approved standard template covering triage steps, recovery sequences, and scenario-based documentation (3 scenario types: restart-based, workaround+restart, non-restart). No self-publishing — all RRPs must be submitted to Thabani for validation and KB publishing. RRPs are living documents with continuous updates expected. Production readiness gate requires RRP + SRD + DR before go-live (Infra intake process). GOCC (George/Jonan) acts as extension of app support driving triage speed; post-incident RRP updates will be triggered via Incident/Problem Management with Rohina team covering Problem + Change alignment.
**Related Objectives:** B-4 (Infrastructure Resilience & Disaster Recovery), H-4 (Unified Support), O4 (Robust Technical Core)
**Owner:** Balaji Ravi
**Source:** 20260526 - RRP Touchpoint (Confluence export)

---

## D012 — Agreed: Shift Batch & MFT L0/L1 Operations to GOCC/GBO

tags: #project:lapu-lapu #domain:batch #domain:mft #domain:gocc-handover #capability:automation

**Date:** 2026-05-28
**Decision:** Approved (directional)
**Summary:** Confirmed direction to shift from project execution to a BAU service model for batch and file transfer operations. L0/L1 operational activities will transfer from Batch/PS/App support teams to GOCC (infrastructure + file transfer) and GBO (batch execution). Standardize all batch execution via the CAWLA platform. Non-production operations will serve as the testbed for ownership clarity, automation validation, and operating model design before production transition. Current batch operations depend on a multi-vendor model (Geantec, Cognizant, Tech Mahindra) with fragmented ownership. Transition is contingent on completing a full batch job inventory, application-to-team ownership mapping, and end-to-end job/file flow mapping. Parallel monitoring setup accepted for the current year with formal transition targeted next year. IS contract constraints (GienTech transition, fixed-bid) mean savings will be indirect.
**Related Objectives:** H-1 (Batch Automation), H-4 (Unified Support), O6 (Technology Transformation through AI & Automation)
**Owner:** David Klan
**Source:** 20260528 - Batch Non-Prod Team syncup + Japan Batch/MFT Opportunities Meeting
## D013 — Agreed: Trim Developer Experience Dashboard Alerting to Actionable Signals Only
- **Date:** 2026-06-09
- **Requestor:** David Klan / Rae Judavar / Debamalya Das
- **Request:** Decide how much of the Developer Experience Dashboard signal surface should fire as real-time alerts vs sit in the dashboard or the daily summary email.
- **Decision:** Agreed
- **Reason:** AQA beta and operational experience show non-actionable notifications dilute responder attention; we will route only actionable signals (red) to responders via push/real-time alerts, keep the full data surface in the dashboard (yellow, pull), and rely on the daily summary email (green) as the one-page health view. Sleeping systems and other false-alert sources will be tuned out, and New Relic subscription workloads will let users subscribe to alerts for specific systems or environments.
- **Tags:** #project:lapu-lapu #area:dev-xp #domain:alerting #domain:noise-reduction

---

## D014 — Agreed: Include Shared-Folder ACL Compliance Monitoring in Lapu-Lapu Scope
- **Date:** 2026-06-09
- **Requestor:** David Klan / Birger Fjaellman / Aleksei Radzeveliuk
- **Request:** Decide whether shared-folder ACL inventory and compliance monitoring belongs in the Lapu-Lapu workstream now that file-server migration is being blocked by outdated accounts and unclear ownership (after the 2026-06-04 stance to keep file share / file transfer separate).
- **Decision:** Agreed
- **Reason:** The lack of a regular inventory and monitoring for shared-drive ACLs has produced persistent outdated accounts, unclear ownership, and unenforced retention; the previous Veronis capability was decommissioned without replacement. Aleksei has already built a compliance checker and folder governance can be piloted on small migrated shares. GOCC Middleware Operations is the prospective long-term owner. File transfer and batch jobs remain a separate workstream (D012); only ACL compliance is in scope here.
- **Tags:** #project:lapu-lapu #area:gocc-transition #domain:acl #domain:fileshare

---

## D015 — Agreed: Mandatory Server Restart Authorization Decision Matrix in Every RRP
- **Date:** 2026-06-09
- **Requestor:** David Klan / Jonan Tan Pangan / Kiran Bonde
- **Request:** Decide whether RRPs must explicitly document who can authorize a server restart and under what circumstances, given the recent Ingenium freeze (INC08624117) and the broader Rapid Recovery rollout.
- **Decision:** Agreed
- **Reason:** Server restarts in Japan have ambiguous authorization paths that slow Rapid Recovery and create downstream blame surface. Every RRP will include a decision matrix and guardrails identifying the responsible parties (app owner, GOCC, vendor) and the circumstances that permit a restart, integrated into the mandatory RRP template (D011) so the 6 Gold apps and all future RRPs inherit the same authorization model.
- **Tags:** #project:lapu-lapu #area:rapid-recovery #domain:governance #domain:authorization

---

## D016 — Agreed: Park R2R-Scope ADX Onboarding Push Until App-Driven Demand Materializes
- **Date:** 2026-06-16
- **Requestor:** David Klan / Balaji Ravi / Hari Pothakamuri
- **Request:** Decide whether to continue pushing central logging / ADX onboarding for Japan applications at the R2R workstream level after the COUE response cycle was already bypassed (W23–W24) by repositioning ADX onboarding as an app-owner responsibility.
- **Decision:** Agreed (parked)
- **Reason:** After discussion with Hari and Tabitha, R2R-scope ADX onboarding was dropped; ADX onboarding is now an app-owner responsibility with catalog-based onboarding instructions sent to non-compliant teams. Going forward, incident analysis will guide whether central logging is required for specific apps/components rather than a top-down push, and Yegor has ADX ACL access to support local investigations. The push resumes only when Balaji explicitly signals "engage". Asia ownership for ADX log monitoring, management, and audit remains in scope under T116.
- **Tags:** #project:lapu-lapu #area:adx-registration #domain:logging #domain:governance

---

## D017 — Agreed: GOCC Transitions to Unified Operating Model Without L1/L2 Silos in September
- **Date:** 2026-06-18
- **Requestor:** Jonan Tan Pangan / Birger Fjaellman / Balaji Ravi
- **Request:** Decide the post-September GOCC support structure for Japan market applications and whether the existing L1/L2 silo runbook structure should remain in the interim.
- **Decision:** Agreed
- **Reason:** By September the GOCC will transition to a unified operational team without L1/L2 silos, with a single engineer handling the full support flow. The current structure and resources remain unchanged until cutover so the existing Ingenium runbook is retained for Japan market applications and updated to the new GOCC model immediately after September. The L0 (automation) → L1 → L2 (specialized troubleshooting not covered by procedures) → L3 (unresolved/complex) procedural flow is preserved in the interim, and the runbook update will follow the new format/versioning standard tracked under T134.
- **Tags:** #project:lapu-lapu #area:gocc-transition #domain:operating-model #domain:escalation

---

## D018 — Agreed: Lock GBO Japan Batch Transition Execution Plan, Operating Principles, and September Pilot Timeline
- **Date:** 2026-06-24
- **Requestor:** David Klan / Balaji Ravi / GBO (Rowena Zulueta)
- **Request:** Lock the executable transition plan for migrating Japan batch operations into a GBO-owned 24x7 operating model, including operating principles, scope, work breakdown, and a September pilot cutover.
- **Decision:** Agreed
- **Reason:** D012 set the directional shift to GBO/GOCC ownership; the 2026-06-24 level-set with GBO converts it into an executable plan. Operating principles confirmed: centralized GBO execution of batch workloads 24x7, Japan teams shift from execution to stability/input management/failure prevention, strict "No runbook = No onboarding" onboarding gate, and full alignment with the Lapu-Lapu global operating model. Phase-1 scope confirmed as CA batch jobs (primary focus), test-environment front-system batch operations (MLK, SCV, AGW, SSW, PAweb, WFI, BPM), and L0/L1 operational activities; manual/non-CA jobs deferred pending inventory + readiness validation. Work breakdown (WP1–WP7) covers operating model, inventory baseline, runbook standardization, execution readiness, pilot implementation, Ingenium parallel track, and governance/reporting. Timeline locked: Discovery & Inventory now → mid-July; Onsite GBO Deployment mid-July; Runbook Build & Dry Runs late July → August; Pilot Cutover September. Top risks: incomplete inventory (esp. non-CA/manual jobs), unclear ownership, unproven 24x7 readiness, missing/poor runbooks, lack of Japan on-site support — each with assigned mitigations (T108, T135, T136, T137, T138). Four follow-up confirmations required: (a) GBO full ownership of batch execution (24x7), (b) Japan input responsibilities (inventory + runbooks), (c) pilot application selection (front system), (d) timeline alignment (July readiness → September pilot).
- **Related Objectives:** H-1 (Batch Automation), H-4 (Unified Support), O6 (Technology Transformation through AI & Automation)
- **Owner:** David Klan
- **Tags:** #project:lapu-lapu #domain:batch #area:gocc-transition #domain:operating-model #domain:governance
- **Source:** Inbox — archive/20260624+-+GBO+Batch+Transition.doc
