#!/usr/bin/env python3
"""Render docs/api.html, the reference page, from the generated interfaces.

The item list is the compiler's own output: every name in
``src/**/pkg.generated.mbti`` becomes an entry, with the signature the package
declares and the ``///`` prose above it in the source. Nothing about the list is
typed by hand here, so a public item cannot be missing from the page; the script
counts what it rendered against what the interfaces declare and refuses to write
when the two disagree.

    python scripts/gen_api.py            rewrite docs/api.html
    python scripts/gen_api.py --check    exit 1 when the page is stale

The prose kept in this file is the editorial layer only: one paragraph of
introduction per package, a one-line summary for the homepage digest, and a
fallback description for items that carry no ``///`` text of their own (a trait
implementation's methods, mostly, whose meaning is the contract's).
"""

from __future__ import annotations

import html
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
PAGE = ROOT / "docs" / "api.html"
INDEX = ROOT / "docs" / "index.html"
BEGIN = "<!-- api:begin -->"
END = "<!-- api:end -->"

ROOT_PKG = "moonbitstack/moonrand"

# ---------------------------------------------------------------------------
# The editorial layer: what each package is for, and the one line an item gets
# when the source has no /// prose above it.
# ---------------------------------------------------------------------------

PKG_TITLE = {
    "moonbitstack/moonrand": ("the root", "The default generator, the sampling functions and the distributions."),
    "moonbitstack/moonrand/contract": ("the contract", "What a generator is, held apart so every package can share it."),
    "moonbitstack/moonrand/auto": ("entropy", "One call, seeded from the platform through moonseed."),
    "moonbitstack/moonrand/bits": ("the bit helpers", "Word arithmetic the generators share: a finalizer, a wide multiply, seed expansion."),
    "moonbitstack/moonrand/chacha": ("stream ciphers", "ARX ciphers run as generators; the twelve-round form is the default."),
    "moonbitstack/moonrand/xoshiro": ("xoshiro", "Vigna's shift-register family, 128 and 256 and 512 bits of state."),
    "moonbitstack/moonrand/pcg": ("PCG", "O'Neill's permuted congruential generators, 32 and 64 bits of output."),
    "moonbitstack/moonrand/mt": ("Mersenne Twister", "The 19937 pair and its SIMD-oriented form."),
    "moonbitstack/moonrand/splitmix": ("SplitMix", "A counter through a finalizer: the seed expander, as a generator."),
    "moonbitstack/moonrand/sfc": ("SFC", "Chris Doty-Humphrey's chaotic generator: three words, a counter, a carry."),
    "moonbitstack/moonrand/jsf": ("JSF", "Jenkins' small fast generator, a rotate per draw."),
    "moonbitstack/moonrand/xorshift": ("xorshift", "Marsaglia's shifts, from 32 bits of state to XORWOW."),
    "moonbitstack/moonrand/well": ("WELL", "Well-equidistributed long-period registers, 512 and 1024 bits."),
    "moonbitstack/moonrand/lcg": ("linear and quadratic", "Congruential recurrences: linear, quadratic, cubic, inversive."),
    "moonbitstack/moonrand/chaos": ("chaotic maps", "Logistic, tent, sine and Chebyshev maps: for looks, not for quality."),
    "moonbitstack/moonrand/lfsr": ("LFSR", "Galois and Tausworthe registers, and L'Ecuyer's combined forms."),
    "moonbitstack/moonrand/fib": ("lagged Fibonacci", "Additive and subtractive lags, with and without carry, and RANLUX."),
    "moonbitstack/moonrand/mrg": ("multiple recurrences", "L'Ecuyer's MRG32k3a: two cubic recurrences over primes."),
    "moonbitstack/moonrand/lxm": ("LXM", "A congruential generator added to a xoshiro one, as Blackman and Vigna mix them."),
    "moonbitstack/moonrand/philox": ("counter based", "Random123's Philox: a bijection over counter words, no state to carry."),
    "moonbitstack/moonrand/threefry": ("counter based", "Random123's Threefry: the same idea without a multiply."),
    "moonbitstack/moonrand/squares": ("squares", "Widynski's Squares, and the middle-square family it descends from."),
    "moonbitstack/moonrand/classic": ("the old ones", "Middle square and its descendants, up to Blum Blum Shub."),
}

