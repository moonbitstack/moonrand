///|
/// Threefry: the counter-based generator built from add, rotate and xor only —
/// no multiplication, which is what makes it the one to reach for on hardware
/// where a 64-bit multiply is not one instruction.
///
/// The rotation schedule is the one published with the algorithm; the key is
/// mixed in every fourth round from a five-word schedule whose last word is the
/// parity constant.

///|
/// The parity constant of the key schedule, the same one Threefish uses.
const PARITY : UInt64 = 0x1BD11BDAA9FC1A22UL

///|
/// The rotation constants, in pairs, taken in order and repeated when the
/// rounds outlast them.
fn threefry_rotations() -> FixedArray[Int32] {
  [14, 16, 52, 57, 23, 40, 5, 37, 25, 33, 46, 12, 58, 22, 32, 32]
}

///|
/// Threefry4x64: four 64-bit counter words, two 64-bit key words, twenty
/// rounds.
pub struct Threefry4x64 {
  priv ctr : FixedArray[UInt64]
  priv key : FixedArray[UInt64]
  priv out : FixedArray[UInt64]
  priv pos : FixedArray[Int32]
}

///|
/// A generator with the key `k0`, `k1` and a zero counter.
pub fn Threefry4x64::with_key(k0 : UInt64, k1 : UInt64) -> Threefry4x64 {
  {
    ctr: FixedArray::make(4, 0UL),
    key: [k0, k1],
    out: FixedArray::make(4, 0UL),
    pos: [4],
  }
}

///|
/// A generator keyed from sixteen bytes.
pub fn Threefry4x64::new(seed : BytesView) -> Threefry4x64 {
  let w = @bits.seed_words(seed, 2)
  Threefry4x64::with_key(w[0], w[1])
}

///|
fn rotl64(x : UInt64, k : Int32) -> UInt64 {
  (x << k) | (x >> (64 - k))
}

///|
fn threefry4x64_block(
  ctr : FixedArray[UInt64],
  key : FixedArray[UInt64],
  out : FixedArray[UInt64],
) -> Unit {
  let ks : FixedArray[UInt64] = [
    key[0],
    key[1],
    0UL,
    0UL,
    PARITY ^ key[0] ^ key[1],
  ]
  let rot = threefry_rotations()
  let x = FixedArray::make(4, 0UL)
  for i = 0; i < 4; i = i + 1 {
    x[i] = ctr[i] + ks[i]
  }
  for r = 0; r < 20; r = r + 1 {
    let a = rot[r % 8 * 2]
    let b = rot[r % 8 * 2 + 1]
    x[0] = x[0] + x[1]
    x[1] = rotl64(x[1], a) ^ x[0]
    x[2] = x[2] + x[3]
    x[3] = rotl64(x[3], b) ^ x[2]
    let t = x[1]
    x[1] = x[3]
    x[3] = t
    if (r + 1) % 4 == 0 {
      let s = (r + 1) / 4
      for i = 0; i < 4; i = i + 1 {
        x[i] = x[i] + ks[(s + i) % 5]
      }
    }
  }
  for i = 0; i < 4; i = i + 1 {
    out[i] = x[i]
  }
  ctr[0] = ctr[0] + 1UL
  if ctr[0] == 0UL {
    ctr[1] = ctr[1] + 1UL
    if ctr[1] == 0UL {
      ctr[2] = ctr[2] + 1UL
      if ctr[2] == 0UL {
        ctr[3] = ctr[3] + 1UL
      }
    }
  }
}

///|
/// Skip `n` 64-bit draws by stepping the counter.
pub fn Threefry4x64::advance(self : Threefry4x64, n : UInt64) -> Unit {
  let used = self.pos[0] % 4
  let at = self.ctr[0] * 4UL + used.to_uint64() + n
  let block = at / 4UL
  let rest = (at % 4UL).to_int()
  self.ctr[0] = block
  if rest == 0 {
    self.pos[0] = 4
  } else {
    threefry4x64_block(self.ctr, self.key, self.out)
    self.pos[0] = rest
  }
}

///|
fn threefry4x64_word(g : Threefry4x64) -> UInt64 {
  if g.pos[0] >= 4 {
    threefry4x64_block(g.ctr, g.key, g.out)
    g.pos[0] = 0
  }
  let v = g.out[g.pos[0]]
  g.pos[0] = g.pos[0] + 1
  v
}

