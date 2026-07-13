import { promises as fs } from 'node:fs';
import path from 'node:path';

export type FocusCategory = 'P1' | 'P2' | 'Watch' | 'ParkingLot';

export interface FocusWorkstream {
  id: string;
  name: string;
  category: FocusCategory;
  score: number;
  raw_score: number;
  strategic_weight: number;
  override_applied: boolean;
  override_reason: string;
  mention_count: number;
  evidence_files: string[];
}

export interface CurrentFocus {
  generated: string;
  generator: string;
  version: string;
  workstreams: FocusWorkstream[];
}

/**
 * Resolve the path to 00-context/generated/current-focus.json.
 * Walks up from the UI root until it finds the repo root (contains 00-context).
 */
function resolveFocusPath(): string {
  const envOverride = process.env.LAPULAPU_FOCUS_JSON;
  if (envOverride) return envOverride;

  let dir = process.cwd();
  for (let i = 0; i < 6; i++) {
    const candidate = path.join(dir, '00-context', 'generated', 'current-focus.json');
    // Note: existsSync avoided for edge-runtime compatibility; caller handles ENOENT.
    if (path.basename(dir).length === 0) break;
    const parent = path.dirname(dir);
    // Try current dir first
    try {
      require('node:fs').accessSync(candidate);
      return candidate;
    } catch {
      /* not here, keep walking */
    }
    if (parent === dir) break;
    dir = parent;
  }
  // Fallback: assume UI runs from repo root
  return path.join(process.cwd(), '00-context', 'generated', 'current-focus.json');
}

export async function loadCurrentFocus(): Promise<CurrentFocus | null> {
  try {
    const p = resolveFocusPath();
    const raw = await fs.readFile(p, 'utf8');
    return JSON.parse(raw) as CurrentFocus;
  } catch {
    return null;
  }
}

export function groupByCategory(focus: CurrentFocus) {
  const groups: Record<FocusCategory, FocusWorkstream[]> = {
    P1: [], P2: [], Watch: [], ParkingLot: [],
  };
  for (const w of focus.workstreams) {
    (groups[w.category] ??= []).push(w);
  }
  for (const k of Object.keys(groups) as FocusCategory[]) {
    groups[k].sort((a, b) => b.score - a.score);
  }
  return groups;
}
