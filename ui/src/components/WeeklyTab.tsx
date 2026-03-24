"use client";

import React, { useState } from "react";
import { usePMData } from "../context/PMContext";

export function WeeklyTab() {
  const { data } = usePMData();
  const [selectedIndex, setSelectedIndex] = useState(0);

  if (!data) return null;

  const summaries = data.weeklySummaries;

  if (summaries.length === 0) {
    return (
      <div className="p-6 max-w-5xl mx-auto">
        <h2 className="text-xl font-bold text-gray-800 mb-4">
          Weekly Reporting
        </h2>
        <div className="rounded-xl border border-gray-200 bg-white p-8 text-center">
          <div className="text-4xl mb-3">📅</div>
          <p className="text-gray-500">
            No weekly summary files found in{" "}
            <code className="text-xs bg-gray-100 px-1 py-0.5 rounded">
              03-reporting/weekly/
            </code>
          </p>
          <p className="text-sm text-gray-400 mt-2">
            Weekly summaries should be named like{" "}
            <code className="text-xs bg-gray-100 px-1 py-0.5 rounded">
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
      <div className="w-64 border-r border-gray-200 overflow-auto bg-white">
        <div className="p-4">
          <h3 className="text-sm font-bold text-gray-500 uppercase tracking-wider mb-3">
            Weekly Summaries ({summaries.length})
          </h3>
          <div className="space-y-1">
            {summaries.map((s, i) => (
              <button
                key={s.filename}
                onClick={() => setSelectedIndex(i)}
                className={`w-full text-left px-3 py-2 text-sm rounded-lg cursor-pointer transition-colors ${
                  selectedIndex === i
                    ? "bg-blue-50 text-blue-700 font-medium"
                    : "text-gray-600 hover:bg-gray-50"
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
        <h2 className="text-lg font-bold text-gray-800 mb-4">
          {selected.filename}
        </h2>
        <div className="prose prose-sm max-w-none">
          <pre className="whitespace-pre-wrap text-sm text-gray-700 bg-gray-50 rounded-xl p-4 border border-gray-200 font-sans leading-relaxed">
            {selected.content}
          </pre>
        </div>
      </div>
    </div>
  );
}
