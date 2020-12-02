"""Find three entries that sum to 2020 and then multiply those numbers
together.

For example, suppose your expense report contained the following:

1721
979
366
299
675
1456

Using the above example again, the three entries that sum to 2020 are 979, 366,
and 675. Multiplying them together produces the answer, 241861950.

In your expense report, what is the product of the three entries that sum to
2020?

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
            for index3, entry3 in enumerate(entries):
                # make sure we aren't comparing the same entry
                if len(set([index1, index2, index3])) != 3:
                    continue
                if entry1 + entry2 + entry3 == 2020:
                    print(entry1, entry2, entry3)
                    return entry1 * entry2 * entry3
    else:
        return None


if __name__ == '__main__':
    main()
