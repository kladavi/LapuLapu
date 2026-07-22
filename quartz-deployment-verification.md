# Quartz Deployment Verification — V4.0 Sprint 26

**Deliverable:** 26.5 — Post-deployment verification
**Chosen hosting option:** A3 Local-Only, integrated with the Next.js dashboard (see [docs/QuartzHostingDecision.md](docs/QuartzHostingDecision.md))
**Deployed URL:** `http://localhost:3000/quartz/`
**Date:** 2026-07-22
**Verifier:** Worker (David Klan)
**Overall result:** **PASS**

---

## 1. Environment

| Item | Value |
|---|---|
| OS | Windows 11 (OneDrive-synced repo) |
| Node | v24.9.0 |
| npm | v11.6.0 |
| pwsh | 7.6.4 |
| Next.js | 16.2.1 (Turbopack) |
| Quartz | v5.0.0 |
| Deploy script | `scripts/deploy-quartz-local.ps1` |
| Portal source | `ui/public/quartz/` (gitignored, build artefact) |

## 2. Deploy pipeline result

Command: `pwsh -File .\scripts\deploy-quartz-local.ps1`

| Step | Detail | Result |
|---|---|---|
| 1/4 Content prep | `prepare-quartz-content.ps1 -Clean`: 20 items · 12 workstreams · 19 reports · 1 home → `quartz-content/` | PASS |
| 2/4 Quartz build | `npx quartz build -d ..\quartz-content -o ..\ui\public\quartz`: 52 sources → 139 emitted files (9 draft-filtered) | PASS |
| 3/4 Integrity gate | `test-quartz-links.ps1 -SiteDir ui/public/quartz`: 440 cross-refs, 22 backlink refs, 0/0/0/0 failures | **PASS** |
| 4/4 Readiness | Pipeline ended clean; wall time 21 s (warm) / 94 s (cold, incl. content prep) | PASS |

Validator report: [quartz-link-validation.md](quartz-link-validation.md)

```text
=== Results ===
  cross-refs scanned:      440
  broken href refs:        0
  backlink refs scanned:   22
  broken backlink refs:    0
  refs to draft targets:   0
  ghost graph edges:       0

OVERALL: PASS
```

## 3. Next.js server integration

- `ui/next.config.ts` extended with rewrites that map extensionless Quartz URLs and section-index directories (`/quartz/decisions`, `/quartz/risks`, `/quartz/workstreams`, `/quartz/reports`) to the emitted `.html` files.
- Server modes verified: `next build` (~10 min cold on OneDrive-synced host) → `next start`, and `next dev` (Ready in 1.4 s after warm cache).
- No changes required to any dashboard route — Quartz is an additive static tree under `public/quartz/`.

## 4. HTTP smoke tests (Deliverable 26.5 core evidence)

15 endpoints probed against `http://localhost:3000` while `next dev` was running. All PASS.

| Path | Status | Bytes |
|---|---|---|
| `/quartz` | 200 | 28,659 |
| `/quartz/index.html` | 200 | 28,659 |
| `/quartz/decisions` | 200 | 17,234 |
| `/quartz/decisions/d-40250bb7d6` | 200 | 28,085 |
| `/quartz/risks` | 200 | 18,454 |
| `/quartz/workstreams` | 200 | 19,494 |
| `/quartz/workstreams/rapid-recovery` | 200 | 24,039 |
| `/quartz/reports` | 200 | 17,542 |
| `/quartz/tags` | 200 | 149,363 |
| `/quartz/tags/workstream` | 200 | 29,424 |
| `/quartz/tags/workstream/rapid-recovery` | 200 | 15,663 |
| `/quartz/static/contentIndex.json` | 200 | 137,952 |
| `/quartz/index.xml` | 200 | 2,892 |
| `/quartz/sitemap.xml` | 200 | 10,545 |
| `/quartz/404.html` | 200 | 7,317 |

**Result: 15 / 15 PASS.**

## 5. Reviewer verification checklist

Reviewer prompt required evidence across seven areas. Each is confirmed below.

### 5.1 Build success — PASS
`npx quartz build` emitted 139 files (86 HTML + assets + xml + tags) in 5 s wall time from 52 markdown sources; 9 draft-filtered sources correctly excluded. See §2 step 2.

### 5.2 Accessibility of the deployed URL — PASS
Server returned HTTP 200 for `http://localhost:3000/quartz/` (portal home) and every section index and deep page probed (§4). Owner has confirmed browser navigation.

