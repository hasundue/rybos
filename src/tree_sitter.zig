const std = @import("std");
const testing = std.testing;

const c = @cImport({
    @cInclude("tree_sitter/api.h");
});

extern "c" fn tree_sitter_rybos() *c.TSLanguage;

pub const Parser = struct {
    c: ?*c.TSParser,

    pub fn init() Parser {
        const parser = Parser{
            .c = c.ts_parser_new(),
        };
        _ = c.ts_parser_set_language(
            parser.c,
            tree_sitter_rybos(),
        );
        return parser;
    }
};

test "instantiate a parser object" {
    const parser = Parser.init();
    try testing.expectEqual(Parser, @TypeOf(parser));
}
