# Decisions Log

## D001 — Deferred: Ad-Hoc Dashboard Request from Marketing

tags: #domain:rejected #system:newrelic #outcome:unaligned

**Date:** 2026-03-18
**Decision:** Deferred
**Reason:** Does not map to any Tier-2 or Tier-3 objective. Marketing lacks a defined SLA for landing page performance, and the request does not contribute to H-3 (AI Ops) or any scoped monitoring objective. Recommended Marketing raise a formal demand through the PMO for prioritisation in the next planning cycle.
**Related Objectives:** none
**Owner:** David Klan

---

## D002 — Agreed: GOCC Delivery Model for Japan Monitoring

tags: #domain:gocc-handover #system:newrelic #system:cmdb #system:xmatters #outcome:resilience

**Date:** 2026-03-26
**Decision:** Approved
**Summary:** Directionally agreed GOCC delivery model for Japan-based monitoring. Top monitoring priorities in order: (a) URL availability, (b) Performance / APM, (c) Rapid Recovery. GOCC handles standardised monitoring and first response. Application teams retain ownership of application logic, auth flows, and runbooks. ServiceNow CMDB must maintain relationships between Applications, Application Services, and Components (DB, middleware, etc.). Support groups and xMatters registration must remain current. Certificate renewals are already automated via GOCC. SPN renewals to adopt Managed Identity + federated credentials. Service account password management identified as a further automation opportunity (vaulting).
**Related Objectives:** H-3 (AI Ops / Incident Troubleshooting), H-4 (Unified Support), B-1 (Endpoint Monitoring & Post-Change Verification), B-4 (Infrastructure Resilience & DR)
**Owner:** David Klan
**Source:** GOCC 2026-03-26 New Relic Monitoring meeting

---

## D003 — Agreed: Simplify Patching for GOCC Handover and Weekday Execution

tags: #domain:patching #system:azure #outcome:resilience #domain:gocc-handover

**Date:** 2026-03-17
**Decision:** Approved (directional)
**Summary:** Agreed that the Japan patching process should be simplified and documented so that GOCC can execute patching independently, reducing dependency on ETS engineering resources. Weekday patching is the target but currently blocked by manpower constraints (split windows require split engineers) and incomplete Ansible automation. Birger's team is allocating engineers to protect batch operations during patching windows. Kanagaraj to document the end-to-end process and challenges as a prerequisite. Standard BAU Change transition for production patching to be pursued in parallel via a standard server template with application name mapping (Hideo).
**Related Objectives:** B-4 (Infrastructure Resilience & Disaster Recovery), H-4 (Unified Support), O4 (Robust Technical Core)
**Owner:** Birger Fjaellman
**Source:** 2026-03-17 Patching Schedule and Possible Standard BAU Transition meeting