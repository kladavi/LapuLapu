---
type: copilot-activity-recap
window_days: 14
generated_on: 2026-07-14
source: Copilot assessment of email, Teams, meetings, meeting transcripts, and files
status: draft
---

# Lapu-Lapu 14-Day Activity Recap

Assessment period based on Microsoft 365 activity discovered across emails, Teams chats, meetings, meeting transcripts, Loop notes, and shared files. Exact mention counts were not available from source data; references are therefore described as "referenced" rather than quantified.

## ADX Registration

### Meeting mentions
Referenced in MMM L2 and observability discussions; SIEM/ADX/Sentinel runbook was shared with application teams. 【1-a00397】【2-37e601】

### Email mentions
Referenced in weekly status reporting as an application-team responsibility; central onboarding remains largely unchanged. 【3-e82252】【1-a00397】

### Chat mentions
Referenced during incident discussions regarding whether additional logging in ADX could have aided diagnosis. 【4-77cd1a】

### Tasks / Action Items
- Continue application onboarding guidance through SIEM/ADX runbook.
- Use ADX selectively for incident-driven investigations. 【1-a00397】【5-e32915】

### Decisions
- Centralized logging onboarding is no longer a Lapu-Lapu-driven rollout; it is owned by application teams unless incident-driven engagement is required. 【5-e32915】【6-0fbe0a】

### Risks / Blockers
- Limited application-owner engagement could slow coverage improvements. 【1-a00397】

### Escalations
- ePOS / Manulink incident review raised questions regarding logging visibility and detection capability. 【4-77cd1a】

### Stakeholders
David Klan, Birger Fjaellman （フィエルマン ビルイェル）, GOCC Observability Team. 【4-77cd1a】【2-37e601】

### Evidence Summary
ADX remains visible as part of MMM/observability architecture but is not an active expansion effort. 【1-a00397】【5-e32915】

### Priority
**Watch**

### Recommended Next Action
Validate whether recent incidents would have benefited from additional ADX telemetry and document findings.

---

## CMDB Mapping

### Meeting mentions
Referenced repeatedly as prerequisite data for GOCC onboarding, MMM L2, capacity management, and application ownership validation. 【7-4da8ca】【8-3b68dc】

### Email mentions
Weekly reports identified CMDB accuracy as a dependency for capacity management and operational maturity. 【3-e82252】【1-a00397】

### Chat mentions
Indirect references through onboarding and ownership discussions. 【9-5d16dc】

### Tasks / Action Items
- Complete remaining CWS entity mapping confirmation.
- Validate LeanIX and CMDB ownership gaps.
- Resolve unrated applications and ownership questions. 【8-3b68dc】【7-4da8ca】

### Decisions
- CMDB serves as a foundational dependency for downstream operational initiatives. 【6-0fbe0a】

### Risks / Blockers
- Poor-quality entity submissions and incomplete ownership data. 【10-7c9fd1】【8-3b68dc】

### Escalations
- Clarifications required from application owners and validation teams. 【7-4da8ca】

### Stakeholders
Rae Judavar, David Klan, Adrian Jose Velasco, MMM validation teams. 【7-4da8ca】【8-3b68dc】

### Evidence Summary
Only a small number of mappings appear unresolved, but quality and validation work remain active. 【8-3b68dc】

### Priority
**P2**

### Recommended Next Action
Publish a CMDB validation backlog with owners, status, and definition-of-done.

---

## Employee XP Dashboard

### Meeting mentions
Significant discussion on process monitoring, branch-office monitoring, health dashboards, and business consumption. 【8-3b68dc】【11-ce5173】

### Email mentions
Dashboard enhancements and business-friendly reporting remain under review. 【3-e82252】【6-0fbe0a】

### Chat mentions
Dashboard reporting and operational health visibility discussed with stakeholders. 【12-5e46d8】

### Tasks / Action Items
- Define baseline server processes.
- Establish tagging strategy.
- Expand branch-office monitoring.
- Improve dashboard KPI visibility. 【8-3b68dc】【13-253c04】

