<!-- HUMAN -->
# 03-reporting — Reporting Outputs

This folder contains **weekly reports, reporting templates, and report-ready
outputs** intended for executive consumption (email, slides, status reviews).

## Contents

| Path | Type | Purpose |
|---|---|---|
| `weekly/YYYY-WNN.md` | Mixed | Weekly summary reports. |
| `templates/` | Human | Report templates and boilerplate. |

## Relationship to Current Focus

The **Current Focus Dashboard** informs weekly reporting but is **not**
generated here. It lives at:

```
00-context/generated/current-focus.md
```

Weekly reports should reference or summarize the current focus, not duplicate
it.

## Agent rules

- Weekly report files use stable `YYYY-WNN.md` naming (ISO week).
- Generated report artifacts must carry a `<!-- GENERATED -->` marker naming
  their source script.
- Do not hand-edit generated files; rerun the script.
