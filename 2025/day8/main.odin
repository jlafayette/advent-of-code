package main

import "core:bytes"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"

Data :: struct {
	boxes: [dynamic][3]int,
}

get_sep :: proc(input: []byte) -> []byte {
	sep: []byte = make([]byte, 1)
	sep[0] = '\n'
	for ch, i in input {
		if ch == '\n' && i > 0 {
			if input[i - 1] == '\r' {
				sep = make([]byte, 2)
				sep[0] = '\r'
				sep[1] = '\n'
			}
		}
	}
	return sep
}

parse :: proc(input: []byte) -> Data {
	data: Data

	sep := get_sep(input)
	buf := input[:]
	for {
		line_buf, line_ok := bytes.split_iterator(&buf, sep)
		if !line_ok || len(line_buf) == 0 {
			break
		}

		num_bufs := bytes.split(line_buf, {','})
		assert(len(num_bufs) == 3)

		box: [3]int
		ok: bool
		box[0], ok = strconv.parse_int(string(num_bufs[0]), 10);assert(ok)
		box[1], ok = strconv.parse_int(string(num_bufs[1]), 10);assert(ok)
		box[2], ok = strconv.parse_int(string(num_bufs[2]), 10);assert(ok)
		append_elem(&data.boxes, box)
	}

	return data
}

distance :: proc(p1, p2: [3]int) -> int {
	x := abs(p1.x - p2.x)
	y := abs(p1.y - p2.y)
	z := abs(p1.z - p2.z)
	return x * x + y * y + z * z
}

DistanceIndex :: struct {
	index:    int,
	distance: int,
}

distance_index_less :: proc(i, j: DistanceIndex) -> bool {
	return i.distance < j.distance
}

circuit_ptr_less :: proc(i, j: ^[dynamic]int) -> bool {
	return len(i) < len(j)
}

part1 :: proc(input: []byte, pair_count: int) -> int {
	data := parse(input)

	circuits := make_map_cap(map[int]^[dynamic]int, len(data.boxes))
	for pos, i in data.boxes {
		circuits[i] = nil
	}

	stride := len(data.boxes)
	distances := make([]int, stride * stride)
	for p1, i in data.boxes {
		for p2, j in data.boxes {
			index := stride * j + i
			distances[index] = distance(p1, p2)
		}
	}

	// stores distance and index into distances slice
	// this index can be unpacked into i and j, which
	// are indexes into the original circuits map value and
	// the indexes into data.boxes
	sorted_distances := make([]DistanceIndex, len(distances))
	for d, i in distances {
		sorted_distances[i] = DistanceIndex{i, d}
	}
	slice.sort_by(sorted_distances, distance_index_less)

	iterations: int
	appends: int
	prev_i: int
	prev_j: int
	for v in sorted_distances {
		if v.distance == 0 {
			continue
		}

		// extract original indices
		box_i: int = v.index % stride
		box_j: int = v.index / stride

		// skip opposite order of indices (after i--j, skip j--i)
		// (assumes that each distance only comes up once...)
		// TODO: check this assumption on dataset
		if box_i == prev_j && box_j == prev_i {
			continue
		}
		prev_i = box_i
		prev_j = box_j

		// fmt.println("----", iterations, box_i, box_j, appends)
		// fmt.println("    ", data.boxes[box_i], data.boxes[box_j], box_i, box_j)

		// update circuits
		// each circuit is a Maybe ptr to a dynamic array containing all
		// indexes that are contained in the circuit
		circuit_i, i_ok := circuits[box_i];assert(i_ok)
		circuit_j, j_ok := circuits[box_j];assert(j_ok)
		new_circuit_i: ^[dynamic]int = nil
		new_circuit_j: ^[dynamic]int = nil
		if circuit_i == nil {
			if circuit_j == nil {
				// both do not have circuits
				ptr := new([dynamic]int)
				ptr^ = make([dynamic]int)
				_, err := append_elems(ptr, box_i, box_j)
				if err != nil {
					fmt.eprintfln("error allocating: %v", err)
					os.exit(1)
				}
				appends += 2
				// fmt.printfln("new circuit: %v %p ptr: %p", ptr^, ptr^, ptr)
				new_circuit_i = ptr
				new_circuit_j = ptr
			} else {
				// j has circuit, i does not
				_, err := append_elem(circuit_j, box_i)
				if err != nil {
					fmt.eprintfln("error allocating: %v", err)
					os.exit(1)
				}
				appends += 1
				new_circuit_i = circuit_j
				new_circuit_j = circuit_j
			}
		} else {
			if circuit_j == nil {
				// i has circuit, j does not
				_, err := append_elem(circuit_i, box_j)
				if err != nil {
					fmt.eprintfln("error allocating: %v", err)
					os.exit(1)
				}
				appends += 1
				new_circuit_i = circuit_i
				new_circuit_j = circuit_i
			} else {
				// both have existing circuits
				if circuit_i == circuit_j {
					// same circuit, no change needed
					new_circuit_i = circuit_i
					new_circuit_j = circuit_j
				} else {
					// different circuits, merge j into i
					combined := circuit_i
					for j in circuit_j {
						_, err := append_elem(combined, j)
						if err != nil {
							fmt.eprintfln("error allocating: %v", err)
							os.exit(1)
						}
						appends += 1
					}

					// find all things pointed at circuit_j and switch
					// them to circuit_i
					for j in circuit_j {
						circuits[j] = combined
					}
					delete_dynamic_array(circuit_j^)

					new_circuit_i = combined
					new_circuit_j = combined
				}
			}
		}
		circuits[box_i] = new_circuit_i
		circuits[box_j] = new_circuit_j

		iterations += 1
		if iterations >= pair_count {
			break
		}
	}

	// sanity checks
	for key in circuits {
		c, found := circuits[key]
		assert(found)
		if c != nil {
			slice_contains_key := slice.contains(c[:], key)
			assert(slice_contains_key)
		}
	}

	// first the top 3
	circuits_deduplicated: [dynamic]^[dynamic]int
	skip: [dynamic]int
	for key in circuits {
		if slice.contains(skip[:], key) {
			continue
		}
		c := circuits[key]
		if c != nil {
			for i in c {
				append_elem(&skip, i)
			}
			append_elem(&circuits_deduplicated, c)
		}
	}
	slice.reverse_sort_by(circuits_deduplicated[:], circuit_ptr_less)
	// fmt.println("------")
	// for c in circuits_deduplicated {
	// 	fmt.printfln("%v", c)
	// }
	// fmt.println("------")
	assert(len(circuits_deduplicated) >= 3)
	a := len(circuits_deduplicated[0])
	b := len(circuits_deduplicated[1])
	c := len(circuits_deduplicated[2])

	return a * b * c
}

