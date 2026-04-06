// ── Repo linter: pre-export safety gate ──
//
// Runs configurable lint checks over the working repo data.
// Returns a list of LintViolation objects. The caller decides
// whether to block or warn based on settings.lint.mode.

import type { PMData } from "./types";
import type { AppSettings } from "./settings";

export type LintSeverity = "error" | "warning";

export interface LintViolation {
  rule: string;
  severity: LintSeverity;
  entity: string;       // e.g. "T012", "2026-W13.md"
  message: string;
}

export interface LintResult {
  violations: LintViolation[];
  /** true if lint.mode === "fail" and there are error-level violations */
  blocked: boolean;
  /** summary counts */
  errorCount: number;
  warningCount: number;
}

// Namespaced tag pattern: #namespace:value (at least one char each side of colon)
const NAMESPACED_TAG_RE = /^#[a-z][a-z0-9_-]*:[a-z0-9_-]+$/i;

/**
 * Run all configured lint checks over the loaded PMData.
 *
 * Which checks run is controlled by `settings.lint.*` flags.
 * `settings.export.maxNotesLength` controls the notes-length threshold.
 */
export function lintRepo(data: PMData, settings: AppSettings): LintResult {
  const violations: LintViolation[] = [];
  const lint = settings.lint;

  if (!lint.enabled) {
    return { violations, blocked: false, errorCount: 0, warningCount: 0 };
  }

  const severity: LintSeverity = lint.mode === "fail" ? "error" : "warning";
  const maxNotes = settings.export.maxNotesLength;

  // ── Check 1: Tasks missing #project:<slug> tag ──
  if (lint.requireProjectTag) {
    for (const task of data.tasks) {
      const hasProjectTag = task.tags.some((t) =>
        t.toLowerCase().startsWith("#project:")
      );
      if (!hasProjectTag) {
        violations.push({
          rule: "require-project-tag",
          severity,
          entity: task.id,
          message: `Task "${task.id}" is missing a #project:<slug> tag.`,
        });
      }
    }

    // Also check decisions
    for (const dec of data.decisions) {
      const hasProjectTag = dec.tags.some((t) =>
        t.toLowerCase().startsWith("#project:")
      );
      if (!hasProjectTag) {
        violations.push({
          rule: "require-project-tag",
          severity,
          entity: dec.id,
          message: `Decision "${dec.id}" is missing a #project:<slug> tag.`,
        });
      }
    }
  }

  // ── Check 2: Tags not in namespaced form #namespace:value ──
  if (lint.requireNamespacedTags) {
    for (const task of data.tasks) {
      for (const tag of task.tags) {
        if (!NAMESPACED_TAG_RE.test(tag)) {
          violations.push({
            rule: "require-namespaced-tags",
            severity,
            entity: task.id,
            message: `Tag "${tag}" on task "${task.id}" is not namespaced. Expected format: #namespace:value.`,
          });
        }
      }
    }

    for (const dec of data.decisions) {
      for (const tag of dec.tags) {
        if (!NAMESPACED_TAG_RE.test(tag)) {
          violations.push({
            rule: "require-namespaced-tags",
            severity,
            entity: dec.id,
            message: `Tag "${tag}" on decision "${dec.id}" is not namespaced. Expected format: #namespace:value.`,
          });
        }
      }
    }
  }

  // ── Check 3: Notes/description exceeding maxNotesLength ──
  if (maxNotes > 0) {
    for (const task of data.tasks) {
      if (task.description.length > maxNotes) {
        violations.push({
          rule: "max-notes-length",
          severity,
          entity: task.id,
          message: `Task "${task.id}" description is ${task.description.length} chars (max ${maxNotes}).`,
        });
      }
    }
  }

  // ── Check 4: Weekly summary files missing project metadata ──
  if (lint.requireProjectTag) {
    for (const ws of data.weeklySummaries) {
      if (!ws.project) {
        violations.push({
          rule: "weekly-missing-project",
          severity,
          entity: ws.filename,
          message: `Weekly summary "${ws.filename}" is missing project metadata in frontmatter.`,
        });
      }
    }
  }

  const errorCount = violations.filter((v) => v.severity === "error").length;
  const warningCount = violations.filter((v) => v.severity === "warning").length;
  const blocked = lint.mode === "fail" && errorCount > 0;

  return { violations, blocked, errorCount, warningCount };
}
