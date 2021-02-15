const std = @import("std");
const fs = std.fs;
const testing = std.testing;
const print = std.debug.print;

pub fn main() anyerror!void {
    std.log.info("Starting main", .{});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    var path_buffer: [100]u8 = undefined;
    const input = try fs.cwd().realpath("input", &path_buffer);
    print("input: {s}\n", .{input});
    const file = try fs.openFileAbsolute(
        input,
        .{ .read = true },
    );
    defer file.close();
    var line_buffer: [16]u8 = undefined;
    var count: usize = 0;
    while (true) {
        var line: []const u8 = (try file.reader().readUntilDelimiterOrEof(
            &line_buffer,
            '\n',
        )) orelse break;
        count += 1;
    }
    print("counted {d} items\n", .{count});
    try file.seekTo(0);

    const array_ptr = try allocator.alloc(i32, count);
    var i: usize = 0;

    while (true) {
        var line: []const u8 = (try file.reader().readUntilDelimiterOrEof(
            &line_buffer,
            '\n',
        )) orelse break;
        if (std.builtin.Target.current.os.tag == .windows) {
            line = std.mem.trimRight(u8, line, "\r");
        }
        const n = try std.fmt.parseInt(i32, line, 10);
        array_ptr[i] = n;
        i += 1;
    }
    const array = array_ptr;

    for (array) |item1, index1| {
        if (index1 + 1 < array.len) {
            for (array[index1 + 1 ..]) |item2| {
                if (item1 + item2 == 2020) {
                    const m = item1 * item2;
                    print("part 1: {d}\n", .{m}); // part 1 answer:  888331
                }
            }
        }
    }

    for (array) |item1, index1| {
        if (index1 + 1 < array.len) {
            for (array[index1 + 1 ..]) |item2, index2| {
                if (index2 + 1 < array.len) {
                    for (array[index2 + 1 ..]) |item3| {
                        if (item1 + item2 + item3 == 2020) {
                            const m = item1 * item2 * item3;
                            print("part 2: {d}\n", .{m}); // part 2 answer:  130933530
                        }
                    }
                }
            }
        }
    }

    print("\n", .{});
}

test "combinations" {
    var array = &[_]i32{ 1, 2, 3 };
    print("\n", .{});
    for (array) |item1, index1| {
        if (index1 + 1 < array.len) {
            for (array[index1 + 1 ..]) |item2| {
                print("{d}, {d}\n", .{ item1, item2 });
                if (item1 + item2 == 5) {
                    const m = item1 * item2;
                    print("{d}", .{m});
                    print("\n", .{});
                }
            }
        }
    }
    print("\n", .{});
}
