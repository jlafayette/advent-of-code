from copy import copy
from collections import Counter
from pathlib import Path


def part1(data: str) -> int:
    lines = data.strip().split("\n")
    length = len(lines[0])

    most_common = ""
    least_common = ""

    for position in range(length):
        counter = Counter([x[position] for x in lines])
        most_common += counter.most_common()[0][0]
        least_common += counter.most_common()[-1][0]

    return int(most_common, base=2) * int(least_common, base=2)


TEST_INPUT = """00100
11110
10110
10111
10101
01111
00111
11100
10000
11001
00010
01010"""


def test_part1():
    actual = part1(TEST_INPUT)

    expected = 198
    assert actual == expected


def test_part1_actual_data():
    report = Path("input.txt").read_text()

    actual = part1(report)

    expected = 2972336
    assert actual == expected


def part2(report: str) -> int:
    lines = report.strip().split("\n")
    length = len(lines[0])

    most_common = ""
    least_common = ""

    for position in range(length):
        counter = Counter([x[position] for x in lines])
        most_common += counter.most_common()[0][0]
        least_common += counter.most_common()[-1][0]

    # oxygen generator rating
    # filter to most common (ties keep values with 1)
    ox_gen_str = ""
    ox_lines = copy(lines)
    for position in range(length):
        counter = Counter([x[position] for x in ox_lines])
        ms_pos = counter.most_common()[0][0]
        # [('0', 1), ('1', 1)]
        mc = counter.most_common()
        equal = mc[0][1] == mc[1][1]

        def f(line: str) -> bool:
            if equal:
                return line[position] == '1'
            else:
                return line[position] == ms_pos

        ox_lines = [
            line for line in ox_lines
            if f(line)
        ]
        if len(ox_lines) == 1:
            ox_gen_str = ox_lines[0]

    # TODO: calculate CO2 scrubber rating
    # ...

    # return int(most_common, base=2) * int(least_common, base=2)
    return 0


def main() -> None:
    report = Path("input.txt").read_text()

    answer1 = part1(report)
    print(answer1)  # 2972336

    answer2 = part2(TEST_INPUT)
    print(answer2)  #


if __name__ == "__main__":
    main()
