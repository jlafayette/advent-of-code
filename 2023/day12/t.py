import collections
import logging
import sys
from copy import copy
import enum
import dataclasses
import typing
from typing import Union, Literal, Optional
import queue
from pathlib import Path
import itertools


logging.basicConfig(level=logging.INFO, format="{message}", style='{')
logger = logging.getLogger()


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


class Q:
    def __init__(self):
        self.q = queue.SimpleQueue()

    def put(self, item):
        self.q.put_nowait(item)

    def get(self):
        try:
            item = self.q.get_nowait()
            ok = True
        except (IndexError, queue.Empty):
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


BR: Literal["#"] = "#"
OP: Literal["."] = "."
UN: Literal["?"] = "?"
Status = Literal["#", ".", "?"]
Item = tuple[int, Status]
Grp = int


class Row:
    grps: list[Grp]
    max_grp: int
    debug_place = -1

    def __init__(self, items: list[Item]):
        self.items = self.glue(items)

    @staticmethod
    def glue(items: list[Item]):
        new = []
        acc_n, acc_ch = 0, OP
        for (n, ch) in items:
            if ch != acc_ch:
                if acc_n:
                    new.append((acc_n, acc_ch))
                    acc_n = n
                else:
                    acc_n += n
                acc_ch = ch
            else:
                acc_n += n
        if acc_n:
            new.append((acc_n, acc_ch))
        return new

    def max_br(self) -> int:
        return max([n for (n, ch) in self.items if ch == BR])

    def enumerate(self):
        for i, (n, ch) in enumerate(self.items):
            try:
                prev_n, prev_ch = self.items[i-1]
            except IndexError:
                prev_n, prev_ch = (1, OP)
            try:
                next_n, next_ch = self.items[i+1]
            except IndexError:
                next_n, next_ch = (1, OP)
            yield (prev_n, prev_ch), (n, ch), (next_n, next_ch)

    def fully_resolved(self) -> bool:
        for (n, ch) in self.items:
            if ch == UN:
                return False
        return True

    def is_valid(self) -> bool:
        group_stack = Stack(reversed(self.grps))
        for (n, ch) in self.items:
            if ch == "#":
                group, ok = group_stack.pop()
                if not ok or group != n:
                    return False
            if ch == "?":
                raise ValueError("No UNKNOWN statuses allowed")

        return len(group_stack) == 0

    def _largest_possible_br(self):
        # combine '#' with '?'
        largest = 0
        current_run = 0
        for (prev_n, prev_ch), (n, ch), (next_n, next_ch) in self.enumerate():
            possible = ch == BR or ch == UN
            if possible:
                current_run += n
            next_possible = next_ch == BR or next_ch == UN
            if not next_possible and possible:
                largest = max(current_run, largest)
                current_run = 0
        return largest

    def _slot_check(self):
        # '.#? 3' will not work (not enough 3 slots)
        # '.##?.##?.##?.##?.## 3,3,3,3,3'
        ...
        # lower index (groups that must have been slotted)
        lo_i = 0
        # upper index (groups that could be slotted so far)
        hi_i = 0
        ok = True
        combinables: list[Item] = []
        for (prev_n, prev_ch), (n, ch), (next_n, next_ch) in self.enumerate():
            combinable = ch == BR or ch == UN
            if combinable:
                combinables.append((n, ch))
            next_combinable = next_ch == BR or next_ch == UN
            if not next_combinable and combinables:
                # deal with combinables
                # '##?'
                # go through tokens, moving lo and hi indexes
                lo_i, hi_i = self._stuff(lo_i, hi_i, combinables)
                combinables = []
        if hi_i < len(self.grps):
            # print("failed slot check")
            # print("  hi_i < len(self.grps)")
            # print(f"  {hi_i} < {len(self.grps)}")
            ok = False
        # can we say anything about lo_i? larger than grps?
        if lo_i > len(self.grps):
            # print("failed slot check")
            # print("  lo_i > len(self.grps)")
            # print(f"  {lo_i} > {len(self.grps)}")
            ok = False
        return ok

    def _check_lo_hi(self, i, acc, t="hi"):
        inc = False
        try:
            if self.grps[i] == acc:
                i += 1
                acc = 0
                inc = True
                # print(f"  {t} {i-1}({self.grps[i-1]})->{i}({self.grps[i]})")
        except IndexError:
            pass

        return i, acc, inc

    @staticmethod
    def _next_br_chunk_of_size(size: int, combinables: list[Item]) -> Optional[int]:
        for (n, ch) in combinables:
            if ch == BR and n == size:
                return n
        return None

    @staticmethod
    def _next_br_chunk(combinables: list[Item]) -> Optional[int]:
        for (n, ch) in combinables:
            if ch == BR:
                return n
        return None

    def get_grp(self, i: int) -> Optional[int]:
        try:
            return self.grps[i]
        except IndexError:
            return None

    def _stuff(self, lo_i: int, hi_i: int, combinables: list[Item]) -> tuple[int, int]:
        # print(f"_stuff {lo_i}, {hi_i}, {combinables}")
        # '##?'
        # go through tokens, moving lo and hi indexes
        lo_acc = 0
        hi_acc = 0

        hi_pass = False  # hi needs to take a break and insert '.'
        for combinables_i, (n, ch) in enumerate(combinables):
            remaining_combinables = combinables[combinables_i+1:]
            # print((n, ch))
            if ch == BR:
                lo_acc += n
                lo_i, lo_acc, inc = self._check_lo_hi(lo_i, lo_acc, t="lo")

                # if hi_pass:
                #     print("not working right... oh well", (n, ch), combinables)
                hi_acc += n
                hi_i, hi_acc, inc = self._check_lo_hi(hi_i, hi_acc, t="hi")
                if inc:
                    hi_pass = True
                else:
                    # ok to go back to lo_i, try each one until one fits, then call that good
                    end = hi_i
                    hi_i = lo_i
                    hi_acc = lo_acc
                    for i in range(lo_i, end):
                        # print(f"    t {i}({self.get_grp(i)})")
                        hi_i, hi_acc, inc = self._check_lo_hi(i, hi_acc, t="hi")
                        if inc:
                            hi_pass = True
                            break
            elif ch == UN:
                next_br_hi_chunk_n = self._next_br_chunk_of_size(self.get_grp(hi_i), remaining_combinables)
                next_br_chunk_n = self._next_br_chunk(remaining_combinables)
                lo_pass = False
                for i in range(n):
                    last_iter = i == n-1
                    # handle lo acc if it won't fit
                    if last_iter:
                        ...
                    elif next_br_chunk_n != self.get_grp(lo_i):
                        # print(f" next br chunk ({next_br_chunk_n}) != current low grp ({self.get_grp(lo_i)})")
                        if lo_pass:
                            lo_pass = False
                        else:
                            lo_acc += 1
                            lo_i, lo_acc, inc = self._check_lo_hi(lo_i, lo_acc, t="lo")
                            if inc:
                                lo_pass = True

                    # hande hi acc one by one, slotting them in
                    if hi_pass:
                        hi_pass = False
                    else:
                        if last_iter and next_br_hi_chunk_n:
                            ...
                        else:
                            hi_acc += 1
                            hi_i, hi_acc, inc = self._check_lo_hi(hi_i, hi_acc, t="hi")
                            if inc:
                                hi_pass = True

        return lo_i, hi_i

    def _locked_in_check(self) -> bool:
        group_stack = Stack(reversed(self.grps))
        for (_, (n, ch), (next_n, next_ch)) in self.enumerate():
            if ch == BR:
                group, ok = group_stack.pop()
                if not ok or group != n:
                    if next_ch == UN:
                        return True
                    return False
            if ch == UN:
                return True
        return True

    def might_work(self) -> bool:
        # '.##. 1' will never work
        max_br = self.max_br()
        if max_br > self.max_grp:
            logger.debug("failed 'if max_br > self.max_grp:'")
            return False
        # '.#?.' 1' might work
        # '.#?.' 2' might work

        # '.#?.' 3' will never work
        if self.max_grp > self._largest_possible_br():
            logger.debug("failed 'if self.max_grp > self._largest_possible_br():'")
            logger.debug(f"failed 'if {self.max_grp} > {self._largest_possible_br()}:'")
            return False

        # this won't work because there are more '#' chunks than grps
        # .#.#?.#.#?.#.#?.#.#?.#.# 1,1,1,1,1
        br_count = sum([n for (n, ch) in self.items if ch == BR])
        grp_count = sum(self.grps)
        if br_count > grp_count:
            logger.debug("failed because there are more '#' than total of groups")
            logger.debug(f"failed 'if {br_count} > {grp_count}:'")
            return False

        ok = self._locked_in_check()
        if not ok:
            logger.debug("failed lock-in check")
            logger.debug("  %s" % str(self))
            return False

        # '.#? 3' will not work (not enough 3 slots)
        # '.##?.##?.##?.##?.## 3,3,3,3,3'
        logger.debug("doing slot check for")
        logger.debug(str(self))
        ok = self._slot_check()
        if not ok:
            logger.debug("failed slot check")
            logger.debug("  %s" % str(self))
            return False

        return True

    def __str__(self):
        items = "".join([ch*n for (n, ch) in self.items])
        grps = ",".join([str(x) for x in self.grps])
        return " ".join([items, grps])


