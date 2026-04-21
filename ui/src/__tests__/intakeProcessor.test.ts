// ── Tests for intakeProcessor.ts ──

import { describe, it, expect } from "vitest";
import {
  buildIntakePrompt,
  parseIntakeResponse,
  parseInboxEntries,
  validateApprovedIntakeResults,
  type IntakeResult,
} from "../lib/intakeProcessor";
import type { PMData } from "../lib/types";
import { DEFAULT_SETTINGS } from "../lib/settings";

// ── Helpers ──

function makePMData(overrides: Partial<PMData> = {}): PMData {
  return {
    projects: [],
    objectives: [],
    teams: [],
    systems: [],
    tasks: [
      { id: "T001", title: "Task One", status: "Open", created: "2026-03-20", objectiveChain: "", objectiveIds: [], team: "", assigned: "", systems: [], tags: [], description: "", raw: "" },
      { id: "T019", title: "Task Nineteen", status: "Open", created: "2026-03-26", objectiveChain: "", objectiveIds: [], team: "", assigned: "", systems: [], tags: [], description: "", raw: "" },
    ],
    decisions: [
      { id: "D001", title: "Dec One", date: "2026-03-18", requestor: "", request: "", decision: "", reason: "", tags: [], raw: "" },
      { id: "D003", title: "Dec Three", date: "2026-03-26", requestor: "", request: "", decision: "", reason: "", tags: [], raw: "" },
    ],
    keyResults: [],
    weeklySummaries: [],
    inbox: "",
    rawFiles: {
      "00-context/objectives.md": "# Objectives\n\n## Tier-1\n\n### O1 — Customer Experience\n",
      "00-context/teams.md": "# Teams\n\n## Obs Team\n- **Lead:** J. Santos\n",
      "00-context/systems.md": "# Systems\n\n| Name | Tag |\n|---|---|\n| New Relic | newrelic |\n",
      "02-work/tasks.md": "# Tasks\n\n## T001 — Task One\n",
      "02-work/decisions.md": "# Decisions Log\n\n## D001 — Dec One\n",
    },
    loadedAt: "2026-03-27T10:00:00Z",
    folderName: "LapuLapu",
    warnings: [],
    settings: DEFAULT_SETTINGS,
    relationships: { tier1ToTier2: {}, tier2ToTasks: {}, taskToTier2: {}, violations: [] },
    ...overrides,
  };
}

// ══════════════════════════════════════════════
// buildIntakePrompt
// ══════════════════════════════════════════════

describe("buildIntakePrompt", () => {
  it("includes the raw input text", () => {
    const data = makePMData();
    const prompt = buildIntakePrompt("Fix the server crash issue", data);
    expect(prompt).toContain("Fix the server crash issue");
  });

  it("includes the role section", () => {
    const data = makePMData();
    const prompt = buildIntakePrompt("Some input", data);
    expect(prompt).toContain("work-intake analyst");
  });

  it("includes objectives context", () => {
    const data = makePMData();
    const prompt = buildIntakePrompt("Some input", data);
    expect(prompt).toContain("Customer Experience");
  });

  it("includes teams context", () => {
    const data = makePMData();
    const prompt = buildIntakePrompt("Some input", data);
    expect(prompt).toContain("J. Santos");
  });

  it("includes systems context", () => {
    const data = makePMData();
    const prompt = buildIntakePrompt("Some input", data);
    expect(prompt).toContain("New Relic");
  });

  it("computes next task ID correctly", () => {
    const data = makePMData();
    const prompt = buildIntakePrompt("Some input", data);
    expect(prompt).toContain("T020");
  });

  it("computes next decision ID correctly", () => {
    const data = makePMData();
    const prompt = buildIntakePrompt("Some input", data);
    expect(prompt).toContain("D004");
  });

  it("includes output format template", () => {
    const data = makePMData();
    const prompt = buildIntakePrompt("Some input", data);
    expect(prompt).toContain("## T[NNN]");
    expect(prompt).toContain("## D[NNN]");
  });

  it("includes rules about not inventing objectives", () => {
    const data = makePMData();
    const prompt = buildIntakePrompt("Some input", data);
    expect(prompt).toContain("Never invent objectives");
  });

  it("handles empty tasks and decisions arrays", () => {
    const data = makePMData({ tasks: [], decisions: [] });
    const prompt = buildIntakePrompt("Some input", data);
    expect(prompt).toContain("T001");
    expect(prompt).toContain("D001");
  });
});

