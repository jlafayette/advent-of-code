import timeit
from report_repair import product_of_entries, get_entries


def main():
    setup = "from __main__ import product_of_entries, get_entries; entries = get_entries()"
    print(timeit.timeit("product_of_entries(entries, 3)", setup=setup, number=5))


if __name__ == "__main__":
    main()
