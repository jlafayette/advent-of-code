"""Day 13: Shuttle Search

https://adventofcode.com/2020/day/13

"""
import sys
from itertools import count
from pathlib import Path
from typing import NamedTuple, List

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
    ("123\n17,x,13", 102),
    ("123\n17,x,13,19", 3417),
    ("123\n67,7,59,61", 754018),
    ("123\n67,x,7,59,61", 779210),
    ("123\n67,7,x,59,61", 1261476),
    ("123\n1789,37,47,1889", 1202161486),
])
def test_part2(schedule, expected):
    assert part2(schedule) == expected


class Bus(NamedTuple):
    id: int
    index: int


def parse_input(data):
    _, schedule = data.strip().split("\n")
    buses = [
        Bus(id=int(s), index=i)
        for i, s in enumerate(schedule.split(","))
        if s != "x"
    ]
    return buses


def part2(data: str):
    first, *rest = parse_input(data)

    def recursive(buses: List[Bus], start: int, step: int) -> int:
        if not buses:
            return start
        bus = buses[0]
        for i in count(start, step):
            if (i + bus.index) % bus.id == 0:
                return recursive(buses[1:], i, bus.id*step)

    return recursive(rest, first.index, first.id)


def main():
    input_file = Path(__file__).parent / "input"
    data = input_file.read_text()

    print(part1(data))
    print(part2(data))


if __name__ == "__main__":
    main()
