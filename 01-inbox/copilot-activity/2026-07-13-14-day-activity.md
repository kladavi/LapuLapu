---
type: copilot-activity-recap
window_days: 14
generated_on: 2026-07-13
source: Copilot assessment of email, Teams, meetings, meeting transcripts, and files
status: draft
---

# Copilot 14-Day Activity Recap

## Activity Window

From: 2026-06-30  
To: 2026-07-13

## High-Level Summary

The last 14 days show Lapu-Lapu activity clustering around four primary delivery themes: MMM L2 / observability maturity, Rapid Recovery operational validation, GOCC transition readiness, and GBO Batch Transition planning. Secondary but important signals appeared around CyberArk / service-account governance, Capacity Management CAP-48585, CMDB quality, Employee XP / branch monitoring, Developer XP synthetic monitoring, and ADX / logging visibility.

Recommended priority posture for Current Focus:

- P1: MMM L2, Rapid Recovery, GBO Batch Transition, GOCC Transition
- P2: CMDB Mapping, Developer XP Dashboard, Employee XP Dashboard, ADX Registration
- Watch: CyberArk Governance, Capacity Management

## Workstream Signals

### MMM L2

Meeting mentions: referenced  
Email mentions: referenced  
Chat mentions: referenced  
Tasks: referenced  
Decisions: referenced  
Risks: referenced  
Escalations: referenced  
Important stakeholders involved: David Klan, Debamalya Das, Harish Arasu, Birger Fjaellman, Jonan Tan Pangan

Evidence summary:

- Japan MMM L2 visibility remains a priority because the current dashboard was described as outdated / hard-coded and not suitable for accurate OMML2 progress reporting.
- David requested clear visibility into Japan MMM L2 progress and deliverables so the Japan team can report accurately.
- Japan was observed at 0% in the current dashboard view, and updates were expected after Japan policies begin.
- A definition of done and checklist for each MMM L2 category was requested.
- MMM L2 continues to depend on ADX registration, CMDB mapping, New Relic tagging, Moogsoft/xMatters integration, and application owner engagement.

Recommended priority category: P1

Recommended next action:

- Keep MMM L2 as a P1 focus until Japan has a reliable source-of-truth report that shows completed items, remaining items, per-category definition of done, and ownership for gaps.

Source references:

- turn17search98
- turn17search75
- turn17search86
- turn17search110
- turn17search112
- turn17search46

---

### Rapid Recovery

Meeting mentions: referenced  
Email mentions: referenced  
Chat mentions: referenced  
Tasks: referenced  
Decisions: referenced  
Risks: referenced  
Escalations: referenced  
Important stakeholders involved: David Klan, Jonan Tan Pangan, Harish Arasu, Birger Fjaellman, Debamalya Das, application teams

Evidence summary:

- Rapid Recovery remains active through Ingenium desktop rehearsal planning and operational validation.
- The Ingenium rehearsal scope includes monitoring, team handoffs, troubleshooting, restart sequence, access to RRP documentation, escalation to triage / L3, MIM engagement, and evidence handoff.
- RRP documentation for Gold applications was reported as completed and reviewed, but operational testing cadence and ongoing maintenance still need clarity.
- Weekly reporting states Japan Gold Application teams engaged after targeted escalation, but timely review feedback and regular engagement are needed to prevent teams from shifting back to operational priorities.
- The service-account password expiry incident is a new failure mode that should be embedded in affected RRPs.

Recommended priority category: P1

Recommended next action:

- Convert Ingenium desktop rehearsal into a tracked Rapid Recovery validation event with explicit entry criteria, participant list, evidence expectations, escalation path, and output actions.

Source references:

- turn17search95
- turn17search103
- turn17search111
- turn17search110
- turn17search47
- turn17search46

---

### GOCC Transition

Meeting mentions: referenced  
Email mentions: referenced  
Chat mentions: referenced  
Tasks: referenced  
Decisions: referenced  
Risks: referenced  
Escalations: referenced  
Important stakeholders involved: David Klan, Jonan Tan Pangan, Mary Kris Cabunilas, Angelo Tiu Mariano, Debamalya Das, Birger Fjaellman, Rae Judavar

