///|
/// JSF64: Jenkins' small fast generator — four words, one rotate per step, and
/// a guaranteed period of at least 2^64.
pub struct Jsf64 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over the four state words.
pub fn Jsf64::with_state(
  a : UInt64,
  b : UInt64,
  c : UInt64,
  d : UInt64,
) -> Jsf64 {
  { s: [a, b, c, d], }
}

///|
/// A generator seeded from 32 bytes through SplitMix64.
pub fn Jsf64::new(seed : BytesView) -> Jsf64 {
  let w = @bits.seed_words(seed, 4)
  Jsf64::with_state(w[0], w[1], w[2], w[3])
}

///|
pub impl @contract.Rng for Jsf64 with fn next_u64(self) -> UInt64 {
  let a = self.s[0]
  let b = self.s[1]
  let c = self.s[2]
  let d = self.s[3]
  let e = a - ((b << 7) | (b >> 57))
  self.s[0] = b ^ ((c << 13) | (c >> 51))
  self.s[1] = c + ((d << 37) | (d >> 27))
  self.s[2] = d + e
  self.s[3] = e + self.s[0]
  self.s[3]
}

///|
pub impl @contract.Seeded for Jsf64 with fn from_seed(seed : BytesView) -> Jsf64 {
  Jsf64::new(seed)
}

///|
pub impl @contract.Seeded for Jsf64 with fn seed_size() -> Int32 {
  32
}

///|
pub extend Jsf64 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Jsf64 with @contract.Seeded::{from_seed, seed_size}
