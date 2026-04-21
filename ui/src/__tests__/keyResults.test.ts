import { describe, it, expect } from "vitest";
import {
  parseKeyResults,
  serializeKeyResult,
  serializeKeyResults,
  computeKRProgress,
  ensureProjectTag,
  nextKRId,
} from "../lib/parsers";
import type { KeyResult } from "../lib/types";

// ── Fixtures ──

const SAMPLE_KR_MD = `# Key Results

## KR001 — Reduce P1 MTTR to <2.5 hours
- **Objective:** H-3 (AI Ops / Incident Troubleshooting)
- **Metric Type:** Numeric
- **Start Value:** 4.2
- **Target Value:** 2.5
- **Current Value:** 3.1
- **Target Date:** 2026-06-30
- **Status:** On Track
- **Created:** 2026-04-01
- **Tags:** #project:lapu-lapu #domain:observability
- **Description:** Track and reduce mean time to resolve P1 incidents.

### Progress Log
| Date | Value | Comment |
|------|-------|---------|
| 2026-04-01 | 4.2 | Baseline from Q1 |
| 2026-04-15 | 3.8 | Improved correlation rules |
| 2026-04-30 | 3.1 | New runbooks deployed |

### Change Log
| Date | Change |
|------|--------|
| 2026-04-01 | Created |
| 2026-04-20 | Target Date extended from 2026-05-31 to 2026-06-30 |

---

## KR002 — Launch predictive monitoring
- **Objective:** H-3
- **Metric Type:** Boolean
- **Start Value:** 0
- **Target Value:** 1
- **Current Value:** 0
- **Target Date:** 2026-09-30
- **Status:** Not Started
- **Created:** 2026-04-01
- **Tags:** #project:lapu-lapu
- **Description:** Deploy predictive monitoring with dynamic thresholds.

### Progress Log
| Date | Value | Comment |
|------|-------|---------|

### Change Log
| Date | Change |
|------|--------|
| 2026-04-01 | Created |

---

## KR003 — Reduce P1/P2 incidents to ≤56 annually
- **Objective:** O1 (Frictionless Customer Experience)
- **Metric Type:** Numeric
- **Start Value:** 80
- **Target Value:** 56
- **Current Value:** 70
- **Target Date:** 2026-12-31
- **Status:** At Risk
- **Created:** 2026-04-01
- **Tags:** #project:lapu-lapu #domain:customer
- **Description:** Reduce total P1/P2 incidents to target level.

### Progress Log
| Date | Value | Comment |
|------|-------|---------|
| 2026-04-01 | 80 | Baseline |
| 2026-04-15 | 75 | Some improvement |
| 2026-05-01 | 70 | Steady progress |

### Change Log
| Date | Change |
|------|--------|
| 2026-04-01 | Created |
`;

function makeKR(overrides: Partial<KeyResult> = {}): KeyResult {
  return {
    id: "KR001",
    title: "Test KR",
    objectiveId: "H-3",
    metricType: "numeric",
    startValue: 0,
    targetValue: 100,
    currentValue: 50,
    targetDate: "2026-06-30",
    status: "On Track",
    created: "2026-04-01",
    tags: ["#project:lapu-lapu"],
    description: "A test key result",
    progressLog: [],
    changeLog: [{ date: "2026-04-01", change: "Created" }],
    raw: "",
    ...overrides,
  };
}

// ══════════════════════════════════════════════
// parseKeyResults
// ══════════════════════════════════════════════

