// Writes the reference outputs that the subpackage tests replay.
//
// Each algorithm here is the published one: the transitions, the output
// functions and the jump polynomials are the authors' own, and the seeding is
// the one their reference code suggests (a SplitMix64 counter, or the reference
// init function where there is one). The generators themselves live in
// `src/<package>/`; this file exists so the expected numbers come from a second
// implementation, not from the one under test.
//
//	go run scripts/gen_vectors.go            every package
//	go run scripts/gen_vectors.go xoshiro    one package
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

const (
	golden = uint64(0x9e3779b97f4a7c15)
	mixA   = uint64(0xbf58476d1ce4e5b9)
	mixB   = uint64(0x94d049bb133111eb)
)

func rotl(x uint64, k uint) uint64 { return x<<k | x>>(64-k) }

func rotl32(x uint32, k uint) uint32 { return x<<k | x>>(32-k) }

func mix64(z uint64) uint64 {
	z = (z ^ (z >> 30)) * mixA
	z = (z ^ (z >> 27)) * mixB
	return z ^ (z >> 31)
}

// splitmix is the reference SplitMix64, the seeding generator the xoshiro
// family's own reference code recommends.
type splitmix struct{ x uint64 }

func newSplitmix(seed uint64) *splitmix { return &splitmix{x: seed} }

func (s *splitmix) Next() uint64 {
	s.x += golden
	return mix64(s.x)
}

// seedWords fills n words the way the reference suggests: a SplitMix64 seeded
// with `seed`, its outputs taken in order.
func seedWords(seed uint64, n int) []uint64 {
	sm := newSplitmix(seed)
	out := make([]uint64, n)
	for i := range out {
		out[i] = sm.Next()
	}
	return out
}

type case_ struct {
	pkg   string
	name  string
	words []uint64
}

var cases []case_

func add(pkg, name string, words []uint64) {
	cases = append(cases, case_{pkg: pkg, name: name, words: words})
}

func main() {
	want := ""
	if len(os.Args) > 1 {
		want = os.Args[1]
	}

	xoshiroVectors()
	splitmixVectors()
	mtVectors()

	byPkg := map[string][]case_{}
	order := []string{}
	for _, c := range cases {
		if _, seen := byPkg[c.pkg]; !seen {
			order = append(order, c.pkg)
		}
		byPkg[c.pkg] = append(byPkg[c.pkg], c)
	}
	if want != "" && len(byPkg[want]) == 0 {
		fmt.Fprintf(os.Stderr, "no vectors for %q\n", want)
		os.Exit(1)
	}
	for _, pkg := range order {
		if want != "" && pkg != want {
			continue
		}
		write(pkg, byPkg[pkg])
	}
}

func write(pkg string, cs []case_) {
	var b strings.Builder
	b.WriteString("///|\n")
	b.WriteString("/// Reference outputs for this package, written by `scripts/gen_vectors.go`.\n")
	b.WriteString("/// Each value is the state a generator starts from or the words it produced;\n")
	b.WriteString("/// the tests replay them and expect the same words.\n")
	for _, c := range cs {
		fmt.Fprintf(&b, "let %s : Array[UInt64] = [", c.name)
		for i, w := range c.words {
			if i%4 == 0 {
				b.WriteString("\n  ")
			}
			fmt.Fprintf(&b, "0x%016XUL, ", w)
		}
		b.WriteString("\n]\n\n")
	}
	path := filepath.Join("src", pkg, "vectors_test.mbt")
	if err := os.WriteFile(path, []byte(b.String()), 0o644); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	fmt.Printf("wrote %s (%d cases)\n", path, len(cs))
}

// jumpByPoly applies a jump polynomial: accumulate where the polynomial has a
// set bit, one step per bit, and take the accumulation as the new state.
func jumpByPoly(state, poly []uint64, step func([]uint64)) []uint64 {
	acc := make([]uint64, len(state))
	for _, w := range poly {
		for b := 0; b < 64; b++ {
			if w&(uint64(1)<<uint(b)) != 0 {
				for i := range state {
					acc[i] ^= state[i]
				}
			}
			step(state)
		}
	}
	return acc
}

// ---------------------------------------------------------------------------
// xoshiro
// ---------------------------------------------------------------------------

func step256(s []uint64) {
	t := s[1] << 17
	s[2] ^= s[0]
	s[3] ^= s[1]
	s[1] ^= s[2]
	s[0] ^= s[3]
	s[2] ^= t
	s[3] = rotl(s[3], 45)
}

func step512(s []uint64) {
	t := s[1] << 11
	s[2] ^= s[0]
	s[5] ^= s[1]
	s[1] ^= s[2]
	s[7] ^= s[3]
	s[3] ^= s[4]
	s[4] ^= s[5]
	s[0] ^= s[6]
	s[6] ^= s[7]
	s[6] ^= t
	s[7] = rotl(s[7], 21)
}

func stepXoro24(s []uint64) {
	s0 := s[0]
	s1 := s[1] ^ s0
	s[0] = rotl(s0, 24) ^ s1 ^ (s1 << 16)
	s[1] = rotl(s1, 37)
}

