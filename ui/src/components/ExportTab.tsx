"use client";

import React, { useState, useMemo } from "react";
import { usePMData } from "../context/PMContext";
import type { ExportOptions } from "../lib/types";
import type { ValidationError, ExportWarning } from "../lib/exporter";
import {
  generateExport,
  estimateExportSize,
  downloadFile,
} from "../lib/exporter";

export function ExportTab() {
  const { data } = usePMData();

  const [options, setOptions] = useState<ExportOptions>({
    includeObjectives: true,
    includeTeamsSystems: true,
    includeTasks: true,
    includeDecisions: true,
    includeWeeklySummaries: true,
    weeklySummaryCount: 1,
    includeInbox: false,
    format: "md",
  });

  const [preview, setPreview] = useState<string | null>(null);
  const [validationErrors, setValidationErrors] = useState<ValidationError[]>([]);
  const [exportWarnings, setExportWarnings] = useState<ExportWarning[]>([]);

  const estimatedSize = useMemo(() => {
    if (!data) return 0;
    return estimateExportSize(data, options);
  }, [data, options]);

  const toggles: {
    key: keyof ExportOptions;
    label: string;
    description: string;
  }[] = [
    {
      key: "includeObjectives",
      label: "Objectives",
      description: "Tier-1, Tier-2, and Tier-3 objectives registry",
    },
    {
      key: "includeTeamsSystems",
      label: "Teams & Systems",
      description: "Team structure and systems of record",
    },
    {
      key: "includeTasks",
      label: "Tasks",
      description: "All tasks from 02-work/tasks.md",
    },
    {
      key: "includeDecisions",
      label: "Decisions Log",
      description: "Deferred/rejected work decisions",
    },
    {
      key: "includeWeeklySummaries",
      label: "Weekly Summaries",
      description: "Latest weekly summary reports",
    },
    {
      key: "includeInbox",
      label: "Raw Inbox",
      description: "Unprocessed inbox items (usually excluded)",
    },
  ];

  const handleExport = () => {
    if (!data) return;
    setValidationErrors([]);
    setExportWarnings([]);
    const result = generateExport(data, options);
    if (result.errors.length > 0) {
      setValidationErrors(result.errors);
      return;
    }
    setExportWarnings(result.warnings);
    const ext = options.format === "json" ? "json" : "md";
    downloadFile(result.content, `copilot-pack.${ext}`);
  };

  const handlePreview = () => {
    if (!data) return;
    setValidationErrors([]);
    setExportWarnings([]);
    const result = generateExport(data, options);
    if (result.errors.length > 0) {
      setValidationErrors(result.errors);
      return;
    }
    setExportWarnings(result.warnings);
    setPreview(result.content);
  };

  if (!data) return null;

  function formatBytes(bytes: number): string {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  }

  return (
    <div className="p-6 max-w-3xl mx-auto space-y-6">
      <h2 className="text-xl font-bold text-gray-800">
        Export Copilot Pack
      </h2>
      <p className="text-sm text-gray-500">
        Generate a single compact file for upload to GitHub Copilot, ChatGPT, or
        any LLM. Archives and binary files are automatically excluded.
      </p>

      {/* Toggles */}
      <div className="rounded-xl border border-gray-200 bg-white divide-y divide-gray-100">
        {toggles.map((toggle) => (
          <label
            key={toggle.key}
            className="flex items-center justify-between p-4 cursor-pointer hover:bg-gray-50"
          >
            <div>
              <div className="text-sm font-medium text-gray-800">
                {toggle.label}
              </div>
              <div className="text-xs text-gray-400">{toggle.description}</div>
            </div>
            <input
              type="checkbox"
              checked={options[toggle.key] as boolean}
              onChange={(e) =>
                setOptions({ ...options, [toggle.key]: e.target.checked })
              }
              className="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
            />
          </label>
        ))}

        {/* Weekly count */}
        {options.includeWeeklySummaries && (
          <div className="flex items-center justify-between p-4">
            <div>
              <div className="text-sm font-medium text-gray-800">
                Include last N weeks
              </div>
              <div className="text-xs text-gray-400">
                {data.weeklySummaries.length} summary files available
              </div>
            </div>
            <input
              type="number"
              min={1}
              max={Math.max(data.weeklySummaries.length, 1)}
              value={options.weeklySummaryCount}
              onChange={(e) =>
                setOptions({
                  ...options,
                  weeklySummaryCount: parseInt(e.target.value) || 1,
                })
              }
              className="w-16 text-sm border border-gray-300 rounded px-2 py-1 text-center focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        )}
      </div>

      {/* Format */}
      <div className="rounded-xl border border-gray-200 bg-white p-4">
        <h3 className="text-sm font-semibold text-gray-700 mb-3">
          Export Format
        </h3>
        <div className="flex gap-3">
          <label
            className={`flex-1 flex items-center gap-3 rounded-lg border p-3 cursor-pointer ${
              options.format === "md"
                ? "border-blue-500 bg-blue-50"
                : "border-gray-200"
            }`}
          >
            <input
              type="radio"
              name="format"
              value="md"
              checked={options.format === "md"}
              onChange={() => setOptions({ ...options, format: "md" })}
              className="text-blue-600"
            />
            <div>
              <div className="text-sm font-medium">Copilot Pack (.md)</div>
              <div className="text-xs text-gray-400">
                YAML frontmatter + instructions + JSON data
              </div>
            </div>
          </label>
          <label
            className={`flex-1 flex items-center gap-3 rounded-lg border p-3 cursor-pointer ${
              options.format === "json"
                ? "border-blue-500 bg-blue-50"
                : "border-gray-200"
            }`}
          >
            <input
              type="radio"
              name="format"
              value="json"
              checked={options.format === "json"}
              onChange={() => setOptions({ ...options, format: "json" })}
              className="text-blue-600"
            />
            <div>
              <div className="text-sm font-medium">Copilot Pack (.json)</div>
              <div className="text-xs text-gray-400">
                Pure structured JSON data
              </div>
            </div>
          </label>
        </div>
      </div>

      {/* Size estimate + actions */}
      <div className="flex items-center justify-between rounded-xl border border-gray-200 bg-white p-4">
        <div>
          <div className="text-sm text-gray-500">Estimated export size</div>
          <div className="text-lg font-bold text-gray-800">
            {formatBytes(estimatedSize)}
          </div>
        </div>
        <div className="flex gap-3">
          <button
            onClick={handlePreview}
            className="px-4 py-2 text-sm border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 cursor-pointer"
          >
            Preview
          </button>
          <button
            onClick={handleExport}
            className="px-6 py-2 text-sm bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 cursor-pointer"
          >
            📦 Export
          </button>
        </div>
      </div>

      {/* Validation errors */}
      {validationErrors.length > 0 && (
        <div className="rounded-xl border border-red-300 bg-red-50 p-4 space-y-2">
          <h3 className="text-sm font-semibold text-red-800">
            ⚠️ Export validation failed ({validationErrors.length} issue{validationErrors.length > 1 ? "s" : ""})
          </h3>
          <ul className="text-xs text-red-700 space-y-1 max-h-48 overflow-auto">
            {validationErrors.map((err, i) => (
              <li key={i} className="flex gap-2">
                <span className="font-mono text-red-500">{err.entity}.{err.field}</span>
                <span>{err.message}</span>
              </li>
            ))}
          </ul>
          <p className="text-xs text-red-600 mt-1">
            Fix the source data and reload before exporting.
          </p>
        </div>
      )}

      {/* Export warnings (soft — export still succeeds) */}
      {exportWarnings.length > 0 && (
        <div className="rounded-xl border border-amber-300 bg-amber-50 p-4 space-y-2">
          <h3 className="text-sm font-semibold text-amber-800">
            ⚠️ Export warnings ({exportWarnings.length})
          </h3>
          <ul className="text-xs text-amber-700 space-y-1 max-h-48 overflow-auto">
            {exportWarnings.map((w, i) => (
              <li key={i} className="flex gap-2">
                <span className="font-mono text-amber-600">{w.taskId} → {w.objectiveId}</span>
                <span>{w.message}</span>
              </li>
            ))}
          </ul>
          <p className="text-xs text-amber-600 mt-1">
            Export completed. These tasks reference objectives outside the exported scope.
          </p>
        </div>
      )}

      {/* Preview */}
      {preview && (
        <div className="rounded-xl border border-gray-200 bg-white overflow-hidden">
          <div className="flex items-center justify-between px-4 py-2 bg-gray-50 border-b border-gray-200">
            <span className="text-sm font-medium text-gray-600">Preview</span>
            <button
              onClick={() => setPreview(null)}
              className="text-xs text-gray-400 hover:text-gray-600 cursor-pointer"
            >
              Close
            </button>
          </div>
          <pre className="p-4 text-xs text-gray-700 overflow-auto max-h-96 font-mono whitespace-pre-wrap">
            {preview}
          </pre>
        </div>
      )}
    </div>
  );
}
