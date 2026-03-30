"use client";

import React, { useState, useMemo } from "react";
import { usePMData } from "../context/PMContext";
import type { ExportOptions } from "../lib/types";
import type { ValidationError, ExportWarning, LintResult } from "../lib/exporter";
import {
  generateExport,
  estimateExportSize,
  downloadFile,
} from "../lib/exporter";

export function ExportTab() {
  const { data } = usePMData();

  const [options, setOptions] = useState<ExportOptions>({
    projectSlug: "",
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
  const [lintResult, setLintResult] = useState<LintResult | null>(null);
  const [initialized, setInitialized] = useState(false);

  // Initialize options from settings when data first loads
  React.useEffect(() => {
    if (data && !initialized) {
      const s = data.settings;
      const defaultSlug =
        s?.project?.defaultProjectSlug ||
        (data.projects.length > 0 ? data.projects[0].slug : "");
      setOptions((prev) => ({
        ...prev,
        projectSlug: defaultSlug,
        format: s?.export?.defaultFormat || prev.format,
        weeklySummaryCount: s?.export?.weeklySummaryCount || prev.weeklySummaryCount,
      }));
      setInitialized(true);
    }
  }, [data, initialized]);

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
    setLintResult(null);
    const result = generateExport(data, options);
    setLintResult(result.lintResult);
    if (result.errors.length > 0) {
      setValidationErrors(result.errors);
      return;
    }
    setExportWarnings(result.warnings);
    const selectedProject = data.projects.find((p) => p.slug === options.projectSlug);
    const packName = selectedProject?.defaultPackName || `copilot-pack_${options.projectSlug}.${options.format === "json" ? "json" : "md"}`;
    const ext = options.format === "json" ? "json" : "md";
    const filename = packName.endsWith(`.${ext}`) ? packName : packName.replace(/\.\w+$/, `.${ext}`);
    downloadFile(result.content, filename);
  };

  const handlePreview = () => {
    if (!data) return;
    setValidationErrors([]);
    setExportWarnings([]);
    setLintResult(null);
    const result = generateExport(data, options);
    setLintResult(result.lintResult);
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
      <h2 className="text-xl font-bold text-th-text">
        Export Copilot Pack
      </h2>
      <p className="text-sm text-th-text-muted">
        Generate a single compact file for upload to GitHub Copilot, ChatGPT, or
        any LLM. Archives and binary files are automatically excluded.
      </p>

      {/* No-projects warning */}
      {data.projects.length === 0 && (
        <div className="rounded-xl border border-th-warn bg-th-warn-light p-4">
          <h3 className="text-sm font-semibold text-th-warn">⚠️ No projects found</h3>
          <p className="text-xs text-th-warn/80 mt-1">
            Create <code className="bg-th-warn/20 px-1 rounded">00-context/projects.md</code> to
            define project scopes. Falling back to
            <strong> {data.settings?.project?.defaultProjectSlug || "lapu-lapu"}</strong> from settings.
          </p>
        </div>
      )}

      {/* Project selector */}
      {data.projects.length > 0 && (
        <div className="rounded-xl border border-th-border bg-th-surface p-4">
          <h3 className="text-sm font-semibold text-th-text-secondary mb-2">
            Project Scope
          </h3>
          <p className="text-xs text-th-text-faint mb-3">
            Export will only include tasks, decisions, and weekly reports tagged to this project.
          </p>
          <div className="flex gap-2">
            {data.projects.map((p) => (
              <label
                key={p.slug}
                className={`flex-1 flex items-center gap-3 rounded-lg border p-3 cursor-pointer ${
                  options.projectSlug === p.slug
                    ? "border-th-accent bg-th-accent-light"
                    : "border-th-border hover:bg-th-surface-alt"
                }`}
              >
                <input
                  type="radio"
                  name="project"
                  value={p.slug}
                  checked={options.projectSlug === p.slug}
                  onChange={() =>
                    setOptions({ ...options, projectSlug: p.slug })
                  }
                  className="text-th-accent"
                />
                <div>
                  <div className="text-sm font-medium text-th-text">{p.name}</div>
                  <div className="text-xs text-th-text-faint">{p.description}</div>
                </div>
              </label>
            ))}
          </div>
        </div>
      )}

      {/* Toggles */}
      <div className="rounded-xl border border-th-border bg-th-surface divide-y divide-th-border">
        {toggles.map((toggle) => (
          <label
            key={toggle.key}
            className="flex items-center justify-between p-4 cursor-pointer hover:bg-th-surface-alt"
          >
            <div>
              <div className="text-sm font-medium text-th-text">
                {toggle.label}
              </div>
              <div className="text-xs text-th-text-faint">{toggle.description}</div>
            </div>
            <input
              type="checkbox"
              checked={options[toggle.key] as boolean}
              onChange={(e) =>
                setOptions({ ...options, [toggle.key]: e.target.checked })
              }
              className="h-4 w-4 rounded border-th-border-strong text-th-accent focus:ring-th-accent"
            />
          </label>
        ))}

        {/* Weekly count */}
        {options.includeWeeklySummaries && (
          <div className="flex items-center justify-between p-4">
            <div>
              <div className="text-sm font-medium text-th-text">
                Include last N weeks
              </div>
              <div className="text-xs text-th-text-faint">
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
              className="w-16 text-sm border border-th-border-strong rounded px-2 py-1 text-center bg-th-surface text-th-text focus:outline-none focus:ring-2 focus:ring-th-accent"
            />
          </div>
        )}
      </div>

      {/* Format */}
      <div className="rounded-xl border border-th-border bg-th-surface p-4">
        <h3 className="text-sm font-semibold text-th-text-secondary mb-3">
          Export Format
        </h3>
        <div className="flex gap-3">
          <label
            className={`flex-1 flex items-center gap-3 rounded-lg border p-3 cursor-pointer ${
              options.format === "md"
                ? "border-th-accent bg-th-accent-light"
                : "border-th-border"
            }`}
          >
            <input
              type="radio"
              name="format"
              value="md"
              checked={options.format === "md"}
              onChange={() => setOptions({ ...options, format: "md" })}
              className="text-th-accent"
            />
            <div>
              <div className="text-sm font-medium text-th-text">Copilot Pack (.md)</div>
              <div className="text-xs text-th-text-faint">
                YAML frontmatter + instructions + JSON data
              </div>
            </div>
          </label>
          <label
            className={`flex-1 flex items-center gap-3 rounded-lg border p-3 cursor-pointer ${
              options.format === "json"
                ? "border-th-accent bg-th-accent-light"
                : "border-th-border"
            }`}
          >
            <input
              type="radio"
              name="format"
              value="json"
              checked={options.format === "json"}
              onChange={() => setOptions({ ...options, format: "json" })}
              className="text-th-accent"
            />
            <div>
              <div className="text-sm font-medium text-th-text">Copilot Pack (.json)</div>
              <div className="text-xs text-th-text-faint">
                Pure structured JSON data
              </div>
            </div>
          </label>
        </div>
      </div>

      {/* Size estimate + actions */}
      <div className="flex items-center justify-between rounded-xl border border-th-border bg-th-surface p-4">
        <div>
          <div className="text-sm text-th-text-muted">Estimated export size</div>
          <div className="text-lg font-bold text-th-text">
            {formatBytes(estimatedSize)}
          </div>
        </div>
        <div className="flex gap-3">
          <button
            onClick={handlePreview}
            className="px-4 py-2 text-sm border border-th-border-strong rounded-lg text-th-text-secondary hover:bg-th-surface-alt cursor-pointer"
          >
            Preview
          </button>
          <button
            onClick={handleExport}
            className="px-6 py-2 text-sm bg-th-accent text-white rounded-lg font-medium hover:bg-th-accent-hover cursor-pointer"
          >
            📦 Export
          </button>
        </div>
      </div>

      {/* Validation errors */}
      {validationErrors.length > 0 && (
        <div className="rounded-xl border border-th-danger bg-th-danger-light p-4 space-y-2">
          <h3 className="text-sm font-semibold text-th-danger">
            ⚠️ Export validation failed ({validationErrors.length} issue{validationErrors.length > 1 ? "s" : ""})
          </h3>
          <ul className="text-xs text-th-danger/80 space-y-1 max-h-48 overflow-auto">
            {validationErrors.map((err, i) => (
              <li key={i} className="flex gap-2">
                <span className="font-mono text-th-danger">{err.entity}.{err.field}</span>
                <span>{err.message}</span>
              </li>
            ))}
          </ul>
          <p className="text-xs text-th-danger/80 mt-1">
            Fix the source data and reload before exporting.
          </p>
        </div>
      )}

      {/* Lint results */}
      {lintResult && lintResult.violations.length > 0 && (
        <div
          className={`rounded-xl border p-4 space-y-2 ${
            lintResult.blocked
              ? "border-th-danger bg-th-danger-light"
              : "border-th-warn bg-th-warn-light"
          }`}
        >
          <h3
            className={`text-sm font-semibold ${
              lintResult.blocked ? "text-th-danger" : "text-th-warn"
            }`}
          >
            {lintResult.blocked ? "🚫" : "⚠️"} Lint{" "}
            {lintResult.blocked ? "blocked export" : "warnings"} ({lintResult.errorCount} error
            {lintResult.errorCount !== 1 ? "s" : ""}, {lintResult.warningCount} warning
            {lintResult.warningCount !== 1 ? "s" : ""})
          </h3>
          <ul
            className={`text-xs space-y-1 max-h-48 overflow-auto ${
              lintResult.blocked ? "text-th-danger/80" : "text-th-warn/80"
            }`}
          >
            {lintResult.violations.slice(0, 20).map((v, i) => (
              <li key={i} className="flex gap-2">
                <span
                  className={`font-mono ${
                    v.severity === "error" ? "text-th-danger" : "text-th-warn"
                  }`}
                >
                  [{v.rule}] {v.entity}
                </span>
                <span>{v.message}</span>
              </li>
            ))}
            {lintResult.violations.length > 20 && (
              <li className="italic">
                … and {lintResult.violations.length - 20} more
              </li>
            )}
          </ul>
          <p
            className={`text-xs mt-1 ${
              lintResult.blocked ? "text-th-danger/80" : "text-th-warn/80"
            }`}
          >
            {lintResult.blocked
              ? "Fix the issues above or set lint.mode to \"warn\" in Settings."
              : "Export completed with lint warnings. Review issues in Settings → Lint."}
          </p>
        </div>
      )}

      {/* Export warnings (soft — export still succeeds) */}
      {exportWarnings.length > 0 && (
        <div className="rounded-xl border border-th-warn bg-th-warn-light p-4 space-y-2">
          <h3 className="text-sm font-semibold text-th-warn">
            ⚠️ Export warnings ({exportWarnings.length})
          </h3>
          <ul className="text-xs text-th-warn/80 space-y-1 max-h-48 overflow-auto">
            {exportWarnings.map((w, i) => (
              <li key={i} className="flex gap-2">
                <span className="font-mono text-th-warn">{w.taskId} → {w.objectiveId}</span>
                <span>{w.message}</span>
              </li>
            ))}
          </ul>
          <p className="text-xs text-th-warn/80 mt-1">
            Export completed. These tasks reference objectives outside the exported scope.
          </p>
        </div>
      )}

      {/* Preview */}
      {preview && (
        <div className="rounded-xl border border-th-border bg-th-surface overflow-hidden">
          <div className="flex items-center justify-between px-4 py-2 bg-th-surface-alt border-b border-th-border">
            <span className="text-sm font-medium text-th-text-secondary">Preview</span>
            <button
              onClick={() => setPreview(null)}
              className="text-xs text-th-text-faint hover:text-th-text-muted cursor-pointer"
            >
              Close
            </button>
          </div>
          <pre className="p-4 text-xs text-th-text-secondary overflow-auto max-h-96 font-mono whitespace-pre-wrap">
            {preview}
          </pre>
        </div>
      )}
    </div>
  );
}
