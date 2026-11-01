///|
/// SFMT19937: the SIMD-oriented Fast Mersenne Twister. Same period as MT19937
/// (2^19937-1) and the same tempered output, but the state is 156 blocks of 128
/// bits and the recursion mixes whole blocks, which is what makes it faster.
///
/// The parameters below are the published ones for the 19937 instance; the
/// state is held as the 624 words the blocks are made of.

///|
const SFMT_POS1 : Int32 = 122

///|
const SFMT_SL1 : Int32 = 18

///|
const SFMT_SR1 : Int32 = 11

///|
/// The four masks of the recursion, one per word of a block.
fn sfmt_masks() -> FixedArray[UInt32] {
  [0xDFFFFFEFU, 0xDDFECB7FU, 0xBFFAFFFFU, 0xBFFFFFF6U]
}

///|
/// One recursion step: `r` gets `a`, `a` shifted a byte, `b` shifted and masked,
/// `c` shifted the other way and `d` shifted by SL1, xored together. `r` and `a`
/// may be the same block, so the four words are read before anything is written.
fn sfmt_recursion(
  s : FixedArray[UInt32],
  r : Int32,
  a : Int32,
  b : Int32,
  c : Int32,
  d : Int32,
) -> Unit {
  let a0 = s[a]
  let a1 = s[a + 1]
  let a2 = s[a + 2]
  let a3 = s[a + 3]
  let c0 = s[c]
  let c1 = s[c + 1]
  let c2 = s[c + 2]
  let c3 = s[c + 3]
  // a << one byte, over the whole 128-bit block.
  let x0 = a0 << 8
  let x1 = (a1 << 8) | (a0 >> 24)
  let x2 = (a2 << 8) | (a1 >> 24)
  let x3 = (a3 << 8) | (a2 >> 24)
  // c >> one byte.
  let y0 = (c0 >> 8) | (c1 << 24)
  let y1 = (c1 >> 8) | (c2 << 24)
  let y2 = (c2 >> 8) | (c3 << 24)
  let y3 = c3 >> 8
  let m = sfmt_masks()
  s[r] = a0 ^ x0 ^ ((s[b] >> SFMT_SR1) & m[0]) ^ y0 ^ (s[d] << SFMT_SL1)
  s[r + 1] = a1 ^
    x1 ^
    ((s[b + 1] >> SFMT_SR1) & m[1]) ^
    y1 ^
    (s[d + 1] << SFMT_SL1)
  s[r + 2] = a2 ^
    x2 ^
    ((s[b + 2] >> SFMT_SR1) & m[2]) ^
    y2 ^
    (s[d + 2] << SFMT_SL1)
  s[r + 3] = a3 ^
    x3 ^
    ((s[b + 3] >> SFMT_SR1) & m[3]) ^
    y3 ^
    (s[d + 3] << SFMT_SL1)
}

///|
/// SFMT19937.
pub struct Sfmt19937 {
  priv s : FixedArray[UInt32]
  priv i : FixedArray[Int32]
}

///|
/// Whether the state has the full period: the parity of the first four words
/// against the published parity words must come out odd. If it does not, the
/// lowest set bit of the first parity word is flipped, which is what the
/// reference does.
fn sfmt_certify(g : Sfmt19937) -> Unit {
  let parity : FixedArray[UInt32] = [0x00000001U, 0U, 0U, 0x13C9E684U]
  let mut inner = 0U
  for i = 0; i < 4; i = i + 1 {
    inner = inner ^ (g.s[i] & parity[i])
  }
  let mut k = 16
  while k > 0 {
    inner = inner ^ (inner >> k)
    k = k >> 1
  }
  if (inner & 1U) == 0U {
    for i = 0; i < 4; i = i + 1 {
      let mut work = 1U
      let mut done = false
      for _j = 0; _j < 32; _j = _j + 1 {
        if !done && (work & parity[i]) != 0U {
          g.s[i] = g.s[i] ^ work
          done = true
        }
        work = work << 1
      }
    }
  }
}

///|
/// The reference seeding `init_gen_rand`: one word, expanded by the same
/// 1812433253 recursion MT19937 uses, then certified.
pub fn Sfmt19937::with_word(seed : UInt32) -> Sfmt19937 {
  let g : Sfmt19937 = { s: FixedArray::make(624, 0U), i: [0], }
  g.s[0] = seed
  for i = 1; i < 624; i = i + 1 {
    g.s[i] = 1812433253U * (g.s[i - 1] ^ (g.s[i - 1] >> 30)) +
      i.reinterpret_as_uint()
  }
  sfmt_certify(g)
  g.i[0] = 624
  g
}

