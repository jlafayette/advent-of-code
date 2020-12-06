"""Day 2: Password Philosophy

https://adventofcode.com/2020/day/2

"""
from pathlib import Path
from typing import NamedTuple, List

import pytest


def main() -> None:
    # read from file
    input_str = read_input()

    # parse input
    lines = parse_input(input_str)

    # filter input to valid passwords
    valid_lines1 = [line for line in lines if line_is_valid1(line)]
    valid_lines2 = [line for line in lines if line_is_valid2(line)]

    # print number of valid passwords for rule1 and rule2
    print(len(valid_lines1))
    print(len(valid_lines2))


def read_input() -> str:
    input_file = Path(__file__).parent / "input"
    return input_file.read_text()


class Line(NamedTuple):
    password: str
    letter: str
    min: int
    max: int


def parse_line(line: str) -> Line:
    parts = line.strip().split(" ")
    if len(parts) != 3:
        raise ValueError(f"Invalid line: {line}, expected 3 parts separated by spaces")
    range_part, letter_part, password = parts
    min_, max_ = range_part.split("-")
    min_ = int(min_.strip())
    max_ = int(max_.strip())
    letter = letter_part.rstrip(":")
    return Line(password=password.strip(), letter=letter.strip(), min=min_, max=max_)


@pytest.mark.parametrize("line,expected", [
    ("4-6 g: vslqbgg", Line(password="vslqbgg", letter="g", min=4, max=6)),
    ("2-9 c: ccccccccc", Line(password="ccccccccc", letter="c", min=2, max=9)),
])
def test_parse_line(line, expected):
    result = parse_line(line)

    assert result == expected


def parse_input(input_str: str) -> List[Line]:
    lines = []
    for line in input_str.strip().split("\n"):
        try:
            lines.append(parse_line(line))
        except Exception as err:
            print(f"Failed to parse line: {line} with {err.__class__.__name__}: {err}")
    return lines


def line_is_valid1(line: Line) -> bool:
    occurrences = 0
    for letter in line.password:
        if line.letter == letter:
            occurrences += 1
    return line.min <= occurrences <= line.max


@pytest.mark.parametrize("line,expected", [
    (Line(password="abcde", letter="a", min=1, max=3), True),
    (Line(password="cdefg", letter="b", min=1, max=3), False),
    (Line(password="ccccccccc", letter="c", min=2, max=9), True),
])
def test_line_is_valid1(line, expected):
    result = line_is_valid1(line)

    assert result == expected


def line_is_valid2(line: Line) -> bool:
    matches = 0
    for index, letter in enumerate(line.password):
        position = index + 1
        if line.letter == letter and position in [line.min, line.max]:
            matches += 1
    return matches == 1


@pytest.mark.parametrize("line,expected", [
    (Line(password="abcde", letter="a", min=1, max=3), True),
    (Line(password="cdefg", letter="b", min=1, max=3), False),
    (Line(password="ccccccccc", letter="c", min=2, max=9), False),
])
def test_line_is_valid2(line, expected):
    result = line_is_valid2(line)

    assert result == expected


if __name__ == '__main__':
    main()
