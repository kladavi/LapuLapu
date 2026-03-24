// ── File System Access API loader + drag-drop fallback ──

const EXCLUDED_DIRS = new Set([
  "01-inbox/archive",
  "90-assets",
  "99-archive",
  ".git",
  "node_modules",
  "ui",
]);

const BINARY_EXTENSIONS = new Set([
  ".pdf",
  ".pptx",
  ".ppt",
  ".xlsx",
  ".xls",
  ".docx",
  ".doc",
  ".zip",
  ".gz",
  ".tar",
  ".png",
  ".jpg",
  ".jpeg",
  ".gif",
  ".svg",
  ".ico",
  ".bmp",
  ".webp",
  ".mp4",
  ".mp3",
  ".wav",
]);

function isExcludedPath(relativePath: string): boolean {
  const normalised = relativePath.replace(/\\/g, "/");
  for (const dir of EXCLUDED_DIRS) {
    if (normalised.startsWith(dir + "/") || normalised === dir) return true;
  }
  return false;
}

function isBinaryFile(filename: string): boolean {
  const lower = filename.toLowerCase();
  for (const ext of BINARY_EXTENSIONS) {
    if (lower.endsWith(ext)) return true;
  }
  return false;
}

// ────────────────────────────────────────────
// File System Access API (folder picker)
// ────────────────────────────────────────────

export async function loadFromFolderPicker(): Promise<{
  files: Record<string, string>;
  folderName: string;
}> {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const dirHandle = await (window as any).showDirectoryPicker({
    mode: "read",
  });

  const files: Record<string, string> = {};
  await readDirectoryRecursive(dirHandle, "", files);

  return { files, folderName: dirHandle.name };
}

async function readDirectoryRecursive(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  dirHandle: any,
  basePath: string,
  files: Record<string, string>
): Promise<void> {
  for await (const entry of dirHandle.values()) {
    const relativePath = basePath ? `${basePath}/${entry.name}` : entry.name;

    if (entry.kind === "directory") {
      if (isExcludedPath(relativePath)) continue;
      await readDirectoryRecursive(entry, relativePath, files);
    } else if (entry.kind === "file") {
      if (isExcludedPath(relativePath)) continue;
      if (isBinaryFile(entry.name)) continue;
      if (!entry.name.endsWith(".md")) continue;

      try {
        const file = await entry.getFile();
        const text = await file.text();
        files[relativePath] = text;
      } catch {
        // Skip unreadable files
      }
    }
  }
}

// ────────────────────────────────────────────
// Drag & drop fallback
// ────────────────────────────────────────────

export async function loadFromDroppedItems(
  items: DataTransferItemList
): Promise<{ files: Record<string, string>; folderName: string }> {
  const files: Record<string, string> = {};
  let folderName = "dropped-files";

  const entries: FileSystemEntry[] = [];
  for (let i = 0; i < items.length; i++) {
    const entry = items[i].webkitGetAsEntry?.();
    if (entry) {
      entries.push(entry);
      if (entry.isDirectory && i === 0) {
        folderName = entry.name;
      }
    }
  }

  for (const entry of entries) {
    await processEntry(entry, "", files);
  }

  return { files, folderName };
}

async function processEntry(
  entry: FileSystemEntry,
  basePath: string,
  files: Record<string, string>
): Promise<void> {
  const relativePath = basePath ? `${basePath}/${entry.name}` : entry.name;

  if (entry.isDirectory) {
    if (isExcludedPath(relativePath)) return;
    const dirReader = (entry as FileSystemDirectoryEntry).createReader();
    const entries = await new Promise<FileSystemEntry[]>((resolve, reject) => {
      dirReader.readEntries(resolve, reject);
    });
    for (const child of entries) {
      await processEntry(child, relativePath, files);
    }
  } else if (entry.isFile) {
    if (isExcludedPath(relativePath)) return;
    if (isBinaryFile(entry.name)) return;
    if (!entry.name.endsWith(".md")) return;

    const file = await new Promise<File>((resolve, reject) => {
      (entry as FileSystemFileEntry).file(resolve, reject);
    });
    const text = await file.text();
    files[relativePath] = text;
  }
}

// ────────────────────────────────────────────
// Feature detection
// ────────────────────────────────────────────

export function supportsFileSystemAccess(): boolean {
  return typeof window !== "undefined" && "showDirectoryPicker" in window;
}
