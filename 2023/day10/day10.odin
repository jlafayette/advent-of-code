package day10

import "core:bytes"
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

TEST_INPUT :: `.....
.S-7.
.|.|.
.L-J.
.....`

TEST_INPUT2 :: `..F7.
.FJ|.
SJ.L7
|F--J
LJ...`

Loc :: struct {
	x:    int,
	y:    int,
	type: u8,
}
DirLoc :: struct {
	using loc: Loc,
	conn:      Loc,
}
loc_to_str :: proc(loc: Loc) -> string {
	b := strings.builder_make()
	fmt.sbprint(&b, "Loc{", loc.x, ",", loc.y, ",", rune(loc.type), "}", sep = "")
	return strings.to_string(b)
}
Dir :: enum {
	Up,
	Right,
	Down,
	Left,
}
Grid :: struct {
	w: int,
	h: int,
	g: [][]u8,
}
grid_make :: proc(input: []u8) -> Grid {
	lines := bytes.split(input, {'\n'})
	return Grid{len(lines[0]), len(lines), lines}
}
grid_get :: proc(g: ^Grid, x, y: int) -> (Loc, bool) {
	if x >= 0 && x < g.w && y >= 0 && y < g.h {
		return Loc{x, y, g.g[y][x]}, true
	}
	return Loc{}, false
}
grid_find_s :: proc(g: ^Grid) -> Loc {
	for y in 0 ..< g.h {
		for x in 0 ..< g.w {
			char := g.g[y][x]
			if char == 'S' {
				return Loc{x, y, 'S'}
			}
		}
	}
	assert(false)
	return Loc{0, 0, '.'}
}
grid_find_second_conn :: proc(g: ^Grid, dl: DirLoc) -> DirLoc {
	f := dl.conn
	c := dl.loc
	x := c.x
	y := c.y
	f_dir: Dir
	if f.x == x && f.y == y - 1 {
		f_dir = Dir.Up
	} else if f.x == x && f.y == y + 1 {
		f_dir = Dir.Down
	} else if f.x == x - 1 && f.y == y {
		f_dir = Dir.Left
	} else if f.x == x + 1 && f.y == y {
		f_dir = Dir.Right
	} else {
		assert(false)
	}
	if f_dir != Dir.Up {
		up, ok := grid_get(g, x, y - 1)
		if ok && type_in(up.type, up_conn_types) && type_in(c.type, down_conn_types) {
			return DirLoc{up, c}
		}
	}
	if f_dir != Dir.Down {
		down, ok := grid_get(g, x, y + 1)
		if ok && type_in(down.type, down_conn_types) && type_in(c.type, up_conn_types) {
			return DirLoc{down, c}
		}
	}
	if f_dir != Dir.Left {
		left, ok := grid_get(g, x - 1, y)
		if ok && type_in(left.type, left_conn_types) && type_in(c.type, right_conn_types) {
			return DirLoc{left, c}
		}
	}
	if f_dir != Dir.Right {
		right, ok := grid_get(g, x + 1, y)
		if ok && type_in(right.type, right_conn_types) && type_in(c.type, left_conn_types) {
			return DirLoc{right, c}
		}
	}
	assert(false)
	return DirLoc{}
}
up_conn_types :: [3]u8{'|', '7', 'F'}
down_conn_types :: [3]u8{'|', 'L', 'J'}
left_conn_types :: [3]u8{'-', 'F', 'L'}
right_conn_types :: [3]u8{'-', '7', 'J'}
type_in :: proc(t: u8, types: [3]u8) -> bool {
	return t == types.x || t == types.y || t == types.z
}
find_s_connections :: proc(g: ^Grid, loc: Loc) -> (c1: DirLoc, c2: DirLoc) {

	conns := make([dynamic]Loc, 0, 2)
	sx := loc.x
	sy := loc.y
	up, ok := grid_get(g, sx, sy - 1)
	if ok && type_in(up.type, up_conn_types) {
		append(&conns, up)
	}
	down: Loc
	down, ok = grid_get(g, sx, sy + 1)
	if ok && type_in(down.type, down_conn_types) {
		append(&conns, down)
	}
	left: Loc
	left, ok = grid_get(g, sx - 1, sy)
	if ok && type_in(left.type, left_conn_types) {
		append(&conns, left)
	}
	right: Loc
	right, ok = grid_get(g, sx + 1, sy)
	if ok && type_in(right.type, right_conn_types) {
		append(&conns, right)
	}
	assert(len(conns) == 2)
	return DirLoc{conns[0], loc}, DirLoc{conns[1], loc}
}

part1 :: proc(input: []u8) -> int {
	g := grid_make(input)
	s_loc := grid_find_s(&g)
	// fmt.println(s_loc)

	c1, c2 := find_s_connections(&g, s_loc)
	// fmt.println("c1:", loc_to_str(c1))
	// fmt.println("c2:", loc_to_str(c2))
	distance := 1
	visited: map[[2]int]bool
	defer delete(visited)
	visited[[2]int{c1.x, c1.y}] = true
	visited[[2]int{c2.x, c2.y}] = true
	// fmt.println(visited)
	for {
		distance += 1
		next_c1 := grid_find_second_conn(&g, c1)
		p: [2]int = {next_c1.x, next_c1.y}
		if p in visited {
			break
		}
		c1 = next_c1
		visited[p] = true

		next_c2 := grid_find_second_conn(&g, c2)
		p = {next_c2.x, next_c2.y}
		if p in visited {
			break
		}
		c2 = next_c2
		visited[p] = true
	}
	return distance
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
		assert(r == 4)
	}
	{
		t := transmute([]u8)string(TEST_INPUT2)
		r := part1(t)
		fmt.println(r)
		assert(r == 8)
	}
	{
		r := part1(input)
		fmt.println(r)
		assert(r == 6613)
	}
	part1_tick := time.tick_now()
	part1_duration := time.tick_diff(start_tick, part1_tick)
	// {
	// 	t := transmute([]u8)string(TEST_INPUT)
	// 	r := part2(t)
	// 	fmt.println(r)
	// 	assert(r == 2)
	// }
	// {
	// 	r := part2(input)
	// 	fmt.println(r)
	// 	assert(r == 1129)
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
