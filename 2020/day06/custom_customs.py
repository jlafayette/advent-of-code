"""Day 6: Custom Customs

https://adventofcode.com/2020/day/6

Initial solution to get the answer as quick as possible

"""
from pathlib import Path


def anyone_yes(group):
    chars = set()
    for char in group:
        if char == "\n":
            continue
        chars.add(char)
    return len(chars)


def part1(data: str):
    groups = data.strip().split("\n\n")
    counts = []
    for group in groups:
        counts.append(anyone_yes(group))
    return sum(counts)


def everyone_yes(group):
    combined = group.replace("\n", "")
    answers = set()
    for char in combined:
        answers.add(char)
    count = 0
    for a in answers:
        if all([a in line for line in group.split()]):
            count += 1
    return count


def test_part2():
    data = """abc

a
b
c

ab
ac

a
a
a
a

b"""
    assert part2(data) == 6


def part2(data: str):
    groups = data.strip().split("\n\n")
    return sum([everyone_yes(group) for group in groups])


def main():
    input_file = Path(__file__).parent / "input"
    data = input_file.read_text()
    print(part1(data))
    print(part2(data))


if __name__ == "__main__":
    main()
