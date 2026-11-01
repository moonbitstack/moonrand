///|
/// Lagged Fibonacci generators and the carry forms of them. They are cheap and
/// they pass the tests, but they are linear over the words they add, which is
/// why the ranlux variants throw most of their output away.

///|
/// AdditiveCongruential: x(n) = x(n-55) + x(n-24) modulo 2^32, the lagged
/// Fibonacci generator of the numerical recipes.
pub struct AdditiveCongruential {
  priv s : FixedArray[UInt32]
  priv i : FixedArray[Int32]
}

///|
/// A generator over the 55 state words.
pub fn AdditiveCongruential::from_state(
  s : FixedArray[UInt32],
) -> AdditiveCongruential {
  if s.length() != 55 {
    abort("AdditiveCongruential: state is 55 words")
  }
  { s, i: [0], }
}

///|
/// A generator from 55 words of SplitMix64 output, none of them all zero.
pub fn AdditiveCongruential::new(seed : BytesView) -> AdditiveCongruential {
  let w = @bits.seed_words(seed, 28)
  let s = FixedArray::make(55, 0U)
  let mut any = false
  for i = 0; i < 27; i = i + 1 {
    s[i * 2] = w[i].to_uint()
    s[i * 2 + 1] = (w[i] >> 32).to_uint()
  }
  for i = 0; i < 55; i = i + 1 {
    any = any || s[i] != 0U
  }
  if !any {
    s[0] = 1U
  }
  AdditiveCongruential::from_state(s)
}

///|
pub impl @contract.Rng for AdditiveCongruential with fn next_u32(self) -> UInt32 {
  let j = (self.i[0] + 31) % 55
  let v = self.s[self.i[0]] + self.s[j]
  self.s[self.i[0]] = v
  self.i[0] = j
  v
}

///|
pub impl @contract.Rng for AdditiveCongruential with fn next_u64(self) -> UInt64 {
  (self.next_u32().to_uint64() << 32) | self.next_u32().to_uint64()
}

///|
pub impl @contract.Seeded for AdditiveCongruential with fn from_seed(
  seed : BytesView,
) -> AdditiveCongruential {
  AdditiveCongruential::new(seed)
}

///|
pub impl @contract.Seeded for AdditiveCongruential with fn seed_size() -> Int32 {
  220
}

///|
/// LaggedFibonacci: the same recurrence with lags 607 and 273, for a period
/// that does not fit in a demo.
pub struct LaggedFibonacci {
  priv s : FixedArray[UInt32]
  priv i : FixedArray[Int32]
}

///|
/// A generator over the 607 state words.
pub fn LaggedFibonacci::from_state(s : FixedArray[UInt32]) -> LaggedFibonacci {
  if s.length() != 607 {
    abort("LaggedFibonacci: state is 607 words")
  }
  { s, i: [0], }
}

///|
/// A generator from 607 words of SplitMix64 output.
pub fn LaggedFibonacci::new(seed : BytesView) -> LaggedFibonacci {
  let w = @bits.seed_words(seed, 304)
  let s = FixedArray::make(607, 0U)
  let mut any = false
  for i = 0; i < 303; i = i + 1 {
    s[i * 2] = w[i].to_uint()
    s[i * 2 + 1] = (w[i] >> 32).to_uint()
  }
  s[606] = w[303].to_uint()
  for i = 0; i < 607; i = i + 1 {
    any = any || s[i] != 0U
  }
  if !any {
    s[0] = 1U
  }
  LaggedFibonacci::from_state(s)
}

///|
pub impl @contract.Rng for LaggedFibonacci with fn next_u32(self) -> UInt32 {
  let j = (self.i[0] + 334) % 607
  let v = self.s[self.i[0]] + self.s[j]
  self.s[self.i[0]] = v
  self.i[0] = j
  v
}

///|
pub impl @contract.Rng for LaggedFibonacci with fn next_u64(self) -> UInt64 {
  (self.next_u32().to_uint64() << 32) | self.next_u32().to_uint64()
}

///|
pub impl @contract.Seeded for LaggedFibonacci with fn from_seed(
  seed : BytesView,
) -> LaggedFibonacci {
  LaggedFibonacci::new(seed)
}

///|
pub impl @contract.Seeded for LaggedFibonacci with fn seed_size() -> Int32 {
  2428
}

///|
/// AddWithCarry: Marsaglia's add-with-carry over 55 words, the carry kept
/// across draws so that the recurrence is not linear modulo 2^32.
pub struct AddWithCarry {
  priv s : FixedArray[UInt32]
  priv i : FixedArray[Int32]
  priv carry : FixedArray[UInt32]
}

