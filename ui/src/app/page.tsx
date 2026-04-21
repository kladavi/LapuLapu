"use client";

import React, { useState, useCallback, useEffect, DragEvent } from "react";
import Link from "next/link";
import Image from "next/image";
import { usePMData } from "../context/PMContext";
import {
  loadFromFolderPicker,
  loadFromDroppedItems,
  supportsFileSystemAccess,
} from "../lib/fileLoader";
import { DashboardTab } from "../components/DashboardTab";
import { ObjectivesTab } from "../components/ObjectivesTab";
import { KeyResultsTab } from "../components/KeyResultsTab";
import { TasksTab } from "../components/TasksTab";
import { WeeklyTab } from "../components/WeeklyTab";
import { ExportTab } from "../components/ExportTab";
import { IntakeTab } from "../components/IntakeTab";

const TABS = [
  { id: "dashboard", label: "Dashboard", icon: "📊" },
  { id: "objectives", label: "Objectives", icon: "🎯" },
  { id: "keyresults", label: "Key Results", icon: "📈" },
  { id: "tasks", label: "Tasks", icon: "✅" },
  { id: "weekly", label: "Weekly", icon: "📅" },
  { id: "intake", label: "Intake", icon: "📥" },
  { id: "export", label: "Export", icon: "📦" },
] as const;

type TabId = (typeof TABS)[number]["id"];

export type NavFilter = { status?: string; tier?: number; ownerTag?: string };

