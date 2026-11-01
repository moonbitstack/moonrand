# moonrand

Reproducible pseudo-random numbers: one default generator that needs no
configuration, sixty-three more behind it when the algorithm matters, and the
sampling and distribution functions Python's `random` names.

```moonbit nocheck
import { "moonbitstack/moonrand", "moonbitstack/moonrand/auto" }

fn main {
  let rng = @auto.rng() catch { _ => @moonrand.seeded(b"a fixed seed") }
  let roll = @moonrand.randint(rng, 1L, 6L)
  let noise = @moonrand.gauss(rng, mu=0.0, sigma=1.0)
  println("\{roll} \{noise}")
}
```

`@auto.rng()` asks the operating system for 32 bytes and hands them to the
default generator. On a host without an entropy source it raises
`Unavailable` instead of guessing; `@moonrand.seeded` takes any seed you give
it, and the same seed always draws the same numbers.

## The default

| | |
|:--|:--|
| `StdRng` | ChaCha12, a 256-bit stream cipher used as a generator |
| `seeded(bytes)` | a generator over the seed, reproducible |
| `@auto.rng()` | a generator over 32 bytes of platform entropy |

A stream cipher is the default because its output is indistinguishable from
uniform under a secret key, it carries the `Secure` marker, and seeking a
million numbers ahead costs one addition to its counter.

## Generators

Every subpackage holds one family of algorithms, each type implementing the same
`Rng` contract, so anything that draws from `Rng` works with all of them.

| Package | Types |
|:--|:--|
| `moonrand/chacha` | `ChaCha8`, `ChaCha12`, `ChaCha20` |
| `moonrand/xoshiro` | `Xoshiro256ss`, `Xoshiro256pp`, `Xoshiro256p`, `Xoshiro512ss`, `Xoshiro512pp`, `Xoshiro512p`, `Xoroshiro128p`, `Xoroshiro128pp`, `Xoroshiro128ss` |
| `moonrand/pcg` | `Pcg32`, `Pcg64`, `Pcg64Dxsm` |
| `moonrand/mt` | `MT19937`, `MT19937_64`, `Sfmt19937` |
| `moonrand/splitmix` | `SplitMix64` |
| `moonrand/sfc` | `Sfc64` |
| `moonrand/jsf` | `Jsf64` |
| `moonrand/xorshift` | `Xorshift32`, `Xorshift64`, `Xorshift128`, `Xorshift128Plus`, `Xorwow` |
| `moonrand/well` | `Well512`, `Well1024` |
| `moonrand/lcg` | `Lcg64`, `Lcg48`, `MinStd`, `Qcg64`, `Ccg64`, `Icg32` |
| `moonrand/chaos` | `Logistic`, `Tent`, `Sine`, `Chebyshev` |
| `moonrand/lfsr` | `Lfsr64`, `Gfsr`, `Taus88`, `Lfsr113`, `Lfsr258` |
| `moonrand/fib` | `AdditiveCongruential`, `LaggedFibonacci`, `AddWithCarry`, `SubtractWithBorrow`, `Ranlux24`, `Ranlux48` |
| `moonrand/mrg` | `Mrg32k3a` |
| `moonrand/lxm` | `L64X128`, `L64X256` |
| `moonrand/philox` | `Philox4x32`, `Philox4x64` |
| `moonrand/threefry` | `Threefry4x64`, `Threefry4x32`, `Threefry2x64` |
| `moonrand/squares` | `Squares` |
| `moonrand/classic` | `MiddleSquare`, `MiddleProduct`, `MiddleSquareWeyl`, `CollatzWeyl`, `Bbs` |

Each type takes a seed of the size it announces, expands it through SplitMix64,
and offers the reference constructor for a state you already have:

```moonbit nocheck
import { "moonbitstack/moonrand/xoshiro" }

fn main {
  let rng = @xoshiro.Xoshiro256ss::new(b"any number of bytes")
  let from_state = @xoshiro.Xoshiro256ss::from_state([1UL, 2UL, 3UL, 4UL])
  rng.jump() // 2^128 draws ahead
  from_state.long_jump() // 2^192 ahead
}
```

Generators that can jump say so: `jump` and `long_jump` on the xoshiro and LXM
families, `advance` on the counter-based ones (ChaCha, PCG, Philox, Threefry,
Squares, SplitMix64, MRG32k3a).

## Sampling

Over any `Rng`, with Python's names:

| Function | Draw |
|:--|:--|
| `random(rng)` | a real in [0, 1) with exactly 53 bits |
| `uniform(rng, low, high)` | a real in [low, high) |
| `randint(rng, lo, hi)` | an integer in [lo, hi], closed, unbiased |
| `randrange(rng, stop, start~, step?)` | Python's `randrange` |
| `getrandbits(rng, k)` | the low `k` bits of a word |
| `choice(rng, items)` | one element, or `None` for an empty view |
| `choices(rng, items, k~, weights?)` | `k` elements, in proportion when weighted |
| `sample(rng, items, k)` | `k` distinct elements |
| `shuffle(rng, items)` | the array in place |

`randint` and `randrange` reject out-of-range draws rather than taking a
remainder, so no value is more likely than another, whatever the range.

## Distributions

| Function | Density |
|:--|:--|
| `gauss(rng, mu~, sigma~)` | normal, by Box-Muller |
| `normalvariate(rng, mu~, sigma~)` | normal, by ratio of uniforms |
| `expovariate(rng, lambda)` | exponential with rate `lambda` |
| `lognormvariate(rng, mu~, sigma~)` | log-normal |
| `gammavariate(rng, alpha, beta)` | gamma, Marsaglia-Tsang |
| `betavariate(rng, alpha, beta)` | beta |
| `poisson(rng, mu)` | Poisson, multiplication or transformed rejection |
| `binomialvariate(rng, n, p)` | the count of successes in `n` trials |
| `triangular(rng, low~, high~, mode?)` | triangular |
| `vonmisesvariate(rng, mu, kappa)` | von Mises on the circle |
| `paretovariate(rng, alpha)` | Pareto |
| `weibullvariate(rng, alpha, beta)` | Weibull |

`gauss` and `normalvariate` are two algorithms, not two spellings: they draw
from the same generator differently, and a run that swaps one for the other does
not reproduce.

## Writing your own generator

The contract is three methods, one of which has a body:

```moonbit nocheck
import { "moonbitstack/moonrand/contract", "moonbitstack/moonrand" }

struct Counter {
  priv n : UInt64
}

pub impl @contract.Rng for Counter with fn next_u64(self) -> UInt64 {
  self.n = self.n + 1UL
  self.n * 6364136223846793005UL
}

fn main {
  let rng : Counter = { n: 0UL }
  let x = @moonrand.random(rng)
  println(x)
}
```

`next_u32`, `fill` and everything above them follow. Add
`impl @contract.Seeded for Counter` to rebuild it from a seed, or
`impl @contract.Secure for Counter` when its output is fit for cryptography —
Philox and PCG pass statistical tests and are not, so they do not carry it.

## Licence

Apache-2.0.
