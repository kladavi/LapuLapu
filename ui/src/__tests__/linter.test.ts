import { describe, it, expect } from "vitest";
import { lintRepo } from "../lib/linter";
import type { LintViolation } from "../lib/linter";
import type { PMData } from "../lib/types";
import type { AppSettings } from "../lib/settings";
import { DEFAULT_SETTINGS } from "../lib/settings";

// ── Helpers ──

/** Build a minimal PMData with tasks, decisions, and weeklySummaries. */
function makePMData(overrides: Partial<PMData> = {}): PMData {
  return {
    projects: [],
    objectives: [],
    teams: [],
    systems: [],
    tasks: [],
    decisions: [],
    weeklySummaries: [],
    inbox: "",
    rawFiles: {},
    loadedAt: new Date().toISOString(),
    folderName: "test-repo",
    warnings: [],
    settings: DEFAULT_SETTINGS,
    relationships: {
      tier1ToTier2: {},
      tier2ToTasks: {},
      taskToTier2: {},
      violations: [],
    },
    ...overrides,
  };
}

/** Build settings with overrides. */
function makeSettings(overrides: Partial<AppSettings> = {}): AppSettings {
  return {
    ...DEFAULT_SETTINGS,
    ...overrides,
    lint: { ...DEFAULT_SETTINGS.lint, ...overrides.lint },
    export: { ...DEFAULT_SETTINGS.export, ...overrides.export },
  };
}

// ── Tests ──

