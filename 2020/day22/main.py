"""Day 22: Crab Combat

https://adventofcode.com/2020/day/22

"""
import logging
from collections import deque
from pathlib import Path
from typing import List


logger = logging.getLogger(__name__)


# -- part 1


TEST_DATA = """Player 1:
9
2
6
3
1

Player 2:
5
8
4
7
10"""


class OutOfCardsError(IndexError):
    pass


class Player:
    def __init__(self, name: str, cards: List[int]):
        self.name = name
        self.q = deque(cards)

    @property
    def card_count(self) -> int:
        return len(self.q)

    def draw(self) -> int:
        try:
            return self.q.popleft()
        except IndexError:
            raise OutOfCardsError(f"{self.name} is out of cards!")

    def take_round(self, winner_card: int, loser_card: int):
        self.q.append(winner_card)
        self.q.append(loser_card)

    def sub_game_copy(self, new_deck_size) -> "Player":
        """Make a copy to engage in a sub-game of recursive combat."""
        return Player(self.name, list(self.q)[:new_deck_size])

    def __str__(self):
        return f"{self.name}'s deck: {list(self.q)}"


class GameOverError(Exception):
    pass


class Game:
    def __init__(self, player1, player2):
        self.p1 = player1
        self.p2 = player2
        self.round = 0

    def play_round(self):
        self.round += 1
        logger.debug(f"-- Round {self.round} --")
        logger.debug(str(self.p1))
        logger.debug(str(self.p2))
        try:
            p1_card = self.p1.draw()
            logger.debug(f"{self.p1.name} plays: {p1_card}")
            p2_card = self.p2.draw()
            logger.debug(f"{self.p2.name} plays: {p2_card}")
        except OutOfCardsError as err:
            logger.debug(err)
            raise GameOverError
        if p1_card > p2_card:
            winner = self.p1
            winner_card = p1_card
            loser_card = p2_card
        else:
            winner = self.p2
            winner_card = p2_card
            loser_card = p1_card
        logger.debug(f"{winner.name} wins the round!\n")
        winner.take_round(winner_card, loser_card)
        if self.p1.card_count == 0 or self.p2.card_count == 0:
            raise GameOverError

    def play(self):
        while True:
            try:
                self.play_round()
            except GameOverError:
                return

    def winning_score(self):
        if self.p1.card_count == 0:
            winner = self.p2
        elif self.p2.card_count == 0:
            winner = self.p1
        else:
            raise RuntimeError("Game is not over!")
        logger.debug("== Post-game results ==")
        logger.debug(str(self.p1))
        logger.debug(str(self.p2))

        multiplier = 1
        score = 0
        try:
            while True:
                score += multiplier * winner.q.pop()
                multiplier += 1
        except IndexError:
            return score


def parse(data: str, cls=Game):
    d1, d2 = data.strip().split("\n\n")

    def player_from_data(player_data: str) -> Player:
        lines = player_data.split("\n")
        name = lines[0].rstrip(":")
        cards = [int(n) for n in lines[1:]]
        return Player(name, cards)

    return cls(player_from_data(d1), player_from_data(d2))


def test_part1():
    assert part1(TEST_DATA) == 306


def part1(data: str) -> int:
    logger.setLevel(logging.DEBUG)
    game = parse(data)
    game.play()
    return game.winning_score()


# -- part 2


game_number = 0


class Game2(Game):
    def __init__(self, p1: Player, p2: Player):
        super(Game2, self).__init__(p1, p2)
        self.previous_rounds = set()
        self.winner = None

        global game_number
        game_number += 1
        self.game_number = game_number

    def play_round(self):
        self.round += 1
        logger.debug(f"-- Round {self.round} (Game {self.game_number}) --")

        # check if the current cards match a previous round
        # if they do, then player 1 wins the game
        current_round = tuple(self.p1.q), tuple(self.p2.q)
        if current_round in self.previous_rounds:
            logger.debug(f"Round matches a previous round, {self.p1.name} wins!")
            self.winner = self.p1
            raise GameOverError
        self.previous_rounds.add(current_round)

        logger.debug(str(self.p1))
        logger.debug(str(self.p2))

        # draw cards
        p1_card = self.p1.draw()
        logger.debug(f"{self.p1.name} plays: {p1_card}")
        p2_card = self.p2.draw()
        logger.debug(f"{self.p2.name} plays: {p2_card}")

        # If both players have at least as many cards as the value of the
        # card they drew, then solve the round with a recursive game.
        if self.p1.card_count >= p1_card and self.p2.card_count >= p2_card:
            result_lookup = {
                self.p1.name: (self.p1, p1_card, p2_card),
                self.p2.name: (self.p2, p2_card, p1_card),
            }
            sub_game = Game2(self.p1.sub_game_copy(p1_card), self.p2.sub_game_copy(p2_card))
            logger.debug("Playing a sub-game to determine the winner...")
            sub_game.play()
            logger.debug(f"\n...anyway, back to game {self.game_number}.")
            winner, winner_card, loser_card = result_lookup[sub_game.winner.name]
        else:
            if p1_card > p2_card:
                winner = self.p1
                winner_card = p1_card
                loser_card = p2_card
            else:
                winner = self.p2
                winner_card = p2_card
                loser_card = p1_card

        logger.debug(f"{winner.name} wins round {self.round} of game {self.game_number}!\n")
        winner.take_round(winner_card, loser_card)

        if self.p1.card_count == 0:
            self.winner = self.p2

        elif self.p2.card_count == 0:
            self.winner = self.p1

        if self.winner:
            logger.debug(f"The winner of game {self.game_number} is {self.winner.name.lower()}!")
            raise GameOverError

    def play(self):
        logger.debug(f"\n=== Game {self.game_number} ===\n")
        while True:
            try:
                self.play_round()
            except GameOverError:
                return


def part2(data: str):

    # debug logging is a bit much for this one...
    logger.setLevel(logging.WARN)

    game = parse(data, cls=Game2)
    game.play()
    return game.winning_score()


def main():
    input_file = Path(__file__).parent / "input"
    data = input_file.read_text()

    print(part1(data))  # 35818
    print(part2(data))  # 34771


if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG, format="%(message)s")
    main()
