<!-- HUMAN -->
# ui/components

## FocusBlock

Server component that renders the latest **Current Focus** summary from
`00-context/generated/current-focus.json`.

### Usage (Next.js App Router)

```tsx
// app/page.tsx or app/dashboard/page.tsx
import FocusBlock from '../components/FocusBlock';

export default function Dashboard() {
  return (
    <main className="mx-auto max-w-3xl p-6 space-y-6">
      <FocusBlock />
      {/* other dashboard blocks */}
    </main>
  );
}
```

### Behaviour

- Reads `00-context/generated/current-focus.json` on every request
  (`export const dynamic = 'force-dynamic'`).
- Walks up from `process.cwd()` to locate the repo root, or honours
  `LAPULAPU_FOCUS_JSON` env var if set.
- Renders category counts, all P1 workstreams with scores and override reasons,
  and a footer noting the file is generated.

### Regenerating the source

```powershell
.\scripts\generate-current-focus.ps1
```

Commit the regenerated JSON — the UI will pick it up on the next request.
