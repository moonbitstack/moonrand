///|
/// SFC64: three words of state and a counter, mixed by addition and shifts.
/// The counter makes the period at least 2^64 whatever the state; the shift
/// constants are the author's.
pub struct Sfc64 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over the state words `a`, `b`, `c`, with the counter at zero.
pub fn Sfc64::with_state(a : UInt64, b : UInt64, c : UInt64) -> Sfc64 {
  { s: [a, b, c, 0UL], }
}

///|
/// A generator seeded from 24 bytes through SplitMix64.
pub fn Sfc64::new(seed : BytesView) -> Sfc64 {
  let w = @bits.seed_words(seed, 3)
  Sfc64::with_state(w[0], w[1], w[2])
}

///|
pub impl @contract.Rng for Sfc64 with fn next_u64(self) -> UInt64 {
  let a = self.s[0]
  let b = self.s[1]
  self.s[3] = self.s[3] + 1UL
  let c = self.s[2] + self.s[3]
  let tmp = a + b + c
  self.s[0] = b ^ (b >> 11)
  self.s[1] = c + (c << 3)
  self.s[2] = (c << 24) | (c >> 40)
  self.s[2] = self.s[2] + tmp
  tmp
}

///|
pub impl @contract.Seeded for Sfc64 with fn from_seed(seed : BytesView) -> Sfc64 {
  Sfc64::new(seed)
}

///|
pub impl @contract.Seeded for Sfc64 with fn seed_size() -> Int32 {
  24
}

///|
pub extend Sfc64 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Sfc64 with @contract.Seeded::{from_seed, seed_size}
