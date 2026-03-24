// ── API route: reads the LapuLapu directory from the local filesystem ──
// This runs server-side, so it has access to Node.js fs.

import { NextResponse } from "next/server";
import fs from "fs/promises";
import path from "path";

const DEFAULT_ROOT = "C:\\Users\\kladavi\\Projects\\LapuLapu";

const EXCLUDED_DIRS = new Set([
  "01-inbox\\archive",
  "01-inbox/archive",
  "90-assets",
  "99-archive",
  ".git",
  "node_modules",
  "ui",
]);

const BINARY_EXTENSIONS = new Set([
  ".pdf", ".pptx", ".ppt", ".xlsx", ".xls", ".docx", ".doc",
  ".zip", ".gz", ".tar",
  ".png", ".jpg", ".jpeg", ".gif", ".svg", ".ico", ".bmp", ".webp",
  ".mp4", ".mp3", ".wav",
]);

function isExcluded(relativePath: string): boolean {
  const normalised = relativePath.replace(/\\/g, "/");
  for (const dir of EXCLUDED_DIRS) {
    const normDir = dir.replace(/\\/g, "/");
    if (normalised.startsWith(normDir + "/") || normalised === normDir) return true;
  }
  return false;
}

function isBinary(filename: string): boolean {
  const lower = filename.toLowerCase();
  for (const ext of BINARY_EXTENSIONS) {
    if (lower.endsWith(ext)) return true;
  }
  return false;
}

async function readDirRecursive(
  dirPath: string,
  basePath: string,
  files: Record<string, string>
): Promise<void> {
  let entries;
  try {
    entries = await fs.readdir(dirPath, { withFileTypes: true });
  } catch {
    return;
  }

  for (const entry of entries) {
    const relativePath = basePath ? `${basePath}/${entry.name}` : entry.name;

    if (entry.isDirectory()) {
      if (isExcluded(relativePath)) continue;
      await readDirRecursive(path.join(dirPath, entry.name), relativePath, files);
    } else if (entry.isFile()) {
      if (isExcluded(relativePath)) continue;
      if (isBinary(entry.name)) continue;
      if (!entry.name.endsWith(".md")) continue;

      try {
        const content = await fs.readFile(path.join(dirPath, entry.name), "utf-8");
        files[relativePath] = content;
      } catch {
        // skip unreadable
      }
    }
  }
}

export async function GET() {
  const rootDir = DEFAULT_ROOT;

  try {
    await fs.access(rootDir);
  } catch {
    return NextResponse.json(
      { error: `Directory not found: ${rootDir}` },
      { status: 404 }
    );
  }

  const files: Record<string, string> = {};
  await readDirRecursive(rootDir, "", files);

  const folderName = path.basename(rootDir);

  return NextResponse.json({ files, folderName });
}
