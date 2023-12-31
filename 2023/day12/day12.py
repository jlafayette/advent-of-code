import collections
import sys
from copy import copy
import enum
import dataclasses
import typing
import queue
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


class Q:
    def __init__(self):
        self.q = queue.SimpleQueue()

    def put(self, item):
        self.q.put_nowait(item)

    def get(self):
        try:
            item = self.q.get_nowait()
            ok = True
        except IndexError:
            item = None
            ok = False
        return item, ok

    def empty(self):
        return self.q.empty()


class Stack(collections.UserList):
    def pop(self):
        try:
            return super(Stack, self).pop(), True
        except IndexError:
            return None, False

    def peek(self):
        try:
            return self[-1]
        except IndexError:
            return None


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
        return self.r_solve(statuses, grps)

    @staticmethod
    def is_valid(statuses: list[tuple[int, str]], grps: list[int]) -> bool:
        group_stack = Stack(reversed(grps))
        for (n, ch) in statuses:
            if ch == "#":
                group, ok = group_stack.pop()
                if not ok or group != n:
                    return False
            if ch == "?":
                raise ValueError("No UNKNOWN statuses allowed")

        return len(group_stack) == 0

    def _lazy(self, ss: list[tuple[int, str]], grps: list[int]) -> (int, bool):

        lazy = Stack(reversed(grps))

        for i, (n, ch) in enumerate(ss):
            # print(i, ch)
            # only use '#', count all '?' as '.'
            if ch == "#":
                while True:
                    grp, ok = lazy.pop()
                    # print((n, ch), (grp, ok))
                    if not ok:
                        return 0, False
                    if grp == n:
                        break

        return len(lazy), True

    def _greedy(self, statuses: list[str], grps: list[int]) -> (int, bool):
        greedy = Stack(reversed(grps))

        br = 0
        grp, ok = greedy.pop()
        if not ok:
            return 0, False
        for i, ch in enumerate(statuses):
            # print(i, ch, br)
            # only use '#', count all '?' as either '.' or '#', whichever uses the next group
            if ch == "#":
                br += 1
            elif ch == "?":
                # count '?' as either '.' or '#', whichever uses the next group
                next_token = greedy.peek()
                next_br = next_token == "#"
                # need to get whole chunk of #...

                if br == 0:
                    br += 1  # use as '#'
                else:
                    # use as '.'
                    if br == grp:
                        # on to next grp
                        print("-br", "".join(["#"] * br), grp)
                        grp, ok = greedy.pop()
                        if not ok:
                            print("early exit")
                            return 0, True
                        br = 0
                    else:
                        br += 1
            else:
                if br == grp:
                    # on to next grp
                    print("-br", "".join(["#"] * br), grp)
                    grp, ok = greedy.pop()
                    if not ok:
                        print("early exit")
                        return 0, True
                br = 0

        # copy block
        if br > 0:
            # print("".join(["#"] * br))
            if br == grp:
                # on to next grp
                grp, ok = greedy.pop()
                if not ok:
                    return 0, True
            else:
                return len(greedy) + 1, False

        if grp:
            return 1, False

        return len(greedy), len(greedy) == 0

    def never_going_to_work(self, statuses: list[tuple[int, str]], grps: list[int]) -> bool:
        # if lazy is out of items, fail
        _, ok = self._lazy(statuses, grps)
        # if not ok:
        #     return not ok
        #
        # # if greedy has any items left, fail
        # _, ok = self._greedy(statuses, grps)
        return not ok

    @staticmethod
    def rework_line(statuses: list[str]) -> list[tuple[int, str]]:
        result = []
        last_ch = None
        acc = 0
        for i, ch in enumerate(statuses):
            if ch == last_ch:
                acc += 1
            else:
                if last_ch:
                    result.append((acc, last_ch))
                acc = 1
            last_ch = ch
        result.append((acc, last_ch))
        return result

    @staticmethod
    def fully_resolved(line: list[tuple[int, str]]) -> bool:
        for (n, ch) in line:
            if ch == "?":
                return False
        return True

    def r_solve(self, statuses: list[str], grps: list[int]):
        ss = self.rework_line(statuses)
        del statuses

        q = Q()
        q.put(ss)

        total = 0

        debug_place = 0
        while True:
            ss, ok = q.get()
            if not ok:
                break
            # print("".join(ss))

            if self.fully_resolved(ss):
                if self.is_valid(ss, grps):
                    total += 1
                    continue

            if self.never_going_to_work(ss, grps):
                continue

            a_statuses: list[tuple[int, str]] = []
            b_statuses: list[tuple[int, str]] = []

            prev_ch = ""
            for i, (n, ch) in enumerate(ss):
                if ch != "?":
                    a_statuses.append((n, ch))
                    b_statuses.append((n, ch))
                    prev_ch = ch
                    continue
                else:
                    if prev_ch == ".":
                        a_statuses[-1][0] += 1
                    else:
                        a_statuses.append((1, "."))
                    if prev_ch == "#":
                        b_statuses[-1][0] += 1
                    else:
                        b_statuses.append((1, "#"))
                    a_statuses.extend(ss[i+1:])
                    b_statuses.extend(ss[i+1:])

                    if i > debug_place:
                        print("".join(ss))
                    debug_place = i
                    break
            else:
                continue
            
            # solve rest with both '.' and '#'
            q.put(a_statuses)
            q.put(b_statuses)

        return total

    def __call__(self, *args, **kwargs):
        print("part2")
        line = ".# 1"
        statuses, groups = self.parse(line)
        assert statuses == [ch for ch in ".#?.#?.#?.#?.#"]
        assert groups == [1, 1, 1, 1, 1]

        # def split_and_strip(data: str, sep: str) -> list[str]:
        for line in split_and_strip(self.data, "\n"):
            statuses, groups = self.parse(line)
            r = self.solve(line)
            print(line)
            print("  ", r)