describe("parseKeyResults", () => {
  it("parses multiple KRs from markdown", () => {
    const krs = parseKeyResults(SAMPLE_KR_MD);
    expect(krs).toHaveLength(3);
  });

  it("extracts KR ID and title", () => {
    const krs = parseKeyResults(SAMPLE_KR_MD);
    expect(krs[0].id).toBe("KR001");
    expect(krs[0].title).toBe("Reduce P1 MTTR to <2.5 hours");
    expect(krs[1].id).toBe("KR002");
    expect(krs[2].id).toBe("KR003");
  });

  it("extracts objective ID from parenthesized field", () => {
    const krs = parseKeyResults(SAMPLE_KR_MD);
    expect(krs[0].objectiveId).toBe("H-3");
    expect(krs[2].objectiveId).toBe("O1");
  });

  it("extracts objective ID from plain field", () => {
    const krs = parseKeyResults(SAMPLE_KR_MD);
    expect(krs[1].objectiveId).toBe("H-3");
  });

  it("parses metric type correctly", () => {
    const krs = parseKeyResults(SAMPLE_KR_MD);
    expect(krs[0].metricType).toBe("numeric");
    expect(krs[1].metricType).toBe("boolean");
    expect(krs[2].metricType).toBe("numeric");
  });

  it("parses numeric values", () => {
    const krs = parseKeyResults(SAMPLE_KR_MD);
    expect(krs[0].startValue).toBe(4.2);
    expect(krs[0].targetValue).toBe(2.5);
    expect(krs[0].currentValue).toBe(3.1);
  });

  it("parses boolean KR values", () => {
    const krs = parseKeyResults(SAMPLE_KR_MD);
    expect(krs[1].startValue).toBe(0);
    expect(krs[1].targetValue).toBe(1);
    expect(krs[1].currentValue).toBe(0);
  });

  it("parses status", () => {
    const krs = parseKeyResults(SAMPLE_KR_MD);
    expect(krs[0].status).toBe("On Track");
    expect(krs[1].status).toBe("Not Started");
    expect(krs[2].status).toBe("At Risk");
  });

  it("parses tags", () => {
    const krs = parseKeyResults(SAMPLE_KR_MD);
    expect(krs[0].tags).toContain("#project:lapu-lapu");
    expect(krs[0].tags).toContain("#domain:observability");
  });

  it("parses progress log", () => {
    const krs = parseKeyResults(SAMPLE_KR_MD);
    expect(krs[0].progressLog).toHaveLength(3);
    expect(krs[0].progressLog[0]).toEqual({
      date: "2026-04-01",
      value: 4.2,
      comment: "Baseline from Q1",
    });
    expect(krs[0].progressLog[2]).toEqual({
      date: "2026-04-30",
      value: 3.1,
      comment: "New runbooks deployed",
    });
  });

  it("parses empty progress log", () => {
    const krs = parseKeyResults(SAMPLE_KR_MD);
    expect(krs[1].progressLog).toHaveLength(0);
  });

  it("parses change log", () => {
    const krs = parseKeyResults(SAMPLE_KR_MD);
    expect(krs[0].changeLog).toHaveLength(2);
    expect(krs[0].changeLog[0]).toEqual({
      date: "2026-04-01",
      change: "Created",
    });
  });

  it("parses created date and target date", () => {
    const krs = parseKeyResults(SAMPLE_KR_MD);
    expect(krs[0].created).toBe("2026-04-01");
    expect(krs[0].targetDate).toBe("2026-06-30");
  });

  it("parses description", () => {
    const krs = parseKeyResults(SAMPLE_KR_MD);
    expect(krs[0].description).toBe(
      "Track and reduce mean time to resolve P1 incidents."
    );
  });

  it("returns empty array for empty markdown", () => {
    expect(parseKeyResults("")).toEqual([]);
    expect(parseKeyResults("# Key Results\n")).toEqual([]);
  });

  it("defaults invalid status to Not Started", () => {
    const md = `## KR001 — Test
- **Objective:** O1
- **Metric Type:** Numeric
- **Start Value:** 0
- **Target Value:** 100
- **Current Value:** 0
- **Target Date:** 2026-12-31
- **Status:** InvalidStatus
- **Created:** 2026-04-01
- **Tags:** 
- **Description:** Test

### Progress Log
| Date | Value | Comment |
|------|-------|---------|

### Change Log
| Date | Change |
|------|--------|
`;
    const krs = parseKeyResults(md);
    expect(krs[0].status).toBe("Not Started");
  });

  it("handles Windows line endings (CRLF)", () => {
    const crlf = SAMPLE_KR_MD.replace(/\n/g, "\r\n");
    const krs = parseKeyResults(crlf);
    expect(krs).toHaveLength(3);
    expect(krs[0].id).toBe("KR001");
  });
});