///|
pub impl @contract.Rng for Threefry4x64 with fn next_u64(self) -> UInt64 {
  threefry4x64_word(self)
}

///|
pub impl @contract.Seeded for Threefry4x64 with fn from_seed(seed : BytesView) -> Threefry4x64 {
  Threefry4x64::new(seed)
}

///|
pub impl @contract.Seeded for Threefry4x64 with fn seed_size() -> Int32 {
  16
}

///|
/// Threefry4x32: the same schedule over 32-bit words.
pub struct Threefry4x32 {
  priv ctr : FixedArray[UInt32]
  priv key : FixedArray[UInt32]
  priv out : FixedArray[UInt32]
  priv pos : FixedArray[Int32]
}

///|
/// A generator with the key `k0`, `k1` and a zero counter.
pub fn Threefry4x32::with_key(k0 : UInt32, k1 : UInt32) -> Threefry4x32 {
  {
    ctr: FixedArray::make(4, 0U),
    key: [k0, k1],
    out: FixedArray::make(4, 0U),
    pos: [4],
  }
}

///|
/// A generator keyed from eight bytes.
pub fn Threefry4x32::new(seed : BytesView) -> Threefry4x32 {
  let w = @bits.seed_words(seed, 1)[0]
  Threefry4x32::with_key(w.to_uint(), (w >> 32).to_uint())
}

///|
fn rotl32(x : UInt32, k : Int32) -> UInt32 {
  (x << k) | (x >> (32 - k))
}

///|
fn threefry4x32_block(
  ctr : FixedArray[UInt32],
  key : FixedArray[UInt32],
  out : FixedArray[UInt32],
) -> Unit {
  let ks : FixedArray[UInt32] = [
    key[0],
    key[1],
    0U,
    0U,
    0x1BD11BDAU ^ key[0] ^ key[1],
  ]
  let rot = threefry_rotations()
  let x = FixedArray::make(4, 0U)
  for i = 0; i < 4; i = i + 1 {
    x[i] = ctr[i] + ks[i]
  }
  for r = 0; r < 20; r = r + 1 {
    let a = rot[r % 8 * 2]
    let b = rot[r % 8 * 2 + 1]
    x[0] = x[0] + x[1]
    x[1] = rotl32(x[1], a % 32) ^ x[0]
    x[2] = x[2] + x[3]
    x[3] = rotl32(x[3], b % 32) ^ x[2]
    let t = x[1]
    x[1] = x[3]
    x[3] = t
    if (r + 1) % 4 == 0 {
      let s = (r + 1) / 4
      for i = 0; i < 4; i = i + 1 {
        x[i] = x[i] + ks[(s + i) % 5]
      }
    }
  }
  for i = 0; i < 4; i = i + 1 {
    out[i] = x[i]
  }
  ctr[0] = ctr[0] + 1U
  if ctr[0] == 0U {
    ctr[1] = ctr[1] + 1U
    if ctr[1] == 0U {
      ctr[2] = ctr[2] + 1U
      if ctr[2] == 0U {
        ctr[3] = ctr[3] + 1U
      }
    }
  }
}

///|
/// Skip `n` 64-bit draws by stepping the counter.
pub fn Threefry4x32::advance(self : Threefry4x32, n : UInt64) -> Unit {
  let used = self.pos[0] % 4
  let at = self.ctr[0].to_uint64() * 4UL + used.to_uint64() + n * 2UL
  let block = at / 4UL
  let rest = (at % 4UL).to_int()
  self.ctr[0] = block.to_uint()
  self.ctr[1] = (block >> 32).to_uint()
  if rest == 0 {
    self.pos[0] = 4
  } else {
    threefry4x32_block(self.ctr, self.key, self.out)
    self.pos[0] = rest
  }
}

///|
fn threefry4x32_word(g : Threefry4x32) -> UInt32 {
  if g.pos[0] >= 4 {
    threefry4x32_block(g.ctr, g.key, g.out)
    g.pos[0] = 0
  }
  let v = g.out[g.pos[0]]
  g.pos[0] = g.pos[0] + 1
  v
}

