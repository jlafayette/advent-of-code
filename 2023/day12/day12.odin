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

part1_2 :: proc(input: []u8) -> int {
	total := 0
	input_ := input
	for line in bytes.split_iterator(&input_, {'\n'}) {
		// fmt.println("\n", string(line))
		r := parse(line)
		total += sliding_fit_solve(r)
	}
	return total
}
// sliding fit solver
// while loop with q to store items in the tree
// split function
// eval function (ok or reject)

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
	reserve(&n.grps, len(record.grps))
	for grp in record.grps {
		append(&n.grps, grp)
	}
	return n
}
node_to_string :: proc(n: ^Node) -> string {
	b := strings.builder_make()
	// defer strings.builder_destroy(&b)

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
	enable:        bool,
	seg:           Seg,
	index:         int,
	merge_forward: bool,
}
branch :: proc(q: ^Q, n: ^Node) -> (ok: bool) {
	// branch n, putting up to 2 new nodes on the q
	// if node is invalid (no chance of working), return
	// without putting anything back on the q
	fmt.println(node_to_string(n))
	ok = true

	if len(n.grps) == 0 {return}
	grp := n.grps[0]

	br_acc := 0 // store BR count from last seg
	optional_br_acc := 0 // discarded but available
	final_seg_i := -1
	final_seg_remaining := 0
	other_i := -1
	edit1: Edit
	edit2: Edit
	otherEdit: Edit
	seg_loop: for seg, seg_i in n.segs {
		last := seg_i + 1 == len(n.segs)
		switch seg.state {
		case .BR:
			{
				if seg.len + br_acc > grp {
					fmt.println("    x .BR set.len + br_acc > grp")
					return
				}
				if seg.len + br_acc == grp || seg.len + br_acc + optional_br_acc >= grp {
					next_seg: Seg = {
						state = .OP,
						len   = 1,
					}
					if !last {
						next_seg = n.segs[seg_i + 1]
					}

					optional_br_used := grp - (seg.len + br_acc)
					// TODO: shift edits

					edit1.enable = true
					edit1.seg = next_seg
					edit1.index = seg_i + 1
					// final_seg_remaining = next_seg.len
					if next_seg.state == .UN {
						edit1.seg.len -= 1
						// final_seg_remaining -= 1
					}
					// final_seg_i = seg_i + 1
					fmt.println("    x .BR seg.len == grp")
					break seg_loop
				} else {
					br_acc += seg.len
				}
			}
		case .UN:
			{
				// get next_seg
				next_seg: Seg = {
					state = .OP,
					len   = 1,
				}
				if !last {
					next_seg = n.segs[seg_i + 1]
				}

				// try to slot in the group
				if (seg.len + br_acc) < grp {
					// Discard UN group if it can't fit and is followed by
					// a OP group, such as in this example
					// ??.#### 4
					discard := br_acc == 0 && next_seg.state == .OP && !last

					// also discard if followed by .BR and combined it would
					// be too large to fit
					// ?### 3
					if next_seg.state == .BR && ((br_acc + seg.len + next_seg.len) > grp) {
						discard = true
					}

					if discard {
						fmt.println("   discard:", seg, seg_i)
						// For cases like .??## 3 where we want to carry over 1 from
						// the UN grp even though as a whole it has been discarded
						optional_br_acc = seg.len - 1
					} else {
						br_acc += seg.len
						if other_i == -1 {
							other_i = seg_i
						}
					}
					continue seg_loop
				}

				// check next to make sure it's not BR
				if (seg.len + br_acc) == grp {
					if next_seg.state == .BR {
						if br_acc > 0 {
							// Can't make this work
							fmt.println("    x .UN (seg.len+br_acc) == grp")
							return
						} else {
							optional_br_acc = seg.len
							continue seg_loop
						}
					}
				}

				// we can slot it!
				// how much of this UN seg do we need?
				// final_seg_i = seg_i
				if other_i == -1 {
					other_i = seg_i
				}
				// final_seg_remaining = seg.len - (grp - br_acc)
				// final_seg_remaining -= 1 // we need a buffer .
				edit1.enable = true
				edit1.seg = seg
				edit1.index = seg_i
				edit1.seg.len -= (grp - br_acc)
				edit1.seg.len -= 1 // we need a buffer .
				if next_seg.state == .BR {
					break seg_loop
					// fmt.println("ERROR: next_seg.state == .BR")
					// fmt.println(node_to_string(n))
					// // assert(next_seg.state != .BR)
					// return false
				}

				// Do we effect the next seg? (resolve ?->. for example)
				if edit1.seg.len < 0 && next_seg.state == .UN {
					if next_seg.len == 1 {
						// next seg is turned into ., skip forward to next->next
						next_next_seg := Seg{.OP, 1}
						if seg_i + 2 < len(n.segs) {
							next_next_seg = n.segs[seg_i + 2]
						}
						edit1.seg = next_next_seg
						edit1.index = seg_i + 2

						// final_seg_i += 2
						// final_seg_remaining = 9999 // high number means all of it remains
					} else {
						// one of next seg will be turned into .
						// final_seg_i += 1
						// final_seg_remaining = next_seg.len - 1
						edit1.seg = next_seg
						edit1.seg.len = next_seg.len - 1
						edit1.index = seg_i + 1
					}
				}
				break seg_loop
			}
		case .OP:
			{
				if br_acc > 0 {
					fmt.println("   x .OP (br_acc > 0)")
					return
				}
				// br_acc = 0
			}
		}
	}
	fmt.println("  grp:", grp, "final:", edit1.index, edit1.seg.len, "other:", other_i)
	fmt.println("  edit1:", edit1)
	if edit1.enable {
		// if slotted, then add that to q
		n1: Node
		if edit1.index < len(n.segs) {
			if edit1.seg.len > 0 {
				append(&n1.segs, edit1.seg)
			}
			for seg, i in n.segs[edit1.index + 1:] {
				append(&n1.segs, seg)
			}
			for grp in n.grps[1:] {
				append(&n1.grps, grp)
			}
		}
		fmt.println("  q<-", node_to_string(&n1))
		queue.push_back(q, n1)
	}

	// then add a version to the q where
	// the opposite is true, (don't slot)
	if other_i > -1 {
		n2: Node

		discarded_count := 0
		for seg, i in n.segs {
			if i < other_i && seg.state == .UN {
				// leave out discarded UN segments
				discarded_count += 1
				continue
			}
			if i == other_i {
				assert(seg.state == .UN)
				append_op := true
				if i > 0 {
					if n.segs[i - 1].state == .OP {
						n2.segs[i - discarded_count - 1].len += 1
						append_op = false
					}
				}
				if append_op {
					append(&n2.segs, Seg{.OP, 1})
				}
				if seg.len > 1 {
					append(&n2.segs, Seg{seg.state, seg.len - 1})
				}
			} else {
				append(&n2.segs, seg)
			}
		}
		for grp in n.grps {
			append(&n2.grps, grp)
		}
		fmt.println("  q<-", node_to_string(&n2))
		queue.push_back(q, n2)
	}
	return
}
node_fully_resolved :: proc(n: ^Node) -> bool {
	for seg in n.segs {
		if seg.state == .UN {
			return false
		}
	}
	return true
}
node_valid :: proc(n: ^Node) -> bool {
	grp_i := 0
	for seg in n.segs {
		assert(seg.state != .UN)
		if seg.state == .BR {
			if grp_i >= len(n.grps) {
				return false
			}
			if seg.len != n.grps[grp_i] {
				return false
			}
			grp_i += 1
		}
	}
	return grp_i == len(n.grps)
}
node_resolved :: proc(n: ^Node) -> (int, bool) {
	br_count := 0
	un_count := 0
	grp_space := 0
	first_non_op := false

	for seg in n.segs {
		switch seg.state {
		case .BR:
			{
				first_non_op = true
				br_count += seg.len
				grp_space += seg.len
			}
		case .UN:
			{
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
	one_grp := len(n.grps) == 1
	if br_count == 0 && one_grp && n.grps[0] == 1 && un_count > 0 {
		return un_count, true
	}

	// ?? 2 --- not sure how common this is and if it's worth it
	if one_grp && len(n.segs) == 1 && n.segs[0].state == .UN {
		if n.segs[0].len == n.grps[0] {
			return 1, true
		}
	}

	//  ...???#?#?????? 1,8,2 --- requires 13, only have 12
	grp_space_required := 0
	for grp in n.grps {
		grp_space_required += grp
	}
	grp_space_required += len(n.grps) - 1 // . between grps
	if grp_space_required > grp_space {
		return 0, true
	}

	// ?? --- currently branch will return this kind of thing
	// ????? 2
	// -> ??
	// -> .???? 2
	if len(n.grps) == 0 && br_count == 0 {
		return 1, true
	}

	// not fully resolved
	if un_count > 0 {
		return 0, false
	}

	// node is fully resolved since UN count is 0
	grp_i := 0
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
	q: Q
	node: Node = node_make(record)
	queue.push_back(&q, node)
	loop_count := 0
	for queue.len(q) > 0 {
		loop_count += 1
		n := queue.pop_back(&q)
		fmt.println("pop:", node_to_string(&n))
		defer node_destroy(&n)
		arrs, resolved := node_resolved(&n)
		if resolved {
			if arrs > 0 {
				fmt.println("-> +", arrs, sep = "")
				possible_arrangments += arrs
			}
			continue
		}
		// if node_resolved(&n) {
		// 	if node_valid(&n) {
		// 		fmt.println("-> +1")
		// 		possible_arrangments += 1
		// 	}
		// 	continue
		// }
		ok := branch(&q, &n)
		if !ok {
			node := node_make(record)
			fmt.println("ERROR: branch failed\n ", node_to_string(&node))
		}
	}
	fmt.println("loops:", loop_count)
	return possible_arrangments
}


part2 :: proc(input: []u8) -> int {
	return 0
}

test_compare :: proc() {
	input, ok := os.read_entire_file_from_filename("input")
	defer delete(input)
	assert(ok)
	for line in bytes.split_iterator(&input, {'\n'}) {
		// fmt.println("\n", string(line))
		record := parse(line)
		a1 := solve(record)
		a2 := sliding_fit_solve(record)
		if a1 != a2 {
			fmt.println("got different answers for line:", string(line), "expected", a1, "got", a2)
			return
		}
	}
}

test :: proc() {
	{
		line := "???.### 1,1,3"
		record := parse(transmute([]u8)line)
		r := sliding_fit_solve(record)
		assert(r == 1)
	}
	{
		line := ".??..??...?##. 1,1,3"
		record := parse(transmute([]u8)line)
		r := sliding_fit_solve(record)
		assert(r == 4)
	}
	{
		line := "?#?#?#?#?#?#?#? 1,3,1,6"
		record := parse(transmute([]u8)line)
		r := sliding_fit_solve(record)
		assert(r == 1)
	}
	{
		line := "????.#...#... 4,1,1"
		record := parse(transmute([]u8)line)
		r := sliding_fit_solve(record)
		assert(r == 1)
	}
	{
		line := "????.######..#####. 1,6,5"
		record := parse(transmute([]u8)line)
		r := sliding_fit_solve(record)
		assert(r == 4)
	}
	{
		line := "?###???????? 3,2,1"
		record := parse(transmute([]u8)line)
		r := sliding_fit_solve(record)
		assert(r == 10)
	}
	// compare failures
	{
		line := "##????????#?#?????? 4,1,8,2"
		// line := "???#?#?????? 8,2"
		record := parse(transmute([]u8)line)
		r := sliding_fit_solve(record)
		assert(r == 4)
	}
	{
		line := "?????.??????##. 2,3,3"
		// line := "????? 2"
		// line := "??.??????##. 3,3"
		// line := "??##. 3"
		record := parse(transmute([]u8)line)
		r := sliding_fit_solve(record)
		assert(r == 8)
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

		// line := "?????.??????##. 2,3,3"
		// line := "????? 2"
		// line := "??.??????##. 3,3"
		// line := "??##. 3"

		// line := ".??#??.??# 3,2" // 3
		line := "??# 2"
		record := parse(transmute([]u8)string(line))
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
