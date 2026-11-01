///|
/// SFC64: three state words and a counter, added and shifted.
pub struct Sfc64 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over the three state words `a`, `b`, `c`.
pub fn Sfc64::with_state(a : UInt64, b : UInt64, c : UInt64) -> Sfc64 {
  ignore((a, b, c))
  { s: FixedArray::make(4, 0UL), }
}

///|
/// A generator seeded from a byte seed.
pub fn Sfc64::new(seed : BytesView) -> Sfc64 {
  ignore(seed)
  { s: FixedArray::make(4, 0UL), }
}

///|
pub impl @contract.Rng for Sfc64 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Sfc64: no implementation yet")
}

///|
pub impl @contract.Seeded for Sfc64 with fn from_seed(seed : BytesView) -> Sfc64 {
  Sfc64::new(seed)
}

///|
pub impl @contract.Seeded for Sfc64 with fn seed_size() -> Int32 {
  24
}

///|
pub extend Sfc64 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Sfc64 with @contract.Seeded::{from_seed, seed_size}
