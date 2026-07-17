# 20260714 Lapu\-Lapu ETS, GOCC and Obs

# **++Key Agenda Items++**

## GOCC

- **Dashboards **- Currently in Beta-test with AQA users, tighten alerting parameters and reporting
    - **Export NRQL to PowerBI**
        - NerdGraph API - Python - Power BI
    - **Developer Experience Dashboard**
        - Biggest ask from AQA is to liaise with Mark Adriel to discuss regular Incident triage and come up with proactive policies and monitoring
        - Ingenium credentials still in talks with ING team
        - **FW complete: **finalize remaining servers (Ingenium+) setup
    - **Employee Experience Dashboard**
        - David got a positive response from IS and Business to continue working on and refining the dashboard, possibly export to PowerBI for more customer focus and remove need for NR ACL.
    - **Establish** **Process monitoring**
        - Patrick created a custom process monitoring solution for DB2
        - Deb has a custom process graph
        - See if process health can be included in *Employee Experience Dashboard*
    - **Laptop monitoring/Synthetic Job Monitor Agents/minions **- Confirm [++new minion set up++](https://manulife-ets.atlassian.net/wiki/x/foBe0AM) and dashboard
        - **JP Branch Offices**: 18x laptops in service
        - **Philippine Branch Offices**: Review updates to the dashboard and next steps (Singapore, other countries) 
        - **MPS Guardia**: Advanced monitoring techniques are in development for poorly designed servers behind load balancers. Check if an FAQ or KB exists to share NR technical details among team members.

## Observability

- **JPE/JPW still needs VNET update** - Dates TBC - ongoing
    - **RITM09472830**: subnet request completed successfully
    - Japan subnet provisioning start/completion ate Venice Angeles Parthiban Thirumoorthy
    - Kyle raised SR ()
    - DEV and PROD server provisioning status 
    - End-to-end Definition of Done for the Japan onboarding effort
- **MMM L2 Coverage**
    - Entity Mapping
        - Session with Japan - Another Kickoff
    - APM rollout to non-AKS starting with **Ingenium**
        - **Implementation complete** on
    - ADX  - Ingenium in-progress and other application teams have been informed
        - ING lower environment forwarding logs now and app teams are defining thresholds
- Rapid Recovery Information Hub
    - **App Teams submitted RRP - Review is stuck - App Teams disengaged**
        - **KB** not created for the other Gold applications and Ingenium does not contain link to **RRP**
        - How do App teams regularly review and update **RRP**?
        - Is Incident Management team responsible for testing and maintaining **RRP**?
    - OS/System restart procedures
    - Application restart procedures/runbooks
    - Application health check procedures
        - Review [**WFI Health Check**](https://mfc.sharepoint.com/:x:/r/sites/ets-japan/Program%20Delivery/Lapu-Lapu/02_Technical_SOP/Health%20Check%20-%20PS/WFI_%E6%9C%9D%E7%A2%BA%E8%AA%8D_Ver1.7.xlsx?d=w66448550236f4b68b637510f4ab640b1&csf=1&web=1&e=5ugFKB)

## GBO

- **File Share**: ServerF **File Transfer**: MFT, WSFTP 
    - **GAM **handover folder creation to **GOCC**
        - GOCC CRUD folder (+Permission CTASK to GAM)
        - GAM grant permission
    - **ACL monitoring proposal:** Assess whether GOCC can monitor shared-folder ACL compliance against the standard `mfcgd\acl_{folder_name}_{tier}` model, including detection of missing required groups (`_C`, `_R`), incorrect rights, unexpected additional principals, and ACL read failures. Key design consideration: unmanaged folders will also generate findings, so scope control and false-positive handling would need to be defined.
    - Contact **JB Villegas + Jonathan** and send proposed report for Exception list

      Apply the same **permission and retention profiles** from **SharePoint**

      - <https://manulife-ets.atlassian.net/wiki/x/AQAk-AI> 
- **Batch jobs**: CAWLA
    - Add Joan and Rowena to weekly meeting to represent GBO
    - Check Japan jobs in CAWLA, Rowena send to Jonan
    - Number of batch jobs reduced from 600 last year to 200 this year
    - Rowena send David request for access to analyze the batch job incident reduction
- **GOAL**
    - Implement a turnkey process to provision file share folder, transfer, ACL, and ID.
    - Consult Kiran and Itagaki

##  Side Quest

- Password expiry investigation in AD and CyberArk
- Pulse
    - Trigger a test of GOCC response to restart/reboot
- Gopher


**Definition of Sludge**

*Sludge refers to unnecessary friction, effort, delays, handoffs, approvals, duplicate data entry, or process complexity that makes it harder for people to achieve a legitimate objective. In operational environments, sludge consumes time and resources without providing corresponding value in terms of risk reduction, compliance, resilience, or customer outcomes. A key objective of continuous improvement is therefore to identify and remove sludge while preserving the controls, governance, and evidence needed for safe and effective operations. In simple terms, if a step adds effort but does not measurably improve quality, security, compliance, or resilience, it is a candidate for sludge reduction.* 

**Lapu‑Lapu:** *Standardization, automation, self-service, monitoring, and reusable evidence are all examples of sludge reduction because they reduce operational overhead while maintaining or improving governance and resilience.* 

---

# **Meeting Notes – GOCC Transition, Monitoring, and Ops Review**

## **1. MPS Guardia (AWMS) – Naming & GOCC Readiness**

**Decision / Status**

- Application naming remains inconsistent:
    - Expected: **AWN / AWMS**
    - Current (LeanIX + CMDB): **MBPS**
- Despite naming misalignment, **CMDB mappings are confirmed → GOCC onboarding can proceed**

**Operational Model**

- Application is **vendor-managed (Fujifilm Services)**:
    - All restarts / ops actions handled by vendor
    - Vendor performs validation
    - Team to secure **contact + escalation path**

**Next Gate**

- GOCC transition can start **once URLs / endpoints are confirmed**

**Risk / Gap**

- ⚠️ Naming inconsistency across CMDB / LeanIX may cause:
    - Monitoring misalignment
    - RRP / AVP traceability issues
- ⚠️ Vendor dependency → slower MTTR unless escalation model is clearly defined

---

## **2. Developer Experience Dashboard & Middleware Monitoring**

**Progress**

- URL validation in progress (no major blockers)
- **New Relic alert policy (UAT)** pending creation + assignment to GOCC Middleware
- Credentials dependency:
    - Mark → coordinating with Sangram (functional monitoring)

**Ingenium Firewall**

- Mostly complete except:
    - 1 URL → **401 (invalid credentials)**
    - 1 URL → **server-side issue**

**Validation Status**

- \~60% complete
- **77 / 225 URLs remaining**
- Automation gap → manual firewall config required for some endpoints

**Action Focus**

- Complete URL validation + revalidation loop
- Deploy alert policy once validation stable

**Risk / Gap**

- ⚠️ Manual firewall configuration → non-scalable, error-prone
- ⚠️ Credential ownership unclear → blocking functional monitoring
- ⚠️ No clear definition of “monitoring ready” (availability vs functionality split)

---

## **3. Branch Laptop Dashboard (Philippines Focus)**

**Status**

- Draft dashboard exists (2 URLs currently)
- Donna + Vignesh expanding coverage

**Target**

- Full coverage of **Philippines-used applications (priority: Gold)**
- Completion targeted **by end of week**

**Risk / Gap**

- ⚠️ Low current coverage → dashboard not yet decision-useful
- ⚠️ Dependency on manual URL onboarding

---

## **4. Phase 2 – Non-Gold Application Onboarding**

**Current State**

- Rae actively engaging app owners
- Applications falling into categories:
    - Desktop
    - File transfer
    - ID components
    - Batch
    - Microservices APIs
    - Decommissioned / already onboarded

**Data Gaps**

- LeanIX gaps:
    - Document Video Library
    - Japan OK Wave
    - HULFT  
→ **No MetalRating assigned**

**Next Steps**

- Intake forms to be distributed for onboarding
- Monitoring approach needs alignment with Observability team

**Stakeholder Alignment**

- David → connect Rae with:
    - VA Desktop owner
    - Takuro Sekimoto (Doc Video Library / FAQ)

**Risk / Gap**

- ⚠️ No standardized monitoring model for non-URL systems (batch, desktop, infra components)
- ⚠️ Missing MetalRatings → blocks Lapu-Lapu prioritization logic
- ⚠️ LeanIX vs CMDB inconsistencies likely

---

## **5. Incident Review – Password Renewal / Account Management**

**Incident Summary**

- Password reset reused same value → rejected due to **AD metadata**
- Required escalation to GAM

**Key Issues Identified**

- Manual password handling to avoid downstream impact
- Lack of ownership clarity for service accounts
- Accounts not registered in **CyberArk (non-compliant)**

**Agreed Direction**

- Move toward:
    - **Full CyberArk registration**
    - **Automated password lifecycle management**
    - **Auditability of all actions**

**Next Steps**

- Identify all relevant accounts (Ingenium focus)
- Validate CyberArk coverage
- Evaluate MFCDD migration for service IDs

**Risk / Gap**

- 🚨 Compliance gap (CyberArk not enforced)
- 🚨 High operational risk (manual renewals + hidden dependencies)
- ⚠️ No unified ownership model for service accounts

---

## **6. Japan East/West VNet & Minions – Network Issues**

**Status**

- Ongoing provisioning issues
- Escalated to Network team

**Commitment**

- Adrian to include:
    - David
    - Vidya  
in escalation comms

**Risk / Gap**

- 🚨 Infrastructure instability impacting application readiness
- ⚠️ Lack of visibility into root cause + resolution timeline

---

## **7. MMM Level 2 – Entity Mapping & Reporting**

**Status**

- All Japan submissions received
- Validation ongoing (with direct follow-ups)

**Issue**

- Reporting clarity insufficient

**Ask**

- Define:
    - **Clear “Definition of Done”**
    - **Current completion status per item**

**Current Reporting**

- Weekly updates from Harish exist
- Accuracy / completeness not verified

**Risk / Gap**

- ⚠️ No single source of truth for MMM L2 status
- ⚠️ Potential disconnect between reported vs actual readiness
- ⚠️ Auditability concern

---

## **8. Pulse Workflow & Safe Approval**

**Status**

- Workflow operational:
    - Daily reports + failure notifications confirmed

**Gap**

- Safe access vs approval separation:
    - Access granted
    - Approval NOT aligned to 24/7 ops model

**Action**

- Engage Akane Mochida to:
    - Include GOCC in approval workflow
    - Enable **24/7 operational coverage**

**Risk / Gap**

- 🚨 Approval bottleneck → potential outage delays
- ⚠️ Process not aligned to GOCC operating model

---

# **Action Tracker (Consolidated)**

## **P1 – Critical**

- Investigate Ingenium firewall issues (401 + server)  
→ *Rae / Mary / Balaji*
- Confirm CyberArk compliance for all service IDs  
→ *Jonan*
- Compile full Ingenium account inventory  
→ *David / Infra*

## **P2 – Required for Onboarding**

- Send intake forms for non-Gold apps  
→ *Rae*
- Confirm monitoring approach (desktop, batch, infra)  
→ *Rae + Observability*
- Assign MetalRatings (3 missing apps)  
→ *Rae + App Owners*

## **P3 – Enablement / Dependencies**

- Connect Rae with VA Desktop + Takuro  
→ *David*
- Confirm Document Video Library URL  
→ *Rae*
- Align Pulse safe approval for 24/7 GOCC  
→ *Kinichi / Akane*

## **P4 – Strategic / Follow-up**

- Improve MMM L2 reporting clarity  
→ *David / Harish*
- Validate migration of engineering accounts to MFCDD  
→ *Birger*
- Continue escalation on VNet issues  
→ *Adrian*

---

# **Key Risks Snapshot (Exec View)**

- 🚨 CyberArk non-compliance → audit + security exposure
- 🚨 Network instability (VNet) → platform readiness risk
- ⚠️ Monitoring model incomplete for non-Gold / non-URL systems
- ⚠️ CMDB / LeanIX inconsistencies → traceability + onboarding risk
- ⚠️ Vendor-managed apps without clear escalation model
