const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const ArrayListUnmanaged = std.ArrayListUnmanaged;
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

// const Bags = struct {
//     name: []const u8,
//     count: usize,
// };

// const Bag = struct {
//     name: []const u8,
//     contains: ArrayList(Bags),
//     possibleParents: ArrayList([]const u8),

//     fn init(allocator: *Allocator, name: []const u8) Bag {
//         var contains = ArrayList(Bags).init(allocator);
//         var possible_parents = ArrayList([]const u8).init(allocator);
//         return Bag{
//             .name = name,
//             .contains = contains,
//             .possibleParents = possible_parents,
//         };
//     }
//     fn deinit(self: *Bag) void {
//         self.contains.deinit();
//         self.possibleParents.deinit();
//     }
// };

fn countLines(data: []const u8) usize {
    var count = 0;
    var lineIt = std.mem.split(data, "\n");
    while (lineIt.next()) |line| {
        count += 1;
    }
    return count;
}

fn parseName(line: []const u8) []const u8 {
    // print("line: {s}\n", .{line});
    var it = std.mem.split(line, " bags ");
    const name = line[0..it.next().?.len];
    // print("bag name: {s}\n", .{name});
    return name;
}

fn parseLine(contains: *ArrayList(Contained), line: []const u8) !Bag {
    print("line: {s}\n", .{line});
    var it = std.mem.split(line, " bags ");
    const name = line[0..it.next().?.len];

    print("bag name: {s}\n", .{name});
    if (std.mem.eql(u8, it.rest(), "contain no other bags.")) {
        print("no other bags, return\n", .{});
        const array = [_]Contained{};
        return Bag{ .name = name, .contains = array[0..] };
    }

    // var contains = ArrayList(Contained).init(allocator);
    // defer contains.deinit(); // this causes a crash when trying to access

    var contained_str = it.rest();
    contained_str = contained_str[8 .. contained_str.len - 1]; // trim off 'contans ' from start and '.' from end
    print("contains: |{s}|\n", .{contained_str});
    var contained_bags_iter = std.mem.split(contained_str, ", ");
    while (contained_bags_iter.next()) |contained_bag| {
        var bag_iter = std.mem.split(contained_bag, " ");
        if (bag_iter.next()) |num_str| {
            const n = try std.fmt.parseInt(u32, num_str, 10);
            var rest = bag_iter.rest();
            const contained_name = switch (n) {
                1 => rest[0 .. rest.len - 4],
                else => rest[0 .. rest.len - 5],
            };
            print("\tcontains {d} of {s}\n", .{ n, contained_name });
            try contains.append(Contained{ .name = contained_name, .count = n });
        }
    }
    print("{}\n", .{contains});
    return Bag{ .name = name, .contains = contains.items };
}

const Contained = struct {
    name: []const u8,
    count: usize,
};

const Bag = struct {
    name: []const u8,
    contains: []Contained,
};

const ContainsIterator = struct {
    split_iterator: *std.mem.SplitIterator,

    /// Return an (optional) iterator for the contents of a bag if it contains anything.
    fn init(line: []const u8) ?ContainsIterator {
        var it = std.mem.split(line, " bags ");
        const name = line[0..it.next().?.len];
        if (std.mem.eql(u8, it.rest(), "contain no other bags.")) {
            return null;
        }
        var contained_str = it.rest();
        contained_str = contained_str[8 .. contained_str.len - 1]; // trim off 'contans ' from start and '.' from end
        return ContainsIterator{
            .split_iterator = &std.mem.split(contained_str, ", "),
        };
    }

    /// Returns a slice of the next bag name, or null if complete.
    fn next(self: *ContainsIterator) ?[]const u8 {
        var contained_bag = self.split_iterator.next() orelse return null;
        var bag_iter = std.mem.split(contained_bag, " ");
        if (bag_iter.next()) |num_str| {
            const n = std.fmt.parseInt(u32, num_str, 10) catch {
                print("oops - no parse...\n", .{});
                return null;
            };
            var rest = bag_iter.rest();
            const contained_name = switch (n) {
                1 => rest[0 .. rest.len - 4],
                else => rest[0 .. rest.len - 5],
            };
            return contained_name;
        } else {
            print("oops - no parse...\n", .{});
            return null;
        }
    }
};

