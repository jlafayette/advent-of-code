package day04

import "core:fmt"
import "core:math"
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


TEST_INPUT :: `Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11`

split_to_numbers :: proc(s: string) -> (result: [dynamic]int) {
	num_strs := strings.split(s, " ")
	// fmt.println(num_strs)
	defer delete(num_strs)
	for n_str in num_strs {
		v, ok := strconv.parse_int(n_str)
		if ok {
			append(&result, v)
		}
	}
	return
}

part1 :: proc(input: ^string) -> int {
	total := 0
	for line in strings.split_lines_iterator(input) {
		// fmt.println(line)
		parts := strings.split(line, ": ")
		defer delete(parts)
		num_parts := strings.split(parts[1], " | ")
		defer delete(num_parts)
		assert(len(num_parts) == 2)
		winning_nums := split_to_numbers(num_parts[0])
		defer delete(winning_nums)
		your_nums := split_to_numbers(num_parts[1])
		defer delete(your_nums)
		// fmt.println("  winning:", winning_nums)
		// fmt.println("  your:", your_nums)
		overlap: int = 0
		for n1 in winning_nums {
			for n2 in your_nums {
				if n1 == n2 {
					overlap += 1
					break
				}
			}
		}
		score := 0
		if overlap > 0 {
			score = 1
		}
		for i := 1; i < overlap; i += 1 {
			score = score * 2
		}
		// fmt.println("  score:", score)
		total += int(score)
	}

	return total
}

Card :: struct {
	number: int,
	score:  int,
}
parse :: proc(line: string) -> Card {
	parts := strings.split(line, ": ")
	assert(len(parts) == 2)
	card_strs := strings.split(parts[0], " ")
	defer delete(card_strs)
	card_number, ok := strconv.parse_int(card_strs[len(card_strs) - 1])
	assert(ok)
	defer delete(parts)
	num_parts := strings.split(parts[1], " | ")
	defer delete(num_parts)
	assert(len(num_parts) == 2)
	winning_nums := split_to_numbers(num_parts[0])
	defer delete(winning_nums)
	your_nums := split_to_numbers(num_parts[1])
	defer delete(your_nums)
	overlap: int = 0
	for n1 in winning_nums {
		for n2 in your_nums {
			if n1 == n2 {
				overlap += 1
				break
			}
		}
	}
	return Card{card_number, overlap}
}
calculate_new_cards :: proc(card: Card, cards: []Card) -> int {
	new_cards := cards[card.number:card.number + card.score]
	total := len(new_cards)
	for c in new_cards {
		total += calculate_new_cards(c, cards)
	}
	return total
}

part2 :: proc(input: ^string) -> int {
	total := 0
	lines := strings.split_lines(input^)
	defer delete(lines)
	cards := make([dynamic]Card, 0, len(lines))
	defer delete(cards)
	for line in lines {
		append(&cards, parse(line))
	}
	for card in cards {
		total += 1
		total += calculate_new_cards(card, cards[:])
	}
	return total
}


_main :: proc() {
	start_tick := time.tick_now()
	read_input_tick: time.Tick
	read_input_duration: time.Duration
	{
		str := string(TEST_INPUT)
		r := part1(&str)
		fmt.println(r)
		assert(r == 13)
	}
	{
		str := string(TEST_INPUT)
		r := part2(&str)
		fmt.println(r)
		assert(r == 30)
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
			str := string(input)
			r := part1(&str)
			fmt.println(r)
			assert(r == 28750)
		}
		{
			str := string(input)
			r := part2(&str)
			fmt.println(r)
			assert(r == 10212704)
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
