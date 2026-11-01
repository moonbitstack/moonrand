///|
/// The PCG family: a linear congruential state whose bits are permuted as the
/// output, so the low bits of the LCG never reach the caller unpermuted.
const PCG32_MULT : UInt64 = 6364136223846793005UL

///|
/// PCG32: a 64-bit LCG, 32 bits of permuted output. The increment names the
/// stream; two generators with different increments never meet.
pub struct Pcg32 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over the LCG state `state` and the stream `inc`. The reference
/// makes `inc` odd, and so does this.
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
/// The reference `pcg32_srandom` seeding: `stream` names the sequence and
/// `seed` picks the place in it, so two streams never overlap.
pub fn Pcg32::with_stream(seed : UInt64, stream : UInt64) -> Pcg32 {
  let g = Pcg32::with_state(0UL, (stream << 1) | 1UL)
  ignore(pcg32_word(g.s))
  g.s[0] = g.s[0] + seed
  ignore(pcg32_word(g.s))
  g
}

///|
/// Skip the next `n` draws of the underlying LCG, by stepping the state `n`
/// times without asking for the output.
pub fn Pcg32::advance(self : Pcg32, n : UInt64) -> Unit {
  let mut acc_mult = 1UL
  let mut acc_plus = 0UL
  let mut cur_mult = PCG32_MULT
  let mut cur_plus = self.s[1]
  let mut delta = n
  while delta > 0UL {
    if (delta & 1UL) == 1UL {
      acc_mult = acc_mult * cur_mult
      acc_plus = acc_plus * cur_mult + cur_plus
    }
    cur_plus = (cur_mult + 1UL) * cur_plus
    cur_mult = cur_mult * cur_mult
    delta = delta >> 1
  }
  self.s[0] = acc_mult * self.s[0] + acc_plus
}

///|
/// One 32-bit output: xorshift the state down to 32 bits, then rotate by the
/// top five bits of the old state.
fn pcg32_word(s : FixedArray[UInt64]) -> UInt32 {
  let old = s[0]
  s[0] = old * PCG32_MULT + s[1]
  let xored = (((old >> 18) ^ old) >> 27).to_uint()
  let rot = (old >> 59).to_int()
  (xored >> rot) | (xored << ((32 - rot) & 31))
}

///|
pub impl @contract.Rng for Pcg32 with fn next_u64(self) -> UInt64 {
  (pcg32_word(self.s).to_uint64() << 32) | pcg32_word(self.s).to_uint64()
}

///|
pub impl @contract.Rng for Pcg32 with fn next_u32(self) -> UInt32 {
  pcg32_word(self.s)
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
/// The 128-bit multiplier of PCG64, as its two halves.
const PCG64_MULT_LO : UInt64 = 0x4385DF649FCCF645UL

///|
const PCG64_MULT_HI : UInt64 = 0x2360ED051FC65DA4UL

///|
/// Two-word multiplication, low half first: (a * b) mod 2^128.
fn mul128(a : FixedArray[UInt64], b : FixedArray[UInt64]) -> FixedArray[UInt64] {
  [a[0] * b[0], @bits.mul_hi(a[0], b[0]) + a[0] * b[1] + a[1] * b[0]]
}

///|
/// Two-word addition, low half first: (a + b) mod 2^128.
fn add128(a : FixedArray[UInt64], b : FixedArray[UInt64]) -> FixedArray[UInt64] {
  let lo = a[0] + b[0]
  [lo, a[1] + b[1] + (if lo < a[0] { 1UL } else { 0UL })]
}

///|
/// Step a 128-bit LCG state, held as `w[0..1]` with the low half first, one
/// step with the PCG64 multiplier and the increment `w[2..3]`.
fn pcg64_step(w : FixedArray[UInt64]) -> Unit {
  let lo = w[0]
  let hi = w[1]
  let new_lo = lo * PCG64_MULT_LO
  let new_hi = @bits.mul_hi(lo, PCG64_MULT_LO) +
    lo * PCG64_MULT_HI +
    hi * PCG64_MULT_LO
  let (sum_lo, carry) = {
    let s = new_lo + w[2]
    (s, if s < new_lo { 1UL } else { 0UL })
  }
  w[0] = sum_lo
  w[1] = new_hi + w[3] + carry
}

///|
/// PCG64: a 128-bit LCG with the XSL-RR output, the permutation NumPy's default
/// generator uses.
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
  { s: [state_lo, state_hi, inc_lo | 1UL, inc_hi], }
}

