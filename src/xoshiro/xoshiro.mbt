///|
/// The reference transitions, outputs and jump polynomials, written once and
/// shared by the nine generators below. Every constant here is from the
/// authors' reference implementation; the tests replay their published output.
fn rotl(x : UInt64, k : Int32) -> UInt64 {
  (x << k) | (x >> (64 - k))
}

///|
/// The 256-bit transition, shared by the three xoshiro256 variants.
fn step_256(s : FixedArray[UInt64]) -> Unit {
  let t = s[1] << 17
  s[2] = s[2] ^ s[0]
  s[3] = s[3] ^ s[1]
  s[1] = s[1] ^ s[2]
  s[0] = s[0] ^ s[3]
  s[2] = s[2] ^ t
  s[3] = rotl(s[3], 45)
}

///|
/// The 512-bit transition, shared by the three xoshiro512 variants.
fn step_512(s : FixedArray[UInt64]) -> Unit {
  let t = s[1] << 11
  s[2] = s[2] ^ s[0]
  s[5] = s[5] ^ s[1]
  s[1] = s[1] ^ s[2]
  s[7] = s[7] ^ s[3]
  s[3] = s[3] ^ s[4]
  s[4] = s[4] ^ s[5]
  s[0] = s[0] ^ s[6]
  s[6] = s[6] ^ s[7]
  s[6] = s[6] ^ t
  s[7] = rotl(s[7], 21)
}

///|
/// The xoroshiro128 transition with the 2016 constants a=24, b=16, c=37, as
/// xoroshiro128+ and xoroshiro128** use it.
fn step_xoro_24(s : FixedArray[UInt64]) -> Unit {
  let s0 = s[0]
  let s1 = s[1] ^ s0
  s[0] = rotl(s0, 24) ^ s1 ^ (s1 << 16)
  s[1] = rotl(s1, 37)
}

///|
/// The xoroshiro128 transition with the constants a=49, b=21, c=28, as
/// xoroshiro128++ uses them.
fn step_xoro_49(s : FixedArray[UInt64]) -> Unit {
  let s0 = s[0]
  let s1 = s[1] ^ s0
  s[0] = rotl(s0, 49) ^ s1 ^ (s1 << 21)
  s[1] = rotl(s1, 28)
}

///|
/// Jump by the polynomial `poly`: accumulate the state wherever the polynomial
/// has a set bit and step once per bit, then take the accumulation as the new
/// state. This is the reference `jump`, and it costs 64 steps per polynomial
/// word.
fn apply_jump(
  s : FixedArray[UInt64],
  poly : FixedArray[UInt64],
  step : (FixedArray[UInt64]) -> Unit,
) -> Unit {
  let n = s.length()
  let t = FixedArray::make(n, 0UL)
  for i = 0; i < poly.length(); i = i + 1 {
    for b = 0; b < 64; b = b + 1 {
      if (poly[i] & (1UL << b)) != 0UL {
        for k = 0; k < n; k = k + 1 {
          t[k] = t[k] ^ s[k]
        }
      }
      step(s)
    }
  }
  for k = 0; k < n; k = k + 1 {
    s[k] = t[k]
  }
}

///|
fn poly_256_jump() -> FixedArray[UInt64] {
  [
    0x180ec6d33cfd0abaUL, 0xd5a61266f0c9392cUL, 0xa9582618e03fc9aaUL, 0x39abdc4529b1661cUL,
  ]
}

///|
fn poly_256_long() -> FixedArray[UInt64] {
  [
    0x76e15d3efefdcbbfUL, 0xc5004e441c522fb3UL, 0x77710069854ee241UL, 0x39109bb02acbe635UL,
  ]
}

///|
fn poly_512_jump() -> FixedArray[UInt64] {
  [
    0x33ed89b6e7a353f9UL, 0x760083d7955323beUL, 0x2837f2fbb5f22faeUL, 0x4b8c5674d309511cUL,
    0xb11ac47a7ba28c25UL, 0xf1be7667092bcc1cUL, 0x53851efdb6df0aafUL, 0x1ebbc8b23eaf25dbUL,
  ]
}

///|
fn poly_512_long() -> FixedArray[UInt64] {
  [
    0x11467fef8f921d28UL, 0xa2a819f2e79c8ea8UL, 0xa8299fc284b3959aUL, 0xb4d347340ca63ee1UL,
    0x1cb0940bedbff6ceUL, 0xd956c5c4fa1f8e17UL, 0x915e38fd4eda93bcUL, 0x5b3ccdfa5d7daca5UL,
  ]
}

