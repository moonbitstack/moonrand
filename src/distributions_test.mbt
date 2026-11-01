///|
/// The mean of a sample, for the moment checks below.
fn mean(xs : Array[Double]) -> Double {
  let mut s = 0.0
  for x in xs {
    s = s + x
  }
  s / xs.length().to_double()
}

///|
/// The variance of a sample.
fn variance(xs : Array[Double]) -> Double {
  let m = mean(xs)
  let mut s = 0.0
  for x in xs {
    s = s + (x - m) * (x - m)
  }
  s / xs.length().to_double()
}

///|
/// Pearson's chi-square statistic for `counts` against `expected` proportions.
fn chi_square(
  counts : Array[Int32],
  expected : Array[Double],
  total : Int32,
) -> Double {
  let mut chi = 0.0
  for i = 0; i < counts.length(); i = i + 1 {
    let want = expected[i] * total.to_double()
    let diff = counts[i].to_double() - want
    chi = chi + diff * diff / want
  }
  chi
}

///|
/// `random` is exactly fifty-three bits: every value is an integer multiple of
/// 2^-53 and none needs fewer bits than that to be written exactly.
test "random_is_fifty_three_bits" {
  let r = @moonrand.seeded(b"fifty-three")
  let step = 1.0 / 9007199254740992.0
  for _i = 0; _i < 2000; _i = _i + 1 {
    let x = @moonrand.random(r)
    let scaled = x / step
    assert_eq(scaled.floor(), scaled)
    assert_true(x >= 0.0 && x < 1.0)
  }
}

///|
/// `randint` is unbiased: ten buckets over ten thousand draws, at the 0.001
/// level (chi-square with nine degrees of freedom rejects above 27.88).
test "randint_is_unbiased" {
  let r = @moonrand.seeded(b"randint")
  let counts = Array::make(10, 0)
  let total = 10000
  for _i = 0; _i < total; _i = _i + 1 {
    let v = @moonrand.randint(r, 0L, 9L).to_int()
    counts[v] = counts[v] + 1
  }
  let expected = Array::make(10, 0.1)
  assert_true(chi_square(counts, expected, total) < 27.88)
}

///|
/// The same for `randint` over a range that is not a power of two, where a
/// modulo reduction would show.
test "randint_is_unbiased_over_a_ragged_range" {
  let r = @moonrand.seeded(b"ragged")
  let counts = Array::make(7, 0)
  let total = 7000
  for _i = 0; _i < total; _i = _i + 1 {
    let v = @moonrand.randint(r, -3L, 3L).to_int()
    counts[v + 3] = counts[v + 3] + 1
  }
  let expected = Array::make(7, 1.0 / 7.0)
  assert_true(chi_square(counts, expected, total) < 22.46)
}

///|
/// `choices` with weights draws in proportion: weights 1, 2, 3, 4 over ten
/// thousand draws, the same test at the same level.
test "choices_with_weights_draws_in_proportion" {
  let r = @moonrand.seeded(b"weights")
  let items = [0L, 1L, 2L, 3L]
  let weights = [1.0, 2.0, 3.0, 4.0]
  let counts = Array::make(4, 0)
  let total = 10000
  let drawn = @moonrand.choices(r, items, k=total, weights~)
  for v in drawn {
    counts[v.to_int()] = counts[v.to_int()] + 1
  }
  let expected = [0.1, 0.2, 0.3, 0.4]
  assert_true(chi_square(counts, expected, total) < 16.27)
}

///|
/// Gamma: mean alpha * beta, variance alpha * beta^2, for a shape above one and
/// a shape below it.
test "gamma_has_the_moments_of_a_gamma" {
  let r = @moonrand.seeded(b"gamma")
  let big = Array::make(20000, 0.0)
  for i = 0; i < big.length(); i = i + 1 {
    big[i] = @moonrand.gammavariate(r, 2.0, 3.0)
  }
  assert_true(mean(big) - 6.0 < 0.3)
  assert_true(variance(big) - 18.0 < 2.0)
  let small = Array::make(20000, 0.0)
  for i = 0; i < small.length(); i = i + 1 {
    small[i] = @moonrand.gammavariate(r, 0.5, 2.0)
  }
  assert_true(mean(small) - 1.0 < 0.2)
}

///|
test "beta_has_the_mean_of_a_beta" {
  let r = @moonrand.seeded(b"beta")
  let xs = Array::make(20000, 0.0)
  for i = 0; i < xs.length(); i = i + 1 {
    xs[i] = @moonrand.betavariate(r, 2.0, 5.0)
  }
  assert_true(mean(xs) - 2.0 / 7.0 < 0.02)
  for x in xs {
    assert_true(x > 0.0 && x < 1.0)
  }
}

