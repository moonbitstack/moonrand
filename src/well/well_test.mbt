///|
test "well512_runs_the_reference_stream" {
  let state = FixedArray::make(16, 0U)
  for i = 0; i < 16; i = i + 1 {
    state[i] = well512_state[i].to_uint()
  }
  let g = @well.Well512::from_state(state)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u32().to_uint64())
  }
  assert_eq(out, well512_first)
}

///|
test "well512_walks_the_index_and_stays_reproducible" {
  let a = @well.Well512::new(b"moonrand")
  let b = @well.Well512::new(b"moonrand")
  for _i = 0; _i < 40; _i = _i + 1 {
    assert_eq(a.next_u32(), b.next_u32())
  }
  assert_eq(@well.Well512::seed_size(), 64)
}

///|
test "well1024_runs_the_reference_stream" {
  let state = FixedArray::make(32, 0U)
  for i = 0; i < 32; i = i + 1 {
    state[i] = well1024_state[i].to_uint()
  }
  let g = @well.Well1024::from_state(state)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u32().to_uint64())
  }
  assert_eq(out, well1024_first)
  assert_eq(@well.Well1024::seed_size(), 128)
}
