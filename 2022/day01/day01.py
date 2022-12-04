from pathlib import Path


def read_input():
    input_file = Path(__file__).absolute().parent / "input"
    data = input_file.read_text()
    return data


def part1():
    data = read_input()
    print(
        max([
            sum([int(f) for f in foods.split()])
            for foods in data.strip().split("\n\n")
        ])
    )


def part2():
    data = read_input()
    caleries_per_elf = [
        sum([int(f) for f in foods.split()])
        for foods in data.strip().split("\n\n")
    ]
    caleries_per_elf.sort(reverse=True)
    a, b, c, *_ = caleries_per_elf
    print(sum([a, b, c]))


part1()
part2()
