#!/usr/bin/env python3
"""Validate CDN manifest SHA256 hashes against files on disk."""
import hashlib
import json
import sys
from pathlib import Path

MANIFEST = Path("/var/www/zorionlabs/dark/downloads/launcher/manifest.json")
DOWNLOADS = Path("/var/www/zorionlabs/dark/downloads")


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    if not MANIFEST.exists():
        print(f"ERROR: manifest not found: {MANIFEST}")
        return 1
    data = json.loads(MANIFEST.read_text())
    files = data.get("files", [])
    ok = True
    for entry in files:
        fname = entry["path"]
        path = DOWNLOADS / fname
        if not path.exists():
            print(f"  MISSING {fname} ({entry.get('role')})")
            ok = False
            continue
        actual = sha256_file(path)
        expected = entry.get("sha256", "")
        if actual.lower() != expected.lower():
            print(f"  HASH MISMATCH {fname}: expected {expected[:16]}... got {actual[:16]}...")
            ok = False
        else:
            print(f"  OK {fname} ({entry.get('role')}) sha256={actual[:16]}...")
    gv = data.get("game_version", "?")
    print(f"\nManifest valid: game_version={gv} files={len(files)}" if ok else f"\nManifest INVALID: {len(files)} files")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
