// ── Settings schema, defaults, parser & validator ──

export interface AppSettings {
  meta: {
    version: number;
    lastSaved: string;   // ISO-8601
  };
  project: {
    repoRoot: string;    // display-only; actual root is where files are loaded from
    defaultProjectSlug: string;
  };
  export: {
    defaultFormat: "md" | "json";
    weeklySummaryCount: number;
    maxNotesLength: number;  // 0 = no limit
    includeObjectives: boolean;
    includeTeamsSystems: boolean;
    includeTasks: boolean;
    includeKeyResults: boolean;
    includeDecisions: boolean;
    includeWeeklySummaries: boolean;
    includeInbox: boolean;
    includeHowToUse: boolean;
    includeRolePrompts: boolean;
  };
  lint: {
    enabled: boolean;
    mode: "warn" | "fail";
    requireProjectTag: boolean;
    requireNamespacedTags: boolean;
  };
  reporting: {
    weekStartDay: "monday" | "sunday";
    autoGenerateWeekly: boolean;
    reportCadence: "weekly" | "biweekly" | "monthly";
  };
  tags: {
    keywordMap: {
      systems: Record<string, string[]>;
      projects: Record<string, string[]>;
      teams: Record<string, string[]>;
      areas: Record<string, string[]>;
    };
  };
  ui: {
    theme: "light" | "dark" | "woodland" | "system";
    defaultTab: "dashboard" | "objectives" | "tasks" | "weekly" | "export" | "intake";
    compactMode: boolean;
  };
}

export const DEFAULT_SETTINGS: AppSettings = {
  meta: {
    version: 1,
    lastSaved: new Date().toISOString(),
  },
  project: {
    repoRoot: "",
    defaultProjectSlug: "lapu-lapu",
  },
  export: {
    defaultFormat: "md",
    weeklySummaryCount: 2,
    maxNotesLength: 500,
    includeObjectives: true,
    includeTeamsSystems: true,
    includeTasks: true,
    includeKeyResults: true,
    includeDecisions: true,
    includeWeeklySummaries: true,
    includeInbox: false,
    includeHowToUse: true,
    includeRolePrompts: true,
  },
  lint: {
    enabled: true,
    mode: "warn",
    requireProjectTag: true,
    requireNamespacedTags: false,
  },
  reporting: {
    weekStartDay: "monday",
    autoGenerateWeekly: false,
    reportCadence: "weekly",
  },
  tags: {
    keywordMap: {
      systems: {
        "#system:newrelic":  ["New Relic", "newrelic", "synthetics", "APM onboarding"],
        "#system:moogsoft":  ["Moogsoft", "moogsoft", "AIOps", "alert correlation"],
        "#system:cmdb":      ["CMDB", "cmdb", "configuration management", "asset inventory"],
        "#system:leanix":    ["LeanIX", "leanix", "enterprise architecture"],
        "#system:xmatters":  ["xMatters", "xmatters", "on-call", "escalation"],
        "#system:ingenium":  ["Ingenium", "ingenium", "policy admin"],
        "#system:azure":     ["Azure", "azure", "ADX", "cloud infrastructure"],
        "#system:adx":       ["ADX", "Data Explorer", "log analytics"],
        "#system:adobe":     ["Adobe", "adobe", "digital experience"],
        "#system:apm":       ["APM", "application performance"],
      },
      projects: {
        "#project:lapu-lapu": ["Lapu-Lapu", "lapu-lapu", "GOCC transition", "Employee Experience", "Developer Experience"],
        "#project:epsilon":   ["Epsilon", "epsilon", "POT", "3-tier", "HA", "Ingenium upgrade"],
      },
      teams: {
        "#team:ets-japan":        ["ETS Japan", "ETS-Japan", "Birger"],
        "#team:gocc":             ["GOCC", "gocc", "Hari"],
        "#team:gocc-monitoring":  ["GOCC Monitoring", "Jonan", "L0", "L1 triage"],
        "#team:gocc-observability": ["Observability", "Deb", "Debamalya", "MMM", "R2R"],
        "#team:ets-region":       ["ETS Region", "ETS-Region", "Kelvin"],
      },
      // Lapu-Lapu delivery areas (see 00-context/pack-config.md → Delivery Area Taxonomy)
      areas: {
        "#area:adx-registration": ["ADX", "Azure Data Explorer"],
        "#area:cmdb-mapping":     ["CMDB mapping", "CMDB gap", "CI structure", "CMDB reconciliation"],
        "#area:employee-xp":      ["Employee Experience", "Employee XP"],
        "#area:dev-xp":           ["Developer Experience", "Dev XP", "non-prod monitoring", "non-production monitoring"],
        "#area:gocc-transition":  ["PS-to-GOCC", "GOCC handover", "GOCC onboarding", "GOCC transition", "scaffolding pack", "reverse-shadow", "KT", "knowledge transfer"],
        "#area:mmm-l2":           ["MMM", "OMM", "Observability Maturity"],
        "#area:patching":         ["patching", "patch cycle", "weekday patching"],
        "#area:rapid-recovery":   ["Rapid Recovery", "RRP", "R2R", "recovery plan"],
      },
    },
  },
  ui: {
    theme: "system",
    defaultTab: "dashboard",
    compactMode: false,
  },
};

