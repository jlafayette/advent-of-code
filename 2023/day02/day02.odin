package day01

import "core:fmt"
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


TEST_INPUT :: `
Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
`

part1 :: proc(input: ^string, alloc: mem.Allocator) -> int {
	sum := 0
	// 12 red cubes, 13 green cubes, and 14 blue cubes
	red_max := 12
	green_max := 13
	blue_max := 14

	for line in strings.split_lines_iterator(input) {
		defer free_all(alloc)
		strs := strings.split_n(line, ": ", 2, alloc)
		if len(strs) != 2 {continue}
		id_parts := strings.split(strs[0], " ", alloc)
		assert(len(id_parts) == 2)
		id_str := id_parts[1]
		id, ok := strconv.parse_int(id_str)
		assert(ok)
		possible := true
		for draw_str in strings.split_iterator(&strs[1], "; ") {
			part_strs := strings.split(draw_str, ", ", alloc)
			for part_str in part_strs {
				col_draw := strings.split(part_str, " ", alloc)
				assert(len(col_draw) == 2)
				count, ok := strconv.parse_int(col_draw[0])
				assert(ok)
				max := 0
				switch col_draw[1] {
				case "red":
					{max = red_max}
				case "green":
					{max = green_max}
				case "blue":
					{max = blue_max}
				}
				assert(max != 0)
				if count > max {
					possible = false
					break
				}
			}
		}
		if possible {
			sum += id
		}
	}
	return sum
}


part2 :: proc(input: ^string, alloc: mem.Allocator) -> int {
	sum := 0
	for line in strings.split_lines_iterator(input) {
		defer free_all(alloc)
		strs := strings.split_n(line, ": ", 2, alloc)
		if len(strs) != 2 {continue}
		id_parts := strings.split(strs[0], " ", alloc)
		assert(len(id_parts) == 2)
		id_str := id_parts[1]
		id, ok := strconv.parse_int(id_str)
		assert(ok)
		min_red := 0
		min_green := 0
		min_blue := 0
		for draw_str in strings.split_iterator(&strs[1], "; ") {
			part_strs := strings.split(draw_str, ", ", alloc)
			for part_str in part_strs {
				col_draw := strings.split(part_str, " ", alloc)
				assert(len(col_draw) == 2)
				count, ok := strconv.parse_int(col_draw[0])
				assert(ok)
				switch col_draw[1] {
				case "red":
					{min_red = max(min_red, count)}
				case "green":
					{min_green = max(min_green, count)}
				case "blue":
					{min_blue = max(min_blue, count)}
				}
			}
		}
		sum += min_red * min_green * min_blue
	}
	return sum
}


part3 :: proc(input: ^string, alloc: mem.Allocator) -> (sum1: int, sum2: int) {
	// 12 red cubes, 13 green cubes, and 14 blue cubes
	red_max := 12
	green_max := 13
	blue_max := 14

	for line in strings.split_lines_iterator(input) {
		defer free_all(alloc)
		strs := strings.split_n(line, ": ", 2, alloc)
		if len(strs) != 2 {continue}
		id_parts := strings.split(strs[0], " ", alloc)
		assert(len(id_parts) == 2)
		id_str := id_parts[1]
		id, ok := strconv.parse_int(id_str)
		assert(ok)
		possible := true
		min_red := 0
		min_green := 0
		min_blue := 0
		for draw_str in strings.split_iterator(&strs[1], "; ") {
			part_strs := strings.split(draw_str, ", ", alloc)
			for part_str in part_strs {
				col_draw := strings.split(part_str, " ", alloc)
				assert(len(col_draw) == 2)
				count, ok := strconv.parse_int(col_draw[0])
				assert(ok)
				max_count := 0
				switch col_draw[1] {
				case "red":
					{
						max_count = red_max
						min_red = max(min_red, count)
					}
				case "green":
					{
						max_count = green_max
						min_green = max(min_green, count)
					}
				case "blue":
					{
						max_count = blue_max
						min_blue = max(min_blue, count)
					}
				}
				assert(max_count != 0)
				if count > max_count {
					possible = false
				}
			}
		}
		if possible {
			sum1 += id
		}
		sum2 += min_red * min_green * min_blue
	}
	return sum1, sum2
}

