///|
test "middle_square_runs_the_reference_stream" {
  let g = @classic.MiddleSquare::with_state(middle_square_seed[0])
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u32().to_uint64())
  }
  assert_eq(out, middle_square_first)
}

///|
test "middle_product_runs_the_reference_stream" {
  let g = @classic.MiddleProduct::with_params(
    0x9E3779B97F4A7C15UL,
    middle_square_seed[0],
  )
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u32().to_uint64())
  }
  assert_eq(out, middle_product_first)
}

///|
test "middle_square_weyl_runs_the_reference_stream" {
  let g = @classic.MiddleSquareWeyl::with_state(middle_square_seed[0])
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u64())
  }
  assert_eq(out, middle_square_weyl_first)
}

///|
test "collatz_weyl_runs_the_reference_stream" {
  let g = @classic.CollatzWeyl::with_state(middle_square_seed[0])
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u64())
  }
  assert_eq(out, collatz_weyl_first)
}

///|
test "blum_blum_shub_runs_the_reference_stream" {
  let g = @classic.Bbs::with_params(192649UL, 12345UL)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u32().to_uint64())
  }
  assert_eq(out, bbs_first)
  assert_eq(@classic.Bbs::seed_size(), 8)
}
