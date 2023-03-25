const std = @import("std");
const cmb = @import("combinator.zig");

const Allocator = std.mem.Allocator;
const Parser = cmb.Combinator;
const Visitor = fn ([]const u8) SyntaxNode;

const eos = cmb.eos();
const @"const" = cmb.literal("const");

const parser = @"const"; // TODO

const Position = struct {
    start: usize,
    end: usize,
};

const SyntaxNode = struct {
    const Self = @This();

    tree: *SyntaxTree,

    token: []const u8,
    syntax: comptime_int,
    position: Position,

    child: []const *Self,
};

const SyntaxTree = struct {
    const Self = @This();

    allocator: *Allocator,
    parser: Parser,
    root: *SyntaxNode,

    pub fn init(a: Allocator, p: Parser, s: []const u8) Self {
        _ = s;
        _ = p;
        _ = a;
    }
};

const testing = std.testing;

test "init" {
    const tree = SyntaxTree.init(testing.allocator, parser, "");
    try testing.expect(tree.root.token == "");
}
