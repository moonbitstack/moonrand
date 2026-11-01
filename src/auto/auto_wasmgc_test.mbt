///|
/// Fails with whatever `@auto.rng` raised, so a test can look at the error
/// without building a generator it does not want.
fn draw_once() -> Unit raise @moonseed.Unavailable {
  ignore(@auto.rng())
}

///|
/// The wasm-gc test host provides no `random_get`, so `rng` fails closed there
/// rather than handing out a generator over a guessed seed.
test "without a platform source rng reports Unavailable, not a generator" {
  let mut seen = false
  draw_once() catch {
    err => {
      assert_eq(err, @moonseed.Unavailable::Platform)
      seen = true
    }
  }
  assert_true(seen)
}
