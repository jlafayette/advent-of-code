import collections
import logging
import typing
import queue
from collections import Counter
from typing import Literal, Optional
from pathlib import Path


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
SizePossibilities = dict[int, list[tuple[int, int]]]


class Row:
    debug_place = -1

    def __init__(self, items: list[Item], grps: list[int]):
        self.grps = grps
        if grps:
            self.max_grp = max(grps)
        else:
            self.max_grp = 0
        self.items = self.glue(items)

    @staticmethod
    def glue(items: list[Item]):
        new = []
        acc_n, acc_ch = 0, OP
        for (n, ch) in items:
            if ch != acc_ch:
                if acc_n:
                    if acc_ch == UN:
                        for _ in range(acc_n):
                            new.append((1, acc_ch))
                    else:
                        new.append((acc_n, acc_ch))
                    acc_n = n
                else:
                    acc_n += n
                acc_ch = ch
            else:
                acc_n += n
        if acc_n:
            if acc_ch == UN:
                for _ in range(acc_n):
                    new.append((1, acc_ch))
            else:
                new.append((acc_n, acc_ch))
        return new

    def max_br(self) -> int:
        try:
            return max([n for (n, ch) in self.items if ch == BR])
        except ValueError:
            return 0

    def enumerate(self):
        for i, (n, ch) in enumerate(self.items):
            if i == 0:
                prev_n, prev_ch = (1, OP)
            else:
                prev_n, prev_ch = self.items[i-1]
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
            logger.debug("failed slot check")
            logger.debug("  hi_i < len(self.grps)")
            logger.debug(f"  {hi_i} < {len(self.grps)}")
            ok = False
        # can we say anything about lo_i? larger than grps?
        if lo_i > len(self.grps):
            logger.debug("failed slot check")
            logger.debug("  lo_i > len(self.grps)")
            logger.debug(f"  {lo_i} > {len(self.grps)}")
            ok = False
        return ok

    def _check_lo_hi(self, i, acc, t="hi"):
        inc = False
        try:
            if self.grps[i] == acc:
                i += 1
                acc = 0
                inc = True
                logger.debug(f"  {t} {i-1}({self.grps[i-1]})->{i}({self.grps[i]})")
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
        logger.debug(f"_stuff {lo_i}, {hi_i}, {combinables}")
        # '##?'
        # go through tokens, moving lo and hi indexes
        lo_acc = 0
        hi_acc = 0

        lo_pass = False
        hi_pass = False  # hi needs to take a break and insert '.'
        for combinables_i, (n, ch) in enumerate(combinables):
            remaining_combinables = combinables[combinables_i+1:]
            logger.debug(str((n, ch)))
            if ch == BR:
                lo_acc += n
                # print(f"  BR {lo_i}({self.get_grp(lo_i)}) {lo_acc}")
                lo_i, lo_acc, inc = self._check_lo_hi(lo_i, lo_acc, t="lo")
                if inc:
                    lo_pass = True
                else:
                    ...
                    # lo must combine with next ? to make it work

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
                        logger.debug(f"    t {i}({self.get_grp(i)})")
                        hi_i, hi_acc, inc = self._check_lo_hi(i, hi_acc, t="hi")
                        if inc:
                            hi_pass = True
                            break
            elif ch == UN:
                next_br_hi_chunk_n = self._next_br_chunk_of_size(self.get_grp(hi_i), remaining_combinables)
                next_br_chunk_n = self._next_br_chunk(remaining_combinables)
                # print("  nxt_br_chunk_n:", next_br_chunk_n, "lo_acc:", lo_acc)

                for i in range(n):
                    last_iter = i == n-1
                    # handle lo acc if it won't fit
                    if last_iter:
                        if lo_pass:
                            lo_pass = False
                        elif next_br_chunk_n == lo_acc + 1:
                            lo_acc += 1
                            lo_i, lo_acc, inc = self._check_lo_hi(lo_i, lo_acc, t="lo")
                            if inc:
                                lo_pass = True
                    elif next_br_chunk_n != self.get_grp(lo_i):
                        logger.debug(f" next br chunk ({next_br_chunk_n}) != current low grp ({self.get_grp(lo_i)})")
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
                    # logger.debug(f"  | -({i}) lo: {lo_i},{lo_acc},{lo_pass}  hi: {hi_i},{hi_acc},{hi_pass}")
            # logger.debug(f"  L lo: {lo_i},{lo_acc},{lo_pass}  hi: {hi_i},{hi_acc},{hi_pass}")

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
        # logger.debug("doing slot check for")
        # logger.debug(str(self))
        # ok = self._slot_check()
        # if not ok:
        #     logger.debug("failed slot check")
        #     logger.debug("  %s" % str(self))
        #     return False

        return True

    def grp_size_options_1(self) -> dict[int, list[tuple[int, int]]]:
        sizes = set(self.grps)
        result = {}
        for size in sizes:
            # print(size)
            ranges: list[tuple[int, int]] = []
            for start_i, ((_, st_prev_ch), (st_n, st_ch), (_, st_nxt_ch)) in enumerate(self.enumerate()):
                # print(start_i, ":", (st_n, st_ch))
                if st_ch == OP:
                    continue
                if st_ch == BR and st_n == size:
                    ranges.append((start_i, start_i+1))
                    continue
                if st_ch == UN and st_n == size and st_prev_ch != BR and st_nxt_ch != BR:
                    ranges.append((start_i, start_i+1))
                    continue
                acc = st_n
                for end_i, (n, ch) in enumerate(self.items[start_i+1:], start=start_i+1):
                    if ch == OP:
                        break
                    elif ch == BR:
                        acc += n
                    elif ch == UN:
                        acc += n
                    nxt_br_n = 0
                    try:
                        nxt_n, nxt_ch = self.items[end_i+1]
                        if nxt_ch == BR:
                            nxt_br_n = nxt_n
                    except IndexError:
                        pass
                    if acc + nxt_br_n == size:
                        ranges.append((start_i, end_i+1))
                        break
            # print(len(ranges), "ranges:", ranges)
            result[size] = ranges
        return result

    def grp_size_options_1_narrowed(self, size_possibilities: SizePossibilities) -> SizePossibilities:
        # find
        result = {}

        grp_counter = Counter(self.grps)
        max_size = max(self.grps)

        # In this case, all the '###' segments must be where the 3 groups go
        # ?###??????????###??????????###??????????###??????????###???????? 3,2,1,3,2,1,3,2,1,3,2,1,3,2,1
        # knowing this, all the other possibilities can be eliminated
        for size, options in size_possibilities.items():
            if len(options) == grp_counter[size]:
                result[size] = options
                continue

            locked_in_options = []
            for option in options:
                (st_i, end_i) = option
                (n, ch) = self.items[st_i]
                if not (end_i == st_i + 1 and ch == BR):
                    continue
                if size == max_size:
                    # a continuous block of # that matches max size is the only
                    # place one of them will fit.
                    locked_in_options.append(option)
                else:
                    # if '#' block matches size and is surrounded by '.', then it
                    # must fit (even if not max size).
                    try:
                        (_, prev_ch) = self.items[st_i-1]
                        prev_op = prev_ch == OP
                    except IndexError:
                        prev_op = True
                    try:
                        (_, nxt_ch) = self.items[end_i]
                        nxt_op = nxt_ch == OP
                    except IndexError:
                        nxt_op = True
                    if prev_op and nxt_op:
                        locked_in_options.append(option)

            if len(locked_in_options) == grp_counter[size]:
                result[size] = locked_in_options
            else:
                result[size] = options

        return result

    def resolve(self):
        # figure out if there are any unknowns that can be resolved through logic

        # .??..??...?##.?.??..??...?##.?.??..??...?##.?.??..??...?##.?.??..??...?##. 1,1,3,1,1,3,1,1,3,1,1,3,1,1,3
        #  1   1    3   1  1   1   3   1  1   1   3   1 1   1    3   1  1   1   3
        # in this example, all '?##' can be resolved
        grp_counter = Counter(self.grps)

        size_possibilities = self.grp_size_options_1()
        size_possibilities = self.grp_size_options_1_narrowed(size_possibilities)

        for size, possibilities in size_possibilities.items():
            if len(possibilities) == grp_counter[size]:

                for (st_i, end_i) in possibilities:
                    for i in range(st_i, end_i):
                        (n, ch) = self.items[i]
                        self.items[i] = (n, BR)
                    # Item before and after BR segment must be OP
                    for index in [st_i-1, end_i]:
                        try:
                            (n, ch) = self.items[index]
                        except IndexError:
                            # print("  IndexError")
                            pass
                        else:
                            if ch == UN:
                                assert n == 1
                                self.items[index] = (n, OP)

        self.items = self.glue(self.items)

    def sub_rows(self) -> list["Row"]:
        if not self.grps:
            return [self]
        grp_counter = Counter(self.grps)

        size_options = self.grp_size_options_1()
        size_options = self.grp_size_options_1_narrowed(size_options)

        # if each group only has 1 option, then we can resolve all others to '.'
        only_one_option = True
        for size, options in size_options.items():
            if len(options) != grp_counter[size]:
                only_one_option = False
                break
        if only_one_option:
            br_indexes = set()
            for size, options in size_options.items():
                for (st_i, end_i) in options:
                    # must be BR
                    for i in range(st_i, end_i):
                        (n, ch) = self.items[i]
                        self.items[i] = (n, BR)
                        br_indexes.add(i)
            for i, (n, ch) in enumerate(self.items):
                if ch == UN and i not in br_indexes:
                    self.items[i] = (n, OP)
            self.items = self.glue(self.items)
            return [self]

        sections: list[tuple[list[Item], list[int]]] = []

        for size, options in size_options.items():
            if len(options) != grp_counter[size]:
                continue

            grp_i = self.grps.index(size)+1
            grp_acc = self.grps[:grp_i]
            item_i = 0

            for enumerate_i, (st_i, end_i) in enumerate(options):
                last_iter = enumerate_i == len(options)-1

                for i in range(st_i, end_i):
                    (n, ch) = self.items[i]
                    self.items[i] = (n, BR)
                # Item before and after BR segment must be OP
                for index in [st_i-1, end_i]:
                    try:
                        (n, ch) = self.items[index]
                    except IndexError:
                        pass
                    else:
                        if ch == UN:
                            assert n == 1
                            self.items[index] = (n, OP)

                # handle existing acc unless it's fully resolved
                # if item_acc:
                #     assert len(grp_acc) > 0
                #     sections.append((item_acc, grp_acc))
                item_acc = self.items[item_i:end_i]
                item_i = end_i
                if grp_acc:
                    assert len(item_acc) > 0
                    sections.append((item_acc, grp_acc))

                # add to item and grp acc
                try:
                    new_grp_i = self.grps[grp_i:].index(size) + 1 + grp_i
                except ValueError:
                    grp_acc = self.grps[grp_i:]
                else:
                    grp_acc = self.grps[grp_i:new_grp_i]
                    grp_i = new_grp_i

                if last_iter:
                    item_acc = self.items[item_i:]
                    if item_acc:
                        try:
                            assert len(item_acc) > 0
                        except AssertionError:
                            breakpoint()
                            raise
                        if not grp_acc:
                            fully_resolved = True
                            for (n, ch) in item_acc:
                                if ch == UN:
                                    fully_resolved = False
                            # no groups, but item acc is not fully resolved
                            if not fully_resolved:
                                return []
                        sections.append((item_acc, grp_acc))
                    else:
                        if len(grp_acc) != 0:
                            return []

            # TODO: allow locking in multiple sizes, but only split into
            #       sub problems on the largest size?
            break

        # merge sections that are fully resolved into the next one
        final_sections = []
        item_acc = []
        grp_acc = []
        for section1 in sections:
            items, grps = section1
            item_acc.extend(items)
            grp_acc.extend(grps)
            fully_resolved = True
            for (n, ch) in items:
                if ch == UN:
                    fully_resolved = False
                    break
            if not fully_resolved:
                final_sections.append((item_acc, grp_acc))
                item_acc = []
                grp_acc = []
        if item_acc or grp_acc:
            final_sections.append((item_acc, grp_acc))

        if final_sections:
            return [Row(items, grps) for items, grps, in final_sections]
        else:
            return [self]

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
    return [Row(a_items, row.grps), Row(b_items, row.grps)]


