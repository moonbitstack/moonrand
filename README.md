<p align="right">
  <a href="https://moonbitstack.github.io/moonrand/">home</a> &nbsp;·&nbsp;
  <a href="https://moonbitstack.github.io/moonrand/#start">guide</a> &nbsp;·&nbsp;
  <a href="https://moonbitstack.github.io/moonrand/#api">api</a> &nbsp;·&nbsp;
  <a href="https://mooncakes.io/docs/moonbitstack/moonrand">mooncakes</a>
</p>

# moonrand

Reproducible pseudo-random numbers: one default generator that needs no
configuration, sixty-two more behind it when the algorithm matters, and the
sampling and distribution functions Python's `random` names.

```moonbit
import {
  "moonbitstack/moonrand",
  "moonbitstack/moonrand/auto",
}
```

```moonbit
test {
  let rng = @moonrand.seeded(b"a seed")
  let roll = @moonrand.randint(rng, 1L, 6L)
  let noise = @moonrand.gauss(rng)
  assert_eq(roll, 5L)
  assert_eq(noise.to_string(), "0.03498079073290354")
}
```

`@moonrand.seeded` takes any bytes you give it. The same bytes always draw the
same numbers, on every backend, so a run that goes wrong can be replayed.

`@auto.rng()` asks the operating system for thirty-two bytes and hands them to
the same generator, for runs that should not repeat:

```moonbit
test {
  let rng = @auto.rng() catch { _ => return }
  let x = @moonrand.random(rng)
  assert_true(x >= 0.0 && x < 1.0)
}
```

A host with no entropy source raises `Unavailable` rather than falling back to a
fixed or clock-derived seed, which would hand out a generator that looks random
and is not.

## The default

| | |
|:--|:--|
| `StdRng` | ChaCha12, a 256-bit stream cipher used as a generator |
| `seeded(bytes)` | a generator over the seed, reproducible |
| `@auto.rng()` | a generator over 32 bytes of platform entropy |

A stream cipher is the default because its output is indistinguishable from
uniform, it carries the `Secure` marker, and seeking a million numbers ahead
costs one addition to its counter. A stream runs for 2^32 blocks of 64 bytes;
past that, seed it again — it never returns to the start on its own.

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
and offers the reference constructor for a state you already have. The words
below are the ones each published algorithm produces from that seed:

```moonbit
test {
  let rng = @xoshiro.Xoshiro256ss::new(b"any number of bytes")
  assert_eq(rng.next_u64(), 3805413477191604227UL)
  assert_eq(rng.next_u64(), 4654090004589171931UL)
}
```

Generators that can jump say so: `jump` and `long_jump` on the xoshiro and LXM
families, `advance` on the counter-based ones — ChaCha, PCG, Philox, Threefry,
Squares, SplitMix64, MRG32k3a. Jumping moves the state forward without drawing
the words in between:

```moonbit
test {
  let rng = @xoshiro.Xoshiro256ss::new(b"any number of bytes")
  rng.jump()
  assert_eq(rng.next_u64(), 1157340615618982128UL)
}
```

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

```moonbit
test {
  let rng = @moonrand.seeded(b"deal")
  let deck = ["A", "K", "Q", "J"]
  assert_eq(@moonrand.choice(rng, deck), Some("A"))
  @moonrand.shuffle(rng, deck)
  assert_eq(deck, ["A", "J", "Q", "K"])
  assert_eq(@moonrand.sample(rng, deck, 2), ["K", "J"])
}
```

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

```moonbit
test {
  let rng = @moonrand.seeded(b"dist")
  assert_eq(@moonrand.gauss(rng).to_string(), "-0.0045334408825839735")
  let other = @moonrand.seeded(b"dist")
  assert_eq(@moonrand.normalvariate(other).to_string(), "0.41874563942799287")
}
```

## Writing your own generator

The contract is three methods, one of which has a body:

```moonbit
struct Counter {
  mut n : UInt64
}

impl @contract.Rng for Counter with fn next_u64(self) -> UInt64 {
  self.n = self.n + 1UL
  self.n * 6364136223846793005UL
}
```

```moonbit
test {
  let rng : Counter = { n: 0UL }
  assert_eq(@moonrand.random(rng).to_string(), "0.3450005159944193")
  assert_eq(@moonrand.randint(rng, 0L, 9L), 7L)
}
```

`next_u32`, `fill` and everything above them follow from `next_u64`. Add
`impl @contract.Seeded for Counter` to rebuild it from a seed, or
`impl @contract.Secure for Counter` when its output is fit for cryptography —
Philox and PCG pass statistical tests and are not, so they do not carry it.

## Licence

Apache-2.0.
