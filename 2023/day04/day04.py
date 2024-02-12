import time
from pathlib import Path


def read_input():
    input_file = Path(__file__).absolute().parent / "input"
    data = input_file.read_text().strip()
    return data


start_time = time.perf_counter()
INPUT = read_input()
read_time = time.perf_counter() - start_time


DATA = """Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11"""


def part1(data):
    total = 0
    for line in data.split("\n"):
        # print(line)
        winning_nums, your_nums = line.split(": ")[-1].split("|")
        winning_nums = {int(n.strip()) for n in winning_nums.strip().split(" ") if n.strip()}
        # print("  ", winning_nums)
        your_nums = {int(n.strip()) for n in your_nums.strip().split(" ") if n.strip()}
        # print("  ", your_nums)
        overlap = len(winning_nums.intersection(your_nums))
        # print("  ", overlap)
        score = pow(2, overlap)
        if score == 1:
            score = 0
        else:
            score = score // 2
        # print("  ", score)
        total += score
    print("Total:", total)


DATA2 = """\
Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11\
"""

from dataclasses import dataclass


@dataclass
class Card:
    number: int
    score: int


def parse(line: str) -> Card:
    card_str, numbers_str = line.split(": ")
    *_, n_str = card_str.split(" ")
    card_number = int(n_str.strip())
    winning_nums, your_nums = numbers_str.split("|")
    winning_nums = {int(n.strip()) for n in winning_nums.strip().split(" ") if n.strip()}
    your_nums = {int(n.strip()) for n in your_nums.strip().split(" ") if n.strip()}
    overlap = len(winning_nums.intersection(your_nums))
    score = overlap
    return Card(card_number, score)


def calculate_new_cards(card: Card, cards: list[Card]) -> int:
    new_cards = cards[card.number:card.number + card.score]
    # print(f"{card.number} -> {len(new_cards)}")
    total = len(new_cards)
    for c in new_cards:
        total += calculate_new_cards(c, cards)
    return total


def part2(data):
    total = 0

    cards = [parse(line) for line in data.split("\n")]

    for card in cards:
        # print(card)
        total += 1
        total += calculate_new_cards(card, cards)

    print("Total:", total)


part1(DATA)
part1(INPUT)
part2(DATA2)
part2(INPUT)
total_elapsed = time.perf_counter() - start_time
print(f" read: {read_time*1000:.4f} ms")
print(f"total: {total_elapsed*1000:.4f} ms")
