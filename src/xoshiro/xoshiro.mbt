///|
/// xoshiro256\*\*: the 256-bit state version whose output is a scrambled product.
pub struct Xoshiro256ss {
  priv s : FixedArray[UInt64]
}

///|
/// A generator whose state is `s`, taken as given: 4 words, no
/// expansion, so a published state reproduces a published stream.
pub fn Xoshiro256ss::from_state(s : FixedArray[UInt64]) -> Xoshiro256ss {
  if s.length() != 4 {
    abort("Xoshiro256ss: state is 4 words")
  }
  { s, }
}

///|
/// A generator seeded from 32 bytes.
pub fn Xoshiro256ss::new(seed : BytesView) -> Xoshiro256ss {
  Xoshiro256ss::from_state(@bits.seed_words(seed, 4))
}

///|
/// Skip 2^128 draws, the reference `jump`.
pub fn Xoshiro256ss::jump(self : Xoshiro256ss) -> Unit {
  ignore(self.s)
  abort("Xoshiro256ss: no implementation yet")
}

///|
/// Skip 2^192 draws, the reference `long_jump`.
pub fn Xoshiro256ss::long_jump(self : Xoshiro256ss) -> Unit {
  ignore(self.s)
  abort("Xoshiro256ss: no implementation yet")
}

///|
pub impl @contract.Rng for Xoshiro256ss with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Xoshiro256ss: no implementation yet")
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
/// xoshiro256++: a sum rotated, with the 256-bit state; the fastest of the family in software.
pub struct Xoshiro256pp {
  priv s : FixedArray[UInt64]
}

///|
/// A generator whose state is `s`, taken as given: 4 words, no
/// expansion, so a published state reproduces a published stream.
pub fn Xoshiro256pp::from_state(s : FixedArray[UInt64]) -> Xoshiro256pp {
  if s.length() != 4 {
    abort("Xoshiro256pp: state is 4 words")
  }
  { s, }
}

///|
/// A generator seeded from 32 bytes.
pub fn Xoshiro256pp::new(seed : BytesView) -> Xoshiro256pp {
  Xoshiro256pp::from_state(@bits.seed_words(seed, 4))
}

///|
/// Skip 2^128 draws, the reference `jump`.
pub fn Xoshiro256pp::jump(self : Xoshiro256pp) -> Unit {
  ignore(self.s)
  abort("Xoshiro256pp: no implementation yet")
}

///|
/// Skip 2^192 draws, the reference `long_jump`.
pub fn Xoshiro256pp::long_jump(self : Xoshiro256pp) -> Unit {
  ignore(self.s)
  abort("Xoshiro256pp: no implementation yet")
}

///|
pub impl @contract.Rng for Xoshiro256pp with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Xoshiro256pp: no implementation yet")
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
/// xoshiro256+: an addition of two state words; the weakest output function of the family, and the fastest when all that is wanted is a fraction.
pub struct Xoshiro256p {
  priv s : FixedArray[UInt64]
}

///|
/// A generator whose state is `s`, taken as given: 4 words, no
/// expansion, so a published state reproduces a published stream.
pub fn Xoshiro256p::from_state(s : FixedArray[UInt64]) -> Xoshiro256p {
  if s.length() != 4 {
    abort("Xoshiro256p: state is 4 words")
  }
  { s, }
}

///|
/// A generator seeded from 32 bytes.
pub fn Xoshiro256p::new(seed : BytesView) -> Xoshiro256p {
  Xoshiro256p::from_state(@bits.seed_words(seed, 4))
}

///|
/// Skip 2^128 draws, the reference `jump`.
pub fn Xoshiro256p::jump(self : Xoshiro256p) -> Unit {
  ignore(self.s)
  abort("Xoshiro256p: no implementation yet")
}

///|
/// Skip 2^192 draws, the reference `long_jump`.
pub fn Xoshiro256p::long_jump(self : Xoshiro256p) -> Unit {
  ignore(self.s)
  abort("Xoshiro256p: no implementation yet")
}

