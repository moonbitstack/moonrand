///|
/// What `rand_chacha` draws from the same key, nonce and counter, written by
/// `scripts/gen_chacha_vectors`. The RFC 8439 vectors in `chacha_test.mbt` pin
/// twenty rounds; the RFC says nothing about eight or twelve, and twelve is
/// this library's default, so these numbers come from the Rust crate that
/// implements the same cipher at every round count.
///
/// The key is the first thirty-two bytes, little-endian, which is how both
/// sides read a seed.

///|
let chacha8_first : Array[UInt64] = [
  0x6AAB126E8FB21540UL, 0x3312C5317B66E8D9UL, 0x4FD9B29027178FF7UL, 0xCBBEBCFFD72E6B32UL,
  0x3BCE895F36AD9EFFUL, 0xFD909D75BC55406FUL, 0x93DFB0C7271D838FUL, 0xD656A23882EDB9B3UL,
]

///|
let chacha12_first : Array[UInt64] = [
  0x5EC67AD1FFF931F2UL, 0xAA40E9D725F30544UL, 0xBC46BEC21F601349UL, 0x361A1AD9C3CAC3E9UL,
  0x9F7C85C208B34059UL, 0x9AD4288554E2D629UL, 0x165D76E60A1B2B61UL, 0x79883646FBAE85E5UL,
]

///|
let chacha20_first : Array[UInt64] = [
  0x6A19C5D97D2BFD39UL, 0x494ADCB87703BD8DUL, 0xCC6ADEBC6FD8358AUL, 0x9224EAD84C7DCCB2UL,
  0xAB2360A2E7CC232BUL, 0x647FC83A69EF0E3FUL, 0x2DA3F7B1EA358225UL, 0x0C415B48A06227C2UL,
]

///|
let chacha8_at_word_1600 : Array[UInt64] = [
  0x0352A86F8A385903UL, 0x89D3BC0635604114UL, 0x406DD050EEC9FB7DUL, 0xE1213F1973D5053CUL,
]

///|
let chacha12_at_word_1600 : Array[UInt64] = [
  0x03A80E45C634361AUL, 0xE4866C497D6652ABUL, 0x7231C6C95DBE3716UL, 0x4181D8D3716AE844UL,
]

///|
let chacha12_with_stream : Array[UInt64] = [
  0xC4D8167263D02309UL, 0x023007B3C1CE9A08UL, 0x53154AC70DBEAB87UL, 0x5CEE1EEE25A81419UL,
]

///|
/// `n` words, in order.
fn[R : @contract.Rng] words(r : R, n : Int32) -> Array[UInt64] {
  let out : Array[UInt64] = []
  for _i = 0; _i < n; _i = _i + 1 {
    out.push(r.next_u64())
  }
  out
}

///|
test "chacha8_runs_the_reference_stream" {
  let r = @chacha.ChaCha8::new(ascending_seed())
  assert_eq(words(r, 8), chacha8_first)
}

///|
test "chacha12_runs_the_reference_stream" {
  let r = @chacha.ChaCha12::new(ascending_seed())
  assert_eq(words(r, 8), chacha12_first)
}

///|
test "chacha20_runs_the_reference_stream" {
  let r = @chacha.ChaCha20::new(ascending_seed())
  assert_eq(words(r, 8), chacha20_first)
}

///|
/// A hundred blocks in: the counter is a word position, and `advance` counts
/// 64-bit draws, so word 1600 is 800 of them.
test "chacha_advance_lands_on_the_reference_word" {
  let eight = @chacha.ChaCha8::new(ascending_seed())
  eight.advance(800UL)
  assert_eq(words(eight, 4), chacha8_at_word_1600)
  let twelve = @chacha.ChaCha12::new(ascending_seed())
  twelve.advance(800UL)
  assert_eq(words(twelve, 4), chacha12_at_word_1600)
}

///|
/// A stream is the low half of the nonce followed by the high half, with the
/// first nonce word left at zero.
test "chacha_with_a_stream_matches_the_reference_nonce" {
  let r = @chacha.ChaCha12::with_nonce(
    ascending_seed(),
    0U,
    0x0f0e0d0cU,
    0x03020100U,
    0U,
  )
  assert_eq(words(r, 4), chacha12_with_stream)
}
