#!/usr/bin/env python3
"""Extract text from a PDF using pdfplumber. Prints plain text to stdout."""
import sys
import os
import io
import logging

# Suppress pdfminer/pdfplumber font warnings
logging.getLogger("pdfminer").setLevel(logging.ERROR)

# Force UTF-8 stdout on Windows
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

import pdfplumber

def extract(path: str) -> str:
    pages = []
    with pdfplumber.open(path) as pdf:
        for page in pdf.pages:
            # Try table extraction first; fall back to full-page text
            tables = page.extract_tables()
            if tables:
                for table in tables:
                    for row in table:
                        cells = [c.strip() if c else "" for c in row]
                        pages.append(" | ".join(cells))
                    pages.append("")  # blank line between tables
            text = page.extract_text()
            if text:
                pages.append(text)
    return "\n".join(pages)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: extract-pdf.py <path>", file=sys.stderr)
        sys.exit(1)
    try:
        print(extract(sys.argv[1]))
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
