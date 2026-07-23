# 20260721 Lapu\-Lapu ETS, GOCC and Obs

# **Key Agenda Items**

## GBO

- Introducing Rajganesh Manohara (Raj) - Dedicated GBO transition
- **Batch jobs**: CAWLA
    - Add Joan and Rowena to weekly meeting to represent GBO
    - Check Japan jobs in CAWLA, Rowena send to Jonan
    - Number of batch jobs reduced from 600 last year to 200 this year
    - Rowena send David request for access to analyze the batch job incident reduction
- **GOAL**
    - 1st: Transition batch operations non-prod jobs to GBO
    - 2nd: transition batch operations prod jobs to GBO
    - Implement a turnkey process to provision file share folder, transfer, ACL, and ID.

## Observability

- **NR Minions: JPE/JPW still needs VNET update** - Dates TBC - ongoing
    - **RITM09472830**: subnet request completed successfully
    - Japan subnet provisioning start/completion ate Venice Angeles Parthiban Thirumoorthy
    - Kyle raised SR ()
    - DEV and PROD server provisioning status 
    - End-to-end Definition of Done for the Japan onboarding effort
- **MMM L2 Coverage**
    - Entity Mapping
        - Complete
        - Session with Japan - Scheduled for 
    - APM rollout to non-AKS starting with **Ingenium**
        - **Implementation complete** on
    - ADX  - Ingenium in-progress and other application teams have been informed
        - ING lower environment forwarding logs now and app teams are defining thresholds
