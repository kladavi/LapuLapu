---
type: rejected-items
title: "Rejected Items (validator v2)"
generator: scripts/generate-current-focus.ps1
generated: 2026-07-22T07:34:04
version: V4.0-sprint23a
schema: ui/src/lib/matryoshka-item.ts
accepted_count: 11
candidate_count: 20
rejected_count: 9
---
# V4.0 Phase 1 - Rejected Items

_Generated: 2026-07-22 07:33_

Validated **20** live decision/risk candidates against the V4.0 canonical schema. **11** pass; **9** need fixing before the V4.0 fail-closed emitters land.

## Failure counts by field

| Field | Count |
|---|---:|
| weak_why_it_matters | 8 |
| missing_why_it_matters | 1 |

## Rejections (top 30)

### decision D-3ced6cbb47 - Developer XP Dashboard

- **Title:** D013 — Agreed: Trim Developer Experience Dashboard Alerting to Actionable Signals Only
- **Owner:** Unassigned
- **Errors:**
  - $(System.Collections.Hashtable.field): must contain an impact/dependency signal word (because / so that / otherwise / risk / impact / blocks / delays / outcome)

### decision D-7f991874c7 - Developer XP Dashboard

- **Title:** D012 — Agreed: Shift Batch & MFT L0/L1 Operations to GOCC/GBO
- **Owner:** David Klan
- **Errors:**
  - $(System.Collections.Hashtable.field): must contain an impact/dependency signal word (because / so that / otherwise / risk / impact / blocks / delays / outcome)

### decision D-6f81d99006 - Rapid Recovery

- **Title:** D015 — Agreed: Mandatory Server Restart Authorization Decision Matrix in Every RRP
- **Owner:** Unassigned
- **Errors:**
  - $(System.Collections.Hashtable.field): must contain an impact/dependency signal word (because / so that / otherwise / risk / impact / blocks / delays / outcome)

### risk R-cd89918f9c - Rapid Recovery

- **Title:** Review and operationalize the vendor escalation format
- **Owner:** Unassigned
- **Errors:**
  - $(System.Collections.Hashtable.field): must contain an impact/dependency signal word (because / so that / otherwise / risk / impact / blocks / delays / outcome)

### risk R-38e1cf13ff - GOCC Transition

- **Title:** Team to secure contact + escalation path
- **Owner:** Unassigned
- **Errors:**
  - $(System.Collections.Hashtable.field): must contain an impact/dependency signal word (because / so that / otherwise / risk / impact / blocks / delays / outcome)

### risk R-228ae1101c - CyberArk Governance

- **Title:** Required escalation to GAM
- **Owner:** Unassigned
- **Errors:**
  - $(System.Collections.Hashtable.field): must contain an impact/dependency signal word (because / so that / otherwise / risk / impact / blocks / delays / outcome)

### risk R-9bfa424dbf - Developer XP Dashboard

- **Title:** ⚠️ Vendor dependency → slower MTTR unless escalation model is clearly defined
- **Owner:** Unassigned
- **Errors:**
  - $(System.Collections.Hashtable.field): must contain an impact/dependency signal word (because / so that / otherwise / risk / impact / blocks / delays / outcome)

### risk R-c7355ab891 - GOCC Transition

- **Title:** Strong dependency on cross-team alignment (GOCC, PS, GBO)
- **Owner:** Unassigned
- **Errors:**
  - $(System.Collections.Hashtable.field): missing required field

### risk R-2884ed4872 - Developer XP Dashboard

- **Title:** CMDB Mapping appears to be the strongest dependency across nearly every other workstream
- **Owner:** Unassigned
- **Errors:**
  - $(System.Collections.Hashtable.field): must contain an impact/dependency signal word (because / so that / otherwise / risk / impact / blocks / delays / outcome)
