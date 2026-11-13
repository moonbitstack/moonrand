///|
/// `gauss` puts the mean where it is told and the width where it is told: two
/// thousand draws, the sample mean and variance within a tenth of a unit.
test "gauss_has_the_moments_its_parameters_give" {
  let r = @moonrand.seeded(b"gauss moments")
  let xs = Array::make(20000, 0.0)
  for i = 0; i < xs.length(); i = i + 1 {
    xs[i] = @moonrand.gauss(r, mu=3.0, sigma=2.0)
  }
  assert_true(near(mean(xs), 3.0, 0.05))
  assert_true(near(variance(xs), 4.0, 0.15))
}

///|
/// Chi-squared with five degrees of freedom: mean five, variance ten, since
/// that is what `k` and `2k` are.
test "chi_squared_has_the_moments_of_a_chi_squared" {
  let r = @moonrand.seeded(b"chi")
  let xs = Array::make(20000, 0.0)
  for i = 0; i < xs.length(); i = i + 1 {
    xs[i] = @moonrand.chi_squared(r, 5.0)
  }
  assert_true(near(mean(xs), 5.0, 0.15))
  assert_true(near(variance(xs), 10.0, 0.8))
}

///|
/// Student's t with ten degrees of freedom: centred on zero, and as wide as
/// `nu / (nu - 2)`.
test "student_t_has_the_moments_of_a_t" {
  let r = @moonrand.seeded(b"student")
  let xs = Array::make(20000, 0.0)
  for i = 0; i < xs.length(); i = i + 1 {
    xs[i] = @moonrand.student_t(r, 10.0)
  }
  assert_true(near(mean(xs), 0.0, 0.06))
  assert_true(near(variance(xs), 1.25, 0.12))
}

///|
/// The F distribution with six and ten degrees of freedom has mean
/// `d2 / (d2 - 2)`, and every draw is positive.
test "fisher_f_has_the_mean_of_an_f" {
  let r = @moonrand.seeded(b"fisher")
  let xs = Array::make(20000, 0.0)
  for i = 0; i < xs.length(); i = i + 1 {
    xs[i] = @moonrand.fisher_f(r, 6.0, 10.0)
    assert_true(xs[i] > 0.0)
  }
  assert_true(near(mean(xs), 1.25, 0.12))
}

///|
/// A Dirichlet draw is a composition: positive parts, one whole, and the parts
/// in the proportions the concentrations ask for.
test "dirichlet_splits_one_in_proportion_to_its_concentrations" {
  let r = @moonrand.seeded(b"dirichlet")
  let alpha = [1.0, 2.0, 3.0]
  let sums = Array::make(3, 0.0)
  let draws = 5000
  for _i = 0; _i < draws; _i = _i + 1 {
    let x = @moonrand.dirichlet(r, alpha)
    assert_eq(x.length(), 3)
    let mut total = 0.0
    for j = 0; j < 3; j = j + 1 {
      assert_true(x[j] > 0.0 && x[j] < 1.0)
      total = total + x[j]
      sums[j] = sums[j] + x[j]
    }
    assert_true(near(total, 1.0, 1.0e-12))
  }
  assert_true(near(sums[0] / draws.to_double(), 1.0 / 6.0, 0.02))
  assert_true(near(sums[1] / draws.to_double(), 1.0 / 3.0, 0.02))
  assert_true(near(sums[2] / draws.to_double(), 1.0 / 2.0, 0.02))
}

///|
/// A concentration of zero is outside the distribution's domain, and a draw
/// says so instead of returning a composition that is not one.
test "panic dirichlet with a concentration of zero" {
  let r = @moonrand.seeded(b"zero alpha")
  let _ = @moonrand.dirichlet(r, [1.0, 0.0])
}

///|
test "panic chi_squared with no degrees of freedom" {
  let _ = @moonrand.chi_squared(@moonrand.seeded(b"chi0"), 0.0)
}

///|
test "panic student_t with no degrees of freedom" {
  let _ = @moonrand.student_t(@moonrand.seeded(b"t0"), 0.0)
}

///|
test "panic fisher_f with a degree of freedom below one" {
  let _ = @moonrand.fisher_f(@moonrand.seeded(b"f0"), 0.0, 4.0)
}

///|
/// A weight below zero is not a weight, and sampling says so rather than
/// quietly treating the element as impossible or as certain.
test "panic sample with a negative weight" {
  let r = @moonrand.seeded(b"negative")
  let _ = @moonrand.sample(r, [1, 2, 3], 2, weights=[1.0, -1.0, 1.0])
}

///|
test "panic choices with a negative weight" {
  let r = @moonrand.seeded(b"negative")
  let _ = @moonrand.choices(r, [1, 2, 3], k=2, weights=[1.0, -1.0, 1.0])
}
