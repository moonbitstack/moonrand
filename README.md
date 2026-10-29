# moonrand

Secure random bytes, and numbers drawn from them without bias, over any entropy
source the caller supplies.

```moonbit
test "draw" {
  let key = @moonrand.bytes(32, @system.source) // 32 uniform bytes
  let n = @moonrand.below(b"\x03\xe8", @system.source) // uniform in [0, 1000)
  let d = @moonrand.scalar(b"\x05", @system.source) // uniform in [1, 4]
  ignore((key, n, d))
}
```

`moon run src/examples/tour` shows all of it in one run.

## Packages

| Package | What it holds | Depends on |
|:--:|:--|:--|
| `moonrand` | `Source`, `Unavailable`, `bytes`, `below`, `scalar`, `Replay` | nothing |
| `moonrand/system` | `source`, the platform's entropy | core `env` |

The root package touches no platform. Linking `system` links the platform's call,
which on wasm is the WASI `random_get` import; a program for a wasm host without
WASI uses the root package with a source of its own.

## Sources

| Source | Where the bytes come from |
|:--:|:--|
| `@system.source` | `crypto.getRandomValues` on JavaScript, WASI `random_get` on wasm and wasm-gc, the runtime on native |
| `Replay::new(bytes)` | the bytes given, in order; exhausted after |
| your own | anything that implements `Source` |

```moonbit
struct Device {}

impl @moonrand.Source for Device with fn fill(_self, _buf) {
  raise Failed("the device is unplugged")
}
```

No source falls back to a seeded generator. When there are no bytes to be had,
the call raises `Unavailable`: `Platform` from the platform source, `Exhausted`
from a replay, `Failed(reason)` from a source of your own.

## Sampling

`below(bound, source)` reads `bound` as a big-endian number and returns one in
[0, `bound`), as wide as `bound`. It draws only as many bits as `bound` has and
draws again when the value lands at or above it, so every value is equally
likely; reducing a wider draw modulo `bound` would favour the small ones.

`scalar(order, source)` returns a value in [1, `order` - 1], as wide as `order`:
a private key or a nonce for a group of that order. A P-521 scalar is 66 bytes
with the top bits clear, which is why this is not "ask for 32 bytes".

## Licence

Apache-2.0.
