package day12

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

TEST_INPUT :: `???.### 1,1,3
.??..??...?##. 1,1,3
?#?#?#?#?#?#?#? 1,3,1,6
????.#...#... 4,1,1
????.######..#####. 1,6,5
?###???????? 3,2,1`

// Spring state is either OPerational, BRoken, UNknown
State :: enum {
	OP,
	BR,
	UN,
}
Record :: struct {
	springs: [dynamic]State,
	grps:    [dynamic]int,
}
springs_fmt :: proc(springs: []State) -> string {
	b := strings.builder_make(len(springs))
	for s in springs {
		switch s {
		case .OP:
			fmt.sbprint(&b, ".")
		case .BR:
			fmt.sbprint(&b, "#")
		case .UN:
			fmt.sbprint(&b, "?")
		}
	}
	return strings.to_string(b)
}
parse :: proc(line: []u8) -> Record {
	r: Record
	// spring states
	last_i: int // to resume place to search in line for grps
	for char, i in line {
		current: State
		done := false
		switch char {
		case '.':
			{current = .OP}
		case '#':
			{current = .BR}
		case '?':
			{current = .UN}
		case:
			{done = true}
		}
		if done {last_i = i;break}
		append(&r.springs, current)
	}
	// grps
	grp_data: []u8 = line[last_i + 1:]
	for num in bytes.split_iterator(&grp_data, {','}) {
		v, ok := strconv.parse_int(string(num), 10)
		if ok {
			append(&r.grps, v)
		}
	}
	return r
}

record_matches_grps :: proc(springs: []State, grps: []int) -> bool {
	group_index := 0
	group := grps[group_index]
	last: State = .OP
	current_br := 0
	for s in springs {
		if s == .BR {
			current_br += 1
		}
		if last == .BR && s != .BR {
			if current_br != group {
				return false
			}
			group_index += 1
			if group_index < len(grps) {
				group = grps[group_index]
			} else {
				group = 0
			}
			current_br = 0
		}
		// if s == .UN {
		// 	fmt.println("ERROR: ? found in springs:\n", springs_fmt(springs))
		// }
		assert(s != .UN)
		last = s
	}
	// fmt.println("-", current_br, "==", group, "&&", group_index, ">=", len(grps) - 1)
	return current_br == group && group_index >= len(grps) - 1
}

product :: proc(n: int) -> [dynamic][]bool {
	size := int(math.pow_f64(2, f64(n)))
	results := make([dynamic][]bool)
	for i in 0 ..< size {
		s := make_slice([]bool, n)
		append(&results, s)
	}
	for i := n - 1; i > -1; i -= 1 {
		// fmt.println("i:", i)
		switch_after := int(math.pow(2, f64(i)))
		c := true
		for _, j in results {
			results[j][n - 1 - i] = c
			switch_after -= 1
			if switch_after <= 0 {
				switch_after = int(math.pow(2, f64(i)))
				c = !c
			}
		}
	}
	return results
}
U :: struct {
	state: State,
	index: int,
}
print_results :: proc(results: [dynamic][]bool) {
	b := strings.builder_make()
	defer strings.builder_destroy(&b)
	for r, ri in results {
		for v in r {
			switch v {
			case true:
				fmt.sbprint(&b, "T")
			case false:
				fmt.sbprint(&b, "F")
			}
		}
		if ri < len(results) - 1 {
			fmt.sbprint(&b, ", ")
		}
	}
	fmt.println(strings.to_string(b))
}

print_result :: proc(result: []bool) {
	b := strings.builder_make()
	defer strings.builder_destroy(&b)
	for v in result {
		switch v {
		case true:
			fmt.sbprint(&b, "T")
		case false:
			fmt.sbprint(&b, "F")
		}
	}
	fmt.println(strings.to_string(b))
}
solve :: proc(record: Record) -> int {
	// for each UN in springs, switch it OP,BR
	arrs := 0

	unknowns: [dynamic]U
	for s, i in record.springs {
		if s == .UN {
			append(&unknowns, U{.UN, i})
		}
	}
	// product [.OP, .BR] for len(unknowns)
	possibilities := product(len(unknowns))
	for p in possibilities {
		// print_result(p)
		new_springs := make_slice([]State, len(record.springs)) //  record.springs
		for s, i in record.springs {
			new_springs[i] = s
		}
		for b, i in p {
			new_springs[unknowns[i].index] = State(b)
		}
		rmg := record_matches_grps(new_springs, record.grps[:])
		// fmt.println("  springs:", springs_fmt(new_springs))
		// fmt.println(" ", rmg)
		if rmg {
			arrs += 1
		}
	}
	fmt.println("found", arrs, "valid arrangements")
	return arrs
}

part1 :: proc(input: []u8) -> int {
	total := 0
	input_ := input
	// i := 0
	for line in bytes.split_iterator(&input_, {'\n'}) {
		fmt.println("\n", string(line))
		r := parse(line)
		// fmt.println(r)
		total += solve(r)
		// if i >= 1 {break}
		// i += 1
	}
	return total
}

// sliding fit solver
// while loop with q to store items in the tree
// split function
// eval function (ok or reject)
Node :: struct {
	id: int, // temp
}
Q :: queue.Queue(Node)
branch :: proc(q: ^Q, n: ^Node) {
	// branch n, putting up to 2 new nodes on the q
	// if node is invalid (no chance of working), return
	// without putting anything back on the q

	// temp code to test overall q and loop
	n1 := Node {
		id = n.id - 1,
	}
	n2 := Node {
		id = n.id - 2,
	}
	queue.push_back(q, n1)
	queue.push_back(q, n2)
}
node_fully_resolved :: proc(n: ^Node) -> bool {
	// TODO: implement
	return n.id <= 0
}
node_valid :: proc(n: ^Node) -> bool {
	// TODO: implement
	return n.id == 0
}
node_destroy :: proc(n: ^Node) {
	// TODO: implement
}

sliding_fit_solve :: proc(record: Record) -> int {
	possible_arrangments := 0
	q: Q
	node: Node
	node.id = 3
	queue.push_back(&q, node)
	for queue.len(q) > 0 {
		n := queue.pop_back(&q)
		fmt.println("pop:", n.id)
		defer node_destroy(&n)
		if node_fully_resolved(&n) {
			if node_valid(&n) {
				possible_arrangments += 1
			}
			continue
		}
		branch(&q, &n)
	}
	return possible_arrangments
}


part2 :: proc(input: []u8) -> int {
	return 0
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
		assert(r == 21)
	}
	{
		line := ".??..??...?##. 1,1,3"
		fmt.println("---", line)
		record := parse(transmute([]u8)line)
		r := sliding_fit_solve(record)
		fmt.println(r)
	}
	{
		r := part1(input)
		fmt.println(r)
		assert(r == 7017)
	}
	part1_tick := time.tick_now()
	part1_duration := time.tick_diff(start_tick, part1_tick)
	// {
	// 	t := transmute([]u8)string(TEST_INPUT)
	// 	r := part2(t)
	// 	fmt.println(r)
	// 	assert(r == )
	// }
	// {
	// 	r := part2(input)
	// 	fmt.println(r)
	// 	assert(r == )
	// }
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