### Decisions
- Process monitoring will be based on baseline services rather than monitoring every process. 【8-3b68dc】【13-253c04】

### Risks / Blockers
- Significant pre-work required for process classification and tagging.
- Dashboard KPI tagging remains incomplete. 【13-253c04】【8-3b68dc】

### Escalations
None explicitly detected.

### Stakeholders
David Klan, Rae Judavar, Debamalya Das, Aleksei Radzeveliuk （ラドゼベリュク アレクセイ）, Jonan Tan Pangan. 【8-3b68dc】【11-ce5173】

### Evidence Summary
Transitioning from availability monitoring toward operational diagnostics and troubleshooting signals. 【8-3b68dc】

### Priority
**P2**

### Recommended Next Action
Finalize baseline categories and deploy first production process-monitoring prototype.

---

## Developer XP Dashboard

### Meeting mentions
Active reviews of URL validation, firewall remediation, synthetic monitoring, alert quality, and credential acquisition. 【8-3b68dc】【7-4da8ca】

### Email mentions
Dashboard draft reported complete and under review. Alert tuning remains active. 【3-e82252】【1-a00397】

### Chat mentions
Magellan monitoring and synthetic coverage were discussed extensively. 【14-ca46ba】【15-4972cb】

### Tasks / Action Items
- Obtain alert-validation credentials.
- Complete URL validation.
- Resolve firewall and 401 issues.
- Rationalize duplicate monitoring policies. 【8-3b68dc】【7-4da8ca】【14-ca46ba】

### Decisions
- Monitoring should move beyond ping checks where feasible.
- Customer-journey and scripted monitoring patterns should be evaluated. 【14-ca46ba】【15-4972cb】

### Risks / Blockers
- Credential delays.
- Firewall issues.
- Fragmented monitoring ownership and policy sprawl. 【8-3b68dc】【14-ca46ba】

### Escalations
Repeated synthetic alert tuning and Magellan monitoring concerns. 【1-a00397】【14-ca46ba】

### Stakeholders
Rae Judavar, Mark Adriel Manuel, Sangram, Debamalya Das, David Klan. 【8-3b68dc】【7-4da8ca】

### Evidence Summary
Dashboard capability is advancing but operationalization remains constrained by credentials and monitoring governance. 【8-3b68dc】【14-ca46ba】

### Priority
**P2**

### Recommended Next Action
Resolve credential dependencies and establish monitoring-policy ownership standards.

---

## GOCC Transition

### Meeting mentions
Extensively referenced in weekly operational meetings. 【8-3b68dc】【7-4da8ca】【16-b2d251】

### Email mentions
Additional applications targeted; onboarding continues. 【3-e82252】【1-a00397】

### Chat mentions
Frequent operational discussions covering monitoring ownership and application onboarding. 【17-f70048】【14-ca46ba】

### Tasks / Action Items
- Continue onboarding applications.
- Resolve transition dependencies.
- Continue vendor manualization activities. 【8-3b68dc】【7-4da8ca】

### Decisions
- Additional GBO/GOCC expertise to be onboarded.
- Weekly stakeholder engagement remains necessary. 【8-3b68dc】【13-253c04】

### Risks / Blockers
- PS Team responsiveness.
- Vendor transition timing.
- Knowledge transfer completion. 【1-a00397】【8-3b68dc】

### Escalations
Transition timeline concerns and onboarding capacity. 【13-253c04】

### Stakeholders
Balaji Ravi （ラヴィ バラジ）, Jonan Tan Pangan, Mary Kris Cabunilas, David Klan. 【8-3b68dc】【7-4da8ca】

### Evidence Summary
Transition remains active and forward-moving but dependent on external teams and onboarding resources. 【1-a00397】【8-3b68dc】

### Priority
**P1**

### Recommended Next Action
Lock transition milestones through September and document ownership gaps.

---

## MMM L2

### Meeting mentions
One of the most referenced subjects across meetings. 【8-3b68dc】【13-253c04】

### Email mentions
Dashboard visibility and definition-of-done remain recurring concerns. 【3-e82252】【1-a00397】

