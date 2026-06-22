"""Append intake tasks (T112-T125) and decisions (D013-D015) for the 2026-06-09 inbox batch."""
from pathlib import Path

EM = "\u2014"
ARROW = "\u2192"

tasks = f"""
## T112 {EM} Schedule and Run PS Team Sharing Session for Employee Experience Dashboard
- **Status:** Open
- **Created:** 2026-06-04
- **Objective Chain:** B-1 (Endpoint Monitoring & Post-Change Verification) {ARROW} O3 (Outstanding Colleague Experience)
- **Team:** #team:ets-japan
- **Assigned:** David Klan
- **Systems:** #system:newrelic
- **Relevance:** 80/100
- **Tags:** #project:lapu-lapu #area:employee-xp #worktype:enablement #audience:ps-team
- **Description:** Schedule and deliver a sharing session with the Japan PS Team for the Employee Experience Dashboard (Prod), including Branch Office monitoring scope. Walk through the dashboard layout, alerting parameters, and the access path so PS support staff can self-serve health checks. Targeted to take place within the week following 2026-06-04 GOCC/Japan touchpoint.
- **Source:** Inbox {EM} archive/20260604+-+Lapu-Lapu+GOCC+and+Japan.doc

---

## T113 {EM} Build URL Onboarding Data Diff vs ServiceNow for GOCC URL Monitoring Quality
- **Status:** Open
- **Created:** 2026-06-04
- **Objective Chain:** B-1 (Endpoint Monitoring & Post-Change Verification) {ARROW} O4 (Robust Technical Core)
- **Team:** #team:gocc-monitoring
- **Assigned:** Jonan Tan Pangan
- **Systems:** #system:newrelic #system:cmdb
- **Relevance:** 80/100
- **Tags:** #project:lapu-lapu #area:gocc-transition #area:dev-xp #domain:data-quality #worktype:tooling
- **Description:** Build a periodic diff between the URL onboarding data source used by GOCC URL Monitoring and ServiceNow to flag quality issues seen during onboarding (e.g., entries with strike-through fonts, stale or mislabeled URLs). Output a short exception list that GOCC and Japan can triage weekly. Required to keep the URL monitoring transition to GOCC trustworthy and avoid handover noise.
- **Source:** Inbox {EM} archive/20260604+-+Lapu-Lapu+GOCC+and+Japan.doc

---

## T114 {EM} Author OAR PRD for Branch Dashboard & DC Minion Comparison Reports
- **Status:** Open
- **Created:** 2026-06-04
- **Objective Chain:** B-1 (Endpoint Monitoring & Post-Change Verification) {ARROW} O1 (Frictionless Customer Experience)
- **Team:** #team:ets-japan
- **Assigned:** David Klan
- **Systems:** #system:newrelic
- **Relevance:** 75/100
- **Tags:** #project:lapu-lapu #area:employee-xp #worktype:requirements #artifact:prd
- **Description:** Author a Product Requirements Document (PRD) for Branch Office dashboards and DC Minion comparison reports between nodes, then send it to the OAR Team (Debamalya Das, Edward Ian Vera, Jesusjr Pepito, Paula Segovia) for build. Comparison report should highlight node-to-node deltas to surface configuration drift or coverage gaps across branch sites and DC minion fleets.
- **Source:** Inbox {EM} archive/20260604+-+Lapu-Lapu+GOCC+and+Japan.doc

---

## T115 {EM} Engage xMatters Vendor for Japan Group/Member Registration Quality Control
- **Status:** Open
- **Created:** 2026-06-04
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) {ARROW} O1 (Frictionless Customer Experience)
- **Team:** #team:gocc-observability
- **Assigned:** Jonan Tan Pangan
- **Systems:** #system:xmatters
- **Relevance:** 80/100
- **Tags:** #project:lapu-lapu #area:rapid-recovery #domain:on-call #worktype:vendor-engagement
- **Description:** Through OAR (Edward Ian Vera lead), engage the xMatters vendor to deliver a quality report on Japan groups and member registrations and put in place ongoing quality control for updated group and member data. Complements T083 (internal xMatters roster and escalation model) by closing the data-quality loop on vendor-managed records.
- **Source:** Inbox {EM} archive/20260604+-+Lapu-Lapu+GOCC+and+Japan.doc

---

## T116 {EM} Establish ADX Coverage Assessment and Asia Ownership for Japan Gold Apps
- **Status:** Open
- **Created:** 2026-06-04
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) {ARROW} O4 (Robust Technical Core)
- **Team:** #team:gocc-observability
- **Assigned:** Jonan Tan Pangan
- **Systems:** #system:adx #system:moogsoft
- **Relevance:** 90/100
- **Tags:** #project:lapu-lapu #area:adx-registration #area:mmm-l2 #worktype:assessment #ownership:asia
- **Description:** Validate ADX coverage for Japan applications, confirming firewall openings and agent installation status per server, then identify applications whose components are not sending logs to ADX. Send catalog-based onboarding instructions to non-compliant application teams. In parallel, stand up an Asia-based ownership model (GOCC Middleware Operations + Observability) for ADX log monitoring, management, and audit so ADX onboarding is no longer dependent on COUE response cycles. Jonan to update David by Thursday or the following week; outcome feeds KR007 baseline.
- **Source:** Inbox {EM} archive/20260604+-+Lapu-Lapu+GOCC+and+Japan.doc, archive/20260609+LapuLapu+ETS,+GOCC+and+Obs.doc

---

## T117 {EM} Define Shared-Folder ACL Compliance Monitoring Capability
- **Status:** Open
- **Created:** 2026-06-09
- **Objective Chain:** B-5 (Security, Data Integrity & Encryption) {ARROW} O4 (Robust Technical Core)
- **Team:** #team:gocc-observability
- **Assigned:** Joan Lee
- **Systems:** #system:fileshare
- **Relevance:** 75/100
- **Tags:** #project:lapu-lapu #area:gocc-transition #domain:acl #domain:fileshare #worktype:assessment
- **Description:** Assess whether GOCC Middleware Operations can monitor shared-folder ACL compliance against the standard mfcgd\\acl_{{folder_name}}_{{tier}} model, including detection of missing required groups (_C, _R), incorrect rights, unexpected additional principals, and ACL read failures. Define scope control and false-positive handling for unmanaged folders. Reuse the SharePoint permission and retention profiles where applicable. Coordinate with Aleksei Radzeveliuk's compliance checker and an Aleksei-led pilot on small migrated shares; check with Dong for existing scripts. Feeds the broader file-server migration and retention cleanup.
- **Source:** Inbox {EM} archive/20260609+LapuLapu+ETS,+GOCC+and+Obs.doc

---

## T118 {EM} Tighten Developer Experience Dashboard Alerting Parameters with AQA Beta
- **Status:** Open
- **Created:** 2026-06-09
- **Objective Chain:** B-1 (Endpoint Monitoring & Post-Change Verification) {ARROW} O4 (Robust Technical Core)
- **Team:** #team:gocc-monitoring
- **Assigned:** Rae Judavar
- **Systems:** #system:newrelic
- **Relevance:** 85/100
- **Tags:** #project:lapu-lapu #area:dev-xp #worktype:alerting #domain:noise-reduction
- **Description:** With the Developer Experience Dashboard in beta with AQA users, tighten alerting parameters so only actionable signals (push, real-time) are routed to responders, while the dashboard (pull) keeps all data across all environments and the daily summary email (Rae) keeps the one-page health view. Refine alerting rules to handle sleeping systems and avoid false alerts. Pair with subscription-based alert workloads in New Relic so users can subscribe to alerts for specific systems or environments.
- **Source:** Inbox {EM} archive/20260609+LapuLapu+ETS,+GOCC+and+Obs.doc

---

## T119 {EM} Extend Daily Summary Email & Alert Tuning Pattern to Employee Experience Dashboard
- **Status:** Open
- **Created:** 2026-06-09
- **Objective Chain:** B-1 (Endpoint Monitoring & Post-Change Verification) {ARROW} O1 (Frictionless Customer Experience)
- **Team:** #team:ets-japan
- **Assigned:** David Klan
- **Systems:** #system:newrelic
- **Relevance:** 80/100
- **Tags:** #project:lapu-lapu #area:employee-xp #worktype:alerting #worktype:reporting
- **Description:** Apply the lessons learned from the Developer Experience Dashboard (alert vs dashboard vs morning email split, actionable-only routing, subscription model) to the Employee Experience Dashboard and other production systems for comprehensive coverage. Coordinate with Mary Kris Cabunilas and Rae Judavar on shared tuning patterns and confirm responder routing for Japan prod alerts.
- **Source:** Inbox {EM} archive/20260609+LapuLapu+ETS,+GOCC+and+Obs.doc

---

## T120 {EM} Schedule Ingenium APM Production Rollout (Outage Coordination)
- **Status:** Open
- **Created:** 2026-06-09
- **Objective Chain:** B-1 (Endpoint Monitoring & Post-Change Verification) {ARROW} O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Angelito Darjuan
- **Systems:** #system:apm #system:ingenium
- **Relevance:** 85/100
- **Tags:** #project:lapu-lapu #area:mmm-l2 #system:ingenium #worktype:rollout
- **Description:** APM has been configured successfully for Ingenium non-production environments (Angelito, Sai); schedule the production rollout including the required outage window and CHG#. Coordinate with Jesus Pepito and Prabu Thiagarajan to confirm rollout plan, validation steps, and rollback path. Production APM coverage on Ingenium is the first non-AKS APM activation and a precursor to MMM L2 declaration for Ingenium.
- **Source:** Inbox {EM} archive/20260609+LapuLapu+ETS,+GOCC+and+Obs.doc

---

## T121 {EM} Follow Up with Harish on Remaining Japan App MMM L2 Updates
- **Status:** Open
- **Created:** 2026-06-09
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) {ARROW} O1 (Frictionless Customer Experience)
- **Team:** #team:ets-japan
- **Assigned:** David Klan
- **Systems:** #system:newrelic #system:apm
- **Relevance:** 80/100
- **Tags:** #project:lapu-lapu #area:mmm-l2 #worktype:tracking
- **Description:** Harish has reached out to all Japan application owners for MMM L2 updates and completed data collection for Ingenium; remaining application updates are expected by Friday. Follow up with Harish at end of week to consolidate the responses, post the per-app status against the MMM L2 declaration checklist, and update KR003. Share the MMM L2 checklist and project plan back to the working group (Debamalya owns checklist distribution).
- **Source:** Inbox {EM} archive/20260609+LapuLapu+ETS,+GOCC+and+Obs.doc

---

## T122 {EM} Document Server Restart Authorization Decision Matrix in RRP Standard
- **Status:** Open
- **Created:** 2026-06-09
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) {ARROW} O4 (Robust Technical Core)
- **Team:** #team:gocc-monitoring
- **Assigned:** Jonan Tan Pangan
- **Systems:** #system:cmdb
- **Relevance:** 85/100
- **Tags:** #project:lapu-lapu #area:rapid-recovery #worktype:standards #domain:governance
- **Description:** With David Klan and Kiran Bonde, document a decision matrix and guardrails for server restart authorization inside every Rapid Recovery Plan. Specify which roles can authorize a restart, the circumstances under which the authorization is valid, and the escalation path if criteria are not met. Roll into the mandatory RRP template (D011) so all 6 Gold apps and future RRPs inherit the same authorization model.
- **Source:** Inbox {EM} archive/20260609+LapuLapu+ETS,+GOCC+and+Obs.doc

---

## T123 {EM} Investigate INC08624117 Ingenium Server Freeze with Red Hat Vendor
- **Status:** Open
- **Created:** 2026-06-09
- **Objective Chain:** H-3 (AI Ops / Incident Troubleshooting) {ARROW} O1 (Frictionless Customer Experience)
- **Team:** #team:gocc-monitoring
- **Assigned:** Jonan Tan Pangan
- **Systems:** #system:ingenium
- **Relevance:** 85/100
- **Tags:** #project:lapu-lapu #area:rapid-recovery #system:ingenium #worktype:incident-management #severity:p2
- **Description:** Ingenium server freeze (INC08624117, 2026-06-08) was resolved with a restart, but root cause remains under investigation by Red Hat. Jonan to follow up with Dennis Talento for vendor log analysis updates, drive the post-incident review, and capture findings against the Ingenium incident analysis baseline (Ing_INC_6Months). Confirm whether GOCC Middleware Operations should take on the post-restart application health check pattern Jonan proposed.
- **Source:** Inbox {EM} archive/20260609+LapuLapu+ETS,+GOCC+and+Obs.doc, archive/GOCC+_+Japan+-+Lapu-Lapu+project.doc

---

## T124 {EM} Onboard Philippine Branch Office Laptop Monitoring (Agent Install + Dashboard)
- **Status:** Open
- **Created:** 2026-06-09
- **Objective Chain:** B-1 (Endpoint Monitoring & Post-Change Verification) {ARROW} O1 (Frictionless Customer Experience)
- **Team:** #team:gocc-observability
- **Assigned:** Vignesh M
- **Systems:** #system:newrelic
- **Relevance:** 75/100
- **Tags:** #project:lapu-lapu #area:employee-xp #domain:branch-office #worktype:onboarding
- **Description:** Donna has submitted a REQ to install the monitoring agent on a laptop in the Philippine branch office. Once installation completes, Aleksei Radzeveliuk will assist with configuration and Vignesh M will work with GOCC on setting up the Philippine branch office dashboard. Run the requirements-gathering call between Aleksei, Donna, and Vignesh to confirm metrics, alerting, and dashboard layout. Mirrors the Japan branch monitoring model (10 JP laptops already in service).
- **Source:** Inbox {EM} archive/20260609+LapuLapu+ETS,+GOCC+and+Obs.doc

---

## T125 {EM} Unblock JPE/JPW Production VNet Subscription Networking Issue
- **Status:** Open
- **Created:** 2026-06-09
- **Objective Chain:** B-4 (Infrastructure Resilience & Disaster Recovery) {ARROW} O4 (Robust Technical Core)
- **Team:** #team:ets-japan
- **Assigned:** Jesus Pepito
- **Systems:** #system:azure
- **Relevance:** 80/100
- **Tags:** #project:lapu-lapu #area:employee-xp #domain:network #domain:branch-office #worktype:infrastructure
- **Description:** Japan East / West non-production VNet setup is complete (post-provisioning issue awaiting fix) but production VNet updates are still pending due to subscription networking issues. Drive the subscription networking fix to closure and complete production VNet provisioning so the JPE/JPW Synthetic Job Monitor agents / minions can be deployed against the new dashboard. Confirm dates with the network team and unblock the cross-location branch observability sequence.
- **Source:** Inbox {EM} archive/20260609+LapuLapu+ETS,+GOCC+and+Obs.doc
"""

