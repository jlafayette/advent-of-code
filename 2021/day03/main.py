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


class BitCriteria:
    def __init__(self, length: int, most_common: bool, tie_result: str) -> None:
        self.length = length
        self.most_common = most_common
        self.tie_result = tie_result

    def _make_filter(self, index: int, equal: bool, result: str):

        def f(line: str) -> bool:
            if equal:
                return line[index] == self.tie_result
            else:
                return line[index] == result

        return f

    def find(self, lines: list[str]) -> int:
        result_line = ""
        lines = copy(lines)

        for position in range(self.length):
            counter = Counter([x[position] for x in lines])

            mc = counter.most_common()
            if self.most_common:
                result = mc[0][0]
                is_equal = mc[0][1] == mc[1][1]
            else:  # least common
                result = mc[-1][0]
                is_equal = mc[0][1] == mc[-1][1]

            filter_func = self._make_filter(position, is_equal, result)
            lines = list(filter(filter_func, lines))

            if len(lines) == 1:
                result_line = lines[0]
                break

        return int(result_line, base=2)


def part2(report: str) -> int:
    lines = report.strip().split("\n")
    length = len(lines[0])

    oxygen_criteria = BitCriteria(length, most_common=True, tie_result='1')
    oxygen_generator_rating = oxygen_criteria.find(lines)

    co2_criteria = BitCriteria(length, most_common=False, tie_result='0')
    co2_scrubber_rating = co2_criteria.find(lines)

    return oxygen_generator_rating * co2_scrubber_rating


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
