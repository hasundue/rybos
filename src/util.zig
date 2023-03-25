const std = @import("std");
const expect = std.testing.expect;

pub fn streamSource(str: []const u8) std.io.StreamSource {
    return std.io.StreamSource{ .const_buffer = std.io.fixedBufferStream(str) };
}

fn noop(comptime T: type) fn (T) void {
    return struct {
        fn f(_: T) void {}
    }.f;
}

pub fn ensureFn(comptime f: anytype) std.builtin.Type.Fn {
    switch (@typeInfo(@TypeOf(f))) {
        .Fn => |F| return F,
        else => @compileError("expected function type, found '" ++ @typeName(@TypeOf(f)) ++ "'"),
    }
}

test "ensureFn" {
    try expect(@TypeOf(ensureFn(noop(u8))) == std.builtin.Type.Fn);
}

pub fn ReturnType(comptime f: anytype) type {
    return ensureFn(f).return_type.?;
}

test "ReturnType" {
    try expect(ReturnType(noop(u8)) == void);
}

pub fn ParamTypes(comptime f: anytype) []const type {
    const params = ensureFn(f).params;
    var types: [params.len]type = undefined;

    for (params, 0..) |param, i| {
        types[i] = param.type orelse @TypeOf(null);
    }
    const cast: []const type = &types;
    return cast;
}

test "ParamType" {
    const types = ParamTypes(noop(u8));
    try expect(types.len == 1);
    try expect(types[0] == u8);
}
