from pathlib import Path


# Test Input
TEST_INPUT = """2-4,6-8
2-3,4-5
5-7,7-9
2-8,3-7
6-6,4-6
2-6,4-8
"""


def parse_line(line) -> tuple[tuple[int, int], tuple[int, int]]:
    a, b = line.split(',')
    a1, a2 = a.split('-')
    b1, b2 = b.split('-')
    return (int(a1), int(a2)), (int(b1), int(b2))


def read_input():
    input_file = Path(__file__).absolute().parent / "input"
    data = input_file.read_text()
    # data = TEST_INPUT
    lines = data.strip().split("\n")
    lines = [line.strip() for line in lines]
    return [parse_line(line) for line in lines]


def _contains(l1, l2):
    a1, a2 = l1
    b1, b2 = l2
    return a1 >= b1 and a2 <= b2


def contains_sublist(l1, l2):
    return _contains(l1, l2) or _contains(l2, l1)


def part1():
    pairs = read_input()
    total = 0
    for elf1, elf2 in pairs:
        if contains_sublist(elf1, elf2):
            total += 1
    print(total)


def overlap(a, b):
    sl = sorted([a, b])
    a1, a2 = sl[0]
    b1, b2 = sl[1]
    return a2 >= b1


def part2():
    pairs = read_input()
    total = 0
    for elf1, elf2 in pairs:
        if overlap(elf1, elf2):
            total += 1
    print(total)


part1()
part2()
