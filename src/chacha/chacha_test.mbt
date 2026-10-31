///|
/// RFC 8439 test vectors for the ChaCha block function. These pin the
/// key-expansion, the 8/12/20-round core, the 32-bit counter at state word 12,
/// the 96-bit nonce at words 13-15, and little-endian serialization.
fn to_hex(buf : FixedArray[Byte]) -> String {
  let d : FixedArray[String] = [
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f",
  ]
  let sb = StringBuilder()
  for i = 0; i < buf.length(); i = i + 1 {
    let b = buf[i].to_uint()
    sb.write_string(d[((b >> 4) & 0xFU).reinterpret_as_int()])
    sb.write_string(d[(b & 0xFU).reinterpret_as_int()])
  }
  sb.to_string()
}

///|
fn ascending_seed() -> BytesView {
  let a = Array::make(32, (0).to_byte())
  for i = 0; i < 32; i = i + 1 {
    a[i] = (i.reinterpret_as_uint() & 0xFFU).to_byte()
  }
  Bytes::from_array(a)[0:]
}

///|
fn zeros_seed() -> BytesView {
  Bytes::from_array(Array::make(32, (0).to_byte()))[0:]
}

///|
fn hex_stream(
  rounds : Int32,
  seed : BytesView,
  nonce0 : UInt32,
  nonce1 : UInt32,
  nonce2 : UInt32,
  ctr : UInt32,
  n : Int32,
) -> String {
  let buf = FixedArray::make(n, (0).to_byte())
  if rounds == 8 {
    let c = @chacha.ChaCha8::with_nonce(seed, nonce0, nonce1, nonce2, ctr)
    c.fill(buf)
  } else if rounds == 12 {
    let c = @chacha.ChaCha12::with_nonce(seed, nonce0, nonce1, nonce2, ctr)
    c.fill(buf)
  } else {
    let c = @chacha.ChaCha20::with_nonce(seed, nonce0, nonce1, nonce2, ctr)
    c.fill(buf)
  }
  to_hex(buf)
}

///|
test "chacha20_rfc8439_2_3_2" {
  // key = 00..1f, nonce = 00000009 0000004a 00000000, counter = 1
  let got = hex_stream(
    20,
    ascending_seed(),
    0x09000000U,
    0x4a000000U,
    0U,
    1U,
    64,
  )
  let want = "10f1e7e4d13b5915500fdd1fa32071c4c7d1f4c733c068030422aa9ac3d46c4ed2826446079faa0914c2d705d98b02a2b5129cd1de164eb9cbd083e8a2503c4e"
  assert_eq(got, want)
}

///|
test "chacha20_rfc8439_2_4_2" {
  // key = 00..1f, nonce = 00000000 0000004a 00000000, counter = 1, 114-byte keystream
  let got = hex_stream(20, ascending_seed(), 0U, 0x4a000000U, 0U, 1U, 114)
  let want = "224f51f3401bd9e12fde276fb8631ded8c131f823d2c06e27e4fcaec9ef3cf788a3b0aa372600a92b57974cded2b9334794cba40c63e34cdea212c4cf07d41b769a6749f3f630f4122cafe28ec4dc47e26d4346d70b98c73f3e9c53ac40c5945398b6eda1a832c89c167eacd901d7e2bf363"
  assert_eq(got, want)
}

///|
test "chacha20_all_zero_keystream" {
  // key = 0, nonce = 0, counter = 0
  let got = hex_stream(20, zeros_seed(), 0U, 0U, 0U, 0U, 64)
  let want = "76b8e0ada0f13d90405d6ae55386bd28bdd219b8a08ded1aa836efcc8b770dc7da41597c5157488d7724e03fb8d84a376a43b8f41518a11cc387b669b2ee6586"
  assert_eq(got, want)
}

///|
test "chacha12_deterministic_and_distinct" {
  let a = hex_stream(12, zeros_seed(), 0U, 0U, 0U, 0U, 64)
  let b = hex_stream(12, zeros_seed(), 0U, 0U, 0U, 0U, 64)
  assert_eq(a, b)
  let c20 = hex_stream(20, zeros_seed(), 0U, 0U, 0U, 0U, 64)
  // Different round counts must produce different keystreams.
  assert_true(a != c20)
}

///|
test "chacha8_deterministic_and_distinct" {
  let a = hex_stream(8, zeros_seed(), 0U, 0U, 0U, 0U, 64)
  let b = hex_stream(8, zeros_seed(), 0U, 0U, 0U, 0U, 64)
  assert_eq(a, b)
  let c20 = hex_stream(20, zeros_seed(), 0U, 0U, 0U, 0U, 64)
  assert_true(a != c20)
}
