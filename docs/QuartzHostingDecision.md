# Quartz Hosting Decision

**Sprint:** V4.0 Sprint 26 — Hosting Selection & Deployment
**Author:** Worker (David Klan)
**Date:** 2026-07-22
**Status:** Decided
**Related:** [04-prompts/20260722_Sprint25b_Review.md](../04-prompts/20260722_Sprint25b_Review.md), [quartz-pilot-review.md](../quartz-pilot-review.md), [quartz-deployment-verification.md](../quartz-deployment-verification.md)

## 1. Context

Sprint 25 installed Quartz v5.0.0 as a static-site generator over the canonical Matryoshka model. Sprint 25a produced pilot task-matrix evidence and recommended a draft-aware navigation fix. Sprint 25b implemented that fix plus an integrity validator (`scripts/test-quartz-links.ps1`), landing at 7 PASS · 2 PARTIAL · 0 FAIL with 0 broken references across 440 cross-refs.

Reviewer prompt `20260722_Sprint25b_Review.md` accepted the worker recommendation **A. Deploy** and instructed:

> Proceed to Sprint 26 – Hosting Selection & Deployment. Move from Pilot to Operational Knowledge Portal.

The five deliverables required by the reviewer:

- **26.1** Select hosting option (A1 GitHub Pages · A2 SharePoint · A3 Local-Only · A4 Internal nginx/IIS)
- **26.2** This document — chosen option, rationale, governance, access, rebuild model
- **26.3** Rebuild trigger (C1 Manual · C2 Chained Pipeline · C3 GitHub Action)
- **26.4** Deploy one working environment
- **26.5** Post-deployment verification → `quartz-deployment-verification.md`

## 2. Constraints

| Constraint | Value | Source of truth |
|---|---|---|
| Repo visibility | **PUBLIC** on github.com (`kladavi/LapuLapu`) | `gh repo view kladavi/LapuLapu --json visibility` |
| Content sensitivity | Manulife Japan project data — decisions, risks, workstream state | `quartz-content/**` |
| Existing infrastructure | Next.js dashboard at `ui/` (React 19, Next 16.2, Turbopack) | [ui/package.json](../ui/package.json) |
| Local platform | Windows 11, OneDrive-synced repo, pwsh 7.6, Node 24.9, npm 11.6 | Verified in this sprint |
| Team distribution scope (today) | Single owner (David) — no team-wide URL requested by reviewer | Reviewer prompt |
| Deployment freedom (Manulife) | No approved external SharePoint site; no internal nginx/IIS provisioned; no vetted GitHub Pages custom domain | Environment survey |

## 3. Options considered

| # | Option | Fit | Blocker |
|---|---|---|---|
| A1 | GitHub Pages (Actions publish) | Low | Repo is PUBLIC — cannot publish Manulife Japan project artefacts to a public web URL without a data-classification review. Out of scope for a one-sprint deployment. |
| A2 | SharePoint (embed static site) | Low | No pre-approved site collection; SharePoint's static hosting has poor support for extensionless URL rewrites Quartz relies on. |
| A3 | Local-Only (static server) | **High** | None. Reviewer explicitly listed it. |
| A4 | Internal nginx / IIS | Medium | Requires ITSM ticket + server allocation; out of one-sprint scope. Candidate for a later promotion sprint. |
| A5 (new) | **Local-Only, mounted under the existing Next.js dashboard** | **Highest** | None. User-selected in Sprint 26 kickoff. |

## 4. Decision

**Chosen: A3 Local-Only, integrated with the Next.js dashboard.** (User-directed at Sprint 26 kickoff: *"Can this be incorporated onto dev server at localhost:3000 ?"*)

Concretely:

- Quartz builds into `ui/public/quartz/` (139 emitted files, ~5 s on this host after warm cache).
- The Next.js server (dev mode via `npm run dev`, prod mode via `npm run start`) serves the emitted directory as static assets under `http://localhost:3000/quartz/`.
- URL rewrites in [ui/next.config.ts](../ui/next.config.ts) map extensionless Quartz URLs (e.g. `/quartz/decisions/d-40250bb7d6`) and section-index paths (e.g. `/quartz/risks`) to the correct `.html` files.
- One entry point ([scripts/deploy-quartz-local.ps1](../scripts/deploy-quartz-local.ps1)) chains the whole pipeline: `prepare-quartz-content.ps1` → `quartz build` → `test-quartz-links.ps1` → readiness message.

### Why this over the four listed options

1. **Compliance**: The repo is PUBLIC, but no new public URL is created. The portal is only reachable from the owner's workstation. This matches the current data-classification posture without any additional review.
2. **Zero new infrastructure**: reuses the Next.js server the dashboard already runs on. No SharePoint site, no internal web server, no Actions workflow with publish rights.
3. **Unified surface**: the dashboard (`http://localhost:3000/`) and the knowledge portal (`http://localhost:3000/quartz/`) live at the same origin. Future dashboard pages can link into Quartz pages with plain relative links.
4. **Reversible**: the whole portal is a static artefact in `ui/public/quartz/` (gitignored). Deleting the directory removes the portal entirely; there is no server-side state to unwind.
5. **Promotable**: the same static output can later be uploaded to A4 (internal web server) or A2 (SharePoint) without regeneration, once a hosting review is complete.

