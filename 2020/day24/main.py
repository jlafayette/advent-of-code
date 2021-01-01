"""Day 24: Lobby Layout

https://adventofcode.com/2020/day/24

"""
from collections import deque
from dataclasses import dataclass
from pathlib import Path


# -- part 1


@dataclass
class Coord:
    x: int
    y: int
    z: int

    def adjacent(self):
        return (
            Coord(self.x + 1, self.y - 1, self.z + 0),
            Coord(self.x + 1, self.y + 0, self.z - 1),
            Coord(self.x + 0, self.y + 1, self.z - 1),
            Coord(self.x - 1, self.y + 1, self.z + 0),
            Coord(self.x - 1, self.y + 0, self.z + 1),
            Coord(self.x + 0, self.y - 1, self.z + 1),
        )

    def __add__(self, other):
        if isinstance(other, Coord):
            return Coord(self.x + other.x, self.y + other.y, self.z + other.z)
        else:
            raise TypeError(f'can only add Coord (not "{type(other)}") to Coord')

    def __radd__(self, other):
        return self.__add__(other)

    def __hash__(self):
        return hash((self.x, self.y, self.z))


@dataclass
class TileState:
    def __init__(self, flipped=True):
        self.flipped = flipped

    def flip(self):
        self.flipped = not self.flipped


def parse_flip_instruction(instruction: str) -> Coord:
    d = deque(instruction)
    coord = Coord(0, 0, 0)
    #         (n)
    #          .
    #      x.     .z
    # (e)            (w)
    #       .     .
    #          .
    #          y
    #         (s)

    dir_to_coord = {
        "w": Coord(1, -1, 0),
        "nw": Coord(1, 0, -1),
        "ne": Coord(0, 1, -1),
        "e": Coord(-1, 1, 0),
        "se": Coord(-1, 0, 1),
        "sw": Coord(0, -1, 1),
    }

    while d:
        i = ""
        i += d.popleft()
        if i == "s" or i == "n":
            i += d.popleft()
        coord = coord + dir_to_coord[i]

    return coord


TEST_DATA = """sesenwnenenewseeswwswswwnenewsewsw
neeenesenwnwwswnenewnwwsewnenwseswesw
seswneswswsenwwnwse
nwnwneseeswswnenewneswwnewseswneseene
swweswneswnenwsewnwneneseenw
eesenwseswswnenwswnwnwsewwnwsene
sewnenenenesenwsewnenwwwse
wenwwweseeeweswwwnwwe
wsweesenenewnwwnwsenewsenwwsesesenwne
neeswseenwwswnwswswnw
nenwswwsewswnenenewsenwsenwnesesenew
enewnwewneswsewnwswenweswnenwsenwsw
sweneswneswneneenwnewenewwneswswnese
swwesenesewenwneswnwwneseswwne
enesenwswwswneneswsenwnewswseenwsese
wnwnesenesenenwwnenwsewesewsesesew
nenewswnwewswnenesenwnesewesw
eneswnwswnwsenenwnwnwwseeswneewsenese
neswnwewnwnwseenwseesewsenwsweewe
wseweeenwnesenwwwswnew"""


def test_part1():
    assert part1(TEST_DATA) == 10


def part1(data: str):
    tile_map = {}
    for instruction in data.strip().split("\n"):
        coord = parse_flip_instruction(instruction)
        if coord in tile_map:
            tile_map[coord].flip()
        else:
            tile_map[coord] = TileState()
    flipped = len([t for t in tile_map.values() if t.flipped])
    return flipped


def part2(data: str):
    tile_map = {}
    for instruction in data.strip().split("\n"):
        coord = parse_flip_instruction(instruction)
        if coord in tile_map:
            tile_map[coord].flip()
        else:
            tile_map[coord] = TileState()

    for _ in range(100):
        # expand outward to include any bordering tiles
        new_coords = []
        for coord, flip_state in tile_map.items():
            new_coords.extend(
                [c for c in coord.adjacent() if c not in tile_map]
            )
        for coord in new_coords:
            tile_map[coord] = TileState(flipped=False)

        # calculate which tiles should be flipped
        coordinates_to_flip = []
        for coord, flip_state in tile_map.items():
            black = flip_state.flipped
            white = not flip_state.flipped
            # Any black tile with zero or more than 2 black tiles immediately
            # adjacent to it is flipped to white.
            adjacent = [c for c in coord.adjacent()]
            adjacent_black = len([c for c in adjacent if tile_map.get(c, TileState(flipped=False)).flipped])
            if black and (adjacent_black == 0 or adjacent_black > 2):
                coordinates_to_flip.append(coord)
                continue

            # Any white tile with exactly 2 black tiles immediately adjacent to
            # it is flipped to black.
            if white and adjacent_black == 2:
                coordinates_to_flip.append(coord)
                continue

        # flip all the tiles
        for coord in coordinates_to_flip:
            tile_map[coord].flip()

    flipped = len([t for t in tile_map.values() if t.flipped])
    return flipped


def main():
    input_file = Path(__file__).parent / "input"
    data = input_file.read_text()

    print(part1(data))  # 386
    print(part2(data))  # 4214


if __name__ == "__main__":
    main()
