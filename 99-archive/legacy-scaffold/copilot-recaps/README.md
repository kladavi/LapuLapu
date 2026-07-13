# Copilot / M365 Recaps

Drop imported markdown recap files here. One file per day or per session.

## Recommended front-matter
```yaml
---
date: 2025-11-14
source: copilot-m365   # or: teams, outlook, calendar
workstreams: [matryoshka, lapulapu-corpus]
---
```

The generator counts mentions per `workstream_id` (front-matter list **and**
inline `#matryoshka` style tags) as the activity signal.

Do not delete old recaps; recency decay handles their fading relevance.