export default function Home() {
  const { data, loading, loadFiles } = usePMData();
  const [activeTab, setActiveTab] = useState<TabId>("dashboard");
  const [navFilter, setNavFilter] = useState<NavFilter>({});
  const [dragOver, setDragOver] = useState(false);
  const [hasFolderPicker, setHasFolderPicker] = useState(false);
  const [autoLoadAttempted, setAutoLoadAttempted] = useState(false);

  const handleNavigate = useCallback((tab: TabId, filter: NavFilter = {}) => {
    setNavFilter(filter);
    setActiveTab(tab);
  }, []);

  // Detect File System Access API on client only to avoid hydration mismatch
  useEffect(() => {
    setHasFolderPicker(supportsFileSystemAccess());
  }, []);

  // Auto-load from the default local directory via API route on startup
  useEffect(() => {
    if (data || loading || autoLoadAttempted) return;
    setAutoLoadAttempted(true);

    fetch("/api/load-local")
      .then((res) => {
        if (!res.ok) throw new Error("API returned " + res.status);
        return res.json();
      })
      .then(({ files, folderName }: { files: Record<string, string>; folderName: string }) => {
        loadFiles(files, folderName);
      })
      .catch((err) => {
        console.warn("Auto-load from default directory failed:", err);
      });
  }, [data, loading, autoLoadAttempted, loadFiles]);

  const handleFolderPick = useCallback(async () => {
    try {
      const { files, folderName } = await loadFromFolderPicker();
      loadFiles(files, folderName);
    } catch (err) {
      console.error("Folder pick cancelled or failed:", err);
    }
  }, [loadFiles]);

  const handleReload = useCallback(async () => {
    try {
      const res = await fetch("/api/load-local");
      if (!res.ok) throw new Error("API returned " + res.status);
      const { files, folderName } = await res.json();
      loadFiles(files, folderName);
    } catch (err) {
      console.error("Reload failed:", err);
    }
  }, [loadFiles]);

  const handleDrop = useCallback(
    async (e: DragEvent) => {
      e.preventDefault();
      setDragOver(false);
      if (e.dataTransfer.items) {
        const { files, folderName } = await loadFromDroppedItems(
          e.dataTransfer.items
        );
        loadFiles(files, folderName);
      }
    },
    [loadFiles]
  );

  const handleDragOver = useCallback((e: DragEvent) => {
    e.preventDefault();
    setDragOver(true);
  }, []);

  const handleDragLeave = useCallback(() => {
    setDragOver(false);
  }, []);

  // Landing screen — no data loaded
  if (!data && !loading) {
    return (
      <div
        className="flex-1 flex items-center justify-center p-8"
        onDrop={handleDrop}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
      >
        <div
          className={`max-w-lg w-full text-center space-y-6 rounded-2xl border-2 border-dashed p-12 transition-colors ${
            dragOver
              ? "border-th-accent bg-th-accent-light"
              : "border-th-border-strong bg-th-surface"
          }`}
        >
          <div className="text-5xl">🗂️</div>
          <h1 className="text-2xl font-bold text-th-text">
            LapuLapu PM Dashboard
          </h1>
          <p className="text-th-text-muted">
            Load your objective-driven PM repo to get started.
          </p>

          {hasFolderPicker && (
            <button
              onClick={handleFolderPick}
              className="inline-flex items-center gap-2 rounded-lg bg-th-accent px-6 py-3 text-white font-medium hover:bg-th-accent-hover transition-colors cursor-pointer"
            >
              📁 Select Folder
            </button>
          )}

          <p className="text-sm text-th-text-faint">
            {hasFolderPicker
              ? "Or drag & drop your project folder here"
              : "Drag & drop your project folder here (folder picker not supported in this browser)"}
          </p>
        </div>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <div className="text-center space-y-4">
          <div className="text-4xl animate-spin">⏳</div>
          <p className="text-th-text-muted">Loading and parsing files…</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1 flex flex-col">
      {/* Header */}
      <header className="bg-th-surface border-b border-th-border px-6 py-3 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Image
            src="/Lapu-Lapu.png"
            alt="Lapu-Lapu"
            width={36}
            height={36}
            className="w-9 h-9 rounded object-cover border border-th-border"
            priority
          />
          <h1 className="text-lg font-semibold text-th-text">LapuLapu</h1>
          <span className="text-xs bg-th-surface-alt text-th-text-muted rounded px-2 py-0.5">
            {data?.folderName}
          </span>
        </div>
        <div className="flex items-center gap-4">
          <span className="text-xs text-th-text-faint">
            Loaded:{" "}
            {data?.loadedAt
              ? new Date(data.loadedAt).toLocaleString()
              : "—"}
          </span>
          <button
            onClick={handleReload}
            className="text-sm text-th-accent hover:text-th-accent-hover cursor-pointer"
          >
            ↻ Reload
          </button>
          {hasFolderPicker && (
            <button
              onClick={handleFolderPick}
              className="text-sm text-th-text-muted hover:text-th-text-secondary cursor-pointer"
            >
              📁 Change Folder
            </button>
          )}
          <Link
            href="/admin"
            className="text-sm text-th-text-muted hover:text-th-text-secondary"
          >
            ⚙️ Settings
          </Link>
        </div>
      </header>

      {/* Tab nav */}
      <nav className="bg-th-surface border-b border-th-border px-6">
        <div className="flex gap-1">
          {TABS.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`px-4 py-3 text-sm font-medium border-b-2 transition-colors cursor-pointer ${
                activeTab === tab.id
                  ? "border-th-accent text-th-accent"
                  : "border-transparent text-th-text-muted hover:text-th-text-secondary hover:border-th-border-strong"
              }`}
            >
              <span className="mr-1.5">{tab.icon}</span>
              {tab.label}
            </button>
          ))}
        </div>
      </nav>

      {/* Tab content */}
      <main className="flex-1 overflow-auto">
        {activeTab === "dashboard" && <DashboardTab onNavigate={handleNavigate} />}
        {activeTab === "objectives" && <ObjectivesTab initialTier={navFilter.tier} initialOwnerTag={navFilter.ownerTag} />}
        {activeTab === "keyresults" && <KeyResultsTab />}
        {activeTab === "tasks" && <TasksTab initialStatus={navFilter.status} />}
        {activeTab === "weekly" && <WeeklyTab />}
        {activeTab === "intake" && <IntakeTab />}
        {activeTab === "export" && <ExportTab />}
      </main>
    </div>
  );
}
