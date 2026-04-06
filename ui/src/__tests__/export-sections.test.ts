import { describe, it, expect } from "vitest";
import { generateExport } from "../lib/exporter";
import type { PMData, ExportOptions } from "../lib/types";
import type { AppSettings } from "../lib/settings";
import { DEFAULT_SETTINGS } from "../lib/settings";

// ── Helpers ──

function makeSettings(overrides: Partial<AppSettings["export"]> = {}): AppSettings {
  return {
    ...DEFAULT_SETTINGS,
    export: { ...DEFAULT_SETTINGS.export, ...overrides },
  };
}

function makePMData(settingsOverrides: Partial<AppSettings["export"]> = {}): PMData {
  const settings = makeSettings(settingsOverrides);
  return {
    projects: [
      {
        id: "P-LPLP",
        slug: "lapu-lapu",
        name: "Lapu-Lapu",
        description: "Test project",
        primaryAudience: ["David Klan"],
        primarySystems: [],
        reportCadence: "weekly",
        defaultPackName: "copilot-pack_lapu-lapu.md",
        tags: [],
      },
    ],
    objectives: [
      {
        id: "O1",
        title: "Test Objective",
        tier: 1,
        tags: ["#tier:1"],
        source: [],
        parentObjectiveIds: [],
        description: "A test objective",
        commitments: [],
        raw: "",
      },
    ],
    teams: [],
    systems: [],
    tasks: [
      {
        id: "T001",
        title: "Test Task",
        status: "Open",
        created: "2026-03-01",
        objectiveChain: "O1",
        objectiveIds: ["O1"],
        team: "Test",
        assigned: "Tester",
        systems: [],
        tags: ["#project:lapu-lapu", "#tier:1"],
        description: "A test task",
        raw: "",
      },
    ],
    decisions: [],
    keyResults: [],
    weeklySummaries: [
      {
        filename: "2026-W13.md",
        content: "---\nproject: lapu-lapu\n---\n## Week 13 summary",
        project: "lapu-lapu",
      },
    ],
    inbox: "",
    rawFiles: {},
    loadedAt: new Date().toISOString(),
    folderName: "test-repo",
    warnings: [],
    settings,
    relationships: {
      tier1ToTier2: {},
      tier2ToTasks: {},
      taskToTier2: {},
      violations: [],
    },
  };
}

const BASE_OPTIONS: ExportOptions = {
  projectSlug: "lapu-lapu",
  includeObjectives: true,
  includeTeamsSystems: false,
  includeTasks: true,
  includeDecisions: false,
  includeWeeklySummaries: true,
  weeklySummaryCount: 1,
  includeInbox: false,
  format: "md",
};

// ── Tests ──

describe("Export: How To Use section", () => {
  it("includes HOW TO USE section when includeHowToUse is true (default)", () => {
    const data = makePMData({ includeHowToUse: true });
    const result = generateExport(data, BASE_OPTIONS);
    expect(result.errors).toEqual([]);
    expect(result.content).toContain("## HOW TO USE THIS PACK (FOR RECIPIENTS)");
    expect(result.content).toContain("Open M365 Copilot Chat");
    expect(result.content).toContain("Upload this file");
  });

  it("omits HOW TO USE section when includeHowToUse is false", () => {
    const data = makePMData({ includeHowToUse: false });
    const result = generateExport(data, BASE_OPTIONS);
    expect(result.errors).toEqual([]);
    expect(result.content).not.toContain("## HOW TO USE THIS PACK (FOR RECIPIENTS)");
  });

  it("HOW TO USE appears before COPILOT INSTRUCTIONS", () => {
    const data = makePMData({ includeHowToUse: true });
    const result = generateExport(data, BASE_OPTIONS);
    const howToIdx = result.content.indexOf("## HOW TO USE THIS PACK");
    const instructionsIdx = result.content.indexOf("## COPILOT INSTRUCTIONS");
    expect(howToIdx).toBeGreaterThan(-1);
    expect(instructionsIdx).toBeGreaterThan(-1);
    expect(howToIdx).toBeLessThan(instructionsIdx);
  });
});

