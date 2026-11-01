///|
/// Philox4x32: four 32-bit counter words, two 32-bit key words, ten rounds.
pub struct Philox4x32 {
  priv ctr : FixedArray[UInt32]
  priv key : FixedArray[UInt32]
  priv out : FixedArray[UInt32]
  priv pos : FixedArray[Int32]
}

///|
/// A generator with the key `k0`, `k1` and a zero counter.
pub fn Philox4x32::with_key(k0 : UInt32, k1 : UInt32) -> Philox4x32 {
  ignore((k0, k1))
  {
    ctr: FixedArray::make(4, 0U),
    key: FixedArray::make(2, 0U),
    out: FixedArray::make(4, 0U),
    pos: [4],
  }
}

///|
/// A generator keyed from eight bytes.
pub fn Philox4x32::new(seed : BytesView) -> Philox4x32 {
  ignore(seed)
  {
    ctr: FixedArray::make(4, 0U),
    key: FixedArray::make(2, 0U),
    out: FixedArray::make(4, 0U),
    pos: [4],
  }
}

///|
/// Skip `n` 64-bit draws by stepping the counter.
pub fn Philox4x32::advance(self : Philox4x32, n : UInt64) -> Unit {
  ignore((self.ctr, n))
  abort("moonrand/philox: no implementation yet")
}

///|
/// Philox4x64: four 64-bit counter words, two 64-bit key words, ten rounds.
pub struct Philox4x64 {
  priv ctr : FixedArray[UInt64]
  priv key : FixedArray[UInt64]
  priv out : FixedArray[UInt64]
  priv pos : FixedArray[Int32]
}

///|
/// A generator with the key `k0`, `k1` and a zero counter.
pub fn Philox4x64::with_key(k0 : UInt64, k1 : UInt64) -> Philox4x64 {
  ignore((k0, k1))
  {
    ctr: FixedArray::make(4, 0UL),
    key: FixedArray::make(2, 0UL),
    out: FixedArray::make(4, 0UL),
    pos: [4],
  }
}

///|
/// A generator keyed from sixteen bytes.
pub fn Philox4x64::new(seed : BytesView) -> Philox4x64 {
  ignore(seed)
  {
    ctr: FixedArray::make(4, 0UL),
    key: FixedArray::make(2, 0UL),
    out: FixedArray::make(4, 0UL),
    pos: [4],
  }
}

///|
/// Skip `n` 64-bit draws by stepping the counter.
pub fn Philox4x64::advance(self : Philox4x64, n : UInt64) -> Unit {
  ignore((self.ctr, n))
  abort("moonrand/philox: no implementation yet")
}

///|
pub impl @contract.Rng for Philox4x32 with fn next_u64(self) -> UInt64 {
  ignore(self.ctr)
  ignore(self.key)
  ignore(self.out)
  ignore(self.pos)
  abort("Philox4x32: no implementation yet")
}

///|
pub impl @contract.Rng for Philox4x64 with fn next_u64(self) -> UInt64 {
  ignore(self.ctr)
  ignore(self.key)
  ignore(self.out)
  ignore(self.pos)
  abort("Philox4x64: no implementation yet")
}

///|
pub impl @contract.Seeded for Philox4x32 with fn from_seed(seed : BytesView) -> Philox4x32 {
  Philox4x32::new(seed)
}

///|
pub impl @contract.Seeded for Philox4x32 with fn seed_size() -> Int32 {
  8
}

///|
pub impl @contract.Seeded for Philox4x64 with fn from_seed(seed : BytesView) -> Philox4x64 {
  Philox4x64::new(seed)
}

///|
pub impl @contract.Seeded for Philox4x64 with fn seed_size() -> Int32 {
  16
}

///|
pub extend Philox4x32 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Philox4x32 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Philox4x64 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Philox4x64 with @contract.Seeded::{from_seed, seed_size}
