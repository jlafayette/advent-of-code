package day12

import "core:bytes"
import "core:fmt"
import "core:math"
import "core:strconv"
import "core:strings"

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
	// fmt.println("found", arrs, "valid arrangements")
	return arrs
}

part1 :: proc(input: []u8) -> int {
	total := 0
	input_ := input
	for line in bytes.split_iterator(&input_, {'\n'}) {
		// fmt.println("\n", string(line))
		r := parse(line)
		defer record_destroy(&r)
		total += solve(r)
	}
	return total
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
