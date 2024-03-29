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

LOG :: #config(LOG, false)

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
parse2 :: proc(line: []u8, expand: bool = true) -> Node {
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
	r2: Record;defer record_destroy(&r2)
	add_x_times: int = 5 if expand else 1
	for i in 0 ..< add_x_times {
		for state in r.springs {
			append(&r2.springs, state)
		}
		if i != add_x_times - 1 {
			append(&r2.springs, State.UN)
		}

		for grp in r.grps {
			append(&r2.grps, grp)
		}
	}
	return node_make(r2)
}

part1_2 :: proc(input: []u8) -> int {
	total := 0
	input_ := input
	for line in bytes.split_iterator(&input_, {'\n'}) {
		when LOG {
			log_info("\n", string(line))
		}
		n := parse2(line, false)
		// defer node_destroy(&n)
		total += sliding_fit_solve(n, false)
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
	grps:          [dynamic]int,
	segs:          [dynamic]Seg,
	patterns:      Patterns,
	max_grp:       int,
	max_grp_count: int,
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
	max_grp := 0
	for grp in record.grps {
		append(&n.grps, grp)
		max_grp = max(max_grp, grp)
	}
	max_count := 0
	for grp in n.grps {
		if grp == max_grp {
			max_count += 1
		}
	}
	n.patterns = patterns_make(n.grps[:], false)
	n.max_grp = max_grp
	n.max_grp_count = max_count
	return n
}

node_to_string :: proc(n: ^Node) -> string {

	b := strings.builder_make(context.temp_allocator)
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
prev_seg :: proc(segs: []Seg, i: int) -> Seg {
	if i == 0 {
		return Seg{.OP, 1}
	} else {
		return segs[i - 1]
	}
}
next_seg :: proc(segs: []Seg, i: int) -> Seg {
	if i == len(segs) - 1 {
		return Seg{.OP, 1}
	} else {
		return segs[i + 1]
	}
}
seg_end_distance :: proc(length: int, i: int) -> int {
	return min(i, (length - 1) - i)
}
branch2 :: proc(q: ^Q, n: ^Node) -> (ok: bool) {
	// branch n, putting up to 2 new nodes on the q

	n1: Node
	n2: Node

	flip_i := -1
	hi_score := -1
	for seg, i in n.segs {
		if seg.state != .UN {
			continue
		}
		prev := prev_seg(n.segs[:], i)
		next := next_seg(n.segs[:], i)
		distance := seg_end_distance(len(n.segs), i)
		score := distance
		if prev.state == .BR {
			score += prev.len
		}
		if next.state == .BR {
			score += next.len
		}
		if score > hi_score {
			hi_score = score
			flip_i = i
		}
	}
	if flip_i == -1 {
		return false
	}

	reserve(&n1.grps, len(n.grps))
	reserve(&n1.segs, len(n.segs) + 1)
	reserve(&n2.grps, len(n.grps))
	reserve(&n2.segs, len(n.segs) + 1)
	for seg, i in n.segs {
		if i == flip_i {
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

	max_grp := 0
	for grp in n.grps {
		max_grp = max(grp, max_grp)
		append(&n1.grps, grp)
		append(&n2.grps, grp)
	}
	max_count := 0
	for grp in n.grps {
		if grp == max_grp {
			max_count += 1
		}
	}
	n1.max_grp = max_grp
	n2.max_grp = max_grp
	n1.max_grp_count = max_count
	n2.max_grp_count = max_count

	// when LOG {log_debug("   -", node_to_string(&n1))}
	node_simplify(&n1)
	when LOG {
		log_info("  q<-", node_to_string(&n1))
	}
	n1.patterns = patterns_make(n1.grps[:], false)
	queue.push_back(q, n1)

	// when LOG {log_debug("   -", node_to_string(&n2))}
	node_simplify(&n2)
	when LOG {
		log_info("  q<-", node_to_string(&n2))
	}
	n2.patterns = patterns_make(n2.grps[:], false)
	queue.push_back(q, n2)
	return true
}
node_simplify :: proc(n: ^Node) {
	// simplify node if possible
	assert(n.max_grp != 0)
	assert(n.max_grp_count != 0)

	// create . next to locked in ###
	// ?###????? 3,2,1 -> .###.????? 3,2,1
	// (for now locked-in only applies to BR sections equal to max len)
}

Patterns :: struct {
	grp3:    [dynamic][3]int,
	grp2:    [dynamic][2]int,
	grp1:    [dynamic]int,
	br_grps: [3]int,
	br_i:    int,
	ok:      bool,
}
patterns_make :: proc(grps: []int, x5_grps: bool) -> Patterns {
	p: Patterns
	end: int
	if x5_grps {
		end = len(grps) / 5
	} else {
		end = len(grps)
	}
	// fmt.println("make:", grps, end)
	reserve(&p.grp3, end)
	reserve(&p.grp2, end)
	reserve(&p.grp1, end)
	for i in 0 ..< end {
		i1 := i
		v1 := grps[i1]
		append(&p.grp1, v1)
		if i + 1 < len(grps) {
			// i2 := i + 1
			// i2 := (i + 1) % len(grps)
			v2 := grps[i + 1]
			append(&p.grp2, [2]int{v1, v2})

			if i + 2 < len(grps) {
				// i3 := i + 2
				// i3 := (i + 2) % len(grps)
				v3 := grps[i + 2]
				append(&p.grp3, [3]int{v1, v2, v3})
			}
		}
	}
	return p
}
patterns_destroy :: proc(p: ^Patterns) {
	delete(p.grp3)
	delete(p.grp2)
	delete(p.grp1)
}
patterns_start_check :: proc(p: ^Patterns) {
	p.ok = true
	p.br_grps = {0, 0, 0}
	p.br_i = 0
}
patterns_reset :: patterns_start_check
patterns_eval_br_grps :: proc(p: ^Patterns) -> bool {
	switch p.br_i {
	case 1:
		{
			// check 1
			for g in p.grp1 {
				if p.br_grps.x == g {
					return true
				}
			}
			fmt.println("failed check 1 (", p.br_i, ")", p.br_grps.x, "not in", p.grp1)
			return false
		}
	case 2:
		{
			// check 2
			for g2 in p.grp2 {
				if p.br_grps.xy == g2 {
					return true
				}
			}
			fmt.println("failed check 2", p.br_grps.xy, "not in", p.grp2)
			return false
		}
	case 3:
		{
			// check 3
			for g3 in p.grp3 {
				if p.br_grps == g3 {
					return true
				}
			}
			fmt.println("failed check 3", p.br_grps.xyz, "not in", p.grp3)
			return false
		}
	case:
		{return true}
	}
}
patterns_check_seg :: proc(p: ^Patterns, prev, seg, next: Seg) -> bool {
	switch seg.state {
	case .OP:
		{return p.ok}
	case .BR:
		{
			if prev.state == .UN || next.state == .UN {
				// this is not something we can check
				// check existing br_grps, then reset
				p.ok = patterns_eval_br_grps(p)
				patterns_reset(p)
				return p.ok
			} else {
				assert(prev.state == .OP && next.state == .OP)
				// check for overflow of 3
				if p.br_i >= 3 {
					// if overflow, check 3, then rotate
					p.ok = patterns_eval_br_grps(p)
					// x falls off, yz rotate left, then new is added as z
					p.br_grps.xy = p.br_grps.yz
					p.br_grps.z = seg.len
					return p.ok
				} else {
					// else add br and inc br_i
					p.br_grps[p.br_i] = seg.len
					p.br_i += 1
				}
			}
		}
	case .UN:
		{return p.ok}
	}

	return p.ok
}
patterns_end_check :: proc(p: ^Patterns) -> bool {
	if !p.ok {return p.ok}
	p.ok = patterns_eval_br_grps(p)
	return p.ok
}

node_patterns_check :: proc(node: ^Node) -> bool {
	p := node.patterns
	ok := true
	patterns_start_check(&p)
	defer patterns_end_check(&p)
	prev: Seg
	next: Seg
	for seg, i in node.segs {
		prev = prev_seg(node.segs[:], i)
		next = next_seg(node.segs[:], i)
		ok = patterns_check_seg(&p, prev, seg, next)
		if !ok {
			break
		}
	}
	if ok {
		ok = patterns_end_check(&p)
	}
	return ok
}

node_resolved2 :: proc(n: ^Node) -> (int, bool) {
	if len(n.grps) == 0 {
		return 0, true
	}
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
				prev := prev_seg(n.segs[:], seg_i)
				next := next_seg(n.segs[:], seg_i)
				if !first_un {
					if grp_i >= len(n.grps) {
						// when LOG { log_debug(" r x grp_i >= len(grps)") }
						return 0, true
					}
					if seg.len != n.grps[grp_i] && next.state != .UN {
						// when LOG {
						// 	log_debug(" r x seg.len != grp && next != UN")
						// 	log_debug("  ", n.grps[grp_i], seg, next_seg)
						// }
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

		//  ...???#?#?????? 1,8,2 --- requires 13, only have 12
		grp_space_required := 0
		for grp in n.grps {
			grp_space_required += grp
		}
		grp_space_required += len(n.grps) - 1 // . between grps
		if grp_space_required > grp_space {
			return 0, true
		}
		ok := node_patterns_check(n)
		if !ok {
			fmt.println("Failed patterns check:", node_to_string(n), flush = false)
			fmt.println(n.patterns)

			return 0, true
		}

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
	patterns_destroy(&n.patterns)
}

sliding_fit_solve :: proc(node_: Node, use_split: bool = true) -> int {
	defer free_all(context.temp_allocator)
	node := node_
	possible_arrangments := 0
	if len(node.grps) == 0 {
		for seg in node.segs {
			if seg.state == .BR {
				return 0
			}
		}
		return 1
	}
	q: Q;defer queue.destroy(&q)
	node_str := node_to_string(&node)
	queue.push_back(&q, node)
	loop_count := 0
	for queue.len(q) > 0 {
		loop_count += 1
		n := queue.pop_back(&q)
		// defer node_destroy(&n)
		defer delete(n.grps)
		defer delete(n.segs)
		when LOG {
			log_info("pop:", node_to_string(&n))
		}
		// when LOG { log_debug("    ", n) }
		// time.sleep(time.Millisecond * 10)

		if use_split {
			// If possible, split node into sub-problems and solve those
			arrs, ok := split_solve(&n)
			if ok {
				when LOG {log_info("-> +", arrs, sep = "")}
				possible_arrangments += arrs
				continue
			}
		}
		arrs, resolved := node_resolved2(&n)
		if resolved {
			if arrs > 0 {
				when LOG {log_info("-> +", arrs, sep = "")}
				possible_arrangments += arrs
			}
			continue
		}
		ok := branch2(&q, &n)
		if !ok {
			log_error("ERROR: branch failed\n ", node_str)
		}
	}
	when LOG {log_info("loops:", loop_count)}
	when LOG {log_warning(loop_count, "--", node_str, "->", possible_arrangments)}
	return possible_arrangments
}

GrpSplitter :: struct {
	grps: []int,
	i:    int,
	max:  int,
}
grp_splitter_iter :: proc(g: ^GrpSplitter) -> (next: []int, last: bool, ok: bool) {
	start_i := g.i
	for grp, i in g.grps[g.i:] {
		if grp == g.max {
			end_i := i + start_i
			g.i = end_i + 1
			next = g.grps[start_i:end_i]
			last = end_i >= len(g.grps) - 1
			ok = true
			return
		}
	}
	if len(g.grps) > start_i {
		g.i = len(g.grps)
		next = g.grps[start_i:]
		last = true
		ok = true
		return
	}
	ok = false
	return
}
SegSplitter :: struct {
	segs: []Seg,
	i:    int,
	max:  int,
}
seg_splitter_iter :: proc(s: ^SegSplitter) -> ([]Seg, bool) {
	start_i := s.i
	for seg, i in s.segs[s.i:] {
		if seg.state == .BR && seg.len == s.max {
			end_i := i + start_i
			s.i = end_i + 1
			return s.segs[start_i:end_i], true
		}
	}
	if len(s.segs) > start_i {
		s.i = len(s.segs)
		return s.segs[start_i:], true
	}
	next: []Seg
	return next, false
}

split_solve :: proc(node: ^Node) -> (int, bool) {
	defer free_all(context.temp_allocator)
	// if solved, return number of arrangments, true
	// if it can't be split, return 0, false
	when LOG {
		indent_log += 2
		defer {indent_log -= 2}
	}

	// could add max_grp, max_count, segs_matching_max on node construction
	// if that helps
	segs_matching_max := 0
	for seg in node.segs {
		if seg.state == .BR && seg.len == node.max_grp {
			segs_matching_max += 1
		}
	}
	if segs_matching_max != node.max_grp_count {
		return 0, false
	}

	when LOG {log_debug("-< split_solve", node_to_string(node))}
	q: Q
	defer 
	{
		for queue.len(q) > 0 {
			n := queue.pop_back(&q)
			node_destroy(&n)
		}
		queue.destroy(&q)
	}

	// can split, iter over grps and segs
	grp_splitter_state := GrpSplitter{node.grps[:], 0, node.max_grp}
	seg_splitter_state := SegSplitter{node.segs[:], 0, node.max_grp}
	first := true
	for grps, last in grp_splitter_iter(&grp_splitter_state) {
		defer first = false
		segs, ok := seg_splitter_iter(&seg_splitter_state)
		assert(ok)
		n: Node
		reserve(&n.segs, len(segs))
		reserve(&n.grps, len(grps))
		seg_loop: for seg, i in segs {
			// When spliting, make sure ? next to # is handled correctly
			seg_ := seg
			if i == 0 && !first {
				if seg.state == .UN {
					seg_.len -= 1
				}
			}
			if i == len(segs) - 1 && !last {
				if seg.state == .UN {
					seg_.len -= 1
				}
			}
			add_seg(&n.segs, seg_)
		}
		for grp in grps {
			append(&n.grps, grp)
		}
		n.patterns = patterns_make(n.grps[:], false)
		queue.push_back(&q, n)
	}

	// while loop to solve each part of q and multiple each together
	// to get total arrangments
	possible_arrangements := 1
	loop_count := 0
	flush_q := false // set to true when done, but need to empty q and free all nodes in it
	for queue.len(q) > 0 {
		loop_count += 1
		n := queue.pop_back(&q)
		when LOG {log_debug("-< pop:", node_to_string(&n))}
		when LOG {indent_log += 2;prev_level := level;level = .Warning}
		arrs := sliding_fit_solve(n, false)
		when LOG {indent_log -= 2;level = prev_level}
		when LOG {log_debug("-< arrs *", arrs, sep = "")}
		possible_arrangements *= arrs
		if possible_arrangements == 0 {
			break
		}
	}
	when LOG {log_info("-< exit split solve", possible_arrangements)}
	return possible_arrangements, true
}

part2 :: proc(input: []u8) -> int {
	total := 0
	input_ := input
	for line in bytes.split_iterator(&input_, {'\n'}) {
		// when LOG {log_info("\n", string(line))}
		node := parse2(line)
		result := sliding_fit_solve(node, true)
		fmt.println(result, "-", string(line))
		total += result
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
			node := node_make(record)
			defer node_destroy(&node)
			a1 := solve(record)
			a2 := sliding_fit_solve(node)
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

PatternsTestCase :: struct {
	line:     string,
	expand:   bool,
	expected: bool,
	x5_grps:  bool,
}
patterns_test :: proc() {
	// .??.#..####.#....#.#...........#.#.#..#.#.####.####.#.?#???? 1,4,1,1,4,1,1,4,1,1,4,1,1,4,1
	//     1  4    1    1 X (can't have a 1,1,1 pattern)
	// 141,411,114 (allowed patterns of 3)
	// 14,41,11 (allowed patterns of 2)
	// 1,4 (allowed patterns of 1)
	// line := "??.???#???? 1,4,1"
	cases := [?]PatternsTestCase {
		 {
			line = ".??.#..####.#....#.#...........#.#.#..#.#.####.####.#.?#???? 1,4,1,1,4,1,1,4,1,1,4,1,1,4,1",
			expand = false,
			expected = false,
			x5_grps = true,
		},
		{line = "???#?? 1,1", expand = false, expected = true},
		{line = "?.#..? 1,1", expand = false, expected = true},
		{line = "# 1", expand = false, expected = true},
		{line = "??.#.#.#.? 1,1", expand = false, expected = false},
		{line = "..##.#? 2,1", expand = false, expected = true},
	}
	for tc in cases {
		node := parse2(transmute([]u8)string(tc.line), tc.expand);defer node_destroy(&node)
		ok := node_patterns_check(&node)
		if ok != tc.expected {
			fmt.println("  F got", ok, "expected", tc.expected)
		} else {
			fmt.println("  P", ok)
		}
	}
}
TestCase :: struct {
	line:     string,
	expand:   bool,
	expected: int,
}
test :: proc() {
	fmt.println("--- Patterns --- ")
	patterns_test()
	fmt.println("--- SlidingFitSolve --- ")
	cases := [?]TestCase {
		// part 1
		{"?###???????? 3,2,1", false, 10},
		{"???.### 1,1,3", false, 1},
		{".??..??...?##. 1,1,3", false, 4},
		{"?#?#?#?#?#?#?#? 1,3,1,6", false, 1},
		{"????.#...#... 4,1,1", false, 1},
		{"????.######..#####. 1,6,5", false, 4},
		{"?###???????? 3,2,1", false, 10},
		// compare failures
		{"##????????#?#?????? 4,1,8,2", false, 4},
		{"?????.??????##. 2,3,3", false, 8},
		{".??#??.??# 3,2", false, 3},
		{"????????##?. 2,2,3", false, 9},
		// part 2
		{"???.### 1,1,3", true, 1},
		{".??..??...?##. 1,1,3", true, 16384},
		{"?#?#?#?#?#?#?#? 1,3,1,6", true, 1},
		{"????.#...#... 4,1,1", true, 16},
		{"????.######..#####. 1,6,5", true, 2500},
		{"??????? 2,1", false, 10},
		{"???????? 2,1", false, 15},
		{"?###???????? 3,2,1", true, 506250},
	}
	for t in cases {
		fmt.println(t.line)
		node := parse2(transmute([]u8)t.line, t.expand)
		r := sliding_fit_solve(node)
		if r != t.expected {
			fmt.println("  F got", r, "expected", t.expected)
		} else {
			fmt.println("  P", r)
		}
		assert(r == t.expected)
	}
}


// 10189491 -- .?###??????????###??????????###??????????###??????????###???????? 3,2,1,3,2,1,3,2,1,3,2,1,3,2,1
// 506250
// total: 4067.0596 ms

_main :: proc() {
	start_tick := time.tick_now()

	input, ok := os.read_entire_file_from_filename("input")
	defer delete(input)
	assert(ok)
	read_input_tick := time.tick_now()
	read_input_duration := time.tick_diff(start_tick, read_input_tick)
	after_read_tick := time.tick_now()

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

	// {
	// 	line := "??.???#???? 1,4,1"
	// 	// line := "???.### 1,1,3"
	// 	// line := ".??..??...?##. 1,1,3"
	// 	node := parse2(transmute([]u8)string(line), true)
	// 	r := sliding_fit_solve(node)
	// 	fmt.println(r)
	// }
	{
		patterns_test()
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
	part1_duration := time.tick_diff(after_read_tick, part1_tick)
	// {
	// 	t := transmute([]u8)string(TEST_INPUT)
	// 	r := part2(t)
	// 	fmt.println(r)
	// 	assert(r == 525152)
	// }
	// {
	// 	r := part2(input)
	// 	fmt.println(r)
	// 	// assert(r == )
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