def parse(line, unfold=True) -> Row:
    logger.debug(f"parsing line: {line}")
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
                if last_ch == UN:
                    for _ in range(acc):
                        result.append((1, last_ch))
                else:
                    result.append((acc, last_ch))
            acc = 1
        if ch not in ".#?":
            raise ValueError(f"{ch} is not valid")
        last_ch = typing.cast(Status, ch)
    if last_ch and acc:
        if last_ch == UN:
            for _ in range(acc):
                result.append((1, last_ch))
        else:
            result.append((acc, last_ch))

    return Row(result, groups)


def solve(line: str):
    row_orig = parse(line)
    result = r_solve(row_orig)
    print(str(row_orig))
    print("  ", result)
    return result


def r_solve(row_orig: Row) -> int:
    rows = row_orig.sub_rows()
    if len(rows) == 0:
        print(f"{row_orig!s}\n  total: {0}")
        return 0
    if len(rows) == 1:
        row_orig = rows[0]
    else:
        total = 1
        for row in rows:
            total *= r_solve(row)
        print(f"{row_orig!s}\n  total: {total}")
        return total

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
        if loops > 999:
            print("ERROR: too many loops")
            break
        if loops % 100 == 0:
            print(f"loop {loops}")
        q_result, ok = q.get()
        if not ok:
            q_index += 1
            # print(f"advanced q index {q_index-1}->{q_index}")
            # print(f"  {q.q.qsize()}")
            # print(f"  {swap_q.q.qsize()}")
            assert q.q.qsize() == 0
            q, swap_q = swap_q, q
            q_result, ok = q.get()
            if not ok:
                break
        row_q_index, row = q_result
        assert isinstance(row, Row)
        # print(f"fresh off the stack: {str(row)}")

        if row.fully_resolved():
            if row.is_valid():
                # print(f"totally valid row: {str(row)}")
                total += 1
            continue

        # solve rest with both '.' and '#'
        # print(f"-- before mutate of row {str(row)}")
        for child in mutate(row):
            # print(f"child: {str(child)}")
            if child.might_work():

                rows = child.sub_rows()
                if len(rows) == 0:
                    # print("rejected (sub_rows())")
                    # print("  ", str(child))
                    rejected_count += 1
                elif len(rows) == 1:
                    swap_q.put((row_q_index + 1, rows[0]))
                else:
                    sub_total = 1
                    for row in rows:
                        # print("  sub", str(row))
                        sub_total *= r_solve(row)
                    total += sub_total
                maybe_valid_count += 1
            else:
                # print("rejected")
                # print("  ", str(child))
                rejected_count += 1

    # print(f"maybe valid: {maybe_valid_count}")
    # print(f"rejected: {rejected_count}")
    print(f"{row_orig!s}\n  total: {total}")
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
        r = row.might_work()
        if r == expected:
            print("P", r)
        else:
            print(f"ERROR: got {r}, expected {expected}")
            print(str(row))
            print(" ", r)

    # t(".#.# 1", False)
    # t(".#. 1", True)
    # t(".##. 1", False)
    # t(".##?. 3", True)
    # t(".#?. 3", False)
    # t(".## 3", False)
    #
    # # the all ok (examples)
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
    #     line = """\
    # .#?#?#?#?#?#?#???#?#?#?#?#?#?#???#?#?#?#?#?#?#???#?#?#?#?#?#?#???#?#?#?#?#?#?#? \
    # 1,3,1,6,1,3,1,6,1,3,1,6,1,3,1,6,1,3,1,6"""
    # line = ".#.###.#.######.?#?#?#?#?#?#?#???#?#?#?#?#?#?#???#?#?#?#?#?#?#???#?#?#?#?#?#?#? 1,3,1,6,1,3,1,6,1,3,1,6,1,3,1,6,1,3,1,6"
    # row = parse(line, unfold=False)
    # print(row._slot_check())

    # the all ok (examples)
    # assert 1 == solve("???.### 1,1,3")
    # assert 16384 == solve(".??..??...?##. 1,1,3")
    # assert 1 == solve("?#?#?#?#?#?#?#? 1,3,1,6")
    # assert 16 == solve("????.#...#... 4,1,1")
    # assert 2500 == solve("????.######..#####. 1,6,5")
    _ = solve("?###???????? 3,2,1")  # 506250


