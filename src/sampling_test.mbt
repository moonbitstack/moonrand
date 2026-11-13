///|
/// `randbytes` writes what `fill` writes: same seed, same bytes, and the two
/// paths agree word for word.
test "randbytes_is_the_streams_bytes" {
  let a = @moonrand.randbytes(@moonrand.seeded(b"bytes"), 24)
  let b = @moonrand.randbytes(@moonrand.seeded(b"bytes"), 24)
  assert_eq(a.length(), 24)
  assert_eq(a, b)
  let other = @moonrand.randbytes(@moonrand.seeded(b"byte"), 24)
  assert_true(a != other)
  let r = @moonrand.seeded(b"bytes")
  let buf = FixedArray::make(24, b'\x00')
  r.fill(buf)
  assert_eq(Bytes::from_array(buf), a)
}

///|
/// A count of zero is an empty result, and a negative one is read the same way
/// rather than aborting: there is nothing to fill either way.
test "randbytes_of_nothing_is_empty" {
  let r = @moonrand.seeded(b"empty")
  assert_eq(@moonrand.randbytes(r, 0).length(), 0)
  assert_eq(@moonrand.randbytes(r, -3).length(), 0)
}

///|
/// `bernoulli` at the two ends is certain, and in between it keeps its share:
/// a quarter of ten thousand draws, at the 0.001 level.
test "bernoulli_keeps_its_probability" {
  let r = @moonrand.seeded(b"coin")
  for _i = 0; _i < 100; _i = _i + 1 {
    assert_false(@moonrand.bernoulli(r, p=0.0))
    assert_true(@moonrand.bernoulli(r, p=1.0))
  }
  let total = 10000
  let mut hits = 0
  for _i = 0; _i < total; _i = _i + 1 {
    if @moonrand.bernoulli(r, p=0.25) {
      hits = hits + 1
    }
  }
  assert_true(near(hits.to_double() / total.to_double(), 0.25, 0.02))
}

///|
/// A probability outside the interval is answered by the nearer end, not by a
/// draw: certainty above one, impossibility below zero.
test "bernoulli_outside_the_interval_is_certain" {
  let r = @moonrand.seeded(b"edges")
  assert_false(@moonrand.bernoulli(r, p=-0.5))
  assert_true(@moonrand.bernoulli(r, p=1.5))
}

///|
/// `permutation` is a permutation: every index once, no index lost.
test "permutation_holds_every_index_once" {
  let r = @moonrand.seeded(b"perm")
  let p = @moonrand.permutation(r, 100)
  assert_eq(p.length(), 100)
  let sorted = p.copy()
  sorted.sort()
  for i = 0; i < 100; i = i + 1 {
    assert_eq(sorted[i], i)
  }
  assert_eq(@moonrand.permutation(r, 0).length(), 0)
  assert_eq(@moonrand.permutation(r, -1).length(), 0)
  assert_eq(@moonrand.permutation(r, 1), [0])
}

///|
/// The head of a permutation is uniform: over five thousand shuffles of four
/// indices, which index comes first is one of four equally often.
test "permutation_starts_everywhere_equally" {
  let r = @moonrand.seeded(b"head")
  let counts = Array::make(4, 0)
  let total = 5000
  for _i = 0; _i < total; _i = _i + 1 {
    let p = @moonrand.permutation(r, 4)
    counts[p[0]] = counts[p[0]] + 1
  }
  let expected = Array::make(4, 0.25)
  assert_true(chi_square(counts, expected, total) < 16.27)
}

///|
/// A shuffle reaches all six orders of three items about equally often, which
/// is what a Fisher-Yates loop that stops one step late or early does not do.
test "shuffle_reaches_every_order_equally" {
  let r = @moonrand.seeded(b"orders")
  let counts = Array::make(6, 0)
  let total = 6000
  for _i = 0; _i < total; _i = _i + 1 {
    let a = [0, 1, 2]
    @moonrand.shuffle(r, a)
    let code = a[0] * 100 + a[1] * 10 + a[2]
    let slot = match code {
      12 => 0
      21 => 1
      102 => 2
      120 => 3
      201 => 4
      _ => 5
    }
    counts[slot] = counts[slot] + 1
  }
  let expected = Array::make(6, 1.0 / 6.0)
  assert_true(chi_square(counts, expected, total) < 20.52)
}

