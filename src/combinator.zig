const std = @import("std");

const Allocator = std.mem.Allocator;
const StreamSource = std.io.StreamSource;

const testing = std.testing;
const expect = testing.expect;
const expectError = testing.expectError;

const util = @import("util.zig");
const ReturnType = util.ReturnType;

const File = std.fs.File;
pub const Error = error{ParseFailed} || Allocator.Error || File.ReadError || File.SeekError;

pub fn Combinator(comptime visitor: anytype) type {
    return fn (Allocator, *StreamSource) Error!ReturnType(visitor);
}

pub const Result = struct {
    str: []const u8,

    start: usize,
    end: usize,

    pub fn init(str: []const u8, start: usize, end: usize) Result {
        return .{ .str = str, .start = start, .end = end };
    }
};

pub fn Visitor(comptime T: type) type {
    return fn (Result) T;
}

fn noop(_: Result) void {}

fn visit(
    comptime visitor: anytype,
    context: Result,
) ReturnType(visitor) {
    const types = util.ParamTypes(visitor);
    if (types.len != 1 or types[0] != Result) {
        @compileError("visitor must take a single parameter of type Context");
    }
    if (util.ReturnType(visitor) == std.builtin.Type.ErrorUnion) {
        return try visitor(context);
    } else {
        return visitor(context);
    }
}

pub fn literal(
    comptime visitor: anytype,
    comptime str: []const u8,
) Combinator(visitor) {
    return struct {
        fn match(alc: Allocator, src: *StreamSource) Error!ReturnType(visitor) {
            const buf = try alc.alloc(u8, str.len);
            defer alc.free(buf);
            const start = try src.getPos();
            const count = try src.read(buf);
            if (count < str.len or !std.mem.eql(u8, buf, str)) {
                try src.seekBy(-@intCast(i64, count));
                return Error.ParseFailed;
            }
            return visit(visitor, Result.init(str, start, start + count));
        }
    }.match;
}

test "literal" {
    const parse = literal(noop, "hello");

    var src = util.streamSource("hello");
    try parse(testing.allocator, &src);

    src = util.streamSource("");
    try expectError(Error.ParseFailed, parse(testing.allocator, &src));
}

pub fn eos(comptime visitor: anytype) Combinator(visitor) {
    return struct {
        fn match(alc: Allocator, src: *StreamSource) Error!ReturnType(visitor) {
            const buf = try alc.alloc(u8, 1);
            defer alc.free(buf);
            const count = try src.read(buf);
            if (count > 0) {
                try src.seekBy(-@intCast(i64, count));
                return Error.ParseFailed;
            }
            const pos = try src.getPos();
            return visit(visitor, Result.init("", pos, pos));
        }
    }.match;
}

test "eos" {
    const cmb = eos(noop);

    var src = util.streamSource("");
    try cmb(testing.allocator, &src);

    src = util.streamSource("hello");
    try expectError(Error.ParseFailed, cmb(testing.allocator, &src));
}
