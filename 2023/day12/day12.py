from copy import copy
import enum
import dataclasses
import typing
from pathlib import Path
import itertools


def split_and_strip(data: str, sep: str) -> list[str]:
    parts = data.strip().split(sep)
    return [p.strip() for p in parts]


INPUT = (Path(__file__).absolute().parent / "input").read_text().strip()


DATA = """\
???.### 1,1,3
.??..??...?##. 1,1,3
?#?#?#?#?#?#?#? 1,3,1,6
????.#...#... 4,1,1
????.######..#####. 1,6,5
?###???????? 3,2,1\
"""
NO_UNKNOWNS = """\
#.#.### 1,1,3
.#...#....###. 1,1,3
.#.###.#.###### 1,3,1,6
####.#...#... 4,1,1
#....######..#####. 1,6,5
.###.##....# 3,2,1\
"""


class Status(enum.Enum):
    BR = "#"
    OP = "."
    UN = "?"


@dataclasses.dataclass
class Record:
    statuses: list[Status]
    groups: list[int]

    def line(self):
        vs = "".join([s.value for s in self.statuses])
        gs = ",".join([str(i) for i in self.groups])
        return f"{vs} {gs}"

    # def permutations(self) -> typing.Generator["Record", None, None]:
    #     for i, s in enumerate(self.statuses):
    #          for b in (True, False):


def parse(line: str) -> Record:
    a, b = line.split(" ", 1)
    statuses = [Status(char) for char in a]
    groups = [int(x) for x in b.split(",")]
    return Record(statuses, groups)


def conditions_match_groups(record: Record) -> bool:
    group_stack = list(reversed(record.groups))
    group = group_stack.pop()
    last = Status.OP
    current_br = 0
    for s in record.statuses:
        if s == Status.BR:
            current_br += 1
            # if current_br > group:
            #     # print(f"{current_br}>{group}")
            #     return False
        if last == Status.BR and s != Status.BR:
            if current_br != group:
                # print(f"{current_br}!={group}")
                return False
            try:
                group = group_stack.pop()
            except IndexError:
                group = 0
            current_br = 0
        if s == Status.UN:
            raise ValueError("No UNKNOWN statuses allowed")
        last = s
    return current_br == group and len(group_stack) == 0


def part1(data):
    records = [parse(line) for line in split_and_strip(data, "\n")]
    # for record in records:
    #     print(conditions_match_groups(record))

    def t(line: str, expected: bool):
        actual = conditions_match_groups(parse(line))
        if actual != expected:
            print(f"F got {actual}, expected {expected}")
            print(f"  {line}")
        else:
            print("P")

    # t("#.#.### 1,1,3", True)
    # t("#...#....###. 1,1,3", True)
    # t("#.###.#.###### 1,3,1,6", True)
    # t("####.#...#... 4,1,1", True)
    # t("#....######..#####. 1,6,5", True)
    # t(".###.##....# 3,2,1", True)
    # t(".#####....# 3,2,1", False)
    # t(".###.##....#.# 3,2,1", False)
    # t("###.###.#.... 3,3,1", True)
    # t("# 1", True)
    # t("## 1", False)
    # t(". 0", True)
    # t("..#...#....##. 1,1,3", False)
    # t(".###......## 3,2,1", False)

    # line = "??"
    #
    # def permutations(line: str):
    #     qs = []
    #     for i, ch in enumerate(line):
    #         if ch == "?":
    #             qs.append(i)
    #     for p in itertools.product(".#", repeat=len(qs)):
    #         line = [x for x in line]
    #         for v, i in zip(p, qs):
    #             line[i] = v
    #         yield "".join(line)

    # for p in permutations("??.#?"):
    #     print(p)

    # def permutations(record: Record):
    #     qs = []
    #     for i, s in enumerate(record.statuses):
    #         if s == Status.UN:
    #             qs.append(i)
    #     for p in itertools.product([Status.OP, Status.BR], repeat=len(qs)):
    #         new_statuses = copy(record.statuses)
    #         for v, i in zip(p, qs):
    #             new_statuses[i] = v
    #         yield Record(new_statuses, record.groups, record.line)
    #
    # for p in permutations(parse("??.#? 1,2")):
    #     print("".join([s.value for s in p.statuses]))

    def arrangements(record: Record):
        arrs = 0
        qs = []
        for i, s in enumerate(record.statuses):
            if s == Status.UN:
                qs.append(i)
        for p in itertools.product([Status.OP, Status.BR], repeat=len(qs)):
            new_statuses = copy(record.statuses)
            for v, i in zip(p, qs):
                new_statuses[i] = v
            r = Record(new_statuses, record.groups)
            cmg = conditions_match_groups(r)
            if cmg:
                # print(" ", r.line(), cmg)
                arrs += 1
        return arrs

    total = 0
    for r in records:
        arrs = arrangements(r)
        total += arrs
        # print(r.line(), ":", arrs)
    print("Total:", total)


class Part2:
    def __init__(self, data):
        self.data = data

    @staticmethod
    def t(line: str, expected: bool):
        actual = conditions_match_groups(parse(line))
        if actual != expected:
            print(f"F got {actual}, expected {expected}")
            print(f"  {line}")
        else:
            print("P")

    @staticmethod
    def parse(line):
        a, b = line.split(" ", 1)
        a = "?".join([a]*5)
        statuses = [char for char in a]
        b = ",".join([b]*5)
        groups = [int(x) for x in b.split(",")]
        return statuses, groups

    def solve(self, line):
        statuses, grps = self.parse(line)
        return self.r_solve(statuses, grps, 0)

    @staticmethod
    def _take_next_grp(statuses: list[str]) -> tuple[int, list[str]]:
        qs = 0
        for i, ch in enumerate(statuses):
            if ch == "?":
                qs += 1
            else:
                if qs:
                    return qs, statuses[i+1:]
        else:
            return 0, statuses

    def r_solve(self, statuses: list[str], grps: list[int], damaged: int):
        # take first ? group
        ss = ""
        while True:
            ss, *statuses = statuses
            if ss == "?":
                break
            if not statuses:
                # done
                if not grps:
                    return 1
                else:
                    return 0

        if not grps:
            return 0

        # solve rest with both '.' and '#'
        a_statuses = ["."] + statuses
        b_statuses = ["#"] + statuses
        a_damaged = 0
        b_damaged = damaged + 1
        a_arrs = self.r_solve(statuses, grps, a_damaged)

        # split group possibilities
        if b_damaged >= grps[0]:
            ...

        # add solutions together
        ...

    def r_solve_multi(self, statuses: list[str], possible_grps: list[list[int]]):
        total = 0
        for grps in possible_grps:
            total += self.r_solve(statuses, grps)
        return total

    def __call__(self, *args, **kwargs):
        print("part2")
        line = ".# 1"
        statuses, groups = parse(line)
        assert statuses == [ch for ch in ".#?.#?.#?.#?.#"]
        assert groups == [1, 1, 1, 1, 1]

        statuses = "?###????????"


def part2(data):
    Part2(data)()


# part1(NO_UNKNOWNS)
# part1(DATA)
# part1(INPUT)
# part2(DATA)
# part2(INPUT)