///|
fn sfmt_func1(x : UInt32) -> UInt32 {
  (x ^ (x >> 27)) * 1664525U
}

///|
fn sfmt_func2(x : UInt32) -> UInt32 {
  (x ^ (x >> 27)) * 1566083941U
}

///|
/// The reference seeding `init_by_array`: a key of any length, mixed through
/// three passes over the state.
pub fn Sfmt19937::from_array(keys : FixedArray[UInt32]) -> Sfmt19937 {
  let g : Sfmt19937 = { s: FixedArray::make(624, 0U), i: [0], }
  for i = 0; i < 624; i = i + 1 {
    g.s[i] = 0x8B8B8B8BU
  }
  let n = keys.length()
  let lag = 11
  let mid = 306
  let count = if n + 1 > 624 { n + 1 } else { 624 }
  let mut r = sfmt_func1(g.s[0] ^ g.s[mid] ^ g.s[623])
  g.s[mid] = g.s[mid] + r
  r = r + n.reinterpret_as_uint()
  g.s[mid + lag] = g.s[mid + lag] + r
  g.s[0] = r
  let mut i = 1
  let mut j = 0
  let total = count - 1
  while j < total && j < n {
    r = sfmt_func1(g.s[i] ^ g.s[(i + mid) % 624] ^ g.s[(i + 623) % 624])
    g.s[(i + mid) % 624] = g.s[(i + mid) % 624] + r
    r = r + keys[j] + i.reinterpret_as_uint()
    g.s[(i + mid + lag) % 624] = g.s[(i + mid + lag) % 624] + r
    g.s[i] = r
    i = (i + 1) % 624
    j = j + 1
  }
  while j < total {
    r = sfmt_func1(g.s[i] ^ g.s[(i + mid) % 624] ^ g.s[(i + 623) % 624])
    g.s[(i + mid) % 624] = g.s[(i + mid) % 624] + r
    r = r + i.reinterpret_as_uint()
    g.s[(i + mid + lag) % 624] = g.s[(i + mid + lag) % 624] + r
    g.s[i] = r
    i = (i + 1) % 624
    j = j + 1
  }
  for _k = 0; _k < 624; _k = _k + 1 {
    r = sfmt_func2(g.s[i] + g.s[(i + mid) % 624] + g.s[(i + 623) % 624])
    g.s[(i + mid) % 624] = g.s[(i + mid) % 624] ^ r
    r = r - i.reinterpret_as_uint()
    g.s[(i + mid + lag) % 624] = g.s[(i + mid + lag) % 624] ^ r
    g.s[i] = r
    i = (i + 1) % 624
  }
  sfmt_certify(g)
  g.i[0] = 624
  g
}

///|
/// A generator from a byte seed, four bytes at a time, little endian.
pub fn Sfmt19937::new(seed : BytesView) -> Sfmt19937 {
  let w = @bits.seed_words(seed, 1)[0]
  Sfmt19937::with_word(w.to_uint())
}

///|
/// One pass of the block recursion over the whole state.
fn sfmt_gen_all(g : Sfmt19937) -> Unit {
  let n = 156
  let mut r1 = n - 2
  let mut r2 = n - 1
  for i = 0; i < n - SFMT_POS1; i = i + 1 {
    sfmt_recursion(g.s, i * 4, i * 4, (i + SFMT_POS1) * 4, r1 * 4, r2 * 4)
    r1 = r2
    r2 = i
  }
  for i = n - SFMT_POS1; i < n; i = i + 1 {
    sfmt_recursion(g.s, i * 4, i * 4, (i + SFMT_POS1 - n) * 4, r1 * 4, r2 * 4)
    r1 = r2
    r2 = i
  }
  g.i[0] = 0
}

///|
fn sfmt_word(g : Sfmt19937) -> UInt32 {
  if g.i[0] >= 624 {
    sfmt_gen_all(g)
  }
  let v = g.s[g.i[0]]
  g.i[0] = g.i[0] + 1
  v
}

///|
pub impl @contract.Rng for Sfmt19937 with fn next_u32(self) -> UInt32 {
  sfmt_word(self)
}

///|
pub impl @contract.Rng for Sfmt19937 with fn next_u64(self) -> UInt64 {
  (sfmt_word(self).to_uint64() << 32) | sfmt_word(self).to_uint64()
}

///|
pub impl @contract.Seeded for Sfmt19937 with fn from_seed(seed : BytesView) -> Sfmt19937 {
  Sfmt19937::new(seed)
}

///|
pub impl @contract.Seeded for Sfmt19937 with fn seed_size() -> Int32 {
  4
}

///|
pub extend Sfmt19937 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Sfmt19937 with @contract.Seeded::{from_seed, seed_size}
