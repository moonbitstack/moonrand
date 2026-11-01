///|
/// MT19937: the 32-bit Mersenne Twister, period 2^19937-1, 624 words of state
/// and an index into them. The seeding, the twist and the tempering are the
/// reference `init_genrand`, `init_by_array` and `genrand_int32`.
pub struct MT19937 {
  priv s : FixedArray[UInt32]
  priv i : FixedArray[Int32]
}

///|
/// The reference seeding `init_genrand`: one word, expanded by the
/// 1812433253 recursion.
pub fn MT19937::with_word(seed : UInt32) -> MT19937 {
  let g : MT19937 = { s: FixedArray::make(624, 0U), i: [0], }
  g.s[0] = seed
  for i = 1; i < 624; i = i + 1 {
    g.s[i] = 1812433253U * (g.s[i - 1] ^ (g.s[i - 1] >> 30)) +
      i.reinterpret_as_uint()
  }
  g.i[0] = 624
  g
}

///|
/// The reference seeding `init_by_array`: a key of any length, mixed in.
pub fn MT19937::from_array(keys : FixedArray[UInt32]) -> MT19937 {
  let g = MT19937::with_word(19650218U)
  let n = keys.length()
  let mut i = 1
  let mut j = 0
  let mut k = if 624 > n { 624 } else { n }
  while k > 0 {
    g.s[i] = (g.s[i] ^ ((g.s[i - 1] ^ (g.s[i - 1] >> 30)) * 1664525U)) +
      keys[j] +
      j.reinterpret_as_uint()
    i = i + 1
    j = j + 1
    if i >= 624 {
      g.s[0] = g.s[623]
      i = 1
    }
    if j >= n {
      j = 0
    }
    k = k - 1
  }
  k = 623
  while k > 0 {
    g.s[i] = (g.s[i] ^ ((g.s[i - 1] ^ (g.s[i - 1] >> 30)) * 1566083941U)) -
      i.reinterpret_as_uint()
    i = i + 1
    if i >= 624 {
      g.s[0] = g.s[623]
      i = 1
    }
    k = k - 1
  }
  g.s[0] = 0x80000000U
  g.i[0] = 624
  g
}

///|
/// A generator from a byte seed: four bytes at a time, little endian, handed to
/// `from_array`. A seed shorter than four bytes is zero-padded.
pub fn MT19937::new(seed : BytesView) -> MT19937 {
  let n = if seed.length() < 4 { 4 } else { seed.length() }
  let words = (n + 3) / 4
  let keys = FixedArray::make(words, 0U)
  for i = 0; i < words; i = i + 1 {
    let mut w = 0U
    for j = 0; j < 4; j = j + 1 {
      let idx = i * 4 + j
      if idx < seed.length() {
        w = w | (seed[idx].to_uint() << (j * 8))
      }
    }
    keys[i] = w
  }
  MT19937::from_array(keys)
}

///|
/// The twist: 624 words folded into the next 624.
fn mt_twist(g : MT19937) -> Unit {
  for i = 0; i < 624; i = i + 1 {
    let y = (g.s[i] & 0x80000000U) |
      (g.s[if i + 1 == 624 { 0 } else { i + 1 }] & 0x7FFFFFFFU)
    let nxt = if i + 397 >= 624 { i + 397 - 624 } else { i + 397 }
    g.s[i] = g.s[nxt] ^
      (y >> 1) ^
      (if (y & 1U) == 1U { 0x9908B0DFU } else { 0U })
  }
  g.i[0] = 0
}

///|
/// One tempered 32-bit draw.
fn mt_word(g : MT19937) -> UInt32 {
  if g.i[0] >= 624 {
    mt_twist(g)
  }
  let mut y = g.s[g.i[0]]
  g.i[0] = g.i[0] + 1
  y = y ^ (y >> 11)
  y = y ^ ((y << 7) & 0x9D2C5680U)
  y = y ^ ((y << 15) & 0xEFC60000U)
  y ^ (y >> 18)
}

///|
pub impl @contract.Rng for MT19937 with fn next_u64(self) -> UInt64 {
  (mt_word(self).to_uint64() << 32) | mt_word(self).to_uint64()
}

///|
pub impl @contract.Rng for MT19937 with fn next_u32(self) -> UInt32 {
  mt_word(self)
}

///|
pub impl @contract.Seeded for MT19937 with fn from_seed(seed : BytesView) -> MT19937 {
  MT19937::new(seed)
}

