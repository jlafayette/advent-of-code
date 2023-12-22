import dataclasses
from pathlib import Path


INPUT = (Path(__file__).absolute().parent / "input").read_text().strip()


DATA = """\
0 3 6 9 12 15
1 3 6 10 15 21
10 13 16 21 30 45\
"""


def parse(data) -> list[list[int]]:
    result = []
    lines = data.strip().split("\n")
    for line in lines:
        result.append(
            [int(x) for x in line.strip().split()]
        )
    return result


def part1_solve(readings: list[int]) -> int:

    def f(stack: list[list[int]], up=False):
        if up:
            bottom = stack.pop()
            if not stack:
                return bottom[-1]
            stack[-1].append(stack[-1][-1]+bottom[-1])
            return f(stack, up=True)
        else:
            # special, return if all zeros, adding one more zero
            if not list(filter(lambda x: x != 0, stack[-1])):
                new_len = len(stack[-1]) + 1
                stack.append([0] * new_len)
                return f(stack, up=True)

            nums = stack[-1]
            diffs = []
            a = nums[0]
            for b in nums[1:]:
                diffs.append(b - a)
                a = b
            stack.append(diffs)
            return f(stack, up=False)

    return f([readings], up=False)


def part1(data):
    d = parse(data)
    total = 0
    for x in d:
        total += part1_solve(x)
    print("Total:", total)


def part2_solve(readings: list[int]) -> int:

    def f(stack: list[list[int]], up=False):
        if up:
            # print("--->")
            # for line in stack:
            #     print("  ", line)
            bottom = stack.pop()
            if not stack:
                # print(bottom)
                return bottom[0]
            stack[-1].insert(0, stack[-1][0]-bottom[0])
            # print("   ---")
            # for line in stack:
            #     print("  ", line)
            # print("   <---")
            return f(stack, up=True)
        else:
            # special, return if all zeros, adding one more zero
            if not list(filter(lambda x: x != 0, stack[-1])):
                new_len = len(stack[-1]) + 1
                stack.append([0] * new_len)
                return f(stack, up=True)

            nums = stack[-1]
            diffs = []
            a = nums[0]
            for b in nums[1:]:
                diffs.append(b - a)
                a = b
            stack.append(diffs)
            return f(stack, up=False)

    return f([readings], up=False)


def part2(data):
    d = parse(data)
    total = 0
    for line in d:
        # print("="*80)
        x = part2_solve(line)
        # print(x)
        total += x
    print("Total:", total)


part1(DATA)
part1(INPUT)
part2(DATA)
part2(INPUT)
