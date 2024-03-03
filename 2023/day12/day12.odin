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
	args := os.args[1:]

	if slice.contains(args, "-v") {
		level = .Info
	} else if slice.contains(args, "-vv") {
		level = .Debug
	}

	if slice.contains(args, "-t") || slice.contains(args, "-test") {
		test()
	} else if slice.contains(args, "-c") || slice.contains(args, "-compare") {
		test_compare()
	} else {
		_main()
	}
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
record_destroy :: proc(r: ^Record) {
	delete(r.springs)
	delete(r.grps)
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
parse2 :: proc(line: []u8) -> Record {
	r: Record
	defer record_destroy(&r)
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

	// expanded
	r2: Record
	for i in 0 ..< 5 {
		for state in r.springs {
			append(&r2.springs, state)
		}
		if i != 4 {
			append(&r2.springs, State.UN)
		}

		for grp in r.grps {
			append(&r2.grps, grp)
		}
	}

	return r2
}

part1_2 :: proc(input: []u8) -> int {
	total := 0
	input_ := input
	for line in bytes.split_iterator(&input_, {'\n'}) {
		log_info("\n", string(line))
		r := parse(line)
		defer record_destroy(&r)
		total += sliding_fit_solve(r)
	}
	return total
}


// --- sliding fit solver


// Segment of springs with same state
Seg :: struct {
	state: State,
	len:   int,
}
Node :: struct {
	grps: [dynamic]int,
	segs: [dynamic]Seg,
}
node_make :: proc(record: Record) -> Node {
	n: Node
	seg: Seg = {.OP, 1}
	for s in record.springs {
		if s == seg.state {
			seg.len += 1
		} else {
			append(&n.segs, Seg{seg.state, seg.len})
			seg.state = s
			seg.len = 1
		}
	}
	append(&n.segs, Seg{seg.state, seg.len})
	// n.grps = record.grps[:]
	reserve(&n.grps, len(record.grps))
	for grp in record.grps {
		append(&n.grps, grp)
	}
	return n
}

node_to_string :: proc(n: ^Node) -> string {
	b := strings.builder_make()
	defer strings.builder_destroy(&b)

	for seg, i in n.segs {
		for j := seg.len; j > 0; j -= 1 {
			char := '.'
			switch seg.state {
			case .OP:
				{char = '.'}
			case .BR:
				{char = '#'}
			case .UN:
				{char = '?'}
			}
			fmt.sbprint(&b, char)
		}
	}
	fmt.sbprint(&b, " ")
	for grp, i in n.grps {
		fmt.sbprint(&b, grp)
		if i < len(n.grps) - 1 {
			fmt.sbprint(&b, ",")
		}
	}

	return strings.to_string(b)
}
Q :: queue.Queue(Node)
Edit :: struct {
	enable: bool,
	seg:    Seg,
	index:  int,
}
OtherEdit :: struct {
	enable:           bool,
	index:            int,
	optional_br:      bool,
	optional_br_used: int,
	optional_br_acc:  int,
}
add_seg :: proc(segs: ^[dynamic]Seg, seg: Seg) {
	if seg.len == 0 {
		return
	}
	if len(segs) > 0 {
		if segs[len(segs) - 1].state == seg.state {
			segs[len(segs) - 1].len += seg.len
			return
		}
	}
	append(segs, seg)
}
branch2 :: proc(q: ^Q, n: ^Node) -> (ok: bool) {
	// branch n, putting up to 2 new nodes on the q

	n1: Node
	reserve(&n1.grps, len(n.grps))
	reserve(&n1.segs, len(n.segs) + 1)
	n2: Node
	reserve(&n2.grps, len(n.grps))
	reserve(&n2.segs, len(n.segs) + 1)
	done := false
	prev := Seg{.OP, 1}
	carry_br := 0
	for seg, i in n.segs {
		defer prev = seg
		if !done && seg.state == .UN {
			done = true
			// n1 flip 1 UN -> BR
			{
				add_seg(&n1.segs, Seg{.BR, 1})
				add_seg(&n1.segs, Seg{seg.state, seg.len - 1})
			}
			// n2 flip 1 UN -> OP
			{
				add_seg(&n2.segs, Seg{.OP, 1})
				add_seg(&n2.segs, Seg{seg.state, seg.len - 1})
			}
		} else {
			add_seg(&n1.segs, seg)
			add_seg(&n2.segs, seg)
		}
	}
	if done {
		// n1.grps = n.grps
		// n2.grps = n.grps
		for grp in n.grps {
			append(&n1.grps, grp)
			append(&n2.grps, grp)
		}

		log_info("  q<-", node_to_string(&n1))
		queue.push_back(q, n1)
		log_info("  q<-", node_to_string(&n2))
		queue.push_back(q, n2)
		return true
	} else {
		return false
	}
}
node_resolved2 :: proc(n: ^Node) -> (int, bool) {
	br_count := 0
	un_count := 0
	grp_space := 0
	first_non_op := false
	first_non_op_seg: Seg

	br_seg_count := 0

	first_un := false
	grp_i := 0

	for seg, seg_i in n.segs {
		switch seg.state {
		case .BR:
			{
				if !first_un {
					if grp_i >= len(n.grps) {
						log_debug(" r x grp_i >= len(grps)")
						return 0, true
					}
					next_seg := Seg{.OP, 1}
					if seg_i < len(n.segs) - 1 {
						next_seg = n.segs[seg_i + 1]
					}
					if seg.len != n.grps[grp_i] && next_seg.state != .UN {
						log_debug(" r x seg.len != grp && next != UN")
						log_debug("  ", n.grps[grp_i], seg, next_seg)
						return 0, true
					}
					grp_i += 1
				}
				if !first_non_op {
					first_non_op_seg = seg
				}
				first_non_op = true
				br_count += seg.len
				grp_space += seg.len
				br_seg_count += 1
			}
		case .UN:
			{
				defer first_un = true
				if !first_non_op {
					first_non_op_seg = seg
				}
				first_non_op = true
				un_count += seg.len
				grp_space += seg.len
			}
		case .OP:
			{
				if first_non_op {
					grp_space += 1
				}
			}
		}
	}

	// Checks that work with either fully resolved or not
	if first_non_op && first_non_op_seg.state == .BR {
		if first_non_op_seg.len > n.grps[0] {
			return 0, true
		}
	}

	// not fully resolved
	if un_count > 0 {
		// Some checks for non resolved nodes if it can never work

		// //  ...???#?#?????? 1,8,2 --- requires 13, only have 12
		// grp_space_required := 0
		// for grp in n.grps {
		// 	grp_space_required += grp
		// }
		// grp_space_required += len(n.grps) - 1 // . between grps
		// if grp_space_required > grp_space {
		// 	return 0, true
		// }

		// Needs more branching
		return 0, false
	}


	// node is fully resolved since UN count is 0
	grp_i = 0
	for seg in n.segs {
		assert(seg.state != .UN)
		if seg.state == .BR {
			if grp_i >= len(n.grps) {
				return 0, true
			}
			if seg.len != n.grps[grp_i] {
				return 0, true
			}
			grp_i += 1
		}
	}
	if grp_i == len(n.grps) {
		return 1, true
	} else {
		return 0, true
	}
}
node_destroy :: proc(n: ^Node) {
	delete(n.grps)
	delete(n.segs)
}

sliding_fit_solve :: proc(record: Record) -> int {
	possible_arrangments := 0
	q: Q;defer queue.destroy(&q)
	node: Node = node_make(record)
	node_str := node_to_string(&node)
	queue.push_back(&q, node)
	loop_count := 0
	for queue.len(q) > 0 {
		loop_count += 1
		n := queue.pop_back(&q)
		log_info("pop:", node_to_string(&n))
		// log_debug("    ", n)
		defer node_destroy(&n)
		arrs, resolved := node_resolved2(&n)
		if resolved {
			if arrs > 0 {
				log_info("-> +", arrs, sep = "")
				possible_arrangments += arrs
			}
			continue
		}
		ok := branch2(&q, &n)
		if !ok {
			node := node_make(record)
			log_error("ERROR: branch failed\n ", node_to_string(&node))
		}
	}
	// log_info("loops:", loop_count)
	log_warning(loop_count, "--", node_str)
	return possible_arrangments
}


part2 :: proc(input: []u8) -> int {
	total := 0
	input_ := input
	for line in bytes.split_iterator(&input_, {'\n'}) {
		log_info("\n", string(line))
		r := parse2(line)
		defer record_destroy(&r)
		total += sliding_fit_solve(r)
	}
	return total
}

test_compare :: proc() {
	input, ok := os.read_entire_file_from_filename("input")
	defer delete(input)
	assert(ok)
	total := 0
	correct := 0
	err := false
	for line in bytes.split_iterator(&input, {'\n'}) {
		total += 1
		log_info("\n", string(line))
		if !err {
			record := parse(line)
			defer record_destroy(&record)
			a1 := solve(record)
			a2 := sliding_fit_solve(record)
			if a1 != a2 {
				log_error(
					"got different answers for line:",
					string(line),
					"expected",
					a1,
					"got",
					a2,
				)
				// err = true
			} else {
				correct += 1
			}
		}
	}
	log_warning("Got", correct, "out of", total, "correct")
}

test :: proc() {
	{
		line := "???.### 1,1,3"
		record := parse(transmute([]u8)line);defer record_destroy(&record)
		r := sliding_fit_solve(record)
		assert(r == 1)
	}
	{
		line := ".??..??...?##. 1,1,3"
		record := parse(transmute([]u8)line);defer record_destroy(&record)
		r := sliding_fit_solve(record)
		assert(r == 4)
	}
	{
		line := "?#?#?#?#?#?#?#? 1,3,1,6"
		record := parse(transmute([]u8)line);defer record_destroy(&record)
		r := sliding_fit_solve(record)
		assert(r == 1)
	}
	{
		line := "????.#...#... 4,1,1"
		record := parse(transmute([]u8)line);defer record_destroy(&record)
		r := sliding_fit_solve(record)
		assert(r == 1)
	}
	{
		line := "????.######..#####. 1,6,5"
		record := parse(transmute([]u8)line);defer record_destroy(&record)
		r := sliding_fit_solve(record)
		assert(r == 4)
	}
	{
		line := "?###???????? 3,2,1"
		record := parse(transmute([]u8)line);defer record_destroy(&record)
		r := sliding_fit_solve(record)
		assert(r == 10)
	}
	// compare failures
	{
		line := "##????????#?#?????? 4,1,8,2"
		// line := "???#?#?????? 8,2"
		record := parse(transmute([]u8)line);defer record_destroy(&record)
		r := sliding_fit_solve(record)
		assert(r == 4)
	}
	{
		line := "?????.??????##. 2,3,3"
		// line := "????? 2"
		// line := "??.??????##. 3,3"
		// line := "??##. 3"
		record := parse(transmute([]u8)line);defer record_destroy(&record)
		r := sliding_fit_solve(record)
		assert(r == 8)
	}
	{
		line := ".??#??.??# 3,2" // 3
		record := parse(transmute([]u8)line);defer record_destroy(&record)
		r := sliding_fit_solve(record)
		assert(r == 3)
	}
	{
		line := "????????##?. 2,2,3" // 9
		record := parse(transmute([]u8)line);defer record_destroy(&record)
		r := sliding_fit_solve(record)
		assert(r == 9)
	}

}

_main :: proc() {
	start_tick := time.tick_now()

	input, ok := os.read_entire_file_from_filename("input")
	defer delete(input)
	assert(ok)
	read_input_tick := time.tick_now()
	read_input_duration := time.tick_diff(start_tick, read_input_tick)

	// {
	// 	t := transmute([]u8)string(TEST_INPUT)
	// 	r := part1(t)
	// 	fmt.println(r)
	// 	assert(r == 21)
	// }
	// {
	// 	t := transmute([]u8)string(TEST_INPUT)
	// 	r := part1_2(t)
	// 	fmt.println(r)
	// 	assert(r == 21)
	// }

	{
		// line := "##????????#?#?????? 4,1,8,2"
		// line := "???#?#?????? 8,2"

		// line := "?????.??????##. 2,3,3" // 8
		// line := "????? 2"
		// line := "??.??????##. 3,3"
		// line := "??##. 3"

		// line := ".??#??.??# 3,2" // 3
		// line := "??# 2"

		// line := "???????#?????#..?? 5,2" // 4
		// line := "?????#?????#..?? 5,2"

		// not solved
		// line := "????????##?. 2,2,3" // 9

		// line := ".#?.?.?#?#..??##.?? 1,1,3,4,1" // 2

		line := ".??..??...?##.?.??..??...?##.?.??..??...?##.?.??..??...?##.?.??..??...?##. 1,1,3,1,1,3,1,1,3,1,1,3,1,1,3"
		// line := "?###??????????###??????????###??????????###??????????###???????? 3,2,1,3,2,1,3,2,1,3,2,1,3,2,1"

		// line := "?#?#?#?#?#?#?#? 1,3,1,6" // 1

		record := parse(transmute([]u8)string(line));defer record_destroy(&record)
		r := sliding_fit_solve(record)
		fmt.println(r)
	}

	// {
	// 	r := part1(input)
	// 	fmt.println(r)
	// 	assert(r == 7017)
	// }
	// {
	// 	r := part1_2(input)
	// 	fmt.println(r)
	// 	assert(r == 7017)
	// }
	part1_tick := time.tick_now()
	part1_duration := time.tick_diff(start_tick, part1_tick)
	// {
	// 	t := transmute([]u8)string(TEST_INPUT)
	// 	r := part2(t)
	// 	fmt.println(r)
	// 	assert(r == 525152)
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
