///|
/// The middle-square family, and Blum Blum Shub. Squares of a word are the
/// oldest generator there is; the middle digits are why von Neumann's version
/// was abandoned, and the Weyl sequence is why the modern forms are not.
const WEYL : UInt64 = 0xB5AD4ECEDA1CE2A9UL

///|
/// The middle thirty-two bits of a sixty-four-bit product: the "middle digits"
/// of the schoolbook method, and the reason the low bits of the state never
/// reach the caller.
fn middle32(x : UInt64) -> UInt32 {
  ((x >> 16) & 0xFFFFFFFFUL).to_uint()
}

///|
/// MiddleSquare: square the word and keep the middle thirty-two bits, as von
/// Neumann described it. A zero state is absorbing, so a zero seed is moved off
/// it; even so, the period can collapse, which is why this is here as a
/// historical entry rather than as a default.
pub struct MiddleSquare {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over `state`, with zero replaced by a constant.
pub fn MiddleSquare::with_state(state : UInt64) -> MiddleSquare {
  { s: [if state == 0UL { 0x9E3779B97F4A7C15UL } else { state }], }
}

///|
/// A generator from eight bytes.
pub fn MiddleSquare::new(seed : BytesView) -> MiddleSquare {
  MiddleSquare::with_state(@bits.seed_words(seed, 1)[0])
}

///|
pub impl @contract.Rng for MiddleSquare with fn next_u32(self) -> UInt32 {
  self.s[0] = middle32(self.s[0] * self.s[0]).to_uint64()
  self.s[0].to_uint()
}

///|
pub impl @contract.Rng for MiddleSquare with fn next_u64(self) -> UInt64 {
  (self.next_u32().to_uint64() << 32) | self.next_u32().to_uint64()
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
/// MiddleProduct: multiply by a fixed constant and keep the middle bits, the
/// mid-product method of the same era.
pub struct MiddleProduct {
  priv s : FixedArray[UInt64]
}

///|
/// A generator with `multiplier` and the starting `seed`.
pub fn MiddleProduct::with_params(
  multiplier : UInt64,
  seed : UInt64,
) -> MiddleProduct {
  { s: [if seed == 0UL { 1UL } else { seed }, multiplier | 1UL], }
}

///|
/// A generator from eight bytes, with the golden-ratio multiplier.
pub fn MiddleProduct::new(seed : BytesView) -> MiddleProduct {
  MiddleProduct::with_params(0x9E3779B97F4A7C15UL, @bits.seed_words(seed, 1)[0])
}

///|
pub impl @contract.Rng for MiddleProduct with fn next_u32(self) -> UInt32 {
  self.s[0] = middle32(self.s[0] * self.s[1]).to_uint64()
  self.s[0].to_uint()
}

///|
pub impl @contract.Rng for MiddleProduct with fn next_u64(self) -> UInt64 {
  (self.next_u32().to_uint64() << 32) | self.next_u32().to_uint64()
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
/// MiddleSquareWeyl: the middle-square word plus a Weyl sequence, which is what
/// keeps it from collapsing into its own short cycle.
pub struct MiddleSquareWeyl {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over the starting `state`, with the Weyl word at zero.
pub fn MiddleSquareWeyl::with_state(state : UInt64) -> MiddleSquareWeyl {
  { s: [state, 0UL], }
}

///|
/// A generator from eight bytes.
pub fn MiddleSquareWeyl::new(seed : BytesView) -> MiddleSquareWeyl {
  MiddleSquareWeyl::with_state(@bits.seed_words(seed, 1)[0])
}

///|
pub impl @contract.Rng for MiddleSquareWeyl with fn next_u64(self) -> UInt64 {
  self.s[0] = self.s[0] * self.s[0] + self.s[1]
  self.s[1] = self.s[1] + WEYL
  self.s[0]
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
/// CollatzWeyl: the Collatz map (halve when even, three n plus one when odd)
/// mixed with a Weyl sequence. The Collatz map on its own is a conjecture, not a
/// generator; the Weyl word is what carries the period, and the xor is what
/// hides the map's structure in the low bits.
pub struct CollatzWeyl {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over the starting `state`, with the Weyl word at zero.
pub fn CollatzWeyl::with_state(state : UInt64) -> CollatzWeyl {
  { s: [if state == 0UL { 1UL } else { state }, 0UL], }
}

///|
/// A generator from eight bytes.
pub fn CollatzWeyl::new(seed : BytesView) -> CollatzWeyl {
  CollatzWeyl::with_state(@bits.seed_words(seed, 1)[0])
}

///|
pub impl @contract.Rng for CollatzWeyl with fn next_u64(self) -> UInt64 {
  let x = self.s[0]
  self.s[0] = if (x & 1UL) == 1UL { 3UL * x + 1UL } else { x >> 1 }
  self.s[1] = self.s[1] + 0x9E3779B97F4A7C15UL
  self.s[0] ^ self.s[1]
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
/// Bbs: Blum Blum Shub, the square modulo the product of two primes. The
/// generator is provably hard to predict from its low bits under a factoring
/// assumption — and slow, which is why it stays a cipher-flavoured footnote.
/// This one works modulo a 32-bit modulus, so a word square fits in a double
/// word; the modulus must be a product of two primes congruent to 3 mod 4, or
/// the period argument does not hold.
pub struct Bbs {
  priv s : FixedArray[UInt64]
}

///|
/// A generator over `seed` modulo `modulus`.
pub fn Bbs::with_params(modulus : UInt64, seed : UInt64) -> Bbs {
  if modulus < 3UL {
    abort("Bbs: the modulus must be at least three")
  }
  let m = if modulus > 0xFFFFFFFFUL { 0xFFFFFFFFUL } else { modulus }
  { s: [seed % m, m], }
}

///|
/// A generator from eight bytes, over 383 * 503 = 192649, a Blum integer that
/// fits a word.
pub fn Bbs::new(seed : BytesView) -> Bbs {
  Bbs::with_params(192649UL, @bits.seed_words(seed, 1)[0])
}

///|
pub impl @contract.Rng for Bbs with fn next_u32(self) -> UInt32 {
  self.s[0] = self.s[0] * self.s[0] % self.s[1]
  self.s[0].to_uint()
}

///|
pub impl @contract.Rng for Bbs with fn next_u64(self) -> UInt64 {
  (self.next_u32().to_uint64() << 32) | self.next_u32().to_uint64()
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
