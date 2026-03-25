"use client";

import React, { createContext, useContext, useState, useCallback } from "react";
import type { PMData } from "../lib/types";
import {
  parseObjectives,
  parseTeams,
  parseSystems,
  parseTasks,
  parseDecisions,
  parseWeeklySummaries,
} from "../lib/parsers";
import { buildRelationshipMap } from "../lib/relationships";

interface PMContextType {
  data: PMData | null;
  loading: boolean;
  loadFiles: (files: Record<string, string>, folderName: string) => void;
}

const PMContext = createContext<PMContextType>({
  data: null,
  loading: false,
  loadFiles: () => {},
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

        if (!objectivesPath) warnings.push("Missing: 00-context/objectives.md");
        if (!teamsPath) warnings.push("Missing: 00-context/teams.md");
        if (!systemsPath) warnings.push("Missing: 00-context/systems.md");
        if (!tasksPath) warnings.push("Missing: 02-work/tasks.md");
        if (!decisionsPath) warnings.push("Missing: 02-work/decisions.md");

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

        // Build and enforce relationships
        const relationships = buildRelationshipMap(objectives, tasks);

        // Add relationship advisory messages to warnings
        if (relationships.violations.length > 0) {
          warnings.push(...relationships.violations.map((v) => v.message));
        }

        setData({
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
        });
      } catch (err) {
        console.error("Failed to parse files:", err);
      } finally {
        setLoading(false);
      }
    },
    []
  );

  return (
    <PMContext.Provider value={{ data, loading, loadFiles }}>
      {children}
    </PMContext.Provider>
  );
}

export function usePMData() {
  return useContext(PMContext);
}