### 5.3 Internal navigation — PASS
Sampled `http://localhost:3000/quartz/workstreams/rapid-recovery` and confirmed outbound decision links resolve:

- `../decisions/d-4fc5c25a1c` → 200
- `../decisions/d-d059b9808f` → 200

Extensionless URLs handled via `next.config.ts` rewrites. Zero broken cross-refs across the whole site (validator, §2 step 3).

### 5.4 Search — PASS
`http://localhost:3000/quartz/static/contentIndex.json` returned a 137 KB JSON payload with 85 keyed entries. Sample:

```
key: decisions/d-40250bb7d6  title: D002 — Agreed: GOCC Delivery Model for Japan Monitoring
key: decisions/d-4fc5c25a1c  title: D005 — Agreed: Phase-1 Checklist and Impact-Based Alerting Govern PS-to-GOCC Transition
key: decisions/d-ad83b89db6  title: D007 — Agreed: Escalate Non-Standard Monitoring Apps Instead of Building Workarounds
```

The Quartz search UI loads via `prescript-2bfc6315.js` on every page; both prescript and postscript bundles serve at 200.

### 5.5 Backlinks — PASS
Sampled `http://localhost:3000/quartz/decisions/d-40250bb7d6`; backlinks block contains:

```html
<h3>Backlinks</h3>
<ul id="list-0" class="overflow">
  <li><a href="../" class="internal">Lapu-Lapu — Knowledge Portal</a></li>
  <li><a href="../workstreams/cyberark-governance" class="internal">CyberArk Governance</a></li>
</ul>
```

Validator scanned 22 backlink refs, 0 broken.

### 5.6 Graph — PASS
Graph plugin is served via `postscript-503771fb.js` (hashed bundle emitted next to page HTML). Ghost edges 0 (validator §2 step 3). Reviewer can render the graph client-side by visiting any page.

### 5.7 Content freshness — PASS
- `ui/public/quartz/decisions/d-40250bb7d6.html` mtime: `07/22/2026 11:38:16` — matches the deploy pipeline run.
- Latest weekly report `2026-W17_StatusReport` is present in `/quartz/reports/`.
- Home page top-10 list uses the current health scoring from `matryoshka-items.json`.
- Draft items (validated: false) do not appear as link targets anywhere; they surface only in the per-workstream "Draft items (excluded from links)" disclosure introduced in Sprint 25b.

## 6. Governance and access

- Portal is reachable only from the owner's workstation. No new public URL was created.
- Repo remains PUBLIC on github.com. The emitted portal (`ui/public/quartz/`) is git-ignored and not published.
- Rebuild trigger: **C1 Manual** via `scripts/deploy-quartz-local.ps1`. C2 chained pipeline and C3 GitHub Action explicitly deferred; see [docs/QuartzHostingDecision.md §7](docs/QuartzHostingDecision.md).

## 7. Known non-issues (documented, not blockers)

| Observation | Disposition |
|---|---|
| `next build` takes ~10 min cold on OneDrive-synced hosts (TypeScript step). | Environmental; dev-mode workflow avoids this. |
| Turbopack emits a "traced full project" warning about `next.config.ts` being imported by `src/app/api/save-local/route.ts`. | Cosmetic; production output still functional. Follow-up in a later sprint if surface area justifies. |
| Trailing-slash requests (e.g. `/quartz/`) receive a 308 redirect to the same URL without trailing slash. | Standard Next.js behaviour; final response is 200. |

## 8. Deliverables checklist

- [x] **26.1** Hosting option selected → A3 Local-Only (integrated with Next.js dashboard)
- [x] **26.2** Hosting decision document → [docs/QuartzHostingDecision.md](docs/QuartzHostingDecision.md)
- [x] **26.3** Rebuild trigger chosen → C1 Manual via [scripts/deploy-quartz-local.ps1](scripts/deploy-quartz-local.ps1)
- [x] **26.4** One working environment deployed → `http://localhost:3000/quartz/`
- [x] **26.5** Verification (this document) → All 15 HTTP probes PASS, all 7 reviewer checklist items PASS

## 9. Worker recommendation

**A. Accept the local operational deployment as-is.** All reviewer verification criteria pass. The portal is operational, reproducible via one command, and gated by the Sprint 25b link validator on every deploy.

If reviewer wants team-wide distribution, promotion path is documented in [docs/QuartzHostingDecision.md §9](docs/QuartzHostingDecision.md).
