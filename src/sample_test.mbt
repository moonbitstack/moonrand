///|
test "bytes takes exactly n from the source" {
  let source = @moonrand.Replay::new(b"\x01\x02\x03\x04")
  assert_eq(@moonrand.bytes(3, source), b"\x01\x02\x03")
  assert_eq(source.remaining(), 1)
  assert_eq(@moonrand.bytes(0, source), b"")
  let refused = try {
    ignore(@moonrand.bytes(2, source))
    None
  } catch {
    e => Some(e)
  }
  assert_eq(refused, Some(@moonrand.Unavailable::Exhausted))
}

///|
test "below keeps the bound's width and leading zeros" {
  let got = @moonrand.below(b"\x00\x05", @moonrand.Replay::new(b"\x04"))
  assert_eq(got, b"\x00\x04")
}

///|
test "below masks to the bound's bit length before comparing" {
  // 256 has one bit in its top byte, so 0xff 0xff is masked to 0x01 0xff,
  // which is still too big; 0x00 0x10 is taken.
  let source = @moonrand.Replay::new(b"\xff\xff\x00\x10")
  assert_eq(@moonrand.below(b"\x01\x00", source), b"\x00\x10")
  assert_eq(source.remaining(), 0)
}

///|
test "below draws again on a value equal to the bound" {
  let source = @moonrand.Replay::new(b"\x80\x00\x7f\xff")
  assert_eq(@moonrand.below(b"\x80\x00", source), b"\x7f\xff")
}

///|
test "below takes every value in range from the same number of draws" {
  // Over all 256 one-byte draws, each value below 3 is accepted from exactly
  // 64 of them and 3 is never returned: no value is likelier than another.
  let counts = [0, 0, 0, 0]
  let mut refused = 0
  for d in 0..<256 {
    let source = @moonrand.Replay::new(Bytes::from_array([d.to_byte()]))
    try @moonrand.below(b"\x03", source) catch {
      _ => refused += 1
    } noraise {
      v => counts[v[0].to_int()] += 1
    }
  }
  assert_eq(counts, [64, 64, 64, 0])
  assert_eq(refused, 64)
}

///|
test "scalar draws again on zero and on values at or above the order" {
  let source = @moonrand.Replay::new(b"\x00\x06\x04")
  assert_eq(@moonrand.scalar(b"\x05", source), b"\x04")
  assert_eq(source.remaining(), 0)
}

///|
test "scalar is as wide as the order" {
  let order = b"\x01\xff\xff"
  let got = @moonrand.scalar(
    order,
    @moonrand.Replay::new(b"\x00\x00\x00\x00\x12\x34"),
  )
  assert_eq(got, b"\x00\x12\x34")
}

///|
test "a source of the program's own plugs in" {
  let failing = Broken::{ }
  let refused = try {
    ignore(@moonrand.bytes(4, failing))
    ""
  } catch {
    e => e.to_string()
  }
  assert_eq(refused, "the device is unplugged")
}

///|
priv struct Broken {}

///|
impl @moonrand.Source for Broken with fn fill(_self, _buf) {
  raise Failed("the device is unplugged")
}

///|
test "messages" {
  assert_eq(
    @moonrand.Unavailable::Platform.to_string(),
    "the platform has no entropy source",
  )
  assert_eq(
    @moonrand.Unavailable::Exhausted.to_string(),
    "the replay source is exhausted",
  )
}

///|
test "panic bytes refuses a negative length" {
  ignore(@moonrand.bytes(-1, @moonrand.Replay::new(b"")))
}

///|
test "panic below refuses a zero bound" {
  ignore(@moonrand.below(b"\x00\x00", @moonrand.Replay::new(b"\x00")))
}

///|
test "panic scalar refuses an order below 2" {
  ignore(@moonrand.scalar(b"\x00\x01", @moonrand.Replay::new(b"\x00")))
}
