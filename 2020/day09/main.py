"""Day 9: Encoding Error

https://adventofcode.com/2020/day/9

"""
import collections
from itertools import combinations
from pathlib import Path


# -- part 1


TEST_DATA = """35
20
15
25
47
40
62
55
65
95
102
117
150
182
127
219
299
277
309
576"""


def first_invalid_number(data, buffer_size):
    buffer = collections.deque(maxlen=buffer_size)
    numbers = [int(x) for x in data.strip().split("\n")]
    preamble = numbers[:buffer_size]
    for number in preamble:
        buffer.append(number)
    for number in numbers[buffer_size:]:
        sums = [sum(combo) for combo in combinations(buffer, 2)]
        if number not in sums:
            return number
        buffer.append(number)
    else:
        return None


def part1(data: str):
    assert first_invalid_number(TEST_DATA, 5) == 127
    return first_invalid_number(data, 25)  # 675280050


# -- part 2

def find_contiguous_range(data: str, target: int):
    buffer = collections.deque()
    numbers = [int(x) for x in data.strip().split("\n")]
    for number in numbers:
        if len(buffer) >= 2 and sum(buffer) == target:
            return min(buffer) + max(buffer)
        buffer.append(number)
        sum_ = sum(buffer)
        while sum_ > target and len(buffer) > 2:
            _ = buffer.popleft()
            sum_ = sum(buffer)


def part2(data: str):
    invalid_number = first_invalid_number(TEST_DATA, 5)
    assert find_contiguous_range(TEST_DATA, invalid_number) == 62
    invalid_number = first_invalid_number(data, 25)
    return find_contiguous_range(data, invalid_number)  # 96081673


if __name__ == "__main__":
    input_file = Path(__file__).parent / "input"
    input_data = input_file.read_text()

    print(part1(input_data))
    print(part2(input_data))
