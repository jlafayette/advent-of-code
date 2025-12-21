package main

import "core:bytes"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"

TachyonManifold :: struct {
	w:           int,
	h:           int,
	beams:       [dynamic][2]int,
	beams2:      [dynamic][2]int,
	splitters:   [dynamic][2]int,
	split_count: int,
}

read_dimensions :: proc(input: []byte) -> [2]int {
	sep: []byte = {'\n'}
	for ch, i in input {
		if ch == '\n' && i > 0 {
			if input[i - 1] == '\r' {
				sep = {'\r', '\n'}
			}
			break
		}
	}
	dim: [2]int
	line_buf := input[:]
	for line_i := 0; true; line_i += 1 {
		line_buf, split_ok := bytes.split_iterator(&line_buf, sep)
		if !split_ok {
			break
		}
		if len(line_buf) == 0 {
			break
		}
		dim.y = line_i + 1
		dim.x = len(line_buf)
	}
	return dim
}

parse :: proc(input: []byte) -> TachyonManifold {
	t: TachyonManifold
	dim := read_dimensions(input)
	t.w = dim.x
	t.h = dim.y
	sep: []byte = {'\n'}
	for ch, i in input {
		if ch == '\n' && i > 0 {
			if input[i - 1] == '\r' {
				sep = {'\r', '\n'}
			}
			break
		}
	}
	line_buf := input[:]
	for line_i := 0; true; line_i += 1 {
		line_buf, split_ok := bytes.split_iterator(&line_buf, sep)
		if !split_ok {
			break
		}
		if len(line_buf) == 0 {
			break
		}

		if line_i == 0 {
			for ch, i in line_buf {
				if ch == 'S' {
					append_elem(&t.beams, [2]int{i, line_i})
				}
			}
		} else {
			for ch, i in line_buf {
				if ch == '^' {
					append_elem(&t.splitters, [2]int{i, line_i})
				}
			}
		}
	}

	return t
}

update_sim :: proc(t: ^TachyonManifold) -> bool {
	done: bool = false

	// for each beam, move it down one
	// if down one is a splitter, move the beam to the lf
	// then add a new beam to the right of the splitter
	// (check if beam is already there)
	for beam in t.beams {
		beam2 := beam
		beam2.y += 1
		if beam2.y > t.h {
			return true
		}
		for s in t.splitters {
			if s == beam2 {
				beam2.x -= 1
				beam_rt: [2]int = {beam.x + 1, beam2.y}
				if !slice.contains(t.beams2[:], beam_rt) {
					append_elem(&t.beams2, beam_rt)
				}
				t.split_count += 1
				break
			}
		}
		if !slice.contains(t.beams2[:], beam2) {
			append_elem(&t.beams2, beam2)
		}
	}
	// swap and clear beams2
	t.beams, t.beams2 = t.beams2, t.beams
	clear(&t.beams2)

	return done
}

part1 :: proc(input: []byte) -> int {
	result: int
	t := parse(input)
	for {
		done := update_sim(&t)
		if done {
			break
		}
	}
	return t.split_count
}

Beam_Count :: distinct int
Splitter :: distinct bool

Value :: union {
	Beam_Count,
	Splitter,
}

TachyonManifold2 :: struct {
	w:          int,
	h:          int,
	beam_count: Beam_Count,
	grid:       []Value,
	grid2:      []Value,
}

tm2_add_beam :: proc(t: ^TachyonManifold2, grid: []Value, b: Beam_Count, coord: [2]int) {
	i := coord.y * t.w + coord.x
	if i < 0 || i >= len(grid) {
		return
	}
	value := grid[i]
	switch v in value {
	case Beam_Count:
		{
			grid[i] = v + b
		}
	case Splitter:
	case:
		{
			grid[i] = b
		}
	}
}

tm2_get_value :: proc(t: TachyonManifold2, grid: []Value, coord: [2]int) -> Value {
	i := coord.y * t.w + coord.x
	if i < 0 || i >= len(grid) {
		return nil
	}
	return grid[i]
}

tm2_set_value :: proc(t: ^TachyonManifold2, grid: []Value, v: Value, coord: [2]int) {
	i := coord.y * t.w + coord.x
	if i < 0 || i >= len(grid) {
		return
	}
	grid[i] = v
}

parse2 :: proc(input: []byte) -> TachyonManifold2 {
	t: TachyonManifold2
	dim := read_dimensions(input)
	t.w = dim.x
	t.h = dim.y
	sep: []byte = {'\n'}
	for ch, i in input {
		if ch == '\n' && i > 0 {
			if input[i - 1] == '\r' {
				sep = {'\r', '\n'}
			}
			break
		}
	}
	line_buf := input[:]
	for line_i := 0; true; line_i += 1 {
		line_buf, split_ok := bytes.split_iterator(&line_buf, sep)
		if !split_ok {
			break
		}
		if len(line_buf) == 0 {
			break
		}
		if line_i == 0 {
			t.grid = make([]Value, t.h * t.w)
			t.grid2 = make([]Value, t.h * t.w)
		}

		if line_i == 0 {
			for ch, i in line_buf {
				if ch == 'S' {
					tm2_add_beam(&t, t.grid, 1, {i, line_i})
				}
			}
		} else {
			for ch, i in line_buf {
				if ch == '^' {
					tm2_set_value(&t, t.grid, true, {i, line_i})
					tm2_set_value(&t, t.grid2, true, {i, line_i})
				}
			}
		}
	}
	return t
}

update_sim2 :: proc(t: ^TachyonManifold2) -> bool {

	// reset t.grid2 to only be splitters
	for value, i in t.grid2 {
		switch v in value {
		case Beam_Count:
			{
				x := i % t.w
				y := i / t.w
				tm2_set_value(t, t.grid2, nil, {x, y})
			}
		case Splitter:
		case:
		}
	}

	// read from grid, write to grid2
	beams_found: int = 0
	for value, i in t.grid {
		switch v in value {
		case Beam_Count:
			{
				beams_found += 1
				x := i % t.w
				y := i / t.w

				below_value := tm2_get_value(t^, t.grid, {x, y + 1})
				switch bv in below_value {
				case Beam_Count:
					{
						assert(true, "should not have a beam below a beam")
						// tm2_add_beam(t, v, {x, y + 1})
					}
				case Splitter:
					{
						tm2_add_beam(t, t.grid2, v, {x - 1, y + 1})
						tm2_add_beam(t, t.grid2, v, {x + 1, y + 1})
					}
				case:
					{
						if y + 1 >= t.h {
							t.beam_count += v
						} else {
							tm2_add_beam(t, t.grid2, v, {x, y + 1})
						}
					}
				}
				// tm2_set_value(t, nil, {x, y})
			}
		case Splitter:
		case:
		}
	}

	t.grid, t.grid2 = t.grid2, t.grid

	return beams_found == 0
}

part2 :: proc(input: []byte) -> int {
	t: TachyonManifold2 = parse2(input)
	for {
		done := update_sim2(&t)
		if done {
			break
		}
	}
	return int(t.beam_count)
}

main :: proc() {
	filename := "example.txt"
	if len(os.args) == 2 {
		filename = os.args[1]
	}
	input, err := os.read_entire_file_or_err(filename)
	if err != nil {
		fmt.eprintfln("Error reading file '%s': %v", filename, err)
		os.exit(1)
	}
	{
		result1 := part1(input)
		fmt.println(result1)
	}
	{
		result2 := part2(input)
		fmt.println(result2)
	}
}

