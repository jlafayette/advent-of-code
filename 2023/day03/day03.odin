package day03

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

TEST_INPUT :: `..........
467..114..
...*......
..35..633.
......#...
617*......
.....+.58.
..592.....
......755.
...$.*....
.664.598..`


Number :: struct {
	v:     int,
	start: int,
	end:   int,
}

next_int :: proc(s: string) -> (n: Number, ok: bool) {
	loop: for r, i in s {
		switch r {
		case '0' ..= '9':
			{
				if ok {
					n.end = i + 1
				} else {
					n.start = i
					n.end = i + 1
					ok = true
				}
			}
		case:
			{if ok {break loop}}
		}
	}
	if ok {
		n.v, ok = strconv.parse_int(s[n.start:n.end])
		assert(ok)
	}
	return
}

part1 :: proc(input: string) -> int {
	total := 0

	lines := strings.split_lines(input)
	defer delete(lines)
	buf := make([dynamic]u8, len(lines[1]), len(lines[1]))
	defer delete(buf)
	for i in 0 ..< len(buf) {
		buf[i] = '.'
	}
	edge_line := string(buf[:])

	for line, i in lines {
		prev: string
		next: string
		if i == 0 {
			prev = edge_line
		} else {
			prev = lines[i - 1]
		}
		if i == len(lines) - 1 {
			next = edge_line
		} else {
			next = lines[i + 1]
		}
		// fmt.println("p", prev)
		// fmt.println(i, line)
		// fmt.println("n", next)
		// fmt.println("")

		rest := line[:]
		offset := 0
		n, ok := next_int(rest)
		for ok {
			si := max(0, n.start - 1 + offset)
			ei := min(n.end + 1 + offset, len(line))
			seg_prev := prev[si:ei]
			seg_curr := line[si:ei]
			seg_next := next[si:ei]
			// fmt.println("  ", seg_prev)
			// fmt.println("  ", seg_curr)
			// fmt.println("  ", seg_next)
			found := false

			segments: [3]string = {seg_prev, seg_curr, seg_next}
			seg_loop: for seg in segments {
				for char in seg {
					switch char {
					case '0' ..= '9':
					case '.':
					case:
						{
							found = true
							break seg_loop
						}
					}
				}
			}
			if found {
				total += n.v
			}

			rest = rest[n.end:]
			offset += n.end
			n, ok = next_int(rest)
		}
	}


	return total
}


Row :: struct {
	gears:   [dynamic]int,
	numbers: [dynamic]Number,
	line:    string,
}
row_init :: proc(r: ^Row, line: string) {
	r.line = line
	clear(&r.gears)
	clear(&r.numbers)
	n: Number
	n_wip := false
	for char, i in line {
		finish_n := false
		switch char {
		case '*':
			{
				append(&r.gears, i)
				finish_n = true
			}
		case '0' ..= '9':
			{
				if n_wip {
					n.end = i + 1
				} else {
					n.start = i
					n.end = i + 1
					n_wip = true
				}
			}
		case:
			{
				finish_n = true
			}
		}
		if (finish_n && n_wip) || (n_wip && i == len(line) - 1) {
			v, ok := strconv.parse_int(line[n.start:n.end])
			assert(ok)
			n.v = v
			append(&r.numbers, n)
			n_wip = false
		}
	}
}
row_delete :: proc(r: ^Row) {
	delete(r.gears)
	delete(r.numbers)
}
rows_delete :: proc(rows: [3]^Row) {
	for r in rows {
		row_delete(r)
	}
}
rows_print :: proc(rows: [3]^Row) {
	fmt.println()
	for r in rows {
		if r.line == "" {
			fmt.println("   ...")
		} else {
			b := strings.builder_make()
			defer strings.builder_destroy(&b)
			fmt.sbprint(&b, "  ", r.line, "gears:", r.gears, "numbers: ")
			for n, i in r.numbers {
				fmt.sbprintf(&b, "%d (%d,%d)", n.v, n.start, n.end)
				if i != len(r.numbers) - 1 {
					fmt.sbprint(&b, ", ")
				}
			}
			fmt.println(strings.to_string(b))
		}
	}
	fmt.println()
}
rows_next :: proc(rows: ^[3]^Row, line: string) {
	row_init(rows.x, line)
	rows^.xyz = rows^.yzx
}
rows_score :: proc(rows: [3]^Row) -> (score: int) {
	adjacent := make([dynamic]int, 0, 4)
	defer delete(adjacent)
	for x in rows.y.gears {
		clear(&adjacent)
		for n in rows.x.numbers {
			if x >= n.start - 1 && x <= n.end {
				append(&adjacent, n.v)
			}
		}
		for n in rows.y.numbers {
			if x == n.start - 1 || x == n.end {
				append(&adjacent, n.v)
			}
		}
		for n in rows.z.numbers {
			if x >= n.start - 1 && x <= n.end {
				append(&adjacent, n.v)
			}
		}
		if len(adjacent) == 2 {
			ratio := adjacent[0] * adjacent[1]
			score += ratio
		}
	}
	return
}


part2 :: proc(input: ^string) -> int {
	total := 0
	row_backing: [3]Row
	rows: [3]^Row = {&row_backing.x, &row_backing.y, &row_backing.z}
	defer rows_delete(rows)
	for line in strings.split_lines_iterator(input) {
		rows_next(&rows, line)
		total += rows_score(rows)
	}
	// score last row
	rows_next(&rows, "")
	total += rows_score(rows)

	return total
}


_main :: proc() {
	start_tick := time.tick_now()
	read_input_tick: time.Tick
	read_input_duration: time.Duration
	{
		r := part1(TEST_INPUT)
		// fmt.println(r)
		assert(r == 4361)
	}
	{
		str := string(TEST_INPUT)
		r := part2(&str)
		// fmt.println(r)
		assert(r == 467835)
	}
	part1_tick := time.tick_now()
	part1_duration := time.tick_diff(start_tick, part1_tick)
	{
		input, ok := os.read_entire_file_from_filename("input")
		defer delete(input)
		assert(ok)
		read_input_tick = time.tick_now()
		read_input_duration = time.tick_diff(part1_tick, read_input_tick)
		{
			r := part1(string(input))
			// fmt.println(r)
			assert(r == 527369)
		}
		{
			str := string(input)
			r := part2(&str)
			// fmt.println(r)
			assert(r == 73074886)
		}
	}
	part2_tick := time.tick_now()
	part2_duration := time.tick_diff(read_input_tick, part2_tick)
	total_duration := time.tick_diff(start_tick, part2_tick)

	part1_ms := time.duration_milliseconds(part1_duration)
	read_input_ms := time.duration_milliseconds(read_input_duration)
	part2_ms := time.duration_milliseconds(part2_duration)
	total_ms := time.duration_milliseconds(total_duration)

	fmt.printf("part1: %.4f ms\n", part1_ms)
	fmt.printf(" read: %.4f ms\n", read_input_ms)
	fmt.printf("part2: %.4f ms\n", part2_ms)
	fmt.printf("total: %.4f ms\n", total_ms)
}
