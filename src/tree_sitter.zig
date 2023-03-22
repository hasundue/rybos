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

    pub fn getRoot(self: Tree) Node {
        return .{
            .c = c.ts_tree_root_node(self.c),
        };
    }
};

fn strlen(ptr: [*c]const u8) usize {
    var len: usize = 0;
    while (ptr[len] != 0) : (len += 1) {}
    return len;
}

const Node = struct {
    c: c.TSNode,

    pub fn getNamedChild(self: Node, id: u8) Node {
        return .{
            .c = c.ts_node_named_child(self.c, id),
        };
    }

    pub fn getType(self: Node) []const u8 {
        const ptr = c.ts_node_type(self.c);
        const len = strlen(ptr);
        return ptr[0..len];
    }
};

pub const Parser = struct {
    c: *c.TSParser,

    pub fn init() !Parser {
        const parser = .{
            .c = c.ts_parser_new() orelse return ParserError.ParserNotCreated,
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

    pub fn exec(self: Parser, str: []const u8) !Tree {
        return .{
            .c = c.ts_parser_parse_string(
                self.c,
                null,
                &str[0],
                @intCast(u32, str.len),
            ) orelse return ParserError.ParseFailed,
        };
    }
};

test "Parser" {
    const parser = try Parser.init();
    try testing.expectEqual(Parser, @TypeOf(parser));

    const str = "0.12 + 3.45";
    const tree = try parser.exec(str);
    try testing.expectEqual(Tree, @TypeOf(tree));

    const root = tree.getRoot();
    try testing.expectEqual(Node, @TypeOf(root));
    try testing.expect(mem.eql(u8, "source_file", root.getType()));

    const float_left = root.getNamedChild(0);
    const add = root.getNamedChild(1);
    const float_right = root.getNamedChild(2);

    try testing.expect(mem.eql(u8, "float", float_left.getType()));
    try testing.expect(mem.eql(u8, "binary_expression", add.getType()));
    try testing.expect(mem.eql(u8, "float", float_right.getType()));
}
