///|
/// SplitMix64: a counter, a golden-ratio step and the finalizer in `bits`.
/// Period 2^64, one 64-bit word of state. It is the generator the xoshiro
/// family is seeded from, and a generator in its own right.
pub struct SplitMix64 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator holding `state` as its counter.
pub fn SplitMix64::from_state(state : UInt64) -> SplitMix64 {
  { s: [state], }
}

///|
/// A generator seeded from eight bytes; a shorter seed is zero-padded.
pub fn SplitMix64::new(seed : BytesView) -> SplitMix64 {
  SplitMix64::from_state(@bits.seed_words(seed, 1)[0])
}

///|
/// Skip the next `n` draws by adding `n` golden-ratio steps to the counter.
pub fn SplitMix64::advance(self : SplitMix64, n : UInt64) -> Unit {
  self.s[0] = self.s[0] + n * 0x9E3779B97F4A7C15UL
}

///|
pub impl @contract.Rng for SplitMix64 with fn next_u64(self) -> UInt64 {
  self.s[0] = self.s[0] + 0x9E3779B97F4A7C15UL
  @bits.mix64(self.s[0])
}

///|
pub impl @contract.Seeded for SplitMix64 with fn from_seed(seed : BytesView) -> SplitMix64 {
  SplitMix64::new(seed)
}

///|
pub impl @contract.Seeded for SplitMix64 with fn seed_size() -> Int32 {
  8
}

///|
pub extend SplitMix64 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend SplitMix64 with @contract.Seeded::{from_seed, seed_size}
