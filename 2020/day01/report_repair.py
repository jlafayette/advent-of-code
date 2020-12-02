"""Day 1: Report Repair

Find the two entries that sum to 2020 and then multiply those two numbers
together.

For example, suppose your expense report contained the following:

1721
979
366
299
675
1456

In this list, the two entries that sum to 2020 are 1721 and 299. Multiplying
them together produces 1721 * 299 = 514579, so the correct answer is 514579.

Of course, your expense report is much larger. Find the two entries that sum to
2020; what do you get if you multiply them together?


--- Part Two ---
Using the above example again, the three entries that sum to 2020 are 979, 366,
and 675. Multiplying them together produces the answer, 241861950.

In your expense report, what is the product of the three entries that sum to
2020?

"""
from pathlib import Path
from typing import Optional, List


def main() -> None:
    # read from input and convert to list of integers
    entries = get_entries()

    # find product of entries that sum to 2020
    result2 = product_of_2_entries(entries)
    print(result2)
    result3 = product_of_3_entries(entries)
    print(result3)


def get_entries() -> List[int]:
    input_file = Path(__file__).parent / "input"
    text = input_file.read_text()
    split = text.split()
    entries = [int(entry) for entry in split]
    return entries


def product_of_2_entries(entries: List[int]) -> Optional[int]:
    for index1, entry1 in enumerate(entries):
        for index2, entry2 in enumerate(entries):
            if index1 == index2:
                continue
            if entry1 + entry2 == 2020:
                return entry1 * entry2
    else:
        return None


def product_of_3_entries(entries: List[int]) -> Optional[int]:
    for index1, entry1 in enumerate(entries):
        for index2, entry2 in enumerate(entries):
            for index3, entry3 in enumerate(entries):
                # make sure we aren't comparing the same entry
                if len({index1, index2, index3}) != 3:
                    continue
                if entry1 + entry2 + entry3 == 2020:
                    return entry1 * entry2 * entry3
    else:
        return None


if __name__ == '__main__':
    main()
