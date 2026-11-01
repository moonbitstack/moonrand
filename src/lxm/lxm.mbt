///|
/// L64X128: a 64-bit LCG and xoroshiro128+, added.
pub struct L64X128 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over the LCG state `lcg` and the xoroshiro state `s0`, `s1`.
pub fn L64X128::with_state(lcg : UInt64, s0 : UInt64, s1 : UInt64) -> L64X128 {
  ignore((lcg, s0, s1))
  { s: FixedArray::make(3, 0UL), }
}

///|
/// A generator seeded from a byte seed.
pub fn L64X128::new(seed : BytesView) -> L64X128 {
  ignore(seed)
  { s: FixedArray::make(3, 0UL), }
}

///|
/// Skip a fixed distance ahead, the reference `jump`.
pub fn L64X128::jump(self : L64X128) -> Unit {
  ignore(self.s)
  abort("moonrand/lxm: no implementation yet")
}

///|
pub impl @contract.Rng for L64X128 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("L64X128: no implementation yet")
}

///|
/// L64X256: a 64-bit LCG and xoshiro256+, added.
pub struct L64X256 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over the LCG state `lcg` and the xoshiro state `s0` to `s3`.
pub fn L64X256::with_state(
  lcg : UInt64,
  s0 : UInt64,
  s1 : UInt64,
  s2 : UInt64,
  s3 : UInt64,
) -> L64X256 {
  ignore((lcg, s0, s1, s2, s3))
  { s: FixedArray::make(5, 0UL), }
}

///|
/// A generator seeded from a byte seed.
pub fn L64X256::new(seed : BytesView) -> L64X256 {
  ignore(seed)
  { s: FixedArray::make(5, 0UL), }
}

///|
/// Skip a fixed distance ahead, the reference `jump`.
pub fn L64X256::jump(self : L64X256) -> Unit {
  ignore(self.s)
  abort("moonrand/lxm: no implementation yet")
}

///|
pub impl @contract.Rng for L64X256 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("L64X256: no implementation yet")
}

///|
pub impl @contract.Seeded for L64X128 with fn from_seed(seed : BytesView) -> L64X128 {
  L64X128::new(seed)
}

///|
pub impl @contract.Seeded for L64X128 with fn seed_size() -> Int32 {
  24
}

///|
pub impl @contract.Seeded for L64X256 with fn from_seed(seed : BytesView) -> L64X256 {
  L64X256::new(seed)
}

///|
pub impl @contract.Seeded for L64X256 with fn seed_size() -> Int32 {
  40
}

///|
pub extend L64X128 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend L64X128 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend L64X256 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend L64X256 with @contract.Seeded::{from_seed, seed_size}
