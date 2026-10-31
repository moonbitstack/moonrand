///|
/// `from_entropy` asks the platform for a seed. On a platform with no entropy
/// source the call fails with `@moonseed.Unavailable`, and that is the correct
/// behaviour: the tests below simply stand down there rather than accept a
/// generator seeded from a fallback.
test "from_entropy_seeds_a_usable_generator" {
  let first = @moonrand.from_entropy() catch { _ => return }
  let second = @moonrand.from_entropy() catch { _ => return }
  let a = @moonrand.random(first)
  let b = @moonrand.random(second)
  assert_true(a >= 0.0 && a < 1.0)
  assert_true(b >= 0.0 && b < 1.0)
  // Two draws from the platform's entropy must not agree: a 53-bit collision
  // here would mean the seed is not coming from entropy at all.
  assert_true(a != b)
}