TYPE_DOC = {
    "ChaCha8": "Eight rounds of ChaCha; the fastest and the narrowest margin.",
    "ChaCha12": "Twelve rounds, the library's default.",
    "ChaCha20": "Twenty rounds, the RFC 8439 count.",
}
ITEM_DOC = {
    "new": "Seed it: the bytes go through SplitMix64, a short seed padded.",
    "from_state": "Start from a state you already have, unchanged.",
    "with_state": "Start from a state you already have, unchanged.",
    "with_params": "Start from the parameters and a seed.",
    "with_key": "Start from a key, with the counter at zero.",
    "with_stream": "Start where the reference seeding puts it.",
    "with_word": "Start from one word, the reference seeding.",
    "from_array": "Start from a key array, the reference seeding.",
    "glibc": "The parameters the C library uses.",
    "numerical_recipes": "The parameters Numerical Recipes prints.",
    "jump": "A fixed distance ahead, by the reference polynomial.",
    "long_jump": "Further ahead than jump, the same way.",
    "advance": "Skip n draws without making them.",
    "next_u64": "The contract's draw: one 64-bit word.",
    "next_u32": "The contract's draw: one 32-bit word.",
    "fill": "Fill a byte array from the stream.",
    "from_seed": "Rebuild from a seed of seed_size bytes.",
    "seed_size": "How many bytes a seed is.",
}

