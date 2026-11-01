///|
/// Squares: a 256-bit key, a 256-bit counter, a round of squares.
pub struct Squares {
  priv key : FixedArray[UInt64]
  priv ctr : FixedArray[UInt64]
}

///|
/// A generator with the four-word key `k0` to `k3` and a zero counter.
pub fn Squares::with_key(
  k0 : UInt64,
  k1 : UInt64,
  k2 : UInt64,
  k3 : UInt64,
) -> Squares {
  ignore((k0, k1, k2, k3))
  { key: FixedArray::make(4, 0UL), ctr: FixedArray::make(4, 0UL), }
}

///|
/// A generator seeded from a byte seed.
pub fn Squares::new(seed : BytesView) -> Squares {
  ignore(seed)
  { key: FixedArray::make(4, 0UL), ctr: FixedArray::make(4, 0UL), }
}

///|
/// Skip `n` draws, the reference counter step.
pub fn Squares::advance(self : Squares, n : UInt64) -> Unit {
  ignore((self.key, self.ctr, n))
  abort("moonrand/squares: no implementation yet")
}

///|
pub impl @contract.Rng for Squares with fn next_u64(self) -> UInt64 {
  ignore(self.key)
  ignore(self.ctr)
  abort("Squares: no implementation yet")
}

///|
pub impl @contract.Seeded for Squares with fn from_seed(seed : BytesView) -> Squares {
  Squares::new(seed)
}

///|
pub impl @contract.Seeded for Squares with fn seed_size() -> Int32 {
  32
}

///|
pub extend Squares with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Squares with @contract.Seeded::{from_seed, seed_size}