## 5. Governance

| Question | Answer |
|---|---|
| Who owns the portal? | David Klan (Worker), until reviewer promotes to team-wide distribution. |
| Where does content come from? | Canonical `matryoshka-items.json` + generated markdown under `quartz-content/`. Draft-aware filtering enforced by [scripts/prepare-quartz-content.ps1](../scripts/prepare-quartz-content.ps1) (see Sprint 25b). |
| Integrity gate | [scripts/test-quartz-links.ps1](../scripts/test-quartz-links.ps1) — must return exit 0 (0 broken refs, 0 backlink refs, 0 draft-target refs, 0 ghost graph edges) before any deployment is considered complete. Enforced by `deploy-quartz-local.ps1`. |
| Change control | Any change to `quartz-content/` follows the standard Matryoshka canonical-model change process (edit → rebuild → validator → commit). |
| Access review | None required today — local-only. If the portal is ever promoted to a shared host, a data-classification review is required first. |
| Retention | The `ui/public/quartz/` directory is a build artefact and is regenerated on every deploy. Historical portal states are reconstructable from git history of `quartz-content/`. |

## 6. Access model

| Actor | Access path |
|---|---|
| Worker (David) | `http://localhost:3000/quartz/` after `npm run dev` (or `npm run build && npm start`) in `ui/`. |
| Reviewer | Read commits, docs, and evidence via GitHub. No portal URL. |
| Anyone else | No access. If required later, promote to A4/A2. |

## 7. Rebuild model (Deliverable 26.3)

**Chosen: C1 Manual** — a single-command wrapper.

Command: `pwsh -File .\scripts\deploy-quartz-local.ps1`

The wrapper performs:

1. `pwsh scripts/prepare-quartz-content.ps1 -Clean` — regenerate markdown under `quartz-content/` from the canonical model (with draft filtering).
2. `cd quartz-site && npx quartz build -d ../quartz-content -o ../ui/public/quartz` — emit the static site into the Next.js `public/` folder.
3. `cd .. && pwsh scripts/test-quartz-links.ps1` — validate every href/backlink and confirm zero draft-target refs. Non-zero exit aborts.
4. Print readiness message with the URLs to test.

**C2 Chained Pipeline** and **C3 GitHub Action** are explicitly **deferred**:

- **C2** requires committing to a specific CI runner and shared cache. Not warranted while the deploy target is a single local workstation.
- **C3** requires a repository secret and publish target — meaningless while the repo is PUBLIC and the portal is local-only.

Both C2 and C3 are candidates for a future sprint when the hosting decision escalates to A4 or beyond.

## 8. Deployment (Deliverable 26.4)

One working environment has been deployed and verified in this sprint. See [quartz-deployment-verification.md](../quartz-deployment-verification.md) for evidence:

- Build success (52 sources → 139 emitted files, 5 s)
- Link validator PASS (0/0/0/0 across 440 refs)
- HTTP 200 on all 15 probed endpoints via `http://localhost:3000/quartz/*`
- Next.js dev server ready in <2 s after warm cache

## 9. Promotion path (future sprints)

If the reviewer later requires team-wide access, the following upgrades are pre-planned:

1. **A4 Internal web server**: copy `ui/public/quartz/` behind an internal Manulife URL. No content change needed. Rewrite rules from `next.config.ts` must be re-implemented in the target server (nginx `try_files`, IIS URL Rewrite).
2. **A2 SharePoint**: requires disabling extensionless URLs — regenerate Quartz with a config that emits all internal links with `.html` extensions, then upload the tree. Larger effort.
3. **C2/C3 automation**: only meaningful after A4/A2 is selected.

## 10. Risks / open items

| Risk | Mitigation |
|---|---|
| OneDrive sync locks slow the Next.js build (10 min cold, seconds warm). | Accept for now; move `ui/` outside OneDrive in a later sprint if it blocks day-to-day usage. |
| `next.config.ts` rewrites diverge from Quartz emission if Quartz upgrades. | The validator [scripts/test-quartz-links.ps1](../scripts/test-quartz-links.ps1) surfaces the emitted structure; rewrites are 5 lines — easy to keep aligned. |
| Portal is not accessible when the dev server is stopped. | Expected. Reviewer selected local-only. |
| Repo remains PUBLIC. | Portal creates no new public URL. Content itself is the only exposure surface and predates Sprint 26. |

## 11. Reviewer decision requested

Approve the deployment recorded here, or specify one of:

- **B. Promote to A4** — worker will open a Sprint 27 hosting-provision task.
- **C. Automate** — worker will scope a C2 chained pipeline or C3 GitHub Action, contingent on choice of target host.
- **D. Defer** — no further hosting work; keep Sprint 26 as the operational deployment.
