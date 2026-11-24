#!/usr/bin/env python3
"""Route a Provenencia PR's reviewers from its diff (ship-pr §3, quick-pr).

This file holds the routing table: which `pr-reviewer` lenses a diff calls
for, by the paths it touches and by what its added lines do. The ship-pr and
quick-pr skills name this script instead of keeping their own copy of the
paths, so there is one list to keep right.

    python3 scripts/route-reviewers.py [--base REF] [--head REF]

--base   default: merge-base of HEAD with origin/main
--head   default: HEAD

Prints RUN or SKIP for each reviewer with the files that matched, then a
line ready to paste into the ship log. Exit 0 always: routing informs, it
does not gate. The orchestrator still reads the diff: code that loads a
stored number, weight or list from the catalog and trusts its size or range
gets the security and performance reviewer wherever it lives, and no path
list can see that.

When a PR adds a package that loops over, keys, joins or derives from data
the app did not write, the same PR adds it to SECURITY_PATHS below.
"""
from __future__ import annotations

import argparse
import fnmatch
import re
import subprocess
import sys

# Paths are prefixes ("core/ingest/") or globs ("*.entitlements").
UX_PATHS = [
    "macos/App/",
    "*Localizable.xcstrings",
    "core/apperr/",
]

SECURITY_PATHS = [
    # Ingest, object store, derivatives, raster
    "core/ingest/", "core/objectpath/", "core/objectstore/",
    "core/derivatives/", "core/raster/",
    # Identity, project open, FFI
    "core/identity/", "core/catalogsession/", "api/ffi/",
    # SQL: every query lives under core/database, and migrations change the
    # schema another project's catalog is checked against
    "core/database/",
    # Swift reads of project files
    "macos/App/Platform/ProjectFiles.swift",
    "macos/App/Platform/ThumbnailCache.swift",
    "*.entitlements",
    # URL and locator code
    "core/urlshape/", "core/locator/", "core/valuecodec/",
    # Matching layers: stored numbers, weights and lists the code trusts
    "core/matchregistry/", "core/valuecompare/", "core/propertycompare/",
    "core/subjectcompare/", "core/subjectprofile/", "core/segmentcompare/",
    "core/kinship/", "core/recordlinks/", "core/shortlist/",
    "core/graphalign/", "core/autoreconcile/",
]

PERFORMANCE_PATHS = [
    "core/database/", "core/search/", "core/derivatives/", "core/raster/",
    # Graph, list and cache code, by name
    "*graph*", "*Graph*", "*cache*", "*Cache*", "*List*.swift",
    # Feature models
    "macos/App/Features/*Model.swift", "macos/App/Features/*Models.swift",
]

# Added lines that call for a lens wherever the file lives.
SQL_RE = re.compile(r"\b(SELECT\s|INSERT\s+INTO|UPDATE\s+\w+\s+SET|DELETE\s+FROM|CREATE\s+(TABLE|INDEX))")
URL_RE = re.compile(r"\b(URL\(string:|NSWorkspace\.shared\.open|url\.Parse\()")
CONTENT_TRIGGERS = [
    # (lens, file glob, regex, why)
    ("security", "*.go", SQL_RE, "builds SQL"),
    ("security", "*.swift", URL_RE, "opens or parses a URL"),
    ("security", "*.go", URL_RE, "parses a URL"),
]

REVIEWERS = [
    # (name, ship-log id, always)
    ("Conformance and regression", "CON", True),
    ("Maintainability", "MNT", True),
    ("User experience", "UX", False),
    ("Security and performance", "SEC+PRF", False),
]


def git(*args: str) -> str:
    return subprocess.run(["git", *args], check=True, capture_output=True, text=True).stdout


def matches(path: str, pattern: str) -> bool:
    if pattern.endswith("/"):
        return path.startswith(pattern)
    if any(c in pattern for c in "*?["):
        return fnmatch.fnmatch(path, pattern) or fnmatch.fnmatch(path.rsplit("/", 1)[-1], pattern)
    return path == pattern


