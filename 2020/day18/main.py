"""Day 18: Operation Order

https://adventofcode.com/2020/day/18

"""
import re
import operator
import string
from pathlib import Path

import pytest


@pytest.mark.parametrize("expression,expected", [
    ("2 * 3 + (4 * 5)", 26),
    ("5 + (8 * 3 + 9 + 3 * 4 * 3)", 437),
    ("5 * 9 * (7 * 3 * 3 + 9 * 3 + (8 + 6 * 4))", 12240),
    ("((2 + 4 * 9) * (6 + 9 * 8 + 6) + 6) + 2 + 4 * 2", 13632),
])
def test_eval_expression(expression, expected):
    # assert eval_expression(expression) == expected
    print()
    print(expression)
    print('-->', eval_expression(expression), '<--')


def in_parens(s):
    open_ = 1
    acc = ""
    for i, c in enumerate(s):
        acc += c
        if c == "(":
            open_ += 1
        elif c == ")":
            open_ -= 1
        if open_ <= 0:
            if acc.endswith(")"):
                acc = acc[:-1]
            return acc, s[i+1:]
    raise RuntimeError("no closing parens found")


def str_op(op):
    if op == operator.mul:
        return "*"
    elif op == operator.add:
        return "+"
    else:
        return ""


def log(msg, verbose):
    if verbose:
        print(msg)


def eval_expression(expression: str, lvl=0, verbose=False) -> int:
    indent = " "*(lvl*2)
    log(f"{indent}eval: {expression!r}", verbose)
    num = None
    op = None

    acc = None

    exp = expression
    while exp:
        c = exp[0]
        exp = exp[1:]

        if c in string.digits:
            num = int(c)
        elif c == " ":
            pass
        elif c == "(":
            enclosed, exp = in_parens(exp)
            num = eval_expression(enclosed, lvl=lvl+1)
            # acc = op(acc, eval_expression(enclosed))
        elif c == ")":
            raise RuntimeError("should not hit ')'")
        elif c == "+":
            op = operator.add
        elif c == "*":
            op = operator.mul
        else:
            raise RuntimeError(f"unidentified {c!r}")

        if num and (acc is None):
            acc = num
            num = None

        if num and op:
            log(f"{indent}{str_op(op)} to acc ({acc} {str_op(op)} {num})", verbose)
            acc = op(acc, num)
            num = None
            op = None

        log(f"{indent}acc={acc},num={num}", verbose)

    return acc


def part1(data: str):
    return sum([eval_expression(exp) for exp in data.strip().split("\n")])


# -- part2


@pytest.mark.parametrize("expression,expected", [
    ("1 + (2 * 3) + (4 * (5 + 6))", 51),
    ("2 * 3 + (4 * 5)", 46),
    ("5 + (8 * 3 + 9 + 3 * 4 * 3)", 1445),
    ("5 * 9 * (7 * 3 * 3 + 9 * 3 + (8 + 6 * 4))", 669060),
    ("((2 + 4 * 9) * (6 + 9 * 8 + 6) + 6) + 2 + 4 * 2", 23340),
    # """
    # ((2 + 4 * 9) * (6 + 9 * 8 + 6) + 6) + 2 + 4 * 2
    # ((    6 * 9) * (   15 *    14) + 6) +     6 * 2
    # ((       54) * (          210) + 6) +     6 * 2
    # (        54  *            210  + 6) +     6 * 2
    # (                            11664) +     6 * 2
    #                              11664  +     6 * 2
    #                              11670          * 2
    #                                           23340
    #
    # """
])
def test_eval_expression2(expression, expected):
    actual = eval_expression2(expression)
    print()
    print(expression)
    print('-->', actual, '<--')
    assert actual == expected


def eval_expression2(expression: str, lvl=0, verbose=False) -> int:
    indent = " "*(lvl*2)
    log(f"{indent}eval: {expression!r}", verbose)

    # solve parenthesis first

    exp = expression
    exp2 = ""
    while exp:
        c = exp[0]
        exp = exp[1:]
        if c == "(":
            enclosed, exp = in_parens(exp)
            exp2 += str(eval_expression2(enclosed, lvl=lvl+1, verbose=verbose))
        else:
            exp2 += c
    log(f"{indent}no parens: {exp2}", verbose)

    # ---- solve addition first

    def replace(matchobj):
        return str(eval(matchobj.group(0)))

    add_pattern = re.compile(r'(\d+ \+ \d+)')

    def replacer(s, pattern):
        s1 = s
        while True:
            s2 = pattern.sub(replace, s1)
            if s1 == s2:
                break
            else:
                s1 = s2
        s = s2
        # print(s)
        return s

    def add_replacer(s):
        return replacer(s, add_pattern)

    exp3 = add_replacer(exp2)
    log(f"{indent}no add: {exp3}", verbose)

    # -- handle multiply with eval

    exp4 = eval(exp3)
    log(f"{indent}final: {exp4}", verbose)
    return exp4


def part2(data: str):
    return sum([eval_expression2(exp) for exp in data.strip().split("\n")])


def main():
    input_file = Path(__file__).parent / "input"
    data = input_file.read_text()

    print(part1(data))
    print(part2(data))


if __name__ == "__main__":
    main()