func stepXoro49(s []uint64) {
	s0 := s[0]
	s1 := s[1] ^ s0
	s[0] = rotl(s0, 49) ^ s1 ^ (s1 << 21)
	s[1] = rotl(s1, 28)
}

var (
	poly256Jump = []uint64{0x180ec6d33cfd0aba, 0xd5a61266f0c9392c, 0xa9582618e03fc9aa, 0x39abdc4529b1661c}
	poly256Long = []uint64{0x76e15d3efefdcbbf, 0xc5004e441c522fb3, 0x77710069854ee241, 0x39109bb02acbe635}
	poly512Jump = []uint64{
		0x33ed89b6e7a353f9, 0x760083d7955323be, 0x2837f2fbb5f22fae, 0x4b8c5674d309511c,
		0xb11ac47a7ba28c25, 0xf1be7667092bcc1c, 0x53851efdb6df0aaf, 0x1ebbc8b23eaf25db,
	}
	poly512Long = []uint64{
		0x11467fef8f921d28, 0xa2a819f2e79c8ea8, 0xa8299fc284b3959a, 0xb4d347340ca63ee1,
		0x1cb0940bedbff6ce, 0xd956c5c4fa1f8e17, 0x915e38fd4eda93bc, 0x5b3ccdfa5d7daca5,
	}
	polyXoroJump   = []uint64{0xdf900294d8f554a5, 0x170865df4b3201fc}
	polyXoroLong   = []uint64{0xd2a98b26625eee7b, 0xdddf9b1090aa7ac1}
	polyXoroPpJump = []uint64{0x2bd7a6a6e99c2ddc, 0x0992ccaf6a6fca05}
	polyXoroPpLong = []uint64{0x360fd5f2cf8d5d99, 0x9c6e6877736c46e3}
)

type xoshiroKind struct {
	name       string
	size       int
	out        func([]uint64) uint64
	step       func([]uint64)
	jump, long []uint64
}

func xoshiroVectors() {
	kinds := []xoshiroKind{
		{"Xoshiro256ss", 4, func(s []uint64) uint64 {
			r := rotl(s[1]*5, 7) * 9
			step256(s)
			return r
		}, step256, poly256Jump, poly256Long},
		{"Xoshiro256pp", 4, func(s []uint64) uint64 {
			r := rotl(s[0]+s[3], 23) + s[0]
			step256(s)
			return r
		}, step256, poly256Jump, poly256Long},
		{"Xoshiro256p", 4, func(s []uint64) uint64 {
			r := s[0] + s[3]
			step256(s)
			return r
		}, step256, poly256Jump, poly256Long},
		{"Xoshiro512ss", 8, func(s []uint64) uint64 {
			r := rotl(s[1]*5, 7) * 9
			step512(s)
			return r
		}, step512, poly512Jump, poly512Long},
		{"Xoshiro512pp", 8, func(s []uint64) uint64 {
			r := rotl(s[0]+s[2], 17) + s[2]
			step512(s)
			return r
		}, step512, poly512Jump, poly512Long},
		{"Xoshiro512p", 8, func(s []uint64) uint64 {
			r := s[0] + s[2]
			step512(s)
			return r
		}, step512, poly512Jump, poly512Long},
		{"Xoroshiro128p", 2, func(s []uint64) uint64 {
			r := s[0] + s[1]
			stepXoro24(s)
			return r
		}, stepXoro24, polyXoroJump, polyXoroLong},
		{"Xoroshiro128pp", 2, func(s []uint64) uint64 {
			r := rotl(s[0]+s[1], 17) + s[0]
			stepXoro49(s)
			return r
		}, stepXoro49, polyXoroPpJump, polyXoroPpLong},
		{"Xoroshiro128ss", 2, func(s []uint64) uint64 {
			r := rotl(s[0]*5, 7) * 9
			stepXoro24(s)
			return r
		}, stepXoro24, polyXoroJump, polyXoroLong},
	}
	for _, k := range kinds {
		lower := strings.ToLower(k.name)
		state := seedWords(1, k.size)
		add("xoshiro", lower+"_state", state)

		run := append([]uint64(nil), state...)
		first := make([]uint64, 0, 8)
		for i := 0; i < 8; i++ {
			first = append(first, k.out(run))
		}
		add("xoshiro", lower+"_first", first)

		jumped := jumpByPoly(append([]uint64(nil), state...), k.jump, k.step)
		words := make([]uint64, 0, 4)
		for i := 0; i < 4; i++ {
			words = append(words, k.out(jumped))
		}
		add("xoshiro", lower+"_jump", words)

		longed := jumpByPoly(append([]uint64(nil), state...), k.long, k.step)
		words = make([]uint64, 0, 4)
		for i := 0; i < 4; i++ {
			words = append(words, k.out(longed))
		}
		add("xoshiro", lower+"_long_jump", words)
	}
}

// ---------------------------------------------------------------------------
// splitmix
// ---------------------------------------------------------------------------

func splitmixVectors() {
	sm := newSplitmix(0)
	words := make([]uint64, 0, 8)
	for i := 0; i < 8; i++ {
		words = append(words, sm.Next())
	}
	add("splitmix", "splitmix64_seed0", words)
}

