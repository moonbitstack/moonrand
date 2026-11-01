///|
/// Logistic: x := r x (1 - x).
pub struct Logistic {
  priv s : FixedArray[Double]
}

///|
/// A generator with the parameter `r` and the starting `x`.
pub fn Logistic::with_params(r : Double, x : Double) -> Logistic {
  ignore((r, x))
  { s: FixedArray::make(2, 0.0), }
}

///|
/// A generator seeded from a byte seed.
pub fn Logistic::new(seed : BytesView) -> Logistic {
  ignore(seed)
  { s: FixedArray::make(2, 0.0), }
}

///|
pub impl @contract.Rng for Logistic with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Logistic: no implementation yet")
}

///|
/// Tent: the tent map, with the slope `mu`.
pub struct Tent {
  priv s : FixedArray[Double]
}

///|
/// A generator with the parameter `mu` and the starting `x`.
pub fn Tent::with_params(mu : Double, x : Double) -> Tent {
  ignore((mu, x))
  { s: FixedArray::make(2, 0.0), }
}

///|
/// A generator seeded from a byte seed.
pub fn Tent::new(seed : BytesView) -> Tent {
  ignore(seed)
  { s: FixedArray::make(2, 0.0), }
}

///|
pub impl @contract.Rng for Tent with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Tent: no implementation yet")
}

///|
/// Sine: x := sin(pi x).
pub struct Sine {
  priv s : FixedArray[Double]
}

///|
/// A generator over the starting `x` in (0, 1).
pub fn Sine::with_state(x : Double) -> Sine {
  ignore(x)
  { s: FixedArray::make(1, 0.0), }
}

///|
/// A generator seeded from a byte seed.
pub fn Sine::new(seed : BytesView) -> Sine {
  ignore(seed)
  { s: FixedArray::make(1, 0.0), }
}

///|
pub impl @contract.Rng for Sine with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Sine: no implementation yet")
}

///|
/// Chebyshev: x := cos(n acos(x)).
pub struct Chebyshev {
  priv s : FixedArray[Double]
}

///|
/// A generator with the degree `n` and the starting `x` in (-1, 1).
pub fn Chebyshev::with_params(n : Double, x : Double) -> Chebyshev {
  ignore((n, x))
  { s: FixedArray::make(2, 0.0), }
}

///|
/// A generator seeded from a byte seed.
pub fn Chebyshev::new(seed : BytesView) -> Chebyshev {
  ignore(seed)
  { s: FixedArray::make(2, 0.0), }
}

///|
pub impl @contract.Rng for Chebyshev with fn next_u64(self) -> UInt64 {
  ignore(self.s)
  abort("Chebyshev: no implementation yet")
}

///|
pub impl @contract.Seeded for Logistic with fn from_seed(seed : BytesView) -> Logistic {
  Logistic::new(seed)
}

///|
pub impl @contract.Seeded for Logistic with fn seed_size() -> Int32 {
  8
}

///|
pub impl @contract.Seeded for Tent with fn from_seed(seed : BytesView) -> Tent {
  Tent::new(seed)
}

///|
pub impl @contract.Seeded for Tent with fn seed_size() -> Int32 {
  8
}

///|
pub impl @contract.Seeded for Sine with fn from_seed(seed : BytesView) -> Sine {
  Sine::new(seed)
}

///|
pub impl @contract.Seeded for Sine with fn seed_size() -> Int32 {
  8
}

///|
pub impl @contract.Seeded for Chebyshev with fn from_seed(seed : BytesView) -> Chebyshev {
  Chebyshev::new(seed)
}

///|
pub impl @contract.Seeded for Chebyshev with fn seed_size() -> Int32 {
  8
}

///|
pub extend Logistic with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Logistic with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Tent with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Tent with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Sine with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Sine with @contract.Seeded::{from_seed, seed_size}

///|
pub extend Chebyshev with @contract.Rng::{next_u64, next_u32, fill}

///|
pub extend Chebyshev with @contract.Seeded::{from_seed, seed_size}
