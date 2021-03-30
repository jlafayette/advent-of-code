const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const print = std.debug.print;
const input = @embedFile("input");

const line_ending = "\n";

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = &arena.allocator;

    const part1_result = try part1(alloc, input);
    print("part1: {d}\n", .{part1_result});
}

fn part1(alloc: *Allocator, data: []const u8) !usize {
    // shiny gold focused
    // in the end
    // gold parents
    // for p in gold parentsA -> parentsB -> parentsN
    var bagsMap = StringHashMap(ArrayList([]const u8)).init(alloc);

    // when we read a rule
    // - add bag to map (if not already there) (empty)
    // - for each contained bag
    // -- look it up in map
    // -- if it exists, then append bag
    // -- else add with one item bag
    var lineIt = std.mem.split(data, line_ending);
    while (lineIt.next()) |line| {
        var it = std.mem.split(line, " bags ");
        const color = line[0..it.next().?.len];
        // - add bag to map (if not already there) (empty)
        //
        var gop_bag = try bagsMap.getOrPut(color);
        if (!gop_bag.found_existing) {
            var arr_list = ArrayList([]const u8).init(alloc);
            gop_bag.entry.value = arr_list;
        }
        if (std.mem.eql(u8, it.rest(), "contain no other bags.")) {
            continue;
        }
        var contained_str = it.rest();
        contained_str = contained_str[8 .. contained_str.len - 1]; // trim off 'contans ' from start and '.' from end
        var contained_bags_iter = std.mem.split(contained_str, ", ");
        while (contained_bags_iter.next()) |contained_bag| {
            var bag_iter = std.mem.split(contained_bag, " ");
            if (bag_iter.next()) |num_str| {
                const n = try std.fmt.parseInt(u32, num_str, 10);
                var rest = bag_iter.rest();
                const contained_color = switch (n) {
                    1 => rest[0 .. rest.len - 4],
                    else => rest[0 .. rest.len - 5],
                };
                // -- look it up in map
                // -- if it exists, then append bag
                // -- else add with one item bag
                gop_bag = try bagsMap.getOrPut(contained_color);
                if (gop_bag.found_existing) {
                    try gop_bag.entry.value.append(color);
                } else {
                    var arr_list = ArrayList([]const u8).init(alloc);
                    try arr_list.append(color);
                    gop_bag.entry.value = arr_list;
                }
            }
        }
    }

    // allOuterBags map name->bool (set)
    // gold bag -> fitInside
    // - add each to allOuterBags
    // - for each, look up in map
    // -- add all the outerBags, recurse/while loop until done
    var allOuterBags = StringHashMap(bool).init(alloc);
    var toCheck = ArrayList([]const u8).init(alloc);
    try toCheck.append("shiny gold");
    while (toCheck.popOrNull()) |color| {
        try allOuterBags.put(color, true);
        const outerBags = bagsMap.get(color) orelse break;
        for (outerBags.items) |outer_color| {
            try toCheck.append(outer_color);
        }
    }

    var count: usize = @as(usize, allOuterBags.count());
    return count - 1; // subtract 1 for original bag
}

test "part 1" {
    var data =
        \\light red bags contain 1 bright white bag, 2 muted yellow bags.
        \\dark orange bags contain 3 bright white bags, 4 muted yellow bags.
        \\bright white bags contain 1 shiny gold bag.
        \\muted yellow bags contain 2 shiny gold bags, 9 faded blue bags.
        \\shiny gold bags contain 1 dark olive bag, 2 vibrant plum bags.
        \\dark olive bags contain 3 faded blue bags, 4 dotted black bags.
        \\vibrant plum bags contain 5 faded blue bags, 6 dotted black bags.
        \\faded blue bags contain no other bags.
        \\dotted black bags contain no other bags.
    ;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = &arena.allocator;
    var r = try part1(a, data);
    print("result: {d}\n", .{r});
    print("\n\n", .{});
    std.testing.expectEqual(@as(usize, 4), r);
}
