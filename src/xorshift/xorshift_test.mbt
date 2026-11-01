///|
/// Four 32-bit words out of a vector of four words.
fn words32(a : Array[UInt64], at : Int32) -> FixedArray[UInt32] {
  let out = FixedArray::make(4, 0U)
  for i = 0; i < 4; i = i + 1 {
    out[i] = a[at + i].to_uint()
  }
  out
}

///|
test "xorshift32_runs_the_paper_stream" {
  let g = @xorshift.Xorshift32::with_state(2463534242U)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u32().to_uint64())
  }
  assert_eq(out, xorshift32)
}

///|
test "xorshift64_runs_the_paper_stream" {
  let g = @xorshift.Xorshift64::with_state(88172645463325252UL)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u64())
  }
  assert_eq(out, xorshift64)
}

///|
test "xorshift128_runs_the_reference_stream" {
  let g = @xorshift.Xorshift128::from_state(words32(xorshift128_state, 0))
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u32().to_uint64())
  }
  assert_eq(out, xorshift128)
}

///|
test "xorshift128plus_runs_the_reference_stream" {
  let g = @xorshift.Xorshift128Plus::with_state(
    xorshift128plus_state[0],
    xorshift128plus_state[1],
  )
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u64())
  }
  assert_eq(out, xorshift128plus)
}

///|
test "xorwow_runs_the_reference_stream" {
  let state = FixedArray::make(6, 0U)
  for i = 0; i < 6; i = i + 1 {
    state[i] = xorwow_state[i].to_uint()
  }
  let g = @xorshift.Xorwow::from_state(state)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u32().to_uint64())
  }
  assert_eq(out, xorwow)
}

///|
test "xorshift_seeding_is_reproducible" {
  let a = @xorshift.Xorshift128Plus::new(b"moonrand")
  let b = @xorshift.Xorshift128Plus::new(b"moonrand")
  assert_eq(a.next_u64(), b.next_u64())
  assert_eq(@xorshift.Xorshift32::seed_size(), 4)
}
