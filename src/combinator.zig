const std = @import("std");
const util = @import("util.zig");

const Allocator = std.mem.Allocator;

const File = std.fs.File;
const StreamSource = std.io.StreamSource;

const testing = std.testing;
const expect = testing.expect;
const expectError = testing.expectError;

pub const Error = error{ParseFailed} || Allocator.Error || File.ReadError || File.SeekError;

pub fn Combinator(comptime ReturnType: type) type {
    return fn (Allocator, *StreamSource) Error!ReturnType;
}

pub const Context = struct {
    const Self = @This();

    str: []const u8,
    pos: struct { start: usize, end: usize },

    pub fn init(str: []const u8, start: usize, end: usize) Self {
        return Self{
            .str = str,
            .pos = .{ .start = start, .end = end },
        };
    }
};

pub fn Visitor(comptime ReturnType: type) type {
    return fn (Context) Error!ReturnType;
}

fn noop(_: Context) !void {}

fn visit(
    comptime visitor: anytype,
    context: Context,
) util.ReturnType(visitor) {
    const types = util.ParamTypes(visitor);
    if (types.len != 1 or types[0] != Context) {
        @compileError("visitor must take a single parameter of type Context");
    }
    if (util.ReturnType(visitor) == std.builtin.Type.ErrorUnion) {
        return try visitor(context);
    } else {
        return visitor(context);
    }
}

pub fn literal(
    comptime ReturnType: type,
    comptime visitor: fn (Context) Error!ReturnType,
    comptime str: []const u8,
) Combinator(ReturnType) {
    return struct {
        fn match(alc: Allocator, src: *StreamSource) Error!ReturnType {
            const buf = try alc.alloc(u8, str.len);
            defer alc.free(buf);
            const start = try src.getPos();
            const count = try src.read(buf);
            if (count < str.len or !std.mem.eql(u8, buf, str)) {
                try src.seekBy(-@intCast(i64, count));
                return Error.ParseFailed;
            }
            const ctx = Context.init(str, start, start + count);
            return visit(visitor, ctx);
        }
    }.match;
}

test "literal" {
    const cmb = literal(void, noop, "hello");

    var src = util.streamSource("hello");
    try cmb(testing.allocator, &src);

    src = util.streamSource("");
    try expectError(Error.ParseFailed, cmb(testing.allocator, &src));
}

pub fn eos(
    comptime ReturnType: type,
    comptime visitor: fn (Context) Error!ReturnType,
) Combinator(ReturnType) {
    return struct {
        fn match(alc: Allocator, src: *StreamSource) Error!ReturnType {
            const buf = try alc.alloc(u8, 1);
            defer alc.free(buf);
            const count = try src.read(buf);
            if (count > 0) {
                try src.seekBy(-@intCast(i64, count));
                return Error.ParseFailed;
            }
            const pos = try src.getPos() + 1;
            return visit(visitor, Context.init("", pos, pos));
        }
    }.match;
}

test "eos" {
    const cmb = eos(void, noop);

    var src = util.streamSource("");
    try cmb(testing.allocator, &src);

    src = util.streamSource("hello");
    try expectError(Error.ParseFailed, cmb(testing.allocator, &src));
}

// pub fn one(
//     comptime visitor: anytype,
//     comptime cs: []Combinator,
// ) Combinator(visitor) {
//     _ = cs;
//     return struct {
//         fn match(rest: []u8) Error!ReturnType(visitor) {
//             var res: [cs.len]ReturnType(visitor) = undefined;
//             for (cs) |combinator| {
//                 const res = try combinator(rest);
//                 return res;
//             }
//             return Error.ParseFailed;
//         }
//     }.match;
// }
