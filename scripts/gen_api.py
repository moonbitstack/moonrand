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

# The algorithm subpackages and the distributions above are appended rather
# than hand-ordered: their rows follow the order of the packages below.
ROWS += [
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "gammavariate",
        "sig": ["gammavariate(rng : R, alpha : Double, beta : Double) -> Double"],
        "zh": "伽马一取，Marsaglia–Tsang 之法：形为 alpha，尺度为 beta。",
        "en": "One gamma draw by Marsaglia-Tsang: shape alpha, scale beta.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "betavariate",
        "sig": ["betavariate(rng : R, alpha : Double, beta : Double) -> Double"],
        "zh": "贝塔一取：两回伽马相除，落在 (0, 1)。",
        "en": "One beta draw: two gamma draws, one over their sum, in (0, 1).",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "poisson",
        "sig": ["poisson(rng : R, mu : Double) -> Int64"],
        "zh": "泊松一取，均值为 mu。小均值用乘法，大均值用变换拒绝，各走各的快路。",
        "en": "One Poisson draw with mean mu: multiplication below thirty, transformed rejection above it.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "binomialvariate",
        "sig": ["binomialvariate(rng : R, n : Int64, p : Double) -> Int64"],
        "zh": "n 次试验里成功几次，每次成功率为 p。逐项反演，非近似。",
        "en": "The number of successes in n trials of probability p, by inverting the distribution term by term.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "triangular",
        "sig": ["triangular(rng : R, low~ : Double = 0.0, high~ : Double = 1.0, mode? : Double) -> Double"],
        "zh": "三角一取，峰在 mode；不给则居正中。",
        "en": "One triangular draw peaking at mode, the midpoint when it is not given.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "vonmisesvariate",
        "sig": ["vonmisesvariate(rng : R, mu : Double, kappa : Double) -> Double"],
        "zh": "圆上的一取，均角为 mu，聚集为 kappa；角度落在 [0, 2π)。",
        "en": "One draw on the circle, mean angle mu, concentration kappa, in [0, 2 pi).",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "paretovariate",
        "sig": ["paretovariate(rng : R, alpha : Double) -> Double"],
        "zh": "帕累托一取，形为 alpha；长尾，却没有上界。",
        "en": "One Pareto draw of shape alpha: a long tail with no upper bound.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "weibullvariate",
        "sig": ["weibullvariate(rng : R, alpha : Double, beta : Double) -> Double"],
        "zh": "威布尔一取，尺度 alpha，形 beta。",
        "en": "One Weibull draw, scale alpha, shape beta.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "normalvariate",
        "sig": ["normalvariate(rng : R, mu~ : Double = 0.0, sigma~ : Double = 1.0) -> Double"],
        "zh": "正态一取，Kinderman–Monahan 的比值法；种子同而流与 gauss 不同。",
        "en": "One normal draw by Kinderman-Monahan; the same seed gives a different stream than gauss.",
    },
    {
        "pkg": "moonbitstack/moonrand/chacha",
        "kind": "fn",
        "key": "ChaCha12::advance",
        "sig": ["pub fn ChaCha12::advance(self : ChaCha12, n : UInt64) -> Unit"],
        "zh": "向前跳 n 个 64 位字：只动计数器，不逐个生成。",
        "en": "Skip n 64-bit words by moving the counter, not by drawing them.",
    },
    {
        "pkg": "moonbitstack/moonrand/chacha",
        "kind": "fn",
        "key": "ChaCha8::advance",
        "sig": ["pub fn ChaCha8::advance(self : ChaCha8, n : UInt64) -> Unit"],
        "zh": "同 ChaCha12：跳 n 个字。",
        "en": "As ChaCha12: skip n words.",
    },
    {
        "pkg": "moonbitstack/moonrand/chacha",
        "kind": "fn",
        "key": "ChaCha20::advance",
        "sig": ["pub fn ChaCha20::advance(self : ChaCha20, n : UInt64) -> Unit"],
        "zh": "同 ChaCha12：跳 n 个字。",
        "en": "As ChaCha12: skip n words.",
    },
    {
        "pkg": "moonbitstack/moonrand/auto",
        "kind": "fn",
        "key": "rng",
        "sig": ["pub fn rng() -> @moonrand.StdRng raise @moonseed.Unavailable"],
        "zh": "一次导入，一次调用：向平台要三十二字节，交与默认生成器。无熵则 raise。",
        "en": "One import, one call: ask the platform for 32 bytes and hand them to the default generator. No entropy, no stream.",
    },
    {
        "pkg": "moonbitstack/moonrand/bits",
        "kind": "fn",
        "key": "mix64",
        "sig": ["pub fn mix64(z : UInt64) -> UInt64"],
        "zh": "SplitMix64 的收尾函数：三段异或移位，两个奇乘子，字字对应。",
        "en": "The SplitMix64 finalizer: three shifted xors and two odd multipliers, one word to one word.",
    },
    {
        "pkg": "moonbitstack/moonrand/bits",
        "kind": "fn",
        "key": "mul_hi",
        "sig": ["pub fn mul_hi(a : UInt64, b : UInt64) -> UInt64"],
        "zh": "两字相乘的高半，不用 128 位类型：拆成四个半字再进位。",
        "en": "The high half of a 64-bit product, without a 128-bit type: four half-word products and a carry.",
    },
    {
        "pkg": "moonbitstack/moonrand/bits",
        "kind": "fn",
        "key": "mul_wide",
        "sig": ["pub fn mul_wide(a : UInt64, b : UInt64) -> (UInt64, UInt64)"],
        "zh": "两字相乘的两半，低半在前。",
        "en": "Both halves of a 64-bit product, low half first.",
    },
    {
        "pkg": "moonbitstack/moonrand/bits",
        "kind": "fn",
        "key": "seed_words",
        "sig": ["pub fn seed_words(seed : BytesView, n : Int32) -> FixedArray[UInt64]"],
        "zh": "把一串字节摊成 n 个状态字：先折进 SplitMix64，再往前跑。每一字节都算数。",
        "en": "Turn a seed into n state words: fold the bytes into SplitMix64, then run it forward. Every byte counts.",
    },
]


