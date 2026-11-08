///|
/// A seed fixes the stream, and the sampling functions consume that stream in a
/// fixed order, so the same seed also fixes every value they return. These are
/// that record: a run logged against one version replays on the next, and a
/// change to how a draw is made shows up here rather than silently shifting
/// every number downstream.
///
/// The values were taken from a run on native and are the same on JS, wasm and
/// wasm-gc.
test "sampling_sequence_is_pinned" {
  let rng = @moonrand.seeded(b"sequence")
  assert_eq(@moonrand.random(rng).to_string(), "0.08077081595962665")
  assert_eq(
    @moonrand.uniform(rng, -2.0, 3.0).to_string(),
    "-0.011185712204859755",
  )
  assert_eq(@moonrand.randint(rng, -5L, 5L), -3L)
  assert_eq(@moonrand.randrange(rng, 10L, start=2L), 8L)
  assert_eq(@moonrand.getrandbits(rng, 17), 57796UL)
  assert_eq(@moonrand.choice(rng, ["a", "b", "c", "d"]), Some("b"))
  assert_eq(@moonrand.choices(rng, ["a", "b", "c"], k=3), ["c", "b", "b"])
  assert_eq(@moonrand.sample(rng, ["a", "b", "c", "d"], 3), ["a", "c", "b"])
  let deck = ["a", "b", "c", "d", "e"]
  @moonrand.shuffle(rng, deck)
  assert_eq(deck, ["e", "c", "b", "d", "a"])
}

///|
/// `randint` has to be flat, not merely in range: taking a remainder would leave
/// the low faces a hair more likely, which only a large sample can see. A
/// chi-square over six faces on 120 000 draws; the 0.1% critical value for five
/// degrees of freedom is 20.5.
test "randint_is_flat" {
  let rng = @moonrand.seeded(b"chi-square")
  let draws = 120000
  let faces = 6
  let counts = FixedArray::make(faces, 0)
  for _i = 0; _i < draws; _i = _i + 1 {
    let face = @moonrand.randint(rng, 0L, 5L).to_int()
    counts[face] = counts[face] + 1
  }
  let expected = draws.to_double() / faces.to_double()
  let mut chi = 0.0
  for i = 0; i < faces; i = i + 1 {
    let gap = counts[i].to_double() - expected
    chi = chi + gap * gap / expected
  }
  assert_true(chi < 20.5)
}

///|
/// The closed and half-open forms differ by exactly the endpoint, and a range of
/// one value is not a special case for the caller to guard.
test "randint_and_randrange_land_on_the_end_they_promise" {
  let rng = @moonrand.seeded(b"bounds")
  let mut low_seen = false
  let mut high_seen = false
  let mut over = false
  for _i = 0; _i < 200; _i = _i + 1 {
    let v = @moonrand.randint(rng, -1L, 1L)
    if v == -1L {
      low_seen = true
    }
    if v == 1L {
      high_seen = true
    }
    if v > 1L || v < -1L {
      over = true
    }
  }
  assert_true(low_seen && high_seen && !over)
  assert_eq(@moonrand.randint(rng, 7L, 7L), 7L)
  for _i = 0; _i < 200; _i = _i + 1 {
    let v = @moonrand.randrange(rng, 3L)
    assert_true(v >= 0L && v < 3L)
  }
  assert_eq(@moonrand.randrange(rng, 5L, start=4L), 4L)
}
