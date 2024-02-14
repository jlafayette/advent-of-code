package day05

import "core:fmt"
import "core:math"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"

main :: proc() {
	// freeing memory is not really needed for a program like this, but
	// this is helpful to learn where allocations are happening.
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)

				}
			}
		}

	}
	_main()
}


TEST_INPUT :: `seeds: 79 14 55 13

seed-to-soil map:
50 98 2
52 50 48

soil-to-fertilizer map:
0 15 37
37 52 2
39 0 15

fertilizer-to-water map:
49 53 8
0 11 42
42 0 7
57 7 4

water-to-light map:
88 18 7
18 25 70

light-to-temperature map:
45 77 23
81 45 19
68 64 13

temperature-to-humidity map:
0 69 1
1 0 69

humidity-to-location map:
60 56 37
56 93 4`

split_to_numbers :: proc(s: string) -> (result: [dynamic]int) {
	num_strs := strings.split(s, " ")
	// fmt.println(num_strs)
	defer delete(num_strs)
	for n_str in num_strs {
		v, ok := strconv.parse_int(n_str)
		if ok {
			append(&result, v)
		}
	}
	return
}

Range :: struct {
	dst: int,
	src: int,
	len: int,
}
Map :: struct {
	ranges: [dynamic]Range,
	src:    string,
	dst:    string,
}
map_print :: proc(m: ^Map) {
	b := strings.builder_make()
	defer strings.builder_destroy(&b)
	fmt.sbprint(&b, m.src, "->", m.dst)
	for r in m.ranges {
		fmt.sbprint(&b, "\n ", r)
	}
	fmt.println(strings.to_string(b))
}
map_call :: proc(m: ^Map, value: int) -> int {
	for r in m.ranges {
		if value >= r.src && value < r.src + r.len {
			return r.dst + (value - r.src)
		}
	}
	return value
}
map_init :: proc(m: ^Map, section: string) {
	lines := strings.split_lines(section)
	assert(len(lines) >= 2)
	defer delete(lines)
	title_parts := strings.split(lines[0], " map")
	defer delete(title_parts)
	assert(len(title_parts) == 2)
	src_dst_strs := strings.split(title_parts[0], "-to-")
	defer delete(src_dst_strs)
	assert(len(src_dst_strs) == 2)
	m.src = src_dst_strs[0]
	m.dst = src_dst_strs[1]

	for line in lines[1:] {
		as_nums := split_to_numbers(line)
		defer delete(as_nums)
		assert(len(as_nums) == 3)
		append(&m.ranges, Range{as_nums[0], as_nums[1], as_nums[2]})
	}
}
map_destroy :: proc(m: ^Map) {
	delete(m.ranges)
}
maps_destroy :: proc(maps: [dynamic]Map) {
	ms := maps
	for m in &ms {
		map_destroy(&m)
	}
	delete(maps)
}


part1 :: proc(input: string) -> int {
	lowest_location: int = 9223372036854775807

	sections := strings.split(input, "\n\n")
	// fmt.println("split into", len(sections), "sections")
	defer delete(sections)
	assert(len(sections) > 0)
	// fmt.println("  sections[0]:", sections[0])
	seed_strs := strings.split(sections[0], ": ")
	defer delete(seed_strs)
	assert(len(seed_strs) == 2)
	seeds := split_to_numbers(seed_strs[1])
	defer delete(seeds)
	// fmt.println("seeds:", seeds)
	// for seed in seeds {
	// 	fmt.println(" ", seed)
	// }

	maps: [dynamic]Map
	defer maps_destroy(maps)
	for section in sections[1:] {
		m: Map
		map_init(&m, section)
		append(&maps, m)
	}
	// for m in &maps {
	// 	map_print(&m)
	// }

	for seed in seeds {
		x := seed
		for m in &maps {
			x = map_call(&m, x)
		}
		lowest_location = min(lowest_location, x)
		// fmt.println("lowest:", lowest_location)
	}

	return lowest_location
}

get_breakpoints :: proc(maps: []Map) -> map[int]bool {
	set := make(map[int]bool)
	for m in maps {
		for r in m.ranges {
			set[r.src] = true
			set[r.src + r.len - 1] = true
			set[r.dst] = true
			set[r.dst + r.len - 1] = true
		}
	}
	return set
}

Pair :: [2]int
pairs :: proc(seeds: []int) -> [dynamic]Pair {
	ps := make([dynamic]Pair, len(seeds) / 2, len(seeds) / 2)
	for i := 0; i < len(ps); i += 1 {
		ps[i][0] = seeds[i * 2]
		ps[i][1] = seeds[i * 2 + 1]
	}
	return ps
}

