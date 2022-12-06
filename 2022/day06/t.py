from pathlib import Path


TEST_INPUT = """mjqjpqmgbljsphdztnvjfqwrcgsmlb
"""


class Q:
    def __init__(self, count):
        self.q = []
        self.place = 0
        self.count = count

    def next_letter(self, letter):
        self.place += 1
        if len(self.q) < self.count:
            self.q.append(letter)
            return
        self.q = self.q[1:]
        self.q.append(letter)

    def unique(self) -> bool:
        return len(self.q) == self.count and len(self.q) == len(set(self.q))


def read_input():
    input_file = Path(__file__).absolute().parent / "input"
    data = input_file.read_text()
    # data = TEST_INPUT
    return data.strip()


def part1():
    buffer = read_input()
    q = Q(4)
    for letter in buffer:
        q.next_letter(letter)
        if q.unique():
            break
    print(q.place)


tests = {
    "mjqjpqmgbljsphdztnvjfqwrcgsmlb": 19,
    "bvwbjplbgvbhsrlpgdmjqwftvncz": 23,
    "nppdvjthqldpwncqszvftbrmjlhg": 23,
    "nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg": 29,
    "zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw": 26,
}


def part2():
    for buffer, ans in tests.items():
        q = Q(14)
        for letter in buffer:
            q.next_letter(letter)
            if q.unique():
                break
        assert q.place == ans, f"got {q.place}, expected {ans}"
    buffer = read_input()
    q = Q(14)
    for letter in buffer:
        q.next_letter(letter)
        if q.unique():
            break
    print(q.place)


part1()
part2()
