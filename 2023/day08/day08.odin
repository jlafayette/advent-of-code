package day08

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

TEST_INPUT :: `RL

AAA = (BBB, CCC)
BBB = (DDD, EEE)
CCC = (ZZZ, GGG)
DDD = (DDD, DDD)
EEE = (EEE, EEE)
GGG = (GGG, GGG)
ZZZ = (ZZZ, ZZZ)`

TEST_INPUT2 :: `LLR

AAA = (BBB, BBB)
BBB = (AAA, ZZZ)
ZZZ = (ZZZ, ZZZ)`


Tag :: [3]byte
TagStart :: [3]byte{'A', 'A', 'A'}
TagEnd :: [3]byte{'Z', 'Z', 'Z'}
tag_copy :: proc(src: []byte) -> (t: Tag) {
	assert(len(src) >= 3)
	// probably a better way...
	t.x = src[0]
	t.y = src[1]
	t.z = src[2]
	return
}
Node :: struct {
	tag:    Tag,
	lf_tag: Tag,
	rt_tag: Tag,
	lf:     ^Node,
	rt:     ^Node,
}
node_print :: proc(node: ^Node) {
	fmt.print(
		string(node.tag[:]),
		" = (",
		string(node.lf_tag[:]),
		", ",
		string(node.rt_tag[:]),
		")\n",
		sep = "",
	)
}
node_from_line :: proc(node: ^Node, line: []byte) {
	split1 := bytes.split(line, {' ', '=', ' '})
	defer delete(split1)
	assert(len(split1) == 2)
	node.tag = tag_copy(split1[0][:])
	split_tags := bytes.split(split1[1], {',', ' '})
	defer delete(split_tags)
	assert(len(split_tags) == 2)
	node.lf_tag = tag_copy(split_tags[0][1:])
	node.rt_tag = tag_copy(split_tags[1][:3])
}

parse :: proc(
	input: []byte,
	node_backing: ^[dynamic]Node,
) -> (
	dirs: []byte,
	node_map: map[Tag]^Node,
) {
	sections := bytes.split(input, {'\n', '\n'})
	assert(len(sections) == 2)
	defer delete(sections)
	dirs = make([]byte, len(sections[0]))
	copy(dirs, sections[0])

	line_count := 0
	for char in sections[1] {
		if char == '\n' {
			line_count += 1
		}
	}
	resize_dynamic_array(node_backing, line_count)

	for line in bytes.split_iterator(&sections[1], {'\n'}) {
		append(node_backing, Node{})
		node: ^Node = &node_backing[len(node_backing) - 1]
		node_from_line(node, line)
		node_map[node.tag] = node
	}
	for _, v in node_map {
		ok := false
		v.lf, ok = node_map[v.lf_tag]
		assert(ok, "missing lf tag")
		v.rt, ok = node_map[v.rt_tag]
		assert(ok, "missing rt tag")
	}
	return
}

part1 :: proc(input: []u8) -> int {
	node_backing: [dynamic]Node
	defer delete(node_backing)
	dirs, node_map := parse(input, &node_backing)
	defer {
		delete(dirs)
		delete(node_map)
	}
	start, start_ok := node_map[TagStart]
	assert(start_ok)
	end, end_ok := node_map[TagEnd]
	assert(end_ok)
	c := start
	steps := 0
	for {
		for d in dirs {
			switch (d) {
			case 'L':
				{
					c = c.lf
					steps += 1
				}
			case 'R':
				{
					c = c.rt
					steps += 1
				}
			}
		}
		if c.tag == end.tag {
			break
		}
	}
	return steps
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
		assert(r == 2)
	}
	{
		t := transmute([]u8)string(TEST_INPUT2)
		r := part1(t)
		fmt.println(r)
		assert(r == 6)
	}
	{
		r := part1(input)
		fmt.println(r)
		assert(r == 16343)
	}
	part1_tick := time.tick_now()
	part1_duration := time.tick_diff(start_tick, part1_tick)
	// {
	// 	t := transmute([]u8)string(TEST_INPUT)
	// 	r := part2(t)
	// 	fmt.println(r)
	// 	assert(r == 0)
	// }
	// {
	// 	r := part2(input)
	// 	fmt.println(r)
	// 	assert(r == 0)
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
