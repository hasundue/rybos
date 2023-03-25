const std = @import("std");
const cmb = @import("combinator.zig");

const Allocator = std.mem.Allocator;
const Parser = cmb.Combinator;
const Visitor = fn ([]const u8) Node;

const eos = cmb.eos();
const @"const" = cmb.literal("const");

const parser = @"const"; // TODO

const Position = struct {
    start: usize,
    end: usize,
};

const Node = struct {
    const Self = @This();

    tree: *Tree,

    token: []const u8,
    syntax: comptime_int,
    position: Position,

    child: []const *Self,

    pub fn init(t: *Tree, s: []const u8, p: Position) Self {
        _ = t;
        _ = s;
        _ = p;
    }
};

const Tree = struct {
    const Self = @This();

    allocator: *Allocator,
    parser: Parser,
    root: *Node,

    pub fn init(a: Allocator, p: Parser, s: []const u8) Self {
        _ = s;
        _ = p;
        _ = a;
    }
};

const testing = std.testing;

test "init" {
    const parser = cmb.eos(
    const tree = SyntaxTree.init(testing.allocator, parser, "");
    try testing.expect(tree.root.token == "");
}
