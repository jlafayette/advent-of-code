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

TEST_INPUT :: `467..114..
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

chomp_next_int :: proc(s: string) -> (n: Number, ok: bool) {
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

		// n := Number{}
		// ok := true
		rest := line[:]
		offset := 0
		n, ok := chomp_next_int(rest)
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
			n, ok = chomp_next_int(rest)
		}
	}


	return total
}


_main :: proc() {
	start_tick := time.tick_now()
	{
		r := part1(TEST_INPUT)
		fmt.println(r)
		assert(r == 4361)
	}
	// {
	// 	str := string(TEST_INPUT)
	// 	r := part2(&str)
	// 	// fmt.println(r)
	// 	assert(r == )
	// }
	{
		input, ok := os.read_entire_file_from_filename("input")
		defer delete(input)
		assert(ok)
		{
			r := part1(string(input))
			fmt.println(r)
			assert(r == 527369)
		}
		// {
		// 	str := string(input)
		// 	r := part2(&str)
		// 	// fmt.println(r)
		// 	assert(r == 63981)
		// }
	}
	elapsed := time.tick_since(start_tick)
	ms := time.duration_milliseconds(elapsed)
	ns := time.duration_nanoseconds(elapsed)
	fmt.println(ms, "ms,", ns, "ns")
}
