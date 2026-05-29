# Inbox

Items below are raw and unprocessed. Run the intake prompt to extract, classify, and assign.

---

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