# --------------------------------------------------------------------------
# The algorithm subpackages. Their rows are built from the compiler's own
# signatures rather than typed out: one row per public item, with the type's
# one-line description and the method's, so a new method cannot slip into the
# package without a line on the page.
# --------------------------------------------------------------------------
GEN_PKGS = [
    "moonbitstack/moonrand/chacha",
    "moonbitstack/moonrand/xoshiro",
    "moonbitstack/moonrand/pcg",
    "moonbitstack/moonrand/mt",
    "moonbitstack/moonrand/splitmix",
    "moonbitstack/moonrand/sfc",
    "moonbitstack/moonrand/jsf",
    "moonbitstack/moonrand/xorshift",
    "moonbitstack/moonrand/well",
    "moonbitstack/moonrand/lcg",
    "moonbitstack/moonrand/chaos",
    "moonbitstack/moonrand/lfsr",
    "moonbitstack/moonrand/fib",
    "moonbitstack/moonrand/mrg",
    "moonbitstack/moonrand/lxm",
    "moonbitstack/moonrand/philox",
    "moonbitstack/moonrand/threefry",
    "moonbitstack/moonrand/squares",
    "moonbitstack/moonrand/classic",
]

TYPE_DOC = {
    "ChaCha8": ("Eight rounds of ChaCha; fastest, narrowest margin.", "八轮 ChaCha，最快，余量最小。"),
    "ChaCha12": ("Twelve rounds, the library's default.", "十二轮，本库之默认。"),
    "ChaCha20": ("Twenty rounds, the RFC's count.", "二十轮，RFC 之数。"),
    "Xoshiro256ss": ("A 256-bit state, a scrambled product as the output.", "二百五十六位状态，输出为打散之积。"),
    "Xoshiro256pp": ("A 256-bit state, a rotated sum as the output.", "二百五十六位状态，输出为旋转之和。"),
    "Xoshiro256p": ("A 256-bit state, an addition as the output.", "二百五十六位状态，输出为两字相加。"),
    "Xoshiro512ss": ("The 512-bit form of xoshiro256**.", "xoshiro256** 之五百一十二位形。"),
    "Xoshiro512pp": ("The 512-bit form of xoshiro256++.", "xoshiro256++ 之五百一十二位形。"),
    "Xoshiro512p": ("The 512-bit form of xoshiro256+.", "xoshiro256+ 之五百一十二位形。"),
    "Xoroshiro128p": ("Two words of state, an addition as the output.", "两字状态，输出为相加。"),
    "Xoroshiro128pp": ("Two words of state, a rotated sum as the output.", "两字状态，输出为旋转之和。"),
    "Xoroshiro128ss": ("Two words of state, a scrambled product as the output.", "两字状态，输出为打散之积。"),
    "Pcg32": ("A 64-bit LCG, 32 bits of permuted output.", "六十四位线性同余，取三十位打散之输出。"),
    "Pcg64": ("A 128-bit LCG with the XSL-RR permutation.", "百二十八位线性同余，XSL-RR 置换。"),
    "Pcg64Dxsm": ("A 128-bit LCG with the double-xorshift-multiply output.", "百二十八位线性同余，双异或乘置换。"),
    "MT19937": ("The 32-bit Mersenne Twister.", "三十二位梅森旋转。"),
    "MT19937_64": ("The 64-bit Mersenne Twister.", "六十四位梅森旋转。"),
    "SplitMix64": ("A counter through the SplitMix64 finalizer.", "以计数器过 SplitMix64 收尾。"),
    "Sfc64": ("Three words and a counter, added and shifted.", "三字与一计数，相加再移位。"),
    "Jsf64": ("Jenkins' small fast generator: four words, one rotate.", "四字、一次旋转，Jenkins 的小快生成器。"),
    "Xorshift32": ("One 32-bit word, three xorshifts.", "一字，三次异或移位。"),
    "Xorshift64": ("One 64-bit word, three xorshifts.", "一长字，三次异或移位。"),
    "Xorshift128": ("Four 32-bit words, the original 128-bit xorshift.", "四字，最初的百二十八位形。"),
    "Xorshift128Plus": ("Two 64-bit words, their sum as the output.", "两长字，输出为相加。"),
    "Xorwow": ("Xorshift128 with a Weyl increment added.", "异或移位再叠一个 Weyl 增量。"),
    "Well512": ("Sixteen words, period 2^512-1.", "十六字，周期 2^512-1。"),
    "Lcg64": ("A linear congruential generator modulo 2^64.", "模 2^64 之线性同余。"),
    "Lcg48": ("The 48-bit recurrence behind drand48.", "drand48 之四十八位递推。"),
    "MinStd": ("16807 modulo 2^31-1, the minimal standard.", "16807 模 2^31-1，最小标准。"),
    "Qcg64": ("x := a x^2 + c, rotated as it leaves.", "x := a x² + c，出时旋转半字。"),
    "Ccg64": ("x := a x^3 + b x^2 + c, rotated as it leaves.", "x := a x³ + b x² + c，出时旋转半字。"),
    "Icg32": ("x := a x^-1 + c over the prime 2^32-5.", "x := a x⁻¹ + c，模素数 2^32-5。"),
    "Logistic": ("x := r x (1 - x).", "x := r x (1 - x)。"),
    "Tent": ("The tent map, folded at one half.", "帐篷映射，半处折返。"),
    "Sine": ("x := sin(pi x).", "x := sin(π x)。"),
    "Chebyshev": ("x := cos(n acos x).", "x := cos(n arccos x)。"),
    "Lfsr64": ("A 64-bit Galois shift register.", "六十四位 Galois 移位寄存器。"),
    "Gfsr": ("Generalized feedback over 250 words.", "二百五十字的广义反馈。"),
    "Taus88": ("Three Tausworthe registers, xored.", "三个 Tausworthe 寄存器异或。"),
    "Lfsr113": ("Four linear feedback registers, period near 2^113.", "四个线性反馈寄存器，周期近 2^113。"),
    "Lfsr258": ("Five linear feedback registers over 64-bit words.", "五个六十四位线性反馈寄存器。"),
    "AdditiveCongruential": ("x(n) = x(n-55) + x(n-24).", "x(n) = x(n-55) + x(n-24)。"),
    "LaggedFibonacci": ("The same recurrence with lags 607 and 273.", "同为滞后递推，取 607 与 273。"),
    "AddWithCarry": ("Lag 55 addition with a carry bit.", "滞后 55 的加法，带进位。"),
    "SubtractWithBorrow": ("Lag 55 subtraction with a borrow bit.", "滞后 55 的减法，带借位。"),
    "Ranlux24": ("Subtract-with-borrow over 24-bit words, discarding most.", "二十四位字之借位减法，弃其大半。"),
    "Ranlux48": ("The same over 48-bit words.", "同为借位减法，取四十八位字。"),
    "Mrg32k3a": ("Two order-three recurrences over primes, subtracted.", "两个三阶素数递推相减。"),
    "L64X128": ("A 64-bit LCG added to xoroshiro128+.", "六十四位线性同余与 xoroshiro128+ 相加。"),
    "L64X256": ("A 64-bit LCG added to xoshiro256+.", "六十四位线性同余与 xoshiro256+ 相加。"),
    "Philox4x32": ("Four 32-bit counter words, ten rounds.", "四个三十二位计数器字，十轮。"),
    "Philox4x64": ("The same round over 64-bit words.", "同样的轮，取六十四位字。"),
    "Threefry4x64": ("Four 64-bit counter words, twenty rounds, no multiply.", "四个六十四位字，二十轮，不用乘法。"),
    "Threefry4x32": ("The same schedule over 32-bit words.", "同样的轮序，取三十二位字。"),
    "Threefry2x64": ("Two counter words, thirteen rounds.", "两个字，十三轮。"),
    "Squares": ("A keyed counter through three rounds of squaring.", "带密钥的计数器，过三轮平方。"),
    "MiddleSquare": ("Square the word, keep the middle bits.", "平方取中。"),
    "MiddleProduct": ("Multiply by a constant, keep the middle bits.", "乘常数取中。"),
    "MiddleSquareWeyl": ("Middle square plus a Weyl sequence.", "平方取中加 Weyl 序列。"),
    "CollatzWeyl": ("The Collatz map xored with a Weyl sequence.", "Collatz 映射与 Weyl 序列异或。"),
    "Bbs": ("The square modulo a Blum integer.", "模 Blum 整数之平方。"),
    "Sfmt19937": ("The SIMD-oriented Fast Mersenne Twister.", "面向 SIMD 的快速梅森旋转。"),
    "Well1024": ("Thirty-two words, period 2^1024-1.", "三十二字，周期 2^1024-1。"),
}