part2 :: proc(input: []byte) -> int {

	data := parse(input)

	circuits := make_map_cap(map[int]^[dynamic]int, len(data.boxes))
	for pos, i in data.boxes {
		circuits[i] = nil
	}

	stride := len(data.boxes)
	distances := make([]int, stride * stride)
	for p1, i in data.boxes {
		for p2, j in data.boxes {
			index := stride * j + i
			distances[index] = distance(p1, p2)
		}
	}

	// stores distance and index into distances slice
	// this index can be unpacked into i and j, which
	// are indexes into the original circuits map value and
	// the indexes into data.boxes
	sorted_distances := make([]DistanceIndex, len(distances))
	for d, i in distances {
		sorted_distances[i] = DistanceIndex{i, d}
	}
	slice.sort_by(sorted_distances, distance_index_less)

	prev_i: int
	prev_j: int
	last_box_indexes: [2]int
	for v in sorted_distances {
		if v.distance == 0 {
			continue
		}

		// extract original indices
		box_i: int = v.index % stride
		box_j: int = v.index / stride

		// skip opposite order of indices (after i--j, skip j--i)
		// (assumes that each distance only comes up once...)
		// TODO: check this assumption on dataset
		if box_i == prev_j && box_j == prev_i {
			continue
		}
		prev_i = box_i
		prev_j = box_j

		// update circuits
		// each circuit is a Maybe ptr to a dynamic array containing all
		// indexes that are contained in the circuit
		circuit_i, i_ok := circuits[box_i];assert(i_ok)
		circuit_j, j_ok := circuits[box_j];assert(j_ok)
		if circuit_i == nil {
			if circuit_j == nil {
				// both do not have circuits
				ptr := new([dynamic]int)
				ptr^ = make([dynamic]int)
				append_elems(ptr, box_i, box_j)
				circuits[box_i] = ptr
				circuits[box_j] = ptr
			} else {
				// j has circuit, i does not
				append_elem(circuit_j, box_i)
				circuits[box_i] = circuit_j
				circuits[box_j] = circuit_j
				if len(circuit_j) == len(data.boxes) {
					last_box_indexes = {box_i, box_j}
					break
				}
			}
		} else {
			if circuit_j == nil {
				// i has circuit, j does not
				append_elem(circuit_i, box_j)
				circuits[box_i] = circuit_i
				circuits[box_j] = circuit_i
				if len(circuit_i) == len(data.boxes) {
					last_box_indexes = {box_i, box_j}
					break
				}
			} else {
				// both have existing circuits
				if circuit_i == circuit_j {
					// same circuit, no change needed
					circuits[box_i] = circuit_i
					circuits[box_j] = circuit_j
				} else {
					// different circuits, merge j into i
					combined := circuit_i
					for j in circuit_j {
						append_elem(combined, j)
					}

					// find all things pointed at circuit_j and switch
					// them to circuit_i
					for j in circuit_j {
						circuits[j] = combined
					}
					delete_dynamic_array(circuit_j^)

					circuits[box_i] = combined
					circuits[box_j] = combined
					if len(combined) == len(data.boxes) {
						last_box_indexes = {box_i, box_j}
						break
					}
				}
			}
		}
	}

	// sanity checks
	for key in circuits {
		c, found := circuits[key]
		assert(found)
		if c != nil {
			slice_contains_key := slice.contains(c[:], key)
			assert(slice_contains_key)
		}
	}
	pos1 := data.boxes[last_box_indexes[0]]
	pos2 := data.boxes[last_box_indexes[1]]

	return pos1.x * pos2.x
}

main :: proc() {
	filename := "example.txt"
	pair_count := 10
	if len(os.args) == 2 {
		filename = os.args[1]
		pair_count = 1000
	}
	input, err := os.read_entire_file_or_err(filename)
	if err != nil {
		fmt.eprintfln("Error reading file '%s': %v", filename, err)
		os.exit(1)
	}
	{
		result := part1(input, pair_count)
		// 3244032 is too high
		assert(result < 3244032, "3244032 is too high")
		fmt.println(result)
	}
	{
		result := part2(input)
		fmt.println(result)
	}
}

