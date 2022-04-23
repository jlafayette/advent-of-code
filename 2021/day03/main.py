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


def main() -> None:
    report = Path("input.txt").read_text()

    answer1 = part1(report)
    print(answer1)  # 2972336


if __name__ == "__main__":
    main()