///|
test "poisson_has_the_mean_and_variance_of_a_poisson" {
  let r = @moonrand.seeded(b"poisson")
  let small = Array::make(20000, 0.0)
  for i = 0; i < small.length(); i = i + 1 {
    small[i] = @moonrand.poisson(r, 4.0).to_double()
  }
  assert_true(mean(small) - 4.0 < 0.15)
  assert_true(variance(small) - 4.0 < 0.3)
  // The large-mean path, which the multiplication loop would never finish.
  let big = Array::make(5000, 0.0)
  for i = 0; i < big.length(); i = i + 1 {
    big[i] = @moonrand.poisson(r, 500.0).to_double()
  }
  assert_true(mean(big) - 500.0 < 5.0)
  assert_eq(@moonrand.poisson(r, 0.0), 0L)
}

///|
test "binomial_has_the_mean_of_a_binomial_and_its_edges" {
  let r = @moonrand.seeded(b"binomial")
  let xs = Array::make(20000, 0.0)
  for i = 0; i < xs.length(); i = i + 1 {
    xs[i] = @moonrand.binomialvariate(r, 10L, 0.3).to_double()
  }
  assert_true(mean(xs) - 3.0 < 0.15)
  assert_eq(@moonrand.binomialvariate(r, 10L, 0.0), 0L)
  assert_eq(@moonrand.binomialvariate(r, 10L, 1.0), 10L)
  assert_eq(@moonrand.binomialvariate(r, 0L, 0.5), 0L)
}

///|
test "triangular_peaks_where_it_is_told_and_spans_its_bounds" {
  let r = @moonrand.seeded(b"triangular")
  let mid = Array::make(20000, 0.0)
  for i = 0; i < mid.length(); i = i + 1 {
    mid[i] = @moonrand.triangular(r, low=0.0, high=1.0, mode=0.5)
  }
  assert_true(mean(mid) - 0.5 < 0.02)
  // A triangular draw has mean (low + mode + high) / 3, so a peak at the low
  // end of [0, 4] has mean 4/3.
  let skewed = Array::make(20000, 0.0)
  for i = 0; i < skewed.length(); i = i + 1 {
    skewed[i] = @moonrand.triangular(r, low=0.0, high=4.0, mode=0.0)
  }
  assert_true(mean(skewed) - 4.0 / 3.0 < 0.05)
  for x in skewed {
    assert_true(x >= 0.0 && x <= 4.0)
  }
}

///|
test "normal_has_the_moments_of_a_normal" {
  let r = @moonrand.seeded(b"normal")
  let xs = Array::make(20000, 0.0)
  for i = 0; i < xs.length(); i = i + 1 {
    xs[i] = @moonrand.normalvariate(r, mu=3.0, sigma=2.0)
  }
  assert_true(mean(xs) - 3.0 < 0.1)
  assert_true(variance(xs) - 4.0 < 0.3)
}

///|
test "weibull_and_pareto_have_the_moments_their_shapes_give" {
  let r = @moonrand.seeded(b"weibull")
  let w = Array::make(20000, 0.0)
  for i = 0; i < w.length(); i = i + 1 {
    w[i] = @moonrand.weibullvariate(r, 1.0, 2.0)
  }
  // The mean of a Weibull with shape 2 and scale 1 is Gamma(1.5) = 0.8862.
  assert_true(mean(w) - 0.8862 < 0.02)
  let p = Array::make(20000, 0.0)
  for i = 0; i < p.length(); i = i + 1 {
    p[i] = @moonrand.paretovariate(r, 3.0)
  }
  // The mean of a Pareto with shape 3 is 3 / 2.
  assert_true(mean(p) - 1.5 < 0.05)
  for x in p {
    assert_true(x >= 1.0)
  }
}

///|
/// von Mises with a large concentration clusters around its mean angle: the
/// mean of cos(theta - mu) is I1(5)/I0(5), about 0.9018.
test "vonmises_clusters_around_its_mean_angle" {
  let r = @moonrand.seeded(b"vonmises")
  let mut total = 0.0
  let n = 20000
  for _i = 0; _i < n; _i = _i + 1 {
    let theta = @moonrand.vonmisesvariate(r, 0.0, 5.0)
    assert_true(theta >= 0.0 && theta < 2.0 * 3.141592653589793)
    total = total + @math.cos(theta)
  }
  assert_true(total / n.to_double() - 0.9018 < 0.02)
}