ITEM_DOC = {
    "new": ("Seed it: the bytes go through SplitMix64, a short seed padded.", "以种子起笔：字节过 SplitMix64，短则补零。"),
    "from_state": ("Start from a state you already have, unchanged.", "以已有之状态起笔，一字不改。"),
    "with_state": ("Start from a state you already have, unchanged.", "以已有之状态起笔，一字不改。"),
    "with_params": ("Start from the parameters and a seed.", "以参数与种子起笔。"),
    "with_key": ("Start from a key, with the counter at zero.", "以密钥起笔，计数器归零。"),
    "with_stream": ("Start where the reference seeding puts it.", "按参考之播种法起笔。"),
    "with_word": ("Start from one word, the reference seeding.", "以一字起笔，即参考之播种。"),
    "from_array": ("Start from a key array, the reference seeding.", "以键数组起笔，即参考之播种。"),
    "glibc": ("The parameters the C library uses.", "C 库所用之参数。"),
    "numerical_recipes": ("The parameters Numerical Recipes prints.", "Numerical Recipes 所载之参数。"),
    "jump": ("A fixed distance ahead, by the reference polynomial.", "按参考多项式向前一跳。"),
    "long_jump": ("Further ahead than jump, the same way.", "比 jump 更远的一跳，法同。"),
    "advance": ("Skip n draws without making them.", "跳过 n 次，不真取。"),
    "next_u64": ("The contract's draw: one 64-bit word.", "契约之取：一长字。"),
    "next_u32": ("The contract's draw: one 32-bit word.", "契约之取：一字。"),
    "fill": ("Fill a byte array from the stream.", "以流填一段字节。"),
    "from_seed": ("Rebuild from a seed of seed_size bytes.", "以 seed_size 字节之种子重建。"),
    "seed_size": ("How many bytes a seed is.", "种子几何字节。"),
}