Evidence summary:

- GOCC transition activity is closely tied to monitoring readiness, incident handoff, alert routing, xMatters / Moogsoft integration, runbooks, and RRP usability.
- The Ingenium desktop rehearsal is effectively a GOCC operating-model validation event.
- Recent discussions emphasized whether alerts are visible to GOCC, whether monitoring is integrated correctly, and whether GOCC can provide enough troubleshooting evidence to L3 teams.
- Non-standard or email-only alerts are being challenged as insufficient for sustainable GOCC monitoring unless integrated into Moogsoft / xMatters and dashboard reporting.
- Non-gold application onboarding and intake forms continue as part of later-phase GOCC transition work.

Recommended priority category: P1

Recommended next action:

- Treat GOCC Transition as a P1 execution path that consumes MMM L2 and Rapid Recovery outputs; use the Ingenium rehearsal to test operational readiness end to end.

Source references:

- turn17search71
- turn17search73
- turn17search81
- turn17search110
- turn17search111
- turn17search112

---

### GBO Batch Transition

Meeting mentions: referenced  
Email mentions: referenced  
Chat mentions: referenced  
Tasks: referenced  
Decisions: referenced  
Risks: referenced  
Escalations: referenced  
Important stakeholders involved: David Klan, Balaji Ravi, Jonan Tan Pangan, Manish Kumar Kapil, Kiran Bonde

Evidence summary:

- BatchOpsTransition_v1 was updated recently and frames the Japan-to-GBO transition as an executable plan to move from manual, isolated workloads to integrated, standardized, monitored batch operations.
- GBO Batch Transition remains aligned to Lapu-Lapu through standardized batch operations, centralized monitoring, observability, and global operating model consistency.
- A new GBO expert is expected to support the transition beginning July 20.
- Vendor manualization is targeted for August 15, with transition planning running in parallel and a stable go-live target in November.
- Recent Teams activity refers to ServerF CA job lists and survey/input collection for batch Ops transition with GBO.

Recommended priority category: P1

Recommended next action:

- Keep GBO Batch Transition as P1 and drive the next artifact set: scope inventory, non-CA/manual jobs, support model, xMatters routing, runbook ownership, and pilot selection.

Source references:

- turn17search96
- turn17search110
- turn17search80
- turn17search91
- turn17search94
- turn17search44

---

### CMDB Mapping

Meeting mentions: referenced  
Email mentions: referenced  
Chat mentions: referenced  
Tasks: referenced  
Decisions: referenced  
Risks: referenced  
Escalations: referenced  
Important stakeholders involved: David Klan, Rae Judavar, Yegor, application owners

Evidence summary:

- CMDB remains a foundation for MMM L2, Rapid Recovery, GOCC transition, capacity management, and ownership resolution.
- Weekly reporting states that service-mapping cleanup advanced for EDL, Vantage, IACB-WFI, Magellan, Agent Web, and SSW; Apollo is done but JCUS service mapping needs redesign; finer Cosmos DB dependency mapping remains in progress.
- Meeting discussions indicate some applications are mapped in LeanIX but lack metal ratings and require outreach to application owners.
- CMDB quality is now also a prerequisite for CAP-48585 capacity management.

Recommended priority category: P2

Recommended next action:

- Keep CMDB Mapping as P2 unless it blocks MMM L2, RRP, GOCC, GBO, or Capacity Management deliverables; prioritize records tied to Gold apps, GBO batch scope, and unresolved ownership.

Source references:

- turn17search46
- turn17search47
- turn17search112
- turn17search45

---

### ADX Registration

Meeting mentions: referenced  
Email mentions: referenced  
Chat mentions: referenced  
Tasks: referenced  
Decisions: referenced  
Risks: referenced  
Escalations: referenced  
Important stakeholders involved: David Klan, Birger Fjaellman, application teams, GOCC Middleware Operations

Evidence summary:

