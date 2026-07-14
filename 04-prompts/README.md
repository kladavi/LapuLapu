<!-- HUMAN -->
# 04-prompts — Agent Prompts

This folder stores prompts for **Copilot, VS Code Agent, ChatITSM**, and other
agents that operate against this repository. Prompts are treated as
**operational assets** — versioned, reviewed, and stable.

## Prompt file structure

Every prompt file **must** include:

1. **Purpose** — one-line statement of what the prompt does.
2. **Inputs** — repository paths / artifacts the agent should read.
3. **Outputs** — where results go, and in what shape.
4. **Version** — semver or date-based (e.g. `v1.2` or `2025-11-14`).

Example header:

```markdown
# Intake Prompt
Purpose: Extract structured work items from raw inbox capture.
Inputs:  01-inbox/inbox.md, 00-context/workstreams.yaml
Outputs: appended rows in 02-work/tasks.md; unaligned items in 02-work/decisions.md
Version: v1.1 (2025-11-14)
```

## Agent rules

- One prompt per file. Filename = purpose.
- Reference repository paths rather than pasting content — the agent reads
  the files.
- Bump the **Version** when semantics change.
- Prompts are **human-maintained**. Do not auto-generate them.

## Sprint prompt files

Multi-package sprint prompts (e.g. [0714Prompt_sprint1.md](0714Prompt_sprint1.md))
coordinate a full agent-driven sprint across the repo. They typically:

- Name the concrete files an agent must create or update.
- List human-maintained vs generated files.
- Define validation commands (usually PowerShell) the agent must run.
- End with a completion report checklist.

When adding a new sprint prompt, follow the same shape and reference the
control/generated files by exact path so the agent can act deterministically.