///|
/// A generator over the 55 state words, with the carry clear.
pub fn AddWithCarry::from_state(s : FixedArray[UInt32]) -> AddWithCarry {
  if s.length() != 55 {
    abort("AddWithCarry: state is 55 words")
  }
  { s, i: [0], carry: [0], }
}

///|
/// A generator from 55 words of SplitMix64 output.
pub fn AddWithCarry::new(seed : BytesView) -> AddWithCarry {
  let base = AdditiveCongruential::new(seed)
  let s = FixedArray::make(55, 0U)
  for i = 0; i < 55; i = i + 1 {
    s[i] = base.s[i]
  }
  AddWithCarry::from_state(s)
}

///|
pub impl @contract.Rng for AddWithCarry with fn next_u32(self) -> UInt32 {
  let j = (self.i[0] + 31) % 55
  let sum = self.s[self.i[0]].to_uint64() +
    self.s[j].to_uint64() +
    self.carry[0].to_uint64()
  self.s[self.i[0]] = (sum & 0xFFFFFFFFUL).to_uint()
  self.carry[0] = (sum >> 32).to_uint()
  let v = self.s[self.i[0]]
  self.i[0] = j
  v
}

///|
pub impl @contract.Rng for AddWithCarry with fn next_u64(self) -> UInt64 {
  (self.next_u32().to_uint64() << 32) | self.next_u32().to_uint64()
}

///|
pub impl @contract.Seeded for AddWithCarry with fn from_seed(seed : BytesView) -> AddWithCarry {
  AddWithCarry::new(seed)
}

///|
pub impl @contract.Seeded for AddWithCarry with fn seed_size() -> Int32 {
  220
}

///|
/// SubtractWithBorrow: the same shape with a borrow, over 55 words. The borrow
/// is what makes the state more than the sum of its words.
pub struct SubtractWithBorrow {
  priv s : FixedArray[UInt32]
  priv i : FixedArray[Int32]
  priv borrow : FixedArray[UInt32]
}

///|
/// A generator over the 55 state words, with the borrow clear.
pub fn SubtractWithBorrow::from_state(
  s : FixedArray[UInt32],
) -> SubtractWithBorrow {
  if s.length() != 55 {
    abort("SubtractWithBorrow: state is 55 words")
  }
  { s, i: [0], borrow: [0], }
}

///|
/// A generator from 55 words of SplitMix64 output.
pub fn SubtractWithBorrow::new(seed : BytesView) -> SubtractWithBorrow {
  let base = AdditiveCongruential::new(seed)
  let s = FixedArray::make(55, 0U)
  for i = 0; i < 55; i = i + 1 {
    s[i] = base.s[i]
  }
  SubtractWithBorrow::from_state(s)
}

///|
pub impl @contract.Rng for SubtractWithBorrow with fn next_u32(self) -> UInt32 {
  let j = (self.i[0] + 31) % 55
  let diff = self.s[self.i[0]].to_int64() -
    self.s[j].to_int64() -
    self.borrow[0].to_int64()
  if diff < 0L {
    self.s[self.i[0]] = (diff + 4294967296L).to_int().reinterpret_as_uint()
    self.borrow[0] = 1U
  } else {
    self.s[self.i[0]] = diff.to_int().reinterpret_as_uint()
    self.borrow[0] = 0U
  }
  let v = self.s[self.i[0]]
  self.i[0] = j
  v
}

///|
pub impl @contract.Rng for SubtractWithBorrow with fn next_u64(self) -> UInt64 {
  (self.next_u32().to_uint64() << 32) | self.next_u32().to_uint64()
}

///|
pub impl @contract.Seeded for SubtractWithBorrow with fn from_seed(
  seed : BytesView,
) -> SubtractWithBorrow {
  SubtractWithBorrow::new(seed)
}

///|
pub impl @contract.Seeded for SubtractWithBorrow with fn seed_size() -> Int32 {
  220
}

///|
/// The seeding recurrence the ranlux bases use: a 32-bit linear congruential
/// generator over the prime 2^31-1, its values taken as the state words and
/// zeros replaced by one.
fn ranlux_fill(seed : BytesView, n : Int32, bits : Int32) -> FixedArray[UInt64] {
  let w = @bits.seed_words(seed, 1)[0]
  let mut x = w % 2147483563UL
  if x == 0UL {
    x = 1UL
  }
  let mask = if bits == 24 { 0xFFFFFFUL } else { 0xFFFFFFFFFFFFUL }
  let out = FixedArray::make(n, 1UL)
  for i = 0; i < n; i = i + 1 {
    x = 40014UL * x % 2147483563UL
    let v = x & mask
    out[i] = if v == 0UL { 1UL } else { v }
  }
  out
}

