///|
/// Threefry4x64: four 64-bit counter words, two 64-bit key words, twenty
/// rounds.
pub struct Threefry4x64 {
  priv ctr : FixedArray[UInt64]
  priv key : FixedArray[UInt64]
  priv out : FixedArray[UInt64]
  priv pos : FixedArray[Int32]
}

///|
/// A generator with the key `k0`, `k1` and a zero counter.
pub fn Threefry4x64::with_key(k0 : UInt64, k1 : UInt64) -> Threefry4x64 {
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
pub fn Threefry4x64::new(seed : BytesView) -> Threefry4x64 {
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
pub fn Threefry4x64::advance(self : Threefry4x64, n : UInt64) -> Unit {
  ignore((self.ctr, n))
  abort("moonrand/threefry: no implementation yet")
}

///|
/// Threefry2x64: two 64-bit counter words, two 64-bit key words, thirteen
/// rounds.
pub struct Threefry2x64 {
  priv ctr : FixedArray[UInt64]
  priv key : FixedArray[UInt64]
  priv out : FixedArray[UInt64]
  priv pos : FixedArray[Int32]
}

///|
/// A generator with the key `k0`, `k1` and a zero counter.
pub fn Threefry2x64::with_key(k0 : UInt64, k1 : UInt64) -> Threefry2x64 {
  ignore((k0, k1))
  {
    ctr: FixedArray::make(2, 0UL),
    key: FixedArray::make(2, 0UL),
    out: FixedArray::make(2, 0UL),
    pos: [2],
  }
}

///|
/// A generator keyed from sixteen bytes.
pub fn Threefry2x64::new(seed : BytesView) -> Threefry2x64 {
  ignore(seed)
  {
    ctr: FixedArray::make(2, 0UL),
    key: FixedArray::make(2, 0UL),
    out: FixedArray::make(2, 0UL),
    pos: [2],
  }
}

///|
/// Skip `n` 64-bit draws by stepping the counter.
pub fn Threefry2x64::advance(self : Threefry2x64, n : UInt64) -> Unit {
  ignore((self.ctr, n))
  abort("moonrand/threefry: no implementation yet")
}

///|
/// Threefry4x32: four 32-bit counter words, two 32-bit key words, twenty
/// rounds.
pub struct Threefry4x32 {
  priv ctr : FixedArray[UInt32]
  priv key : FixedArray[UInt32]
  priv out : FixedArray[UInt32]
  priv pos : FixedArray[Int32]
}

///|
/// A generator with the key `k0`, `k1` and a zero counter.
pub fn Threefry4x32::with_key(k0 : UInt32, k1 : UInt32) -> Threefry4x32 {
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
pub fn Threefry4x32::new(seed : BytesView) -> Threefry4x32 {
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
pub fn Threefry4x32::advance(self : Threefry4x32, n : UInt64) -> Unit {
  ignore((self.ctr, n))
  abort("moonrand/threefry: no implementation yet")
}

///|
pub impl @contract.Rng for Threefry4x64 with fn next_u64(self) -> UInt64 {
  ignore(self.ctr)
  ignore(self.key)
  ignore(self.out)
  ignore(self.pos)
  abort("Threefry4x64: no implementation yet")
}

///|
pub impl @contract.Rng for Threefry2x64 with fn next_u64(self) -> UInt64 {
  ignore(self.ctr)
  ignore(self.key)
  ignore(self.out)
  ignore(self.pos)
  abort("Threefry2x64: no implementation yet")
}

///|
pub impl @contract.Rng for Threefry4x32 with fn next_u64(self) -> UInt64 {
  ignore(self.ctr)
  ignore(self.key)
  ignore(self.out)
  ignore(self.pos)
  abort("Threefry4x32: no implementation yet")
}

///|
pub impl @contract.Seeded for Threefry4x64 with fn from_seed(seed : BytesView) -> Threefry4x64 {
  Threefry4x64::new(seed)
}

///|
pub impl @contract.Seeded for Threefry4x64 with fn seed_size() -> Int32 {
  16
}

///|
pub impl @contract.Seeded for Threefry2x64 with fn from_seed(seed : BytesView) -> Threefry2x64 {
  Threefry2x64::new(seed)
}

///|
pub impl @contract.Seeded for Threefry2x64 with fn seed_size() -> Int32 {
  16
}

///|
pub impl @contract.Seeded for Threefry4x32 with fn from_seed(seed : BytesView) -> Threefry4x32 {
  Threefry4x32::new(seed)
}

///|
pub impl @contract.Seeded for Threefry4x32 with fn seed_size() -> Int32 {
  8
}

///|
pub extend Threefry4x64 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Threefry4x64 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Threefry2x64 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Threefry2x64 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Threefry4x32 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Threefry4x32 with @contract.Seeded::{from_seed, seed_size}
