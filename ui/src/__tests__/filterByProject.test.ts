import { describe, it, expect } from "vitest";
import { filterByProject } from "../lib/exporter";
import type { PMData } from "../lib/types";
import { DEFAULT_SETTINGS } from "../lib/settings";

// ── Fixture builder ──

function makePMData(overrides: Partial<PMData> = {}): PMData {
  return {
    projects: [
      {
        id: "P-LPLP", slug: "lapu-lapu", name: "Lapu-Lapu",
        description: "", primaryAudience: [], primarySystems: [],
        reportCadence: "weekly", defaultPackName: "copilot-pack_lapu-lapu.md", tags: [],
      },
      {
        id: "P-EPS", slug: "epsilon", name: "Epsilon",
        description: "", primaryAudience: [], primarySystems: [],
        reportCadence: "weekly", defaultPackName: "copilot-pack_epsilon.md", tags: [],
      },
    ],
    objectives: [],
    keyResults: [
      {
        id: "KR001",
        title: "Lapu KR",
        objectiveId: "O1",
        metricType: "numeric",
        startValue: 0,
        targetValue: 100,
        currentValue: 10,
        targetDate: "2026-12-31",
        status: "On Track",
        created: "2026-03-01",
        tags: ["#project:lapu-lapu"],
        description: "",
        progressLog: [],
        changeLog: [],
        raw: "",
      },
      {
        id: "KR002",
        title: "Epsilon KR",
        objectiveId: "O2",
        metricType: "numeric",
        startValue: 0,
        targetValue: 100,
        currentValue: 20,
        targetDate: "2026-12-31",
        status: "On Track",
        created: "2026-03-01",
        tags: ["#project:epsilon"],
        description: "",
        progressLog: [],
        changeLog: [],
        raw: "",
      },
      {
        id: "KR003",
        title: "Untagged KR",
        objectiveId: "O1",
        metricType: "numeric",
        startValue: 0,
        targetValue: 100,
        currentValue: 5,
        targetDate: "2026-12-31",
        status: "Not Started",
        created: "2026-03-01",
        tags: [],
        description: "",
        progressLog: [],
        changeLog: [],
        raw: "",
      },
    ],
    teams: [
      { name: "GOCC", lead: "Jonan", tags: [], raw: "" },
      { name: "ETS Japan", lead: "Birger", tags: [], raw: "" },
      { name: "Architecture", lead: "Balaji", tags: [], raw: "" },
    ],
    systems: [
      { name: "New Relic", tag: "#system:newrelic", purpose: "APM" },
      { name: "Moogsoft", tag: "#system:moogsoft", purpose: "AIOps" },
      { name: "LeanIX", tag: "#system:leanix", purpose: "EA" },
    ],
    tasks: [
      {
        id: "T001", title: "GOCC monitoring", status: "Open", created: "2026-03-01",
        objectiveChain: "O1", objectiveIds: ["O1"], team: "GOCC", assigned: "Jonan",
        systems: ["#system:newrelic", "#system:moogsoft"],
        tags: ["#project:lapu-lapu", "#tier:1"], description: "Lapu task", raw: "",
      },
      {
        id: "T002", title: "Epsilon POT setup", status: "Open", created: "2026-03-02",
        objectiveChain: "O2", objectiveIds: ["O2"], team: "Architecture", assigned: "Balaji",
        systems: ["#system:leanix"],
        tags: ["#project:epsilon", "#tier:2"], description: "Epsilon task", raw: "",
      },
      {
        id: "T003", title: "Shared task", status: "Open", created: "2026-03-03",
        objectiveChain: "O1", objectiveIds: ["O1"], team: "ETS Japan", assigned: "Birger",
        systems: ["#system:newrelic"],
        tags: ["#project:lapu-lapu", "#tier:1"], description: "Another lapu task", raw: "",
      },
      {
        id: "T004", title: "Untagged task", status: "Open", created: "2026-03-04",
        objectiveChain: "O3", objectiveIds: ["O3"], team: "GOCC", assigned: "Jonan",
        systems: [], tags: [], description: "No project tag", raw: "",
      },
    ],
    decisions: [
      {
        id: "D001", title: "Lapu decision", date: "2026-03-01", requestor: "",
        request: "", decision: "Approved", reason: "",
        tags: ["#project:lapu-lapu"], raw: "",
      },
      {
        id: "D002", title: "Epsilon decision", date: "2026-03-02", requestor: "",
        request: "", decision: "Deferred", reason: "",
        tags: ["#project:epsilon"], raw: "",
      },
      {
        id: "D003", title: "Untagged decision", date: "2026-03-03", requestor: "",
        request: "", decision: "TBD", reason: "",
        tags: [], raw: "",
      },
    ],
    weeklySummaries: [
      { filename: "2026-W13.md", content: "lapu weekly", project: "lapu-lapu" },
      { filename: "2026-W13—epsilon.md", content: "eps weekly", project: "epsilon" },
      { filename: "2026-W11.md", content: "legacy weekly", project: undefined },
    ],
    inbox: "",
    rawFiles: {},
    loadedAt: new Date().toISOString(),
    folderName: "test-repo",
    warnings: [],
    settings: DEFAULT_SETTINGS,
    relationships: { tier1ToTier2: {}, tier2ToTasks: {}, taskToTier2: {}, violations: [] },
    ...overrides,
  };
}