///|
fn poly_xoro_jump() -> FixedArray[UInt64] {
  [0xdf900294d8f554a5UL, 0x170865df4b3201fcUL]
}

///|
fn poly_xoro_long() -> FixedArray[UInt64] {
  [0xd2a98b26625eee7bUL, 0xdddf9b1090aa7ac1UL]
}

///|
fn poly_xoro_pp_jump() -> FixedArray[UInt64] {
  [0x2bd7a6a6e99c2ddcUL, 0x0992ccaf6a6fca05UL]
}

///|
fn poly_xoro_pp_long() -> FixedArray[UInt64] {
  [0x360fd5f2cf8d5d99UL, 0x9c6e6877736c46e3UL]
}

///|
/// xoshiro256**: a scrambled product as the output, a 256-bit state.
fn next_256ss(s : FixedArray[UInt64]) -> UInt64 {
  let r = rotl(s[1] * 5UL, 7) * 9UL
  step_256(s)
  r
}

///|
fn next_256pp(s : FixedArray[UInt64]) -> UInt64 {
  let r = rotl(s[0] + s[3], 23) + s[0]
  step_256(s)
  r
}

///|
fn next_256p(s : FixedArray[UInt64]) -> UInt64 {
  let r = s[0] + s[3]
  step_256(s)
  r
}

///|
fn next_512ss(s : FixedArray[UInt64]) -> UInt64 {
  let r = rotl(s[1] * 5UL, 7) * 9UL
  step_512(s)
  r
}

///|
fn next_512pp(s : FixedArray[UInt64]) -> UInt64 {
  let r = rotl(s[0] + s[2], 17) + s[2]
  step_512(s)
  r
}

///|
fn next_512p(s : FixedArray[UInt64]) -> UInt64 {
  let r = s[0] + s[2]
  step_512(s)
  r
}

///|
fn next_xoro_p(s : FixedArray[UInt64]) -> UInt64 {
  let r = s[0] + s[1]
  step_xoro_24(s)
  r
}

///|
fn next_xoro_pp(s : FixedArray[UInt64]) -> UInt64 {
  let r = rotl(s[0] + s[1], 17) + s[0]
  step_xoro_49(s)
  r
}

///|
fn next_xoro_ss(s : FixedArray[UInt64]) -> UInt64 {
  let r = rotl(s[0] * 5UL, 7) * 9UL
  step_xoro_24(s)
  r
}

///|
/// xoshiro256\*\*: a 256-bit state and a scrambled product as the output.
pub struct Xoshiro256ss {
  priv s : FixedArray[UInt64]
}

///|
/// A generator whose state is `s`, taken as given: 4 words, no expansion,
/// so a published state reproduces the published stream.
pub fn Xoshiro256ss::from_state(s : FixedArray[UInt64]) -> Xoshiro256ss {
  if s.length() != 4 {
    abort("Xoshiro256ss: state is 4 words")
  }
  { s, }
}

///|
/// A generator seeded from 32 bytes, expanded through SplitMix64.
pub fn Xoshiro256ss::new(seed : BytesView) -> Xoshiro256ss {
  Xoshiro256ss::from_state(@bits.seed_words(seed, 4))
}

///|
/// Skip 2^128 draws.
pub fn Xoshiro256ss::jump(self : Xoshiro256ss) -> Unit {
  apply_jump(self.s, poly_256_jump(), step_256)
}

///|
/// Skip 2^192 draws.
pub fn Xoshiro256ss::long_jump(self : Xoshiro256ss) -> Unit {
  apply_jump(self.s, poly_256_long(), step_256)
}

///|
pub impl @contract.Rng for Xoshiro256ss with fn next_u64(self) -> UInt64 {
  next_256ss(self.s)
}

///|
pub impl @contract.Seeded for Xoshiro256ss with fn from_seed(seed : BytesView) -> Xoshiro256ss {
  Xoshiro256ss::new(seed)
}

///|
pub impl @contract.Seeded for Xoshiro256ss with fn seed_size() -> Int32 {
  32
}

///|
pub extend Xoshiro256ss with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Xoshiro256ss with @contract.Seeded::{from_seed, seed_size}

///|
/// xoshiro256++: a 256-bit state and a rotated sum as the output.
pub struct Xoshiro256pp {
  priv s : FixedArray[UInt64]
}

///|
/// A generator whose state is `s`, taken as given: 4 words, no expansion,
/// so a published state reproduces the published stream.
pub fn Xoshiro256pp::from_state(s : FixedArray[UInt64]) -> Xoshiro256pp {
  if s.length() != 4 {
    abort("Xoshiro256pp: state is 4 words")
  }
  { s, }
}

