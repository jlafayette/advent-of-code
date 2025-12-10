package main

import "core:bytes"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"


is_digit :: proc(b: byte) -> bool {
	return b >= '0' && b <= '9'
}

parse_int :: proc(slice: []byte) -> int {
	b := slice[:]
	for !is_digit(b[len(b) - 1]) {
		b = b[0:len(b) - 1]
	}
	n, ok := strconv.parse_int(string(b), 10)
	if !ok {
		fmt.eprintln("failed to parse number from string:", string(b))
		os.exit(1)
	}
	return n
}

parse_range :: proc(range: []byte) -> (int, int) {
	number_slices := bytes.split(range, {'-'})
	assert(len(number_slices) == 2)
	start := parse_int(number_slices[0])
	end := parse_int(number_slices[1])
	return start, end
}


is_valid :: proc(s: string) -> bool {
	b := transmute([]byte)s
	assert(len(b) >= 1)

	if len(b) % 2 != 0 {
		return true
	}

	valid: bool = false
	for i in 0 ..< (len(b) / 2) {
		if b[i] != b[i + len(b) / 2] {
			valid = true
			break
		}
	}
	return valid
}


part1 :: proc(input: []byte) -> int {
	bad_id_sum: int = 0
	data := input[:]
	for true {
		range, ok := bytes.split_iterator(&data, {','})
		if !ok {break}
		start, end := parse_range(range)
		b: strings.Builder = strings.builder_make_len_cap(0, 64)
		for n in start ..= end {
			s := fmt.sbprintf(&b, "%d", n)
			if !is_valid(s) {
				bad_id_sum += n
			}
			strings.builder_reset(&b)
		}
	}
	return bad_id_sum
}

is_valid2 :: proc(s: string) -> bool {
	b := transmute([]byte)s
	assert(len(b) >= 1)

	for repeats in 2 ..= len(b) {

		r := len(b) / repeats
		if r < 1 {
			return true
		}
		if len(b) % repeats != 0 {
			continue
		}

		valid: bool = false
		outer: for i in 0 ..< (len(b) / repeats) {
			for off in 1 ..< repeats {
				assert(r * off + i < len(b))
				if b[i] != b[r * off + i] {
					valid = true
					break outer
				}
			}
		}
		if !valid {
			return false
		}
	}

	return true
}

part2 :: proc(input: []byte) -> (int, int) {
	bad_id_sum: int = 0
	count: int = 0
	data := input[:]
	for true {
		range, ok := bytes.split_iterator(&data, {','})
		if !ok {break}
		start, end := parse_range(range)
		b: strings.Builder = strings.builder_make_len_cap(0, 64)
		for n in start ..= end {
			s := fmt.sbprintf(&b, "%d", n)
			if !is_valid2(s) {
				count += 1
				bad_id_sum += n
			}
			strings.builder_reset(&b)
		}
	}
	return count, bad_id_sum
}

main :: proc() {
	filename := "example.txt"
	if len(os.args) == 2 {
		filename = os.args[1]
	}
	data, ok := os.read_entire_file(filename)
	assert(ok)
	data1 := data[:]
	result1 := part1(data1)
	fmt.println(result1)
	data2 := data[:]
	count2, result2 := part2(data2)
	fmt.println(count2, ":", result2)
}

