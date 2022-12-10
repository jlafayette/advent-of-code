import dataclasses
import enum
from pathlib import Path
from typing import TypeAlias, Union, Optional


TEST_INPUT = """noop
addx 3
addx -5"""


TEST_INPUT2 = """addx 15
addx -11
addx 6
addx -3
addx 5
addx -1
addx -8
addx 13
addx 4
noop
addx -1
addx 5
addx -1
addx 5
addx -1
addx 5
addx -1
addx 5
addx -1
addx -35
addx 1
addx 24
addx -19
addx 1
addx 16
addx -11
noop
noop
addx 21
addx -15
noop
noop
addx -3
addx 9
addx 1
addx -3
addx 8
addx 1
addx 5
noop
noop
noop
noop
noop
addx -36
noop
addx 1
addx 7
noop
noop
noop
addx 2
addx 6
noop
noop
noop
noop
noop
addx 1
noop
noop
addx 7
addx 1
noop
addx -13
addx 13
addx 7
noop
addx 1
addx -33
noop
noop
noop
addx 2
noop
noop
noop
addx 8
noop
addx -1
addx 2
addx 1
noop
addx 17
addx -9
addx 1
addx 1
addx -3
addx 11
noop
noop
addx 1
noop
addx 1
noop
noop
addx -13
addx -19
addx 1
addx 3
addx 26
addx -30
addx 12
addx -1
addx 3
addx 1
noop
noop
noop
addx -9
addx 18
addx 1
addx 2
noop
noop
addx 9
noop
noop
noop
addx -1
addx 2
addx -37
addx 1
addx 3
noop
addx 15
addx -21
addx 22
addx -6
addx 1
noop
addx 2
addx 1
noop
addx -10
noop
noop
addx 20
addx 1
addx 2
addx 2
addx -6
addx -11
noop
noop
noop"""


class Noop:
    def __init__(self):
        self.cycles = 1


class AddX:
    def __init__(self, v: int):
        self.v = v
        self.cycles = 2


I: TypeAlias = Union[Noop, AddX]


def parse_i(i: str) -> I:
    if i == "noop":
        return Noop()
    else:
        _, v = i.split()
        return AddX(int(v))


INPUT = (Path(__file__).absolute().parent / "input").read_text()


def read_input(data: str):
    return [parse_i(i) for i in data.strip().split("\n")]


class Cpu:
    def __init__(self, i: list[I], read_cycles=None):
        self.instructions = list(reversed(i))
        self.i = self.instructions.pop()
        self.x = 1
        self.read_cycles = read_cycles
        self.cycle = 0

    def run(self):
        while True:
            try:
                v = self.next()
                if v is not None:
                    yield v
            except StopIteration:
                return

    def next(self):
        self.cycle += 1
        if self.i.cycles == 0:
            if isinstance(self.i, AddX):
                self.x += self.i.v
            try:
                self.i = self.instructions.pop()
            except IndexError:
                raise StopIteration("done") from None
        self.i.cycles -= 1
        if self.read_cycles is None or self.cycle in self.read_cycles:
            return self.x
        return None


def part1():
    instructions = read_input(INPUT)
    cpu = Cpu(instructions, [20, 60, 100, 140, 180, 220])
    result = 0
    for x in cpu.run():
        result += cpu.cycle * x
        print(cpu.cycle, x, cpu.cycle * x)
    print(result)


class Cpu2:
    def __init__(self, i: list[I]):
        self.instructions = list(reversed(i))
        self.i = self.instructions.pop()
        self.x = 1
        self.cycle = 0

    def run(self):
        while True:
            try:
                v = self.next()
                yield v
            except StopIteration:
                return

    def next(self):
        self.cycle += 1
        if self.i.cycles == 0:
            if isinstance(self.i, AddX):
                self.x += self.i.v
            try:
                self.i = self.instructions.pop()
            except IndexError:
                raise StopIteration("done") from None
        self.i.cycles -= 1

        # return the pixel drawn
        draw_pos = (self.cycle - 1) % 40
        diff = abs(draw_pos - self.x)
        if diff <= 1:
            result = "#"
        else:
            result = "."
        if self.cycle % 40 == 0:
            result += "\n"
        return result


"""
##..##..##..##..##..##..##..##..##..##..
###...###...###...###...###...###...###.
####....####....####....####....####....
#####.....#####.....#####.....#####.....
######......######......######......####
#######.......#######.......#######.....

##..##..##..##..##..##..##..##..##..##..
###...###...###...###...###...###...###.
####....####....####....####....####....
#####.....#####.....#####.....#####.....
######......######......######......####
#######.......#######.......#######.....

"""


def part2():
    instructions = read_input(INPUT)
    cpu = Cpu2(instructions)
    for x in cpu.run():
        print(x, end="")


part1()
part2()
