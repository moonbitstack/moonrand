///|
/// Reference outputs for this package, written by `scripts/gen_vectors.go`.
/// Each value is the state a generator starts from or the words it produced;
/// the tests replay them and expect the same words.
let sfc64_state : Array[UInt64] = [
  0x910A2DEC89025CC1UL, 0xBEEB8DA1658EEC67UL, 0xF893A2EEFB32555EUL,
]

///|
let sfc64_first : Array[UInt64] = [
  0x48895E7CE9C39E87UL, 0xB3B19C09F023903CUL, 0x36CB8C124B187149UL, 0x1C74638A8BE15827UL,
  0x036DC336D6938E10UL, 0x64C58CC28A3978B9UL, 0x0A52485768A56713UL, 0x69AD212B508C04DCUL,
]
