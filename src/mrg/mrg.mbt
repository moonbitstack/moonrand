///|
/// MRG32k3a: two recursive generators of order three over the primes 2^32-209 and 2^32-22853, combined.
pub struct Mrg32k3a {
  priv s : FixedArray[Int64]
}

///|
/// A generator over the six reference state words.
pub fn Mrg32k3a::from_state(s : FixedArray[Int64]) -> Mrg32k3a {
  ignore(s)
  { s: FixedArray::make(6, 0L), }
}

///|
/// A generator seeded from a byte seed.
pub fn Mrg32k3a::new(seed : BytesView) -> Mrg32k3a {
  ignore(seed)
  { s: FixedArray::make(6, 0L), }
}

///|
/// Skip `n` draws, the reference counter step.
pub fn Mrg32k3a::advance(self : Mrg32k3a, n : UInt64) -> Unit {
  ignore((self.s, n))
  abort("moonrand/mrg: no implementation yet")
}

///|
pub impl @contract.Rng for Mrg32k3a with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Mrg32k3a: no implementation yet")
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
