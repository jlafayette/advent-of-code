import dataclasses
from enum import Enum
from pathlib import Path
from typing import Optional


@dataclasses.dataclass
class Loc:
    x: int
    y: int
    type: str


@dataclasses.dataclass
class DirLoc:
    x: int
    y: int
    type: str
    conn: Loc

    @classmethod
    def from_loc(cls, loc: Loc, conn: Loc) -> "DirLoc":
        return cls(loc.x, loc.y, loc.type, conn)


INPUT = (Path(__file__).absolute().parent / "input").read_text().strip()
DATA = """\
.....
.S-7.
.|.|.
.L-J.
.....\
"""
DATA2 = """\
..F7.
.FJ|.
SJ.L7
|F--J
LJ...\
"""


def split_and_strip(data: str, sep: str) -> list[str]:
    parts = data.strip().split(sep)
    return [p.strip() for p in parts]


class Dir(Enum):
    UP = 0
    RIGHT = 1
    DOWN = 2
    LEFT = 3


class Grid:
    def __init__(self, data: str):
        self._g: list[str] = split_and_strip(data, "\n")

    def get(self, x, y) -> Optional[Loc]:
        try:
            return Loc(x, y, self._g[y][x])
        except IndexError:
            return None

    def rows(self):
        yield from self._g

    def print_neighborhood(self, loc: Loc):
        print(f"neighborhood of {loc.type} at {loc.x},{loc.y}")
        for y in range(loc.y-1, loc.y+2):
            for x in range(loc.x-1, loc.x+2):
                print(self._g[y][x], end="")
            print()

    def find_second_conn(self, dl: DirLoc) -> DirLoc:
        f = dl.conn
        c = Loc(dl.x, dl.y, dl.type)
        x = c.x
        y = c.y
        if f.x == x and f.y == y - 1:
            f_dir = Dir.UP
        elif f.x == x and f.y == y + 1:
            f_dir = Dir.DOWN
        elif f.x == x - 1 and f.y == y:
            f_dir = Dir.LEFT
        elif f.x == x + 1 and f.y == y:
            f_dir = Dir.RIGHT
        else:
            raise ValueError("connection not connected")
        if f_dir != Dir.UP:
            up = self.get(x, y-1)
            if up and up.type in "|7F" and c.type in "|LJ":
                return DirLoc.from_loc(up, c)
        if f_dir != Dir.DOWN:
            down = self.get(x, y+1)
            if down and down.type in "|LJ" and c.type in "|7F":
                return DirLoc.from_loc(down, c)
        if f_dir != Dir.LEFT:
            left = self.get(x-1, y)
            if left and left.type in "-FL" and c.type in "-7J":
                return DirLoc.from_loc(left, c)
        if f_dir != Dir.RIGHT:
            right = self.get(x+1, y)
            if right and right.type in "-7J" and c.type in "-FL":
                return DirLoc.from_loc(right, c)
        self.print_neighborhood(f)
        self.print_neighborhood(c)

        raise ValueError("no second connection")


def part1(data):
    grid = Grid(data)

    def find_s() -> Loc:
        for y, row in enumerate(grid.rows()):
            for x, char in enumerate(row):
                if char == "S":
                    return Loc(x, y, "S")
        raise ValueError("No S location found")

    s_loc = find_s()
    print(s_loc)

    # follow pipes around until next is already visited
    # alternate between two options
    # .F-7.
    # .|.|.
    # .L-J.
    def find_s_connections(loc: Loc) -> tuple[DirLoc, DirLoc]:
        conns: list[Loc] = list()
        sx = loc.x
        sy = loc.y
        up = grid.get(sx, sy-1)
        if up and up.type in "|7F":
            conns.append(up)
        down = grid.get(sx, sy+1)
        if down and down.type in "|LJ":
            conns.append(down)
        left = grid.get(sx-1, sy)
        if left and left.type in "-FL":
            conns.append(left)
        right = grid.get(sx+1, sy)
        if right and right.type in "-7J":
            conns.append(right)
        assert len(conns) == 2
        a, b = conns
        return DirLoc.from_loc(a, loc), DirLoc.from_loc(b, loc)

    c1, c2 = find_s_connections(s_loc)
    print(c1)
    print(c2)
    distance = 1
    visited: set[tuple[int, int]] = set()
    visited.add((c1.x, c1.y))
    visited.add((c2.x, c2.y))
    while True:
        distance += 1

        # find next conn of c1
        next_c1 = grid.find_second_conn(c1)
        if (next_c1.x, next_c1.y) in visited:
            break
        c1 = next_c1
        visited.add((c1.x, c1.y))

        # find next conn of c2
        next_c2 = grid.find_second_conn(c2)
        if (next_c2.x, next_c2.y) in visited:
            break
        c2 = next_c2
        visited.add((c2.x, c2.y))

    print("Distance:", distance)


def part2(data):
    ...


# part1(DATA)
# part1(DATA2)
part1(INPUT)
# part2(DATA)
# part2(INPUT)
