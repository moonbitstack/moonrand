///|
/// Marsaglia's xorshift generators: the 2003 paper's 32-, 64- and 128-bit
/// forms, the 128-bit sum, and XORWOW.
pub struct Xorshift32 {
  priv s : FixedArray[UInt32]
}

///|
/// A generator over `state`, which must not be zero.
pub fn Xorshift32::with_state(state : UInt32) -> Xorshift32 {
  { s: [state], }
}

///|
/// A generator seeded from four bytes; a zero seed becomes one.
pub fn Xorshift32::new(seed : BytesView) -> Xorshift32 {
  let w = @bits.seed_words(seed, 1)[0].to_uint()
  Xorshift32::with_state(if w == 0U { 1U } else { w })
}

///|
pub impl @contract.Rng for Xorshift32 with fn next_u32(self) -> UInt32 {
  let mut x = self.s[0]
  x = x ^ (x << 13)
  x = x ^ (x >> 17)
  x = x ^ (x << 5)
  self.s[0] = x
  x
}

///|
pub impl @contract.Rng for Xorshift32 with fn next_u64(self) -> UInt64 {
  (self.next_u32().to_uint64() << 32) | self.next_u32().to_uint64()
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
pub struct Xorshift64 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over `state`, which must not be zero.
pub fn Xorshift64::with_state(state : UInt64) -> Xorshift64 {
  { s: [state], }
}

///|
/// A generator seeded from eight bytes; a zero seed becomes one.
pub fn Xorshift64::new(seed : BytesView) -> Xorshift64 {
  let w = @bits.seed_words(seed, 1)[0]
  Xorshift64::with_state(if w == 0UL { 1UL } else { w })
}

///|
pub impl @contract.Rng for Xorshift64 with fn next_u64(self) -> UInt64 {
  let mut x = self.s[0]
  x = x ^ (x << 13)
  x = x ^ (x >> 7)
  x = x ^ (x << 17)
  self.s[0] = x
  x
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
/// Xorshift128: the four-word form of the 2003 paper.
pub struct Xorshift128 {
  priv s : FixedArray[UInt32]
}

///|
/// A generator over the four state words `x`, `y`, `z`, `w`.
pub fn Xorshift128::from_state(s : FixedArray[UInt32]) -> Xorshift128 {
  if s.length() != 4 {
    abort("Xorshift128: state is four words")
  }
  { s, }
}

///|
/// A generator seeded from sixteen bytes through SplitMix64.
pub fn Xorshift128::new(seed : BytesView) -> Xorshift128 {
  let w = @bits.seed_words(seed, 2)
  Xorshift128::from_state([
    w[0].to_uint(),
    (w[0] >> 32).to_uint(),
    w[1].to_uint(),
    (w[1] >> 32).to_uint(),
  ])
}

///|
pub impl @contract.Rng for Xorshift128 with fn next_u32(self) -> UInt32 {
  let t = self.s[0] ^ (self.s[0] << 11)
  self.s[0] = self.s[1]
  self.s[1] = self.s[2]
  self.s[2] = self.s[3]
  self.s[3] = self.s[3] ^ (self.s[3] >> 19) ^ (t ^ (t >> 8))
  self.s[3]
}

///|
pub impl @contract.Rng for Xorshift128 with fn next_u64(self) -> UInt64 {
  (self.next_u32().to_uint64() << 32) | self.next_u32().to_uint64()
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
/// Xorshift128Plus: two 64-bit words, their sum as the output.
pub struct Xorshift128Plus {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over the two state words, which must not both be zero.
pub fn Xorshift128Plus::with_state(s0 : UInt64, s1 : UInt64) -> Xorshift128Plus {
  { s: [s0, s1], }
}

///|
/// A generator seeded from sixteen bytes through SplitMix64.
pub fn Xorshift128Plus::new(seed : BytesView) -> Xorshift128Plus {
  let w = @bits.seed_words(seed, 2)
  Xorshift128Plus::with_state(w[0], w[1])
}

///|
pub impl @contract.Rng for Xorshift128Plus with fn next_u64(self) -> UInt64 {
  let mut x = self.s[0]
  let y = self.s[1]
  self.s[0] = y
  x = x ^ (x << 23)
  self.s[1] = x ^ y ^ (x >> 17) ^ (y >> 26)
  self.s[1] + y
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
/// Xorwow: xorshift128 with a Weyl increment added to the output, Marsaglia's
/// contribution to the Curand library.
pub struct Xorwow {
  priv s : FixedArray[UInt32]
  priv d : FixedArray[UInt32]
}

///|
/// A generator over the five state words `x`, `y`, `z`, `w`, `v` and the Weyl
/// word `d`.
pub fn Xorwow::from_state(s : FixedArray[UInt32]) -> Xorwow {
  if s.length() != 6 {
    abort("Xorwow: state is five words and the Weyl word")
  }
  { s: [s[0], s[1], s[2], s[3], s[4]], d: [s[5]], }
}

///|
/// A generator seeded from 24 bytes through SplitMix64.
pub fn Xorwow::new(seed : BytesView) -> Xorwow {
  let w = @bits.seed_words(seed, 3)
  Xorwow::from_state([
    w[0].to_uint(),
    (w[0] >> 32).to_uint(),
    w[1].to_uint(),
    (w[1] >> 32).to_uint(),
    w[2].to_uint(),
    362437U,
  ])
}

///|
pub impl @contract.Rng for Xorwow with fn next_u32(self) -> UInt32 {
  let t = self.s[0] ^ (self.s[0] >> 2)
  self.s[0] = self.s[1]
  self.s[1] = self.s[2]
  self.s[2] = self.s[3]
  self.s[3] = self.s[4]
  self.s[4] = self.s[4] ^ (self.s[4] << 4) ^ (t ^ (t << 1))
  self.d[0] = self.d[0] + 362437U
  self.s[4] + self.d[0]
}

///|
pub impl @contract.Rng for Xorwow with fn next_u64(self) -> UInt64 {
  (self.next_u32().to_uint64() << 32) | self.next_u32().to_uint64()
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
