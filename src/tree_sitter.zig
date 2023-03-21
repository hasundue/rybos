const std = @import("std");
const testing = std.testing;

const c = @cImport({
    @cInclude("tree_sitter/api.h");
});

extern "c" fn tree_sitter_rybos() *c.TSLanguage;

const ParserError = error{
    ParserNotCreated,
    LanguageNotAssigned,
};

const Tree = struct {
    c: *c.TSTree,
};

pub const Parser = struct {
    c: *c.TSParser,

    pub fn init() ParserError!Parser {
        const parser = Parser{
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

    pub fn parse(self: Parser, str: []const u8) Tree {
        return Tree{
            .c = c.ts_parser_parse_string(self.c, null, str, str.len),
        };
    }
};

test "Parser" {
    const parser = Parser.init();
    try testing.expectEqual(Parser, @TypeOf(parser));

    const str = "0.12 + 3.45";
    const tree = parser.parse(str);
    try testing.expectEqual(Tree, @TypeOf(tree));
}
