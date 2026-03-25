Hi Birger,

As part of the Ingenium Modernization initiative, we are proposing to move forward with the Epsilon Upgrade – POT (Proof of Technology) to enhance the existing application architecture and overall system performance. 

Below is the detailed proposal, expected benefits, project plan, and required stakeholder involvement.

1. Proposal Overview

The current setup is built on a two‑tier architecture where the application and database components are tightly coupled. As part of the modernization efforts, we propose converting the existing setup into a three‑tier architecture with High Availability (HA).

The new architecture separates:
Presentation Layer
Application / Middleware Layer
Database Layer

This separation will help streamline operations, improve reliability, enhance scalability, and simplify maintenance.


2. Key Benefits of the New Architecture

1. Improved System Reliability
2. Licensing Cost Reduction
3. Online Patching Advantages
4. Enhanced Performance
5. Standardized Enterprise Architecture Alignment


3. Proposed Project Plan (High-Level)

INGENIUM Activity List (TASKS)
POT Subscription & Access
Server Provisionion
DB Install & Configuration
Middleware(WAS, CICS, CTG,COBOL, Batch, SFTP) Install & Configuration
ALB setup
VCS setup & DB native HA setup
Application Deploy and Verification
POT validation:
Application & Policy level testing - to check the workflow
Zone level Failover testing with different layer
Presentation layer
Middleware layer
Data layer layer
VCS & Pacemaker Verifications
Batch execution
Online Patching testing 
POT - Feedback analysis
Planning for Q3 and Q4
 
4. Stakeholder Involvement Required

ETS – Unix Team
ETS – DB Engineering / BAU Team
ETS - Ingenium Infrastructure Team( Modernization)
Application Team (already approved)

5. Support Required from Your End
Announce the Epsilon POT plan formally to the wider team.
Seek stakeholder commitment from ETS (Unix, DB) and other required groups.
@David Klan - Drive alignment on timelines, especially around VM provisioning and resource availability.

Thanks & Regards,

Balaji Ravi