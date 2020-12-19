"""Day 18: Operation Order

https://adventofcode.com/2020/day/18

"""
import re
import sys
import logging
from pathlib import Path

import pytest


logger = logging.getLogger(__name__)


@pytest.mark.parametrize("expression,expected", [
    ("2 * 3 + (4 * 5)", 26),
    ("5 + (8 * 3 + 9 + 3 * 4 * 3)", 437),
    ("5 * 9 * (7 * 3 * 3 + 9 * 3 + (8 + 6 * 4))", 12240),
    ("((2 + 4 * 9) * (6 + 9 * 8 + 6) + 6) + 2 + 4 * 2", 13632),
])
def test_eval_expression(expression, expected):
    actual = eval_expression(expression)
    logger.debug("")
    logger.debug(expression)
    logger.debug('-->', actual, '<--')
    assert actual == expected


def in_parens(s: str) -> (str, str):
    """Scan forward in string to find closing parenthesis.

    Returns:
        Tuple:
            part of expression enclosed in parens
            remainder of expression after the closing parens

    """

    # This function will be invoked after finding the first opening parens,
    # so the counter starts at 1
    open_ = 1

    enclosed = ""
    for i, c in enumerate(s):
        enclosed += c
        if c == "(":
            open_ += 1
        elif c == ")":
            open_ -= 1
        if open_ <= 0:
            if enclosed.endswith(")"):
                enclosed = enclosed[:-1]
            return enclosed, s[i+1:]
    raise RuntimeError("No closing parens found")


def eval_expression(expression: str, lvl=0) -> int:
    indent = " "*(lvl*2)
    logger.debug(f"{indent}eval: {expression!r}")

    # -- solve parens first
    exp = expression
    exp2 = ""
    while exp:
        c = exp[0]
        exp = exp[1:]
        if c == "(":
            enclosed, exp = in_parens(exp)
            result = eval_expression(enclosed, lvl=lvl+1)
            exp2 += str(result)
        else:
            exp2 += c
    logger.debug(f"{indent} no parens: {exp2}")

    # -- solve from left to right
    result_str, exp2 = exp2.split(" ", 1)
    result = int(result_str)
    while exp2:
        try:
            op_str, num, exp2 = exp2.split(" ", 2)
        except ValueError:  # not enough to unpack
            try:
                op_str, num = exp2.split(" ")
                exp2 = ""
            except ValueError:
                logger.debug(f"{indent}break: {exp2!r}")
                break

        if op_str == "+":
            result += int(num)
        elif op_str == "*":
            result *= int(num)
        else:
            raise RuntimeError(f"Invalid operator: {op_str!r}")

    logger.debug(f"{indent}{result}")
    return result


def part1(data: str) -> int:
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
    logger.debug("")
    logger.debug(expression)
    logger.debug('-->', actual, '<--')
    assert actual == expected


def eval_expression2(expression: str, lvl=0) -> int:
    indent = " "*(lvl*2)
    logger.debug(f"{indent}eval: {expression!r}")

    # solve parenthesis first

    exp = expression
    exp2 = ""
    while exp:
        c = exp[0]
        exp = exp[1:]
        if c == "(":
            enclosed, exp = in_parens(exp)
            exp2 += str(eval_expression2(enclosed, lvl=lvl+1))
        else:
            exp2 += c
    logger.debug(f"{indent}no parens: {exp2}")

    # -- solve addition before multiplication

    def replace(match):
        return str(eval(match.group(0)))

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
        return s

    def add_replacer(s):
        return replacer(s, add_pattern)

    exp3 = add_replacer(exp2)
    logger.debug(f"{indent}no add: {exp3}")

    # -- handle multiplication with eval

    exp4 = eval(exp3)
    logger.debug(f"{indent}final: {exp4}")
    return exp4


def part2(data: str) -> int:
    return sum([eval_expression2(exp) for exp in data.strip().split("\n")])


def main():
    input_file = Path(__file__).parent / "input"
    data = input_file.read_text()

    logger.info(part1(data))  # 14006719520523
    logger.info(part2(data))  # 545115449981968


if __name__ == "__main__":
    if "-v" in sys.argv:
        logging.basicConfig(level=logging.DEBUG, format="%(message)s")
    else:
        logging.basicConfig(level=logging.INFO, format="%(message)s")
    main()
