Recommendation: Make Sprint 15 = Why-It-Matters
Do not start additional dashboard, inbox, or reporting work yet.
All downstream capabilities now depend on semantic quality.
Sprint 15: Semantic Impact Extraction
Deliverables
Add canonical fields:
TypeScriptwhy_it_matters: stringwhy_it_matters_confidence: numberwhy_it_matters_source: stringShow more lines
Extraction ladder
Priority order:
Tier 1: Explicit rationale
Look for:
Plain Textbecausedue toso thatin order torequired forneeded toto enableto avoidotherwiseShow more lines
Example:
Plain TextVendor upgrade delayed because security signoff is pending.Show more lines
↓
Plain TextSecurity signoff delay blocks vendor upgrade.Show more lines

Tier 2: Risk consequence
Example:
Plain TextFailure to complete onboarding may delay migration.Show more lines
↓
Plain TextMigration timeline may be delayed.Show more lines

Tier 3: Decision impact
Example:
Plain TextDecision required before August deployment planning.Show more lines
↓
Plain TextDeployment planning cannot proceed until the decision is made.Show more lines

Tier 4: Context fallback
Use context summary when no rationale exists.
Low confidence.

Validator v2
The spec already defines validation expectations around impact/dependency language. [mfc-my.sha...epoint.com]
Add:
Plain Textmissing_why_it_mattersweak_why_it_mattersgeneric_why_it_mattersduplicate_why_it_mattersShow more lines
Reject patterns like:
Plain TextNeeds attention.Important issue.Follow up required.Show more lines
Require impact language:
Plain TextblocksdelaysenablespreventsriskdependencydeadlineoutcomeimpactShow more lines
which aligns with the V4 validation direction. [mfc-my.sha...epoint.com]

Sprint 16: Canonical Emit
After Sprint 15 succeeds:
Make:
Plain Textmatryoshka-items.jsonShow more lines
the system of record.
Target architecture:
Plain TextSources  ↓Canonical Items  ↓Validator  ↓Priority Engine  ↓Weekly Report  ↓DashboardShow more lines
Everything should consume the same object model.
This reduces future drift substantially.

Sprint 17: Priority Explainability
Once why_it_matters exists, add:
TypeScriptpriorityReasonShow more lines
Example:
Plain TextPriority 94Reasons:• High-severity risk• Decision overdue 12 days• Blocks deployment planning• Active owner engagement detectedShow more lines
This is likely more valuable to users than another scoring tweak.

Sprint 18: Automated Executive Summary
Current weekly reports appear to be selection/ranking focused.
After Sprint 15, generate:
MarkdownExecutive SummaryTop RisksTop DecisionsNew IssuesWorkstreams Requiring AttentionShow more lines
directly from:
Plain TextpriorityScorewhy_it_mattersstatusdeltaShow more lines
The quality of this summary depends almost entirely on completing Sprint 15 first.