def path_hits(files: list[str], patterns: list[str], code_only: bool = False) -> list[str]:
    return [f for f in files
            if not (code_only and f.endswith(".md")) and any(matches(f, p) for p in patterns)]


def added_lines(base: str, head: str) -> list[tuple[str, int, str]]:
    out: list[tuple[str, int, str]] = []
    path, line = "", 0
    for raw in git("diff", "-U0", "--no-color", f"{base}...{head}").splitlines():
        if raw.startswith("+++ "):
            path = raw[6:] if raw.startswith("+++ b/") else ""
        elif raw.startswith("@@"):
            m = re.search(r"\+(\d+)", raw)
            line = int(m.group(1)) if m else 0
        elif raw.startswith("+") and path:
            out.append((path, line, raw[1:]))
            line += 1
    return out


def content_hits(lines: list[tuple[str, int, str]], lens: str) -> list[str]:
    hits: dict[str, str] = {}
    for path, num, text in lines:
        if path.endswith("_test.go") or "Tests/" in path:
            continue
        for t_lens, glob, regex, why in CONTENT_TRIGGERS:
            if t_lens == lens and fnmatch.fnmatch(path, glob) and regex.search(text):
                hits.setdefault(path, f"{path}:{num} ({why})")
    return list(hits.values())


def summarize(items: list[str], limit: int = 6) -> str:
    shown = ", ".join(f"`{i}`" for i in items[:limit])
    return shown + (f" and {len(items) - limit} more" if len(items) > limit else "")


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--base")
    ap.add_argument("--head", default="HEAD")
    args = ap.parse_args(argv)
    base = args.base
    if not base:
        try:
            base = git("merge-base", args.head, "origin/main").strip()
        except subprocess.CalledProcessError:
            base = git("merge-base", args.head, "main").strip()

    files = [f for f in git("diff", "--name-only", f"{base}...{args.head}").splitlines() if f]
    lines = added_lines(base, args.head)

    ux = path_hits(files, UX_PATHS)
    sec = path_hits(files, SECURITY_PATHS, code_only=True)
    sec += [h for h in content_hits(lines, "security") if h.split(":")[0] not in sec]
    prf = path_hits(files, PERFORMANCE_PATHS, code_only=True)

    print(f"route-reviewers: {git('rev-parse', '--short', base).strip()}...{args.head}, {len(files)} file(s)")
    run_ids: list[str] = []
    skipped: list[str] = []
    for name, rid, always in REVIEWERS:
        if always:
            print(f"RUN   {rid:<8} {name}: every PR")
            run_ids.append(rid)
        elif rid == "UX":
            if ux:
                print(f"RUN   {rid:<8} {name}: {summarize(ux)}")
                run_ids.append(rid)
            else:
                print(f"SKIP  {rid:<8} {name}: no `macos/App/**`, strings, or `core/apperr`")
                skipped.append(f"UX (no `macos/App/**`, strings, or error codes)")
        else:
            if sec or prf:
                why = []
                if sec:
                    why.append(f"security: {summarize(sec)}")
                if prf:
                    why.append(f"performance: {summarize(prf)}")
                print(f"RUN   {rid:<8} {name}: {'; '.join(why)}")
                run_ids.append(rid)
            else:
                print(f"SKIP  {rid:<8} {name}: no security or performance path, no added SQL or URL code")
                skipped.append("SEC+PRF (no security or performance path, no added SQL or URL code)")

    log = f"Reviewers: {', '.join(run_ids)}."
    if skipped:
        log += f" Skipped: {'; '.join(skipped)}."
    print()
    print(f"Ship log: {log}")
    print("Also read the diff: code that trusts the size or range of a stored number, "
          "weight or list gets SEC+PRF wherever it lives. When unsure, dispatch.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
