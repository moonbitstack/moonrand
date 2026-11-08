---
name: moonrand
description: "Seeded pseudo-random numbers in MoonBit: a default generator that needs no configuration, eighteen further algorithm families, and the sampling and distribution functions Python's random names. Reach for it when code needs random integers, reals, shuffles or draws from a named distribution, and when a run has to be replayable from a seed."
---

# moonrand

`moonbitstack/moonrand` draws random numbers. The root package holds the `Rng`
contract, the default generator, the sampling functions and the distributions;
each algorithm family is its own subpackage.

## Install

```text
moon add moonbitstack/moonrand
```

```moonbit
import {
  "moonbitstack/moonrand",
  "moonbitstack/moonrand/auto",
}
```

## Draw from a seed

`seeded` takes any bytes. The same bytes draw the same numbers on native, JS,
wasm and wasm-gc, so a failing run can be replayed exactly.

```moonbit
test {
  let rng = @moonrand.seeded(b"report-2026")
  assert_eq(@moonrand.randint(rng, 1L, 6L), 5L)
  assert_eq(@moonrand.gauss(rng).to_string(), "-1.0397630953614725")
}
```

Sampling takes the generator first and follows Python's names: `randint` is
closed at both ends, `randrange` takes `stop` and excludes it, `choice` returns
`Some` or `None`, and `shuffle` reorders in place.

```moonbit
test {
  let rng = @moonrand.seeded(b"deal")
  let hand = ["A", "K", "Q", "J"]
  assert_eq(@moonrand.choice(rng, hand), Some("A"))
  @moonrand.shuffle(rng, hand)
  assert_eq(hand, ["A", "J", "Q", "K"])
}
```

## Seed from the platform

When the run should not repeat, `@auto.rng()` asks the operating system for
thirty-two bytes. It raises `Unavailable` on a host with no entropy source; it
never falls back to a fixed seed.

```moonbit
test {
  let rng = @auto.rng() catch { _ => return }
  let x = @moonrand.random(rng)
  assert_true(x >= 0.0 && x < 1.0)
}
```

## Choose the algorithm

Every subpackage implements the same contract, so replacing the default changes
one import and nothing else. `StdRng` is ChaCha12; the other families are
xoshiro, PCG, Mersenne Twister, SplitMix64, SFC, JSF, xorshift, WELL, LCG, chaos
maps, LFSR, lagged Fibonacci, MRG, LXM, Philox, Threefry, Squares and the classic
constructions.

```moonbit
test {
  let rng = @xoshiro.Xoshiro256ss::new(b"a seed")
  assert_eq(rng.next_u64(), 17739514199892251868UL)
  rng.jump()
  assert_eq(rng.next_u64(), 4799447535634282370UL)
}
```

Import the subpackage you named: `"moonbitstack/moonrand/xoshiro"` for
`@xoshiro`, `"moonbitstack/moonrand/pcg"` for `@pcg`, and so on.

## Rules that catch people out

- A draw advances the generator you pass, even though the functions take it by
  value. Two calls with the same generator give two different numbers, and there
  is no way to ask for the same one twice — build a fresh generator from the seed
  instead.
- `gauss` and `normalvariate` are two algorithms, not two names for one. Swapping
  them changes the stream, so a recorded run no longer reproduces.
- `randint` is closed and `randrange` is half-open. `randint(rng, 1L, 6L)` never
  returns 7; `randrange(rng, 6L)` returns 0 to 5.
- A distribution called with a parameter outside its domain aborts instead of
  returning a plausible-looking number: a non-positive `lambda`, a non-positive
  gamma shape, a negative Poisson mean, `p` outside [0, 1].
- Only types marked `Secure` are fit for keys and tokens. ChaCha carries the
  marker; Philox, PCG and the rest pass statistical tests and do not. For secrets,
  take the bytes from `moonbitstack/moonseed` and use `seeded` on them, or use
  moonseed directly.
- `jump` and `long_jump` move the state by a fixed number of draws without
  generating the words in between, which is what makes parallel streams cheap.
  `advance(n)` does the same for the counter-based generators.
