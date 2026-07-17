---
type: copilot-activity-recap
window_days: 14
generated_on: 2026-07-17
source: Copilot assessment of email, Teams, meetings, meeting transcripts, and files
status: draft
---

# Lapu-Lapu Program – Microsoft 365 Activity Assessment (Last 14 Days)

## Assessment Summary

This assessment is based on activity found across meetings, meeting transcripts, emails, Teams discussions, and associated files related to the Lapu-Lapu program. Evidence strongly indicates that the primary areas of activity during the period were:

- CMDB Mapping
- GOCC Transition
- Rapid Recovery
- Employee Experience Dashboard
- Developer Experience Dashboard
- MMM L2
- CyberArk Governance
- Capacity Management
- GBO Batch Transition

Evidence sources include recurring Lapu-Lapu GOCC and Japan meetings, [Lapu-Lapu] ETS Japan, GOCC, and Observability Team discussions, recurring status reports, meeting transcripts, Teams conversations, and project documents. 【1-33de2e】【2-3f7a2c】【3-02aa5f】【4-9c0482】【5-15d35a】

---

# ADX Registration

## Meeting Mentions
Referenced during observability discussions and application-team onboarding conversations. Discussion centered on forwarding logs to ADX and establishing alerting support. 【6-7d04c2】

## Email Mentions
Weekly status updates indicated ADX onboarding remains application-owner responsibility and a CAWLA dashboard proposal remains under review. Later status updates referenced sharing SIEM/ADX/Sentinel runbooks with application teams. 【3-02aa5f】【4-9c0482】

## Chat Mentions
Incident review discussion noted that relevant logs were already flowing to ADX. 【7-53a7c5】

## Tasks / Action Items
- Continue application-team engagement on log forwarding.
- Define alerting requirements following ADX onboarding. 【6-7d04c2】

## Decisions
- No new decision detected in the last 14 days.
- Existing operating direction continues: application teams own central logging onboarding. 【3-02aa5f】

## Risks / Blockers
- Dependence on application-team participation.
- Dashboard proposal remains under review. 【3-02aa5f】

## Escalations
None observed.

## Stakeholders
Balaji Ravi, David Klan, Observability Team. 【6-7d04c2】

## Evidence Summary
Activity exists but appears maintenance-oriented rather than execution-focused. 【3-02aa5f】【6-7d04c2】

## Recommended Priority
**Watch**

## Recommended Next Action
Identify candidate applications requiring log onboarding and establish an alerting implementation path.

---

# CMDB Mapping

## Meeting Mentions
Major recurring topic across Lapu-Lapu GOCC meetings. Discussions covered:
- Server F relationship accuracy
- Amazon Connect
- BPM mapping
- JCUS restructuring
- Dependency relationships
- Monitoring and recovery dependencies 【1-33de2e】【8-8f0495】【9-568bce】

## Email Mentions
Weekly update stated service mapping cleanup progressed for multiple applications and CMDB is becoming a prerequisite for Capacity Management. 【4-9c0482】【3-02aa5f】

## Chat Mentions
Teams discussion explicitly highlighted CMDB as a dependency for automation, monitoring, recovery, and future improvements. 【10-cbeec2】

## Tasks / Action Items
- Review current mappings with Yegor Pomozoff.
- Correct Server F CI mapping.
- Identify missing application relationships.
- Review system completeness. 【1-33de2e】【11-a42965】

## Decisions
- Conduct focused review of completed and incomplete mappings. 【12-4f9431】【1-33de2e】

## Risks / Blockers
- Server F relationship complexity.
- Inconsistent CI relationships.
- Mapping accuracy impacts monitoring, MMM L2, recovery and capacity programs. 【1-33de2e】【11-a42965】

## Escalations
Potential alignment needed with North American CMDB stakeholders. 【11-a42965】

## Stakeholders
David Klan, Yegor Pomozoff, Birger Fjaellman, Jonan Tan Pangan, Dennis Talento, Balaji Ravi. 【1-33de2e】

## Evidence Summary
One of the highest-volume workstreams during the assessment window. 【1-33de2e】【8-8f0495】【10-cbeec2】

## Recommended Priority
**P1**

## Recommended Next Action
Complete mapping validation sessions and resolve Server F relationship issues.

---

# Employee XP Dashboard

## Meeting Mentions
Extensive discussion around dashboard modernization, Power BI integration, business visibility, and process monitoring. 【13-ef222d】【14-c2239c】【15-732c88】

## Email Mentions
Business-friendly reporting remains requested by Japanese business stakeholders. 【3-02aa5f】【16-9d0706】

## Chat Mentions
Power BI integration planning and business-focused dashboard design discussions took place. 【17-0272cf】

## Tasks / Action Items
- Evaluate Power BI integration.
- Investigate process monitoring integration.
- Continue dashboard refinement. 【13-ef222d】【18-f234ed】

## Decisions
No formal decision detected.

## Risks / Blockers
- Process monitoring baseline not yet established.
- Power BI refresh and operational visibility limitations. 【17-0272cf】【14-c2239c】

## Escalations
None observed.

