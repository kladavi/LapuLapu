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
                          items.map((item) => (
                            <div key={`${section}-${item.name}`} className="rounded-md border border-th-border p-2">
                              <div className="flex items-center justify-between gap-3">
                                <div className="text-sm font-medium text-th-text">{item.name}</div>
                                <div className="flex items-center gap-2 text-xs">
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
                          ))
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
