///|
/// Property and correctness checks for the generic sampling/distribution
/// functions in `moonrand`, exercised through the default `StdRng` (ChaCha12).
/// Every generator is rebuilt from an explicit seed so the runs are
/// reproducible.
fn zeros_seed() -> BytesView {
  Bytes::from_array(Array::make(32, (0).to_byte()))[0:]
}

///|
fn ascending_seed() -> BytesView {
  let a = Array::make(32, (0).to_byte())
  for i = 0; i < 32; i = i + 1 {
    a[i] = (i.reinterpret_as_uint() & 0xFFU).to_byte()
  }
  Bytes::from_array(a)[0:]
}

///|
test "dist_determinism" {
  let r1 = @moonrand.seeded(zeros_seed())
  let r2 = @moonrand.seeded(zeros_seed())
  let a1 = Array::make(20, 0L)
  let a2 = Array::make(20, 0L)
  for i = 0; i < 20; i = i + 1 {
    a1[i] = @moonrand.randint(r1, 0L, 1000000L)
    a2[i] = @moonrand.randint(r2, 0L, 1000000L)
  }
  assert_eq(a1, a2)
}

///|
test "dist_random_in_unit" {
  let r = @moonrand.seeded(zeros_seed())
  for _i = 0; _i < 2000; _i = _i + 1 {
    let x = @moonrand.random(r)
    assert_true(x >= 0.0 && x < 1.0)
  }
}

///|
test "dist_uniform_bounds" {
  let r = @moonrand.seeded(zeros_seed())
  for _i = 0; _i < 2000; _i = _i + 1 {
    let x = @moonrand.uniform(r, -5.0, 5.0)
    assert_true(x >= -5.0 && x < 5.0)
  }
}

///|
test "dist_randint_bounds" {
  let r = @moonrand.seeded(ascending_seed())
  for _i = 0; _i < 2000; _i = _i + 1 {
    let x = @moonrand.randint(r, 5L, 12L)
    assert_true(x >= 5L && x <= 12L)
  }
}

///|
test "dist_randrange_step" {
  let r = @moonrand.seeded(ascending_seed())
  for _i = 0; _i < 2000; _i = _i + 1 {
    let x = @moonrand.randrange(r, 10L, start=2L, step=2L)
    assert_true(x >= 2L && x <= 8L)
    assert_true((x - 2L) % 2L == 0L)
  }
}

///|
test "dist_getrandbits_mask" {
  let r = @moonrand.seeded(zeros_seed())
  for k = 1; k <= 63; k = k + 1 {
    let x = @moonrand.getrandbits(r, k)
    assert_true(x < 1UL << k)
  }
  let full = @moonrand.getrandbits(r, 64)
  assert_true(full <= 0xFFFFFFFFFFFFFFFFUL)
}

///|
test "dist_choice_membership" {
  let items = [10L, 20L, 30L, 40L]
  let r = @moonrand.seeded(ascending_seed())
  for _i = 0; _i < 500; _i = _i + 1 {
    match @moonrand.choice(r, items) {
      Some(x) => assert_true(x == 10L || x == 20L || x == 30L || x == 40L)
      None => abort("choice returned None on a non-empty population")
    }
  }
  let empty : Array[Int64] = []
  assert_true(@moonrand.choice(r, empty) is None)
}

///|
test "dist_sample_distinct" {
  let items = [0L, 1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L, 9L]
  let r = @moonrand.seeded(ascending_seed())
  let s = @moonrand.sample(r, items, 5)
  assert_eq(s.length(), 5)
  for i = 0; i < s.length(); i = i + 1 {
    let mut found = false
    for j = 0; j < items.length(); j = j + 1 {
      if s[i] == items[j] {
        found = true
      }
    }
    assert_true(found)
  }
  for i = 0; i < s.length(); i = i + 1 {
    for j = i + 1; j < s.length(); j = j + 1 {
      assert_true(s[i] != s[j])
    }
  }
}

///|
test "dist_shuffle_preserves_multiset" {
  let r = @moonrand.seeded(zeros_seed())
  let a = [0L, 1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L, 9L]
  let mut sum_before = 0L
  for i = 0; i < a.length(); i = i + 1 {
    sum_before = sum_before + a[i]
  }
  @moonrand.shuffle(r, a)
  let mut sum_after = 0L
  for i = 0; i < a.length(); i = i + 1 {
    sum_after = sum_after + a[i]
  }
  assert_eq(sum_before, sum_after)
  assert_eq(a.length(), 10)
}

///|
test "dist_gauss_expo_lognorm_finite" {
  let r = @moonrand.seeded(ascending_seed())
  for _i = 0; _i < 200; _i = _i + 1 {
    let g = @moonrand.gauss(r, mu=0.0, sigma=1.0)
    assert_true(g - g == 0.0)
    let e = @moonrand.expovariate(r, 1.0)
    assert_true(e - e == 0.0 && e > 0.0)
    let l = @moonrand.lognormvariate(r, mu=0.0, sigma=1.0)
    assert_true(l - l == 0.0 && l > 0.0)
  }
}