// ══════════════════════════════════════════════
// serializeKeyResult / serializeKeyResults
// ══════════════════════════════════════════════

describe("serializeKeyResult", () => {
  it("produces valid markdown for a KR", () => {
    const kr = makeKR({
      progressLog: [
        { date: "2026-04-01", value: 0, comment: "Baseline" },
        { date: "2026-04-15", value: 50, comment: "Midpoint" },
      ],
    });
    const md = serializeKeyResult(kr);
    expect(md).toContain("## KR001 — Test KR");
    expect(md).toContain("- **Objective:** H-3");
    expect(md).toContain("- **Metric Type:** Numeric");
    expect(md).toContain("- **Start Value:** 0");
    expect(md).toContain("- **Target Value:** 100");
    expect(md).toContain("| 2026-04-01 | 0 | Baseline |");
    expect(md).toContain("| 2026-04-15 | 50 | Midpoint |");
  });

  it("serializes boolean metric type correctly", () => {
    const kr = makeKR({ metricType: "boolean", startValue: 0, targetValue: 1 });
    const md = serializeKeyResult(kr);
    expect(md).toContain("- **Metric Type:** Boolean");
  });

  it("includes change log entries", () => {
    const kr = makeKR({
      changeLog: [
        { date: "2026-04-01", change: "Created" },
        { date: "2026-04-10", change: "Target changed" },
      ],
    });
    const md = serializeKeyResult(kr);
    expect(md).toContain("| 2026-04-01 | Created |");
    expect(md).toContain("| 2026-04-10 | Target changed |");
  });
});

describe("serializeKeyResults", () => {
  it("produces header with separator between KRs", () => {
    const krs = [makeKR({ id: "KR001" }), makeKR({ id: "KR002" })];
    const md = serializeKeyResults(krs);
    expect(md).toContain("# Key Results");
    expect(md).toContain("## KR001");
    expect(md).toContain("---");
    expect(md).toContain("## KR002");
  });

  it("produces just a header for empty array", () => {
    const md = serializeKeyResults([]);
    expect(md).toBe("# Key Results\n");
  });
});

describe("roundtrip: parse → serialize → parse", () => {
  it("preserves all key fields through serialization roundtrip", () => {
    const original = parseKeyResults(SAMPLE_KR_MD);
    const serialized = serializeKeyResults(original);
    const reparsed = parseKeyResults(serialized);

    expect(reparsed).toHaveLength(original.length);
    for (let i = 0; i < original.length; i++) {
      expect(reparsed[i].id).toBe(original[i].id);
      expect(reparsed[i].title).toBe(original[i].title);
      expect(reparsed[i].objectiveId).toBe(original[i].objectiveId);
      expect(reparsed[i].metricType).toBe(original[i].metricType);
      expect(reparsed[i].startValue).toBe(original[i].startValue);
      expect(reparsed[i].targetValue).toBe(original[i].targetValue);
      expect(reparsed[i].currentValue).toBe(original[i].currentValue);
      expect(reparsed[i].status).toBe(original[i].status);
      expect(reparsed[i].tags).toEqual(original[i].tags);
      expect(reparsed[i].progressLog).toEqual(original[i].progressLog);
      expect(reparsed[i].changeLog).toEqual(original[i].changeLog);
    }
  });
});

// ══════════════════════════════════════════════
// computeKRProgress
// ══════════════════════════════════════════════

