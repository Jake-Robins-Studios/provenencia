#!/usr/bin/env python3
"""Fail when a line this branch adds has the shape of a known review trap.

The review-pr lenses' **Known traps** and the layer skills name mistakes that
reached `main` past review. The ones with a code shape a grep can see are
checked here, for nothing, so a reviewer spends its reading on judgment
calls. Only lines the branch adds are checked (committed or not), so code
already on `main` does not fail the gate; files under a test folder or named
`*_test.go` are skipped unless a rule says otherwise.

    python3 scripts/check-patterns.py [--base REF]

--base   default: merge-base of HEAD with origin/main

A line that is right on purpose carries `check-patterns: allow <rule> — <why>`
in a comment on the same line or the line above. Each rule below names the
skill or lens it comes from. Add a rule when a Known trap gets a shape a regex
can see without false positives on `main`; keep the trap's line in its lens
and say there that this script checks it.
"""
from __future__ import annotations

import argparse
import fnmatch
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

SQL_KEYWORD = r"(SELECT|INSERT|UPDATE|DELETE|WHERE|VALUES|SET)\b"


@dataclass
class Rule:
    id: str
    files: tuple[str, ...]          # globs the rule applies to
    pattern: re.Pattern[str] | None  # matched against an added line; None: an added file is the finding
    message: str
    source: str
    exclude: tuple[str, ...] = ()
    tests_too: bool = False
    before_preview: bool = False    # Swift: only lines above the file's first #Preview
    outside_debug: bool = False     # Swift: only lines outside an `#if DEBUG` region


RULES = [
    Rule(
        "sql-value-format",
        ("core/*.go", "api/*.go"),
        re.compile(r"Sprintf\(.*" + SQL_KEYWORD + r".*('%[sv]'|%[vdq])"),
        "a value formatted into SQL; bind it as a `?` parameter",
        "review-pr security lens, SQL",
    ),
    Rule(
        "sql-value-concat",
        ("core/*.go", "api/*.go"),
        re.compile(r"""'"\s*\+\s*\w|\w\s*\+\s*"'"""),
        "a quoted value concatenated into a string (SQL); bind it as a `?` parameter",
        "review-pr security lens, SQL",
    ),
    Rule(
        "sql-in-marks",
        ("core/*.go", "api/*.go"),
        re.compile(r'strings\.Repeat\(\s*"\?'),
        "hand-built IN-list markers; IN lists go through `sqlbatch` (markers: `dbsql.SQLInPlaceholders`)",
        "review-pr security and performance lenses",
        exclude=("core/database/dbsql/*", "core/database/sqlbatch/*"),
    ),
    Rule(
        "private-sql-in-use",
        ("core/*.go",),
        re.compile(r"\bfunc\s+sqlInUse\b"),
        "a private `sqlInUse`; a delete goes through `deleteimpact`",
        "add-catalog-delete; maintainability Known traps",
    ),
    Rule(
        "test-walks-up",
        ("core/*_test.go", "api/*_test.go"),
        re.compile(r'(filepath\.WalkDir|filepath\.Walk|os\.ReadDir)\(\s*"\.\.'),
        "a guard test walks the repo by hand; use `core/internal/gosrc.Files`",
        "maintainability Known traps (S16-49)",
        tests_too=True,
    ),
    Rule(
        "swift-full-decode",
        ("macos/App/*.swift",),
        re.compile(r"NSImage\(contentsOf:"),
        "an unbounded image decode in Swift; go through Go's `raster` bounds or `CachedThumbnail`",
        "review-pr security Known traps",
    ),
    Rule(
        "swift-text-literal",
        ("macos/App/*.swift",),
        re.compile(r'\bText\("'),
        "a bare `Text(\"…\")`; copy goes through `L10n`, non-copy through `Text(verbatim:)`",
        "add-localized-string",
        before_preview=True,
    ),
    Rule(
        "swift-empty-label",
        ("macos/App/*.swift",),
        re.compile(r'\b(TextField|Picker)\(\s*""'),
        "an empty-string label extracts catalog key \"\"; use the label-closure form with `EmptyView()`",
        "add-localized-string",
        before_preview=True,
    ),
    Rule(
        "swift-optional-text",
        ("macos/App/*.swift",),
        re.compile(r'\bText\((verbatim:\s*)?[\w.]+\s*\?\?\s*""\s*\)'),
        "`Text(x ?? \"\")` extracts catalog key \"\"; use `if let s = x { Text(verbatim: s) }`",
        "add-localized-string",
    ),
    Rule(
        "swift-string-localized",
        ("macos/App/*.swift",),
        re.compile(r"\bString\(localized:"),
        "`String(localized:)`; copy needed as a `String` uses `L10n.string(…)`",
        "add-localized-string",
        exclude=("macos/App/Platform/L10n.swift",),
    ),
    Rule(
        "swift-debug-only-in-release",
        ("macos/App/*.swift",),
        None,  # built in main() from the names `macos/App` declares only under `#if DEBUG`
        "a Debug-only type (FakeStore, a preview fixture) outside `#if DEBUG` breaks the Release build; "
        "wrap the `#Preview` or the fixture file in `#if DEBUG`",
        "macos-client-patterns Previews and tests (#1003)",
        outside_debug=True,
    ),
    Rule(
        "kit-legacy-folder",
        ("macos/App/DesignSystem/Components/Core/*", "macos/App/DesignSystem/Components/Forms/*",
         "macos/App/DesignSystem/Components/Research/*"),
        None,
        "a new file in a legacy kit folder; a component gets its own `Components/<Name>/` folder",
        "maintainability Q4; add-ui-component",
        tests_too=True,
    ),
]