///|
pub impl @contract.Rng for Threefry4x32 with fn next_u32(self) -> UInt32 {
  threefry4x32_word(self)
}

///|
pub impl @contract.Rng for Threefry4x32 with fn next_u64(self) -> UInt64 {
  (threefry4x32_word(self).to_uint64() << 32) |
  threefry4x32_word(self).to_uint64()
}

///|
pub impl @contract.Seeded for Threefry4x32 with fn from_seed(seed : BytesView) -> Threefry4x32 {
  Threefry4x32::new(seed)
}

///|
pub impl @contract.Seeded for Threefry4x32 with fn seed_size() -> Int32 {
  8
}

///|
/// Threefry2x64: two 64-bit counter words, thirteen rounds, its own rotation
/// schedule.
pub struct Threefry2x64 {
  priv ctr : FixedArray[UInt64]
  priv key : FixedArray[UInt64]
  priv out : FixedArray[UInt64]
  priv pos : FixedArray[Int32]
}

///|
/// A generator with the key `k0`, `k1` and a zero counter.
pub fn Threefry2x64::with_key(k0 : UInt64, k1 : UInt64) -> Threefry2x64 {
  {
    ctr: FixedArray::make(2, 0UL),
    key: [k0, k1],
    out: FixedArray::make(2, 0UL),
    pos: [2],
  }
}

///|
/// A generator keyed from sixteen bytes.
pub fn Threefry2x64::new(seed : BytesView) -> Threefry2x64 {
  let w = @bits.seed_words(seed, 2)
  Threefry2x64::with_key(w[0], w[1])
}

///|
fn threefry2x64_block(
  ctr : FixedArray[UInt64],
  key : FixedArray[UInt64],
  out : FixedArray[UInt64],
) -> Unit {
  let ks : FixedArray[UInt64] = [key[0], key[1], PARITY ^ key[0] ^ key[1]]
  let rot : FixedArray[Int32] = [
    16, 42, 12, 31, 16, 32, 24, 21, 16, 32, 24, 21, 16, 32,
  ]
  let x = FixedArray::make(2, 0UL)
  x[0] = ctr[0] + ks[0]
  x[1] = ctr[1] + ks[1]
  for r = 0; r < 13; r = r + 1 {
    x[0] = x[0] + x[1]
    x[1] = rotl64(x[1], rot[r % 14]) ^ x[0]
    if (r + 1) % 4 == 0 {
      let s = (r + 1) / 4
      for i = 0; i < 2; i = i + 1 {
        x[i] = x[i] + ks[(s + i) % 3]
      }
    }
  }
  out[0] = x[0]
  out[1] = x[1]
  ctr[0] = ctr[0] + 1UL
  if ctr[0] == 0UL {
    ctr[1] = ctr[1] + 1UL
  }
}

///|
/// Skip `n` 64-bit draws by stepping the counter.
pub fn Threefry2x64::advance(self : Threefry2x64, n : UInt64) -> Unit {
  let used = self.pos[0] % 2
  let at = self.ctr[0] * 2UL + used.to_uint64() + n
  let block = at / 2UL
  let rest = (at % 2UL).to_int()
  self.ctr[0] = block
  if rest == 0 {
    self.pos[0] = 2
  } else {
    threefry2x64_block(self.ctr, self.key, self.out)
    self.pos[0] = rest
  }
}

///|
fn threefry2x64_word(g : Threefry2x64) -> UInt64 {
  if g.pos[0] >= 2 {
    threefry2x64_block(g.ctr, g.key, g.out)
    g.pos[0] = 0
  }
  let v = g.out[g.pos[0]]
  g.pos[0] = g.pos[0] + 1
  v
}

///|
pub impl @contract.Rng for Threefry2x64 with fn next_u64(self) -> UInt64 {
  threefry2x64_word(self)
}

///|
pub impl @contract.Seeded for Threefry2x64 with fn from_seed(seed : BytesView) -> Threefry2x64 {
  Threefry2x64::new(seed)
}

///|
pub impl @contract.Seeded for Threefry2x64 with fn seed_size() -> Int32 {
  16
}

///|
pub extend Threefry4x64 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Threefry4x64 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Threefry4x32 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Threefry4x32 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Threefry2x64 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Threefry2x64 with @contract.Seeded::{from_seed, seed_size}
