import re
import time
from pathlib import Path


def read_input():
    input_file = Path(__file__).absolute().parent / "input"
    data = input_file.read_text().strip()
    return data


start = time.perf_counter()
INPUT = read_input()
read_input_elapsed = time.perf_counter() - start
print(f"read: {read_input_elapsed*1000:.4f} ms")


DATA = """467..114..
...*......
..35..633.
......#...
617*......
.....+.58.
..592.....
......755.
...$.*....
.664.598.."""


def part1(data):
    total = 0
    lines = data.strip().split()
    for i, line in enumerate(lines):
        # print(i)
        if i == 0:
            prev = "." * len(line)
        else:
            prev = lines[i-1]
        if i == len(lines)-1:
            next = "." * len(line)
        else:
            next = lines[i+1]
        # print("prev:", prev)
        # print("line:", line)
        # print("next:", next)

        for m in re.finditer(r"(\d+)", line):
            # print(m)
            part_num = int(m.group(0))
            # print(int(m.group(0)))
            start, end = m.span()
            # print(part_num, "->", start, end)
            seg_prev = prev[max(0,start-1):min(end+1, len(prev))]
            seg_curr = line[max(0,start-1):min(end+1, len(line))]
            seg_next = next[max(0,start-1):min(end+1, len(next))]
            # print()
            # print("  ", seg_prev)
            # print("  ", seg_curr)
            # print("  ", seg_next)
            # print()
            for char in seg_prev + seg_curr + seg_next:
                if char.isdigit():
                    continue
                if char == ".":
                    continue
                else:
                    total += part_num
                    break
    print("Sum:", total)



DATA2 = """467..114..
...*......
..35..633.
......#...
617*......
.....+.58.
..592.....
......755.
...$.*....
.664.598.."""


def part2(data):
    total = 0
    lines = data.strip().split()
    for i, line in enumerate(lines):
        if i == 0:
            prev = "." * len(line)
        else:
            prev = lines[i - 1]
        if i == len(lines) - 1:
            next = "." * len(line)
        else:
            next = lines[i + 1]
        y = i
        for x, char in enumerate(line):
            if char != "*":
                continue
            # print(f"found * at {x},{y}")

            adjacent = []

            for m in re.finditer(r"(\d+)", prev):
                # print("prev:")
                part_num = int(m.group(0))
                start, end = m.span()
                # print("  ", part_num, start, end, x)
                if x >= start-1 and x <= end:
                    # print("==", part_num)
                    adjacent.append(part_num)
            for m in re.finditer(r"(\d+)", line):
                part_num = int(m.group(0))
                start, end = m.span()
                if x == start-1 or x == end:
                    # print("curr:", part_num)
                    adjacent.append(part_num)
            for m in re.finditer(r"(\d+)", next):
                # print("next:")
                part_num = int(m.group(0))
                start, end = m.span()

                # print("  ", part_num, start, end, x)
                if x >= start-1 and x <= end:
                    # print("==", part_num)
                    adjacent.append(part_num)

            # print("adj:", adjacent)
            if len(adjacent) == 2:
                ratio = adjacent[0] * adjacent[1]
                total += ratio

    print("Sum:", total)


part1(DATA)
part1(INPUT)
part2(DATA2)
part2(INPUT)
end = time.perf_counter()
elapsed = end - start
print(f"Took {elapsed*1000:.4f} ms")

