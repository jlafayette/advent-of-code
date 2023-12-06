import dataclasses
import functools
from operator import mul
from pathlib import Path


def read_input():
    input_file = Path(__file__).absolute().parent / "input"
    data = input_file.read_text().strip()
    return data


INPUT = read_input()


DATA = """\
Time:      7  15   30
Distance:  9  40  200\
"""


@dataclasses.dataclass
class Race:
    time: int
    distance: int


def parse(data) -> list[Race]:
    time_line, distance_line = data.strip().split("\n")
    times = [int(x) for x in time_line.strip().split(":")[-1].strip().split()]
    distances = [int(x) for x in distance_line.strip().split(":")[-1].strip().split()]
    print(times)
    print(distances)
    return [Race(x, y) for x, y in zip(times, distances)]


def ways_to_win(race: Race) -> int:
    ways = 0

    print(race)

    for time_held in range(race.time+1):
        speed = time_held
        distance = speed * (race.time - time_held)
        # print(time_held, "->", distance)
        if distance > race.distance:
            ways += 1

    return ways


def part1(data):
    races = parse(data)
    result = functools.reduce(mul, [ways_to_win(r) for r in races])
    print(result)


DATA2 = """\
Time:      71530
Distance:  940200\
"""

input_file2 = Path(__file__).absolute().parent / "input2"
INPUT2 = input_file2.read_text().strip()


def part2(data):
    race = parse(data)[0]
    result = ways_to_win(race)
    print(result)


part1(DATA)
part1(INPUT)
part2(DATA2)
part2(INPUT2)