///|
/// A generator seeded from 32 bytes, expanded through SplitMix64.
pub fn Xoshiro256pp::new(seed : BytesView) -> Xoshiro256pp {
  Xoshiro256pp::from_state(@bits.seed_words(seed, 4))
}

///|
/// Skip 2^128 draws.
pub fn Xoshiro256pp::jump(self : Xoshiro256pp) -> Unit {
  apply_jump(self.s, poly_256_jump(), step_256)
}

///|
/// Skip 2^192 draws.
pub fn Xoshiro256pp::long_jump(self : Xoshiro256pp) -> Unit {
  apply_jump(self.s, poly_256_long(), step_256)
}

///|
pub impl @contract.Rng for Xoshiro256pp with fn next_u64(self) -> UInt64 {
  next_256pp(self.s)
}

///|
pub impl @contract.Seeded for Xoshiro256pp with fn from_seed(seed : BytesView) -> Xoshiro256pp {
  Xoshiro256pp::new(seed)
}

///|
pub impl @contract.Seeded for Xoshiro256pp with fn seed_size() -> Int32 {
  32
}

///|
pub extend Xoshiro256pp with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Xoshiro256pp with @contract.Seeded::{from_seed, seed_size}

///|
/// xoshiro256+: a 256-bit state and an addition as the output; the fastest of the three when all that is wanted is a fraction from the high bits.
pub struct Xoshiro256p {
  priv s : FixedArray[UInt64]
}

///|
/// A generator whose state is `s`, taken as given: 4 words, no expansion,
/// so a published state reproduces the published stream.
pub fn Xoshiro256p::from_state(s : FixedArray[UInt64]) -> Xoshiro256p {
  if s.length() != 4 {
    abort("Xoshiro256p: state is 4 words")
  }
  { s, }
}

///|
/// A generator seeded from 32 bytes, expanded through SplitMix64.
pub fn Xoshiro256p::new(seed : BytesView) -> Xoshiro256p {
  Xoshiro256p::from_state(@bits.seed_words(seed, 4))
}

///|
/// Skip 2^128 draws.
pub fn Xoshiro256p::jump(self : Xoshiro256p) -> Unit {
  apply_jump(self.s, poly_256_jump(), step_256)
}

///|
/// Skip 2^192 draws.
pub fn Xoshiro256p::long_jump(self : Xoshiro256p) -> Unit {
  apply_jump(self.s, poly_256_long(), step_256)
}

///|
pub impl @contract.Rng for Xoshiro256p with fn next_u64(self) -> UInt64 {
  next_256p(self.s)
}

///|
pub impl @contract.Seeded for Xoshiro256p with fn from_seed(seed : BytesView) -> Xoshiro256p {
  Xoshiro256p::new(seed)
}

///|
pub impl @contract.Seeded for Xoshiro256p with fn seed_size() -> Int32 {
  32
}

///|
pub extend Xoshiro256p with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Xoshiro256p with @contract.Seeded::{from_seed, seed_size}

///|
/// xoshiro512\*\*: a 512-bit state and a scrambled product as the output.
pub struct Xoshiro512ss {
  priv s : FixedArray[UInt64]
}

///|
/// A generator whose state is `s`, taken as given: 8 words, no expansion,
/// so a published state reproduces the published stream.
pub fn Xoshiro512ss::from_state(s : FixedArray[UInt64]) -> Xoshiro512ss {
  if s.length() != 8 {
    abort("Xoshiro512ss: state is 8 words")
  }
  { s, }
}

///|
/// A generator seeded from 64 bytes, expanded through SplitMix64.
pub fn Xoshiro512ss::new(seed : BytesView) -> Xoshiro512ss {
  Xoshiro512ss::from_state(@bits.seed_words(seed, 8))
}

///|
/// Skip 2^256 draws.
pub fn Xoshiro512ss::jump(self : Xoshiro512ss) -> Unit {
  apply_jump(self.s, poly_512_jump(), step_512)
}

///|
/// Skip 2^384 draws.
pub fn Xoshiro512ss::long_jump(self : Xoshiro512ss) -> Unit {
  apply_jump(self.s, poly_512_long(), step_512)
}

///|
pub impl @contract.Rng for Xoshiro512ss with fn next_u64(self) -> UInt64 {
  next_512ss(self.s)
}

///|
pub impl @contract.Seeded for Xoshiro512ss with fn from_seed(seed : BytesView) -> Xoshiro512ss {
  Xoshiro512ss::new(seed)
}

