///|
fn hex(b : Bytes) -> String {
  let digits = "0123456789abcdef"
  let out = StringBuilder()
  for x in b {
    out.write_char(digits[x.to_int() >> 4].unsafe_to_char())
    out.write_char(digits[x.to_int() & 15].unsafe_to_char())
  }
  out.to_string()
}

///|
/// The order of the P-256 group, the bound of its private keys and nonces.
let p256_order : Bytes = b"\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\xbc\xe6\xfa\xad\xa7\x17\x9e\x84\xf3\xb9\xca\xc2\xfc\x63\x25\x51"

///|
fn main {
  try {
    println("16 bytes        \{hex(@moonrand.bytes(16, @system.source))}")
    println(
      "below 1000      \{hex(@moonrand.below(b"\x03\xe8", @system.source))}",
    )
    println(
      "P-256 scalar    \{hex(@moonrand.scalar(p256_order, @system.source))}",
    )
    // A replay source gives the same answer every time, and runs out.
    let fixed = @moonrand.Replay::new(b"\xff\x02\x07")
    println("replayed        \{hex(@moonrand.below(b"\x03", fixed))}")
    ignore(@moonrand.bytes(2, fixed))
  } catch {
    e => println("unavailable     \{e}")
  }
}
