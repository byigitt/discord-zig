#!/usr/bin/env python3
"""Find unused private Zig import/member alias const declarations.

This is intentionally narrower than a full Zig analyzer. It catches the cleanup
case this repository tends to accumulate: file-level `const X = @import(...)`
and `const X = Module.Member` aliases that are never referenced.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path


DECL_RE = re.compile(
    r"^(?P<indent>[ \t]*)const\s+"
    r"(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*=\s*"
    r"(?P<rhs>[^;\n]+);",
    re.MULTILINE,
)
IDENT_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
EXCLUDED_DIRS = {".git", ".zig-cache", "zig-out"}


@dataclass(frozen=True)
class Finding:
    path: Path
    line: int
    name: str
    rhs: str


def is_alias_rhs(rhs: str) -> bool:
    rhs = rhs.strip()
    if rhs.startswith("@import("):
        return True
    return re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)+", rhs) is not None


def sanitized_source(source: str) -> str:
    """Remove comments and string contents while preserving offsets/newlines."""
    out: list[str] = []
    i = 0
    while i < len(source):
        ch = source[i]
        nxt = source[i + 1] if i + 1 < len(source) else ""

        if ch == "/" and nxt == "/":
            out.extend("  ")
            i += 2
            while i < len(source) and source[i] != "\n":
                out.append(" ")
                i += 1
            continue

        if ch == '"':
            out.append(" ")
            i += 1
            while i < len(source):
                if source[i] == "\n":
                    out.append("\n")
                    i += 1
                    break
                if source[i] == "\\" and i + 1 < len(source):
                    out.extend("  ")
                    i += 2
                    continue
                out.append(" ")
                if source[i] == '"':
                    i += 1
                    break
                i += 1
            continue

        if ch == "'":
            out.append(" ")
            i += 1
            while i < len(source):
                if source[i] == "\n":
                    out.append("\n")
                    i += 1
                    break
                if source[i] == "\\" and i + 1 < len(source):
                    out.extend("  ")
                    i += 2
                    continue
                out.append(" ")
                if source[i] == "'":
                    i += 1
                    break
                i += 1
            continue

        out.append(ch)
        i += 1

    return "".join(out)


def line_depths(cleaned: str) -> list[int]:
    depths = []
    depth = 0
    for line in cleaned.splitlines(keepends=True):
        depths.append(depth)
        for ch in line:
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth = max(0, depth - 1)
    return depths


def line_number_from_offset(source: str, offset: int) -> int:
    return source.count("\n", 0, offset) + 1


def token_is_used(cleaned: str, start: int, end: int, name: str) -> bool:
    searchable = cleaned[:start] + (" " * (end - start)) + cleaned[end:]
    token_re = re.compile(rf"(?<![A-Za-z0-9_]){re.escape(name)}(?![A-Za-z0-9_])")
    return token_re.search(searchable) is not None


def findings_for_file(path: Path) -> list[Finding]:
    source = path.read_text(encoding="utf-8")
    cleaned = sanitized_source(source)
    depths = line_depths(cleaned)
    findings: list[Finding] = []

    for match in DECL_RE.finditer(source):
        line = line_number_from_offset(source, match.start())
        if match.group("indent"):
            continue
        if depths[line - 1] != 0:
            continue

        name = match.group("name")
        rhs = match.group("rhs").strip()
        if not is_alias_rhs(rhs):
            continue
        if token_is_used(cleaned, match.start(), match.end(), name):
            continue

        findings.append(Finding(path=path, line=line, name=name, rhs=rhs))

    return findings


def zig_files(paths: list[Path]) -> list[Path]:
    files: list[Path] = []
    for path in paths:
        if path.is_file() and path.suffix == ".zig":
            files.append(path)
            continue
        if not path.is_dir():
            continue
        for candidate in path.rglob("*.zig"):
            if any(part in EXCLUDED_DIRS for part in candidate.parts):
                continue
            files.append(candidate)
    return sorted(set(files))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Report unused private Zig @import/member alias const declarations.",
    )
    parser.add_argument(
        "paths",
        nargs="*",
        type=Path,
        default=[Path(".")],
        help="Files or directories to scan. Defaults to the current tree.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    findings: list[Finding] = []
    for path in zig_files(args.paths):
        findings.extend(findings_for_file(path))

    if not findings:
        print("No unused private Zig import/member aliases found.")
        return 0

    for finding in findings:
        print(f"{finding.path}:{finding.line}: unused const {finding.name} = {finding.rhs};")
    print(f"\n{len(findings)} unused alias(es) found.", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
