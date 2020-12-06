"""Day 1: Report Repair

https://adventofcode.com/2020/day/1

"""
import itertools
import operator
from functools import reduce
from pathlib import Path
from typing import Optional, List


def main() -> None:
    # read from input and convert to list of integers
    entries = get_entries()

    # find product of entries that sum to 2020
    result2 = product_of_entries(entries, 2)
    print(result2)
    result3 = product_of_entries(entries, 3)
    print(result3)


def get_entries() -> List[int]:
    input_file = Path(__file__).parent / "input"
    text = input_file.read_text()
    split = text.split()
    entries = [int(entry) for entry in split]
    return entries


def product_of_entries(entries: List[int], number: int) -> Optional[int]:

    # Thanks to Shawn Frueh for the idea of using itertools.combinations
    # https://github.com/ShawnFrueh/advent_of_code/blob/266cada3c6d4949d7d88b4be75fbc85cc903b291/2020/day_01/answer.py#L30
    for combination in itertools.combinations(entries, number):
        if sum(combination) == 2020:
            return reduce(operator.mul, combination, 1)


if __name__ == '__main__':
    main()
