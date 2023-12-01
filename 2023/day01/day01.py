import re
from pathlib import Path


def read_input():
    input_file = Path(__file__).absolute().parent / "input"
    data = input_file.read_text().strip()
    return data


DATA = """1abc2
pqr3stu8vwx
a1b2c3d4e5f
treb7uchet
"""
NUMBERS = "0123456789"
pattern = re.compile(r"(\d+)")


def part1(data):
    total = 0
    for line in data.split("\n"):
        line = line.strip()
        if not line:
            continue
        m = pattern.findall(line)
        try:
            first, *_, last = m
            total += int(first[0] + last[-1])
        except ValueError:
            total += int(m[0][0] + m[0][-1])
    print("total:", total)


DATA2 = """two1nine
eightwothree
abcone2threexyz
xtwone3four
4nineeightseven2
zoneight234
7pqrstsixteen"""
pattern2 = re.compile(r"(\d+|one|two|three|four|five|six|seven|eight|nine)")
reversed_pattern2 = re.compile(r"(\d+|eno|owt|eerht|ruof|evif|xis|neves|thgie|enin)")

def part2(data):
    convert = {
        "one": "1",
        "two": "2",
        "three": "3",
        "four": "4",
        "five": "5",
        "six": "6",
        "seven": "7",
        "eight": "8",
        "nine": "9",
    }
    total = 0
    for line in data.split("\n"):
        line = line.strip()
        if not line:
            continue
        # print("-----")
        # print(line)
        forward = pattern2.findall(line)
        backwards = reversed_pattern2.findall("".join(reversed(line)))
        first = forward[0]
        last = backwards[0]
        # print(first, last)
        # if len(m) == 1:
        #     first = last = m[0]
        # else:
        #     first, *_, last = m
        if first in convert:
            first = convert[first]
        rlast = "".join(reversed(last))
        if rlast in convert:
            last = convert[rlast]
        else:
            last = rlast
        # first = convert.get(first, first)
        # last = convert.get(last, last)
        # print(first, last, int(first[0] + last[-1]))
        total += int(first[0] + last[-1])
    print("total:", total)


part1(DATA)
part1(read_input())
part2(DATA2)
part2(read_input())
