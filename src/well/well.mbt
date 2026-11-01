///|
/// WELL512a: sixteen 32-bit words and an index, period 2^512-1. The recursion
/// is the reference `WELLRNG512a`, down to the mask on the temepering shift.
pub struct Well512 {
  priv s : FixedArray[UInt32]
  priv i : FixedArray[Int32]
}

///|
/// A generator over sixteen state words, starting at index zero.
pub fn Well512::from_state(s : FixedArray[UInt32]) -> Well512 {
  if s.length() != 16 {
    abort("Well512: state is sixteen words")
  }
  { s, i: [0], }
}

///|
/// A generator seeded from 64 bytes through SplitMix64.
pub fn Well512::new(seed : BytesView) -> Well512 {
  let w = @bits.seed_words(seed, 8)
  let s = FixedArray::make(16, 0U)
  let mut any = false
  for i = 0; i < 8; i = i + 1 {
    s[i * 2] = w[i].to_uint()
    s[i * 2 + 1] = (w[i] >> 32).to_uint()
    any = any || s[i * 2] != 0U || s[i * 2 + 1] != 0U
  }
  if !any {
    s[0] = 1U
  }
  Well512::from_state(s)
}

///|
pub impl @contract.Rng for Well512 with fn next_u32(self) -> UInt32 {
  let i = self.i[0]
  let a = self.s[i]
  let c = self.s[(i + 13) & 15]
  let b = a ^ c ^ (a << 16) ^ (c << 15)
  let c2 = self.s[(i + 9) & 15] ^ (self.s[(i + 9) & 15] >> 11)
  let a2 = b ^ c2
  self.s[i] = a2
  let d = a2 ^ ((a2 << 5) & 0xDA442D24U)
  self.i[0] = (i + 15) & 15
  let a3 = self.s[self.i[0]]
  self.s[self.i[0]] = a3 ^ a2 ^ d ^ (a3 << 2) ^ (a2 << 18) ^ (c2 << 28)
  self.s[self.i[0]]
}

///|
pub impl @contract.Rng for Well512 with fn next_u64(self) -> UInt64 {
  (self.next_u32().to_uint64() << 32) | self.next_u32().to_uint64()
}

///|
pub impl @contract.Seeded for Well512 with fn from_seed(seed : BytesView) -> Well512 {
  Well512::new(seed)
}

///|
pub impl @contract.Seeded for Well512 with fn seed_size() -> Int32 {
  64
}

///|
pub extend Well512 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Well512 with @contract.Seeded::{from_seed, seed_size}