# The homepage keeps its Chinese layer, so the root package's one-liners carry
# both languages. Every function of the root package is here.
CURATED = {
    "seeded": (
        "Start from thirty-two bytes. The same bytes give the same stream, bit for bit on all four backends.",
        "从三十二字节开始。字节相同，流就相同；四个后端上逐位一致。",
    ),
    "random": (
        "A real in [0, 1) with exactly fifty-three bits, the same draw as Python's random().",
        "[0, 1) 之间的实数，五十三位精度，取法与 Python 的 random() 相同。",
    ),
    "uniform": (
        "Anywhere in [low, high), equally thick. Reversed ends are taken as given.",
        "[low, high) 上的均匀实数。low 比 high 大也照收，两端自行调换。",
    ),
    "bernoulli": (
        "True with probability p, false the rest of the time; p outside [0, 1] is answered by the nearer end.",
        "以 p 的概率为真，其余为假；p 超出 [0, 1] 时按近的那一端答。",
    ),
    "randint": (
        "An integer, both ends included. A high below low returns low.",
        "闭区间 [low, high] 上的整数。high 小于 low 时原样返回 low。",
    ),
    "randrange": (
        "An integer, right end excluded, with an optional start and step. An empty range or a zero step aborts.",
        "左闭右开的整数，起点和步长可选。范围为空或步长为零则中止。",
    ),
    "getrandbits": (
        "The low k bits, not one more. Above sixty-four, the whole word comes back.",
        "取低 k 位，不多一位。k 超过 64 时返回整个字。",
    ),
    "randbytes": (
        "n bytes from the stream: the same seed writes the same bytes.",
        "从流里取 n 个字节：同一个种子写出的字节相同。",
    ),
    "choice": (
        "Take one, or None when there is nothing to take.",
        "从中抽一个；数组为空则返回 None，不凭空造一个。",
    ),
    "choices": (
        "Take k with replacement; give weights and the draws follow them. All-zero weights are read as none.",
        "有放回地抽 k 次；给了权重就按权重抽，权重全为零视同未给。",
    ),
    "sample": (
        "Take k without replacement, no repeats. With weights, each place is filled from what is left in proportion.",
        "不放回地抽 k 个，互不重复。给了权重就按剩余元素的比例逐个占位。",
    ),
    "shuffle": (
        "Shuffle in place. Every element stays, no position does.",
        "就地打乱顺序，元素一个不少。",
    ),
    "permutation": (
        "0 to n - 1 in a random order: the indices of a shuffle, without an array to shuffle.",
        "0 到 n-1 的一个随机顺序：洗牌的索引，不必先有数组。",
    ),
    "gauss": (
        "One normal draw by Box-Muller, centred on mu, as wide as sigma.",
        "一次正态抽样，Box–Muller 法；均值为 mu，标准差为 sigma。",
    ),
    "normalvariate": (
        "One normal draw by Kinderman-Monahan; the same seed gives a different stream than gauss.",
        "一次正态抽样，Kinderman–Monahan 比值法。同一个种子，走势与 gauss 不同。",
    ),
    "expovariate": (
        "One exponential draw at rate lambda, mean its reciprocal. A non-positive rate aborts.",
        "一次指数抽样，比率为 lambda，均值为其倒数。lambda 不为正时中止。",
    ),
    "lognormvariate": (
        "One lognormal draw: a normal draw, exponentiated.",
        "一次对数正态抽样：先取正态，再取指数。",
    ),
    "gammavariate": (
        "One gamma draw by Marsaglia-Tsang: shape alpha, scale beta.",
        "一次伽马抽样，Marsaglia–Tsang 法；形状为 alpha，尺度为 beta。",
    ),
    "betavariate": (
        "One beta draw: two gamma draws, one over their sum, in (0, 1).",
        "一次贝塔抽样：两个伽马相除，结果落在 (0, 1)。",
    ),
    "chi_squared": (
        "One chi-squared draw with df degrees of freedom: a gamma draw of shape df/2 and scale two.",
        "一次卡方抽样，自由度为 df：形状 df/2、尺度二的伽马抽样。",
    ),
    "student_t": (
        "One Student's t draw with nu degrees of freedom: a normal draw over the root of a chi-squared one.",
        "一次 t 抽样，自由度为 nu：正态抽样除以卡方抽样与其自由度之比的开方。",
    ),
    "fisher_f": (
        "One F draw: two chi-squared draws, each over its own degrees of freedom, divided.",
        "一次 F 抽样：两个卡方各除以自己的自由度，再相除。",
    ),
    "dirichlet": (
        "One Dirichlet draw: a gamma draw per concentration, each scaled down by their sum.",
        "一次狄利克雷抽样：每个浓度取一个伽马，再按总和归一。",
    ),
    "poisson": (
        "One Poisson draw with mean mu: multiplication below thirty, transformed rejection above it.",
        "一次泊松抽样，均值为 mu。均值小时走乘法，均值大时走变换拒绝，各走各的快路。",
    ),
    "binomialvariate": (
        "The number of successes in n trials of probability p, by inverting the distribution term by term.",
        "n 次独立试验里的成功次数，单次成功率为 p。逐项反演，不做近似。",
    ),
    "triangular": (
        "One triangular draw peaking at mode, the midpoint when it is not given.",
        "一次三角分布抽样，峰在 mode；不给则取中点。",
    ),
    "vonmisesvariate": (
        "One draw on the circle, mean angle mu, concentration kappa, in [0, 2 pi).",
        "圆周上的一次抽样，平均角为 mu，聚集度为 kappa，结果在 [0, 2π) 内。",
    ),
    "paretovariate": (
        "One Pareto draw of shape alpha: a long tail with no upper bound.",
        "一次帕累托抽样，形状参数 alpha；尾部很长，没有上界。",
    ),
    "weibullvariate": (
        "One Weibull draw, scale alpha, shape beta.",
        "一次威布尔抽样，尺度为 alpha，形状为 beta。",
    ),
    "StdRng": (
        "The default generator's name. Change this line and the whole library follows.",
        "默认生成器的别名。换掉这一行，全库的默认算法随之改变。",
    ),
}

ORDER = ["root", "contract", "auto", "bits"]
GENERIC_FN = "Part of the package's surface."
GENERIC_TYPE = "A generator."


# ---------------------------------------------------------------------------
# Reading the interfaces and the source
# ---------------------------------------------------------------------------

class Item:
    __slots__ = ("name", "kind", "sig", "doc", "methods", "traits", "fields")

    def __init__(self, name: str, kind: str, sig: str):
        self.name = name
        self.kind = kind
        self.sig = sig
        self.doc = ""
        self.methods: list[Item] = []
        self.traits: list[str] = []
        self.fields: list[str] = []


