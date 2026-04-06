import { describe, it, expect } from "vitest";
import { suggestTags, generateIntakePrompt } from "../lib/tagSuggester";
import { DEFAULT_SETTINGS, type AppSettings } from "../lib/settings";

// Helper: create settings with a custom keyword map
function makeSettings(
  overrides?: Partial<AppSettings["tags"]["keywordMap"]>
): AppSettings {
  return {
    ...DEFAULT_SETTINGS,
    tags: {
      keywordMap: {
        ...DEFAULT_SETTINGS.tags.keywordMap,
        ...overrides,
      },
    },
  };
}

describe("suggestTags", () => {
  it("returns empty array for empty text", () => {
    expect(suggestTags("", DEFAULT_SETTINGS)).toEqual([]);
    expect(suggestTags("   ", DEFAULT_SETTINGS)).toEqual([]);
  });

  it("matches system keywords (case-insensitive)", () => {
    const result = suggestTags("We need to onboard the app in New Relic", DEFAULT_SETTINGS);
    const tags = result.map((r) => r.tag);
    expect(tags).toContain("#system:newrelic");
  });

  it("matches project keywords", () => {
    const result = suggestTags("Epsilon POT migration readiness check", DEFAULT_SETTINGS);
    const tags = result.map((r) => r.tag);
    expect(tags).toContain("#project:epsilon");
  });

  it("matches team keywords", () => {
    const result = suggestTags("GOCC shift handover procedure", DEFAULT_SETTINGS);
    const tags = result.map((r) => r.tag);
    expect(tags).toContain("#team:gocc");
  });

  it("matches multiple categories in one text", () => {
    const result = suggestTags(
      "Moogsoft alert correlation for Epsilon project, assigned to GOCC Monitoring",
      DEFAULT_SETTINGS
    );
    const tags = result.map((r) => r.tag);
    expect(tags).toContain("#system:moogsoft");
    expect(tags).toContain("#project:epsilon");
    expect(tags).toContain("#team:gocc-monitoring");
  });

  it("uses word-boundary matching for short keywords (HA, POT)", () => {
    // "HA" should match as a standalone word
    const result = suggestTags("The HA cluster needs upgrading", DEFAULT_SETTINGS);
    const tags = result.map((r) => r.tag);
    expect(tags).toContain("#project:epsilon");

    // "HA" inside another word ("HAVE") should NOT match
    const falsePos = suggestTags("We have to ship this today", DEFAULT_SETTINGS);
    const fpTags = falsePos.map((r) => r.tag);
    expect(fpTags).not.toContain("#project:epsilon");
  });

  it("short keyword L0 matches with word boundary", () => {
    const result = suggestTags("L0 triage process update", DEFAULT_SETTINGS);
    const tags = result.map((r) => r.tag);
    expect(tags).toContain("#team:gocc-monitoring");
  });

  it("does not double-count the same tag", () => {
    const result = suggestTags(
      "Azure Azure Azure cloud infrastructure ADX",
      DEFAULT_SETTINGS
    );
    const azureTags = result.filter((r) => r.tag === "#system:azure");
    expect(azureTags).toHaveLength(1);
  });

  it("returns high confidence for keywords ≥ 4 chars", () => {
    const result = suggestTags("Moogsoft noise reduction", DEFAULT_SETTINGS);
    const moog = result.find((r) => r.tag === "#system:moogsoft");
    expect(moog?.confidence).toBe("high");
  });

  it("returns medium confidence for short keywords", () => {
    const result = suggestTags("The HA architecture is ready", DEFAULT_SETTINGS);
    const ha = result.find((r) => r.tag === "#project:epsilon");
    expect(ha?.confidence).toBe("medium");
  });

  it("sorts by confidence then category then tag", () => {
    const result = suggestTags(
      "HA upgrade for Moogsoft alerts at GOCC",
      DEFAULT_SETTINGS
    );
    // "Moogsoft" (high, system), "GOCC" (high, team) should come before "HA" (medium, project)
    const highTags = result.filter((r) => r.confidence === "high");
    const medTags = result.filter((r) => r.confidence === "medium");
    expect(result.indexOf(highTags[0])).toBeLessThan(result.indexOf(medTags[0]));
  });

  it("works with custom keyword map overrides", () => {
    const settings = makeSettings({
      systems: { "#system:custom": ["foobar", "baz"] },
    });
    const result = suggestTags("We deployed foobar", settings);
    const tags = result.map((r) => r.tag);
    expect(tags).toContain("#system:custom");
  });

  it("returns empty when settings.tags is missing", () => {
    const noTags = { ...DEFAULT_SETTINGS, tags: undefined } as unknown as AppSettings;
    expect(suggestTags("Moogsoft New Relic", noTags)).toEqual([]);
  });

  it("matches CMDB (case-insensitive)", () => {
    const result = suggestTags("cmdb reconciliation needed", DEFAULT_SETTINGS);
    const tags = result.map((r) => r.tag);
    expect(tags).toContain("#system:cmdb");
  });
});

describe("generateIntakePrompt", () => {
  it("contains the raw text in a code block", () => {
    const prompt = generateIntakePrompt("Hello world", DEFAULT_SETTINGS);
    expect(prompt).toContain("Hello world");
    expect(prompt).toContain("```");
  });

  it("includes objective registry when provided", () => {
    const prompt = generateIntakePrompt("note", DEFAULT_SETTINGS, "## O1 — Observability");
    expect(prompt).toContain("Objective Registry");
    expect(prompt).toContain("O1 — Observability");
  });

  it("includes default project slug", () => {
    const prompt = generateIntakePrompt("note", DEFAULT_SETTINGS);
    expect(prompt).toContain("#project:lapu-lapu");
  });

  it("includes keyword map sections", () => {
    const prompt = generateIntakePrompt("note", DEFAULT_SETTINGS);
    expect(prompt).toContain("### Systems");
    expect(prompt).toContain("### Projects");
    expect(prompt).toContain("### Teams");
  });
});
