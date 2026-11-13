///|
/// The distributions, one draw each, over any `Rng`. Names follow Python's
/// `random` where they overlap; several more are built from those by the
/// definition of the distribution.
///
/// A draw takes as many words from the stream as its algorithm needs, so two
/// distributions asked of the same generator interleave in the order you ask.
/// Nothing is cached between calls: a normal draw is one draw, not one of a
/// stored pair.

///|
/// A normal draw, scaled to `mu` and `sigma` (Box-Muller).
pub fn[R : @contract.Rng] gauss(
  r : R,
  mu~ : Double = 0.0,
  sigma~ : Double = 1.0,
) -> Double {
  let u1 = 1.0 - random(r)
  let u2 = random(r)
  let mag = sigma * (-2.0 * @math.ln(u1)).sqrt()
  mag * @math.cos(2.0 * 3.141592653589793 * u2) + mu
}

///|
/// An exponential draw with rate `lambd` (mean `1/lambd`).
pub fn[R : @contract.Rng] expovariate(r : R, lambd : Double) -> Double {
  if lambd <= 0.0 {
    abort("expovariate: lambda must be positive")
  }
  -@math.ln(random(r)) / lambd
}

///|
/// A lognormal draw: `exp(gauss(mu, sigma))`.
pub fn[R : @contract.Rng] lognormvariate(
  r : R,
  mu~ : Double = 0.0,
  sigma~ : Double = 1.0,
) -> Double {
  @math.exp(gauss(r, mu~, sigma~))
}

///|
/// The constants the reference samplers carry: log 4, the squeeze constant of
/// the Marsaglia-Tsang gamma, and the magic constant of the Kinderman-Monahan
/// normal.
const LOG4 : Double = 1.3862943611198906

///|
const SQ_MAGIC : Double = 2.504077396776274

///|
const NV_MAGIC : Double = 1.71552776992141

///|
/// A gamma draw with shape `alpha` and scale `beta`, by Marsaglia and Tsang's
/// transform-reject method with the squeeze from their paper (and the Cheng
/// variant for `alpha` below one).
pub fn[R : @contract.Rng] gammavariate(
  r : R,
  alpha : Double,
  beta : Double,
) -> Double {
  if alpha <= 0.0 || beta <= 0.0 {
    abort("gammavariate: alpha and beta must be positive")
  }
  if alpha > 1.0 {
    let ainv = (2.0 * alpha - 1.0).sqrt()
    let bbb = alpha - LOG4
    let ccc = alpha + ainv
    while true {
      let u1 = random(r)
      if u1 > 1.0e-7 && u1 < 0.9999999 {
        let u2 = 1.0 - random(r)
        let v = @math.ln(u1 / (1.0 - u1)) / ainv
        let x = alpha * @math.exp(v)
        let z = u1 * u1 * u2
        let rr = bbb + ccc * v - x
        if rr + SQ_MAGIC - 4.5 * z >= 0.0 || rr >= @math.ln(z) {
          return x * beta
        }
      }
    }
    abort("gammavariate: unreachable")
  } else if alpha == 1.0 {
    let mut u = random(r)
    while u <= 1.0e-7 {
      u = random(r)
    }
    -@math.ln(u) * beta
  } else {
    // Below one: the convolution of a gamma of shape alpha + 1 with a
    // fractional power, the "GS" algorithm of Kennedy and Gentle.
    let e = 2.718281828459045
    while true {
      let u = random(r)
      let b = (e + alpha) / e
      let p = b * u
      let x = if p <= 1.0 {
        @math.pow(p, 1.0 / alpha)
      } else {
        -@math.ln((b - p) / alpha)
      }
      let u1 = random(r)
      if p > 1.0 {
        if u1 <= @math.pow(x, alpha - 1.0) {
          return x * beta
        }
      } else if u1 <= @math.exp(-x) {
        return x * beta
      }
    }
    abort("gammavariate: unreachable")
  }
}

///|
/// A beta draw with shape parameters `alpha` and `beta`: two gamma draws, taken
/// as a fraction of their sum.
pub fn[R : @contract.Rng] betavariate(
  r : R,
  alpha : Double,
  beta : Double,
) -> Double {
  let x = gammavariate(r, alpha, 1.0)
  let y = gammavariate(r, beta, 1.0)
  x / (x + y)
}

