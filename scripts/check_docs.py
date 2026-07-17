#!/usr/bin/env python3
"""Check local Markdown links and required Chinese/English document pairs."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parent.parent
MARKDOWN = [
    *ROOT.glob("*.md"),
    *ROOT.glob("docs/*.md"),
    *ROOT.glob("examples/**/*.md"),
]
PAIR_ROOTS = ["README.md", "AGENTS.md", "CONTRIBUTING.md", "SECURITY.md", "CODE_OF_CONDUCT.md"]
errors: list[str] = []

for relative in PAIR_ROOTS:
    chinese = ROOT / relative
    english = chinese.with_name(f"{chinese.stem}.en.md")
    if chinese.exists() and not english.exists():
        errors.append(f"missing English pair: {english.relative_to(ROOT)}")

for chinese in [*ROOT.glob("docs/*.md"), *ROOT.glob("examples/*/README.md")]:
    if chinese.name.endswith(".en.md"):
        continue
    english = chinese.with_name(f"{chinese.stem}.en.md")
    if not english.exists():
        errors.append(f"missing English pair: {english.relative_to(ROOT)}")

for document in MARKDOWN:
    text = document.read_text(encoding="utf-8")
    for target in re.findall(r"\[[^]]*\]\(([^)]+)\)", text):
        if target.startswith(("http://", "https://", "mailto:", "#")):
            continue
        path = target.split("#", 1)[0]
        if path and not (document.parent / path).resolve().exists():
            errors.append(f"{document.relative_to(ROOT)}: broken link {target}")

if errors:
    print("\n".join(errors), file=sys.stderr)
    raise SystemExit(1)
