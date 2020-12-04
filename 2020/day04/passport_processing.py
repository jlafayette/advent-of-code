import string
from pathlib import Path


def valid_passports(data: str) -> int:
    passports = data.strip().split("\n\n")
    passports = [p.strip() for p in passports]

    valid = 0
    for passport in passports:
        pairs = passport.split()
        fields = [p.split(":")[0] for p in pairs]
        required = {"ecl", "pid", "eyr", "hcl", "byr", "iyr", "hgt"}
        if required.issubset(set(fields)):
            valid += 1

    return valid


def validate_field(field: str, value: str) -> bool:
    try:
        if field == "ecl":
            # ecl (Eye Color) - exactly one of: amb blu brn gry grn hzl oth.
            assert value in {"amb", "blu", "brn", "gry", "grn", "hzl", "oth"}
        elif field == "pid":
            # pid (Passport ID) - a nine-digit number, including leading zeroes.
            assert len(value) == 9
            for digit in value:
                assert digit in string.digits
        elif field == "eyr":
            # eyr (Expiration Year) - four digits; at least 2020 and at most 2030.
            assert 2020 <= int(value) <= 2030
        elif field == "hcl":
            # hcl (Hair Color) - a # followed by exactly six characters 0-9 or a-f.
            assert value.startswith("#")
            assert len(value) == 7  # hcl:#a97842
            for char in value[1:]:
                assert char in string.digits + string.ascii_lowercase[:6]
        elif field == "byr":
            # byr (Birth Year) - four digits; at least 1920 and at most 2002.
            assert 1920 <= int(value) <= 2002
        elif field == "iyr":
            # iyr (Issue Year) - four digits; at least 2010 and at most 2020.
            assert 2010 <= int(value) <= 2020
        elif field == "hgt":
            # hgt (Height) - a number followed by either cm or in:
            # If cm, the number must be at least 150 and at most 193.
            # If in, the number must be at least 59 and at most 76.
            number = int(value.rstrip("incm"))
            if value.endswith("cm"):
                assert 150 <= number <= 193
            elif value.endswith("in"):
                assert 59 <= number <= 76
            else:
                raise AssertionError("Must end in 'in' or 'cm'")
    except (ValueError, AssertionError) as err:
        # print(f"{field}:{value} failed with {err}")
        return False
    else:
        # print(f"{field}:{value} is valid")
        return True


def valid_passports2(data: str) -> int:
    passports = data.strip().split("\n\n")
    passports = [p.strip() for p in passports]

    valid_count = 0
    for passport in passports:
        pairs = passport.split()
        d = {}
        for p in pairs:
            k, v = p.split(":")
            d[k] = v
        required = {"ecl", "pid", "eyr", "hcl", "byr", "iyr", "hgt"}

        valid = True
        if not required.issubset(set(d.keys())):
            valid = False
        for k, v in d.items():
            if not validate_field(k, v):
                valid = False
                break
        if valid:
            valid_count += 1

    return valid_count


PASSPORT_DATA = """ecl:gry pid:860033327 eyr:2020 hcl:#fffffd
byr:1937 iyr:2017 cid:147 hgt:183cm

iyr:2013 ecl:amb cid:350 eyr:2023 pid:028048884
hcl:#cfa07d byr:1929

hcl:#ae17e1 iyr:2013
eyr:2024
ecl:brn pid:760753108 byr:1931
hgt:179cm

hcl:#cfa07d eyr:2025 pid:166559648
iyr:2011 ecl:brn hgt:59in
"""


def test_valid_passports_part1():
    assert valid_passports(PASSPORT_DATA) == 2


VALID_DATA = """pid:087499704 hgt:74in ecl:grn iyr:2012 eyr:2030 byr:1980
hcl:#623a2f

eyr:2029 ecl:blu cid:129 byr:1989
iyr:2014 pid:896056539 hcl:#a97842 hgt:165cm

hcl:#888785
hgt:164cm byr:2001 iyr:2015 cid:88
pid:545766238 ecl:hzl
eyr:2022

iyr:2010 hgt:158cm hcl:#b6652a ecl:blu byr:1944 eyr:2021 pid:093154719"""
INVALID_DATA = """eyr:1972 cid:100
hcl:#18171d ecl:amb hgt:170 pid:186cm iyr:2018 byr:1926

iyr:2019
hcl:#602927 eyr:1967 hgt:170cm
ecl:grn pid:012533040 byr:1946

hcl:dab227 iyr:2012
ecl:brn hgt:182cm pid:021572410 eyr:2020 byr:1992 cid:277

hgt:59cm ecl:zzz
eyr:2038 hcl:74454a iyr:2023
pid:3556412378 byr:2007"""


def test_valid_passports_part2_valid():
    assert valid_passports2(VALID_DATA) == 4


def test_valid_passports_part2_invalid():
    assert valid_passports2(INVALID_DATA) == 0


def main():
    input_file = Path(__file__).parent / "input"
    passport_data = input_file.read_text()

    # part 1   time elapsed 15:20
    print(valid_passports(passport_data))

    # part 2   time elapsed 43:26
    print(valid_passports2(passport_data))


if __name__ == "__main__":
    main()
