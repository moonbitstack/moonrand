///|
/// Chaotic maps. Each one iterates a continuous map and hands out the bits of
/// the result. They are here to reproduce a map — a logistic sequence, a tent
/// sequence — not to draw numbers for a simulation: a float has 53 bits and a
/// chaotic orbit loses its own entropy, so the stream repeats at a far shorter
/// distance than the state suggests.

///|
/// A double in (0, 1) from a byte seed, kept off the endpoints where the maps
/// are stationary.
fn chaos_start(seed : BytesView) -> Double {
  let w = @bits.seed_words(seed, 1)[0]
  let x = (w >> 11).to_double() / 9007199254740992.0
  if x < 1.0e-9 {
    1.0e-9
  } else if x > 1.0 - 1.0e-9 {
    1.0 - 1.0e-9
  } else {
    x
  }
}

///|
/// The bits of the current orbit point: what a map hands to a generator
/// interface.
fn chaos_word(x : Double) -> UInt64 {
  x.reinterpret_as_uint64()
}

///|
/// Logistic: x := r x (1 - x). The parameters that give a full-looking orbit are
/// r near 4; the map is chaotic there and nowhere else.
pub struct Logistic {
  priv s : FixedArray[Double]
}

///|
/// A generator with the parameter `r` and the starting point `x`.
pub fn Logistic::with_params(r : Double, x : Double) -> Logistic {
  { s: [x, r], }
}

///|
/// A generator seeded from eight bytes, at r = 4.
pub fn Logistic::new(seed : BytesView) -> Logistic {
  Logistic::with_params(4.0, chaos_start(seed))
}

///|
pub impl @contract.Rng for Logistic with fn next_u64(self) -> UInt64 {
  let x = self.s[1] * self.s[0] * (1.0 - self.s[0])
  self.s[0] = x
  chaos_word(x)
}

///|
pub impl @contract.Seeded for Logistic with fn from_seed(seed : BytesView) -> Logistic {
  Logistic::new(seed)
}

///|
pub impl @contract.Seeded for Logistic with fn seed_size() -> Int32 {
  8
}

///|
/// Tent: x := mu x when x < 1/2, mu (1 - x) otherwise; mu near 2 is the chaotic
/// case.
pub struct Tent {
  priv s : FixedArray[Double]
}

///|
/// A generator with the parameter `mu` and the starting point `x`.
pub fn Tent::with_params(mu : Double, x : Double) -> Tent {
  { s: [x, mu], }
}

///|
/// A generator seeded from eight bytes, at mu = 2.
pub fn Tent::new(seed : BytesView) -> Tent {
  Tent::with_params(2.0, chaos_start(seed))
}

///|
pub impl @contract.Rng for Tent with fn next_u64(self) -> UInt64 {
  let x = self.s[0]
  let mu = self.s[1]
  let next = if x < 0.5 { mu * x } else { mu * (1.0 - x) }
  self.s[0] = next
  chaos_word(next)
}

///|
pub impl @contract.Seeded for Tent with fn from_seed(seed : BytesView) -> Tent {
  Tent::new(seed)
}

///|
pub impl @contract.Seeded for Tent with fn seed_size() -> Int32 {
  8
}

///|
/// Sine: x := sin(pi x), which is chaotic on (0, 1) and never leaves it.
pub struct Sine {
  priv s : FixedArray[Double]
}

///|
/// A generator over the starting point `x` in (0, 1).
pub fn Sine::with_state(x : Double) -> Sine {
  { s: [x], }
}

///|
/// A generator seeded from eight bytes.
pub fn Sine::new(seed : BytesView) -> Sine {
  Sine::with_state(chaos_start(seed))
}

///|
pub impl @contract.Rng for Sine with fn next_u64(self) -> UInt64 {
  let x = @math.sin(@math.PI * self.s[0])
  self.s[0] = x
  chaos_word(x)
}

///|
pub impl @contract.Seeded for Sine with fn from_seed(seed : BytesView) -> Sine {
  Sine::new(seed)
}

///|
pub impl @contract.Seeded for Sine with fn seed_size() -> Int32 {
  8
}

///|
/// Chebyshev: x := cos(n acos(x)), chaotic for n at or above 2.
pub struct Chebyshev {
  priv s : FixedArray[Double]
}

///|
/// A generator with the degree `n` and the starting point `x` in (-1, 1).
pub fn Chebyshev::with_params(n : Double, x : Double) -> Chebyshev {
  { s: [x, n], }
}

///|
/// A generator seeded from eight bytes, at n = 3, mapped into (-1, 1).
pub fn Chebyshev::new(seed : BytesView) -> Chebyshev {
  Chebyshev::with_params(3.0, chaos_start(seed) * 2.0 - 1.0)
}

///|
pub impl @contract.Rng for Chebyshev with fn next_u64(self) -> UInt64 {
  let x = @math.cos(self.s[1] * @math.acos(self.s[0]))
  self.s[0] = x
  chaos_word(x)
}

///|
pub impl @contract.Seeded for Chebyshev with fn from_seed(seed : BytesView) -> Chebyshev {
  Chebyshev::new(seed)
}

///|
pub impl @contract.Seeded for Chebyshev with fn seed_size() -> Int32 {
  8
}

///|
pub extend Logistic with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Logistic with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Tent with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Tent with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Sine with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Sine with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Chebyshev with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Chebyshev with @contract.Seeded::{from_seed, seed_size}
