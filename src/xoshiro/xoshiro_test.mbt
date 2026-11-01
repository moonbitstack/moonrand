///|
/// The state a `from_state` call takes: the vectors are written as arrays, and
/// the generators take a fixed array so the caller owns it.
fn state_of(a : Array[UInt64]) -> FixedArray[UInt64] {
  let out = FixedArray::make(a.length(), 0UL)
  for i = 0; i < a.length(); i = i + 1 {
    out[i] = a[i]
  }
  out
}

///|
/// `n` words, in order.
fn[R : @contract.Rng] draw(r : R, n : Int32) -> Array[UInt64] {
  let out : Array[UInt64] = []
  for _i = 0; _i < n; _i = _i + 1 {
    out.push(r.next_u64())
  }
  out
}

///|
/// The authors' seeding state, the first words, and where `jump` and
/// `long_jump` land, all from the reference implementation.
test "xoshiro256ss_runs_the_reference_stream" {
  let first = @xoshiro.Xoshiro256ss::from_state(state_of(xoshiro256ss_state))
  assert_eq(draw(first, 8), xoshiro256ss_first)
  let jumped = @xoshiro.Xoshiro256ss::from_state(state_of(xoshiro256ss_state))
  jumped.jump()
  assert_eq(draw(jumped, 4), xoshiro256ss_jump)
  let longed = @xoshiro.Xoshiro256ss::from_state(state_of(xoshiro256ss_state))
  longed.long_jump()
  assert_eq(draw(longed, 4), xoshiro256ss_long_jump)
}

///|
test "xoshiro256ss_seeded_twice_agrees_and_seeded_differently_does_not" {
  let a = @xoshiro.Xoshiro256ss::new(b"moonrand")
  let b = @xoshiro.Xoshiro256ss::new(b"moonrand")
  assert_eq(draw(a, 4), draw(b, 4))
  let c = @xoshiro.Xoshiro256ss::new(b"moonranE")
  assert_true(draw(c, 4) != draw(@xoshiro.Xoshiro256ss::new(b"moonrand"), 4))
}

///|
/// The authors' seeding state, the first words, and where `jump` and
/// `long_jump` land, all from the reference implementation.
test "xoshiro256pp_runs_the_reference_stream" {
  let first = @xoshiro.Xoshiro256pp::from_state(state_of(xoshiro256pp_state))
  assert_eq(draw(first, 8), xoshiro256pp_first)
  let jumped = @xoshiro.Xoshiro256pp::from_state(state_of(xoshiro256pp_state))
  jumped.jump()
  assert_eq(draw(jumped, 4), xoshiro256pp_jump)
  let longed = @xoshiro.Xoshiro256pp::from_state(state_of(xoshiro256pp_state))
  longed.long_jump()
  assert_eq(draw(longed, 4), xoshiro256pp_long_jump)
}

///|
test "xoshiro256pp_seeded_twice_agrees_and_seeded_differently_does_not" {
  let a = @xoshiro.Xoshiro256pp::new(b"moonrand")
  let b = @xoshiro.Xoshiro256pp::new(b"moonrand")
  assert_eq(draw(a, 4), draw(b, 4))
  let c = @xoshiro.Xoshiro256pp::new(b"moonranE")
  assert_true(draw(c, 4) != draw(@xoshiro.Xoshiro256pp::new(b"moonrand"), 4))
}

///|
/// The authors' seeding state, the first words, and where `jump` and
/// `long_jump` land, all from the reference implementation.
test "xoshiro256p_runs_the_reference_stream" {
  let first = @xoshiro.Xoshiro256p::from_state(state_of(xoshiro256p_state))
  assert_eq(draw(first, 8), xoshiro256p_first)
  let jumped = @xoshiro.Xoshiro256p::from_state(state_of(xoshiro256p_state))
  jumped.jump()
  assert_eq(draw(jumped, 4), xoshiro256p_jump)
  let longed = @xoshiro.Xoshiro256p::from_state(state_of(xoshiro256p_state))
  longed.long_jump()
  assert_eq(draw(longed, 4), xoshiro256p_long_jump)
}

