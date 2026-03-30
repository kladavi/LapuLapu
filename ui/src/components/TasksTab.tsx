"use client";

import React, { useState, useMemo, useEffect } from "react";
import { usePMData } from "../context/PMContext";

interface Props {
  initialStatus?: string;
}

export function TasksTab({ initialStatus }: Props) {
  const { data } = usePMData();
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>(initialStatus ?? "");
  const [expandedId, setExpandedId] = useState<string | null>(null);

  useEffect(() => {
    setStatusFilter(initialStatus ?? "");
    setExpandedId(null);
  }, [initialStatus]);

  const filtered = useMemo(() => {
    if (!data) return [];
    let tasks = data.tasks;

    if (statusFilter) {
      tasks = tasks.filter(
        (t) => t.status.toLowerCase() === statusFilter.toLowerCase()
      );
    }

    if (search) {
      const q = search.toLowerCase();
      tasks = tasks.filter(
        (t) =>
          t.id.toLowerCase().includes(q) ||
          t.title.toLowerCase().includes(q) ||
          t.tags.some((tag) => tag.toLowerCase().includes(q)) ||
          t.team.toLowerCase().includes(q) ||
          t.assigned.toLowerCase().includes(q) ||
          t.objectiveIds.some((oid) => oid.toLowerCase().includes(q)) ||
          t.systems.some((s) => s.toLowerCase().includes(q))
      );
    }

    return tasks;
  }, [data, search, statusFilter]);

  if (!data) return null;

  const statuses = [...new Set(data.tasks.map((t) => t.status))];

  return (
    <div className="p-6 max-w-5xl mx-auto space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-bold text-th-text">
          Tasks{" "}
          <span className="text-th-text-faint font-normal text-base">
            ({filtered.length})
          </span>
        </h2>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-3 items-center">
        <input
          type="text"
          placeholder="Search tasks (ID, title, tag, team, objective, system)…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="text-sm border border-th-border-strong rounded-lg px-3 py-2 w-80 bg-th-surface text-th-text focus:outline-none focus:ring-2 focus:ring-th-accent"
        />
        <div className="flex gap-1">
          <button
            onClick={() => setStatusFilter("")}
            className={`px-3 py-1 text-xs rounded-full border cursor-pointer ${
              statusFilter === ""
                ? "bg-th-accent text-white border-th-accent"
                : "bg-th-surface text-th-text-secondary border-th-border-strong"
            }`}
          >
            All
          </button>
          {statuses.map((s) => (
            <button
              key={s}
              onClick={() => setStatusFilter(s)}
              className={`px-3 py-1 text-xs rounded-full border cursor-pointer ${
                statusFilter === s
                  ? "bg-th-accent text-white border-th-accent"
                  : "bg-th-surface text-th-text-secondary border-th-border-strong"
              }`}
            >
              {s}
            </button>
          ))}
        </div>
      </div>

      {/* Task cards */}
      <div className="space-y-3">
        {filtered.map((task) => (
          <div
            key={task.id}
            className="rounded-xl border border-th-border bg-th-surface overflow-hidden"
          >
            <button
              onClick={() =>
                setExpandedId(expandedId === task.id ? null : task.id)
              }
              className="w-full text-left p-4 cursor-pointer hover:bg-th-surface-alt transition-colors"
            >
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <span className="font-mono text-xs font-bold text-th-success bg-th-success-light rounded px-2 py-0.5">
                    {task.id}
                  </span>
                  <span className="font-medium text-sm text-th-text">
                    {task.title}
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  {task.relevance !== undefined && (
                    <span
                      className={`text-xs font-bold rounded-full px-2 py-0.5 ${
                        task.relevance >= 80
                          ? "bg-green-100 text-green-800"
                          : task.relevance >= 50
                          ? "bg-yellow-100 text-yellow-800"
                          : "bg-red-100 text-red-800"
                      }`}
                    >
                      {task.relevance}
                    </span>
                  )}
                  <span
                    className={`text-xs rounded-full px-2 py-0.5 ${
                      task.status.toLowerCase() === "open"
                        ? "bg-th-accent-light text-th-accent-text"
                        : "bg-th-surface-alt text-th-text-muted"
                    }`}
                  >
                    {task.status}
                  </span>
                </div>
              </div>

              {/* Meta row */}
              <div className="flex flex-wrap gap-3 mt-2 text-xs text-th-text-muted">
                {task.objectiveChain && (
                  <span>
                    🎯{" "}
                    <span className="font-mono">{task.objectiveChain}</span>
                  </span>
                )}
                {task.team && <span>👥 {task.team}</span>}
                {task.assigned && <span>👤 {task.assigned}</span>}
                {task.created && <span>📅 {task.created}</span>}
              </div>

              {/* Tags */}
              <div className="flex flex-wrap gap-1 mt-2">
                {task.systems.map((s) => (
                  <span
                    key={s}
                    className="text-[10px] bg-th-danger-light text-th-danger rounded px-1.5 py-0.5"
                  >
                    {s}
                  </span>
                ))}
                {task.tags.map((t) => (
                  <span
                    key={t}
                    className="text-[10px] bg-th-surface-alt text-th-text-muted rounded px-1.5 py-0.5"
                  >
                    {t}
                  </span>
                ))}
              </div>
            </button>

            {/* Expanded detail */}
            {expandedId === task.id && (
              <div className="border-t border-th-border p-4 bg-th-surface-alt">
                <h4 className="text-xs font-bold text-th-text-muted uppercase mb-1">
                  Description
                </h4>
                <p className="text-sm text-th-text-secondary leading-relaxed">
                  {task.description}
                </p>

                {/* Objective chain detail */}
                {task.objectiveIds.length > 0 && (
                  <div className="mt-3">
                    <h4 className="text-xs font-bold text-th-text-muted uppercase mb-1">
                      Objective Chain
                    </h4>
                    <div className="flex flex-wrap gap-2">
                      {task.objectiveIds.map((oid) => {
                        const obj = data.objectives.find(
                          (o) => o.id === oid
                        );
                        return (
                          <span
                            key={oid}
                            className="text-xs bg-th-accent-light text-th-accent-text border border-th-accent/30 rounded px-2 py-0.5"
                          >
                            {oid}
                            {obj ? ` — ${obj.title}` : ""}
                            {obj ? ` (Tier-${obj.tier})` : ""}
                          </span>
                        );
                      })}
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        ))}

        {filtered.length === 0 && (
          <p className="text-th-text-faint italic text-sm py-8 text-center">
            No tasks match the current filters.
          </p>
        )}
      </div>
    </div>
  );
}
