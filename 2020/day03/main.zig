const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

const test_tree_map =
    \\..##.......
    \\#...#...#..
    \\.#....#..#.
    \\..#.#...#.#
    \\.#...##..#.
    \\..#.##.....
    \\.#.#.#....#
    \\.#........#
    \\#.##...#...
    \\#...##....#
    \\.#..#...#.#
;

fn treesEncountered(
    a: *Allocator,
    right: usize,
    down: usize,
    tree_map: []const u8,
) Allocator.Error!usize {
    var map = tree_map;
    map = std.mem.trimRight(u8, map, "\r\n");
    var line_count: usize = 1;
    for (map) |byte, i| {
        if (byte == '\n') {
            line_count += 1;
        }
    }
    var lines: [][]const u8 = try a.alloc([]const u8, line_count);
    defer a.free(lines);
    var line_start_index: usize = 0;
    var insert_index: usize = 0;
    for (map) |byte, i| {
        if (byte == '\n') {
            var line = map[line_start_index..i];

            // If reading a file with CRLF
            line = std.mem.trimRight(u8, line, "\r");

            lines[insert_index] = line;
            line_start_index = i + 1;
            insert_index += 1;
        }
    }
    lines[insert_index] = map[line_start_index..];
    var x: usize = 0;
    const width: usize = lines[0].len;
    var trees: usize = 0;
    var skipped: usize = 0;
    for (lines) |line, y| {
        if (@mod(y, down) != 0) {
            skipped += 1;
            continue;
        }
        const pos_index = @mod(x, width);
        const pos_byte = line[pos_index];
        if (pos_byte == '#') {
            trees += 1;
        }
        x += right;
    }
    return trees;
}

test "tree count" {
    const r = try treesEncountered(std.testing.allocator, 1, 1, test_tree_map);
    expect(r == 2);
}
test "tree count2" {
    const r = try treesEncountered(std.testing.allocator, 3, 1, test_tree_map);
    expect(r == 7);
}
test "tree count3" {
    const r = try treesEncountered(std.testing.allocator, 5, 1, test_tree_map);
    expect(r == 3);
}
test "tree count4" {
    const r = try treesEncountered(std.testing.allocator, 7, 1, test_tree_map);
    expect(r == 4);
}
test "tree count5" {
    const r = try treesEncountered(std.testing.allocator, 1, 2, test_tree_map);
    expect(r == 2);
}

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    var path_buffer: [100]u8 = undefined;
    const input = try fs.cwd().realpath("input", &path_buffer);
    const file = try fs.openFileAbsolute(
        input,
        .{ .read = true },
    );
    defer file.close();

    // read whole file into buffer
    var buffer = try file.readToEndAlloc(allocator, 4294967295);

    // calculate part 1
    const part1 = treesEncountered(allocator, 3, 1, buffer);
    print("part 1: {d}\n", .{part1}); // 257

    // calculate part 2
    var part2: usize = 1;
    var tree_count = try treesEncountered(allocator, 1, 1, buffer);
    part2 = part2 * tree_count;
    tree_count = try treesEncountered(allocator, 3, 1, buffer);
    part2 = part2 * tree_count;
    tree_count = try treesEncountered(allocator, 5, 1, buffer);
    part2 = part2 * tree_count;
    tree_count = try treesEncountered(allocator, 7, 1, buffer);
    part2 = part2 * tree_count;
    tree_count = try treesEncountered(allocator, 1, 2, buffer);
    part2 = part2 * tree_count;
    print("part 2: {d}\n", .{part2}); // 1744787392
}
