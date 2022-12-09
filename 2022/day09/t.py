import dataclasses
import enum
from pathlib import Path


TEST_INPUT = """R 4
U 4
L 3
D 1
R 4
D 1
L 5
R 2"""


def read_input():
    input_file = Path(__file__).absolute().parent / "input"
    data = input_file.read_text()
    # data = TEST_INPUT
    return data.strip().split("\n")


class Dir(enum.Enum):
    L = "L"
    R = "R"
    U = "U"
    D = "D"


class H:
    def __init__(self, x: int, y: int):
        self.x = x
        self.y = y

    def move(self, d: Dir):
        if d == Dir.L:
            self.x -= 1
        elif d == Dir.R:
            self.x += 1
        elif d == Dir.U:
            self.y += 1
        else:
            self.y -= 1

    def __str__(self):
        return f"({self.x},{self.y})"


class T(H):

    def follow(self, h: H):
        x_diff = abs(h.x - self.x)
        y_diff = abs(h.y - self.y)
        # print(f"{h} {self} diff({x_diff},{y_diff}) ", end="")
        if x_diff <= 1 and y_diff <= 1:
            return
        x_dir = Dir.L
        if h.x > self.x:
            x_dir = Dir.R
        if x_diff == 2 and y_diff == 0:
            self.move(x_dir)
            return
        y_dir = Dir.D
        if h.y > self.y:
            y_dir = Dir.U
        if x_diff == 0 and y_diff == 2:
            self.move(y_dir)
            return
        # print(f"<{x_dir.value}{y_dir.value}>")
        self.move(x_dir)
        self.move(y_dir)


class Motion:
    def __init__(self, s: str):
        d, c = s.split()
        self.dir = Dir(d)
        self.count = int(c)


class Sim:
    def __init__(self, motions: list[str]):
        self.h = H(0, 0)
        self.t = T(0, 0)
        self.motions = motions
        self.motions.reverse()
        self.motion = Motion("L 0")
        self.done = False
        self.visited = set()

    def run(self):
        # self.print()
        while not self.done:
            self.step()
            # self.print()

        # print("done")

    def print(self):
        h = self.h
        t = self.t
        rows = []
        for y in range(0, 6):
            row = ""
            for x in range(0, 6):
                if x == h.x and y == h.y:
                    row += "H"
                elif x == t.x and y == t.y:
                    row += "T"
                else:
                    row += "."
            rows.append(row)
        rows.reverse()
        for row in rows:
            print(row)
        print()

    def step(self):
        if self.motion.count == 0:
            try:
                self.motion = Motion(self.motions.pop())
            except IndexError:
                self.done = True
                return
        # print(f"{self.motion.dir.value} {self.motion.count}", end=" ")
        self.motion.count -= 1
        self.h.move(self.motion.dir)
        self.t.follow(self.h)
        # print((self.t.x, self.t.y))
        self.visited.add((self.t.x, self.t.y))


def part1():
    motions = read_input()
    sim = Sim(motions)
    sim.run()
    print(len(sim.visited))


class Sim2:
    def __init__(self, motions: list[str]):
        self.knots = []
        for i in range(10):
            if i == 0:
                self.knots.append(H(0, 0))
            else:
                self.knots.append(T(0, 0))
        self.motions = motions
        self.motions.reverse()
        self.motion = Motion("L 0")
        self.done = False
        self.visited = set()

    def run(self):
        # self.print()
        while not self.done:
            self.step()
            # self.print()

        # print("done")

    def print(self):
        h = self.knots[0]
        ts = self.knots[1:]
        rows = []
        for y in range(0, 6):
            row = ""
            for x in range(0, 6):
                if x == h.x and y == h.y:
                    row += "H"
                    continue
                for i, t in enumerate(ts, start=1):
                    if x == t.x and y == t.y:
                        row += str(i)
                        break
                else:
                    row += "."
            rows.append(row)
        rows.reverse()
        for row in rows:
            print(row)
        print()

    def step(self):
        if self.motion.count == 0:
            try:
                self.motion = Motion(self.motions.pop())
            except IndexError:
                self.done = True
                return
        # print(f"{self.motion.dir.value} {self.motion.count}", end=" ")
        self.motion.count -= 1
        self.knots[0].move(self.motion.dir)
        for i in range(1, 10):
            self.knots[i].follow(self.knots[i-1])
        # print((self.t.x, self.t.y))
        t = self.knots[-1]
        self.visited.add((t.x, t.y))


TEST_INPUT2 = """R 5
U 8
L 8
D 3
R 17
D 10
L 25
U 20"""


def read_input2():
    input_file = Path(__file__).absolute().parent / "input"
    data = input_file.read_text()
    # data = TEST_INPUT2
    return data.strip().split("\n")


def part2():
    motions = read_input2()
    sim = Sim2(motions)
    sim.run()
    print(len(sim.visited))


part1()
part2()
