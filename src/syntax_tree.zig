const std = @import("std");
const utl = @import("util.zig");
const cmb = @import("combinator.zig");

const t = std.testing;

const Node = struct {
    rule: []const u8,
    token: cmb.Result,

    // child: []const *Self,

    pub fn builder(comptime rule: []const u8) cmb.Visitor(Node) {
        return struct {
            fn visitor(res: cmb.Result) Node {
                return .{ .rule = rule, .token = res };
            }
        }.visitor;
    }
};

test "init" {
    const parse = cmb.eos(Node.builder("EOS"));
    var src = utl.streamSource("");

    var node = try parse(t.allocator, &src);
    try expectNode(.{
        .rule = "EOS",
        .token = .{ .str = "", .start = 0, .end = 0 },
    }, node);
}

fn expectNode(
    expected: Node,
    actual: Node,
) !void {
    try t.expectEqualStrings(expected.rule, actual.rule);
    try t.expectEqualStrings(expected.token.str, actual.token.str);
    try t.expect(expected.token.start == actual.token.start);
    try t.expect(expected.token.end == actual.token.end);
}
