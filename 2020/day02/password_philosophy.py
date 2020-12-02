"""Day 2: Password Philosophy

Your flight departs in a few days from the coastal airport; the easiest way down
to the coast from here is via toboggan.

The shopkeeper at the North Pole Toboggan Rental Shop is having a bad day.
"Something's wrong with our computers; we can't log in!" You ask if you can take
a look.

Their password database seems to be a little corrupted: some of the passwords
wouldn't have been allowed by the Official Toboggan Corporate Policy that was
in effect when they were chosen.

To try to debug the problem, they have created a list (your puzzle input) of
passwords (according to the corrupted database) and the corporate policy when
that password was set.

For example, suppose you have the following list:

1-3 a: abcde
1-3 b: cdefg
2-9 c: ccccccccc

Each line gives the password policy and then the password. The password policy
indicates the lowest and highest number of times a given letter must appear for
the password to be valid. For example, 1-3 a means that the password must
contain a at least 1 time and at most 3 times.

In the above example, 2 passwords are valid. The middle password, cdefg, is not;
it contains no instances of b, but needs at least 1. The first and third
passwords are valid: they contain one a or nine c, both within the limits of
their respective policies.

How many passwords are valid according to their policies?

--- Part Two ---
While it appears you validated the passwords correctly, they don't seem to be
what the Official Toboggan Corporate Authentication System is expecting.

The shopkeeper suddenly realizes that he just accidentally explained the
password policy rules from his old job at the sled rental place down the street!
The Official Toboggan Corporate Policy actually works a little differently.

Each policy actually describes two positions in the password, where 1 means the
first character, 2 means the second character, and so on. (Be careful; Toboggan
Corporate Policies have no concept of "index zero"!) Exactly one of these
positions must contain the given letter. Other occurrences of the letter are
irrelevant for the purposes of policy enforcement.

Given the same example list from above:

1-3 a: abcde is valid: position 1 contains a and position 3 does not.
1-3 b: cdefg is invalid: neither position 1 nor position 3 contains b.
2-9 c: ccccccccc is invalid: both position 2 and position 9 contain c.

How many passwords are valid according to the new interpretation of the policies?

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
