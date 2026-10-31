///|
/// ChaCha: a 256-bit-key stream cipher, used here as a generator. The three
/// variants differ only in round count; the 12-round form is the library
/// default. The cipher follows RFC 8439 exactly (32-bit block counter in
/// state word 12, 96-bit nonce in words 13-15); `gen_vectors` checks its
/// keystream against the RFC test vectors.
///
/// State lives in interior-mutable `Array` buffers and a `priv mut` counter, so
/// `next_u64` advances the generator through a by-value `Self`.
pub struct ChaCha8 {
  priv key : Array[UInt32]
  priv nonce0 : UInt32
  priv nonce1 : UInt32
  priv nonce2 : UInt32
  priv mut ctr : UInt32
  priv words : Array[UInt32]
  priv mut pos : Int32
}

///|
pub struct ChaCha12 {
  priv key : Array[UInt32]
  priv nonce0 : UInt32
  priv nonce1 : UInt32
  priv nonce2 : UInt32
  priv mut ctr : UInt32
  priv words : Array[UInt32]
  priv mut pos : Int32
}

///|
pub struct ChaCha20 {
  priv key : Array[UInt32]
  priv nonce0 : UInt32
  priv nonce1 : UInt32
  priv nonce2 : UInt32
  priv mut ctr : UInt32
  priv words : Array[UInt32]
  priv mut pos : Int32
}

///|
fn rotl(x : UInt32, n : Int32) -> UInt32 {
  (x << n) | (x >> (32 - n))
}

///|
/// One ChaCha quarter round, in place on the state words.
fn quarter(
  s : Array[UInt32],
  a : Int32,
  b : Int32,
  c : Int32,
  d : Int32,
) -> Unit {
  s[a] = s[a] + s[b]
  s[d] = s[d] ^ s[a]
  s[d] = rotl(s[d], 16)
  s[c] = s[c] + s[d]
  s[b] = s[b] ^ s[c]
  s[b] = rotl(s[b], 12)
  s[a] = s[a] + s[b]
  s[d] = s[d] ^ s[a]
  s[d] = rotl(s[d], 8)
  s[c] = s[c] + s[d]
  s[b] = s[b] ^ s[c]
  s[b] = rotl(s[b], 7)
}

///|
/// Expand the key, nonce and counter into a fresh keystream block and write it
/// into `words`. Returns the advanced 32-bit counter.
fn generate_block_into(
  key : Array[UInt32],
  nonce0 : UInt32,
  nonce1 : UInt32,
  nonce2 : UInt32,
  ctr : UInt32,
  words : Array[UInt32],
  rounds : Int32,
) -> UInt32 {
  let s = Array::make(16, 0U)
  s[0] = 0x61707865U
  s[1] = 0x3320646eU
  s[2] = 0x79622d32U
  s[3] = 0x6b206574U
  for i = 0; i < 8; i = i + 1 {
    s[4 + i] = key[i]
  }
  s[12] = ctr
  s[13] = nonce0
  s[14] = nonce1
  s[15] = nonce2
  let v = Array::make(16, 0U)
  for i = 0; i < 16; i = i + 1 {
    v[i] = s[i]
  }
  for _r = 0; _r < rounds; _r = _r + 1 {
    if _r % 2 == 0 {
      quarter(s, 0, 4, 8, 12)
      quarter(s, 1, 5, 9, 13)
      quarter(s, 2, 6, 10, 14)
      quarter(s, 3, 7, 11, 15)
    } else {
      quarter(s, 0, 5, 10, 15)
      quarter(s, 1, 6, 11, 12)
      quarter(s, 2, 7, 8, 13)
      quarter(s, 3, 4, 9, 14)
    }
  }
  for i = 0; i < 16; i = i + 1 {
    words[i] = v[i] + s[i]
  }
  ctr + 1U
}

