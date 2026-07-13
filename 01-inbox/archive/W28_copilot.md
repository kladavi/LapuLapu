---
project: "lapu-lapu"
weekId: "2026-W28"
period: "Monday July 6, 2026 00:00 JST – Friday July 10, 2026 13:59 JST"
distribution: ["Birger","Hari","Kelvin","Jonan","Deb","Balaji","Joan"]
status: "DRAFT — generated from Microsoft 365 activity; requires David review"
---

## Weekly Project Status Report — Lapu-Lapu

**Project:** Lapu-Lapu  
**Week Ending:** W28 July 10, 2026

## Executive Summary

**Frictionless Customer Experience:**  
Monitoring work continued across production and non-production visibility, including Developer Experience synthetic alerting, ADX logging discussions, branch/laptop monitoring expansion, process-monitoring baseline design, and troubleshooting-oriented dashboard improvements. The strongest current-week evidence is the Lapu-Lapu observability meeting, where the team reviewed NRQL-to-Power BI progress, AQA/UAT monitoring, Ingenium server access, process monitoring, laptop monitoring expansion, and the need for application-specific baseline process monitoring. 【1-b5ccf0】

**Robust Technical Core:**  
RRP, MMM L2, CyberArk/IAM governance, CMDB/service mapping, and service-account lifecycle risk remained active themes. Current-week evidence shows completed/reviewed Gold application RRP documentation, requested confirmation of Japan access/visibility, follow-up needed on operational testing cadence, and escalation of CyberArk privileged-access governance concerns after the Ingenium APIM service-account incident. 【1-b5ccf0】【2-e0c2a7】【3-73e4a9】

**Outstanding Colleague Experience:**  
Material this week: the team continued to reduce operational friction through clearer handover paths, reusable monitoring patterns, and a proposed central repository for advanced monitoring configurations and edge cases. The Lapu-Lapu meeting explicitly captured a need for a centralized repository / FAQ for custom monitoring solutions and lessons learned. 【1-b5ccf0】

**Technology Transformation through AI & Automation:**  
Material this week: GOCC/GBO transition planning continued, including the onboarding of a new GBO expert from July 20, additional stakeholder sessions, and transition planning in parallel with vendor manualization. Observability automation also advanced through discussion of NRQL export, Power BI integration, synthetic monitoring, Moogsoft, self-healing use cases, and predictive monitoring work in the OAR Community of Practice. 【1-b5ccf0】【4-4e4548】

## Monitoring Status — List of Apps and Transition Activities

### ADX Registration
ADX remained relevant as an application-owner / troubleshooting capability rather than a broad push. David shared the SIEM / ADX / Sentinel runbook with application teams and noted that centralized logging currently covers infra/synthetic logs, while application teams can set up application-specific logs for advanced troubleshooting and performance monitoring. 【5-e805dd】【6-d4d84f】

[ISSUE] Application teams may not be aware ADX is available or may not have onboarded application-specific logs. Mitigation - continue targeted education using the SIEM / ADX / Sentinel runbook and tie ADX onboarding to concrete incident/problem-review use cases. Owner: application owners, supported by Lapu-Lapu / GOCC coordination. 【5-e805dd】

### CMDB Mapping
CMDB/service mapping progressed through direct follow-up with Yegor Pomozoff （ポモゾフ イゴ）: EDL, Vantage, IACB-WFI, Magellan, Agent Web, and SSW were described as done, Apollo was done but still needed JCUS service-mapping redesign, and finer mapping between Cosmos DB and dependent services remained in progress. 【7-55837b】

### Employee XP Dashboard
The Employee Experience / process-monitoring work advanced through discussion of New Relic dashboarding, branch-office / laptop monitoring, and application process baselines. Current draft monitoring can compare running processes over time, but the team identified the need to define baseline processes per server/application category and tag servers accordingly to reduce monitoring noise. 【1-b5ccf0】

### Dev XP Dashboard
Developer Experience monitoring had active evidence this week through New Relic synthetic alerts for ePOS non-prod monitors under the “GOCC Japan Developer Experience Synthetic Policy.” Multiple New Relic emails showed active and closed ping-check issues for Asia-JP-ePOS DEV monitors, including issue durations explicitly reported in the alert emails. 【8-3f12d9】【9-c0e944】【10-9e4e4c】【11-dc69fd】

### GOCC Transition
The Lapu-Lapu meeting captured continued GOCC transition planning: a new GBO expert is expected to join from July 20 to support global batch operations transition, additional stakeholder sessions are planned for open items from Manish, and regular weekly or bi-weekly stakeholder meetings were discussed. 【1-b5ccf0】