class Package:
    def __init__(self, name: str):
        self.name = name
        self.short = name.rsplit("/", 1)[-1] if name != ROOT_PKG else "root"
        self.traits: list[Item] = []
        self.types: list[Item] = []
        self.fns: list[Item] = []
        self.aliases: list[Item] = []

    def all_items(self):
        for t in self.traits:
            yield t
            yield from t.methods
        for t in self.types:
            yield t
            yield from t.methods
        yield from self.fns
        yield from self.aliases

    def count(self) -> int:
        return sum(1 for _ in self.all_items())


def parse_mbti(path: Path) -> Package:
    text = path.read_text(encoding="utf-8")
    pkg = Package(re.search(r'^package "([^"]+)"', text, re.M).group(1))
    lines = text.splitlines()
    i = 0
    pending: dict[str, Item] = {}
    while i < len(lines):
        s = lines[i].strip()
        m = re.match(r"pub\(open\) trait (\w+)(?:\s*:\s*([\w@.]+))?\s*\{$", s)
        if not m:
            m2 = re.match(r"pub trait (\w+)(?:\s*:\s*([\w@.]+))?\s*\{$", s)
            m = m2 if m2 else m
        if m and (s.startswith("pub(open) trait") or s.startswith("pub trait")):
            item = Item(m.group(1), "trait", f"pub(open) trait {m.group(1)}" if s.startswith("pub(open)") else f"pub trait {m.group(1)}")
            if m.group(2):
                item.sig += f" : {m.group(2)}"
            i += 1
            while i < len(lines) and lines[i].strip() != "}":
                inner = lines[i].strip()
                if inner and not inner.startswith("//"):
                    item.methods.append(Item(inner.split("(")[0].replace("fn ", ""), "method", inner))
                i += 1
            pkg.traits.append(item)
            i += 1
            continue
        m = re.match(r"pub struct (\w+)\s*\{$", s)
        if m:
            item = Item(m.group(1), "type", f"pub struct {m.group(1)}")
            pending[m.group(1)] = item
            i += 1
            while i < len(lines) and lines[i].strip() != "}":
                inner = lines[i].strip()
                if inner and not inner.startswith("//"):
                    item.fields.append(inner)
                i += 1
            pkg.types.append(item)
            i += 1
            continue
        m = re.match(r"pub fn(?:\[[^\]]*\])?\s+([\w]+)::(\w+)\(", s)
        if m:
            owner, meth = m.group(1), m.group(2)
            item = Item(f"{owner}::{meth}", "method", s)
            if owner in pending:
                pending[owner].methods.append(item)
            else:
                pkg.fns.append(item)
            i += 1
            continue
        m = re.match(r"pub fn(?:\[[^\]]*\])?\s+(\w+)\(", s)
        if m:
            pkg.fns.append(Item(m.group(1), "fn", s))
            i += 1
            continue
        m = re.match(r"pub using .*type (\w+) as (\w+)", s)
        if m:
            pkg.aliases.append(Item(m.group(2), "alias", f"pub type {m.group(2)} = {m.group(1)}"))
            i += 1
            continue
        m = re.match(r"pub impl ([\w@.]+) for (\w+)$", s)
        if m and m.group(2) in pending:
            pending[m.group(2)].traits.append(m.group(1).rsplit(".", 1)[-1])
            i += 1
            continue
        i += 1
    return pkg


