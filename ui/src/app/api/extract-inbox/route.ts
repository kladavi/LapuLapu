// ── API route: extract text from binary inbox files (PDF, DOCX, EML, MSG) ──
// Reads files from 01-inbox/ and returns extracted plain text.
// PDF extraction uses pdfplumber (Python) for superior table/layout support.

import { NextResponse } from "next/server";
import fs from "fs/promises";
import path from "path";
import { execFile } from "child_process";

const DEFAULT_ROOT = "C:\\Users\\kladavi\\Projects\\LapuLapu";
const INBOX_DIR = path.join(DEFAULT_ROOT, "01-inbox");
const EXTRACT_PDF_SCRIPT = path.join(DEFAULT_ROOT, "ui", "scripts", "extract-pdf.py");

interface ExtractedFile {
  filename: string;
  text: string;
  type: string;
  error?: string;
}

async function extractPdf(filePath: string): Promise<string> {
  return new Promise((resolve, reject) => {
    execFile(
      "python",
      [EXTRACT_PDF_SCRIPT, filePath],
      { maxBuffer: 10 * 1024 * 1024, encoding: "utf8" },
      (err, stdout, stderr) => {
        if (err) {
          reject(new Error(stderr?.trim() || err.message));
        } else {
          resolve(stdout.trim());
        }
      }
    );
  });
}

async function extractDocx(filePath: string): Promise<string> {
  const mammoth = await import("mammoth");
  const result = await mammoth.extractRawText({ path: filePath });
  return result.value;
}

async function extractEml(filePath: string): Promise<string> {
  const { simpleParser } = await import("mailparser");
  const raw = await fs.readFile(filePath);
  const parsed = await simpleParser(raw);

  const parts: string[] = [];
  if (parsed.subject) parts.push(`Subject: ${parsed.subject}`);
  if (parsed.from?.text) parts.push(`From: ${parsed.from.text}`);
  if (parsed.to) {
    const toText = Array.isArray(parsed.to)
      ? parsed.to.map((a) => a.text).join(", ")
      : parsed.to.text;
    parts.push(`To: ${toText}`);
  }
  if (parsed.date) parts.push(`Date: ${parsed.date.toISOString().split("T")[0]}`);
  parts.push("");
  if (parsed.text) {
    parts.push(parsed.text);
  } else if (parsed.html) {
    // Strip HTML tags as fallback
    parts.push(parsed.html.replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim());
  }
  return parts.join("\n");
}

async function extractMsg(filePath: string): Promise<string> {
  // .msg files are Outlook's proprietary format.
  // mailparser can sometimes handle them, but they're compound binary.
  // Try to parse as raw email first; fall back to binary notice.
  try {
    const { simpleParser } = await import("mailparser");
    const raw = await fs.readFile(filePath);
    const parsed = await simpleParser(raw);

    const parts: string[] = [];
    if (parsed.subject) parts.push(`Subject: ${parsed.subject}`);
    if (parsed.from?.text) parts.push(`From: ${parsed.from.text}`);
    if (parsed.text) {
      parts.push("");
      parts.push(parsed.text);
    }
    if (parts.length > 1) return parts.join("\n");
  } catch {
    // Fall through
  }
  return "[.msg file — Outlook proprietary format. Open in Outlook and save as .eml or paste content manually.]";
}

const SUPPORTED_EXTENSIONS: Record<string, (fp: string) => Promise<string>> = {
  ".pdf": extractPdf,
  ".docx": extractDocx,
  ".eml": extractEml,
  ".msg": extractMsg,
};

export async function GET() {
  try {
    await fs.access(INBOX_DIR);
  } catch {
    return NextResponse.json(
      { error: `Inbox directory not found: ${INBOX_DIR}` },
      { status: 404 }
    );
  }

  const entries = await fs.readdir(INBOX_DIR, { withFileTypes: true });
  const results: ExtractedFile[] = [];

  for (const entry of entries) {
    if (!entry.isFile()) continue;

    const ext = path.extname(entry.name).toLowerCase();
    const extractor = SUPPORTED_EXTENSIONS[ext];

    if (!extractor) continue; // skip .md, .json, unsupported types

    const filePath = path.join(INBOX_DIR, entry.name);
    try {
      const text = await extractor(filePath);
      results.push({
        filename: entry.name,
        text,
        type: ext.replace(".", ""),
      });
    } catch (err) {
      results.push({
        filename: entry.name,
        text: "",
        type: ext.replace(".", ""),
        error: err instanceof Error ? err.message : "Extraction failed",
      });
    }
  }

  return NextResponse.json({ files: results });
}
