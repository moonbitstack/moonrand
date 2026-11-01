///|
/// LXM: a linear congruential generator added to an xoroshiro one. The LCG is
/// there for the period — it is one long cycle with no state to fall into — and
/// the xoroshiro is there for the bits; adding them is what Vigna's paper does,
/// and it is why the low bits of the sum are not the LCG's low bits.
///
/// Both halves are stepped together, so `jump` has to move both to the same
/// distance: 2^128 calls, which is the xoroshiro jump taken twice (or the
/// xoshiro256 jump once) and the LCG half squared 128 times.

///|
/// The LCG multiplier and increment of LXM.
const LXM_MULT : UInt64 = 0xD1342543DE82EF95UL

///|
fn rotl64(x : UInt64, k : Int32) -> UInt64 {
  (x << k) | (x >> (64 - k))
}

///|
/// The xoroshiro128+ transition on `s[1..2]`.
fn xoro_step(s : FixedArray[UInt64]) -> Unit {
  let s0 = s[1]
  let s1 = s[2] ^ s0
  s[1] = rotl64(s0, 24) ^ s1 ^ (s1 << 16)
  s[2] = rotl64(s1, 37)
}

///|
/// Two jumps of the xoroshiro half, 2^64 calls each, with the same accumulate
/// and step loop the reference uses.
fn xoro_jump(s : FixedArray[UInt64], poly : FixedArray[UInt64]) -> Unit {
  let t : FixedArray[UInt64] = [0UL, 0UL, 0UL]
  for i = 0; i < poly.length(); i = i + 1 {
    for b = 0; b < 64; b = b + 1 {
      if (poly[i] & (1UL << b)) != 0UL {
        t[1] = t[1] ^ s[1]
        t[2] = t[2] ^ s[2]
      }
      xoro_step(s)
    }
  }
  s[1] = t[1]
  s[2] = t[2]
}

///|
/// L64X128: a 64-bit LCG over xoroshiro128+.
pub struct L64X128 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over the LCG state `lcg` and the xoroshiro state `s0`, `s1`.
pub fn L64X128::with_state(lcg : UInt64, s0 : UInt64, s1 : UInt64) -> L64X128 {
  { s: [lcg, s0, s1], }
}

///|
/// A generator from twenty-four bytes through SplitMix64.
pub fn L64X128::new(seed : BytesView) -> L64X128 {
  let w = @bits.seed_words(seed, 3)
  L64X128::with_state(w[0], w[1], w[2])
}

///|
/// Skip 2^128 draws: both halves move together, or the sum stops meaning
/// anything.
pub fn L64X128::jump(self : L64X128) -> Unit {
  let poly : FixedArray[UInt64] = [0xDF900294D8F554A5UL, 0x170865DF4B3201FCUL]
  xoro_jump(self.s, poly)
  xoro_jump(self.s, poly)
  // The LCG half: A^(2^128) and the matching addend, by squaring the affine
  // map 128 times.
  let mut m = LXM_MULT
  let mut a = 1UL
  for _i = 0; _i < 128; _i = _i + 1 {
    a = a * (m + 1UL)
    m = m * m
  }
  self.s[0] = a * self.s[0] + a
}

///|
pub impl @contract.Rng for L64X128 with fn next_u64(self) -> UInt64 {
  let result = self.s[1] + self.s[2] + self.s[0]
  xoro_step(self.s)
  self.s[0] = self.s[0] * LXM_MULT + 1UL
  result
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
/// L64X256: the same LCG over xoshiro256+.
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
  { s: [lcg, s0, s1, s2, s3], }
}

///|
/// A generator from forty bytes through SplitMix64.
pub fn L64X256::new(seed : BytesView) -> L64X256 {
  let w = @bits.seed_words(seed, 5)
  L64X256::with_state(w[0], w[1], w[2], w[3], w[4])
}

///|
/// The xoshiro256 transition, on `s[1..4]`.
fn xoshiro256_step(s : FixedArray[UInt64]) -> Unit {
  let t = s[2] << 17
  s[3] = s[3] ^ s[1]
  s[4] = s[4] ^ s[2]
  s[2] = s[2] ^ s[3]
  s[1] = s[1] ^ s[4]
  s[3] = s[3] ^ t
  s[4] = rotl64(s[4], 45)
}

///|
/// Skip 2^128 draws, both halves together: the xoshiro half takes its own
/// 2^128 jump once, the LCG half squares its affine map 128 times.
pub fn L64X256::jump(self : L64X256) -> Unit {
  let poly : FixedArray[UInt64] = [
    0x180EC6D33CFD0ABAUL, 0xD5A61266F0C9392CUL, 0xA9582618E03FC9AAUL, 0x39ABDC4529B1661CUL,
  ]
  let t : FixedArray[UInt64] = [0UL, 0UL, 0UL, 0UL, 0UL]
  for i = 0; i < poly.length(); i = i + 1 {
    for b = 0; b < 64; b = b + 1 {
      if (poly[i] & (1UL << b)) != 0UL {
        for k = 1; k < 5; k = k + 1 {
          t[k] = t[k] ^ self.s[k]
        }
      }
      xoshiro256_step(self.s)
    }
  }
  for k = 1; k < 5; k = k + 1 {
    self.s[k] = t[k]
  }
  let mut m = LXM_MULT
  let mut a = 1UL
  for _i = 0; _i < 128; _i = _i + 1 {
    a = a * (m + 1UL)
    m = m * m
  }
  self.s[0] = a * self.s[0] + a
}

///|
pub impl @contract.Rng for L64X256 with fn next_u64(self) -> UInt64 {
  let result = self.s[1] + self.s[4] + self.s[0]
  xoshiro256_step(self.s)
  self.s[0] = self.s[0] * LXM_MULT + 1UL
  result
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