ALLOW_RE = re.compile(r"check-patterns:\s*allow\s+([\w-]+)")
COMMENT_RE = re.compile(r"^\s*(//|#|\*|/\*)")


def git(*args: str) -> str:
    return subprocess.run(["git", *args], cwd=ROOT, check=True, capture_output=True, text=True).stdout


def is_test(path: str) -> bool:
    return path.endswith("_test.go") or "/ProvenenciaTests/" in f"/{path}" or "/testdata/" in path


def applies(rule: Rule, path: str) -> bool:
    if not any(fnmatch.fnmatch(path, g) for g in rule.files):
        return False
    if any(fnmatch.fnmatch(path, g) for g in rule.exclude):
        return False
    return rule.tests_too or not is_test(path)


def added(base: str) -> tuple[dict[str, list[tuple[int, str]]], list[str]]:
    """Lines added since base (working tree included), and files added."""
    lines: dict[str, list[tuple[int, str]]] = {}
    path, num = "", 0
    for raw in git("diff", "-U0", "--no-color", base).splitlines():
        if raw.startswith("+++ "):
            path = raw[6:] if raw.startswith("+++ b/") else ""
        elif raw.startswith("@@"):
            m = re.search(r"\+(\d+)", raw)
            num = int(m.group(1)) if m else 0
        elif raw.startswith("+") and path:
            lines.setdefault(path, []).append((num, raw[1:]))
            num += 1
    new_files = git("diff", "--name-only", "--diff-filter=A", base).splitlines()
    untracked = git("ls-files", "--others", "--exclude-standard").splitlines()
    for f in untracked:
        p = ROOT / f
        if p.is_file():
            try:
                text = p.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue
            lines[f] = list(enumerate(text.splitlines(), start=1))
    return lines, new_files + untracked


def file_lines(path: str) -> list[str]:
    try:
        return (ROOT / path).read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeDecodeError):
        return []


def debug_regions(lines: list[str]) -> list[bool]:
    """Whether each line sits inside an `#if DEBUG` region (its `#else` is not)."""
    out: list[bool] = []
    stack: list[list] = []  # [in DEBUG, condition]
    for line in lines:
        s = line.strip()
        if s.startswith("#if "):
            cond = s[4:].strip()
            stack.append([cond == "DEBUG", cond])
        elif s.startswith("#elseif"):
            if stack:
                stack[-1][0] = False
        elif s.startswith("#else"):
            if stack:
                stack[-1][0] = stack[-1][1] == "!DEBUG"
        elif s.startswith("#endif"):
            if stack:
                stack.pop()
        out.append(any(frame[0] for frame in stack))
    return out


SWIFT_DECL_RE = re.compile(
    r"^(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:public|internal|private|fileprivate|final|nonisolated)\s+)*"
    r"(?:enum|struct|class|actor|protocol|typealias)\s+([A-Z]\w*)"
)


def debug_only_names() -> re.Pattern[str] | None:
    """Top-level types `macos/App` declares only inside `#if DEBUG`, as one word pattern."""
    debug, release = set(), set()
    for path in (ROOT / "macos/App").rglob("*.swift"):
        lines = path.read_text(encoding="utf-8").splitlines()
        for line, in_debug in zip(lines, debug_regions(lines)):
            m = SWIFT_DECL_RE.match(line)
            if m:
                (debug if in_debug else release).add(m.group(1))
    names = sorted(debug - release)
    return re.compile(r"\b(" + "|".join(names) + r")\b") if names else None


def allowed(rule: Rule, text: str, prev: str) -> bool:
    for line in (text, prev):
        m = ALLOW_RE.search(line)
        if m and m.group(1) == rule.id:
            return True
    return False


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--base")
    args = ap.parse_args(argv)
    base = args.base
    if not base:
        try:
            base = git("merge-base", "HEAD", "origin/main").strip()
        except subprocess.CalledProcessError:
            base = git("merge-base", "HEAD", "main").strip()

    lines, new_files = added(base)
    findings: list[str] = []

    for path in new_files:
        for rule in RULES:
            # A rule that checks lines (`outside_debug`) gets its pattern below; a new file is not a finding.
            if rule.pattern is None and not rule.outside_debug and applies(rule, path):
                findings.append(f"{path}: {rule.id}: {rule.message} ({rule.source})")

    for rule in RULES:
        if rule.outside_debug:
            rule.pattern = debug_only_names()

    for path, hunk in sorted(lines.items()):
        rules = [r for r in RULES if r.pattern is not None and applies(r, path)]
        if not rules:
            continue
        whole = file_lines(path)
        preview_at = next((i + 1 for i, l in enumerate(whole) if l.lstrip().startswith("#Preview")), None)
        in_debug = debug_regions(whole) if any(r.outside_debug for r in rules) else []
        for num, text in hunk:
            if COMMENT_RE.match(text):
                continue
            prev = whole[num - 2] if 1 < num <= len(whole) + 1 else ""
            for rule in rules:
                if rule.before_preview and preview_at is not None and num > preview_at:
                    continue
                if rule.outside_debug and 0 < num <= len(in_debug) and in_debug[num - 1]:
                    continue
                if rule.pattern.search(text) and not allowed(rule, text, prev):
                    findings.append(f"{path}:{num}: {rule.id}: {rule.message} ({rule.source})")

    for f in findings:
        print(f)
    print(f"check-patterns: {len(findings)} finding(s) against {git('rev-parse', '--short', base).strip()}")
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