// ══════════════════════════════════════════════
// parseIntakeResponse
// ══════════════════════════════════════════════

describe("parseIntakeResponse", () => {
  const sampleResponse = `## T020 — Deploy Monitoring Agent
- **Status:** Open
- **Created:** 2026-03-27
- **Objective Chain:** H-3 (AI Ops) → O1 (Customer Experience)
- **Team:** #team:obs
- **Assigned:** J. Santos
- **Systems:** #system:newrelic
- **Relevance:** 88/100
- **Tags:** #project:lapu-lapu
- **Description:** Deploy New Relic monitoring agent to all production servers.

---

## T021 — Update CMDB Records
- **Status:** Open
- **Created:** 2026-03-27
- **Objective Chain:** B-6 (IT Asset Management) → O4 (Technical Core)
- **Team:** #team:infra
- **Assigned:** A. Delgado
- **Systems:** #system:cmdb
- **Relevance:** 75/100
- **Tags:** #project:lapu-lapu
- **Description:** Update CMDB records for newly provisioned VMs.

---

## D004 — Deferred: Marketing Dashboard Request
- **Date:** 2026-03-27
- **Requestor:** Marketing Team
- **Request:** Custom dashboard for landing page metrics
- **Decision:** Deferred
- **Reason:** Does not map to any Tier-3 objective.
- **Tags:** #rejected #unaligned`;

  it("parses tasks from LLM response", () => {
    const results = parseIntakeResponse(sampleResponse);
    const tasks = results.filter((r) => r.type === "task");
    expect(tasks).toHaveLength(2);
    expect(tasks[0].id).toBe("T020");
    expect(tasks[1].id).toBe("T021");
  });

  it("parses decisions from LLM response", () => {
    const results = parseIntakeResponse(sampleResponse);
    const decisions = results.filter((r) => r.type === "decision");
    expect(decisions).toHaveLength(1);
    expect(decisions[0].id).toBe("D004");
  });

  it("extracts titles correctly", () => {
    const results = parseIntakeResponse(sampleResponse);
    expect(results[0].title).toBe("Deploy Monitoring Agent");
    expect(results[2].title).toContain("Marketing Dashboard Request");
  });

  it("marks all items as approved by default", () => {
    const results = parseIntakeResponse(sampleResponse);
    expect(results.every((r) => r.approved)).toBe(true);
  });

  it("preserves full raw block for each item", () => {
    const results = parseIntakeResponse(sampleResponse);
    expect(results[0].raw).toContain("Deploy New Relic monitoring agent");
    expect(results[1].raw).toContain("Update CMDB records");
    expect(results[2].raw).toContain("Does not map to any Tier-3 objective");
  });

  it("returns empty array for empty input", () => {
    expect(parseIntakeResponse("")).toHaveLength(0);
  });

  it("returns empty array for input with no valid blocks", () => {
    expect(parseIntakeResponse("Just some random text")).toHaveLength(0);
  });

  it("handles response with only tasks", () => {
    const onlyTasks = `## T020 — Task A
- **Status:** Open
- **Description:** Something.`;
    const results = parseIntakeResponse(onlyTasks);
    expect(results).toHaveLength(1);
    expect(results[0].type).toBe("task");
  });

  it("handles response with only decisions", () => {
    const onlyDecisions = `## D004 — Deferred: Item X
- **Date:** 2026-03-27
- **Decision:** Deferred`;
    const results = parseIntakeResponse(onlyDecisions);
    expect(results).toHaveLength(1);
    expect(results[0].type).toBe("decision");
  });

  it("handles Windows-style line endings", () => {
    const winResponse = "## T020 — Task A\r\n- **Status:** Open\r\n- **Description:** Test.\r\n";
    const results = parseIntakeResponse(winResponse);
    expect(results).toHaveLength(1);
  });
});

