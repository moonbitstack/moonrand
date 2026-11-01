///|
test "jsf64_runs_the_reference_stream" {
  let g = @jsf.Jsf64::with_state(
    jsf64_state[0],
    jsf64_state[1],
    jsf64_state[2],
    jsf64_state[3],
  )
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u64())
  }
  assert_eq(out, jsf64_first)
}

///|
test "jsf64_seeding_is_reproducible" {
  let a = @jsf.Jsf64::new(b"moonrand")
  let b = @jsf.Jsf64::new(b"moonrand")
  for _i = 0; _i < 4; _i = _i + 1 {
    assert_eq(a.next_u64(), b.next_u64())
  }
  assert_eq(@jsf.Jsf64::seed_size(), 32)
}
