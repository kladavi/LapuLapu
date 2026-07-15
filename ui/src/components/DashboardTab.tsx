"use client";

import React, { useState } from "react";
import { usePMData } from "../context/PMContext";
import { computeKRProgress } from "../lib/parsers";
import type { NavFilter } from "../app/page";

type FocusSection = "P1 Focus" | "P2 Focus" | "Watch List" | "Parking Lot";

type CurrentFocusItem = {
  name: string;
  status: string;
  score: number;
  overrideDetail: string;
  mentions: number | null;
  signals: string;
  summary: string;
  recommendedAction: string;
  evidence: string[];
  // V1.2 enrichment (populated from current-focus.json when available)
  attentionScore?: number;
  activityScore?: number;
  strategicScore?: number;
  strategicWeight?: number;
  trendSymbol?: string;
  trendDirection?: string;
  deltaPercent?: number;
  overrideApplied?: boolean;
  // V2.0 enrichment
  health?: WorkstreamHealth;
};

type CurrentFocusFromMd = {
  generated: string;
  version: string;
  executiveSummary: string;
  sections: Record<FocusSection, CurrentFocusItem[]>;
};

type FocusJsonItem = {
  id?: string;
  name?: string;
  category?: string;
  score?: number;
  attention_score?: number;
  activity_score?: number;
  strategic_score?: number;
  strategic_weight?: number;
  override_applied?: boolean;
  override_reason?: string;
  trend_symbol?: string;
  trend_direction?: string;
  trend_delta_percent?: number;
  evidence_files?: string[];
  health?: WorkstreamHealth;
};

type TrendJsonItem = {
  id?: string;
  name?: string;
  currentActivityScore?: number;
  previousActivityScore?: number;
  delta?: number;
  deltaPercent?: number;
  trendDirection?: string;
  trendSymbol?: string;
  trendReason?: string;
};

type TrendJson = {
  generated?: string;
  currentWindowDays?: number;
  previousWindowDays?: number;
  workstreams?: TrendJsonItem[];
};

type BriefingPrimary = {
  id?: string;
  name?: string;
  category?: string;
  attentionScore?: number;
  strategicScore?: number;
  activityScore?: number;
  trendDirection?: string;
  trendSymbol?: string;
  deltaPercent?: number;
  overrideApplied?: boolean;
  overrideReason?: string;
  whyItMatters?: string;
  recommendedNextAction?: string;
  topEvidence?: string[];
};

type BriefingItemLite = { name?: string; deltaPercent?: number; trendSymbol?: string; riskSignals?: number; escalationSignals?: number; decisionSignals?: number; category?: string };
type BriefingActionItem = { name?: string; action?: string };
type BriefingSource = { path?: string; weight?: number; window?: string; date?: string };

type BriefingJson = {
  generated?: string;
  executiveSnapshot?: string;
  primaryFocus?: BriefingPrimary[];
  risingRisks?: BriefingItemLite[];
  decisionWatch?: BriefingItemLite[];
  blockedOrEscalationCandidates?: BriefingItemLite[];
  recommendedActionsForDavid?: BriefingActionItem[];
  sourceInputs?: BriefingSource[];
};

type PipelineHealth = {
  lastRun?: string;
  status?: string;
  message?: string;
  lastActivityFile?: string;
  lastActivityHash?: string;
  currentFocusGenerated?: boolean;
  trendsGenerated?: boolean;
  morningBriefingGenerated?: boolean;
  jsonValidated?: boolean;
  gitCommitted?: boolean;
  lastCommitHash?: string;
};

type StructuredAction = {
  priority?: number;
  verb?: string;
  subject?: string;
  targetOwner?: string;
  dueBy?: string;
  rationale?: string;
};

type LinkedAction = {
  text?: string;
  owner?: string;
  dueBy?: string;
  status?: string;
  actionSource?: string;   // V3.0: 'marker' or 'inferred'
};

type DecisionEntry = {
  decisionId?: string;
  title?: string;
  dateDetected?: string;
  firstSeenDate?: string;
  lastSeenDate?: string;
  status?: string;
  owner?: string;
  ownerConfidence?: string;
  escalationPath?: string[];
  stakeholders?: string[];
  workstream?: string;
  sourceFiles?: string[];
  decisionAgeDays?: number;
  recencyDays?: number;
  decisionSummary?: string;
  recommendedFollowUp?: string | StructuredAction;
  // V2.0 additions
  type?: string;
  decisionRequired?: boolean;
  decisionPrompt?: string;
  decisionDeadline?: string;
  impact?: string;
  decisionConfidence?: number;
  // V2.5 additions
  decisionStatus?: string;
  decisionOutcome?: string;
  completionSignal?: string;
  linkedActions?: LinkedAction[];
  timeToEscalationRisk?: number | null;
  // V3.0 additions
  outcomeQuality?: string;      // 'High' | 'Medium' | 'Low' | 'Unknown'
  recurrenceCount?: number;
};

type DecisionRegistry = {
  generated?: string;
  version?: string;
  totals?: {
    total?: number;
    open?: number;
    closed?: number;
    authorativelyOwned?: number;
    pendingDecisions?: number;
    lifecycle?: { pending?: number; decided?: number; expired?: number };
    outcomeQuality?: { high?: number; medium?: number; low?: number; unknown?: number };
    recurring?: number;
    inferredActions?: number;
  };
  decisions?: DecisionEntry[];
};

type RiskEntry = {
  riskId?: string;
  title?: string;
  workstream?: string;
  owner?: string;
  ownerConfidence?: string;
  escalationPath?: string[];
  stakeholders?: string[];
  severity?: string;
  status?: string;
  trend?: string;
  agingDays?: number;
  recencyDays?: number;
  firstSeenDate?: string;
  lastSeenDate?: string;
  dateDetected?: string;
  sourceFiles?: string[];
  recommendedAction?: string | StructuredAction;
  // V2.0 additions
  impact?: string;
  riskConfidence?: number;
  // V2.5 additions
  timeToEscalationRisk?: number | null;
};

type RiskRegistry = {
  generated?: string;
  version?: string;
  totals?: {
    total?: number;
    open?: number;
    closed?: number;
    high?: number;
    rising?: number;
    authorativelyOwned?: number;
    imminentEscalation?: number;
  };
  risks?: RiskEntry[];
};

type WorkstreamHealth = {
  status?: string;
  color?: string;
  reason?: string;
  openRiskCount?: number;
  highRiskCount?: number;
  openDecisionCount?: number;
  oldDecisionCount?: number;
};

type InboxItem = {
  kind?: "decision" | "risk" | string;
  id?: string;
  title?: string;
  workstream?: string;
  owner?: string;
  ownerConfidence?: string;
  priority?: number;
  verb?: string;
  dueBy?: string;
  deadline?: string;
  confidence?: number;
  ageDays?: number;
  severity?: string;
  trend?: string;
  decisionRequired?: boolean;
  impact?: string;
  rationale?: string;
  // V2.5 additions
  decisionStatus?: string;
  decisionOutcome?: string;
  timeToEscalationRisk?: number | null;
  linkedActionCount?: number;
  // V3.0 additions
  outcomeQuality?: string;
  recurrenceCount?: number;
  actionSource?: string;
  rankingScore?: number;
  personalizationSignals?: PersonalizationSignal[];
};

type PersonalizationSignal = {
  source?: string;
  delta?: number;
  reason?: string;
};

type InboxCluster = {
  workstream?: string;
  theme?: string;
  itemCount?: number;
  topPriority?: number;
  p1Count?: number;
  minEscalationRisk?: number | null;
  kinds?: string[];
  itemIds?: string[];
};

type DavidInbox = {
  generated?: string;
  version?: string;
  caps?: { p1?: number; p2?: number; p3?: number };
  totals?: {
    candidates?: number;
    selected?: number;
    byPriority?: { p1?: number; p2?: number; p3?: number; p4?: number; p5?: number };
    tiers?: { p1Shown?: number; p2Shown?: number; p3Shown?: number };
    clusters?: number;
    imminentEscalation?: number;
    personalized?: number;
  };
  tiers?: { p1?: InboxItem[]; p2?: InboxItem[]; p3?: InboxItem[] };
  clusters?: InboxCluster[];
  items?: InboxItem[];
};

// V3.0 Execution Insights
type DelayedDecision = { id?: string; title?: string; workstream?: string; owner?: string; ageDays?: number };
type MissedDeadline  = { id?: string; title?: string; workstream?: string; owner?: string; deadline?: string; daysOverdue?: number };
type OverloadedOwner = { owner?: string; itemCount?: number; decisions?: number; risks?: number; p1Count?: number; avgConfidence?: number };
type RecurringDecision = { normalizedTitle?: string; count?: number; exampleTitle?: string; exampleId?: string; workstream?: string };
type StalePendingWs = { workstream?: string; count?: number; avgAgeDays?: number };
type HighAgedRisk = { id?: string; title?: string; workstream?: string; owner?: string; ageDays?: number };

type ExecutionInsights = {
  generated?: string;
  version?: string;
  totals?: {
    delayedDecisions?: number;
    missedDeadlines?: number;
    overloadedOwners?: number;
    recurringDecisions?: number;
    stalePendingByWorkstream?: number;
    highSeverityAgedRisks?: number;
  };
  delayedDecisions?: DelayedDecision[];
  missedDeadlines?: MissedDeadline[];
  overloadedOwners?: OverloadedOwner[];
  recurringDecisions?: RecurringDecision[];
  stalePendingByWorkstream?: StalePendingWs[];
  highSeverityAgedRisks?: HighAgedRisk[];
};

// Renders either the new structured action object or the legacy string.
function formatAction(action?: string | StructuredAction): string {
  if (!action) return "";
  if (typeof action === "string") return action;
  const parts: string[] = [];
  if (action.priority) parts.push(`P${action.priority}`);
  if (action.verb) parts.push(action.verb);
  if (action.subject) parts.push(`- ${action.subject}`);
  if (action.targetOwner) parts.push(`(owner: ${action.targetOwner})`);
  if (action.dueBy) parts.push(`by ${action.dueBy}`);
  return parts.join(" ");
}

function ownerBadgeClass(confidence?: string): string {
  if (confidence === "workstream-map") return "bg-green-50 text-green-800 border-green-200";
  if (confidence === "name-proximity") return "bg-amber-50 text-amber-800 border-amber-200";
  return "bg-slate-100 text-slate-600 border-slate-200";
}

function healthClass(status?: string): { stripe: string; badge: string } {
  switch (status) {
    case "Red":   return { stripe: "border-l-4 border-l-red-500",   badge: "bg-red-50 text-red-800 border-red-200" };
    case "Amber": return { stripe: "border-l-4 border-l-amber-500", badge: "bg-amber-50 text-amber-800 border-amber-200" };
    case "Green": return { stripe: "border-l-4 border-l-green-500", badge: "bg-green-50 text-green-800 border-green-200" };
    default:      return { stripe: "border-l-4 border-l-slate-300", badge: "bg-slate-100 text-slate-600 border-slate-200" };
  }
}

function priorityBadgeClass(priority?: number): string {
  if (priority === 1) return "bg-red-50 text-red-800 border-red-200";
  if (priority === 2) return "bg-amber-50 text-amber-800 border-amber-200";
  if (priority === 3) return "bg-blue-50 text-blue-800 border-blue-200";
  return "bg-slate-100 text-slate-600 border-slate-200";
}

function lifecycleBadgeClass(status?: string): string {
  switch (status) {
    case "Decided": return "bg-green-50 text-green-800 border-green-200";
    case "Expired": return "bg-red-50 text-red-800 border-red-200";
    case "Pending": return "bg-amber-50 text-amber-800 border-amber-200";
    default:        return "bg-slate-100 text-slate-600 border-slate-200";
  }
}