///|
/// Ranlux24: subtract-with-borrow over 24-bit words, 24 of them with a lag of
/// ten, and all but one in 223 of each block thrown away. The discard is what
/// turns a weak linear recurrence into something that passes the tests.
pub struct Ranlux24 {
  priv s : FixedArray[UInt32]
  priv i : FixedArray[Int32]
  priv carry : FixedArray[UInt32]
}

///|
/// A generator over the 24 state words.
pub fn Ranlux24::from_state(s : FixedArray[UInt32]) -> Ranlux24 {
  if s.length() != 24 {
    abort("Ranlux24: state is 24 words")
  }
  { s, i: [0], carry: [0], }
}

///|
/// A generator from eight bytes, seeded the way the reference does.
pub fn Ranlux24::new(seed : BytesView) -> Ranlux24 {
  let w = ranlux_fill(seed, 24, 24)
  let s = FixedArray::make(24, 0U)
  for i = 0; i < 24; i = i + 1 {
    s[i] = w[i].to_uint()
  }
  Ranlux24::from_state(s)
}

///|
/// One step of the underlying recurrence: x(i) = x(i-24) - x(i-10) - carry.
fn ranlux24_step(g : Ranlux24) -> UInt32 {
  let j = (g.i[0] + 14) % 24
  let diff = g.s[g.i[0]].to_int64() - g.s[j].to_int64() - g.carry[0].to_int64()
  let v = if diff < 0L {
    g.carry[0] = 1U
    diff + 16777216L
  } else {
    g.carry[0] = 0U
    diff
  }
  g.s[g.i[0]] = v.to_int().reinterpret_as_uint()
  g.i[0] = j
  g.s[j]
}

///|
pub impl @contract.Rng for Ranlux24 with fn next_u32(self) -> UInt32 {
  for _k = 0; _k < 223; _k = _k + 1 {
    ignore(ranlux24_step(self))
  }
  ranlux24_step(self)
}

///|
pub impl @contract.Rng for Ranlux24 with fn next_u64(self) -> UInt64 {
  (self.next_u32().to_uint64() << 32) | self.next_u32().to_uint64()
}

///|
pub impl @contract.Seeded for Ranlux24 with fn from_seed(seed : BytesView) -> Ranlux24 {
  Ranlux24::new(seed)
}

///|
pub impl @contract.Seeded for Ranlux24 with fn seed_size() -> Int32 {
  8
}

///|
/// Ranlux48: the same generator over 48-bit words, twelve of them with a lag of
/// five, discarding 389 of every 390.
pub struct Ranlux48 {
  priv s : FixedArray[UInt64]
  priv i : FixedArray[Int32]
  priv carry : FixedArray[UInt64]
}

///|
/// A generator over the twelve state words.
pub fn Ranlux48::from_state(s : FixedArray[UInt64]) -> Ranlux48 {
  if s.length() != 12 {
    abort("Ranlux48: state is twelve words")
  }
  { s, i: [0], carry: [0], }
}

///|
/// A generator from eight bytes, seeded the way the reference does.
pub fn Ranlux48::new(seed : BytesView) -> Ranlux48 {
  Ranlux48::from_state(ranlux_fill(seed, 12, 48))
}

///|
fn ranlux48_step(g : Ranlux48) -> UInt64 {
  let j = (g.i[0] + 7) % 12
  let diff = g.s[g.i[0]] - g.s[j] - g.carry[0]
  let v = if g.s[g.i[0]] < g.s[j] + g.carry[0] {
    g.carry[0] = 1UL
    diff + 281474976710656UL
  } else {
    g.carry[0] = 0UL
    diff
  }
  g.s[g.i[0]] = v
  g.i[0] = j
  g.s[j]
}

///|
pub impl @contract.Rng for Ranlux48 with fn next_u64(self) -> UInt64 {
  for _k = 0; _k < 389; _k = _k + 1 {
    ignore(ranlux48_step(self))
  }
  ranlux48_step(self)
}

///|
pub impl @contract.Seeded for Ranlux48 with fn from_seed(seed : BytesView) -> Ranlux48 {
  Ranlux48::new(seed)
}

///|
pub impl @contract.Seeded for Ranlux48 with fn seed_size() -> Int32 {
  8
}

///|
pub extend AdditiveCongruential with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend AdditiveCongruential with @contract.Seeded::{from_seed, seed_size}

///|
pub extend LaggedFibonacci with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend LaggedFibonacci with @contract.Seeded::{from_seed, seed_size}

///|
pub extend AddWithCarry with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend AddWithCarry with @contract.Seeded::{from_seed, seed_size}

///|
pub extend SubtractWithBorrow with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend SubtractWithBorrow with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Ranlux24 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Ranlux24 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Ranlux48 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Ranlux48 with @contract.Seeded::{from_seed, seed_size}
