const std = @import("std");
const print = std.debug.print;

const Error = error{ ParseFailed, VisitorError };

fn checkParamType(comptime visitor: anytype) void {
    const params = switch (@typeInfo(@TypeOf(visitor))) {
        .Pointer => |p| @typeInfo(p.child).Fn.params,
        .Fn => |f| f.params,
        else => unreachable,
    };
    if (params.len != 1) {
        @compileError("visitor must accept exactly one parameter");
    }
    if (params[0].type.? != []const u8) {
        @compileError("visitor must accept []const u8");
    }
}

fn ReturnType(comptime visitor: anytype) type {
    return switch (@typeInfo(@TypeOf(visitor))) {
        .Pointer => |p| @typeInfo(p.child).Fn.return_type.?,
        .Fn => |f| f.return_type.?,
        else => unreachable,
    };
}

pub fn literal(
    comptime visitor: anytype,
    comptime str: []const u8,
) fn ([]const u8) Error!ReturnType(visitor) {
    checkParamType(visitor);
    return struct {
        fn match(src: []const u8) Error!ReturnType(visitor) {
            if (!std.mem.startsWith(u8, src, str)) {
                return Error.ParseFailed;
            }
            return visitor(str);
        }
    }.match;
}

fn debug(res: []const u8) void {
    print("matched: {s}\n", .{res});
}

test "literal" {
    _ = try literal(debug, "hello")("hello");
}
