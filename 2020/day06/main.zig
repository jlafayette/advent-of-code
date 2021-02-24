const std = @import("std");
const print = std.debug.print;
const input = @embedFile("input");

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;
    var it = std.mem.split(input, "\r\n\r\n");
    var sum: usize = 0;
    while (it.next()) |group| {
        sum += try anyoneYes(allocator, group);
    }
    print("part 1: {d}\n", .{sum}); // 6763
}

fn anyoneYes(allocator: *std.mem.Allocator, group: []const u8) !usize {
    var map = std.AutoHashMap(u8, bool).init(allocator);
    defer map.deinit();
    for (group) |byte| {
        switch (byte) {
            '\r' => {
                continue;
            },
            '\n' => {
                continue;
            },
            else => {
                try map.put(byte, true);
            },
        }
    }
    return map.count();
}

const testing = std.testing;

test "anyoneYes" {
    // print("\n", .{});
    const actual = try anyoneYes(testing.allocator, "abcx\nabcy\nabcz");
    // print("actual: {d}\n", .{actual});
    testing.expectEqual(@as(usize, 6), actual);
    // var map = std.AutoHashMap(u8, u32).init(testing.allocator);
    // defer map.deinit();
    // try map.put(1, 1);
    // try map.put(2, 2);
    // const count = (map.get(2) orelse 0) + 1;
    // try map.put(2, count);
    // var iter = map.iterator();
    // while (iter.next()) |kv| {
    //     print("key: {d}, value: {d}\n", .{kv.key, kv.value});
    // }
    // print("\n\n", .{});
}
