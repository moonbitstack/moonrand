///|
/// WELL512a: sixteen 32-bit words, period 2^512-1.
pub struct Well512 {
  priv s : FixedArray[UInt32]
  priv i : FixedArray[Int32]
}

///|
/// A generator over sixteen state words.
pub fn Well512::from_state(s : FixedArray[UInt32]) -> Well512 {
  ignore(s)
  { s: FixedArray::make(16, 0U), i: FixedArray::make(1, 0), }
}

///|
/// A generator seeded from a byte seed.
pub fn Well512::new(seed : BytesView) -> Well512 {
  ignore(seed)
  { s: FixedArray::make(16, 0U), i: FixedArray::make(1, 0), }
}

///|
pub impl @contract.Rng for Well512 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  ignore(self.i)
  abort("Well512: no implementation yet")
}

///|
/// WELL1024a: thirty-two 32-bit words, period 2^1024-1.
pub struct Well1024 {
  priv s : FixedArray[UInt32]
  priv i : FixedArray[Int32]
}

///|
/// A generator over thirty-two state words.
pub fn Well1024::from_state(s : FixedArray[UInt32]) -> Well1024 {
  ignore(s)
  { s: FixedArray::make(32, 0U), i: FixedArray::make(1, 0), }
}

///|
/// A generator seeded from a byte seed.
pub fn Well1024::new(seed : BytesView) -> Well1024 {
  ignore(seed)
  { s: FixedArray::make(32, 0U), i: FixedArray::make(1, 0), }
}

///|
pub impl @contract.Rng for Well1024 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  ignore(self.i)
  abort("Well1024: no implementation yet")
}

///|
pub impl @contract.Seeded for Well512 with fn from_seed(seed : BytesView) -> Well512 {
  Well512::new(seed)
}

///|
pub impl @contract.Seeded for Well512 with fn seed_size() -> Int32 {
  64
}

///|
pub impl @contract.Seeded for Well1024 with fn from_seed(seed : BytesView) -> Well1024 {
  Well1024::new(seed)
}

///|
pub impl @contract.Seeded for Well1024 with fn seed_size() -> Int32 {
  128
}

///|
pub extend Well512 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Well512 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Well1024 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Well1024 with @contract.Seeded::{from_seed, seed_size}