///|
pub impl @contract.Seeded for Xoshiro512ss with fn seed_size() -> Int32 {
  64
}

///|
pub extend Xoshiro512ss with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Xoshiro512ss with @contract.Seeded::{from_seed, seed_size}

///|
/// xoshiro512++: a 512-bit state and a rotated sum as the output.
pub struct Xoshiro512pp {
  priv s : FixedArray[UInt64]
}

///|
/// A generator whose state is `s`, taken as given: 8 words, no expansion,
/// so a published state reproduces the published stream.
pub fn Xoshiro512pp::from_state(s : FixedArray[UInt64]) -> Xoshiro512pp {
  if s.length() != 8 {
    abort("Xoshiro512pp: state is 8 words")
  }
  { s, }
}

///|
/// A generator seeded from 64 bytes, expanded through SplitMix64.
pub fn Xoshiro512pp::new(seed : BytesView) -> Xoshiro512pp {
  Xoshiro512pp::from_state(@bits.seed_words(seed, 8))
}

///|
/// Skip 2^256 draws.
pub fn Xoshiro512pp::jump(self : Xoshiro512pp) -> Unit {
  apply_jump(self.s, poly_512_jump(), step_512)
}

///|
/// Skip 2^384 draws.
pub fn Xoshiro512pp::long_jump(self : Xoshiro512pp) -> Unit {
  apply_jump(self.s, poly_512_long(), step_512)
}

///|
pub impl @contract.Rng for Xoshiro512pp with fn next_u64(self) -> UInt64 {
  next_512pp(self.s)
}

///|
pub impl @contract.Seeded for Xoshiro512pp with fn from_seed(seed : BytesView) -> Xoshiro512pp {
  Xoshiro512pp::new(seed)
}

///|
pub impl @contract.Seeded for Xoshiro512pp with fn seed_size() -> Int32 {
  64
}

///|
pub extend Xoshiro512pp with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Xoshiro512pp with @contract.Seeded::{from_seed, seed_size}

///|
/// xoshiro512+: a 512-bit state and an addition as the output.
pub struct Xoshiro512p {
  priv s : FixedArray[UInt64]
}

///|
/// A generator whose state is `s`, taken as given: 8 words, no expansion,
/// so a published state reproduces the published stream.
pub fn Xoshiro512p::from_state(s : FixedArray[UInt64]) -> Xoshiro512p {
  if s.length() != 8 {
    abort("Xoshiro512p: state is 8 words")
  }
  { s, }
}

///|
/// A generator seeded from 64 bytes, expanded through SplitMix64.
pub fn Xoshiro512p::new(seed : BytesView) -> Xoshiro512p {
  Xoshiro512p::from_state(@bits.seed_words(seed, 8))
}

///|
/// Skip 2^256 draws.
pub fn Xoshiro512p::jump(self : Xoshiro512p) -> Unit {
  apply_jump(self.s, poly_512_jump(), step_512)
}

///|
/// Skip 2^384 draws.
pub fn Xoshiro512p::long_jump(self : Xoshiro512p) -> Unit {
  apply_jump(self.s, poly_512_long(), step_512)
}

///|
pub impl @contract.Rng for Xoshiro512p with fn next_u64(self) -> UInt64 {
  next_512p(self.s)
}

///|
pub impl @contract.Seeded for Xoshiro512p with fn from_seed(seed : BytesView) -> Xoshiro512p {
  Xoshiro512p::new(seed)
}

///|
pub impl @contract.Seeded for Xoshiro512p with fn seed_size() -> Int32 {
  64
}

///|
pub extend Xoshiro512p with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Xoshiro512p with @contract.Seeded::{from_seed, seed_size}

///|
/// xoroshiro128+: two words of state, an addition as the output; small and fast, and the weakest of the family in the low bits.
pub struct Xoroshiro128p {
  priv s : FixedArray[UInt64]
}

///|
/// A generator whose state is `s`, taken as given: 2 words, no expansion,
/// so a published state reproduces the published stream.
pub fn Xoroshiro128p::from_state(s : FixedArray[UInt64]) -> Xoroshiro128p {
  if s.length() != 2 {
    abort("Xoroshiro128p: state is 2 words")
  }
  { s, }
}

///|
/// A generator seeded from 16 bytes, expanded through SplitMix64.
pub fn Xoroshiro128p::new(seed : BytesView) -> Xoroshiro128p {
  Xoroshiro128p::from_state(@bits.seed_words(seed, 2))
}

