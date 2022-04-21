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


def part1(data: str) -> int:
    numbers = [int(x) for x in data.split("\n") if x]
    increase_count = 0
    for i, n1 in enumerate(numbers):
        try:
            n2 = numbers[i+1]
        except IndexError:
            break
        if n2 > n1:
            increase_count += 1
    return increase_count


def test_part1():
    assert part1(TEST_INPUT) == 7


def main():
    # read puzzle input from file
    input_file = Path(__file__).parent / "input"
    contents = input_file.read_text()

    part1_answer = part1(contents)
    print(part1_answer)


if __name__ == "__main__":
    main()
