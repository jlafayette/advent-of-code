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
    for line in data.split("\n"):
        dir_str, amount_str = line.strip().split(" ")
        instructions.append(
            Instruction(
                dir=Dir(dir_str),
                amount=int(amount_str),
            )
        )
    return instructions


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


def main():
    data = Path("input").read_text()
    instructions = parse_input(data)

    answer1 = part1(instructions)
    print(answer1)


if __name__ == "__main__":
    main()