if __name__ == "__main__":
    part2(DATA)
    # part2(INPUT)


def test_solve_example1():
    assert 1 == solve("???.### 1,1,3")


def test_solve_example2():
    assert 16384 == solve(".??..??...?##. 1,1,3")


def test_solve_example3():
    assert 1 == solve("?#?#?#?#?#?#?#? 1,3,1,6")


def test_solve_example4():
    assert 16 == solve("????.#...#... 4,1,1")


def test_solve_example5():
    assert 2500 == solve("????.######..#####. 1,6,5")


def test_solve_example6():
    assert 506250 == solve("?###???????? 3,2,1")


def test_solve_sub_1():
    line = "???.### 1,1,3"
    row = parse(line, unfold=False)

    result = r_solve(row)

    assert result == 1


def test_parse1():
    line = ".??..??...?##. 1,1,3"
    row = parse(line)
    assert str(row) == (
        ".??..??...?##.?.??..??...?##.?.??..??...?##.?.??..??...?##.?.??..??...?##. "
        "1,1,3,1,1,3,1,1,3,1,1,3,1,1,3"
    )


def test_resolve1():
    # figure out if there are any unknowns that can be resolved through logic

    # .??..??...?##.?.??..??...?##.?.??..??...?##.?.??..??...?##.?.??..??...?##. 1,1,3,1,1,3,1,1,3,1,1,3,1,1,3
    #  1   1    3   1  1   1   3   1  1   1   3   1 1   1    3   1  1   1   3
    # in this example, all '?##' can be resolved
    line = ".??..??...?##. 1,1,3"
    row = parse(line)

    row.resolve()

    expected = (
        ".??..??...###.?.??..??...###.?.??..??...###.?.??..??...###.?.??..??...###. "
        "1,1,3,1,1,3,1,1,3,1,1,3,1,1,3"
    )
    assert str(row) == expected


