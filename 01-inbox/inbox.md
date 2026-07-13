# Inbox

Items below are raw and unprocessed. Run the intake prompt to extract, classify, and assign.

---

- **2026-07-10 — W28 Copilot-Generated Work Summary (Recap Artifact)** #processed
  - **Source:** archive/W28_copilot.md
  - **From:** Copilot-generated week-in-review recap (David Klan working notes, week of 2026-07-06 → 2026-07-10; distribution set to Birger, Hari, Kelvin, Jonan, Deb, Balaji, Joan)
  - **Focus:** Theme-level summary of W28 activity across the Lapu-Lapu observability meeting (Dev XP synthetics, process monitoring, laptop/branch expansion, NRQL→Power BI, MMM L2 dashboard rebuild, GBO transition, CyberArk/AD accounts), the Ingenium GOCC/Japan meeting (production-incident desktop rehearsal), CyberArk/IAM governance escalation, Yegor's CMDB service-mapping status update, ADX/SIEM/Sentinel runbook sharing, Dev XP synthetic ping-check alert traffic, and the H1 report distribution.
  - **Key outcomes:**
    1. Observability meeting confirmed continued cadence on NRQL export → Power BI, AQA/UAT monitoring, Ingenium server access, process monitoring, laptop/branch monitoring, and Gold-application RRP completion — all already tracked under T005/T106/T117/T118/T121/T128 and T139.
    2. Process monitoring identified a new prerequisite: define application-specific baseline processes and tag servers by application category before broader alerting expansion — folds into existing T118 dev-XP alert-tuning workstream (add baseline-definition sub-scope) and T005/T121 MMM L2 dashboard rebuild.
    3. Central repository / FAQ for advanced monitoring configurations and edge cases proposed at the observability meeting — flagged as a colleague-experience enabler but not yet committed; parked (no new T### until an owner and scope are named).
    4. Ingenium GOCC/Japan meeting (2026-07-09) locked plans for a production-incident desktop rehearsal covering GOCC alerting, handoff to L2/L3, troubleshooting, restart sequences, escalation, MIM engagement, and RRP usability — a specific execution event that advances T003/T106/T139 and now warrants its own tracked activity (see T145).
    5. CyberArk Privileged Access Review escalated beyond the T143/T144 account-level remediation into a broader privileged-access governance concern (role concentration across Safes, evidence gaps for approval/risk acceptance, unclear challenge ownership) with named next actions: request ServiceNow approval history, IIQ certification records, identify the automated excessive-privilege / SoD monitoring control, and confirm Archer/CAP tracking once issue owners are identified (see T146).
    6. New Relic email traffic confirmed active Dev XP synthetic ping-check alerts for the ePOS DEV monitors under the "GOCC Japan Developer Experience Synthetic Policy" (Policy 7316475) — reinforces the need to finish T118 alert tuning and disposition whether ePOS non-prod alerts are actionable, non-prod-expected, or noise.
    7. `mfcgd\wasAPIMprod` service-account response from CyberArk/GAM restated the Semi-Managed configuration, 365-day expected expiry, manual PWMGR rotation dependency, notification behaviour, and ownership — no new material beyond what T143/T144 already carry.
    8. Yegor's CMDB update marked EDL, Vantage, IACB-WFI, Magellan, Agent Web, and SSW as done; Apollo done but JCUS service mapping needs redesign; finer Cosmos DB dependency mapping remains in progress — feeds ongoing CMDB-mapping work (T002 / T121) with no new T### required.
    9. GBO transition planning continued: a new GBO expert is expected to join from July 20 to support batch transition, additional stakeholder sessions are planned for open items from Manish, and vendor manualization is targeted for August 15 with parallel transition-plan development for a November go-live — all covered under T135/T136/T137/T138 and D018.
    10. ADX remained an app-owner responsibility per D016; the SIEM / ADX / Sentinel runbook was shared with application teams to support advanced troubleshooting and app-specific logging — no scope reopening.
    11. MMM L2 dashboard rebuild in progress; the existing dashboard was flagged as outdated and not to be used for executive figures until the new one lands — reinforces T005 / T121 status and the PS-Team engagement risk (T121 / T126).
  - **Actions extracted → T145, T146**
  - **Actions referenced → T002, T003, T005, T106, T117, T118, T121, T126, T128, T135, T136, T137, T138, T139, T143, T144**
  - **Decisions referenced → D011, D015, D016, D017, D018**

---

- **2026-07-02 — INC08672078 / PRB00024864: mfcgd\wasAPIMprod Credential Expiry Post-Incident Analysis** #processed
  - **Source:** archive/INC08672078-mfcgd_wasAPIMprod-credential-expiry.doc
  - **From:** Confluence export (INC08672078 problem-management page)
  - **Focus:** Root-cause analysis of the 2026-06-27 domain service account credential expiry that broke ING APIM communication for SCV, MLK, PAW, and SSW; captures CyberArk semi-managed account posture, ownership mapping, notification behaviour, and escalation gaps confirmed with Dennis Icaro (CyberArk PAS ops).
  - **Key outcomes:**
    1. Immediate fix: ING APIM communication for SCV, MLK, PAW, and SSW resumed at 10:06am HKT after Global Access Management (GAM) reset the `mfcgd\wasAPIMprod` password (expired 2026-06-27).
    2. Ownership mapping (ADUC): primary /S/108078/MLI/Hirooka, Kinue; backup /S/490766/MLI/Yeung, Rosalina; Safe owner = Kinue Hirooka. No clear registered accountable owner for the ID — a root-cause finding.
    3. CyberArk posture: `mfcgd\wasAPIMprod` is Semi-Managed (SSEMI) under Safe `NH_MLJ_ITIS_SUPP_S`, Platform `NH_WINDOM_SSEMI_DOMAINREC_DC_NoAAM`; rotation is manual by NH_MLJ_ITIS_SUPP_S Password Managers (PWMGR); expiry threshold = 365 days per Manulife IAM Standard. No PWMGR rotation performed since 2024-05-27.
    4. Notification: CyberArk only notifies (via `mlj_it_is_support@manulife.com`) when "Change the password immediately" has been executed; GAM (`Information_Security@manulife.com`) is the pre-expiry notification path. Escalation gap: no enforced action when notifications are ignored.
    5. Impacted systems: SCV, MLK, PAW, SSW ING APIM communication (all four listed in the Rapid Recovery scope) — new failure mode to embed in the APIM-consumer RRP set.
  - **Actions extracted → T143, T144**
  - **Actions referenced → T001, T003, T005, T106, T121**
  - **Decision referenced → D002, D004**

- **2026-07-01 — CAP-48585: Implement Process to Estimate Future Capacity Requirements (Delivery Plan + GRC Governance Record)** #processed
  - **Source:** archive/CAP+for+Capacity+Management.doc, archive/Corrective_Action_Plan.pdf
  - **From:** Confluence export (Delivery Plan) + GRC system export (Corrective Action Plan formal record)
  - **Focus:** Formalize the Lapu-Lapu delivery model for the CAP-48585 corrective action plan filed under Global Information Risk Management (GIRM) / Technology Stability, Reliability and Scalability, and align internal GOCC/ETS work packages with the September 2026 target.
  - **Key outcomes:**
    1. GRC record: CAP-48585 "Implement process to estimate future capacity requirements" (Issue-4027146, "Lack of regular monitoring to estimate future capacity requirements"). CAP Owner: Rasheersh Jha; Coordinators: Hideo Hasegawa, Eiji Omi, Naomi Tsuchida; Issue Owner: Sandeep Chakraborty; ELT Owner: Shamus Weiland; Responsible Common Unit: Information Technology (Japan); Responsible Parent Business Process: Systems Performance & Capacity; Impact Level: Moderate; CAP Health: On Track; CAP Days Open: 63; Original & Current Planned Completion: 2026-09-30; Opened 2026-04-27 by Naomi Tsuchida.
    2. Delivery plan objective: standardized, repeatable capacity management process that estimates future infrastructure capacity, identifies capacity-related risks proactively, enables GOCC to operate a predictive runbook-driven model, and supports MMM L2 maturity and Lapu-Lapu operational readiness.
    3. Scope: Gold applications (Phase 1) expanding to full estate (~65 apps); covers Compute (CPU/memory), Storage, Database growth, and Batch processing windows. Out of scope in Phase 1: deep workload re-architecture and advanced ML forecasting.
    4. Success criteria: 100% of Gold apps with baseline + 6-12 month forecast, defined thresholds & trigger actions; capacity risk integrated into RRP and MMM L2 dashboards; GOCC owns ongoing monitoring and forecast updates.
    5. Six work packages: WP1 Capacity Baseline (GOCC primary; deliverables D1.1 Baseline Dataset, D1.2 Data Source Inventory, D1.3 Data Quality Assessment); WP2 Demand Driver Definition (ETS primary; D2.1 Template, D2.2 Application Driver Matrix); WP3 Forecasting Model (GOCC primary; D3.1 Standard Method, D3.2 Per-App 6-12 Month Forecast, D3.3 Assumptions Log); WP4 Thresholds & Trigger Actions (GOCC primary; 70% Watch / 85% Plan / 95% Urgent; D4.1 Threshold Matrix, D4.2 Trigger Action Runbook, D4.3 Alerting Integration Requirements); WP5 GOCC Operationalization (monthly capacity review, quarterly forecast refresh; D5.1 GOCC Capacity Runbook, D5.2 Cadence Schedule, D5.3 RACI); WP6 Reporting & Evidence (ETS primary; D6.1 Power BI/NR Capacity Dashboard, D6.2 Standard Evidence Pack, D6.3 GOCC Import Template).
    6. Timeline (high-level): Phase 1 Gold applications (baseline + forecast); Phase 2 full estate rollout; Phase 3 automation + dashboard integration.
    7. Risks: inconsistent data quality → standardize sources/validation (WP1); lack of monitoring coverage → prioritize Gold apps; unclear ownership → formalize GOCC ownership (WP5); over-complex modeling → keep simple and transparent.
    8. Dependencies: GOCC onboarding & operating-model readiness (D017), NR/log monitoring data availability, CMDB accuracy (T002 / T121), application team engagement (T121).
    9. Immediate next actions: confirm GOCC ownership of WP1-WP5; align on baseline + forecast template (D1 / D3); pilot with top Gold applications (Ingenium, NDM, ServerF).
  - **Actions extracted → T142**
  - **Actions referenced → T002, T003, T005, T106, T118, T121, T128**
  - **Decision extracted → D019**
  - **Decision referenced → D017**

- **2026-06-26 — W26 Copilot-Generated Work Summary (Recap Artifact)** #processed
  - **Source:** archive/W26_copilot.md
  - **From:** Copilot-generated week-in-review recap (David Klan working notes, week of 2026-06-22 → 2026-06-26)
  - **Focus:** Theme-level summary of W26 activity across GBO Japan Batch Transition formalization, batch operations readiness, Rapid Recovery progress, MMM L2 expansion, observability & logging, dashboard & monitoring maturity, patching standardization, PS Team risk, and batch readiness risk.
  - **Key outcomes:**
    1. Recap confirms W26 headline: GBO Batch Transition Program formalized with seven work packages (WP1-WP7), September pilot target, "No Runbook = No Onboarding" gate, and identified inventory / ownership / runbook / 24x7 readiness risks — all already tracked under T135–T138 and D018.
    2. Batch operations readiness: ADX logging clarification, sample runbook + status report templates, xMatters group `ETS-GBO-N-Asia` confirmed — all captured under T136, T138, T140, T141.
    3. Rapid Recovery: Ingenium Gold RRP delivered; AI-assisted drafting; new QC workflow (David/Balaji QC, Jonan sequencing); mandatory authorization matrix reinforced — all covered by T106, T107, T139, D011, D015.
    4. MMM L2 expansion continues (T005 / T121); Ingenium as baseline; PS Team engagement remains the binding constraint.
    5. Dashboard & monitoring maturity: Employee XP / Business Capability feedback captured (T128), Dev XP alert tuning and process-monitoring focus (T118), external app health-check reports for IT-savvy business users flagged for T128 refinement.
    6. Patching standardization slowed by CMDB/ServiceNow knowledge gaps — already tracked under T017/T020/D003 with the CMDB-query skills risk under T126.
    7. PS Team contract-transition responsiveness reaffirmed as active delivery risk — tracked under T077, T121, T126.
    8. Batch readiness risk profile — inventory completeness, runbook quality, GBO operational readiness, local/regional support — mapped to T108/T135/T136/T137/T138.
    9. Next-week focus items (operating model & ownership boundaries, inventory & runbook standardization, RRP acceleration + QC, MMM L2 onboarding, 24x7 staffing/xMatters, Dev/Employee XP, PS Team engagement) all already covered by open tasks; no new T### required.
  - **Actions extracted → none (recap artifact; all themes mapped to existing tracked work)**
  - **Actions referenced → T005, T017, T020, T077, T106, T107, T108, T118, T121, T126, T128, T135, T136, T137, T138, T139, T140, T141**
  - **Decisions referenced → D003, D011, D015, D017, D018**

---

- **2026-06-25 — FW: Action items from the meeting with Japan BU (CAWLA Admin Confirmations: ADX Logging & DR Posture)** #processed
  - **Source:** archive/FW_ Action items from the meeting with Japan BU.eml
  - **From:** Rowena Zulueta (forwarding Godfrey Esguerra's CAWLA admin responses) → David Klan, Balaji Ravi; cc Izza Ilagan, Melanie Lumbao, Eric Vaughan
  - **Focus:** GBO follow-up after the 2026-06-24 GBO Batch Transition level-set with Japan BU — confirming ADX logging coverage/usage for batch troubleshooting and the CAWLA hosting/DR architecture; sharing sample runbook + batch status report templates and the xMatters group.
  - **Key outcomes:**
    1. ADX logging clarification: APROD ADX environment captures CA batch tracelog messages for all batch jobs across all regions (HKG/JPN/SGP) with a rolling 1-hour query window for performance; Godfrey proposed a separate ADX dashboard for GBO Batch Ops with read-only access scoped by application string (e.g., `JPN`) using KQL filters on Hostname `AZWAPPGBOAPPP01` + Message contains "JPN" + TimeGenerated >= ago(1h).
    2. CAWLA hosting and DR: HA architecture with primary CAWLA application and SQL MI database servers in EAS (East Asia), secondary servers in SEA (South East Asia). Cross-region execution introduces network latency; DB failover to SEA requires the application server to fail over in tandem to maintain optimal performance and stability.
    3. Sample runbooks (using the runbook template) and sample batch status reports (manual and automated) shared as reference material — feeds the WP3 CA-batch runbook standardization (T136).
    4. xMatters group confirmed for the GBO Asia coverage: `ETS-GBO-N-Asia` — feeds the GBO 24x7 staffing/registration work (T138).
    5. Re-engagement signal for ADX at the batch-app level (app-driven demand) — consistent with D016 (parked R2R push, resume on explicit demand).
  - **Actions extracted → T140, T141**
  - **Actions referenced → T136, T138**
  - **Decision referenced → D016, D018**

- **2026-06-25 — Direction (David Klan): FT/FS/Batch Kickoff, RRP QC Workflow, MMM L2 + Patching + GOCC Status** #processed
  - **Source:** archive/20260625+-+Direction.doc
  - **From:** Confluence export (David Klan direction notes)
  - **Focus:** Direction snapshot after the GBO Batch Transition level-set — File Transfer / File Share / Batch Job Services kickoff with GBO; ADX registration parked; status checkpoints on MMM L2, Rapid Recovery (with new draft QC workflow), Patching, Employee XP Dashboard, Dev XP Dashboard, CMDB mapping, GOCC transition; and additional related work on Branch / JPE-JPW.
  - **Key outcomes:**
    1. File Transfer / File Share / Batch Job Services kickoff held with Rowena, Izza, Balaji, and David. All Cobol jobs onboarded to CA (TBC). GBO 24/7 support confirmation in progress — team name, member list, shift schedule, xMatters registration, and Rowena's direct reports; Raj Kanesh joining the team.
    2. ADX Registration parked pending further instruction as an MMM L2 requirement (aligns with D016).
    3. MMM L2 (Pending PS Team engagement): Harish reached out to all Japan app owners; Ingenium data collected; remaining Gold app updates planned once PS Team members are assigned; Debamalya owns checklist / project-plan distribution; escalation in progress with Japan Team engaged; Ingenium ADX registration will enable other app thresholds — all aligned to T121.
    4. Rapid Recovery (Pending PS Team engagement): Ingenium Gold RRP delivered (Balaji Ravi / Senthil Kumar Jaganathan) to the mandatory standard template (full restart sequence WAS → CICS → DB + batch-slowness workaround; RTO/RPO Primary 2h/2h, DR 4h/4h); Kanagaraj's restart runbooks integrated as baseline; mandatory server-restart authorization decision matrix required in every RRP (D015); AI-assisted RRP drafting workflow built for PS team; PS team still needs to assign authors. NEW: David Klan and Balaji Ravi perform QC on incoming draft documentation; Jonan Tan Pangan sequences out responses.
    5. Patching (Pending PS Team engagement): Standardization and weekday patch registration meetings continue; first application weekday onboarding being confirmed; weekday patching for non-Gold non-batch apps/servers remains the path to reduce weekend workload (Karen, Sreekanth, Kanaraj). Risk reaffirmed: team repeats the same questions weekly and lacks CMDB/ServiceNow query skills to drive standardized patching changes.
    6. Employee XP Dashboard: David received feedback from Ito-san on Employee XP, Business Capability, and Branch monitoring dashboards; external app health-check reports for IT-savvy business members requested (already feeds T128).
    7. Dev XP Dashboard: In beta with AQA group; alerting tightened to actionable signals (push for real-time action, dashboard for full data surface across all environments, Rae's daily summary email for one-page health); sleeping-system false alerts being tuned out; active hours (9am–9pm JST) set; focus on process monitoring next (aligns with T118).
    8. CMDB Mapping: Yegor continues app-mapping cleanup (in-flight; no new task).
    9. GOCC Transition (Pending PS Team engagement): Yam moving teams and handing remaining applications to Rae; PS Team responsiveness risk during contract transition (aligned to T077, T121, T126).
    10. Branch / JPE-JPW: Non-prod VNet setup complete (post-provisioning fix pending); production VNet still blocked on subscription networking; 10 JP laptops in service; Philippine branch laptop monitoring kicked off — Donna submitted agent install REQ, Aleksei to configure, Vignesh to build PH branch dashboard with GOCC (mirrors Japan branch model). Aligns to existing T119/T120/T125.
  - **Actions extracted → T138, T139**
  - **Actions referenced → T020, T077, T106, T107, T108, T118, T121, T126, T127, T128**
  - **Decision referenced → D011, D012, D015, D016, D017**

- **2026-06-24 — GBO Japan Batch Transition: Level Set & Execution Plan (WP1–WP7, September Pilot)** #processed
  - **Source:** archive/20260624+-+GBO+Batch+Transition.doc
  - **From:** Confluence export (GBO Japan Batch Transition level-set meeting notes; deck reference: SharePoint BatchOpsTransition_v1.pptx)
  - **Focus:** Align stakeholders on the executable transition plan to migrate Japan batch operations into a GBO-owned 24x7 operating model, with a September pilot validating end-to-end ownership; lock operating principles, scope, work breakdown, timeline, risks, and the four decisions required.
  - **Key outcomes:**
    1. Operating principles: centralized GBO execution of batch workloads (24x7); Japan teams shift from execution to stability/input management/failure prevention; strict "No runbook = No onboarding" gate; full alignment with Lapu-Lapu global operating model (standardization, observability, governance). RACI: Japan Application Teams provide accurate job inputs, runbooks, and requests; GBO owns execution, monitoring, escalation, and governance.
    2. Phase-1 scope confirmed: CA batch jobs (primary focus), test-environment front-system batch operations (MLK, SCV, AGW, SSW, PAweb, WFI, BPM), and L0/L1 operational activities. To-be transition scope covers batch execution (test environments initially), ad-hoc batch request handling, input validation and prerequisite checks, execution monitoring and reporting, and output coordination with downstream systems. Manual and non-CA jobs out-of-scope pending inventory + readiness validation.
    3. Work breakdown locked: WP1 Operating Model Definition (24x7 model + RACI + SLO categories scheduled/ad-hoc/incident + GBO → L3 escalation); WP2 Inventory Baseline (consolidate complete CA job inventory + non-CA/manual; map ownership and execution dependencies; capture failure patterns and incident history); WP3 Runbook Standardization (L1/L2/L3-aligned template; convert existing docs; validate completeness/testability; enforce runbook onboarding gate); WP4 Execution Readiness (configure CA jobs under GBO ownership; validate access/credentials, tooling; align monitoring on job success/failure; run execution simulations and failure scenario testing); WP5 Pilot Implementation (select 1 pilot front-system app, fully onboard inventory + runbooks, transition execution to GBO, validate zero dependency on Japan execution and clean escalation flow); WP6 Ingenium Parallel Track (align with existing RRP/failure patterns, ensure high-quality runbooks and recovery alignment, transition incrementally to GBO); WP7 Governance & Reporting (success metrics — execution success rate, failure recovery time — integrated into GBO monitoring + Lapu-Lapu governance; reporting cadence and visibility/accountability dashboards).
    4. Timeline locked: Discovery & Inventory now → mid-July (complete batch inventory + scope definition); Onsite GBO Deployment mid-July (local Japan support established); Runbook Build & Dry Runs late July → August (validated execution and failure readiness); Pilot Cutover September (full GBO execution of selected pilot front-system app).
    5. Top risks and mitigations: incomplete inventory (esp. non-CA/manual) → enforce WP2 baseline before onboarding (T108); unclear ownership model → formalize RACI in WP1 (T135); 24x7 support readiness unproven → validate capability during pilot (T138); missing/poor runbooks → enforce runbook gating in WP3 (T136); lack of Japan on-site support → deploy GBO local resource (T138).
    6. Four decisions required for confirmation: (a) GBO full ownership of batch execution (24x7); (b) Japan input responsibilities (inventory + runbooks); (c) pilot application selection (front-system domain); (d) timeline alignment (July readiness → September pilot). Captured under D018.
    7. Expected outcomes: release engineering capacity for modernization/automation, improved consistency/reliability/audit readiness via runbooks, reduced manual effort and SME dependency, scalable global batch operations model aligned to GBO/GOCC.
    8. Immediate next steps: finalize RACI and operating model boundaries; complete CA job inventory baseline; define and distribute runbook template; confirm GBO resourcing (24x7 + onsite Japan); select pilot application and begin onboarding.
  - **Actions extracted → T135, T136, T137, T138**
  - **Actions referenced → T108, T109, T110, T127**
  - **Decision extracted → D018**
  - **Decision referenced → D012, D017**

---

- **2026-06-19 — W25 Copilot-Generated Work Summary (Recap Artifact)** #processed
  - **Source:** archive/W25_copilot.md
  - **From:** Copilot-generated week-in-review recap (David Klan working notes, week of 2026-06-15 → 2026-06-19)
  - **Focus:** Theme-level summary of W25 activity across Rapid Recovery Plan / MMM L2, Lapu-Lapu / GOCC transition, Batch / MFT transition readiness, operational governance + BAU alignment, Azure cost optimization, and dashboard/collaboration enablement.
  - **Key outcomes:**
    1. Recap confirms continued cadence on the in-flight workstreams already tracked — RRP standardization (T106 / D011 / D015), MMM L2 (T005 / T121 / T126), GOCC transition + onboarding (T077 / T118 / D017), batch/MFT readiness (T108–T110 / D012 / T127), patching governance (T017 / T020 / D003), and dashboard alerting tune-up (T128 / D013).
    2. Mentions Azure cost optimization review and GOCC Azure resource reduction discussions at theme level only; too vague to extract a discrete task — flagged for direction at the next governance forum if it warrants its own workstream (otherwise folds into T002 orphan-VM hygiene).
    3. Mentions SNOW asset/CMDB sync at theme level only; folds into existing CMDB-mapping work (T002 + Yegor's in-flight app-mapping cleanup).
    4. Observation that work is skewed toward coordination and governance rather than isolated delivery — aligns with the PS Team transition responsiveness risk already tracked (T121 / T126) and the contract transition flagged under T077 (Yam → Rae handover).
    5. "Next focus" items (RRP ownership/enforcement, Lapu-Lapu readiness scoring, batch/MFT clarity, measurable deliverables/dashboards) all already covered by open tasks; no new T### required.
  - **Actions extracted → none (recap artifact; all themes mapped to existing tracked work)**
  - **Actions referenced → T002, T005, T017, T020, T077, T106, T108, T109, T110, T118, T121, T126, T127, T128**
  - **Decisions referenced → D003, D011, D012, D013, D015, D017**

- **2026-06-18 — Lapu-Lapu GOCC (Dashboards, Moogsoft/Ansible Auto-Restart, Firewall Approval, Runbook Standardization)** #processed
  - **Source:** archive/20260618+-+Lapu-Lapu+GOCC.doc
  - **From:** Confluence export (Lapu-Lapu GOCC meeting notes — David Klan, Jonan Tan Pangan, Rae Judavar, Mary Kris Cabunilas, Mark Adriel Manuel, Balaji Ravi, Birger Fjaellman, Dennis Talento, Angelo Tiu Mariano)
  - **Focus:** Employee/Developer Experience dashboard feedback, automated Moogsoft + Ansible non-prod incident response, Enginium non-prod URL monitoring firewall approvals, Ingenium L1/L2/L3 runbook clarity, GOCC transition runbook standardization, Ingenium Rapid Recovery + KB publication, Philippines branch monitoring go-live.
  - **Key outcomes:**
    1. Sales team and other business stakeholders found the Employee Experience and Business Capability dashboards useful and asked for further access and a feedback mechanism; David and Rae exploring direct New Relic access and importing external reports into Power BI.
    2. Solace SIT/UAT environments exhibit recurring instability; David contacted the app owner and is partnering with the test environment team to investigate.
    3. Plan locked to integrate non-prod alerts with Moogsoft (target end of month / early next month) and trigger an Ansible auto-restart on failure; until live, the team runs the Ansible script manually with Moogsoft registering incidents after validation. Escalation: failed restart → GOCC → L2.
    4. Enginium firewall approval pending (switch to Azure jump due to on-prem decommissioning); incomplete approvals previously blocked GOCC validation during non-prod patching — Rae driving approval, Mark to validate URLs post-change.
    5. Ingenium runbook lacks explicit L2 roles; current runbook retained for Japan market apps until September, then updated for the new GOCC unified operating model. L0 → L1 → L2 → L3 procedural flow confirmed.
    6. Runbook format/versioning improvements proposed (metadata extraction, version control, ServiceNow integration) to support automation and AI-assisted RRP drafting.
    7. Ingenium Rapid Recovery Plan complete with KB article published; extension to other apps requires PS Team coordination (Harish + Hirooka-san).
    8. Philippines branch monitoring is operational; Singapore expressed interest in similar solutions (future opportunity).
    9. Some applications currently out-of-scope for GOCC transition; Rae to follow up with Donna and AMS to confirm reasons; minimum availability monitoring agreed to remain in scope even where deeper performance/capacity coverage is excluded.
  - **Actions extracted → T128, T129, T130, T131, T132, T133, T134**
  - **Actions referenced → T003, T106, T112, T118, T124**
  - **Decision extracted → D017**
  - **Decision referenced → D011**

- **2026-06-17 — Test Environment Front-System Batch Operation Transition Proposal (Balaji Ravi)** #processed
  - **Source:** archive/Batch Operation - Front system.pptx
  - **From:** Balaji Ravi (proposal deck dated June 17, 2026)
  - **Focus:** Formal proposal to transition test-environment front-system batch operations (MLK, SCV, AGW, SSW, PAweb, WFI, BPM) to GBO/GOCC under the D012 transition direction.
  - **Key outcomes:**
    1. Current state: batch execution in FT/SIT/UAT; ad-hoc batch requests from AQA/BA; full lifecycle (prerequisites, input prep, system date config, execution, output handoff); high engineering effort with no standardized runbooks and significant SME dependency.
    2. Proposed transition scope: batch execution in test environments, recurring/ad-hoc batch request handling, prerequisite + input file validation, execution monitoring and reporting, output coordination — all moved to GBO/GOCC.
    3. Benefits framed as: engineering capacity release for modernization, standardization via runbooks, lower-cost delivery model, scalability via time-zone/shift coverage, reduced manual-error risk, and audit-readiness.
    4. Aligns directly with D012 and the existing batch-transition workstream (T108–T110); no new actions beyond what is already tracked.
  - **Actions extracted → none (proposal artifact advancing D012, T108–T110)**
  - **Actions referenced → T108, T109, T110, T127**
  - **Decision referenced → D012**

- **2026-06-16 — Direction (David Klan): ADX Park, MMM L2 PS Engagement, Batch Services Intake** #processed
  - **Source:** archive/20260616+-+Direction.doc
  - **From:** Confluence export (David Klan direction notes)
  - **Focus:** Direction adjustments across ADX, MMM L2, Rapid Recovery, Patching, Dashboards, CMDB mapping, GOCC transition, branch monitoring, and the File Transfer / File Share / Batch Job Services intake.
  - **Key outcomes:**
    1. ADX onboarding push at the R2R workstream is parked until Balaji signals "engage"; incident analysis will guide central-logging needs, with Yegor supporting investigations via his ADX ACL access.
    2. MMM L2 progress for remaining Japan Gold apps is blocked on PS Team engagement; Harish to be introduced to Hirooka-san for the entry point; Debamalya retains checklist/project-plan ownership.
    3. Rapid Recovery + Patching remain pending PS Team engagement, with patching risk that the team repeats the same questions weekly and lacks the CMDB/ServiceNow query skills to drive standardized patching changes.
    4. Employee XP dashboard: Ito-san feedback received; external app health-check reports requested for IT-savvy business users — feeds T128 with the GOCC meeting feedback.
    5. Dev XP dashboard: alerting tightened, sleeping-system false alerts being tuned out, active hours (9am–9pm JST) set; focus on process monitoring next.
    6. CMDB mapping: Yegor continues app-mapping cleanup (in-flight under existing CMDB-area work; no new task).
    7. GOCC transition: Yam moving teams, handing over remaining applications to Rae; PS Team responsiveness risk during contract transition flagged.
    8. Branch / JPE-JPW: non-prod VNet complete (post-provisioning fix pending); production VNet still blocked on subscription networking; 10 JP laptops in service; Philippines branch monitoring set up (Donna agent install REQ, Aleksei to configure, Vignesh to build PH dashboard with GOCC).
    9. File Transfer / File Share / Batch Job Services intake: dynamic-date batch ingestion noted as automation design intent; Arbindra may provide batch job failure data; Izza to be added to the weekly meeting.
  - **Actions extracted → T126, T127**
  - **Actions referenced → T002, T108, T109, T110, T116, T118, T119, T120, T121, T122, T123, T124, T125**
  - **Decision extracted → D016**

- **2026-06-12 — [Lapu-Lapu] Weekly Status Update W24 (Distribution Copy)** #processed
  - **Source:** archive/[Lapu-Lapu] Weekly Status Update.eml
  - **From:** David Klan → Birger Fjaellman, Kelvin Leung, Hari Pothakamuri (cc Joan Lee, Debamalya Das, Jonan Tan Pangan, Balaji Ravi, Harish Arasu)
  - **Focus:** Distribution copy of the W24 weekly status report sent to leadership on 2026-06-12.
  - **Key outcomes:**
    1. Matches the W24 record already filed in 03-reporting/weekly/2026-W24.md; dashboard metrics, risks, ADX, MMM L2, Rapid Recovery, and INC08624117 narratives align with that report.
    2. PS Team contract transition risk surfaced as the new headline risk (less responsiveness expected) — already reflected in T121/T126 and the W24 narrative.
    3. No new actionable content beyond the filed report.
  - **Actions extracted → none (report-only artifact)**

---

- **2026-06-09 — LapuLapu ETS, GOCC and Obs (Weekly Touchpoint)** #processed
  - **Source:** archive/20260609+LapuLapu+ETS,+GOCC+and+Obs.doc
  - **From:** Confluence export (Lapu-Lapu ETS / GOCC / Observability weekly meeting notes)
  - **Focus:** Beta-test status for the Developer Experience Dashboard, ACL compliance for shared folders, MMM L2 coverage, APM rollout, ADX coverage in Asia, Rapid Recovery readiness, JPE/JPW + branch office monitoring, weekday patching, and the INC08624117 Ingenium freeze post-incident discussion.
  - **Key outcomes:**
    1. Developer Experience Dashboard alerting being tightened with the AQA beta group — push alerts only for actionable signals, full data kept in the dashboard, daily summary email (Rae) for one-page health.
    2. Shared-folder ACL compliance brought into scope: Aleksei's compliance checker + folder governance pilot on small migrated shares; GOCC Middleware Operations is the prospective long-term owner. File transfer / batch remain separate (D012); ACL only.
    3. MMM L2: Harish has reached out to all Japan app owners; Ingenium data collected; remaining updates expected by Friday. Debamalya to share MMM L2 checklist and project plan.
    4. APM successfully configured for Ingenium non-prod (Angelito, Sai); production rollout pending outage scheduling.
    5. ADX (centralized logging): R2R-scope ADX onboarding was dropped after discussion with Hari and Tabitha; ADX onboarding is now app-owner responsibility, but Asia ownership for ADX log monitoring/management needs to be stood up by GOCC Middleware Operations + Observability. Jonan to update David by Thursday/next week.
    6. Rapid Recovery: AI-assisted workflow built for PS team to draft RRPs; PS team still needs to assign authors. Server restart authorization decision matrix to be embedded in every RRP (D015).
    7. Branch/JPE-JPW: Non-prod VNet complete (post-provisioning fix pending); prod VNet still blocked on subscription networking; 10 JP laptops in service; Philippines branch laptop agent install REQ in progress (Donna), Aleksei to configure, Vignesh to build PH branch dashboard.
    8. Weekday patching for non-gold, non-batch apps/servers to be implemented to reduce weekend workload (Karen, Srikranth, Kanu Rajesh).
    9. INC08624117 Ingenium server freeze (2026-06-08) resolved by restart; root cause under investigation with Red Hat; Jonan to follow up with Dennis. Jonan proposed GOCC Middleware Operations take on post-restart application health checks.
    10. Joan and Rowena to be added to the weekly meeting to represent GBO.
  - **Actions extracted → T117, T118, T119, T120, T121, T122, T124, T125**
  - **Actions referenced → T003, T005, T020, T108, T116, T123**
  - **Decision extracted → D013, D014, D015**

- **2026-06-08 — GOCC / Japan Lapu-Lapu Project Hub (Confluence Landing Page Snapshot)** #processed
  - **Source:** archive/GOCC+_+Japan+-+Lapu-Lapu+project.doc
  - **From:** Confluence export (Lapu-Lapu project landing/index page)
  - **Focus:** Snapshot of the Lapu-Lapu project landing page on Confluence — navigation hub for Alerting & Recovery, Observability & Monitoring, Reporting & Insights, OKRs, Source of Truth, side quests, meeting notes archive, ADX coverage docs, Rapid Recovery Information Hub, gold/silver/bronze app lists, and the INC08624117 Ingenium incident headline.
  - **Key outcomes:**
    1. Confirms current scope split: Employee Experience Dashboard (Japan Prod), Developer Experience Dashboard (Japan Non-Prod), Japan Business Capability dashboard, GOCC transition (synthetic/uptime + incident routing handover), and RRP (documented, tested, KB-published).
    2. Confirms Observability scope (MMM L2, ADX, branch minions, certificates), Reporting scope (Power BI Lapu-Lapu/Epsilon/Gopher + Super Ops), and side-quest portfolio (Gopher, Pulse, Patching, CMDB Mapping, NW Inventory, File Transfer/Batch/File Share).
    3. Incident analysis backlog page lists Ingenium, eClaims, OSCS, SURF, IACB-WFI, Sales Support Web, and Vantage — confirms RRP scope set already tracked in T106 + RRP work.
    4. Featured incident headline: INC08624117 - Ingenium (2026-06-08) — same incident tracked under T123.
  - **Actions extracted → none (reference/navigation hub)**
  - **Actions referenced → T003, T004, T005, T006, T077, T079, T081, T106, T123**

- **2026-06-04 — Lapu-Lapu GOCC and Japan (Application Monitoring Onboarding & Dashboard Review)** #processed
  - **Source:** archive/20260604+-+Lapu-Lapu+GOCC+and+Japan.doc
  - **From:** Confluence export (GOCC / Japan weekly touchpoint meeting notes)
  - **Focus:** Dashboards (Prod Employee Experience + Non-Prod Developer Experience), URL monitoring transition to GOCC, branch dashboards + DC Minion comparison, xMatters quality control, ADX firewall/agent posture, and confirmation that File Share / File Transfer stays separate from Lapu-Lapu for now.
  - **Key outcomes:**
    1. David to set up sharing session with PS Team for the Employee Experience Dashboard, including Branch Office monitoring scope.
    2. Developer Experience Dashboard: validate current Health Check email config to replace the TEM-owned daily report; align alert handling with TEM (Sangram, Rupesh).
    3. URL Monitoring transition to GOCC: Jonan to onboard a data-quality diff between the URL onboarding source and ServiceNow (catches strike-through fonts and similar data-quality defects).
    4. Branch dashboards + DC Minion node-to-node comparison reports — David to write the PRD and send to OAR Team (debamalya_das, edward_ian_vera, jesusjr_pepito, paula_segovia).
    5. xMatters: OAR (Jonan/Edward) to engage the vendor for a Japan group/member registration quality report and ongoing QC.
    6. SMS spam incident response — handled by Monitoring Team (referenced INC08574374 / T104).
    7. ADX: GOCC to verify firewall openings and agent installation status (feeds the broader ADX Asia coverage assessment).
    8. File Share / File Transfer to remain a separate workstream from Lapu-Lapu for now (subsequently revisited 2026-06-09 — ACL compliance pulled in via D014).
  - **Actions extracted → T112, T113, T114, T115, T116**
  - **Actions referenced → T077, T083, T104**

- **2026-06-01 — RE: KLO - Application Onboarding (Cross-Market GOCC MMM)** #processed
  - **Source:** archive/RE_ KLO - application onboarding.eml
  - **From:** Birger Fjaellman (reply to David Klan's forward of the Kelvin Leung / Julian Wai / Harish Arasu thread)
  - **Focus:** Cross-market KLO reduction initiative driven by Kelvin Leung — onboard non-Gold applications into GOCC MMM beyond Japan, using the Japan onboarding playbook and the 2026LapuLapu Power BI dashboard as the cross-market status reference.
  - **Key outcomes:**
    1. Kelvin Leung is engaging market CIOs to onboard more applications into GOCC MMM to reduce Planview hours booked under Incident Management and Monitoring & Alert Response (the KLO categories).
    2. Julian Wai directed Harish Arasu to re-initiate the GOCC onboarding process for new markets using the same template, with David Klan as the Japan reference contact.
    3. David shared the 2026LapuLapu Power BI dashboard (Japan applications, metal rating, monitoring/alert/incident response categories) with Harish on 2026-05-27; Harish has not responded.
    4. Birger requested this item be added to the weekly status report so the stalled outreach stays visible until contact with Harish is re-established.
  - **Actions extracted → T111**
  - **Actions referenced → T070, T077, T081**

- **2026-04-13 — Fw: URL/API [TEST - UAT] Morning Health Check (TEM Daily Non-Prod Report)** #processed
  - **Source:** archive/Fw_ URL_API [TEST - UAT] - Morning Health Check- Automation Execution Results Summary - 2026-03-26 09_31_02 (1).eml
  - **From:** David Klan forward (Kiran Puthanveettil Mohandas → David Klan/Birger; original sender Rupesh Mishra) to Rae Judavar, Mary Kris Cabunilas, Yam Villanueva, Dennis Talento
  - **Focus:** TEM team's automated daily non-prod environment health check report (URL/API status across ~120 application/environment endpoints for AIS, Apollo, Cone, CWS SFDC, IACB, Ingenium, Iwin, Magellan, MLK, NBBPM, PA-Web, SCV, SSW, etc.) shared with the Developer Experience Dashboard team as a reference dataset.
  - **Key outcomes:**
    1. Confirms TEM already publishes a daily non-prod URL/API health summary covering most Japan non-prod environment groups — overlaps with the Developer Experience Dashboard coverage scope.
    2. ePOS environments are not in the TEM daily report (gap previously called out in the 2026-03-26 GOCC New Relic Monitoring meeting and tracked under T013/T014).
    3. Useful as a reconciliation source for the 50/60 non-prod environment groups currently in the Developer Experience Dashboard and for future Service ID workaround design.
  - **Actions extracted → none (reference artifact)**
  - **Actions referenced → T013, T014, T093**

- **2026-05-28 — Batch Non-Prod Team Syncup: L0/L1 Transition & Inventory Baseline** #processed
  - **Source:** 20260528+-+Batch+Non-Prod+Team+syncup.doc
  - **From:** Confluence export (Batch Non-Prod team syncup meeting notes)
  - **Focus:** Confirm direction for shifting batch and file transfer L0/L1 operations from project execution to a BAU service model under GOCC/GBO ownership.
  - **Key outcomes:**
    1. Confirmed direction: L0/L1 batch and file transfer operations to transition from Batch/PS/App support teams to GOCC (infra + transfer) and GBO (batch execution), freeing engineering/testing for higher-value work.
    2. Batch execution to be standardized via CAWLA platform; QA team automation tools currently in testing, pending firewall opening for broader rollout.
    3. Critical blocker identified: no complete inventory of jobs, applications, or ownership — multiple teams (Engineering, MDM, Batch, others) support overlapping areas with no clear service boundaries.
    4. ~600 open issues reported but unsegmented by system/team, making ownership attribution impossible.
    5. Non-production batch operations will serve as testbed for ownership clarity, automation validation, and operating model design.
    6. Target ownership model: GBO (batch execution/control), GOCC (file transfer + infra), App Teams (data/application logic).
  - **Actions extracted → T108, T109, T110**
  - **Decision extracted → D012**

- **2026-05-28 — Japan Batch/MFT Opportunities: Multi-Vendor Model & Transition Readiness** #processed
  - **Source:** Japan+Batch_MFT+Opportunities+Meeting+Notes+and+Key+Outcomes.doc
  - **From:** Confluence export (Joan Lee meeting notes)
  - **Focus:** Review batch operations structure, multi-vendor landscape, and transition constraints for Japan batch/MFT operations.
  - **Key outcomes:**
    1. Current batch operations depend on a multi-vendor model (Geantec, Cognizant, Tech Mahindra) with fragmented ownership and processes.
    2. Technical and process constraints require careful planning and phased execution — parallel monitoring setup accepted for current year, formal transition targeted next year.
    3. Priority focus on reducing delays in batch execution and file transfers (MFT).
    4. Transition readiness gaps: lack of clarity on manual batch processes, MFT integration details, and end-to-end ownership.
    5. Decision to collect structured questions from all teams to clarify manual processes and MFT uncertainties before transition proceeds.
    6. CA workload automation confirmed for job execution and monitoring; language barrier challenges previously affecting coordination acknowledged.
  - **Actions extracted → none (actions consolidated into T108, T109, T110 from sibling meeting)**
  - **Decision referenced → D012**

- **2026-05-28 — GBO Opportunities Briefing: Japan Batch Landscape & Contract Constraints** #processed
  - **Source:** GBO Opportunities.pptx
  - **From:** Briefing deck (Japan batch/MFT operations overview)
  - **Focus:** Context briefing on Japan batch operations landscape, IS managed service contracts, and transition opportunities/constraints.
  - **Key outcomes:**
    1. File transfer methods in use: SFTP, RSYNC, HULFT, MFT — multiple protocols complicate standardization.
    2. IS managed service contracts: Cognizant (CTS) for PAS dev+ops, Tech Mahindra for non-PAS dev, GienTech for non-PAS ops / batch ops / ITSM — GienTech contract transitioning to new vendor Q3 2026.
    3. Total contractor base ~1,000 across three vendors.
    4. Production CA batch run by Batch operations (~5 perm + GienTech); Non-prod by PS (GienTech different team) and AQA (Cognizant, Tech Mahindra).
    5. Constraints: GienTech contract transition will tie up staff; fixed-bid IS contracts mean savings will be indirect.
    6. Opportunities: IS contract ramp-down supports GBO/GOCC transition timing; KLO reduction possible; adding CA to ADX for batch observability.
  - **Actions extracted → none (reference/context material supporting D012)**

- **2026-05-28 — RRP Ingenium App Japan (Updated): Recovery Plan Deliverable** #processed
  - **Source:** RRP_Ingenium_App_Japan_updated_20260528.docx
  - **From:** Balaji Ravi / Ingenium support team (updated RRP document)
  - **Focus:** Completed Rapid Recovery Plan for Ingenium - App - Japan (Gold application, APM0004174) using the mandatory standard template with scenario-based recovery sequences.
  - **Key outcomes:**
    1. RRP covers two recovery scenarios: (1) full service restart sequence (WAS → CICS → DB, with validated bring-up order) and (2) batch slowness workaround (CPU/memory/IO diagnostics, DB lock analysis, stray process kill with PS confirmation, batch retrigger).
    2. RTO/RPO defined: Primary 2hr/2hr, DR 4hr/4hr — sourced from the 2025 Criticality Framework Revision.
    3. Local HA, load balancing, and DR site parity all confirmed as Y.
    4. Support groups documented: Asia-JP-Ingenium-Owner-A (managed by), Asia-JP-PST-PolicyAdmin-IPCRW (support), owned by Rosalina Yeung, assigned to Senthil Kumar Jaganathan.
    5. Tech stack, known endpoints (prod + UAT URLs), and CI metadata captured in appendix.
    6. This is one of the 6 Gold application RRPs required by T106 — advances the June 10 reboot/restart milestone and June 30 audit-ready completion target.
  - **Actions extracted → none (deliverable artifact advancing T106)**
  - **Actions referenced → T106, T107, T003**

- **2026-05-26 — RRP Touchpoint: Gold Application Rapid Recovery Execution** #processed
  - **Source:** 20260526+-+RRP+Touchpoint.doc
  - **From:** Confluence export (RRP touchpoint meeting notes)
  - **Focus:** Lock execution approach, timeline, and ownership for delivering scenario-based Rapid Recovery Plans for 6 Gold applications under regulatory priority.
  - **Key outcomes:**
    1. Mandatory standard template adopted for all RRPs, covering triage steps, recovery sequences, and scenario-based documentation (restart, workaround+restart, non-restart).
    2. Controlled publishing process: all RRPs must be submitted to Thabani for validation and KB publishing — no self-publishing allowed.
    3. Hard milestone: reboot/restart sequences for 6 Gold apps due June 10; full audit-ready RRP completion due June 30.
    4. Gold apps are not yet fully compliant with architecture standards (local redundancy, LB, DR) — remediation planned separately.
    5. GOCC (George/Jonan) acts as extension of app support, driving triage speed during incidents; ITSM integration confirmed with post-incident RRP updates triggered via Incident/Problem Management.
    6. Restart runbooks from Kanagaraj's team must be integrated as critical baseline before RRP scenarios can be authored.
    7. RRPs are linked via PEM to CIs in Knowledge Base; production readiness gate requires RRP + SRD + DR.
    8. Thabani validation bottleneck flagged as risk for the tight June timeline.
  - **Actions extracted → T106, T107**
  - **Actions referenced → T003, T041, T084, T085**
  - **Decision extracted → D011**

- **2026-05-27 — 2026 Plan Ideas (David Klan Copy)** #processed
  - **Source:** 2026 Plan Ideas_DK.docx
  - **From:** David Klan (plan ideas document)
  - **Focus:** David Klan's copy of the 2026 ETS-Japan plan ideas covering reliability engineering, operational standards, pipelines, infrastructure, security, asset management, PPS service improvement, and Ingenium modernization.
  - **Key outcomes:**
    1. Content aligns to the existing Tier-2 objectives B-1 through B-7 already registered from Birger Fjaellman's source document (2026_Birger_Plan Ideas.docx).
    2. Includes a "Ring-Fence MITDC Team" proposal (5–6 person L2 team with Ingenium/Pathfinder/WAS/DB2/Microfocus/TX-Gateway skills to proactively support Japan IT) — not yet committed or sponsored.
    3. No new standalone objectives or tasks beyond what is already captured; MITDC team ringfencing noted for future consideration.
  - **Actions extracted → none (reference copy; objectives already registered)**

- **2026-05-22 — Incident Analysis: Unintended SMS/LINE Messages Sent to 70,000 Customers (INC08574374)** #processed
  - **Source:** Incident+Analysis_+Unintended+SMS_LINE+Messages+Sent+to+70,000+Customers+Due+to+Data+Update+Error.doc
  - **From:** Confluence export (incident analysis page)
  - **Focus:** Root cause analysis and Lapu-Lapu alignment assessment for INC08574374 — mass SMS/LINE messaging caused by incorrect batch data update without validation gates.
  - **Key outcomes:**
    1. Root cause: bad customer data update entered batch input; batch-to-notification flow had no recipient eligibility or volume validation, allowing mass outbound messages.
    2. Detection was reactive (business/customer signals), not automated; no volume anomaly or data integrity alerts fired.
    3. Historical problem records (PRB00023122, PRB00022754) show recurring gaps in batch ordering, logging, and integrity checks.
    4. Immediate fix needed: message suppression / circuit breaker and recipient-volume guardrails before next batch window.
    5. Strategic improvement: end-to-end observability for batch → data integrity → message generation with actionable alerts and L1/L2 runbooks.
    6. Existing batch failure runbook (KB0033382) does not cover "batch succeeded but produced wrong outbound communications" — a dedicated outbound messaging mis-send runbook is needed.
    7. Lapu-Lapu alignment: batch jobs monitored for failure but not bad outcomes; missing controls for abnormal data updates; missing end-to-end telemetry for outbound messaging.
  - **Actions extracted → T104, T105**

- **2026-05-22 — W21 Weekly Breakdown (Pre-Analysis)** #processed
  - **Source:** W21_Breakdown.md
  - **From:** David Klan (weekly activity analysis)
  - **Focus:** Consolidated W21 activity breakdown across all Lapu-Lapu workstreams for weekly report generation.
  - **Key outcomes:**
    1. RRP formally transitioned from planning to active execution with Ingenium as the pilot dataset; incident pattern analysis files created (Ing_INC_6Months).
    2. 11 new monitoring/observability tasks registered (APM policies, MMM L2, Minion deployment, ADX log onboarding) — already captured in T096–T103.
    3. Dashboards functionally complete (68/88 EE, 50/60 DE), entering usability/coverage refinement with Service ID workarounds in design.
    4. Minion strategy expanded to branch-level cross-location observability with GOCC-compatible deployment standards.
    5. GOCC onboarding stalled at 25/65 applications with no new completions — velocity risk flagged.
    6. CMDB data quality confirmed as critical-path dependency for RRP scaling.
    7. xMatters escalation model nearing definition; roster reconciliation and coverage-gap remediation continuing.
    8. Confluence access issue resolved during the week.
  - **Actions extracted → none (activity summary; tasks already registered)**
  - **Actions referenced → T003, T006, T007, T093, T096, T097, T098, T100, T101, T102, T103**

- **2026-05-11 — Epsilon Kickoff Review: AQA Information Sharing Session** #processed
  - **Source:** archive/Re_ Epsilon Kickoff Review_ AQA Information Sharing Session.eml
  - **From:** David Klan (meeting summary reply to original invite)
  - **To:** AQA team (Manish Kumar Kapil, Sangram Keshari Swain, Rupesh Mishra), Balaji Ravi, Prabu Thiagarajan, Birger Fjaellman
  - **Focus:** Align AQA team on the Ingenium 3-tier architecture transformation, confirm CI/CD and automated testing direction, and define QA engagement model for Epsilon.
  - **Key outcomes:**
    1. Two decisions locked: AQA automation scripts will be onboarded into Jenkins pipeline for Ingenium; Delta project test cases will be reused for Epsilon migration testing.
    2. QA scope expands significantly from app-level to end-to-end validation including infrastructure, failover, integration, regression, and performance testing across all tiers.
    3. Architecture shifting to 3-tier model (presentation with load balancer, middleware with active-passive cluster, data layer with HA under evaluation) introduces new failure modes and cross-system integration risks.
    4. Short-term CI/CD standardized on Asia Jenkins; planned GitHub Actions transition not yet ready. Target is zero-manual testing with standardized pipelines.
    5. Business impact: ~¥54M annual licensing savings (¥240M → ¥187M), release cycle reduction from 4–5 hours to 1–2 hours with automation.
    6. Biggest risk: QA scope expansion is understood conceptually but not operationally defined yet.
    7. POT in progress, CI/CD + GitHub migration targeted Q2 2026, production rollout targeted Mar/Apr 2027.
  - **Actions extracted → T088, T089, T090, T091, T092**
  - **Actions referenced → T008, T010, T086, T087**
  - **Decision extracted → D010**

- **2026-04-24 — [Lapu-Lapu] Weekly Status Update W17** #processed
  - **Source:** archive/[Lapu-Lapu] Weekly Status Update W17.eml
  - **Focus:** Sent copy of the W17 weekly status report distributed to leadership on April 24.
  - **Key outcomes:**
    1. The email is the distribution copy of the W17 report already captured in 03-reporting/weekly/2026-W17.md.
    2. No new actionable content beyond the filed report; dashboard metrics, risks, and planned items match the existing record.
  - **Actions extracted → none (report-only artifact)**

- **2026-05-07 — Lapu-Lapu GOCC and Japan** #processed
  - **Source:** archive/20260507+-+Lapu-Lapu+GOCC+and+Japan.doc
  - **Focus:** Confirm operational scope, alert and incident workflow, and escalation-readiness for Japan application onboarding into GOCC.
  - **Key outcomes:**
    1. Japan monitoring coverage reached 68/88 application systems in production and 50/60 non-production environment groups, while GOCC L0/L1 go-live stood at 25/65 applications.
    2. The meeting reaffirmed that only onboarded applications are routed into GOCC alert handling and that non-onboarded applications will continue to have slower or missing detection paths.
    3. Rapid Recovery plans are expected to be accessible from ServiceNow-linked runbooks, with manual upload as a fallback until the integration path is finalized.
    4. Japan xMatters groups still need a cleaner roster baseline and a defined L1/L2/L3 escalation structure before broader onboarding can scale.
  - **Actions extracted → T083**
  - **Actions referenced → T042, T077, T079, T080, T081**
  - **Decision referenced → D005**

- **2026-04-21 — Epsilon Ingenium Modernization Executive Update** #processed
  - **Source:** archive/Epsilon_Ingenium-Modernization.pdf
  - **Focus:** Executive status update on the Ingenium modernization roadmap, including 3-tier architecture rollout, GitHub and CI/CD enablement, KT progress, and Q3 production-readiness asks.
  - **Key outcomes:**
    1. The modernization plan continues to center on the validated 3-tier architecture, GitHub source-control migration, Jenkins-driven CI/CD, Ingenium KT to GOCC, and BAU automation.
    2. Q2 work focuses on POT and DEV implementation, pipeline creation, Version Manager exit, KT progression, and documentation improvements.
    3. The next execution gate is production rollout readiness, which requires DEV and AQA support across end-to-end validation, configuration checks, rollback preparation, batch validation, and non-functional testing.
    4. The roadmap also positions the modernization for lower run cost, more predictable releases, and reduced dependency on the Ingenium infrastructure team as GOCC ownership expands.
  - **Actions extracted → T086, T087**
  - **Actions referenced → T008, T010, T046, T064, T065**

- **2026-03-17 — Rapid Recovery Planning Automation Process** #processed
  - **Source:** archive/Rapid Recovery Planning Automation Process.pdf
  - **Focus:** Automate Rapid Recovery Plan generation from CMDB and ServiceNow data so the gold-application RRP backlog can be scaled without manual copy-paste.
  - **Key outcomes:**
    1. Manual RRP creation for 134 gold applications is not sustainable because the current process depends on fragmented CMDB, spreadsheet, and email data.
    2. A proof of concept can already generate six-section RRP documents from CMDB data, but CMDB CI mismatches remain the primary blocker to trusted output.
    3. Integration maps, vendor contacts, and triage steps still need SME input or better source-of-truth coverage before automation can fully replace manual effort.
    4. The proposed next steps are to validate sample RRPs, resolve CMDB discrepancies, segment the application scope, and run a staged pilot before handoff and scale-out.
  - **Actions extracted → T084, T085**
  - **Actions referenced → T003, T041**

- **2026-04-24 — SRM Incident, Operational Gaps, and Rapid Recovery Onboarding** #processed
  - **Source:** archive/Meeting+Summary_+SRM+Certificate+Incident,+Operational+Gaps,+and+Rapid+Recovery+Onboarding.doc
  - **Focus:** Review the SRM incident, close the validation and recovery-readiness gaps, and use SRM as a focused Rapid Recovery onboarding case.
  - **Key outcomes:**
    1. The incident required an application restart during business hours in Japan, but the exact underlying cause remains unconfirmed.
    2. Current runbooks, validation steps, and explicit restart or recovery procedures need tightening so similar incidents can be recovered faster and with clearer authority.
    3. SRM and similar applications were asked to register for Rapid Recovery, with follow-up and knowledge-transfer sessions to close ownership and recovery-readiness gaps.
    4. CMDB and ServiceNow data quality, integration mapping, and contact quality remain blockers to auto-generated recovery plans and still require SME input.
  - **Actions extracted → T082**
  - **Actions referenced → T079**
  - **Decision extracted → D009**

- **2026-04-23 — RE: [Lapu-Lapu] Weekly Status Update** #processed
  - **Source:** archive/RE_ [Lapu-Lapu] Weekly Status Update.eml
  - **Focus:** Leadership follow-up on the April 17 weekly report, specifically asking for the standard PS-to-GOCC handover task types across the 65-application scope.
  - **Key outcomes:**
    1. Kelvin requested an explicit breakdown of the work PS will transition to GOCC for the 65 applications.
    2. David responded with the tracking-sheet categories used for handover: CMDB reconciliation, support-group and xMatters coverage, monitored URLs, infrastructure thresholds, business-operation timing, alert validation, and GOCC ORR sign-off.
    3. The thread confirms the transition-scaffolding work already captured for weekly reporting and onboarding standardization rather than creating a new standalone workstream.
  - **Actions referenced → T070, T081**

- **2026-04-23 — LapuLapu Team Direction and Execution** #processed
  - **Source:** archive/20260423+-+LapuLapu+Team+Direction+and+Execution.doc
  - **Focus:** Unblocking asks for non-prod workflow, rapid recovery onboarding, GOCC transition scaffolding, and operational side quests.
  - **Key outcomes:**
    1. Non-production monitoring needs an explicit alert-response workflow before environment lifecycle or rapid recovery steps are invoked.
    2. GOCC and Rohina need per-application reboot and restore procedures from the Server Team to widen Rapid Recovery registration.
    3. Transition scaffolding needs to be published as reusable templates, a support-level definitions pack, and a prioritized onboarding checklist.
    4. Fileshare and MFT ownership follow-ups remain outside the current objective-scoped workset, and the Gopher PRD POC remains unaligned pending clearer sponsorship.
  - **Actions extracted → T079, T080, T081**
  - **Actions referenced → T020, T044, T075, T076**
  - **Decision referenced → D006**
  - **Decision extracted → D008**

- **2026-04-23 — Lapu-Lapu GOCC and Japan** #processed
  - **Source:** archive/20260423+-+Lapu-Lapu+GOCC+and+Japan.doc
  - **Focus:** Dashboard onboarding, alerting flow, rapid recovery onboarding, and the operating model for the PS-to-GOCC transition.
  - **Key outcomes:**
    1. Production and non-production dashboards remain in flight and need explicit alerting and incident workflow confirmation.
    2. Non-standard monitoring applications will be escalated to the owning application team instead of being handled through new workaround patterns.
    3. Rapid Recovery onboarding needs reboot and restore procedure capture so more applications can be registered.
    4. Accepted April 16 transition decisions remain in force for checklist reporting, credential standards, workload-noise reduction, 500-error escalation, and bilingual rapid recovery enablement.
  - **Actions extracted → T077, T079**
  - **Actions referenced → T070, T071, T072, T073, T074**
  - **Decision extracted → D007**
  - **Decision referenced → D005**

- **2026-04-21 — LapuLapu ETS Japan, GOCC, and Obs Team** #processed
  - **Source:** archive/20260421+-+LapuLapu+ETS+Japan,+GOCC,+and+Obs+Team.doc
  - **Focus:** Transition checkpoint across dashboard coverage, rapid recovery enablement, and synthetic credential standards.
  - **Key outcomes:**
    1. PS-to-GOCC transition remained at 16/65 completed, with access-service-ID blockers called out for ePOS, WODM, and Solace.
    2. Dashboard coverage, OMM L2 entity mapping, and rapid recovery follow-up remained consistent with the April 16 workset.
    3. The Japan Business Capability dashboard needs clearer alert-count labeling before leadership review.
    4. Credential, workload-noise, and non-production error actions were already being executed under the accepted transition model.
  - **Actions extracted → T078**
  - **Actions referenced → T070, T071, T072, T073, T074**

- **2026-03-26 — Incident Review Meeting** #processed
  - Applications that do not have batch jobs running can be patched on Thursday night, instead of waiting for the weekend when other Releases and upgrades are prioritized.  This will relieve some pressure on the weekend schedule.
  - **Actions extracted → T020**

- **2026-03-26 — New Relic Monitoring (GOCC) Meeting** #processed
  - **Source:** GOCC-20260326 - New Relic Monitoring-260326-035913.pdf
  - **Attendees:** IS and ETS teams
  - **Focus:** Japan-based observability, dashboard delivery, and GOCC operating model
  - **Key outcomes:**
    1. Confirmed objective: Japan-based observability for Employee Experience and Developer Experience
    2. Two consolidated dashboards in scope (Employee Experience — production; Developer Experience — non-production)
    3. 16 applications transitioned from PS monitoring to GOCC; long-term goal to onboard all systems
    4. ePOS deep-dive: runs on AKS, monitored via New Relic APM, aligns to OMM Level 3
    5. PS team performs daily manual health checks via Manulink batch script (contacts: Nakatsu-san, Yamamoto-san, Murata-san)
    6. ePOS has ~17 non-prod environments; not currently in daily non-prod monitoring alert email from TEM — gap acknowledged
    7. GOCC monitoring requires service account with key-based authentication through Manulink
    8. Offloading opportunities: certificate renewals (already automated), SPN renewals (Managed Identity + federated creds), service account password management (vaulting)
    9. ePOS environment/DB management is ad hoc; opportunity for on-demand enablement and automated refresh
    10. GOCC delivery model agreed: URL availability → APM → Rapid Recovery; CMDB relationships must stay current
  - **Actions extracted → T012, T013, T014, T015, T016**
  - **Decision extracted → D002**

- **2026-03-17 — Patching Schedule and Possible Standard BAU Transition** #processed
  - **Source:** Minutes of the Meeting_ Patching Schedule and Possible Standard BAU Transition.eml
  - **From:** Karen L Escalona (Global Asia CM)
  - **Attendees:** Karen Escalona, Shunsuke Miura (JP CAB), Manoj Kondody (P2G Lead), Sreekanth Dogiparthy (Windows Lead), Birger Fjaellman (JP HOT), Naoki Tada (JP CAB), Kanagaraj Ramasamy (Linux Lead), Hideo Hasegawa (JP IT Operation and Risk)
  - **Focus:** Patching activity conflicts with Japan project releases; identification of changes for Standard BAU transition
  - **Key outcomes:**
    1. Weekday patching for Japan is challenging for ETS — manpower/resource splitting across windows and lack of end-to-end Ansible automation
    2. Birger's team working on allocating engineers so batch operations are not impacted during patching
    3. Recommendation to simplify and document patching process so GOCC can execute, reducing ETS dependency
    4. Kanagaraj to prepare documentation outlining patching challenges and end-to-end process
    5. Standard template for Japan Production Servers to be prepared; Kanagaraj and Sreekanth to share updated Linux/Windows prod server lists with Hideo-san for application name mapping
    6. Karen to schedule follow-up with HK and Indonesia representatives for non-production environments
  - **Actions extracted → T017, T018, T019**
  - **Decision extracted → D003**

- **2026-03-31 — GOCC-Monitoring Team Assignments (from Jonan)** #processed
  - **Source:** TeamUpdate.md
  - **From:** Jonan Tan Pangan (GOCC-Monitoring Lead)
  - **Focus:** Team member work stream assignments for LapuLapu
  - **Key outcomes:**
    1. Mary Kris, Rae, Yam — Dashboard
    2. Edward and team (12 members) — actual instrumentation
    3. Dennis/Mark — server build implementation of patching for Ingenium
    4. George/Angelo — gathering of rapid recovery items
  - **Actions extracted → T022**

- **2026-03-31 — Add 3 URLs to Employee Experience Dashboard** #processed
  - **Source:** Add3URLtodashboard.md (JIRA: LPLP-99)
  - **From:** David Klan → Mary Kris Cabunilas
  - **Focus:** 3 new application URLs to include in Employee Experience Dashboard monitoring
  - **Key outcomes:**
    1. Azure Databricks: https://adb-290394047047427.7.azuredatabricks.net/ (external service)
    2. Pathwise from Aon: https://manulife.pathwise.aon.com/logon/LogonPoint/index.html (internal)
    3. DORA app from AI team: https://dora.manulife.com/ (internal)
  - **Actions extracted → T021**

- **2026-03-31 — GOCC Monitoring Discussion** #processed
  - **Source:** GOCC-20260331 - Monitoring Discussion-310326-070126.pdf
  - **Note:** Detailed meeting agenda for 2026-03-31 monitoring session. Actions already captured in T023–T035 from the intake LLM processing pass. PDF confirms action owners, deliverables, and risk register items. No additional tasks beyond T023–T035 required.

- **2026-04-02 — Re: Epsilon – POT - Ingenium Modernization** #processed
  - **Source:** Re_ Epsilon– POT - Ingenium Modernization .eml
  - **From:** Balaji Ravi (Lead Infrastructure Architect – ETS Management Arch)
  - **To:** Prabu Thiagarajan, Ezhilarasan Mohan, David Klan
  - **Focus:** Epsilon POT prerequisite progress, low-level plan need, VCS setup, subscription access
  - **Key outcomes:**
    1. Prerequisite activities already started: subscription, resource group (CC9153), initial server provisioning
    2. Grey areas around prerequisite dependencies identified — need low-level implementation plan
    3. VCS setup: Kana agreed ETS BAU team will screen-share with VCS team; Kana to document VCS process
    4. Subscription access: Sanjeev needs contributor access to POT subscription
    5. Prabu to continue tracking SR requests in Ingenium Modernization activity tracker
    6. David Klan to facilitate and coordinate Epsilon POT execution after prerequisites firmed up
  - **Actions extracted → T036, T037, T038**

- **2026-03-30 — Japan Team - Global Incident Management w/ Rohina** #processed
  - **Source:** RE Japan Team - Global Incident Management w Rohina (Placeholder).txt
  - **From:** George Francis Fermo (Director, GOCC Application Operations & Delivery)
  - **Attendees:** Rohina Emerson, Keiichi Yamamoto, Makoto Murata, Christopher Bond, Hideo Hasegawa, David Klan, Birger Fjaellman, Jonan Tan Pangan, Angelo Tiu Mariano, Debamalya Das, Mary Kris Cabunilas
  - **Focus:** Japan incident management concerns, Rapid Recovery status, template standardisation
  - **Key outcomes:**
    1. Dedicated problem ticket for recurring Japan incident use cases to be created
    2. Standardized structured template from R2R Knowledge Management deck
    3. Documentation must be searchable by CIs, include Key Contacts and RR Contacts
    4. Japan incidents to explicitly identify Primary CI, Supporting CI components, and CIs for rapid recovery
    5. Employee Experience Dashboard to be completed within 2 weeks (Deb, with OAR team)
    6. ADS and xMatters groups to be added for enhanced alerting/escalation
    7. Standardized vendor escalation procedure format to be defined
  - **Actions extracted → T039, T040, T041, T042, T043**
  - **Decision extracted → D004**

- **2026-03-30 — Japan Team - Global Incident Management (MSG duplicate)** #processed
  - **Source:** RE_ Japan Team - Global Incident Management w_ Rohina (Placeholder).msg
  - **Note:** Outlook .msg binary format — same content as the .txt version. No additional actions required.

- **2026-04-13 — FW: [R2R] JP IACB OSCS Follow-Up Meeting with AWS** #processed
  - **Source:** archive/FW_ [R2R] JP IACB OSCS Follow-Up Meeting with AWS.eml
  - **From:** Vaibhav Singh (forwarding Glenn Ku / AWS follow-up thread)
  - **Focus:** Review AWS-updated IACB/OSCS assessment package (v0.2), capture concerns, and provide sign-off or priority feedback.
  - **Key outcomes:**
    1. AWS shared updated package (v0.2) after previous discussion.
    2. Team requested to review and respond with concerns, especially on priority items.
    3. Decision/feedback readiness required to avoid downstream execution delays.
  - **Actions extracted → T068**

- **2026-04-13 — FW: [R2R] JP SSW Follow-Up Meeting with AWS** #processed
  - **Source:** archive/FW_ [R2R] JP SSW Follow-Up Meeting with AWS.eml
  - **From:** Vaibhav Singh (forwarding Glenn Ku / AWS follow-up thread)
  - **Focus:** Time-bound feedback request on SSW reports to ensure updates are incorporated before AWS support window closes.
  - **Key outcomes:**
    1. Reminder sent to provide feedback on SSW reports.
    2. AWS support available only until month-end; feedback after cutoff may not be incorporated.
    3. Prompt review and response is required to lock report quality and next-step planning.
  - **Actions extracted → T069**

- **2026-04-16 — Lapu-Lapu GOCC and Japan** #processed
  - **Source:** archive/20260416+-+Lapu-Lapu+GOCC+and+Japan.doc
  - **Focus:** Dashboard progress, PS-to-GOCC transition tracking, impact-based alerting, and rapid recovery enablement.
  - **Key outcomes:**
    1. Employee Experience Dashboard reached 66/81 systems used by Japan users; Developer Experience Dashboard reached 45/60 non-prod environment groups.
    2. PS-to-GOCC transition stands at 16/65 completed with 9 applications in progress, with the Phase-1 checklist accepted as the handover source of truth.
    3. Branch laptop monitoring is live and non-prod HTTP 500 errors plus workload-health noise were called out as active issues.
    4. Parallel monitoring, impact-based alerting, and a bilingual rapid recovery alignment session were accepted as operating direction.
  - **Actions extracted → T070, T071, T072, T073, T074**
  - **Decision extracted → D005**

- **2026-04-16 — LapuLapu Team Direction and Execution** #processed
  - **Source:** archive/20260416+-+LapuLapu+Team+Direction+and+Execution.doc
  - **Focus:** Alert routing, non-prod monitoring blockers, operational side quests, and asset cleanup.
  - **Key outcomes:**
    1. Team needs a clear answer for New Relic-to-Moogsoft alert routing and support-team registration settings.
    2. Non-prod monitoring sequencing remains alert workflow first, then environment spin up or down and rapid recovery follow-up.
    3. Orphaned asset cleanup should be driven by category, starting with servers.
    4. File share, MFT ownership, and approval automation ideas remain outside the current objective-scoped workset.
  - **Actions extracted → T075, T076**
  - **Decision extracted → D006**

- **2026-04-16 — Rapid Recovery Information Hub** #processed
  - **Source:** archive/Rapid+Recovery+Information+Hub.doc
  - **Note:** Reference standard for Rapid Recovery Plans across Ingenium and other MLJ internal applications. Content aligns to existing work in T003, T040, T041, and the April 16 enablement follow-up captured in T074. No additional standalone task created.

- **2026-04-16 — Side Quests** #processed
  - **Source:** archive/Side+Quests.doc
  - **Focus:** Weekday patching details, approval-workflow optimization ideas, and reminder escalation patterns.
  - **Key outcomes:**
    1. Weekday patching detail aligns to the existing tracked work in T020.
    2. Approval reminder and escalation ideas were reviewed but deferred pending objective alignment and confirmed sponsoring ownership.
  - **Decision extracted → D006**
