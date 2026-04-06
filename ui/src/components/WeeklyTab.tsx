"use client";

import React, { useState, useCallback, useRef, useEffect } from "react";
import { usePMData } from "../context/PMContext";

type SaveState = "idle" | "saving" | "saved" | "error";

export function WeeklyTab() {
  const { data, loadFiles } = usePMData();
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [editing, setEditing] = useState(false);
  const [editContent, setEditContent] = useState("");
  const [saveState, setSaveState] = useState<SaveState>("idle");
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  // Focus textarea when entering edit mode
  useEffect(() => {
    if (editing && textareaRef.current) {
      textareaRef.current.focus();
    }
  }, [editing]);

  const handleEdit = useCallback(() => {
    if (!data) return;
    const selected = data.weeklySummaries[selectedIndex];
    setEditContent(selected.content);
    setEditing(true);
    setSaveState("idle");
  }, [data, selectedIndex]);

  const handleCancel = useCallback(() => {
    setEditing(false);
    setEditContent("");
    setSaveState("idle");
  }, []);

  const handleSave = useCallback(async () => {
    if (!data) return;
    const selected = data.weeklySummaries[selectedIndex];
    const filePath = `03-reporting/weekly/${selected.filename}`;

    setSaveState("saving");
    try {
      const res = await fetch("/api/save-local", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ filePath, content: editContent }),
      });

      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.error || "Save failed");
      }

      // Reload data from disk to reflect the change
      const reloadRes = await fetch("/api/load-local");
      if (reloadRes.ok) {
        const { files, folderName } = await reloadRes.json();
        loadFiles(files, folderName);
      }

      setSaveState("saved");
      setEditing(false);
      setTimeout(() => setSaveState("idle"), 2000);
    } catch (err) {
      console.error("Save failed:", err);
      setSaveState("error");
      setTimeout(() => setSaveState("idle"), 3000);
    }
  }, [data, selectedIndex, editContent, loadFiles]);

  const handleSelectFile = useCallback(
    (i: number) => {
      if (editing) {
        const discard = window.confirm(
          "You have unsaved changes. Discard them?"
        );
        if (!discard) return;
      }
      setSelectedIndex(i);
      setEditing(false);
      setEditContent("");
      setSaveState("idle");
    },
    [editing]
  );

  if (!data) return null;

  const summaries = data.weeklySummaries;

  if (summaries.length === 0) {
    return (
      <div className="p-6 max-w-5xl mx-auto">
        <h2 className="text-xl font-bold text-th-text mb-4">
          Weekly Reporting
        </h2>
        <div className="rounded-xl border border-th-border bg-th-surface p-8 text-center">
          <div className="text-4xl mb-3">📅</div>
          <p className="text-th-text-muted">
            No weekly summary files found in{" "}
            <code className="text-xs bg-th-surface-alt px-1 py-0.5 rounded">
              03-reporting/weekly/
            </code>
          </p>
          <p className="text-sm text-th-text-faint mt-2">
            Weekly summaries should be named like{" "}
            <code className="text-xs bg-th-surface-alt px-1 py-0.5 rounded">
              YYYY-WNN.md
            </code>
          </p>
        </div>
      </div>
    );
  }

  const selected = summaries[selectedIndex];

  return (
    <div className="flex flex-1 h-full">
      {/* File list */}
      <div className="w-64 border-r border-th-border overflow-auto bg-th-surface">
        <div className="p-4">
          <h3 className="text-sm font-bold text-th-text-muted uppercase tracking-wider mb-3">
            Weekly Summaries ({summaries.length})
          </h3>
          <div className="space-y-1">
            {summaries.map((s, i) => (
              <button
                key={s.filename}
                onClick={() => handleSelectFile(i)}
                className={`w-full text-left px-3 py-2 text-sm rounded-lg cursor-pointer transition-colors ${
                  selectedIndex === i
                    ? "bg-th-accent-light text-th-accent-text font-medium"
                    : "text-th-text-secondary hover:bg-th-surface-alt"
                }`}
              >
                📄 {s.filename}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-auto p-6">
        {/* Header with title and action buttons */}
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-bold text-th-text">
            {selected.filename}
          </h2>
          <div className="flex items-center gap-2">
            {/* Save state indicator */}
            {saveState === "saved" && (
              <span className="text-sm text-th-success flex items-center gap-1">
                ✓ Saved
              </span>
            )}
            {saveState === "error" && (
              <span className="text-sm text-th-danger flex items-center gap-1">
                ✗ Save failed
              </span>
            )}

            {editing ? (
              <>
                <button
                  onClick={handleCancel}
                  className="px-3 py-1.5 text-sm text-th-text-secondary bg-th-surface-alt hover:bg-th-border rounded-lg transition-colors cursor-pointer"
                >
                  Cancel
                </button>
                <button
                  onClick={handleSave}
                  disabled={saveState === "saving"}
                  className="px-3 py-1.5 text-sm text-white bg-th-accent hover:bg-th-accent-hover disabled:bg-th-accent/50 rounded-lg transition-colors cursor-pointer flex items-center gap-1.5"
                >
                  {saveState === "saving" ? (
                    <>
                      <span className="inline-block w-3 h-3 border-2 border-white border-t-transparent rounded-full animate-spin" />
                      Saving…
                    </>
                  ) : (
                    "Save"
                  )}
                </button>
              </>
            ) : (
              <button
                onClick={handleEdit}
                className="px-3 py-1.5 text-sm text-th-text-secondary bg-th-surface-alt hover:bg-th-border rounded-lg transition-colors cursor-pointer flex items-center gap-1.5"
              >
                ✏️ Edit
              </button>
            )}
          </div>
        </div>

        {/* Editor or viewer */}
        {editing ? (
          <textarea
            ref={textareaRef}
            value={editContent}
            onChange={(e) => setEditContent(e.target.value)}
            className="w-full h-[calc(100vh-200px)] text-sm text-th-text-secondary bg-th-surface rounded-xl p-4 border border-th-accent font-mono leading-relaxed resize-none focus:outline-none focus:ring-2 focus:ring-th-accent focus:border-th-accent"
            spellCheck={false}
          />
        ) : (
          <div className="prose prose-sm max-w-none">
            <pre className="whitespace-pre-wrap text-sm text-th-text-secondary bg-th-surface-alt rounded-xl p-4 border border-th-border font-sans leading-relaxed">
              {selected.content}
            </pre>
          </div>
        )}
      </div>
    </div>
  );
}
