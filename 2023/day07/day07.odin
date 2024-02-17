package day07

import "core:bytes"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strconv"
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

TEST_INPUT :: `32T3K 765
T55J5 684
KK677 28
KTJJT 220
QQQJA 483`

Card :: struct {
	label:    u8,
	strength: int,
}
card_greater :: proc(i, j: Card) -> bool {
	return i.strength > j.strength
}
card_from_label :: proc(label: u8, part: int) -> Card {
	if part == 1 {
		switch (label) {
		case 'A':
			return {label, 14}
		case 'K':
			return {label, 13}
		case 'Q':
			return {label, 12}
		case 'J':
			return {label, 11}
		case 'T':
			return {label, 10}
		case '2' ..= '9':
			return {label, int(label - '0')}
		case:
			assert(false)
		}
	} else {
		switch (label) {
		case 'A':
			return {label, 14}
		case 'K':
			return {label, 13}
		case 'Q':
			return {label, 12}
		case 'T':
			return {label, 10}
		case '2' ..= '9':
			return {label, int(label - '0')}
		case 'J':
			return {label, 1}
		case:
			assert(false)
		}
	}
	return {'0', 0}
}
Type :: enum {
	HighCard,
	OnePair,
	TwoPair,
	ThreeOfAKind,
	FullHouse,
	FourOfAKind,
	FiveOfAKind,
}
HandStrength :: struct {
	type:      Type,
	strengths: [5]int,
}
Hand :: struct {
	cards:    [5]Card,
	bid:      int,
	strength: HandStrength,
}
hand_from_str :: proc(s: []u8, part: int) -> Hand {
	hand: Hand

	split1 := bytes.split(s, {' '})
	defer delete(split1)
	assert(len(split1) == 2)
	assert(len(split1[0]) == 5)
	for char, i in split1[0] {
		hand.cards[i] = card_from_label(char, part)
		hand.strength.strengths[i] = hand.cards[i].strength // before sorting
	}
	// sort by reverse strength
	slice.sort_by(hand.cards[:], card_greater)

	ok := false
	hand.bid, ok = strconv.parse_int(string(split1[1]))
	assert(ok)

	hand.strength.type = hand_type(hand.cards[:], part)

	return hand
}
counter_add :: proc(counter: ^map[u8]int, label: u8) {
	if label in counter {
		counter[label] += 1
	} else {
		counter[label] = 1
	}
}
counter_get_most_common :: proc(counter: ^map[u8]int) -> (mc_label: u8, mc: int) {
	for key, value in counter {
		if value > mc {
			mc = value
			mc_label = key
		}
	}
	return
}
hand_type :: proc(cards: []Card, part: int) -> Type {
	counter: map[u8]int
	for card in cards {
		label := card.label
		counter_add(&counter, label)
	}
	label: u8
	first: int
	if part == 2 {
		jokers := counter['J']
		delete_key(&counter, 'J')
		label, first = counter_get_most_common(&counter)
		delete_key(&counter, label)
		first += jokers
	} else {
		label, first = counter_get_most_common(&counter)
		delete_key(&counter, label)
	}
	_, second := counter_get_most_common(&counter)
	type: Type
	if first == 5 {
		type = .FiveOfAKind
	} else if first == 4 {
		type = .FourOfAKind
	} else if first == 3 && second == 2 {
		type = .FullHouse
	} else if first == 3 {
		type = .ThreeOfAKind
	} else if first == 2 && second == 2 {
		type = .TwoPair
	} else if first == 2 {
		type = .OnePair
	} else {
		type = .HighCard
	}
	return type
}

parse :: proc(data: []u8, part: int) -> [dynamic]Hand {
	d := data
	hands: [dynamic]Hand
	for line in bytes.split_iterator(&d, {'\n'}) {
		append(&hands, hand_from_str(line, part))
	}
	return hands
}

hand_less :: proc(i, j: Hand) -> bool {
	if i.strength.type == j.strength.type {
		for k in 0 ..< 5 {
			i_s := i.strength.strengths[k]
			j_s := j.strength.strengths[k]
			if i_s == j_s {
				continue
			}
			return i_s < j_s
		}
	}
	return i.strength.type < j.strength.type
}
part1_2 :: proc(input: []u8, part: int) -> int {
	hands := parse(input, part)
	slice.sort_by(hands[:], hand_less)
	winnings := 0
	for hand, i in hands {
		rank := i + 1
		winnings += hand.bid * rank
	}
	return winnings
}
part1 :: proc(input: []u8) -> int {
	return part1_2(input, 1)
}
part2 :: proc(input: []u8) -> int {
	return part1_2(input, 2)
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
		r := part1(t)
		fmt.println(r)
		assert(r == 6440)
	}
	{
		r := part1(input)
		fmt.println(r)
		assert(r == 251106089)
	}
	part1_tick := time.tick_now()
	part1_duration := time.tick_diff(start_tick, part1_tick)
	{
		t := transmute([]u8)string(TEST_INPUT)
		r := part2(t)
		fmt.println(r)
		assert(r == 5905)
	}
	{
		r := part2(input)
		fmt.println(r)
		assert(r == 249620106)
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
