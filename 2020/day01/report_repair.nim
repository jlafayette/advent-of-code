import strutils, sequtils

let input = readFile("input")
let entries = input.split({'\n'})
                   .mapIt(parseInt(it))

iterator combinations2(list: seq[int]): (int, int) =
    for ix, x in list:
        for iy in (ix + 1) ..< list.len:
            yield (x, list[iy])

iterator combinations3(list: seq[int]): (int, int, int) =
    for ix, x in list:
        for iy in (ix + 1) ..< list.len:
            for iz in (iy + 1) ..< list.len:
                yield (x, list[iy], list[iz])

# part 1
for combo in combinations2(entries):
    if combo[0] + combo[1] == 2020:
        echo combo[0] * combo[1]

# part 2
for combo in combinations3(entries):
    if combo[0] + combo[1] + combo[2] == 2020:
        echo combo[0] * combo[1] * combo[2]