## Stakeholders
David Klan, Mary Kris Cabunilas, Rae Judavar, Debamalya Das. 【17-0272cf】【13-ef222d】

## Evidence Summary
Active design and stakeholder engagement work continues. 【13-ef222d】【17-0272cf】

## Recommended Priority
**P2**

## Recommended Next Action
Finalize business reporting requirements and process-monitoring metrics.

---

# Developer XP Dashboard

## Meeting Mentions
Firewall validation, proactive monitoring, incident triage, dashboard hardening, and alert tuning were discussed. 【13-ef222d】【14-c2239c】

## Email Mentions
Repeated ePOS synthetic monitoring alerts and associated investigation were referenced. 【4-9c0482】【19-cabfe4】

## Chat Mentions
Developer Dashboard reported approximately 80% complete with remaining credential dependencies. 【5-15d35a】

## Tasks / Action Items
- Resolve credential dependencies.
- Complete firewall validation.
- Disposition recurring ePOS synthetic alerts. 【5-15d35a】【4-9c0482】

## Decisions
No formal decision detected.

## Risks / Blockers
- Repeated synthetic alert noise.
- Remaining firewall and credential dependencies. 【4-9c0482】【5-15d35a】

## Escalations
Recurring incidents have driven alert-review discussions. 【19-cabfe4】【20-099133】

## Stakeholders
David Klan, Rae Judavar, GOCC, AQA teams. 【5-15d35a】【13-ef222d】

## Evidence Summary
High operational activity and ongoing tuning effort. 【5-15d35a】【13-ef222d】

## Recommended Priority
**P2**

## Recommended Next Action
Classify recurring alert sources as actionable, suppressible, or remediation candidates.

---

# GOCC Transition

## Meeting Mentions
Coverage expansion, onboarding readiness, access provisioning, monitoring handoff, application ownership, and health-check support discussions occurred repeatedly. 【1-33de2e】【21-0891fc】

## Email Mentions
Additional applications targeted, onboarding progress discussed, and transition dependencies highlighted. 【3-02aa5f】【4-9c0482】

## Chat Mentions
Phase-2 onboarding delayed awaiting intake forms and owner responses. 【5-15d35a】

## Tasks / Action Items
- Create common GOCC application IDs.
- Support application health-check onboarding.
- Continue non-Gold onboarding. 【1-33de2e】【11-a42965】【5-15d35a】

## Decisions
- GOCC IDs should be established and onboarded to CyberArk. 【12-4f9431】【1-33de2e】

## Risks / Blockers
- Application owner responsiveness.
- Access-management gaps.
- Credential dependencies. 【5-15d35a】【1-33de2e】

## Escalations
GOCC access and ownership discussions crossed multiple support organizations. 【1-33de2e】

## Stakeholders
Balaji Ravi, Sai Pradeep Reddy, Mary Kris Cabunilas, Jonan Tan Pangan, Birger Fjaellman. 【1-33de2e】

## Evidence Summary
Execution workstream with active dependency management. 【1-33de2e】【5-15d35a】

## Recommended Priority
**P1**

## Recommended Next Action
Close access-management gaps before DR and production validation activities.

---

# MMM L2

## Meeting Mentions
Progress visibility and reporting repeatedly discussed. 【14-c2239c】【22-8feddf】

## Email Mentions
Japan teams requested status visibility and definition of completion criteria. 【3-02aa5f】【4-9c0482】

## Chat Mentions
Need to explain MMM L2 activities to Japan application teams. 【18-f234ed】

## Tasks / Action Items
- Conduct Japan team awareness sessions.
- Clarify reporting and source data visibility. 【18-f234ed】【22-8feddf】

## Decisions
No new decision detected.

## Risks / Blockers
- Visibility concerns.
- Dependence on application-team participation. 【22-8feddf】【4-9c0482】

## Escalations
Requests for clearer reporting. 【4-9c0482】【22-8feddf】

## Stakeholders
David Klan, Harish Arasu, Adrian Jose Velasco. 【18-f234ed】

## Recommended Priority
**P2**

## Recommended Next Action
Publish a simplified Japan MMM L2 progress view.

---

# Rapid Recovery

## Meeting Mentions
One of the most active workstreams:
- Tabletop rehearsals
- DR testing
- Verification protocols
- Incident simulation
- Escalation flow reviews 【1-33de2e】【2-3f7a2c】【23-e819ee】【24-c39225】

## Email Mentions
Rapid Recovery engagement and completion tracking continued. 【3-02aa5f】【4-9c0482】

## Chat Mentions
Multiple discussions on incident response and monitoring-driven recovery. 【7-53a7c5】【25-a98c46】

## Tasks / Action Items
- Conduct desktop rehearsal.
- Identify participants.
- Validate escalation paths.
- Document application verification procedures. 【1-33de2e】【2-3f7a2c】【23-e819ee】

## Decisions
- Proceed with tabletop rehearsal approach before sign-off. 【1-33de2e】

## Risks / Blockers
- Incomplete validation.
- Need for participant confirmation.
- Dependence on health-check documentation. 【1-33de2e】【23-e819ee】

## Escalations
Incident escalation workflow itself became a review topic. 【2-3f7a2c】

