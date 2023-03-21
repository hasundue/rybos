const std = @import("std");
const testing = std.testing;

const c = @cImport({
    @cInclude("tree_sitter/api.h");
});

const ParserError = error{
    ParserNotCreated,
    LanguageNotAssigned,
};

extern "c" fn tree_sitter_rybos() *c.TSLanguage;

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
};

test "instantiate a parser object" {
    const parser = Parser.init();
    try testing.expectEqual(Parser, @TypeOf(parser));
}
