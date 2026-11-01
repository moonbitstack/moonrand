///|
test "mrg32k3a_runs_the_reference_stream" {
  let st = FixedArray::make(6, 0L)
  for i = 0; i < 6; i = i + 1 {
    st[i] = mrg32k3a_state[i].reinterpret_as_int64()
  }
  let g = @mrg.Mrg32k3a::from_state(st)
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u32().to_uint64())
  }
  assert_eq(out, mrg32k3a_first)
}

///|
/// `advance` raises each component's transition matrix instead of stepping it,
/// so skipping n draws must land on the same word as drawing n times.
test "mrg32k3a_advance_lands_where_drawing_does" {
  for skip in [0UL, 1UL, 2UL, 7UL, 100UL] {
    let walked = @mrg.Mrg32k3a::new(b"moonrand")
    for _i = 0UL; _i < skip; _i = _i + 1UL {
      ignore(walked.next_u32())
    }
    let sought = @mrg.Mrg32k3a::new(b"moonrand")
    sought.advance(skip)
    assert_eq(sought.next_u32(), walked.next_u32())
  }
  assert_eq(@mrg.Mrg32k3a::seed_size(), 24)
}
