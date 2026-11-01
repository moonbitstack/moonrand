/// The generator contract lives in the `contract` subpackage so the root
/// package and the algorithm subpackages can both use it without a circular
/// import. To name the traits, import `@moonrand/contract` (`Rng`, `Secure`,
/// `Seeded`); the root package adds the convenience names below.
///
/// The default generator is ChaCha12 (see `StdRng`). Two ways in: `seeded` is
/// pure and reproduces a stream from a seed you supply; `@auto.rng()` asks the
/// platform through moonseed for a seed no one can predict or replay.
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
