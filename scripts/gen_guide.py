#!/usr/bin/env python3
"""Build docs/guide.html: the walk-through, from a seed to a distribution.

Each section is a paragraph of prose and one block of MoonBit that the page
then prints the result of. The code and the output it prints live together
here, so the page cannot drift from either: `scripts/check_snippets.py` takes
the blocks out of the built page and compiles them, and the output under each
one was copied from a run of that page's own blocks.

    python scripts/gen_guide.py            rewrite docs/guide.html
    python scripts/gen_guide.py --check     exit 1 when the page is stale
"""

from __future__ import annotations

import html
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from site_parts import band

ROOT = Path(__file__).resolve().parent.parent
PAGE = ROOT / "docs" / "guide.html"

SECTIONS = [
    {
        "n": "01",
        "slug": "install",
        "name": "it starts with a seed",
        "kick": "install",
        "prose": """
<p>Add the module and the generator comes with it. There is nothing to configure:
<code>seeded</code> takes any bytes and gives back a generator, and every draw
after that is a function that takes the generator first.</p>
<p>Thirty-two bytes fix the whole stream. Where they come from is your business —
a constant, a file, a hash, a row id. The same bytes always draw the same
numbers, which is what makes a run that went wrong replayable.</p>
""",
        "code": """
let rng = @moonrand.seeded(b"a seed")
let roll = @moonrand.randint(rng, 1L, 6L)
let noise = @moonrand.gauss(rng)
println(roll)
println(noise)
""",
        "out": """
5
0.03498079073290354
""",
    },
    {
        "n": "02",
        "slug": "seed",
        "name": "the seed decides the stream",
        "kick": "seeds",
        "prose": """
<p>A seed is not a number that picks a starting point; it is the whole state. Two
generators seeded alike are the same generator, and one changed byte is a
different stream from the first draw — not a related one that drifts.</p>
<p><code>randbytes</code> writes the stream out as bytes, which is the plainest
way to see that. Every backend — native, JS, wasm, wasm-gc — writes the same
eight bytes here.</p>
""",
        "code": """
let first = @moonrand.seeded(b"a seed")
let same = @moonrand.seeded(b"a seed")
let other = @moonrand.seeded(b"a seeD")
println(@moonrand.randbytes(first, 8))
println(@moonrand.randbytes(same, 8))
println(@moonrand.randbytes(other, 8))
""",
        "out": """
b"\\x87\\x9d\\x02R\\xadn@O"
b"\\x87\\x9d\\x02R\\xadn@O"
b"2\\xf4\\xea\\x89\\xec\\x0c)A"
""",
    },
    {
        "n": "03",
        "slug": "handle",
        "name": "a generator is a handle",
        "kick": "state",
        "prose": """
<p>There is no global generator and no thread-local one: a generator carries its
own state, and the functions that draw are generic over it. Two generators built
from the same seed walk the same numbers, side by side, without touching each
other.</p>
<p>The state itself lives in a buffer the handle points at, so <code>let b = a</code>
gives you a second name for one state rather than a second stream. Seed another
generator when you want two streams to be independent — or use <code>jump</code>,
below, to move one of them far away.</p>
""",
        "code": """
let left = @moonrand.seeded(b"two streams")
let right = @moonrand.seeded(b"two streams")
println(@moonrand.randint(left, 0L, 999L))
println(@moonrand.randint(right, 0L, 999L))
""",
        "out": """
630
630
""",
    },
    {
        "n": "04",
        "slug": "algorithms",
        "name": "when the algorithm matters",
        "kick": "algorithms",
        "prose": """
<p>The default is ChaCha12, and most code should keep it. When a published
algorithm is the point — reproducing someone else's stream, matching a paper,
fitting a hardware budget — pick the type out of the subpackage that holds that
family. Every one of them satisfies the same contract, so <code>randint</code>
and the rest do not change.</p>
<p>The same seed across three families gives three different numbers, and the
same family on another machine gives the same one.</p>
""",
        "code": """
let x = @xoshiro.Xoshiro256ss::new(b"algebra")
println(@moonrand.randint(x, 0L, 99L))
let p = @pcg.Pcg64::new(b"algebra")
println(@moonrand.randint(p, 0L, 99L))
let m = @mt.MT19937::new(b"algebra")
println(@moonrand.randint(m, 0L, 99L))
""",
        "out": """
64
89
68
""",
    },
    {
        "n": "05",
        "slug": "integers",
        "name": "integers, without a thumb on the scale",
        "kick": "integers",
        "prose": """
<p><code>randint</code> takes both ends, <code>randrange</code> leaves the right one
out and allows a start and a step, and <code>getrandbits</code> returns the low
bits of a word. None of them takes a remainder: a draw outside the range is
rejected and drawn again, so no value is more likely than another however ragged
the range is.</p>
<p>An inverted range is answered, not punished — <code>high</code> below
<code>low</code> returns <code>low</code> — while a range with no integers in it
aborts, because there is no honest number to return.</p>
""",
        "code": """
let r = @moonrand.seeded(b"ranges")
println(@moonrand.randint(r, -3L, 3L))
println(@moonrand.randrange(r, 100L, start=90L, step=5L))
println(@moonrand.getrandbits(r, 12))
println(@moonrand.randbytes(r, 4))
""",
        "out": """
-3
90
692
b"\\xf4\\xef\\xf2\\x00"
""",
    },
    {
        "n": "06",
        "slug": "collections",
        "name": "choosing from a collection",
        "kick": "collections",
        "prose": """
<p>Five functions cover the deck: <code>choice</code> takes one,
<code>choices</code> takes several with replacement, <code>sample</code> takes
several without, <code>shuffle</code> reorders in place, and
<code>permutation</code> hands back the order as indices.</p>
<p>Give <code>choices</code> weights and the draws follow them. Give
<code>sample</code> weights and each place is filled from what is still left, in
proportion — a heavier element tends to come out earlier, and nothing repeats.</p>
""",
        "code": """
let r = @moonrand.seeded(b"deck")
let deck = ["A", "K", "Q", "J", "10"]
println(@moonrand.choice(r, deck))
println(@moonrand.choices(r, deck, k=3))
println(@moonrand.sample(r, deck, 2))
@moonrand.shuffle(r, deck)
println(deck)
println(@moonrand.permutation(r, 6))
""",
        "out": """
Some(10)
[K, A, 10]
[K, 10]
[10, Q, J, A, K]
[0, 1, 4, 5, 3, 2]
""",
    },
    {
        "n": "07",
        "slug": "distributions",
        "name": "the shapes",
        "kick": "distributions",
        "prose": """
<p>One draw each, over the same generator, named as Python's <code>random</code>
names them. Gamma, beta, chi-squared, Student's t and Fisher's F are one family:
each is built from a gamma or a normal draw by its own definition, so a beta is
two gammas and a t is a normal over a chi-squared.</p>
<p><code>gauss</code> and <code>normalvariate</code> are two algorithms, not two
spellings — Box-Muller against ratio of uniforms. A run that swaps one for the
other does not reproduce, and neither caches a spare draw, so the stream stays in
step with the calls you make.</p>
""",
        "code": """
let r = @moonrand.seeded(b"shapes")
println(@moonrand.gauss(r, mu=10.0, sigma=2.0))
println(@moonrand.normalvariate(r))
println(@moonrand.gammavariate(r, 2.0, 3.0))
println(@moonrand.betavariate(r, 2.0, 5.0))
println(@moonrand.chi_squared(r, 5.0))
println(@moonrand.student_t(r, 10.0))
println(@moonrand.fisher_f(r, 6.0, 10.0))
let parts = @moonrand.dirichlet(r, [1.0, 2.0, 3.0])
println(parts[0])
println(parts[1])
println(parts[2])
println(@moonrand.poisson(r, 4.0))
println(@moonrand.binomialvariate(r, 10L, 0.3))
println(@moonrand.triangular(r, low=0.0, high=1.0, mode=0.2))
println(@moonrand.vonmisesvariate(r, 0.0, 2.0))
println(@moonrand.expovariate(r, 1.5))
println(@moonrand.lognormvariate(r))
println(@moonrand.weibullvariate(r, 1.0, 2.0))
println(@moonrand.paretovariate(r, 3.0))
""",
        "out": """
8.113666721484485
0.3617346781734278
7.777457291235741
0.06833245340410213
3.0586760418166508
0.33356405740751544
0.8286047251522426
0.15726360321301575
0.2714849683542949
0.5712514284326893
1
1
0.6461219406157481
5.556735066875801
0.9475801878667874
0.4936908827545176
1.4418699334614764
1.030161657701656
""",
    },
    {
        "n": "08",
        "slug": "jumping",
        "name": "jumping ahead",
        "kick": "jumping",
        "prose": """
<p>Counter-based generators can be moved instead of drawn. <code>advance</code>
adds to the counter, and <code>jump</code> sends a shift-register generator a
fixed distance along its own cycle by the polynomial its authors published — two
hundred bits ahead for <code>long_jump</code>. Both cost a fixed handful of
operations, however far they move.</p>
<p>That is how one seed becomes many streams: seed once, then jump each worker
into its own stretch of the cycle, where the stretches do not overlap.</p>
""",
        "code": """
let r = @xoshiro.Xoshiro256ss::new(b"streams")
r.jump()
println(@moonrand.randint(r, 0L, 999L))
let c = @moonrand.seeded(b"streams")
c.advance(1000000UL)
println(@moonrand.randint(c, 0L, 999L))
""",
        "out": """
869
800
""",
    },
    {
        "n": "09",
        "slug": "entropy",
        "name": "when it must not repeat",
        "kick": "entropy",
        "prose": """
<p>Everything so far is reproducible on purpose. For a run that should not repeat
— a session id, a jitter, a salt — ask the platform for the seed instead:
<code>@auto.rng()</code> takes thirty-two bytes from the operating system through
moonseed and hands them to the same generator.</p>
<p>It raises when there is no entropy source, rather than falling back to a clock
or a constant. A machine that cannot give you randomness is a thing you want to
hear about. On wasm-gc, where the host decides whether a source exists, that
error is expected.</p>
<p>The block below prints <code>true</code> on every run; the number it drew on
the way is different each time, which is the point.</p>
""",
        "code": """
let rng = @auto.rng() catch { _ => return }
let roll = @moonrand.randint(rng, 0L, 999L)
println(roll >= 0L && roll <= 999L)
""",
        "out": """
true
""",
    },
    {
        "n": "10",
        "slug": "own",
        "name": "writing your own",
        "kick": "your own",
        "prose": """
<p>The contract is three methods, and only one of them has to be written:
<code>next_u64</code>. <code>next_u32</code> and <code>fill</code> follow from it,
and so does everything above — the sampling, the distributions, the lot.</p>
<p>State lives in the type, so a struct with a <code>mut</code> field is enough.
Add <code>impl Seeded for Counter</code> to rebuild it from a seed, and
<code>impl Secure</code> only when the output is fit for cryptography: Philox and
PCG pass statistical tests and are not.</p>
""",
        "code": [
            """
struct Counter {
  mut n : UInt64
}

impl @contract.Rng for Counter with fn next_u64(self) -> UInt64 {
  self.n = self.n + 1UL
  self.n * 6364136223846793005UL
}
""",
            """
let mine : Counter = { n: 0UL }
println(@moonrand.randint(mine, 0L, 9L))
println(@moonrand.random(mine))
""",
        ],
        "out": """
7
0.38000206397767744
""",
    },
]