describe("computeKRProgress", () => {
  it("computes progress for numeric KR", () => {
    const kr = makeKR({ startValue: 0, targetValue: 100, currentValue: 50 });
    expect(computeKRProgress(kr)).toBe(50);
  });

  it("computes 100% when target reached", () => {
    const kr = makeKR({ startValue: 0, targetValue: 100, currentValue: 100 });
    expect(computeKRProgress(kr)).toBe(100);
  });

  it("computes 0% when at start", () => {
    const kr = makeKR({ startValue: 0, targetValue: 100, currentValue: 0 });
    expect(computeKRProgress(kr)).toBe(0);
  });

  it("clamps to 100% when exceeding target", () => {
    const kr = makeKR({ startValue: 0, targetValue: 100, currentValue: 120 });
    expect(computeKRProgress(kr)).toBe(100);
  });

  it("clamps to 0% when below start", () => {
    const kr = makeKR({ startValue: 10, targetValue: 100, currentValue: 5 });
    expect(computeKRProgress(kr)).toBe(0);
  });

  it("handles decreasing metric (e.g., MTTR reduction)", () => {
    // Start: 4.2, Target: 2.5, Current: 3.1
    // Range = 2.5 - 4.2 = -1.7
    // Progress = (3.1 - 4.2) / (2.5 - 4.2) * 100 = (-1.1 / -1.7) * 100 ≈ 65%
    const kr = makeKR({ startValue: 4.2, targetValue: 2.5, currentValue: 3.1 });
    expect(computeKRProgress(kr)).toBe(65);
  });

  it("returns 0% for boolean KR with current 0", () => {
    const kr = makeKR({ metricType: "boolean", startValue: 0, targetValue: 1, currentValue: 0 });
    expect(computeKRProgress(kr)).toBe(0);
  });

  it("returns 100% for boolean KR with current 1", () => {
    const kr = makeKR({ metricType: "boolean", startValue: 0, targetValue: 1, currentValue: 1 });
    expect(computeKRProgress(kr)).toBe(100);
  });

  it("handles zero range gracefully", () => {
    const kr = makeKR({ startValue: 50, targetValue: 50, currentValue: 50 });
    expect(computeKRProgress(kr)).toBe(100);
  });

  it("handles zero range with current below target", () => {
    const kr = makeKR({ startValue: 50, targetValue: 50, currentValue: 40 });
    expect(computeKRProgress(kr)).toBe(0);
  });
});

describe("ensureProjectTag", () => {
  it("adds the default project tag when none exists", () => {
    expect(ensureProjectTag(["#domain:cloud"], "lapu-lapu")).toEqual([
      "#project:lapu-lapu",
      "#domain:cloud",
    ]);
  });

  it("preserves an existing project tag", () => {
    expect(ensureProjectTag(["#project:epsilon", "#domain:cloud"], "lapu-lapu")).toEqual([
      "#project:epsilon",
      "#domain:cloud",
    ]);
  });

  it("deduplicates and ignores blank tags", () => {
    expect(ensureProjectTag(["", "#domain:cloud", "#domain:cloud"], "lapu-lapu")).toEqual([
      "#project:lapu-lapu",
      "#domain:cloud",
    ]);
  });
});

// ══════════════════════════════════════════════
// nextKRId
// ══════════════════════════════════════════════

describe("nextKRId", () => {
  it("returns KR001 for empty array", () => {
    expect(nextKRId([])).toBe("KR001");
  });

  it("returns next ID after highest", () => {
    const krs = [makeKR({ id: "KR001" }), makeKR({ id: "KR003" })];
    expect(nextKRId(krs)).toBe("KR004");
  });

  it("pads to 3 digits", () => {
    const krs = [makeKR({ id: "KR009" })];
    expect(nextKRId(krs)).toBe("KR010");
  });

  it("handles large IDs", () => {
    const krs = [makeKR({ id: "KR099" })];
    expect(nextKRId(krs)).toBe("KR100");
  });
});
