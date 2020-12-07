import strutils, sequtils, sugar


type
    Slope = object
        x*: Positive
        y*: Positive


const tree = '#'


proc trees_encountered(slope: Slope, tree_map: string): int =
    let rows = tree_map.strip().split({'\n'})
    let width = rows[0].len
    var xpos = 0
    var ypos = 0
    while ypos < rows.len:
        let row = rows[ypos]
        let obstacle = row[xpos mod width]
        if obstacle == tree:
            result += 1
        xpos += slope.x
        ypos += slope.y
    result


# -- part 1


let tree_map = readFile("input")

echo trees_encountered(Slope(x: 3, y: 1), tree_map)


# -- part 2


let result = @[Slope(x: 1, y: 1),
               Slope(x: 3, y: 1),
               Slope(x: 5, y: 1),
               Slope(x: 7, y: 1),
               Slope(x: 1, y: 2)]
    .map(slope => trees_encountered(slope, tree_map))
    .foldl(a * b, 1)

echo result
