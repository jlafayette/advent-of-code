const std = @import("std");
const expect = std.testing.expect;
const print = std.debug.print;
const input = @embedFile("input");

pub fn main() anyerror!void {
    // part 1: 204
    var iter = std.mem.split(input, "\r\n\r\n");
    var valid: usize = 0;
    while (true) {
        var slice = iter.next() orelse break;
        var tokens = std.mem.tokenize(slice, "\r\n ");
        var required: u7 = 0;
        while (true) {
            var t = tokens.next() orelse break;
            const field: []const u8 = t[0..3];
            if (std.mem.eql(u8, field, "ecl")) {
                required |= 1;
            }
            if (std.mem.eql(u8, field, "pid")) {
                required |= 2;
            }
            if (std.mem.eql(u8, field, "eyr")) {
                required |= 4;
            }
            if (std.mem.eql(u8, field, "hcl")) {
                required |= 8;
            }
            if (std.mem.eql(u8, field, "byr")) {
                required |= 16;
            }
            if (std.mem.eql(u8, field, "iyr")) {
                required |= 32;
            }
            if (std.mem.eql(u8, field, "hgt")) {
                required |= 64;
            }
        }
        if (required == @as(u7, 127)) {
            valid += 1;
        }
    }
    print("part 1: {d}\n", .{valid});

    // part 2: 179
    iter = std.mem.split(input, "\r\n\r\n");
    valid = 0;
    while (true) {
        var slice = iter.next() orelse break;
        var tokens = std.mem.tokenize(slice, "\r\n ");
        var required: u7 = 0;
        while (true) {
            var t = tokens.next() orelse break;
            if (t.len < 4) {
                continue;
            }
            const field: []const u8 = t[0..3];
            const value: []const u8 = t[4..];
            if (std.mem.eql(u8, field, "ecl") and eclIsValid(value)) {
                required |= 1;
            }
            if (std.mem.eql(u8, field, "pid") and pidIsValid(value)) {
                required |= 2;
            }
            if (std.mem.eql(u8, field, "eyr") and eyrIsValid(value)) {
                required |= 4;
            }
            if (std.mem.eql(u8, field, "hcl") and hclIsValid(value)) {
                required |= 8;
            }
            if (std.mem.eql(u8, field, "byr") and byrIsValid(value)) {
                required |= 16;
            }
            if (std.mem.eql(u8, field, "iyr") and iyrIsValid(value)) {
                required |= 32;
            }
            if (std.mem.eql(u8, field, "hgt") and hgtIsValid(value)) {
                required |= 64;
            }
        }
        if (required == @as(u7, 127)) {
            valid += 1;
        }
    }
    print("part 2: {d}\n", .{valid});
}

test "out of range" {
    const str = "aaa";
    if (str.len < 4) {
        return;
    }
    print("\nfield: {s}\n", .{str[0..3]});
    print("value: {s}\n", .{str[4..]});
    print("\n\n", .{});
}

fn eclIsValid(value: []const u8) bool {
    // assert value in {"amb", "blu", "brn", "gry", "grn", "hzl", "oth"}
    if (std.mem.eql(u8, value, "amb")) {
        return true;
    }
    if (std.mem.eql(u8, value, "blu")) {
        return true;
    }
    if (std.mem.eql(u8, value, "brn")) {
        return true;
    }
    if (std.mem.eql(u8, value, "gry")) {
        return true;
    }
    if (std.mem.eql(u8, value, "grn")) {
        return true;
    }
    if (std.mem.eql(u8, value, "hzl")) {
        return true;
    }
    if (std.mem.eql(u8, value, "oth")) {
        return true;
    }
    return false;
}

test "numbers" {
    print("\n0-9: {d}-{d}\n", .{ '0', '9' });
    print("a-f: {d}-{d}\n", .{ 'a', 'f' });
    print("\n\n", .{});
}

fn pidIsValid(value: []const u8) bool {
    // pid (Passport ID) - a nine-digit number, including leading zeroes.
    if (value.len != 9) {
        return false;
    }
    for (value) |byte| {
        if (byte < 48 or byte > 57) {
            return false;
        }
    }
    return true;
}

fn eyrIsValid(value: []const u8) bool {
    // eyr (Expiration Year) - four digits; at least 2020 and at most 2030.
    if (value.len != 4) {
        return false;
    }
    if (std.fmt.parseInt(usize, value, 10)) |number| {
        if (number < 2020 or number > 2030) {
            return false;
        }
    } else |err| {
        return false;
    }
    return true;
}

fn hclIsValid(value: []const u8) bool {
    // hcl (Hair Color) - a # followed by exactly six characters 0-9 or a-f.
    if (value.len != 7) {
        return false;
    }
    if (value[0] != '#') {
        return false;
    }
    for (value[1..]) |byte| {
        // 0-9 -> 48-57
        // a-f -> 97-102
        if (!((byte >= 48 and byte <= 57) or (byte >= 97 and byte <= 102))) {
            return false;
        }
    }
    return true;
}

fn byrIsValid(value: []const u8) bool {
    // byr (Birth Year) - four digits; at least 1920 and at most 2002.
    if (value.len != 4) {
        return false;
    }
    if (std.fmt.parseInt(usize, value, 10)) |number| {
        if (number < 1920 or number > 2002) {
            return false;
        }
    } else |err| {
        return false;
    }
    return true;
}

fn iyrIsValid(value: []const u8) bool {
    // iyr (Issue Year) - four digits; at least 2010 and at most 2020.
    if (value.len != 4) {
        return false;
    }
    if (std.fmt.parseInt(usize, value, 10)) |number| {
        if (number < 2010 or number > 2020) {
            return false;
        }
    } else |err| {
        return false;
    }
    return true;
}

fn hgtIsValid(value: []const u8) bool {
    // hgt (Height) - a number followed by either cm or in:
    // If cm, the number must be at least 150 and at most 193.
    // If in, the number must be at least 59 and at most 76.
    var number_str = std.mem.trimRight(u8, value, "incm");
    if (std.fmt.parseInt(usize, number_str, 10)) |number| {
        if (std.mem.endsWith(u8, value, "cm")) {
            if (number < 150 or number > 193) {
                return false;
            }
        } else if (std.mem.endsWith(u8, value, "in")) {
            if (number < 59 or number > 76) {
                return false;
            }
        } else {
            return false;
        }
    } else |err| {
        return false;
    }
    return true;
}

test "bitwise operators" {
    print("\n", .{});
    var required: u7 = 0;
    required |= 1;
    required |= 8;
    print("{b}\n", .{required});
    print("\n", .{});
    std.testing.expectEqual(@as(u7, 0b1001), required);
}
