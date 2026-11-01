///|
/// Philox: a counter-based generator. The state is a counter and a key, the
/// round is a multiply-high-low and a pair of xors, and there is no feedback —
/// which is why a Philox stream can be split across threads or machines by
/// handing each of them a different counter.
///
/// The round constants and the key schedule are the ones in the reference
/// implementation the algorithm was published with.
pub struct Philox4x32 {
  priv ctr : FixedArray[UInt32]
  priv key : FixedArray[UInt32]
  priv out : FixedArray[UInt32]
  priv pos : FixedArray[Int32]
}

///|
/// A generator with the key `k0`, `k1` and a zero counter.
pub fn Philox4x32::with_key(k0 : UInt32, k1 : UInt32) -> Philox4x32 {
  {
    ctr: FixedArray::make(4, 0U),
    key: [k0, k1],
    out: FixedArray::make(4, 0U),
    pos: [4],
  }
}

///|
/// A generator keyed from eight bytes.
pub fn Philox4x32::new(seed : BytesView) -> Philox4x32 {
  let w = @bits.seed_words(seed, 1)[0]
  Philox4x32::with_key(w.to_uint(), (w >> 32).to_uint())
}

///|
/// The 32x32 to 64-bit multiply the round needs, both halves.
fn mulhilo32(a : UInt32, b : UInt32) -> (UInt32, UInt32) {
  let p = a.to_uint64() * b.to_uint64()
  ((p >> 32).to_uint(), (p & 0xFFFFFFFFUL).to_uint())
}

