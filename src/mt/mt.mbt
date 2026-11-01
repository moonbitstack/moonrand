///|
/// MT19937: the 32-bit Mersenne Twister, period 2^19937-1, 624 words of state.
pub struct MT19937 {
  priv s : FixedArray[UInt32]
  priv i : FixedArray[Int32]
}

///|
/// The reference seeding `init_genrand`: one word, expanded by the 1812433253
/// recursion.
pub fn MT19937::with_word(seed : UInt32) -> MT19937 {
  ignore(seed)
  { s: FixedArray::make(624, 0U), i: [0], }
}

///|
/// The reference seeding `init_by_array`: a key of any length, mixed in.
pub fn MT19937::from_array(keys : FixedArray[UInt32]) -> MT19937 {
  ignore(keys)
  { s: FixedArray::make(624, 0U), i: [0], }
}

///|
/// A generator from a byte seed, read four bytes at a time, little endian, and
/// handed to `from_array`.
pub fn MT19937::new(seed : BytesView) -> MT19937 {
  ignore(seed)
  { s: FixedArray::make(624, 0U), i: [0], }
}

///|
/// MT19937-64: the 64-bit Mersenne Twister, 312 words of state.
pub struct MT19937_64 {
  priv s : FixedArray[UInt64]
  priv i : FixedArray[Int32]
}

///|
/// The reference seeding `init_genrand64`.
pub fn MT19937_64::with_word(seed : UInt64) -> MT19937_64 {
  ignore(seed)
  { s: FixedArray::make(312, 0UL), i: [0], }
}

///|
/// The reference seeding `init_by_array64`.
pub fn MT19937_64::from_array(keys : FixedArray[UInt64]) -> MT19937_64 {
  ignore(keys)
  { s: FixedArray::make(312, 0UL), i: [0], }
}

///|
/// A generator from a byte seed, read eight bytes at a time, little endian.
pub fn MT19937_64::new(seed : BytesView) -> MT19937_64 {
  ignore(seed)
  { s: FixedArray::make(312, 0UL), i: [0], }
}

///|
/// SFMT19937: the SIMD-oriented Fast Mersenne Twister, period 2^19937-1, the
/// same period as MT19937 with a faster recursion and 128-bit blocks.
pub struct Sfmt19937 {
  priv s : FixedArray[UInt32]
  priv i : FixedArray[Int32]
}

///|
/// The reference seeding `init_gen_rand`.
pub fn Sfmt19937::with_word(seed : UInt32) -> Sfmt19937 {
  ignore(seed)
  { s: FixedArray::make(624, 0U), i: [0], }
}

///|
/// The reference seeding `init_by_array`.
pub fn Sfmt19937::from_array(keys : FixedArray[UInt32]) -> Sfmt19937 {
  ignore(keys)
  { s: FixedArray::make(624, 0U), i: [0], }
}

///|
/// A generator from a byte seed, read four bytes at a time, little endian.
pub fn Sfmt19937::new(seed : BytesView) -> Sfmt19937 {
  ignore(seed)
  { s: FixedArray::make(624, 0U), i: [0], }
}

///|
pub impl @contract.Rng for MT19937 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  ignore(self.i)
  abort("MT19937: no implementation yet")
}

///|
pub impl @contract.Rng for MT19937_64 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  ignore(self.i)
  abort("MT19937_64: no implementation yet")
}

///|
pub impl @contract.Rng for Sfmt19937 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  ignore(self.i)
  abort("Sfmt19937: no implementation yet")
}

///|
pub impl @contract.Seeded for MT19937 with fn from_seed(seed : BytesView) -> MT19937 {
  MT19937::new(seed)
}

///|
pub impl @contract.Seeded for MT19937 with fn seed_size() -> Int32 {
  4
}

///|
pub impl @contract.Seeded for MT19937_64 with fn from_seed(seed : BytesView) -> MT19937_64 {
  MT19937_64::new(seed)
}

///|
pub impl @contract.Seeded for MT19937_64 with fn seed_size() -> Int32 {
  8
}

///|
pub impl @contract.Seeded for Sfmt19937 with fn from_seed(seed : BytesView) -> Sfmt19937 {
  Sfmt19937::new(seed)
}

///|
pub impl @contract.Seeded for Sfmt19937 with fn seed_size() -> Int32 {
  4
}

///|
pub extend MT19937 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend MT19937 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend MT19937_64 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend MT19937_64 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Sfmt19937 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Sfmt19937 with @contract.Seeded::{from_seed, seed_size}
