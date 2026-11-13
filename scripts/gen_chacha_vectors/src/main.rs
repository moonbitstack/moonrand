// Writes the reference outputs for `src/chacha/vectors_test.mbt`.
//
// The RFC 8439 vectors pin the twenty-round cipher; they say nothing about
// eight or twelve rounds, which is what this library's default is made of. The
// reference for those is the `rand_chacha` crate, the widely used Rust
// implementation of the same cipher at any round count, so the numbers below
// are its own: same key, same nonce, same counter, same words.
//
//     cargo run --release
//
// The seed is the key, little-endian, which is how both sides read it.
use rand_chacha::{ChaCha12Rng, ChaCha20Rng, ChaCha8Rng};
use rand_core::{RngCore, SeedableRng};

fn seed() -> [u8; 32] {
    let mut s = [0u8; 32];
    for i in 0..32 {
        s[i] = i as u8;
    }
    s
}

fn dump(name: &str, mut words: Vec<u64>) {
    println!("// {name}");
    let mut line = String::new();
    for (i, w) in words.drain(..).enumerate() {
        if i % 4 == 0 {
            if i > 0 {
                println!("{line}");
            }
            line = String::from("  ");
        }
        line.push_str(&format!("0x{:016X}UL, ", w));
    }
    if !line.trim().is_empty() {
        println!("{line}");
    }
    println!();
}

fn main() {
    // The first eight words, straight off the start of the stream.
    let mut r8 = ChaCha8Rng::from_seed(seed());
    dump("chacha8", (0..8).map(|_| r8.next_u64()).collect());
    let mut r12 = ChaCha12Rng::from_seed(seed());
    dump("chacha12", (0..8).map(|_| r12.next_u64()).collect());
    let mut r20 = ChaCha20Rng::from_seed(seed());
    dump("chacha20", (0..8).map(|_| r20.next_u64()).collect());

    // The same eight words, after a hundred blocks of the keystream: the
    // counter is a word position, and a block is sixteen words.
    let mut r12b = ChaCha12Rng::from_seed(seed());
    r12b.set_word_pos(1600);
    dump("chacha12 at word 1600", (0..4).map(|_| r12b.next_u64()).collect());
    let mut r8b = ChaCha8Rng::from_seed(seed());
    r8b.set_word_pos(1600);
    dump("chacha8 at word 1600", (0..4).map(|_| r8b.next_u64()).collect());

    // A non-zero nonce, three words of it, which is RFC 8439's layout.
    let mut r12c = ChaCha12Rng::from_seed(seed());
    r12c.set_stream(0x03020100_0f0e0d0c);
    dump("chacha12 with stream 030201000f0e0d0c", (0..4).map(|_| r12c.next_u64()).collect());
}
