package main

import "core:bytes"
import "core:fmt"
import "core:os"
import "core:strconv"

Op :: enum {
	Plus,
	Mult,
}

Data :: struct {
	rows: [dynamic][dynamic]int,
	ops:  [dynamic]Op,
}

parse :: proc(input_arg: []byte) -> Data {
	data: Data
	input := input_arg[:]
	sep: []byte = {'\n'}
	for ch, i in input {
		if ch == '\n' && i > 0 {
			if input[i - 1] == '\r' {
				sep = {'\r', '\n'}
			}
			break
		}
	}
	for true {
		line, line_ok := bytes.split_iterator(&input, sep)
		if !line_ok {
			break
		}
		row: [dynamic]int
		symbol_row: bool = false
		for true {
			thing, ok := bytes.split_iterator(&line, {' '})
			if !ok {
				break
			}
			if len(thing) == 0 {
				continue
			}

			// first
			if len(row) == 0 {
				if len(thing) == 1 {
					ch: byte = thing[0]
					if ch == '+' || ch == '*' {
						symbol_row = true
					}
				}
			}
			if symbol_row {
				assert(len(thing) == 1)
				ch: byte = thing[0]
				op: Op
				switch ch {
				case '+':
					op = .Plus
				case '*':
					op = .Mult
				case:
					assert(false, "op must be '+', '*'")
				}
				append_elem(&data.ops, op)
			} else {
				n, n_ok := strconv.parse_int(string(thing), 10)
				assert(n_ok)
				append_elem(&row, n)
			}
		}
		if len(row) > 0 {
			append_elem(&data.rows, row)
		}
	}

	row_len := len(data.rows[0])
	for row in data.rows {
		assert(len(row) == row_len)
	}
	assert(len(data.ops) == row_len)

	return data
}

part1 :: proc(input: []byte) -> int {
	result: int

	data := parse(input)
	for i in 0 ..< len(data.rows[0]) {
		op := data.ops[i]
		r := -1
		for row in data.rows {
			if r == -1 {
				r = row[i]
			} else {
				switch op {
				case .Plus:
					r += row[i]
				case .Mult:
					r *= row[i]
				}
			}
		}
		result += r
	}

	return result
}

Problem :: struct {
	col_offset: int,
	width:      int,
	op:         Op,
}

Data2 :: struct {
	buf:       []byte,
	row_len:   int,
	row_count: int,
	stride:    int,
	problems:  [dynamic]Problem,
}

parse2 :: proc(input: []byte) -> Data2 {
	data: Data2
	data.buf = input[:]

	sep: []byte = {'\n'}
	for ch, i in input {
		if ch == '\n' && i > 0 {
			if input[i - 1] == '\r' {
				sep = {'\r', '\n'}
			}
			break
		}
	}
	row_len: int = 0
	for ch, i in input {
		if ch == '\n' {
			row_len = i - len(sep) + 1
			break
		}
	}
	data.row_len = row_len

	line_buf := input[:]
	line_count: int = 0
	for {
		line, line_ok := bytes.split_iterator(&line_buf, sep)
		if !line_ok {
			break
		}
		if len(line) == row_len {
			line_count += 1
		}
	}
	data.row_count = line_count

	data.stride = data.row_len + len(sep)

	for i in 0 ..< data.row_len {
		// new problems will have op in column i
		op_i := ((data.row_count - 1) * data.stride) + i
		op_ch := data.buf[op_i]
		is_op: bool = false
		op: Op
		switch op_ch {
		case '+':
			{
				is_op = true
				op = .Plus
			}
		case '*':
			{
				is_op = true
				op = .Mult
			}
		case:
		}
		if !is_op {
			continue
		}

		// if all spaces, or fall off the edge (out of bounds), then mark the
		// len and add the problem		
		for j := 1; true; j += 1 {
			all_spaces := true
			for y in 0 ..< (data.row_count - 1) {
				ch_i := y * data.stride + i + j
				if ch_i >= len(data.buf) {
					break
				}
				ch := data.buf[ch_i]
				if ch == '\r' || ch == '\n' {
					break
				}
				if ch != ' ' {
					all_spaces = false
					break
				}
			}
			// add to problem
			if all_spaces && j > 0 {
				p: Problem
				p.col_offset = i
				p.width = j
				p.op = op
				append_elem(&data.problems, p)
				break
			}
		}
	}

	return data
}

part2 :: proc(input: []byte) -> int {
	result: int = 0
	data := parse2(input)
	#reverse for p in data.problems {
		r: int = -1
		for x := p.col_offset + p.width - 1; x >= p.col_offset; x -= 1 {
			full_n: int = 0
			for y in 0 ..< (data.row_count - 1) {
				ch_i: int = y * data.stride + x
				ch := data.buf[ch_i]
				if ch == ' ' {
					continue
				}
				assert(ch >= '0' && ch <= '9')
				n := int(ch - '0')
				full_n = (full_n * 10) + n
			}
			if r == -1 {
				r = full_n
			} else {
				switch p.op {
				case .Plus:
					r += full_n
				case .Mult:
					r *= full_n
				}
			}
		}
		assert(r != -1)
		result += r
	}
	return result
}

main :: proc() {
	filename := "example.txt"
	if len(os.args) == 2 {
		filename = os.args[1]
	}

	input, err := os.read_entire_file_or_err(filename)
	if err != nil {
		fmt.eprintfln("Error reading from file '%s': %v", filename, err)
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

