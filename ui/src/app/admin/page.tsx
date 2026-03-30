"use client";

import React, { useState, useEffect, useCallback } from "react";
import Link from "next/link";
import { usePMData } from "../../context/PMContext";
import type { AppSettings } from "../../lib/settings";
import { DEFAULT_SETTINGS, validateSettings } from "../../lib/settings";

const inputCls =
  "block w-full rounded-md border border-gray-300 bg-white px-3 py-1.5 text-sm text-gray-900 shadow-sm focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none";

type Toast = { message: string; type: "success" | "error" | "info" };

export default function AdminPage() {
  const { data, saveSettings } = usePMData();
  const [draft, setDraft] = useState<AppSettings>(DEFAULT_SETTINGS);
  const [toast, setToast] = useState<Toast | null>(null);
  const [saving, setSaving] = useState(false);
  const [validationErrors, setValidationErrors] = useState<string[]>([]);

  // Initialise from loaded data
  useEffect(() => {
    if (data?.settings) {
      setDraft(data.settings);
    }
  }, [data?.settings]);

  // Live validation on every change
  useEffect(() => {
    const errs = validateSettings(draft);
    setValidationErrors(errs.map((e) => `${e.path}: ${e.message}`));
  }, [draft]);

  const showToast = useCallback((t: Toast) => {
    setToast(t);
    setTimeout(() => setToast(null), 4000);
  }, []);

  const handleSave = useCallback(async () => {
    const errs = validateSettings(draft);
    if (errs.length > 0) {
      showToast({ message: `Validation failed: ${errs[0].message}`, type: "error" });
      return;
    }
    setSaving(true);
    try {
      await saveSettings(draft);
      showToast({ message: "Settings saved to 00-context/settings.json", type: "success" });
    } catch (err) {
      showToast({ message: `Save failed: ${err instanceof Error ? err.message : "Unknown error"}`, type: "error" });
    } finally {
      setSaving(false);
    }
  }, [draft, saveSettings, showToast]);

  const handleReset = useCallback(() => {
    setDraft(DEFAULT_SETTINGS);
    showToast({ message: "Settings reset to defaults (not saved yet)", type: "info" });
  }, [showToast]);

  // ── Updater helpers ──
  const updateProject = (key: keyof AppSettings["project"], value: string) =>
    setDraft((prev) => ({ ...prev, project: { ...prev.project, [key]: value } }));

  const updateExport = (key: keyof AppSettings["export"], value: unknown) =>
    setDraft((prev) => ({ ...prev, export: { ...prev.export, [key]: value } }));

  const updateReporting = (key: keyof AppSettings["reporting"], value: unknown) =>
    setDraft((prev) => ({ ...prev, reporting: { ...prev.reporting, [key]: value } }));

  const updateUI = (key: keyof AppSettings["ui"], value: unknown) =>
    setDraft((prev) => ({ ...prev, ui: { ...prev.ui, [key]: value } }));

  const updateLint = (key: keyof AppSettings["lint"], value: unknown) =>
    setDraft((prev) => ({ ...prev, lint: { ...prev.lint, [key]: value } }));

  if (!data) {
    return (
      <div className="flex-1 flex items-center justify-center p-8">
        <div className="text-center space-y-4">
          <p className="text-gray-500">No data loaded. Go back and load a project first.</p>
          <Link href="/" className="text-blue-600 hover:underline">← Back to Dashboard</Link>
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1 flex flex-col">
      {/* Header */}
      <header className="bg-white border-b border-gray-200 px-6 py-3 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Link href="/" className="text-blue-600 hover:text-blue-800 text-sm">
            ← Back
          </Link>
          <span className="text-xl">⚙️</span>
          <h1 className="text-lg font-semibold text-gray-800">Settings</h1>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={handleReset}
            className="text-sm text-gray-500 hover:text-gray-700 cursor-pointer"
          >
            ↺ Reset to Defaults
          </button>
          <button
            onClick={handleSave}
            disabled={saving || validationErrors.length > 0}
            className="inline-flex items-center gap-1.5 rounded-lg bg-blue-600 px-4 py-2 text-sm text-white font-medium hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors cursor-pointer"
          >
            {saving ? "Saving…" : "💾 Save Settings"}
          </button>
        </div>
      </header>

      {/* Toast */}
      {toast && (
        <div
          className={`mx-6 mt-3 rounded-lg px-4 py-2 text-sm font-medium ${
            toast.type === "success"
              ? "bg-green-100 text-green-800"
              : toast.type === "error"
              ? "bg-red-100 text-red-800"
              : "bg-blue-100 text-blue-800"
          }`}
        >
          {toast.message}
        </div>
      )}

      {/* Validation errors */}
      {validationErrors.length > 0 && (
        <div className="mx-6 mt-3 rounded-lg bg-red-50 border border-red-200 px-4 py-3 text-sm">
          <p className="font-medium text-red-700 mb-1">Validation Errors</p>
          <ul className="list-disc list-inside text-red-600 space-y-0.5">
            {validationErrors.map((e, i) => (
              <li key={i}>{e}</li>
            ))}
          </ul>
        </div>
      )}

      {/* Sections */}
      <main className="flex-1 overflow-auto p-6 space-y-6 max-w-3xl">
        {/* Config Status */}
        <Section title="Config Status" icon="📋">
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div>
              <span className="text-gray-500">Loaded from</span>
              <p className="font-mono text-gray-800">00-context/settings.json</p>
            </div>
            <div>
              <span className="text-gray-500">Last saved</span>
              <p className="font-mono text-gray-800">
                {draft.meta.lastSaved
                  ? new Date(draft.meta.lastSaved).toLocaleString()
                  : "Never"}
              </p>
            </div>
            <div>
              <span className="text-gray-500">Schema version</span>
              <p className="font-mono text-gray-800">{draft.meta.version}</p>
            </div>
            <div>
              <span className="text-gray-500">Folder</span>
              <p className="font-mono text-gray-800">{data.folderName}</p>
            </div>
          </div>
        </Section>

        {/* Project */}
        <Section title="Project" icon="📁">
          <Field label="Default Project Slug">
            <select
              value={draft.project.defaultProjectSlug}
              onChange={(e) => updateProject("defaultProjectSlug", e.target.value)}
              className={inputCls}
            >
              {data.projects.map((p) => (
                <option key={p.slug} value={p.slug}>
                  {p.name} ({p.slug})
                </option>
              ))}
              {data.projects.length === 0 && (
                <option value={draft.project.defaultProjectSlug}>
                  {draft.project.defaultProjectSlug}
                </option>
              )}
            </select>
          </Field>
          <Field label="Repo Root (display only)">
            <input
              type="text"
              value={draft.project.repoRoot}
              onChange={(e) => updateProject("repoRoot", e.target.value)}
              placeholder="e.g. C:\Users\…\LapuLapu"
              className={inputCls}
            />
          </Field>
        </Section>

        {/* Export Defaults */}
        <Section title="Export Defaults" icon="📦">
          <Field label="Default Format">
            <select
              value={draft.export.defaultFormat}
              onChange={(e) =>
                updateExport("defaultFormat", e.target.value as "md" | "json")
              }
              className={inputCls}
            >
              <option value="md">Markdown (.md)</option>
              <option value="json">JSON (.json)</option>
            </select>
          </Field>
          <Field label="Weekly Summary Count">
            <input
              type="number"
              min={1}
              max={52}
              value={draft.export.weeklySummaryCount}
              onChange={(e) =>
                updateExport("weeklySummaryCount", parseInt(e.target.value, 10) || 1)
              }
              className={`${inputCls} w-24`}
            />
          </Field>
          <div className="grid grid-cols-2 gap-3">
            <Toggle
              label="Include Objectives"
              checked={draft.export.includeObjectives}
              onChange={(v) => updateExport("includeObjectives", v)}
            />
            <Toggle
              label="Include Teams & Systems"
              checked={draft.export.includeTeamsSystems}
              onChange={(v) => updateExport("includeTeamsSystems", v)}
            />
            <Toggle
              label="Include Tasks"
              checked={draft.export.includeTasks}
              onChange={(v) => updateExport("includeTasks", v)}
            />
            <Toggle
              label="Include Decisions"
              checked={draft.export.includeDecisions}
              onChange={(v) => updateExport("includeDecisions", v)}
            />
            <Toggle
              label="Include Weekly Summaries"
              checked={draft.export.includeWeeklySummaries}
              onChange={(v) => updateExport("includeWeeklySummaries", v)}
            />
            <Toggle
              label="Include Inbox"
              checked={draft.export.includeInbox}
              onChange={(v) => updateExport("includeInbox", v)}
            />
            <Toggle
              label='Include "How to Use" guide'
              checked={draft.export.includeHowToUse}
              onChange={(v) => updateExport("includeHowToUse", v)}
            />
            <Toggle
              label="Include Role-Based Starter Prompts"
              checked={draft.export.includeRolePrompts}
              onChange={(v) => updateExport("includeRolePrompts", v)}
            />
          </div>
          <Field label="Max Notes Length (0 = no limit)">
            <input
              type="number"
              min={0}
              max={10000}
              value={draft.export.maxNotesLength}
              onChange={(e) =>
                updateExport("maxNotesLength", parseInt(e.target.value, 10) || 0)
              }
              className={`${inputCls} w-28`}
            />
          </Field>
        </Section>

        {/* Lint */}
        <Section title="Lint (Pre-Export Safety Gate)" icon="🔍">
          <p className="text-xs text-gray-400">
            Runs lint checks before each export. In <strong>warn</strong> mode violations are shown
            but export proceeds. In <strong>fail</strong> mode the export is blocked.
          </p>
          <Toggle
            label="Enabled"
            checked={draft.lint.enabled}
            onChange={(v) => updateLint("enabled", v)}
          />
          <Field label="Mode">
            <select
              value={draft.lint.mode}
              onChange={(e) =>
                updateLint("mode", e.target.value as "warn" | "fail")
              }
              className={inputCls}
            >
              <option value="warn">Warn (non-blocking)</option>
              <option value="fail">Fail (block export)</option>
            </select>
          </Field>
          <Toggle
            label="Require #project: tag on tasks &amp; decisions"
            checked={draft.lint.requireProjectTag}
            onChange={(v) => updateLint("requireProjectTag", v)}
          />
          <Toggle
            label="Require namespaced tags (#ns:value)"
            checked={draft.lint.requireNamespacedTags}
            onChange={(v) => updateLint("requireNamespacedTags", v)}
          />
        </Section>

        {/* Reporting */}
        <Section title="Reporting" icon="📅">
          <Field label="Week Start Day">
            <select
              value={draft.reporting.weekStartDay}
              onChange={(e) =>
                updateReporting("weekStartDay", e.target.value as "monday" | "sunday")
              }
              className={inputCls}
            >
              <option value="monday">Monday</option>
              <option value="sunday">Sunday</option>
            </select>
          </Field>
          <Field label="Report Cadence">
            <select
              value={draft.reporting.reportCadence}
              onChange={(e) =>
                updateReporting(
                  "reportCadence",
                  e.target.value as "weekly" | "biweekly" | "monthly"
                )
              }
              className={inputCls}
            >
              <option value="weekly">Weekly</option>
              <option value="biweekly">Biweekly</option>
              <option value="monthly">Monthly</option>
            </select>
          </Field>
          <Toggle
            label="Auto-generate Weekly Report"
            checked={draft.reporting.autoGenerateWeekly}
            onChange={(v) => updateReporting("autoGenerateWeekly", v)}
          />
        </Section>

        {/* UI */}
        <Section title="UI Preferences" icon="🎨">
          <Field label="Theme">
            <select
              value={draft.ui.theme}
              onChange={(e) =>
                updateUI("theme", e.target.value as "light" | "dark" | "system")
              }
              className={inputCls}
            >
              <option value="system">System</option>
              <option value="light">Light</option>
              <option value="dark">Dark</option>
            </select>
          </Field>
          <Field label="Default Tab">
            <select
              value={draft.ui.defaultTab}
              onChange={(e) => updateUI("defaultTab", e.target.value)}
              className={inputCls}
            >
              <option value="dashboard">Dashboard</option>
              <option value="objectives">Objectives</option>
              <option value="tasks">Tasks</option>
              <option value="weekly">Weekly</option>
              <option value="export">Export</option>
            </select>
          </Field>
          <Toggle
            label="Compact Mode"
            checked={draft.ui.compactMode}
            onChange={(v) => updateUI("compactMode", v)}
          />
        </Section>

        {/* Raw JSON preview */}
        <Section title="Raw JSON" icon="🔍">
          <pre className="bg-gray-50 border border-gray-200 rounded-lg p-4 text-xs font-mono overflow-auto max-h-64 whitespace-pre-wrap">
            {JSON.stringify(draft, null, 2)}
          </pre>
        </Section>
      </main>
    </div>
  );
}

// ── Reusable sub-components ──

function Section({
  title,
  icon,
  children,
}: {
  title: string;
  icon: string;
  children: React.ReactNode;
}) {
  return (
    <section className="bg-white rounded-xl border border-gray-200 p-5 space-y-4">
      <h2 className="text-base font-semibold text-gray-800 flex items-center gap-2">
        <span>{icon}</span> {title}
      </h2>
      {children}
    </section>
  );
}

function Field({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <label className="block space-y-1">
      <span className="text-sm font-medium text-gray-600">{label}</span>
      {children}
    </label>
  );
}

function Toggle({
  label,
  checked,
  onChange,
}: {
  label: string;
  checked: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <label className="flex items-center gap-2 cursor-pointer select-none">
      <input
        type="checkbox"
        checked={checked}
        onChange={(e) => onChange(e.target.checked)}
        className="rounded border-gray-300 text-blue-600 focus:ring-blue-500 w-4 h-4 cursor-pointer"
      />
      <span className="text-sm text-gray-700">{label}</span>
    </label>
  );
}
