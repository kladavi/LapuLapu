"use client";

import React, { createContext, useContext, useState, useCallback } from "react";
import type { PMData } from "../lib/types";
import type { AppSettings } from "../lib/settings";
import {
  parseObjectives,
  parseTeams,
  parseSystems,
  parseTasks,
  parseDecisions,
  parseWeeklySummaries,
  parseProjects,
} from "../lib/parsers";
import { buildRelationshipMap } from "../lib/relationships";
import { DEFAULT_SETTINGS, parseSettings } from "../lib/settings";

interface PMContextType {
  data: PMData | null;
  loading: boolean;
  loadFiles: (files: Record<string, string>, folderName: string) => void;
  updateSettings: (settings: AppSettings) => void;
  saveSettings: (settings: AppSettings) => Promise<void>;
}

const PMContext = createContext<PMContextType>({
  data: null,
  loading: false,
  loadFiles: () => {},
  updateSettings: () => {},
  saveSettings: async () => {},
});

export function PMProvider({ children }: { children: React.ReactNode }) {
  const [data, setData] = useState<PMData | null>(null);
  const [loading, setLoading] = useState(false);

  const loadFiles = useCallback(
    (files: Record<string, string>, folderName: string) => {
      setLoading(true);

      try {
        const warnings: string[] = [];

        // Find key files (normalise paths)
        const findFile = (suffix: string): string | undefined => {
          const keys = Object.keys(files);
          return keys.find((k) => k.replace(/\\/g, "/").endsWith(suffix));
        };

        const objectivesPath = findFile("00-context/objectives.md");
        const teamsPath = findFile("00-context/teams.md");
        const systemsPath = findFile("00-context/systems.md");
        const tasksPath = findFile("02-work/tasks.md");
        const decisionsPath = findFile("02-work/decisions.md");
        const inboxPath = findFile("01-inbox/inbox.md");
        const projectsPath = findFile("00-context/projects.md");

        if (!objectivesPath) warnings.push("Missing: 00-context/objectives.md");
        if (!teamsPath) warnings.push("Missing: 00-context/teams.md");
        if (!systemsPath) warnings.push("Missing: 00-context/systems.md");
        if (!tasksPath) warnings.push("Missing: 02-work/tasks.md");
        if (!decisionsPath) warnings.push("Missing: 02-work/decisions.md");
        if (!projectsPath) warnings.push("Missing: 00-context/projects.md");

        const projects = projectsPath
          ? parseProjects(files[projectsPath])
          : [];
        const objectives = objectivesPath
          ? parseObjectives(files[objectivesPath])
          : [];
        const teams = teamsPath ? parseTeams(files[teamsPath]) : [];
        const systems = systemsPath ? parseSystems(files[systemsPath]) : [];
        const tasks = tasksPath ? parseTasks(files[tasksPath]) : [];
        const decisions = decisionsPath
          ? parseDecisions(files[decisionsPath])
          : [];
        const weeklySummaries = parseWeeklySummaries(files);
        const inbox = inboxPath ? files[inboxPath] : "";

        // Parse settings from 00-context/settings.json
        const settingsPath = findFile("00-context/settings.json");
        let settings: AppSettings;
        if (settingsPath) {
          try {
            const { settings: parsed } = parseSettings(files[settingsPath]);
            settings = parsed;
          } catch {
            warnings.push("settings.json exists but could not be parsed — using defaults");
            settings = { ...DEFAULT_SETTINGS, meta: { ...DEFAULT_SETTINGS.meta, lastSaved: new Date().toISOString() } };
          }
        } else {
          warnings.push("Missing: 00-context/settings.json — created with defaults");
          settings = { ...DEFAULT_SETTINGS, meta: { ...DEFAULT_SETTINGS.meta, lastSaved: new Date().toISOString() } };
        }

        // Build and enforce relationships
        const relationships = buildRelationshipMap(objectives, tasks);

        // Add relationship advisory messages to warnings
        if (relationships.violations.length > 0) {
          warnings.push(...relationships.violations.map((v) => v.message));
        }

        setData({
          projects,
          objectives,
          teams,
          systems,
          tasks,
          decisions,
          weeklySummaries,
          inbox,
          rawFiles: files,
          loadedAt: new Date().toISOString(),
          folderName,
          warnings,
          relationships,
          settings,
        });
      } catch (err) {
        console.error("Failed to parse files:", err);
      } finally {
        setLoading(false);
      }
    },
    []
  );

  const updateSettings = useCallback((settings: AppSettings) => {
    setData((prev) => (prev ? { ...prev, settings } : prev));
  }, []);

  const saveSettings = useCallback(async (settings: AppSettings) => {
    const stamped: AppSettings = {
      ...settings,
      meta: { ...settings.meta, lastSaved: new Date().toISOString() },
    };

    const content = JSON.stringify(stamped, null, 2) + "\n";

    // Persist via save-local API route
    const res = await fetch("/api/save-local", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        filePath: "00-context/settings.json",
        content,
      }),
    });

    if (!res.ok) {
      const body = await res.json().catch(() => ({}));
      throw new Error(body.error || "Failed to save settings");
    }

    // Update in-memory state
    setData((prev) => (prev ? { ...prev, settings: stamped } : prev));
  }, []);

  return (
    <PMContext.Provider value={{ data, loading, loadFiles, updateSettings, saveSettings }}>
      {children}
    </PMContext.Provider>
  );
}

export function usePMData() {
  return useContext(PMContext);
}
