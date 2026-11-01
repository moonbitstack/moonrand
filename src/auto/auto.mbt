///|
/// A `StdRng` seeded from the platform's entropy: 32 bytes asked of
/// `@system.source` through moonseed, then handed to `@moonrand.seeded`.
///
/// This is the only place the library touches the platform. It fails with
/// `@moonseed.Unavailable` when there is no entropy source or when reading it
/// fails; there is no fallback to a fixed or clock-derived seed, because a
/// silent fallback would hand out a generator that looks random and is not.
///
/// ```mbt check
/// test {
///   let r = @auto.rng() catch { _ => return }
///   let x = @moonrand.random(r)
///   assert_true(x >= 0.0 && x < 1.0)
/// }
/// ```
pub fn rng() -> @moonrand.StdRng raise @moonseed.Unavailable {
  @moonrand.seeded(@moonseed.bytes(32, @system.source)[0:])
}