f :: proc(seed: int, maps: []Map) -> int {
	x := seed
	ms := maps
	for m in &ms {
		x = map_call(&m, x)
	}
	return x
}

R :: struct {
	lo: int,
	hi: int,
}
r_continuous :: proc(r: R, breakpoints: map[int]bool, maps: []Map) -> bool {
	if r.lo == r.hi {
		return true
	}
	if r.lo in breakpoints || r.hi in breakpoints {
		return false
	}
	diff := r.hi - r.lo
	return f(r.hi, maps) - f(r.lo, maps) == diff
}
r_break :: proc(r: R) -> [2]R {
	if r.hi == r.lo + 1 {
		return {R{r.lo, r.lo}, R{r.hi, r.hi}}
	}
	diff := r.hi - r.lo
	mid := r.hi - (diff / 2)
	return {R{r.lo, mid}, R{mid + 1, r.hi}}
}
break_all :: proc(r: R, breakpoints: map[int]bool, maps: []Map, acc: ^[dynamic]R) {
	if r_continuous(r, breakpoints, maps) {
		append(acc, r)
		return
	} else {
		rs := r_break(r)
		break_all(rs[0], breakpoints, maps, acc)
		break_all(rs[1], breakpoints, maps, acc)
	}
}
join_all :: proc(rs: []R, breakpoints: map[int]bool, maps: []Map) -> [dynamic]R {
	new_rs: [dynamic]R
	cr := rs[0]
	for next_r in rs[1:] {
		p := R{cr.lo, next_r.hi}
		if r_continuous(p, breakpoints, maps) {
			cr = p
		} else {
			append(&new_rs, cr)
			cr = next_r
		}
	}
	append(&new_rs, cr)
	return new_rs
}

// based on python part2_3 approach
part2 :: proc(input: string) -> int {
	lowest: int = 9223372036854775807
	// sections
	sections := strings.split(input, "\n\n")
	assert(len(sections) > 5)
	defer delete(sections)
	// seeds
	seed_strs := strings.split(sections[0], ": ")
	defer delete(seed_strs)
	assert(len(seed_strs) == 2)
	seeds := split_to_numbers(seed_strs[1])
	defer delete(seeds)
	// fmt.println("seeds:", seeds)
	// maps
	maps: [dynamic]Map
	defer maps_destroy(maps)
	for section in sections[1:] {
		m: Map
		map_init(&m, section)
		append(&maps, m)
	}
	// for m in &maps {
	// 	map_print(&m)
	// }
	breakpoints := get_breakpoints(maps[:])
	defer delete(breakpoints)
	dyn_pairs := pairs(seeds[:])
	defer delete(dyn_pairs)
	for pair in dyn_pairs {
		// no idea why these are named like this... just
		// translating from the pythong solution and it's
		// been too long to remember what I was thinking
		start := pair.x
		len_ := pair.y
		// fmt.println(start, len_)
		lo := start
		hi := start + len_ - 1
		acc: [dynamic]R
		defer delete(acc)
		break_all(R{lo, hi}, breakpoints, maps[:], &acc)
		// fmt.println(acc[:])

		ranges := join_all(acc[:], breakpoints, maps[:])
		defer delete(ranges)
		for r in ranges {
			lowest = min(lowest, f(r.lo, maps[:]))
		}
	}

	return lowest
}


_main :: proc() {
	start_tick := time.tick_now()

	input, ok := os.read_entire_file_from_filename("input")
	defer delete(input)
	assert(ok)
	read_input_tick := time.tick_now()
	read_input_duration := time.tick_diff(start_tick, read_input_tick)

	{
		r := part1(string(TEST_INPUT))
		fmt.println(r)
		assert(r == 35)
	}
	{
		r := part1(string(input))
		fmt.println(r)
		assert(r == 261668924)
	}
	part1_tick := time.tick_now()
	part1_duration := time.tick_diff(start_tick, part1_tick)
	{
		r := part2(TEST_INPUT)
		fmt.println(r)
		assert(r == 46)
	}
	{
		r := part2(string(input))
		fmt.println(r)
		assert(r == 24261545)
	}
	part2_tick := time.tick_now()
	part2_duration := time.tick_diff(part1_tick, part2_tick)
	total_duration := time.tick_diff(start_tick, part2_tick)

	read_input_ms := time.duration_milliseconds(read_input_duration)
	part1_ms := time.duration_milliseconds(part1_duration)
	part2_ms := time.duration_milliseconds(part2_duration)
	total_ms := time.duration_milliseconds(total_duration)

	fmt.printf(" read: %.4f ms\n", read_input_ms)
	fmt.printf("part1: %.4f ms\n", part1_ms)
	fmt.printf("part2: %.4f ms\n", part2_ms)
	fmt.printf("total: %.4f ms\n", total_ms)
}
