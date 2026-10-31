///|
/// The contract every generator satisfies: produce uniform machine words. The
/// algorithms in subpackages implement the one required method `next_u64`; the
/// other two are shared defaults. The sampling and distribution functions in
/// `moonrand` are generic over any `Rng`.
///
/// Methods take `Self` by value and keep their state in interior-mutable
/// fields (`Array` buffers and `priv mut` scalars), so a draw advances the
/// caller's generator without a mutable reference.
pub(open) trait Rng {
  /// The next 64-bit word, uniformly over `[0, 2^64)`. Every algorithm
  /// implements this one method; `next_u32` and `fill` are shared defaults.
  fn next_u64(Self) -> UInt64
  /// The next 32-bit word. The default takes the top half of a 64-bit draw.
  fn next_u32(Self) -> UInt32 = _
  /// Fill `buf` with uniform bytes. The default draws 8 at a time.
  fn fill(Self, buf : FixedArray[Byte]) -> Unit = _
}

///|
impl Rng with fn next_u32(self) -> UInt32 {
  ((self.next_u64() >> 32) & 0xFFFFFFFF).to_uint()
}

///|
impl Rng with fn fill(self, buf : FixedArray[Byte]) -> Unit {
  let n = buf.length()
  let mut i = 0
  while i < n {
    let w = self.next_u64()
    for j = 0; j < 8 && i + j < n; j = j + 1 {
      buf[i + j] = ((w >> (j * 8)) & 0xFF).to_byte()
    }
    i = i + 8
  }
}

///|
/// A generator fit for cryptography: ChaCha and the like. Philox and PCG pass
/// statistical tests but are not, so they do not carry this marker.
pub(open) trait Secure: Rng {}

///|
/// A generator rebuilt from a seed, for reproducible runs.
pub(open) trait Seeded: Rng {
  /// Rebuild the generator from a `seed_size`-byte seed.
  fn from_seed(BytesView) -> Self
  /// How many seed bytes `from_seed` expects.
  fn seed_size() -> Int32
}
