from pathlib import Path
from enum import Enum


class Move(Enum):
    ROCK = 1
    PAPER = 2
    SCISSORS = 3


def _decode_move(move: str) -> Move:
    if move == "A" or move == "X":
        return Move.ROCK
    elif move == "B" or move == "Y":
        return Move.PAPER
    elif move == "C" or move == "Z":
        return Move.SCISSORS
    else:
        raise ValueError(f"Invalid move {move}")


def _score(move1: Move, move2: Move) -> int:
    if move1 == move2:
        return 3 + move2.value  # draw
    if move2.value == move1.value + 1 or move2 == Move.ROCK and move1 == Move.SCISSORS:
        return 6 + move2.value  # win
    else:
        return 0 + move2.value  # loss


def read_input():
    input_file = Path(__file__).absolute().parent / "input"
    data = input_file.read_text()
    lines = data.strip().split("\n")
    return [line.split() for line in lines]


# Test Input
TEST_INPUT = """A Y
B X
C Z
"""


def part1():
    data = read_input()
    total = 0
    for encoded_mv1, encoded_mv2 in data:
        mv1 = _decode_move(encoded_mv1)
        mv2 = _decode_move(encoded_mv2)
        total += _score(mv1, mv2)
    print(total)


def lose(move: Move) -> Move:
    enum_value = move.value - 1
    if enum_value < 1:
        enum_value = 3
    return Move(enum_value)


def draw(move: Move) -> Move:
    return move


def win(move: Move) -> Move:
    enum_value = move.value + 1
    if enum_value > 3:
        enum_value = 1
    return Move(enum_value)


def part2():
    data = read_input()
    total = 0
    # now second is desired outcome
    # X=lose, Y=draw, Z=win
    for encoded_mv1, desired_outcome in data:
        opponent_move = _decode_move(encoded_mv1)
        func = {
            "X": lose,
            "Y": draw,
            "Z": win,
        }[desired_outcome]
        total += _score(opponent_move, func(opponent_move))
    print(total)


part1()
part2()