///|
/// `choice` is uniform over the view, whatever the elements are.
test "choice_is_uniform_over_the_view" {
  let r = @moonrand.seeded(b"choice")
  let items = ["a", "b", "c", "d", "e"]
  let counts = Array::make(5, 0)
  let total = 10000
  for _i = 0; _i < total; _i = _i + 1 {
    let got = @moonrand.choice(r, items).unwrap()
    for i = 0; i < 5; i = i + 1 {
      if items[i] == got {
        counts[i] = counts[i] + 1
      }
    }
  }
  let expected = Array::make(5, 0.2)
  assert_true(chi_square(counts, expected, total) < 18.47)
}

///|
/// With weights, `sample` fills the first place in proportion to the weight,
/// as `choices` does with one draw, and still returns distinct elements.
test "sample_with_weights_draws_in_proportion" {
  let r = @moonrand.seeded(b"weighted sample")
  let items = [0L, 1L, 2L, 3L]
  let weights = [1.0, 2.0, 3.0, 4.0]
  let counts = Array::make(4, 0)
  let total = 10000
  for _i = 0; _i < total; _i = _i + 1 {
    let got = @moonrand.sample(r, items, 1, weights~)
    counts[got[0].to_int()] = counts[got[0].to_int()] + 1
  }
  let expected = [0.1, 0.2, 0.3, 0.4]
  assert_true(chi_square(counts, expected, total) < 16.27)
}

///|
/// A weight of zero is never taken while a positive weight is left: with one
/// positive entry, that entry is the first place every time.
test "sample_with_one_positive_weight_takes_it_first" {
  let r = @moonrand.seeded(b"heavy")
  let items = [0, 1, 2, 3]
  let weights = [0.0, 0.0, 0.0, 1.0]
  for _i = 0; _i < 200; _i = _i + 1 {
    let got = @moonrand.sample(r, items, 4, weights~)
    assert_eq(got.length(), 4)
    assert_eq(got[0], 3)
  }
}

///|
/// Weights that are all zero are read as no weights, as `choices` reads them.
test "sample_with_zero_weights_is_the_unweighted_sample" {
  let r = @moonrand.seeded(b"zero weights")
  let got = @moonrand.sample(r, [1, 2, 3, 4], 4, weights=[0.0, 0.0, 0.0, 0.0])
  let sorted = got.copy()
  sorted.sort()
  assert_eq(sorted, [1, 2, 3, 4])
}

///|
/// `getrandbits` at the edges: nothing, one bit, a whole word, and more than a
/// word, which is the whole word.
test "getrandbits_at_its_edges" {
  assert_eq(@moonrand.getrandbits(@moonrand.seeded(b"bits"), 0), 0UL)
  assert_eq(@moonrand.getrandbits(@moonrand.seeded(b"bits"), -1), 0UL)
  let single = @moonrand.getrandbits(@moonrand.seeded(b"bits"), 1)
  assert_true(single == 0UL || single == 1UL)
  let word = @moonrand.seeded(b"bits").next_u64()
  assert_eq(@moonrand.getrandbits(@moonrand.seeded(b"bits"), 64), word)
  assert_eq(@moonrand.getrandbits(@moonrand.seeded(b"bits"), 65), word)
}

///|
/// Reversed ends of `uniform` still give a value between them, in the order
/// given: the interval is `[b, a)` when `a` is above `b`.
test "uniform_takes_reversed_ends" {
  let r = @moonrand.seeded(b"reversed")
  for _i = 0; _i < 500; _i = _i + 1 {
    let x = @moonrand.uniform(r, 5.0, -2.0)
    assert_true(x >= -2.0 && x < 5.0)
  }
}

///|
/// A negative step walks down and stops at `stop`, both ends as promised.
test "randrange_with_a_negative_step" {
  let r = @moonrand.seeded(b"down")
  let seen = Array::make(6, 0)
  for _i = 0; _i < 1000; _i = _i + 1 {
    let v = @moonrand.randrange(r, -5L, start=10L, step=-3L)
    let slot = (v + 5L).to_int() / 3
    seen[slot] = seen[slot] + 1
  }
  for i = 1; i < 6; i = i + 1 {
    assert_true(seen[i] > 0)
  }
}