describe("lintRepo", () => {
  it("returns no violations when lint is disabled", () => {
    const settings = makeSettings({ lint: { ...DEFAULT_SETTINGS.lint, enabled: false } });
    const data = makePMData({
      tasks: [
        {
          id: "T001", title: "Test", status: "Open", created: "2026-03-01",
          objectiveChain: "", objectiveIds: [], team: "", assigned: "",
          systems: [], tags: [], description: "x".repeat(1000), raw: "",
        },
      ],
    });
    const result = lintRepo(data, settings);
    expect(result.violations).toEqual([]);
    expect(result.blocked).toBe(false);
  });

  it("detects task missing #project: tag", () => {
    const settings = makeSettings({
      lint: { enabled: true, mode: "warn", requireProjectTag: true, requireNamespacedTags: false },
    });
    const data = makePMData({
      tasks: [
        {
          id: "T001", title: "Tagged", status: "Open", created: "2026-03-01",
          objectiveChain: "", objectiveIds: [], team: "", assigned: "",
          systems: [], tags: ["#project:lapu-lapu", "#tier:1"], description: "", raw: "",
        },
        {
          id: "T002", title: "Untagged", status: "Open", created: "2026-03-01",
          objectiveChain: "", objectiveIds: [], team: "", assigned: "",
          systems: [], tags: ["#tier:1"], description: "", raw: "",
        },
      ],
    });
    const result = lintRepo(data, settings);
    const projectViolations = result.violations.filter((v) => v.rule === "require-project-tag");
    expect(projectViolations.length).toBe(1);
    expect(projectViolations[0].entity).toBe("T002");
  });

  it("detects decision missing #project: tag", () => {
    const settings = makeSettings({
      lint: { enabled: true, mode: "warn", requireProjectTag: true, requireNamespacedTags: false },
    });
    const data = makePMData({
      decisions: [
        {
          id: "D001", title: "Good", date: "2026-03-01", requestor: "",
          request: "", decision: "", reason: "",
          tags: ["#project:lapu-lapu"], raw: "",
        },
        {
          id: "D002", title: "Bad", date: "2026-03-01", requestor: "",
          request: "", decision: "", reason: "",
          tags: [], raw: "",
        },
      ],
    });
    const result = lintRepo(data, settings);
    const projectViolations = result.violations.filter((v) => v.rule === "require-project-tag");
    expect(projectViolations.length).toBe(1);
    expect(projectViolations[0].entity).toBe("D002");
  });

  it("detects non-namespaced tags", () => {
    const settings = makeSettings({
      lint: { enabled: true, mode: "warn", requireProjectTag: false, requireNamespacedTags: true },
    });
    const data = makePMData({
      tasks: [
        {
          id: "T001", title: "Mixed tags", status: "Open", created: "2026-03-01",
          objectiveChain: "", objectiveIds: [], team: "", assigned: "",
          systems: [], tags: ["#project:lapu-lapu", "#badtag", "#tier:1"], description: "", raw: "",
        },
      ],
    });
    const result = lintRepo(data, settings);
    const nsViolations = result.violations.filter((v) => v.rule === "require-namespaced-tags");
    expect(nsViolations.length).toBe(1);
    expect(nsViolations[0].message).toContain("#badtag");
  });

  it("detects oversized notes", () => {
    const settings = makeSettings({
      lint: { enabled: true, mode: "warn", requireProjectTag: false, requireNamespacedTags: false },
      export: { ...DEFAULT_SETTINGS.export, maxNotesLength: 100 },
    });
    const data = makePMData({
      tasks: [
        {
          id: "T001", title: "Short", status: "Open", created: "2026-03-01",
          objectiveChain: "", objectiveIds: [], team: "", assigned: "",
          systems: [], tags: [], description: "short", raw: "",
        },
        {
          id: "T002", title: "Long", status: "Open", created: "2026-03-01",
          objectiveChain: "", objectiveIds: [], team: "", assigned: "",
          systems: [], tags: [], description: "x".repeat(200), raw: "",
        },
      ],
    });
    const result = lintRepo(data, settings);
    const notesViolations = result.violations.filter((v) => v.rule === "max-notes-length");
    expect(notesViolations.length).toBe(1);
    expect(notesViolations[0].entity).toBe("T002");
  });

  it("detects weekly summary missing project metadata", () => {
    const settings = makeSettings({
      lint: { enabled: true, mode: "warn", requireProjectTag: true, requireNamespacedTags: false },
    });
    const data = makePMData({
      weeklySummaries: [
        { filename: "2026-W13.md", content: "has project", project: "lapu-lapu" },
        { filename: "2026-W11.md", content: "no project", project: undefined },
      ],
    });
    const result = lintRepo(data, settings);
    const weeklyViolations = result.violations.filter((v) => v.rule === "weekly-missing-project");
    expect(weeklyViolations.length).toBe(1);
    expect(weeklyViolations[0].entity).toBe("2026-W11.md");
  });

  it("blocks export when mode is 'fail' and errors exist", () => {
    const settings = makeSettings({
      lint: { enabled: true, mode: "fail", requireProjectTag: true, requireNamespacedTags: false },
    });
    const data = makePMData({
      tasks: [
        {
          id: "T001", title: "No tag", status: "Open", created: "2026-03-01",
          objectiveChain: "", objectiveIds: [], team: "", assigned: "",
          systems: [], tags: [], description: "", raw: "",
        },
      ],
    });
    const result = lintRepo(data, settings);
    expect(result.blocked).toBe(true);
    expect(result.errorCount).toBeGreaterThan(0);
    expect(result.violations[0].severity).toBe("error");
  });

  it("does not block when mode is 'warn'", () => {
    const settings = makeSettings({
      lint: { enabled: true, mode: "warn", requireProjectTag: true, requireNamespacedTags: false },
    });
    const data = makePMData({
      tasks: [
        {
          id: "T001", title: "No tag", status: "Open", created: "2026-03-01",
          objectiveChain: "", objectiveIds: [], team: "", assigned: "",
          systems: [], tags: [], description: "", raw: "",
        },
      ],
    });
    const result = lintRepo(data, settings);
    expect(result.blocked).toBe(false);
    expect(result.warningCount).toBeGreaterThan(0);
    expect(result.violations[0].severity).toBe("warning");
  });

  it("returns all violation types for a fixture with multiple issues", () => {
    const settings = makeSettings({
      lint: { enabled: true, mode: "fail", requireProjectTag: true, requireNamespacedTags: true },
      export: { ...DEFAULT_SETTINGS.export, maxNotesLength: 50 },
    });
    const data = makePMData({
      tasks: [
        {
          id: "T001", title: "Missing project, non-ns tag, oversized notes",
          status: "Open", created: "2026-03-01",
          objectiveChain: "", objectiveIds: [], team: "", assigned: "",
          systems: [], tags: ["#badtag"], description: "x".repeat(100), raw: "",
        },
      ],
      weeklySummaries: [
        { filename: "2026-W13.md", content: "no project", project: undefined },
      ],
    });

    const result = lintRepo(data, settings);
    const rules = new Set(result.violations.map((v: LintViolation) => v.rule));

    expect(rules.has("require-project-tag")).toBe(true);
    expect(rules.has("require-namespaced-tags")).toBe(true);
    expect(rules.has("max-notes-length")).toBe(true);
    expect(rules.has("weekly-missing-project")).toBe(true);
    expect(result.blocked).toBe(true);
    expect(result.errorCount).toBeGreaterThanOrEqual(4);
  });
});