def esc(text: str) -> str:
    return html.escape(text, quote=False)


def code_block(code: str) -> str:
    body = code.strip("\n")
    return f'<pre class="gcode"><code>{esc(body)}</code></pre>'


def out_block(out: str, note: str | None) -> str:
    body = out.strip("\n")
    head = f'<span class="out__k">{note}</span>' if note else '<span class="out__k">prints</span>'
    return f'<div class="out">{head}<pre>{esc(body)}</pre></div>'


def render() -> str:
    body: list[str] = []
    for sec in SECTIONS:
        prose = sec["prose"].strip()
        note = sec.get("note")
        body.append(f'  <section class="gx" id="{sec["slug"]}">')
        body.append(f'    <p class="kicker">step {sec["n"]}</p>')
        body.append(f'    <h2>{esc(sec["name"])}<small>{esc(sec["slug"])}</small></h2>')
        body.append(f'    <div class="gx__prose">\n{prose}\n    </div>')
        body.append("    <figure class=\"run\">")
        code = sec["code"] if isinstance(sec["code"], list) else [sec["code"]]
        for chunk in code:
            body.append("      " + code_block(chunk))
        body.append("      " + out_block(sec["out"], note))
        body.append("    </figure>")
        body.append("  </section>")
    return "\n".join(body)