function escalationBadgeClass(days?: number | null): string {
  if (days === null || days === undefined) return "bg-slate-100 text-slate-500 border-slate-200";
  if (days <= 0) return "bg-red-50 text-red-800 border-red-200";
  if (days <= 3) return "bg-amber-50 text-amber-800 border-amber-200";
  if (days <= 7) return "bg-blue-50 text-blue-800 border-blue-200";
  return "bg-slate-100 text-slate-600 border-slate-200";
}

function escalationLabel(days?: number | null): string {
  if (days === null || days === undefined) return "n/a";
  if (days <= 0) return "escalate today";
  if (days === 1) return "escalate in 1 day";
  return `escalate in ${days} days`;
}

function outcomeQualityBadgeClass(q?: string): string {
  switch (q) {
    case "High":    return "bg-green-50 text-green-800 border-green-200";
    case "Medium":  return "bg-blue-50 text-blue-800 border-blue-200";
    case "Low":     return "bg-amber-50 text-amber-800 border-amber-200";
    default:        return "bg-slate-100 text-slate-500 border-slate-200";
  }
}

function rankingScoreBadgeClass(score?: number): string {
  if (typeof score !== "number" || score === 0) return "bg-slate-100 text-slate-500 border-slate-200";
  if (score > 0) return "bg-green-50 text-green-800 border-green-200";
  return "bg-amber-50 text-amber-800 border-amber-200";
}

function confidenceLabel(confidence?: number): string {
  if (typeof confidence !== "number") return "n/a";
  if (confidence >= 0.7) return "High";
  if (confidence >= 0.4) return "Medium";
  return "Low";
}

