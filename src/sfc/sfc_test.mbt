///|
test "sfc64_runs_the_reference_stream" {
  let g = @sfc.Sfc64::with_state(sfc64_state[0], sfc64_state[1], sfc64_state[2])
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u64())
  }
  assert_eq(out, sfc64_first)
}

///|
test "sfc64_seeding_is_reproducible" {
  let a = @sfc.Sfc64::new(b"moonrand")
  let b = @sfc.Sfc64::new(b"moonrand")
  for _i = 0; _i < 4; _i = _i + 1 {
    assert_eq(a.next_u64(), b.next_u64())
  }
  assert_eq(@sfc.Sfc64::seed_size(), 24)
}
