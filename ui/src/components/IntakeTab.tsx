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
        <h2 className="text-lg font-semibold text-gray-800 flex items-center gap-2">
          📥 Intake — Tag Suggestions
        </h2>
        <p className="text-sm text-gray-500 mt-1">
          Paste raw notes below. Tags are suggested automatically from keyword maps configured in{" "}
          <span className="font-mono text-xs bg-gray-100 px-1 rounded">Settings → Tag Suggestions</span>.
        </p>
      </div>

      {/* Text area */}
      <div>
        <label className="block text-sm font-medium text-gray-600 mb-1">
          Raw Notes
        </label>
        <textarea
          value={rawText}
          onChange={(e) => setRawText(e.target.value)}
          placeholder="Paste meeting notes, email content, or any raw input here…"
          rows={10}
          className="block w-full rounded-lg border border-gray-300 bg-white px-4 py-3 text-sm text-gray-900 shadow-sm focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none resize-y font-mono"
        />
        <p className="text-xs text-gray-400 mt-1">
          {rawText.length > 0 ? `${rawText.length} chars` : "No text entered"}
        </p>
      </div>

      {/* Suggestions */}
      {suggestions.length > 0 && (
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-semibold text-gray-700">
              Suggested Tags ({suggestions.length})
            </h3>
            <div className="flex gap-2">
              <button
                onClick={acceptAll}
                className="text-xs text-blue-600 hover:text-blue-800 cursor-pointer"
              >
                Accept All
              </button>
              <span className="text-gray-300">|</span>
              <button
                onClick={clearAll}
                className="text-xs text-gray-500 hover:text-gray-700 cursor-pointer"
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
                      ? `${colors.bg} ${colors.border} ${colors.text} ring-2 ring-offset-1 ring-blue-400`
                      : `bg-gray-50 border-gray-200 text-gray-500 hover:bg-gray-100`
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
        <div className="rounded-lg border border-amber-200 bg-amber-50 p-3 text-sm text-amber-700">
          ⚠️ No keyword matches found. Try the <strong>Copy Copilot Prompt</strong> button for AI-assisted tagging, or update keyword maps in Settings.
        </div>
      )}

      {/* Actions */}
      <div className="flex flex-wrap items-center gap-3 pt-2">
        {accepted.size > 0 && (
          <button
            onClick={handleCopyTagged}
            className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm text-white font-medium hover:bg-blue-700 transition-colors cursor-pointer"
          >
            📋 Copy Tagged Text
          </button>
        )}

        <button
          onClick={handleCopyPrompt}
          disabled={!rawText.trim()}
          className="inline-flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm text-gray-700 font-medium hover:bg-gray-50 transition-colors cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed"
        >
          🤖 Copy Copilot Prompt
        </button>

        {copyFeedback && (
          <span className="text-sm text-emerald-600 font-medium animate-pulse">
            {copyFeedback}
          </span>
        )}
      </div>

      {/* Preview */}
      {accepted.size > 0 && taggedText && (
        <div className="space-y-2">
          <h3 className="text-sm font-semibold text-gray-700">Preview — Tagged Text</h3>
          <pre className="bg-gray-50 border border-gray-200 rounded-lg p-4 text-xs font-mono overflow-auto max-h-48 whitespace-pre-wrap text-gray-700">
            {taggedText}
          </pre>
        </div>
      )}

      {/* Legend */}
      <div className="border-t border-gray-100 pt-4">
        <p className="text-xs text-gray-400">
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
