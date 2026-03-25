// ── Data types parsed from Markdown files ──

export interface Objective {
  id: string;
  title: string;
  tier: 1 | 2 | 3;
  tags: string[];
  source: string[];
  sourceFile?: string;
  parentObjectiveIds: string[];
  description: string;
  commitments: string[];
  ownerSection?: string; // e.g. "Hari Pothakamuri", "Debamalya Das", "David Klan"
  raw: string;
}

export interface Team {
  name: string;
  lead: string;
  reportsTo?: string;
  members?: string[];
  primarySystems?: string[];
  workTypes?: string;
  objectiveAlignment?: string;
  tags: string[];
  subTeams?: Team[];
  raw: string;
}

export interface SystemOfRecord {
  name: string;
  tag: string;
  purpose: string;
}

export interface Task {
  id: string;
  title: string;
  status: string;
  created: string;
  objectiveChain: string;
  objectiveIds: string[];
  team: string;
  assigned: string;
  systems: string[];
  relevance?: number;
  tags: string[];
  description: string;
  raw: string;
}

export interface Decision {
  id: string;
  title: string;
  date: string;
  requestor: string;
  request: string;
  decision: string;
  reason: string;
  tags: string[];
  raw: string;
}

export interface WeeklySummary {
  filename: string;
  content: string;
}

export type AdvisoryKind =
  | "orphaned-tier2"       // Tier-2 with no Tier-1 parent
  | "invalid-parent"       // Tier-2 with a non-Tier-1 parent
  | "task-skips-tier2"     // Task links directly to Tier-1 only
  | "missing-objective";   // Task references an objective ID that doesn't exist

export interface RelationshipAdvisory {
  kind: AdvisoryKind;
  subject: string;          // ID of the objective or task with the issue
  message: string;          // Human-readable description
  resolution: string;       // Concrete suggestion for how to fix it
  relatedIds: string[];     // IDs mentioned in the issue (parents, refs, etc.)
}

export interface RelationshipMap {
  // Tier-1 → Tier-2: one-to-many (a Tier-1 can have many Tier-2 children;
  //   a Tier-2 may reference one or more Tier-1 parents for cross-cutting objectives)
  tier1ToTier2: Record<string, string[]>;
  // Tier-2 → Tasks: many-to-many (tier2_id → [task_ids])
  tier2ToTasks: Record<string, string[]>;
  // Task → Tier-2: many-to-many (task_id → [tier2_ids])
  taskToTier2: Record<string, string[]>;
  // Relationship advisory notes
  violations: RelationshipAdvisory[];
}

export interface PMData {
  objectives: Objective[];
  teams: Team[];
  systems: SystemOfRecord[];
  tasks: Task[];
  decisions: Decision[];
  weeklySummaries: WeeklySummary[];
  inbox: string;
  rawFiles: Record<string, string>;
  loadedAt: string;
  folderName: string;
  warnings: string[];
  relationships: RelationshipMap;
}

export interface ExportWarning {
  type: string;
  taskId: string;
  objectiveId: string;
  message: string;
}

export interface ExportOptions {
  includeObjectives: boolean;
  includeTeamsSystems: boolean;
  includeTasks: boolean;
  includeDecisions: boolean;
  includeWeeklySummaries: boolean;
  weeklySummaryCount: number;
  includeInbox: boolean;
  format: 'md' | 'json';
}
