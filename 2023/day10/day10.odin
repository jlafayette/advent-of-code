package day10

TRACY_ENABLE :: #config(TRACY_ENABLE, false)
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

import tracy "../../../odin-tracy"

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

P :: [2]int
Loc :: struct {
	using p: P,
	type:    u8,
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
grid_destroy :: proc(g: ^Grid) {
	delete(g.g)
}
grid_get :: proc(g: ^Grid, x, y: int) -> (Loc, bool) {
	if x >= 0 && x < g.w && y >= 0 && y < g.h {
		return Loc{{x, y}, g.g[y][x]}, true
	}
	return Loc{}, false
}
grid_find_s :: proc(g: ^Grid) -> Loc {
	for y in 0 ..< g.h {
		for x in 0 ..< g.w {
			char := g.g[y][x]
			if char == 'S' {
				return Loc{{x, y}, 'S'}
			}
		}
	}
	assert(false)
	return Loc{{0, 0}, '.'}
}
grid_find_second_conn :: proc(g: ^Grid, dl: DirLoc) -> DirLoc {
	tracy.ZoneN("grid_find_second_conn")
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
find_s_connections :: proc(g: ^Grid, loc: Loc) -> (DirLoc, DirLoc) {
	tracy.ZoneN("find_s_connnections")
	conns := make([dynamic]Loc, 0, 2);defer delete(conns)
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
	tracy.ZoneN("part1")
	g := grid_make(input)
	defer grid_destroy(&g)
	s_loc := grid_find_s(&g)
	// fmt.println(s_loc)

	c1, c2 := find_s_connections(&g, s_loc)
	distance := 1
	visited: Set2 = set2_make(g.w, g.h)
	defer set2_destroy(&visited)
	set_add(&visited, c1.p)
	set_add(&visited, c2.p)
	for {
		distance += 1
		next_c1 := grid_find_second_conn(&g, c1)
		if set_contains(&visited, next_c1.p) {
			break
		}
		c1 = next_c1
		set_add(&visited, c1.p)

		next_c2 := grid_find_second_conn(&g, c2)
		if set_contains(&visited, next_c2.p) {
			break
		}
		c2 = next_c2
		set_add(&visited, c2.p)
	}
	return distance
}
E :: struct {
	a: P,
	b: P,
}
Q :: queue.Queue(E)

// G.visited [2]int (square)
// G.conn    [4]int (square to square)
// visited   [4]int (edges, [2]int+[2]int)
// corners   [2]int (square corner) grid +1

// Set for 2d positions
Set2 :: struct {
	buf: []bool,
	w:   int,
	h:   int,
}
set2_make :: proc(w, h: int) -> Set2 {
	s: Set2
	s.buf = make_slice([]bool, w * h)
	for i in 0 ..< w * h {
		s.buf[i] = false
	}
	s.w = w
	s.h = h
	return s
}
set2_contains :: proc(s: ^Set2, p: P) -> bool {
	i := p.x + (s.w * p.y)
	return s.buf[i]
}
set2_add :: proc(s: ^Set2, p: P) {
	i := p.x + (s.w * p.y)
	s.buf[i] = true
}
set2_destroy :: proc(s: ^Set2) {
	delete(s.buf)
}
// Keep track of connections
Conn :: enum {
	Left,
	Up,
	Right,
	Down,
}
Conn_BitSet :: bit_set[Conn]
SetConn :: struct {
	buf:  []Conn_BitSet,
	w:    int,
	h:    int,
	size: int,
}
set_conn_make :: proc(w: int, h: int) -> SetConn {
	s := SetConn {
		buf  = make_slice([]Conn_BitSet, w * h),
		w    = w,
		h    = h,
		size = w * h,
	}
	return s
}
// check if connection exists between positions a and b
set_conn_contains :: proc(s: ^SetConn, e: E) -> bool {
	a := e.a
	b := e.b
	i := a.x + (s.w * a.y)
	bi := b.x + (s.w * b.y)
	if i < 0 || bi < 0 {
		return false
	}
	a_conn := s.buf[i]
	if card(a_conn) == 0 {
		return false
	}
	diff := b - a
	conn: Conn
	switch diff.x {
	case 1:
		{conn = .Right}
	case -1:
		{conn = .Left}
	case 0:
		{
			switch diff.y {
			case 1:
				{conn = .Down}
			case -1:
				{conn = .Up}
			case:
				{assert(false)}
			}
		}
	case:
		{assert(false)}
	}
	return conn in a_conn
}
set_conn_add :: proc(s: ^SetConn, e: E) {
	a := e.a
	b := e.b
	ai := a.x + (s.w * a.y)
	bi := b.x + (s.w * b.y)
	if ai < 0 || bi < 0 {
		return
	}
	ac := s.buf[ai]
	bc := s.buf[bi]

	diff := b - a
	ac2: Conn_BitSet
	bc2: Conn_BitSet
	switch diff.x {
	case 1:
		{
			ac2 = {.Right}
			bc2 = {.Left}
		}
	case -1:
		{
			ac2 = {.Left}
			bc2 = {.Right}
		}
	case 0:
		{
			switch diff.y {
			case 1:
				{
					ac2 = {.Down}
					bc2 = {.Up}
				}
			case -1:
				{
					ac2 = {.Up}
					bc2 = {.Down}
				}
			case:
				{assert(false)}
			}
		}
	case:
		{assert(false)}
	}
	s.buf[ai] = s.buf[ai] | ac2
	s.buf[bi] = s.buf[bi] | bc2
}
set_conn_destroy :: proc(s: ^SetConn) {
	delete(s.buf)
}

set_make :: proc {
	set2_make,
}
set_contains :: proc {
	set2_contains,
	set_conn_contains,
}
set_add :: proc {
	set2_add,
	set_conn_add,
}
set_destroy :: proc {
	set2_destroy,
	set_conn_destroy,
}


Grid2 :: struct {
	using g1: Grid,
	s:        Loc,
	visited:  Set2,
	conn:     SetConn,
	q:        Q,
}
g2_make :: proc(input: []u8) -> Grid2 {
	g: Grid2
	g.g1 = grid_make(input)
	g.s = grid_find_s(&g.g1)
	g.visited = set_make(g.w, g.h)
	g.conn = set_conn_make(g.w + 1, g.h + 1)
	return g
}
g2_destroy :: proc(g: ^Grid2) {
	when ODIN_DEBUG {
		fmt.println("destroying Grid2:", g.w, "x", g.h)
	}
	set_destroy(&g.visited)
	set_destroy(&g.conn)
	queue.destroy(&g.q)
	grid_destroy(&g.g1)
}
g2_find_s_connections :: proc(g: ^Grid2) -> (DirLoc, DirLoc) {
	return find_s_connections(&g.g1, g.s)
}
g2_mark_conn :: proc(g: ^Grid2, a, b: Loc) {
	set_add(&g.conn, E{a.p, b.p})
}
g2_is_conn :: proc(g: ^Grid2, a, b: Loc) -> bool {
	return set_contains(&g.conn, E{a.p, b.p})
}
g2_mark_visited :: proc(g: ^Grid2, loc: Loc) {
	set_add(&g.visited, loc.p)
}
g2_is_visited :: proc(g: ^Grid2, loc: Loc) -> bool {
	return set_contains(&g.visited, loc.p)
}
g2_add_neighbors :: proc(g: ^Grid2, p: P) {
	tracy.ZoneN("g2_add_neighbors")
	x := p.x
	y := p.y
	if x <= g.w {
		queue.push_back(&g.q, E{p, {x + 1, y}})
	}
	if x > 0 {
		queue.push_back(&g.q, E{p, {x - 1, y}})
	}
	if y <= g.h {
		queue.push_back(&g.q, E{p, {x, y + 1}})
	}
	if y > 0 {
		queue.push_back(&g.q, E{p, {x, y - 1}})
	}
}
g2_flood_fill :: proc(g: ^Grid2) -> int {
	tracy.ZoneN("g2_flood_fill")

	// The +2 to width and height is needed because edges need
	// +1 already, and the extra +1 is because there is no bounds
	// checking // on the high side currently.
	visited: SetConn = set_conn_make(g.w + 2, g.h + 2)
	defer set_destroy(&visited)
	corners: Set2 = set_make(g.w + 2, g.h + 2)
	defer set_destroy(&corners)

	c: P = {0, 0}
	g2_add_neighbors(g, c)
	for {
		tracy.ZoneN("g2_flood_fill--for-loop")
		if queue.len(g.q) == 0 {
			break
		}
		edge := queue.pop_front(&g.q)
		if set_contains(&visited, edge) {
			continue
		}
		set_add(&visited, edge)

		// does edge cross a pipe edge?
		x1 := edge.a.x
		y1 := edge.a.y
		x2 := edge.b.x
		y2 := edge.b.y
		horizontal := y1 == y2
		cross_edge: E
		if horizontal {
			x := min(x1, x2)
			cross_edge = {{x, y1 - 1}, {x, y1}}
		} else {
			assert(x1 == x2)
			y := min(y1, y2)
			cross_edge = {{x1 - 1, y}, {x1, y}}
		}
		if set_contains(&g.conn, cross_edge) {
			// It does cross a pipe - do not continue flood fill
			continue
		}
		// Contiue flood fill from far end of the edge
		set_add(&corners, edge.a)
		set_add(&corners, edge.b)
		g2_add_neighbors(g, edge.b)
	}
	inside_count := 0
	{
		tracy.ZoneN("count inside")
		for y in 0 ..< g.h {
			for x in 0 ..< g.w {
				cn1: P = {x, y}
				cn2: P = {x + 1, y}
				cn3: P = {x, y + 1}
				cn4: P = {x + 1, y + 1}
				filled :=
					set_contains(&corners, cn1) &&
					set_contains(&corners, cn2) &&
					set_contains(&corners, cn3) &&
					set_contains(&corners, cn4)
				if filled {
					continue
				} else if set_contains(&g.visited, cn1) {
					continue
				} else {
					inside_count += 1
				}
			}
		}
	}
	return inside_count
}


TEST_INPUT_2_1 :: `...........
.S-------7.
.|F-----7|.
.||.....||.
.||.....||.
.|L-7.F-J|.
.|..|.|..|.
.L--J.L--J.
...........`

TEST_INPUT_2_2 :: `.F----7F7F7F7F-7....
.|F--7||||||||FJ....
.||.FJ||||||||L7....
FJL7L7LJLJ||LJ.L-7..
L--J.L7...LJS7F-7L7.
....F-J..F7FJ|L7L7L7
....L7.F7||L7|.L7L7|
.....|FJLJ|FJ|F7|.LJ
....FJL-7.||.||||...
....L---J.LJ.LJLJ...`

part2 :: proc(input: []u8) -> int {
	tracy.ZoneN("part2")
	g := g2_make(input);defer g2_destroy(&g)
	g2_mark_visited(&g, g.s)
	c1, c2 := g2_find_s_connections(&g)
	g2_mark_conn(&g, g.s, c1)
	g2_mark_conn(&g, g.s, c2)
	g2_mark_visited(&g, c1)
	g2_mark_visited(&g, c2)

	for {
		tracy.ZoneN("part2--for-loop")
		// find next conn of c1
		next_c1 := grid_find_second_conn(&g, c1)
		g2_mark_conn(&g, c1, next_c1)
		g2_mark_visited(&g, next_c1)
		if next_c1.x == c2.x && next_c1.y == c2.y {
			break
		}
		c1 = next_c1
	}
	result := g2_flood_fill(&g)
	return result
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
	{
		t := transmute([]u8)string(TEST_INPUT_2_1)
		r := part2(t)
		fmt.println(r)
		assert(r == 4)
	}
	{
		t := transmute([]u8)string(TEST_INPUT_2_2)
		r := part2(t)
		fmt.println(r)
		assert(r == 8)
	}
	{
		r := part2(input)
		fmt.println(r)
		assert(r == 511)
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
