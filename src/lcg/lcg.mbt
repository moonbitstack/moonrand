///|
/// Lcg64: a linear congruential generator modulo 2^64.
pub struct Lcg64 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator with `multiplier`, `increment` and the starting `seed`.
pub fn Lcg64::with_params(
  multiplier : UInt64,
  increment : UInt64,
  seed : UInt64,
) -> Lcg64 {
  ignore((multiplier, increment, seed))
  { s: FixedArray::make(3, 0UL), }
}

///|
/// The parameters glibc and the C library use.
pub fn Lcg64::glibc(seed : UInt64) -> Lcg64 {
  ignore(seed)
  { s: FixedArray::make(3, 0UL), }
}

///|
/// The parameters Numerical Recipes prints.
pub fn Lcg64::numerical_recipes(seed : UInt64) -> Lcg64 {
  ignore(seed)
  { s: FixedArray::make(3, 0UL), }
}

///|
/// A generator seeded from a byte seed.
pub fn Lcg64::new(seed : BytesView) -> Lcg64 {
  ignore(seed)
  { s: FixedArray::make(3, 0UL), }
}

///|
pub impl @contract.Rng for Lcg64 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Lcg64: no implementation yet")
}

///|
/// Lcg48: the 48-bit linear congruential generator behind drand48.
pub struct Lcg48 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator seeded from a byte seed.
pub fn Lcg48::new(seed : BytesView) -> Lcg48 {
  ignore(seed)
  { s: FixedArray::make(1, 0UL), }
}

///|
pub impl @contract.Rng for Lcg48 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Lcg48: no implementation yet")
}

///|
/// MinStd: the minimal standard generator, 16807 modulo 2^31-1.
pub struct MinStd {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over `state`, which must be in [1, 2^31-2].
pub fn MinStd::with_state(state : UInt64) -> MinStd {
  ignore(state)
  { s: FixedArray::make(1, 0UL), }
}

///|
/// A generator seeded from a byte seed.
pub fn MinStd::new(seed : BytesView) -> MinStd {
  ignore(seed)
  { s: FixedArray::make(1, 0UL), }
}

///|
pub impl @contract.Rng for MinStd with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("MinStd: no implementation yet")
}

///|
/// Qcg64: a quadratic congruential generator, x squared plus a constant.
pub struct Qcg64 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator with `multiplier`, `increment` and the starting `seed`.
pub fn Qcg64::with_params(
  multiplier : UInt64,
  increment : UInt64,
  seed : UInt64,
) -> Qcg64 {
  ignore((multiplier, increment, seed))
  { s: FixedArray::make(3, 0UL), }
}

///|
/// A generator seeded from a byte seed.
pub fn Qcg64::new(seed : BytesView) -> Qcg64 {
  ignore(seed)
  { s: FixedArray::make(3, 0UL), }
}

///|
pub impl @contract.Rng for Qcg64 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Qcg64: no implementation yet")
}

///|
/// Ccg64: a cubic congruential generator.
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
  ignore((a, b, c, seed))
  { s: FixedArray::make(4, 0UL), }
}

///|
/// A generator seeded from a byte seed.
pub fn Ccg64::new(seed : BytesView) -> Ccg64 {
  ignore(seed)
  { s: FixedArray::make(4, 0UL), }
}

///|
pub impl @contract.Rng for Ccg64 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Ccg64: no implementation yet")
}

///|
/// Icg32: an inversive congruential generator over the prime 2^32-5.
pub struct Icg32 {
  priv s : FixedArray[UInt64]
}

///|
/// A generator with `multiplier`, `increment` and the starting `seed`.
pub fn Icg32::with_params(
  multiplier : UInt64,
  increment : UInt64,
  seed : UInt64,
) -> Icg32 {
  ignore((multiplier, increment, seed))
  { s: FixedArray::make(3, 0UL), }
}

///|
/// A generator seeded from a byte seed.
pub fn Icg32::new(seed : BytesView) -> Icg32 {
  ignore(seed)
  { s: FixedArray::make(3, 0UL), }
}

///|
pub impl @contract.Rng for Icg32 with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Icg32: no implementation yet")
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
pub impl @contract.Seeded for Lcg48 with fn from_seed(seed : BytesView) -> Lcg48 {
  Lcg48::new(seed)
}

///|
pub impl @contract.Seeded for Lcg48 with fn seed_size() -> Int32 {
  8
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
pub impl @contract.Seeded for Qcg64 with fn from_seed(seed : BytesView) -> Qcg64 {
  Qcg64::new(seed)
}

///|
pub impl @contract.Seeded for Qcg64 with fn seed_size() -> Int32 {
  8
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
