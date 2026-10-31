#!/usr/bin/env python3
"""Render the API table in docs/index.html from the generated interfaces.

Every public item in ``src/**/pkg.generated.mbti`` must appear on the page: the
script refuses to write when an item has no row, and refuses to leave a row
behind for an item the library no longer has. Signature text and prose live
below; the item list comes from the compiler's own output.

    python scripts/gen_api.py            rewrite docs/index.html
    python scripts/gen_api.py --check    exit 1 when the page is stale
"""

from __future__ import annotations

import html
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PAGE = ROOT / "docs" / "index.html"
BEGIN = "<!-- api:begin -->"
END = "<!-- api:end -->"

# --------------------------------------------------------------------------
# The rows, in the order the page shows them. `key` names the interface item
# the row documents, spelled as the .mbti file spells it; `covers` names the
# further items a row documents when one signature block names several.
# --------------------------------------------------------------------------
ROWS = [
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "seeded",
        "sig": ["pub fn seeded(seed : BytesView) -> StdRng"],
        "zh": "以三十二字节起笔。字节同，则流同，四后端逐位不差。",
        "en": "Start from thirty-two bytes. The same bytes give the same stream, bit for bit on all four backends.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "from_entropy",
        "sig": ["pub fn from_entropy() -> StdRng raise @moonseed.Unavailable"],
        "zh": "向平台要三十二字节，交与 seeded。无熵则 raise，不暗自改用钟表或常数。",
        "en": "Ask the platform for thirty-two bytes and hand them to seeded. No entropy, no stream; it never falls back to a clock or a constant.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "random",
        "sig": ["random(rng : R) -> Double"],
        "zh": "[0, 1) 之实数，恰五十三位。Python 之 random() 同此一取。",
        "en": "A real in [0, 1) with exactly fifty-three bits, the same draw as Python's random().",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "uniform",
        "sig": ["uniform(rng : R, low : Double, high : Double) -> Double"],
        "zh": "[low, high) 之内，处处同厚。low 高于 high 亦听之，端点自换。",
        "en": "Anywhere in [low, high), equally thick. Reversed ends are taken as given.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "randint",
        "sig": ["randint(rng : R, low : Int64, high : Int64) -> Int64"],
        "zh": "整数，两端皆算。high 小于 low，则还 low。",
        "en": "An integer, both ends included. A high below low returns low.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "randrange",
        "sig": ["randrange(rng : R, stop : Int64, start~ : Int64 = 0, step? : Int64) -> Int64"],
        "zh": "整数，右端不算；可给起点与步长。空范围、零步长，皆 abort。",
        "en": "An integer, right end excluded, with an optional start and step. An empty range or a zero step aborts.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "getrandbits",
        "sig": ["getrandbits(rng : R, k : Int32) -> UInt64"],
        "zh": "取 k 个低位，一位不多。k 逾六十四，则整字相付。",
        "en": "The low k bits, not one more. Above sixty-four, the whole word comes back.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "choice",
        "sig": ["choice(rng : R, items : ArrayView[T]) -> T?"],
        "zh": "拈一颗；空则 None，不编一个出来。",
        "en": "Take one, or None when there is nothing to take.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "choices",
        "sig": ["choices(rng : R, items : ArrayView[T], k~ : Int32 = 1, weights? : ArrayView[Double]) -> Array[T]"],
        "zh": "有放回地拈 k 次；给权重，则按权重拈。全零之权，视同无权。",
        "en": "Take k with replacement; give weights and the draws follow them. All-zero weights are read as none.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "sample",
        "sig": ["sample(rng : R, items : ArrayView[T], k : Int32) -> Array[T]"],
        "zh": "不放回地拈 k 个，无一重复。k 逾其数，则尽取。",
        "en": "Take k without replacement, no repeats. A k past the end takes all of them.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "shuffle",
        "sig": ["shuffle(rng : R, a : Array[T]) -> Unit"],
        "zh": "就地把顺序打散。元素一个不少，位置全非旧观。",
        "en": "Shuffle in place. Every element stays, no position does.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "gauss",
        "sig": ["gauss(rng : R, mu~ : Double = 0.0, sigma~ : Double = 1.0) -> Double"],
        "zh": "正态一取，Box–Muller 之法，中峰在 mu，宽为 sigma。",
        "en": "One normal draw by Box–Muller, centred on mu, as wide as sigma.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "expovariate",
        "sig": ["expovariate(rng : R, lambd : Double) -> Double"],
        "zh": "指数一取，率为 lambda，均值为其倒数。lambda 非正，则 abort。",
        "en": "One exponential draw at rate lambda, mean its reciprocal. A non-positive rate aborts.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "lognormvariate",
        "sig": ["lognormvariate(rng : R, mu~ : Double = 0.0, sigma~ : Double = 1.0) -> Double"],
        "zh": "对数正态一取，即取正态而幂之。",
        "en": "One lognormal draw: a normal draw, exponentiated.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "alias",
        "key": "StdRng",
        "sig": ["pub type StdRng = @chacha.ChaCha12"],
        "zh": "默认发生器之名。欲换默认，改此一行即可，全库随之。",
        "en": "The default generator's name. Change this line and the whole library follows.",
    },
    {
        "pkg": "moonbitstack/moonrand/contract",
        "kind": "trait",
        "key": "Rng",
        "sig": [
            "pub(open) trait Rng {",
            "  fn next_u64(Self) -> UInt64",
            "  fn next_u32(Self) -> UInt32 = _",
            "  fn fill(Self, buf : FixedArray[Byte]) -> Unit = _",
            "}",
        ],
        "zh": "一切发生器之约：交出均匀机器字。只须自具 next_u64，余二法有默认。",
        "en": "The contract every generator keeps: uniform machine words. Only next_u64 is yours to write; the other two have defaults.",
    },
    {
        "pkg": "moonbitstack/moonrand/contract",
        "kind": "trait",
        "key": "Secure",
        "sig": ["pub(open) trait Secure : Rng {}"],
        "zh": "可为密码学用之标记。Philox 与 PCG 统计上过，然不在此列。",
        "en": "A marker for generators fit for cryptography. Philox and PCG pass the statistics and do not carry it.",
    },
    {
        "pkg": "moonbitstack/moonrand/contract",
        "kind": "trait",
        "key": "Seeded",
        "sig": [
            "pub(open) trait Seeded : Rng {",
            "  fn from_seed(BytesView) -> Self",
            "  fn seed_size() -> Int32",
            "}",
        ],
        "zh": "可自种子重建之发生器，供可复现之跑。种子几何，由 seed_size 自陈。",
        "en": "A generator rebuilt from a seed, for reproducible runs. seed_size says how many bytes it wants.",
    },
    {
        "pkg": "moonbitstack/moonrand/chacha",
        "kind": "type",
        "key": "ChaCha8",
        "sig": [
            "pub struct ChaCha8",
            "new(seed : BytesView) -> ChaCha8",
            "with_nonce(seed : BytesView, nonce0 : UInt32, nonce1 : UInt32, nonce2 : UInt32, ctr : UInt32)",
            "next_u32() -> UInt32 · next_u64() -> UInt64 · fill(buf : FixedArray[Byte])",
        ],
        "covers": ["ChaCha8", "ChaCha8::new", "ChaCha8::with_nonce", "ChaCha8::next_u32", "ChaCha8::next_u64", "ChaCha8::fill"],
        "zh": "八轮。快，余裕最薄，宜于不涉密钥之处。",
        "en": "Eight rounds: fastest, thinnest margin, for places no key passes through.",
    },
    {
        "pkg": "moonbitstack/moonrand/chacha",
        "kind": "type",
        "key": "ChaCha12",
        "sig": [
            "pub struct ChaCha12",
            "new(seed : BytesView) -> ChaCha12",
            "with_nonce(seed : BytesView, nonce0 : UInt32, nonce1 : UInt32, nonce2 : UInt32, ctr : UInt32)",
            "next_u32() -> UInt32 · next_u64() -> UInt64 · fill(buf : FixedArray[Byte])",
        ],
        "covers": ["ChaCha12", "ChaCha12::new", "ChaCha12::with_nonce", "ChaCha12::next_u32", "ChaCha12::next_u64", "ChaCha12::fill"],
        "zh": "十二轮，默认之选。速度与余裕之间，取其中。",
        "en": "Twelve rounds, the default: the middle of the road between speed and margin.",
    },
    {
        "pkg": "moonbitstack/moonrand/chacha",
        "kind": "type",
        "key": "ChaCha20",
        "sig": [
            "pub struct ChaCha20",
            "new(seed : BytesView) -> ChaCha20",
            "with_nonce(seed : BytesView, nonce0 : UInt32, nonce1 : UInt32, nonce2 : UInt32, ctr : UInt32)",
            "next_u32() -> UInt32 · next_u64() -> UInt64 · fill(buf : FixedArray[Byte])",
        ],
        "covers": ["ChaCha20", "ChaCha20::new", "ChaCha20::with_nonce", "ChaCha20::next_u32", "ChaCha20::next_u64", "ChaCha20::fill"],
        "zh": "二十轮，RFC 8439 之数。余裕最厚，速度最让。",
        "en": "Twenty rounds, RFC 8439's count: the widest margin, the least speed.",
    },
]

