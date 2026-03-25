// ── API route: saves a file back to the local filesystem ──
// Only allows writing to the LapuLapu project directory for safety.

import { NextResponse } from "next/server";
import fs from "fs/promises";
import path from "path";

const DEFAULT_ROOT = "C:\\Users\\kladavi\\Projects\\LapuLapu";

export async function POST(request: Request) {
  try {
    const { filePath, content } = (await request.json()) as {
      filePath: string;
      content: string;
    };

    if (!filePath || typeof content !== "string") {
      return NextResponse.json(
        { error: "Missing filePath or content" },
        { status: 400 }
      );
    }

    // Normalise and resolve the path
    const normalised = filePath.replace(/\\/g, "/");
    const fullPath = path.resolve(DEFAULT_ROOT, normalised);

    // Security: ensure the resolved path is within the project root
    const resolvedRoot = path.resolve(DEFAULT_ROOT);
    if (!fullPath.startsWith(resolvedRoot)) {
      return NextResponse.json(
        { error: "Path escapes project root" },
        { status: 403 }
      );
    }

    // Only allow .md files
    if (!fullPath.endsWith(".md")) {
      return NextResponse.json(
        { error: "Only .md files can be saved" },
        { status: 403 }
      );
    }

    // Ensure the directory exists
    const dir = path.dirname(fullPath);
    await fs.mkdir(dir, { recursive: true });

    // Write the file
    await fs.writeFile(fullPath, content, "utf-8");

    return NextResponse.json({ ok: true, path: normalised });
  } catch (err) {
    console.error("Save failed:", err);
    return NextResponse.json(
      { error: "Failed to save file" },
      { status: 500 }
    );
  }
}