def toc() -> str:
    out = ['    <nav class="guide__toc" aria-label="contents">',
           '      <p class="ref__sideh">contents</p>',
           "      <ol>"]
    for sec in SECTIONS:
        out.append(f'        <li><a href="#{sec["slug"]}"><i>{sec["n"]}</i>{esc(sec["name"])}</a></li>')
    out.append("      </ol>")
    out.append("    </nav>")
    return "\n".join(out)


def version() -> str:
    text = (ROOT / "moon.mod").read_text(encoding="utf-8")
    return re.search(r'^version = "(.*)"', text, re.M).group(1)


def page() -> str:
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>moonrand — the guide</title>
<meta name="description" content="A walk through moonrand: from a seed to a distribution, ten steps, each with the output it prints.">
<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' fill='%23F7F5ED'/%3E%3Ccircle cx='16' cy='16' r='11' fill='none' stroke='%231E3A5C' stroke-width='1.2'/%3E%3Ccircle cx='16' cy='16' r='4' fill='%23A83A2B'/%3E%3C/svg%3E">
<link rel="stylesheet" href="site.css">
</head>
<body class="page-guide">
<div class="sheet">

  <header class="bar">
    <div><b>moonrand</b> <span class="bar__v"><span id="rev-value">{version()}</span> · Apache-2.0</span></div>
    <div class="r">
      <a href="https://moonbitstack.github.io/moonseed/">moonseed · entropy</a>
      <a href="index.html">overview</a>
      <a href="guide.html" aria-current="page">guide</a>
      <a href="api.html">api</a>
      <a href="index.html#plates">demo</a>
      <a href="index.html#limits">limits</a>
      <a href="https://github.com/moonbitstack/moonrand">GitHub</a>
    </div>
  </header>

  {band()}

  <main class="guide">
{toc()}
    <article class="guide__body">
      <div class="guide__top">
        <p class="kicker">guide</p>
        <h1 class="ref__t">From a seed to a distribution<small>ten steps</small></h1>
        <p class="ref__lede">Every block below was run against this version, and the
        line under it is what it printed. Read it in order, or take the section you
        came for.</p>
      </div>
{render()}
      <p class="guide__end"><a href="api.html">The reference lists every item →</a></p>
    </article>
  </main>

  <footer class="foot">
    <div class="wrap">
      <div class="foot__row">
        <div><span class="seal">掷</span></div>
        <div class="foot__meta">
          <b>moonrand · Apache-2.0</b>
          <a href="https://github.com/moonbitstack/moonrand">github.com/moonbitstack/moonrand</a><br>
          <span>the blocks compile · the output was run</span>
        </div>
        <div class="foot__next">
          <span>next</span>
          <a href="api.html">the reference</a>
        </div>
      </div>
    </div>
  </footer>

</div>
<script src="site.js"></script>
</body>
</html>
"""


def main() -> int:
    fresh = page()
    if "--check" in sys.argv:
        if not PAGE.exists() or PAGE.read_text(encoding="utf-8") != fresh:
            print("docs/guide.html is stale: run python scripts/gen_guide.py", file=sys.stderr)
            return 1
        print(f"docs/guide.html: {len(SECTIONS)} sections")
        return 0
    with open(PAGE, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(fresh)
    print(f"wrote docs/guide.html: {len(SECTIONS)} sections")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
