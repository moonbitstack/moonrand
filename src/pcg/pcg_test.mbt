///|
/// The words the reference demo prints for seed 42 and stream 54.
test "pcg32_matches_the_published_demo_output" {
  let g = @pcg.Pcg32::with_stream(42UL, 54UL)
  let out : Array[UInt64] = []
  for _i = 0; _i < 6; _i = _i + 1 {
    out.push(g.next_u32().to_uint64())
  }
  assert_eq(out, pcg32_demo_seed42_stream54)
}

///|
test "pcg32_runs_the_reference_stream_from_a_raw_state" {
  let g = @pcg.Pcg32::with_state(42UL, 54UL)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u32().to_uint64())
  }
  assert_eq(out, pcg32_stream54)
}

///|
test "pcg64_xslrr_runs_the_reference_stream" {
  let g = @pcg.Pcg64::with_state(42UL, 0UL, 54UL, 0UL)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u64())
  }
  assert_eq(out, pcg64_state42)
}

///|
test "pcg64_dxsm_runs_the_reference_stream" {
  let g = @pcg.Pcg64Dxsm::with_state(42UL, 0UL, 54UL, 0UL)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u64())
  }
  assert_eq(out, pcg64dxsm_state42)
}

///|
/// `advance` steps the LCG without drawing: skipping n draws must land where n
/// draws would have, for both the 64-bit and the 128-bit state.
test "advance_seeks_the_same_place_as_drawing" {
  for skip in [0UL, 1UL, 2UL, 5UL, 1000UL] {
    let walked = @pcg.Pcg32::with_stream(7UL, 9UL)
    for _i = 0UL; _i < skip; _i = _i + 1UL {
      ignore(walked.next_u32())
    }
    let sought = @pcg.Pcg32::with_stream(7UL, 9UL)
    sought.advance(skip)
    assert_eq(sought.next_u32(), walked.next_u32())
  }
  for skip in [0UL, 1UL, 3UL, 1000UL] {
    let walked = @pcg.Pcg64::with_state(7UL, 3UL, 9UL, 5UL)
    for _i = 0UL; _i < skip; _i = _i + 1UL {
      ignore(walked.next_u64())
    }
    let sought = @pcg.Pcg64::with_state(7UL, 3UL, 9UL, 5UL)
    sought.advance(skip)
    assert_eq(sought.next_u64(), walked.next_u64())
  }
}

///|
test "pcg_seeding_is_reproducible" {
  let a = @pcg.Pcg64Dxsm::new(b"moonrand")
  let b = @pcg.Pcg64Dxsm::new(b"moonrand")
  assert_eq(a.next_u64(), b.next_u64())
  assert_eq(@pcg.Pcg32::seed_size(), 16)
  assert_eq(@pcg.Pcg64::seed_size(), 32)
}
