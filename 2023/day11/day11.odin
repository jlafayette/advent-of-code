package day11

import "core:bytes"
import "core:container/queue"
import "core:fmt"
import "core:math"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
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

TEST_INPUT :: `...#......
.......#..
#.........
..........
......#...
.#........
.........#
..........
.......#..
#...#.....`


Pos :: [2]int
pos_distance :: proc(a, b: Pos) -> int {
	return abs(b.y - a.y) + abs(b.x - a.x)
}

solve :: proc(input: []u8, expansion_factor: int) -> int {
	starmap := bytes.split(input, {'\n'})
	defer delete(starmap)

	// expansion_factor := 2
	row_distances := make_slice([]int, len(starmap));defer delete(row_distances)
	for _, i in row_distances {
		row_distances[i] = expansion_factor
	}
	col_distances := make_slice([]int, len(starmap[0]));defer delete(col_distances)
	for _, i in col_distances {
		col_distances[i] = expansion_factor
	}

	galaxies: [dynamic]Pos;defer delete(galaxies)
	for row, y in starmap {
		for char, x in row {
			if char == '#' {
				append(&galaxies, Pos{x, y})
				row_distances[y] = 1
				col_distances[x] = 1
			}
		}
	}

	acc := 0
	// fmt.println("rows:", row_distances)
	for value, i in row_distances {
		// acc += value
		row_distances[i] = acc
		acc += value
	}
	// fmt.println("rows:", row_distances)

	// fmt.println("cols:", col_distances)
	acc = 0
	for value, i in col_distances {
		col_distances[i] = acc
		acc += value
	}
	// fmt.println("cols:", col_distances)

	// fmt.println()
	// fmt.println(galaxies)
	for g, i in galaxies {
		galaxies[i].x = col_distances[g.x]
		galaxies[i].y = row_distances[g.y]
	}
	// fmt.println(galaxies)

	calculated := make_slice([]bool, len(galaxies) * len(galaxies))
	sum: int
	// pairs: int
	for g1, i in galaxies {
		for g2, j in galaxies {
			if i == j {
				continue
			}
			// Check if we've already summed the opposite of this pair
			ii := i * len(galaxies) + j
			if calculated[ii] {
				continue
			}
			// Store opposite combo of i and j so we skip this pair next time
			ij := j * len(galaxies) + i
			calculated[ij] = true

			// pairs += 1
			distance := pos_distance(g1, g2)
			// fmt.printf(
			// 	"Between galaxy %d and galaxy %d: %d\n",
			// 	min(i, j) + 1,
			// 	max(i, j) + 1,
			// 	distance,
			// )
			sum += distance
		}
	}
	// fmt.println("pairs:", pairs)
	return sum
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
		r := solve(t, 2)
		fmt.println(r)
		assert(r == 374)
	}
	{
		r := solve(input, 2)
		fmt.println(r)
		assert(r == 10313550)
	}
	part1_tick := time.tick_now()
	part1_duration := time.tick_diff(start_tick, part1_tick)
	{
		t := transmute([]u8)string(TEST_INPUT)
		r := solve(t, 10)
		fmt.println(r)
		assert(r == 1030)
	}
	{
		t := transmute([]u8)string(TEST_INPUT)
		r := solve(t, 100)
		fmt.println(r)
		assert(r == 8410)
	}
	{
		r := solve(input, 1_000_000)
		fmt.println(r)
		assert(r == 611998089572)
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
