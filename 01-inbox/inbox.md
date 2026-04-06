# Inbox

Items below are raw and unprocessed. Run the intake prompt to extract, classify, and assign.

---

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
