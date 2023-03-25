const std = @import("std");
const cmb = @import("combinator.zig");
const testing = std.testing;

const Visitor = fn ([]const u8) SyntaxNode;

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
    position: Position,

    children: []const *Self,
};

const SyntaxTree = struct {
    const Self = @This();

    allocator: *std.mem.Allocator,
    parser: cmb.Combinator,
    root: *SyntaxNode,

    pub fn init(a: *std.mem.Allocator, p: cmb.Combinator, s: []const u8) Self {
        _ = s;
        _ = p;
        _ = a;
    }
};

test "init" {
    const alc = testing.allocator;
    const st = SyntaxTree.init(alc, parser, "");
    _ = st;
}
