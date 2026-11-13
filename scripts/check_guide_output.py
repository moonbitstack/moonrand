#!/usr/bin/env python3
"""Run the guide's blocks and compare what they print with the page.

A walk-through that claims "this is what it printed" has to be able to prove
it. The blocks of `docs/guide.html` are lifted in the order the page reads them
and run as one program; each block's output is compared with the panel under it
on the page. A block whose result depends on entropy says so by printing
something that does not — `true`, in the one such block — so the comparison
stays exact.

    python scripts/check_guide_output.py
"""

from __future__ import annotations

import html as htmllib
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GUIDE = ROOT / "docs" / "guide.html"
sys.path.insert(0, str(ROOT / "scripts"))
import check_snippets as cs  # noqa: E402  (the alias map is the same for both)

FIGURE = re.compile(
    r'<figure class="run">(.*?)</figure>', re.S
)
CODE = re.compile(r'<pre class="gcode"><code>(.*?)</code></pre>', re.S)
OUT = re.compile(r'<pre>(.*?)</pre>', re.S)


def figures() -> list[tuple[list[str], str]]:
    text = GUIDE.read_text(encoding="utf-8")
    found: list[tuple[list[str], str]] = []
    for fig in FIGURE.finditer(text):
        body = fig.group(1)
        blocks = [
            htmllib.unescape(re.sub(r"<[^>]+>", "", m.group(1))).strip("\n")
            for m in CODE.finditer(body)
        ]
        m = OUT.search(body)
        want = htmllib.unescape(re.sub(r"<[^>]+>", "", m.group(1))).strip("\n") if m else ""
        found.append((blocks, want))
    return found


def main() -> int:
    module, src, deps = cs.module_info()
    aliases = cs.packages(module, src, deps)
    pairs = figures()
    if not pairs:
        print("no blocks found in docs/guide.html", file=sys.stderr)
        return 1

    # A block that declares something belongs at the top level; the ones that
    # draw belong inside main, in the order the page reads them.
    decls: list[str] = []
    body_lines: list[str] = []
    for i, (blocks, _want) in enumerate(pairs):
        statements = [b for b in blocks if not cs.TOP.search(b)]
        decls.extend(b for b in blocks if cs.TOP.search(b))
        if statements:
            body_lines.append(f'  println("@@{i}")')
            for b in statements:
                body_lines.extend("  " + line if line.strip() else line for line in b.splitlines())
    body = "\n".join(body_lines)

    source = "\n\n".join(decls) + ("\n\n" if decls else "") + f"fn main {{\n{body}\n}}\n"
    used = set(re.findall(r"@([a-z_][a-z0-9_]*)\.", source))
    imports = sorted({aliases[a] for a in used if a in aliases})
    pkg = src / "snippet_check"
    shutil.rmtree(pkg, ignore_errors=True)
    pkg.mkdir(parents=True)
    head = "import {\n" + "".join(f'  "{p}",\n' for p in imports) + "}\n\noptions(\"is-main\": true)\n"
    (pkg / "moon.pkg").write_text(head, encoding="utf-8", newline="\n")
    (pkg / "main.mbt").write_text(source, encoding="utf-8", newline="\n")
    try:
        run = subprocess.run(
            ["moon", "run", "--target", "native", str(pkg.relative_to(ROOT))],
            cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace",
        )
    finally:
        shutil.rmtree(pkg, ignore_errors=True)

    if run.returncode != 0:
        print("the guide's blocks do not run:", file=sys.stderr)
        print((run.stdout + run.stderr).strip()[-2000:], file=sys.stderr)
        return 1

    chunks = re.split(r"^@@(\d+)$", run.stdout, flags=re.M)
    got: dict[int, str] = {}
    for j in range(1, len(chunks), 2):
        got[int(chunks[j])] = chunks[j + 1].strip("\n")

    bad = 0
    for i, (blocks, want) in enumerate(pairs):
        if not any(not cs.TOP.search(b) for b in blocks):
            continue
        have = got.get(i, "").strip("\n")
        if have.strip("\n") != want.strip("\n"):
            bad += 1
            print(f"block {i + 1}: the page says", file=sys.stderr)
            for line in want.splitlines():
                print("    " + line, file=sys.stderr)
            print("  the run says", file=sys.stderr)
            for line in have.splitlines():
                print("    " + line, file=sys.stderr)
    if bad:
        return 1
    print(f"docs/guide.html: {len(pairs)} blocks print what the page says")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
