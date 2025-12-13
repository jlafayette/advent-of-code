package main

import "core:bytes"
import "core:fmt"
import "core:os"
import "core:strconv"

part1 :: proc(input: []byte) -> int {
	result: int = 0
	data := input[:]
	for true {
		line, ok := bytes.split_iterator(&data, {'\n'})
		if !ok {
			break
		}
		end_i: int
		for ch, i in line {
			if ch < '0' || ch > '9' {
				end_i = i
				break
			}

		}
		hi1: byte = '0'
		hi2: byte = '0'
		for ch, i in line {
			if i >= end_i {break}
			digits_left: int = end_i - i - 1
			if ch > hi1 && digits_left >= 1 {
				hi1 = ch
				hi2 = '0'
			} else if ch > hi2 {
				hi2 = ch
			}
		}
		hi1_i: int = int(hi1 - '0')
		hi2_i: int = int(hi2 - '0')
		// fmt.printfln("line: %s jolt: %i%i", string(line), hi1_i, hi2_i)
		result += ((10 * hi1_i) + hi2_i)
	}
	return result
}

part2 :: proc(input: []byte) -> int {
	result: int = 0
	data := input[:]
	for true {
		line, ok := bytes.split_iterator(&data, {'\n'})
		if !ok {
			break
		}
		// to trim off \r on windows after splitting on \n 
		end_i: int
		for ch, i in line {
			if ch < '0' || ch > '9' {
				end_i = i
				break
			}
		}

		jolt: [12]int

		for ch, ch_i in line {
			if ch_i >= end_i {break}

			digits_left: int = end_i - ch_i - 1

			n: int = int(ch - '0')

			pos_i: int = len(jolt)
			#reverse for j, i in jolt {
				if n > j {
					pos_i = i
				}
				if (len(jolt) - i) > digits_left {
					// only promote the new number if there enough digits left
					break
				}
			}
			if pos_i < len(jolt) {
				jolt[pos_i] = n
				for i := pos_i + 1; i < len(jolt); i += 1 {
					jolt[i] = 0
				}
			}
		}
		joltage: int = 0
		mult: int = 1
		#reverse for j in jolt {
			joltage += j * mult
			mult = 10 * mult
		}
		result += joltage
	}
	return result
}


main :: proc() {
	filename := "example.txt"
	if len(os.args) == 2 {
		filename = os.args[1]
	}
	data, ok := os.read_entire_file(filename)
	if !ok {
		fmt.eprintln("Failed to open file:", filename)
		os.exit(1)
	}

	result1 := part1(data)
	fmt.println(result1)

	result2 := part2(data)
	fmt.println(result2)
}

