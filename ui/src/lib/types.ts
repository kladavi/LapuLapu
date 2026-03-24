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
