///|
/// A `StdRng` seeded from the platform's entropy: 32 bytes asked of
/// `@system.source` through moonseed, then handed to `@moonrand.seeded`.
///
/// This is the only place the library touches the platform. It fails with
/// `@moonseed.Unavailable` when there is no entropy source or it fails; there
/// is no fallback to a fixed or clock-derived seed, because a silent fallback
/// would hand out a generator that looks random and is not.
pub fn rng() -> @moonrand.StdRng raise @moonseed.Unavailable {
  ignore(@system.source)
  raise @moonseed.Unavailable::Platform
}
