import { loadCurrentFocus, groupByCategory, type FocusWorkstream } from '../lib/current-focus';

// This is a React Server Component (Next.js App Router).
// It re-reads the JSON on each request, so the dashboard always shows
// the latest committed summary. For static/edge use, wrap with revalidate.
export const dynamic = 'force-dynamic';

const CATEGORY_STYLES: Record<string, string> = {
  P1:         'bg-red-50 text-red-800 border-red-200',
  P2:         'bg-amber-50 text-amber-800 border-amber-200',
  Watch:      'bg-blue-50 text-blue-800 border-blue-200',
  ParkingLot: 'bg-slate-50 text-slate-600 border-slate-200',
};

function Pill({ category }: { category: string }) {
  const cls = CATEGORY_STYLES[category] ?? CATEGORY_STYLES.ParkingLot;
  return (
    <span className={`inline-block rounded-full border px-2 py-0.5 text-xs font-medium ${cls}`}>
      {category}
    </span>
  );
}

function WorkstreamRow({ w }: { w: FocusWorkstream }) {
  return (
    <li className="flex items-start justify-between gap-3 border-b border-slate-100 py-2 last:border-b-0">
      <div className="min-w-0">
        <div className="flex items-center gap-2">
          <span className="font-medium text-slate-900">{w.name}</span>
          {w.override_applied && (
            <span title={w.override_reason} className="text-xs text-slate-500">
              (override)
            </span>
          )}
        </div>
        {w.override_applied && w.override_reason && (
          <p className="mt-0.5 text-xs text-slate-500">{w.override_reason}</p>
        )}
      </div>
      <div className="flex shrink-0 items-center gap-2">
        <span className="tabular-nums text-sm text-slate-600">{w.score.toFixed(1)}</span>
        <Pill category={w.category} />
      </div>
    </li>
  );
}

export default async function FocusBlock() {
  const focus = await loadCurrentFocus();

  if (!focus) {
    return (
      <section className="rounded-lg border border-amber-200 bg-amber-50 p-4">
        <h2 className="font-semibold text-amber-900">Current Focus</h2>
        <p className="mt-1 text-sm text-amber-800">
          No <code>00-context/generated/current-focus.json</code> found.
          Run <code>scripts/generate-current-focus.ps1</code> to generate it.
        </p>
      </section>
    );
  }

  const groups = groupByCategory(focus);
  const p1 = groups.P1;
  const counts = {
    P1: groups.P1.length,
    P2: groups.P2.length,
    Watch: groups.Watch.length,
    ParkingLot: groups.ParkingLot.length,
  };

  return (
    <section className="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
      <header className="mb-3 flex items-baseline justify-between">
        <h2 className="text-lg font-semibold text-slate-900">Current Focus</h2>
        <span className="text-xs text-slate-500">
          Generated {focus.generated} · v{focus.version}
        </span>
      </header>

      <div className="mb-3 flex flex-wrap gap-2 text-xs">
        {(['P1', 'P2', 'Watch', 'ParkingLot'] as const).map((c) => (
          <span key={c} className="flex items-center gap-1">
            <Pill category={c} />
            <span className="tabular-nums text-slate-600">{counts[c]}</span>
          </span>
        ))}
      </div>

      {p1.length > 0 ? (
        <>
          <h3 className="mb-1 text-sm font-medium uppercase tracking-wide text-slate-500">
            P1 Focus
          </h3>
          <ul>
            {p1.map((w) => <WorkstreamRow key={w.id} w={w} />)}
          </ul>
        </>
      ) : (
        <p className="text-sm text-slate-500">No P1 workstreams.</p>
      )}

      <footer className="mt-3 border-t border-slate-100 pt-2 text-xs text-slate-500">
        Source: <code>00-context/generated/current-focus.json</code> — do not hand-edit.
      </footer>
    </section>
  );
}
