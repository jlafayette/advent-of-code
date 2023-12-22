import dataclasses
import os
import sys
from pathlib import Path


INPUT = (Path(__file__).absolute().parent / "input").read_text().strip()


DATA = """\
RL

AAA = (BBB, CCC)
BBB = (DDD, EEE)
CCC = (ZZZ, GGG)
DDD = (DDD, DDD)
EEE = (EEE, EEE)
GGG = (GGG, GGG)
ZZZ = (ZZZ, ZZZ)\
"""


DATA2 = """\
LLR

AAA = (BBB, BBB)
BBB = (AAA, ZZZ)
ZZZ = (ZZZ, ZZZ)\
"""


@dataclasses.dataclass
class Node:
    tag: str
    lf_tag: str
    rt_tag: str
    lf: "Node"
    rt: "Node"

    @classmethod
    def from_line(cls, line: str) -> "Node":
        tag, rest = line.strip().split(" = ")
        tag = tag.strip()
        lf_tag, rt_tag = rest.strip(" ()\n\r").split(", ")
        lf_tag = lf_tag.strip()
        rt_tag = rt_tag.strip()
        return cls(tag, lf_tag, rt_tag, None, None)


def parse(data: str) -> tuple[str, dict[str, Node]]:
    dirs, nodes_str = data.strip().split("\n\n")
    lines = nodes_str.strip().split("\n")

    node_lookup: dict[str, Node] = {}

    for line in lines:
        node = Node.from_line(line)
        node_lookup[node.tag] = node

    for tag, node in node_lookup.items():
        node.lf = node_lookup[node.lf_tag]
        node.rt = node_lookup[node.rt_tag]

    return dirs, node_lookup


def part1(data):
    dirs, node_lookup = parse(data)
    start = node_lookup["AAA"]
    end = node_lookup["ZZZ"]
    print(dirs)
    c = start
    steps = 0
    while True:
        for d in dirs:
            if d == "L":
                c = c.lf
                steps += 1
            elif d == "R":
                c = c.rt
                steps += 1
        if c == end:
            break
    print("Step:", steps)


DATA3 = """\
LR

11A = (11B, XXX)
11B = (XXX, 11Z)
11Z = (11B, XXX)
22A = (22B, XXX)
22B = (22C, 22C)
22C = (22Z, 22Z)
22Z = (22B, 22B)
XXX = (XXX, XXX)\
"""


def part2(data):
    dirs, lookup = parse(data)

    starting_nodes = [
        node for node in lookup.values() if node.tag.endswith("A")
    ]
    ending_node_tags = {
        node.tag for node in lookup.values() if node.tag.endswith("Z")
    }

    cn = starting_nodes
    steps = 0
    progress_counter = 0
    while True:
        for d in dirs:
            if d == "L":
                for i, c in enumerate(cn):
                    cn[i] = c.lf
            elif d == "R":
                for i, c in enumerate(cn):
                    cn[i] = c.rt
            else:
                raise ValueError(f"Invalid instruction: {d}")
            steps += 1
            progress_counter += 1
        all_z = True
        for c in cn:
            if c.tag not in ending_node_tags:
                all_z = False
                break
        if all_z:
            break
        if progress_counter > 10_000:
            print(".", end="", flush=True)
            progress_counter = 0

    print("Steps:", steps)


def experiment(data):
    dirs, lookup = parse(data)

    starting_nodes = [
        node for node in lookup.values() if node.tag.endswith("A")
    ]
    acc = []

    for starting_node in starting_nodes:

        def f():
            c = starting_node
            prev = set()
            steps = 0
            print(starting_node.tag)
            zzzs = 0
            zzzs_step = []
            cycle_found = False
            while True:
                for i, d in enumerate(dirs):
                    id_ = i, c.tag
                    if c.tag.endswith("Z"):
                        print(f"  Z at step {steps}, {id_}")
                        zzzs += 1
                        zzzs_step.append(steps)
                    if zzzs >= 3:
                        a, b, c = zzzs_step
                        print("  ", c - b, b - a)
                        acc.append(c - b)
                        return
                    if not cycle_found and id_ in prev:
                        print("  found cycle",  id_, "steps:", steps)
                        cycle_found = True
                    prev.add(id_)
                    if d == "L":
                        c = c.lf
                    elif d == "R":
                        c = c.rt
                    else:
                        sys.exit(1)
                    steps += 1

        f()

    print(acc)
    import math
    print(math.lcm(*acc))


# part1(DATA)
# part1(DATA2)
# part1(INPUT)
# part2(DATA3)
# part2(INPUT)  # probably won't complete in my lifetime :(
experiment(DATA3)
experiment(INPUT)