// ══════════════════════════════════════════════
// parseInboxEntries
// ══════════════════════════════════════════════

describe("parseInboxEntries", () => {
  const sampleInbox = `# Inbox

Items below are raw and unprocessed.

---

- **2026-03-26 — Incident Review Meeting** #raw
  - Applications that do not have batch jobs can be patched Thursday night.

- **2026-03-26 — New Relic Monitoring (GOCC) Meeting** #processed
  - **Source:** GOCC-20260326.pdf
  - **Attendees:** IS and ETS teams
  - **Actions extracted → T012, T013**`;

  it("parses raw entries", () => {
    const entries = parseInboxEntries(sampleInbox);
    const raw = entries.filter((e) => e.status === "raw");
    expect(raw).toHaveLength(1);
    expect(raw[0].label).toContain("Incident Review Meeting");
  });

  it("parses processed entries", () => {
    const entries = parseInboxEntries(sampleInbox);
    const processed = entries.filter((e) => e.status === "processed");
    expect(processed).toHaveLength(1);
    expect(processed[0].label).toContain("New Relic Monitoring");
  });

  it("includes entry text content", () => {
    const entries = parseInboxEntries(sampleInbox);
    const raw = entries.filter((e) => e.status === "raw");
    expect(raw[0].text).toContain("batch jobs");
  });

  it("returns empty array for empty input", () => {
    expect(parseInboxEntries("")).toHaveLength(0);
    expect(parseInboxEntries("   ")).toHaveLength(0);
  });

  it("returns empty array for inbox with no entries", () => {
    expect(parseInboxEntries("# Inbox\n\nNo items.")).toHaveLength(0);
  });

  it("handles single entry inbox", () => {
    const single = `- **2026-03-26 — Test Item** #raw\n  - Some content here.`;
    const entries = parseInboxEntries(single);
    expect(entries).toHaveLength(1);
    expect(entries[0].status).toBe("raw");
  });
});

describe("validateApprovedIntakeResults", () => {
  it("blocks in fail mode when approved tasks skip Tier-2", () => {
    const data = makePMData({
      settings: {
        ...DEFAULT_SETTINGS,
        lint: {
          ...DEFAULT_SETTINGS.lint,
          enabled: true,
          mode: "fail",
          requireProjectTag: false,
          requireNamespacedTags: false,
        },
      },
      objectives: [
        {
          id: "O1", title: "Customer Experience", tier: 1,
          tags: [], source: [], parentObjectiveIds: [], description: "", commitments: [], raw: "",
        },
        {
          id: "H-3", title: "AI Ops", tier: 2,
          tags: [], source: [], parentObjectiveIds: ["O1"], description: "", commitments: [], raw: "",
        },
      ],
    });

    const results: IntakeResult[] = [
      {
        id: "T020",
        type: "task",
        title: "Tier-1 only task",
        approved: true,
        raw: `## T020 — Tier-1 only task
- **Status:** Open
- **Created:** 2026-04-09
- **Objective Chain:** O1 (Customer Experience)
- **Team:** #team:gocc
- **Assigned:** Test
- **Systems:** #system:newrelic
- **Relevance:** 80/100
- **Tags:** #project:lapu-lapu
- **Description:** Test task`,
      },
    ];

    const preflight = validateApprovedIntakeResults(results, data);
    expect(preflight.approvedTaskCount).toBe(1);
    expect(preflight.lintResult.blocked).toBe(true);
    expect(
      preflight.lintResult.violations.some((v) => v.rule === "relationship-task-skips-tier2")
    ).toBe(true);
  });
});
