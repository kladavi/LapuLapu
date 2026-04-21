import type { Objective, Task, RelationshipAdvisory } from "./types";

export type ObjectiveIndexes = {
  tier1Map: Map<string, Objective>;
  tier2Map: Map<string, Objective>;
  allObjMap: Map<string, Objective>;
};

export type TaskObjectiveRefs = {
  tier2Refs: string[];
  tier1Refs: string[];
  invalidRefs: string[];
};

export function uniqueInOrder(values: string[]): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const value of values) {
    if (!seen.has(value)) {
      seen.add(value);
      out.push(value);
    }
  }
  return out;
}

export function makeObjectiveIndexes(objectives: Objective[]): ObjectiveIndexes {
  return {
    tier1Map: new Map(objectives.filter((o) => o.tier === 1).map((o) => [o.id, o])),
    tier2Map: new Map(objectives.filter((o) => o.tier === 2).map((o) => [o.id, o])),
    allObjMap: new Map(objectives.map((o) => [o.id, o])),
  };
}

export function collectTaskObjectiveRefs(task: Task, indexes: ObjectiveIndexes): TaskObjectiveRefs {
  const ids = uniqueInOrder(task.objectiveIds);
  return {
    tier2Refs: ids.filter((oid) => indexes.tier2Map.has(oid)),
    tier1Refs: ids.filter((oid) => indexes.tier1Map.has(oid)),
    invalidRefs: ids.filter((oid) => !indexes.allObjMap.has(oid)),
  };
}

export function buildTier2CandidatesFromTier1(
  tier1Refs: string[],
  tier1ToTier2: Record<string, string[]>
): string[] {
  const candidates = tier1Refs.flatMap((t1id) => tier1ToTier2[t1id] || []);
  return uniqueInOrder(candidates).slice(0, 3);
}

export function pushTier2ParentViolations(
  tier2: Objective,
  tier2Id: string,
  indexes: ObjectiveIndexes,
  tier1ToTier2: Record<string, string[]>,
  violations: RelationshipAdvisory[]
): void {
  const uniqueParents = uniqueInOrder(tier2.parentObjectiveIds);
  const tier1Parents = uniqueParents.filter((pid) => indexes.tier1Map.has(pid));

  if (tier1Parents.length === 0) {
    const knownParents = uniqueParents.filter((pid) => indexes.allObjMap.has(pid));
    violations.push({
      kind: "orphaned-tier2",
      subject: tier2Id,
      relatedIds: [],
      message: `"${tier2.title}" (${tier2Id}) has no Tier-1 parent.`,
      resolution: knownParents.length > 0
        ? `Add a Tier-1 parent ID (e.g. O1–O6) to the **Parent Objective** list in objectives.md for ${tier2Id}. Current entries (${knownParents.join(", ")}) are not Tier-1 objectives.`
        : `Add a **Parent Objective** line to ${tier2Id} in objectives.md, e.g. \`- O1 (Frictionless Customer Experience)\`.`,
    });
  } else {
    tier1Parents.forEach((parentId) => {
      if (!tier1ToTier2[parentId].includes(tier2Id)) {
        tier1ToTier2[parentId].push(tier2Id);
      }
    });
  }

  const invalidParents = uniqueParents.filter(
    (pid) => !indexes.tier1Map.has(pid) && indexes.allObjMap.has(pid)
  );
  if (invalidParents.length > 0) {
    const invalidObjs = invalidParents.map((pid) => {
      const o = indexes.allObjMap.get(pid)!;
      return `${pid} (Tier-${o.tier})`;
    });
    violations.push({
      kind: "invalid-parent",
      subject: tier2Id,
      relatedIds: invalidParents,
      message: `"${tier2.title}" (${tier2Id}) references non-Tier-1 parent(s): ${invalidObjs.join(", ")}.`,
      resolution: `In objectives.md, replace the **Parent Objective** entries for ${tier2Id} with Tier-1 IDs (O1–O6). If this is intentional cross-cutting, add the appropriate Tier-1 ID alongside the existing entry.`,
    });
  }
}

export function pushTaskRelationshipViolations(
  task: Task,
  refs: TaskObjectiveRefs,
  tier1ToTier2: Record<string, string[]>,
  violations: RelationshipAdvisory[]
): void {
  if (refs.tier1Refs.length > 0 && refs.tier2Refs.length === 0) {
    const suggestions = buildTier2CandidatesFromTier1(refs.tier1Refs, tier1ToTier2);
    violations.push({
      kind: "task-skips-tier2",
      subject: task.id,
      relatedIds: refs.tier1Refs,
      message: `"${task.title}" (${task.id}) links only to Tier-1 objective(s): ${refs.tier1Refs.join(", ")} — no Tier-2 link.`,
      resolution: suggestions.length > 0
        ? `Update the **Objective Chain** in tasks.md for ${task.id} to include a Tier-2 objective. Candidates under ${refs.tier1Refs.join(", ")}: ${suggestions.join(", ")}.`
        : `Update the **Objective Chain** in tasks.md for ${task.id} to include a Tier-2 objective ID between the Tier-1 reference and this task.`,
    });
  }

  if (refs.invalidRefs.length > 0) {
    violations.push({
      kind: "missing-objective",
      subject: task.id,
      relatedIds: refs.invalidRefs,
      message: `"${task.title}" (${task.id}) references objective ID(s) that don't exist: ${refs.invalidRefs.join(", ")}.`,
      resolution: `In tasks.md, correct the **Objective Chain** for ${task.id}. Check for typos — valid IDs are Tier-1 (O1–O6) or Tier-2 (e.g. H-1, B-1, KL-1). Remove or replace: ${refs.invalidRefs.join(", ")}.`,
    });
  }
}
