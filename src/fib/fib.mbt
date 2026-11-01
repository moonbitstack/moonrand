///|
/// AdditiveCongruential: x(n) = x(n-55) + x(n-24) modulo 2^32.
pub struct AdditiveCongruential {
  priv s : FixedArray[UInt32]
  priv i : FixedArray[Int32]
}

///|
/// A generator over the 55 state words.
pub fn AdditiveCongruential::from_state(
  s : FixedArray[UInt32],
) -> AdditiveCongruential {
  ignore(s)
  { s: FixedArray::make(55, 0U), i: FixedArray::make(1, 0), }
}

///|
/// A generator seeded from a byte seed.
pub fn AdditiveCongruential::new(seed : BytesView) -> AdditiveCongruential {
  ignore(seed)
  { s: FixedArray::make(55, 0U), i: FixedArray::make(1, 0), }
}

///|
pub impl @contract.Rng for AdditiveCongruential with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  ignore(self.i)
  abort("AdditiveCongruential: no implementation yet")
}

///|
/// LaggedFibonacci: x(n) = x(n-607) + x(n-273) modulo 2^32.
pub struct LaggedFibonacci {
  priv s : FixedArray[UInt32]
  priv i : FixedArray[Int32]
}

///|
/// A generator over the 607 state words.
pub fn LaggedFibonacci::from_state(s : FixedArray[UInt32]) -> LaggedFibonacci {
  ignore(s)
  { s: FixedArray::make(607, 0U), i: FixedArray::make(1, 0), }
}

///|
/// A generator seeded from a byte seed.
pub fn LaggedFibonacci::new(seed : BytesView) -> LaggedFibonacci {
  ignore(seed)
  { s: FixedArray::make(607, 0U), i: FixedArray::make(1, 0), }
}

///|
pub impl @contract.Rng for LaggedFibonacci with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  ignore(self.i)
  abort("LaggedFibonacci: no implementation yet")
}

///|
/// AddWithCarry: Marsaglia's add-with-carry, a carry bit kept across draws.
pub struct AddWithCarry {
  priv s : FixedArray[UInt32]
  priv i : FixedArray[Int32]
  priv carry : FixedArray[UInt32]
}

///|
/// A generator over the 55 state words, without a carry.
pub fn AddWithCarry::from_state(s : FixedArray[UInt32]) -> AddWithCarry {
  ignore(s)
  {
    s: FixedArray::make(55, 0U),
    i: FixedArray::make(1, 0),
    carry: FixedArray::make(1, 0U),
  }
}

///|
/// A generator seeded from a byte seed.
pub fn AddWithCarry::new(seed : BytesView) -> AddWithCarry {
  ignore(seed)
  {
    s: FixedArray::make(55, 0U),
    i: FixedArray::make(1, 0),
    carry: FixedArray::make(1, 0U),
  }
}

///|
pub impl @contract.Rng for AddWithCarry with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  ignore(self.i)
  ignore(self.carry)
  abort("AddWithCarry: no implementation yet")
}

///|
/// SubtractWithBorrow: subtract-with-borrow over 55 words and a borrow bit.
pub struct SubtractWithBorrow {
  priv s : FixedArray[UInt32]
  priv i : FixedArray[Int32]
  priv borrow : FixedArray[UInt32]
}

///|
/// A generator over the 55 state words, without a borrow.
pub fn SubtractWithBorrow::from_state(
  s : FixedArray[UInt32],
) -> SubtractWithBorrow {
  ignore(s)
  {
    s: FixedArray::make(55, 0U),
    i: FixedArray::make(1, 0),
    borrow: FixedArray::make(1, 0U),
  }
}

///|
/// A generator seeded from a byte seed.
pub fn SubtractWithBorrow::new(seed : BytesView) -> SubtractWithBorrow {
  ignore(seed)
  {
    s: FixedArray::make(55, 0U),
    i: FixedArray::make(1, 0),
    borrow: FixedArray::make(1, 0U),
  }
}

///|
pub impl @contract.Rng for SubtractWithBorrow with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  ignore(self.i)
  ignore(self.borrow)
  abort("SubtractWithBorrow: no implementation yet")
}

///|
/// Ranlux24: subtract-with-borrow over 24-bit words with the luxury discard.
pub struct Ranlux24 {
  priv s : FixedArray[UInt32]
  priv i : FixedArray[Int32]
  priv carry : FixedArray[UInt32]
}

