import dataclasses
import queue
from queue import Queue
from enum import Enum
from pathlib import Path
from typing import Optional, Union


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

    def find_s(self) -> Loc:
        for y, row in enumerate(self.rows()):
            for x, char in enumerate(row):
                if char == "S":
                    return Loc(x, y, "S")
        raise ValueError("No S location found")

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

    s_loc = grid.find_s()
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


DATA2_1 = """\
...........
.S-------7.
.|F-----7|.
.||.....||.
.||.....||.
.|L-7.F-J|.
.|..|.|..|.
.L--J.L--J.
...........\
"""


class Grid2(Grid):
    def __init__(self, data):
        self._data = data
        super(Grid2, self).__init__(data)
        self.s = self.find_s()
        self._visited: set[tuple[int, int]] = set()
        self._conn: set[tuple[int, int, int, int]] = set()

    def find_s_connections(self) -> tuple[DirLoc, DirLoc]:
        conns: list[Loc] = list()
        sx = self.s.x
        sy = self.s.y
        up = self.get(sx, sy - 1)
        if up and up.type in "|7F":
            conns.append(up)
        down = self.get(sx, sy + 1)
        if down and down.type in "|LJ":
            conns.append(down)
        left = self.get(sx - 1, sy)
        if left and left.type in "-FL":
            conns.append(left)
        right = self.get(sx + 1, sy)
        if right and right.type in "-7J":
            conns.append(right)
        assert len(conns) == 2
        a, b = conns
        return DirLoc.from_loc(a, self.s), DirLoc.from_loc(b, self.s)

    def mark_conn(self, a, b):
        self._conn.add((a.x, a.y, b.x, b.y))
        self._conn.add((b.x, b.y, a.x, a.y))

    def is_conn(self, a, b):
        return (a.x, a.y, b.x, b.y) in self._conn

    def mark_visited(self, loc: Loc | DirLoc):
        self._visited.add((loc.x, loc.y))

    def visited(self, loc: Loc | DirLoc) -> bool:
        return (loc.x, loc.y) in self._visited

    def debug_print(self):
        out = ""
        for y, row in enumerate(self.rows()):
            for x, char in enumerate(row):
                if (x, y) in self._visited:
                    out += "O"
                else:
                    out += "."
            out += "\n"
        # print(out)
        # (Path(__file__).absolute().parent / "debug").write_text(out)

    def flood_fill(self):
        # do a flood fill from 0,0 corner along edges
        def f(x, y):
            if x <= len(self._g[0]):
                q.put((x, y, x+1, y))
            if x > 0:
                q.put((x, y, x-1, y))
            if y <= len(self._g):
                q.put((x, y, x, y+1))
            if y > 0:
                q.put((x, y, x, y-1))

        c = (0, 0)
        q = queue.SimpleQueue()
        visited: set[tuple[int, int, int, int]] = set()
        corners: set[tuple[int, int]] = set()
        f(*c)
        while True:
            try:
                edge = q.get_nowait()
                # print(edge)
            except queue.Empty:
                break
            if edge in visited:
                continue
            x1, y1, x2, y2 = edge
            visited.add((x1, y1, x2, y2))
            visited.add((x2, y2, x1, y1))

            # does edge cross a pipe edge?
            """
            ._._._.
            | | | |
            ._._._.
            | | | |
            ._._._.
            """
            horizontal = y1 == y2
            if horizontal:
                sx, sy = min(x1, x2), y1-1
                ex, ey = min(x1, x2), y1
            else:
                assert x1 == x2
                sx, sy = x1-1, min(y1, y2)
                ex, ey = x1, min(y1, y2)
            if (sx, sy, ex, ey) in self._conn:
                # would cross a pipe, discard
                # print("discard")
                continue
            # else:
            #     print((sx, sy, ex, ey), "not in conn")

            corners.add((x1, y1))
            corners.add((x2, y2))
            f(x2, y2)

        # debug print flood fill
        out = ""
        inside_count = 0
        for y, row in enumerate(self.rows()):
            for x, char in enumerate(row):
                if (
                    (x, y) in corners and
                    (x+1, y) in corners and
                    (x, y+1) in corners and
                    (x+1, y+1) in corners
                ):
                    out += "."
                elif (x, y) in self._visited:
                    out += self.get(x, y).type
                else:
                    out += "I"
                    inside_count += 1
            out += "\n"
        # print(out)
        (Path(__file__).absolute().parent / "debug").write_text(out)
        print("Inside count:", inside_count)


def part2(data):
    grid = Grid2(data)
    grid.mark_visited(grid.s)
    c1, c2 = grid.find_s_connections()
    grid.mark_conn(grid.s, c1)
    grid.mark_conn(grid.s, c2)
    grid.mark_visited(c1)
    grid.mark_visited(c2)
    while True:
        # find next conn of c1
        next_c1 = grid.find_second_conn(c1)
        grid.mark_conn(c1, next_c1)
        grid.mark_visited(next_c1)
        if next_c1.x == c2.x and next_c1.y == c2.y:
            break
        c1 = next_c1

    grid.debug_print()

    # do a flood fill from 0,0 corner along edges
    grid.flood_fill()


import time
start_time = time.perf_counter()
part1(DATA)
part1(DATA2)
part1(INPUT)
part2(DATA2_1)
part2(INPUT)
total_time = time.perf_counter() - start_time
print(f"total: {total_time*1000:.4f} ms")