function safeJsonParse<T>(raw: string | undefined): T | null {
  if (!raw || !raw.trim()) return null;
  try {
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

const FOCUS_SECTIONS: FocusSection[] = ["P1 Focus", "P2 Focus", "Watch List", "Parking Lot"];

function parseCurrentFocusMarkdown(markdown: string): CurrentFocusFromMd | null {
  if (!markdown.trim()) return null;

  const md = markdown.replace(/\r\n/g, "\n");

  const generated = md.match(/Generated:\s*\*\*(.+?)\*\*/)?.[1]?.trim() ?? "";
  const version = md.match(/Generated:.*?·\s*([^\n]+)/)?.[1]?.trim() ?? "";

  const executiveSummaryBlock = md.match(/## Executive Summary\s+([\s\S]*?)(?=\n---|\n## )/);
  const executiveSummary = executiveSummaryBlock?.[1]
    ?.replace(/\*\*/g, "")
    .replace(/\n+/g, " ")
    .trim() ?? "";

  const sections: Record<FocusSection, CurrentFocusItem[]> = {
    "P1 Focus": [],
    "P2 Focus": [],
    "Watch List": [],
    "Parking Lot": [],
  };

  const sectionRegex = /## (P1 Focus|P2 Focus|Watch List|Parking Lot)\n([\s\S]*?)(?=\n## |\n---|$)/g;
  let sectionMatch: RegExpExecArray | null;

  while ((sectionMatch = sectionRegex.exec(md)) !== null) {
    const sectionName = sectionMatch[1] as FocusSection;
    const sectionContent = sectionMatch[2] ?? "";
    const itemRegex = /### ([^\n]+)\n([\s\S]*?)(?=\n### |$)/g;
    let itemMatch: RegExpExecArray | null;

    while ((itemMatch = itemRegex.exec(sectionContent)) !== null) {
      const name = itemMatch[1].trim();
      const body = itemMatch[2] ?? "";
      const statusLine = body.match(/\*\*Status:\*\*\s*([^\n]+)/)?.[1] ?? "";
      const status = statusLine.match(/^([^\s]+)/)?.[1] ?? "";
      const score = Number(statusLine.match(/\*\*Score:\*\*\s*([0-9.]+)/)?.[1] ?? 0);
      const overrideDetail = statusLine.match(/\*\*Override:\*\*\s*(.+)/)?.[1]?.trim() ?? "";
      const mentions = Number(body.match(/\*\*Mentions:\*\*\s*([0-9]+)/)?.[1] ?? "");
      const signals = body.match(/\*\*Signals:\*\*\s*([^\n]+)/)?.[1]?.trim() ?? "";

      const summary = body
        .match(/\*\*Signals:\*\*[^\n]*\n\n([\s\S]*?)\n\n\*\*Evidence:\*\*/)?.[1]
        ?.replace(/\n+/g, " ")
        .trim() ?? "";

      const evidenceBlock = body.match(/\*\*Evidence:\*\*\n([\s\S]*?)\n\n\*\*Recommended next action:\*\*/)?.[1] ?? "";
      const evidence = evidenceBlock
        .split("\n")
        .map((line) => line.replace(/^-\s+`?/, "").replace(/`$/, "").trim())
        .filter(Boolean);

      const recommendedAction = body
        .match(/\*\*Recommended next action:\*\*\n-\s*(.+)/)?.[1]
        ?.trim() ?? "";

      sections[sectionName].push({
        name,
        status,
        score,
        overrideDetail,
        mentions: Number.isFinite(mentions) ? mentions : null,
        signals,
        summary,
        recommendedAction,
        evidence,
      });
    }
  }

  return { generated, version, executiveSummary, sections };
}

type TabId = "dashboard" | "objectives" | "keyresults" | "tasks" | "weekly" | "export";

interface Props {
  onNavigate: (tab: TabId, filter?: NavFilter) => void;
}

type SectionId = "objectives" | "keyresults" | "open" | "closed" | "decisions" | "teams" | "systems";

export function DashboardTab({ onNavigate }: Props) {
  const { data } = usePMData();
  const [expandedSection, setExpandedSection] = useState<SectionId | null>(null);
  const [expandedFocusSections, setExpandedFocusSections] = useState<Record<FocusSection, boolean>>({
    "P1 Focus": true,
    "P2 Focus": false,
    "Watch List": false,
    "Parking Lot": false,
  });

  if (!data) return null;

  const tier1 = data.objectives.filter((o) => o.tier === 1);
  const tier2 = data.objectives.filter((o) => o.tier === 2);
  const totalObjectives = tier1.length + tier2.length;
  const openTasks = data.tasks.filter(
    (t) => t.status.toLowerCase() === "open"
  );
  const closedTasks = data.tasks.filter(
    (t) => t.status.toLowerCase() !== "open"
  );
  const latestWeekly = data.weeklySummaries[0];
  const focusMarkdown = data.rawFiles["00-context/generated/current-focus.md"];
  const currentFocus = focusMarkdown ? parseCurrentFocusMarkdown(focusMarkdown) : null;

  // V1.2/V1.3/V1.4: JSON enrichment (safe if any file is missing)
  const focusJson    = safeJsonParse<{ workstreams?: FocusJsonItem[]; version?: string; generated?: string }>(
    data.rawFiles["00-context/generated/current-focus.json"]
  );
  const trendsJson   = safeJsonParse<TrendJson>(data.rawFiles["00-context/generated/current-focus-trends.json"]);
  const briefingJson = safeJsonParse<BriefingJson>(data.rawFiles["00-context/generated/morning-briefing.json"]);
  const pipelineHealth = safeJsonParse<PipelineHealth>(data.rawFiles["00-context/generated/pipeline-health.json"]);
  const decisionRegistry = safeJsonParse<DecisionRegistry>(data.rawFiles["00-context/generated/decision-registry.json"]);
  const riskRegistry = safeJsonParse<RiskRegistry>(data.rawFiles["00-context/generated/risk-register.json"]);
  const davidInbox   = safeJsonParse<DavidInbox>(data.rawFiles["00-context/generated/david-inbox.json"]);
  const executionInsights = safeJsonParse<ExecutionInsights>(data.rawFiles["00-context/generated/execution-insights.json"]);

  // Merge JSON enrichment into markdown-derived items by name
  if (currentFocus && focusJson?.workstreams?.length) {
    const jsonByName = new Map<string, FocusJsonItem>();
    for (const w of focusJson.workstreams) {
      if (w?.name) jsonByName.set(w.name, w);
    }
    for (const section of FOCUS_SECTIONS) {
      for (const item of currentFocus.sections[section]) {
        const j = jsonByName.get(item.name);
        if (!j) continue;
        item.attentionScore   = j.attention_score ?? j.score;
        item.activityScore    = j.activity_score;
        item.strategicScore   = j.strategic_score;
        item.strategicWeight  = j.strategic_weight;
        item.trendSymbol      = j.trend_symbol;
        item.trendDirection   = j.trend_direction;
        item.deltaPercent     = j.trend_delta_percent;
        item.overrideApplied  = j.override_applied;
        item.health           = j.health;
        if ((!item.evidence || item.evidence.length === 0) && j.evidence_files?.length) {
          item.evidence = j.evidence_files;
        }
      }
    }
  }

  // Flatten teams (top-level + sub-teams)
  const allTeams = data.teams.flatMap((t) => [t, ...(t.subTeams || [])]);

  const toggle = (id: SectionId) =>
    setExpandedSection((prev) => (prev === id ? null : id));

  const toggleFocusSection = (section: FocusSection) => {
    setExpandedFocusSections((prev) => ({ ...prev, [section]: !prev[section] }));
  };

  const cards: {
    id: SectionId;
    label: string;
    value: number;
    icon: string;
    color: string;
    hasTab: boolean;
    tabAction?: () => void;
  }[] = [
    {
      id: "objectives",
      label: "Objectives",
      value: totalObjectives,
      icon: "🎯",
      color: "bg-blue-50 text-blue-700 border-blue-200",
      hasTab: true,
      tabAction: () => onNavigate("objectives"),
    },
    {
      id: "keyresults",
      label: "Key Results",
      value: data.keyResults.length,
      icon: "📈",
      color: "bg-purple-50 text-purple-700 border-purple-200",
      hasTab: true,
      tabAction: () => onNavigate("keyresults"),
    },
    {
      id: "open",
      label: "Open Tasks",
      value: openTasks.length,
      icon: "✅",
      color: "bg-green-50 text-green-700 border-green-200",
      hasTab: true,
      tabAction: () => onNavigate("tasks", { status: "Open" }),
    },
    {
      id: "closed",
      label: "Closed Tasks",
      value: closedTasks.length,
      icon: "☑️",
      color: "bg-gray-50 text-gray-600 border-gray-200",
      hasTab: true,
      tabAction: () => onNavigate("tasks", { status: "Closed" }),
    },
    {
      id: "decisions",
      label: "Decisions",
      value: data.decisions.length,
      icon: "⚖️",
      color: "bg-amber-50 text-amber-700 border-amber-200",
      hasTab: false,
    },
    {
      id: "teams",
      label: "Teams",
      value: allTeams.length,
      icon: "👥",
      color: "bg-teal-50 text-teal-700 border-teal-200",
      hasTab: false,
    },
    {
      id: "systems",
      label: "Systems of Record",
      value: data.systems.length,
      icon: "🖥️",
      color: "bg-rose-50 text-rose-700 border-rose-200",
      hasTab: false,
    },
  ];

  return (
    <div className="p-6 max-w-5xl mx-auto space-y-6">
      <h2 className="text-xl font-bold text-th-text">Dashboard</h2>

      {/* Stat cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 xl:grid-cols-7 gap-3">
        {cards.map((c) => (
          <button
            key={c.id}
            onClick={() => toggle(c.id)}
            className={`rounded-xl border p-4 text-left w-full cursor-pointer hover:shadow-md hover:scale-[1.02] transition-all ${c.color} ${expandedSection === c.id ? "ring-2 ring-offset-1 ring-current" : ""}`}
          >
            <div className="text-2xl mb-1">{c.icon}</div>
            <div className="text-3xl font-bold">{c.value}</div>
            <div className="text-sm mt-1 opacity-80">{c.label}</div>
            <div className="text-xs mt-2 opacity-50">
              {expandedSection === c.id ? "▼ collapse" : "▶ expand"}
            </div>
          </button>
        ))}
      </div>

      {/* Expanded detail section */}
      {expandedSection && (
        <div className="rounded-xl border border-th-border bg-th-surface overflow-hidden">
          {/* Header with optional tab link */}
          <div className="flex items-center justify-between px-4 py-3 bg-th-surface-alt border-b border-th-border">
            <h3 className="font-semibold text-th-text-secondary">
              {cards.find((c) => c.id === expandedSection)?.icon}{" "}
              {cards.find((c) => c.id === expandedSection)?.label}
            </h3>
            <div className="flex items-center gap-3">
              {cards.find((c) => c.id === expandedSection)?.hasTab && (
                <button
                  onClick={() => cards.find((c) => c.id === expandedSection)?.tabAction?.()}
                  className="text-xs text-th-accent hover:text-th-accent-hover font-medium cursor-pointer"
                >
                  Open in tab →
                </button>
              )}
              <button
                onClick={() => setExpandedSection(null)}
                className="text-xs text-th-text-faint hover:text-th-text-muted cursor-pointer"
              >
                ✕
              </button>
            </div>
          </div>

          <div className="p-4 max-h-96 overflow-auto">
            {/* Combined Objectives */}
            {expandedSection === "objectives" && (
              <div className="space-y-3">
                <div className="flex gap-3 text-xs text-gray-500 mb-2">
                  <span className="bg-blue-100 text-blue-700 rounded-full px-2 py-0.5 font-medium">{tier1.length} Tier-1</span>
                  <span className="bg-indigo-100 text-indigo-700 rounded-full px-2 py-0.5 font-medium">{tier2.length} Tier-2</span>
                </div>
                {tier1.map((o) => {
                  const children = tier2.filter((t2) => t2.parentObjectiveIds.includes(o.id));
                  return (
                    <div key={o.id} className="rounded-lg border border-th-border overflow-hidden">
                      <div className="flex items-start gap-3 p-2 bg-th-accent-light">
                        <span className="font-mono text-xs font-bold text-th-accent bg-th-accent-light rounded px-1.5 py-0.5 shrink-0">
                          {o.id}
                        </span>
                        <div className="min-w-0">
                          <div className="text-sm font-medium text-th-text">{o.title}</div>
                          <p className="text-xs text-th-text-muted mt-0.5 line-clamp-2">{o.description}</p>
                        </div>
                      </div>
                      {children.length > 0 && (
                        <div className="border-t border-th-border bg-th-surface">
                          {children.map((c) => (
                            <div key={c.id} className="flex items-start gap-3 p-2 pl-8 hover:bg-th-surface-alt border-b border-th-border/30 last:border-b-0">
                              <span className="font-mono text-xs font-bold text-indigo-500 bg-indigo-500/10 rounded px-1.5 py-0.5 shrink-0">
                                {c.id}
                              </span>
                              <div className="min-w-0">
                                <div className="text-sm font-medium text-th-text-secondary">{c.title}</div>
                                {c.ownerSection && (
                                  <span className="text-[10px] text-th-text-faint">👤 {c.ownerSection}</span>
                                )}
                              </div>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            )}

            {/* Open Tasks */}
            {expandedSection === "open" && (
              <div className="space-y-2">
                {openTasks.length === 0 && <p className="text-sm text-th-text-faint italic">No open tasks.</p>}
                {openTasks.map((t) => (
                  <div key={t.id} className="flex items-start gap-3 p-2 rounded-lg hover:bg-th-surface-alt">
                    <span className="font-mono text-xs font-bold text-th-success bg-th-success-light rounded px-1.5 py-0.5 shrink-0">
                      {t.id}
                    </span>
                    <div className="min-w-0">
                      <div className="text-sm font-medium text-th-text">{t.title}</div>
                      <div className="flex flex-wrap gap-2 mt-1 text-xs text-th-text-muted">
                        {t.assigned && <span>👤 {t.assigned}</span>}
                        {t.team && <span>👥 {t.team}</span>}
                        {t.created && <span>📅 {t.created}</span>}
                      </div>
                      {t.objectiveIds.length > 0 && (
                        <div className="flex gap-1 mt-1">
                          <span className="text-[10px] text-th-text-faint">Objectives:</span>
                          {t.objectiveIds.map((oid) => (
                            <span key={oid} className="text-[10px] font-mono bg-th-accent-light text-th-accent-text rounded px-1">{oid}</span>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* Closed Tasks */}
            {expandedSection === "closed" && (
              <div className="space-y-2">
                {closedTasks.length === 0 && <p className="text-sm text-th-text-faint italic">No closed tasks.</p>}
                {closedTasks.map((t) => (
                  <div key={t.id} className="flex items-start gap-3 p-2 rounded-lg hover:bg-th-surface-alt">
                    <span className="font-mono text-xs font-bold text-th-text-muted bg-th-surface-alt rounded px-1.5 py-0.5 shrink-0">
                      {t.id}
                    </span>
                    <div className="min-w-0">
                      <div className="text-sm font-medium text-th-text">{t.title}</div>
                      <div className="flex flex-wrap gap-2 mt-1 text-xs text-th-text-muted">
                        <span className="bg-th-surface-alt rounded px-1.5 py-0.5">{t.status}</span>
                        {t.assigned && <span>👤 {t.assigned}</span>}
                        {t.created && <span>📅 {t.created}</span>}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* Decisions */}
            {expandedSection === "decisions" && (
              <div className="space-y-2">
                {data.decisions.length === 0 && <p className="text-sm text-th-text-faint italic">No decisions recorded.</p>}
                {data.decisions.map((d) => (
                  <div key={d.id} className="p-2 rounded-lg hover:bg-th-surface-alt">
                    <div className="flex items-center gap-2">
                      <span className="font-mono text-xs font-bold text-th-warn bg-th-warn-light rounded px-1.5 py-0.5 shrink-0">
                        {d.id}
                      </span>
                      <span className="text-sm font-medium text-th-text">{d.title}</span>
                      {d.date && <span className="text-xs text-th-text-faint ml-auto">{d.date}</span>}
                    </div>
                    {d.decision && (
                      <p className="text-xs text-th-text-secondary mt-1 ml-10"><span className="font-medium">Decision:</span> {d.decision}</p>
                    )}
                    {d.reason && (
                      <p className="text-xs text-th-text-muted mt-0.5 ml-10"><span className="font-medium">Reason:</span> {d.reason}</p>
                    )}
                    {d.tags.length > 0 && (
                      <div className="flex gap-1 mt-1 ml-10">
                        {d.tags.map((tag) => (
                          <span key={tag} className="text-[10px] bg-th-surface-alt text-th-text-muted rounded px-1.5 py-0.5">{tag}</span>
                        ))}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}

            {/* Teams */}
            {expandedSection === "teams" && (
              <table className="w-full text-sm">
                <thead>
                  <tr className="text-left text-xs text-th-text-faint border-b border-th-border">
                    <th className="pb-2 font-medium">Team</th>
                    <th className="pb-2 font-medium">Lead</th>
                    <th className="pb-2 font-medium text-center">Members</th>
                    <th className="pb-2 font-medium">Reports to</th>
                  </tr>
                </thead>
                <tbody>
                  {data.teams.map((team) => (
                    <React.Fragment key={team.name}>
                      <tr className="border-b border-th-border/30 hover:bg-th-surface-alt">
                        <td className="py-2 font-semibold text-th-text">{team.name}</td>
                        <td className="py-2 text-th-text-secondary">{team.lead}</td>
                        <td className="py-2 text-center text-th-text-muted">{team.members?.length ?? "—"}</td>
                        <td className="py-2 text-th-text-faint text-xs">{team.reportsTo ?? "—"}</td>
                      </tr>
                      {team.subTeams && team.subTeams.map((sub) => (
                        <tr key={sub.name} className="border-b border-th-border/30 hover:bg-th-surface-alt">
                          <td className="py-1.5 pl-5 text-th-text-secondary">
                            <span className="text-th-text-faint mr-1">└</span>{sub.name}
                          </td>
                          <td className="py-1.5 text-th-text-secondary">{sub.lead}</td>
                          <td className="py-1.5 text-center text-th-text-muted">{sub.members?.length ?? "—"}</td>
                          <td className="py-1.5 text-th-text-faint text-xs">{sub.reportsTo ?? "—"}</td>
                        </tr>
                      ))}
                    </React.Fragment>
                  ))}
                </tbody>
              </table>
            )}

            {/* Systems */}
            {expandedSection === "systems" && (
              <div className="space-y-1">
                {data.systems.map((s) => (
                  <div key={s.tag} className="flex items-center gap-3 p-2 rounded-lg hover:bg-th-surface-alt">
                    <span className="text-xs font-mono font-bold text-th-danger bg-th-danger-light rounded px-2 py-0.5 shrink-0 whitespace-nowrap">
                      {s.tag}
                    </span>
                    <div className="min-w-0">
                      <span className="text-sm font-medium text-th-text">{s.name}</span>
                      <span className="text-xs text-th-text-faint ml-2">— {s.purpose}</span>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* Key Results */}
            {expandedSection === "keyresults" && (
              <div className="space-y-2">
                {data.keyResults.length === 0 && <p className="text-sm text-th-text-faint italic">No key results registered.</p>}
                {data.keyResults.map((kr) => {
                  const progress = computeKRProgress(kr);
                  const progressColor =
                    progress >= 75 ? "bg-green-500" :
                    progress >= 50 ? "bg-yellow-500" :
                    progress >= 25 ? "bg-orange-500" : "bg-red-500";
                  const statusColor: Record<string, string> = {
                    "Not Started": "bg-gray-100 text-gray-600",
                    "On Track": "bg-green-100 text-green-700",
                    "At Risk": "bg-yellow-100 text-yellow-700",
                    "Behind": "bg-red-100 text-red-700",
                    "Complete": "bg-blue-100 text-blue-700",
                  };
                  const obj = data.objectives.find((o) => o.id === kr.objectiveId);
                  return (
                    <div key={kr.id} className="p-2 rounded-lg hover:bg-th-surface-alt">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="font-mono text-xs font-bold text-purple-700 bg-purple-100 rounded px-1.5 py-0.5 shrink-0">
                          {kr.id}
                        </span>
                        <span className="text-sm font-medium text-th-text">{kr.title}</span>
                        <span className={`text-[10px] font-medium rounded-full px-2 py-0.5 ml-auto shrink-0 ${statusColor[kr.status] || "bg-gray-100 text-gray-600"}`}>
                          {kr.status}
                        </span>
                      </div>
                      <div className="flex items-center gap-2 ml-10">
                        <div className="flex-1 bg-th-surface-alt rounded-full h-2">
                          <div className={`h-2 rounded-full transition-all ${progressColor}`} style={{ width: `${Math.min(progress, 100)}%` }} />
                        </div>
                        <span className="text-xs text-th-text-muted w-10 text-right">{progress}%</span>
                      </div>
                      <div className="flex flex-wrap gap-3 mt-1 ml-10 text-xs text-th-text-muted">
                        <span>🎯 {kr.objectiveId}{obj ? ` — ${obj.title}` : ""}</span>
                        <span>📅 {kr.targetDate || "—"}</span>
                        <span>{kr.metricType === "boolean" ? "☑️ Boolean" : `📊 ${kr.currentValue} / ${kr.targetValue}`}</span>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      )}

      {/* David's Priority Inbox (V2.5) - highest signal card, top of page */}
      <div className="rounded-xl border-2 border-red-200 bg-red-50/30 p-4">
        <div className="flex items-baseline justify-between mb-2">
          <h3 className="font-semibold text-th-text-secondary">
            David&apos;s Priority Inbox
            {davidInbox?.version && (
              <span className="ml-2 text-[11px] font-mono text-th-text-faint">{davidInbox.version}</span>
            )}
          </h3>
          {davidInbox?.generated && (
            <span className="text-xs text-th-text-faint">Generated {davidInbox.generated}</span>
          )}
        </div>
        {davidInbox && (davidInbox.tiers || davidInbox.items?.length) ? (
          (() => {
            const p1Items = davidInbox.tiers?.p1 ?? (davidInbox.items ?? []).filter((i) => i.priority === 1);
            const p2Items = davidInbox.tiers?.p2 ?? (davidInbox.items ?? []).filter((i) => i.priority === 2);
            const p3Items = davidInbox.tiers?.p3 ?? (davidInbox.items ?? []).filter((i) => i.priority === 3);
            const p1Cap = davidInbox.caps?.p1 ?? 5;
            const p2Cap = davidInbox.caps?.p2 ?? 10;
            const p3Cap = davidInbox.caps?.p3 ?? 10;
            const clusters = davidInbox.clusters ?? [];
            const imminent = davidInbox.totals?.imminentEscalation ?? 0;

            const renderItem = (it: InboxItem, idx: number) => (
              <div key={it.id ?? `${it.kind}-${idx}`} className="rounded-md border border-th-border bg-th-surface p-2">
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <div className="text-sm font-medium text-th-text break-words">
                      {it.verb ? <span className="font-semibold">{it.verb}: </span> : null}
                      {it.title ?? "(no title)"}
                    </div>
                    <div className="mt-0.5 text-xs text-th-text-muted">
                      <span className="uppercase font-mono mr-2">{it.kind}</span>
                      {it.workstream ? <span className="font-medium">{it.workstream}</span> : <span className="italic">no workstream</span>}
                      {it.id ? <span className="font-mono"> · {it.id}</span> : null}
                    </div>
                    <div className="mt-1 flex flex-wrap items-center gap-1 text-[11px]">
                      {it.owner ? (
                        <span className={`inline-block rounded-full border px-1.5 py-0.5 font-medium ${ownerBadgeClass(it.ownerConfidence)}`}>
                          owner: {it.owner}
                        </span>
                      ) : (
                        <span className="inline-block rounded-full border border-slate-200 bg-slate-100 px-1.5 py-0.5 font-medium text-slate-600">
                          owner: unassigned
                        </span>
                      )}
                      {it.decisionStatus && (
                        <span className={`inline-block rounded-full border px-1.5 py-0.5 font-medium ${lifecycleBadgeClass(it.decisionStatus)}`}>
                          {it.decisionStatus}
                        </span>
                      )}
                      {it.decisionRequired && (
                        <span className="inline-block rounded-full border border-red-200 bg-red-50 px-1.5 py-0.5 font-medium text-red-800">
                          DECISION REQUIRED
                        </span>
                      )}
                      {(it.timeToEscalationRisk !== undefined && it.timeToEscalationRisk !== null) && (
                        <span
                          className={`inline-block rounded-full border px-1.5 py-0.5 font-medium ${escalationBadgeClass(it.timeToEscalationRisk)}`}
                          title="Predicted days until this needs escalation"
                        >
                          {escalationLabel(it.timeToEscalationRisk)}
                        </span>
                      )}
                      {typeof it.confidence === "number" && (
                        <span className="inline-block rounded-full border border-th-border bg-th-surface-alt px-1.5 py-0.5 text-th-text-muted" title={`raw ${it.confidence.toFixed(2)}`}>
                          confidence: {confidenceLabel(it.confidence)} ({it.confidence.toFixed(2)})
                        </span>
                      )}
                      {typeof it.linkedActionCount === "number" && it.linkedActionCount > 0 && (
                        <span className="inline-block rounded-full border border-blue-200 bg-blue-50 px-1.5 py-0.5 font-medium text-blue-800" title="Linked follow-up actions">
                          {it.linkedActionCount} linked action{it.linkedActionCount === 1 ? "" : "s"}
                          {it.actionSource === "inferred" && <span className="ml-1 text-[10px] opacity-75">(inferred)</span>}
                          {it.actionSource === "marker" && <span className="ml-1 text-[10px] opacity-75">(marker)</span>}
                        </span>
                      )}
                      {typeof it.recurrenceCount === "number" && it.recurrenceCount >= 2 && (
                        <span className="inline-block rounded-full border border-amber-200 bg-amber-50 px-1.5 py-0.5 font-medium text-amber-800" title="Same question has resurfaced">
                          recurring {it.recurrenceCount}x
                        </span>
                      )}
                      {typeof it.rankingScore === "number" && it.rankingScore !== 0 && (
                        <span
                          className={`inline-block rounded-full border px-1.5 py-0.5 font-mono font-medium ${rankingScoreBadgeClass(it.rankingScore)}`}
                          title={(it.personalizationSignals ?? [])
                            .map((s) => `${s.source} ${s.delta && s.delta > 0 ? "+" : ""}${s.delta}: ${s.reason}`)
                            .join("\n") || "Ranking adjustment applied"}
                        >
                          {it.rankingScore > 0 ? "+" : ""}
                          {it.rankingScore.toFixed(2)}
                        </span>
                      )}
                    </div>
                  </div>
                  <div className="flex flex-col items-end gap-1 shrink-0 text-xs tabular-nums">
                    <span className={`inline-block rounded-full border px-2 py-0.5 font-mono ${priorityBadgeClass(it.priority)}`}>
                      P{it.priority ?? "?"}
                    </span>
                    <span className="text-th-text-muted">by {it.deadline || it.dueBy || "-"}</span>
                    {typeof it.ageDays === "number" && (
                      <span className="text-th-text-faint">aging {it.ageDays}d</span>
                    )}
                  </div>
                </div>
                {it.decisionOutcome && (
                  <p className="mt-1 text-xs text-th-text-secondary">
                    <span className="font-medium">Outcome: </span>{it.decisionOutcome}
                  </p>
                )}
                {it.rationale && (
                  <p className="mt-1 text-xs text-th-text-secondary">
                    <span className="font-medium">Why: </span>{it.rationale}
                  </p>
                )}
                {it.impact && (
                  <p className="mt-1 text-xs text-th-text-secondary">
                    <span className="font-medium">Impact: </span>{it.impact}
                  </p>
                )}
              </div>
            );

            const renderTier = (label: string, cap: number, items: InboxItem[], borderClass: string) => (
              <div className={`rounded-md border ${borderClass} bg-th-surface/50 p-2`}>
                <div className="mb-2 flex items-baseline gap-2 text-xs text-th-text-secondary">
                  <strong>{label}</strong>
                  <span className="text-th-text-faint">
                    ({items.length} shown / cap {cap})
                  </span>
                </div>
                {items.length ? (
                  <div className="space-y-2">{items.map((it, idx) => renderItem(it, idx))}</div>
                ) : (
                  <p className="text-xs italic text-th-text-faint">No items in this tier.</p>
                )}
              </div>
            );

            return (
              <div className="space-y-3">
                <div className="flex flex-wrap items-center gap-2 text-xs">
                  <span className="inline-block rounded-full border border-th-border bg-th-surface-alt px-2 py-0.5 text-th-text-secondary">
                    Candidates: <strong>{davidInbox.totals?.candidates ?? 0}</strong>
                  </span>
                  <span className="inline-block rounded-full border border-th-border bg-th-surface-alt px-2 py-0.5 text-th-text-secondary">
                    Selected: <strong>{davidInbox.totals?.selected ?? 0}</strong>
                  </span>
                  {(davidInbox.totals?.byPriority?.p1 ?? 0) > 0 && (
                    <span className="inline-block rounded-full border border-red-200 bg-red-50 px-2 py-0.5 text-red-800">
                      P1: <strong>{davidInbox.totals?.byPriority?.p1 ?? 0}</strong>
                    </span>
                  )}
                  {(davidInbox.totals?.byPriority?.p2 ?? 0) > 0 && (
                    <span className="inline-block rounded-full border border-amber-200 bg-amber-50 px-2 py-0.5 text-amber-800">
                      P2: <strong>{davidInbox.totals?.byPriority?.p2 ?? 0}</strong>
                    </span>
                  )}
                  {(davidInbox.totals?.byPriority?.p3 ?? 0) > 0 && (
                    <span className="inline-block rounded-full border border-blue-200 bg-blue-50 px-2 py-0.5 text-blue-800">
                      P3: <strong>{davidInbox.totals?.byPriority?.p3 ?? 0}</strong>
                    </span>
                  )}
                  {imminent > 0 && (
                    <span className="inline-block rounded-full border border-red-200 bg-red-50 px-2 py-0.5 text-red-800" title="Items whose predicted escalation window is <= 3 days">
                      Imminent escalation: <strong>{imminent}</strong>
                    </span>
                  )}
                  {clusters.length > 0 && (
                    <span className="inline-block rounded-full border border-th-border bg-th-surface-alt px-2 py-0.5 text-th-text-secondary">
                      Clusters: <strong>{clusters.length}</strong>
                    </span>
                  )}
                </div>

                {renderTier("P1 - Escalate today", p1Cap, p1Items, "border-red-200")}
                {renderTier("P2 - Confirm or investigate this week", p2Cap, p2Items, "border-amber-200")}
                {renderTier("P3 - Review this week", p3Cap, p3Items, "border-blue-200")}

                {clusters.length > 0 && (
                  <div className="rounded-md border border-th-border bg-th-surface/60 p-2">
                    <div className="mb-2 text-xs font-semibold text-th-text-secondary">Clusters (workstream / theme)</div>
                    <div className="grid gap-1.5 md:grid-cols-2">
                      {clusters.slice(0, 12).map((c, idx) => (
                        <div
                          key={`${c.workstream ?? "(none)"}-${c.theme ?? "(misc)"}-${idx}`}
                          className="flex items-center justify-between gap-2 rounded border border-th-border bg-th-surface p-1.5 text-xs"
                        >
                          <div className="min-w-0">
                            <div className="font-medium text-th-text truncate">
                              {c.workstream || "(no workstream)"}
                              <span className="mx-1 text-th-text-faint">/</span>
                              <em className="text-th-text-muted">{c.theme || "(misc)"}</em>
                            </div>
                            <div className="text-[11px] text-th-text-faint">
                              {c.kinds?.join(" + ") || ""}
                            </div>
                          </div>
                          <div className="flex items-center gap-1 shrink-0">
                            <span className={`inline-block rounded-full border px-1.5 py-0.5 font-mono ${priorityBadgeClass(c.topPriority)}`}>
                              P{c.topPriority ?? "?"}
                            </span>
                            <span className="rounded border border-th-border bg-th-surface-alt px-1.5 py-0.5 text-th-text-secondary">
                              {c.itemCount ?? 0} items
                            </span>
                            {typeof c.p1Count === "number" && c.p1Count > 0 && (
                              <span className="rounded-full border border-red-200 bg-red-50 px-1.5 py-0.5 text-red-800">
                                {c.p1Count} P1
                              </span>
                            )}
                            {(c.minEscalationRisk !== undefined && c.minEscalationRisk !== null) && (
                              <span
                                className={`rounded-full border px-1.5 py-0.5 ${escalationBadgeClass(c.minEscalationRisk)}`}
                                title="Minimum days-to-escalation across the cluster"
                              >
                                {escalationLabel(c.minEscalationRisk)}
                              </span>
                            )}
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                <p className="text-xs text-th-text-faint">
                  Source: 00-context/generated/david-inbox.json - regenerated by scripts/generate-current-focus.ps1.
                </p>
              </div>
            );
          })()
        ) : (
          <p className="text-sm text-th-text-faint italic">
            Priority inbox not available. Regenerate to produce 00-context/generated/david-inbox.json.
          </p>
        )}
      </div>

      {/* Execution Insights (V3.0) - learning-loop signals feeding the inbox */}
      <div className="rounded-xl border border-blue-200 bg-blue-50/20 p-4">
        <div className="flex items-baseline justify-between mb-2">
          <h3 className="font-semibold text-th-text-secondary">
            Execution Insights
            {executionInsights?.version && (
              <span className="ml-2 text-[11px] font-mono text-th-text-faint">{executionInsights.version}</span>
            )}
          </h3>
          {executionInsights?.generated && (
            <span className="text-xs text-th-text-faint">Generated {executionInsights.generated}</span>
          )}
        </div>
        {executionInsights ? (
          (() => {
            const t = executionInsights.totals ?? {};
            const chip = (label: string, count: number, cls: string) => (
              <span className={`inline-block rounded-full border px-2 py-0.5 text-xs ${cls}`}>
                {label}: <strong>{count}</strong>
              </span>
            );

            return (
              <div className="space-y-3">
                <div className="flex flex-wrap items-center gap-2">
                  {chip("Delayed", t.delayedDecisions ?? 0, (t.delayedDecisions ?? 0) > 0 ? "border-red-200 bg-red-50 text-red-800" : "border-th-border bg-th-surface-alt text-th-text-secondary")}
                  {chip("Missed deadlines", t.missedDeadlines ?? 0, (t.missedDeadlines ?? 0) > 0 ? "border-red-200 bg-red-50 text-red-800" : "border-th-border bg-th-surface-alt text-th-text-secondary")}
                  {chip("Overloaded owners", t.overloadedOwners ?? 0, (t.overloadedOwners ?? 0) > 0 ? "border-amber-200 bg-amber-50 text-amber-800" : "border-th-border bg-th-surface-alt text-th-text-secondary")}
                  {chip("Recurring", t.recurringDecisions ?? 0, (t.recurringDecisions ?? 0) > 0 ? "border-amber-200 bg-amber-50 text-amber-800" : "border-th-border bg-th-surface-alt text-th-text-secondary")}
                  {chip("Stale WS", t.stalePendingByWorkstream ?? 0, (t.stalePendingByWorkstream ?? 0) > 0 ? "border-amber-200 bg-amber-50 text-amber-800" : "border-th-border bg-th-surface-alt text-th-text-secondary")}
                  {chip("High aged risks", t.highSeverityAgedRisks ?? 0, (t.highSeverityAgedRisks ?? 0) > 0 ? "border-red-200 bg-red-50 text-red-800" : "border-th-border bg-th-surface-alt text-th-text-secondary")}
                </div>

                <div className="grid gap-3 md:grid-cols-2">
                  {/* Overloaded owners */}
                  <div className="rounded-md border border-amber-200 bg-th-surface p-2">
                    <div className="mb-1 text-xs font-semibold text-amber-800">Overloaded owners</div>
                    {(executionInsights.overloadedOwners ?? []).length > 0 ? (
                      <ul className="space-y-1 text-xs">
                        {(executionInsights.overloadedOwners ?? []).slice(0, 6).map((o, i) => (
                          <li key={`ovl-${o.owner}-${i}`} className="flex items-center justify-between gap-2">
                            <span className="font-medium">{o.owner}</span>
                            <span className="text-th-text-muted">
                              {o.itemCount} items ({o.decisions}d / {o.risks}r, {o.p1Count} P1) · avg conf {o.avgConfidence}
                            </span>
                          </li>
                        ))}
                      </ul>
                    ) : (
                      <p className="text-xs italic text-th-text-faint">No owners over capacity.</p>
                    )}
                  </div>

                  {/* Delayed + missed */}
                  <div className="rounded-md border border-red-200 bg-th-surface p-2">
                    <div className="mb-1 text-xs font-semibold text-red-800">Delayed / missed</div>
                    {(executionInsights.delayedDecisions ?? []).length > 0 && (
                      <ul className="space-y-1 text-xs">
                        {(executionInsights.delayedDecisions ?? []).slice(0, 4).map((d, i) => (
                          <li key={`del-${d.id}-${i}`}>
                            <span className="text-red-800 font-mono mr-1">{d.ageDays}d</span>
                            <span className="font-medium">{d.title}</span>
                            <span className="text-th-text-faint"> · {d.owner}</span>
                          </li>
                        ))}
                      </ul>
                    )}
                    {(executionInsights.missedDeadlines ?? []).length > 0 && (
                      <ul className="mt-1 space-y-1 text-xs">
                        {(executionInsights.missedDeadlines ?? []).slice(0, 4).map((d, i) => (
                          <li key={`miss-${d.id}-${i}`}>
                            <span className="text-red-800 font-mono mr-1">{d.daysOverdue}d over</span>
                            <span className="font-medium">{d.title}</span>
                            <span className="text-th-text-faint"> · deadline {d.deadline}</span>
                          </li>
                        ))}
                      </ul>
                    )}
                    {(executionInsights.delayedDecisions ?? []).length === 0 && (executionInsights.missedDeadlines ?? []).length === 0 && (
                      <p className="text-xs italic text-th-text-faint">Nothing delayed or overdue.</p>
                    )}
                  </div>

                  {/* Recurring */}
                  <div className="rounded-md border border-amber-200 bg-th-surface p-2">
                    <div className="mb-1 text-xs font-semibold text-amber-800">Recurring decisions</div>
                    {(executionInsights.recurringDecisions ?? []).length > 0 ? (
                      <ul className="space-y-1 text-xs">
                        {(executionInsights.recurringDecisions ?? []).slice(0, 5).map((r, i) => (
                          <li key={`rec-${r.exampleId}-${i}`}>
                            <span className="text-amber-800 font-mono mr-1">{r.count}x</span>
                            <span className="font-medium">{r.exampleTitle}</span>
                            <span className="text-th-text-faint"> · {r.workstream || "(no workstream)"}</span>
                          </li>
                        ))}
                      </ul>
                    ) : (
                      <p className="text-xs italic text-th-text-faint">No decisions have resurfaced.</p>
                    )}
                  </div>

                  {/* High severity aged risks */}
                  <div className="rounded-md border border-red-200 bg-th-surface p-2">
                    <div className="mb-1 text-xs font-semibold text-red-800">High-severity aged risks</div>
                    {(executionInsights.highSeverityAgedRisks ?? []).length > 0 ? (
                      <ul className="space-y-1 text-xs">
                        {(executionInsights.highSeverityAgedRisks ?? []).slice(0, 5).map((r, i) => (
                          <li key={`har-${r.id}-${i}`}>
                            <span className="text-red-800 font-mono mr-1">{r.ageDays}d</span>
                            <span className="font-medium">{r.title}</span>
                            <span className="text-th-text-faint"> · {r.workstream} · {r.owner || "unassigned"}</span>
                          </li>
                        ))}
                      </ul>
                    ) : (
                      <p className="text-xs italic text-th-text-faint">No aged high-severity risks.</p>
                    )}
                  </div>
                </div>

                <p className="text-xs text-th-text-faint">
                  Source: 00-context/generated/execution-insights.json - feeds david-inbox.json ranking via 00-context/david-preferences.yaml.
                </p>
              </div>
            );
          })()
        ) : (
          <p className="text-sm text-th-text-faint italic">
            Execution insights not available. Regenerate to produce 00-context/generated/execution-insights.json.
          </p>
        )}
      </div>

      {/* Automation status */}
      <div className="rounded-xl border border-th-border bg-th-surface p-4">
        <h3 className="font-semibold text-th-text-secondary mb-2">Automation Status</h3>
        {pipelineHealth ? (
          (() => {
            const status = (pipelineHealth.status ?? "unknown").toLowerCase();
            const badgeClass =
              status === "success"
                ? "bg-green-100 text-green-800 border-green-200"
                : status === "no-op"
                ? "bg-blue-50 text-blue-800 border-blue-200"
                : status === "error"
                ? "bg-red-50 text-red-800 border-red-200"
                : "bg-slate-100 text-slate-700 border-slate-200";
            const shortHash = pipelineHealth.lastCommitHash
              ? pipelineHealth.lastCommitHash.slice(0, 7)
              : "-";
            return (
              <div className="space-y-2">
                <div className="flex flex-wrap items-center gap-2">
                  <span className={`inline-block rounded-full border px-2 py-0.5 text-xs font-medium ${badgeClass}`}>
                    {pipelineHealth.status ?? "unknown"}
                  </span>
                  {pipelineHealth.jsonValidated ? (
                    <span className="inline-block rounded-full border border-green-200 bg-green-50 px-2 py-0.5 text-[10px] font-medium text-green-700">
                      JSON validated
                    </span>
                  ) : (
                    <span className="inline-block rounded-full border border-slate-200 bg-slate-50 px-2 py-0.5 text-[10px] font-medium text-slate-500">
                      JSON not validated this run
                    </span>
                  )}
                  {pipelineHealth.gitCommitted && (
                    <span className="inline-block rounded-full border border-purple-200 bg-purple-50 px-2 py-0.5 text-[10px] font-medium text-purple-700">
                      Committed
                    </span>
                  )}
                </div>

                {pipelineHealth.message && (
                  <p className="text-sm text-th-text-secondary">{pipelineHealth.message}</p>
                )}

                <div className="grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-1 text-xs text-th-text-muted tabular-nums">
                  <div>
                    <span className="text-th-text-faint">Last run: </span>
                    <span className="text-th-text">{pipelineHealth.lastRun ?? "-"}</span>
                  </div>
                  <div>
                    <span className="text-th-text-faint">Last commit: </span>
                    <span className="font-mono text-th-text">{shortHash}</span>
                  </div>
                  <div className="break-all">
                    <span className="text-th-text-faint">Last activity recap: </span>
                    <span className="font-mono text-th-text">{pipelineHealth.lastActivityFile || "-"}</span>
                  </div>
                  <div>
                    <span className="text-th-text-faint">Artifacts: </span>
                    <span className="text-th-text">
                      focus:{pipelineHealth.currentFocusGenerated ? "✓" : "·"}
                      {" "}trends:{pipelineHealth.trendsGenerated ? "✓" : "·"}
                      {" "}briefing:{pipelineHealth.morningBriefingGenerated ? "✓" : "·"}
                    </span>
                  </div>
                </div>

                <p className="text-xs text-th-text-faint">
                  Source: 00-context/generated/pipeline-health.json - refreshed by scripts/run-matryoshka-pipeline.ps1.
                </p>
              </div>
            );
          })()
        ) : (
          <p className="text-sm text-th-text-faint italic">
            No pipeline health data. Run scripts/run-matryoshka-pipeline.ps1 to generate 00-context/generated/pipeline-health.json.
          </p>
        )}
      </div>

      {/* Latest weekly */}
      <div className="rounded-xl border border-th-border bg-th-surface p-4">
        <h3 className="font-semibold text-th-text-secondary mb-2">
          Latest Weekly Summary
        </h3>
        {latestWeekly ? (
          <div>
            <button
              onClick={() => onNavigate("weekly")}
              className="text-sm text-th-accent hover:text-th-accent-hover cursor-pointer"
            >
              📄 {latestWeekly.filename} →
            </button>
          </div>
        ) : (
          <p className="text-sm text-th-text-faint italic">
            No weekly summaries found in 03-reporting/weekly/
          </p>
        )}
      </div>

      {/* Warnings */}
      {data.warnings.length > 0 && (
        <div className="rounded-xl border border-th-warn bg-th-warn-light p-4">
          <h3 className="font-semibold text-th-warn mb-2">⚠️ Warnings</h3>
          <ul className="space-y-1">
            {data.warnings.map((w, i) => (
              <li key={i} className="text-sm text-th-warn">
                {w}
              </li>
            ))}
          </ul>
        </div>
      )}

      {/* Current focus */}
      <div className="rounded-xl border border-th-border bg-th-surface p-4">
        <h3 className="font-semibold text-th-text-secondary mb-2">Current Focus</h3>
        {currentFocus ? (
          <div className="space-y-3">
            <div className="text-xs text-th-text-faint">
              Generated {currentFocus.generated || "-"}
              {currentFocus.version ? ` ${currentFocus.version}` : ""}
            </div>

            {currentFocus.executiveSummary && (
              <div className="rounded-lg border border-th-border bg-th-surface-alt p-3">
                <h4 className="text-xs font-semibold uppercase tracking-wide text-th-text-faint mb-1">
                  Executive Summary
                </h4>
                <p className="text-sm text-th-text-secondary">{currentFocus.executiveSummary}</p>
              </div>
            )}

            <div className="space-y-2">
              {FOCUS_SECTIONS.map((section) => {
                const items = currentFocus.sections[section] ?? [];
                const isOpen = expandedFocusSections[section];
                return (
                  <div key={section} className="rounded-lg border border-th-border overflow-hidden">
                    <button
                      onClick={() => toggleFocusSection(section)}
                      className="w-full px-3 py-2 bg-th-surface-alt flex items-center justify-between text-left cursor-pointer"
                    >
                      <span className="text-sm font-semibold text-th-text-secondary">
                        {section}
                      </span>
                      <span className="text-xs text-th-text-faint">
                        {items.length} items {isOpen ? "▼" : "▶"}
                      </span>
                    </button>

                    {isOpen && (
                      <div className="p-3 space-y-2">
                        {items.length === 0 ? (
                          <p className="text-sm text-th-text-faint italic">No workstreams found.</p>
                        ) : (
                          items.map((item) => {
                            const hc = healthClass(item.health?.status);
                            return (
                            <div key={`${section}-${item.name}`} className={`rounded-md border border-th-border p-2 ${hc.stripe}`}>
                              <div className="flex items-center justify-between gap-3">
                                <div className="text-sm font-medium text-th-text">{item.name}</div>
                                <div className="flex items-center gap-2 text-xs">
                                  {item.health?.status && (
                                    <span className={`rounded-full border px-2 py-0.5 font-medium ${hc.badge}`} title={item.health.reason ?? ""}>
                                      {item.health.status}
                                    </span>
                                  )}
                                  <span className="rounded-full border border-th-border bg-th-surface-alt px-2 py-0.5 font-medium text-th-text-secondary">
                                    {item.status || section.replace(" Focus", "").replace(" List", "").replace(" Lot", "Lot")}
                                  </span>
                                  <span className="tabular-nums text-th-text">
                                    Attention: <strong>{(item.attentionScore ?? item.score).toFixed(1)}</strong>
                                  </span>
                                  {item.trendSymbol && (
                                    <span className="tabular-nums text-th-text-muted" title={item.trendDirection || ""}>
                                      {item.trendSymbol}{" "}
                                      {typeof item.deltaPercent === "number"
                                        ? `${item.deltaPercent > 0 ? "+" : ""}${item.deltaPercent.toFixed(1)}%`
                                        : ""}
                                    </span>
                                  )}
                                </div>
                              </div>

                              <div className="mt-1 flex flex-wrap gap-x-3 gap-y-1 text-xs text-th-text-muted tabular-nums">
                                <span>Activity: <strong>{item.activityScore != null ? item.activityScore.toFixed(1) : "-"}</strong></span>
                                <span>Strategic: <strong>{item.strategicScore != null ? item.strategicScore.toFixed(1) : "-"}</strong>{item.strategicWeight != null ? ` (${item.strategicWeight}/10)` : ""}</span>
                                <span>Override: <strong>{item.overrideApplied ? "Yes" : "No"}</strong></span>
                                <span>Mentions: {item.mentions ?? "-"}</span>
                              </div>

                              {item.health?.reason && (
                                <p className="mt-1 text-xs text-th-text-secondary">
                                  <span className="font-medium">Health: </span>{item.health.reason}
                                </p>
                              )}

                              {item.overrideDetail && item.overrideDetail !== "No" && (
                                <p className="mt-1 text-xs text-th-text-secondary">Override: {item.overrideDetail}</p>
                              )}

                              {item.summary && (
                                <p className="mt-1 text-xs text-th-text-secondary">{item.summary}</p>
                              )}

                              {item.recommendedAction && (
                                <p className="mt-1 text-xs text-th-text-secondary">Next: {item.recommendedAction}</p>
                              )}

                              {item.evidence.length > 0 && (
                                <p className="mt-1 text-xs text-th-text-faint break-all">
                                  Evidence: {item.evidence.slice(0, 3).join(", ")}
                                  {item.evidence.length > 3 ? ` (+${item.evidence.length - 3} more)` : ""}
                                </p>
                              )}
                            </div>
                            );
                          })
                        )}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>

            <p className="text-xs text-th-text-faint">
              Source: 00-context/generated/current-focus.md - do not hand-edit.
            </p>
          </div>
        ) : (
          <p className="text-sm text-th-text-faint italic">
            Current focus data not available. Generate 00-context/generated/current-focus.md to display this section.
          </p>
        )}
      </div>

      {/* Trends */}
      <div className="rounded-xl border border-th-border bg-th-surface p-4">
        <h3 className="font-semibold text-th-text-secondary mb-2">Trends</h3>
        {trendsJson?.workstreams?.length ? (
          <div className="space-y-2">
            <p className="text-xs text-th-text-faint">
              Comparing last {trendsJson.currentWindowDays ?? 14} days vs previous {trendsJson.previousWindowDays ?? 14} days.
              {trendsJson.generated ? ` Generated ${trendsJson.generated}.` : ""}
            </p>
            <div className="overflow-x-auto">
              <table className="w-full text-xs">
                <thead>
                  <tr className="text-left text-th-text-faint border-b border-th-border">
                    <th className="py-1 pr-3 font-medium">Workstream</th>
                    <th className="py-1 pr-3 font-medium text-right">Current</th>
                    <th className="py-1 pr-3 font-medium text-right">Previous</th>
                    <th className="py-1 pr-3 font-medium text-right">Delta %</th>
                    <th className="py-1 pr-3 font-medium">Trend</th>
                    <th className="py-1 font-medium">Reason</th>
                  </tr>
                </thead>
                <tbody>
                  {[...trendsJson.workstreams]
                    .sort((a, b) => (b.deltaPercent ?? 0) - (a.deltaPercent ?? 0))
                    .map((w) => (
                      <tr key={w.id ?? w.name} className="border-b border-th-border/40">
                        <td className="py-1 pr-3 text-th-text font-medium">{w.name}</td>
                        <td className="py-1 pr-3 text-right tabular-nums text-th-text-muted">{(w.currentActivityScore ?? 0).toFixed(2)}</td>
                        <td className="py-1 pr-3 text-right tabular-nums text-th-text-muted">{(w.previousActivityScore ?? 0).toFixed(2)}</td>
                        <td className="py-1 pr-3 text-right tabular-nums text-th-text-muted">
                          {typeof w.deltaPercent === "number"
                            ? `${w.deltaPercent > 0 ? "+" : ""}${w.deltaPercent.toFixed(1)}%`
                            : "-"}
                        </td>
                        <td className="py-1 pr-3 text-th-text">
                          <span className="mr-1">{w.trendSymbol ?? "-"}</span>
                          <span className="text-th-text-muted">{w.trendDirection ?? ""}</span>
                        </td>
                        <td className="py-1 text-th-text-muted">{w.trendReason ?? ""}</td>
                      </tr>
                    ))}
                </tbody>
              </table>
            </div>
            <p className="text-xs text-th-text-faint">
              Source: 00-context/generated/current-focus-trends.json - do not hand-edit.
            </p>
          </div>
        ) : (
          <p className="text-sm text-th-text-faint italic">
            Trend data not available. Regenerate to produce 00-context/generated/current-focus-trends.json.
          </p>
        )}
      </div>

      {/* Decision Watch */}
      <div className="rounded-xl border border-th-border bg-th-surface p-4">
        <h3 className="font-semibold text-th-text-secondary mb-2">Decision Watch</h3>
        {decisionRegistry?.decisions?.length ? (
          (() => {
            const decisions = decisionRegistry.decisions ?? [];
            const openDecisions = decisions.filter((d) => (d.status ?? "open") !== "closed");
            const closedDecisions = decisions.filter((d) => d.status === "closed");
            const oldestUnresolved = [...openDecisions]
              .sort((a, b) => (b.decisionAgeDays ?? 0) - (a.decisionAgeDays ?? 0))
              .slice(0, 6);
            const escalationCandidates = openDecisions.filter((d) => (d.decisionAgeDays ?? 0) >= 14);
            const recentlyClosed = [...closedDecisions]
              .sort((a, b) => (a.decisionAgeDays ?? 0) - (b.decisionAgeDays ?? 0))
              .slice(0, 5);

            const totals = decisionRegistry.totals ?? {};
            const openCount = totals.open ?? openDecisions.length;
            const closedCount = totals.closed ?? closedDecisions.length;
            const totalCount = totals.total ?? decisions.length;

            const renderEntry = (d: DecisionEntry) => {
              const actionText = formatAction(d.recommendedFollowUp);
              const actionPriority = typeof d.recommendedFollowUp === "object" ? d.recommendedFollowUp?.priority : undefined;
              const escalation = d.escalationPath ?? [];
              const linkedCount = d.linkedActions?.length ?? 0;
              return (
              <div key={d.decisionId ?? `${d.workstream}-${d.title}`} className="rounded-md border border-th-border p-2">
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <div className="text-sm font-medium text-th-text break-words">{d.title ?? "(no title)"}</div>
                    <div className="mt-0.5 text-xs text-th-text-muted">
                      {d.workstream ? <span className="font-medium">{d.workstream}</span> : <span className="italic">no workstream</span>}
                      {d.decisionId ? <span className="font-mono"> · {d.decisionId}</span> : null}
                    </div>
                    <div className="mt-1 flex flex-wrap items-center gap-1 text-[11px]">
                      {d.owner || d.ownerConfidence ? (
                        <span className={`inline-block rounded-full border px-1.5 py-0.5 font-medium ${ownerBadgeClass(d.ownerConfidence)}`} title={`ownerConfidence: ${d.ownerConfidence ?? "unknown"}`}>
                          owner: {d.owner || "unassigned"} · {d.ownerConfidence ?? "unknown"}
                        </span>
                      ) : null}
                      {d.decisionStatus ? (
                        <span className={`inline-block rounded-full border px-1.5 py-0.5 font-medium ${lifecycleBadgeClass(d.decisionStatus)}`} title="V2.5 lifecycle bucket">
                          {d.decisionStatus}
                        </span>
                      ) : null}
                      {d.decisionStatus === "Decided" && d.outcomeQuality ? (
                        <span className={`inline-block rounded-full border px-1.5 py-0.5 font-medium ${outcomeQualityBadgeClass(d.outcomeQuality)}`} title="V3.0 outcome quality">
                          quality: {d.outcomeQuality}
                        </span>
                      ) : null}
                      {typeof d.recurrenceCount === "number" && d.recurrenceCount >= 2 ? (
                        <span className="inline-block rounded-full border border-amber-200 bg-amber-50 px-1.5 py-0.5 font-medium text-amber-800" title="Same question has resurfaced">
                          recurring {d.recurrenceCount}x
                        </span>
                      ) : null}
                      {(d.timeToEscalationRisk !== undefined && d.timeToEscalationRisk !== null) ? (
                        <span className={`inline-block rounded-full border px-1.5 py-0.5 font-medium ${escalationBadgeClass(d.timeToEscalationRisk)}`}
                              title="Predicted days until escalation">
                          {escalationLabel(d.timeToEscalationRisk)}
                        </span>
                      ) : null}
                      {linkedCount > 0 ? (
                        <span className="inline-block rounded-full border border-blue-200 bg-blue-50 px-1.5 py-0.5 font-medium text-blue-800">
                          {linkedCount} linked action{linkedCount === 1 ? "" : "s"}
                        </span>
                      ) : null}
                      {escalation.length > 0 ? (
                        <span className="inline-block rounded-full border border-th-border bg-th-surface-alt px-1.5 py-0.5 text-th-text-muted">
                          escalate → {escalation.join(" → ")}
                        </span>
                      ) : null}
                      {d.firstSeenDate ? (
                        <span className="text-th-text-faint">first {d.firstSeenDate}</span>
                      ) : null}
                      {d.lastSeenDate ? (
                        <span className="text-th-text-faint">last {d.lastSeenDate}</span>
                      ) : null}
                    </div>
                  </div>
                  <div className="flex flex-col items-end gap-1 shrink-0 text-xs">
                    <span className={`inline-block rounded-full border px-2 py-0.5 font-medium ${
                      d.status === "closed"
                        ? "bg-slate-100 text-slate-600 border-slate-200"
                        : (d.decisionAgeDays ?? 0) >= 14
                          ? "bg-red-50 text-red-800 border-red-200"
                          : (d.decisionAgeDays ?? 0) >= 7
                            ? "bg-amber-50 text-amber-800 border-amber-200"
                            : "bg-blue-50 text-blue-800 border-blue-200"
                    }`}>
                      {d.status ?? "open"}
                    </span>
                    <span className="tabular-nums text-th-text-muted">
                      Pending {d.decisionAgeDays ?? 0} days
                    </span>
                    {actionPriority ? (
                      <span className={`inline-block rounded-full border px-1.5 py-0.5 font-mono ${
                        actionPriority === 1 ? "bg-red-50 text-red-800 border-red-200" :
                        actionPriority === 2 ? "bg-amber-50 text-amber-800 border-amber-200" :
                        "bg-slate-100 text-slate-600 border-slate-200"
                      }`}>P{actionPriority}</span>
                    ) : null}
                  </div>
                </div>
                {actionText && (
                  <p className="mt-1 text-xs text-th-text-secondary">
                    <span className="font-medium">Follow-up: </span>{actionText}
                  </p>
                )}
                {d.decisionOutcome && (
                  <p className="mt-1 text-xs text-th-text-secondary">
                    <span className="font-medium">Outcome: </span>{d.decisionOutcome}
                  </p>
                )}
                {d.linkedActions && d.linkedActions.length > 0 && (
                  <ul className="mt-1 ml-4 list-disc text-xs text-th-text-secondary space-y-0.5">
                    {d.linkedActions.map((la, i) => (
                      <li key={`${d.decisionId}-la-${i}`}>
                        <span className={`inline-block rounded border px-1 py-0 mr-1 text-[10px] font-mono ${
                          la.status === "completed" ? "border-green-200 bg-green-50 text-green-800" :
                          la.status === "in-progress" ? "border-blue-200 bg-blue-50 text-blue-800" :
                          la.status === "blocked" ? "border-red-200 bg-red-50 text-red-800" :
                          "border-slate-200 bg-slate-50 text-slate-700"
                        }`}>{la.status ?? "pending"}</span>
                        {la.actionSource === "inferred" && (
                          <span className="inline-block rounded border border-blue-200 bg-blue-50 px-1 py-0 mr-1 text-[10px] font-mono text-blue-800" title="Synthesized by V3.0 action inference">inferred</span>
                        )}
                        {la.text}
                        {la.owner ? <span className="text-th-text-faint"> · {la.owner}</span> : null}
                        {la.dueBy ? <span className="text-th-text-faint"> · due {la.dueBy}</span> : null}
                      </li>
                    ))}
                  </ul>
                )}
                {d.sourceFiles && d.sourceFiles.length > 0 && (
                  <p className="mt-1 text-xs text-th-text-faint break-all">
                    Sources: {d.sourceFiles.slice(0, 2).join(", ")}
                    {d.sourceFiles.length > 2 ? ` (+${d.sourceFiles.length - 2} more)` : ""}
                  </p>
                )}
              </div>
              );
            };

            return (
              <div className="space-y-3">
                <div className="flex flex-wrap items-center gap-2 text-xs">
                  <span className="inline-block rounded-full border border-th-border bg-th-surface-alt px-2 py-0.5 text-th-text-secondary">
                    Total: <strong>{totalCount}</strong>
                  </span>
                  <span className="inline-block rounded-full border border-blue-200 bg-blue-50 px-2 py-0.5 text-blue-800">
                    Open: <strong>{openCount}</strong>
                  </span>
                  <span className="inline-block rounded-full border border-slate-200 bg-slate-100 px-2 py-0.5 text-slate-700">
                    Closed: <strong>{closedCount}</strong>
                  </span>
                  {escalationCandidates.length > 0 && (
                    <span className="inline-block rounded-full border border-red-200 bg-red-50 px-2 py-0.5 text-red-800">
                      Escalate ({escalationCandidates.length}) 14+ days
                    </span>
                  )}
                  {(totals.lifecycle?.pending ?? 0) > 0 && (
                    <span className="inline-block rounded-full border border-amber-200 bg-amber-50 px-2 py-0.5 text-amber-800" title="V2.5 lifecycle: awaiting a decision">
                      Pending: <strong>{totals.lifecycle?.pending ?? 0}</strong>
                    </span>
                  )}
                  {(totals.lifecycle?.decided ?? 0) > 0 && (
                    <span className="inline-block rounded-full border border-green-200 bg-green-50 px-2 py-0.5 text-green-800" title="V2.5 lifecycle: outcome or completion recorded">
                      Decided: <strong>{totals.lifecycle?.decided ?? 0}</strong>
                    </span>
                  )}
                  {(totals.lifecycle?.expired ?? 0) > 0 && (
                    <span className="inline-block rounded-full border border-red-200 bg-red-50 px-2 py-0.5 text-red-800" title="V2.5 lifecycle: past deadline or aged out">
                      Expired: <strong>{totals.lifecycle?.expired ?? 0}</strong>
                    </span>
                  )}
                  {decisionRegistry.generated && (
                    <span className="ml-auto text-th-text-faint">Generated {decisionRegistry.generated}</span>
                  )}
                </div>

                {escalationCandidates.length > 0 && (
                  <div>
                    <h4 className="text-xs font-semibold uppercase tracking-wide text-red-700 mb-2">
                      Escalation Candidates (14+ days)
                    </h4>
                    <div className="space-y-2">
                      {escalationCandidates.slice(0, 6).map(renderEntry)}
                    </div>
                  </div>
                )}

                <div>
                  <h4 className="text-xs font-semibold uppercase tracking-wide text-th-text-faint mb-2">
                    Oldest Unresolved Decisions
                  </h4>
                  {oldestUnresolved.length > 0 ? (
                    <div className="space-y-2">
                      {oldestUnresolved.map(renderEntry)}
                    </div>
                  ) : (
                    <p className="text-xs text-th-text-faint italic">No unresolved decisions in the registry.</p>
                  )}
                </div>

                {recentlyClosed.length > 0 && (
                  <div>
                    <h4 className="text-xs font-semibold uppercase tracking-wide text-th-text-faint mb-2">
                      Recently Closed
                    </h4>
                    <div className="space-y-2">
                      {recentlyClosed.map(renderEntry)}
                    </div>
                  </div>
                )}

                <p className="text-xs text-th-text-faint">
                  Source: 00-context/generated/decision-registry.json - do not hand-edit.
                </p>
              </div>
            );
          })()
        ) : (
          <p className="text-sm text-th-text-faint italic">
            Decision registry not available. Regenerate to produce 00-context/generated/decision-registry.json.
          </p>
        )}
      </div>

      {/* Risk Watch */}
      <div className="rounded-xl border border-th-border bg-th-surface p-4">
        <h3 className="font-semibold text-th-text-secondary mb-2">Risk Watch</h3>
        {riskRegistry?.risks?.length ? (
          (() => {
            const risks = riskRegistry.risks ?? [];
            const openRisks = risks.filter((r) => (r.status ?? "open") !== "closed");
            const severityRank: Record<string, number> = { High: 0, Medium: 1, Low: 2 };
            const bySeverityAndAge = (a: RiskEntry, b: RiskEntry) => {
              const sa = severityRank[a.severity ?? "Medium"] ?? 1;
              const sb = severityRank[b.severity ?? "Medium"] ?? 1;
              if (sa !== sb) return sa - sb;
              return (b.agingDays ?? 0) - (a.agingDays ?? 0);
            };

            const highest = [...openRisks].sort(bySeverityAndAge).slice(0, 6);
            const growing = [...openRisks]
              .filter((r) => r.trend === "increasing")
              .sort((a, b) => (b.agingDays ?? 0) - (a.agingDays ?? 0))
              .slice(0, 6);
            const oldest = [...openRisks]
              .filter((r) => (r.agingDays ?? 0) >= 14)
              .sort((a, b) => (b.agingDays ?? 0) - (a.agingDays ?? 0))
              .slice(0, 6);
            const escalated = [...openRisks]
              .filter((r) => {
                if (r.severity === "High") return true;
                const act = r.recommendedAction;
                if (typeof act === "string") return act.toLowerCase().includes("escalate");
                if (act && typeof act === "object") {
                  return (act.verb ?? "").toLowerCase() === "escalate";
                }
                return false;
              })
              .sort(bySeverityAndAge)
              .slice(0, 6);

            const totals = riskRegistry.totals ?? {};
            const totalCount = totals.total ?? risks.length;
            const openCount = totals.open ?? openRisks.length;
            const highCount = totals.high ?? openRisks.filter((r) => r.severity === "High").length;
            const risingCount = totals.rising ?? openRisks.filter((r) => r.trend === "increasing").length;

            const severityBadge = (sev?: string) => {
              const cls =
                sev === "High"
                  ? "bg-red-50 text-red-800 border-red-200"
                  : sev === "Low"
                    ? "bg-slate-100 text-slate-600 border-slate-200"
                    : "bg-amber-50 text-amber-800 border-amber-200";
              return (
                <span className={`inline-block rounded-full border px-2 py-0.5 text-xs font-medium ${cls}`}>
                  {sev ?? "Medium"}
                </span>
              );
            };

            const trendGlyph = (trend?: string) => {
              if (trend === "increasing") return { symbol: "↑", label: "increasing", cls: "text-red-700" };
              if (trend === "decreasing") return { symbol: "↓", label: "decreasing", cls: "text-green-700" };
              return { symbol: "→", label: "stable", cls: "text-th-text-muted" };
            };

            const renderRisk = (r: RiskEntry) => {
              const t = trendGlyph(r.trend);
              const actionText = formatAction(r.recommendedAction);
              const actionPriority = typeof r.recommendedAction === "object" ? r.recommendedAction?.priority : undefined;
              const escalation = r.escalationPath ?? [];
              return (
                <div key={r.riskId ?? `${r.workstream}-${r.title}`} className="rounded-md border border-th-border p-2">
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0">
                      <div className="text-sm font-medium text-th-text break-words">{r.title ?? "(no title)"}</div>
                      <div className="mt-0.5 text-xs text-th-text-muted">
                        {r.workstream ? <span className="font-medium">{r.workstream}</span> : <span className="italic">no workstream</span>}
                        {r.riskId ? <span className="font-mono"> · {r.riskId}</span> : null}
                      </div>
                      <div className="mt-1 flex flex-wrap items-center gap-1 text-[11px]">
                        {r.owner || r.ownerConfidence ? (
                          <span className={`inline-block rounded-full border px-1.5 py-0.5 font-medium ${ownerBadgeClass(r.ownerConfidence)}`} title={`ownerConfidence: ${r.ownerConfidence ?? "unknown"}`}>
                            owner: {r.owner || "unassigned"} · {r.ownerConfidence ?? "unknown"}
                          </span>
                        ) : null}
                        {(r.timeToEscalationRisk !== undefined && r.timeToEscalationRisk !== null) ? (
                          <span className={`inline-block rounded-full border px-1.5 py-0.5 font-medium ${escalationBadgeClass(r.timeToEscalationRisk)}`}
                                title="Predicted days until escalation">
                            {escalationLabel(r.timeToEscalationRisk)}
                          </span>
                        ) : null}
                        {escalation.length > 0 ? (
                          <span className="inline-block rounded-full border border-th-border bg-th-surface-alt px-1.5 py-0.5 text-th-text-muted">
                            escalate → {escalation.join(" → ")}
                          </span>
                        ) : null}
                        {r.firstSeenDate ? (
                          <span className="text-th-text-faint">first {r.firstSeenDate}</span>
                        ) : null}
                        {r.lastSeenDate ? (
                          <span className="text-th-text-faint">last {r.lastSeenDate}</span>
                        ) : null}
                      </div>
                    </div>
                    <div className="flex flex-col items-end gap-1 shrink-0 text-xs">
                      {severityBadge(r.severity)}
                      <span className={`tabular-nums ${t.cls}`} title={t.label}>
                        {t.symbol} {t.label}
                      </span>
                      <span className="tabular-nums text-th-text-muted">
                        Aging {r.agingDays ?? 0}d
                      </span>
                      {actionPriority ? (
                        <span className={`inline-block rounded-full border px-1.5 py-0.5 font-mono ${
                          actionPriority === 1 ? "bg-red-50 text-red-800 border-red-200" :
                          actionPriority === 2 ? "bg-amber-50 text-amber-800 border-amber-200" :
                          "bg-slate-100 text-slate-600 border-slate-200"
                        }`}>P{actionPriority}</span>
                      ) : null}
                    </div>
                  </div>
                  {actionText && (
                    <p className="mt-1 text-xs text-th-text-secondary">
                      <span className="font-medium">Action: </span>{actionText}
                    </p>
                  )}
                  {r.sourceFiles && r.sourceFiles.length > 0 && (
                    <p className="mt-1 text-xs text-th-text-faint break-all">
                      Sources: {r.sourceFiles.slice(0, 2).join(", ")}
                      {r.sourceFiles.length > 2 ? ` (+${r.sourceFiles.length - 2} more)` : ""}
                    </p>
                  )}
                </div>
              );
            };

            return (
              <div className="space-y-3">
                <div className="flex flex-wrap items-center gap-2 text-xs">
                  <span className="inline-block rounded-full border border-th-border bg-th-surface-alt px-2 py-0.5 text-th-text-secondary">
                    Total: <strong>{totalCount}</strong>
                  </span>
                  <span className="inline-block rounded-full border border-blue-200 bg-blue-50 px-2 py-0.5 text-blue-800">
                    Open: <strong>{openCount}</strong>
                  </span>
                  <span className="inline-block rounded-full border border-red-200 bg-red-50 px-2 py-0.5 text-red-800">
                    High: <strong>{highCount}</strong>
                  </span>
                  <span className="inline-block rounded-full border border-amber-200 bg-amber-50 px-2 py-0.5 text-amber-800">
                    Rising: <strong>{risingCount}</strong>
                  </span>
                  {(totals.imminentEscalation ?? 0) > 0 && (
                    <span className="inline-block rounded-full border border-red-200 bg-red-50 px-2 py-0.5 text-red-800" title="Predicted to need escalation within 3 days">
                      Imminent: <strong>{totals.imminentEscalation ?? 0}</strong>
                    </span>
                  )}
                  {riskRegistry.generated && (
                    <span className="ml-auto text-th-text-faint">Generated {riskRegistry.generated}</span>
                  )}
                </div>

                <div>
                  <h4 className="text-xs font-semibold uppercase tracking-wide text-red-700 mb-2">
                    Highest Risks
                  </h4>
                  {highest.length > 0 ? (
                    <div className="space-y-2">{highest.map(renderRisk)}</div>
                  ) : (
                    <p className="text-xs text-th-text-faint italic">No open risks.</p>
                  )}
                </div>

                {growing.length > 0 && (
                  <div>
                    <h4 className="text-xs font-semibold uppercase tracking-wide text-amber-700 mb-2">
                      Fastest Growing Risks
                    </h4>
                    <div className="space-y-2">{growing.map(renderRisk)}</div>
                  </div>
                )}

                {oldest.length > 0 && (
                  <div>
                    <h4 className="text-xs font-semibold uppercase tracking-wide text-th-text-faint mb-2">
                      Oldest Risks (14+ days)
                    </h4>
                    <div className="space-y-2">{oldest.map(renderRisk)}</div>
                  </div>
                )}

                {escalated.length > 0 && (
                  <div>
                    <h4 className="text-xs font-semibold uppercase tracking-wide text-red-700 mb-2">
                      Escalated Risks
                    </h4>
                    <div className="space-y-2">{escalated.map(renderRisk)}</div>
                  </div>
                )}

                <p className="text-xs text-th-text-faint">
                  Source: 00-context/generated/risk-register.json - do not hand-edit.
                </p>
              </div>
            );
          })()
        ) : (
          <p className="text-sm text-th-text-faint italic">
            Risk register not available. Regenerate to produce 00-context/generated/risk-register.json.
          </p>
        )}
      </div>

      {/* Morning Briefing */}
      <div className="rounded-xl border border-th-border bg-th-surface p-4">
        <h3 className="font-semibold text-th-text-secondary mb-2">Morning Briefing</h3>
        {briefingJson ? (
          <div className="space-y-3">
            {briefingJson.generated && (
              <p className="text-xs text-th-text-faint">Generated {briefingJson.generated}</p>
            )}
            {briefingJson.executiveSnapshot && (
              <div className="rounded-lg border border-th-border bg-th-surface-alt p-3">
                <h4 className="text-xs font-semibold uppercase tracking-wide text-th-text-faint mb-1">
                  Executive Snapshot
                </h4>
                <p className="text-sm text-th-text-secondary">{briefingJson.executiveSnapshot}</p>
              </div>
            )}

            {briefingJson.primaryFocus && briefingJson.primaryFocus.length > 0 && (
              <div>
                <h4 className="text-xs font-semibold uppercase tracking-wide text-th-text-faint mb-2">
                  Today&apos;s Primary Focus
                </h4>
                <div className="space-y-2">
                  {briefingJson.primaryFocus.map((p) => (
                    <div key={p.id ?? p.name} className="rounded-md border border-th-border p-2">
                      <div className="flex items-center justify-between gap-3">
                        <div className="text-sm font-medium text-th-text">{p.name}</div>
                        <div className="flex items-center gap-2 text-xs tabular-nums">
                          <span className="rounded-full border border-th-border bg-th-surface-alt px-2 py-0.5 font-medium text-th-text-secondary">{p.category ?? "-"}</span>
                          <span>Attention: <strong>{(p.attentionScore ?? 0).toFixed(1)}</strong></span>
                          {p.trendSymbol && (
                            <span className="text-th-text-muted" title={p.trendDirection || ""}>
                              {p.trendSymbol} {typeof p.deltaPercent === "number" ? `${p.deltaPercent > 0 ? "+" : ""}${p.deltaPercent.toFixed(1)}%` : ""}
                            </span>
                          )}
                        </div>
                      </div>
                      {p.whyItMatters && (
                        <p className="mt-1 text-xs text-th-text-secondary"><span className="font-medium">Why: </span>{p.whyItMatters}</p>
                      )}
                      {p.overrideApplied && p.overrideReason && (
                        <p className="mt-1 text-xs text-th-text-secondary"><span className="font-medium">Override: </span>{p.overrideReason}</p>
                      )}
                      {p.recommendedNextAction && (
                        <p className="mt-1 text-xs text-th-text-secondary"><span className="font-medium">Next: </span>{p.recommendedNextAction}</p>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}

            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div className="rounded-lg border border-th-border p-3">
                <h4 className="text-xs font-semibold uppercase tracking-wide text-th-text-faint mb-1">Rising Risks</h4>
                {briefingJson.risingRisks && briefingJson.risingRisks.length > 0 ? (
                  <ul className="space-y-1 text-xs text-th-text-secondary">
                    {briefingJson.risingRisks.map((r, i) => (
                      <li key={i}>
                        <span className="font-medium">{r.name}</span>
                        {r.trendSymbol ? ` ${r.trendSymbol}` : ""}
                        {typeof r.deltaPercent === "number" ? ` ${r.deltaPercent > 0 ? "+" : ""}${r.deltaPercent.toFixed(1)}%` : ""}
                        {typeof r.riskSignals === "number" && r.riskSignals > 0 ? ` · risk:${r.riskSignals}` : ""}
                        {typeof r.escalationSignals === "number" && r.escalationSignals > 0 ? ` · escalation:${r.escalationSignals}` : ""}
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="text-xs text-th-text-faint italic">None flagged.</p>
                )}
              </div>

              <div className="rounded-lg border border-th-border p-3">
                <h4 className="text-xs font-semibold uppercase tracking-wide text-th-text-faint mb-1">Decision Watch</h4>
                {briefingJson.decisionWatch && briefingJson.decisionWatch.length > 0 ? (
                  <ul className="space-y-1 text-xs text-th-text-secondary">
                    {briefingJson.decisionWatch.map((d, i) => (
                      <li key={i}>
                        <span className="font-medium">{d.name}</span>
                        {typeof d.decisionSignals === "number" ? ` · decisions:${d.decisionSignals}` : ""}
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="text-xs text-th-text-faint italic">None flagged.</p>
                )}
              </div>

              <div className="rounded-lg border border-th-border p-3">
                <h4 className="text-xs font-semibold uppercase tracking-wide text-th-text-faint mb-1">Blocked / Escalation</h4>
                {briefingJson.blockedOrEscalationCandidates && briefingJson.blockedOrEscalationCandidates.length > 0 ? (
                  <ul className="space-y-1 text-xs text-th-text-secondary">
                    {briefingJson.blockedOrEscalationCandidates.map((e, i) => (
                      <li key={i}>
                        <span className="font-medium">{e.name}</span>
                        {e.category ? ` · ${e.category}` : ""}
                        {typeof e.escalationSignals === "number" ? ` · escalation:${e.escalationSignals}` : ""}
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="text-xs text-th-text-faint italic">None detected.</p>
                )}
              </div>

              <div className="rounded-lg border border-th-border p-3">
                <h4 className="text-xs font-semibold uppercase tracking-wide text-th-text-faint mb-1">Recommended Actions for David</h4>
                {briefingJson.recommendedActionsForDavid && briefingJson.recommendedActionsForDavid.length > 0 ? (
                  <ul className="space-y-1 text-xs text-th-text-secondary">
                    {briefingJson.recommendedActionsForDavid.map((a, i) => (
                      <li key={i}>
                        <span className="font-medium">{a.name}: </span>{a.action}
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="text-xs text-th-text-faint italic">Nothing on the plate today.</p>
                )}
              </div>
            </div>

            {briefingJson.sourceInputs && briefingJson.sourceInputs.length > 0 && (
              <div className="rounded-lg border border-th-border p-3">
                <h4 className="text-xs font-semibold uppercase tracking-wide text-th-text-faint mb-1">Source Inputs</h4>
                <ul className="space-y-0.5 text-xs text-th-text-muted font-mono">
                  {briefingJson.sourceInputs.slice(0, 8).map((s, i) => (
                    <li key={i}>
                      {s.path}{s.date ? ` (${s.date})` : ""}{typeof s.weight === "number" ? ` [w=${s.weight}]` : ""}
                    </li>
                  ))}
                </ul>
              </div>
            )}

            <p className="text-xs text-th-text-faint">
              Source: 00-context/generated/morning-briefing.json - do not hand-edit.
            </p>
          </div>
        ) : (
          <p className="text-sm text-th-text-faint italic">
            Morning briefing not available. Regenerate to produce 00-context/generated/morning-briefing.json.
          </p>
        )}
      </div>
    </div>
  );
}
