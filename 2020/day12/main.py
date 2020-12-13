"""Day 12: Rain Risk

https://adventofcode.com/2020/day/12

"""
import re
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Optional, NamedTuple


# -- part 1


TEST_DATA = """F10
N3
F7
R90
F11"""


class Direction(Enum):
    North = 0
    West = 1
    South = 2
    East = 3


class Turn(Enum):
    Left = "Left"
    Right = "Right"


class Ferry(object):
    def __init__(self):
        self.heading = Direction.East
        self.x = 0  # east is positive
        self.y = 0  # north is positive

    def left(self, amount: int):
        steps = amount // 90
        self.turn(steps, Turn.Left)

    def right(self, amount: int):
        steps = amount // 90
        self.turn(steps, Turn.Right)

    def turn(self, steps: int, dir: Turn):
        while steps > 0:
            if dir == Turn.Left:
                self.heading = Direction((self.heading.value + 1) % 4)
            elif dir == Turn.Right:
                self.heading = Direction((self.heading.value - 1) % 4)
            steps -= 1

    def move(self, dir: Optional[Direction], amount: int):
        if dir is None:
            dir = self.heading
        if dir == Direction.North:
            self.y += amount
        elif dir == Direction.West:
            self.x -= amount
        elif dir == Direction.South:
            self.y -= amount
        elif dir == Direction.East:
            self.x += amount

    def manhatten_distance(self):
        return abs(self.x) + abs(self.y)


class Instruction(NamedTuple):
    type: str
    amount: int


def instructions(data: str):
    strs = data.strip().split("\n")
    pattern = re.compile(r'(\w)(\d+)')
    results = []
    for s in strs:
        if m := pattern.match(s):
            letter = m.groups()[0]
            number = int(m.groups()[1])
            # print(f"{letter} - {number}")
            results.append(Instruction(type=letter, amount=number))
    return results


def part1(data: str):
    f = Ferry()
    for type_, amount in instructions(data):
        if type_ == "F":
            f.move(None, amount)
        elif type_ == "L":
            f.left(amount)
        elif type_ == "R":
            f.right(amount)
        elif type_ == "N":
            f.move(Direction.North, amount)
        elif type_ == "E":
            f.move(Direction.East, amount)
        elif type_ == "W":
            f.move(Direction.West, amount)
        elif type_ == "S":
            f.move(Direction.South, amount)

    return f.manhatten_distance()


# -- part 2


@dataclass
class Point:
    north: int
    east: int


class WaypointFerry(object):
    def __init__(self):
        self.heading = Direction.East
        self.waypoint = Point(north=1, east=10)
        self.pos = Point(north=0, east=0)

    def left(self, amount: int):
        steps = amount // 90
        self.turn(steps, Turn.Left)

    def right(self, amount: int):
        steps = amount // 90
        self.turn(steps, Turn.Right)

    def turn(self, steps: int, dir: Turn):
        while steps > 0:
            e = self.waypoint.east
            n = self.waypoint.north
            if dir == Turn.Left:
                self.waypoint.east = -n
                self.waypoint.north = e
            elif dir == Turn.Right:
                self.waypoint.east = n
                self.waypoint.north = -e
            steps -= 1

    def move(self, amount: int):
        self.pos.north += self.waypoint.north * amount
        self.pos.east += self.waypoint.east * amount

    def move_waypoint(self, dir: Direction, amount: int):
        if dir == Direction.North:
            self.waypoint.north += amount
        elif dir == Direction.West:
            self.waypoint.east -= amount
        elif dir == Direction.South:
            self.waypoint.north -= amount
        elif dir == Direction.East:
            self.waypoint.east += amount

    def manhatten_distance(self):
        return abs(self.pos.north) + abs(self.pos.east)


def part2(data: str):
    f = WaypointFerry()
    for type_, amount in instructions(data):
        if type_ == "F":
            f.move(amount)
        elif type_ == "L":
            f.left(amount)
        elif type_ == "R":
            f.right(amount)
        elif type_ == "N":
            f.move_waypoint(Direction.North, amount)
        elif type_ == "E":
            f.move_waypoint(Direction.East, amount)
        elif type_ == "W":
            f.move_waypoint(Direction.West, amount)
        elif type_ == "S":
            f.move_waypoint(Direction.South, amount)

    return f.manhatten_distance()


def main():
    input_file = Path(__file__).parent / "input"
    data = input_file.read_text()

    print(part1(data))
    print(part2(data))


if __name__ == "__main__":
    main()
