///|
/// Xorshift32: one 32-bit word, three xorshifts.
pub struct Xorshift32 {
  priv s : FixedArray[UInt32]
}

///|
/// A generator over `state`, which must not be zero.
pub fn Xorshift32::with_state(state : UInt32) -> Xorshift32 {
  ignore(state)
  { s: FixedArray::make(1, 0U), }
}

///|
/// A generator seeded from a byte seed.
pub fn Xorshift32::new(seed : BytesView) -> Xorshift32 {
  ignore(seed)
  { s: FixedArray::make(1, 0U), }
}

///|
pub impl @contract.Rng for Xorshift32 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Xorshift32: no implementation yet")
}

///|
/// Xorshift64: one 64-bit word, three xorshifts.
pub struct Xorshift64 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over `state`, which must not be zero.
pub fn Xorshift64::with_state(state : UInt64) -> Xorshift64 {
  ignore(state)
  { s: FixedArray::make(1, 0UL), }
}

///|
/// A generator seeded from a byte seed.
pub fn Xorshift64::new(seed : BytesView) -> Xorshift64 {
  ignore(seed)
  { s: FixedArray::make(1, 0UL), }
}

///|
pub impl @contract.Rng for Xorshift64 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Xorshift64: no implementation yet")
}

///|
/// Xorshift128: four 32-bit words, the original 128-bit xorshift.
pub struct Xorshift128 {
  priv s : FixedArray[UInt32]
}

///|
/// A generator over the four state words.
pub fn Xorshift128::from_state(s : FixedArray[UInt32]) -> Xorshift128 {
  ignore(s)
  { s: FixedArray::make(4, 0U), }
}

///|
/// A generator seeded from a byte seed.
pub fn Xorshift128::new(seed : BytesView) -> Xorshift128 {
  ignore(seed)
  { s: FixedArray::make(4, 0U), }
}

///|
pub impl @contract.Rng for Xorshift128 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Xorshift128: no implementation yet")
}

///|
/// Xorshift128Plus: two 64-bit words, a sum as the output.
pub struct Xorshift128Plus {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over the two state words.
pub fn Xorshift128Plus::with_state(s0 : UInt64, s1 : UInt64) -> Xorshift128Plus {
  ignore((s0, s1))
  { s: FixedArray::make(2, 0UL), }
}

///|
/// A generator seeded from a byte seed.
pub fn Xorshift128Plus::new(seed : BytesView) -> Xorshift128Plus {
  ignore(seed)
  { s: FixedArray::make(2, 0UL), }
}

///|
pub impl @contract.Rng for Xorshift128Plus with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Xorshift128Plus: no implementation yet")
}

///|
/// Xorwow: xorshift128 with a Weyl increment added.
pub struct Xorwow {
  priv s : FixedArray[UInt32]
  priv d : FixedArray[UInt32]
}

///|
/// A generator over five state words and the Weyl increment.
pub fn Xorwow::from_state(s : FixedArray[UInt32]) -> Xorwow {
  ignore(s)
  { s: FixedArray::make(5, 0U), d: FixedArray::make(1, 0U), }
}

///|
/// A generator seeded from a byte seed.
pub fn Xorwow::new(seed : BytesView) -> Xorwow {
  ignore(seed)
  { s: FixedArray::make(5, 0U), d: FixedArray::make(1, 0U), }
}

///|
pub impl @contract.Rng for Xorwow with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  ignore(self.d)
  abort("Xorwow: no implementation yet")
}

///|
pub impl @contract.Seeded for Xorshift32 with fn from_seed(seed : BytesView) -> Xorshift32 {
  Xorshift32::new(seed)
}

///|
pub impl @contract.Seeded for Xorshift32 with fn seed_size() -> Int32 {
  4
}

///|
pub impl @contract.Seeded for Xorshift64 with fn from_seed(seed : BytesView) -> Xorshift64 {
  Xorshift64::new(seed)
}

///|
pub impl @contract.Seeded for Xorshift64 with fn seed_size() -> Int32 {
  8
}

///|
pub impl @contract.Seeded for Xorshift128 with fn from_seed(seed : BytesView) -> Xorshift128 {
  Xorshift128::new(seed)
}

///|
pub impl @contract.Seeded for Xorshift128 with fn seed_size() -> Int32 {
  16
}

///|
pub impl @contract.Seeded for Xorshift128Plus with fn from_seed(
  seed : BytesView,
) -> Xorshift128Plus {
  Xorshift128Plus::new(seed)
}

///|
pub impl @contract.Seeded for Xorshift128Plus with fn seed_size() -> Int32 {
  16
}

///|
pub impl @contract.Seeded for Xorwow with fn from_seed(seed : BytesView) -> Xorwow {
  Xorwow::new(seed)
}

///|
pub impl @contract.Seeded for Xorwow with fn seed_size() -> Int32 {
  24
}

///|
pub extend Xorshift32 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Xorshift32 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Xorshift64 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Xorshift64 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Xorshift128 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Xorshift128 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Xorshift128Plus with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Xorshift128Plus with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Xorwow with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Xorwow with @contract.Seeded::{from_seed, seed_size}