///|
/// Skip 2^64 draws.
pub fn Xoroshiro128p::jump(self : Xoroshiro128p) -> Unit {
  apply_jump(self.s, poly_xoro_jump(), step_xoro_24)
}

///|
/// Skip 2^96 draws.
pub fn Xoroshiro128p::long_jump(self : Xoroshiro128p) -> Unit {
  apply_jump(self.s, poly_xoro_long(), step_xoro_24)
}

///|
pub impl @contract.Rng for Xoroshiro128p with fn next_u64(self) -> UInt64 {
  next_xoro_p(self.s)
}

///|
pub impl @contract.Seeded for Xoroshiro128p with fn from_seed(seed : BytesView) -> Xoroshiro128p {
  Xoroshiro128p::new(seed)
}

///|
pub impl @contract.Seeded for Xoroshiro128p with fn seed_size() -> Int32 {
  16
}

///|
pub extend Xoroshiro128p with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Xoroshiro128p with @contract.Seeded::{from_seed, seed_size}

///|
/// xoroshiro128++: two words of state, a rotated sum as the output.
pub struct Xoroshiro128pp {
  priv s : FixedArray[UInt64]
}

///|
/// A generator whose state is `s`, taken as given: 2 words, no expansion,
/// so a published state reproduces the published stream.
pub fn Xoroshiro128pp::from_state(s : FixedArray[UInt64]) -> Xoroshiro128pp {
  if s.length() != 2 {
    abort("Xoroshiro128pp: state is 2 words")
  }
  { s, }
}

///|
/// A generator seeded from 16 bytes, expanded through SplitMix64.
pub fn Xoroshiro128pp::new(seed : BytesView) -> Xoroshiro128pp {
  Xoroshiro128pp::from_state(@bits.seed_words(seed, 2))
}

///|
/// Skip 2^64 draws.
pub fn Xoroshiro128pp::jump(self : Xoroshiro128pp) -> Unit {
  apply_jump(self.s, poly_xoro_pp_jump(), step_xoro_49)
}

///|
/// Skip 2^96 draws.
pub fn Xoroshiro128pp::long_jump(self : Xoroshiro128pp) -> Unit {
  apply_jump(self.s, poly_xoro_pp_long(), step_xoro_49)
}

///|
pub impl @contract.Rng for Xoroshiro128pp with fn next_u64(self) -> UInt64 {
  next_xoro_pp(self.s)
}

///|
pub impl @contract.Seeded for Xoroshiro128pp with fn from_seed(seed : BytesView) -> Xoroshiro128pp {
  Xoroshiro128pp::new(seed)
}

///|
pub impl @contract.Seeded for Xoroshiro128pp with fn seed_size() -> Int32 {
  16
}

///|
pub extend Xoroshiro128pp with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Xoroshiro128pp with @contract.Seeded::{from_seed, seed_size}

///|
/// xoroshiro128\*\*: two words of state, a scrambled product as the output.
pub struct Xoroshiro128ss {
  priv s : FixedArray[UInt64]
}

///|
/// A generator whose state is `s`, taken as given: 2 words, no expansion,
/// so a published state reproduces the published stream.
pub fn Xoroshiro128ss::from_state(s : FixedArray[UInt64]) -> Xoroshiro128ss {
  if s.length() != 2 {
    abort("Xoroshiro128ss: state is 2 words")
  }
  { s, }
}

///|
/// A generator seeded from 16 bytes, expanded through SplitMix64.
pub fn Xoroshiro128ss::new(seed : BytesView) -> Xoroshiro128ss {
  Xoroshiro128ss::from_state(@bits.seed_words(seed, 2))
}

///|
/// Skip 2^64 draws.
pub fn Xoroshiro128ss::jump(self : Xoroshiro128ss) -> Unit {
  apply_jump(self.s, poly_xoro_jump(), step_xoro_24)
}

///|
/// Skip 2^96 draws.
pub fn Xoroshiro128ss::long_jump(self : Xoroshiro128ss) -> Unit {
  apply_jump(self.s, poly_xoro_long(), step_xoro_24)
}

///|
pub impl @contract.Rng for Xoroshiro128ss with fn next_u64(self) -> UInt64 {
  next_xoro_ss(self.s)
}

///|
pub impl @contract.Seeded for Xoroshiro128ss with fn from_seed(seed : BytesView) -> Xoroshiro128ss {
  Xoroshiro128ss::new(seed)
}

///|
pub impl @contract.Seeded for Xoroshiro128ss with fn seed_size() -> Int32 {
  16
}

///|
pub extend Xoroshiro128ss with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Xoroshiro128ss with @contract.Seeded::{from_seed, seed_size}
