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
    includeObjectives: boolean;
    includeTeamsSystems: boolean;
    includeTasks: boolean;
    includeDecisions: boolean;
    includeWeeklySummaries: boolean;
    includeInbox: boolean;
  };
  reporting: {
    weekStartDay: "monday" | "sunday";
    autoGenerateWeekly: boolean;
    reportCadence: "weekly" | "biweekly" | "monthly";
  };
  ui: {
    theme: "light" | "dark" | "system";
    defaultTab: "dashboard" | "objectives" | "tasks" | "weekly" | "export";
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
    includeObjectives: true,
    includeTeamsSystems: true,
    includeTasks: true,
    includeDecisions: true,
    includeWeeklySummaries: true,
    includeInbox: false,
  },
  reporting: {
    weekStartDay: "monday",
    autoGenerateWeekly: false,
    reportCadence: "weekly",
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
const VALID_THEMES = new Set(["light", "dark", "system"]);
const VALID_TABS = new Set(["dashboard", "objectives", "tasks", "weekly", "export"]);

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
    expectBoolean(exp.includeDecisions, "export.includeDecisions", errors);
    expectBoolean(exp.includeWeeklySummaries, "export.includeWeeklySummaries", errors);
    expectBoolean(exp.includeInbox, "export.includeInbox", errors);
  } else {
    errors.push({ path: "export", message: "Missing or invalid export section" });
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
  const parsed = JSON.parse(raw);
  const merged = mergeWithDefaults(parsed);
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
    reporting: {
      ...DEFAULT_SETTINGS.reporting,
      ...(partial.reporting ?? {}),
    },
    ui: {
      ...DEFAULT_SETTINGS.ui,
      ...(partial.ui ?? {}),
    },
  };
}
