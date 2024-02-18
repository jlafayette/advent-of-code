package day09

import "core:bytes"
import "core:fmt"
import "core:math"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:time"


main :: proc() {
	// freeing memory is not really needed for a cli program like this,
	// but it's helpful to see where allocations are happening.
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

split_to_numbers :: proc(s: []u8, acc: ^[dynamic]int) {
	num_strs := bytes.split(s, {' '})
	defer delete(num_strs)
	for n_str in num_strs {
		v, ok := strconv.parse_int(string(n_str), 10)
		if ok {
			append(acc, v)
		}
	}
}

TEST_INPUT :: `0 3 6 9 12 15
1 3 6 10 15 21
10 13 16 21 30 45`

parse :: proc(data: []u8) -> [dynamic]S {
	result: [dynamic]S
	data2 := data
	for line in bytes.split_iterator(&data2, {'\n'}) {
		// fmt.println("line:", string(line))
		numbers: [dynamic]int
		split_to_numbers(line, &numbers)
		s := s_make(numbers[:])
		append(&result, s)
	}
	return result
}

S :: struct {
	backing:     [dynamic]int,
	level:       int,
	level_count: int,
	carry:       int,
	up:          bool,
}
s_make :: proc(numbers: []int) -> S {
	s: S
	s.level_count = len(numbers)
	buf_len := 0
	for i in 1 ..= len(numbers) {
		buf_len += i
	}
	s.backing = make([dynamic]int, buf_len, buf_len)
	copy_slice(s.backing[0:len(numbers)], numbers)
	return s
}
s_get_level :: proc(s: ^S, level: int) -> (buf: []int, ok: bool) {
	if level > s.level_count {
		return
	}
	span := s.level_count - level
	start := 0
	for i in 0 ..< level {
		start += s.level_count - i
	}
	buf = s.backing[start:start + span]
	ok = true
	return
}
s_compute_down :: proc(s: ^S) -> (ok: bool) {
	current: []int
	current, ok = s_get_level(s, s.level)
	if !ok {return}
	next: []int
	next, ok = s_get_level(s, s.level + 1)
	if !ok {return}
	s.level += 1
	all_zeros := true
	for i in 1 ..< len(current) {
		next[i - 1] = current[i] - current[i - 1]
		if next[i - 1] != 0 {
			all_zeros = false
		}
	}
	if all_zeros {
		s.up = true
		ok = false
	} else {
		ok = true
	}
	return
}
s_compute_up :: proc(s: ^S) -> bool {
	assert(s.up == true)
	if s.level == 0 {
		return true
	}
	// bottom := s_get_level(s, s.level)
	s.level -= 1
	new_bottom, ok := s_get_level(s, s.level)
	assert(ok)
	s.carry = new_bottom[len(new_bottom) - 1] + s.carry //  bottom[len(bottom) - 1]
	return false
}

s_solve :: proc(s: ^S) -> int {
	ok := true
	for ok {
		ok = s_compute_down(s)
	}
	done := false
	for !done {
		done = s_compute_up(s)
	}
	return s.carry
}

part1 :: proc(input: []u8) -> int {
	ss := parse(input)
	total := 0
	for s in &ss {
		total += s_solve(&s)
	}
	return total
}

s_compute_up2 :: proc(s: ^S) -> bool {
	assert(s.up == true)
	if s.level == 0 {
		return true
	}
	s.level -= 1
	new_bottom, ok := s_get_level(s, s.level)
	assert(ok)
	s.carry = new_bottom[0] - s.carry
	return false
}

s_solve2 :: proc(s: ^S) -> int {
	ok := true
	for ok {
		ok = s_compute_down(s)
	}
	done := false
	for !done {
		done = s_compute_up2(s)
	}
	return s.carry
}

part2 :: proc(input: []u8) -> int {
	ss := parse(input)
	total := 0
	for s in &ss {
		total += s_solve2(&s)
	}
	return total
}

_main :: proc() {
	start_tick := time.tick_now()

	input, ok := os.read_entire_file_from_filename("input")
	defer delete(input)
	assert(ok)
	read_input_tick := time.tick_now()
	read_input_duration := time.tick_diff(start_tick, read_input_tick)

	{
		t := transmute([]u8)string(TEST_INPUT)
		r := part1(t)
		fmt.println(r)
		assert(r == 114)
	}
	{
		r := part1(input)
		fmt.println(r)
		assert(r == 1934898178)
	}
	part1_tick := time.tick_now()
	part1_duration := time.tick_diff(start_tick, part1_tick)
	{
		t := transmute([]u8)string(TEST_INPUT)
		r := part2(t)
		fmt.println(r)
		assert(r == 2)
	}
	{
		r := part2(input)
		fmt.println(r)
		assert(r == 1129)
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
