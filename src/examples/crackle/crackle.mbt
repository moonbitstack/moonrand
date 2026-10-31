///|
/// The page's only door into the library. It exists so a browser can ask
/// ChaCha12 for numbers without re-implementing it: `open` takes the entropy
/// the page collected, `unit` returns the next value in [0, 1).
///
/// The generator sits in a one-slot array because the page calls one function
/// at a time. `ChaCha12` advances through interior mutability, so handing a
/// copy into `random` still moves the stream forward.
let cell : Array[@moonrand.StdRng] = []

///|
fn put_u64(seed : FixedArray[Byte], at : Int32, v : UInt64) -> Unit {
  for i in 0..<8 {
    let shift = (7 - i) * 8
    seed[at + i] = ((v >> shift) & 0xFF).to_int().to_byte()
  }
}

///|
/// Reseed the page's stream. `hi` and `lo` are whatever the page could see
/// that nobody else can repeat: the clock at load, the screen, the pointer,
/// a fresh draw from the platform. Mixing happens on the page side; this side
/// only insists on 32 bytes of seed.
pub fn open(hi : UInt64, lo : UInt64) -> Unit {
  let seed = FixedArray::make(32, (0).to_byte())
  put_u64(seed, 0, hi)
  put_u64(seed, 8, lo)
  put_u64(seed, 16, hi ^ lo)
  put_u64(seed, 24, hi ^ (lo >> 1))
  let bytes = Bytes::from_array(seed)
  cell.push(@moonrand.seeded(bytes[0:]))
}

///|
/// The next number in [0, 1). The page calls this in a loop: one crack network
/// is a few hundred of these.
pub fn unit() -> Double {
  if cell.length() == 0 {
    0.5
  } else {
    @moonrand.random(cell[cell.length() - 1])
  }
}

///|
fn main {
  ignore(unit)
}