def mutate(row: Row) -> list[Row]:
    a_items: list[Item] = []
    b_items: list[Item] = []

    for i, (n, ch) in enumerate(row.items):
        if ch != UN:
            a_items.append((n, ch))
            b_items.append((n, ch))
            continue
        else:
            # a gets '.'
            a_items.append((1, OP))
            if n-1:
                a_items.append((n-1, ch))

            # b gets '#'
            b_items.append((1, BR))
            if n-1:
                b_items.append((n-1, ch))

            a_items.extend(row.items[i + 1:])
            b_items.extend(row.items[i + 1:])

            if i > Row.debug_place:
                print(str(row))
                Row.debug_place = i
            break

    return [Row(a_items), Row(b_items)]


def parse(line, unfold=True) -> Row:
    print(f"parsing line: {line}")
    a, b = line.split(" ", 1)
    if unfold:
        a = "?".join([a] * 5)
    statuses = [char for char in a]
    # print(f"statuses: {statuses}")

    if unfold:
        b = ",".join([b] * 5)
    groups = [int(x) for x in b.split(",")]
    # print(f"groups: {groups}")

    result = []
    last_ch: Optional[Status] = None
    acc = 0
    for i, ch in enumerate(statuses):
        if ch == last_ch:
            acc += 1
        else:
            if last_ch:
                result.append((acc, last_ch))
            acc = 1
        if ch not in ".#?":
            raise ValueError(f"{ch} is not valid")
        last_ch = typing.cast(Status, ch)
    if last_ch:
        result.append((acc, last_ch))

    Row.grps = groups
    Row.max_grp = max(groups)
    return Row(result)


