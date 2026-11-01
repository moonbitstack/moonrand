///|
/// The published output of `init_genrand(5489)`: the first words of the
/// reference `mt19937ar.out`.
test "mt19937_init_genrand_matches_the_reference_output" {
  let g = @mt.MT19937::with_word(5489U)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u32().to_uint64())
  }
  assert_eq(out, mt19937_init5489)
}

///|
test "mt19937_init_by_array_matches_the_reference_output" {
  let g = @mt.MT19937::from_array([0x123U, 0x234U, 0x345U, 0x456U])
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u32().to_uint64())
  }
  assert_eq(out, mt19937_by_array)
}

///|
test "mt19937_64_init_genrand_matches_the_reference_output" {
  let g = @mt.MT19937_64::with_word(5489UL)
  let out : Array[UInt64] = []
  for _i = 0; _i < 6; _i = _i + 1 {
    out.push(g.next_u64())
  }
  assert_eq(out, mt19937_64_init5489)
}

///|
test "mt19937_64_init_by_array_matches_the_reference_output" {
  let g = @mt.MT19937_64::from_array([0x123UL, 0x234UL, 0x345UL, 0x456UL])
  let out : Array[UInt64] = []
  for _i = 0; _i < 6; _i = _i + 1 {
    out.push(g.next_u64())
  }
  assert_eq(out, mt19937_64_by_array)
}

///|
/// The 64-bit draw of a 32-bit generator is two words of the same stream, the
/// first one high: nothing is drawn twice and nothing is dropped.
test "mt19937_next_u64_is_two_words_of_the_stream" {
  let packed = @mt.MT19937::with_word(5489U)
  let apart = @mt.MT19937::with_word(5489U)
  let word = packed.next_u64()
  let hi = apart.next_u32().to_uint64()
  let lo = apart.next_u32().to_uint64()
  assert_eq(word, (hi << 32) | lo)
}

///|
test "mt_seeding_is_reproducible_and_the_twist_fires" {
  let a = @mt.MT19937::new(b"moonrand")
  let b = @mt.MT19937::new(b"moonrand")
  for _i = 0; _i < 700; _i = _i + 1 {
    assert_eq(a.next_u32(), b.next_u32())
  }
  assert_eq(@mt.MT19937_64::seed_size(), 8)
}
