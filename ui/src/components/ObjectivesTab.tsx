"use client";

import React, { useState, useMemo, useEffect, useCallback } from "react";
import { usePMData } from "../context/PMContext";
import type { Objective, Task, RelationshipAdvisory, RelationshipMap } from "../lib/types";
import { computeKRProgress } from "../lib/parsers";

// ── Chevron icon component ──
function Chevron({ open, className = "" }: { open: boolean; className?: string }) {
  return (
    <svg
      className={`w-4 h-4 transition-transform duration-200 ${open ? "rotate-90" : ""} ${className}`}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth={2}
    >
      <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
    </svg>
  );
}

// ── Status badge ──
function StatusBadge({ status }: { status: string }) {
  const isOpen = status.toLowerCase() === "open";
  return (
    <span
      className={`text-[10px] font-medium rounded-full px-2 py-0.5 ${
        isOpen
          ? "bg-green-100 text-green-700"
          : "bg-th-surface-alt text-th-text-muted"
      }`}
    >
      {status}
    </span>
  );
}

const OWNER_FILTERS = [
  { label: "All", value: "" },
  { label: "Hari", value: "#hari" },
  { label: "Birger", value: "#birger" },
  { label: "Kelvin", value: "#kelvin" },
];

// ── View mode type ──
type ViewMode = "tree" | "diagram";

interface Props {
  initialTier?: number;
  initialOwnerTag?: string;
}

// ── Helper: get tasks related to a Tier-2 objective using relationship map ──
function getTier2RelatedTasks(tier2Id: string, allTasks: Task[], relationships: RelationshipMap) {
  const taskIds = relationships.tier2ToTasks[tier2Id] || [];
  return allTasks.filter((t) => taskIds.includes(t.id));
}

// ── Helper: get Tier-2 children of a Tier-1 objective using relationship map ──
function getTier1Children(tier1Id: string, allObjectives: Objective[], relationships: RelationshipMap) {
  const childIds = relationships.tier1ToTier2[tier1Id] || [];
  return allObjectives.filter((o) => childIds.includes(o.id));
}

