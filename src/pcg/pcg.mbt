///|
/// PCG32: a 64-bit linear congruential state, 32 bits of permuted output. The
/// increment names the stream; two generators with different increments never
/// meet.
pub struct Pcg32 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over the LCG state `state` and the stream `inc`. The reference
/// makes `inc` odd; this does too.
pub fn Pcg32::with_state(state : UInt64, inc : UInt64) -> Pcg32 {
  { s: [state, inc | 1UL], }
}

///|
/// A generator from sixteen bytes: eight for the state, eight for the stream.
pub fn Pcg32::new(seed : BytesView) -> Pcg32 {
  let w = @bits.seed_words(seed, 2)
  Pcg32::with_state(w[0], w[1])
}

///|
/// Skip the next `n` draws of the underlying LCG.
pub fn Pcg32::advance(self : Pcg32, n : UInt64) -> Unit {
  ignore(self.s)
  ignore(n)
  abort("moonrand/pcg: no implementation yet")
}

///|
/// PCG64: a 128-bit LCG with the XSL-RR output permutation.
pub struct Pcg64 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over the 128-bit state `state_lo` + `state_hi` and the 128-bit
/// stream `inc_lo` + `inc_hi`.
pub fn Pcg64::with_state(
  state_lo : UInt64,
  state_hi : UInt64,
  inc_lo : UInt64,
  inc_hi : UInt64,
) -> Pcg64 {
  { s: [state_lo, state_hi, inc_lo, inc_hi | 1UL], }
}

///|
/// A generator from thirty-two bytes: sixteen of state, sixteen of stream.
pub fn Pcg64::new(seed : BytesView) -> Pcg64 {
  let w = @bits.seed_words(seed, 4)
  Pcg64::with_state(w[0], w[1], w[2], w[3])
}

///|
/// Skip the next `n` draws of the underlying LCG.
pub fn Pcg64::advance(self : Pcg64, n : UInt64) -> Unit {
  ignore(self.s)
  ignore(n)
  abort("moonrand/pcg: no implementation yet")
}

///|
/// PCG64-DXSM: a 128-bit LCG with the double-xorshift-multiply output, the
/// permutation the PCG author recommends for 64-bit outputs.
pub struct Pcg64Dxsm {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over the 128-bit state and the 128-bit stream.
pub fn Pcg64Dxsm::with_state(
  state_lo : UInt64,
  state_hi : UInt64,
  inc_lo : UInt64,
  inc_hi : UInt64,
) -> Pcg64Dxsm {
  { s: [state_lo, state_hi, inc_lo, inc_hi | 1UL], }
}

///|
/// A generator from thirty-two bytes: sixteen of state, sixteen of stream.
pub fn Pcg64Dxsm::new(seed : BytesView) -> Pcg64Dxsm {
  let w = @bits.seed_words(seed, 4)
  Pcg64Dxsm::with_state(w[0], w[1], w[2], w[3])
}

///|
/// Skip the next `n` draws of the underlying LCG.
pub fn Pcg64Dxsm::advance(self : Pcg64Dxsm, n : UInt64) -> Unit {
  ignore(self.s)
  ignore(n)
  abort("moonrand/pcg: no implementation yet")
}

///|
pub impl @contract.Rng for Pcg32 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Pcg32: no implementation yet")
}

///|
pub impl @contract.Rng for Pcg64 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Pcg64: no implementation yet")
}

///|
pub impl @contract.Rng for Pcg64Dxsm with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Pcg64Dxsm: no implementation yet")
}

///|
pub impl @contract.Seeded for Pcg32 with fn from_seed(seed : BytesView) -> Pcg32 {
  Pcg32::new(seed)
}

///|
pub impl @contract.Seeded for Pcg32 with fn seed_size() -> Int32 {
  16
}

///|
pub impl @contract.Seeded for Pcg64 with fn from_seed(seed : BytesView) -> Pcg64 {
  Pcg64::new(seed)
}

///|
pub impl @contract.Seeded for Pcg64 with fn seed_size() -> Int32 {
  32
}

///|
pub impl @contract.Seeded for Pcg64Dxsm with fn from_seed(seed : BytesView) -> Pcg64Dxsm {
  Pcg64Dxsm::new(seed)
}

///|
pub impl @contract.Seeded for Pcg64Dxsm with fn seed_size() -> Int32 {
  32
}

///|
pub extend Pcg32 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Pcg32 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Pcg64 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Pcg64 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Pcg64Dxsm with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Pcg64Dxsm with @contract.Seeded::{from_seed, seed_size}
