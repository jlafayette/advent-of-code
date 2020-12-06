"""Day 5: Report Repair 

https://adventofcode.com/2020/day/5

Cleaned up solution

"""
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import pytest


@dataclass
class DecodedSeat:
    row: int
    col: int

    @property
    def id(self) -> int:
        return calculate_id(self.row, self.col)


def calculate_id(row: int, col: int) -> int:
    return row * 8 + col


def decode_seat(seat: str) -> DecodedSeat:
    seat = seat.replace("F", "0").replace("B", "1").replace("L", "0").replace("R", "1")
    row_part = seat[:7]
    col_part = seat[7:]
    row = int(f"0b{row_part}", 2)
    col = int(f"0b{col_part}", 2)
    return DecodedSeat(row=row, col=col)


@pytest.mark.parametrize("encoded_seat,expected", [
    ("BFFFBBFRRR", (70, 7, 567)),
    ("FFFBBBFRRR", (14, 7, 119)),
    ("BBFFBBFRLL", (102, 4, 820)),
])
def test_decode_seat(encoded_seat, expected):
    assert decode_seat(encoded_seat) == expected


def part1(data: str) -> int:
    encoded_seats = data.strip().split("\n")
    return max([decode_seat(x).id for x in encoded_seats])


def all_ids() -> Iterable[int]:
    max_id = calculate_id(127, 7)
    return range(max_id + 1)


def part2(data: str):
    encoded_seats = data.strip().split("\n")
    ids = [decode_seat(x).id for x in encoded_seats]
    for seat_id in all_ids():
        if (
            seat_id + 1 in ids and
            seat_id - 1 in ids and
            seat_id not in ids
        ):
            return seat_id


def main():
    input_file = Path(__file__).parent / "input"
    data = input_file.read_text()
    print(part1(data))
    print(part2(data))


if __name__ == "__main__":
    main()
