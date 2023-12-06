import sys
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path


def read_input():
    input_file = Path(__file__).absolute().parent / "input"
    data = input_file.read_text().strip()
    return data


INPUT = read_input()


DATA = """\
seeds: 79 14 55 13

seed-to-soil map:
50 98 2
52 50 48

soil-to-fertilizer map:
0 15 37
37 52 2
39 0 15

fertilizer-to-water map:
49 53 8
0 11 42
42 0 7
57 7 4

water-to-light map:
88 18 7
18 25 70

light-to-temperature map:
45 77 23
81 45 19
68 64 13

temperature-to-humidity map:
0 69 1
1 0 69

humidity-to-location map:
60 56 37
56 93 4\
"""


@dataclass
class Range:
    dst_start: int
    src_start: int
    range_len: int


class Map:
    def __init__(self, section: str) -> None:
        lines = section.strip().split("\n")
        title, *ranges = lines
        self.src, self.dst = title.strip().split(" map")[0].split("-to-")
        # print(self.src, "->", self.dst)

        self.ranges: list[Range] = []
        for line in ranges:
            as_nums = [int(x) for x in line.strip().split(" ")]
            ds, ss, rl = as_nums
            self.ranges.append(
                Range(dst_start=ds, src_start=ss, range_len=rl)
            )
        # for r in self.ranges:
        #     print("  ", r)

    def __str__(self):
        s = f"{self.src} -> {self.dst}"
        for r in self.ranges:
            s += "\n  "
            s += str(r)
        return s

    def __call__(self, value: int) -> int:
        for r in self.ranges:
            if value >= r.src_start and value < r.src_start + r.range_len:
                return r.dst_start + (value - r.src_start)
        return value


def part1(data):
    lowest_location = sys.maxsize

    sections = data.strip().split("\n\n")
    seeds = [int(x) for x in sections[0].strip().split(": ")[-1].split(" ")]
    print(seeds)

    maps = [Map(m) for m in sections[1:]]

    for seed in seeds:
        x = seed
        # s = f"seed: {seed}"
        for m in maps:
            x = m(x)
            # s += f" -> {x}"
        # print(s)
        lowest_location = min(lowest_location, x)

    # 35
    print("Lowest location:", lowest_location)


DATA2 = DATA


g_maps: list[Map] = []


@lru_cache()
def g_f(seed: int) -> int:
    x = seed
    for m in g_maps:
        x = m(x)
    return x


def part2_1(data):
    lowest_location = sys.maxsize

    sections = data.strip().split("\n\n")
    seeds = [int(x) for x in sections[0].strip().split(": ")[-1].split(" ")]
    print(seeds)

    global g_maps
    g_maps = [Map(m) for m in sections[1:]]

    i = 0
    while True:
        start = seeds[i]
        i += 1
        length = seeds[i]
        i += 1
        print(start, length)

        count = 0
        for seed in range(start, start+length):
            count += 1
            if count > 100000:
                print(".", end="", flush=True)
                count = 0
            x = g_f(seed)
            lowest_location = min(lowest_location, x)

        if i >= len(seeds):
            break

    # 46
    print("Lowest location:", lowest_location)


def input_range(maps: list[Map]):
    lo = sys.maxsize
    hi = 0
    for m in maps:
        for r in m.ranges:
            lo = min(r.src_start, lo)
            hi = max(r.src_start+r.range_len, hi)
    return lo, hi


def output_range(maps: list[Map]):
    lo = sys.maxsize
    hi = 0
    for m in maps:
        for r in m.ranges:
            lo = min(r.dst_start, lo)
            hi = max(r.dst_start+r.range_len, hi)
    return lo, hi


def part2_2(data):
    # lowest_location = sys.maxsize

    sections = data.strip().split("\n\n")
    seeds = [int(x) for x in sections[0].strip().split(": ")[-1].split(" ")]
    print(seeds)

    global g_maps
    g_maps = [Map(m) for m in sections[1:]]

    # print(output_range(maps))
    # print(input_range(maps))

    hum_map = g_maps[-2]
    # 69-70 -> 0-1
    #  0-69 -> 1-70
    #  71.. -> 71..

    loc_map = g_maps[-1]
    # ..56  -> ..56
    # 56-93 -> 60-97
    # 93-97 -> 56-60
    # 98..  -> 98..

    x3_min = sys.maxsize
    x3_max = 0
    offsets = set()
    range_lookup = {}
    for x1 in range(1000):
        x2 = hum_map(x1)
        x3 = loc_map(x2)
        x3_min = min(x3_min, x3)
        x3_max = max(x3_max, x3)
        # if x1 == x2 == x3:
        #     pass
        # else:
        #     print(x1, x2, x3)
        offset = x3 - x1
        offsets.add(offset)
        rs = range_lookup.get(offset, None)
        if rs is None:
            rs = [(x1, x1)]
            range_lookup[offset] = rs
        else:
            for i, r in enumerate(rs):
                start, stop = r
                if x1 == stop+1:
                    rs[i] = (start, x1)
            range_lookup[offset] = rs

    print(x3_min, x3_max)
    print(offsets)
    # print(range_lookup)
    for k, v in range_lookup.items():
        print(k, v)

    # # 46
    # print("Lowest location:", lowest_location)


maps: list[Map] = list()


def pairs(seeds: list[int]):
    i = 0
    while True:
        yield seeds[i], seeds[i+1]
        i += 2
        if i >= len(seeds):
            break


def f(seed: int) -> int:
    x = seed
    for m in maps:
        x = m(x)
    return x


class R:
    def __init__(self, lo, hi):
        self.lo = lo
        self.hi = hi

    def continuous(self) -> bool:
        if self.lo == self.hi:
            return True
        diff = self.hi - self.lo
        return f(self.hi) - f(self.lo) == diff

    def __str__(self):
        return f"({self.lo}, {self.hi})"


def break_r(r: R) -> tuple[R, R]:
    if r.hi == r.lo+1:
        return R(r.lo, r.lo), R(r.hi, r.hi)
    diff = r.hi - r.lo
    mid = r.hi - (diff // 2)
    return R(r.lo, mid), R(mid+1, r.hi)


def break_all(r: R) -> list[R]:
    if r.continuous():
        return [r]
    else:
        r1, r2 = break_r(r)
        print(f"broke {r} -> {r1}, {r2}")
        return break_all(r1) + break_all(r2)


def break_ranges(data):
    sections = data.strip().split("\n\n")
    seeds = [int(x) for x in sections[0].strip().split(": ")[-1].split(" ")]
    global maps
    maps = [Map(m) for m in sections[1:]]
    for start, len_ in pairs(seeds):
        print(start, len_)
        for i in range(start, start+len_):
            print(i, "", end="")
        print("")
        lo = start
        hi = start+len_-1
        ranges = break_all(R(lo, hi))
        print([str(r) for r in ranges])
        for r in ranges:
            print(r)
            for x in range(r.lo, r.hi+1):
                print("  ", x, "->", f(x))
        print("\n")


break_ranges(DATA2)


# part1(DATA)
# part1(INPUT)
# part2_2(DATA2)
# part2_2(INPUT)


