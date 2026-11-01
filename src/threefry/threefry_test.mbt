///|
test "threefry4x64_matches_the_reference_vector" {
  let g = @threefry.Threefry4x64::with_key(0UL, 0UL)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u64())
  }
  assert_eq(out, threefry4x64_zero)
}

///|
test "threefry2x64_matches_the_reference_vector" {
  let g = @threefry.Threefry2x64::with_key(0UL, 0UL)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u64())
  }
  assert_eq(out, threefry2x64_zero)
}

///|
test "threefry4x32_matches_the_reference_vector" {
  let g = @threefry.Threefry4x32::with_key(0U, 0U)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u32().to_uint64())
  }
  assert_eq(out, threefry4x32_zero)
}

///|
test "threefry_advance_seeks_the_counter" {
  for skip in [0UL, 1UL, 2UL, 3UL, 7UL] {
    let walked = @threefry.Threefry4x64::with_key(7UL, 9UL)
    for _i = 0UL; _i < skip; _i = _i + 1UL {
      ignore(walked.next_u64())
    }
    let sought = @threefry.Threefry4x64::with_key(7UL, 9UL)
    sought.advance(skip)
    assert_eq(sought.next_u64(), walked.next_u64())
  }
  assert_eq(@threefry.Threefry4x64::seed_size(), 16)
}