///|
/// A generator from thirty-two bytes: sixteen of state, sixteen of stream.
pub fn Pcg64::new(seed : BytesView) -> Pcg64 {
  let w = @bits.seed_words(seed, 4)
  Pcg64::with_state(w[0], w[1], w[2], w[3])
}

///|
/// Skip the next `n` draws of the underlying LCG, by stepping the state `n`
/// times without asking for the output.
pub fn Pcg64::advance(self : Pcg64, n : UInt64) -> Unit {
  let acc_mult : FixedArray[UInt64] = [1UL, 0UL]
  let acc_plus : FixedArray[UInt64] = [0UL, 0UL]
  let cur_mult : FixedArray[UInt64] = [PCG64_MULT_LO, PCG64_MULT_HI]
  let cur_plus : FixedArray[UInt64] = [self.s[2], self.s[3]]
  let mut delta = n
  while delta > 0UL {
    if (delta & 1UL) == 1UL {
      let m = mul128(acc_mult, cur_mult)
      acc_mult[0] = m[0]
      acc_mult[1] = m[1]
      let p = add128(mul128(acc_plus, cur_mult), cur_plus)
      acc_plus[0] = p[0]
      acc_plus[1] = p[1]
    }
    let one : FixedArray[UInt64] = [1UL, 0UL]
    let plus = add128(cur_mult, one)
    let cp = mul128(plus, cur_plus)
    cur_plus[0] = cp[0]
    cur_plus[1] = cp[1]
    let cm = mul128(cur_mult, cur_mult)
    cur_mult[0] = cm[0]
    cur_mult[1] = cm[1]
    delta = delta >> 1
  }
  let state : FixedArray[UInt64] = [self.s[0], self.s[1]]
  let m = mul128(acc_mult, state)
  let r = add128(m, acc_plus)
  self.s[0] = r[0]
  self.s[1] = r[1]
}

///|
/// The XSL-RR permutation: xor the halves, rotate by the top six bits of the
/// state.
fn pcg64_word(s : FixedArray[UInt64]) -> UInt64 {
  let old_lo = s[0]
  let old_hi = s[1]
  pcg64_step(s)
  let x = old_hi ^ old_lo
  let rot = (old_hi >> 58).to_int()
  if rot == 0 {
    x
  } else {
    (x >> rot) | (x << (64 - rot))
  }
}

///|
pub impl @contract.Rng for Pcg64 with fn next_u64(self) -> UInt64 {
  pcg64_word(self.s)
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
/// The DXSM multiplier, the one the PCG author recommends for 64-bit outputs.
const DXSM_MULT : UInt64 = 0xDA942042E4DD58B5UL

///|
/// PCG64-DXSM: a 128-bit LCG with the double-xorshift-multiply output.
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
  { s: [state_lo, state_hi, inc_lo | 1UL, inc_hi], }
}

///|
/// A generator from thirty-two bytes: sixteen of state, sixteen of stream.
pub fn Pcg64Dxsm::new(seed : BytesView) -> Pcg64Dxsm {
  let w = @bits.seed_words(seed, 4)
  Pcg64Dxsm::with_state(w[0], w[1], w[2], w[3])
}

///|
/// The DXSM permutation: xorshift the high half twice around a multiply, then
/// multiply by the low half.
fn dxsm_word(s : FixedArray[UInt64]) -> UInt64 {
  let lo = s[0]
  let hi = s[1]
  pcg64_step(s)
  let a = (hi ^ (hi >> 32)) * DXSM_MULT
  let b = a ^ (a >> 48)
  b * lo
}

///|
pub impl @contract.Rng for Pcg64Dxsm with fn next_u64(self) -> UInt64 {
  dxsm_word(self.s)
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