describe("Export: Role Prompts section", () => {
  it("includes STARTER PROMPTS BY ROLE when includeRolePrompts is true (default)", () => {
    const data = makePMData({ includeRolePrompts: true });
    const result = generateExport(data, BASE_OPTIONS);
    expect(result.errors).toEqual([]);
    expect(result.content).toContain("## STARTER PROMPTS BY ROLE");
    expect(result.content).toContain("### For Birger (ETS Japan)");
    expect(result.content).toContain("### For Hari / Jonan (GOCC)");
    expect(result.content).toContain("### For Deb (Observability)");
    expect(result.content).toContain("### For Kelvin (ETS Region)");
    expect(result.content).toContain("### For Balaji (Architecture)");
  });

  it("omits STARTER PROMPTS BY ROLE when includeRolePrompts is false", () => {
    const data = makePMData({ includeRolePrompts: false });
    const result = generateExport(data, BASE_OPTIONS);
    expect(result.errors).toEqual([]);
    expect(result.content).not.toContain("## STARTER PROMPTS BY ROLE");
    expect(result.content).not.toContain("### For Birger");
  });

  it("Role Prompts appear before COPILOT INSTRUCTIONS", () => {
    const data = makePMData({ includeRolePrompts: true });
    const result = generateExport(data, BASE_OPTIONS);
    const roleIdx = result.content.indexOf("## STARTER PROMPTS BY ROLE");
    const instructionsIdx = result.content.indexOf("## COPILOT INSTRUCTIONS");
    expect(roleIdx).toBeGreaterThan(-1);
    expect(roleIdx).toBeLessThan(instructionsIdx);
  });
});

describe("Export: Both sections together", () => {
  it("includes both HOW TO USE and Role Prompts by default", () => {
    const data = makePMData();
    const result = generateExport(data, BASE_OPTIONS);
    expect(result.content).toContain("## HOW TO USE THIS PACK (FOR RECIPIENTS)");
    expect(result.content).toContain("## STARTER PROMPTS BY ROLE");
  });

  it("omits both when both disabled", () => {
    const data = makePMData({ includeHowToUse: false, includeRolePrompts: false });
    const result = generateExport(data, BASE_OPTIONS);
    expect(result.content).not.toContain("## HOW TO USE THIS PACK");
    expect(result.content).not.toContain("## STARTER PROMPTS BY ROLE");
    // But COPILOT INSTRUCTIONS should still be present
    expect(result.content).toContain("## COPILOT INSTRUCTIONS");
  });

  it("section order: frontmatter → HOW TO USE → ROLE PROMPTS → COPILOT INSTRUCTIONS → DATA", () => {
    const data = makePMData({ includeHowToUse: true, includeRolePrompts: true });
    const result = generateExport(data, BASE_OPTIONS);
    const c = result.content;
    const order = [
      c.indexOf("---\ntitle:"),
      c.indexOf("## HOW TO USE THIS PACK"),
      c.indexOf("## STARTER PROMPTS BY ROLE"),
      c.indexOf("## COPILOT INSTRUCTIONS"),
      c.indexOf("## DATA (MACHINE-READABLE)"),
    ];
    for (let i = 1; i < order.length; i++) {
      expect(order[i]).toBeGreaterThan(order[i - 1]);
    }
  });

  it("JSON format does not include HOW TO USE or Role Prompts", () => {
    const data = makePMData({ includeHowToUse: true, includeRolePrompts: true });
    const result = generateExport(data, { ...BASE_OPTIONS, format: "json" });
    expect(result.errors).toEqual([]);
    expect(result.content).not.toContain("## HOW TO USE THIS PACK");
    expect(result.content).not.toContain("## STARTER PROMPTS BY ROLE");
  });
});
