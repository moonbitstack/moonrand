///|
/// Reference outputs for this package, written by `scripts/gen_vectors.go`.
/// Each value is the state a generator starts from or the words it produced;
/// the tests replay them and expect the same words.
let philox4x32_zero : Array[UInt64] = [
  0x000000006627E8D5UL, 0x00000000E169C58DUL, 0x00000000BC57AC4CUL, 0x000000009B00DBD8UL,
  0x00000000F8E4CCA4UL, 0x000000005CB200DBUL, 0x00000000B1A574EBUL, 0x00000000097EFF67UL,
]

///|
let philox4x64_zero : Array[UInt64] = [
  0x16554D9ECA36314CUL, 0xDB20FE9D672D0FDCUL, 0xD7E772CEE186176BUL, 0x7E68B68AEC7BA23BUL,
  0x02F4BA6408E4D89BUL, 0x3DD62B0B9CA8C5B2UL, 0x1C8667A55D902E79UL, 0x907D7A052FD5B4DCUL,
]
