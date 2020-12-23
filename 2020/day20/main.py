"""Day 20: Jurassic Jigsaw

https://adventofcode.com/2020/day/20

"""
from copy import copy, deepcopy
from pathlib import Path
from typing import List
from operator import mul
from functools import reduce

import pytest


TEST_DATA = """Tile 2311:
..##.#..#.
##..#.....
#...##..#.
####.#...#
##.##.###.
##...#.###
.#.#.#..##
..#....#..
###...#.#.
..###..###

Tile 1951:
#.##...##.
#.####...#
.....#..##
#...######
.##.#....#
.###.#####
###.##.##.
.###....#.
..#.#..#.#
#...##.#..

Tile 1171:
####...##.
#..##.#..#
##.#..#.#.
.###.####.
..###.####
.##....##.
.#...####.
#.##.####.
####..#...
.....##...

Tile 1427:
###.##.#..
.#..#.##..
.#.##.#..#
#.#.#.##.#
....#...##
...##..##.
...#.#####
.#.####.#.
..#..###.#
..##.#..#.

Tile 1489:
##.#.#....
..##...#..
.##..##...
..#...#...
#####...#.
#..#.#.#.#
...#.#.#..
##.#...##.
..##.##.##
###.##.#..

Tile 2473:
#....####.
#..#.##...
#.##..#...
######.#.#
.#...#.#.#
.#########
.###.#..#.
########.#
##...##.#.
..###.#.#.

Tile 2971:
..#.#....#
#...###...
#.#.###...
##.##..#..
.#####..##
.#..####.#
#..#.#..#.
..####.###
..#.#.###.
...#.#.#.#

Tile 2729:
...#.#.#.#
####.#....
..#.#.....
....#..#.#
.##..##.#.
.#.####...
####.#.#..
##.####...
##..#.##..
#.##...##.

Tile 3079:
#.#.#####.
.#..######
..#.......
######....
####.#..#.
.#...#.##.
#.#####.##
..#.###...
..#.......
..#.###..."""


def test_part1():
    assert part1(TEST_DATA) == 20899048083289


def reverse(old: str) -> str:
    new = ""
    for c in old:
        new = c + new
    return new


def flip_grid_x(grid):
    for row in grid:
        row.reverse()


def flip_grid_y(grid):
    grid.reverse()


def rotate_grid_cw(grid):
    rows = deepcopy(grid)
    rows.reverse()
    new_rows = []
    for i in range(len(rows)):
        new_rows.append([row[i] for row in rows])
    return new_rows


def all_alignments(grid):
    yield grid
    grid = rotate_grid_cw(grid)
    yield grid
    grid = rotate_grid_cw(grid)
    yield grid
    grid = rotate_grid_cw(grid)
    yield grid
    grid = rotate_grid_cw(grid)
    flip_grid_x(grid)
    print("fx", end=" ")
    grid = rotate_grid_cw(grid)
    yield grid
    grid = rotate_grid_cw(grid)
    yield grid
    grid = rotate_grid_cw(grid)
    yield grid
    grid = rotate_grid_cw(grid)
    flip_grid_y(grid)
    print("fy", end=" ")
    flip_grid_x(grid)
    print("fx", end=" ")
    grid = rotate_grid_cw(grid)
    grid = rotate_grid_cw(grid)
    yield grid


