"""Day 23: Crab Cups

https://adventofcode.com/2020/day/23

"""
import logging
from typing import List, Optional


logger = logging.getLogger(__name__)


# -- part 1


class Cup:
    def __init__(self, number: int, next: Optional["Cup"] = None, prev: Optional["Cup"] = None):
        self.number = number
        self.next: Optional[Cup] = next
        self.prev: Optional[Cup] = prev

    def __str__(self):
        if self.prev:
            p = str(self.prev.number)
        else:
            p = "."
        if self.next:
            n = str(self.next.number)
        else:
            n = "."
        return p + "<-" + str(self.number) + "->" + n


class Cups:
    def __init__(self, numbers: List[int]):
        self.lowest = min(numbers)
        self.highest = max(numbers)

        self.current = Cup(numbers[0])
        head = self.current
        tail = self.current
        self.lookup = {numbers[0]: head}
        for n in numbers[1:]:
            cup = Cup(n)
            cup.prev = tail
            tail.next = cup
            tail = cup
            self.lookup[n] = cup
        # close the loop
        tail.next = head
        head.prev = tail

        self.pickup_cup1 = None
        self.dest = None

        self.orig_head = head

    def pickup(self):
        # detach the 3 pickup nodes from the loop
        self.pickup_cup1 = self.current.next

        self.current.next = self.pickup_cup1.next.next.next
        self.pickup_cup1.next.next.next.prev = self.current

        self.pickup_cup1.prev = None
        self.pickup_cup1.next.next.next = None

    def calculate_dest(self):
        dest = self.current.number - 1
        if dest < self.lowest:
            dest = self.highest
        while (
            dest == self.pickup_cup1.number or
            dest == self.pickup_cup1.next.number or
            dest == self.pickup_cup1.next.next.number
        ):
            dest -= 1
            if dest < self.lowest:
                dest = self.highest
        self.dest = self.lookup[dest]

    def insert_pickup(self):
        # swap so that the pickup are immediately after the dest cup


        cup_after = self.dest.next
        self.pickup_cup1.prev = self.dest
        self.pickup_cup1.next.next.next = cup_after
        self.dest.next = self.pickup_cup1
        cup_after.prev = self.pickup_cup1.next.next

        #     8, 9, 1
        #              2
        # (3) 8  9  1  2  5  4  6  7
        #  3 (2) 8  9  1  5  4  6  7

        # >7                    3, 6,
        #           8
        #  7  2  5  8  4  1 (9) 3  6
        #  8  3  6  7  4  1  9 (2) 5

    def new_current_cup(self):
        self.current = self.current.next

    def answer(self):
        start = self.lookup[1]

        cup = start.next
        s = ""
        while cup is not start:
            s = s + str(cup.number)
            cup = cup.next
        return s

    def __iter__(self):
        cup = self.orig_head
        while cup is not self.orig_head.prev:
            yield cup
            cup = cup.next

    def numbers_str(self, start_number=None):
        start_number = start_number or self.orig_head.number
        s = ""
        cup = self.lookup[start_number]
        while True:
            if cup is self.current:
                s = s + "(" + str(cup.number) + ")"
            else:
                s = s + " " + str(cup.number) + " "
            cup = cup.next
            assert cup is not None
            if cup is self.lookup[start_number]:
                break
        return s

    def __str__(self):
        s = self.numbers_str()
        ps = ", ".join([
            str(n) for n in [
                self.pickup_cup1.number,
                self.pickup_cup1.next.number,
                self.pickup_cup1.next.next.number]])
        return f"""cups: {s}
pick up: {ps}
destination: {self.dest.number}
"""


def test_insert_pickup1():
    cups = Cups([3, 8, 9, 1, 2, 5, 4, 6, 7])
    print()
    print(cups.numbers_str())
    cups.current = cups.lookup[3]
    cups.pickup()
    cups.calculate_dest()
    cups.insert_pickup()
    cups.new_current_cup()
    print(cups.numbers_str())
    assert cups.numbers_str(3) == " 3 (2) 8  9  1  5  4  6  7 "


def test_insert_pickup2():
    # >7                    3, 6,
    #           8
    #  7  2  5  8  4  1 (9) 3  6
    #  8  3  6  7  4  1  9 (2) 5
    cups = Cups([7, 2, 5, 8, 4, 1, 9, 3, 6])
    print()
    print(cups.numbers_str())
    cups.current = cups.lookup[9]
    cups.pickup()
    cups.calculate_dest()
    cups.insert_pickup()
    cups.new_current_cup()
    print(cups.numbers_str())
    assert cups.numbers_str(8) == " 8  3  6  7  4  1  9 (2) 5 "


class Game:
    def __init__(self, cups: List[int]):
        self.cups = Cups(cups)
        self.move_number = 0

    def move(self):
        self.move_number += 1
        # logger.debug(f"-- move {self.move_number} --")

        # pickup 3 cups cw of the current cup
        self.cups.pickup()

        # crab selects a destination cup
        self.cups.calculate_dest()

        # placed picked up cups after the destination cup
        self.cups.insert_pickup()

        # logger.debug(str(self.cups))

        # Calculate new current cup
        self.cups.new_current_cup()


TEST_DATA = "389125467"
AFTER_10 = "92658374"
AFTER_100 = "67384529"


def test_10_moves():
    game = Game([int(n) for n in TEST_DATA])
    for _ in range(10):
        game.move()
    assert game.cups.answer() == AFTER_10


def test_100_moves():
    game = Game([int(n) for n in TEST_DATA])
    for _ in range(100):
        game.move()
    assert game.cups.answer() == AFTER_100


def part1(data: str):
    game = Game([int(n) for n in data])
    for _ in range(100):
        game.move()
    return game.cups.answer()


# -- part 2


def part2(data: str):
    starting_numbers = [int(n) for n in data]
    other_numbers = list(range(max(starting_numbers) + 1, 1000001))
    cups = starting_numbers + other_numbers
    game = Game(cups)
    for _ in range(10000000):
        game.move()
    cup1 = game.cups.lookup[1]
    return cup1.next.number * cup1.next.next.number


def main():
    data = "792845136"

    print(part1(data))  # 98742365
    print(part2(data))  # 294320513093


if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG, format="%(message)s")
    main()
