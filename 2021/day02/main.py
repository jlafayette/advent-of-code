import enum
from dataclasses import dataclass
from pathlib import Path


class Dir(enum.Enum):
    UP = "up"
    DOWN = "down"
    FORWARD = "forward"


@dataclass(frozen=True)
class Instruction:
    dir: Dir
    amount: int


def parse_input(data: str) -> list[Instruction]:
    instructions = []
    for line in data.strip().split("\n"):
        dir_str, amount_str = line.strip().split(" ")
        try:
            instructions.append(
                Instruction(
                    dir=Dir(dir_str),
                    amount=int(amount_str),
                )
            )
        except ValueError as err:
            print(f"Bad instruction {line!r}, {err}")
    return instructions


def test_parse_newline() -> None:
    """Newline should be stripped from the end."""
    data = """forward 5
down 5
up 3
"""

    actual = parse_input(data)

    expected = [
        Instruction(dir=Dir.FORWARD, amount=5),
        Instruction(dir=Dir.DOWN, amount=5),
        Instruction(dir=Dir.UP, amount=3),
    ]
    assert actual == expected


def test_parse_bad_instruction() -> None:
    """Bad instructions should be skipped."""
    data = """forward 5
down 5
up 3
back 123
"""

    actual = parse_input(data)

    expected = [
        Instruction(dir=Dir.FORWARD, amount=5),
        Instruction(dir=Dir.DOWN, amount=5),
        Instruction(dir=Dir.UP, amount=3),
    ]
    assert actual == expected


def test_parse_bad_instruction_no_number() -> None:
    """Bad instructions should be skipped."""
    data = """forward ABC
up 3
"""

    actual = parse_input(data)

    expected = [
        Instruction(dir=Dir.UP, amount=3),
    ]
    assert actual == expected


def part1(instructions: list[Instruction]) -> int:
    horizontal_pos = 0
    depth = 0
    for instruction in instructions:
        if instruction.dir == Dir.FORWARD:
            horizontal_pos += instruction.amount
        elif instruction.dir == Dir.UP:
            depth -= instruction.amount
        elif instruction.dir == Dir.DOWN:
            depth += instruction.amount

    return horizontal_pos * depth


def test_part1() -> None:
    instructions = parse_input("""forward 5
down 5
forward 8
up 3
down 8
forward 2""")

    actual = part1(instructions)

    expected = 150
    assert actual == expected


def part2(instructions: list[Instruction]) -> int:
    horizontal_pos = 0
    depth = 0
    aim = 0

    for instruction in instructions:
        if instruction.dir == Dir.FORWARD:
            horizontal_pos += instruction.amount
            depth += aim * instruction.amount
        elif instruction.dir == Dir.UP:
            aim -= instruction.amount
        elif instruction.dir == Dir.DOWN:
            aim += instruction.amount

    return horizontal_pos * depth


def test_part2() -> None:
    instructions = parse_input("""forward 5
down 5
forward 8
up 3
down 8
forward 2""")

    actual = part2(instructions)

    expected = 900
    assert actual == expected


def main() -> None:
    data = Path("input").read_text()
    instructions = parse_input(data)

    answer1 = part1(instructions)
    print(answer1)

    answer2 = part2(instructions)
    print(answer2)


if __name__ == "__main__":
    main()
