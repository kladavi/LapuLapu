"use client";

import React, { useState, useMemo, useCallback, useEffect } from "react";
import { usePMData } from "../context/PMContext";
import {
  buildIntakePrompt,
  parseIntakeResponse,
  parseInboxEntries,
  type IntakeResult,
  type InboxEntry,
} from "../lib/intakeProcessor";

interface ExtractedFile {
  filename: string;
  text: string;
  type: string;
  error?: string;
}

type Phase = "input" | "prompt" | "review" | "done";

/**
 * IntakeTab — redesigned intake processor.
 *
 * Flow:
 *   1. INPUT   – paste text, pick #raw inbox entries, or type notes
 *   2. PROMPT  – generated LLM prompt copied; user pastes back LLM response
 *   3. REVIEW  – parsed tasks/decisions shown for approve/reject
 *   4. DONE    – approved items appended to files, inbox marked #processed
 */
export function IntakeTab() {
  const { data, loadFiles } = usePMData();

  // Phase state
  const [phase, setPhase] = useState<Phase>("input");

  // Phase 1: input
  const [rawText, setRawText] = useState("");
  const [selectedInbox, setSelectedInbox] = useState<Set<number>>(new Set());

  // Phase 2: prompt / response
  const [generatedPrompt, setGeneratedPrompt] = useState("");
  const [llmResponse, setLlmResponse] = useState("");

  // Phase 3: review
  const [results, setResults] = useState<IntakeResult[]>([]);

  // Phase 4: done
  const [applySummary, setApplySummary] = useState<string[]>([]);

  // Feedback
  const [feedback, setFeedback] = useState<string | null>(null);
  const [applying, setApplying] = useState(false);

  // Extracted binary files from inbox
  const [extractedFiles, setExtractedFiles] = useState<ExtractedFile[]>([]);
  const [extractedLoading, setExtractedLoading] = useState(false);
  const [selectedExtracted, setSelectedExtracted] = useState<Set<number>>(new Set());

  // Fetch extracted files on mount
  useEffect(() => {
    let cancelled = false;
    async function fetchExtracted() {
      setExtractedLoading(true);
      try {
        const res = await fetch("/api/extract-inbox");
        if (!res.ok) return;
        const { files } = await res.json() as { files: ExtractedFile[] };
        if (!cancelled) setExtractedFiles(files);
      } catch {
        // Non-critical — binary extraction is optional
      } finally {
        if (!cancelled) setExtractedLoading(false);
      }
    }
    fetchExtracted();
    return () => { cancelled = true; };
  }, []);

  // Parse inbox entries from loaded data
  const inboxEntries = useMemo<InboxEntry[]>(() => {
    if (!data?.inbox) return [];
    return parseInboxEntries(data.inbox);
  }, [data?.inbox]);

  const rawEntries = useMemo(
    () => inboxEntries.filter((e) => e.status === "raw"),
    [inboxEntries]
  );

  // Build combined input from textarea + selected inbox entries + selected extracted files
  const combinedInput = useMemo(() => {
    const parts: string[] = [];
    if (rawText.trim()) parts.push(rawText.trim());
    for (const idx of selectedInbox) {
      if (rawEntries[idx]) {
        parts.push(rawEntries[idx].text);
      }
    }
    for (const idx of selectedExtracted) {
      const f = extractedFiles[idx];
      if (f && f.text) {
        parts.push(`[Source: ${f.filename}]\n${f.text}`);
      }
    }
    return parts.join("\n\n---\n\n");
  }, [rawText, selectedInbox, rawEntries, selectedExtracted, extractedFiles]);

  const hasInput = combinedInput.trim().length > 0;

  // ── Phase 1 → 2: Generate prompt ──
  const handleGeneratePrompt = useCallback(() => {
    if (!data || !hasInput) return;
    const prompt = buildIntakePrompt(combinedInput, data);
    setGeneratedPrompt(prompt);
    setPhase("prompt");
  }, [data, combinedInput, hasInput]);

  // Copy prompt to clipboard
  const handleCopyPrompt = useCallback(async () => {
    try {
      await navigator.clipboard.writeText(generatedPrompt);
      setFeedback("Prompt copied to clipboard!");
      setTimeout(() => setFeedback(null), 2500);
    } catch {
      setFeedback("Copy failed — check browser permissions");
      setTimeout(() => setFeedback(null), 3000);
    }
  }, [generatedPrompt]);

  // ── Phase 2 → 3: Parse LLM response ──
  const handleParseResponse = useCallback(() => {
    if (!llmResponse.trim()) return;
    const parsed = parseIntakeResponse(llmResponse);
    if (parsed.length === 0) {
      setFeedback("No task or decision blocks found. Ensure the response contains ## T### or ## D### headings.");
      setTimeout(() => setFeedback(null), 4000);
      return;
    }
    setResults(parsed);
    setPhase("review");
  }, [llmResponse]);

  // Toggle approval of a result
  const toggleApproval = useCallback((index: number) => {
    setResults((prev) =>
      prev.map((r, i) => (i === index ? { ...r, approved: !r.approved } : r))
    );
  }, []);

  // ── Phase 3 → 4: Apply approved changes ──
  const handleApply = useCallback(async () => {
    if (!data) return;
    setApplying(true);
    const summary: string[] = [];

    try {
      const approvedTasks = results.filter((r) => r.approved && r.type === "task");
      const approvedDecisions = results.filter((r) => r.approved && r.type === "decision");

      // Append tasks to 02-work/tasks.md
      if (approvedTasks.length > 0) {
        const tasksKey = Object.keys(data.rawFiles).find(
          (k) => k.replace(/\\/g, "/").endsWith("02-work/tasks.md")
        );
        const existingTasks = tasksKey ? data.rawFiles[tasksKey] : "# Tasks\n";
        const newBlocks = approvedTasks.map((t) => t.raw).join("\n\n---\n\n");
        const updatedTasks = existingTasks.trimEnd() + "\n\n---\n\n" + newBlocks + "\n";

        const res = await fetch("/api/save-local", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ filePath: "02-work/tasks.md", content: updatedTasks }),
        });
        if (!res.ok) throw new Error("Failed to save tasks.md");
        summary.push(`${approvedTasks.length} task(s) appended to tasks.md`);
      }

      // Append decisions to 02-work/decisions.md
      if (approvedDecisions.length > 0) {
        const decisionsKey = Object.keys(data.rawFiles).find(
          (k) => k.replace(/\\/g, "/").endsWith("02-work/decisions.md")
        );
        const existingDecisions = decisionsKey ? data.rawFiles[decisionsKey] : "# Decisions Log\n";
        const newBlocks = approvedDecisions.map((d) => d.raw).join("\n\n---\n\n");
        const updatedDecisions = existingDecisions.trimEnd() + "\n\n---\n\n" + newBlocks + "\n";

        const res = await fetch("/api/save-local", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ filePath: "02-work/decisions.md", content: updatedDecisions }),
        });
        if (!res.ok) throw new Error("Failed to save decisions.md");
        summary.push(`${approvedDecisions.length} decision(s) appended to decisions.md`);
      }

      // Mark selected inbox entries as #processed
      if (selectedInbox.size > 0 && data.inbox) {
        let updatedInbox = data.inbox;
        for (const idx of selectedInbox) {
          if (rawEntries[idx]) {
            const entry = rawEntries[idx];
            // Replace #raw with #processed in the entry's first line
            const rawLine = entry.text.split("\n")[0];
            const processedLine = rawLine.replace("#raw", "#processed");
            updatedInbox = updatedInbox.replace(rawLine, processedLine);
          }
        }
        const res = await fetch("/api/save-local", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ filePath: "01-inbox/inbox.md", content: updatedInbox }),
        });
        if (!res.ok) throw new Error("Failed to update inbox.md");
        summary.push(`${selectedInbox.size} inbox item(s) marked as #processed`);
      }

      const rejected = results.filter((r) => !r.approved).length;
      if (rejected > 0) {
        summary.push(`${rejected} item(s) skipped (not approved)`);
      }

      setApplySummary(summary);
      setPhase("done");

      // Reload files to reflect changes
      try {
        const res = await fetch("/api/load-local");
        if (res.ok) {
          const { files, folderName } = await res.json();
          loadFiles(files, folderName);
        }
      } catch {
        // Non-critical — data is saved, just won't reflect immediately
      }
    } catch (err) {
      setFeedback(`Error: ${err instanceof Error ? err.message : "Unknown error"}`);
      setTimeout(() => setFeedback(null), 4000);
    } finally {
      setApplying(false);
    }
  }, [data, results, selectedInbox, rawEntries, loadFiles]);

  // ── Reset to start over ──
  const handleReset = useCallback(() => {
    setPhase("input");
    setRawText("");
    setSelectedInbox(new Set());
    setSelectedExtracted(new Set());
    setGeneratedPrompt("");
    setLlmResponse("");
    setResults([]);
    setApplySummary([]);
    setFeedback(null);
  }, []);

  // Toggle inbox entry selection
  const toggleInbox = useCallback((idx: number) => {
    setSelectedInbox((prev) => {
      const next = new Set(prev);
      if (next.has(idx)) next.delete(idx);
      else next.add(idx);
      return next;
    });
  }, []);

  const selectAllRaw = useCallback(() => {
    setSelectedInbox(new Set(rawEntries.map((_, i) => i)));
  }, [rawEntries]);

  // Toggle extracted file selection
  const toggleExtracted = useCallback((idx: number) => {
    setSelectedExtracted((prev) => {
      const next = new Set(prev);
      if (next.has(idx)) next.delete(idx);
      else next.add(idx);
      return next;
    });
  }, []);

  const selectAllExtracted = useCallback(() => {
    setSelectedExtracted(
      new Set(extractedFiles.filter((f) => f.text && !f.error).map((_, i) => i))
    );
  }, [extractedFiles]);

  if (!data) return null;

  return (
    <div className="p-6 max-w-5xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-lg font-semibold text-th-text flex items-center gap-2">
            📥 Intake Processor
          </h2>
          <p className="text-sm text-th-text-muted mt-1">
            Process raw inputs into categorised tasks and decisions.
          </p>
        </div>
        {/* Phase indicator */}
        <div className="flex items-center gap-1 text-xs">
          {(["input", "prompt", "review", "done"] as Phase[]).map((p, i) => (
            <React.Fragment key={p}>
              {i > 0 && <span className="text-th-text-faint mx-1">&rarr;</span>}
              <span
                className={`px-2 py-1 rounded ${
                  phase === p
                    ? "bg-th-accent text-white font-medium"
                    : "bg-th-surface-alt text-th-text-muted"
                }`}
              >
                {i + 1}. {p.charAt(0).toUpperCase() + p.slice(1)}
              </span>
            </React.Fragment>
          ))}
        </div>
      </div>

      {/* ═══════════ PHASE 1: INPUT ═══════════ */}
      {phase === "input" && (
        <div className="space-y-6">
          {/* Inbox entries */}
          {rawEntries.length > 0 && (
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <h3 className="text-sm font-semibold text-th-text-secondary">
                  Unprocessed Inbox Items ({rawEntries.length})
                </h3>
                <button
                  onClick={selectAllRaw}
                  className="text-xs text-th-accent hover:text-th-accent-hover cursor-pointer"
                >
                  Select All
                </button>
              </div>
              <div className="space-y-2">
                {rawEntries.map((entry, idx) => {
                  const isSelected = selectedInbox.has(idx);
                  return (
                    <button
                      key={idx}
                      onClick={() => toggleInbox(idx)}
                      className={`w-full text-left rounded-lg border p-3 transition-colors cursor-pointer ${
                        isSelected
                          ? "border-th-accent bg-th-accent/5 ring-1 ring-th-accent"
                          : "border-th-border bg-th-surface hover:border-th-border-strong"
                      }`}
                    >
                      <div className="flex items-center gap-2">
                        <span className={`text-sm ${isSelected ? "text-th-accent" : "text-th-text-muted"}`}>
                          {isSelected ? "✓" : "○"}
                        </span>
                        <span className="text-sm font-medium text-th-text">{entry.label}</span>
                        <span className="ml-auto text-xs px-2 py-0.5 rounded-full bg-amber-100 text-amber-700">
                          #raw
                        </span>
                      </div>
                      {isSelected && (
                        <pre className="mt-2 text-xs text-th-text-secondary font-mono whitespace-pre-wrap max-h-32 overflow-auto border-t border-th-border pt-2">
                          {entry.text.slice(0, 500)}{entry.text.length > 500 ? "..." : ""}
                        </pre>
                      )}
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {inboxEntries.length > 0 && rawEntries.length === 0 && (
            <div className="rounded-lg border border-th-success/30 bg-th-success/5 p-4 text-sm text-th-success">
              All inbox items have been processed. You can still paste new text below.
            </div>
          )}

          {/* Extracted binary files */}
          {extractedLoading && (
            <div className="text-sm text-th-text-muted animate-pulse">
              Scanning inbox for PDF, DOCX, EML files…
            </div>
          )}
          {!extractedLoading && extractedFiles.length > 0 && (
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <h3 className="text-sm font-semibold text-th-text-secondary">
                  📎 Inbox Files ({extractedFiles.length})
                </h3>
                <button
                  onClick={selectAllExtracted}
                  className="text-xs text-th-accent hover:text-th-accent-hover cursor-pointer"
                >
                  Select All
                </button>
              </div>
              <div className="space-y-2">
                {extractedFiles.map((file, idx) => {
                  const isSelected = selectedExtracted.has(idx);
                  const hasError = !!file.error || !file.text;
                  const typeLabel = file.type.toUpperCase();
                  const typeBg =
                    file.type === "pdf" ? "bg-red-100 text-red-700"
                    : file.type === "docx" ? "bg-blue-100 text-blue-700"
                    : file.type === "eml" ? "bg-green-100 text-green-700"
                    : "bg-gray-100 text-gray-600";

                  return (
                    <button
                      key={idx}
                      onClick={() => !hasError && toggleExtracted(idx)}
                      disabled={hasError}
                      className={`w-full text-left rounded-lg border p-3 transition-colors ${
                        hasError
                          ? "border-th-border bg-th-surface opacity-50 cursor-not-allowed"
                          : isSelected
                            ? "border-th-accent bg-th-accent/5 ring-1 ring-th-accent cursor-pointer"
                            : "border-th-border bg-th-surface hover:border-th-border-strong cursor-pointer"
                      }`}
                    >
                      <div className="flex items-center gap-2">
                        <span className={`text-sm ${isSelected ? "text-th-accent" : "text-th-text-muted"}`}>
                          {hasError ? "✗" : isSelected ? "✓" : "○"}
                        </span>
                        <span className="text-sm font-medium text-th-text">{file.filename}</span>
                        <span className={`ml-auto text-xs px-2 py-0.5 rounded-full ${typeBg}`}>
                          {typeLabel}
                        </span>
                      </div>
                      {hasError && (
                        <p className="mt-1 text-xs text-red-500 ml-6">
                          {file.error || "No text extracted"}
                        </p>
                      )}
                      {isSelected && !hasError && (
                        <pre className="mt-2 text-xs text-th-text-secondary font-mono whitespace-pre-wrap max-h-32 overflow-auto border-t border-th-border pt-2">
                          {file.text.slice(0, 500)}{file.text.length > 500 ? "..." : ""}
                        </pre>
                      )}
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* Divider when both sections are present */}
          {(rawEntries.length > 0 || extractedFiles.length > 0) && (
            <div className="flex items-center gap-3">
              <div className="flex-1 border-t border-th-border" />
              <span className="text-xs text-th-text-faint">and / or</span>
              <div className="flex-1 border-t border-th-border" />
            </div>
          )}

          {/* Text input */}
          <div>
            <label className="block text-sm font-semibold text-th-text-secondary mb-1">
              Paste or Type Raw Input
            </label>
            <textarea
              value={rawText}
              onChange={(e) => setRawText(e.target.value)}
              placeholder="Paste meeting notes, email content, action items, or any raw input here..."
              rows={8}
              className="block w-full rounded-lg border border-th-border-strong bg-th-surface px-4 py-3 text-sm text-th-text shadow-sm focus:border-th-accent focus:ring-1 focus:ring-th-accent outline-none resize-y"
            />
            <p className="text-xs text-th-text-faint mt-1">
              {rawText.length > 0 ? `${rawText.length} characters` : "No text entered"}
              {selectedInbox.size > 0 && ` · ${selectedInbox.size} inbox item(s) selected`}
              {selectedExtracted.size > 0 && ` · ${selectedExtracted.size} file(s) selected`}
            </p>
          </div>

          {/* Process button */}
          <div className="flex items-center gap-3">
            <button
              onClick={handleGeneratePrompt}
              disabled={!hasInput}
              className="inline-flex items-center gap-2 rounded-lg bg-th-accent px-5 py-2.5 text-sm text-white font-medium hover:bg-th-accent-hover transition-colors cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed"
            >
              ⚡ Generate Processing Prompt
            </button>
            <span className="text-xs text-th-text-faint">
              Creates an AI prompt with full project context
            </span>
          </div>
        </div>
      )}

      {/* ═══════════ PHASE 2: PROMPT + RESPONSE ═══════════ */}
      {phase === "prompt" && (
        <div className="space-y-6">
          {/* Generated prompt */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-semibold text-th-text-secondary">
                Step 1: Copy This Prompt
              </h3>
              <button
                onClick={handleCopyPrompt}
                className="inline-flex items-center gap-1.5 rounded-lg bg-th-accent px-3 py-1.5 text-xs text-white font-medium hover:bg-th-accent-hover transition-colors cursor-pointer"
              >
                📋 Copy Prompt
              </button>
            </div>
            <p className="text-xs text-th-text-muted">
              Copy this prompt and paste it into your LLM (Copilot Chat, ChatGPT, Claude, etc.)
            </p>
            <pre className="bg-th-surface-alt border border-th-border rounded-lg p-4 text-xs font-mono overflow-auto max-h-64 whitespace-pre-wrap text-th-text-secondary">
              {generatedPrompt.slice(0, 2000)}{generatedPrompt.length > 2000 ? `\n\n... (${generatedPrompt.length.toLocaleString()} chars total)` : ""}
            </pre>
          </div>

          {/* LLM response paste area */}
          <div className="space-y-2">
            <h3 className="text-sm font-semibold text-th-text-secondary">
              Step 2: Paste the LLM Response
            </h3>
            <p className="text-xs text-th-text-muted">
              After your LLM processes the prompt, paste its full response here.
            </p>
            <textarea
              value={llmResponse}
              onChange={(e) => setLlmResponse(e.target.value)}
              placeholder="Paste the LLM response containing ## T### and ## D### blocks..."
              rows={12}
              className="block w-full rounded-lg border border-th-border-strong bg-th-surface px-4 py-3 text-sm text-th-text shadow-sm focus:border-th-accent focus:ring-1 focus:ring-th-accent outline-none resize-y font-mono"
            />
            <p className="text-xs text-th-text-faint">
              {llmResponse.length > 0 ? `${llmResponse.length} characters` : "Waiting for response..."}
            </p>
          </div>

          {/* Actions */}
          <div className="flex items-center gap-3">
            <button
              onClick={handleParseResponse}
              disabled={!llmResponse.trim()}
              className="inline-flex items-center gap-2 rounded-lg bg-th-accent px-5 py-2.5 text-sm text-white font-medium hover:bg-th-accent-hover transition-colors cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed"
            >
              🔍 Parse &amp; Preview
            </button>
            <button
              onClick={() => setPhase("input")}
              className="inline-flex items-center gap-2 rounded-lg border border-th-border-strong bg-th-surface px-4 py-2.5 text-sm text-th-text-secondary font-medium hover:bg-th-surface-alt transition-colors cursor-pointer"
            >
              ← Back to Input
            </button>
          </div>
        </div>
      )}

      {/* ═══════════ PHASE 3: REVIEW ═══════════ */}
      {phase === "review" && (
        <div className="space-y-6">
          <div>
            <h3 className="text-sm font-semibold text-th-text-secondary">
              Review Extracted Items ({results.length})
            </h3>
            <p className="text-xs text-th-text-muted mt-1">
              Toggle items to approve or skip them before applying.
            </p>
          </div>

          <div className="space-y-3">
            {results.map((item, idx) => (
              <div
                key={item.id}
                className={`rounded-lg border p-4 transition-colors ${
                  item.approved
                    ? "border-th-success/40 bg-th-success/5"
                    : "border-th-border bg-th-surface opacity-60"
                }`}
              >
                <div className="flex items-center gap-3">
                  <button
                    onClick={() => toggleApproval(idx)}
                    className={`flex-shrink-0 w-6 h-6 rounded border-2 flex items-center justify-center cursor-pointer transition-colors ${
                      item.approved
                        ? "border-th-success bg-th-success text-white"
                        : "border-th-border-strong bg-th-surface text-transparent hover:border-th-text-muted"
                    }`}
                  >
                    {item.approved && "✓"}
                  </button>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className={`text-xs font-mono px-1.5 py-0.5 rounded ${
                        item.type === "task"
                          ? "bg-blue-100 text-blue-700"
                          : "bg-amber-100 text-amber-700"
                      }`}>
                        {item.id}
                      </span>
                      <span className="text-sm font-medium text-th-text truncate">
                        {item.title}
                      </span>
                    </div>
                  </div>
                  <span className={`text-xs px-2 py-0.5 rounded-full ${
                    item.type === "task"
                      ? "bg-blue-50 text-blue-600"
                      : "bg-amber-50 text-amber-600"
                  }`}>
                    {item.type}
                  </span>
                </div>
                <pre className="mt-3 text-xs text-th-text-secondary font-mono whitespace-pre-wrap max-h-40 overflow-auto border-t border-th-border pt-2">
                  {item.raw}
                </pre>
              </div>
            ))}
          </div>

          {/* Summary bar */}
          <div className="flex items-center justify-between rounded-lg bg-th-surface-alt border border-th-border p-3">
            <span className="text-sm text-th-text-secondary">
              <strong>{results.filter((r) => r.approved).length}</strong> of{" "}
              <strong>{results.length}</strong> items approved
              {" · "}
              <span className="text-blue-600">
                {results.filter((r) => r.approved && r.type === "task").length} tasks
              </span>
              {" · "}
              <span className="text-amber-600">
                {results.filter((r) => r.approved && r.type === "decision").length} decisions
              </span>
            </span>
          </div>

          {/* Actions */}
          <div className="flex items-center gap-3">
            <button
              onClick={handleApply}
              disabled={applying || results.filter((r) => r.approved).length === 0}
              className="inline-flex items-center gap-2 rounded-lg bg-th-success px-5 py-2.5 text-sm text-white font-medium hover:opacity-90 transition-colors cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed"
            >
              {applying ? "Applying..." : "✓ Apply Approved Changes"}
            </button>
            <button
              onClick={() => setPhase("prompt")}
              className="inline-flex items-center gap-2 rounded-lg border border-th-border-strong bg-th-surface px-4 py-2.5 text-sm text-th-text-secondary font-medium hover:bg-th-surface-alt transition-colors cursor-pointer"
            >
              ← Back to Prompt
            </button>
          </div>
        </div>
      )}

      {/* ═══════════ PHASE 4: DONE ═══════════ */}
      {phase === "done" && (
        <div className="space-y-6">
          <div className="rounded-lg border border-th-success/40 bg-th-success/5 p-6 text-center space-y-4">
            <div className="text-4xl">✅</div>
            <h3 className="text-lg font-semibold text-th-text">
              Intake Complete
            </h3>
            <ul className="space-y-1">
              {applySummary.map((line, i) => (
                <li key={i} className="text-sm text-th-text-secondary">
                  {line}
                </li>
              ))}
            </ul>
          </div>

          <div className="flex items-center justify-center gap-3">
            <button
              onClick={handleReset}
              className="inline-flex items-center gap-2 rounded-lg bg-th-accent px-5 py-2.5 text-sm text-white font-medium hover:bg-th-accent-hover transition-colors cursor-pointer"
            >
              📥 Process More Items
            </button>
          </div>
        </div>
      )}

      {/* Global feedback toast */}
      {feedback && (
        <div className="fixed bottom-6 right-6 rounded-lg bg-th-surface border border-th-border-strong shadow-lg px-4 py-3 text-sm text-th-text max-w-sm animate-pulse z-50">
          {feedback}
        </div>
      )}
    </div>
  );
}
