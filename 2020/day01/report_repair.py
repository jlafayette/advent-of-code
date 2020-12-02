"""Find the two entries that sum to 2020 and then multiply those two numbers
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
"""
from pathlib import Path
from typing import Optional, List


def main() -> None:
    # read from input and convert to list of integers
    input_file = Path(__file__).parent / "report_repair_input"
    text = input_file.read_text()
    split = text.split()
    entries = [int(entry) for entry in split]

    # find product of entries that sum to 2020
    result = product_of_entries(entries)

    # print result
    print(result)


def product_of_entries(entries: List[int]) -> Optional[int]:
    for index1, entry1 in enumerate(entries):
        for index2, entry2 in enumerate(entries):
            if index1 == index2:
                continue
            if entry1 + entry2 == 2020:
                return entry1 * entry2
    else:
        return None


if __name__ == '__main__':
    main()
