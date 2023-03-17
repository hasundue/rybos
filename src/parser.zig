const std = @import("std");
const expect = std.testing.expect;
// const testing = std.testing;

pub const Error = error{ParseError};

pub fn Result(comptime T: type) type {
    return struct {
        value: T,
        rest: []const u8 = "",
    };
}

pub fn Parser(comptime T: type) type {
    return fn (input: []const u8) Error!Result(T);
}

fn char(comptime c: u8) Parser(u8) {
    return struct {
        fn parse(input: []const u8) Error!Result(u8) {
            if (input.len == 0 or c != input[0])
                return Error.ParseError;
            return .{ .value = c, .rest = input[1..] };
        }
    }.parse;
}

test "char" {
    const result = try char('a')("a");
    try expect(result.value == 'a');
}

pub fn main() void {}
