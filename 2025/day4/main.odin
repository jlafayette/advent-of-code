package main

import "core:bytes"
import "core:fmt"
import "core:os"
import "core:strconv"


Grid :: struct {
	data:    []byte,
	// \n (1) or \r\n (2)
	sep_len: int,
	w:       int,
	h:       int,
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

	return Grid{data, sep_len, w, h}
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
	fmt.println(result1)


}