class Tile:
    lookup = {}

    def __init__(self, data: str):
        self.data = data.strip()
        self.id = int(self.data.split("\n")[0].strip("Tile :"))

        self.grid: List[List[str]] = []
        rows = self.data.split("\n")[1:]
        for row in rows:
            self.grid.append([c for c in row])

        self.links = []
        self.lookup[self.id] = self

    @property
    def grid_str(self) -> str:
        s = ""
        for row in self.grid:
            s = s + "".join(row)
            s = s + "\n"
        if s.endswith("\n"):
            s = s[:-1]
        return s

    @property
    def edges(self) -> List[str]:

        # edge direction
        # tp -->   007  114
        # rt |     007  117
        #    V     004  117
        # bt <--
        # lf ^
        #    |
        # This means that the edges will not change if the tile is rotated.
        return ["".join(e) for e in [
            self.grid[0],                                   # tp
            list(reversed(self.grid[-1])),                  # bt
            list(reversed([row[0] for row in self.grid])),  # lf
            [row[-1] for row in self.grid],                 # rt
        ]]

    @property
    def edgesf(self) -> List[str]:
        all_edges = copy(self.edges)
        for e in self.edges:
            all_edges.append(reverse(e))
        return all_edges

    @property
    def right(self):
        """Return link to the right."""
        for id_ in self.links:
            other = self.lookup[id_]
            if self.edges[3] == reverse(other.edges[2]):
                return other

    @property
    def left(self):
        """Return link to the right."""
        for id_ in self.links:
            other = self.lookup[id_]
            if self.edges[2] == reverse(other.edges[3]):
                return other

    @property
    def up(self):
        """Return link to the right."""
        for id_ in self.links:
            other = self.lookup[id_]
            if self.edges[0] == reverse(other.edges[1]):
                return other

    @property
    def down(self):
        """Return link to the right."""
        for id_ in self.links:
            other = self.lookup[id_]
            if self.edges[1] == reverse(other.edges[0]):
                return other

    def rotate_cw(self):
        rows = deepcopy(self.grid)
        rows.reverse()
        new_rows = []
        for i in range(len(rows)):
            new_rows.append([row[i] for row in rows])
        self.grid = new_rows

    def flip_x(self):
        for row in self.grid:
            row.reverse()

    def flip_y(self):
        self.grid.reverse()

    def flip_aligned(self, other: "Tile"):
        return len(set(self.edges).intersection([reverse(e) for e in other.edges])) == 1

    def aligned(self, other: "Tile") -> bool:
        return (
            self.edges[0] == reverse(other.edges[1]) or
            self.edges[1] == reverse(other.edges[0]) or
            self.edges[2] == reverse(other.edges[3]) or
            self.edges[3] == reverse(other.edges[2])
        )

    def align_to(self, other: "Tile"):
        for funcs in (
                (self.flip_x, ),
                (self.flip_y, ),
                (self.flip_x, self.flip_y),
        ):
            if self.flip_aligned(other):
                break
            for f in funcs:
                f()
        assert self.flip_aligned(other)
        for _ in range(3):
            if self.aligned(other):
                return
            self.rotate_cw()
        assert self.aligned(other)


def part1(data: str) -> int:
    tiles = [Tile(x) for x in data.strip().split("\n\n")]
    all_edges = []
    for t in tiles:
        all_edges.extend(t.edgesf)
    for t in tiles:
        t.shared_edges = 0
        for edge in t.edgesf:
            if all_edges.count(edge) > 1:
                t.shared_edges += 1

    # Because of flipping, shared edges is 4 instead of 2
    corners = [t.id for t in tiles if t.shared_edges == 4]
    assert len(corners) == 4

    return reduce(mul, corners)


# -- part 2


def test_flip_x():
    data = """Tile: 000
123
456
789"""

    expected_grid = """321
654
987"""
    t = Tile(data)
    t.flip_x()
    assert t.grid_str == expected_grid


def test_flip_y():
    data = """Tile: 000
123
456
789"""

    expected_grid = """789
456
123"""
    t = Tile(data)
    t.flip_y()
    assert t.grid_str == expected_grid


def test_rotate_cw1():
    t = Tile("""Tile: 000
007
007
004""")
    t.rotate_cw()
    assert t.grid_str == """000
000
477"""


def test_rotate_cw2():
    t = Tile("""Tile: 000
123
456
789""")
    t.rotate_cw()
    assert t.grid_str == """741
852
963"""


def test_align():
    t = Tile("""Tile: 000
123
456
789""")

    t2 = Tile("""Tile: 111
111
111
321""")

    t.align_to(t2)

    assert t.grid_str == """321
654
987"""


def test_align2():
    t = Tile("""Tile: 000
007
007
004""")
    t2 = Tile("""Tile: 111
114
117
117""")

    t.align_to(t2)

    assert t.grid_str == """400
700
700"""


SEA_MONSTER = """                  # 
#    ##    ##    ###
 #  #  #  #  #  #   """


