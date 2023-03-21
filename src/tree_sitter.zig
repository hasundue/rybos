const std = @import("std");
const testing = std.testing;

const c = @cImport({
    @cInclude("tree_sitter/api.h");
    @cInclude("tree_sitter/parser.h");
});

const tree_sitter_rybos = @import("tree_sitter_rybos.zig");

pub const Language = c.TSLanguage;

pub const Parser = struct {
    c: ?*c.TSParser,

    pub fn init() Parser {
        return .{
            .c = c.ts_parser_new(),
        };
    }

    pub fn setLanguage(self: Parser, lang: Language) void {
        c.ts_parser_set_language(self.c, lang);
    }

    pub fn language(self: Parser) Language {
        return c.ts_parser_language(self.c);
    }
};

test "instantiate a parser object" {
    const parser = Parser.init();
    try testing.expectEqual(Parser, @TypeOf(parser));
}

test "set a language" {
    const parser = Parser.init();
    const rybos = tree_sitter_rybos.create();
    parser.setLanguage(rybos);
}
