const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const print = std.debug.print;
const input = @embedFile("input");


pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    // var data =
    // \\light red bags contain 1 bright white bag, 2 muted yellow bags.
    // \\dark orange bags contain 3 bright white bags, 4 muted yellow bags.
    // \\bright white bags contain 1 shiny gold bag.
    // \\muted yellow bags contain 2 shiny gold bags, 9 faded blue bags.
    // \\shiny gold bags contain 1 dark olive bag, 2 vibrant plum bags.
    // \\dark olive bags contain 3 faded blue bags, 4 dotted black bags.
    // \\vibrant plum bags contain 5 faded blue bags, 6 dotted black bags.
    // \\faded blue bags contain no other bags.
    // \\dotted black bags contain no other bags.
    // ;
    const part1_result = try part1(allocator, input);
    print("part1: {d}\n", .{part1_result});
}

const Bags = struct {
    bag: *Bag,
    count: usize,
};

const Bag = struct {
    name: []const u8,
    // contains: ArrayList(*Bags),
    possibleParents: ArrayList([]const u8),

    fn init(allocator: *Allocator, name: []const u8) Bag {
        // var contains = ArrayList(*Bags).init(allocator);
        var possible_parents = ArrayList([]const u8).init(allocator);
        return Bag{
            .name=name,
            // .contains=contains,
            .possibleParents=possible_parents,
        };
    }
    fn deinit(self: *Bag) void {
        // self.contains.deinit();
        self.possibleParents.deinit();
    }
};


fn part1(allocator: *Allocator, data: []const u8) !usize {
    var map = std.StringHashMap(Bag).init(allocator);
    defer map.deinit();
    // store all bags in a map
    var lineIt = std.mem.split(data, "\n");
    // hash map of bag-name -> *Bag
    while (lineIt.next()) |line| {
        // print(" . {s} . \n", .{line});
        var it = std.mem.split(line, " bags ");
        const name = line[0..it.next().?.len];

        // print("name: {s}\n", .{name});
        // var bag = getBag(allocator, &map, name);
        const gop_bag = try map.getOrPut(name);
        if (!gop_bag.found_existing) {
            // var name_buffer = try allocator.alloc(u8, name.len);
            // print("type of name buffer: {}\n", .{@TypeOf(name_buffer)});
            gop_bag.entry.value = Bag.init(allocator, name);
        }
        // print("bag.name: {s}\n", .{gop_bag.entry.value.name});
        if (std.mem.eql(u8, it.rest(), "contain no other bags.")) {
            // print("no other bags, continue\n", .{});
            continue;
        }
        var contained_str = it.rest();
        contained_str = contained_str[8..contained_str.len-1];  // trim off 'contans ' from start and '.' from end
        // print("contains: |{s}|\n", .{contained_str});
        var contained_bags_iter = std.mem.split(contained_str, ", ");
        while(contained_bags_iter.next()) |contained_bag| {
            var bag_iter = std.mem.split(contained_bag, " ");
            if (bag_iter.next()) |num_str| {
                const n = try std.fmt.parseInt(u32, num_str, 10);
                var rest = bag_iter.rest();
                const contained_name = switch(n) {
                    1 => rest[0..rest.len-4],
                    else => rest[0..rest.len-5],
                };
                // print("\tcontains {d} of {s}\n", .{n, contained_name});
                const gop_cbag = try map.getOrPut(contained_name);
                if (!gop_cbag.found_existing) {
                    gop_cbag.entry.value = Bag.init(allocator, contained_name);
                }
                try gop_cbag.entry.value.possibleParents.append(gop_bag.entry.value.name);
                // var cbag = getBag(allocator, &map, contained_name);
                // try cbag.possibleParents.append(bag);
                // try map.put(hashStr(contained_name), cbag);
            }
        }
    }
    // var mapIter = map.iterator();
    // while (mapIter.next()) |kv| {
    //     print("bag hash: {s}, name: {s}\n", .{kv.key, kv.value.name});
    //     for (kv.value.possibleParents.items) |pp| {
    //         print("\thas possible parent: {s}\n", .{pp});
    //     }
    // }
    if (map.get("shiny gold")) |shiny_gold| {
        return possibleParents(0, map, &shiny_gold);
    }
    return 0;
}

fn possibleParents(top_parents: usize, map: std.StringHashMap(Bag), bag: *const Bag) usize {
    var result = top_parents;
    for (bag.possibleParents.items) |pp_name| {
        if (map.get(pp_name)) |pp| {
            if (pp.possibleParents.items.len == 0) {
                // print("added top level parent: {s}\n", .{pp.name});
                result += 1;
            } else {
                result = possibleParents(result, map, &pp);
            }
        }

    }
    return result;
}

/// Convert string to int so it can be used as a HashMap key.
fn hashStr(str: []const u8) usize {
    var hash: usize = 0;
    for (str) |byte, i| {
        hash += byte * i;
    }
    return hash;
}

test "hash str->*Bag" {
    var map = std.AutoHashMap(usize, *Bag).init(std.testing.allocator);
    defer map.deinit();
    var golden_bag = Bag.init(std.testing.allocator, "golden bag");
    defer golden_bag.deinit();
    var red_bag = Bag.init(std.testing.allocator, "red bag");
    defer red_bag.deinit();
    try map.put(hashStr(golden_bag.name), &golden_bag);
    try map.put(hashStr(red_bag.name), &red_bag);
    if (map.get(hashStr("golden bag"))) |bag| {
        print("found bag: {s}\n", .{bag.name});
    }
    print("\n\n", .{});
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
    // std.testing.expectEqual(@as(usize, 4), part1(data));
}

// def test_part1():
//     assert part1(create_bag_lookup(TEST_DATA)) == 4

test "ArrayList" {
    var a = std.testing.allocator;
    var list: ArrayList(u8) = ArrayList(u8).init(a);
    defer list.deinit();
    try list.append('a');
    try list.append('b');
    try list.append('c');
    print("list: {s}\n", .{list.items});
    print("\n\n", .{});
    var bag = Bag.init(a, "golden bag");
    defer bag.deinit();
    var bag2 = Bag.init(a, "olive bag");
    defer bag2.deinit();
    try bag.contains.append(&Bags{ .bag=&bag2, .count=3 });
    try bag2.possibleParents.append(&bag);
}

