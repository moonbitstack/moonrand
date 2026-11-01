///|
/// Congruential generators, linear and polynomial, plus the inversive one:
/// the oldest family, kept because their periods and their faults are both
/// exactly known.
pub struct Lcg64 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator with `multiplier`, `increment` and the starting `seed`: the
/// recurrence is x := multiplier * x + increment modulo 2^64.
pub fn Lcg64::with_params(
  multiplier : UInt64,
  increment : UInt64,
  seed : UInt64,
) -> Lcg64 {
  { s: [seed, multiplier, increment], }
}

///|
/// The parameters the C library and glibc use.
pub fn Lcg64::glibc(seed : UInt64) -> Lcg64 {
  Lcg64::with_params(1103515245UL, 12345UL, seed)
}

///|
/// The parameters Numerical Recipes prints.
pub fn Lcg64::numerical_recipes(seed : UInt64) -> Lcg64 {
  Lcg64::with_params(1664525UL, 1013904223UL, seed)
}

///|
/// A generator from eight bytes, with the Numerical Recipes parameters.
pub fn Lcg64::new(seed : BytesView) -> Lcg64 {
  Lcg64::numerical_recipes(@bits.seed_words(seed, 1)[0])
}

///|
pub impl @contract.Rng for Lcg64 with fn next_u64(self) -> UInt64 {
  self.s[0] = self.s[0] * self.s[1] + self.s[2]
  self.s[0]
}

///|
pub impl @contract.Seeded for Lcg64 with fn from_seed(seed : BytesView) -> Lcg64 {
  Lcg64::new(seed)
}

///|
pub impl @contract.Seeded for Lcg64 with fn seed_size() -> Int32 {
  8
}

///|
/// Lcg48: the 48-bit generator behind `drand48`, x := 0x5DEECE66D x + 0xB
/// modulo 2^48.
pub struct Lcg48 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over `state`, of which only the low 48 bits count.
pub fn Lcg48::with_state(state : UInt64) -> Lcg48 {
  { s: [state & 0xFFFFFFFFFFFFUL], }
}

///|
/// A generator from eight bytes, as `srand48` takes them.
pub fn Lcg48::new(seed : BytesView) -> Lcg48 {
  Lcg48::with_state(@bits.seed_words(seed, 1)[0])
}

///|
/// The high 32 bits of the 48-bit state: what `drand48` scales into [0, 1).
fn lcg48_word(g : Lcg48) -> UInt32 {
  g.s[0] = (g.s[0] * 0x5DEECE66DUL + 0xBUL) & 0xFFFFFFFFFFFFUL
  (g.s[0] >> 16).to_uint()
}

///|
pub impl @contract.Rng for Lcg48 with fn next_u32(self) -> UInt32 {
  lcg48_word(self)
}

///|
pub impl @contract.Rng for Lcg48 with fn next_u64(self) -> UInt64 {
  (lcg48_word(self).to_uint64() << 32) | lcg48_word(self).to_uint64()
}

///|
pub impl @contract.Seeded for Lcg48 with fn from_seed(seed : BytesView) -> Lcg48 {
  Lcg48::new(seed)
}

///|
pub impl @contract.Seeded for Lcg48 with fn seed_size() -> Int32 {
  8
}

