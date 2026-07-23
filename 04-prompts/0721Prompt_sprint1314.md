Recommended Next Sprint Plan
Sprint 12c (next)
Theme
Meaning Extraction
Deliverables
Phase W1: why_it_matters extractor
Add:
TypeScriptwhyItMatters?: stringwhyItMattersConfidence?: numberShow more lines
Extraction hierarchy:


Explicit rationale

because
due to
in order to
to enable
so that



Decision impact sentence


Risk consequence sentence


ContextSummary-derived fallback


Validator should separately score:
TypeScriptmissing_why_it_mattersweak_why_it_mattersShow more lines
Success criteria
Target:
Plain Text>= 50% validator acceptanceShow more lines
or whatever real threshold matches the validator's rubric.

Sprint 12d
Theme
Canonical Emit
Deliverables
Make:
Plain Textmatryoshka-items.jsonShow more lines
the primary output contract.
Everything else becomes a projection.
Current situation appears to be:
Plain TextSource → enrichment → dashboardShow more lines
Target:
Plain TextSource  ↓Canonical Item Graph  ↓JSON  ↓Validator  ↓Dashboard  ↓ReportsShow more lines
This creates a single truth model.

Sprint 13a
Theme
Focus Model Foundation
Before full Priority Inbox logic:
Introduce:
TypeScriptengagedattentionRequiredawaitingOthersShow more lines
as canonical state dimensions.
Avoid jumping straight to inbox ranking.
First establish the signals.
Then rank from those signals.

Sprint 13b
Theme
Priority Inbox
Implement scoring:
Plain TextImpact+ Ownership+ Deadline proximity+ Red/Amber status+ EngagementShow more lines
Output:
TypeScriptpriorityScorepriorityReasonShow more lines
This becomes the basis for inbox ordering.

Sprint 14
Theme
Recap Automation (8b/8c)
I would deliberately schedule this after the semantic model work.
Reason:
A poor model automated faster is still a poor model.
A stronger canonical model feeding recap generation will produce dramatically better weekly reports.

What I would NOT do next
I would not start Phase 8b/8c immediately.
The platform still has a semantic gap:
Plain TextStatus     ✅Ownership  ✅Actions    ✅Confidence ✅Aging      ✅Why it Matters ❌Show more lines
Until that gap is closed, report automation will generate larger quantities of less useful output.

Recommended sequence
Plain TextSprint 12c  why_it_matters extractorSprint 12d  canonical emitSprint 13a  focus model primitivesSprint 13b  priority inbox rankingSprint 14  recap fetch + weekly report automationShow more lines
If the worker can only take one task next, I would assign why_it_matters extractor immediately. It appears to be the highest leverage remaining capability in the V4 architecture.