path = Path('02-work/tasks.md')
existing = path.read_text(encoding='utf-8')
if not existing.endswith('\n'):
    existing += '\n'
path.write_text(existing + tasks.lstrip('\n'), encoding='utf-8', newline='')
print(f'tasks.md length: {len(path.read_text(encoding="utf-8"))} chars')

decisions = f"""
## D013 {EM} Agreed: Trim Developer Experience Dashboard Alerting to Actionable Signals Only
- **Date:** 2026-06-09
- **Requestor:** David Klan / Rae Judavar / Debamalya Das
- **Request:** Decide how much of the Developer Experience Dashboard signal surface should fire as real-time alerts vs sit in the dashboard or the daily summary email.
- **Decision:** Agreed
- **Reason:** AQA beta and operational experience show non-actionable notifications dilute responder attention; we will route only actionable signals (red) to responders via push/real-time alerts, keep the full data surface in the dashboard (yellow, pull), and rely on the daily summary email (green) as the one-page health view. Sleeping systems and other false-alert sources will be tuned out, and New Relic subscription workloads will let users subscribe to alerts for specific systems or environments.
- **Tags:** #project:lapu-lapu #area:dev-xp #domain:alerting #domain:noise-reduction

---

## D014 {EM} Agreed: Include Shared-Folder ACL Compliance Monitoring in Lapu-Lapu Scope
- **Date:** 2026-06-09
- **Requestor:** David Klan / Birger Fjaellman / Aleksei Radzeveliuk
- **Request:** Decide whether shared-folder ACL inventory and compliance monitoring belongs in the Lapu-Lapu workstream now that file-server migration is being blocked by outdated accounts and unclear ownership (after the 2026-06-04 stance to keep file share / file transfer separate).
- **Decision:** Agreed
- **Reason:** The lack of a regular inventory and monitoring for shared-drive ACLs has produced persistent outdated accounts, unclear ownership, and unenforced retention; the previous Veronis capability was decommissioned without replacement. Aleksei has already built a compliance checker and folder governance can be piloted on small migrated shares. GOCC Middleware Operations is the prospective long-term owner. File transfer and batch jobs remain a separate workstream (D012); only ACL compliance is in scope here.
- **Tags:** #project:lapu-lapu #area:gocc-transition #domain:acl #domain:fileshare

---

## D015 {EM} Agreed: Mandatory Server Restart Authorization Decision Matrix in Every RRP
- **Date:** 2026-06-09
- **Requestor:** David Klan / Jonan Tan Pangan / Kiran Bonde
- **Request:** Decide whether RRPs must explicitly document who can authorize a server restart and under what circumstances, given the recent Ingenium freeze (INC08624117) and the broader Rapid Recovery rollout.
- **Decision:** Agreed
- **Reason:** Server restarts in Japan have ambiguous authorization paths that slow Rapid Recovery and create downstream blame surface. Every RRP will include a decision matrix and guardrails identifying the responsible parties (app owner, GOCC, vendor) and the circumstances that permit a restart, integrated into the mandatory RRP template (D011) so the 6 Gold apps and all future RRPs inherit the same authorization model.
- **Tags:** #project:lapu-lapu #area:rapid-recovery #domain:governance #domain:authorization
"""

dpath = Path('02-work/decisions.md')
dexisting = dpath.read_text(encoding='utf-8')
if not dexisting.endswith('\n'):
    dexisting += '\n'
dpath.write_text(dexisting + decisions.lstrip('\n'), encoding='utf-8', newline='')
print(f'decisions.md length: {len(dpath.read_text(encoding="utf-8"))} chars')
