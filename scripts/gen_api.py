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
        "zh": "从三十二字节开始。字节相同，流就相同；四个后端上逐位一致。",
        "en": "Start from thirty-two bytes. The same bytes give the same stream, bit for bit on all four backends.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "random",
        "sig": ["random(rng : R) -> Double"],
        "zh": "[0, 1) 之间的实数，五十三位精度，取法与 Python 的 random() 相同。",
        "en": "A real in [0, 1) with exactly fifty-three bits, the same draw as Python's random().",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "uniform",
        "sig": ["uniform(rng : R, low : Double, high : Double) -> Double"],
        "zh": "[low, high) 上的均匀实数。low 比 high 大也照收，两端自行调换。",
        "en": "Anywhere in [low, high), equally thick. Reversed ends are taken as given.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "randint",
        "sig": ["randint(rng : R, low : Int64, high : Int64) -> Int64"],
        "zh": "闭区间 [low, high] 上的整数。high 小于 low 时原样返回 low。",
        "en": "An integer, both ends included. A high below low returns low.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "randrange",
        "sig": ["randrange(rng : R, stop : Int64, start~ : Int64 = 0, step? : Int64) -> Int64"],
        "zh": "左闭右开的整数，起点和步长可选。范围为空或步长为零则中止。",
        "en": "An integer, right end excluded, with an optional start and step. An empty range or a zero step aborts.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "getrandbits",
        "sig": ["getrandbits(rng : R, k : Int32) -> UInt64"],
        "zh": "取低 k 位。k 超过 64 时返回整个字。",
        "en": "The low k bits, not one more. Above sixty-four, the whole word comes back.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "choice",
        "sig": ["choice(rng : R, items : ArrayView[T]) -> T?"],
        "zh": "从中抽一个；数组为空则返回 None，不凭空造一个。",
        "en": "Take one, or None when there is nothing to take.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "choices",
        "sig": ["choices(rng : R, items : ArrayView[T], k~ : Int32 = 1, weights? : ArrayView[Double]) -> Array[T]"],
        "zh": "有放回地抽 k 次；给了权重就按权重抽，权重全为零视同未给。",
        "en": "Take k with replacement; give weights and the draws follow them. All-zero weights are read as none.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "sample",
        "sig": ["sample(rng : R, items : ArrayView[T], k : Int32) -> Array[T]"],
        "zh": "不放回地抽 k 个，互不重复。k 超过元素个数时全部取出。",
        "en": "Take k without replacement, no repeats. A k past the end takes all of them.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "shuffle",
        "sig": ["shuffle(rng : R, a : Array[T]) -> Unit"],
        "zh": "就地打乱顺序，元素一个不少。",
        "en": "Shuffle in place. Every element stays, no position does.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "gauss",
        "sig": ["gauss(rng : R, mu~ : Double = 0.0, sigma~ : Double = 1.0) -> Double"],
        "zh": "一次正态抽样，Box–Muller 法；均值为 mu，标准差为 sigma。",
        "en": "One normal draw by Box–Muller, centred on mu, as wide as sigma.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "expovariate",
        "sig": ["expovariate(rng : R, lambd : Double) -> Double"],
        "zh": "一次指数抽样，比率为 lambda，均值为其倒数。lambda 不为正时中止。",
        "en": "One exponential draw at rate lambda, mean its reciprocal. A non-positive rate aborts.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "lognormvariate",
        "sig": ["lognormvariate(rng : R, mu~ : Double = 0.0, sigma~ : Double = 1.0) -> Double"],
        "zh": "一次对数正态抽样：先取正态，再取指数。",
        "en": "One lognormal draw: a normal draw, exponentiated.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "alias",
        "key": "StdRng",
        "sig": ["pub type StdRng = @chacha.ChaCha12"],
        "zh": "默认生成器的别名。换掉这一行，全库的默认算法随之改变。",
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
        "zh": "所有生成器共守的约定：交出均匀的机器字。自己实现 next_u64 即可，另外两个方法有默认实现。",
        "en": "The contract every generator keeps: uniform machine words. Only next_u64 is yours to write; the other two have defaults.",
    },
    {
        "pkg": "moonbitstack/moonrand/contract",
        "kind": "trait",
        "key": "Secure",
        "sig": ["pub(open) trait Secure : Rng {}"],
        "zh": "标记「可用于密码学」。Philox 和 PCG 的统计性质尚可，但不带这个标记。",
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
        "zh": "能从种子重建的生成器，用于复现同一次运行。种子长度由 seed_size 说明。",
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
        "zh": "八轮 ChaCha：最快，安全余量也最小，适合不涉及密钥的场合。",
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
        "zh": "十二轮，默认选择：在速度与安全余量之间折中。",
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
        "zh": "二十轮，即 RFC 8439 的轮数：安全余量最大，速度最慢。",
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
        "zh": "一次伽马抽样，Marsaglia–Tsang 法；形状为 alpha，尺度为 beta。",
        "en": "One gamma draw by Marsaglia-Tsang: shape alpha, scale beta.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "betavariate",
        "sig": ["betavariate(rng : R, alpha : Double, beta : Double) -> Double"],
        "zh": "一次贝塔抽样：两个伽马相除，结果落在 (0, 1)。",
        "en": "One beta draw: two gamma draws, one over their sum, in (0, 1).",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "poisson",
        "sig": ["poisson(rng : R, mu : Double) -> Int64"],
        "zh": "一次泊松抽样，均值为 mu。均值小时走乘法，均值大时走变换拒绝，各走各的快路。",
        "en": "One Poisson draw with mean mu: multiplication below thirty, transformed rejection above it.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "binomialvariate",
        "sig": ["binomialvariate(rng : R, n : Int64, p : Double) -> Int64"],
        "zh": "n 次独立试验里的成功次数，单次成功率为 p。逐项反演，不做近似。",
        "en": "The number of successes in n trials of probability p, by inverting the distribution term by term.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "triangular",
        "sig": ["triangular(rng : R, low~ : Double = 0.0, high~ : Double = 1.0, mode? : Double) -> Double"],
        "zh": "一次三角分布抽样，峰在 mode；不给则取中点。",
        "en": "One triangular draw peaking at mode, the midpoint when it is not given.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "vonmisesvariate",
        "sig": ["vonmisesvariate(rng : R, mu : Double, kappa : Double) -> Double"],
        "zh": "圆周上的一次抽样，平均角为 mu，聚集度为 kappa，结果在 [0, 2π) 内。",
        "en": "One draw on the circle, mean angle mu, concentration kappa, in [0, 2 pi).",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "paretovariate",
        "sig": ["paretovariate(rng : R, alpha : Double) -> Double"],
        "zh": "一次帕累托抽样，形状参数 alpha；尾部很长，没有上界。",
        "en": "One Pareto draw of shape alpha: a long tail with no upper bound.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "weibullvariate",
        "sig": ["weibullvariate(rng : R, alpha : Double, beta : Double) -> Double"],
        "zh": "一次威布尔抽样，尺度为 alpha，形状为 beta。",
        "en": "One Weibull draw, scale alpha, shape beta.",
    },
    {
        "pkg": "moonbitstack/moonrand",
        "kind": "fn",
        "key": "normalvariate",
        "sig": ["normalvariate(rng : R, mu~ : Double = 0.0, sigma~ : Double = 1.0) -> Double"],
        "zh": "一次正态抽样，Kinderman–Monahan 比值法。同一个种子，走势与 gauss 不同。",
        "en": "One normal draw by Kinderman-Monahan; the same seed gives a different stream than gauss.",
    },
    {
        "pkg": "moonbitstack/moonrand/chacha",
        "kind": "fn",
        "key": "ChaCha12::advance",
        "sig": ["pub fn ChaCha12::advance(self : ChaCha12, n : UInt64) -> Unit"],
        "zh": "向前跳 n 个 64 位字：只移动计数器，不逐个生成。",
        "en": "Skip n 64-bit words by moving the counter, not by drawing them.",
    },
    {
        "pkg": "moonbitstack/moonrand/chacha",
        "kind": "fn",
        "key": "ChaCha8::advance",
        "sig": ["pub fn ChaCha8::advance(self : ChaCha8, n : UInt64) -> Unit"],
        "zh": "与 ChaCha12 相同：向前跳 n 个字。",
        "en": "As ChaCha12: skip n words.",
    },
    {
        "pkg": "moonbitstack/moonrand/chacha",
        "kind": "fn",
        "key": "ChaCha20::advance",
        "sig": ["pub fn ChaCha20::advance(self : ChaCha20, n : UInt64) -> Unit"],
        "zh": "与 ChaCha12 相同：向前跳 n 个字。",
        "en": "As ChaCha12: skip n words.",
    },
    {
        "pkg": "moonbitstack/moonrand/auto",
        "kind": "fn",
        "key": "rng",
        "sig": ["pub fn rng() -> @moonrand.StdRng raise @moonseed.Unavailable"],
        "zh": "一次导入，一次调用：向平台要三十二字节，交给默认生成器。取不到熵时 raise。",
        "en": "One import, one call: ask the platform for 32 bytes and hand them to the default generator. No entropy, no stream.",
    },
    {
        "pkg": "moonbitstack/moonrand/bits",
        "kind": "fn",
        "key": "mix64",
        "sig": ["pub fn mix64(z : UInt64) -> UInt64"],
        "zh": "SplitMix64 的收尾函数：三段异或移位，两个奇乘子，输入输出各一个字。",
        "en": "The SplitMix64 finalizer: three shifted xors and two odd multipliers, one word to one word.",
    },
    {
        "pkg": "moonbitstack/moonrand/bits",
        "kind": "fn",
        "key": "mul_hi",
        "sig": ["pub fn mul_hi(a : UInt64, b : UInt64) -> UInt64"],
        "zh": "求两个字相乘的高半，不依赖 128 位类型：拆成四个半字再处理进位。",
        "en": "The high half of a 64-bit product, without a 128-bit type: four half-word products and a carry.",
    },
    {
        "pkg": "moonbitstack/moonrand/bits",
        "kind": "fn",
        "key": "mul_wide",
        "sig": ["pub fn mul_wide(a : UInt64, b : UInt64) -> (UInt64, UInt64)"],
        "zh": "两个字相乘的两半，低半在前。",
        "en": "Both halves of a 64-bit product, low half first.",
    },
    {
        "pkg": "moonbitstack/moonrand/bits",
        "kind": "fn",
        "key": "seed_words",
        "sig": ["pub fn seed_words(seed : BytesView, n : Int32) -> FixedArray[UInt64]"],
        "zh": "把种子摊成 n 个状态字：先折进 SplitMix64，再依次往后跑。",
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
    "ChaCha8": ("Eight rounds of ChaCha; fastest, narrowest margin.", "八轮 ChaCha：最快，安全余量也最小。"),
    "ChaCha12": ("Twelve rounds, the library's default.", "十二轮，本库的默认。"),
    "ChaCha20": ("Twenty rounds, the RFC's count.", "二十轮，RFC 8439 的轮数。"),
    "Xoshiro256ss": ("A 256-bit state, a scrambled product as the output.", "256 位状态，输出是两个字的打散乘积。"),
    "Xoshiro256pp": ("A 256-bit state, a rotated sum as the output.", "256 位状态，输出是两个旋转后相加的字。"),
    "Xoshiro256p": ("A 256-bit state, an addition as the output.", "256 位状态，输出是两个相加的字。"),
    "Xoshiro512ss": ("The 512-bit form of xoshiro256**.", "xoshiro256** 的 512 位版本。"),
    "Xoshiro512pp": ("The 512-bit form of xoshiro256++.", "xoshiro256++ 的 512 位版本。"),
    "Xoshiro512p": ("The 512-bit form of xoshiro256+.", "xoshiro256+ 的 512 位版本。"),
    "Xoroshiro128p": ("Two words of state, an addition as the output.", "两个字的状态，输出为两者相加。"),
    "Xoroshiro128pp": ("Two words of state, a rotated sum as the output.", "两个字的状态，输出是旋转后相加。"),
    "Xoroshiro128ss": ("Two words of state, a scrambled product as the output.", "两个字的状态，输出是打散的乘积。"),
    "Pcg32": ("A 64-bit LCG, 32 bits of permuted output.", "64 位线性同余，输出取 32 位再打散。"),
    "Pcg64": ("A 128-bit LCG with the XSL-RR permutation.", "128 位线性同余，XSL-RR 置换。"),
    "Pcg64Dxsm": ("A 128-bit LCG with the double-xorshift-multiply output.", "128 位线性同余，双异或乘置换。"),
    "MT19937": ("The 32-bit Mersenne Twister.", "32 位梅森旋转。"),
    "MT19937_64": ("The 64-bit Mersenne Twister.", "64 位梅森旋转。"),
    "SplitMix64": ("A counter through the SplitMix64 finalizer.", "一个计数器，过 SplitMix64 收尾。"),
    "Sfc64": ("Three words and a counter, added and shifted.", "三个字加一个计数器，相加再移位。"),
    "Jsf64": ("Jenkins' small fast generator: four words, one rotate.", "Jenkins 的小快生成器：四个字，一次旋转。"),
    "Xorshift32": ("One 32-bit word, three xorshifts.", "一个 32 位字，三次异或移位。"),
    "Xorshift64": ("One 64-bit word, three xorshifts.", "一个 64 位字，三次异或移位。"),
    "Xorshift128": ("Four 32-bit words, the original 128-bit xorshift.", "四个字，最早的 128 位 xorshift。"),
    "Xorshift128Plus": ("Two 64-bit words, their sum as the output.", "两个 64 位字，输出为两字相加。"),
    "Xorwow": ("Xorshift128 with a Weyl increment added.", "异或移位，再叠一个 Weyl 增量。"),
    "Well512": ("Sixteen words, period 2^512-1.", "十六个字，周期 2^512-1。"),
    "Lcg64": ("A linear congruential generator modulo 2^64.", "模 2^64 的线性同余。"),
    "Lcg48": ("The 48-bit recurrence behind drand48.", "drand48 用的 48 位递推。"),
    "MinStd": ("16807 modulo 2^31-1, the minimal standard.", "16807 模 2^31-1，最小标准生成器。"),
    "Qcg64": ("x := a x^2 + c, rotated as it leaves.", "x := a x² + c，输出前旋转半个字。"),
    "Ccg64": ("x := a x^3 + b x^2 + c, rotated as it leaves.", "x := a x³ + b x² + c，输出前旋转半个字。"),
    "Icg32": ("x := a x^-1 + c over the prime 2^32-5.", "x := a x⁻¹ + c，模素数 2^32-5。"),
    "Logistic": ("x := r x (1 - x).", "x := r x (1 - x)。"),
    "Tent": ("The tent map, folded at one half.", "帐篷映射，在 0.5 处折返。"),
    "Sine": ("x := sin(pi x).", "x := sin(π x)。"),
    "Chebyshev": ("x := cos(n acos x).", "x := cos(n arccos x)。"),
    "Lfsr64": ("A 64-bit Galois shift register.", "64 位 Galois 移位寄存器。"),
    "Gfsr": ("Generalized feedback over 250 words.", "250 个字上的广义反馈。"),
    "Taus88": ("Three Tausworthe registers, xored.", "三个 Tausworthe 寄存器异或合成。"),
    "Lfsr113": ("Four linear feedback registers, period near 2^113.", "四个线性反馈寄存器，周期接近 2^113。"),
    "Lfsr258": ("Five linear feedback registers over 64-bit words.", "五个 64 位线性反馈寄存器。"),
    "AdditiveCongruential": ("x(n) = x(n-55) + x(n-24).", "x(n) = x(n-55) + x(n-24)。"),
    "LaggedFibonacci": ("The same recurrence with lags 607 and 273.", "同一个递推，滞后取 607 与 273。"),
    "AddWithCarry": ("Lag 55 addition with a carry bit.", "滞后 55 的加法，带进位。"),
    "SubtractWithBorrow": ("Lag 55 subtraction with a borrow bit.", "滞后 55 的减法，带借位。"),
    "Ranlux24": ("Subtract-with-borrow over 24-bit words, discarding most.", "24 位字上的借位减法，大部分输出丢掉。"),
    "Ranlux48": ("The same over 48-bit words.", "同为借位减法，字宽 48 位。"),
    "Mrg32k3a": ("Two order-three recurrences over primes, subtracted.", "两个三阶素数递推相减。"),
    "L64X128": ("A 64-bit LCG added to xoroshiro128+.", "64 位线性同余，与 xoroshiro128+ 相加。"),
    "L64X256": ("A 64-bit LCG added to xoshiro256+.", "64 位线性同余，与 xoshiro256+ 相加。"),
    "Philox4x32": ("Four 32-bit counter words, ten rounds.", "四个 32 位计数器字，十轮。"),
    "Philox4x64": ("The same round over 64-bit words.", "同样的轮数，字宽 64 位。"),
    "Threefry4x64": ("Four 64-bit counter words, twenty rounds, no multiply.", "四个 64 位字，二十轮，不用乘法。"),
    "Threefry4x32": ("The same schedule over 32-bit words.", "同样的轮序，字宽 32 位。"),
    "Threefry2x64": ("Two counter words, thirteen rounds.", "两个字，十三轮。"),
    "Squares": ("A keyed counter through three rounds of squaring.", "带密钥的计数器，每步过三轮平方。"),
    "MiddleSquare": ("Square the word, keep the middle bits.", "平方之后取中。"),
    "MiddleProduct": ("Multiply by a constant, keep the middle bits.", "乘一个常数之后取中。"),
    "MiddleSquareWeyl": ("Middle square plus a Weyl sequence.", "平方取中，再叠一个 Weyl 序列。"),
    "CollatzWeyl": ("The Collatz map xored with a Weyl sequence.", "Collatz 映射与 Weyl 序列异或。"),
    "Bbs": ("The square modulo a Blum integer.", "对 Blum 整数取模做平方。"),
    "Sfmt19937": ("The SIMD-oriented Fast Mersenne Twister.", "面向 SIMD 的快速梅森旋转。"),
    "Well1024": ("Thirty-two words, period 2^1024-1.", "三十二个字，周期 2^1024-1。"),
}

