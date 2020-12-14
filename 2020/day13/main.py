"""Day 13: Shuttle Search

https://adventofcode.com/2020/day/13

"""
import sys
from pathlib import Path

import pytest


# -- part 1


def part1(data: str):
    earliest_timestamp, bus_id_strings = data.strip().split("\n")
    earliest_timestamp = int(earliest_timestamp)
    bus_id_strings = bus_id_strings.split(",")
    bus_ids = []
    for id_str in bus_id_strings:
        try:
            bus_ids.append(int(id_str))
        except ValueError:
            pass

    earliest_bus_id = sys.maxsize
    earliest_bus_timestamp = sys.maxsize
    for bus_id in bus_ids:
        mult = 1
        while True:
            timestamp = bus_id * mult
            if earliest_timestamp <= timestamp:
                if timestamp < earliest_bus_timestamp:
                    earliest_bus_id = bus_id
                    earliest_bus_timestamp = timestamp
                break
            mult += 1
    minutes_to_wait = earliest_bus_timestamp - earliest_timestamp
    return earliest_bus_id * minutes_to_wait


# -- part 2


@pytest.mark.parametrize("schedule,expected", [
    ("123\n17,x,13,19", 3417),
    ("123\n67,7,59,61", 754018),
    ("123\n67,x,7,59,61", 779210),
    ("123\n67,7,x,59,61", 1261476),
    ("123\n1789,37,47,1889", 1202161486),
])
def test_part2(schedule, expected):
    assert part2(schedule) == expected


def part2(data: str):

    # TODO: Find a more efficient solution. Currently this solves the test
    #       examples but is way to slow for the full data for the challenge.

    _, bus_id_strings = data.strip().split("\n")
    bus_id_strings = bus_id_strings.split(",")
    bus_ids = []
    for id_str in bus_id_strings:
        try:
            bus_ids.append(int(id_str))
        except ValueError:
            bus_ids.append(None)

    largest_id = 0
    largest_index = -1
    for i, bus_id in enumerate(bus_ids):
        if bus_id is None:
            continue
        if bus_id > largest_id:
            largest_id = bus_id
            largest_index = i

    def counter():
        mult = 1
        while True:
            yield (largest_id * mult) - largest_index
            mult += 1

    for t in counter():
        for i, bus_id in enumerate(bus_ids):
            if bus_id is not None:
                if (t + i) % bus_id != 0:
                    break
        else:
            return t


def main():
    input_file = Path(__file__).parent / "input"
    data = input_file.read_text()

    print(part1(data))
    print(part2(data))


if __name__ == "__main__":
    main()