// ── Validation helpers ──

export interface SettingsValidationError {
  path: string;
  message: string;
}

const VALID_FORMATS = new Set(["md", "json"]);
const VALID_WEEK_DAYS = new Set(["monday", "sunday"]);
const VALID_CADENCES = new Set(["weekly", "biweekly", "monthly"]);
const VALID_THEMES = new Set(["light", "dark", "woodland", "system"]);
const VALID_TABS = new Set(["dashboard", "objectives", "tasks", "weekly", "export", "intake"]);
const VALID_LINT_MODES = new Set(["warn", "fail"]);

function expectType(
  obj: unknown,
  path: string,
  type: string,
  errors: SettingsValidationError[]
): boolean {
  if (typeof obj !== type) {
    errors.push({ path, message: `Expected ${type}, got ${typeof obj}` });
    return false;
  }
  return true;
}

function expectOneOf(
  value: unknown,
  path: string,
  allowed: Set<string>,
  errors: SettingsValidationError[]
): boolean {
  if (typeof value !== "string" || !allowed.has(value)) {
    errors.push({
      path,
      message: `Must be one of: ${[...allowed].join(", ")}`,
    });
    return false;
  }
  return true;
}

function expectBoolean(
  value: unknown,
  path: string,
  errors: SettingsValidationError[]
): boolean {
  return expectType(value, path, "boolean", errors);
}

function expectPositiveInt(
  value: unknown,
  path: string,
  errors: SettingsValidationError[]
): boolean {
  if (typeof value !== "number" || !Number.isInteger(value) || value < 1) {
    errors.push({ path, message: "Must be a positive integer" });
    return false;
  }
  return true;
}

/**
 * Validate a settings object and return a list of errors.
 * An empty array means the settings are valid.
 */
export function validateSettings(settings: unknown): SettingsValidationError[] {
  const errors: SettingsValidationError[] = [];
  if (!settings || typeof settings !== "object") {
    errors.push({ path: "(root)", message: "Settings must be an object" });
    return errors;
  }

  const s = settings as Record<string, unknown>;

  // meta
  if (s.meta && typeof s.meta === "object") {
    const meta = s.meta as Record<string, unknown>;
    expectType(meta.version, "meta.version", "number", errors);
    expectType(meta.lastSaved, "meta.lastSaved", "string", errors);
  } else {
    errors.push({ path: "meta", message: "Missing or invalid meta section" });
  }

  // project
  if (s.project && typeof s.project === "object") {
    const project = s.project as Record<string, unknown>;
    expectType(project.repoRoot, "project.repoRoot", "string", errors);
    expectType(project.defaultProjectSlug, "project.defaultProjectSlug", "string", errors);
  } else {
    errors.push({ path: "project", message: "Missing or invalid project section" });
  }

  // export
  if (s.export && typeof s.export === "object") {
    const exp = s.export as Record<string, unknown>;
    expectOneOf(exp.defaultFormat, "export.defaultFormat", VALID_FORMATS, errors);
    expectPositiveInt(exp.weeklySummaryCount, "export.weeklySummaryCount", errors);
    expectBoolean(exp.includeObjectives, "export.includeObjectives", errors);
    expectBoolean(exp.includeTeamsSystems, "export.includeTeamsSystems", errors);
    expectBoolean(exp.includeTasks, "export.includeTasks", errors);
    expectBoolean(exp.includeKeyResults, "export.includeKeyResults", errors);
    expectBoolean(exp.includeDecisions, "export.includeDecisions", errors);
    expectBoolean(exp.includeWeeklySummaries, "export.includeWeeklySummaries", errors);
    expectBoolean(exp.includeInbox, "export.includeInbox", errors);
    expectBoolean(exp.includeHowToUse, "export.includeHowToUse", errors);
    expectBoolean(exp.includeRolePrompts, "export.includeRolePrompts", errors);
    if (typeof exp.maxNotesLength !== "number" || exp.maxNotesLength < 0 || !Number.isInteger(exp.maxNotesLength)) {
      errors.push({ path: "export.maxNotesLength", message: "Must be a non-negative integer" });
    }
  } else {
    errors.push({ path: "export", message: "Missing or invalid export section" });
  }

  // lint
  if (s.lint && typeof s.lint === "object") {
    const lint = s.lint as Record<string, unknown>;
    expectBoolean(lint.enabled, "lint.enabled", errors);
    expectOneOf(lint.mode, "lint.mode", VALID_LINT_MODES, errors);
    expectBoolean(lint.requireProjectTag, "lint.requireProjectTag", errors);
    expectBoolean(lint.requireNamespacedTags, "lint.requireNamespacedTags", errors);
  } else {
    errors.push({ path: "lint", message: "Missing or invalid lint section" });
  }

  // reporting
  if (s.reporting && typeof s.reporting === "object") {
    const rep = s.reporting as Record<string, unknown>;
    expectOneOf(rep.weekStartDay, "reporting.weekStartDay", VALID_WEEK_DAYS, errors);
    expectBoolean(rep.autoGenerateWeekly, "reporting.autoGenerateWeekly", errors);
    expectOneOf(rep.reportCadence, "reporting.reportCadence", VALID_CADENCES, errors);
  } else {
    errors.push({ path: "reporting", message: "Missing or invalid reporting section" });
  }

  // ui
  if (s.ui && typeof s.ui === "object") {
    const ui = s.ui as Record<string, unknown>;
    expectOneOf(ui.theme, "ui.theme", VALID_THEMES, errors);
    expectOneOf(ui.defaultTab, "ui.defaultTab", VALID_TABS, errors);
    expectBoolean(ui.compactMode, "ui.compactMode", errors);
  } else {
    errors.push({ path: "ui", message: "Missing or invalid ui section" });
  }

  // tags
  if (s.tags && typeof s.tags === "object") {
    const tags = s.tags as Record<string, unknown>;
    if (tags.keywordMap && typeof tags.keywordMap === "object") {
      const km = tags.keywordMap as Record<string, unknown>;
      for (const key of ["systems", "projects", "teams", "areas"] as const) {
        if (km[key] !== undefined && (typeof km[key] !== "object" || km[key] === null)) {
          errors.push({ path: `tags.keywordMap.${key}`, message: "Must be an object (tag → keyword[])" });
        }
      }
    } else {
      errors.push({ path: "tags.keywordMap", message: "Missing or invalid keywordMap" });
    }
  } else {
    errors.push({ path: "tags", message: "Missing or invalid tags section" });
  }

  return errors;
}

