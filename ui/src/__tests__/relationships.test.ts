import { describe, it, expect } from "vitest";
import { buildRelationshipMap } from "../lib/relationships";
import type { Objective, Task } from "../lib/types";

function makeObjective(
  id: string,
  tier: 1 | 2,
  parentObjectiveIds: string[] = []
): Objective {
  return {
    id,
    title: id,
    tier,
    tags: [],
    source: [],
    parentObjectiveIds,
    description: "",
    commitments: [],
    raw: "",
  };
}

function makeTask(id: string, objectiveIds: string[]): Task {
  return {
    id,
    title: id,
    status: "Open",
    created: "2026-04-09",
    objectiveChain: objectiveIds.join(" → "),
    objectiveIds,
    team: "",
    assigned: "",
    systems: [],
    tags: [],
    description: "",
    raw: "",
  };
}

describe("buildRelationshipMap hardening", () => {
  it("deduplicates repeated Tier-1 refs in task-skips-tier2 advisories", () => {
    const objectives: Objective[] = [
      makeObjective("O1", 1),
      makeObjective("H-3", 2, ["O1"]),
    ];
    const tasks: Task[] = [makeTask("T001", ["O1", "O1"])];

    const result = buildRelationshipMap(objectives, tasks);
    const advisory = result.violations.find((v) => v.kind === "task-skips-tier2");

    expect(advisory).toBeTruthy();
    expect(advisory?.relatedIds).toEqual(["O1"]);
    expect(advisory?.message).toContain("O1 — no Tier-2 link");
    expect(advisory?.message).not.toContain("O1, O1");
  });

  it("deduplicates repeated missing objective refs", () => {
    const objectives: Objective[] = [makeObjective("O1", 1)];
    const tasks: Task[] = [makeTask("T002", ["ZZ-99", "ZZ-99", "O1"] )];

    const result = buildRelationshipMap(objectives, tasks);
    const advisory = result.violations.find((v) => v.kind === "missing-objective");

    expect(advisory).toBeTruthy();
    expect(advisory?.relatedIds).toEqual(["ZZ-99"]);
    expect(advisory?.message).toContain("ZZ-99");
    expect(advisory?.message).not.toContain("ZZ-99, ZZ-99");
  });

  it("returns unique Tier-2 suggestions in task-skips-tier2 resolution", () => {
    const objectives: Objective[] = [
      makeObjective("O1", 1),
      makeObjective("H-1", 2, ["O1"]),
      makeObjective("H-2", 2, ["O1"]),
    ];
    const tasks: Task[] = [makeTask("T003", ["O1", "O1"] )];

    const result = buildRelationshipMap(objectives, tasks);
    const advisory = result.violations.find((v) => v.kind === "task-skips-tier2");

    expect(advisory).toBeTruthy();
    expect(advisory?.resolution).toContain("H-1, H-2");
    expect(advisory?.resolution).not.toContain("H-1, H-1");
  });
});
