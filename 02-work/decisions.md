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