export function ObjectivesTab({ initialTier, initialOwnerTag }: Props) {
  const { data } = usePMData();
  const [viewMode, setViewMode] = useState<ViewMode>("tree");
  const [ownerFilter, setOwnerFilter] = useState(initialOwnerTag ?? "");
  const [tagFilter, setTagFilter] = useState("");
  const [expandedT1, setExpandedT1] = useState<Set<string>>(new Set());
  const [expandedT2, setExpandedT2] = useState<Set<string>>(new Set());
  const [expandedTaskGroup, setExpandedTaskGroup] = useState<Set<string>>(new Set());
  const [selectedId, setSelectedId] = useState<string | null>(null);

  // Reset filters when navigated via dashboard
  useEffect(() => {
    setOwnerFilter(initialOwnerTag ?? "");
    setSelectedId(null);
  }, [initialOwnerTag]);

  // If a specific tier was requested, auto-expand all Tier-1 if tier=2
  useEffect(() => {
    if (initialTier === 2 && data) {
      const t1Ids = new Set(data.objectives.filter((o) => o.tier === 1).map((o) => o.id));
      setExpandedT1(t1Ids);
    }
  }, [initialTier, data]);

  const tier1Objectives = useMemo(() => {
    if (!data) return [];
    let objs = data.objectives.filter((o) => o.tier === 1);
    if (ownerFilter) {
      // Show tier-1 that either match the owner tag themselves, or have tier-2 children that match
      const tier2Matching = data.objectives.filter(
        (o) =>
          o.tier === 2 &&
          o.tags.some((t) => t.toLowerCase() === ownerFilter.toLowerCase())
      );
      const parentIds = new Set(tier2Matching.flatMap((o) => o.parentObjectiveIds));
      objs = objs.filter(
        (o) =>
          o.tags.some((t) => t.toLowerCase() === ownerFilter.toLowerCase()) ||
          parentIds.has(o.id)
      );
    }
    if (tagFilter) {
      const search = tagFilter.toLowerCase();
      // Filter: show tier-1 if it matches or any of its tier-2 children match
      objs = objs.filter((o) => {
        const selfMatch =
          o.tags.some((t) => t.toLowerCase().includes(search)) ||
          o.title.toLowerCase().includes(search) ||
          o.id.toLowerCase().includes(search);
        if (selfMatch) return true;
        const children = getTier1Children(o.id, data.objectives, data.relationships);
        return children.some(
          (c) =>
            c.tags.some((t) => t.toLowerCase().includes(search)) ||
            c.title.toLowerCase().includes(search) ||
            c.id.toLowerCase().includes(search)
        );
      });
    }
    return objs;
  }, [data, ownerFilter, tagFilter]);

  const toggleT1 = useCallback((id: string) => {
    setExpandedT1((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }, []);

  const toggleT2 = useCallback((id: string) => {
    setExpandedT2((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }, []);

  const toggleTaskGroup = useCallback((key: string) => {
    setExpandedTaskGroup((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  }, []);

  const expandAll = useCallback(() => {
    if (!data) return;
    setExpandedT1(new Set(data.objectives.filter((o) => o.tier === 1).map((o) => o.id)));
    setExpandedT2(new Set(data.objectives.filter((o) => o.tier === 2).map((o) => o.id)));
  }, [data]);

  const collapseAll = useCallback(() => {
    setExpandedT1(new Set());
    setExpandedT2(new Set());
    setExpandedTaskGroup(new Set());
  }, []);

  // Selected objective detail
  const selected = useMemo(
    () => data?.objectives.find((o) => o.id === selectedId) || null,
    [data, selectedId]
  );

  const relatedTasks = useMemo(() => {
    if (!selected || !data) return [];
    // For Tier-2, use relationship map; otherwise filter by objectiveIds
    if (selected.tier === 2) {
      return getTier2RelatedTasks(selected.id, data.tasks, data.relationships);
    } else {
      return data.tasks.filter((t) => t.objectiveIds.includes(selected.id));
    }
  }, [data, selected]);

  if (!data) return null;

  return (
    <div className="flex flex-1 h-full">
      {/* Main panel */}
      <div className={`${selected ? "w-1/2" : "w-full"} border-r border-th-border overflow-auto`}>
        <div className="p-4 space-y-4">
          {/* Controls bar */}
          <div className="flex flex-wrap gap-3 items-center justify-between">
            <div className="flex flex-wrap gap-3 items-center">
              {/* View mode toggle */}
              <div className="flex gap-1 bg-th-surface-alt rounded-lg p-0.5">
                <button
                  onClick={() => setViewMode("tree")}
                  className={`px-3 py-1.5 text-xs rounded-md font-medium transition-colors cursor-pointer ${
                    viewMode === "tree"
                      ? "bg-th-surface text-th-text shadow-sm"
                      : "text-th-text-muted hover:text-th-text-secondary"
                  }`}
                >
                  🌳 Tree View
                </button>
                <button
                  onClick={() => setViewMode("diagram")}
                  className={`px-3 py-1.5 text-xs rounded-md font-medium transition-colors cursor-pointer ${
                    viewMode === "diagram"
                      ? "bg-th-surface text-th-text shadow-sm"
                      : "text-th-text-muted hover:text-th-text-secondary"
                  }`}
                >
                  🔗 Relationship Diagram
                </button>
              </div>

              {/* Owner filter */}
              <div className="flex gap-1">
                {OWNER_FILTERS.map((f) => (
                  <button
                    key={f.value}
                    onClick={() => setOwnerFilter(f.value)}
                    className={`px-3 py-1 text-xs rounded-full border cursor-pointer transition-colors ${
                      ownerFilter === f.value
                        ? "bg-indigo-600 text-white border-indigo-600"
                        : "bg-th-surface text-th-text-secondary border-th-border-strong hover:border-indigo-400"
                    }`}
                  >
                    {f.label}
                  </button>
                ))}
              </div>

              <input
                type="text"
                placeholder="Filter by tag or keyword…"
                value={tagFilter}
                onChange={(e) => setTagFilter(e.target.value)}
                className="text-sm border border-th-border-strong rounded-lg px-3 py-1.5 w-48 bg-th-surface text-th-text focus:outline-none focus:ring-2 focus:ring-th-accent"
              />
            </div>

            {viewMode === "tree" && (
              <div className="flex gap-2">
                <button
                  onClick={expandAll}
                  className="text-xs text-th-accent hover:text-th-accent-hover cursor-pointer"
                >
                  Expand All
                </button>
                <span className="text-th-text-faint">|</span>
                <button
                  onClick={collapseAll}
                  className="text-xs text-th-accent hover:text-th-accent-hover cursor-pointer"
                >
                  Collapse All
                </button>
              </div>
            )}
          </div>

          {/* Advisory notes */}
          {data.relationships.violations.length > 0 && (
            <AdvisoryPanel advisories={data.relationships.violations} />
          )}

          {/* Tree View */}
          {viewMode === "tree" && (
            <div className="space-y-1">
              {tier1Objectives.length === 0 && (
                <p className="text-gray-400 italic text-sm py-4">
                  No objectives match the current filters.
                </p>
              )}
              {tier1Objectives.map((t1) => {
                const isT1Open = expandedT1.has(t1.id);
                const children = getTier1Children(t1.id, data.objectives, data.relationships).filter((c) => {
                  if (ownerFilter) {
                    return c.tags.some(
                      (t) => t.toLowerCase() === ownerFilter.toLowerCase()
                    );
                  }
                  if (tagFilter) {
                    const search = tagFilter.toLowerCase();
                    return (
                      c.tags.some((t) => t.toLowerCase().includes(search)) ||
                      c.title.toLowerCase().includes(search) ||
                      c.id.toLowerCase().includes(search)
                    );
                  }
                  return true;
                });
                const allChildTasks = children.flatMap((c) =>
                  getTier2RelatedTasks(c.id, data.tasks, data.relationships)
                );
                const directTasks = data.tasks.filter((t) => t.objectiveIds.includes(t1.id));

                return (
                  <div key={t1.id} className="rounded-lg border border-th-border bg-th-surface overflow-hidden">
                    {/* Tier-1 row */}
                    <div className="flex items-center gap-2 px-3 py-2.5 hover:bg-th-accent-light/50 transition-colors">
                      <button
                        onClick={() => toggleT1(t1.id)}
                        className="flex items-center gap-2 flex-1 text-left cursor-pointer"
                      >
                        <Chevron open={isT1Open} className="text-th-accent shrink-0" />
                        <span className="text-xs font-mono font-bold text-th-accent-text bg-th-accent-light rounded px-1.5 py-0.5 shrink-0">
                          {t1.id}
                        </span>
                        <span className="font-semibold text-sm text-th-text">
                          {t1.title}
                        </span>
                      </button>
                      <div className="flex items-center gap-2 shrink-0">
                        <span className="text-[10px] text-th-text-faint">
                          {children.length} sub-obj · {allChildTasks.length + directTasks.length} tasks
                        </span>
                        <button
                          onClick={() => setSelectedId(selectedId === t1.id ? null : t1.id)}
                          className="text-xs text-th-accent hover:text-th-accent-hover cursor-pointer px-1"
                          title="View details"
                        >
                          ℹ️
                        </button>
                      </div>
                    </div>

                    {/* Expanded: Tier-2 children */}
                    {isT1Open && (
                      <div className="border-t border-th-border bg-th-surface-alt/50">
                        {/* Direct tasks under Tier-1 (if any) */}
                        {directTasks.length > 0 && (
                          <div className="ml-6 border-l-2 border-th-accent/20">
                            <div className="pl-4 py-1">
                              <button
                                onClick={() => toggleTaskGroup(`${t1.id}-direct`)}
                                className="flex items-center gap-2 text-xs text-gray-500 cursor-pointer hover:text-gray-700 py-1"
                              >
                                <Chevron open={expandedTaskGroup.has(`${t1.id}-direct`)} className="text-gray-400" />
                                <span className="font-medium">Direct Tasks (cross-cutting)</span>
                                <span className="text-th-text-faint">({directTasks.length})</span>
                              </button>
                              {expandedTaskGroup.has(`${t1.id}-direct`) && (
                                <TaskList tasks={directTasks} />
                              )}
                            </div>
                          </div>
                        )}

                        {children.length === 0 && directTasks.length === 0 && (
                          <p className="text-xs text-gray-400 italic px-10 py-3">
                            No Tier-2 objectives linked to this objective.
                          </p>
                        )}

                        {children.map((t2) => {
                          const isT2Open = expandedT2.has(t2.id);
                          const t2Tasks = getTier2RelatedTasks(t2.id, data.tasks, data.relationships);
                          const openTasks = t2Tasks.filter(
                            (t) => t.status.toLowerCase() === "open"
                          );
                          const closedTasks = t2Tasks.filter(
                            (t) => t.status.toLowerCase() !== "open"
                          );

                          return (
                            <div key={t2.id} className="ml-6 border-l-2 border-indigo-200">
                              <div className="pl-4">
                                {/* Tier-2 row */}
                                <div className="flex items-center gap-2 py-2 hover:bg-indigo-500/10 transition-colors rounded-r">
                                  <button
                                    onClick={() => toggleT2(t2.id)}
                                    className="flex items-center gap-2 flex-1 text-left cursor-pointer"
                                  >
                                    <Chevron open={isT2Open} className="text-indigo-400 shrink-0" />
                                    <span className="text-xs font-mono font-bold text-indigo-600 bg-indigo-100 rounded px-1.5 py-0.5 shrink-0">
                                      {t2.id}
                                    </span>
                                    <span className="text-sm font-medium text-th-text-secondary">
                                      {t2.title}
                                    </span>
                                  </button>
                                  <div className="flex items-center gap-2 shrink-0 pr-3">
                                    {openTasks.length > 0 && (
                                      <span className="text-[10px] bg-green-100 text-green-700 rounded-full px-2 py-0.5">
                                        {openTasks.length} open
                                      </span>
                                    )}
                                    {closedTasks.length > 0 && (
                                      <span className="text-[10px] bg-th-surface-alt text-th-text-muted rounded-full px-2 py-0.5">
                                        {closedTasks.length} closed
                                      </span>
                                    )}
                                    {t2.ownerSection && (
                                      <span className="text-[10px] text-th-text-faint">
                                        {t2.ownerSection}
                                      </span>
                                    )}
                                    <button
                                      onClick={() =>
                                        setSelectedId(selectedId === t2.id ? null : t2.id)
                                      }
                                      className="text-xs text-indigo-400 hover:text-indigo-600 cursor-pointer px-1"
                                      title="View details"
                                    >
                                      ℹ️
                                    </button>
                                  </div>
                                </div>

                                {/* Expanded: Task groups */}
                                {isT2Open && (
                                  <div className="ml-5 border-l-2 border-green-200 mb-2">
                                    {t2Tasks.length === 0 && (
                                      <p className="text-xs text-gray-400 italic pl-4 py-2">
                                        No tasks linked.
                                      </p>
                                    )}

                                    {/* Open tasks group */}
                                    {openTasks.length > 0 && (
                                      <div className="pl-4 py-1">
                                        <button
                                          onClick={() =>
                                            toggleTaskGroup(`${t2.id}-open`)
                                          }
                                          className="flex items-center gap-2 text-xs cursor-pointer hover:text-green-700 py-1"
                                        >
                                          <Chevron
                                            open={expandedTaskGroup.has(`${t2.id}-open`)}
                                            className="text-green-500"
                                          />
                                          <span className="font-medium text-green-700">
                                            Open Tasks
                                          </span>
                                          <span className="text-green-500 bg-green-50 rounded-full px-1.5 py-0.5 text-[10px]">
                                            {openTasks.length}
                                          </span>
                                        </button>
                                        {expandedTaskGroup.has(`${t2.id}-open`) && (
                                          <TaskList tasks={openTasks} />
                                        )}
                                      </div>
                                    )}

                                    {/* Closed tasks group */}
                                    {closedTasks.length > 0 && (
                                      <div className="pl-4 py-1">
                                        <button
                                          onClick={() =>
                                            toggleTaskGroup(`${t2.id}-closed`)
                                          }
                                          className="flex items-center gap-2 text-xs cursor-pointer hover:text-gray-700 py-1"
                                        >
                                          <Chevron
                                            open={expandedTaskGroup.has(`${t2.id}-closed`)}
                                            className="text-gray-400"
                                          />
                                          <span className="font-medium text-th-text-secondary">
                                            Closed Tasks
                                          </span>
                                          <span className="text-gray-500 bg-gray-100 rounded-full px-1.5 py-0.5 text-[10px]">
                                            {closedTasks.length}
                                          </span>
                                        </button>
                                        {expandedTaskGroup.has(`${t2.id}-closed`) && (
                                          <TaskList tasks={closedTasks} />
                                        )}
                                      </div>
                                    )}
                                  </div>
                                )}
                              </div>
                            </div>
                          );
                        })}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          )}

          {/* Relationship Diagram View */}
          {viewMode === "diagram" && (
            <RelationshipDiagram
              objectives={data.objectives}
              tasks={data.tasks}
              relationships={data.relationships}
              ownerFilter={ownerFilter}
              tagFilter={tagFilter}
              onSelect={(id) => setSelectedId(selectedId === id ? null : id)}
            />
          )}
        </div>
      </div>

      {/* Detail panel */}
      {selected && (
        <div className="w-1/2 overflow-auto p-6 space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="text-sm font-mono font-bold text-th-accent-text bg-th-accent-light rounded px-2 py-1">
                {selected.id}
              </span>
              <span className="text-xs bg-purple-100 text-purple-700 rounded px-2 py-0.5">
                Tier-{selected.tier}
              </span>
            </div>
            <button
              onClick={() => setSelectedId(null)}
              className="text-gray-400 hover:text-gray-600 cursor-pointer"
            >
              ✁E
            </button>
          </div>

          <h2 className="text-lg font-bold text-th-text">{selected.title}</h2>

          {/* Parent objectives */}
          {selected.parentObjectiveIds.length > 0 && (
            <div>
              <h4 className="text-xs font-bold text-gray-500 uppercase mb-1">
                Parent Objectives
              </h4>
              <div className="flex gap-2 flex-wrap">
                {selected.parentObjectiveIds.map((pid) => {
                  const parent = data.objectives.find((o) => o.id === pid);
                  return (
                    <button
                      key={pid}
                      onClick={() => setSelectedId(pid)}
                      className="text-xs bg-th-accent-light text-th-accent-text border border-th-accent/30 rounded px-2 py-1 hover:bg-th-accent-light cursor-pointer"
                    >
                      {pid}
                      {parent ? `  E${parent.title}` : ""}
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* Child objectives (for Tier-1) */}
          {selected.tier === 1 && (
            <div>
              <h4 className="text-xs font-bold text-gray-500 uppercase mb-1">
                Child Tier-2 Objectives
              </h4>
              {(() => {
                const children = getTier1Children(selected.id, data.objectives, data.relationships);
                if (children.length === 0)
                  return <p className="text-xs text-gray-400 italic">None linked.</p>;
                return (
                  <div className="flex flex-wrap gap-2">
                    {children.map((c) => (
                      <button
                        key={c.id}
                        onClick={() => setSelectedId(c.id)}
                        className="text-xs bg-indigo-50 text-indigo-700 border border-indigo-200 rounded px-2 py-1 hover:bg-indigo-100 cursor-pointer"
                      >
                        {c.id}  E{c.title}
                      </button>
                    ))}
                  </div>
                );
              })()}
            </div>
          )}

          {/* Description */}
          <div>
            <h4 className="text-xs font-bold text-gray-500 uppercase mb-1">
              Description
            </h4>
            <p className="text-sm text-gray-700 leading-relaxed">
              {selected.description}
            </p>
          </div>

          {/* Commitments */}
          {selected.commitments.length > 0 && (
            <div>
              <h4 className="text-xs font-bold text-gray-500 uppercase mb-1">
                Commitments / Outcomes
              </h4>
              <ul className="text-sm text-gray-700 space-y-1 list-disc list-inside">
                {selected.commitments.map((c, i) => (
                  <li key={i}>{c}</li>
                ))}
              </ul>
            </div>
          )}

          {/* Tags */}
          <div>
            <h4 className="text-xs font-bold text-gray-500 uppercase mb-1">
              Tags
            </h4>
            <div className="flex flex-wrap gap-1">
              {selected.tags.map((t) => (
                <span
                  key={t}
                  className="text-xs bg-th-surface-alt text-th-text-muted rounded-full px-2 py-0.5"
                >
                  {t}
                </span>
              ))}
            </div>
          </div>

          {/* Source */}
          {selected.source.length > 0 && (
            <div>
              <h4 className="text-xs font-bold text-gray-500 uppercase mb-1">
                Source
              </h4>
              <ul className="text-xs text-th-text-muted space-y-0.5">
                {selected.source.map((s, i) => (
                  <li key={i}>• {s}</li>
                ))}
              </ul>
            </div>
          )}

          {/* Key Results linked to this objective */}
          {data.keyResults && (() => {
            const linkedKRs = data.keyResults.filter(
              (kr) => kr.objectiveId === selected.id
            );
            return (
              <div>
                <h4 className="text-xs font-bold text-gray-500 uppercase mb-1">
                  Key Results ({linkedKRs.length})
                </h4>
                {linkedKRs.length > 0 ? (
                  <div className="space-y-2">
                    {linkedKRs.map((kr) => {
                      const progress = computeKRProgress(kr);
                      return (
                        <div
                          key={kr.id}
                          className="text-sm border border-th-border rounded-lg p-2 bg-th-surface-alt"
                        >
                          <div className="flex items-center justify-between mb-1">
                            <div>
                              <span className="font-mono text-xs font-bold text-purple-700">
                                {kr.id}
                              </span>{" "}
                              <span className="text-th-text-secondary">
                                {kr.title}
                              </span>
                            </div>
                            <span className="text-xs text-th-text-muted">
                              {progress}%
                            </span>
                          </div>
                          <div className="w-full bg-th-surface rounded-full h-1.5">
                            <div
                              className={`h-1.5 rounded-full transition-all ${
                                progress >= 75
                                  ? "bg-green-500"
                                  : progress >= 50
                                    ? "bg-yellow-500"
                                    : progress >= 25
                                      ? "bg-orange-500"
                                      : "bg-red-500"
                              }`}
                              style={{ width: `${Math.min(progress, 100)}%` }}
                            />
                          </div>
                          <div className="text-xs text-gray-400 mt-0.5">
                            {kr.status} · {kr.metricType === "boolean" ? "Boolean" : `${kr.currentValue} / ${kr.targetValue}`} · 📅 {kr.targetDate || "—"}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                ) : (
                  <p className="text-xs text-gray-400 italic">
                    No key results linked to this objective.
                  </p>
                )}
              </div>
            );
          })()}

          {/* Related tasks */}
          <div>
            <h4 className="text-xs font-bold text-gray-500 uppercase mb-1">
              Related Tasks ({relatedTasks.length})
            </h4>
            {relatedTasks.length > 0 ? (
              <div className="space-y-2">
                {relatedTasks.map((t) => (
                  <div
                    key={t.id}
                    className="text-sm border border-th-border rounded-lg p-2 bg-th-surface-alt"
                  >
                    <span className="font-mono text-xs font-bold text-green-700">
                      {t.id}
                    </span>{" "}
                    <span className="text-th-text-secondary">{t.title}</span>
                    <div className="text-xs text-gray-400 mt-0.5">
                      {t.status} · {t.assigned} · {t.team}
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-xs text-gray-400 italic">
                No tasks reference this objective.
              </p>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

// ── Advisory Notes Panel ──
const KIND_META: Record<RelationshipAdvisory["kind"], { icon: string; label: string; color: string; border: string; bg: string }> = {
  "orphaned-tier2":  { icon: "🔗", label: "Orphaned Tier-2",     color: "text-amber-800",  border: "border-amber-200", bg: "bg-amber-50" },
  "invalid-parent":  { icon: "⛓️",  label: "Invalid Parent",      color: "text-orange-800", border: "border-orange-200", bg: "bg-orange-50" },
  "task-skips-tier2":{ icon: "⤵️",  label: "Task Skips Tier-2",  color: "text-th-accent",   border: "border-th-accent/20",  bg: "bg-th-accent-light" },
  "missing-objective":{ icon: "❓", label: "Missing Objective",   color: "text-red-800",    border: "border-red-200",   bg: "bg-red-50" },
};

function AdvisoryPanel({ advisories }: { advisories: RelationshipAdvisory[] }) {
  const [open, setOpen] = useState(false);
  const [expandedIdx, setExpandedIdx] = useState<number | null>(null);

  // Group by kind for summary
  const byKind = advisories.reduce<Record<string, number>>((acc, a) => {
    acc[a.kind] = (acc[a.kind] || 0) + 1;
    return acc;
  }, {});

  return (
    <div className="rounded-lg border border-amber-300 overflow-hidden">
      {/* Header  Ealways visible */}
      <button
        onClick={() => setOpen((v) => !v)}
        className="w-full flex items-center justify-between px-3 py-2 bg-amber-50 hover:bg-amber-100 transition-colors cursor-pointer"
      >
        <div className="flex items-center gap-2">
          <span className="text-sm">⚠️</span>
          <span className="text-xs font-bold text-amber-800">
            {advisories.length} Relationship {advisories.length === 1 ? "Note" : "Notes"}
          </span>
          <div className="flex gap-1">
            {Object.entries(byKind).map(([kind, count]) => {
              const meta = KIND_META[kind as RelationshipAdvisory["kind"]];
              return (
                <span key={kind} className={`text-[10px] font-medium rounded-full px-2 py-0.5 border ${meta.border} ${meta.bg} ${meta.color}`}>
                  {meta.icon} {count} {meta.label}
                </span>
              );
            })}
          </div>
        </div>
        <Chevron open={open} className="text-amber-600 shrink-0" />
      </button>

      {/* Expanded list */}
      {open && (
        <div className="divide-y divide-amber-100 max-h-72 overflow-auto">
          {advisories.map((advisory, i) => {
            const meta = KIND_META[advisory.kind];
            const isExpanded = expandedIdx === i;
            return (
              <div key={i} className={`${meta.bg}`}>
                <button
                  onClick={() => setExpandedIdx(isExpanded ? null : i)}
                  className="w-full flex items-start gap-2 px-3 py-2 text-left cursor-pointer hover:brightness-95 transition-all"
                >
                  <span className="text-sm shrink-0 mt-0.5">{meta.icon}</span>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className={`text-[10px] font-bold uppercase tracking-wide ${meta.color}`}>{meta.label}</span>
                      <span className="font-mono text-[10px] bg-th-surface/60 rounded px-1 py-0.5 text-th-text-secondary">{advisory.subject}</span>
                    </div>
                    <p className={`text-xs mt-0.5 ${meta.color}`}>{advisory.message}</p>
                    {isExpanded && (
                      <div className="mt-2 rounded border border-current/20 bg-th-surface/50 px-3 py-2">
                        <div className="text-[10px] font-bold text-gray-500 uppercase tracking-wide mb-1">💡 Suggested Resolution</div>
                        <p className="text-xs text-gray-700 leading-relaxed">{advisory.resolution}</p>
                        {advisory.relatedIds.length > 0 && (
                          <div className="flex flex-wrap gap-1 mt-2">
                            {advisory.relatedIds.map((id) => (
                              <span key={id} className="text-[10px] font-mono bg-th-surface-alt text-th-text-muted rounded px-1.5 py-0.5">{id}</span>
                            ))}
                          </div>
                        )}
                      </div>
                    )}
                  </div>
                  <Chevron open={isExpanded} className="text-gray-400 shrink-0 mt-1" />
                </button>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

// ── Task list sub-component ──
function TaskList({ tasks }: { tasks: Task[] }) {
  return (
    <div className="space-y-1 py-1">
      {tasks.map((t) => (
        <div
          key={t.id}
          className="flex items-center gap-2 px-2 py-1.5 rounded hover:bg-th-surface-alt transition-colors text-sm"
        >
          <span className="font-mono text-[11px] font-bold text-green-700 bg-green-50 rounded px-1.5 py-0.5 shrink-0">
            {t.id}
          </span>
          <span className="text-gray-700 text-xs flex-1">{t.title}</span>
          <StatusBadge status={t.status} />
          {t.assigned && (
            <span className="text-[10px] text-gray-400 shrink-0">
              👤 {t.assigned}
            </span>
          )}
        </div>
      ))}
    </div>
  );
}

// ── Relationship Diagram ──
interface DiagramProps {
  objectives: Objective[];
  tasks: Task[];
  relationships: RelationshipMap;
  ownerFilter: string;
  tagFilter: string;
  onSelect: (id: string) => void;
}

function RelationshipDiagram({
  objectives,
  tasks,
  relationships,
  ownerFilter,
  tagFilter,
  onSelect,
}: DiagramProps) {
  const tier1 = useMemo(() => {
    let objs = objectives.filter((o) => o.tier === 1);
    if (ownerFilter) {
      const tier2Matching = objectives.filter(
        (o) =>
          o.tier === 2 &&
          o.tags.some((t) => t.toLowerCase() === ownerFilter.toLowerCase())
      );
      const parentIds = new Set(tier2Matching.flatMap((o) => o.parentObjectiveIds));
      objs = objs.filter(
        (o) =>
          o.tags.some((t) => t.toLowerCase() === ownerFilter.toLowerCase()) ||
          parentIds.has(o.id)
      );
    }
    if (tagFilter) {
      const search = tagFilter.toLowerCase();
      objs = objs.filter(
        (o) =>
          o.tags.some((t) => t.toLowerCase().includes(search)) ||
          o.title.toLowerCase().includes(search) ||
          o.id.toLowerCase().includes(search) ||
          getTier1Children(o.id, objectives, relationships).some(
            (c) =>
              c.tags.some((t) => t.toLowerCase().includes(search)) ||
              c.title.toLowerCase().includes(search) ||
              c.id.toLowerCase().includes(search)
          )
      );
    }
    return objs;
  }, [objectives, relationships, ownerFilter, tagFilter]);

  const [hoveredNode, setHoveredNode] = useState<string | null>(null);

  // Build the complete hierarchy data
  const hierarchy = useMemo(() => {
    return tier1.map((t1) => {
      let children = getTier1Children(t1.id, objectives, relationships);
      if (ownerFilter) {
        children = children.filter((c) =>
          c.tags.some((t) => t.toLowerCase() === ownerFilter.toLowerCase())
        );
      }
      if (tagFilter) {
        const search = tagFilter.toLowerCase();
        children = children.filter(
          (c) =>
            c.tags.some((t) => t.toLowerCase().includes(search)) ||
            c.title.toLowerCase().includes(search) ||
            c.id.toLowerCase().includes(search)
        );
      }
      return {
        ...t1,
        children: children.map((t2) => {
          const t2Tasks = getTier2RelatedTasks(t2.id, tasks, relationships);
          return {
            ...t2,
            openTasks: t2Tasks.filter((t) => t.status.toLowerCase() === "open"),
            closedTasks: t2Tasks.filter((t) => t.status.toLowerCase() !== "open"),
          };
        }),
      };
    });
  }, [tier1, objectives, tasks, relationships, ownerFilter, tagFilter]);

  // Color palette for Tier-1 nodes
  const t1Colors = [
    { bg: "bg-th-accent", light: "bg-blue-100", text: "text-th-accent-text", border: "border-th-accent/30", line: "#3b82f6" },
    { bg: "bg-purple-500", light: "bg-purple-100", text: "text-purple-700", border: "border-purple-300", line: "#8b5cf6" },
    { bg: "bg-teal-500", light: "bg-teal-100", text: "text-teal-700", border: "border-teal-300", line: "#14b8a6" },
    { bg: "bg-orange-500", light: "bg-orange-100", text: "text-orange-700", border: "border-orange-300", line: "#f97316" },
    { bg: "bg-rose-500", light: "bg-rose-100", text: "text-rose-700", border: "border-rose-300", line: "#f43f5e" },
    { bg: "bg-cyan-500", light: "bg-cyan-100", text: "text-cyan-700", border: "border-cyan-300", line: "#06b6d4" },
  ];

  if (hierarchy.length === 0) {
    return (
      <p className="text-gray-400 italic text-sm py-4">
        No objectives match the current filters.
      </p>
    );
  }

  return (
    <div className="space-y-6">
      {/* Legend */}
      <div className="flex flex-wrap items-center gap-6 text-xs text-gray-500 bg-gray-50 rounded-lg p-3">
        <div className="flex items-center gap-1.5">
          <div className="w-3 h-3 rounded bg-blue-500"></div>
          <span>Tier-1 Objective</span>
        </div>
        <div className="flex items-center gap-1.5">
          <div className="w-3 h-3 rounded bg-indigo-400"></div>
          <span>Tier-2 Objective</span>
        </div>
        <div className="flex items-center gap-1.5">
          <div className="w-3 h-3 rounded bg-green-400"></div>
          <span>Open Tasks</span>
        </div>
        <div className="flex items-center gap-1.5">
          <div className="w-3 h-3 rounded bg-th-text-faint"></div>
          <span>Closed Tasks</span>
        </div>
        <div className="flex items-center gap-1.5">
          <svg width="24" height="12" viewBox="0 0 24 12">
            <line x1="0" y1="6" x2="24" y2="6" stroke="#94a3b8" strokeWidth="2" strokeDasharray="4,2" />
          </svg>
          <span>1:Many Relationship</span>
        </div>
      </div>

      {/* Diagram cards */}
      {hierarchy.map((t1, t1Index) => {
        const color = t1Colors[t1Index % t1Colors.length];
        const isHovered = hoveredNode === t1.id;

        return (
          <div key={t1.id} className="relative">
            {/* Tier-1 node */}
            <div
              className={`relative rounded-xl border-2 ${color.border} ${
                isHovered ? "shadow-lg scale-[1.01]" : "shadow-sm"
              } bg-th-surface overflow-hidden transition-all duration-200`}
              onMouseEnter={() => setHoveredNode(t1.id)}
              onMouseLeave={() => setHoveredNode(null)}
            >
              {/* Tier-1 header */}
              <div
                className={`${color.bg} text-white px-4 py-3 flex items-center justify-between cursor-pointer`}
                onClick={() => onSelect(t1.id)}
              >
                <div className="flex items-center gap-2">
                  <span className="text-lg">🎯</span>
                  <span className="font-mono text-xs font-bold bg-th-surface/20 rounded px-2 py-0.5">
                    {t1.id}
                  </span>
                  <span className="font-semibold text-sm">{t1.title}</span>
                </div>
                <span className="text-xs opacity-75">
                  Tier-1 · {t1.children.length} sub-objectives
                </span>
              </div>

              {/* Tier-2 children in a flow layout */}
              {t1.children.length > 0 && (
                <div className="p-4">
                  {/* Connection line from header */}
                  <div className="flex items-center gap-1 mb-3 text-xs text-th-text-faint">
                    <svg width="20" height="20" viewBox="0 0 20 20">
                      <line x1="10" y1="0" x2="10" y2="20" stroke={color.line} strokeWidth="2" strokeDasharray="4,2" />
                    </svg>
                    <span>child objectives (1:many)</span>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
                    {t1.children.map((t2) => {
                      const isT2Hovered = hoveredNode === t2.id;
                      const totalTasks = t2.openTasks.length + t2.closedTasks.length;
                      return (
                        <div
                          key={t2.id}
                          className={`rounded-lg border ${color.border} ${
                            isT2Hovered ? "shadow-md ring-2 ring-indigo-200" : ""
                          } bg-white transition-all duration-200 overflow-hidden`}
                          onMouseEnter={() => setHoveredNode(t2.id)}
                          onMouseLeave={() => setHoveredNode(null)}
                        >
                          {/* Tier-2 header */}
                          <div
                            className={`${color.light} px-3 py-2 cursor-pointer border-b ${color.border}`}
                            onClick={() => onSelect(t2.id)}
                          >
                            <div className="flex items-center gap-1.5">
                              <span className={`font-mono text-[11px] font-bold ${color.text}`}>
                                {t2.id}
                              </span>
                              <span className="text-xs font-medium text-gray-800 line-clamp-1">
                                {t2.title}
                              </span>
                            </div>
                            {t2.ownerSection && (
                              <span className="text-[10px] text-gray-500 mt-0.5 block">
                                👤 {t2.ownerSection}
                              </span>
                            )}
                          </div>

                          {/* Task summary bar */}
                          <div className="px-3 py-2">
                            {totalTasks > 0 ? (
                              <div className="space-y-1.5">
                                {/* Visual bar */}
                                <div className="flex rounded-full h-2 overflow-hidden bg-gray-100">
                                  {t2.openTasks.length > 0 && (
                                    <div
                                      className="bg-green-400 transition-all"
                                      style={{
                                        width: `${(t2.openTasks.length / totalTasks) * 100}%`,
                                      }}
                                    />
                                  )}
                                  {t2.closedTasks.length > 0 && (
                                    <div
                                      className="bg-gray-300 transition-all"
                                      style={{
                                        width: `${(t2.closedTasks.length / totalTasks) * 100}%`,
                                      }}
                                    />
                                  )}
                                </div>
                                <div className="flex justify-between text-[10px]">
                                  <span className="text-green-600">
                                    {t2.openTasks.length} open
                                  </span>
                                  <span className="text-th-text-muted">
                                    {t2.closedTasks.length} closed
                                  </span>
                                </div>
                                {/* Task IDs */}
                                <div className="flex flex-wrap gap-1">
                                  {t2.openTasks.slice(0, 5).map((tk) => (
                                    <span
                                      key={tk.id}
                                      className="text-[9px] font-mono bg-green-50 text-green-600 rounded px-1 py-0.5"
                                      title={tk.title}
                                    >
                                      {tk.id}
                                    </span>
                                  ))}
                                  {t2.closedTasks.slice(0, 3).map((tk) => (
                                    <span
                                      key={tk.id}
                                      className="text-[9px] font-mono bg-th-surface-alt text-th-text-muted rounded px-1 py-0.5 line-through"
                                      title={tk.title}
                                    >
                                      {tk.id}
                                    </span>
                                  ))}
                                  {totalTasks > 8 && (
                                    <span className="text-[9px] text-th-text-faint">
                                      +{totalTasks - 8} more
                                    </span>
                                  )}
                                </div>
                              </div>
                            ) : (
                              <span className="text-[10px] text-gray-400 italic">
                                No tasks linked
                              </span>
                            )}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {t1.children.length === 0 && (
                <div className="px-4 py-3 text-xs text-gray-400 italic">
                  No Tier-2 objectives linked
                </div>
              )}
            </div>
          </div>
        );
      })}

      {/* Summary stats */}
      <div className="flex flex-wrap gap-4 text-xs text-gray-500 border-t border-th-border pt-4">
        <span>
          <strong className="text-th-text-secondary">{tier1.length}</strong> Tier-1 objectives
        </span>
        <span>
          <strong className="text-th-text-secondary">
            {hierarchy.reduce((acc, t1) => acc + t1.children.length, 0)}
          </strong>{" "}
          Tier-2 objectives
        </span>
        <span>
          <strong className="text-green-700">
            {hierarchy.reduce(
              (acc, t1) =>
                acc + t1.children.reduce((a, t2) => a + t2.openTasks.length, 0),
              0
            )}
          </strong>{" "}
          open tasks
        </span>
        <span>
          <strong className="text-th-text-secondary">
            {hierarchy.reduce(
              (acc, t1) =>
                acc + t1.children.reduce((a, t2) => a + t2.closedTasks.length, 0),
              0
            )}
          </strong>{" "}
          closed tasks
        </span>
      </div>
    </div>
  );
}