### MMM L2 / OMM L2
MMM L2 remained active. In the Lapu-Lapu meeting, Harish confirmed RRP documentation for Gold applications was completed and reviewed, while the team discussed confusion over the current MMM L2 dashboard and noted that a new dashboard is being developed to more accurately reflect application status and KPIs. 【1-b5ccf0】

### Patching
No detailed material update found this week beyond the existence of the recurring [Japan] Patching Schedule and Standard BAU Transition meeting. The meeting result did not include transcript content or status detail. 【12-355a91】

### Rapid Recovery
Rapid Recovery advanced through review of completed Gold-app RRP documentation, confirmation that documents are stored in public SharePoint accessible via Copilot, and follow-up on operational testing cadence. A separate Lapu-Lapu GOCC and Japan meeting focused on planning an Ingenium production-incident desktop rehearsal covering monitoring, handoffs, troubleshooting, restarts, escalation, MIM engagement, and use of RRP documentation. 【1-b5ccf0】【13-d8cc05】

### CyberArk / IAM / Access Governance
CyberArk/IAM became a major risk and governance focus this week. Evidence from Re: PRB00024864 - INC08672078 Investigation showed the mfcgd\wasAPIMprod account is onboarded in CyberArk under the CyberArk Asia instance, uses a semi-managed platform requiring manual rotation by PWMGR safe members, has an expected one-year service-ID expiry, and had not been rotated since May 27, 2024; the password was reset by GAM on June 27, 2026, which means CyberArk notification behavior may not work as expected for that reset path. 【2-e0c2a7】

A separate Re: CyberArk Privileged Access Review — Summary of Findings and Governance Concern raised broader privileged-access governance concerns: the review identified role concentration across CyberArk Safes, evidence gaps for approval/risk acceptance, unclear challenge ownership, and a recommendation to request ServiceNow approval history, IIQ certification records, identification of the automated control for excessive privilege / SoD monitoring, and Archer/CAP tracking once issue owners are identified. 【3-73e4a9】

### Batch Operations / GBO Transition
Batch/GBO transition remained active through the Lapu-Lapu meeting. The team discussed onboarding a new GBO expert from July 20, additional sessions to address open items from Manish, vendor manualization targeting completion by August 15 with approvals, and parallel transition-plan development to support a stable go-live by November. 【1-b5ccf0】

## Key Accomplishments This Week

1. Advanced the Lapu-Lapu observability operating model by reviewing NRQL export, Developer Experience monitoring, AQA/UAT validation, process monitoring, laptop / branch monitoring expansion, and New Relic dashboard utility in a single cross-functional forum. 【1-b5ccf0】  
2. Moved Rapid Recovery from documentation completion toward operational validation by planning an Ingenium incident desktop rehearsal covering alerting, handoffs, troubleshooting, escalation, and RRP usage. 【13-d8cc05】  
3. Elevated CyberArk/IAM from a local account cleanup issue to a privileged-access governance concern, with specific next actions around ServiceNow approvals, IIQ certification, automated SoD monitoring, and Archer/CAP tracking. 【3-73e4a9】  
4. Confirmed service-account lifecycle details for mfcgd\wasAPIMprod, including semi-managed status, manual rotation dependency, expected one-year expiry, notification behavior, and ownership information from CyberArk / GAM responses. 【2-e0c2a7】  
5. Continued CMDB/service mapping cleanup, with multiple services marked done and remaining refinement focused on finer dependency mapping between Cosmos DB and consuming services. 【7-55837b】  

## Key Results Snapshot

- No updated consolidated Lapu-Lapu program metric found this week.
- Current-week New Relic alert evidence exists for Developer Experience synthetic monitoring: ePOS DEV synthetic ping-check alerts were active and closed across multiple notifications, with individual issue durations explicitly shown in the alert emails. 【8-3f12d9】【9-c0e944】【10-9e4e4c】【11-dc69fd】
- CMDB/service mapping status was partially updated: EDL, Vantage, IACB-WFI, Magellan, Agent Web, and SSW were described as done; Apollo required redesign for JCUS service mapping; finer Cosmos DB dependency mapping remained in progress. 【7-55837b】

## Top Risks & Issues

[Risk] · Developer Experience synthetic monitoring is producing repeated ePOS non-prod ping-check failures; this may indicate instability, expected non-prod behavior, or alert-noise requiring review | mitigation: review whether these alerts are actionable and whether policy thresholds / suppression logic need adjustment | owner: application owner / Lapu-Lapu monitoring coordination | 【8-3f12d9】【9-c0e944】【10-9e4e4c】【11-dc69fd】

