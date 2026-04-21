"use client";

import React, { useState, useMemo, useCallback } from "react";
import { usePMData } from "../context/PMContext";
import type { KeyResult, KeyResultStatus } from "../lib/types";
import {
  computeKRProgress,
  ensureProjectTag,
  nextKRId,
  serializeKeyResults,
} from "../lib/parsers";

// ── Status colours ──
const STATUS_COLORS: Record<KeyResultStatus, string> = {
  "Not Started": "bg-gray-100 text-gray-600",
  "On Track": "bg-green-100 text-green-700",
  "At Risk": "bg-yellow-100 text-yellow-700",
  Behind: "bg-red-100 text-red-700",
  Complete: "bg-blue-100 text-blue-700",
};

const ALL_STATUSES: KeyResultStatus[] = [
  "Not Started",
  "On Track",
  "At Risk",
  "Behind",
  "Complete",
];

type SortKey = "targetDate" | "progress" | "status" | "id";
type ViewMode = "list" | "detail";

// ── Progress bar ──
function ProgressBar({
  value,
  className = "",
}: {
  value: number;
  className?: string;
}) {
  const color =
    value >= 75
      ? "bg-green-500"
      : value >= 50
        ? "bg-yellow-500"
        : value >= 25
          ? "bg-orange-500"
          : "bg-red-500";
  return (
    <div
      className={`w-full bg-th-surface-alt rounded-full h-2.5 ${className}`}
    >
      <div
        className={`h-2.5 rounded-full transition-all ${color}`}
        style={{ width: `${Math.min(value, 100)}%` }}
      />
    </div>
  );
}

// ── Empty form state ──
function emptyKRForm(
  id: string,
  today: string
): Omit<KeyResult, "raw" | "progressLog" | "changeLog"> {
  return {
    id,
    title: "",
    objectiveId: "",
    metricType: "numeric",
    startValue: 0,
    targetValue: 100,
    currentValue: 0,
    targetDate: "",
    status: "Not Started",
    created: today,
    tags: [],
    description: "",
  };
}

