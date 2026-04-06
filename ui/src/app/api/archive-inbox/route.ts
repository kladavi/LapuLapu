// ── API route: move processed inbox files to archive ──
// Moves files from 01-inbox/ to 01-inbox/archive/.

import { NextResponse } from "next/server";
import fs from "fs/promises";
import path from "path";

const DEFAULT_ROOT = "C:\\Users\\kladavi\\Projects\\LapuLapu";
const INBOX_DIR = path.join(DEFAULT_ROOT, "01-inbox");
const ARCHIVE_DIR = path.join(INBOX_DIR, "archive");

export async function POST(request: Request) {
  try {
    const { filenames } = (await request.json()) as { filenames: string[] };

    if (!Array.isArray(filenames) || filenames.length === 0) {
      return NextResponse.json(
        { error: "Missing or empty filenames array" },
        { status: 400 }
      );
    }

    // Ensure archive directory exists
    await fs.mkdir(ARCHIVE_DIR, { recursive: true });

    const moved: string[] = [];
    const errors: string[] = [];

    for (const filename of filenames) {
      // Security: strip path separators — only bare filenames allowed
      const safe = path.basename(filename);
      if (safe !== filename) {
        errors.push(`${filename}: path traversal rejected`);
        continue;
      }

      const src = path.join(INBOX_DIR, safe);
      const dst = path.join(ARCHIVE_DIR, safe);

      // Verify source is inside inbox
      if (!src.startsWith(path.resolve(INBOX_DIR))) {
        errors.push(`${filename}: outside inbox directory`);
        continue;
      }

      try {
        await fs.access(src);
        // If destination already exists, add a timestamp suffix
        let finalDst = dst;
        try {
          await fs.access(dst);
          const ext = path.extname(safe);
          const base = path.basename(safe, ext);
          const ts = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
          finalDst = path.join(ARCHIVE_DIR, `${base}_${ts}${ext}`);
        } catch {
          // Destination doesn't exist — good, use original path
        }
        await fs.rename(src, finalDst);
        moved.push(safe);
      } catch (err) {
        errors.push(`${safe}: ${err instanceof Error ? err.message : "move failed"}`);
      }
    }

    return NextResponse.json({ moved, errors });
  } catch (err) {
    console.error("Archive failed:", err);
    return NextResponse.json(
      { error: "Failed to archive files" },
      { status: 500 }
    );
  }
}
