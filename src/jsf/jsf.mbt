///|
/// JSF64: four state words, a rotate and an add.
pub struct Jsf64 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over the four state words.
pub fn Jsf64::with_state(
  a : UInt64,
  b : UInt64,
  c : UInt64,
  d : UInt64,
) -> Jsf64 {
  ignore((a, b, c, d))
  { s: FixedArray::make(4, 0UL), }
}

///|
/// A generator seeded from a byte seed.
pub fn Jsf64::new(seed : BytesView) -> Jsf64 {
  ignore(seed)
  { s: FixedArray::make(4, 0UL), }
}

///|
pub impl @contract.Rng for Jsf64 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Jsf64: no implementation yet")
}

///|
pub impl @contract.Seeded for Jsf64 with fn from_seed(seed : BytesView) -> Jsf64 {
  Jsf64::new(seed)
}

///|
pub impl @contract.Seeded for Jsf64 with fn seed_size() -> Int32 {
  32
}

///|
pub extend Jsf64 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Jsf64 with @contract.Seeded::{from_seed, seed_size}