///|
pub impl @contract.Rng for Xoshiro256p with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Xoshiro256p: no implementation yet")
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
/// xoshiro512\*\*: the 512-bit state version of xoshiro256\*\*.
pub struct Xoshiro512ss {
  priv s : FixedArray[UInt64]
}

///|
/// A generator whose state is `s`, taken as given: 8 words, no
/// expansion, so a published state reproduces a published stream.
pub fn Xoshiro512ss::from_state(s : FixedArray[UInt64]) -> Xoshiro512ss {
  if s.length() != 8 {
    abort("Xoshiro512ss: state is 8 words")
  }
  { s, }
}

///|
/// A generator seeded from 64 bytes.
pub fn Xoshiro512ss::new(seed : BytesView) -> Xoshiro512ss {
  Xoshiro512ss::from_state(@bits.seed_words(seed, 8))
}

///|
/// Skip 2^128 draws, the reference `jump`.
pub fn Xoshiro512ss::jump(self : Xoshiro512ss) -> Unit {
  ignore(self.s)
  abort("Xoshiro512ss: no implementation yet")
}

///|
/// Skip 2^192 draws, the reference `long_jump`.
pub fn Xoshiro512ss::long_jump(self : Xoshiro512ss) -> Unit {
  ignore(self.s)
  abort("Xoshiro512ss: no implementation yet")
}

///|
pub impl @contract.Rng for Xoshiro512ss with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Xoshiro512ss: no implementation yet")
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
/// xoshiro512++: the 512-bit state version of xoshiro256++.
pub struct Xoshiro512pp {
  priv s : FixedArray[UInt64]
}

///|
/// A generator whose state is `s`, taken as given: 8 words, no
/// expansion, so a published state reproduces a published stream.
pub fn Xoshiro512pp::from_state(s : FixedArray[UInt64]) -> Xoshiro512pp {
  if s.length() != 8 {
    abort("Xoshiro512pp: state is 8 words")
  }
  { s, }
}

///|
/// A generator seeded from 64 bytes.
pub fn Xoshiro512pp::new(seed : BytesView) -> Xoshiro512pp {
  Xoshiro512pp::from_state(@bits.seed_words(seed, 8))
}

///|
/// Skip 2^128 draws, the reference `jump`.
pub fn Xoshiro512pp::jump(self : Xoshiro512pp) -> Unit {
  ignore(self.s)
  abort("Xoshiro512pp: no implementation yet")
}

///|
/// Skip 2^192 draws, the reference `long_jump`.
pub fn Xoshiro512pp::long_jump(self : Xoshiro512pp) -> Unit {
  ignore(self.s)
  abort("Xoshiro512pp: no implementation yet")
}

///|
pub impl @contract.Rng for Xoshiro512pp with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Xoshiro512pp: no implementation yet")
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
/// xoshiro512+: the 512-bit state version of xoshiro256+.
pub struct Xoshiro512p {
  priv s : FixedArray[UInt64]
}

///|
/// A generator whose state is `s`, taken as given: 8 words, no
/// expansion, so a published state reproduces a published stream.
pub fn Xoshiro512p::from_state(s : FixedArray[UInt64]) -> Xoshiro512p {
  if s.length() != 8 {
    abort("Xoshiro512p: state is 8 words")
  }
  { s, }
}

///|
/// A generator seeded from 64 bytes.
pub fn Xoshiro512p::new(seed : BytesView) -> Xoshiro512p {
  Xoshiro512p::from_state(@bits.seed_words(seed, 8))
}

///|
/// Skip 2^128 draws, the reference `jump`.
pub fn Xoshiro512p::jump(self : Xoshiro512p) -> Unit {
  ignore(self.s)
  abort("Xoshiro512p: no implementation yet")
}

///|
/// Skip 2^192 draws, the reference `long_jump`.
pub fn Xoshiro512p::long_jump(self : Xoshiro512p) -> Unit {
  ignore(self.s)
  abort("Xoshiro512p: no implementation yet")
}

