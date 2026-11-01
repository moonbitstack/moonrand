///|
/// WELL1024a: thirty-two 32-bit words, period 2^1024-1, the same construction
/// as WELL512a with a longer ring. The tempering mask differs per instance and
/// is the one the WELL reference gives for 1024a.
pub struct Well1024 {
  priv s : FixedArray[UInt32]
  priv i : FixedArray[Int32]
}

///|
/// A generator over thirty-two state words, starting at index zero.
pub fn Well1024::from_state(s : FixedArray[UInt32]) -> Well1024 {
  if s.length() != 32 {
    abort("Well1024: state is thirty-two words")
  }
  { s, i: [0], }
}

///|
/// A generator seeded from 128 bytes through SplitMix64.
pub fn Well1024::new(seed : BytesView) -> Well1024 {
  let w = @bits.seed_words(seed, 16)
  let s = FixedArray::make(32, 0U)
  let mut any = false
  for i = 0; i < 16; i = i + 1 {
    s[i * 2] = w[i].to_uint()
    s[i * 2 + 1] = (w[i] >> 32).to_uint()
    any = any || s[i * 2] != 0U || s[i * 2 + 1] != 0U
  }
  if !any {
    s[0] = 1U
  }
  Well1024::from_state(s)
}

///|
pub impl @contract.Rng for Well1024 with fn next_u32(self) -> UInt32 {
  let i = self.i[0]
  let a = self.s[i]
  let c = self.s[(i + 24) & 31]
  let b = a ^ c ^ (a << 8) ^ (c >> 19)
  let c2 = self.s[(i + 13) & 31] ^ (self.s[(i + 13) & 31] << 4)
  let a2 = b ^ c2
  self.s[i] = a2
  let d = a2 ^ ((a2 << 14) & 0x97A5A5D8U)
  self.i[0] = (i + 31) & 31
  let a3 = self.s[self.i[0]]
  self.s[self.i[0]] = a3 ^ a2 ^ d ^ (a3 << 11) ^ (b << 23)
  self.s[self.i[0]]
}

///|
pub impl @contract.Rng for Well1024 with fn next_u64(self) -> UInt64 {
  (self.next_u32().to_uint64() << 32) | self.next_u32().to_uint64()
}

///|
pub impl @contract.Seeded for Well1024 with fn from_seed(seed : BytesView) -> Well1024 {
  Well1024::new(seed)
}

///|
pub impl @contract.Seeded for Well1024 with fn seed_size() -> Int32 {
  128
}

///|
pub extend Well1024 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Well1024 with @contract.Seeded::{from_seed, seed_size}
