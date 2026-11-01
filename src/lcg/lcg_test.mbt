///|
test "lcg64_runs_the_numerical_recipes_stream" {
  let g = @lcg.Lcg64::numerical_recipes(42UL)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u64())
  }
  assert_eq(out, lcg64_nr_seed42)
}

///|
test "lcg48_runs_the_drand48_recurrence" {
  let g = @lcg.Lcg48::with_state(0x1234ABCDUL)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u32().to_uint64())
  }
  assert_eq(out, lcg48_state)
}

///|
test "minstd_runs_the_park_miller_stream" {
  let g = @lcg.MinStd::with_state(1UL)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u64())
  }
  assert_eq(out, minstd_seed1)
}

///|
test "qcg64_and_ccg64_run_the_reference_stream" {
  let q = @lcg.Qcg64::with_params(0x9E3779B97F4A7C15UL, 1UL, 42UL)
  let qout : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    qout.push(q.next_u64())
  }
  assert_eq(qout, qcg64_seed42)
  let c = @lcg.Ccg64::with_params(
    0x9E3779B97F4A7C15UL, 0xBF58476D1CE4E5B9UL, 1UL, 42UL,
  )
  let cout : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    cout.push(c.next_u64())
  }
  assert_eq(cout, ccg64_seed42)
}

///|
test "icg32_runs_the_inversive_recurrence" {
  let g = @lcg.Icg32::with_params(12345UL, 1013904223UL, 42UL)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u32().to_uint64())
  }
  assert_eq(out, icg32_seed42)
}

///|
test "lcg_seeding_is_reproducible" {
  let a = @lcg.Lcg64::new(b"moonrand")
  let b = @lcg.Lcg64::new(b"moonrand")
  assert_eq(a.next_u64(), b.next_u64())
  assert_eq(@lcg.MinStd::seed_size(), 8)
}
