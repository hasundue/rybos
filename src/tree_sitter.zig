const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const musl = std.musl;

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

    pub fn delete(self: Tree) void {
        c.ts_tree_delete(self.c);
    }
};

pub fn rootOf(tree: Tree) Node {
    return .{
        .c = c.ts_tree_root_node(tree.c),
    };
}

const Node = struct {
    c: c.TSNode,

    pub fn child(self: Node, id: u8) Node {
        return .{
            .c = c.ts_node_child(self.c, id),
        };
    }

    pub fn namedChild(self: Node, id: u8) Node {
        return .{
            .c = c.ts_node_named_child(self.c, id),
        };
    }

    pub fn is(self: Node, expected: []const u8) bool {
        const actual = typeOf(self);
        return mem.eql(u8, expected, actual);
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

    pub fn parse(self: Parser, str: []const u8) !Tree {
        return .{
            .c = c.ts_parser_parse_string(
                self.c,
                null,
                &str[0],
                @intCast(u32, str.len),
            ) orelse return ParserError.ParseFailed,
        };
    }

    pub fn delete(self: Parser) void {
        c.ts_parser_delete(self.c);
    }
};

pub fn createParser() !Parser {
    const parser = .{
        .c = c.ts_parser_new() orelse {
            return ParserError.ParserNotCreated;
        },
    };
    const success = c.ts_parser_set_language(
        parser.c,
        tree_sitter_rybos(),
    );
    if (!success) {
        return ParserError.LanguageNotAssigned;
    }
    return parser;
}

test "Parser" {
    // Create a parser
    const parser = try createParser();
    defer parser.delete();
    try testing.expectEqual(Parser, @TypeOf(parser));

    // Source code for testing
    const str = "0.12 + 3.45";

    // Parse the source code and create a tree
    const tree = try parser.parse(str);
    defer tree.delete();
    try testing.expectEqual(Tree, @TypeOf(tree));

    // Check the type of the root node
    const root = rootOf(tree);
    try testing.expectEqual(Node, @TypeOf(root));
    try testing.expect(mem.eql(u8, "source_file", typeOf(root)));

    // Check the child nodes
    try testing.expect(childCount(root) == 3);
    const float_left = root.namedChild(0);
    const add = root.namedChild(1);
    const float_right = root.namedChild(2);
    try testing.expect(float_left.is("float"));
    try testing.expect(add.is("binary_expression"));
    try testing.expect(float_right.is("float"));
}
