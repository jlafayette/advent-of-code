"""Day 7: Handy Haversacks

https://adventofcode.com/2020/day/7

"""
import re
from dataclasses import dataclass
from pathlib import Path


# -- part 1


bag_contains_pattern = re.compile(r"(\w+ \w+) bags contain (.*)\.")
part_pattern = re.compile(r"(\d+) (\w+ \w+) bags?")
contains_nothing_pattern = re.compile(r"(\w+ \w+) bags contain no other bags?\.")


def part1(data: str):
    bag_lookup = {}
    for line in data.split("\n"):
        m = contains_nothing_pattern.match(line)
        if m:
            bag_lookup[m.groups()[0]] = []
            continue
        m = bag_contains_pattern.match(line)
        if m:
            name = m.groups()[0]
            contains = []
            rest = m.groups()[1]
            for part in rest.split(", "):
                m = part_pattern.match(part)
                if m:
                    contains.append(m.groups()[1])
            bag_lookup[name] = contains
            continue
        print(f"ERROR: {line}")

    def find_parents(name):
        result = []
        for k, v in bag_lookup.items():
            if name in v:
                result.append(k)
        return result

    def find_root_parents(root_parents, names):
        if not names:
            return list(set(root_parents))
        new_names = []
        while names:
            name = names.pop()
            parents = find_parents(name)
            if not parents:
                root_parents.append(name)
            else:
                new_names.extend(parents)
            for parent in parents:
                if parent in bag_lookup:
                    root_parents.append(parent)
        return find_root_parents(root_parents, list(set(new_names)))

    root_parents = find_root_parents([], ["shiny gold"])

    return len(root_parents)


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
    assert part1(TEST_DATA) == 4


# -- part2


@dataclass
class Bag:
    count: int
    name: str


def create_bag_lookup(data):
    lookup = {}
    for line in data.split("\n"):
        m = contains_nothing_pattern.match(line)
        if m:
            lookup[m.groups()[0]] = []
            continue

        m = bag_contains_pattern.match(line)
        if m:
            name = m.groups()[0]
            contains = []
            rest = m.groups()[1]
            for part in rest.split(", "):
                m = part_pattern.match(part)
                if m:
                    contains.append(Bag(count=int(m.groups()[0]), name=m.groups()[1]))
            lookup[name] = contains
            continue
        print(f"ERROR: {line}")
    return lookup


def part2(data: str):
    bag_lookup = create_bag_lookup(data)

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
    assert part2(TEST_DATA2) == 126


if __name__ == "__main__":
    input_file = Path(__file__).parent / "input"
    data = input_file.read_text()

    print(part1(data))
    print(part2(data))
