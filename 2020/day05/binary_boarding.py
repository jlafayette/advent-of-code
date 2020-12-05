from pathlib import Path

import pytest

"""
BFFFBBFRRR: row 70, column 7, seat ID 567.
FFFBBBFRRR: row 14, column 7, seat ID 119.
BBFFBBFRLL: row 102, column 4, seat ID 820.
"""


def b(min, max, hi):
    mid = (max - min) // 2
    if hi:
        return mid + 1 + min, max
    else:
        return min, mid + min


def is_hi(x: str) -> bool:
    return {
        "F": False,
        "B": True,
        "L": False,
        "R": True,
    }[x]


def decode_seat(seat: str) -> (int, int, int):
    # row: 0 - 127
    # col: 0 - 7
    row_lo = 0
    row_hi = 127
    for x in seat[:7]:
        row_lo, row_hi = b(row_lo, row_hi, is_hi(x))
    row = row_lo

    col_lo = 0
    col_hi = 7
    for x in seat[7:]:
        col_lo, col_hi = b(col_lo, col_hi, is_hi(x))
    col = col_lo

    return row, col, row * 8 + col


@pytest.mark.parametrize("seat,expected", [
    ("BFFFBBFRRR", (70, 7, 567)),
    ("FFFBBBFRRR", (14, 7, 119)),
    ("BBFFBBFRLL", (102, 4, 820)),
])
def test_decode_seat(seat, expected):
    assert decode_seat(seat) == expected


def part1(data: str) -> int:
    seats = data.strip().split("\n")
    return max([decode_seat(x)[2] for x in seats])


def part2(data: str):
    seats = data.strip().split("\n")

    codes = [decode_seat(x)[2] for x in seats]
    codes.sort()

    all_codes = []
    for row in range(128):
        for col in range(8):
            all_codes.append(row * 8 + col)

    diff = set(codes).symmetric_difference(set(all_codes))

    candidates = []

    # print()
    diff_list = sorted(list(diff))
    last = diff_list[0] - 1
    for x in diff_list:
        if (x - 1) != last:
            # print(x)
            candidates.append(x)
        last = x
    # print()

    candidates2 = []

    # print()
    diff_list.reverse()
    last = diff_list[0] + 1
    for x in diff_list:
        if (x + 1) != last:
            # print(x)
            candidates2.append(x)
        last = x
    # print()

    for c1 in candidates:
        if c1 in candidates2:
            return c1


def main():
    input_file = Path(__file__).parent / "input"
    data = input_file.read_text()

    # part 1   time elapsed 29 min
    print(part1(data))

    # part 2   time elapsed 44 min
    print(part2(data))


if __name__ == "__main__":
    main()
