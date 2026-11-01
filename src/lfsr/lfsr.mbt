///|
/// Shift-register generators: one LFSR, one generalized feedback register, and
/// the combined forms L'Ecuyer built out of several. A single LFSR is linear —
/// its next bit is a linear function of the state — which is what the combined
/// forms exist to hide.

///|
/// Lfsr64: a Galois register over the maximal-period polynomial
/// x^64 + x^63 + x^61 + x^60.
pub struct Lfsr64 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over `state`, which must not be zero: zero is the fixed point of
/// every shift register.
pub fn Lfsr64::with_state(state : UInt64) -> Lfsr64 {
  { s: [if state == 0UL { 1UL } else { state }], }
}

///|
/// A generator from eight bytes.
pub fn Lfsr64::new(seed : BytesView) -> Lfsr64 {
  Lfsr64::with_state(@bits.seed_words(seed, 1)[0])
}

///|
pub impl @contract.Rng for Lfsr64 with fn next_u64(self) -> UInt64 {
  let x = self.s[0]
  let next = if (x & 1UL) == 1UL {
    (x >> 1) ^ 0xD800000000000000UL
  } else {
    x >> 1
  }
  self.s[0] = next
  next
}

///|
pub impl @contract.Seeded for Lfsr64 with fn from_seed(seed : BytesView) -> Lfsr64 {
  Lfsr64::new(seed)
}

///|
pub impl @contract.Seeded for Lfsr64 with fn seed_size() -> Int32 {
  8
}

///|
/// Gfsr: a generalized feedback shift register of 250 words, each new word the
/// xor of itself and the word 103 places back — Lewis and Payne's parameters.
pub struct Gfsr {
  priv s : FixedArray[UInt32]
  priv i : FixedArray[Int32]
}

///|
/// A generator over the 250 state words, starting at index zero.
pub fn Gfsr::from_state(s : FixedArray[UInt32]) -> Gfsr {
  if s.length() != 250 {
    abort("Gfsr: state is 250 words")
  }
  { s, i: [0], }
}

///|
/// A generator from 250 words of SplitMix64 output.
pub fn Gfsr::new(seed : BytesView) -> Gfsr {
  let w = @bits.seed_words(seed, 125)
  let s = FixedArray::make(250, 0U)
  let mut any = false
  for i = 0; i < 125; i = i + 1 {
    s[i * 2] = w[i].to_uint()
    s[i * 2 + 1] = (w[i] >> 32).to_uint()
    any = any || s[i * 2] != 0U
  }
  if !any {
    s[0] = 1U
  }
  Gfsr::from_state(s)
}

///|
pub impl @contract.Rng for Gfsr with fn next_u32(self) -> UInt32 {
  let nxt = (self.i[0] + 103) % 250
  let v = self.s[self.i[0]] ^ self.s[nxt]
  self.s[self.i[0]] = v
  self.i[0] = nxt
  v
}

///|
pub impl @contract.Rng for Gfsr with fn next_u64(self) -> UInt64 {
  (self.next_u32().to_uint64() << 32) | self.next_u32().to_uint64()
}

///|
pub impl @contract.Seeded for Gfsr with fn from_seed(seed : BytesView) -> Gfsr {
  Gfsr::new(seed)
}

///|
pub impl @contract.Seeded for Gfsr with fn seed_size() -> Int32 {
  1000
}

///|
/// Taus88: three Tausworthe registers combined by xor, L'Ecuyer's 1996
/// generator; the periods multiply out to about 2^88.
pub struct Taus88 {
  priv s : FixedArray[UInt32]
}

///|
/// A generator over the three component states.
pub fn Taus88::with_state(s1 : UInt32, s2 : UInt32, s3 : UInt32) -> Taus88 {
  { s: [s1, s2, s3], }
}

///|
/// A generator from twelve bytes through SplitMix64, each component moved into
/// its admissible range: above 1, 7 and 15 respectively.
pub fn Taus88::new(seed : BytesView) -> Taus88 {
  let w = @bits.seed_words(seed, 2)
  let s1 = w[0].to_uint()
  let s2 = (w[0] >> 32).to_uint()
  let s3 = w[1].to_uint()
  Taus88::with_state(
    if s1 > 1U {
      s1
    } else {
      2U
    },
    if s2 > 7U {
      s2
    } else {
      8U
    },
    if s3 > 15U {
      s3
    } else {
      16U
    },
  )
}

///|
pub impl @contract.Rng for Taus88 with fn next_u32(self) -> UInt32 {
  let s1 = ((self.s[0] & 0xFFFFFFFEU) << 12) ^
    (((self.s[0] << 13) ^ self.s[0]) >> 19)
  let s2 = ((self.s[1] & 0xFFFFFFF8U) << 4) ^
    (((self.s[1] << 2) ^ self.s[1]) >> 25)
  let s3 = ((self.s[2] & 0xFFFFFFF0U) << 17) ^
    (((self.s[2] << 3) ^ self.s[2]) >> 11)
  self.s[0] = s1
  self.s[1] = s2
  self.s[2] = s3
  s1 ^ s2 ^ s3
}

///|
pub impl @contract.Rng for Taus88 with fn next_u64(self) -> UInt64 {
  (self.next_u32().to_uint64() << 32) | self.next_u32().to_uint64()
}

///|
pub impl @contract.Seeded for Taus88 with fn from_seed(seed : BytesView) -> Taus88 {
  Taus88::new(seed)
}

///|
pub impl @contract.Seeded for Taus88 with fn seed_size() -> Int32 {
  12
}

