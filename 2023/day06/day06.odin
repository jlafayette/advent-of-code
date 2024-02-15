package day05

import "core:container/queue"
import "core:fmt"
import "core:math"
import "core:mem"
import "core:os"
import "core:runtime"
import "core:slice"
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
	args := os.args[1:]
	if slice.contains(args, "-b") || slice.contains(args, "--benchmark") {
		benchmark()
	} else {
		_main()
	}
}

benchmark :: proc() {
	fmt.println("running benchmark")

	input, ok := os.read_entire_file_from_filename("input")
	defer delete(input)

	opt := time.Benchmark_Options{}
	opt.rounds = 10000
	runs := 1

	{
		durations: [dynamic]time.Duration
		defer delete(durations)
		for i := 0; i < runs; i += 1 {
			d: time.Duration
			t: int
			{
				time.SCOPED_TICK_DURATION(&d)
				x := split_to_numbers(string(input))
				t += len(x)
				defer delete(x)
			}
			assert(t == 7 || t == 8)
			append(&durations, d)
		}
		assert(len(durations) == runs)
		total: f64
		for d in durations {
			total += time.duration_milliseconds(d)
		}
		avg := total / f64(runs)
		fmt.printf("split_to_numbers took %.6f ms on average\n", avg)
	}
	{
		durations: [dynamic]time.Duration
		defer delete(durations)
		for i := 0; i < runs; i += 1 {
			d: time.Duration
			t: int
			{
				time.SCOPED_TICK_DURATION(&d)
				x := to_numbers(string(input))
				t += len(x)
				defer delete(x)
			}
			assert(t == 8)
			append(&durations, d)
		}
		assert(len(durations) == runs)
		total: f64
		for d in durations {
			total += time.duration_milliseconds(d)
		}
		avg := total / f64(runs)
		fmt.printf("to_numbers took %.6f ms on average\n", avg)
	}
}

TEST_INPUT :: `Time:      7  15   30
Distance:  9  40  200`

to_numbers :: proc(s: string) -> (result: [dynamic]int) {
	start := 0
	end := 0
	wip := false
	loop: for r, i in s {
		switch r {
		case '0' ..= '9':
			{
				if wip {
					end = i + 1
				} else {
					start = i
					end = i + 1
					wip = true
				}
			}
		case:
			{
				if wip {
					v, ok := strconv.parse_int(s[start:end], 10)
					assert(ok)
					append(&result, v)
					wip = false
				}
			}
		}
	}
	if wip {
		v, ok := strconv.parse_int(s[start:end], 10)
		assert(ok)
		append(&result, v)
	}
	return
}
to_number :: proc(s: string) -> int {
	b := strings.builder_make(0, 16)
	defer strings.builder_destroy(&b)
	loop: for r in s {
		switch r {
		case '0' ..= '9':
			fmt.sbprint(&b, r)
		case:
		}
	}
	res := strings.to_string(b)
	v, ok := strconv.parse_int(res, 10)
	assert(ok)
	return v
}
split_to_numbers :: proc(s: string) -> (result: [dynamic]int) {
	num_strs := strings.split(s, " ")
	// fmt.println(num_strs)
	defer delete(num_strs)
	for n_str in num_strs {
		v, ok := strconv.parse_int(n_str, 10)
		if ok {
			append(&result, v)
		}
	}
	return
}
Race :: struct {
	time:     int,
	distance: int,
}
parse :: proc(data: string) -> []Race {
	lines := strings.split_lines(data)
	defer delete(lines)
	assert(len(lines) == 2)
	times := to_numbers(lines[0])
	defer delete(times)
	distances := to_numbers(lines[1])
	defer delete(distances)
	assert(len(times) == len(distances))
	races := make([dynamic]Race, 0, len(times))
	for i := 0; i < len(times); i += 1 {
		append(&races, Race{times[i], distances[i]})
	}
	return races[:]
}
ways_to_win :: proc(race: Race) -> int {
	ways := 0
	// fmt.println(race)
	for time_held in 0 ..= race.time {
		speed := time_held
		distance := speed * (race.time - time_held)
		if distance > race.distance {
			ways += 1
		}
	}
	return ways
}

part1 :: proc(input: string) -> int {
	races := parse(input)
	defer delete(races)
	results := make([dynamic]int, 0, len(races))
	defer delete(results)
	for race in races {
		append(&results, ways_to_win(race))
	}
	total := results[0]
	for r in results[1:] {
		total = total * r
	}
	return total
}

part2 :: proc(input: string) -> int {
	lines := strings.split_lines(input)
	defer delete(lines)
	assert(len(lines) == 2)
	race: Race
	race.time = to_number(lines[0])
	race.distance = to_number(lines[1])
	fmt.println(race)
	return ways_to_win(race)
}

_main :: proc() {
	start_tick := time.tick_now()

	input, ok := os.read_entire_file_from_filename("input")
	defer delete(input)
	assert(ok)
	read_input_tick := time.tick_now()
	read_input_duration := time.tick_diff(start_tick, read_input_tick)

	{
		r := part1(string(TEST_INPUT))
		fmt.println(r)
		assert(r == 288)
	}
	{
		r := part1(string(input))
		fmt.println(r)
		assert(r == 316800)
	}
	part1_tick := time.tick_now()
	part1_duration := time.tick_diff(start_tick, part1_tick)
	{
		r := part2(TEST_INPUT)
		fmt.println(r)
		assert(r == 71503)
	}
	{
		r := part2(string(input))
		fmt.println(r)
		assert(r == 45647654)
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