// ---------------------------------------------------------------------------
// mt
// ---------------------------------------------------------------------------

type mt32 struct{ s [624]uint32; i int }

func newMT32(seed uint32) *mt32 {
	g := &mt32{i: 624}
	g.s[0] = seed
	for i := 1; i < 624; i++ {
		g.s[i] = 1812433253*(g.s[i-1]^(g.s[i-1]>>30)) + uint32(i)
	}
	return g
}

func (g *mt32) twist() {
	for i := 0; i < 624; i++ {
		y := (g.s[i] & 0x80000000) | (g.s[(i+1)%624] & 0x7fffffff)
		g.s[i] = g.s[(i+397)%624] ^ (y >> 1)
		if y&1 != 0 {
			g.s[i] ^= 0x9908b0df
		}
	}
	g.i = 0
}

func (g *mt32) word() uint32 {
	if g.i >= 624 {
		g.twist()
	}
	y := g.s[g.i]
	g.i++
	y ^= y >> 11
	y ^= (y << 7) & 0x9d2c5680
	y ^= (y << 15) & 0xefc60000
	return y ^ (y >> 18)
}

func mt32ByArray(keys []uint32) *mt32 {
	g := newMT32(19650218)
	n := len(keys)
	i, j := 1, 0
	k := 624
	if n > k {
		k = n
	}
	for ; k > 0; k-- {
		g.s[i] = (g.s[i] ^ ((g.s[i-1] ^ (g.s[i-1] >> 30)) * 1664525)) + keys[j] + uint32(j)
		i++
		j++
		if i >= 624 {
			g.s[0] = g.s[623]
			i = 1
		}
		if j >= n {
			j = 0
		}
	}
	for k = 623; k > 0; k-- {
		g.s[i] = (g.s[i] ^ ((g.s[i-1] ^ (g.s[i-1] >> 30)) * 1566083941)) - uint32(i)
		i++
		if i >= 624 {
			g.s[0] = g.s[623]
			i = 1
		}
	}
	g.s[0] = 0x80000000
	return g
}

type mt64 struct{ s [312]uint64; i int }

func newMT64(seed uint64) *mt64 {
	g := &mt64{i: 312}
	g.s[0] = seed
	for i := 1; i < 312; i++ {
		g.s[i] = 6364136223846793005*(g.s[i-1]^(g.s[i-1]>>62)) + uint64(i)
	}
	return g
}

func (g *mt64) twist() {
	for i := 0; i < 312; i++ {
		y := (g.s[i] & 0xffffffff80000000) | (g.s[(i+1)%312] & 0x7fffffff)
		g.s[i] = g.s[(i+156)%312] ^ (y >> 1)
		if y&1 != 0 {
			g.s[i] ^= 0xb5026f5aa96619e9
		}
	}
	g.i = 0
}

func (g *mt64) word() uint64 {
	if g.i >= 312 {
		g.twist()
	}
	x := g.s[g.i]
	g.i++
	x ^= (x >> 29) & 0x5555555555555555
	x ^= (x << 17) & 0x71d67fffeda60000
	x ^= (x << 37) & 0xfff7eee000000000
	return x ^ (x >> 43)
}

func mt64ByArray(keys []uint64) *mt64 {
	g := newMT64(19650218)
	n := len(keys)
	i, j := 1, 0
	k := 312
	if n > k {
		k = n
	}
	for ; k > 0; k-- {
		g.s[i] = (g.s[i] ^ ((g.s[i-1] ^ (g.s[i-1] >> 62)) * 3935559000370003845)) + keys[j] + uint64(j)
		i++
		j++
		if i >= 312 {
			g.s[0] = g.s[311]
			i = 1
		}
		if j >= n {
			j = 0
		}
	}
	for k = 311; k > 0; k-- {
		g.s[i] = (g.s[i] ^ ((g.s[i-1] ^ (g.s[i-1] >> 62)) * 2862933555777941757)) - uint64(i)
		i++
		if i >= 312 {
			g.s[0] = g.s[311]
			i = 1
		}
	}
	g.s[0] = 1 << 63
	return g
}

func mtVectors() {
	g := newMT32(5489)
	w := make([]uint64, 0, 8)
	for i := 0; i < 8; i++ {
		w = append(w, uint64(g.word()))
	}
	add("mt", "mt19937_init5489", w)

	g = mt32ByArray([]uint32{0x123, 0x234, 0x345, 0x456})
	w = make([]uint64, 0, 8)
	for i := 0; i < 8; i++ {
		w = append(w, uint64(g.word()))
	}
	add("mt", "mt19937_by_array", w)

	h := newMT64(5489)
	w = make([]uint64, 0, 6)
	for i := 0; i < 6; i++ {
		w = append(w, h.word())
	}
	add("mt", "mt19937_64_init5489", w)

	h = mt64ByArray([]uint64{0x123, 0x234, 0x345, 0x456})
	w = make([]uint64, 0, 6)
	for i := 0; i < 6; i++ {
		w = append(w, h.word())
	}
	add("mt", "mt19937_64_by_array", w)
}