///|
/// A generator over the 24 state words.
pub fn Ranlux24::from_state(s : FixedArray[UInt32]) -> Ranlux24 {
  ignore(s)
  {
    s: FixedArray::make(24, 0U),
    i: FixedArray::make(1, 0),
    carry: FixedArray::make(1, 0U),
  }
}

///|
/// A generator seeded from a byte seed.
pub fn Ranlux24::new(seed : BytesView) -> Ranlux24 {
  ignore(seed)
  {
    s: FixedArray::make(24, 0U),
    i: FixedArray::make(1, 0),
    carry: FixedArray::make(1, 0U),
  }
}

///|
pub impl @contract.Rng for Ranlux24 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  ignore(self.i)
  ignore(self.carry)
  abort("Ranlux24: no implementation yet")
}

///|
/// Ranlux48: subtract-with-borrow over 48-bit words with the luxury discard.
pub struct Ranlux48 {
  priv s : FixedArray[UInt64]
  priv i : FixedArray[Int32]
  priv carry : FixedArray[UInt64]
}

///|
/// A generator over the twelve state words.
pub fn Ranlux48::from_state(s : FixedArray[UInt64]) -> Ranlux48 {
  ignore(s)
  {
    s: FixedArray::make(12, 0UL),
    i: FixedArray::make(1, 0),
    carry: FixedArray::make(1, 0UL),
  }
}

///|
/// A generator seeded from a byte seed.
pub fn Ranlux48::new(seed : BytesView) -> Ranlux48 {
  ignore(seed)
  {
    s: FixedArray::make(12, 0UL),
    i: FixedArray::make(1, 0),
    carry: FixedArray::make(1, 0UL),
  }
}

///|
pub impl @contract.Rng for Ranlux48 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  ignore(self.i)
  ignore(self.carry)
  abort("Ranlux48: no implementation yet")
}

///|
pub impl @contract.Seeded for AdditiveCongruential with fn from_seed(
  seed : BytesView,
) -> AdditiveCongruential {
  AdditiveCongruential::new(seed)
}

///|
pub impl @contract.Seeded for AdditiveCongruential with fn seed_size() -> Int32 {
  220
}

///|
pub impl @contract.Seeded for LaggedFibonacci with fn from_seed(
  seed : BytesView,
) -> LaggedFibonacci {
  LaggedFibonacci::new(seed)
}

///|
pub impl @contract.Seeded for LaggedFibonacci with fn seed_size() -> Int32 {
  2428
}

///|
pub impl @contract.Seeded for AddWithCarry with fn from_seed(seed : BytesView) -> AddWithCarry {
  AddWithCarry::new(seed)
}

///|
pub impl @contract.Seeded for AddWithCarry with fn seed_size() -> Int32 {
  220
}

///|
pub impl @contract.Seeded for SubtractWithBorrow with fn from_seed(
  seed : BytesView,
) -> SubtractWithBorrow {
  SubtractWithBorrow::new(seed)
}

///|
pub impl @contract.Seeded for SubtractWithBorrow with fn seed_size() -> Int32 {
  220
}

///|
pub impl @contract.Seeded for Ranlux24 with fn from_seed(seed : BytesView) -> Ranlux24 {
  Ranlux24::new(seed)
}

///|
pub impl @contract.Seeded for Ranlux24 with fn seed_size() -> Int32 {
  96
}

///|
pub impl @contract.Seeded for Ranlux48 with fn from_seed(seed : BytesView) -> Ranlux48 {
  Ranlux48::new(seed)
}

///|
pub impl @contract.Seeded for Ranlux48 with fn seed_size() -> Int32 {
  96
}

///|
pub extend AdditiveCongruential with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend AdditiveCongruential with @contract.Seeded::{from_seed, seed_size}

///|
pub extend LaggedFibonacci with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend LaggedFibonacci with @contract.Seeded::{from_seed, seed_size}

///|
pub extend AddWithCarry with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend AddWithCarry with @contract.Seeded::{from_seed, seed_size}

///|
pub extend SubtractWithBorrow with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend SubtractWithBorrow with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Ranlux24 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Ranlux24 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Ranlux48 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Ranlux48 with @contract.Seeded::{from_seed, seed_size}