///|
test "xoshiro256p_seeded_twice_agrees_and_seeded_differently_does_not" {
  let a = @xoshiro.Xoshiro256p::new(b"moonrand")
  let b = @xoshiro.Xoshiro256p::new(b"moonrand")
  assert_eq(draw(a, 4), draw(b, 4))
  let c = @xoshiro.Xoshiro256p::new(b"moonranE")
  assert_true(draw(c, 4) != draw(@xoshiro.Xoshiro256p::new(b"moonrand"), 4))
}

///|
/// The authors' seeding state, the first words, and where `jump` and
/// `long_jump` land, all from the reference implementation.
test "xoshiro512ss_runs_the_reference_stream" {
  let first = @xoshiro.Xoshiro512ss::from_state(state_of(xoshiro512ss_state))
  assert_eq(draw(first, 8), xoshiro512ss_first)
  let jumped = @xoshiro.Xoshiro512ss::from_state(state_of(xoshiro512ss_state))
  jumped.jump()
  assert_eq(draw(jumped, 4), xoshiro512ss_jump)
  let longed = @xoshiro.Xoshiro512ss::from_state(state_of(xoshiro512ss_state))
  longed.long_jump()
  assert_eq(draw(longed, 4), xoshiro512ss_long_jump)
}

///|
test "xoshiro512ss_seeded_twice_agrees_and_seeded_differently_does_not" {
  let a = @xoshiro.Xoshiro512ss::new(b"moonrand")
  let b = @xoshiro.Xoshiro512ss::new(b"moonrand")
  assert_eq(draw(a, 4), draw(b, 4))
  let c = @xoshiro.Xoshiro512ss::new(b"moonranE")
  assert_true(draw(c, 4) != draw(@xoshiro.Xoshiro512ss::new(b"moonrand"), 4))
}

///|
/// The authors' seeding state, the first words, and where `jump` and
/// `long_jump` land, all from the reference implementation.
test "xoshiro512pp_runs_the_reference_stream" {
  let first = @xoshiro.Xoshiro512pp::from_state(state_of(xoshiro512pp_state))
  assert_eq(draw(first, 8), xoshiro512pp_first)
  let jumped = @xoshiro.Xoshiro512pp::from_state(state_of(xoshiro512pp_state))
  jumped.jump()
  assert_eq(draw(jumped, 4), xoshiro512pp_jump)
  let longed = @xoshiro.Xoshiro512pp::from_state(state_of(xoshiro512pp_state))
  longed.long_jump()
  assert_eq(draw(longed, 4), xoshiro512pp_long_jump)
}

///|
test "xoshiro512pp_seeded_twice_agrees_and_seeded_differently_does_not" {
  let a = @xoshiro.Xoshiro512pp::new(b"moonrand")
  let b = @xoshiro.Xoshiro512pp::new(b"moonrand")
  assert_eq(draw(a, 4), draw(b, 4))
  let c = @xoshiro.Xoshiro512pp::new(b"moonranE")
  assert_true(draw(c, 4) != draw(@xoshiro.Xoshiro512pp::new(b"moonrand"), 4))
}

///|
/// The authors' seeding state, the first words, and where `jump` and
/// `long_jump` land, all from the reference implementation.
test "xoshiro512p_runs_the_reference_stream" {
  let first = @xoshiro.Xoshiro512p::from_state(state_of(xoshiro512p_state))
  assert_eq(draw(first, 8), xoshiro512p_first)
  let jumped = @xoshiro.Xoshiro512p::from_state(state_of(xoshiro512p_state))
  jumped.jump()
  assert_eq(draw(jumped, 4), xoshiro512p_jump)
  let longed = @xoshiro.Xoshiro512p::from_state(state_of(xoshiro512p_state))
  longed.long_jump()
  assert_eq(draw(longed, 4), xoshiro512p_long_jump)
}

///|
test "xoshiro512p_seeded_twice_agrees_and_seeded_differently_does_not" {
  let a = @xoshiro.Xoshiro512p::new(b"moonrand")
  let b = @xoshiro.Xoshiro512p::new(b"moonrand")
  assert_eq(draw(a, 4), draw(b, 4))
  let c = @xoshiro.Xoshiro512p::new(b"moonranE")
  assert_true(draw(c, 4) != draw(@xoshiro.Xoshiro512p::new(b"moonrand"), 4))
}

