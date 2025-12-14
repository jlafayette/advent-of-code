package main

import "core:bytes"
import "core:fmt"
import "core:os"
import "core:strconv"


Grid :: struct {
	data:       []byte,
	// \n (1) or \r\n (2)
	sep_len:    int,
	w:          int,
	h:          int,
	accessible: [dynamic][2]int,
}

grid_init :: proc(data: []byte) -> Grid {
	sep_len: int = 1
	for ch, i in data {
		if ch == '\n' && i > 0 {
			if data[i - 1] == '\r' {
				sep_len = 2
			}
			break
		}
	}

	w: int
	h: int = 1
	for ch, i in data {
		if ch == '\n' && w == 0 {
			w = i + 1 - sep_len
		}
		if ch == '\n' && len(data) - i >= w {
			h += 1
		}
	}

	accessible: [dynamic][2]int
	return Grid{data, sep_len, w, h, accessible}
}

grid_get :: proc(g: Grid, pos: [2]int) -> bool {
	x := pos.x
	y := pos.y
	if x >= 0 && x < g.w && y >= 0 && y < g.h {
		ch := g.data[(y * (g.w + g.sep_len)) + x]
		return ch == '@'
	}
	return false
}

grid_mark_accessible :: proc(g: ^Grid) {
	for y in 0 ..< g.h {
		for x in 0 ..< g.w {
			is_roll := grid_get(g^, {x, y})
			if !is_roll {continue}
			adjacent_rolls := 0
			for x_off in -1 ..= 1 {
				for y_off in -1 ..= 1 {
					if x_off == 0 && y_off == 0 {continue}
					if grid_get(g^, {x + x_off, y + y_off}) {
						adjacent_rolls += 1
					}
				}
			}
			if adjacent_rolls < 4 {
				pos: [2]int = {x, y}
				append_elem(&g.accessible, pos)
			}
		}
	}
}

grid_remove_marked :: proc(g: ^Grid) {
	for pos in g.accessible {
		x := pos.x
		y := pos.y
		in_bounds: bool = x >= 0 && x < g.w && y >= 0 && y < g.h
		assert(in_bounds)
		if in_bounds {
			index := (y * (g.w + g.sep_len)) + x
			ch := g.data[index]
			assert(ch == '@')
			g.data[index] = '.'
		}
	}
	clear_dynamic_array(&g.accessible)
}

part2 :: proc(g: ^Grid) -> int {
	result: int
	for true {
		grid_mark_accessible(g)
		if len(g.accessible) > 0 {
			result += len(g.accessible)
			grid_remove_marked(g)
		} else {
			break
		}
	}
	return result
}

part1 :: proc(grid: Grid) -> int {
	result: int
	for y in 0 ..< grid.h {
		for x in 0 ..< grid.w {
			is_roll := grid_get(grid, {x, y})
			if !is_roll {continue}
			adjacent_rolls := 0
			for x_off in -1 ..= 1 {
				for y_off in -1 ..= 1 {
					if x_off == 0 && y_off == 0 {continue}
					if grid_get(grid, {x + x_off, y + y_off}) {
						adjacent_rolls += 1
					}
				}
			}
			if adjacent_rolls < 4 {
				result += 1
			}
		}
	}
	return result
}

main :: proc() {
	filename := "example.txt"
	if len(os.args) == 2 {
		filename = os.args[1]
	}
	data, err := os.read_entire_file_or_err(filename)
	if err != nil {
		fmt.eprintfln("Failed to open file '%s' with error: %v", filename, err)
		os.exit(1)
	}

	grid := grid_init(data)

	result1 := part1(grid)
	if filename == "input.txt" {
		assert(result1 == 1464)
	}
	fmt.println(result1)

	result2 := part2(&grid)
	if filename == "input.txt" {
		assert(result2 == 8409)
	}
	fmt.println(result2)
}