fn part1(alloc: *Allocator, data: []const u8) !usize {
    // store all bags in a map of bag-name -> bool
    // true for bags that can hold a shiny golden bag (directly or indirectly)
    var map = std.StringHashMap(bool).init(alloc);
    defer map.deinit();

    var lineIt = std.mem.split(data, "\n");
    while (lineIt.next()) |line| {
        try map.put(parseName(line), false);
    }

    // Go over the map, if a bag contains a shiny gold bag, then mark it as true.
    // Also if a bag contains any bag marked true, then mark it as true.
    // Record if any changes were made, continue until a loop does not make any
    // changes to the map.
    while (true) {
        var changes: bool = false;
        lineIt = std.mem.split(data, "\n");
        while (lineIt.next()) |line| {
            const name = parseName(line);
            var contains_gold = map.get(name).?;
            if (contains_gold) {
                continue;
            }
            var contains_iterator = ContainsIterator.init(line) orelse continue;
            while (contains_iterator.next()) |contained_name| {
                if (std.mem.eql(u8, contained_name, "shiny gold")) {
                    contains_gold = true;
                    break;
                }
                if (map.get(contained_name).?) {
                    contains_gold = true;
                    break;
                }
            }
            if (contains_gold) {
                changes = true;
                var gop = try map.getOrPut(name);
                gop.entry.value = true;
            }
        }
        if (!changes) {
            break;
        }
    }
    var result: usize = 0;
    var iterator = map.iterator();
    while (iterator.next()) |entry| {
        if (entry.value) {
            result += 1;
        }
    }
    return result;
}

fn leak(alloc: *Allocator) !void {
    var map = std.StringHashMap(bool).init(alloc);
    try map.put("foo", true);
}

test "leak" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = &arena.allocator;
    try leak(a);
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

// test "hash str->Bag" {
//     var a = std.testing.allocator;
//     var map = std.StringHashMap(Bag).init(a);
//     defer map.deinit();
//     var golden_bag = Bag.init(a, "shiny gold");
//     defer golden_bag.deinit();
//     var olive_bag = Bag.init(a, "dark olive");
//     defer olive_bag.deinit();
//     try map.put(golden_bag.name, golden_bag);
//     try map.put(olive_bag.name, olive_bag);

//     var bag = map.get("shiny gold").?;
//     print("found bag: {s}\n", .{bag.name});
//     try bag.contains.append(Bags{ .name = olive_bag.name, .count = 1 });
//     // print("contains: {s}\n", .{bag.contains.items[0].name});

//     // if (map.get("shiny gold")) |bag| {
//     //     print("found bag: {s}\n", .{bag.name});
//     //     try bag.contains.append(Bags{ .name = olive_bag.name, .count = 1 });
//     //     print("contains: {s}\n", .{bag.contains.items[0].name});
//     // }

//     // var cbag = try map.getOrPut("shiny gold");
//     // if (cbag.found_existing) {
//     //     try cbag.entry.value.contains.append(Bags{ .name = olive_bag.name, .count = 1 });
//     // }

//     // if (map.get("shiny gold")) |bag| {
//     //     print("found bag: {s}\n", .{bag.name});
//     //     print("contains: {s}\n", .{bag.contains.items[0].name});
//     // }
//     print("\n\n", .{});
// }

// test "ArrayList" {
//     var a = std.testing.allocator;
//     var list: ArrayList(u8) = ArrayList(u8).init(a);
//     defer list.deinit();
//     try list.append('a');
//     try list.append('b');
//     try list.append('c');
//     print("\nlist: {s}\n", .{list.items});
//     print("\n\n", .{});
//     var bag = Bag.init(a, "golden bag");
//     defer bag.deinit();
//     var bag2 = Bag.init(a, "olive bag");
//     defer bag2.deinit();
//     try bag.contains.append(Bags{ .name = bag2.name, .count = 3 });
//     try bag2.possibleParents.append(bag.name);
//     print("{s}\n", .{bag2.name});
//     print("{}\n", .{bag2.contains});
//     print("{}\n", .{bag2.possibleParents});
//     print("\n\n", .{});
// }