- ADX / SIEM / Sentinel runbook was shared with application teams to support advanced troubleshooting and app-specific logging.
- H1 reporting states the R2R-scope ADX onboarding push was parked and replaced with an application-owner responsibility model.
- Recent incident discussion on ePOS / Manulink included the observation that logs went to ADX, reinforcing ADX as a troubleshooting data path.
- ADX remains important but appears less dominant than MMM L2, RRP, GOCC, and GBO in the current activity window.

Recommended priority category: P2

Recommended next action:

- Keep ADX as P2 and trigger deeper work only when an incident or use case requires application-specific logging, alerting, or dashboard integration.

Source references:

- turn17search46
- turn17search47
- turn17search81
- turn17search101

---

### Employee XP Dashboard

Meeting mentions: referenced  
Email mentions: referenced  
Chat mentions: referenced  
Tasks: referenced  
Decisions: referenced  
Risks: referenced  
Escalations: referenced  
Important stakeholders involved: David Klan, Angelo Tiu Mariano, Aleksei Radzeveliuk, Jonan Tan Pangan, Sales stakeholders, Ito-san

Evidence summary:

- Employee Experience / branch monitoring continues through branch office laptop monitoring, dashboard refinement, and expansion discussions.
- Process monitoring was reviewed as a possible enhancement, but baseline categories and server/application tagging must be defined before alerting is expanded.
- The H1 report states Employee Experience and Business Capability dashboards moved from draft to business/shared stakeholder use, with Sales and other stakeholders requesting access and Ito-san asking for a business-friendly external health-check report.
- Branch monitoring patterns are receiving attention and are being discussed for reuse beyond Japan.

Recommended priority category: P2

Recommended next action:

- Keep Employee XP as P2 and focus on making dashboard outputs business-readable, with process monitoring treated as a controlled enhancement rather than broad alert expansion.

Source references:

- turn17search82
- turn17search110
- turn17search47
- turn17search46

---

### Developer XP Dashboard

Meeting mentions: referenced  
Email mentions: referenced  
Chat mentions: referenced  
Tasks: referenced  
Decisions: referenced  
Risks: referenced  
Escalations: referenced  
Important stakeholders involved: David Klan, Rae Judavar, Mark, Sangram, New Relic Incident Intelligence, application owners

Evidence summary:

- Developer XP has strong activity signals due to repeated New Relic synthetic ping-check alerts for ePOS non-production monitors under the GOCC Japan Developer Experience Synthetic Policy.
- Meeting discussions covered AQA/UAT monitoring credentials, Ingenium non-prod URL validation, firewall issues, dashboard revalidation, New Relic policy creation, and alert functionality validation.
- Weekly reporting flags repeated ePOS DEV alerts as an issue requiring disposition: actionable, non-prod-expected, or noise.
- Dev XP is important but should not displace P1 delivery unless alert noise is actively impairing operations or masking true failure signals.

Recommended priority category: P2

Recommended next action:

- Keep Developer XP as P2 with a narrow action: disposition recurring ePOS DEV synthetic alerts and either tune thresholds, suppress expected non-prod noise, or escalate remediation.

Source references:

- turn17search50
- turn17search53
- turn17search54
- turn17search55
- turn17search56
- turn17search57
- turn17search58
- turn17search59
- turn17search60
- turn17search61
- turn17search62
- turn17search63
- turn17search64
- turn17search65
- turn17search66
- turn17search67
- turn17search68
- turn17search69
- turn17search70
- turn17search110
- turn17search112
- turn17search46

---

### CyberArk Governance

Meeting mentions: referenced  
Email mentions: referenced  
Chat mentions: referenced  
Tasks: referenced  
Decisions: referenced  
Risks: referenced  
Escalations: referenced  
Important stakeholders involved: David Klan, Balaji Ravi, Jonan Tan Pangan, Birger Fjaellman, Adrian Jose Velasco, Kiran Bonde, Path To Green Asia Team, GAM team, CyberArk operations

Evidence summary:

- CyberArk / service-account governance remains a material risk theme after a password expiration incident involving Semi-Managed accounts and broader concerns around role concentration, evidence gaps, and unclear challenge ownership.
- Recent meeting activity covered CyberArk registration compliance, account inventory, account ownership, AD metadata / password reset behavior, and migration testing.
- A password-expiration-control report asked teams to review accounts expiring within 7, 30, and 90 days and noted accounts with 365-day expiration that are not managed by CyberArk.
- CyberArk account list / approval activity is present in Teams, but this should remain a Watch item unless it blocks RRP, GOCC, or production incident prevention work.

