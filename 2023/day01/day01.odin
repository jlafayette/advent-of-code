package day01

import "core:fmt"
import "core:mem"
import "core:os"
import "core:runtime"
import "core:strconv"
import "core:strings"

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

to_digit_u8 :: proc(char: u8) -> (v: int, ok: bool) {
	switch char {
	case '0' ..= '9':
		{
			v = int(char) - '0'
			ok = true
		}
	}
	return
}
to_digit_u8_yolo :: proc(char: u8) -> int {
	return int(char) - '0'
}

part1_2 :: proc(input: ^string) -> int {
	sum := 0
	for line in strings.split_lines_iterator(input) {
		first := strings.index_any(line, "0123456789")
		last := strings.last_index_any(line, "0123456789")
		if first != -1 {
			sum += to_digit_u8_yolo(line[first]) * 10
		}
		if last != -1 {
			sum += to_digit_u8_yolo(line[last])
		}
	}
	return sum
}

TEST_INPUT :: `1abc2
pqr3stu8vwx
a1b2c3d4e5f
treb7uchet
no`

TEST_INPUT2 :: `two1nine
eightwothree
abcone2threexyz
xtwone3four
4nineeightseven2
zoneight234
7pqrstsixteen`

to_digit_rune_yolo :: proc(r: rune) -> int {
	return int(r) - '0'
}

starts_with_num :: proc(str: string) -> int {
	num_strs: []string = {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine"}
	for num_str, i in num_strs {
		if strings.has_prefix(str, num_str) {
			return i + 1
		}
	}
	return -1
}

part2 :: proc(input: ^string) -> int {
	sum := 0
	for line in strings.split_lines_iterator(input) {
		// fmt.println(line)
		first := -1
		last := -1
		for char, i in line {
			// fmt.println("  ", i, char, line[i:])
			num := -1
			switch char {
			case '0' ..= '9':
				{
					num = to_digit_rune_yolo(char)
				}
			case:
				{
					num = starts_with_num(line[i:])
				}
			}
			if num != -1 {
				if first == -1 {
					first = num
					last = num
				} else {
					last = num
				}
			}
		}
		// fmt.println("--", first, last)
		if first != -1 {
			sum += first * 10
		}
		if last != -1 {
			sum += last
		}
	}
	return sum
}

_main :: proc() {
	{
		r := part1(TEST_INPUT)
		fmt.println(r)
		assert(r == 142)
	}
	{
		str := string(TEST_INPUT)
		r := part1_2(&str)
		fmt.println(r)
		assert(r == 142)
	}
	{
		str := string(TEST_INPUT2)
		r := part2(&str)
		fmt.println(r)
		assert(r == 281)
	}
	{
		input, ok := os.read_entire_file_from_filename("input")
		defer delete(input)
		assert(ok)

		{
			r := part1(string(input))
			fmt.println(r)
			assert(r == 54927)
		}
		{
			str := string(input)
			r := part1_2(&str)
			fmt.println(r)
			assert(r == 54927)
		}
		{
			str := string(input)
			r := part2(&str)
			fmt.println(r)
			assert(r == 54581)
		}
	}
}