# Items the compiler derives for a type rather than declaring on its own, and
# the `pub impl` lines: named in the type's row instead of getting one.
ABSORB = {
    "ChaCha8::equal": "ChaCha8",
    "ChaCha12::equal": "ChaCha12",
    "ChaCha20::equal": "ChaCha20",
}

CN_DIGIT = "零一二三四五六七八九十"


def cn_count(n: int) -> str:
    return CN_DIGIT[n] if 0 <= n <= 10 else str(n)


CN_WORD = {
    "fn": "函数",
    "type": "类型",
    "error": "错误",
    "value": "值",
    "trait": "契约",
    "alias": "别名",
}

COUNT_WORD = {
    "fn": ("function", "functions"),
    "type": ("type", "types"),
    "error": ("error", "errors"),
    "value": ("value", "values"),
    "trait": ("trait", "traits"),
    "alias": ("alias", "aliases"),
}


def parse_mbti(path: Path) -> list[tuple[str, str, str]]:
    """Return (package, kind, name) for every public item the file declares."""
    text = path.read_text(encoding="utf-8")
    pkg = re.search(r'^package "([^"]+)"', text, re.M).group(1)
    items: list[tuple[str, str, str]] = []
    block = None
    for line in text.splitlines():
        s = line.strip()
        if block is None:
            patterns = [
                (r"pub fn(?:\[[^\]]*\])?\s+([\w:]+)", "fn"),
                (r"pub struct (\w+)", "type"),
                (r"pub(?:\(all\))? suberror (\w+)", "error"),
                (r"pub let (\w+)", "value"),
                (r"pub(?:\(open\))? trait (\w+)", "trait"),
            ]
            for pattern, kind in patterns:
                m = re.match(pattern, s)
                if m:
                    items.append((pkg, kind, m.group(1)))
                    break
            else:
                m = re.search(r"type \w+ as (\w+)", s) if s.startswith("pub using") else None
                if m:
                    items.append((pkg, "alias", m.group(1)))
            if s.endswith("{"):
                block = s
                continue
        else:
            if s.startswith("}"):
                block = None
            elif block.startswith(("pub(open) trait", "pub trait")) and s.startswith("fn "):
                items.append((pkg, "trait_method", re.match(r"fn (\w+)", s).group(1)))
            elif "suberror" in block and re.fullmatch(r"\w+(\(.*\))?", s):
                items.append((pkg, "variant", s.split("(")[0]))
    return items


