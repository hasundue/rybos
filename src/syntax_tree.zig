const std = @import("std");
const cmb = @import("combinator.zig");
const utl = @import("util.zig");

const testing = std.testing;

const Allocator = std.mem.Allocator;
const Parser = cmb.Combinator;

const Node = struct {
    const Self = @This();

    rule: []const u8,
    str: []const u8,
    pos: struct { start: usize, end: usize },

    // child: []const *Self,

    pub fn builder(comptime rule: []const u8) cmb.Visitor(Node) {
        return struct {
            fn visitor(ctx: cmb.Context) cmb.Error!Node {
                return .{
                    .rule = rule,
                    .str = ctx.str,
                    .pos = .{ .start = ctx.pos.start, .end = ctx.pos.end },
                };
            }
        }.visitor;
    }
};

test "init" {
    const parser = cmb.eos(Node, Node.builder("EOS"));
    var src = utl.streamSource("");

    const node = try parser(testing.allocator, &src);

    try testing.expectEqualStrings("EOS", node.rule);
    try testing.expectEqualStrings("", node.str);
    try testing.expect(node.pos.start == 1);
    try testing.expect(node.pos.end == 1);
}
