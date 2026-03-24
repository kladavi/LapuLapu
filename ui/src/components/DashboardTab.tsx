"use client";

import React from "react";
import { usePMData } from "../context/PMContext";

export function DashboardTab() {
  const { data } = usePMData();
  if (!data) return null;

  const tier1 = data.objectives.filter((o) => o.tier === 1);
  const tier2 = data.objectives.filter((o) => o.tier === 2);
  const tier3 = data.objectives.filter((o) => o.tier === 3);
  const openTasks = data.tasks.filter(
    (t) => t.status.toLowerCase() === "open"
  );
  const closedTasks = data.tasks.filter(
    (t) => t.status.toLowerCase() !== "open"
  );
  const latestWeekly = data.weeklySummaries[0];

  const cards = [
    {
      label: "Tier-1 Objectives",
      value: tier1.length,
      icon: "🎯",
      color: "bg-blue-50 text-blue-700 border-blue-200",
    },
    {
      label: "Tier-2 Objectives",
      value: tier2.length,
      icon: "🎯",
      color: "bg-indigo-50 text-indigo-700 border-indigo-200",
    },
    {
      label: "Tier-3 Objectives",
      value: tier3.length,
      icon: "🎯",
      color: "bg-purple-50 text-purple-700 border-purple-200",
    },
    {
      label: "Open Tasks",
      value: openTasks.length,
      icon: "✅",
      color: "bg-green-50 text-green-700 border-green-200",
    },
    {
      label: "Closed Tasks",
      value: closedTasks.length,
      icon: "☑️",
      color: "bg-gray-50 text-gray-600 border-gray-200",
    },
    {
      label: "Decisions",
      value: data.decisions.length,
      icon: "⚖️",
      color: "bg-amber-50 text-amber-700 border-amber-200",
    },
    {
      label: "Teams",
      value: data.teams.length,
      icon: "👥",
      color: "bg-teal-50 text-teal-700 border-teal-200",
    },
    {
      label: "Systems",
      value: data.systems.length,
      icon: "🖥️",
      color: "bg-rose-50 text-rose-700 border-rose-200",
    },
  ];

  return (
    <div className="p-6 max-w-5xl mx-auto space-y-6">
      <h2 className="text-xl font-bold text-gray-800">Dashboard</h2>

      {/* Stat cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {cards.map((c) => (
          <div
            key={c.label}
            className={`rounded-xl border p-4 ${c.color}`}
          >
            <div className="text-2xl mb-1">{c.icon}</div>
            <div className="text-3xl font-bold">{c.value}</div>
            <div className="text-sm mt-1 opacity-80">{c.label}</div>
          </div>
        ))}
      </div>

      {/* Latest weekly */}
      <div className="rounded-xl border border-gray-200 bg-white p-4">
        <h3 className="font-semibold text-gray-700 mb-2">
          Latest Weekly Summary
        </h3>
        {latestWeekly ? (
          <p className="text-sm text-gray-600">
            📄 {latestWeekly.filename}
          </p>
        ) : (
          <p className="text-sm text-gray-400 italic">
            No weekly summaries found in 03-reporting/weekly/
          </p>
        )}
      </div>

      {/* Warnings */}
      {data.warnings.length > 0 && (
        <div className="rounded-xl border border-amber-300 bg-amber-50 p-4">
          <h3 className="font-semibold text-amber-800 mb-2">⚠️ Warnings</h3>
          <ul className="space-y-1">
            {data.warnings.map((w, i) => (
              <li key={i} className="text-sm text-amber-700">
                {w}
              </li>
            ))}
          </ul>
        </div>
      )}

      {/* Files loaded */}
      <div className="rounded-xl border border-gray-200 bg-white p-4">
        <h3 className="font-semibold text-gray-700 mb-2">Files Loaded</h3>
        <div className="text-sm text-gray-500 space-y-0.5 max-h-48 overflow-auto font-mono">
          {Object.keys(data.rawFiles)
            .sort()
            .map((f) => (
              <div key={f}>{f}</div>
            ))}
        </div>
      </div>
    </div>
  );
}