Recommended priority category: Watch

Recommended next action:

- Keep CyberArk Governance on Watch, but escalate if account inventory, owner confirmation, or rotation controls become blockers for Rapid Recovery or GOCC operational readiness.

Source references:

- turn17search43
- turn17search47
- turn17search110
- turn17search112
- turn17search89
- turn17search90
- turn17search92

---

### Capacity Management

Meeting mentions: referenced  
Email mentions: referenced  
Chat mentions: referenced  
Tasks: referenced  
Decisions: referenced  
Risks: referenced  
Escalations: referenced  
Important stakeholders involved: David Klan, Hasegawa-san, GOCC, ETS, Rasheersh Jha

Evidence summary:

- CAP-48585 was adopted as a Lapu-Lapu workstream, targeting an estimation process for future capacity requirements.
- Weekly and H1 reporting state that the plan is split into six work packages and that capacity risk should integrate into RRP and MMM L2 dashboards.
- Pilot applications are Ingenium, NDM, and ServerF.
- Teams activity indicates David planned to work with Hasegawa-san to define the required process.
- Capacity Management is strategically important but should remain Watch unless delivery risk increases or it becomes a direct dependency for MMM L2, RRP, or GOCC readiness.

Recommended priority category: Watch

Recommended next action:

- Keep Capacity Management on Watch and confirm the minimum viable baseline / forecast template for Ingenium, NDM, and ServerF.

Source references:

- turn17search47
- turn17search85
- turn17search45

## New Decisions Detected

- Treat non-standard or email-only monitoring policies as insufficient for durable MMM / GOCC compliance unless they are brought into the appropriate monitored, tagged, and routed model.
- Continue the application-owner responsibility model for ADX unless an incident or specific app logging use case requires re-engagement.
- Use desktop rehearsal / controlled failure testing to validate Rapid Recovery and GOCC operational readiness rather than relying only on static documents.

## New Risks Detected

- MMM L2 dashboard/reporting ambiguity may misrepresent Japan progress and create false confidence or false escalation.
- RRP documents may be complete on paper but insufficiently validated without controlled operational testing and rehearsal.
- GOCC readiness may be constrained if alerts remain email-only, non-standard, untagged, or not integrated into Moogsoft / xMatters.
- Repeated ePOS non-prod synthetic alerts may create noise unless dispositioned.
- CyberArk Semi-Managed and unmanaged account exposure may create future silent-expiry incidents.
- Capacity Management depends on monitoring data quality, CMDB accuracy, and clear ownership.

## Possible Priority Changes

- Elevate GOCC Transition to P1 alongside MMM L2, Rapid Recovery, and GBO Batch Transition because the Ingenium desktop rehearsal is a direct test of the GOCC operating model.
- Keep Developer XP at P2, with a specific alert-tuning focus.
- Keep CyberArk Governance and Capacity Management at Watch unless they block operational readiness.

## Recommended Human Overrides

Recommended updates to priority-overrides.yaml:

```yaml
overrides:
  - workstream_id: gocc-transition
    force_category: P1
    reason: Ingenium desktop rehearsal and incident handoff validation make GOCC readiness an active execution priority for the current window.
    expires: null

  - workstream_id: developer-xp
    force_category: P2
    reason: Repeated ePOS DEV synthetic alerts require disposition, but the work should remain scoped to alert tuning unless it blocks operational readiness.
    expires: null
```

## Notes for David

- This recap should be saved as `01-inbox/copilot-activity/2026-07-13-14-day-activity.md`.
- After saving this file into the repo, run `scripts/generate-current-focus.ps1` from the repo root to refresh `00-context/generated/current-focus.md` and `00-context/generated/current-focus.json`.
- Suggested V1.1 behavior change: add GOCC Transition to forced P1 for this cycle because it is the operational consumer of MMM L2 and Rapid Recovery outputs.
