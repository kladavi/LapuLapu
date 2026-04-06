import { describe, it, expect } from "vitest";
import {
  DEFAULT_SETTINGS,
  validateSettings,
  parseSettings,
  mergeWithDefaults,
} from "../lib/settings";
import type { AppSettings } from "../lib/settings";

// ── validateSettings ──

describe("validateSettings", () => {
  it("returns no errors for valid DEFAULT_SETTINGS", () => {
    const errors = validateSettings(DEFAULT_SETTINGS);
    expect(errors).toEqual([]);
  });

  it("rejects null input", () => {
    const errors = validateSettings(null);
    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0].path).toBe("(root)");
  });

  it("rejects non-object input", () => {
    const errors = validateSettings("not an object");
    expect(errors.length).toBeGreaterThan(0);
  });

  it("reports missing sections", () => {
    const errors = validateSettings({});
    const paths = errors.map((e) => e.path);
    expect(paths).toContain("meta");
    expect(paths).toContain("project");
    expect(paths).toContain("export");
    expect(paths).toContain("lint");
    expect(paths).toContain("reporting");
    expect(paths).toContain("ui");
  });

  it("rejects invalid export.defaultFormat", () => {
    const bad = {
      ...DEFAULT_SETTINGS,
      export: { ...DEFAULT_SETTINGS.export, defaultFormat: "csv" },
    };
    const errors = validateSettings(bad);
    expect(errors.some((e) => e.path === "export.defaultFormat")).toBe(true);
  });

  it("rejects zero weeklySummaryCount", () => {
    const bad = {
      ...DEFAULT_SETTINGS,
      export: { ...DEFAULT_SETTINGS.export, weeklySummaryCount: 0 },
    };
    const errors = validateSettings(bad);
    expect(errors.some((e) => e.path === "export.weeklySummaryCount")).toBe(true);
  });

  it("rejects non-integer weeklySummaryCount", () => {
    const bad = {
      ...DEFAULT_SETTINGS,
      export: { ...DEFAULT_SETTINGS.export, weeklySummaryCount: 1.5 },
    };
    const errors = validateSettings(bad);
    expect(errors.some((e) => e.path === "export.weeklySummaryCount")).toBe(true);
  });

  it("rejects invalid ui.theme", () => {
    const bad = {
      ...DEFAULT_SETTINGS,
      ui: { ...DEFAULT_SETTINGS.ui, theme: "neon" },
    };
    const errors = validateSettings(bad);
    expect(errors.some((e) => e.path === "ui.theme")).toBe(true);
  });

  it("rejects invalid reporting.weekStartDay", () => {
    const bad = {
      ...DEFAULT_SETTINGS,
      reporting: { ...DEFAULT_SETTINGS.reporting, weekStartDay: "friday" },
    };
    const errors = validateSettings(bad);
    expect(errors.some((e) => e.path === "reporting.weekStartDay")).toBe(true);
  });

  it("rejects non-boolean for export toggles", () => {
    const bad = {
      ...DEFAULT_SETTINGS,
      export: { ...DEFAULT_SETTINGS.export, includeTasks: "yes" },
    };
    const errors = validateSettings(bad);
    expect(errors.some((e) => e.path === "export.includeTasks")).toBe(true);
  });
});

// ── mergeWithDefaults ──

describe("mergeWithDefaults", () => {
  it("returns defaults when given empty object", () => {
    const result = mergeWithDefaults({});
    expect(result.meta).toEqual(DEFAULT_SETTINGS.meta);
    expect(result.project).toEqual(DEFAULT_SETTINGS.project);
    expect(result.export).toEqual(DEFAULT_SETTINGS.export);
    expect(result.reporting).toEqual(DEFAULT_SETTINGS.reporting);
    expect(result.ui).toEqual(DEFAULT_SETTINGS.ui);
  });

  it("overrides only supplied keys", () => {
    const result = mergeWithDefaults({
      project: { repoRoot: "/my/path", defaultProjectSlug: "epsilon" },
    });
    expect(result.project.repoRoot).toBe("/my/path");
    expect(result.project.defaultProjectSlug).toBe("epsilon");
    // Other sections unchanged
    expect(result.export).toEqual(DEFAULT_SETTINGS.export);
  });

  it("partially overrides within a section", () => {
    const result = mergeWithDefaults({
      ui: { theme: "dark" } as AppSettings["ui"],
    });
    expect(result.ui.theme).toBe("dark");
    expect(result.ui.defaultTab).toBe("dashboard"); // default
    expect(result.ui.compactMode).toBe(false); // default
  });
});

// ── parseSettings ──

describe("parseSettings", () => {
  it("parses valid JSON and returns no errors", () => {
    const json = JSON.stringify(DEFAULT_SETTINGS);
    const { settings, errors } = parseSettings(json);
    expect(errors).toEqual([]);
    expect(settings.meta.version).toBe(1);
    expect(settings.project.defaultProjectSlug).toBe("lapu-lapu");
  });

  it("throws on invalid JSON", () => {
    expect(() => parseSettings("{ not json ")).toThrow();
  });

  it("fills in missing sections with defaults", () => {
    const partial = { meta: { version: 1, lastSaved: "2026-01-01T00:00:00Z" } };
    const { settings } = parseSettings(JSON.stringify(partial));
    expect(settings.export.defaultFormat).toBe("md");
    expect(settings.ui.theme).toBe("system");
  });

  it("reports validation errors for invalid values but still returns merged settings", () => {
    const bad = {
      ...DEFAULT_SETTINGS,
      ui: { theme: "neon", defaultTab: "invalid", compactMode: "yes" },
    };
    const { settings, errors } = parseSettings(JSON.stringify(bad));
    expect(errors.length).toBeGreaterThan(0);
    // Merged settings still have the bad values (caller can decide what to do)
    expect(settings.ui.theme).toBe("neon");
  });
});