///|
/// A chi-squared draw with `k` degrees of freedom: a gamma draw of shape
/// `k/2` and scale two, which is what the chi-squared distribution is.
pub fn[R : @contract.Rng] chi_squared(r : R, df : Double) -> Double {
  if df <= 0.0 {
    abort("chi_squared: the degrees of freedom must be positive")
  }
  gammavariate(r, df / 2.0, 2.0)
}

///|
/// A Student's t draw with `nu` degrees of freedom: a normal draw over the
/// square root of a chi-squared draw divided by its own degrees of freedom.
pub fn[R : @contract.Rng] student_t(r : R, nu : Double) -> Double {
  if nu <= 0.0 {
    abort("student_t: nu must be positive")
  }
  gauss(r) / (chi_squared(r, nu) / nu).sqrt()
}

///|
/// An F draw with `d1` and `d2` degrees of freedom: the ratio of two
/// chi-squared draws, each divided by its own degrees of freedom.
pub fn[R : @contract.Rng] fisher_f(r : R, d1 : Double, d2 : Double) -> Double {
  if d1 <= 0.0 || d2 <= 0.0 {
    abort("fisher_f: the degrees of freedom must be positive")
  }
  let a = chi_squared(r, d1) / d1
  let b = chi_squared(r, d2) / d2
  a / b
}

///|
/// A Dirichlet draw of concentration `alpha`: one gamma draw per component,
/// each scaled down by their sum, so the result adds up to one. Every
/// component of `alpha` must be positive.
pub fn[R : @contract.Rng] dirichlet(
  r : R,
  alpha : ArrayView[Double],
) -> Array[Double] {
  let n = alpha.length()
  let out : Array[Double] = []
  if n == 0 {
    return out
  }
  let mut total = 0.0
  for i = 0; i < n; i = i + 1 {
    let x = gammavariate(r, alpha[i], 1.0)
    total = total + x
    out.push(x)
  }
  if total > 0.0 {
    for i = 0; i < n; i = i + 1 {
      out[i] = out[i] / total
    }
  }
  out
}

///|
/// A Pareto draw with shape `alpha`: one minus a uniform, raised to -1/alpha.
pub fn[R : @contract.Rng] paretovariate(r : R, alpha : Double) -> Double {
  if alpha <= 0.0 {
    abort("paretovariate: alpha must be positive")
  }
  1.0 / @math.pow(1.0 - random(r), 1.0 / alpha)
}

///|
/// A Weibull draw with scale `alpha` and shape `beta`, as Python's
/// `weibullvariate` names them.
pub fn[R : @contract.Rng] weibullvariate(
  r : R,
  alpha : Double,
  beta : Double,
) -> Double {
  if alpha <= 0.0 || beta <= 0.0 {
    abort("weibullvariate: alpha and beta must be positive")
  }
  alpha * @math.pow(-@math.ln(1.0 - random(r)), 1.0 / beta)
}

///|
/// A von Mises draw with mean angle `mu` and concentration `kappa`, by the
/// Best-Fisher rejection scheme Python's `vonmisesvariate` uses. Angles come
/// back in [0, 2 pi).
pub fn[R : @contract.Rng] vonmisesvariate(
  r : R,
  mu : Double,
  kappa : Double,
) -> Double {
  if kappa <= 1.0e-6 {
    return 2.0 * @math.PI * random(r)
  }
  let a = 1.0 + (1.0 + 4.0 * kappa * kappa).sqrt()
  let b = (a - (2.0 * a).sqrt()) / (2.0 * kappa)
  let rad = (1.0 + b * b) / (2.0 * b)
  let mut f = 0.0
  while true {
    let u1 = random(r)
    let z = @math.cos(@math.PI * u1)
    f = (1.0 + rad * z) / (rad + z)
    let c = kappa * (rad - f)
    let u2 = random(r)
    if u2 < c * (2.0 - c) || u2 <= c * @math.exp(1.0 - c) {
      break
    }
  }
  let u3 = random(r)
  let base = mu - 2.0 * @math.PI * (mu / (2.0 * @math.PI)).floor()
  let theta = if u3 > 0.5 { base + @math.acos(f) } else { base - @math.acos(f) }
  if theta < 0.0 {
    theta + 2.0 * @math.PI
  } else if theta >= 2.0 * @math.PI {
    theta - 2.0 * @math.PI
  } else {
    theta
  }
}

