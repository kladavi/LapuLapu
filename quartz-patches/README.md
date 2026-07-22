# Quartz local patches

Two patches were required to make Quartz v5.0.0 build successfully on a locked-down Manulife Windows workstation. Both are **local overlay patches** kept in this directory. They are **not** committed inside `quartz-site/` (which is gitignored), so re-cloning Quartz will lose them; you must reapply.

## Reapply after a clean clone

```powershell
cd quartz-site
git apply ..\quartz-patches\01-disable-og-image.patch
git apply ..\quartz-patches\02-junction-fallback-trysymlink.patch
npm install
npx quartz plugin install --from-config
npx quartz build -d ../quartz-content
```

## Patch inventory

### `01-disable-og-image.patch`

| Field | Value |
|---|---|
| File changed | `quartz.config.default.yaml` |
| Change | Set `github:quartz-community/og-image` `enabled: false` |
| Failure mode without patch | `Failed to emit from plugin CustomOgImages: fetch failed` → fatal `undici` assertion; build aborts. |
| Root cause | The plugin fetches TTF font files from a CDN at build time to composite Open-Graph card images. The Manulife corporate egress blocks the fetch. |
| Environment scope | Manulife corp network (any air-gapped or CDN-blocked network). Not Windows-specific. |
| Classification | **Local patch.** Not a candidate upstream contribution — the plugin behaves correctly on the open internet. |
| Long-term fix | If Quartz is deployed, either (a) permanently disable and use a static default OG image, or (b) fork the og-image plugin to load fonts from local disk. |

### `02-junction-fallback-trysymlink.patch`

| Field | Value |
|---|---|
| File changed | `quartz/plugins/loader/gitLoader.ts` |
| Change | Extended `trySymlink()` with an NTFS-junction fallback when the initial `fs.symlinkSync(..., "dir")` throws `EPERM` / `UNKNOWN`. |
| Failure mode without patch | Every plugin (44 in the default config) fails to install with `EPERM: operation not permitted, symlink '..\..\..\..\node_modules\preact' -> 'quartz-site\.quartz\plugins\<plugin>\node_modules\preact'`, followed by cascade failure. |
| Root cause | Windows requires `SeCreateSymbolicLinkPrivilege` to create directory symlinks. The privilege is granted only to Administrators or via Windows Developer Mode. Manulife-managed machines have neither. NTFS junctions serve the same purpose for same-volume directories and require **no elevation**. |
| Environment scope | Windows without Developer Mode / admin. On Linux, macOS, or Windows with Developer Mode, the fallback is never triggered so the patch is a no-op. |
| Classification | **Candidate upstream patch.** The behaviour is strictly additive (only used when the original call fails) and would improve out-of-the-box compatibility for the Windows-corporate audience. See "Upstream contribution" below. |
| Long-term fix | Open a PR against `jackyzha0/quartz` on GitHub. |

## Upstream contribution note

The junction fallback is a strict superset of current behaviour: on Linux/macOS `fs.symlinkSync(..., "dir")` succeeds and the `catch` block is never entered, so the fallback is a no-op. On Windows without elevation, it turns a hard failure into a working install. The change is ~15 lines and touches only one function. If a follow-up sprint chooses **A. Deploy**, a small PR against upstream is the recommended path so future Quartz upgrades keep working on the target environment.

## Non-tracked upstream drift

Running `npm install` + `npx quartz plugin install --from-config` also modifies `package-lock.json` and `quartz.lock.json` inside `quartz-site/`. These are **install artefacts**, not intentional patches, and are not captured here. They are recreated deterministically by a clean `npm install`.
