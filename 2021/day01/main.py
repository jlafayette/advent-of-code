from pathlib import Path


TEST_INPUT = """199
200
208
210
200
207
240
269
260
263
"""


def parse(data: str) -> list[int]:
    return [int(x) for x in data.split("\n") if x]


def read_input() -> list[int]:
    input_file = Path(__file__).parent / "input"
    contents = input_file.read_text()
    depths = parse(contents)
    return depths


def part1(depths: list[int]) -> int:
    increase_count = 0
    for i, n1 in enumerate(depths):
        try:
            n2 = depths[i+1]
        except IndexError:
            break
        if n2 > n1:
            increase_count += 1
    return increase_count


def test_part1() -> None:
    depths = parse(TEST_INPUT)
    assert part1(depths) == 7


def test_part1_full_input() -> None:
    depths = read_input()

    result = part1(depths)

    expected = 1791
    assert result == expected


def part2(depths: list[int]) -> int:
    increase_count = 0
    for i, n1 in enumerate(depths):
        try:
            n2, n3, n4 = depths[i+1],  depths[i+2], depths[i+3]
        except IndexError:
            break

        sum1 = n1 + n2 + n3
        sum2 = n2 + n3 + n4

        if sum2 > sum1:
            increase_count += 1
    return increase_count


def test_part2() -> None:
    depths = parse(TEST_INPUT)

    result = part2(depths)

    expected = 5
    assert result == expected


def test_part2_full_input() -> None:
    depths = read_input()

    result = part2(depths)

    expected = 1822
    assert result == expected


def main() -> None:
    depths = read_input()

    part1_answer = part1(depths)
    print(part1_answer)

    part2_answer = part2(depths)
    print(part2_answer)


if __name__ == "__main__":
    main()
