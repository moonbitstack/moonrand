/// The generator contract lives in the `contract` subpackage so the root
/// package and the algorithm subpackages can both use it without a circular
/// import. To name the traits, import `@moonrand/contract` (`Rng`, `Secure`,
/// `Seeded`); the root package adds the convenience names below.
///
/// The default generator is ChaCha12 (see `StdRng`). Two ways in: `seeded` is
/// pure and reproduces a stream from a seed you supply; `from_entropy` asks the
/// platform through moonseed for a seed that no one can predict or replay.
/// Everything else in the library is pure, so a seeded run repeats exactly.

///|
/// The default generator: ChaCha12. Change this one line to change the whole
/// library's default algorithm.
pub type StdRng = @chacha.ChaCha12

///|
/// A `StdRng` seeded from `seed`, reproducible for the same seed.
pub fn seeded(seed : BytesView) -> StdRng {
  @chacha.ChaCha12::new(seed)
}

///|
/// A `StdRng` seeded from the platform's entropy: 32 bytes asked of
/// `@system.source` through moonseed.
///
/// This is the only place the library touches the platform. It fails with
/// `@moonseed.Unavailable` when there is no entropy source or it fails; there
/// is no fallback to a fixed or clock-derived seed, because a silent fallback
/// would hand out a generator that looks random and is not.
pub fn from_entropy() -> StdRng raise @moonseed.Unavailable {
  @chacha.ChaCha12::new(@moonseed.bytes(32, @system.source)[0:])
}
