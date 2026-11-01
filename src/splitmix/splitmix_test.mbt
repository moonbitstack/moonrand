///|
/// The state a `from_state` call takes.
fn state_of(a : Array[UInt64]) -> FixedArray[UInt64] {
  let out = FixedArray::make(a.length(), 0UL)
  for i = 0; i < a.length(); i = i + 1 {
    out[i] = a[i]
  }
  out
}

///|
/// The reference stream from a zero counter: the first eight SplitMix64 outputs.
test "splitmix64_runs_the_reference_stream" {
  let r = @splitmix.SplitMix64::from_state(0UL)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(r.next_u64())
  }
  assert_eq(out, splitmix64_seed0)
  ignore(state_of(splitmix64_seed0))
}

///|
/// `advance` adds whole golden-ratio steps, so seeking n draws must land where
/// n draws would have: the same counter, the same word.
test "splitmix64_advance_seeks" {
  for skip in [0UL, 1UL, 2UL, 9UL, 1000UL] {
    let walked = @splitmix.SplitMix64::from_state(42UL)
    for _i = 0UL; _i < skip; _i = _i + 1UL {
      ignore(walked.next_u64())
    }
    let sought = @splitmix.SplitMix64::from_state(42UL)
    sought.advance(skip)
    assert_eq(sought.next_u64(), walked.next_u64())
  }
}

///|
test "splitmix64_seeded_twice_agrees" {
  let a = @splitmix.SplitMix64::new(b"moonrand")
  let b = @splitmix.SplitMix64::new(b"moonrand")
  assert_eq(a.next_u64(), b.next_u64())
  assert_eq(@splitmix.SplitMix64::seed_size(), 8)
}
