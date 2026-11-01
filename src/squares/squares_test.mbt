///|
test "squares_runs_the_reference_stream" {
  let g = @squares.Squares::with_key(
    squares_key[0],
    squares_key[1],
    squares_key[2],
    squares_key[3],
  )
  let out : Array[UInt64] = []
  for _i = 0; _i < 8; _i = _i + 1 {
    out.push(g.next_u64())
  }
  assert_eq(out, squares_first)
}

///|
/// The counter is the whole state, so seeking must land where drawing lands.
test "squares_advance_seeks_the_counter" {
  for skip in [0UL, 1UL, 2UL, 9UL, 1000UL] {
    let walked = @squares.Squares::new(b"moonrand")
    for _i = 0UL; _i < skip; _i = _i + 1UL {
      ignore(walked.next_u64())
    }
    let sought = @squares.Squares::new(b"moonrand")
    sought.advance(skip)
    assert_eq(sought.next_u64(), walked.next_u64())
  }
  assert_eq(@squares.Squares::seed_size(), 32)
}
