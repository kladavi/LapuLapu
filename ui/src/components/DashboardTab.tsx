"use client";

import React, { useState } from "react";
import { usePMData } from "../context/PMContext";
import type { NavFilter } from "../app/page";

type TabId = "dashboard" | "objectives" | "tasks" | "weekly" | "export";

interface Props {
  onNavigate: (tab: TabId, filter?: NavFilter) => void;
}

type SectionId = "objectives" | "open" | "closed" | "decisions" | "teams" | "systems";

export function DashboardTab({ onNavigate }: Props) {
  const { data } = usePMData();
  const [expandedSection, setExpandedSection] = useState<SectionId | null>(null);

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

  // Flatten teams (top-level + sub-teams)
  const allTeams = data.teams.flatMap((t) => [t, ...(t.subTeams || [])]);

  const toggle = (id: SectionId) =>
    setExpandedSection((prev) => (prev === id ? null : id));

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
      <h2 className="text-xl font-bold text-gray-800">Dashboard</h2>

      {/* Stat cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
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
        <div className="rounded-xl border border-gray-200 bg-white overflow-hidden">
          {/* Header with optional tab link */}
          <div className="flex items-center justify-between px-4 py-3 bg-gray-50 border-b border-gray-200">
            <h3 className="font-semibold text-gray-700">
              {cards.find((c) => c.id === expandedSection)?.icon}{" "}
              {cards.find((c) => c.id === expandedSection)?.label}
            </h3>
            <div className="flex items-center gap-3">
              {cards.find((c) => c.id === expandedSection)?.hasTab && (
                <button
                  onClick={() => cards.find((c) => c.id === expandedSection)?.tabAction?.()}
                  className="text-xs text-blue-600 hover:text-blue-800 font-medium cursor-pointer"
                >
                  Open in tab →
                </button>
              )}
              <button
                onClick={() => setExpandedSection(null)}
                className="text-xs text-gray-400 hover:text-gray-600 cursor-pointer"
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
                    <div key={o.id} className="rounded-lg border border-blue-200 overflow-hidden">
                      <div className="flex items-start gap-3 p-2 bg-blue-50/50">
                        <span className="font-mono text-xs font-bold text-blue-600 bg-blue-100 rounded px-1.5 py-0.5 shrink-0">
                          {o.id}
                        </span>
                        <div className="min-w-0">
                          <div className="text-sm font-medium text-gray-800">{o.title}</div>
                          <p className="text-xs text-gray-500 mt-0.5 line-clamp-2">{o.description}</p>
                        </div>
                      </div>
                      {children.length > 0 && (
                        <div className="border-t border-blue-100 bg-white">
                          {children.map((c) => (
                            <div key={c.id} className="flex items-start gap-3 p-2 pl-8 hover:bg-gray-50 border-b border-gray-50 last:border-b-0">
                              <span className="font-mono text-xs font-bold text-indigo-600 bg-indigo-100 rounded px-1.5 py-0.5 shrink-0">
                                {c.id}
                              </span>
                              <div className="min-w-0">
                                <div className="text-sm font-medium text-gray-700">{c.title}</div>
                                {c.ownerSection && (
                                  <span className="text-[10px] text-gray-400">👤 {c.ownerSection}</span>
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
                {openTasks.length === 0 && <p className="text-sm text-gray-400 italic">No open tasks.</p>}
                {openTasks.map((t) => (
                  <div key={t.id} className="flex items-start gap-3 p-2 rounded-lg hover:bg-gray-50">
                    <span className="font-mono text-xs font-bold text-green-700 bg-green-50 rounded px-1.5 py-0.5 shrink-0">
                      {t.id}
                    </span>
                    <div className="min-w-0">
                      <div className="text-sm font-medium text-gray-800">{t.title}</div>
                      <div className="flex flex-wrap gap-2 mt-1 text-xs text-gray-500">
                        {t.assigned && <span>👤 {t.assigned}</span>}
                        {t.team && <span>👥 {t.team}</span>}
                        {t.created && <span>📅 {t.created}</span>}
                      </div>
                      {t.objectiveIds.length > 0 && (
                        <div className="flex gap-1 mt-1">
                          <span className="text-[10px] text-gray-400">Objectives:</span>
                          {t.objectiveIds.map((oid) => (
                            <span key={oid} className="text-[10px] font-mono bg-blue-50 text-blue-600 rounded px-1">{oid}</span>
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
                {closedTasks.length === 0 && <p className="text-sm text-gray-400 italic">No closed tasks.</p>}
                {closedTasks.map((t) => (
                  <div key={t.id} className="flex items-start gap-3 p-2 rounded-lg hover:bg-gray-50">
                    <span className="font-mono text-xs font-bold text-gray-500 bg-gray-100 rounded px-1.5 py-0.5 shrink-0">
                      {t.id}
                    </span>
                    <div className="min-w-0">
                      <div className="text-sm font-medium text-gray-800">{t.title}</div>
                      <div className="flex flex-wrap gap-2 mt-1 text-xs text-gray-500">
                        <span className="bg-gray-100 rounded px-1.5 py-0.5">{t.status}</span>
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
                {data.decisions.length === 0 && <p className="text-sm text-gray-400 italic">No decisions recorded.</p>}
                {data.decisions.map((d) => (
                  <div key={d.id} className="p-2 rounded-lg hover:bg-gray-50">
                    <div className="flex items-center gap-2">
                      <span className="font-mono text-xs font-bold text-amber-700 bg-amber-100 rounded px-1.5 py-0.5 shrink-0">
                        {d.id}
                      </span>
                      <span className="text-sm font-medium text-gray-800">{d.title}</span>
                      {d.date && <span className="text-xs text-gray-400 ml-auto">{d.date}</span>}
                    </div>
                    {d.decision && (
                      <p className="text-xs text-gray-600 mt-1 ml-10"><span className="font-medium">Decision:</span> {d.decision}</p>
                    )}
                    {d.reason && (
                      <p className="text-xs text-gray-500 mt-0.5 ml-10"><span className="font-medium">Reason:</span> {d.reason}</p>
                    )}
                    {d.tags.length > 0 && (
                      <div className="flex gap-1 mt-1 ml-10">
                        {d.tags.map((tag) => (
                          <span key={tag} className="text-[10px] bg-gray-100 text-gray-500 rounded px-1.5 py-0.5">{tag}</span>
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
                  <tr className="text-left text-xs text-gray-400 border-b border-gray-100">
                    <th className="pb-2 font-medium">Team</th>
                    <th className="pb-2 font-medium">Lead</th>
                    <th className="pb-2 font-medium text-center">Members</th>
                    <th className="pb-2 font-medium">Reports to</th>
                  </tr>
                </thead>
                <tbody>
                  {data.teams.map((team) => (
                    <React.Fragment key={team.name}>
                      <tr className="border-b border-gray-50 hover:bg-gray-50">
                        <td className="py-2 font-semibold text-gray-800">{team.name}</td>
                        <td className="py-2 text-gray-600">{team.lead}</td>
                        <td className="py-2 text-center text-gray-500">{team.members?.length ?? "—"}</td>
                        <td className="py-2 text-gray-400 text-xs">{team.reportsTo ?? "—"}</td>
                      </tr>
                      {team.subTeams && team.subTeams.map((sub) => (
                        <tr key={sub.name} className="border-b border-gray-50 hover:bg-gray-50">
                          <td className="py-1.5 pl-5 text-gray-700">
                            <span className="text-gray-300 mr-1">└</span>{sub.name}
                          </td>
                          <td className="py-1.5 text-gray-600">{sub.lead}</td>
                          <td className="py-1.5 text-center text-gray-500">{sub.members?.length ?? "—"}</td>
                          <td className="py-1.5 text-gray-400 text-xs">{sub.reportsTo ?? "—"}</td>
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
                  <div key={s.tag} className="flex items-center gap-3 p-2 rounded-lg hover:bg-gray-50">
                    <span className="text-xs font-mono font-bold text-rose-600 bg-rose-50 rounded px-2 py-0.5 shrink-0 w-24 text-center">
                      {s.tag}
                    </span>
                    <div>
                      <span className="text-sm font-medium text-gray-800">{s.name}</span>
                      <span className="text-xs text-gray-400 ml-2">— {s.purpose}</span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}

      {/* Latest weekly */}
      <div className="rounded-xl border border-gray-200 bg-white p-4">
        <h3 className="font-semibold text-gray-700 mb-2">
          Latest Weekly Summary
        </h3>
        {latestWeekly ? (
          <div>
            <button
              onClick={() => onNavigate("weekly")}
              className="text-sm text-blue-600 hover:text-blue-800 cursor-pointer"
            >
              📄 {latestWeekly.filename} →
            </button>
          </div>
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
