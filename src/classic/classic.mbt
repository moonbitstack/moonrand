///|
/// MiddleSquare: square the word, keep the middle digits.
pub struct MiddleSquare {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over `state`.
pub fn MiddleSquare::with_state(state : UInt64) -> MiddleSquare {
  ignore(state)
  { s: FixedArray::make(1, 0UL), }
}

///|
/// A generator seeded from a byte seed.
pub fn MiddleSquare::new(seed : BytesView) -> MiddleSquare {
  ignore(seed)
  { s: FixedArray::make(1, 0UL), }
}

///|
pub impl @contract.Rng for MiddleSquare with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("MiddleSquare: no implementation yet")
}

///|
/// MiddleProduct: multiply by a fixed constant, keep the middle digits.
pub struct MiddleProduct {
  priv s : FixedArray[UInt64]
}

///|
/// A generator with `multiplier` and the starting `seed`.
pub fn MiddleProduct::with_params(
  multiplier : UInt64,
  seed : UInt64,
) -> MiddleProduct {
  ignore((multiplier, seed))
  { s: FixedArray::make(2, 0UL), }
}

///|
/// A generator seeded from a byte seed.
pub fn MiddleProduct::new(seed : BytesView) -> MiddleProduct {
  ignore(seed)
  { s: FixedArray::make(2, 0UL), }
}

///|
pub impl @contract.Rng for MiddleProduct with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("MiddleProduct: no implementation yet")
}

///|
/// MiddleSquareWeyl: the middle-square word plus a Weyl sequence.
pub struct MiddleSquareWeyl {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over the starting `state`, with the Weyl word at zero.
pub fn MiddleSquareWeyl::with_state(state : UInt64) -> MiddleSquareWeyl {
  ignore(state)
  { s: FixedArray::make(2, 0UL), }
}

///|
/// A generator seeded from a byte seed.
pub fn MiddleSquareWeyl::new(seed : BytesView) -> MiddleSquareWeyl {
  ignore(seed)
  { s: FixedArray::make(2, 0UL), }
}

///|
pub impl @contract.Rng for MiddleSquareWeyl with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("MiddleSquareWeyl: no implementation yet")
}

///|
/// CollatzWeyl: the Collatz map plus a Weyl sequence.
pub struct CollatzWeyl {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over the starting `state`, with the Weyl word at zero.
pub fn CollatzWeyl::with_state(state : UInt64) -> CollatzWeyl {
  ignore(state)
  { s: FixedArray::make(2, 0UL), }
}

///|
/// A generator seeded from a byte seed.
pub fn CollatzWeyl::new(seed : BytesView) -> CollatzWeyl {
  ignore(seed)
  { s: FixedArray::make(2, 0UL), }
}

///|
pub impl @contract.Rng for CollatzWeyl with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("CollatzWeyl: no implementation yet")
}

///|
/// Bbs: Blum Blum Shub, the square modulo a product of two primes.
pub struct Bbs {
  priv s : FixedArray[UInt64]
}

///|
/// A generator with the modulus `modulus` and the starting `seed`.
pub fn Bbs::with_params(modulus : UInt64, seed : UInt64) -> Bbs {
  ignore((modulus, seed))
  { s: FixedArray::make(2, 0UL), }
}

///|
/// A generator seeded from a byte seed.
pub fn Bbs::new(seed : BytesView) -> Bbs {
  ignore(seed)
  { s: FixedArray::make(2, 0UL), }
}

///|
pub impl @contract.Rng for Bbs with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Bbs: no implementation yet")
}

///|
pub impl @contract.Seeded for MiddleSquare with fn from_seed(seed : BytesView) -> MiddleSquare {
  MiddleSquare::new(seed)
}

///|
pub impl @contract.Seeded for MiddleSquare with fn seed_size() -> Int32 {
  8
}

///|
pub impl @contract.Seeded for MiddleProduct with fn from_seed(seed : BytesView) -> MiddleProduct {
  MiddleProduct::new(seed)
}

///|
pub impl @contract.Seeded for MiddleProduct with fn seed_size() -> Int32 {
  8
}

///|
pub impl @contract.Seeded for MiddleSquareWeyl with fn from_seed(
  seed : BytesView,
) -> MiddleSquareWeyl {
  MiddleSquareWeyl::new(seed)
}

///|
pub impl @contract.Seeded for MiddleSquareWeyl with fn seed_size() -> Int32 {
  8
}

///|
pub impl @contract.Seeded for CollatzWeyl with fn from_seed(seed : BytesView) -> CollatzWeyl {
  CollatzWeyl::new(seed)
}

///|
pub impl @contract.Seeded for CollatzWeyl with fn seed_size() -> Int32 {
  8
}

///|
pub impl @contract.Seeded for Bbs with fn from_seed(seed : BytesView) -> Bbs {
  Bbs::new(seed)
}

///|
pub impl @contract.Seeded for Bbs with fn seed_size() -> Int32 {
  8
}

///|
pub extend MiddleSquare with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend MiddleSquare with @contract.Seeded::{from_seed, seed_size}

///|
pub extend MiddleProduct with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend MiddleProduct with @contract.Seeded::{from_seed, seed_size}

///|
pub extend MiddleSquareWeyl with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend MiddleSquareWeyl with @contract.Seeded::{from_seed, seed_size}

///|
pub extend CollatzWeyl with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend CollatzWeyl with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Bbs with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Bbs with @contract.Seeded::{from_seed, seed_size}