- Rapid Recovery Information Hub
    - **App Teams submitted RRP - Review is stuck - App Teams disengaged**
        - **KB** not created for the other Gold applications and Ingenium does not contain link to **RRP**
        - How do App teams regularly review and update **RRP**?
        - Is Incident Management team responsible for testing and maintaining **RRP**?
        - Jonan will discuss with Rohina later today
            - MK has completed Ingenium Ansible playbook
            - Need to confirm other Ansible playbooks are completed
    - OS/System restart procedures
    - Application restart procedures/runbooks
    - Application health check procedures
        - Review [**WFI Health Check**](https://mfc.sharepoint.com/:x:/r/sites/ets-japan/Program%20Delivery/Lapu-Lapu/02_Technical_SOP/Health%20Check%20-%20PS/WFI_%E6%9C%9D%E7%A2%BA%E8%AA%8D_Ver1.7.xlsx?d=w66448550236f4b68b637510f4ab640b1&csf=1&web=1&e=5ugFKB)

## GOCC

- **Dashboards **- Currently in Beta-test with AQA users, tighten alerting parameters and reporting
    - **Export NRQL to PowerBI**
        - NerdGraph API - Python - Power BI
        - Draft within this week 
    - **Developer Experience Dashboard**
        - Biggest ask from AQA is to liaise with Mark Adriel to discuss regular Incident triage and come up with proactive policies and monitoring
        - Ingenium credentials still in talks with ING team
        - **FW complete: **finalize remaining servers (Ingenium+) setup
    - **Employee Experience Dashboard**
        - David got a positive response from IS and Business to continue working on and refining the dashboard, possibly export to PowerBI for more customer focus and remove need for NR ACL.
    - **Establish** **Process monitoring**
        - Patrick created a custom process monitoring solution for DB2
        - Deb has a custom process graph, Angelito will work with Rae on it
        - See if process health can be included in *Employee Experience Dashboard*
        - Compare NR process monitoring to APM coverage
    - **Laptop monitoring/Synthetic Job Monitor Agents/minions **- Confirm [new minion set up](https://manulife-ets.atlassian.net/wiki/x/foBe0AM) and dashboard
        - **JP Branch Offices**: 18x laptops in service
        - **Philippine Branch Offices**: Review updates to the dashboard and next steps (Singapore, other countries).  Working on 2nd laptop
        - **MPS Guardia**: Advanced monitoring techniques are in development for poorly designed servers behind load balancers. Check if an FAQ or KB exists to share NR technical details among team members. – Alex Osama is the contact working in EUS

## FireFighting

- Set up for 11am-noon HKT

## Side Quest

- Password expiry investigation in AD and CyberArk
- Pulse
    - Trigger a test of GOCC response to restart/reboot
- Gopher


**Definition of Sludge**

*Sludge refers to unnecessary friction, effort, delays, handoffs, approvals, duplicate data entry, or process complexity that makes it harder for people to achieve a legitimate objective. In operational environments, sludge consumes time and resources without providing corresponding value in terms of risk reduction, compliance, resilience, or customer outcomes. A key objective of continuous improvement is therefore to identify and remove sludge while preserving the controls, governance, and evidence needed for safe and effective operations. In simple terms, if a step adds effort but does not measurably improve quality, security, compliance, or resilience, it is a candidate for sludge reduction.* 

**Lapu‑Lapu:** *Standardization, automation, self-service, monitoring, and reusable evidence are all examples of sludge reduction because they reduce operational overhead while maintaining or improving governance and resilience.* 

---

# Generated by AI. Be sure to check for accuracy.

Meeting notes:

- **GBO Transition Planning: **David introduced Rajganesh as the new GBO support lead, outlining the plan to transition batch jobs starting with non-prod environments, and discussed the need for Rajganesh to update their user ID for Manulife access, with future meetings and communication plans to be scheduled.
    - **Introduction of Rajganesh: **David introduced Rajganesh, who has 15 years of IT experience, mainly in mainframe support and batch operations, and has been with Manulife for 11 years, previously supporting GPO and leading the Cognizant team.
    - **Transition Plan Overview: **The team discussed starting the transition for batch jobs in non-prod environments, with the possibility of moving to production later in the year, and Rajganesh's role in running this transition.
    - **User ID Migration: **David highlighted the immediate need for Rajganesh to transition their user ID from John Hancock to Manulife as the first major effort in the GBO transition.
    - **Future Meetings and Communication: **David mentioned that meetings, a communication plan, and a detailed work breakdown structure (WBS) are being developed as part of the ongoing transition process.
- **Observability Setup in Japan Data Centers: **David and Jonan discussed the progress and challenges in setting up New Relic minions for observability in Japan East and West data centers, including network configuration issues, involvement of Kyle Moyer, Dennis, and Melody Mersine, and the use of Terraform for server provisioning.
    - **Network Configuration Issues: **David explained that while JPE allows HTTPS communications, JPW does not, despite similar setups, and the team is awaiting responses from the network team and Melody Mersine to resolve these issues.
    - **Active-Active Setup Discussion: **Jonan inquired about the active-active setup, and David clarified that there are non-prod and prod environments in East and West, but the replication details for New Relic minions are unclear.
    - **Minion Installation Location: **Balaji asked about whether the minions should be installed on Azure IaaS or PaaS platforms, and David responded that while IP addresses and subnets are known, the specific VNet configuration is not yet clear.
    - **Team Roles and Progress: **David identified Kyle Moyer as the observability lead, Dennis on the network side, and Melody Mersine from Network Security, with Terraform setup completed but server provisioning halted due to network issues.
    - **Collaboration and Communication: **David offered to add Balaji to the observability chat group to facilitate collaboration and information sharing on the setup process.
- **MMM Level 2 Compliance and Rapid Recovery Plan: **Harish provided updates on MMM Level 2 compliance, including entity mapping completion and upcoming validation calls, while Jonan and Balaji discussed the status and quality of rapid recovery plans for gold applications, the use of Ansible playbooks, and the need for further iterations and testing.
    - **MMM Level 2 Compliance Progress: **Harish reported that entity mapping for MMM Level 2 compliance is complete, and the team is validating data from application owners, with a scheduled call on Thursday to clarify technical requirements.
    - **RRP Completion and Automation: **Harish confirmed that RRP is completed from their perspective, with data provided to the automation team to enhance user experience in ticket logging.
    - **Gold Application Data Validation: **Balaji raised concerns about application dependency data, specifically for Ingenium, and Harish clarified that the team will validate provided data and ensure agents are installed, with further details to be discussed in the upcoming call.
    - **RRP Plan Quality and Iteration: **Jonan noted that RRP plans are in draft form and require validation, multiple iterations, and testing before finalization, with ongoing collaboration between the PS team and Rohina's team.
    - **Ansible Playbook Usage: **Balaji and Jonan discussed the completed Ansible playbook for Ingenium service restart and stop, its potential reuse for other applications, and the need for standardization and best practice sharing across gold applications.
- **GOCC Dashboards and Power BI Integration: **Mary updated the team on the development of GOCC dashboards, focusing on production alerts and incidents, and described the process of exporting data from New Relic API to Python scripts and then to Power BI, with a draft targeted for review by David within the week.
    - **Dashboard Alert Coverage: **Mary is consolidating alerts for servers, middleware, and databases into the GOCC dashboard and comparing them to service incidents for visibility in Japan, currently focusing on production environments.
    - **Data Export Process: **The preferred method involves using the New Relic API to extract data, processing it with Python scripts, and then pushing it to Power BI, with refreshes scheduled at least every 12 hours.
    - **Draft Timeline and Feedback: **Mary aims to create a draft dashboard for David's review by the end of the week, after which additional features or data may be added based on feedback.
- **Process Monitoring and APM Integration: **David, Angelito, Mary, and Jonan discussed the goal of process monitoring as a troubleshooting tool within dashboards, the overlap with APM monitoring, and the need to identify critical processes, with consideration to focus on application-level monitoring for a holistic view.
    - **Process Monitoring Goals: **David described process monitoring as a drill-down feature for dashboards to aid troubleshooting by identifying which processes are down during incidents.
    - **APM Overlap and Focus: **Mary and Jonan noted that APM monitoring covers much of the required functionality, suggesting a shift in focus to application-level monitoring for comprehensive performance insights.
    - **Critical Process Identification: **David confirmed that the team has identified the top critical processes per server and is working on queries and baselines for reporting, with potential reliance on APM if overlap is significant.
- **Laptop Monitoring in Philippine Branch: **David and Jonan discussed the status of laptop monitoring in the Philippine branch, noting challenges in cooperation and confirming that only one branch is currently under their influence, with ongoing efforts to set up monitoring dashboards.
    - **Branch Coverage and Cooperation: **Jonan clarified that only one Philippine branch is being monitored, with difficulties in obtaining cooperation from local staff for dashboard setup.
    - **Monitoring Progress: **David confirmed that the monitoring setup is in progress, and Jonan will provide updates on follow-up actions.
- **MPS Guardia Print Server Monitoring: **David explained the monitoring and escalation procedures for the MPS Guardia print server in Japan, managed by ETS and Fujifilm, and identified Alex Osama as the contact for related issues.
    - **Vendor Management and Escalation: **David emphasized the importance of including Fujifilm in escalation procedures and templates for MPS Guardia, as it is a vendor-managed service.
    - **Contact Identification: **Mary asked for a contact person, and David confirmed Alex Osama as the team member responsible for MPS Guardia.
- **Firefighting Tabletop Rehearsal and Incident Analysis: **David, Jonan, Angelo, and Mark discussed plans for a tabletop rehearsal with the MIM team, scheduled for Wednesday, and reviewed incident analysis in non-prod environments with the AQA and environment management teams, aiming to improve GOCC responsiveness and support models.
    - **Tabletop Rehearsal Planning: **Jonan scheduled a tabletop rehearsal for Wednesday at 11 a.m. Hong Kong time, with Angelo arranging validation and scenario discussions, focusing on roleplay to identify gaps in procedures.
    - **Incident Analysis Collaboration: **David described ongoing collaboration with Mark, Rupesh, and Sangram from environment management to analyze incidents and develop action plans, including feedback to GOCC on improvements.
    - **Support Model Review: **Jonan and Mark are working to understand root causes of failures in lower environments, aiming to refine the support model and provide actionable suggestions based on incident analysis.
    - **Communication with AQA Team: **David stressed the importance of over-communicating responsiveness to the AQA team to build confidence and facilitate smoother transitions for GBO and GOCC production environments.
- **CyberArk Account Management and Risk Mitigation: **David, Balaji, and Jonan discussed CyberArk account management issues, including unmanaged and semi-managed accounts, role standardization, risk management scans, and legacy account conflicts, with Balaji detailing efforts to standardize access for Ingenium and plans to extend best practices to other applications.
    - **Unmanaged and Semi-Managed Accounts: **David highlighted the responsibility of teams to update passwords for non-managed and semi-managed CyberArk accounts, noting the prevalence of such accounts and the need for IS teams to address related incidents.
    - **Role Standardization and Cleanup: **Balaji described the inventory and cleanup process for Ingenium, aiming to restrict roles to user and approver groups, with audit and password changes handled by the CyberArk team, and plans to roll out these practices to other applications.
    - **Risk Management and SOX Compliance: **David noted that risk management conducts yearly SOX compliance scans but lacks meaningful action, advocating for more proactive scans and enforcement of account management standards.
    - **Promotion to Managed Accounts: **Balaji confirmed that all accounts should be fully managed through CyberArk, and the team is revisiting existing IDs to implement best practices across all applications.
    - **Legacy Account Conflict Resolution: **Jonan explained a recent incident involving WAS admin account conflicts due to LDAP integration, emphasizing the need for standard practices and improved processes to prevent similar issues, with risk management investigating setup instructions.

Follow-up tasks:

- **GBO Transition User ID: **Complete the transition of Rajganesh's user ID from John Hancock to Manulife to enable GBO support activities. (Rajganesh)
- **Observability Network Issue: **Follow up with Melody Mersine and the network team to resolve the JPW network configuration issue affecting New Relic minion setup. (David)
- **Observability Team Communication: **Add Balaji to the observability chat group for updates and collaboration on alert setup and network troubleshooting. (David)
- **MMM Level 2 Compliance Call: **Schedule and conduct a call on Thursday to clarify application-specific requirements for MMM Level 2 compliance and validate data provided by application owners. (Harish)
- **RRP Plan Quality and Follow-up: **Discuss with Rohina the feedback and follow-through on the quality and completeness of RRP plans for Japan and other markets, including potential reuse of Ansible playbooks. (Jonan)
- **GOCC Dashboard Draft: **Create and share a draft of the GOCC dashboard focused on production alerts and incidents for review and feedback. (Mary)
- **Process Monitoring Dashboard: **Coordinate with Rae to assist in process monitoring dashboard development and clarify which critical processes need to be monitored. (Angelito)
- **Tabletop Rehearsal Scheduling: **Send the meeting invite and confirm the schedule for the tabletop rehearsal planned for Wednesday at 11 a.m. Hong Kong time. (Jonan)
