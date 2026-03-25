/**
 * Relationship enforcement and validation for objectives and tasks.
 *
 * Enforces:
 * - Tier-1 ↔ Tier-2: One-to-many (one or more Tier-1 can relate to many Tier-2)
 *   - A Tier-2 can reference one or more Tier-1 parents (flexible hierarchy)
 *   - A Tier-1 can have many Tier-2 children
 * - Tier-2 ↔ Tasks: Many-to-many (many Tier-2 can relate to many tasks)
 *   - Tasks should preferentially reference Tier-2 (not Tier-1)
 */

import type { Objective, Task, RelationshipMap, RelationshipAdvisory } from "./types";

/**
 * Builds and validates the relationship map for objectives and tasks.
 * Enforces flexible parent-child relationships and many-to-many task links.
 */
export function buildRelationshipMap(
  objectives: Objective[],
  tasks: Task[]
): RelationshipMap {
  const tier1ToTier2: Record<string, string[]> = {};
  const tier2ToTasks: Record<string, string[]> = {};
  const taskToTier2: Record<string, string[]> = {};
  const violations: RelationshipAdvisory[] = [];

  const tier1Map = new Map(objectives.filter((o) => o.tier === 1).map((o) => [o.id, o]));
  const tier2Map = new Map(objectives.filter((o) => o.tier === 2).map((o) => [o.id, o]));
  const allObjMap = new Map(objectives.map((o) => [o.id, o]));

  tier1Map.forEach((_, id) => { tier1ToTier2[id] = []; });

  // Build Tier-1 → Tier-2 (a Tier-2 may have one or more Tier-1 parents)
  tier2Map.forEach((tier2, tier2Id) => {
    const tier1Parents = tier2.parentObjectiveIds.filter((pid) => tier1Map.has(pid));

    if (tier1Parents.length === 0) {
      // Determine what parents exist (if any) to give a precise resolution
      const knownParents = tier2.parentObjectiveIds.filter((pid) => allObjMap.has(pid));
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

    // Warn about non-Tier-1 parents
    const invalidParents = tier2.parentObjectiveIds.filter(
      (pid) => !tier1Map.has(pid) && allObjMap.has(pid)
    );
    if (invalidParents.length > 0) {
      const invalidObjs = invalidParents.map((pid) => {
        const o = allObjMap.get(pid)!;
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
  });

  tier2Map.forEach((_, id) => { tier2ToTasks[id] = []; });

  // Build Tier-2 → Tasks (many-to-many)
  tasks.forEach((task) => {
    const tier2Refs = task.objectiveIds.filter((oid) => tier2Map.has(oid));
    const tier1Refs = task.objectiveIds.filter((oid) => tier1Map.has(oid));
    const invalidRefs = task.objectiveIds.filter((oid) => !allObjMap.has(oid));

    tier2Refs.forEach((tier2Id) => {
      if (!tier2ToTasks[tier2Id].includes(task.id)) tier2ToTasks[tier2Id].push(task.id);
      if (!taskToTier2[task.id]) taskToTier2[task.id] = [];
      if (!taskToTier2[task.id].includes(tier2Id)) taskToTier2[task.id].push(tier2Id);
    });

    // Task only links to Tier-1, skipping Tier-2
    if (tier1Refs.length > 0 && tier2Refs.length === 0) {
      // Find Tier-2 children of the referenced Tier-1s as concrete suggestions
      const suggestions = tier1Refs
        .flatMap((t1id) => (tier1ToTier2[t1id] || []))
        .slice(0, 3);
      violations.push({
        kind: "task-skips-tier2",
        subject: task.id,
        relatedIds: tier1Refs,
        message: `"${task.title}" (${task.id}) links only to Tier-1 objective(s): ${tier1Refs.join(", ")} — no Tier-2 link.`,
        resolution: suggestions.length > 0
          ? `Update the **Objective Chain** in tasks.md for ${task.id} to include a Tier-2 objective. Candidates under ${tier1Refs.join(", ")}: ${suggestions.join(", ")}.`
          : `Update the **Objective Chain** in tasks.md for ${task.id} to include a Tier-2 objective ID between the Tier-1 reference and this task.`,
      });
    }

    // References non-existent objective IDs
    if (invalidRefs.length > 0) {
      violations.push({
        kind: "missing-objective",
        subject: task.id,
        relatedIds: invalidRefs,
        message: `"${task.title}" (${task.id}) references objective ID(s) that don't exist: ${invalidRefs.join(", ")}.`,
        resolution: `In tasks.md, correct the **Objective Chain** for ${task.id}. Check for typos — valid IDs are Tier-1 (O1–O6) or Tier-2 (e.g. H-1, B-1, KL-1). Remove or replace: ${invalidRefs.join(", ")}.`,
      });
    }
  });

  return { tier1ToTier2, tier2ToTasks, taskToTier2, violations };
}

/**
 * Get all Tier-2 objectives that are children of a Tier-1 objective.
 * A Tier-1 can have multiple Tier-2 children.
 */
export function getTier2Children(
  tier1Id: string,
  relationships: RelationshipMap,
  tier2Objectives: Objective[]
): Objective[] {
  const childIds = relationships.tier1ToTier2[tier1Id] || [];
  const tier2Map = new Map(tier2Objectives.map((o) => [o.id, o]));
  return childIds
    .filter((id) => tier2Map.has(id))
    .map((id) => tier2Map.get(id)!)
    .sort((a, b) => a.id.localeCompare(b.id));
}

/**
 * Get all tasks that are related to a Tier-2 objective.
 * Many-to-many: a Tier-2 can relate to many tasks.
 */
export function getTier2Tasks(
  tier2Id: string,
  relationships: RelationshipMap,
  tasks: Task[]
): Task[] {
  const taskIds = relationships.tier2ToTasks[tier2Id] || [];
  const taskMap = new Map(tasks.map((t) => [t.id, t]));
  return taskIds
    .filter((id) => taskMap.has(id))
    .map((id) => taskMap.get(id)!)
    .sort((a, b) => a.id.localeCompare(b.id));
}

/**
 * Get all Tier-2 objectives that are related to a task.
 * Many-to-many: a task can relate to many Tier-2 objectives.
 */
export function getTaskTier2Objectives(
  taskId: string,
  relationships: RelationshipMap,
  tier2Objectives: Objective[]
): Objective[] {
  const tier2Ids = relationships.taskToTier2[taskId] || [];
  const tier2Map = new Map(tier2Objectives.map((o) => [o.id, o]));
  return tier2Ids
    .filter((id) => tier2Map.has(id))
    .map((id) => tier2Map.get(id)!)
    .sort((a, b) => a.id.localeCompare(b.id));
}

/**
 * Check if a Tier-2 objective is a valid child of a Tier-1 objective.
 * Returns true if the relationship is recorded in the map.
 */
export function isValidTier1Tier2Relationship(
  tier1Id: string,
  tier2Id: string,
  relationships: RelationshipMap
): boolean {
  return (relationships.tier1ToTier2[tier1Id] || []).includes(tier2Id);
}

/**
 * Check if a task is related to a Tier-2 objective.
 * Returns true if the many-to-many relationship is recorded in the map.
 */
export function isValidTier2TaskRelationship(
  tier2Id: string,
  taskId: string,
  relationships: RelationshipMap
): boolean {
  return (relationships.tier2ToTasks[tier2Id] || []).includes(taskId);
}

/**
 * Get all Tier-1 objectives that have Tier-2 children.
 * Useful for filtering out Tier-1 objectives with no children.
 */
export function getTier1ObjectivesWithChildren(
  relationships: RelationshipMap
): string[] {
  return Object.entries(relationships.tier1ToTier2)
    .filter(([_, children]) => children.length > 0)
    .map(([tier1Id]) => tier1Id);
}

/**
 * Get all orphaned Tier-2 objectives (those without any Tier-1 parents).
 * These are informational - not necessarily errors, but worth noting.
 */
export function getOrphanedTier2Objectives(
  relationships: RelationshipMap,
  tier2Objectives: Objective[]
): Objective[] {
  const tier2Ids = new Set(tier2Objectives.map((o) => o.id));
  const linkedTier2Ids = new Set(
    Object.values(relationships.tier1ToTier2).flat()
  );
  const orphanedIds = [...tier2Ids].filter((id) => !linkedTier2Ids.has(id));
  return tier2Objectives
    .filter((o) => orphanedIds.includes(o.id))
    .sort((a, b) => a.id.localeCompare(b.id));
}

/**
 * Get all tasks that are not linked to any Tier-2 objective.
 * These tasks may be linked to Tier-1 or be completely orphaned.
 */
export function getOrphanedTasks(
  relationships: RelationshipMap,
  tasks: Task[]
): Task[] {
  return tasks
    .filter((t) => !relationships.taskToTier2[t.id] || relationships.taskToTier2[t.id].length === 0)
    .sort((a, b) => a.id.localeCompare(b.id));
}
