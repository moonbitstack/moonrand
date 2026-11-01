///|
/// MRG32k3a: two recursive generators of order three over the primes 2^32-209
/// and 2^32-22853, their outputs subtracted. L'Ecuyer's parametrisation; the
/// period is about 2^191 and the lattice structure is what the two components
/// are there to break.

///|
const M1 : Int64 = 4294967087L

///|
const M2 : Int64 = 4294944443L

///|
const A12 : Int64 = 1403580L

///|
const A13N : Int64 = 810728L

///|
const A21 : Int64 = 527612L

///|
const A23N : Int64 = 1370589L

///|
pub struct Mrg32k3a {
  priv s : FixedArray[Int64]
}

///|
/// A generator over the six reference state words, the first three for the
/// first component.
pub fn Mrg32k3a::from_state(s : FixedArray[Int64]) -> Mrg32k3a {
  if s.length() != 6 {
    abort("Mrg32k3a: state is six words")
  }
  { s, }
}

///|
/// A generator from twenty-four bytes through SplitMix64, each component
/// reduced into its own prime.
pub fn Mrg32k3a::new(seed : BytesView) -> Mrg32k3a {
  let w = @bits.seed_words(seed, 6)
  let s = FixedArray::make(6, 0L)
  for i = 0; i < 3; i = i + 1 {
    s[i] = (w[i] % 4294967087UL).reinterpret_as_int64()
  }
  for i = 0; i < 3; i = i + 1 {
    s[3 + i] = (w[3 + i] % 4294944443UL).reinterpret_as_int64()
  }
  Mrg32k3a::from_state(s)
}

///|
/// One combined output in [0, M1): the difference of the two components, with
/// zero moved to M1 - 1 as the reference does.
fn mrg_step(g : Mrg32k3a) -> UInt32 {
  let p1 = (A12 * g.s[1] - A13N * g.s[0]) % M1
  let p2 = (A21 * g.s[5] - A23N * g.s[3]) % M2
  g.s[0] = g.s[1]
  g.s[1] = g.s[2]
  g.s[2] = if p1 < 0L { p1 + M1 } else { p1 }
  g.s[3] = g.s[4]
  g.s[4] = g.s[5]
  g.s[5] = if p2 < 0L { p2 + M2 } else { p2 }
  let z = g.s[2] - g.s[5]
  let v = if z < 0L { z + M1 } else { z }
  if v == 0L {
    (M1 - 1L).to_int().reinterpret_as_uint()
  } else {
    v.to_int().reinterpret_as_uint()
  }
}

///|
/// Skip `n` draws by stepping the recurrence `n` times. Each component is a
/// linear recurrence, so a matrix power would do this in log n steps; the loop
/// is what is here, and the doc says so rather than pretending otherwise.
pub fn Mrg32k3a::advance(self : Mrg32k3a, n : UInt64) -> Unit {
  let mut left = n
  while left > 0UL {
    ignore(mrg_step(self))
    left = left - 1UL
  }
}

///|
pub impl @contract.Rng for Mrg32k3a with fn next_u32(self) -> UInt32 {
  mrg_step(self)
}

///|
pub impl @contract.Rng for Mrg32k3a with fn next_u64(self) -> UInt64 {
  (mrg_step(self).to_uint64() << 32) | mrg_step(self).to_uint64()
}

///|
pub impl @contract.Seeded for Mrg32k3a with fn from_seed(seed : BytesView) -> Mrg32k3a {
  Mrg32k3a::new(seed)
}

///|
pub impl @contract.Seeded for Mrg32k3a with fn seed_size() -> Int32 {
  24
}

///|
pub extend Mrg32k3a with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Mrg32k3a with @contract.Seeded::{from_seed, seed_size}