///|
/// A normal draw by the ratio-of-uniforms method of Kinderman and Monahan, the
/// one Python's `normalvariate` uses — a different algorithm from `gauss`, and
/// a different stream for the same seed.
pub fn[R : @contract.Rng] normalvariate(
  r : R,
  mu~ : Double = 0.0,
  sigma~ : Double = 1.0,
) -> Double {
  while true {
    let u1 = random(r)
    let u2 = 1.0 - random(r)
    let z = NV_MAGIC * (u1 - 0.5) / u2
    let zz = z * z / 4.0
    if zz <= -@math.ln(u2) {
      return mu + z * sigma
    }
  }
  abort("normalvariate: unreachable")
}

///|
/// A triangular draw between `low` and `high` with the peak at `mode`, which
/// defaults to the midpoint. The inverse of the triangular CDF, folded so that
/// one uniform does the work.
pub fn[R : @contract.Rng] triangular(
  r : R,
  low~ : Double = 0.0,
  high~ : Double = 1.0,
  mode? : Double,
) -> Double {
  let mid = match mode {
    Some(m) => m
    None => (low + high) / 2.0
  }
  if high <= low {
    abort("triangular: high must exceed low")
  }
  let mut u = random(r)
  let mut c = (mid - low) / (high - low)
  let mut lo = low
  let mut hi = high
  if u > c {
    u = 1.0 - u
    c = 1.0 - c
    lo = high
    hi = low
  }
  lo + (hi - lo) * (u * c).sqrt()
}

///|
/// A Poisson draw with mean `mu`: multiplication for small means, and the
/// transformed-rejection method with a squeeze for large ones, so that a mean
/// of a million costs the same as a mean of a hundred.
pub fn[R : @contract.Rng] poisson(r : R, mu : Double) -> Int64 {
  if mu < 0.0 {
    abort("poisson: mu must not be negative")
  }
  if mu == 0.0 {
    return 0L
  }
  if mu < 30.0 {
    let limit = @math.exp(-mu)
    let mut p = 1.0
    let mut k = 0L
    while true {
      p = p * random(r)
      if p <= limit {
        return k
      }
      k = k + 1L
    }
  }
  let slam = (mu - 0.5).sqrt()
  let loglam = @math.ln(mu)
  let b = 0.931 + 2.53 * slam
  let a = -0.059 + 0.02483 * b
  let invalpha = 1.1239 + 1.1328 / (b - 3.4)
  let vr = 0.9277 - 3.6224 / (b - 2.0)
  while true {
    let u = random(r) - 0.5
    let v = random(r)
    let us = 0.5 - (if u < 0.0 { -u } else { u })
    let k = ((2.0 * a / us + b) * u + mu + 0.43).floor()
    if us >= 0.07 && v <= vr {
      return k.to_int64()
    }
    if k < 0.0 || (us < 0.013 && v > us) {
      continue
    }
    if @math.ln(v) + @math.ln(invalpha) - @math.ln(a / (us * us) + b) <=
      -mu + k * loglam - log_factorial(k) {
      return k.to_int64()
    }
  }
  abort("poisson: unreachable")
}

///|
/// log(k!) by the Stirling series, accurate to well under a float bit for the
/// range a Poisson mean can reach.
fn log_factorial(k : Double) -> Double {
  if k < 2.0 {
    0.0
  } else {
    let x = k + 1.0
    (x - 0.5) * @math.ln(x) -
    x +
    0.5 * @math.ln(2.0 * @math.PI) +
    1.0 / (12.0 * x) -
    1.0 / (360.0 * x * x * x)
  }
}

///|
/// The number of successes in `n` trials with success probability `p`, by
/// inverting the binomial CDF term by term: exact for any `n`, and linear in
/// the number of successes drawn.
pub fn[R : @contract.Rng] binomialvariate(
  r : R,
  n : Int64,
  p : Double,
) -> Int64 {
  if p < 0.0 || p > 1.0 || n < 0L {
    abort("binomialvariate: p in [0, 1] and n not negative")
  }
  if p == 0.0 || n == 0L {
    return 0L
  }
  if p == 1.0 {
    return n
  }
  let q = 1.0 - p
  let ratio = p / q
  let nn = n.to_double()
  let mut term = @math.pow(q, nn)
  let mut u = random(r)
  let mut k = 0L
  while k < n {
    if u < term {
      return k
    }
    u = u - term
    k = k + 1L
    term = term * (nn - k.to_double() + 1.0) * ratio / k.to_double()
  }
  k
}