///|
/// Lfsr113: four combined linear feedback registers, period near 2^113.
pub struct Lfsr113 {
  priv s : FixedArray[UInt32]
}

///|
/// A generator over the four component states.
pub fn Lfsr113::with_state(
  s1 : UInt32,
  s2 : UInt32,
  s3 : UInt32,
  s4 : UInt32,
) -> Lfsr113 {
  { s: [s1, s2, s3, s4], }
}

///|
/// A generator from sixteen bytes through SplitMix64, each component moved above
/// 1, 7, 15 and 127 respectively.
pub fn Lfsr113::new(seed : BytesView) -> Lfsr113 {
  let w = @bits.seed_words(seed, 2)
  let s1 = w[0].to_uint()
  let s2 = (w[0] >> 32).to_uint()
  let s3 = w[1].to_uint()
  let s4 = (w[1] >> 32).to_uint()
  Lfsr113::with_state(
    if s1 > 1U {
      s1
    } else {
      2U
    },
    if s2 > 7U {
      s2
    } else {
      8U
    },
    if s3 > 15U {
      s3
    } else {
      16U
    },
    if s4 > 127U {
      s4
    } else {
      128U
    },
  )
}

///|
pub impl @contract.Rng for Lfsr113 with fn next_u32(self) -> UInt32 {
  let z1 = ((self.s[0] & 0xFFFFFFFEU) << 18) ^
    (((self.s[0] << 6) ^ self.s[0]) >> 13)
  let z2 = ((self.s[1] & 0xFFFFFFF8U) << 2) ^
    (((self.s[1] << 2) ^ self.s[1]) >> 27)
  let z3 = ((self.s[2] & 0xFFFFFFF0U) << 7) ^
    (((self.s[2] << 13) ^ self.s[2]) >> 21)
  let z4 = ((self.s[3] & 0xFFFFFF80U) << 13) ^
    (((self.s[3] << 3) ^ self.s[3]) >> 12)
  self.s[0] = z1
  self.s[1] = z2
  self.s[2] = z3
  self.s[3] = z4
  z1 ^ z2 ^ z3 ^ z4
}

///|
pub impl @contract.Rng for Lfsr113 with fn next_u64(self) -> UInt64 {
  (self.next_u32().to_uint64() << 32) | self.next_u32().to_uint64()
}

///|
pub impl @contract.Seeded for Lfsr113 with fn from_seed(seed : BytesView) -> Lfsr113 {
  Lfsr113::new(seed)
}

///|
pub impl @contract.Seeded for Lfsr113 with fn seed_size() -> Int32 {
  16
}

///|
/// Lfsr258: five combined linear feedback registers over 64-bit words, period
/// near 2^258. The shifts and masks are L'Ecuyer's; each component keeps its low
/// bits clear so that its recurrence has the stated period.
pub struct Lfsr258 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over the five component states.
pub fn Lfsr258::with_state(
  s1 : UInt64,
  s2 : UInt64,
  s3 : UInt64,
  s4 : UInt64,
  s5 : UInt64,
) -> Lfsr258 {
  { s: [s1, s2, s3, s4, s5], }
}

///|
/// A generator from forty bytes through SplitMix64, each component moved into
/// its admissible range.
pub fn Lfsr258::new(seed : BytesView) -> Lfsr258 {
  let w = @bits.seed_words(seed, 5)
  Lfsr258::with_state(
    if w[0] > 1UL {
      w[0]
    } else {
      2UL
    },
    if w[1] > 511UL {
      w[1]
    } else {
      512UL
    },
    if w[2] > 4095UL {
      w[2]
    } else {
      4096UL
    },
    if w[3] > 131071UL {
      w[3]
    } else {
      131072UL
    },
    if w[4] > 8388607UL {
      w[4]
    } else {
      8388608UL
    },
  )
}

///|
pub impl @contract.Rng for Lfsr258 with fn next_u64(self) -> UInt64 {
  let z1 = ((self.s[0] & 0xFFFFFFFFFFFFFFFEUL) << 10) ^
    (((self.s[0] << 1) ^ self.s[0]) >> 53)
  let z2 = ((self.s[1] & 0xFFFFFFFFFFFFFE00UL) << 5) ^
    (((self.s[1] << 24) ^ self.s[1]) >> 50)
  let z3 = ((self.s[2] & 0xFFFFFFFFFFFFF000UL) << 29) ^
    (((self.s[2] << 3) ^ self.s[2]) >> 23)
  let z4 = ((self.s[3] & 0xFFFFFFFFFFFE0000UL) << 23) ^
    (((self.s[3] << 5) ^ self.s[3]) >> 24)
  let z5 = ((self.s[4] & 0xFFFFFFFFFF800000UL) << 8) ^
    (((self.s[4] << 3) ^ self.s[4]) >> 33)
  self.s[0] = z1
  self.s[1] = z2
  self.s[2] = z3
  self.s[3] = z4
  self.s[4] = z5
  z1 ^ z2 ^ z3 ^ z4 ^ z5
}

///|
pub impl @contract.Seeded for Lfsr258 with fn from_seed(seed : BytesView) -> Lfsr258 {
  Lfsr258::new(seed)
}

///|
pub impl @contract.Seeded for Lfsr258 with fn seed_size() -> Int32 {
  40
}

///|
pub extend Lfsr64 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Lfsr64 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Gfsr with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Gfsr with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Taus88 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Taus88 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Lfsr113 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Lfsr113 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Lfsr258 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Lfsr258 with @contract.Seeded::{from_seed, seed_size}
