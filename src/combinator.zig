const std = @import("std");

const mem = std.mem;
const Allocator = std.mem.Allocator;

const File = std.fs.File;
const StreamSource = std.io.StreamSource;
const fixedBufferStream = std.io.fixedBufferStream;

const print = std.debug.print;
const testing = std.testing;

const Error = error{ParseFailed} || Allocator.Error || File.ReadError || File.SeekError;

fn noop(comptime T: type) fn (T) void {
    return struct {
        fn f(_: T) void {}
    }.f;
}

fn ensureFn(comptime visitor: anytype) std.builtin.Type.Fn {
    switch (@typeInfo(@TypeOf(visitor))) {
        .Fn => |f| return f,
        else => @compileError("visitor must be a function"),
    }
}

test "ensureFn" {
    try testing.expect(@TypeOf(ensureFn(noop(u8))) == std.builtin.Type.Fn);
}

fn ReturnType(comptime visitor: anytype) type {
    return ensureFn(visitor).return_type.?;
}

test "ReturnType" {
    try testing.expect(ReturnType(noop(u8)) == void);
}

fn ParamTypes(comptime visitor: anytype) []const type {
    const params = ensureFn(visitor).params;
    var types: [params.len]type = undefined;

    for (params, 0..) |param, i| {
        types[i] = param.type.?;
    }
    const cast: []const type = &types;
    return cast;
}

test "ParamType" {
    const types = ParamTypes(noop(u8));
    try testing.expect(types.len == 1);
    try testing.expect(types[0] == u8);
}

fn visit(
    comptime visitor: anytype,
    comptime context: anytype,
) ReturnType(visitor) {
    // validate the signature of the visitor
    _ = ensureFn(visitor);

    if (ReturnType(visitor) == std.builtin.Type.ErrorUnion) {
        return try visitor(context);
    } else {
        return visitor(context);
    }
}

pub fn Combinator(comptime visitor: anytype) type {
    return fn (Allocator, *StreamSource) Error!ReturnType(visitor);
}

pub fn literal(
    comptime visitor: anytype,
    comptime str: []const u8,
) Combinator(visitor) {
    const types = ParamTypes(visitor);
    if (types.len != 1 or types[0] != []const u8) {
        @compileError("visitor must take a single parameter of type []const u8");
    }
    return struct {
        fn match(alc: Allocator, src: *StreamSource) Error!ReturnType(visitor) {
            const buf = try alc.alloc(u8, str.len);
            defer alc.free(buf);

            const count = try src.read(buf);

            if (count < str.len or !mem.eql(u8, buf, str)) {
                try src.seekBy(-@intCast(i64, count));
                return Error.ParseFailed;
            }
            return visit(visitor, str);
        }
    }.match;
}

test "literal" {
    var src = StreamSource{ .const_buffer = fixedBufferStream("hello") };
    try literal(noop([]const u8), "hello")(testing.allocator, &src);
}

// pub fn eos(comptime visitor: anytype) Combinator(visitor) {
//     return struct {
//         fn match(rest: []u8) Error!ReturnType(visitor) {
//             if (rest.len != 0) {
//                 return Error.ParseFailed;
//             }
//             return visit(visitor, rest);
//         }
//     }.match;
// }

// pub fn choice(
//     comptime visitor: anytype,
//     comptime cs: []Combinator,
// ) Combinator(visitor) {
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
