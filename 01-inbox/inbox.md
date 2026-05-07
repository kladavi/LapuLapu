# Inbox

Items below are raw and unprocessed. Run the intake prompt to extract, classify, and assign.

---

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
