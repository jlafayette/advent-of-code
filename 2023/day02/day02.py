import re
from pathlib import Path


def read_input():
    input_file = Path(__file__).absolute().parent / "input"
    data = input_file.read_text().strip()
    return data


INPUT = read_input()


DATA = """Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green"""


def part1(data):
    red = 12
    green = 13
    blue = 14

    total = 0
    for game in data.strip().split("\n"):
        if not game:
            continue
        pre, post = game.split(":")
        id = int(pre.split()[-1])
        game_possible = True
        for draw in post.split(";"):
            draw = draw.strip()
            # print(draw)
            draw_possible = True
            for color in draw.split(","):
                count, color = color.strip().split(" ")
                count = int(count)
                color = color.strip()
                # print("  ", count, color)
                possible = True
                if color == "red":
                    possible = count <= red
                elif color == "green":
                    possible = count <= green
                elif color == "blue":
                    possible = count <= blue
                if not possible:
                    draw_possible = False
                    break
            if not draw_possible:
                game_possible = False
                break
        if game_possible:
            total += id
    print(total)


DATA2 = """Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green"""


def part2(data):
    total = 0
    for game in data.strip().split("\n"):
        if not game:
            continue
        min_red = 0
        min_green = 0
        min_blue = 0

        pre, post = game.split(":")
        id = int(pre.split()[-1])

        for draw in post.split(";"):
            draw = draw.strip()
            # print(draw)
            draw_possible = True
            for color in draw.split(","):
                count, color = color.strip().split(" ")
                count = int(count)
                color = color.strip()
                # print("  ", count, color)

                if color == "red":
                    min_red = max(min_red, count)
                elif color == "green":
                    min_green = max(min_green, count)
                elif color == "blue":
                    min_blue = max(min_blue, count)
        pow = min_red * min_green * min_blue
        total += pow
    print(total)


part1(DATA)
part1(INPUT)
part2(DATA2)
part2(INPUT)
