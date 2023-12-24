import dataclasses
import typing
from pathlib import Path


INPUT = (Path(__file__).absolute().parent / "input").read_text().strip()


DATA = """\
...#......
.......#..
#.........
..........
......#...
.#........
.........#
..........
.......#..
#...#.....\
"""


def split_and_strip(data: str, sep: str) -> list[str]:
    parts = data.strip().split(sep)
    return [p.strip() for p in parts]


def expand(orig_starmap: str) -> list[str]:
    orig_rows = split_and_strip(orig_starmap, "\n")
    # expand columns
    cols_to_expand: list[int] = []
    for x, _ in enumerate(orig_rows[0]):
        for row in orig_rows:
            v = row[x]
            if v == "#":
                break
        else:
            cols_to_expand.append(x)

    new_rows = []
    for orig_row in orig_rows:
        new_row = ""
        for i, char in enumerate(orig_row):
            if i in cols_to_expand:
                new_row += ".."
            else:
                new_row += char
        new_rows.append(new_row)

    new_new_rows = []
    for row in new_rows:
        if "#" in row:
            new_new_rows.append(row)
        else:
            new_new_rows.extend([row, row])
    return new_new_rows


@dataclasses.dataclass
class Pos:
    x: int
    y: int
    label: str

    def __str__(self):
        return f"g{self.label}({self.x},{self.y})"

    def distance(self, p2: "Pos") -> int:
        x1 = self.x
        y1 = self.y
        x2 = p2.x
        y2 = p2.y
        return abs(y2 - y1) + abs(x2 - x1)


def number_gen() -> typing.Generator[int, None, None]:
    n = 1
    while True:
        yield n
        n += 1


def extract_galaxies(starmap: list[str]) -> list[Pos]:
    result: list[Pos] = list()
    numberer = number_gen()
    for y, row in enumerate(starmap):
        for x, char in enumerate(row):
            if char == "#":
                result.append(Pos(x, y, str(next(numberer))))
    return result


def part1(data):
    # for row in split_and_strip(data, "\n"):
    #     print(row)
    # print()
    starmap = expand(data)
    # for row in starmap:
    #     print(row)
    # print()
    galaxies = extract_galaxies(starmap)
    # starmap2 = [[x for x in row] for row in starmap]
    # for galaxy in galaxies:
    #     starmap2[galaxy.y][galaxy.x] = galaxy.label
    # starmap3 = ["".join(row) for row in starmap2]
    # for row in starmap3:
    #     print(row)

    calculated: set[tuple[int, int, int, int]] = set()
    distances: list[int] = []
    for g1 in galaxies:
        for g2 in galaxies:
            if g1.label == g2.label:
                continue
            if (g1.x, g1.y, g2.x, g2.y) in calculated:
                continue

            distance = g1.distance(g2)
            # print(f"distance from {g1} to {g2} is {distance}")
            distances.append(distance)

            calculated.add((g1.x, g1.y, g2.x, g2.y))
            calculated.add((g2.x, g2.y, g1.x, g1.y))

    print("Sum:", sum(distances))


def part2(data, expansion_factor=1_000_000):
    starmap = split_and_strip(data, "\n")
    galaxies = extract_galaxies(starmap)

    # expand columns
    row_distance: dict[int, int] = {-1: -1}
    for x, _ in enumerate(starmap[0]):
        for row in starmap:
            if row[x] == "#":
                row_distance[x] = row_distance[x-1] + 1
                break
        else:
            row_distance[x] = row_distance[x-1] + expansion_factor
    # expand rows
    col_distance: dict[int, int] = {-1: -1}
    for y, row in enumerate(starmap):
        if "#" in row:
            col_distance[y] = col_distance[y-1] + 1
        else:
            col_distance[y] = col_distance[y-1] + expansion_factor

    for i, g in enumerate(galaxies):
        galaxies[i].x = row_distance[g.x]
        galaxies[i].y = col_distance[g.y]

    calculated: set[tuple[int, int, int, int]] = set()
    distances: list[int] = []
    for g1 in galaxies:
        for g2 in galaxies:
            if g1.label == g2.label:
                continue
            if (g1.x, g1.y, g2.x, g2.y) in calculated:
                continue

            distance = g1.distance(g2)
            # print(f"distance from {g1} to {g2} is {distance}")
            distances.append(distance)

            calculated.add((g1.x, g1.y, g2.x, g2.y))
            calculated.add((g2.x, g2.y, g1.x, g1.y))

    print("Sum:", sum(distances))


part1(DATA)
part1(INPUT)
part2(DATA, expansion_factor=10)
part2(DATA, expansion_factor=100)
part2(INPUT)