def generated_rows(taken: set[str]) -> list[dict]:
    """One row per public item of the algorithm subpackages."""
    rows: list[dict] = []
    for pkg in GEN_PKGS:
        path = ROOT / "src" / pkg.rsplit("/", 1)[1] / "pkg.generated.mbti"
        if not path.exists():
            continue
        for line in path.read_text(encoding="utf-8").splitlines():
            s = line.strip()
            m = re.match(r"pub struct (\w+)", s)
            if m:
                name = m.group(1)
                if name in taken:
                    continue
                en, zh = TYPE_DOC.get(name, ("A generator.", "一个生成器。"))
                rows.append({"pkg": pkg, "kind": "type", "key": name,
                             "sig": [s], "en": en, "zh": zh})
                continue
            m = re.match(r"pub fn (\w+)::(\w+)\(", s)
            if not m:
                continue
            owner, meth = m.group(1), m.group(2)
            key = f"{owner}::{meth}"
            if key in taken:
                continue
            en, zh = ITEM_DOC.get(meth, ("Part of the generator's surface.", "生成器界面之一。"))
            rows.append({"pkg": pkg, "kind": "fn", "key": key, "sig": [s], "en": en, "zh": zh})
    return rows


ROWS += generated_rows({row["key"] for row in ROWS})

ABSORB = {
    "ChaCha8::equal": "ChaCha8",
    "ChaCha12::equal": "ChaCha12",
    "ChaCha20::equal": "ChaCha20",
}

CN_DIGIT = "零一二三四五六七八九十"


def cn_count(n: int) -> str:
    """Chinese numerals for counts, up to ninety-nine. Arabic digits would
    break the line of a Chinese page: 函数十四, not 函数14."""
    if n < 0:
        return str(n)
    if n <= 10:
        return CN_DIGIT[n]
    if n < 20:
        return "十" + CN_DIGIT[n - 10]
    if n < 100:
        tens, units = divmod(n, 10)
        return CN_DIGIT[tens] + "十" + (CN_DIGIT[units] if units else "")
    return str(n)


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

    # Not Path.write_text: on Windows it truncates before it validates newline,
    # and a ValueError there leaves the page at zero bytes.
    with open(PAGE, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(fresh)
    print(f"wrote docs/index.html: {len(ROWS)} rows for {len(declared)} public items")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
