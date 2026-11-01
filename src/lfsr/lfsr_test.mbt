///|
test "lfsr64_runs_the_reference_stream" {
  let g = @lfsr.Lfsr64::with_state(lfsr64_state[0])
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u64())
  }
  assert_eq(out, lfsr64_first)
}

///|
test "taus88_runs_the_reference_stream" {
  let g = @lfsr.Taus88::with_state(
    taus88_state[0].to_uint(),
    taus88_state[1].to_uint(),
    taus88_state[2].to_uint(),
  )
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u32().to_uint64())
  }
  assert_eq(out, taus88_first)
}

///|
test "lfsr113_runs_the_reference_stream" {
  let g = @lfsr.Lfsr113::with_state(
    lfsr113_state[0].to_uint(),
    lfsr113_state[1].to_uint(),
    lfsr113_state[2].to_uint(),
    lfsr113_state[3].to_uint(),
  )
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u32().to_uint64())
  }
  assert_eq(out, lfsr113_first)
}

///|
test "lfsr258_runs_the_reference_stream" {
  let g = @lfsr.Lfsr258::with_state(
    lfsr258_state[0],
    lfsr258_state[1],
    lfsr258_state[2],
    lfsr258_state[3],
    lfsr258_state[4],
  )
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u64())
  }
  assert_eq(out, lfsr258_first)
}

///|
/// The generalized register hands out each word once per pass over its 250
/// words, and the ring moves on: a short run must not repeat itself.
test "gfsr_walks_its_ring" {
  let g = @lfsr.Gfsr::new(b"moonrand")
  let mut seen = 0
  let mut last = 0U
  for _i = 0; _i < 300; _i = _i + 1 {
    let v = g.next_u32()
    if v != last {
      seen = seen + 1
    }
    last = v
  }
  assert_true(seen > 250)
  assert_eq(@lfsr.Lfsr113::seed_size(), 16)
}