///|
/// MinStd: the minimal standard generator, x := 16807 x modulo 2^31-1, the
/// multiplicative one Park and Miller recommended.
pub struct MinStd {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over `state`, which must be in [1, 2^31-2].
pub fn MinStd::with_state(state : UInt64) -> MinStd {
  let m = 2147483647UL
  let v = state % m
  { s: [if v == 0UL { 1UL } else { v }], }
}

///|
/// A generator from eight bytes, mapped into the usable range.
pub fn MinStd::new(seed : BytesView) -> MinStd {
  MinStd::with_state(@bits.seed_words(seed, 1)[0])
}

///|
pub impl @contract.Rng for MinStd with fn next_u64(self) -> UInt64 {
  self.s[0] = self.s[0] * 16807UL % 2147483647UL
  self.s[0]
}

///|
pub impl @contract.Seeded for MinStd with fn from_seed(seed : BytesView) -> MinStd {
  MinStd::new(seed)
}

///|
pub impl @contract.Seeded for MinStd with fn seed_size() -> Int32 {
  8
}

///|
/// Qcg64: a quadratic congruential generator, x := a x^2 + c modulo 2^64. The
/// state is rotated by half a word before it leaves, because the low bits of a
/// polynomial recurrence are the weak ones.
pub struct Qcg64 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator with `multiplier` and `increment` (both odd is the useful
/// choice) and the starting `seed`.
pub fn Qcg64::with_params(
  multiplier : UInt64,
  increment : UInt64,
  seed : UInt64,
) -> Qcg64 {
  { s: [seed, multiplier, increment], }
}

///|
/// A generator from eight bytes.
pub fn Qcg64::new(seed : BytesView) -> Qcg64 {
  Qcg64::with_params(0x9E3779B97F4A7C15UL, 1UL, @bits.seed_words(seed, 1)[0])
}

///|
pub impl @contract.Rng for Qcg64 with fn next_u64(self) -> UInt64 {
  let x = self.s[1] * self.s[0] * self.s[0] + self.s[2]
  self.s[0] = x
  (x >> 32) | (x << 32)
}

///|
pub impl @contract.Seeded for Qcg64 with fn from_seed(seed : BytesView) -> Qcg64 {
  Qcg64::new(seed)
}

///|
pub impl @contract.Seeded for Qcg64 with fn seed_size() -> Int32 {
  8
}

///|
/// Ccg64: a cubic congruential generator, x := a x^3 + b x^2 + c modulo 2^64,
/// rotated by half a word as it leaves.
pub struct Ccg64 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator with the three coefficients and the starting `seed`.
pub fn Ccg64::with_params(
  a : UInt64,
  b : UInt64,
  c : UInt64,
  seed : UInt64,
) -> Ccg64 {
  { s: [seed, a, b, c], }
}

///|
/// A generator from eight bytes.
pub fn Ccg64::new(seed : BytesView) -> Ccg64 {
  Ccg64::with_params(
    0x9E3779B97F4A7C15UL,
    0xBF58476D1CE4E5B9UL,
    1UL,
    @bits.seed_words(seed, 1)[0],
  )
}

///|
pub impl @contract.Rng for Ccg64 with fn next_u64(self) -> UInt64 {
  let x = self.s[0]
  let y = self.s[1] * x * x * x + self.s[2] * x * x + self.s[3]
  self.s[0] = y
  (y >> 32) | (y << 32)
}

///|
pub impl @contract.Seeded for Ccg64 with fn from_seed(seed : BytesView) -> Ccg64 {
  Ccg64::new(seed)
}

///|
pub impl @contract.Seeded for Ccg64 with fn seed_size() -> Int32 {
  8
}

///|
/// The prime modulus of the inversive generator: the largest prime below 2^32.
const ICG_MOD : Int64 = 4294967291L

///|
/// The modular inverse of `x` modulo ICG_MOD, by the extended Euclidean
/// algorithm; `x` must not be zero.
fn icg_inverse(x : Int64) -> Int64 {
  let mut t = 0L
  let mut new_t = 1L
  let mut r = ICG_MOD
  let mut new_r = x % ICG_MOD
  while new_r != 0L {
    let q = r / new_r
    let t2 = t - q * new_t
    t = new_t
    new_t = t2
    let r2 = r - q * new_r
    r = new_r
    new_r = r2
  }
  if t < 0L {
    t = t + ICG_MOD
  }
  t
}

///|
/// Icg32: an inversive congruential generator, x := a x^-1 + c modulo the
/// prime 2^32-5. Unlike every other generator here the map is not linear, so
/// the low bits are as good as the high ones.
pub struct Icg32 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator with `multiplier`, `increment` and the starting `seed`, all
/// taken modulo the prime.
pub fn Icg32::with_params(
  multiplier : UInt64,
  increment : UInt64,
  seed : UInt64,
) -> Icg32 {
  {
    s: [
      seed % 4294967291UL,
      multiplier % 4294967291UL,
      increment % 4294967291UL,
    ],
  }
}

///|
/// A generator from eight bytes.
pub fn Icg32::new(seed : BytesView) -> Icg32 {
  Icg32::with_params(12345UL, 1013904223UL, @bits.seed_words(seed, 1)[0])
}

///|
fn icg32_word(g : Icg32) -> UInt32 {
  let x = g.s[0]
  let inv = if x == 0UL { 0L } else { icg_inverse(x.reinterpret_as_int64()) }
  let next = (
      g.s[1].reinterpret_as_int64() * inv + g.s[2].reinterpret_as_int64()
    ) %
    ICG_MOD
  g.s[0] = next.reinterpret_as_uint64()
  next.to_int().reinterpret_as_uint()
}

///|
pub impl @contract.Rng for Icg32 with fn next_u32(self) -> UInt32 {
  icg32_word(self)
}

///|
pub impl @contract.Rng for Icg32 with fn next_u64(self) -> UInt64 {
  (icg32_word(self).to_uint64() << 32) | icg32_word(self).to_uint64()
}

///|
pub impl @contract.Seeded for Icg32 with fn from_seed(seed : BytesView) -> Icg32 {
  Icg32::new(seed)
}

///|
pub impl @contract.Seeded for Icg32 with fn seed_size() -> Int32 {
  8
}

///|
pub extend Lcg64 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Lcg64 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Lcg48 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Lcg48 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend MinStd with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend MinStd with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Qcg64 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Qcg64 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Ccg64 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Ccg64 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Icg32 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Icg32 with @contract.Seeded::{from_seed, seed_size}
