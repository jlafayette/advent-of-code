// Day 5: Binary Boarding
// https://adventofcode.com/2020/day/5
const std = @import("std");
const input = @embedFile("input");
const print = std.debug.print;

pub fn main() anyerror!void {
    // part 1: 838
    var lines = std.mem.split(input, "\r\n");
    var line_count: usize = 0;
    var max: i32 = 0;
    while (true) {
        var line = lines.next() orelse break;
        const seat = decodeSeat(line);
        max = std.math.max(max, seat.code);
        line_count += 1;
    }
    print("part 1: {d}\n", .{max});

    // part 2: 714
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;
    lines = std.mem.split(input, "\r\n");
    var ids = try allocator.alloc(i32, line_count);
    var ids_index: usize = 0;
    while (true) {
        const line = lines.next() orelse break;
        const seat = decodeSeat(line);
        ids[ids_index] = seat.code;
        ids_index += 1;
    }
    const max_id = calculateId(127, 7);
    var candidate_id: i32 = 0;
    var part2: i32 = -1;
    while (candidate_id <= max_id) : (candidate_id += 1) {
        var plus1_in_ids = false;
        var minus1_in_ids = false;
        var in_ids = false;
        for (ids) |id| {
            if (candidate_id + 1 == id) {
                plus1_in_ids = true;
            }
            if (candidate_id - 1 == id) {
                minus1_in_ids = true;
            }
            if (candidate_id == id) {
                in_ids = true;
            }
        }
        if (plus1_in_ids and minus1_in_ids and !in_ids) {
            part2 = candidate_id;
            break;
        }
    }
    print("part 2: {d}\n", .{part2});
}

test "iterators" {
    print("\n", .{});
    const words = "iterators in zig are awkward";
    var iter = std.mem.tokenize(words, " ");
    var word = iter.next();
    while (word != null) : (word = iter.next()) {
        print("word: {s}\n", .{word});
    }
    iter = std.mem.tokenize(words, " ");
    while (true) {
        word = iter.next() orelse break;
        print("word: {s}\n", .{word});
    }
    print("\n\n", .{});
}

fn calculateId(row: i32, col: i32) i32 {
    return row*8 + col;
}

test "range" {
    print("\n", .{});
    var i: u8 = 0;
    while (i < 10) : (i += 1) {
        print("{d} ", .{i});
    }
    print("\n\n", .{});
}

const Range = struct {
    lo: i32,
    hi: i32,
};

fn b(in: Range, hi: bool) Range {
    const mid = @divFloor((in.hi - in.lo), 2);
    if (hi == true) {
        return Range{ .lo=mid+1+in.lo, .hi=in.hi };
    } else {
        return Range{ .lo=in.lo, .hi=mid+in.lo };
    }
}

fn isHi(x: u8) bool {
    return switch (x) {
        'F' => false,
        'B' => true,
        'L' => false,
        'R' => true,
        else => unreachable,
    };
}

const Seat = struct {
    row: i32,
    col: i32,
    code: i32,
};

fn decodeSeat(str: []const u8) Seat {
    // row 0 - 127
    // col 0 - 7
    var row_range = Range{ .lo=0, .hi=127 };
    for (str[0..7]) |byte| {
        row_range = b(row_range, isHi(byte));
    }
    const row = row_range.lo;
    var col_range = Range{ .lo=0, .hi=7 };
    for (str[7..]) |byte| {
        col_range = b(col_range, isHi(byte));
    }
    const col = col_range.lo;
    return Seat{ .row=row, .col=col, .code=calculateId(row, col)};
}

test "decode seat" {
    var expected = Seat{ .row=70, .col=7, .code=567 };
    var actual = decodeSeat("BFFFBBFRRR");
    std.testing.expectEqual(expected.row, actual.row);
    std.testing.expectEqual(expected.col, actual.col);
    std.testing.expectEqual(expected.code, actual.code);

    expected = Seat{ .row=14, .col=7, .code=119 };
    actual = decodeSeat("FFFBBBFRRR");
    std.testing.expectEqual(expected.row, actual.row);
    std.testing.expectEqual(expected.col, actual.col);
    std.testing.expectEqual(expected.code, actual.code);

    expected = Seat{ .row=102, .col=4, .code=820 };
    actual = decodeSeat("BBFFBBFRLL");
    std.testing.expectEqual(expected.row, actual.row);
    std.testing.expectEqual(expected.col, actual.col);
    std.testing.expectEqual(expected.code, actual.code);
}