///|
pub impl @contract.Seeded for MT19937 with fn seed_size() -> Int32 {
  4
}

///|
/// MT19937-64: the 64-bit Mersenne Twister, period 2^19937-1, 312 words.
pub struct MT19937_64 {
  priv s : FixedArray[UInt64]
  priv i : FixedArray[Int32]
}

///|
/// The reference seeding `init_genrand64`.
pub fn MT19937_64::with_word(seed : UInt64) -> MT19937_64 {
  let g : MT19937_64 = { s: FixedArray::make(312, 0UL), i: [0], }
  g.s[0] = seed
  for i = 1; i < 312; i = i + 1 {
    g.s[i] = 6364136223846793005UL * (g.s[i - 1] ^ (g.s[i - 1] >> 62)) +
      i.to_uint64()
  }
  g.i[0] = 312
  g
}

///|
/// The reference seeding `init_by_array64`.
pub fn MT19937_64::from_array(keys : FixedArray[UInt64]) -> MT19937_64 {
  let g = MT19937_64::with_word(19650218UL)
  let n = keys.length()
  let mut i = 1
  let mut j = 0
  let mut k = if 312 > n { 312 } else { n }
  while k > 0 {
    g.s[i] = (
        g.s[i] ^ ((g.s[i - 1] ^ (g.s[i - 1] >> 62)) * 3935559000370003845UL)
      ) +
      keys[j] +
      j.to_uint64()
    i = i + 1
    j = j + 1
    if i >= 312 {
      g.s[0] = g.s[311]
      i = 1
    }
    if j >= n {
      j = 0
    }
    k = k - 1
  }
  k = 311
  while k > 0 {
    g.s[i] = (
        g.s[i] ^ ((g.s[i - 1] ^ (g.s[i - 1] >> 62)) * 2862933555777941757UL)
      ) -
      i.to_uint64()
    i = i + 1
    if i >= 312 {
      g.s[0] = g.s[311]
      i = 1
    }
    k = k - 1
  }
  g.s[0] = 1UL << 63
  g.i[0] = 312
  g
}

///|
/// A generator from a byte seed, eight bytes at a time, little endian.
pub fn MT19937_64::new(seed : BytesView) -> MT19937_64 {
  let n = if seed.length() < 8 { 8 } else { seed.length() }
  let words = (n + 7) / 8
  let keys = FixedArray::make(words, 0UL)
  for i = 0; i < words; i = i + 1 {
    let mut w = 0UL
    for j = 0; j < 8; j = j + 1 {
      let idx = i * 8 + j
      if idx < seed.length() {
        w = w | (seed[idx].to_uint64() << (j * 8))
      }
    }
    keys[i] = w
  }
  MT19937_64::from_array(keys)
}

///|
fn mt64_twist(g : MT19937_64) -> Unit {
  for i = 0; i < 312; i = i + 1 {
    let y = (g.s[i] & 0xFFFFFFFF80000000UL) |
      (g.s[if i + 1 == 312 { 0 } else { i + 1 }] & 0x7FFFFFFFUL)
    let nxt = if i + 156 >= 312 { i + 156 - 312 } else { i + 156 }
    g.s[i] = g.s[nxt] ^
      (y >> 1) ^
      (if (y & 1UL) == 1UL { 0xB5026F5AA96619E9UL } else { 0UL })
  }
  g.i[0] = 0
}

///|
fn mt64_word(g : MT19937_64) -> UInt64 {
  if g.i[0] >= 312 {
    mt64_twist(g)
  }
  let mut x = g.s[g.i[0]]
  g.i[0] = g.i[0] + 1
  x = x ^ ((x >> 29) & 0x5555555555555555UL)
  x = x ^ ((x << 17) & 0x71D67FFFEDA60000UL)
  x = x ^ ((x << 37) & 0xFFF7EEE000000000UL)
  x ^ (x >> 43)
}

///|
pub impl @contract.Rng for MT19937_64 with fn next_u64(self) -> UInt64 {
  mt64_word(self)
}

///|
pub impl @contract.Seeded for MT19937_64 with fn from_seed(seed : BytesView) -> MT19937_64 {
  MT19937_64::new(seed)
}

///|
pub impl @contract.Seeded for MT19937_64 with fn seed_size() -> Int32 {
  8
}

///|
pub extend MT19937 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend MT19937 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend MT19937_64 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend MT19937_64 with @contract.Seeded::{from_seed, seed_size}