## Stakeholders
David Klan, Jonan Tan Pangan, Dennis Talento, Mary Kris Cabunilas, MIM stakeholders. 【1-33de2e】【2-3f7a2c】

## Recommended Priority
**P1**

## Recommended Next Action
Execute and document the tabletop rehearsal.

---

# GBO Batch Transition

## Meeting Mentions
Referenced during observability meetings and transition planning. 【26-36c560】【15-732c88】

## Email Mentions
Onboarding plans, staffing preparation, and pilot timing were discussed. 【3-02aa5f】【4-9c0482】

## Chat Mentions
Questionnaire collection and planning discussions occurred with Balaji Ravi. 【27-cd491c】

## Tasks / Action Items
- Complete questionnaires.
- Finalize onboarding planning.
- Continue pilot preparation. 【27-cd491c】【3-02aa5f】

## Risks / Blockers
- Inventory completion.
- Batch-plan authoring.
- Participation from supporting teams. 【3-02aa5f】

## Recommended Priority
**P2**

## Recommended Next Action
Finalize transition readiness assessment and application selection.

---

# CyberArk Governance

## Meeting Mentions
Significant focus on GOCC account management and credential governance. 【1-33de2e】【9-568bce】

## Email Mentions
Credential lifecycle governance appeared as a standalone concern in weekly reporting. 【3-02aa5f】【16-9d0706】

## Chat Mentions
CyberArk account approvals and governance discussions were visible. 【28-1e911f】

## Tasks / Action Items
- Create GOCC accounts.
- Onboard accounts to CyberArk.
- Review role assignments.
- Review password-governance exposure. 【1-33de2e】【18-f234ed】

## Decisions
- Create shared GOCC access model with CyberArk onboarding. 【1-33de2e】【12-4f9431】

## Risks / Blockers
- Service account governance risks.
- Approval-traceability concerns.
- User role concentration concerns. 【3-02aa5f】【18-f234ed】

## Escalations
Risk-team review requested for CyberArk role exposure. 【18-f234ed】

## Recommended Priority
**P1**

## Recommended Next Action
Perform focused governance review before wider GOCC onboarding.

---

# Capacity Management

## Meeting Mentions
Referenced through monitoring, file-system alerting, and operational resilience discussions. 【1-33de2e】

## Email Mentions
CAP-48585 continues as a major workstream with pilot applications identified. 【3-02aa5f】【16-9d0706】

## Chat Mentions
Indirect references through monitoring and alerting reviews. 【7-53a7c5】

## Tasks / Action Items
- Build operational baseline.
- Define thresholds.
- Validate monitoring coverage. 【3-02aa5f】

## Risks / Blockers
- Dependence on CMDB quality.
- Monitoring completeness. 【3-02aa5f】【1-33de2e】

## Recommended Priority
**P2**

## Recommended Next Action
Tie monitoring and CMDB validation outputs into pilot capacity forecasts.

---

# New Decisions Detected

1. Review current CMDB completeness through dedicated mapping sessions. 【12-4f9431】【1-33de2e】
2. Create GOCC application IDs and onboard them to CyberArk. 【12-4f9431】【1-33de2e】
3. Conduct Rapid Recovery tabletop exercises before sign-off. 【1-33de2e】

# New Risks Detected

1. CMDB relationship accuracy impacting downstream programs. 【1-33de2e】【11-a42965】
2. Credential and access-management gaps for GOCC operations. 【1-33de2e】
3. Repeated Developer Experience synthetic alert activity. 【4-9c0482】【19-cabfe4】
4. CyberArk governance and role-allocation concerns. 【18-f234ed】【3-02aa5f】
5. Monitoring coverage gaps exposed by recent production incidents. 【25-a98c46】【7-53a7c5】

# Possible Priority Changes

| Workstream | Suggested Change |
|------------|-----------------|
| CMDB Mapping | Raise to sustained P1 |
| Rapid Recovery | Remain P1 |
| GOCC Transition | Remain P1 |
| CyberArk Governance | Raise from Watch/P2 to P1 |
| Developer XP Dashboard | Watch for escalation if alert noise persists |
| MMM L2 | Remain P2 until reporting visibility improves |

# Recommended Human Overrides

1. Determine whether CyberArk Governance should become a formal named workstream.
2. Confirm whether Capacity Management CAP-48585 requires executive reporting cadence.
3. Decide whether recurring Developer Experience alerts represent operational incidents or alert-tuning debt.
4. Review whether CMDB Mapping warrants dedicated weekly governance reviews.

# Notes for David

- CMDB Mapping appears to be the strongest dependency across nearly every other workstream.
- Rapid Recovery activity is moving from documentation into operational validation.
- CyberArk and identity management issues are becoming increasingly intertwined with GOCC readiness.
- Developer Experience activity is increasingly operational rather than dashboard construction.
- Multiple discussions surfaced the need for monitoring beyond simple URL availability (process monitoring, customer journeys, richer health indicators).
- Several threads indicate an ongoing shift from project delivery into sustainable operational ownership. 【1-33de2e】【25-a98c46】【13-ef222d】【6-7d04c2】