///|
pub impl @contract.Rng for Xoshiro512p with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Xoshiro512p: no implementation yet")
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
/// xoroshiro128+: two words of state, an addition as the output; small and fast.
pub struct Xoroshiro128p {
  priv s : FixedArray[UInt64]
}

///|
/// A generator whose state is `s`, taken as given: 2 words, no
/// expansion, so a published state reproduces a published stream.
pub fn Xoroshiro128p::from_state(s : FixedArray[UInt64]) -> Xoroshiro128p {
  if s.length() != 2 {
    abort("Xoroshiro128p: state is 2 words")
  }
  { s, }
}

///|
/// A generator seeded from 16 bytes.
pub fn Xoroshiro128p::new(seed : BytesView) -> Xoroshiro128p {
  Xoroshiro128p::from_state(@bits.seed_words(seed, 2))
}

///|
/// Skip 2^128 draws, the reference `jump`.
pub fn Xoroshiro128p::jump(self : Xoroshiro128p) -> Unit {
  ignore(self.s)
  abort("Xoroshiro128p: no implementation yet")
}

///|
/// Skip 2^192 draws, the reference `long_jump`.
pub fn Xoroshiro128p::long_jump(self : Xoroshiro128p) -> Unit {
  ignore(self.s)
  abort("Xoroshiro128p: no implementation yet")
}

///|
pub impl @contract.Rng for Xoroshiro128p with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Xoroshiro128p: no implementation yet")
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
/// A generator whose state is `s`, taken as given: 2 words, no
/// expansion, so a published state reproduces a published stream.
pub fn Xoroshiro128pp::from_state(s : FixedArray[UInt64]) -> Xoroshiro128pp {
  if s.length() != 2 {
    abort("Xoroshiro128pp: state is 2 words")
  }
  { s, }
}

///|
/// A generator seeded from 16 bytes.
pub fn Xoroshiro128pp::new(seed : BytesView) -> Xoroshiro128pp {
  Xoroshiro128pp::from_state(@bits.seed_words(seed, 2))
}

///|
/// Skip 2^128 draws, the reference `jump`.
pub fn Xoroshiro128pp::jump(self : Xoroshiro128pp) -> Unit {
  ignore(self.s)
  abort("Xoroshiro128pp: no implementation yet")
}

///|
/// Skip 2^192 draws, the reference `long_jump`.
pub fn Xoroshiro128pp::long_jump(self : Xoroshiro128pp) -> Unit {
  ignore(self.s)
  abort("Xoroshiro128pp: no implementation yet")
}

///|
pub impl @contract.Rng for Xoroshiro128pp with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Xoroshiro128pp: no implementation yet")
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
/// A generator whose state is `s`, taken as given: 2 words, no
/// expansion, so a published state reproduces a published stream.
pub fn Xoroshiro128ss::from_state(s : FixedArray[UInt64]) -> Xoroshiro128ss {
  if s.length() != 2 {
    abort("Xoroshiro128ss: state is 2 words")
  }
  { s, }
}

///|
/// A generator seeded from 16 bytes.
pub fn Xoroshiro128ss::new(seed : BytesView) -> Xoroshiro128ss {
  Xoroshiro128ss::from_state(@bits.seed_words(seed, 2))
}

///|
/// Skip 2^128 draws, the reference `jump`.
pub fn Xoroshiro128ss::jump(self : Xoroshiro128ss) -> Unit {
  ignore(self.s)
  abort("Xoroshiro128ss: no implementation yet")
}

///|
/// Skip 2^192 draws, the reference `long_jump`.
pub fn Xoroshiro128ss::long_jump(self : Xoroshiro128ss) -> Unit {
  ignore(self.s)
  abort("Xoroshiro128ss: no implementation yet")
}

///|
pub impl @contract.Rng for Xoroshiro128ss with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Xoroshiro128ss: no implementation yet")
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