// TEST_INPUT :: `
// Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
// Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
// Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
// Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
// Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
// `
Parser :: struct {
	line: string,
}
chomp_n :: proc(p: ^Parser, n: int) {
	p.line = p.line[n:]
}
chomp_number :: proc(p: ^Parser) -> int {
	for r, i in p.line {
		switch r {
		case '0' ..= '9':
		case:
			{
				n, ok := strconv.parse_int(p.line[:i])
				if !ok {
					fmt.println("  ERR parsing number from", p.line[:i])
				}
				assert(ok)
				p.line = p.line[i:]
				return n
			}
		}
	}
	assert(false)
	return 0
}
Label :: enum {
	R,
	G,
	B,
	Err,
}
chomp_label :: proc(p: ^Parser) -> Label {
	if strings.has_prefix(p.line, "red") {
		p.line = p.line[3:]
		return .R
	}
	if strings.has_prefix(p.line, "green") {
		p.line = p.line[5:]
		return .G
	}
	if strings.has_prefix(p.line, "blue") {
		p.line = p.line[4:]
		return .B
	}
	return .Err
}
Divider :: enum {
	Comma,
	SemiColon,
	EOL,
}
chomp_divider :: proc(p: ^Parser) -> Divider {
	if len(p.line) == 0 {
		return .EOL
	}
	defer {
		p.line = p.line[1:]
	}
	switch p.line[0] {
	case ',':
		return .Comma
	case ';':
		return .SemiColon
	case:
		return .EOL
	}
}

part4 :: proc(input: ^string) -> (sum1: int, sum2: int) {
	// 12 red cubes, 13 green cubes, and 14 blue cubes
	red_max := 12
	green_max := 13
	blue_max := 14

	for line in strings.split_lines_iterator(input) {
		if len(line) == 0 {
			continue
		}
		// fmt.println(line)
		p := Parser {
			line = line,
		}
		chomp_n(&p, 5)
		id := chomp_number(&p)
		// fmt.println("   id:", id)
		chomp_n(&p, 2)

		possible := true
		min_red := 0
		min_green := 0
		min_blue := 0

		done := false
		for !done {
			divider: Divider = .Comma
			for divider == .Comma {
				count := chomp_number(&p)
				chomp_n(&p, 1)
				col := chomp_label(&p)
				divider = chomp_divider(&p)
				// fmt.println("    ", count, col, divider)

				max_count := 0
				switch col {
				case .R:
					{
						max_count = red_max
						min_red = max(min_red, count)
					}
				case .G:
					{
						max_count = green_max
						min_green = max(min_green, count)

					}
				case .B:
					{
						max_count = blue_max
						min_blue = max(min_blue, count)
					}
				case .Err:
					{
						fmt.println("ERR")
					}
				}
				if count > max_count {
					possible = false
				}

				if divider == .EOL {
					done = true
					break
				}
				chomp_n(&p, 1)
			}
		}
		if possible {
			sum1 += id
		}
		sum2 += min_red * min_green * min_blue
	}
	return sum1, sum2
}


_main :: proc() {
	start_tick := time.tick_now()
	// buf: [1024]byte
	// arena: mem.Arena
	// mem.arena_init(&arena, buf[:])
	// alloc := mem.arena_allocator(&arena)
	// {
	// 	str := string(TEST_INPUT)
	// 	r := part1(&str, alloc)
	// 	// fmt.println(r)
	// 	assert(r == 8)
	// }
	// {
	// 	str := string(TEST_INPUT)
	// 	r := part2(&str, alloc)
	// 	// fmt.println(r)
	// 	assert(r == 2286)
	// }
	{
		str := string(TEST_INPUT)
		r1, r2 := part4(&str)
		// fmt.println(r1, r2)
		assert(r1 == 8)
		assert(r2 == 2286)
	}
	{
		input, ok := os.read_entire_file_from_filename("input")
		defer delete(input)
		assert(ok)
		// {
		// 	str := string(input)
		// 	r := part1(&str, alloc)
		// 	// fmt.println(r)
		// 	assert(r == 2449)
		// }
		// {
		// 	str := string(input)
		// 	r := part2(&str, alloc)
		// 	// fmt.println(r)
		// 	assert(r == 63981)
		// }
		{
			str := string(input)
			r1, r2 := part4(&str)
			// fmt.println(r1, r2)
			assert(r1 == 2449)
			assert(r2 == 63981)
		}
	}
	elapsed := time.tick_since(start_tick)
	ms := time.duration_milliseconds(elapsed)
	ns := time.duration_nanoseconds(elapsed)
	fmt.println(ms, "ms,", ns, "ns")
}