def test_resolve2():
    line = "?###???????? 3,2,1"
    row = parse(line)
    print(str(row))

    row.resolve()
    print(str(row))

    expected = (
        ".###.????????.###.????????.###.????????.###.????????.###.??????? "
        "3,2,1,3,2,1,3,2,1,3,2,1,3,2,1"
    )
    print(expected)
    assert str(row) == expected


def test_sub_problem():
    line = "?###???????? 3,2,1"
    row = parse(line)
    row.resolve()
    expected = (
        ".###.????????.###.????????.###.????????.###.????????.###.??????? "
        "3,2,1,3,2,1,3,2,1,3,2,1,3,2,1"
    )
    assert str(row) == expected

    sub_rows = row.sub_rows()
    assert len(sub_rows) == 5
    assert str(sub_rows[0]) == ".###.????????.### 3,2,1,3"
    assert str(sub_rows[1]) == ".????????.### 2,1,3"
    assert str(sub_rows[2]) == ".????????.### 2,1,3"
    assert str(sub_rows[3]) == ".????????.### 2,1,3"
    assert str(sub_rows[4]) == ".??????? 2,1"

    # total = 0
    # for row in sub_rows:
    #     x = r_solve(row)
    #     total = total * x
    # assert total == 506250


def test_sub_problem2():
    """Should return original row if it can't be subdivided."""
    line = "?#?#?#?#?#?#?#? 1,3,1,6"
    row = parse(line)
    row.resolve()
    expected = (
        "?#?#?#?#?#?#?#???#?#?#?#?#?#?#???#?#?#?#?#?#?#???#?#?#?#?#?#?#???#?#?#?#?#?#?#? "
        "1,3,1,6,1,3,1,6,1,3,1,6,1,3,1,6,1,3,1,6"
    )
    assert str(row) == expected

    sub_rows = row.sub_rows()
    assert len(sub_rows) == 1
    assert str(sub_rows[0]) == expected


