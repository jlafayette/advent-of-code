import collections
import functools
import logging
import typing
import queue
from collections import Counter
from typing import Literal, Optional
from pathlib import Path


logging.basicConfig(level=logging.WARNING, format="{message}", style='{')
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
        self.items = self._glue1(items)

    def glue(self, items: list[Item]):
        return self._glue1(items)
    
    @staticmethod
    def _glue1(items: list[Item]):
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

    @staticmethod
    def _glue2(items: list[Item]):
        new = []
        acc_n, acc_ch = 0, OP
        for (n, ch) in items:
            if ch != acc_ch:
                if acc_n:
                    if acc_ch == UN:
                        for _ in range(acc_n):
                            new.append((1, acc_ch))
                    else:
                        if acc_ch == OP:
                            acc_n = 1
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
                if acc_ch == OP:
                    acc_n = 1
                new.append((acc_n, acc_ch))
        if len(new) >= 2:
            start_index = 0
            (n, ch) = new[0]
            if ch == OP:
                start_index = 1
            end_index = len(new)
            (n, ch) = new[-1]
            if ch == OP:
                end_index = -1
            new = new[start_index:end_index]
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

    def __str__(self):
        items = "".join([ch*n for (n, ch) in self.items])
        grps = ",".join([str(x) for x in self.grps])
        return " ".join([items, grps])

    def __hash__(self):
        items = "".join([ch*n for (n, ch) in self._glue2(self.items)])
        grps = ",".join([str(x) for x in self.grps])
        s = " ".join([items, grps])
        return hash(s)

    def __eq__(self, other):
        return hash(self) == hash(other)


@functools.lru_cache(maxsize=1000)
def sub_rows(self: Row) -> list[Row]:
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
                logger.debug(str(row))
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
    logger.warning(f"line: {row_orig!s}\n\ttotal: {result}")
    return result


@functools.lru_cache(maxsize=1000)
def r_solve(row_orig: Row) -> int:
    rows = sub_rows(row_orig)
    if len(rows) == 0:
        logger.warning(f"sub: {row_orig!s}\n\ttotal: {0}")
        return 0
    if len(rows) == 1:
        row_orig = rows[0]
    else:
        total = 1
        for row in rows:
            total *= r_solve(row)
        logger.warning(f"sub: {row_orig!s}\n\ttotal: {total}")
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
            raise RuntimeError(f"too many loops ({loops}) qsize={q.q.qsize()+swap_q.q.qsize()}")
        if loops % 100 == 0:
            logger.info(f"loop {loops}")
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
        logger.debug(f"! (pop) stack: {str(row)}")

        if row.fully_resolved():
            if row.is_valid():
                logger.debug(f"VV valid row: {str(row)}")
                total += 1
            continue

        # solve rest with both '.' and '#'
        logger.debug(f"-- before mutate of row {str(row)}")
        for child in mutate(row):
            logger.debug(f"  child: {str(child)}")
            if child.might_work():

                rows = sub_rows(child)
                if len(rows) == 0:
                    logger.debug("    rejected (sub_rows())")
                    logger.debug(f"    {child!s}")
                    rejected_count += 1
                elif len(rows) == 1:
                    swap_q.put((row_q_index + 1, rows[0]))
                else:
                    sub_total = 1
                    for row in rows:
                        logger.debug(f"      sub {row!s}")
                        sub_total *= r_solve(row)
                    total += sub_total
                maybe_valid_count += 1
            else:
                logger.debug("  rejected")
                logger.debug(f"  {child!s}")
                rejected_count += 1

    logger.debug(f"maybe valid: {maybe_valid_count}")
    logger.debug(f"rejected: {rejected_count}")
    logger.info(f"{row_orig!s}\n  total: {total}")
    return total


def part2(data):
    total = 0
    errors = []
    for line in split_and_strip(data, "\n"):
        try:
            total += solve(line)
        except RuntimeError as err:
            print(f"ERROR: {err}")
            errors.append((line, err))
    for (line, err) in errors:
        print(f"ERROR: {err} for line: {line}")
    print("Total:", total)


if __name__ == "__main__":
    # part2(DATA)
    part2(INPUT)


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


def test_cache():
    solve("?###???????? 3,2,1")
    solve("?###???????? 3,2,1")
    solve(".??..??...?##. 1,1,3")

    print(r_solve.cache_info())
    print(sub_rows.cache_info())


def test_cache_glue_1():
    line = ".??????? 2,1"
    row = parse(line, unfold=False)
    result = r_solve(row)
    logger.warning(f"result: {result}")

    print(r_solve.cache_info())
    print(sub_rows.cache_info())


def test_solve_sub_1():
    line = "???.### 1,1,3"
    row = parse(line, unfold=False)

    result = r_solve(row)

    assert result == 1


def test_solve_sub_2():
    line = ".??????? 2,1"
    row = parse(line, unfold=False)
    result = r_solve(row)
    logger.warning(f"result: {result}")
    logger.warning("----- VV")
    assert result == 10


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

    results = sub_rows(row)
    assert len(results) == 5
    assert str(results[0]) == ".###.????????.### 3,2,1,3"
    assert str(results[1]) == ".????????.### 2,1,3"
    assert str(results[2]) == ".????????.### 2,1,3"
    assert str(results[3]) == ".????????.### 2,1,3"
    assert str(results[4]) == ".??????? 2,1"

    # total = 0
    # for row in results:
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

    results = sub_rows(row)
    assert len(results) == 1
    assert str(results[0]) == expected


def test_sub_problem3():
    line = "???.### 1,1,3"
    row = parse(line)
    row.resolve()
    expected = (
        "???.###.???.###.???.###.???.###.???.### "
        "1,1,3,1,1,3,1,1,3,1,1,3,1,1,3"
    )
    assert str(row) == expected

    results = sub_rows(row)
    assert len(results) == 5
    assert len(results) == 5
    assert str(results[0]) == "???.### 1,1,3"
    assert str(results[1]) == ".???.### 1,1,3"
    assert str(results[1]) == ".???.### 1,1,3"
    assert str(results[1]) == ".???.### 1,1,3"
    assert str(results[1]) == ".???.### 1,1,3"


def test_sub_problem4():
    line = "???.### 1,1,3"
    row = parse(line, unfold=False)
    assert str(row) == line

    rows = sub_rows(row)

    assert len(rows) == 1
    assert str(rows[0]) == line


def test_sub_problem5():
    line = ".##.#.?? 2,1"
    row = parse(line, unfold=False)
    assert str(row) == line

    rows = sub_rows(row)

    assert len(rows) == 1
    assert str(rows[0]) == ".##.#... 2,1"


def test_unit():
    row = Row([(1, OP)], [])

    result = r_solve(row)

    assert result == 1


def test_hash():
    line = "...??..?...#.###. 2,1,1,3"
    row1 = parse(line, unfold=False)

    line = "??.?.#.### 2,1,1,3"
    row2 = parse(line, unfold=False)

    assert hash(row1) == hash(row2)