def monster_count(grid: List[List[str]]) -> (int, int):
    rows = SEA_MONSTER.split("\n")
    sm_grid = []
    for row in rows:
        sm_grid.append([x for x in row])
    sm_coord = []
    for y, row in enumerate(sm_grid):
        for x, c in enumerate(row):
            if c == "#":
                sm_coord.append((x, y))

    grid_w = len(grid[0])
    grid_h = len(grid)
    sm_w = len(sm_grid[0])
    sm_h = len(sm_grid)

    count = 0
    for x in range(grid_w - sm_w + 1):
        for y in range(grid_h - sm_h + 1):
            # print(f"checking {x}, {y}")
            for sm_x, sm_y in sm_coord:
                if grid[y + sm_y][x + sm_x] != "#":
                    break
            else:
                count += 1

    total_roughness = 0
    for row in grid:
        for c in row:
            if c == "#":
                total_roughness += 1

    monster_roughness = SEA_MONSTER.count("#")
    roughness = total_roughness - (monster_roughness * count)
    return count, roughness


def part2(data: str) -> int:
    tiles = [Tile(x) for x in data.strip().split("\n\n")]

    all_edges = []
    for t in tiles:
        all_edges.extend(t.edgesf)
    for t in tiles:
        t.shared_edges = 0
        for edge in t.edgesf:
            if all_edges.count(edge) > 1:
                t.shared_edges += 1

    # Because of flipping, shared edges is double the actual number, since the
    # flipped version of each matching edge also counts
    corner_tiles = [t for t in tiles if t.shared_edges == 4]
    edge_tiles = [t for t in tiles if t.shared_edges == 6]
    middle_tiles = [t for t in tiles if t.shared_edges == 8]

    print("   all tiles:", len(tiles))
    print("corner tiles:", len(corner_tiles))
    print("  edge tiles:", len(edge_tiles))
    print("middle tiles:", len(middle_tiles))
    assert len(corner_tiles) + len(edge_tiles) + len(middle_tiles) == len(tiles)
    square_root = int(len(tiles) ** 0.5)
    assert len(corner_tiles) == 4
    assert len(edge_tiles) == (square_root - 2) * 4
    assert len(middle_tiles) == (square_root - 2) ** 2

    for t in tiles:
        for other in tiles:
            if t is other:
                continue
            if len(set(t.edgesf).intersection(other.edgesf)) == 2:
                t.links.append(other.id)

    for t in tiles:
        assert 2 <= len(t.links) <= 4
    for t in corner_tiles:
        assert len(t.links) == 2
    for t in edge_tiles:
        assert len(t.links) == 3
    for t in middle_tiles:
        assert len(t.links) == 4

    first = corner_tiles[0]

    seen = set()

    def r(input_id):
        if input_id in seen:
            return
        seen.add(input_id)
        for id_ in Tile.lookup[input_id].links:
            Tile.lookup[id_].align_to(Tile.lookup[input_id])
            r(id_)
    r(first.id)

    print(len(seen))
    print(len(tiles))
    assert len(seen) == len(tiles)

    upper_left = None
    for t in tiles:
        if (
            t.down and
            t.right and
            t.up is None and
            t.left is None
        ):
            upper_left = t
            break
    print(f"upper left: {upper_left.id}")

    # combine image tiles into grid
    first = None
    tiles = []
    for y in range(square_root):
        row = []
        if first is None:
            first = upper_left
        else:
            first = first.down
        current = first

        for x in range(square_root):
            row.append(current)
            current = current.right
        tiles.append(row)
    print([
        [t.id for t in r]
        for r in tiles
    ])

    # get final image from tile grid
    grid = []
    for tile_row in tiles:
        combined_row = []
        for x in range(len(tile_row[0].grid[1:-1])):
            combined_row.append([])
        for t in tile_row:
            for i, row in enumerate(t.grid[1:-1]):
                combined_row[i].extend(row[1:-1])
        grid.extend(combined_row)

    # print grid for debugging
    s = ""
    for row in grid:
        s = s + "".join(row)
        s = s + "\n"
    if s.endswith("\n"):
        s = s[:-1]
    print(s)

    # look for sea monsters
    counts = {}

    seen = []

    for g in all_alignments(grid):
        count, roughness = monster_count(g)
        counts[count] = roughness
        for s in seen:
            if g == s:
                print("- seen -", end=" ")
                break
        else:
            seen.append(deepcopy(g))
    print(len(seen))
    return counts[max(counts.keys())]


def main():
    input_file = Path(__file__).parent / "input"
    data = input_file.read_text()

    # print(part1(data))  # 54755174472007
    print(part2(data))


if __name__ == "__main__":
    main()