def part2(data):
    data = """\
???.### 1,1,3
.??..??...?##. 1,1,3\
"""
    # .??..??...?##. 1,1,3
    # ?#?#?#?#?#?#?#? 1,3,1,6
    # ????.#...#... 4,1,1
    # ????.######..#####. 1,6,5
    # ?###???????? 3,2,1
    p2 = Part2(data)

    print("\n--- lazy ---")

    def t(line, expected):
        statuses, groups = p2.parse(line)
        print("".join(statuses), ",".join([str(x) for x in groups]))
        ss = p2.rework_line(statuses)
        del statuses
        # print(ss)
        r = p2._lazy(ss, groups)
        if r[1] == expected:
            print("P", r)
        else:
            print(f"ERROR: got, {r[1]}, expected {expected}")
            print(" ", r)

    # t("???.### 1,1,3", True)
    # t(".#.# 1", False)
    # t(".#. 1", True)
    # t(".##. 1", False)

    # the all true (examples)
    t("???.### 1,1,3", True)
    t(".#. 1,1", True)
    t(".??..??...?##. 1,1,3", True)
    # t("?#?#?#?#?#?#?#? 1,3,1,6", True)
    # t("????.#...#... 4,1,1", True)
    # t("????.######..#####. 1,6,5", True)
    # t("?###???????? 3,2,1", True)

    # print("\n--- greedy ---")
    #
    # def g(line):
    #     statuses, groups = p2.parse(line)
    #     print("".join(statuses), ",".join([str(x) for x in groups]))
    #     r = p2._greedy(statuses, groups)
    #     print(len(statuses), r)
    # g("???.### 1,1,3")
    # g(".#. 1,1")
    # g(".??..??...?##. 1,1,3")
    # g("?#?#?#?#?#?#?#? 1,3,1,6")
    # g("????.#...#... 4,1,1")
    # g("????.######..#####. 1,6,5")
    # g("?###???????? 3,2,1")

    # p2()


# part1(NO_UNKNOWNS)
# part1(DATA)
# part1(INPUT)
part2(DATA)
# part2(INPUT)