### Chat mentions
Japan progress visibility questioned publicly. 【12-5e46d8】

### Tasks / Action Items
- Clarify source-of-truth reporting.
- Provide completion status.
- Define completion criteria. 【8-3b68dc】【10-7c9fd1】

### Decisions
- New dashboard is being developed because current reporting is unreliable. 【8-3b68dc】【13-253c04】

### Risks / Blockers
- Dashboard currently does not accurately represent progress.
- Status transparency gap. 【13-253c04】【12-5e46d8】

### Escalations
Japan leadership visibility requests. 【13-253c04】【3-e82252】

### Stakeholders
David Klan, Debamalya Das, Harish Arasu, Adrian Jose Velasco. 【8-3b68dc】【10-7c9fd1】

### Evidence Summary
Work is progressing but reporting is not trusted enough to support executive reporting. 【13-253c04】【12-5e46d8】

### Priority
**P1**

### Recommended Next Action
Obtain authoritative MMM L2 status export and align it with dashboard reporting.

---

## Rapid Recovery

### Meeting mentions
Heavily discussed in operational reviews and rehearsal planning. 【8-3b68dc】【16-b2d251】

### Email mentions
Gold application RRPs reported complete and moving toward operational validation. 【1-a00397】

### Chat mentions
References tied to operational readiness and incident preparedness. 【9-5d16dc】

### Tasks / Action Items
- Establish review cadence.
- Validate operational testing.
- Execute incident rehearsals. 【13-253c04】【16-b2d251】

### Decisions
- RRP reviews completed for gold applications.
- Automation work transitions to global teams. 【8-3b68dc】【11-ce5173】

### Risks / Blockers
- Operational testing cadence remains unclear.
- Consumption model for RRPs remains immature. 【13-253c04】【11-ce5173】

### Escalations
Requests for best practices and validation visibility. 【11-ce5173】

### Stakeholders
Harish Arasu, Birger Fjaellman （フィエルマン ビルイェル）, David Klan. 【11-ce5173】【8-3b68dc】

### Evidence Summary
Documentation maturity is improving; operational rehearsal maturity is the next major step. 【16-b2d251】【8-3b68dc】

### Priority
**P1**

### Recommended Next Action
Run the planned Ingenium desktop incident rehearsal.

---

## GBO Batch Transition

### Meeting mentions
Recurring topic in operating review meetings. 【8-3b68dc】【13-253c04】

### Email mentions
Pilot cutover planning, staffing, onboarding, and manualization discussed. 【3-e82252】【1-a00397】

### Chat mentions
Limited direct chat evidence found.

### Tasks / Action Items
- Onboard GBO expert.
- Schedule stakeholder sessions.
- Complete vendor manualization. 【8-3b68dc】【13-253c04】

### Decisions
- New expert onboarding from July 20.
- Transition planning continues in parallel with vendor activities. 【8-3b68dc】

### Risks / Blockers
- Inventory completion.
- Knowledge-transfer timing.
- Open stakeholder actions. 【3-e82252】【8-3b68dc】

### Escalations
None explicitly identified.

### Stakeholders
Balaji Ravi （ラヴィ バラジ）, Jonan Tan Pangan, Manish Kumar Kapil, David Klan. 【8-3b68dc】【3-e82252】

### Evidence Summary
Transition remains on-plan and is moving toward pilot execution. 【3-e82252】【8-3b68dc】

### Priority
**P1**

### Recommended Next Action
Publish readiness criteria for September pilot cutover.

---

## CyberArk Governance

### Meeting mentions
Major recurring topic tied to password-expiry incidents. 【8-3b68dc】【7-4da8ca】【13-253c04】

### Email mentions
Explicit focus area in weekly reports. 【3-e82252】【1-a00397】

### Chat mentions
Password-expiration controls and governance referenced. 【18-47b44b】【19-9c9c73】

### Tasks / Action Items
- Cross-reference CyberArk and AD accounts.
- Identify unmanaged and semi-managed accounts.
- Improve ownership and rotation governance. 【13-253c04】【8-3b68dc】

### Decisions
