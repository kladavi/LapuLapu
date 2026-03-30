"use client";

import React, { useState, useMemo, useCallback } from "react";
import { usePMData } from "../context/PMContext";
import { suggestTags, generateIntakePrompt, type TagSuggestion } from "../lib/tagSuggester";

/**
 * IntakeTab — paste raw notes, get heuristic tag suggestions, optionally
 * copy a Copilot-ready prompt for AI-assisted routing.
 */
export function IntakeTab() {
  const { data } = usePMData();
  const [rawText, setRawText] = useState("");
  const [accepted, setAccepted] = useState<Set<string>>(new Set());
  const [copyFeedback, setCopyFeedback] = useState<string | null>(null);

  const settings = data?.settings;

  // Compute suggestions whenever text or settings change
  const suggestions = useMemo<TagSuggestion[]>(() => {
    if (!rawText.trim() || !settings) return [];
    return suggestTags(rawText, settings);
  }, [rawText, settings]);

  // Toggle a tag chip on/off
  const toggleTag = useCallback((tag: string) => {
    setAccepted((prev) => {
      const next = new Set(prev);
      if (next.has(tag)) next.delete(tag);
      else next.add(tag);
      return next;
    });
  }, []);

  // Accept all suggestions at once
  const acceptAll = useCallback(() => {
    setAccepted(new Set(suggestions.map((s) => s.tag)));
  }, [suggestions]);

  // Clear all accepted
  const clearAll = useCallback(() => {
    setAccepted(new Set());
  }, []);

  // Build tagged text with accepted tags appended
  const taggedText = useMemo(() => {
    if (!rawText.trim()) return "";
    const tagLine = [...accepted].join(" ");
    return tagLine ? `${rawText.trimEnd()}\n\nTags: ${tagLine}` : rawText;
  }, [rawText, accepted]);

  // Copy tagged text to clipboard
  const handleCopyTagged = useCallback(async () => {
    if (!taggedText) return;
    try {
      await navigator.clipboard.writeText(taggedText);
      setCopyFeedback("Copied tagged text!");
      setTimeout(() => setCopyFeedback(null), 2500);
    } catch {
      setCopyFeedback("Copy failed — check browser permissions");
      setTimeout(() => setCopyFeedback(null), 3000);
    }
  }, [taggedText]);

  // Copy Copilot-ready intake prompt
  const handleCopyPrompt = useCallback(async () => {
    if (!settings) return;
    const objRaw = data?.rawFiles?.["00-context/objectives.md"];
    const prompt = generateIntakePrompt(rawText, settings, objRaw);
    try {
      await navigator.clipboard.writeText(prompt);
      setCopyFeedback("Copilot prompt copied!");
      setTimeout(() => setCopyFeedback(null), 2500);
    } catch {
      setCopyFeedback("Copy failed — check browser permissions");
      setTimeout(() => setCopyFeedback(null), 3000);
    }
  }, [rawText, settings, data?.rawFiles]);

  if (!data) return null;

  const chipColor: Record<TagSuggestion["category"], { bg: string; border: string; text: string }> = {
    project: { bg: "bg-purple-50", border: "border-purple-300", text: "text-purple-800" },
    system:  { bg: "bg-blue-50",   border: "border-blue-300",   text: "text-blue-800" },
    team:    { bg: "bg-green-50",   border: "border-green-300",  text: "text-green-800" },
  };

  return (
    <div className="p-6 max-w-5xl mx-auto space-y-6">
      {/* Header */}
      <div>
        <h2 className="text-lg font-semibold text-th-text flex items-center gap-2">
          📥 Intake — Tag Suggestions
        </h2>
        <p className="text-sm text-th-text-muted mt-1">
          Paste raw notes below. Tags are suggested automatically from keyword maps configured in{" "}
          <span className="font-mono text-xs bg-th-surface-alt px-1 rounded">Settings → Tag Suggestions</span>.
        </p>
      </div>

      {/* Text area */}
      <div>
        <label className="block text-sm font-medium text-th-text-secondary mb-1">
          Raw Notes
        </label>
        <textarea
          value={rawText}
          onChange={(e) => setRawText(e.target.value)}
          placeholder="Paste meeting notes, email content, or any raw input here…"
          rows={10}
          className="block w-full rounded-lg border border-th-border-strong bg-th-surface px-4 py-3 text-sm text-th-text shadow-sm focus:border-th-accent focus:ring-1 focus:ring-th-accent outline-none resize-y font-mono"
        />
        <p className="text-xs text-th-text-faint mt-1">
          {rawText.length > 0 ? `${rawText.length} chars` : "No text entered"}
        </p>
      </div>

      {/* Suggestions */}
      {suggestions.length > 0 && (
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-semibold text-th-text-secondary">
              Suggested Tags ({suggestions.length})
            </h3>
            <div className="flex gap-2">
              <button
                onClick={acceptAll}
                className="text-xs text-th-accent hover:text-th-accent-hover cursor-pointer"
              >
                Accept All
              </button>
              <span className="text-th-text-faint">|</span>
              <button
                onClick={clearAll}
                className="text-xs text-th-text-muted hover:text-th-text-secondary cursor-pointer"
              >
                Clear All
              </button>
            </div>
          </div>

          <div className="flex flex-wrap gap-2">
            {suggestions.map((s) => {
              const isOn = accepted.has(s.tag);
              const colors = chipColor[s.category];
              return (
                <button
                  key={s.tag}
                  onClick={() => toggleTag(s.tag)}
                  title={`Matched keyword: "${s.source}" (${s.confidence} confidence)`}
                  className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium border transition-all cursor-pointer select-none ${
                    isOn
                      ? `${colors.bg} ${colors.border} ${colors.text} ring-2 ring-offset-1 ring-th-accent`
                      : `bg-th-surface-alt border-th-border text-th-text-muted hover:bg-th-border`
                  }`}
                >
                  {isOn ? "✓" : "○"}{" "}
                  <span className="font-mono">{s.tag}</span>
                  <span className={`text-[10px] ${s.confidence === "high" ? "text-emerald-500" : "text-amber-500"}`}>
                    ({s.confidence})
                  </span>
                </button>
              );
            })}
          </div>
        </div>
      )}

      {rawText.trim() && suggestions.length === 0 && (
        <div className="rounded-lg border border-th-warn bg-th-warn-light p-3 text-sm text-th-warn">
          ⚠️ No keyword matches found. Try the <strong>Copy Copilot Prompt</strong> button for AI-assisted tagging, or update keyword maps in Settings.
        </div>
      )}

      {/* Actions */}
      <div className="flex flex-wrap items-center gap-3 pt-2">
        {accepted.size > 0 && (
          <button
            onClick={handleCopyTagged}
            className="inline-flex items-center gap-2 rounded-lg bg-th-accent px-4 py-2 text-sm text-white font-medium hover:bg-th-accent-hover transition-colors cursor-pointer"
          >
            📋 Copy Tagged Text
          </button>
        )}

        <button
          onClick={handleCopyPrompt}
          disabled={!rawText.trim()}
          className="inline-flex items-center gap-2 rounded-lg border border-th-border-strong bg-th-surface px-4 py-2 text-sm text-th-text-secondary font-medium hover:bg-th-surface-alt transition-colors cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed"
        >
          🤖 Copy Copilot Prompt
        </button>

        {copyFeedback && (
          <span className="text-sm text-th-success font-medium animate-pulse">
            {copyFeedback}
          </span>
        )}
      </div>

      {/* Preview */}
      {accepted.size > 0 && taggedText && (
        <div className="space-y-2">
          <h3 className="text-sm font-semibold text-th-text-secondary">Preview — Tagged Text</h3>
          <pre className="bg-th-surface-alt border border-th-border rounded-lg p-4 text-xs font-mono overflow-auto max-h-48 whitespace-pre-wrap text-th-text-secondary">
            {taggedText}
          </pre>
        </div>
      )}

      {/* Legend */}
      <div className="border-t border-th-border pt-4">
        <p className="text-xs text-th-text-faint">
          <strong>Chip colours:</strong>{" "}
          <span className="text-purple-600">■ project</span>{" · "}
          <span className="text-blue-600">■ system</span>{" · "}
          <span className="text-green-600">■ team</span>{" · "}
          Confidence: <span className="text-emerald-500">high</span> (keyword ≥ 4 chars) /{" "}
          <span className="text-amber-500">medium</span> (short keyword, word-boundary matched)
        </p>
      </div>
    </div>
  );
}
