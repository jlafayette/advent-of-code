import strutils, sequtils


# -- decode input


type
    DecodedLine = object
        password*: string
        ch*: char
        min*: int
        max*: int


proc decode_line(line: string): DecodedLine =
    let parts = line.strip().split({' '})
    let min_max = parts[0].split({'-'})
    DecodedLine(
        password : parts[2],
        ch : parts[1][0],
        min : parseInt(min_max[0]),
        max : parseInt(min_max[1]),
    )


let input = readFile("input")
let decoded_lines = input.split({'\n'})
                         .mapIt(decode_line(it))


# -- part1


proc is_valid1(line: DecodedLine): bool =
    let count = line.password
                    .filterIt(it == line.ch)
                    .len
    line.min <= count and count <= line.max


echo decoded_lines.filterIt(is_valid1(it)).len


# -- part2


proc is_valid2(line: DecodedLine): bool =
    var matches = 0
    for i, ch in line.password:
        let position = i + 1
        if line.ch == ch and (position == line.min or position == line.max):
            matches += 1
    matches == 1


echo decoded_lines.filterIt(is_valid2(it)).len