ITEM_DOC = {
    "new": ("Seed it: the bytes go through SplitMix64, a short seed padded.", "以种子初始化：字节经 SplitMix64 展开，种子偏短则补零。"),
    "from_state": ("Start from a state you already have, unchanged.", "直接以给定的状态初始化，不做改动。"),
    "with_state": ("Start from a state you already have, unchanged.", "直接以给定的状态初始化，不做改动。"),
    "with_params": ("Start from the parameters and a seed.", "以参数和种子初始化。"),
    "with_key": ("Start from a key, with the counter at zero.", "以密钥初始化，计数器从零开始。"),
    "with_stream": ("Start where the reference seeding puts it.", "按参考实现的播种方式初始化。"),
    "with_word": ("Start from one word, the reference seeding.", "以一个种子字初始化，即参考实现的播种方式。"),
    "from_array": ("Start from a key array, the reference seeding.", "以键数组初始化，即参考实现的播种方式。"),
    "glibc": ("The parameters the C library uses.", "C 库所用的参数。"),
    "numerical_recipes": ("The parameters Numerical Recipes prints.", "Numerical Recipes 里的参数。"),
    "jump": ("A fixed distance ahead, by the reference polynomial.", "按参考多项式向前跳跃一段。"),
    "long_jump": ("Further ahead than jump, the same way.", "比 jump 跳得更远，方法相同。"),
    "advance": ("Skip n draws without making them.", "跳过 n 次，不逐个真正生成。"),
    "next_u64": ("The contract's draw: one 64-bit word.", "契约要求的一次取值：一个 64 位字。"),
    "next_u32": ("The contract's draw: one 32-bit word.", "契约要求的一次取值：一个 32 位字。"),
    "fill": ("Fill a byte array from the stream.", "用流填满一段字节。"),
    "from_seed": ("Rebuild from a seed of seed_size bytes.", "以 seed_size 字节的种子重建。"),
    "seed_size": ("How many bytes a seed is.", "种子的字节数。"),
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
            en, zh = ITEM_DOC.get(meth, ("Part of the generator's surface.", "生成器接口的一部分。"))
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
    first = {}
    for i, row in enumerate(ROWS):
        first.setdefault(row["pkg"], i)
    for row in sorted(ROWS, key=lambda r: first[r["pkg"]]):
        if row["pkg"] != group:
            if group is not None:
                out.append("        </div>")
                out.append("        </details>")
            # The root package stays open; nineteen generators unfolded would bury the page.
            opened = " open" if group is None else ""
            group = row["pkg"]
            counts: dict[str, int] = {}
            for other in ROWS:
                if other["pkg"] == group:
                    counts[other["kind"]] = counts.get(other["kind"], 0) + 1
            summary = " · ".join(
                f"{n} {COUNT_WORD[k][1] if n > 1 else COUNT_WORD[k][0]}" for k, n in counts.items()
            )
            cn_summary = " · ".join(f"{CN_WORD[k]}{cn_count(n)}" for k, n in counts.items())
            out.append(f'        <details class="ins__pkg"{opened}>')
            out.append(
                f'        <summary class="ins__grp"><span>{html.escape(group)}</span>'
                f'<i data-zh="{cn_summary}">{summary}</i></summary>'
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
        out.append("        </details>")
    return "\n".join(out)


def version_patch(page: str) -> str:
    version = re.search(r'^version = "(.*)"', (ROOT / "moon.mod").read_text(encoding="utf-8"), re.M)
    return re.sub(r'(<(?:b|span) id="rev-value">)[^<]*(</(?:b|span)>)',
                  rf"\g<1>{version.group(1)}\g<2>", page)


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
