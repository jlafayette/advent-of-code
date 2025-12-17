package main

import "core:bytes"
import "core:fmt"
import "core:os"
import "core:strconv"

Data :: struct {
	ranges:         [dynamic][2]int,
	ingredient_ids: [dynamic]int,
}

parse :: proc(input: []byte) -> Data {
	data: Data

	buf := input[:]
	sep: []byte = {'\n'}
	for ch, i in buf {
		if ch == '\n' && i > 0 {
			if buf[i - 1] == '\r' {
				sep = {'\r', '\n'}
			}
		}
	}

	lines_buf := buf[:]
	part: int = 1

	for true {
		line, line_ok := bytes.split_iterator(&lines_buf, sep)
		if !line_ok {break}

		if len(line) == 0 {
			part = 2
			continue
		}

		if part == 1 {
			parts := bytes.split(line, {'-'})
			assert(len(parts) == 2)
			n1, ok1 := strconv.parse_int(string(parts[0]), 10)
			assert(ok1)
			n2, ok2 := strconv.parse_int(string(parts[1]), 10)
			assert(ok2)
			append_elem(&data.ranges, [2]int{n1, n2})
		} else {
			n, ok := strconv.parse_int(string(line), 10)
			assert(ok)
			append_elem(&data.ingredient_ids, n)
		}
	}

	return data
}

part1 :: proc(input: []byte) -> int {
	result: int
	data := parse(input)
	for id in data.ingredient_ids {
		for range in data.ranges {
			if id >= range.x && id <= range.y {
				result += 1
				break
			}
		}
	}
	return result
}

merge :: proc(r1, r2: [2]int) -> ([2]int, bool) {
	r: [2]int
	// r2.x is within r1
	if r2.x >= r1.x && r2.x <= r1.y {
		r.x = r1.x
		r.y = max(r1.y, r2.y)
		return r, true
		// r2.y is within r1
	} else if r2.y >= r1.x && r2.y <= r1.y {
		r.x = min(r1.x, r2.x)
		r.y = r1.y
		return r, true
		// r1.x is within r2
	} else if r1.x >= r2.x && r1.x <= r2.y {
		r.x = r2.x
		r.y = max(r1.y, r2.y)
		return r, true
		// r1.y is within r2
	} else if r1.y >= r2.x && r1.y <= r2.y {
		r.x = min(r1.x, r2.x)
		r.y = r2.y
		return r, true
	}

	return r, false
}

part2 :: proc(input: []byte) -> int {
	result: int

	data := parse(input)

	// merge all the ranges that can be
	ranges: [dynamic][2]int = data.ranges
	i: int = 0
	merged := 0
	for true {

		j: int = len(ranges) - 1
		for true {
			if i >= j {
				break
			}
			r1 := ranges[i]
			r2 := ranges[j]
			r, ok := merge(r1, r2)
			if ok {
				unordered_remove(&ranges, j)
				ranges[i] = r
				merged += 1
			}
			j -= 1
		}
		i += 1
		if i >= len(ranges) {
			i = 0
			if merged == 0 {
				break
			}
			merged = 0
		}
	}

	// count all ranges
	for range in ranges {
		result += (range.y - range.x + 1)
	}

	return result
}

test_merge :: proc(r1, r2, expected: [2]int, expected_ok: bool) {
	actual, ok := merge(r1, r2)
	if ok != expected_ok {
		fmt.printfln("xx merge(%v, %v) failed: expected ok %v, got %v", r1, r2, expected_ok, ok)
	}
	if actual != expected {
		fmt.printfln("xx merge(%v, %v) failed: expected %v, got %v", r1, r2, expected, actual)
	}
	fmt.printfln("ok merge(%v, %v)", r1, r2)
}

main :: proc() {
	filename := "example.txt"
	if len(os.args) == 2 {
		filename = os.args[1]
	}
	input, err := os.read_entire_file_or_err(filename)
	if err != nil {
		fmt.eprintfln("Error reading file '%s': %v", filename, err)
		os.exit(1)
	}

	result1 := part1(input)
	fmt.println(result1)

	result2 := part2(input)
	fmt.println(result2)

	if filename == "example.txt" {
		assert(result1 == 3)
		assert(result2 == 14)
	} else if filename == "input.txt" {
		assert(result1 == 828)
		assert(result2 == 352681648086146)
	}

	// test_merge({1, 3}, {2, 4}, {1, 4}, true)
	// test_merge({8, 11}, {2, 4}, {0, 0}, false)
	// test_merge({1, 3}, {5, 9}, {0, 0}, false)
	// test_merge({5, 11}, {3, 5}, {3, 11}, true)
}

