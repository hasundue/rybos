const std = @import("std");

pub const Error = error{ParseError};

pub fn Result(comptime T: type) type {
    return struct {
        value: T,
        rest: []const u8 = "",
    };
}

fn expect(comptime T: type, expected: Error!Result(T), actual: Error!Result(T)) !void {
    const r_expected = expected catch |err| {
        try std.testing.expectError(err, actual);
        return;
    };
    const r_actual = try actual;
    try std.testing.expectEqualDeep(r_expected.value, r_actual.value);
    try std.testing.expectEqualStrings(r_expected.rest, r_actual.rest);
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
    try expect(u8, Error.ParseError, char('a')(""));
    try expect(u8, .{ .value = 'a', .rest = "" }, char('a')("a"));
}

pub fn main() void {}
