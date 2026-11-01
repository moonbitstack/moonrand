///|
/// Lfsr64: a 64-bit linear feedback shift register.
pub struct Lfsr64 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over `state`, which must not be zero.
pub fn Lfsr64::with_state(state : UInt64) -> Lfsr64 {
  ignore(state)
  { s: FixedArray::make(1, 0UL), }
}

///|
/// A generator seeded from a byte seed.
pub fn Lfsr64::new(seed : BytesView) -> Lfsr64 {
  ignore(seed)
  { s: FixedArray::make(1, 0UL), }
}

///|
pub impl @contract.Rng for Lfsr64 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Lfsr64: no implementation yet")
}

///|
/// Gfsr: a generalized feedback shift register over 250 32-bit words.
pub struct Gfsr {
  priv s : FixedArray[UInt32]
  priv i : FixedArray[Int32]
}

///|
/// A generator over 250 state words.
pub fn Gfsr::from_state(s : FixedArray[UInt32]) -> Gfsr {
  ignore(s)
  { s: FixedArray::make(250, 0U), i: FixedArray::make(1, 0), }
}

///|
/// A generator seeded from a byte seed.
pub fn Gfsr::new(seed : BytesView) -> Gfsr {
  ignore(seed)
  { s: FixedArray::make(250, 0U), i: FixedArray::make(1, 0), }
}

///|
pub impl @contract.Rng for Gfsr with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  ignore(self.i)
  abort("Gfsr: no implementation yet")
}

///|
/// Taus88: L'Ecuyer's combined Tausworthe generator.
pub struct Taus88 {
  priv s : FixedArray[UInt32]
}

///|
/// A generator over the three component states.
pub fn Taus88::with_state(s1 : UInt32, s2 : UInt32, s3 : UInt32) -> Taus88 {
  ignore((s1, s2, s3))
  { s: FixedArray::make(3, 0U), }
}

///|
/// A generator seeded from a byte seed.
pub fn Taus88::new(seed : BytesView) -> Taus88 {
  ignore(seed)
  { s: FixedArray::make(3, 0U), }
}

///|
pub impl @contract.Rng for Taus88 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Taus88: no implementation yet")
}

///|
/// Lfsr113: L'Ecuyer's combined LFSR generator with period near 2^113.
pub struct Lfsr113 {
  priv s : FixedArray[UInt32]
}

///|
/// A generator over the four component states.
pub fn Lfsr113::with_state(
  s1 : UInt32,
  s2 : UInt32,
  s3 : UInt32,
  s4 : UInt32,
) -> Lfsr113 {
  ignore((s1, s2, s3, s4))
  { s: FixedArray::make(4, 0U), }
}

///|
/// A generator seeded from a byte seed.
pub fn Lfsr113::new(seed : BytesView) -> Lfsr113 {
  ignore(seed)
  { s: FixedArray::make(4, 0U), }
}

///|
pub impl @contract.Rng for Lfsr113 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Lfsr113: no implementation yet")
}

///|
/// Lfsr258: L'Ecuyer's combined LFSR generator with period near 2^258.
pub struct Lfsr258 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over the five component states.
pub fn Lfsr258::with_state(
  s1 : UInt64,
  s2 : UInt64,
  s3 : UInt64,
  s4 : UInt64,
  s5 : UInt64,
) -> Lfsr258 {
  ignore((s1, s2, s3, s4, s5))
  { s: FixedArray::make(5, 0UL), }
}

///|
/// A generator seeded from a byte seed.
pub fn Lfsr258::new(seed : BytesView) -> Lfsr258 {
  ignore(seed)
  { s: FixedArray::make(5, 0UL), }
}

///|
pub impl @contract.Rng for Lfsr258 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Lfsr258: no implementation yet")
}

///|
pub impl @contract.Seeded for Lfsr64 with fn from_seed(seed : BytesView) -> Lfsr64 {
  Lfsr64::new(seed)
}

///|
pub impl @contract.Seeded for Lfsr64 with fn seed_size() -> Int32 {
  8
}

///|
pub impl @contract.Seeded for Gfsr with fn from_seed(seed : BytesView) -> Gfsr {
  Gfsr::new(seed)
}

///|
pub impl @contract.Seeded for Gfsr with fn seed_size() -> Int32 {
  1000
}

///|
pub impl @contract.Seeded for Taus88 with fn from_seed(seed : BytesView) -> Taus88 {
  Taus88::new(seed)
}

///|
pub impl @contract.Seeded for Taus88 with fn seed_size() -> Int32 {
  12
}

///|
pub impl @contract.Seeded for Lfsr113 with fn from_seed(seed : BytesView) -> Lfsr113 {
  Lfsr113::new(seed)
}

///|
pub impl @contract.Seeded for Lfsr113 with fn seed_size() -> Int32 {
  16
}

///|
pub impl @contract.Seeded for Lfsr258 with fn from_seed(seed : BytesView) -> Lfsr258 {
  Lfsr258::new(seed)
}

///|
pub impl @contract.Seeded for Lfsr258 with fn seed_size() -> Int32 {
  40
}

///|
pub extend Lfsr64 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Lfsr64 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Gfsr with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Gfsr with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Taus88 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Taus88 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Lfsr113 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Lfsr113 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Lfsr258 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Lfsr258 with @contract.Seeded::{from_seed, seed_size}