///|
/// The authors' seeding state, the first words, and where `jump` and
/// `long_jump` land, all from the reference implementation.
test "xoroshiro128p_runs_the_reference_stream" {
  let first = @xoshiro.Xoroshiro128p::from_state(state_of(xoroshiro128p_state))
  assert_eq(draw(first, 8), xoroshiro128p_first)
  let jumped = @xoshiro.Xoroshiro128p::from_state(state_of(xoroshiro128p_state))
  jumped.jump()
  assert_eq(draw(jumped, 4), xoroshiro128p_jump)
  let longed = @xoshiro.Xoroshiro128p::from_state(state_of(xoroshiro128p_state))
  longed.long_jump()
  assert_eq(draw(longed, 4), xoroshiro128p_long_jump)
}

///|
test "xoroshiro128p_seeded_twice_agrees_and_seeded_differently_does_not" {
  let a = @xoshiro.Xoroshiro128p::new(b"moonrand")
  let b = @xoshiro.Xoroshiro128p::new(b"moonrand")
  assert_eq(draw(a, 4), draw(b, 4))
  let c = @xoshiro.Xoroshiro128p::new(b"moonranE")
  assert_true(draw(c, 4) != draw(@xoshiro.Xoroshiro128p::new(b"moonrand"), 4))
}

///|
/// The authors' seeding state, the first words, and where `jump` and
/// `long_jump` land, all from the reference implementation.
test "xoroshiro128pp_runs_the_reference_stream" {
  let first = @xoshiro.Xoroshiro128pp::from_state(
    state_of(xoroshiro128pp_state),
  )
  assert_eq(draw(first, 8), xoroshiro128pp_first)
  let jumped = @xoshiro.Xoroshiro128pp::from_state(
    state_of(xoroshiro128pp_state),
  )
  jumped.jump()
  assert_eq(draw(jumped, 4), xoroshiro128pp_jump)
  let longed = @xoshiro.Xoroshiro128pp::from_state(
    state_of(xoroshiro128pp_state),
  )
  longed.long_jump()
  assert_eq(draw(longed, 4), xoroshiro128pp_long_jump)
}

///|
test "xoroshiro128pp_seeded_twice_agrees_and_seeded_differently_does_not" {
  let a = @xoshiro.Xoroshiro128pp::new(b"moonrand")
  let b = @xoshiro.Xoroshiro128pp::new(b"moonrand")
  assert_eq(draw(a, 4), draw(b, 4))
  let c = @xoshiro.Xoroshiro128pp::new(b"moonranE")
  assert_true(draw(c, 4) != draw(@xoshiro.Xoroshiro128pp::new(b"moonrand"), 4))
}

///|
/// The authors' seeding state, the first words, and where `jump` and
/// `long_jump` land, all from the reference implementation.
test "xoroshiro128ss_runs_the_reference_stream" {
  let first = @xoshiro.Xoroshiro128ss::from_state(
    state_of(xoroshiro128ss_state),
  )
  assert_eq(draw(first, 8), xoroshiro128ss_first)
  let jumped = @xoshiro.Xoroshiro128ss::from_state(
    state_of(xoroshiro128ss_state),
  )
  jumped.jump()
  assert_eq(draw(jumped, 4), xoroshiro128ss_jump)
  let longed = @xoshiro.Xoroshiro128ss::from_state(
    state_of(xoroshiro128ss_state),
  )
  longed.long_jump()
  assert_eq(draw(longed, 4), xoroshiro128ss_long_jump)
}

///|
test "xoroshiro128ss_seeded_twice_agrees_and_seeded_differently_does_not" {
  let a = @xoshiro.Xoroshiro128ss::new(b"moonrand")
  let b = @xoshiro.Xoroshiro128ss::new(b"moonrand")
  assert_eq(draw(a, 4), draw(b, 4))
  let c = @xoshiro.Xoroshiro128ss::new(b"moonranE")
  assert_true(draw(c, 4) != draw(@xoshiro.Xoroshiro128ss::new(b"moonrand"), 4))
}

///|
/// Every generator says how long a seed is, and reads no more than that.
test "seeds_are_the_size_the_contract_announces" {
  assert_eq(@xoshiro.Xoshiro256ss::seed_size(), 32)
  assert_eq(@xoshiro.Xoshiro512ss::seed_size(), 64)
  assert_eq(@xoshiro.Xoroshiro128p::seed_size(), 16)
}
