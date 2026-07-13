"""
Project Matryoshka V1.1B — Current Focus Dashboard generator.

Reads:
  00-context/workstreams.yaml
  00-context/priority-overrides.yaml
  00-context/scoring-model.yaml
  01-inbox/copilot-recaps/*.md
  01-inbox/inbox.md            (optional)
  03-reporting/weekly/*.md     (optional, for mention counts)

Writes:
  03-reporting/current-focus.md   (GENERATED, Git-tracked)
"""
from __future__ import annotations

import math
import re
import sys
from dataclasses import dataclass, field
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Iterable

try:
    import yaml
except ImportError:
    sys.exit("Missing dependency: pip install pyyaml")

ROOT = Path(__file__).resolve().parent.parent
CTX = ROOT / "00-context"
RECAPS = ROOT / "01-inbox" / "copilot-recaps"
INBOX = ROOT / "01-inbox" / "inbox.md"
WEEKLY = ROOT / "03-reporting" / "weekly"
OUT = ROOT / "03-reporting" / "current-focus.md"

FRONT_MATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)


def load_yaml(path: Path) -> dict:
    if not path.exists():
        return {}
    with path.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


@dataclass
class Workstream:
    id: str
    name: str
    owner: str = ""
    status: str = "active"
    priority: int = 3
    tags: list = field(default_factory=list)
    description: str = ""
    mentions: int = 0
    last_seen: date | None = None
    override_boost: float = 0.0
    override_reason: str = ""
    score: float = 0.0


def parse_front_matter(text: str) -> tuple[dict, str]:
    m = FRONT_MATTER_RE.match(text)
    if not m:
        return {}, text
    try:
        fm = yaml.safe_load(m.group(1)) or {}
    except yaml.YAMLError:
        fm = {}
    return fm, text[m.end():]


def scan_file(path: Path, ws_ids: set[str]) -> tuple[dict[str, int], date | None]:
    """Return per-workstream mention counts and the file's effective date."""
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return {}, None

    fm, body = parse_front_matter(text)
    counts: dict[str, int] = {}

    # Front-matter workstreams
    for wid in fm.get("workstreams", []) or []:
        if wid in ws_ids:
            counts[wid] = counts.get(wid, 0) + 1

    # Inline #tag mentions
    for wid in ws_ids:
        pattern = re.compile(rf"(?<![A-Za-z0-9_])#{re.escape(wid)}\b")
        n = len(pattern.findall(body))
        if n:
            counts[wid] = counts.get(wid, 0) + n

    # Effective date: front-matter date > file mtime
    eff: date | None = None
    fm_date = fm.get("date")
    if isinstance(fm_date, date):
        eff = fm_date
    elif isinstance(fm_date, str):
        try:
            eff = datetime.fromisoformat(fm_date).date()
        except ValueError:
            eff = None
    if eff is None:
        try:
            eff = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc).date()
        except OSError:
            eff = None

    return counts, eff


def iter_source_files() -> Iterable[Path]:
    if RECAPS.exists():
        yield from RECAPS.glob("*.md")
    if WEEKLY.exists():
        yield from WEEKLY.glob("*.md")
    if INBOX.exists():
        yield INBOX


def recency_score(last: date | None, half_life_days: float, today: date) -> float:
    if last is None or half_life_days <= 0:
        return 0.0
    age = max((today - last).days, 0)
    return math.pow(0.5, age / half_life_days)


def build() -> str:
    ws_cfg = load_yaml(CTX / "workstreams.yaml").get("workstreams", []) or []
    overrides = load_yaml(CTX / "priority-overrides.yaml").get("overrides", []) or []
    model = load_yaml(CTX / "scoring-model.yaml")

    weights = model.get("weights", {}) or {}
    w_rec = float(weights.get("recency", 1.0))
    w_pri = float(weights.get("priority", 1.0))
    w_sig = float(weights.get("signal", 1.0))
    half_life = float((model.get("decay") or {}).get("half_life_days", 7))
    saturation = float((model.get("signal") or {}).get("saturation_count", 5))
    top_n = int(model.get("top_n", 10))

    workstreams: dict[str, Workstream] = {}
    for w in ws_cfg:
        wid = w.get("id")
        if not wid:
            continue
        workstreams[wid] = Workstream(
            id=wid,
            name=w.get("name", wid),
            owner=w.get("owner", ""),
            status=w.get("status", "active"),
            priority=int(w.get("priority", 3)),
            tags=list(w.get("tags", []) or []),
            description=w.get("description", ""),
        )

    today = date.today()

    # Apply overrides (skip expired)
    for ov in overrides:
        wid = ov.get("workstream_id")
        if wid not in workstreams:
            continue
        exp = ov.get("expires")
        if isinstance(exp, str):
            try:
                exp = datetime.fromisoformat(exp).date()
            except ValueError:
                exp = None
        if isinstance(exp, date) and exp < today:
            continue
        workstreams[wid].override_boost += float(ov.get("boost", 0.0))
        if ov.get("reason"):
            workstreams[wid].override_reason = ov["reason"]

    # Scan source files
    ws_ids = set(workstreams.keys())
    for path in iter_source_files():
        counts, eff = scan_file(path, ws_ids)
        for wid, n in counts.items():
            w = workstreams[wid]
            w.mentions += n
            if eff and (w.last_seen is None or eff > w.last_seen):
                w.last_seen = eff

    # Score
    for w in workstreams.values():
        rec = recency_score(w.last_seen, half_life, today)
        pri = max(0.0, min(1.0, w.priority / 5.0))
        sig = min(1.0, w.mentions / saturation) if saturation > 0 else 0.0
        w.score = w_rec * rec + w_pri * pri + w_sig * sig + w.override_boost

    ranked = sorted(
        (w for w in workstreams.values() if w.status == "active"),
        key=lambda x: x.score,
        reverse=True,
    )[:top_n]

    # Render
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    lines = [
        "<!-- GENERATED: do not hand-edit. Source: scripts/generate_current_focus.py -->",
        "# Current Focus",
        "",
        f"_Generated: {now}_",
        "",
        "| Rank | Workstream | Score | Priority | Mentions | Last seen | Override |",
        "|-----:|------------|------:|---------:|---------:|-----------|----------|",
    ]
    for i, w in enumerate(ranked, 1):
        last = w.last_seen.isoformat() if w.last_seen else "—"
        ov = f"{w.override_boost:+.1f}" if w.override_boost else ""
        lines.append(
            f"| {i} | **{w.name}** (`{w.id}`) | {w.score:.2f} | {w.priority} | {w.mentions} | {last} | {ov} |"
        )

    lines += ["", "## Details", ""]
    for w in ranked:
        lines.append(f"### {w.name} (`{w.id}`)")
        if w.description:
            lines.append(w.description)
        meta = [f"owner: {w.owner or '—'}", f"tags: {', '.join(w.tags) or '—'}"]
        if w.override_reason:
            meta.append(f"override: {w.override_reason}")
        lines.append("_" + " · ".join(meta) + "_")
        lines.append("")

    lines += [
        "---",
        "",
        "## Inputs",
        f"- Workstreams: `{(CTX / 'workstreams.yaml').relative_to(ROOT)}`",
        f"- Overrides:   `{(CTX / 'priority-overrides.yaml').relative_to(ROOT)}`",
        f"- Model:       `{(CTX / 'scoring-model.yaml').relative_to(ROOT)}`",
        f"- Recaps:      `{RECAPS.relative_to(ROOT)}/*.md`",
        "",
    ]
    return "\n".join(lines) + "\n"


def main() -> int:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(build(), encoding="utf-8")
    print(f"Wrote {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
