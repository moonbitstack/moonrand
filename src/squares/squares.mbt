///|
/// Squares: a counter-based generator with a 256-bit key and a 256-bit counter.
/// The published family of that name is parametrised by how many words it
/// mixes and how many rounds of squaring it takes; this is the three-word
/// three-round shape, with a cross add between the squarings so that a word
/// depends on its neighbours.
///
/// The construction here is the one this library defines — the counter and the
/// key are the published shape, the round function is written out below — and
/// the tests replay what `scripts/gen_vectors.go` produces from the same
/// definition. It is not claimed to match the author's own constants word for
/// word.
pub struct Squares {
  priv key : FixedArray[UInt64]
  priv ctr : FixedArray[UInt64]
}

///|
/// A generator with the four-word key `k0` to `k3` and a zero counter.
pub fn Squares::with_key(
  k0 : UInt64,
  k1 : UInt64,
  k2 : UInt64,
  k3 : UInt64,
) -> Squares {
  { key: [k0, k1, k2, k3], ctr: FixedArray::make(4, 0UL), }
}

///|
/// A generator from thirty-two bytes through SplitMix64.
pub fn Squares::new(seed : BytesView) -> Squares {
  let w = @bits.seed_words(seed, 4)
  Squares::with_key(w[0], w[1], w[2], w[3])
}

///|
/// Skip `n` 64-bit draws by stepping the counter.
pub fn Squares::advance(self : Squares, n : UInt64) -> Unit {
  let lo = self.ctr[0] + n
  self.ctr[0] = lo
  if lo < n {
    self.ctr[1] = self.ctr[1] + 1UL
    if self.ctr[1] == 0UL {
      self.ctr[2] = self.ctr[2] + 1UL
      if self.ctr[2] == 0UL {
        self.ctr[3] = self.ctr[3] + 1UL
      }
    }
  }
}

///|
/// One word of output: the three squarings with a cross add, then a step of the
/// counter.
fn squares_word(g : Squares) -> UInt64 {
  let x0 = g.ctr[0] + g.key[0]
  let x1 = g.ctr[1] + g.key[1]
  let x2 = g.ctr[2] + g.key[2]
  let x3 = g.ctr[3] + g.key[3]
  let a0 = x0 * x0 + x1
  let a1 = x1 * x1 + x2
  let a2 = x2 * x2 + x3
  let a3 = x3 * x3 + x0
  let b0 = a0 * a0 + a3
  let b1 = a1 * a1 + a0
  let b2 = a2 * a2 + a1
  let b3 = a3 * a3 + a2
  let out = (b0 * b0 + b3) ^ (b1 * b1 + b0) ^ (b2 * b2 + b1) ^ (b3 * b3 + b2)
  let lo = g.ctr[0] + 1UL
  g.ctr[0] = lo
  if lo == 0UL {
    g.ctr[1] = g.ctr[1] + 1UL
    if g.ctr[1] == 0UL {
      g.ctr[2] = g.ctr[2] + 1UL
      if g.ctr[2] == 0UL {
        g.ctr[3] = g.ctr[3] + 1UL
      }
    }
  }
  out
}

///|
pub impl @contract.Rng for Squares with fn next_u64(self) -> UInt64 {
  squares_word(self)
}

///|
pub impl @contract.Seeded for Squares with fn from_seed(seed : BytesView) -> Squares {
  Squares::new(seed)
}

///|
pub impl @contract.Seeded for Squares with fn seed_size() -> Int32 {
  32
}

///|
pub extend Squares with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Squares with @contract.Seeded::{from_seed, seed_size}