[Risk] · CyberArk semi-managed service-account rotation relies on manual PWMGR action and may not provide reliable pre-expiry notification when passwords are reset outside CyberArk | mitigation: confirm notification path, owner/DL mapping, rotation cadence, and estate-wide exposure for semi-managed accounts | owner: CyberArk/PAS, GAM/IAM, application/safe owners | 【2-e0c2a7】

[Risk] · Privileged-access role combinations may persist without clear independent challenge, documented risk acceptance, or automated SoD monitoring evidence | mitigation: obtain ServiceNow approval history, IIQ certification records, automated-control details, and Archer/CAP tracking once owners are identified | owner: IAM/PAS/Information Risk with Safe/Application Owners | 【3-73e4a9】

[Risk] · Process monitoring may create noise unless application-specific baseline processes are defined and server tagging is completed | mitigation: define standard baseline categories, capture application-specific process lists, and tag servers before alerting expansion | owner: monitoring team with application teams | 【1-b5ccf0】

[Risk] · MMM L2 reporting may be misunderstood while the existing dashboard is outdated and a new dashboard is still being developed | mitigation: provide timely dashboard-status clarification and avoid using outdated dashboard figures for executive reporting | owner: MMM L2 / observability reporting team | 【1-b5ccf0】

## Planned for Next Week

1. **O1 / O4:** Complete follow-up on Developer Experience synthetic alert review for ePOS non-prod monitors and decide whether tuning, suppression, or application remediation is required. 【8-3f12d9】【9-c0e944】【10-9e4e4c】【11-dc69fd】  
2. **O4:** Drive CyberArk/IAM governance follow-up: request ServiceNow approval history, IIQ certification evidence, and confirmation of the automated excessive-privilege / SoD control. 【3-73e4a9】  
3. **O4 / O6:** Prepare the Ingenium incident desktop rehearsal with the right participants to test GOCC-to-MIM escalation, troubleshooting evidence, and RRP usability. 【13-d8cc05】  
4. **O1 / O6:** Continue process-monitoring design by defining baseline process categories and a reusable repository for advanced monitoring configurations and edge cases. 【1-b5ccf0】  

## Project Resources

- Confluence — GOCC Japan (Lapu-Lapu)
- Jira — LPLP Project Board
- Ops Dashboard — Power BI
- SharePoint — ETS Japan Program Delivery

## Source Evidence

- [Lapu-Lapu] ETS Japan, GOCC, and Observability Team, Tuesday July 7, 2026 — meeting transcript/summary covering dashboards, Dev XP monitoring, process monitoring, laptop monitoring, MMM L2/RRP, GBO transition, CyberArk/AD account management, Pulse HR monitoring, and Gopher approval automation. 【1-b5ccf0】
- Lapu-Lapu GOCC and Japan, Thursday July 9, 2026 — meeting transcript/summary covering Ingenium incident desktop rehearsal planning and escalation process review. 【13-d8cc05】
- Re: PRB00024864 - INC08672078 Investigation, received July 9, 2026 — CyberArk/GAM response on mfcgd\wasAPIMprod configuration, semi-managed rotation, expiry, notifications, and ownership. 【2-e0c2a7】
- Re: CyberArk Privileged Access Review — Summary of Findings and Governance Concern, received July 9, 2026 — privileged-access governance analysis and recommended leadership / IAM / PAS follow-up actions. 【3-73e4a9】
- [Lapu-Lapu] ETS Japan, GOCC, and Observability Team, Tuesday July 7, 2026 — meeting chat/facilitator updates capturing dashboard, OMM L2, laptop monitoring, rapid recovery, GBO transition, Pulse HR testing, and CyberArk/AD action themes. 【14-20d3de】
- CyberArk Safe Design and Roles, current week — Teams discussion on CyberArk role combinations, self-approval control, IIQ recertification, and need for SoD monitoring / governance clarity. 【15-0ec849】【16-5e6a1c】【17-9e5944】
- Application logging & Monitoring - ADX, Thursday July 9, 2026 — Teams reference to SIEM / ADX / Sentinel runbook and Linux/Unix/AIX system logging guide. 【6-d4d84f】
- CMDB/service mapping update with Yegor, Monday July 6, 2026 — direct update on completed and remaining service-mapping work. 【7-55837b】
- [Lapu-Lapu] 2026 H1 Report, sent July 6, 2026 — baseline H1 context for Lapu-Lapu workstreams, decisions, risks, and H2 priorities. 【18-69e47a】
- [EXTERNAL] Policy 7316475: GOCC Japan Developer Experience Synthetic Policy, July 8–10, 2026 — New Relic alert notifications for GOCC Japan Developer Experience synthetic ePOS DEV ping-check failures. 【8-3f12d9】【9-c0e944】【10-9e4e4c】【11-dc69fd】