/**
 * Parse a JSON string into AppSettings, merging with defaults for any missing keys.
 * Throws if the JSON is completely unparseable.
 */
export function parseSettings(raw: string): {
  settings: AppSettings;
  errors: SettingsValidationError[];
} {
  const trimmed = raw.trim();

  // Treat empty settings files as defaults so UI does not crash on first run.
  if (trimmed.length === 0) {
    const merged = mergeWithDefaults({});
    const errors = validateSettings(merged);
    return { settings: merged, errors };
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(trimmed);
  } catch {
    const merged = mergeWithDefaults({});
    const errors = validateSettings(merged);
    errors.unshift({
      path: "settings",
      message: "Invalid JSON. Falling back to defaults.",
    });
    return { settings: merged, errors };
  }

  const merged = mergeWithDefaults(parsed as Partial<AppSettings>);
  const errors = validateSettings(merged);
  return { settings: merged, errors };
}

/**
 * Deep-merge a partial settings object with the default settings.
 * Only merges known keys to avoid polluting with arbitrary data.
 */
export function mergeWithDefaults(partial: Partial<AppSettings>): AppSettings {
  return {
    meta: {
      ...DEFAULT_SETTINGS.meta,
      ...(partial.meta ?? {}),
    },
    project: {
      ...DEFAULT_SETTINGS.project,
      ...(partial.project ?? {}),
    },
    export: {
      ...DEFAULT_SETTINGS.export,
      ...(partial.export ?? {}),
    },
    lint: {
      ...DEFAULT_SETTINGS.lint,
      ...(partial.lint ?? {}),
    },
    reporting: {
      ...DEFAULT_SETTINGS.reporting,
      ...(partial.reporting ?? {}),
    },
    ui: {
      ...DEFAULT_SETTINGS.ui,
      ...(partial.ui ?? {}),
    },
    tags: {
      keywordMap: {
        systems: {
          ...DEFAULT_SETTINGS.tags.keywordMap.systems,
          ...(partial.tags?.keywordMap?.systems ?? {}),
        },
        projects: {
          ...DEFAULT_SETTINGS.tags.keywordMap.projects,
          ...(partial.tags?.keywordMap?.projects ?? {}),
        },
        teams: {
          ...DEFAULT_SETTINGS.tags.keywordMap.teams,
          ...(partial.tags?.keywordMap?.teams ?? {}),
        },
        areas: {
          ...DEFAULT_SETTINGS.tags.keywordMap.areas,
          ...(partial.tags?.keywordMap?.areas ?? {}),
        },
      },
    },
  };
}