///|
/// Produce the next 64-bit word and return the advanced counter and position.
fn chacha_next_u64(
  key : Array[UInt32],
  nonce0 : UInt32,
  nonce1 : UInt32,
  nonce2 : UInt32,
  ctr : UInt32,
  words : Array[UInt32],
  pos : Int32,
  rounds : Int32,
) -> (UInt64, UInt32, Int32) {
  if pos >= 16 {
    let ctr = generate_block_into(
      key, nonce0, nonce1, nonce2, ctr, words, rounds,
    )
    (words[0].to_uint64() | (words[1].to_uint64() << 32), ctr, 2)
  } else {
    let lo = words[pos]
    let hi = words[pos + 1]
    (lo.to_uint64() | (hi.to_uint64() << 32), ctr, pos + 2)
  }
}

///|
fn key_from_seed(seed : BytesView) -> Array[UInt32] {
  let key = Array::make(8, 0U)
  let n = seed.length()
  for i = 0; i < 8; i = i + 1 {
    let mut w = 0U
    for j = 0; j < 4; j = j + 1 {
      let idx = i * 4 + j
      let b = if idx < n { seed[idx].to_uint() } else { 0U }
      w = w | (b << (j * 8))
    }
    key[i] = w
  }
  key
}

///|
fn new_chacha(seed : BytesView) -> (Array[UInt32], Array[UInt32]) {
  let key = key_from_seed(seed)
  let words = Array::make(16, 0U)
  (key, words)
}

///|
pub fn ChaCha8::with_nonce(
  seed : BytesView,
  nonce0 : UInt32,
  nonce1 : UInt32,
  nonce2 : UInt32,
  ctr : UInt32,
) -> ChaCha8 {
  let (key, words) = new_chacha(seed)
  { key, nonce0, nonce1, nonce2, ctr, words, pos: 16, }
}

///|
pub fn ChaCha8::new(seed : BytesView) -> ChaCha8 {
  ChaCha8::with_nonce(seed, 0U, 0U, 0U, 0U)
}

///|
pub fn ChaCha12::with_nonce(
  seed : BytesView,
  nonce0 : UInt32,
  nonce1 : UInt32,
  nonce2 : UInt32,
  ctr : UInt32,
) -> ChaCha12 {
  let (key, words) = new_chacha(seed)
  { key, nonce0, nonce1, nonce2, ctr, words, pos: 16, }
}

///|
pub fn ChaCha12::new(seed : BytesView) -> ChaCha12 {
  ChaCha12::with_nonce(seed, 0U, 0U, 0U, 0U)
}

///|
pub fn ChaCha20::with_nonce(
  seed : BytesView,
  nonce0 : UInt32,
  nonce1 : UInt32,
  nonce2 : UInt32,
  ctr : UInt32,
) -> ChaCha20 {
  let (key, words) = new_chacha(seed)
  { key, nonce0, nonce1, nonce2, ctr, words, pos: 16, }
}

///|
pub fn ChaCha20::new(seed : BytesView) -> ChaCha20 {
  ChaCha20::with_nonce(seed, 0U, 0U, 0U, 0U)
}

///|
pub impl @contract.Rng for ChaCha8 with fn next_u64(self) -> UInt64 {
  let (v, c, p) = chacha_next_u64(
    self.key,
    self.nonce0,
    self.nonce1,
    self.nonce2,
    self.ctr,
    self.words,
    self.pos,
    8,
  )
  self.ctr = c
  self.pos = p
  v
}

///|
pub impl @contract.Rng for ChaCha12 with fn next_u64(self) -> UInt64 {
  let (v, c, p) = chacha_next_u64(
    self.key,
    self.nonce0,
    self.nonce1,
    self.nonce2,
    self.ctr,
    self.words,
    self.pos,
    12,
  )
  self.ctr = c
  self.pos = p
  v
}

///|
pub impl @contract.Rng for ChaCha20 with fn next_u64(self) -> UInt64 {
  let (v, c, p) = chacha_next_u64(
    self.key,
    self.nonce0,
    self.nonce1,
    self.nonce2,
    self.ctr,
    self.words,
    self.pos,
    20,
  )
  self.ctr = c
  self.pos = p
  v
}

///|
pub extend ChaCha8 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend ChaCha12 with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend ChaCha20 with @contract.Rng::{next_u64, next_u32, fill}