def solve(line: str):
    row_orig = parse(line)
    result = r_solve(row_orig)
    print(str(row_orig))
    print("  ", result)
    return result


def r_solve(row_orig: Row):
    q = Q()
    swap_q = Q()
    q_index = 0
    q.put((q_index, row_orig))

    total = 0

    loops = 0
    maybe_valid_count = 1
    rejected_count = 0
    while True:
        loops += 1
        if loops > 99999:
            print("ERROR: too many loops")
            break
        if loops % 1000 == 0:
            print(f"loop {loops}")
        q_result, ok = q.get()
        if not ok:
            q_index += 1
            print(f"advanced q index {q_index-1}->{q_index}")
            print(f"  {q.q.qsize()}")
            print(f"  {swap_q.q.qsize()}")
            assert q.q.qsize() == 0
            q, swap_q = swap_q, q
            q_result, ok = q.get()
            if not ok:
                break
        row_q_index, row = q_result
        assert isinstance(row, Row)

        if row.fully_resolved():
            if row.is_valid():
                # print("totally valid row:")
                # print(str(row))
                # print(row.items)
                total += 1
                continue

        # solve rest with both '.' and '#'
        for child in mutate(row):
            if child.might_work():
                swap_q.put((row_q_index+1, child))
                maybe_valid_count += 1
            else:
                # print("rejected")
                # print(str(child))
                rejected_count += 1

    print(f"maybe valid: {maybe_valid_count}")
    print(f"rejected: {rejected_count}")

    return total


def part2(data):
    #     data = """\
    # ???.### 1,1,3
    # .??..??...?##. 1,1,3\
    # """
    # .??..??...?##. 1,1,3
    # ?#?#?#?#?#?#?#? 1,3,1,6
    # ????.#...#... 4,1,1
    # ????.######..#####. 1,6,5
    # ?###???????? 3,2,1

    # print("\n--- might work ---")

    def t(line, expected):
        row = parse(line)
        print(str(row))
        r = row.might_work()
        if r == expected:
            print("P", r)
        else:
            print(f"ERROR: got {r}, expected {expected}")
            print(" ", r)

    # t(".#.# 1", False)
    # t(".#. 1", True)
    # t(".##. 1", False)
    # t(".##?. 3", True)
    # t(".#?. 3", False)
    # t(".## 3", False)

    # the all ok (examples)
    # t("???.### 1,1,3", True)
    # t(".??..??...?##. 1,1,3", True)
    # t("?#?#?#?#?#?#?#? 1,3,1,6", True)  # needs work
    # t("????.#...#... 4,1,1", True)
    # t("????.######..#####. 1,6,5", True)
    # t("?###???????? 3,2,1", True)

    # is_valid
    # line = "##..#####...####.#..####.#..#####...### 1,1,3,1,1,3,1,1,3,1,1,3,1,1,3"
    # line = "..#...#...###.#..#...#...###.#..#...#...###.#..#...#...###.?.??..??...?##. 1,1,3,1,1,3,1,1,3,1,1,3,1,1,3"
    # line = "#???.#...#...?????.#...#...?????.#...#...?????.#...#...?????.#...#... 4,1,1,4,1,1,4,1,1,4,1,1,4,1,1"
    # row = parse(line, unfold=False)
    # print(row.might_work())

    # the all ok (examples)
    # assert 1 == solve("???.### 1,1,3")
    # assert 16384 == solve(".??..??...?##. 1,1,3")
    _ = solve("?#?#?#?#?#?#?#? 1,3,1,6")  # working on this
    # assert 16 == solve("????.#...#... 4,1,1")
    # assert 2500 == solve("????.######..#####. 1,6,5")
    # _ = solve("?###???????? 3,2,1")


part2(DATA)
# part2(INPUT)
