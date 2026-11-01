///|
/// Reference outputs for this package, written by `scripts/gen_vectors.go`.
/// Each value is the state a generator starts from or the words it produced;
/// the tests replay them and expect the same words.
let mrg32k3a_state : Array[UInt64] = [
  0x00000000F2523AC3UL, 0x0000000043DE0C34UL, 0x00000000EBBAFF67UL, 0x00000000ED0941F2UL,
  0x00000000A6D31D7EUL, 0x0000000014C4A382UL,
]

///|
let mrg32k3a_first : Array[UInt64] = [
  0x000000002C322D0FUL, 0x0000000095452888UL, 0x000000008309104DUL, 0x000000005547E656UL,
  0x00000000F57E45A8UL, 0x00000000A044D08AUL, 0x0000000038ECCDE4UL, 0x00000000160F38BDUL,
]
