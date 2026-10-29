///|
/// `n` uniform random bytes: Go's `rand.Read`, Python's `secrets.token_bytes`.
/// Aborts on a negative `n`.
pub fn[S : Source] bytes(n : Int32, source : S) -> Bytes raise Unavailable {
  if n < 0 {
    abort("moonrand.bytes: a negative length, \{n}")
  }
  let buf = FixedArray::make(n, b'\x00')
  source.fill(buf)
  Bytes::from_array(buf[:])
}

///|
/// A uniform number in [0, `bound`), both big-endian and as wide as `bound`:
/// Go's `rand.Int`, Python's `secrets.randbelow`. The draw keeps only as many
/// bits as `bound` has and is retried when it lands at or above it, so no
/// value is likelier than another; a reduction modulo `bound` would be biased.
/// Aborts when `bound` is zero.
pub fn[S : Source] below(
  bound : BytesView,
  source : S,
) -> Bytes raise Unavailable {
  let width = bound.length()
  let mut lead = 0
  while lead < width && bound[lead] == b'\x00' {
    lead += 1
  }
  if lead == width {
    abort("moonrand.below: the bound is zero")
  }
  let top = bound[lead].to_int()
  let mut mask = 0xFF
  while mask >> 1 >= top {
    mask = mask >> 1
  }
  let k = width - lead
  let draw = FixedArray::make(k, b'\x00')
  while true {
    source.fill(draw)
    draw[0] = (draw[0].to_int() & mask).to_byte()
    if less(draw, bound[lead:]) {
      break
    }
  }
  let out = FixedArray::make(width, b'\x00')
  for i in 0..<k {
    out[lead + i] = draw[i]
  }
  Bytes::from_array(out[:])
}

///|
/// A uniform number in [1, `order` - 1], as wide as `order`: the private key or
/// nonce of a curve whose group has that order. A zero from `below` is drawn
/// again, which keeps the rest uniform. Aborts when `order` is below 2.
pub fn[S : Source] scalar(
  order : BytesView,
  source : S,
) -> Bytes raise Unavailable {
  if !above_one(order) {
    abort("moonrand.scalar: the order is below 2")
  }
  while true {
    let d = below(order, source)
    if !zero(d) {
      return d
    }
  }
  panic()
}

///|
/// Whether `a` is less than `b`, both big-endian and of one length.
fn less(a : FixedArray[Byte], b : BytesView) -> Bool {
  for i in 0..<a.length() {
    if a[i] != b[i] {
      return a[i] < b[i]
    }
  }
  false
}

///|
fn zero(b : Bytes) -> Bool {
  b.iter().all(x => x == b'\x00')
}

///|
fn above_one(b : BytesView) -> Bool {
  for i in 0..<b.length() {
    if i < b.length() - 1 && b[i] != b'\x00' {
      return true
    }
  }
  b.length() > 0 && b[b.length() - 1] >= b'\x02'
}
