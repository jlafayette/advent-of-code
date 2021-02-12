const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectError = std.testing.expectError;
const expectEqualStrings = std.testing.expectEqualStrings;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    var path_buffer: [100]u8 = undefined;
    const cwd = try fs.cwd().realpath("", &path_buffer);
    const day01 = fs.path.dirname(cwd).?;
    const input = try fs.path.join(allocator, &[_][]const u8{ day01, "input" });
    print("cwd: {s}\n", .{cwd});
    print("input: {s}\n", .{input});
    const file = try fs.openFileAbsolute(
        input,
        .{ .read = true },
    );
    defer file.close();

    var part1: u32 = 0;
    var part2: u32 = 0;
    var line_buffer: [64]u8 = undefined;
    while (true) {
        var line: []const u8 = (try file.reader().readUntilDelimiterOrEof(
            &line_buffer,
            '\n',
        )) orelse break;
        if (std.builtin.Target.current.os.tag == .windows) {
            line = std.mem.trimRight(u8, line, "\r");
        }
        const parsed_line = try parseLine(line);
        if (isValid1(parsed_line)) {
            part1 += 1;
        }
        if (isValid2(parsed_line)) {
            part2 += 1;
        }
    }
    print("part 1: {d}\n", .{part1}); // 636
    print("part 2: {d}\n", .{part2}); // 588
}

const Line = struct {
    min: u32,
    max: u32,
    letter: u8,
    password: []const u8,
};

const ParseError = error{
    /// The result cannot fit in the type specified
    Overflow,

    /// The input was empty or had a byte that was not a digit (should not be possible)
    InvalidCharacter,

    /// The input was empty or had no digits at the start
    NoDigitsFound,
};

fn parseLine(line: []const u8) ParseError!Line {
    var slice = line;
    const min = try chompU32(line);
    slice = slice[min.size..]; // size of min int
    slice = slice[1..]; // dash between min and max numbers
    const max = try chompU32(slice);
    slice = slice[max.size..]; // size of max int
    slice = slice[1..]; // space before letter
    const letter = slice[0];
    slice = slice[3..]; // letter and separators: 'a: '
    const password = slice;
    return Line{
        .min = min.value,
        .max = max.value,
        .letter = letter,
        .password = password,
    };
}

test "parse line" {
    const actual = try parseLine("15-16 m: mhmjmzrmmlmmmmmm");
    expectEqual(@as(u32, 15), actual.min);
    expectEqual(@as(u32, 16), actual.max);
    expectEqual(@as(u8, 'm'), actual.letter);
    expectEqualStrings("mhmjmzrmmlmmmmmm", actual.password);
}

test "parse line single digit min and max" {
    const actual = try parseLine("5-6 d: dcdddhzld");
    expectEqual(@as(u32, 5), actual.min);
    expectEqual(@as(u32, 6), actual.max);
    expectEqual(@as(u8, 'd'), actual.letter);
    expectEqualStrings("dcdddhzld", actual.password);
}

fn isValid1(line: Line) bool {
    var occurances: u32 = 0;
    for (line.password) |byte| {
        if (line.letter == byte) {
            occurances += 1;
        }
    }
    return line.min <= occurances and occurances <= line.max;
}

test "isValid1" {
    expect(isValid1(Line{ .min = 1, .max = 3, .letter = 'a', .password = "abcde" }));
    expect(!isValid1(Line{ .min = 1, .max = 3, .letter = 'b', .password = "cdefg" }));
    expect(isValid1(Line{ .min = 2, .max = 9, .letter = 'c', .password = "ccccccccc" }));
}

fn isValid2(line: Line) bool {
    var matches: u32 = 0;
    for (line.password) |byte, index| {
        const pos = index + 1;
        const position_matches = (pos == @as(usize, line.min) or pos == @as(usize, line.max));
        if (byte == line.letter and position_matches) {
            matches += 1;
        }
    }
    return matches == 1;
}

const ChompedU32 = struct {
    value: u32,
    size: usize,
};

fn chompU32(string: []const u8) ParseError!ChompedU32 {
    var i: usize = 0;
    for (string) |byte, index| {
        switch (byte) {
            48...57 => {
                i = index + 1;
            },
            else => {
                break;
            },
        }
    }
    if (i > 0) {
        var number_str: []const u8 = string[0..i];
        const n = try std.fmt.parseInt(u32, number_str, 10);
        return ChompedU32{ .value = n, .size = i };
    }
    return error.NoDigitsFound;
}

test "chomp ints" {
    expectEqual(ChompedU32{ .value = 1, .size = 1 }, try chompU32("1-abc"));
    var actual = chompU32("abc-abc");
    expectError(error.NoDigitsFound, actual);
    actual = chompU32("999999999999999999999999999999999999999999");
    expectError(error.Overflow, actual);
    expectEqual(ChompedU32{ .value = 123, .size = 3 }, try chompU32("123"));
}
