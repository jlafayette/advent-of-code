package day01

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strconv"

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

to_digit :: proc(r: rune) -> (v: int, ok: bool) {
	switch r {
	case '0' ..= '9':
		{
			v = int(r) - '0'
			ok = true
		}
	}
	return
}

part1 :: proc(input: string) -> int {
	sum := 0
	first_found := false
	first_digit := 0
	last_digit := 0
	for rune, i in input {
		last := i == len(input) - 1
		if rune == '\n' || last {
			sum += first_digit * 10
			sum += last_digit
			first_digit = 0
			last_digit = 0
			first_found = false
			continue
		}
		v, ok := to_digit(rune)
		if ok {
			last_digit = v
			if !first_found {
				first_digit = v
				first_found = true
			}
		}
	}
	return sum
}

TEST_INPUT :: `1abc2
pqr3stu8vwx
a1b2c3d4e5f
treb7uchet`


_main :: proc() {
	r := part1(TEST_INPUT)
	fmt.println(r)
	input, ok := os.read_entire_file_from_filename("input")
	defer delete(input)
	assert(ok)
	// input is byte[]
	r = part1(string(input))
	fmt.println(r)
}
