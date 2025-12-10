package d1

import "core:bytes"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

part1 :: proc(data: ^[]u8) -> (zero_count: int, success: bool) {
	ok: bool = true
	dial: int = 50
	zero_count = 0
	for ok {
		line_bytes: []u8
		line_bytes, ok = bytes.split_iterator(data, {'\n'})
		if !ok || len(line_bytes) == 0 {
			break
		}
		if line_bytes[len(line_bytes) - 1] == '\r' {
			line_bytes = line_bytes[:len(line_bytes) - 1]
		}
		line := string(line_bytes[:])

		n: int
		n, ok = strconv.parse_int(line[1:], 10)
		assert(ok)
		ch := line[0]

		if ch == 'L' {
			dial -= n
			for dial < 0 {
				dial += 100
			}
		} else if ch == 'R' {
			dial += n
			for dial > 99 {
				dial -= 100
			}
		} else {
			fmt.eprintln("Expected L or R, got", ch)
			return zero_count, false
		}
		if dial == 0 {
			zero_count += 1
		}
	}
	return zero_count, true

}


part2 :: proc(data: ^[]u8) -> (zero_count: int, success: bool) {
	ok: bool = true
	dial: int = 50
	zero_count = 0
	for ok {
		line_bytes: []u8
		line_bytes, ok = bytes.split_iterator(data, {'\n'})
		if !ok || len(line_bytes) == 0 {
			break
		}
		if line_bytes[len(line_bytes) - 1] == '\r' {
			line_bytes = line_bytes[:len(line_bytes) - 1]
		}
		line := string(line_bytes[:])

		n: int
		n, ok = strconv.parse_int(line[1:], 10)
		assert(ok)
		ch := line[0]

		// past_zero: bool = false
		orig_dial: int = dial
		if ch == 'L' {
			for n > 0 {
				n -= 1
				dial -= 1
				if dial == 0 {
					zero_count += 1
				}
				if dial < 0 {
					dial += 100
				}
			}
		} else if ch == 'R' {
			for n > 0 {
				n -= 1
				dial += 1
				if dial > 99 {
					dial -= 100
				}
				if dial == 0 {
					zero_count += 1
				}
			}
		} else {
			fmt.eprintln("Expected L or R, got", ch)
			return zero_count, false
		}
	}
	return zero_count, true
}


main :: proc() {
	args := os.args
	filename: string = "d1_example.txt"
	if len(args) == 2 {
		filename = args[1]
	}
	data, ok := os.read_entire_file(filename)
	if (!ok) {
		fmt.println("Failed to open file", filename)
		return
	}
	part1_result: int
	data1 := data[:]
	part1_result, ok = part1(&data1)
	assert(ok)
	fmt.println(part1_result)
	data2 := data[:]
	part2_result, ok2 := part2(&data2)
	assert(ok2)
	// 2609 (too low)
	// 7340 (too high)
	fmt.println(part2_result)
}