def source_facts(pkg_dir: Path) -> tuple[dict[str, str], dict[str, str]]:
    """Doc comment and declaration text, keyed by the name the interface uses."""
    docs: dict[str, str] = {}
    sigs: dict[str, str] = {}
    for path in sorted(pkg_dir.glob("*.mbt")):
        if path.name.endswith("_test.mbt"):
            continue
        lines = path.read_text(encoding="utf-8").splitlines()
        buf: list[str] = []
        i = 0
        while i < len(lines):
            s = lines[i].strip()
            if s.startswith("///"):
                text = s[3:]
                if text.startswith("|"):
                    text = text[1:]
                buf.append(text.strip())
                i += 1
                continue
            if s.startswith("#["):
                i += 1
                continue
            m = re.match(
                r"pub(?:\(open\))?\s+(?:fn|struct|trait|type|let|enum)\b", s) or re.match(
                r"pub impl .* for \w+ with fn \w+", s)
            if not m:
                if s and not s.startswith("//"):
                    buf = []
                i += 1
                continue
            # A declaration: gather its text up to the opening brace.
            decl = [s]
            depth = s.count("{") - s.count("}")
            j = i
            while depth == 0 and j + 1 < len(lines) and not decl[-1].rstrip().endswith("{"):
                j += 1
                decl.append(lines[j].strip())
                depth += lines[j].count("{") - lines[j].count("}")
            text = re.sub(r"\s+", " ", " ".join(decl)).strip()
            text = re.sub(r"\s*\{\s*$", "", text)
            name = None
            mk = re.match(r"pub fn(?:\[[^\]]*\])?\s+([\w:]+)\(", text)
            with_fn = re.match(r"pub impl .* for (\w+) with fn (\w+)", text)
            if with_fn:
                name = f"{with_fn.group(1)}::{with_fn.group(2)}"
                text = "pub fn " + text.split("with fn ", 1)[1]
            elif mk:
                name = mk.group(1)
            else:
                mk = re.match(
                    r"pub(?:\(open\))?\s+(?:struct|enum|trait|type|let)\s+(\w+)", text)
                if mk:
                    name = mk.group(1)
            if name:
                if not re.match(r"pub fn", text):
                    text = re.sub(r"\s*=\s*", " = ", text)
                sigs[name] = text
                if buf:
                    docs[name] = "\n".join(buf).strip()
            buf = []
            i = max(i, j) + 1
    return docs, sigs


def sort_key(pkg: Package) -> tuple[int, str]:
    return (ORDER.index(pkg.short) if pkg.short in ORDER else len(ORDER), pkg.short)


def load() -> list[Package]:
    pkgs: list[Package] = []
    for path in sorted(SRC.rglob("pkg.generated.mbti")):
        if "examples" in path.parts:
            continue
        pkg = parse_mbti(path)
        docs, sigs = source_facts(path.parent)
        for item in pkg.all_items():
            if item.name in docs:
                item.doc = docs[item.name]
            if item.name in sigs:
                item.sig = sigs[item.name]
        pkgs.append(pkg)
    pkgs.sort(key=sort_key)
    return pkgs


def describe(pkg: Package, item: Item) -> str:
    """The prose under a signature: the source's own, else the editorial line."""
    if item.doc:
        return item.doc
    name = item.name.rsplit("::", 1)[-1]
    if pkg.name == ROOT_PKG and item.name in CURATED:
        return CURATED[item.name][0]
    if name in ITEM_DOC and item.kind == "method":
        return ITEM_DOC[name]
    if item.name in TYPE_DOC:
        return TYPE_DOC[item.name]
    if item.kind == "type":
        return GENERIC_TYPE
    if item.kind == "method":
        return "Part of the generator's surface."
    if item.kind == "trait":
        return "A contract a generator keeps."
    return GENERIC_FN


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

def esc(text: str) -> str:
    return html.escape(text, quote=True)


def anchor(pkg: Package, item: Item) -> str:
    return f"{pkg.short}-{item.name.replace('::', '-')}".lower()


