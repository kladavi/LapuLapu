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
        <h2 className="text-xl font-bold text-gray-800">
          Tasks{" "}
          <span className="text-gray-400 font-normal text-base">
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
          className="text-sm border border-gray-300 rounded-lg px-3 py-2 w-80 focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
        <div className="flex gap-1">
          <button
            onClick={() => setStatusFilter("")}
            className={`px-3 py-1 text-xs rounded-full border cursor-pointer ${
              statusFilter === ""
                ? "bg-blue-600 text-white border-blue-600"
                : "bg-white text-gray-600 border-gray-300"
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
                  ? "bg-blue-600 text-white border-blue-600"
                  : "bg-white text-gray-600 border-gray-300"
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
            className="rounded-xl border border-gray-200 bg-white overflow-hidden"
          >
            <button
              onClick={() =>
                setExpandedId(expandedId === task.id ? null : task.id)
              }
              className="w-full text-left p-4 cursor-pointer hover:bg-gray-50 transition-colors"
            >
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <span className="font-mono text-xs font-bold text-green-700 bg-green-50 rounded px-2 py-0.5">
                    {task.id}
                  </span>
                  <span className="font-medium text-sm text-gray-800">
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
                        ? "bg-blue-100 text-blue-800"
                        : "bg-gray-100 text-gray-600"
                    }`}
                  >
                    {task.status}
                  </span>
                </div>
              </div>

              {/* Meta row */}
              <div className="flex flex-wrap gap-3 mt-2 text-xs text-gray-500">
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
                    className="text-[10px] bg-rose-50 text-rose-600 rounded px-1.5 py-0.5"
                  >
                    {s}
                  </span>
                ))}
                {task.tags.map((t) => (
                  <span
                    key={t}
                    className="text-[10px] bg-gray-100 text-gray-500 rounded px-1.5 py-0.5"
                  >
                    {t}
                  </span>
                ))}
              </div>
            </button>

            {/* Expanded detail */}
            {expandedId === task.id && (
              <div className="border-t border-gray-100 p-4 bg-gray-50">
                <h4 className="text-xs font-bold text-gray-500 uppercase mb-1">
                  Description
                </h4>
                <p className="text-sm text-gray-700 leading-relaxed">
                  {task.description}
                </p>

                {/* Objective chain detail */}
                {task.objectiveIds.length > 0 && (
                  <div className="mt-3">
                    <h4 className="text-xs font-bold text-gray-500 uppercase mb-1">
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
                            className="text-xs bg-blue-50 text-blue-700 border border-blue-200 rounded px-2 py-0.5"
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
          <p className="text-gray-400 italic text-sm py-8 text-center">
            No tasks match the current filters.
          </p>
        )}
      </div>
    </div>
  );
}