export function KeyResultsTab() {
  const { data, loadFiles } = usePMData();
  const [viewMode, setViewMode] = useState<ViewMode>("list");
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [objectiveFilter, setObjectiveFilter] = useState("");
  const [statusFilter, setStatusFilter] = useState<KeyResultStatus | "">("");
  const [searchQuery, setSearchQuery] = useState("");
  const [sortKey, setSortKey] = useState<SortKey>("id");
  const [showForm, setShowForm] = useState(false);
  const [editingKR, setEditingKR] = useState<KeyResult | null>(null);
  const [showProgressForm, setShowProgressForm] = useState(false);
  const [saving, setSaving] = useState(false);

  // Form state
  const today = new Date().toISOString().slice(0, 10);
  const [formData, setFormData] = useState(
    emptyKRForm(nextKRId(data?.keyResults ?? []), today)
  );
  const [formTags, setFormTags] = useState("");
  const [progressDate, setProgressDate] = useState(today);
  const [progressValue, setProgressValue] = useState("");
  const [progressComment, setProgressComment] = useState("");
  const defaultProjectSlug =
    data?.settings?.project?.defaultProjectSlug || data?.projects?.[0]?.slug || "";

  // Objectives for dropdown
  const objectives = useMemo(() => data?.objectives ?? [], [data]);

  // Count KRs per objective
  const krCountByObjective = useMemo(() => {
    const counts: Record<string, number> = {};
    (data?.keyResults ?? []).forEach((kr) => {
      counts[kr.objectiveId] = (counts[kr.objectiveId] || 0) + 1;
    });
    return counts;
  }, [data]);

  // Filtered and sorted KRs
  const filteredKRs = useMemo(() => {
    if (!data) return [];
    let krs = [...data.keyResults];

    if (objectiveFilter) {
      krs = krs.filter((kr) => kr.objectiveId === objectiveFilter);
    }
    if (statusFilter) {
      krs = krs.filter((kr) => kr.status === statusFilter);
    }
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      krs = krs.filter(
        (kr) =>
          kr.title.toLowerCase().includes(q) ||
          kr.id.toLowerCase().includes(q) ||
          kr.tags.some((t) => t.toLowerCase().includes(q)) ||
          kr.description.toLowerCase().includes(q)
      );
    }

    // Sort
    krs.sort((a, b) => {
      switch (sortKey) {
        case "targetDate":
          return a.targetDate.localeCompare(b.targetDate);
        case "progress":
          return computeKRProgress(b) - computeKRProgress(a);
        case "status": {
          const order = ALL_STATUSES;
          return order.indexOf(a.status) - order.indexOf(b.status);
        }
        case "id":
        default:
          return a.id.localeCompare(b.id);
      }
    });

    return krs;
  }, [data, objectiveFilter, statusFilter, searchQuery, sortKey]);

  const selected = useMemo(
    () => data?.keyResults.find((kr) => kr.id === selectedId) ?? null,
    [data, selectedId]
  );

  // ── Save key results to file ──
  const saveKeyResults = useCallback(
    async (updatedKRs: KeyResult[]) => {
      setSaving(true);
      try {
        const content = serializeKeyResults(updatedKRs);
        const res = await fetch("/api/save-local", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            filePath: "02-work/key-results.md",
            content,
          }),
        });
        if (!res.ok) throw new Error("Save failed");

        // Reload data
        const loadRes = await fetch("/api/load-local");
        if (loadRes.ok) {
          const { files, folderName } = await loadRes.json();
          loadFiles(files, folderName);
        }
      } catch (err) {
        console.error("Failed to save key results:", err);
      } finally {
        setSaving(false);
      }
    },
    [loadFiles]
  );

  // ── Create / Update KR ──
  const handleSaveForm = useCallback(async () => {
    if (!data) return;
    const tags = ensureProjectTag(
      formTags
        .split(/\s+/)
        .filter((t) => t.startsWith("#") && t.length > 1),
      defaultProjectSlug
    );
    const isEdit = editingKR !== null;

    const kr: KeyResult = {
      ...formData,
      tags,
      raw: "",
      progressLog: isEdit ? editingKR.progressLog : [],
      changeLog: isEdit
        ? [
            ...editingKR.changeLog,
            { date: today, change: "Definition updated" },
          ]
        : [{ date: today, change: "Created" }],
    };

    // If editing and definition fields changed, add specific change log entries
    if (isEdit) {
      const changes: string[] = [];
      if (editingKR.title !== kr.title)
        changes.push(`Title changed from "${editingKR.title}" to "${kr.title}"`);
      if (editingKR.targetValue !== kr.targetValue)
        changes.push(
          `Target Value changed from ${editingKR.targetValue} to ${kr.targetValue}`
        );
      if (editingKR.targetDate !== kr.targetDate)
        changes.push(
          `Target Date changed from ${editingKR.targetDate} to ${kr.targetDate}`
        );
      if (editingKR.status !== kr.status)
        changes.push(
          `Status changed from "${editingKR.status}" to "${kr.status}"`
        );
      if (editingKR.objectiveId !== kr.objectiveId)
        changes.push(
          `Objective changed from ${editingKR.objectiveId} to ${kr.objectiveId}`
        );
      if (changes.length > 0) {
        // Replace the generic "Definition updated" with specific changes
        kr.changeLog = [
          ...editingKR.changeLog,
          ...changes.map((c) => ({ date: today, change: c })),
        ];
      }
    }

    let updatedKRs: KeyResult[];
    if (isEdit) {
      updatedKRs = data.keyResults.map((existing) =>
        existing.id === kr.id ? kr : existing
      );
    } else {
      updatedKRs = [...data.keyResults, kr];
    }

    await saveKeyResults(updatedKRs);
    setShowForm(false);
    setEditingKR(null);
    setSelectedId(kr.id);
  }, [data, defaultProjectSlug, formData, formTags, editingKR, today, saveKeyResults]);

  // ── Add Progress Entry ──
  const handleAddProgress = useCallback(async () => {
    if (!data || !selected) return;
    const value = parseFloat(progressValue);
    if (isNaN(value)) return;

    const updatedKR: KeyResult = {
      ...selected,
      currentValue: value,
      progressLog: [
        ...selected.progressLog,
        { date: progressDate, value, comment: progressComment },
      ],
    };

    const updatedKRs = data.keyResults.map((kr) =>
      kr.id === selected.id ? updatedKR : kr
    );

    await saveKeyResults(updatedKRs);
    setShowProgressForm(false);
    setProgressValue("");
    setProgressComment("");
  }, [
    data,
    selected,
    progressDate,
    progressValue,
    progressComment,
    saveKeyResults,
  ]);

  // ── Open edit form ──
  const openEditForm = useCallback(
    (kr: KeyResult) => {
      setFormData({
        id: kr.id,
        title: kr.title,
        objectiveId: kr.objectiveId,
        metricType: kr.metricType,
        startValue: kr.startValue,
        targetValue: kr.targetValue,
        currentValue: kr.currentValue,
        targetDate: kr.targetDate,
        status: kr.status,
        created: kr.created,
        tags: kr.tags,
        description: kr.description,
      });
      setFormTags(ensureProjectTag(kr.tags, defaultProjectSlug).join(" "));
      setEditingKR(kr);
      setShowForm(true);
    },
    [defaultProjectSlug]
  );

  // ── Open create form ──
  const openCreateForm = useCallback(() => {
    const id = nextKRId(data?.keyResults ?? []);
    setFormData(emptyKRForm(id, today));
    setFormTags(ensureProjectTag([], defaultProjectSlug).join(" "));
    setEditingKR(null);
    setShowForm(true);
  }, [data, defaultProjectSlug, today]);

  if (!data) return null;

  // ── Objective label helper ──
  const objLabel = (id: string) => {
    const obj = objectives.find((o) => o.id === id);
    return obj ? `${id} — ${obj.title}` : id;
  };

  // ── Objectives with zero KRs (for warnings) ──
  const objectivesWithNoKRs = objectives.filter(
    (o) => !krCountByObjective[o.id]
  );

  return (
    <div className="flex flex-1 h-full">
      {/* ── Main Panel ── */}
      <div
        className={`${selected && viewMode === "list" ? "w-1/2" : "w-full"} border-r border-th-border overflow-auto`}
      >
        <div className="p-4 space-y-4">
          {/* Controls */}
          <div className="flex flex-wrap gap-3 items-center justify-between">
            <h2 className="text-lg font-bold text-th-text">
              Key Results{" "}
              <span className="text-sm font-normal text-th-text-muted">
                ({filteredKRs.length})
              </span>
            </h2>
            <button
              onClick={openCreateForm}
              disabled={saving}
              className="inline-flex items-center gap-1.5 rounded-lg bg-th-accent px-4 py-2 text-sm text-white font-medium hover:bg-th-accent-hover transition-colors cursor-pointer disabled:opacity-50"
            >
              ➕ New Key Result
            </button>
          </div>

          {/* Filters */}
          <div className="flex flex-wrap gap-3 items-center">
            {/* Objective filter */}
            <select
              value={objectiveFilter}
              onChange={(e) => setObjectiveFilter(e.target.value)}
              className="rounded-lg border border-th-border bg-th-surface px-3 py-1.5 text-sm text-th-text"
            >
              <option value="">All Objectives</option>
              {objectives.map((o) => (
                <option key={o.id} value={o.id}>
                  {o.id} — {o.title}
                  {!krCountByObjective[o.id] ? " ⚠️ No KRs" : ""}
                  {(krCountByObjective[o.id] ?? 0) > 5 ? " ⚠️ >5 KRs" : ""}
                </option>
              ))}
            </select>

            {/* Status filter */}
            <select
              value={statusFilter}
              onChange={(e) =>
                setStatusFilter(e.target.value as KeyResultStatus | "")
              }
              className="rounded-lg border border-th-border bg-th-surface px-3 py-1.5 text-sm text-th-text"
            >
              <option value="">All Statuses</option>
              {ALL_STATUSES.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>

            {/* Search */}
            <input
              type="text"
              placeholder="Search title, tags…"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="rounded-lg border border-th-border bg-th-surface px-3 py-1.5 text-sm text-th-text flex-1 min-w-[200px]"
            />

            {/* Sort */}
            <select
              value={sortKey}
              onChange={(e) => setSortKey(e.target.value as SortKey)}
              className="rounded-lg border border-th-border bg-th-surface px-3 py-1.5 text-sm text-th-text"
            >
              <option value="id">Sort: ID</option>
              <option value="targetDate">Sort: Target Date</option>
              <option value="progress">Sort: Progress</option>
              <option value="status">Sort: Status</option>
            </select>
          </div>

          {/* Warnings */}
          {objectivesWithNoKRs.length > 0 && !objectiveFilter && (
            <div className="bg-yellow-50 border border-yellow-200 rounded-lg px-4 py-2 text-sm text-yellow-700">
              ⚠️ {objectivesWithNoKRs.length} objective(s) have no Key Results:{" "}
              {objectivesWithNoKRs
                .slice(0, 5)
                .map((o) => o.id)
                .join(", ")}
              {objectivesWithNoKRs.length > 5 && " …"}
            </div>
          )}

          {objectiveFilter &&
            (krCountByObjective[objectiveFilter] ?? 0) > 5 && (
              <div className="bg-yellow-50 border border-yellow-200 rounded-lg px-4 py-2 text-sm text-yellow-700">
                ⚠️ Consider decomposing —{" "}
                {krCountByObjective[objectiveFilter]} KRs linked to{" "}
                {objectiveFilter}
              </div>
            )}

          {/* KR List */}
          {filteredKRs.length === 0 ? (
            <div className="text-center py-12 text-th-text-muted">
              <div className="text-4xl mb-3">📈</div>
              <p>No Key Results found.</p>
              <button
                onClick={openCreateForm}
                className="mt-3 text-sm text-th-accent hover:text-th-accent-hover cursor-pointer"
              >
                Create your first Key Result →
              </button>
            </div>
          ) : (
            <div className="space-y-2">
              {filteredKRs.map((kr) => {
                const progress = computeKRProgress(kr);
                const isSelected = selectedId === kr.id;
                return (
                  <button
                    key={kr.id}
                    onClick={() => {
                      setSelectedId(kr.id);
                      setViewMode("list");
                    }}
                    className={`w-full text-left rounded-lg border p-4 transition-all cursor-pointer hover:shadow-sm ${
                      isSelected
                        ? "border-th-accent bg-th-accent-light ring-1 ring-th-accent"
                        : "border-th-border bg-th-surface hover:border-th-border-strong"
                    }`}
                  >
                    <div className="flex items-center justify-between gap-3 mb-2">
                      <div className="flex items-center gap-2 min-w-0">
                        <span className="text-xs font-mono text-th-text-muted">
                          {kr.id}
                        </span>
                        <span className="font-medium text-sm text-th-text truncate">
                          {kr.title}
                        </span>
                      </div>
                      <div className="flex items-center gap-2 flex-shrink-0">
                        <span
                          className={`text-[10px] font-medium rounded-full px-2 py-0.5 ${STATUS_COLORS[kr.status]}`}
                        >
                          {kr.status}
                        </span>
                      </div>
                    </div>
                    <div className="flex items-center gap-3">
                      <ProgressBar value={progress} className="flex-1" />
                      <span className="text-xs text-th-text-muted w-10 text-right">
                        {progress}%
                      </span>
                    </div>
                    <div className="flex items-center gap-3 mt-2 text-xs text-th-text-faint">
                      <span>🎯 {kr.objectiveId}</span>
                      <span>📅 {kr.targetDate || "—"}</span>
                      <span>
                        {kr.metricType === "boolean"
                          ? "☑️ Boolean"
                          : `📊 ${kr.currentValue} / ${kr.targetValue}`}
                      </span>
                    </div>
                  </button>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {/* ── Detail Panel ── */}
      {selected && viewMode === "list" && (
        <div className="w-1/2 overflow-auto bg-th-surface">
          <div className="p-6 space-y-6">
            {/* Header */}
            <div className="flex items-center justify-between">
              <div>
                <div className="flex items-center gap-2 mb-1">
                  <span className="text-xs font-mono text-th-text-muted">
                    {selected.id}
                  </span>
                  <span
                    className={`text-[10px] font-medium rounded-full px-2 py-0.5 ${STATUS_COLORS[selected.status]}`}
                  >
                    {selected.status}
                  </span>
                </div>
                <h3 className="text-lg font-bold text-th-text">
                  {selected.title}
                </h3>
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() => openEditForm(selected)}
                  disabled={saving}
                  className="text-sm text-th-accent hover:text-th-accent-hover cursor-pointer disabled:opacity-50"
                >
                  ✏️ Edit
                </button>
                <button
                  onClick={() => setSelectedId(null)}
                  className="text-sm text-th-text-muted hover:text-th-text cursor-pointer"
                >
                  ✕
                </button>
              </div>
            </div>

            {/* Info */}
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <span className="text-th-text-muted">Objective</span>
                <p className="font-medium text-th-text">
                  {objLabel(selected.objectiveId)}
                </p>
              </div>
              <div>
                <span className="text-th-text-muted">Metric Type</span>
                <p className="font-medium text-th-text capitalize">
                  {selected.metricType}
                </p>
              </div>
              <div>
                <span className="text-th-text-muted">Progress</span>
                <div className="flex items-center gap-2 mt-1">
                  <ProgressBar
                    value={computeKRProgress(selected)}
                    className="flex-1"
                  />
                  <span className="font-medium text-th-text">
                    {computeKRProgress(selected)}%
                  </span>
                </div>
              </div>
              <div>
                <span className="text-th-text-muted">Target Date</span>
                <p className="font-medium text-th-text">
                  {selected.targetDate || "—"}
                </p>
              </div>
              <div>
                <span className="text-th-text-muted">Values</span>
                <p className="font-medium text-th-text">
                  {selected.startValue} → {selected.currentValue} →{" "}
                  {selected.targetValue}
                </p>
              </div>
              <div>
                <span className="text-th-text-muted">Created</span>
                <p className="font-medium text-th-text">
                  {selected.created || "—"}
                </p>
              </div>
            </div>

            {/* Description */}
            {selected.description && (
              <div>
                <h4 className="text-sm font-semibold text-th-text-muted mb-1">
                  Description
                </h4>
                <p className="text-sm text-th-text">{selected.description}</p>
              </div>
            )}

            {/* Tags */}
            {selected.tags.length > 0 && (
              <div className="flex flex-wrap gap-1.5">
                {selected.tags.map((tag) => (
                  <span
                    key={tag}
                    className="text-xs bg-th-surface-alt text-th-text-muted rounded px-2 py-0.5"
                  >
                    {tag}
                  </span>
                ))}
              </div>
            )}

            {/* Progress Log */}
            <div>
              <div className="flex items-center justify-between mb-2">
                <h4 className="text-sm font-semibold text-th-text-muted">
                  Progress Log ({selected.progressLog.length})
                </h4>
                <button
                  onClick={() => {
                    setShowProgressForm(true);
                    setProgressDate(today);
                    setProgressValue("");
                    setProgressComment("");
                  }}
                  disabled={saving}
                  className="text-xs text-th-accent hover:text-th-accent-hover cursor-pointer disabled:opacity-50"
                >
                  + Add Progress
                </button>
              </div>

              {/* Progress entry form */}
              {showProgressForm && (
                <div className="border border-th-border rounded-lg p-3 mb-3 space-y-2 bg-th-surface-alt">
                  <div className="grid grid-cols-3 gap-2">
                    <div>
                      <label className="text-xs text-th-text-muted">Date</label>
                      <input
                        type="date"
                        value={progressDate}
                        onChange={(e) => setProgressDate(e.target.value)}
                        className="w-full rounded border border-th-border bg-th-surface px-2 py-1 text-sm"
                      />
                    </div>
                    <div>
                      <label className="text-xs text-th-text-muted">
                        Value
                      </label>
                      <input
                        type="number"
                        step="any"
                        value={progressValue}
                        onChange={(e) => setProgressValue(e.target.value)}
                        placeholder={
                          selected.metricType === "boolean" ? "0 or 1" : "Value"
                        }
                        className="w-full rounded border border-th-border bg-th-surface px-2 py-1 text-sm"
                      />
                    </div>
                    <div>
                      <label className="text-xs text-th-text-muted">
                        Comment
                      </label>
                      <input
                        type="text"
                        value={progressComment}
                        onChange={(e) => setProgressComment(e.target.value)}
                        placeholder="Progress note"
                        className="w-full rounded border border-th-border bg-th-surface px-2 py-1 text-sm"
                      />
                    </div>
                  </div>
                  <div className="flex gap-2 justify-end">
                    <button
                      onClick={() => setShowProgressForm(false)}
                      className="text-xs text-th-text-muted hover:text-th-text cursor-pointer"
                    >
                      Cancel
                    </button>
                    <button
                      onClick={handleAddProgress}
                      disabled={saving || !progressValue}
                      className="text-xs bg-th-accent text-white rounded px-3 py-1 hover:bg-th-accent-hover cursor-pointer disabled:opacity-50"
                    >
                      Save Entry
                    </button>
                  </div>
                </div>
              )}

              {/* Progress table */}
              {selected.progressLog.length > 0 ? (
                <div className="overflow-auto rounded-lg border border-th-border">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="bg-th-surface-alt text-th-text-muted text-xs">
                        <th className="px-3 py-2 text-left">Date</th>
                        <th className="px-3 py-2 text-right">Value</th>
                        <th className="px-3 py-2 text-left">Comment</th>
                      </tr>
                    </thead>
                    <tbody>
                      {[...selected.progressLog].reverse().map((entry, i) => (
                        <tr
                          key={i}
                          className="border-t border-th-border hover:bg-th-surface-alt"
                        >
                          <td className="px-3 py-2 text-th-text-muted">
                            {entry.date}
                          </td>
                          <td className="px-3 py-2 text-right font-mono">
                            {entry.value}
                          </td>
                          <td className="px-3 py-2 text-th-text">
                            {entry.comment}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <p className="text-xs text-th-text-faint">
                  No progress entries yet.
                </p>
              )}
            </div>

            {/* Change Log */}
            <div>
              <h4 className="text-sm font-semibold text-th-text-muted mb-2">
                Change Log ({selected.changeLog.length})
              </h4>
              {selected.changeLog.length > 0 ? (
                <div className="overflow-auto rounded-lg border border-th-border">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="bg-th-surface-alt text-th-text-muted text-xs">
                        <th className="px-3 py-2 text-left">Date</th>
                        <th className="px-3 py-2 text-left">Change</th>
                      </tr>
                    </thead>
                    <tbody>
                      {[...selected.changeLog].reverse().map((entry, i) => (
                        <tr
                          key={i}
                          className="border-t border-th-border hover:bg-th-surface-alt"
                        >
                          <td className="px-3 py-2 text-th-text-muted">
                            {entry.date}
                          </td>
                          <td className="px-3 py-2 text-th-text">
                            {entry.change}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <p className="text-xs text-th-text-faint">No changes logged.</p>
              )}
            </div>
          </div>
        </div>
      )}

      {/* ── Create/Edit Form Modal ── */}
      {showForm && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50">
          <div className="bg-th-surface rounded-xl shadow-xl max-w-lg w-full max-h-[90vh] overflow-auto p-6 space-y-4">
            <h3 className="text-lg font-bold text-th-text">
              {editingKR ? `Edit ${editingKR.id}` : "New Key Result"}
            </h3>

            {/* Title */}
            <div>
              <label className="text-sm text-th-text-muted">Title *</label>
              <input
                type="text"
                value={formData.title}
                onChange={(e) =>
                  setFormData((p) => ({ ...p, title: e.target.value }))
                }
                placeholder="e.g. Reduce P1 MTTR to <2.5 hours"
                className="w-full rounded-lg border border-th-border bg-th-surface px-3 py-2 text-sm"
              />
            </div>

            {/* Objective */}
            <div>
              <label className="text-sm text-th-text-muted">Objective *</label>
              <select
                value={formData.objectiveId}
                onChange={(e) =>
                  setFormData((p) => ({ ...p, objectiveId: e.target.value }))
                }
                className="w-full rounded-lg border border-th-border bg-th-surface px-3 py-2 text-sm"
              >
                <option value="">Select objective…</option>
                {objectives.map((o) => (
                  <option key={o.id} value={o.id}>
                    {o.id} — {o.title}
                  </option>
                ))}
              </select>
            </div>

            {/* Metric Type */}
            <div>
              <label className="text-sm text-th-text-muted">Metric Type</label>
              <div className="flex gap-3 mt-1">
                <label className="flex items-center gap-1.5 text-sm cursor-pointer">
                  <input
                    type="radio"
                    name="metricType"
                    checked={formData.metricType === "numeric"}
                    onChange={() => {
                      setFormData((p) => ({
                        ...p,
                        metricType: "numeric",
                        startValue: 0,
                        targetValue: 100,
                      }));
                    }}
                  />
                  Numeric
                </label>
                <label className="flex items-center gap-1.5 text-sm cursor-pointer">
                  <input
                    type="radio"
                    name="metricType"
                    checked={formData.metricType === "boolean"}
                    onChange={() => {
                      setFormData((p) => ({
                        ...p,
                        metricType: "boolean",
                        startValue: 0,
                        targetValue: 1,
                        currentValue: 0,
                      }));
                    }}
                  />
                  Boolean
                </label>
              </div>
            </div>

            {/* Values (numeric only) */}
            {formData.metricType === "numeric" && (
              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="text-sm text-th-text-muted">
                    Start Value
                  </label>
                  <input
                    type="number"
                    step="any"
                    value={formData.startValue}
                    onChange={(e) =>
                      setFormData((p) => ({
                        ...p,
                        startValue: parseFloat(e.target.value) || 0,
                      }))
                    }
                    className="w-full rounded-lg border border-th-border bg-th-surface px-3 py-2 text-sm"
                  />
                </div>
                <div>
                  <label className="text-sm text-th-text-muted">
                    Target Value
                  </label>
                  <input
                    type="number"
                    step="any"
                    value={formData.targetValue}
                    onChange={(e) =>
                      setFormData((p) => ({
                        ...p,
                        targetValue: parseFloat(e.target.value) || 0,
                      }))
                    }
                    className="w-full rounded-lg border border-th-border bg-th-surface px-3 py-2 text-sm"
                  />
                </div>
                <div>
                  <label className="text-sm text-th-text-muted">
                    Current Value
                  </label>
                  <input
                    type="number"
                    step="any"
                    value={formData.currentValue}
                    onChange={(e) =>
                      setFormData((p) => ({
                        ...p,
                        currentValue: parseFloat(e.target.value) || 0,
                      }))
                    }
                    className="w-full rounded-lg border border-th-border bg-th-surface px-3 py-2 text-sm"
                  />
                </div>
              </div>
            )}

            {/* Target Date */}
            <div>
              <label className="text-sm text-th-text-muted">
                Target Date *
              </label>
              <input
                type="date"
                value={formData.targetDate}
                onChange={(e) =>
                  setFormData((p) => ({ ...p, targetDate: e.target.value }))
                }
                className="w-full rounded-lg border border-th-border bg-th-surface px-3 py-2 text-sm"
              />
            </div>

            {/* Status */}
            <div>
              <label className="text-sm text-th-text-muted">Status</label>
              <select
                value={formData.status}
                onChange={(e) =>
                  setFormData((p) => ({
                    ...p,
                    status: e.target.value as KeyResultStatus,
                  }))
                }
                className="w-full rounded-lg border border-th-border bg-th-surface px-3 py-2 text-sm"
              >
                {ALL_STATUSES.map((s) => (
                  <option key={s} value={s}>
                    {s}
                  </option>
                ))}
              </select>
            </div>

            {/* Tags */}
            <div>
              <label className="text-sm text-th-text-muted">Tags</label>
              <input
                type="text"
                value={formTags}
                onChange={(e) => setFormTags(e.target.value)}
                placeholder="#project:lapu-lapu #domain:observability"
                className="w-full rounded-lg border border-th-border bg-th-surface px-3 py-2 text-sm"
              />
            </div>

            {/* Description */}
            <div>
              <label className="text-sm text-th-text-muted">Description</label>
              <textarea
                value={formData.description}
                onChange={(e) =>
                  setFormData((p) => ({ ...p, description: e.target.value }))
                }
                rows={3}
                placeholder="Brief description of this key result…"
                className="w-full rounded-lg border border-th-border bg-th-surface px-3 py-2 text-sm resize-y"
              />
            </div>

            {/* Actions */}
            <div className="flex gap-3 justify-end pt-2 border-t border-th-border">
              <button
                onClick={() => {
                  setShowForm(false);
                  setEditingKR(null);
                }}
                className="px-4 py-2 text-sm text-th-text-muted hover:text-th-text cursor-pointer"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveForm}
                disabled={
                  saving ||
                  !formData.title ||
                  !formData.objectiveId ||
                  !formData.targetDate
                }
                className="px-4 py-2 text-sm bg-th-accent text-white rounded-lg hover:bg-th-accent-hover cursor-pointer disabled:opacity-50"
              >
                {saving
                  ? "Saving…"
                  : editingKR
                    ? "Update Key Result"
                    : "Create Key Result"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
