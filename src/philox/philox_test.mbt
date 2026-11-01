///|
/// The published known-answer vector: counter and key both zero.
test "philox4x32_matches_the_reference_vector" {
  let g = @philox.Philox4x32::with_key(0U, 0U)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u32().to_uint64())
  }
  assert_eq(out, philox4x32_zero)
}

///|
test "philox4x64_matches_the_reference_vector" {
  let g = @philox.Philox4x64::with_key(0UL, 0UL)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u64())
  }
  assert_eq(out, philox4x64_zero)
}

///|
/// The counter is the state: seeking n words must land where n draws land.
test "philox_advance_seeks_the_counter" {
  for skip in [0UL, 1UL, 2UL, 3UL, 5UL, 100UL] {
    let walked = @philox.Philox4x32::with_key(7U, 9U)
    for _i = 0UL; _i < skip; _i = _i + 1UL {
      ignore(walked.next_u64())
    }
    let sought = @philox.Philox4x32::with_key(7U, 9U)
    sought.advance(skip)
    assert_eq(sought.next_u64(), walked.next_u64())
  }
  assert_eq(@philox.Philox4x32::seed_size(), 8)
}