///|
/// Ten rounds of Philox on one counter block, with the key bumped between
/// rounds by the two Weyl constants.
fn philox4x32_block(
  ctr : FixedArray[UInt32],
  key : FixedArray[UInt32],
  out : FixedArray[UInt32],
) -> Unit {
  let c = FixedArray::make(4, 0U)
  for i = 0; i < 4; i = i + 1 {
    c[i] = ctr[i]
  }
  let mut k0 = key[0]
  let mut k1 = key[1]
  for _r = 0; _r < 10; _r = _r + 1 {
    let (hi0, lo0) = mulhilo32(0xD2511F53U, c[0])
    let (hi1, lo1) = mulhilo32(0xCD9E8D57U, c[2])
    let n0 = hi1 ^ c[1] ^ k0
    let n1 = lo1
    let n2 = hi0 ^ c[3] ^ k1
    let n3 = lo0
    c[0] = n0
    c[1] = n1
    c[2] = n2
    c[3] = n3
    k0 = k0 + 0x9E3779B9U
    k1 = k1 + 0xBB67AE85U
  }
  for i = 0; i < 4; i = i + 1 {
    out[i] = c[i]
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
pub fn Philox4x32::advance(self : Philox4x32, n : UInt64) -> Unit {
  let used = self.pos[0] % 4
  let at = self.ctr[0].to_uint64() * 4UL + used.to_uint64() + n * 2UL
  let block = at / 4UL
  let rest = (at % 4UL).to_int()
  self.ctr[0] = block.to_uint()
  self.ctr[1] = (block >> 32).to_uint()
  // A remainder of zero means the next draw starts a fresh block; anything
  // else means the block it lands in has to be generated now, and the counter
  // moves past it.
  if rest == 0 {
    self.pos[0] = 4
  } else {
    philox4x32_block(self.ctr, self.key, self.out)
    self.pos[0] = rest
  }
}

///|
fn philox4x32_word(g : Philox4x32) -> UInt32 {
  if g.pos[0] >= 4 {
    philox4x32_block(g.ctr, g.key, g.out)
    g.pos[0] = 0
  }
  let v = g.out[g.pos[0]]
  g.pos[0] = g.pos[0] + 1
  v
}

///|
pub impl @contract.Rng for Philox4x32 with fn next_u32(self) -> UInt32 {
  philox4x32_word(self)
}

///|
pub impl @contract.Rng for Philox4x32 with fn next_u64(self) -> UInt64 {
  (philox4x32_word(self).to_uint64() << 32) | philox4x32_word(self).to_uint64()
}

///|
pub impl @contract.Seeded for Philox4x32 with fn from_seed(seed : BytesView) -> Philox4x32 {
  Philox4x32::new(seed)
}

///|
pub impl @contract.Seeded for Philox4x32 with fn seed_size() -> Int32 {
  8
}

///|
/// Philox4x64: the same round over 64-bit words, with the 128-bit multiplier
/// split into its two halves.
pub struct Philox4x64 {
  priv ctr : FixedArray[UInt64]
  priv key : FixedArray[UInt64]
  priv out : FixedArray[UInt64]
  priv pos : FixedArray[Int32]
}

///|
/// A generator with the key `k0`, `k1` and a zero counter.
pub fn Philox4x64::with_key(k0 : UInt64, k1 : UInt64) -> Philox4x64 {
  {
    ctr: FixedArray::make(4, 0UL),
    key: [k0, k1],
    out: FixedArray::make(4, 0UL),
    pos: [4],
  }
}

///|
/// A generator keyed from sixteen bytes.
pub fn Philox4x64::new(seed : BytesView) -> Philox4x64 {
  let w = @bits.seed_words(seed, 2)
  Philox4x64::with_key(w[0], w[1])
}

///|
fn philox4x64_block(
  ctr : FixedArray[UInt64],
  key : FixedArray[UInt64],
  out : FixedArray[UInt64],
) -> Unit {
  let c = FixedArray::make(4, 0UL)
  for i = 0; i < 4; i = i + 1 {
    c[i] = ctr[i]
  }
  let mut k0 = key[0]
  let mut k1 = key[1]
  for _r = 0; _r < 10; _r = _r + 1 {
    let lo0 = 0xD2E7470EE14C6C93UL * c[0]
    let hi0 = @bits.mul_hi(0xD2E7470EE14C6C93UL, c[0])
    let lo1 = 0xCA5A826395121157UL * c[2]
    let hi1 = @bits.mul_hi(0xCA5A826395121157UL, c[2])
    let n0 = hi1 ^ c[1] ^ k0
    let n1 = lo1
    let n2 = hi0 ^ c[3] ^ k1
    let n3 = lo0
    c[0] = n0
    c[1] = n1
    c[2] = n2
    c[3] = n3
    k0 = k0 + 0x9E3779B97F4A7C15UL
    k1 = k1 + 0xBB67AE8584CAA73BUL
  }
  for i = 0; i < 4; i = i + 1 {
    out[i] = c[i]
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
pub fn Philox4x64::advance(self : Philox4x64, n : UInt64) -> Unit {
  let used = self.pos[0] % 4
  let at = self.ctr[0] * 4UL + used.to_uint64() + n
  let block = at / 4UL
  let rest = (at % 4UL).to_int()
  self.ctr[0] = block
  if rest == 0 {
    self.pos[0] = 4
  } else {
    philox4x64_block(self.ctr, self.key, self.out)
    self.pos[0] = rest
  }
}

///|
fn philox4x64_word(g : Philox4x64) -> UInt64 {
  if g.pos[0] >= 4 {
    philox4x64_block(g.ctr, g.key, g.out)
    g.pos[0] = 0
  }
  let v = g.out[g.pos[0]]
  g.pos[0] = g.pos[0] + 1
  v
}

///|
pub impl @contract.Rng for Philox4x64 with fn next_u64(self) -> UInt64 {
  philox4x64_word(self)
}

///|
pub impl @contract.Seeded for Philox4x64 with fn from_seed(seed : BytesView) -> Philox4x64 {
  Philox4x64::new(seed)
}

///|
pub impl @contract.Seeded for Philox4x64 with fn seed_size() -> Int32 {
  16
}

///|
pub extend Philox4x32 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Philox4x32 with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Philox4x64 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Philox4x64 with @contract.Seeded::{from_seed, seed_size}
