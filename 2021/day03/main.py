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

    def make_filter(index: int, equal: bool, result: str, equal_result: str):

        def f(line: str) -> bool:
            if equal:
                return line[index] == equal_result
            else:
                return line[index] == result

        return f

    # oxygen generator rating
    # filter to most common (ties keep values with 1)
    ox_gen_str = ""
    ox_lines = copy(lines)
    for position in range(length):
        counter = Counter([x[position] for x in ox_lines])
        mc = counter.most_common()
        result = counter.most_common()[0][0]
        equal_result = '1'
        is_equal = mc[0][1] == mc[1][1]
        filter_func = make_filter(
            position,
            is_equal,
            result,
            equal_result,
        )
        ox_lines = list(filter(filter_func, ox_lines))

        if len(ox_lines) == 1:
            ox_gen_str = ox_lines[0]
            break

    # CO2 scrubber rating
    # filter to least common (ties keep values with 0)
    co2_str = ""
    co2_lines = copy(lines)
    for position in range(length):
        counter = Counter([x[position] for x in co2_lines])
        mc = counter.most_common()

        result = mc[-1][0]
        equal_result = '0'
        is_equal = mc[0][1] == mc[-1][1]
        filter_func = make_filter(
            position,
            is_equal,
            result,
            equal_result,
        )
        co2_lines = list(filter(filter_func, co2_lines))

        if len(co2_lines) == 1:
            co2_str = co2_lines[0]
            break

    return int(ox_gen_str, base=2) * int(co2_str, base=2)


def test_part2():
    actual = part2(TEST_INPUT)

    expected = 230
    assert actual == expected


def test_part2_actual_data():
    report = Path("input.txt").read_text()

    actual = part2(report)

    expected = 3368358
    assert actual == expected


def main() -> None:
    report = Path("input.txt").read_text()

    answer1 = part1(report)
    print(answer1)  # 2972336

    answer2 = part2(report)
    print(answer2)  # 3368358


if __name__ == "__main__":
    main()
