///|
/// Sampling and distributions over any `Rng`. Names follow Python's `random`
/// where they overlap, but the receiver is always the generator `r`.
fn bit_length(n : Int64) -> Int32 {
  let mut b = 0
  let mut v = n
  while v > 0 {
    v = v >> 1
    b = b + 1
  }
  b
}

// One uniform index in `[0, range)`, unbiased by rejection. `range` is 1 or more.

///|
fn[R : @contract.Rng] uniform_index(r : R, range : Int64) -> Int64 {
  if range <= 1 {
    return 0
  }
  let needed = bit_length(range - 1)
  let mask : UInt64 = (1UL << needed) - 1UL
  let range_u = range.reinterpret_as_uint64()
  let mut x = r.next_u64() & mask
  while x >= range_u {
    x = r.next_u64() & mask
  }
  x.reinterpret_as_int64()
}

///|
/// A uniform `Double` in `[0, 1)`, with 53 bits of resolution, as Python's
/// `random.random` draws it.
pub fn[R : @contract.Rng] random(r : R) -> Double {
  (r.next_u64() >> 11).to_double() / 9007199254740992.0
}

///|
/// A uniform `Double` in `[a, b)`.
pub fn[R : @contract.Rng] uniform(r : R, a : Double, b : Double) -> Double {
  a + (b - a) * random(r)
}

///|
/// A uniform integer in the closed interval `[lo, hi]`, unbiased.
pub fn[R : @contract.Rng] randint(r : R, lo : Int64, hi : Int64) -> Int64 {
  if hi < lo {
    return lo
  }
  uniform_index(r, hi - lo + 1) + lo
}

///|
/// A uniform integer from `range(start, stop, step)`, as Python's `randrange`.
/// `stop` is required; `start` defaults to 0 and `step` to 1.
pub fn[R : @contract.Rng] randrange(
  r : R,
  stop : Int64,
  start~ : Int64 = 0,
  step? : Int64,
) -> Int64 {
  let step = match step {
    Some(s) => s
    None => 1
  }
  if step == 0 {
    abort("randrange: step is zero")
  }
  let span = stop - start
  let count : Int64 = if step > 0 {
    if span <= 0 {
      0
    } else {
      (span + step - 1) / step
    }
  } else if span >= 0 {
    0
  } else {
    (-span - step - 1) / -step
  }
  if count <= 0 {
    abort("randrange: empty range")
  }
  start + uniform_index(r, count) * step
}

///|
/// `k` low bits of the next word; `k` over 64 returns the whole word.
pub fn[R : @contract.Rng] getrandbits(r : R, k : Int32) -> UInt64 {
  let x = r.next_u64()
  if k <= 0 {
    return 0
  } else if k >= 64 {
    return x
  } else {
    x & ((1UL << k) - 1UL)
  }
}

///|
/// One element, or `None` for an empty view.
pub fn[R : @contract.Rng, T] choice(r : R, items : ArrayView[T]) -> T? {
  let n = items.length()
  if n == 0 {
    return None
  }
  Some(items[uniform_index(r, n.to_int64()).to_int()])
}

///|
/// `k` elements with replacement; with `weights` they are drawn proportionally.
pub fn[R : @contract.Rng, T] choices(
  r : R,
  items : ArrayView[T],
  k~ : Int32 = 1,
  weights? : ArrayView[Double],
) -> Array[T] {
  let n = items.length()
  let out : Array[T] = []
  if k <= 0 || n == 0 {
    return out
  }
  match weights {
    None =>
      for _i = 0; _i < k; _i = _i + 1 {
        out.push(items[uniform_index(r, n.to_int64()).to_int()])
      }
    Some(w) => {
      let cum = FixedArray::make(n, 0.0)
      let mut total = 0.0
      for i = 0; i < n; i = i + 1 {
        total = total + w[i]
        cum[i] = total
      }
      if total <= 0.0 {
        for _i = 0; _i < k; _i = _i + 1 {
          out.push(items[uniform_index(r, n.to_int64()).to_int()])
        }
      } else {
        for _i = 0; _i < k; _i = _i + 1 {
          let u = random(r) * total
          let mut lo = 0
          let mut hi = n
          while lo < hi {
            let mid = (lo + hi) / 2
            if cum[mid] < u {
              lo = mid + 1
            } else {
              hi = mid
            }
          }
          out.push(items[if lo >= n { n - 1 } else { lo }])
        }
      }
    }
  }
  out
}

///|
/// `k` distinct elements, by a Fisher-Yates partial shuffle.
pub fn[R : @contract.Rng, T] sample(
  r : R,
  items : ArrayView[T],
  k : Int32,
) -> Array[T] {
  let n = items.length()
  let kk = if k < 0 { 0 } else if k > n { n } else { k }
  let a = items.to_owned()
  for i = 0; i < kk; i = i + 1 {
    let j = i + uniform_index(r, (n - i).to_int64()).to_int()
    let t = a[i]
    a[i] = a[j]
    a[j] = t
  }
  a[0:kk].to_owned()
}

///|
/// Shuffle `a` in place, Fisher-Yates.
pub fn[R : @contract.Rng, T] shuffle(r : R, a : Array[T]) -> Unit {
  let n = a.length()
  for i = n - 1; i > 0; i = i - 1 {
    let j = uniform_index(r, (i + 1).to_int64()).to_int()
    let t = a[i]
    a[i] = a[j]
    a[j] = t
  }
}

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
