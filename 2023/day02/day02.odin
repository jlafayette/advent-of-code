package day01

import "core:fmt"
import "core:mem"
import "core:os"
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


TEST_INPUT :: `
Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
`

part1 :: proc(input: ^string) -> int {
	sum := 0
	// 12 red cubes, 13 green cubes, and 14 blue cubes
	red_max := 12
	green_max := 13
	blue_max := 14
	for line in strings.split_lines_iterator(input) {
		strs := strings.split_n(line, ": ", 2)
		defer delete(strs)
		if len(strs) != 2 {continue}
		id_parts := strings.split(strs[0], " ")
		defer delete(id_parts)
		assert(len(id_parts) == 2)
		id_str := id_parts[1]
		id, ok := strconv.parse_int(id_str)
		assert(ok)
		possible := true
		for draw_str in strings.split_iterator(&strs[1], "; ") {
			part_strs := strings.split(draw_str, ", ")
			defer delete(part_strs)
			for part_str in part_strs {
				col_draw := strings.split(part_str, " ")
				defer delete(col_draw)
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

part2 :: proc(input: ^string) -> int {
	sum := 0
	return sum
}

_main :: proc() {
	{
		str := string(TEST_INPUT)
		r := part1(&str)
		fmt.println(r)
		assert(r == 8)
	}
	// {
	// 	str := string(TEST_INPUT)
	// 	r := part2(&str)
	// 	// fmt.println(r)
	// }
	{
		input, ok := os.read_entire_file_from_filename("input")
		defer delete(input)
		assert(ok)

		{
			str := string(input)
			r := part1(&str)
			fmt.println(r)
			assert(r == 2449)
		}
		// {
		// 	str := string(input)
		// 	r := part2(&str)
		// 	// fmt.println(r)
		// }
	}
}
