///|
test "l64x128_runs_the_reference_stream" {
  let g = @lxm.L64X128::with_state(
    l64x128_state[0],
    l64x128_state[1],
    l64x128_state[2],
  )
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u64())
  }
  assert_eq(out, l64x128_first)
}

///|
test "l64x128_jump_lands_where_the_reference_does" {
  let g = @lxm.L64X128::with_state(
    l64x128_state[0],
    l64x128_state[1],
    l64x128_state[2],
  )
  g.jump()
  let out : Array[UInt64] = []
  for _i = 0; _i < 4; _i = _i + 1 {
    out.push(g.next_u64())
  }
  assert_eq(out, l64x128_jump)
}

///|
test "l64x256_runs_the_reference_stream" {
  let g = @lxm.L64X256::with_state(
    l64x256_state[0],
    l64x256_state[1],
    l64x256_state[2],
    l64x256_state[3],
    l64x256_state[4],
  )
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u64())
  }
  assert_eq(out, l64x256_first)
  // The jump vectors start from the initial state, so a fresh generator.
  let jumped = @lxm.L64X256::with_state(
    l64x256_state[0],
    l64x256_state[1],
    l64x256_state[2],
    l64x256_state[3],
    l64x256_state[4],
  )
  jumped.jump()
  let after : Array[UInt64] = []
  for _i = 0; _i < 4; _i = _i + 1 {
    after.push(jumped.next_u64())
  }
  assert_eq(after, l64x256_jump)
  assert_eq(@lxm.L64X128::seed_size(), 24)
}
