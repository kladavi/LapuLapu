<!-- HUMAN -->
# ui — UI / Application Assets

This folder contains **UI and application assets** for any viewer, dashboard,
or app that renders the vault.

## Agent rules

- **Do not mix operational knowledge files** (context, tasks, reports,
  prompts) into `ui/`. Operational content belongs in `00-context/`,
  `02-work/`, `03-reporting/`, or `04-prompts/`.
- Files in `ui/` should be **specifically used by the UI** (components,
  styles, static assets, build config).
- Treat the markdown corpus as the **source of truth**; the UI is a
  read-oriented view over it.
- Any generated UI artifacts (bundles, static HTML) must be marked
  `<!-- GENERATED -->` and produced by a script in `scripts/`.
- If this folder is currently unused, leave it as a reserved slot.

This is a [Next.js](https://nextjs.org) project bootstrapped with [`create-next-app`](https://nextjs.org/docs/app/api-reference/cli/create-next-app).

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

## Startup behaviour

On every mount, the Dashboard (`src/app/page.tsx`) auto-loads the current
project from disk via the `/api/load-local` route. The default project root is
the LapuLapu vault:

- Route: [`ui/src/app/api/load-local/route.ts`](src/app/api/load-local/route.ts)
- Default: `C:\Users\kladavi\OneDrive - Manulife\Projects\LapuLapu`
- Override: set the `LAPU_ROOT` environment variable before `npm run dev` / `next start`.

While the auto-load is in flight the app shows a **"Loading LapuLapu…"**
spinner. The **"Select Folder"** landing screen only appears when the
auto-load explicitly fails (network error, missing directory, permission
issue). This means navigating from the Quartz portal (`/quartz/`) back to the
Dashboard — which is a full-page navigation and therefore resets React state —
takes you straight back to the current project instead of the folder picker.

Use the header's **📁 Change Folder** button (browsers that support the File
System Access API) if you need to point the Dashboard at a different vault
after startup.

## Dashboard data sources

The Dashboard tab (see `src/components/DashboardTab.tsx`) reads three generated
JSON artifacts from the vault via the `/api/load-local` route:

- `00-context/generated/current-focus.json` — populates the Current Focus
  cards with attention / activity / strategic / override / trend scores.
- `00-context/generated/current-focus-trends.json` — powers the Trends table.
- `00-context/generated/morning-briefing.json` — powers the Morning Briefing
  block (executive snapshot, primary focus, rising risks, decision watch,
  escalation candidates, recommended actions, source inputs).

All three sections fail gracefully with a friendly message if the corresponding
JSON file is missing. Regenerate the artifacts with:

```powershell
& "C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.3.0_x64__8wekyb3d8bbwe\pwsh.exe" -NoLogo -NoProfile -File ..\scripts\generate-current-focus.ps1
```

Then hit the **Reload** button in the header so the API re-reads the vault.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!

## Deploy on Vercel

The easiest way to deploy your Next.js app is to use the [Vercel Platform](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme) from the creators of Next.js.

Check out our [Next.js deployment documentation](https://nextjs.org/docs/app/building-your-application/deploying) for more details.
