import operator
from functools import reduce
from pathlib import Path

import pytest


def trees_encountered(right: int, down: int, tree_map: str) -> int:
    rows = tree_map.strip().split("\n")
    width = len(rows[0])
    x = 0
    trees = 0
    for y, row in enumerate(rows):
        if y % down != 0:
            continue
        position = row[x % width]
        if position == "#":
            trees += 1
        x += right
    return trees


TEST_TREE_MAP = """..##.......
#...#...#..
.#....#..#.
..#.#...#.#
.#...##..#.
..#.##.....
.#.#.#....#
.#........#
#.##...#...
#...##....#
.#..#...#.#
"""


@pytest.mark.parametrize("right,down,expected", [
    (1, 1, 2),
    (3, 1, 7),
    (5, 1, 3),
    (7, 1, 4),
    (1, 2, 2),
])
def test_tree_map(right, down, expected):
    assert trees_encountered(right, down, TEST_TREE_MAP) == expected


def main():
    input_file = Path(__file__).parent / "input"
    tree_map = input_file.read_text()

    # part 1
    print(trees_encountered(3, 1, tree_map))

    # part 2
    product = reduce(operator.mul, [
        trees_encountered(1, 1, tree_map),
        trees_encountered(3, 1, tree_map),
        trees_encountered(5, 1, tree_map),
        trees_encountered(7, 1, tree_map),
        trees_encountered(1, 2, tree_map),
    ], 1)
    print(product)


if __name__ == "__main__":
    main()
