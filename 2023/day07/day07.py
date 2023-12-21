import dataclasses
from pathlib import Path
from collections import Counter


INPUT = (Path(__file__).absolute().parent / "input").read_text().strip()


DATA = """\
32T3K 765
T55J5 684
KK677 28
KTJJT 220
QQQJA 483\
"""


part = 1


@dataclasses.dataclass
class Card:
    label: str
    strength: int

    @classmethod
    def from_str(cls, label: str) -> "Card":
        """A, K, Q, J, T, 9, 8, 7, 6, 5, 4, 3, or 2"""
        if part == 1:
            labels = "AKQJT98765432"
            scores = [14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2]
        else:
            labels = "AKQT98765432J"
            scores = [14, 13, 12, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
        for l, s in zip(labels, scores):
            if label == l:
                strength = s
                break
        else:
            raise ValueError(f"Bad label: {label!r}")

        return cls(
            label=label,
            strength=strength,
        )


@dataclasses.dataclass
class Hand:
    orig_str: str
    cards: list[Card]
    bid: int
    strength: tuple[int, tuple[int, int, int, int, int]]

    @classmethod
    def from_str(cls, s: str) -> "Hand":
        cards_str, bid_str = s.strip().split()

        cards = [Card.from_str(c) for c in cards_str]
        card_strengths = [card.strength for card in cards]  # before sorting
        cards.sort(key=lambda x: x.strength, reverse=True)

        labels = [card.label for card in cards]
        if part == 2:
            labels1 = labels

            labels = []
            for label in labels1:
                if label == "J":
                    labels.extend([x for x in "AKQJT98765432"])
                else:
                    labels.append(label)

        c = Counter(labels)
        print(c)
        frequencies = sorted(list(c.values()), reverse=True)
        first = frequencies[0]
        if len(frequencies) > 1:
            second = frequencies[1]
        else:
            second = 0
        print(first, second)

        # Five of a kind
        # Four of a kind
        # Full house
        # Three of a kind
        # Two pair
        # One pair
        # High card

        if first == 5:
            type_ = 6
        elif first == 4:
            type_ = 5
        elif first == 3 and second == 2:
            type_ = 4
        elif first == 3:
            type_ = 3
        elif first == 2 and second == 2:
            type_ = 2
        elif first == 2:
            type_ = 1
        else:
            type_ = 0

        return cls(cards_str, cards, int(bid_str), (type_, tuple(card_strengths)))


def parse(data) -> list[Hand]:
    lines = data.split("\n")
    return [Hand.from_str(line.strip()) for line in lines if line.strip()]


def part1(data):
    global part
    part = 1

    hands = parse(data)
    for hand in hands:
        print([c.label for c in hand.cards], hand.bid, hand.strength)
    print()
    sorted_hands = sorted(hands, key=lambda x: x.strength)
    for hand in sorted_hands:
        print([c.label for c in hand.cards], hand.orig_str, hand.bid, hand.strength)
    print()
    winnings = 0
    for i, hand in enumerate(sorted_hands):
        rank = i + 1
        print(hand.orig_str, rank, hand.bid)
        winnings += hand.bid * rank
    print("Winnings:", winnings)


DATA2 = """\
32T3K 765
T55J5 684
KK677 28
KTJJT 220
QQQJA 483\
"""


def part2(data):
    global part
    part = 2

    hands = parse(data)
    for hand in hands:
        print([c.label for c in hand.cards], hand.orig_str, hand.bid, hand.strength)
    print()
    sorted_hands = sorted(hands, key=lambda x: x.strength)
    for hand in sorted_hands:
        print([c.label for c in hand.cards], hand.orig_str, hand.bid, hand.strength)
    print()
    winnings = 0
    for i, hand in enumerate(sorted_hands):
        rank = i + 1
        print(hand.orig_str, rank, hand.bid)
        winnings += hand.bid * rank
    print("Winnings:", winnings)


part1(DATA)   # 6440
# part1(INPUT)
part2(DATA2)  # 5905
# part2(INPUT)  # 248439515 is too low
              # 248439515
