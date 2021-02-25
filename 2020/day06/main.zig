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

    it = std.mem.split(input, "\r\n\r\n");
    sum = 0;
    while (it.next()) |group| {
        sum += try everyoneYes(allocator, group);
    }
    print("part 2: {d}\n", .{sum}); // 3512
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
    const actual = try anyoneYes(testing.allocator, "abcx\nabcy\nabcz");
    testing.expectEqual(@as(usize, 6), actual);
}

fn everyoneYes(allocator: *std.mem.Allocator, group: []const u8) !usize {
    var map = std.AutoHashMap(u8, u32).init(allocator);
    defer map.deinit();
    var peopleCount: usize = 1;
    for (group) |byte| {
        switch (byte) {
            '\n' => {
                peopleCount += 1;
            },
            '\r' => {
                continue;
            },
            else => {
                const count = (map.get(byte) orelse 0) + 1;
                try map.put(byte, count);
            },
        }
    }
    var count: usize = 0;
    var it = map.iterator();
    while (it.next()) |kv| {
        if (kv.value == peopleCount) {
            count += 1;
        }
    }
    return count;
}

test "everyoneYes" {
    const actual = try everyoneYes(testing.allocator, "abcx\nabcy\nabcz");
    testing.expectEqual(@as(usize, 3), actual);
}