def test_sub_problem3():
    line = "???.### 1,1,3"
    row = parse(line)
    row.resolve()
    expected = (
        "???.###.???.###.???.###.???.###.???.### "
        "1,1,3,1,1,3,1,1,3,1,1,3,1,1,3"
    )
    assert str(row) == expected

    sub_rows = row.sub_rows()
    assert len(sub_rows) == 5
    assert len(sub_rows) == 5
    assert str(sub_rows[0]) == "???.### 1,1,3"
    assert str(sub_rows[1]) == ".???.### 1,1,3"
    assert str(sub_rows[1]) == ".???.### 1,1,3"
    assert str(sub_rows[1]) == ".???.### 1,1,3"
    assert str(sub_rows[1]) == ".???.### 1,1,3"


def test_sub_problem4():
    line = "???.### 1,1,3"
    row = parse(line, unfold=False)
    assert str(row) == line

    rows = row.sub_rows()

    assert len(rows) == 1
    assert str(rows[0]) == line


def test_sub_problem5():
    line = ".##.#.?? 2,1"
    row = parse(line, unfold=False)
    assert str(row) == line

    rows = row.sub_rows()

    assert len(rows) == 1
    assert str(rows[0]) == ".##.#... 2,1"


def test_unit():
    row = Row([(1, OP)], [])

    result = r_solve(row)

    assert result == 1
