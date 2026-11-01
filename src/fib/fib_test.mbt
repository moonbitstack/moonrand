///|
test "additive_congruential_runs_the_reference_stream" {
  let st = FixedArray::make(55, 0U)
  for i = 0; i < 55; i = i + 1 {
    st[i] = additive_state[i].to_uint()
  }
  let g = @fib.AdditiveCongruential::from_state(st)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u32().to_uint64())
  }
  assert_eq(out, additive_first)
}

///|
test "add_with_carry_runs_the_reference_stream" {
  let st = FixedArray::make(55, 0U)
  for i = 0; i < 55; i = i + 1 {
    st[i] = additive_state[i].to_uint()
  }
  let g = @fib.AddWithCarry::from_state(st)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u32().to_uint64())
  }
  assert_eq(out, add_with_carry_first)
}

///|
test "subtract_with_borrow_runs_the_reference_stream" {
  let st = FixedArray::make(55, 0U)
  for i = 0; i < 55; i = i + 1 {
    st[i] = additive_state[i].to_uint()
  }
  let g = @fib.SubtractWithBorrow::from_state(st)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u32().to_uint64())
  }
  assert_eq(out, subtract_with_borrow_first)
}

///|
/// The long lags and the ranlux discards are expensive, so this test asks only
/// that they move, stay in range, and repeat from the same seed.
test "long_lags_and_ranlux_move_and_repeat" {
  let a = @fib.LaggedFibonacci::new(b"moonrand")
  let b = @fib.LaggedFibonacci::new(b"moonrand")
  let mut seen = 0
  let mut last = 0U
  for _i = 0; _i < 20; _i = _i + 1 {
    let v = a.next_u32()
    assert_eq(v, b.next_u32())
    if v != last {
      seen = seen + 1
    }
    last = v
  }
  assert_true(seen > 15)
  let r = @fib.Ranlux24::new(b"moonrand")
  for _i = 0; _i < 10; _i = _i + 1 {
    assert_true(r.next_u32() < 16777216U)
  }
  let s = @fib.Ranlux48::new(b"moonrand")
  assert_true(s.next_u64() < 281474976710656UL)
  assert_eq(@fib.LaggedFibonacci::seed_size(), 2428)
}