// ── Tests ──

describe("filterByProject", () => {
  describe("task filtering", () => {
    it("includes only lapu-lapu tasks when slug is lapu-lapu", () => {
      const data = makePMData();
      const result = filterByProject(data, "lapu-lapu");
      const ids = result.tasks.map((t) => t.id);
      expect(ids).toContain("T001");
      expect(ids).toContain("T003");
      expect(ids).not.toContain("T002"); // epsilon
      expect(ids).not.toContain("T004"); // untagged
    });

    it("includes only epsilon tasks when slug is epsilon", () => {
      const data = makePMData();
      const result = filterByProject(data, "epsilon");
      const ids = result.tasks.map((t) => t.id);
      expect(ids).toEqual(["T002"]);
    });

    it("returns empty tasks for unknown project", () => {
      const data = makePMData();
      const result = filterByProject(data, "nonexistent");
      expect(result.tasks).toEqual([]);
    });
  });

  describe("decision filtering", () => {
    it("includes only lapu-lapu decisions", () => {
      const data = makePMData();
      const result = filterByProject(data, "lapu-lapu");
      const ids = result.decisions.map((d) => d.id);
      expect(ids).toEqual(["D001"]);
    });

    it("includes only epsilon decisions", () => {
      const data = makePMData();
      const result = filterByProject(data, "epsilon");
      const ids = result.decisions.map((d) => d.id);
      expect(ids).toEqual(["D002"]);
    });
  });

  describe("key result filtering", () => {
    it("includes only lapu-lapu key results", () => {
      const data = makePMData();
      const result = filterByProject(data, "lapu-lapu");
      const ids = result.keyResults.map((kr) => kr.id);
      expect(ids).toEqual(["KR001", "KR003"]);
    });

    it("includes only epsilon key results", () => {
      const data = makePMData();
      const result = filterByProject(data, "epsilon");
      const ids = result.keyResults.map((kr) => kr.id);
      expect(ids).toEqual(["KR002"]);
    });

    it("includes untagged key results only for the default project", () => {
      const data = makePMData({
        settings: {
          ...DEFAULT_SETTINGS,
          project: {
            ...DEFAULT_SETTINGS.project,
            defaultProjectSlug: "epsilon",
          },
        },
      });

      expect(filterByProject(data, "epsilon").keyResults.map((kr) => kr.id)).toEqual([
        "KR002",
        "KR003",
      ]);
      expect(filterByProject(data, "lapu-lapu").keyResults.map((kr) => kr.id)).toEqual([
        "KR001",
      ]);
    });
  });

  describe("weekly summary filtering", () => {
    it("includes lapu-lapu weeklies (by frontmatter + legacy fallback)", () => {
      const data = makePMData();
      const result = filterByProject(data, "lapu-lapu");
      const fnames = result.weeklySummaries.map((ws) => ws.filename);
      expect(fnames).toContain("2026-W13.md");
      expect(fnames).toContain("2026-W11.md"); // legacy → lapu-lapu
      expect(fnames).not.toContain("2026-W13—epsilon.md");
    });

    it("includes epsilon weeklies (by frontmatter + filename)", () => {
      const data = makePMData();
      const result = filterByProject(data, "epsilon");
      const fnames = result.weeklySummaries.map((ws) => ws.filename);
      expect(fnames).toContain("2026-W13—epsilon.md");
      expect(fnames).not.toContain("2026-W13.md");
      expect(fnames).not.toContain("2026-W11.md");
    });
  });

  describe("teams/systems filtering", () => {
    it("filters teams to those referenced by lapu-lapu tasks", () => {
      const data = makePMData();
      const result = filterByProject(data, "lapu-lapu");
      const teamNames = result.teams.map((t) => t.name);
      expect(teamNames).toContain("GOCC");       // T001
      expect(teamNames).toContain("ETS Japan");   // T003
      expect(teamNames).not.toContain("Architecture"); // only epsilon T002
    });

    it("filters systems to those referenced by lapu-lapu tasks", () => {
      const data = makePMData();
      const result = filterByProject(data, "lapu-lapu");
      const sysNames = result.systems.map((s) => s.name);
      expect(sysNames).toContain("New Relic");    // T001, T003
      expect(sysNames).toContain("Moogsoft");     // T001
      expect(sysNames).not.toContain("LeanIX");   // only epsilon T002
    });

    it("filters systems to those referenced by epsilon tasks", () => {
      const data = makePMData();
      const result = filterByProject(data, "epsilon");
      const sysNames = result.systems.map((s) => s.name);
      expect(sysNames).toContain("LeanIX");
      expect(sysNames).not.toContain("Moogsoft");
    });
  });

  describe("warnings", () => {
    it("warns about tasks missing #project: tag", () => {
      const data = makePMData();
      const result = filterByProject(data, "lapu-lapu");
      const missingTagWarnings = result.warnings.filter(
        (w) => w.type === "MISSING_PROJECT_TAG" && w.taskId === "T004"
      );
      expect(missingTagWarnings.length).toBe(1);
    });

    it("warns about decisions missing #project: tag", () => {
      const data = makePMData();
      const result = filterByProject(data, "lapu-lapu");
      const missingTagWarnings = result.warnings.filter(
        (w) => w.type === "MISSING_PROJECT_TAG" && w.taskId === "D003"
      );
      expect(missingTagWarnings.length).toBe(1);
    });

    it("warns about key results missing #project: tag", () => {
      const data = makePMData();
      const result = filterByProject(data, "lapu-lapu");
      const missingTagWarnings = result.warnings.filter(
        (w) => w.type === "MISSING_PROJECT_TAG" && w.taskId === "KR003"
      );
      expect(missingTagWarnings.length).toBe(1);
    });

    it("case-insensitive project tag matching", () => {
      const data = makePMData({
        tasks: [
          {
            id: "T010", title: "Mixed case", status: "Open", created: "2026-03-01",
            objectiveChain: "", objectiveIds: [], team: "", assigned: "",
            systems: [], tags: ["#Project:Lapu-Lapu"], description: "", raw: "",
          },
        ],
      });
      const result = filterByProject(data, "lapu-lapu");
      expect(result.tasks.map((t) => t.id)).toContain("T010");
    });
  });
});
