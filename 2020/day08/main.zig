const std = @import("std");
const print = std.debug.print;
const input = @embedFile("input");

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = &arena.allocator;

    var program = Program.init(alloc);
    program.run(input) catch |err| print("err: {}\n", .{err});
    print("part 1: {d}\n", .{program.acc});
    print("\n\n", .{});

    const result = try part2(alloc, input);
    print("part 2: {d}\n", .{result});
    print("\n\n", .{});
}

const Instruction = union(enum) {
    nop: i32,
    acc: i32,
    jmp: i32,
};

const Program = struct {
    acc: i32,
    pos: usize,
    line: u32,
    visited: std.AutoHashMap(u32, bool),

    fn init(alloc: *std.mem.Allocator) Program {
        var hm = std.AutoHashMap(u32, bool).init(alloc);
        return Program{ .acc = 0, .pos = 0, .line = 0, .visited = hm };
    }
    fn run(self: *Program, data: []const u8) !void {
        while (true) {
            // check for loop
            if (self.visited.get(self.line)) |value| {
                return error.LoopDetected;
            }
            try self.visited.put(self.line, true);

            const end = std.mem.indexOfScalarPos(u8, data, self.pos, '\n') orelse break;
            const line = data[self.pos..end];
            // print("line: '{s}'\n", .{line});
            const instruction = try parse(line);
            // take the current line, call a function to convert it into an
            // instruction, then execute the instruction.
            self.line += 1;
            switch (instruction) {
                .nop => |_| self.pos = end + 1,
                .acc => |n| {
                    self.pos = end + 1;
                    self.acc += n;
                },
                .jmp => |n| {
                    self.pos = end + 1;
                    try self.jmp(n - 1, data);
                },
            }
        }
    }
    fn jmp(self: *Program, n: i32, data: []const u8) !void {
        const new_line = @as(i64, self.line) + @as(i64, n);
        if (new_line < 0) {
            return error.OutOfRange;
        }
        self.line = @intCast(u32, new_line);
        var i = n;
        switch (n) {
            0 => return,
            1...2147483647 => while (i > 0) {
                i -= 1;
                const end = std.mem.indexOfScalarPos(u8, data, self.pos, '\n') orelse return error.OutOfRange;
                self.pos = end + 1;
            },
            else => while (i < 0) {
                i += 1;
                if (self.pos == 0) {
                    return error.OutOfRange;
                }
                const x = std.mem.lastIndexOfScalar(u8, data[0 .. self.pos - 1], '\n') orelse return error.OutOfRange;
                self.pos = @intCast(usize, x) + 1;
            },
        }
    }
};

fn parse(line: []const u8) !Instruction {
    const sign = line[4];
    const num_str = line[5..];
    var n = try std.fmt.parseInt(i32, num_str, 10);
    if (sign == '-') {
        n *= -1;
    }
    if (std.mem.eql(u8, line[0..3], "nop")) {
        return Instruction{ .nop = n };
    }
    if (std.mem.eql(u8, line[0..3], "acc")) {
        return Instruction{ .acc = n };
    }
    if (std.mem.eql(u8, line[0..3], "jmp")) {
        return Instruction{ .jmp = n };
    }
    return error.BadInstruction;
}

const Program2 = struct {
    acc: i32,
    line: usize,
    visited: std.AutoHashMap(usize, bool),

    fn init(alloc: *std.mem.Allocator) Program2 {
        var hm = std.AutoHashMap(usize, bool).init(alloc);
        return Program2{ .acc = 0, .line = 0, .visited = hm };
    }
    fn run(self: *Program2, instructions: std.ArrayList(Instruction)) !void {
        while (true) {
            // check for loop
            if (self.visited.get(self.line)) |_| {
                return error.LoopDetected;
            }
            try self.visited.put(self.line, true);

            // const end = std.mem.indexOfScalarPos(u8, data, self.pos, '\n') orelse break;
            // const line = data[self.pos..end];
            // print("line: '{s}'\n", .{line});
            if (self.line >= instructions.items.len) {
                return;
            }
            const instruction = instructions.items[self.line];
            // take the current line, call a function to convert it into an
            // instruction, then execute the instruction.
            self.line += 1;
            switch (instruction) {
                .nop => {},
                .acc => |n| {
                    self.acc += n;
                },
                .jmp => |n| {
                    try self.jmp(n - 1);
                },
            }
        }
    }
    fn jmp(self: *Program2, n: i32) !void {
        const new_line = @as(i128, self.line) + @as(i128, n);
        if (new_line < 0) {
            return error.OutOfRange;
        }
        self.line = @intCast(usize, new_line);
    }
};

fn part2(alloc: *std.mem.Allocator, data: []const u8) !i32 {
    var pos: usize = 0;
    var result: i32 = 0;

    // convert to array of instructions
    var instructions = std.ArrayList(Instruction).init(alloc);
    defer instructions.deinit();

    var iter = std.mem.split(data, "\n");
    while (iter.next()) |line| {
        const i = try parse(line);
        try instructions.append(i);
    }

    for (instructions.items) |instruction, idx| {
        var opposite = Instruction{ .nop = 0 };
        switch (instruction) {
            .acc => |_| continue,
            .nop => |n| {
                opposite = Instruction{ .jmp = n };
            },
            .jmp => |n| {
                opposite = Instruction{ .nop = n };
            },
        }

        const swap = instructions.items[idx];
        instructions.items[idx] = opposite;

        var progam = Program2.init(alloc);
        // printInstructions(&instructions);
        progam.run(instructions) catch |err| switch (err) {
            error.LoopDetected => {
                // print("{}\n", .{err});
                instructions.items[idx] = swap;
                continue;
            }, // try again
            error.OutOfRange => {
                print("caught: {}\n", .{err});
                return progam.acc;
            },
            error.OutOfMemory => {
                print("caught: {}\n", .{err});
                return progam.acc;
            },
        };
        return progam.acc;
    }
    print("finished with loop \n", .{});
    return error.NoSolution;
}

fn printInstructions(ins: *std.ArrayList(Instruction)) void {
    print("\n", .{});
    for (ins.items) |i, idx| {
        print("{d}: {}\n", .{ idx, i });
    }
}

test "part 1" {
    var data =
        \\nop +0
        \\acc +1
        \\jmp +4
        \\acc +3
        \\jmp -3
        \\acc -99
        \\acc +1
        \\jmp -4
        \\acc +6
    ;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = &arena.allocator;

    var program = Program.init(alloc);
    program.run(data) catch |err| print("err: {}\n", .{err});
    print("result: {d}\n", .{program.acc});
    print("\n\n", .{});
    std.testing.expectEqual(@as(i32, 5), program.acc);
}

test "part 2" {
    const data =
        \\nop +0
        \\acc +1
        \\jmp +4
        \\acc +3
        \\jmp -3
        \\acc -99
        \\acc +1
        \\jmp -4
        \\acc +6
    ;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = &arena.allocator;

    const result = try part2(alloc, data);
    print("result: {d}\n", .{result});
    print("\n\n", .{});
    std.testing.expectEqual(@as(i32, 8), result);
}
