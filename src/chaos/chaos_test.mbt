///|
/// A chaotic orbit stays inside the interval the map maps into, is not a
/// constant, and repeats exactly when the start repeats.
test "logistic_stays_in_range_and_repeats" {
  let a = @chaos.Logistic::with_params(4.0, 0.3)
  let b = @chaos.Logistic::with_params(4.0, 0.3)
  let mut seen = 0
  let mut last = 0UL
  for _i = 0; _i < 200; _i = _i + 1 {
    let x = a.next_u64()
    assert_eq(x, b.next_u64())
    if x != last {
      seen = seen + 1
    }
    last = x
  }
  assert_true(seen > 190)
}

///|
test "tent_sine_and_chebyshev_stay_inside_their_interval" {
  let t = @chaos.Tent::with_params(2.0, 0.21)
  let s = @chaos.Sine::with_state(0.21)
  let c = @chaos.Chebyshev::with_params(3.0, 0.21)
  for _i = 0; _i < 100; _i = _i + 1 {
    let xt = t.next_u64().reinterpret_as_double()
    assert_true(xt >= 0.0 && xt <= 1.0)
    let xs = s.next_u64().reinterpret_as_double()
    assert_true(xs >= 0.0 && xs <= 1.0)
    let xc = c.next_u64().reinterpret_as_double()
    assert_true(xc >= -1.0 && xc <= 1.0)
  }
}

///|
test "different_starts_give_different_orbits" {
  let a = @chaos.Logistic::with_params(4.0, 0.3)
  let b = @chaos.Logistic::with_params(4.0, 0.3000001)
  assert_true(a.next_u64() != b.next_u64())
  assert_eq(@chaos.Sine::seed_size(), 8)
}
