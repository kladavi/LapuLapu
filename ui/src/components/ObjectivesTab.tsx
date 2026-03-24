"use client";

import React, { useState, useMemo } from "react";
import { usePMData } from "../context/PMContext";
import type { Objective } from "../lib/types";

const OWNER_FILTERS = [
  { label: "All", value: "" },
  { label: "Hari", value: "#hari" },
  { label: "Debamalya", value: "#debamalya" },
  { label: "David", value: "#davidklan" },
  { label: "Birger", value: "#birger" },
  { label: "Kelvin", value: "#kelvin" },
  { label: "Jonan", value: "#jonan" },
];

export function ObjectivesTab() {
  const { data } = usePMData();
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [ownerFilter, setOwnerFilter] = useState("");
  const [tagFilter, setTagFilter] = useState("");

  const filtered = useMemo(() => {
    if (!data) return [];
    let objs = data.objectives;

    if (ownerFilter) {
      objs = objs.filter((o) =>
        o.tags.some((t) => t.toLowerCase() === ownerFilter.toLowerCase())
      );
    }

    if (tagFilter) {
      const search = tagFilter.toLowerCase();
      objs = objs.filter(
        (o) =>
          o.tags.some((t) => t.toLowerCase().includes(search)) ||
          o.title.toLowerCase().includes(search) ||
          o.id.toLowerCase().includes(search)
      );
    }

    return objs;
  }, [data, ownerFilter, tagFilter]);

  const tiers = useMemo(() => {
    const grouped: Record<number, Objective[]> = { 1: [], 2: [], 3: [] };
    for (const o of filtered) {
      if (!grouped[o.tier]) grouped[o.tier] = [];
      grouped[o.tier].push(o);
    }
    return grouped;
  }, [filtered]);

  const selected = useMemo(
    () => data?.objectives.find((o) => o.id === selectedId) || null,
    [data, selectedId]
  );

  const relatedTasks = useMemo(() => {
    if (!selected || !data) return [];
    return data.tasks.filter((t) => t.objectiveIds.includes(selected.id));
  }, [data, selected]);

  if (!data) return null;

  return (
    <div className="flex flex-1 h-full">
      {/* List panel */}
      <div
        className={`${
          selected ? "w-1/2" : "w-full"
        } border-r border-gray-200 overflow-auto`}
      >
        <div className="p-4 space-y-4">
          {/* Filters */}
          <div className="flex flex-wrap gap-3 items-center">
            <div className="flex gap-1">
              {OWNER_FILTERS.map((f) => (
                <button
                  key={f.value}
                  onClick={() => setOwnerFilter(f.value)}
                  className={`px-3 py-1 text-xs rounded-full border cursor-pointer transition-colors ${
                    ownerFilter === f.value
                      ? "bg-blue-600 text-white border-blue-600"
                      : "bg-white text-gray-600 border-gray-300 hover:border-blue-400"
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
              className="text-sm border border-gray-300 rounded-lg px-3 py-1.5 w-48 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {/* Tier groups */}
          {([1, 2, 3] as const).map((tier) => {
            const objs = tiers[tier] || [];
            if (objs.length === 0) return null;
            return (
              <div key={tier}>
                <h3 className="text-sm font-bold text-gray-500 uppercase tracking-wider mb-2">
                  Tier-{tier}{" "}
                  <span className="text-gray-400 font-normal">
                    ({objs.length})
                  </span>
                </h3>
                <div className="space-y-2">
                  {objs.map((o) => (
                    <button
                      key={o.id}
                      onClick={() =>
                        setSelectedId(selectedId === o.id ? null : o.id)
                      }
                      className={`w-full text-left rounded-lg border p-3 transition-colors cursor-pointer ${
                        selectedId === o.id
                          ? "border-blue-500 bg-blue-50"
                          : "border-gray-200 bg-white hover:border-blue-300"
                      }`}
                    >
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-mono font-bold text-blue-600 bg-blue-100 rounded px-1.5 py-0.5">
                          {o.id}
                        </span>
                        <span className="font-medium text-sm text-gray-800">
                          {o.title}
                        </span>
                      </div>
                      <div className="flex flex-wrap gap-1 mt-1.5">
                        {o.tags.slice(0, 6).map((t) => (
                          <span
                            key={t}
                            className="text-[10px] bg-gray-100 text-gray-500 rounded px-1.5 py-0.5"
                          >
                            {t}
                          </span>
                        ))}
                        {o.tags.length > 6 && (
                          <span className="text-[10px] text-gray-400">
                            +{o.tags.length - 6}
                          </span>
                        )}
                      </div>
                    </button>
                  ))}
                </div>
              </div>
            );
          })}

          {filtered.length === 0 && (
            <p className="text-gray-400 italic text-sm">
              No objectives match the current filters.
            </p>
          )}
        </div>
      </div>

      {/* Detail panel */}
      {selected && (
        <div className="w-1/2 overflow-auto p-6 space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="text-sm font-mono font-bold text-blue-600 bg-blue-100 rounded px-2 py-1">
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
              ✕
            </button>
          </div>

          <h2 className="text-lg font-bold text-gray-800">{selected.title}</h2>

          {/* Parent objectives */}
          {selected.parentObjectiveIds.length > 0 && (
            <div>
              <h4 className="text-xs font-bold text-gray-500 uppercase mb-1">
                Parent Objectives
              </h4>
              <div className="flex gap-2">
                {selected.parentObjectiveIds.map((pid) => {
                  const parent = data.objectives.find((o) => o.id === pid);
                  return (
                    <button
                      key={pid}
                      onClick={() => setSelectedId(pid)}
                      className="text-xs bg-blue-50 text-blue-700 border border-blue-200 rounded px-2 py-1 hover:bg-blue-100 cursor-pointer"
                    >
                      {pid}
                      {parent ? ` — ${parent.title}` : ""}
                    </button>
                  );
                })}
              </div>
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
                  className="text-xs bg-gray-100 text-gray-600 rounded-full px-2 py-0.5"
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
              <ul className="text-xs text-gray-500 space-y-0.5">
                {selected.source.map((s, i) => (
                  <li key={i}>• {s}</li>
                ))}
              </ul>
            </div>
          )}

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
                    className="text-sm border border-gray-200 rounded-lg p-2 bg-gray-50"
                  >
                    <span className="font-mono text-xs font-bold text-green-700">
                      {t.id}
                    </span>{" "}
                    <span className="text-gray-700">{t.title}</span>
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