def tidy_sig(text: str) -> str:
    """One line a reader can copy: no stray space before a bracket, no dangling comma."""
    text = re.sub(r"\s*,\s*", ", ", text)
    text = re.sub(r"\(\s+", "(", text)
    text = re.sub(r"\s+\)", ")", text)
    text = re.sub(r"\[\s+", "[", text)
    text = re.sub(r"\s+\]", "]", text)
    text = re.sub(r",\s*\)", ")", text)
    text = re.sub(r"\s*->\s*", " -> ", text)
    text = re.sub(r"\s*=\s*", " = ", text)
    text = re.sub(r"\s*:\s*", " : ", text)
    text = re.sub(r"\s*::\s*", "::", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def sig_html(item: Item) -> str:
    """The declaration, one line, with the owner stripped from a method row."""
    text = item.sig
    if item.kind == "method":
        text = re.sub(r"^pub fn(?:\[[^\]]*\])?\s+", "", text)
        text = re.sub(r"^\w+::", "", text)
    return esc(tidy_sig(text))


INLINE = re.compile(r"`([^`]+)`|\*\*([^*]+)\*\*")


def inline(text: str) -> str:
    out: list[str] = []
    last = 0
    for m in INLINE.finditer(text):
        out.append(esc(text[last:m.start()]))
        if m.group(1) is not None:
            out.append(f"<code>{esc(m.group(1))}</code>")
        else:
            out.append(f"<strong>{esc(m.group(2))}</strong>")
        last = m.end()
    out.append(esc(text[last:]))
    return "".join(out)


def paragraphs(doc: str) -> str:
    """Doc comments are Markdown: paragraphs, inline code, and the odd fence."""
    out: list[str] = []
    for chunk in re.split(r"\n\s*\n", doc):
        chunk = chunk.strip()
        if not chunk:
            continue
        if chunk.startswith("```"):
            body = re.sub(r"^```[^\n]*\n", "", chunk)
            body = re.sub(r"\n?```$", "", body)
            out.append(f'<pre class="ref__code"><code>{esc(body)}</code></pre>')
        else:
            out.append(f"<p>{inline(re.sub(r'\s*\n\s*', ' ', chunk))}</p>")
    return "".join(out)


def render_item(pkg: Package, item: Item) -> list[str]:
    a = anchor(pkg, item)
    out = [f'      <div class="ref__item" id="i-{a}" data-item="{esc(pkg.name)}::{esc(item.name)}">',
           f'        <div class="ref__sig"><code>{sig_html(item)}</code></div>',
           f'        <div class="ref__doc">{paragraphs(describe(pkg, item))}</div>',
           "      </div>"]
    return out


def render_type(pkg: Package, item: Item) -> list[str]:
    a = anchor(pkg, item)
    out = [f'    <article class="ref__type" id="i-{a}" data-item="{esc(pkg.name)}::{esc(item.name)}">',
           '      <header class="ref__head">',
           f'        <h3><code>{esc(item.name)}</code></h3>',
           f'        <span class="ref__implements">{esc(", ".join(item.traits)) if item.traits else ""}</span>',
           "      </header>",
           f'      <div class="ref__sig"><code>{sig_html(item)}</code></div>',
           f'      <div class="ref__doc">{paragraphs(describe(pkg, item))}</div>']
    if item.methods:
        out.append('      <div class="ref__methods">')
        for meth in item.methods:
            out.extend(render_item(pkg, meth))
        out.append("      </div>")
    out.append("    </article>")
    return out


def render_trait(pkg: Package, item: Item) -> list[str]:
    a = anchor(pkg, item)
    out = [f'    <article class="ref__type" id="i-{a}" data-item="{esc(pkg.name)}::{esc(item.name)}">',
           '      <header class="ref__head">',
           f'        <h3><code>{esc(item.name)}</code></h3>',
           '        <span class="ref__implements">trait</span>',
           "      </header>",
           f'      <div class="ref__sig"><code>{sig_html(item)}</code></div>',
           f'      <div class="ref__doc">{paragraphs(describe(pkg, item))}</div>']
    if item.methods:
        out.append('      <div class="ref__methods">')
        for meth in item.methods:
            out.append('      <div class="ref__item" data-item="'
                       f'{esc(pkg.name)}::{esc(item.name)}::{esc(meth.name)}">')
            out.append(f'        <div class="ref__sig"><code>{esc(meth.sig)}</code></div>')
            body = ITEM_DOC.get(meth.name, "A method the contract asks for.")
            out.append(f'        <div class="ref__doc"><p>{esc(body)}</p></div>')
            out.append("      </div>")
        out.append("      </div>")
    out.append("    </article>")
    return out


def render_package(pkg: Package) -> list[str]:
    title, intro = PKG_TITLE.get(pkg.name, ("", ""))
    out = [f'  <section class="ref__pkg" id="pkg-{pkg.short.lower()}">',
           '    <header class="ref__pkgh">',
           f'      <p class="kicker">{esc(title)}</p>',
           f'      <h2><code>{esc(pkg.name)}</code><small>{pkg.count()} item{"" if pkg.count() == 1 else "s"}</small></h2>',
           f'      <p class="ref__intro">{esc(intro)}</p>',
           "    </header>"]
    if pkg.traits:
        out.append('    <p class="ref__label">traits</p>')
        for item in pkg.traits:
            out.extend(render_trait(pkg, item))
    if pkg.types:
        out.append('    <p class="ref__label">types</p>')
        for item in pkg.types:
            out.extend(render_type(pkg, item))
    if pkg.fns:
        out.append('    <p class="ref__label">functions</p>')
        out.append('    <div class="ref__list">')
        for item in pkg.fns:
            out.extend(render_item(pkg, item))
        out.append("    </div>")
    if pkg.aliases:
        out.append('    <p class="ref__label">type aliases</p>')
        out.append('    <div class="ref__list">')
        for item in pkg.aliases:
            out.extend(render_item(pkg, item))
        out.append("    </div>")
    out.append("  </section>")
    return out


def render_side(packages: list[Package]) -> list[str]:
    out = ['    <nav class="ref__side" aria-label="packages">',
           '      <p class="ref__sideh">packages</p>',
           '      <ul>']
    for pkg in packages:
        out.append(f'        <li><a href="#pkg-{pkg.short.lower()}">'
                   f'<span>{esc(pkg.short)}</span><i>{pkg.count()}</i></a></li>')
    out.append("      </ul>")
    out.append("    </nav>")
    return out


def render_page(packages: list[Package]) -> str:
    total_items = sum(p.count() for p in packages)
    total_types = sum(len(p.types) for p in packages)
    body: list[str] = []
    body.extend(render_side(packages))
    body.append('    <div class="ref__main">')
    body.append('      <div class="ref__top">')
    body.append('        <p class="kicker">reference</p>')
    body.append('        <h1 class="ref__t">Every public item<small>the compiler\'s own list</small></h1>')
    body.append(
        '        <p class="ref__lede">This page is generated from the interfaces '
        f'<code>moon info</code> writes and the <code>///</code> prose above each declaration: '
        f'{total_items} items over {len(packages)} packages, of which {total_types} are generator types. '
        'The signature is the compiler\'s; the paragraph under it is the source\'s.</p>')
    body.append("      </div>")
    for pkg in packages:
        body.extend(render_package(pkg))
    body.append("    </div>")
    version = version_of()
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>moonrand — the reference</title>
<meta name="description" content="Every public type, function and trait of moonrand, generated from the module's interfaces.">
<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' fill='%23F7F5ED'/%3E%3Ccircle cx='16' cy='16' r='11' fill='none' stroke='%231E3A5C' stroke-width='1.2'/%3E%3Ccircle cx='16' cy='16' r='4' fill='%23A83A2B'/%3E%3C/svg%3E">
<link rel="stylesheet" href="site.css">
</head>
<body class="page-ref">
<div class="sheet">

  <header class="bar">
    <div><b>moonrand</b> <span class="bar__v"><span id="rev-value">{version}</span> · Apache-2.0</span></div>
    <div class="r">
      <a href="https://moonbitstack.github.io/moonseed/">moonseed · entropy</a>
      <a href="index.html">overview</a>
      <a href="guide.html">guide</a>
      <a href="index.html#plates">demo</a>
      <a href="api.html" aria-current="page">api</a>
      <a href="https://github.com/moonbitstack/moonrand">GitHub</a>
    </div>
  </header>

  <main class="ref">
{BEGIN}
{chr(10).join(body)}
{END}
  </main>

  <footer class="foot">
    <div class="wrap">
      <div class="foot__row">
        <div><span class="seal">掷</span></div>
        <div class="foot__meta">
          <b>moonrand · Apache-2.0</b>
          <a href="https://github.com/moonbitstack/moonrand">github.com/moonbitstack/moonrand</a><br>
          <span>generated from pkg.generated.mbti · do not edit by hand</span>
        </div>
        <div class="foot__next">
          <span>back to</span>
          <a href="index.html">overview</a>
          <a href="guide.html">guide</a>
        </div>
      </div>
    </div>
  </footer>

</div>
<script src="site.js"></script>
</body>
</html>
"""


def render_index_digest(root: Package) -> str:
    """The homepage's short table: the root package, in the interface's order."""
    out: list[str] = []
    items = root.fns + root.aliases
    out.append(f'        <details class="ins__pkg" open>')
    counts = f"{len(root.fns)} functions · {len(root.aliases)} alias"
    out.append(f'        <summary class="ins__grp"><span>{esc(root.name)}</span>'
               f'<i data-zh="函数{cn_count(len(root.fns))} · 别名{cn_count(len(root.aliases))}">{counts}</i></summary>')
    out.append('        <div class="ins__rows">')
    for item in items:
        en, zh = CURATED.get(item.name, (describe(root, item), describe(root, item)))
        out.append(f'        <div class="ins__row" data-item="{esc(item.name)}">')
        out.append(f'          <div class="ins__sig">{esc(tidy_sig(item.sig))}</div>')
        out.append(f'          <div class="ins__g" data-zh="{esc(zh)}">{esc(en)}</div>')
        out.append("        </div>")
    out.append("        </div>")
    out.append("        </details>")
    total = sum(pkg.count() for pkg in PACKAGES)
    out.append(f'        <p class="ins__foot"><a href="api.html" data-zh="参考页 · 全部 {total} 项，{len(PACKAGES)} 个包">'
               f'The reference: all {total} items, {len(PACKAGES)} packages</a></p>')
    return "\n".join(out)


CN_DIGIT = "零一二三四五六七八九十"


def cn_count(n: int) -> str:
    if n <= 10:
        return CN_DIGIT[n]
    if n < 20:
        return "十" + CN_DIGIT[n - 10]
    if n < 100:
        tens, units = divmod(n, 10)
        return CN_DIGIT[tens] + "十" + (CN_DIGIT[units] if units else "")
    return str(n)


def version_of() -> str:
    text = (ROOT / "moon.mod").read_text(encoding="utf-8")
    return re.search(r'^version = "(.*)"', text, re.M).group(1)


def declared_keys(packages: list[Package]) -> set[str]:
    keys: set[str] = set()
    for pkg in packages:
        for trait in pkg.traits:
            keys.add(f"{pkg.name}::{trait.name}")
            for meth in trait.methods:
                keys.add(f"{pkg.name}::{trait.name}::{meth.name}")
        for typ in pkg.types:
            keys.add(f"{pkg.name}::{typ.name}")
            for meth in typ.methods:
                keys.add(f"{pkg.name}::{meth.name}")
        for fn in pkg.fns:
            keys.add(f"{pkg.name}::{fn.name}")
        for alias in pkg.aliases:
            keys.add(f"{pkg.name}::{alias.name}")
    return keys


def rendered_keys(page: str) -> set[str]:
    return set(re.findall(r'data-item="([^"]+)"', page))


def check_coverage(packages: list[Package], page: str) -> list[str]:
    """Every name the interfaces declare must be on the page, once."""
    problems: list[str] = []
    want = declared_keys(packages)
    got = rendered_keys(page)
    for name in sorted(want - got):
        problems.append(f"missing from the page: {name}")
    for name in sorted(got - want):
        problems.append(f"on the page but not in the interfaces: {name}")
    return problems


PACKAGES: list[Package] = []


def main() -> int:
    global PACKAGES
    packages = load()
    PACKAGES = packages
    page = render_page(packages)
    problems = check_coverage(packages, page)
    if problems:
        for line in problems:
            print(line, file=sys.stderr)
        return 1

    index = INDEX.read_text(encoding="utf-8")
    if BEGIN in index and END in index:
        head, rest = index.split(BEGIN, 1)
        _, tail = rest.split(END, 1)
        root = next(p for p in packages if p.name == ROOT_PKG)
        index_new = f"{head}{BEGIN}\n{render_index_digest(root)}\n        {END}{tail}"
        index_new = re.sub(r'(<(?:b|span) id="rev-value">)[^<]*(</(?:b|span)>)',
                           rf"\g<1>{version_of()}\g<2>", index_new)
    else:
        index_new = index

    if "--check" in sys.argv:
        stale = []
        if page != (PAGE.read_text(encoding="utf-8") if PAGE.exists() else ""):
            stale.append("docs/api.html")
        if index_new != index:
            stale.append("docs/index.html")
        if stale:
            print("stale: run python scripts/gen_api.py :: " + ", ".join(stale), file=sys.stderr)
            return 1
        total = sum(p.count() for p in packages)
        print(f"the reference covers {total} public items in {len(packages)} packages")
        return 0

    with open(PAGE, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(page)
    with open(INDEX, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(index_new)
    total = sum(p.count() for p in packages)
    print(f"wrote docs/api.html: {total} items in {len(packages)} packages")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
