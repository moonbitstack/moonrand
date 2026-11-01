///|
/// Arithmetic wider than a machine word, and the one way a byte seed becomes
/// state words. Both are shared: 128-bit generators need the high half of a
/// 64-bit product, and every generator needs the same expansion so the same
/// seed means the same stream in every subpackage.

///|
/// The SplitMix64 finalizer: three xorshifts and two odd multipliers, a
/// bijection on 64-bit words.
pub fn mix64(z : UInt64) -> UInt64 {
  let a = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9UL
  let b = (a ^ (a >> 27)) * 0x94D049BB133111EBUL
  b ^ (b >> 31)
}

///|
/// The high 64 bits of `a * b`, without a 128-bit type: split both into 32-bit
/// halves and carry the middle terms.
pub fn mul_hi(a : UInt64, b : UInt64) -> UInt64 {
  let a_lo = a & 0xFFFFFFFFUL
  let a_hi = a >> 32
  let b_lo = b & 0xFFFFFFFFUL
  let b_hi = b >> 32
  let p0 = a_lo * b_lo
  let p1 = a_lo * b_hi
  let p2 = a_hi * b_lo
  let p3 = a_hi * b_hi
  let mid = (p0 >> 32) + (p1 & 0xFFFFFFFFUL) + (p2 & 0xFFFFFFFFUL)
  p3 + (p1 >> 32) + (p2 >> 32) + (mid >> 32)
}

///|
/// Both halves of `a * b`, the low one first.
pub fn mul_wide(a : UInt64, b : UInt64) -> (UInt64, UInt64) {
  (a * b, mul_hi(a, b))
}

///|
/// `n` state words from `seed`. The seed is read eight bytes at a time, little
/// endian, mixed into a SplitMix64 counter, and the counter is run forward —
/// so every byte of the seed counts, and a short seed is the same as itself
/// with zero bytes appended.
pub fn seed_words(seed : BytesView, n : Int32) -> FixedArray[UInt64] {
  let len = seed.length()
  let mut x = 0x9E3779B97F4A7C15UL
  let mut i = 0
  while i < len {
    let mut w = 0UL
    for j = 0; j < 8; j = j + 1 {
      let idx = i + j
      if idx < len {
        w = w | (seed[idx].to_uint64() << (j * 8))
      }
    }
    x = mix64(x ^ w)
    i = i + 8
  }
  let out = FixedArray::make(n, 0UL)
  for j = 0; j < n; j = j + 1 {
    x = x + 0x9E3779B97F4A7C15UL
    out[j] = mix64(x)
  }
  out
}
