import dataclasses
import queue
from pathlib import Path
from queue import LifoQueue


# Test Input
TEST_INPUT = """    [D]    
[N] [C]    
[Z] [M] [P]
 1   2   3 

move 1 from 2 to 1
move 3 from 1 to 3
move 2 from 2 to 1
move 1 from 1 to 2
"""


@dataclasses.dataclass()
class Mv:
    src: int
    dst: int
    count: int


def read_input():
    input_file = Path(__file__).absolute().parent / "input"
    data = input_file.read_text()
    # data = TEST_INPUT
    cargo_text, move_text = data.rstrip().split("\n\n")  # no lstrip! leading space is important

    # stacks of cargo (store as LIFO queues)
    cargo_lines = cargo_text.split("\n")
    cols = cargo_lines[-1]
    count = int(cols.split()[-1])
    qs = []
    for _ in range(count):
        qs.append(queue.LifoQueue())
    cargo_lines = cargo_lines[:-1]
    cargo_lines = reversed(cargo_lines)  # need to add bottom to qs first
    for line in cargo_lines:
        # [Z] [M] [P]
        #  1   5   9
        # 0*4+1, 1*4+1, 2*4+1
        for i in range(count):
            index = (i*4) + 1
            try:
                letter = line[index]
            except Exception as err:
                breakpoint()
                raise
            if letter != " ":
                qs[i].put(letter)

    # move instructions
    mvs = []
    move_lines = move_text.strip().split("\n")
    move_lines = [x.strip() for x in move_lines if x.strip()]
    for line in move_lines:
        # move 2 from 2 to 1
        try:
            a, b = line.split(" from ")
        except Exception as err:
            breakpoint()
            raise
        _, count = a.split()
        src, dst = b.split(" to ")
        # -1 to get index in qs
        mvs.append(Mv(int(src) - 1, int(dst) - 1, int(count)))

    return qs, mvs


def part1():
    qs, mvs = read_input()
    # CMZ (test input)
    for mv in mvs:
        for _ in range(mv.count):
            qs[mv.dst].put(qs[mv.src].get())
    result = ""
    for q in qs:
        result += q.get()
    print(result)


def part2():
    qs, mvs = read_input()
    # MCD (move multiple at once!)
    for mv in mvs:
        crates = []
        for _ in range(mv.count):
            crates.append(qs[mv.src].get())
        crates = reversed(crates)
        for crate in crates:
            qs[mv.dst].put(crate)
    result = ""
    for q in qs:
        result += q.get()
    print(result)


part1()
part2()
