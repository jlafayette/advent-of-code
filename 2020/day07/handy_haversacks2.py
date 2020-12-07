"""Day 7: Handy Haversacks

https://adventofcode.com/2020/day/7

"""
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List


# -- parse data into lookup table


@dataclass
class Bag:
    count: int
    name: str


BagLookup = Dict[str, List[Bag]]


def create_bag_lookup(data: str) -> BagLookup:

    # regex patterns
    contains_nothing_pattern = re.compile(r"(\w+ \w+) bags contain no other bags?\.")
    contains_something_pattern = re.compile(r"(\w+ \w+) bags contain (.*)\.")
    part_pattern = re.compile(r"(\d+) (\w+ \w+) bags?")

    lookup = {}
    for line in data.split("\n"):
        if m := contains_nothing_pattern.match(line):
            lookup[m.groups()[0]] = []
        elif m := contains_something_pattern.match(line):
            name = m.groups()[0]
            contains = []
            rest = m.groups()[1]
            for part in rest.split(", "):
                if m := part_pattern.match(part):
                    contains.append(Bag(count=int(m.groups()[0]), name=m.groups()[1]))
                else:
                    print(f"ERROR: {part}")
            lookup[name] = contains
        else:
            print(f"ERROR: {line}")
    return lookup


# -- part 1


def part1(bag_lookup: BagLookup) -> int:

    def find_parents(name: str) -> List[str]:
        result = []
        for candidate_name, bags in bag_lookup.items():
            bag_names = [bag.name for bag in bags]
            if name in bag_names:
                result.append(candidate_name)
        return result

    def find_all_parents(all_parents: List[str], names: List[str]) -> List[str]:
        if not names:
            return all_parents
        new_names = []
        while names:
            name = names.pop()
            parents = find_parents(name)
            new_names.extend(parents)
            all_parents.extend(parents)
        return find_all_parents(list(set(all_parents)), list(set(new_names)))

    all_parents = find_all_parents([], ["shiny gold"])
    return len(all_parents)


TEST_DATA = """light red bags contain 1 bright white bag, 2 muted yellow bags.
dark orange bags contain 3 bright white bags, 4 muted yellow bags.
bright white bags contain 1 shiny gold bag.
muted yellow bags contain 2 shiny gold bags, 9 faded blue bags.
shiny gold bags contain 1 dark olive bag, 2 vibrant plum bags.
dark olive bags contain 3 faded blue bags, 4 dotted black bags.
vibrant plum bags contain 5 faded blue bags, 6 dotted black bags.
faded blue bags contain no other bags.
dotted black bags contain no other bags."""


def test_part1():
    assert part1(create_bag_lookup(TEST_DATA)) == 4


# -- part2


def part2(bag_lookup: BagLookup) -> int:

    def calculate_inside_bags(bags, count):
        if not bags:
            return count
        new_bags = []
        for bag in bags:
            for _ in range(bag.count):
                new_bags.extend(bag_lookup[bag.name])
                count += 1
        return calculate_inside_bags(new_bags, count)

    total = calculate_inside_bags([Bag(count=1, name="shiny gold")], 0)
    return total - 1  # subtract the original bag


TEST_DATA2 = """shiny gold bags contain 2 dark red bags.
dark red bags contain 2 dark orange bags.
dark orange bags contain 2 dark yellow bags.
dark yellow bags contain 2 dark green bags.
dark green bags contain 2 dark blue bags.
dark blue bags contain 2 dark violet bags.
dark violet bags contain no other bags."""


def test_part2():
    assert part2(create_bag_lookup(TEST_DATA2)) == 126


def main():
    input_file = Path(__file__).parent / "input"
    data = input_file.read_text()
    bag_lookup = create_bag_lookup(data)

    answer1 = part1(bag_lookup)
    print(answer1)
    if answer1 != 287:
        print(f"Expected 287, got {answer1}")

    answer2 = part2(bag_lookup)
    print(answer2)
    if answer2 != 48160:
        print(f"Expected 48160, got {answer2}")


if __name__ == "__main__":
    main()
