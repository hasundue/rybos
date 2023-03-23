const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const print = std.debug.print;

const c = @cImport({
    @cInclude("tree_sitter/api.h");
});

extern "c" fn tree_sitter_rybos() *c.TSLanguage;

const ParserError = error{
    ParserNotCreated,
    LanguageNotAssigned,
    ParseFailed,
    NotFound,
};

const Tree = struct {
    c: *c.TSTree,
    parser: *const Parser,

    pub fn delete(self: Tree) void {
        c.ts_tree_delete(self.c);
    }
};

pub fn rootOf(tree: Tree) Node {
    return .{
        .c = c.ts_tree_root_node(tree.c),
        .tree = &tree,
    };
}

const Node = struct {
    c: c.TSNode,
    tree: *const Tree,

    pub fn child(self: Node, id: u8) Node {
        return .{
            .c = c.ts_node_child(self.c, id),
            .tree = self.tree,
        };
    }

    pub fn namedChild(self: Node, id: u8) Node {
        return .{
            .c = c.ts_node_named_child(self.c, id),
            .tree = self.tree,
        };
    }

    pub fn is(self: Node, expected: []const u8) bool {
        const actual = typeOf(self);
        return mem.eql(u8, expected, actual);
    }

    pub fn toString(self: Node) []const u8 {
        const ptr = c.ts_node_string(self.c);
        const len = mem.len(ptr);
        return ptr[0..len];
    }
};

pub fn childCount(node: Node) u32 {
    return @intCast(u32, c.ts_node_child_count(node.c));
}

pub fn namedChildCount(node: Node) u32 {
    return @intCast(u32, c.ts_node_named_child_count(node.c));
}

pub fn typeOf(node: Node) []const u8 {
    const ptr = c.ts_node_type(node.c);
    const len = mem.len(ptr);
    return ptr[0..len];
}

pub const Parser = struct {
    c: *c.TSParser,

    pub fn init() !Parser {
        const c_parser_ptr = c.ts_parser_new() orelse {
            return ParserError.ParserNotCreated;
        };
        const success = c.ts_parser_set_language(
            c_parser_ptr,
            tree_sitter_rybos(),
        );
        if (!success) {
            return ParserError.LanguageNotAssigned;
        }
        return .{
            .c = c_parser_ptr,
        };
    }

    pub fn parse(self: Parser, str: []const u8) !Tree {
        return .{
            .c = c.ts_parser_parse_string(
                self.c,
                null,
                &str[0],
                @intCast(u32, str.len),
            ) orelse return ParserError.ParseFailed,
            .parser = &self,
        };
    }

    pub fn deinit(self: Parser) void {
        c.ts_parser_delete(self.c);
    }
};

test "Parser" {
    // Create a parser
    const parser = try Parser.init();
    defer parser.deinit();
    try testing.expectEqual(Parser, @TypeOf(parser));

    // Source code for testing
    const src = "0.12 + 3.45";

    // Parse the source code and create a tree
    const tree = try parser.parse(src);
    defer tree.delete();
    try testing.expectEqual(Tree, @TypeOf(tree));

    // Check the type of the root node
    const root = rootOf(tree);
    try testing.expectEqual(Node, @TypeOf(root));
    try testing.expect(mem.eql(u8, "source_file", typeOf(root)));

    const str = root.toString();
    try testing.expect(
        mem.eql(u8, "(source_file (float) (binary_expression) (float))", str),
    );

    // Check the child nodes
    try testing.expect(childCount(root) == 3);
    const float_left = root.namedChild(0);
    const add = root.namedChild(1);
    const float_right = root.namedChild(2);
    try testing.expect(float_left.is("float"));
    try testing.expect(add.is("binary_expression"));
    try testing.expect(float_right.is("float"));
}