def rows_html() -> str:
    out: list[str] = []
    group = None
    for row in ROWS:
        if row["pkg"] != group:
            if group is not None:
                out.append("        </div>")
            group = row["pkg"]
            counts: dict[str, int] = {}
            for other in ROWS:
                if other["pkg"] == group:
                    counts[other["kind"]] = counts.get(other["kind"], 0) + 1
            summary = " · ".join(
                f"{n} {COUNT_WORD[k][1] if n > 1 else COUNT_WORD[k][0]}" for k, n in counts.items()
            )
            cn_summary = " · ".join(f"{CN_WORD[k]}{cn_count(n)}" for k, n in counts.items())
            out.append(
                f'        <div class="ins__grp"><span>{html.escape(group)}</span>'
                f'<i data-zh="{cn_summary}">{summary}</i></div>'
            )
            out.append('        <div class="ins__rows">')
        sig = "<br>".join(html.escape(line) for line in row["sig"])
        out.append(f'        <div class="ins__row" data-item="{row["key"]}">')
        out.append(f'          <div class="ins__sig">{sig}</div>')
        out.append(f'          <div class="ins__g" data-zh="{html.escape(row["zh"], quote=True)}">'
                   f'{html.escape(row["en"], quote=False)}</div>')
        out.append("        </div>")
    if group is not None:
        out.append("        </div>")
    return "\n".join(out)


def version_patch(page: str) -> str:
    version = re.search(r'^version = "(.*)"', (ROOT / "moon.mod").read_text(encoding="utf-8"), re.M)
    return re.sub(r'(<b id="rev-value">)[^<]*(</b>)', rf"\g<1>{version.group(1)}\g<2>", page)


def main() -> int:
    items: list[tuple[str, str, str]] = []
    for path in sorted((ROOT / "src").rglob("pkg.generated.mbti")):
        if "examples" in path.parts:
            continue
        items.extend(parse_mbti(path))

    declared = {(pkg, name) for pkg, kind, name in items if kind in ("fn", "type", "error", "value", "trait", "alias")}
    by_name = {name for _, name in declared}
    covered = {row["key"] for row in ROWS}
    for row in ROWS:
        covered.update(row.get("covers", []))

    missing = sorted(name for _, name in declared if name not in covered and name not in ABSORB)
    stale = sorted(row["key"] for row in ROWS if row["key"] not in by_name)
    if missing:
        print("public items with no row:", file=sys.stderr)
        for name in missing:
            print("  " + name, file=sys.stderr)
    if stale:
        print("rows for items the library no longer has:", file=sys.stderr)
        for name in stale:
            print("  " + name, file=sys.stderr)
    if missing or stale:
        return 1

    page = PAGE.read_text(encoding="utf-8")
    if BEGIN not in page or END not in page:
        print(f"{PAGE} has no {BEGIN} / {END} markers", file=sys.stderr)
        return 1
    head, rest = page.split(BEGIN, 1)
    _, tail = rest.split(END, 1)
    fresh = version_patch(f"{head}{BEGIN}\n{rows_html()}\n        {END}{tail}")

    if "--check" in sys.argv:
        if fresh != page:
            print(f"{PAGE.name} is stale: run python scripts/gen_api.py", file=sys.stderr)
            return 1
        print(f"docs API table covers all {len(declared)} public items in {len(ROWS)} rows")
        return 0

    PAGE.write_text(fresh, encoding="utf-8", newline="\n")
    print(f"wrote docs/index.html: {len(ROWS)} rows for {len(declared)} public items")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
