from pathlib import Path


TEST_INPUT = """30373
25512
65332
33549
35390"""


def read_input():
    input_file = Path(__file__).absolute().parent / "input"
    data = input_file.read_text()
    # data = TEST_INPUT
    return data.strip().split("\n")


def part1():
    rows = read_input()

    min_x = 0
    max_x = len(rows[0]) - 1
    min_y = 0
    max_y = len(rows) - 1

    visible = 0
    for y, row in enumerate(rows):
        for x, tree in enumerate(row):
            if x == min_x or x == max_x or y == min_y or y == max_y:
                visible += 1
                continue
            left = row[:x]
            right = row[x+1:]
            up = "".join([r[x] for r in rows[:y]])
            down = "".join([r[x] for r in rows[y+1:]])
            # print(f"{x},{y} ({tree}) left={left}, right={right}, up={up}, down={down}")
            if max(left) < tree:
                visible += 1
                continue
            if max(right) < tree:
                visible += 1
                continue
            if max(up) < tree:
                visible += 1
                continue
            if max(down) < tree:
                visible += 1
                continue
    print(visible)


def part2():
    rows = read_input()

    max_score = 0
    for y, row in enumerate(rows):
        for x, tree in enumerate(row):
            left = [t for t in row[:x]]
            left.reverse()
            right = [t for t in row[x + 1:]]
            up = [r[x] for r in rows[:y]]
            up.reverse()
            down = [r[x] for r in rows[y + 1:]]
            scores = [0, 0, 0, 0]
            for i, trees in enumerate([left, right, up, down]):
                for t in trees:
                    scores[i] += 1
                    if t >= tree:
                        break
            score = scores[0] * scores[1] * scores[2] * scores[3]
            max_score = max(max_score, score)
            # print(f"{x},{y} ({tree}) left={left}, right={right}, up={up}, down={down}")
    print(max_score)


part1()
part2()
