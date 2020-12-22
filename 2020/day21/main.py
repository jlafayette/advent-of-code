"""Day 21: Allergen Assessment

https://adventofcode.com/2020/day/21

"""
from dataclasses import dataclass
from pathlib import Path
from typing import List


# -- part 1


TEST_DATA = """mxmxvkd kfcds sqjhc nhms (contains dairy, fish)
trh fvjkl sbzzf mxmxvkd (contains dairy)
sqjhc fvjkl (contains soy)
sqjhc mxmxvkd sbzzf (contains fish)"""


def test_part1():
    assert part1(TEST_DATA) == 5


@dataclass
class Food:
    ingredients: List[str]
    allergens: List[str]


def parse(data: str) -> List[Food]:
    foods = data.strip().split("\n")
    result = []
    for food in foods:
        ingredients, allergens = food.split("(")
        ingredients = ingredients.strip().split(" ")
        allergens = allergens[9:-1].split(", ")
        result.append(Food(ingredients=ingredients, allergens=allergens))
    return result


@dataclass
class Match:
    ingredient: str
    allergen: str


def find_matches(foods: List[Food]) -> List[Match]:
    lookup = {}
    for food in foods:
        for allergen in food.allergens:
            existing = lookup.get(allergen, [])
            existing.append(food.ingredients)
            lookup[allergen] = existing
    matches = []
    progress = True
    while progress:
        progress = False
        new_matches = []

        for allergen, ingredient_lists in lookup.items():
            if allergen in [m.allergen for m in new_matches]:
                continue
            if len(ingredient_lists) == 1 and len(ingredient_lists[0]) == 1:
                new_matches.append(Match(ingredient=ingredient_lists[0][0], allergen=allergen))
                progress = True
                continue
            common_ingredients = set(ingredient_lists[0])
            for ingredients in ingredient_lists:
                common_ingredients = common_ingredients.intersection(set(ingredients))
            if len(common_ingredients) == 1:
                new_matches.append(Match(ingredient=list(common_ingredients)[0], allergen=allergen))
                progress = True

        # Matched ingredients can be removed from the lookup dict and
        # other ingredient lists.
        for match in new_matches:
            del lookup[match.allergen]
            for ingredient_lists in lookup.values():
                for ingredients in ingredient_lists:
                    try:
                        ingredients.remove(match.ingredient)
                    except ValueError:
                        pass
        matches.extend(new_matches)

    return matches


def get_all_ingredients(foods: List[Food]) -> List[str]:
    ingredients = list()
    for food in foods:
        ingredients.extend(food.ingredients)
    return ingredients


def part1(data: str):
    foods = parse(data)
    all_ingredients = get_all_ingredients(foods)
    matches = find_matches(foods)
    no_allergens = set(all_ingredients).difference(set([m.ingredient for m in matches]))
    count = 0
    for ingredient in no_allergens:
        count += all_ingredients.count(ingredient)
    return count


# -- part 2


def part2(data: str):
    foods = parse(data)
    matches = find_matches(foods)
    matches.sort(key=lambda m: m.allergen)
    dangerous = [m.ingredient for m in matches]
    return ",".join(dangerous)


def main():
    input_file = Path(__file__).parent / "input"
    data = input_file.read_text()

    print(part1(data))  # 2786
    print(part2(data))  # prxmdlz,ncjv,knprxg,lxjtns,vzzz,clg,cxfz,qdfpq


if __name__ == "__main__":
    main()
