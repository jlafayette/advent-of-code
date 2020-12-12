"""Day 8: Handheld Halting

https://adventofcode.com/2020/day/8

"""
import io
import re
from pathlib import Path


class InfiniteLoopError(Exception):
    pass


class ProgramFinishedError(Exception):
    pass


class Program(io.StringIO):
    # nop_pattern = re.compile(r"nop \+0\n")
    acc_pattern = re.compile(r"acc (\+|-)(\d+)\n?")
    jmp_pattern = re.compile(r"jmp (\+|-)(\d+)\n?")

    def __init__(self, *args, **kwargs):
        self.acc = 0
        self.visited = set()
        super().__init__(*args, **kwargs)

    def peek(self):
        value = self.read(1)
        self.seek(self.tell() - 1, 0)
        return value

    def peekback(self):
        self.seek(self.tell() - 1, 0)
        return self.read(1)

    def jmp(self, offset):
        if offset > 0:
            for _ in range(offset - 1):
                self.readline()
        else:
            for _ in range(abs(offset) + 1):
                self.prevline()

    def prevline(self):
        self.seek(self.tell() - 6, 0)
        prev = self.peekback()
        while prev != '\n':
            self.seek(self.tell() - 1, 0)
            prev = self.peekback()

    def step(self):
        """Process the next line."""
        if not self.peek():
            print("Done!")
            raise ProgramFinishedError("Done!")
        if self.tell() in self.visited:
            raise InfiniteLoopError(self.acc)
        self.visited.add(self.tell())
        command = self.readline()
        if m := self.acc_pattern.match(command):
            # print(f"  command is acc: {command.strip()}")
            sign, offset = m.groups()
            offset = int(offset)
            if sign == '-':
                offset = offset * -1
            self.acc += offset
        elif m := self.jmp_pattern.match(command):
            # print(f"  command is jmp: {command.strip()}")
            sign, offset = m.groups()
            offset = int(offset)
            if sign == '-':
                offset = offset * -1
            self.jmp(offset)

        # print(f"{command.strip()} -> {self.tell()} acc: {self.acc}")

    def run(self):
        try:
            while True:
                self.step()
        except ProgramFinishedError:
            return self.acc



# -- part 1


TEST_DATA = """nop +0
acc +1
jmp +4
acc +3
jmp -3
acc -99
acc +1
jmp -4
acc +6"""


"""
nop +0  | 1
acc +1  | 2, 8(!)
jmp +4  | 3
acc +3  | 6
jmp -3  | 7
acc -99 |
acc +1  | 4
jmp -4  | 5
acc +6  |
"""


def test_part1():
    p = Program(TEST_DATA)
    try:
        p.run()
    except InfiniteLoopError as err:
        assert int(str(err)) == 5


def part1(data: str):
    p = Program(data)
    try:
        p.run()
    except InfiniteLoopError as err:
        return int(str(err))


# -- part2


TEST_DATA2 = """nop +0
acc +1
jmp +4
acc +3
jmp -3
acc -99
acc +1
jmp -4
acc +6"""


"""
nop +0  | 1
acc +1  | 2
jmp +4  | 3
acc +3  |
jmp -3  |
acc -99 |
acc +1  | 4
nop -4  | 5
acc +6  | 6
"""

TEST_DATA3 = """nop +0
acc +1
jmp +4
acc +3
jmp -3
acc -99
acc +1
nop -4
acc +6"""


# def test_terminate():
#     p = Program(TEST_DATA2)
#     p.run()


def part2(data: str):
    lines = data.strip().split("\n")
    for i, line in enumerate(lines):
        new = None
        current = None
        if line.startswith("nop"):
            new = "jmp"
            current = "nop"
        elif line.startswith("jmp"):
            new = "nop"
            current = "jmp"
        if new is None or current is None:
            continue

        lines[i] = line.replace(current, new)

        mutated_data = "\n".join(lines)
        p = Program(mutated_data)
        try:
            result = p.run()
        except InfiniteLoopError:
            lines[i] = line
        else:
            return result


if __name__ == "__main__":
    input_file = Path(__file__).parent / "input"
    data = input_file.read_text()

    print(part1(data))
    print(part2(data))
