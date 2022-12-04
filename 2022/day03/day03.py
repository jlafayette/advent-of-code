from pathlib import Path


# Test Input
TEST_INPUT = """vJrwpWtwJgWrhcsFMMfFFhFp
jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
PmmdzqPrVvPwwTWBwg
wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
ttgJtRGJQctTZtZT
CrZsJsPPZsGzwwsLwLmpwMDw
"""


def read_input():
    input_file = Path(__file__).absolute().parent / "input"
    data = input_file.read_text()
    # data = TEST_INPUT
    lines = data.strip().split("\n")
    lines = [line.strip() for line in lines]
    return lines


def score(letter: str):
    if letter.islower():
        return ord(letter) - ord('a') + 1
    else:
        return ord(letter) - ord('A') + 27


def part1():
    rucksacks = read_input()
    split_rucksacks = [(r[:len(r)//2], r[len(r)//2:]) for r in rucksacks]
    total = 0
    for compartment_1, compartment_2 in split_rucksacks:
        common = set(compartment_1).intersection(set(compartment_2))
        for item in common:
            total += score(item)
    print(total)


def next3(iterable):
    while True:
        try:
            a = next(iterable)
            b = next(iterable)
            c = next(iterable)
            yield a, b, c
        except StopIteration:
            return


def part2():
    rucksacks = read_input()
    total = 0
    for a, b, c in next3(iter(rucksacks)):
        badge = set(a).intersection(set(b), set(c))
        for b in badge:
            total += score(b)
    print(total)


part1()
part2()
