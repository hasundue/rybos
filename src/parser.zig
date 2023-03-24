const std = @import("std");
const ptk = @import("ptk");
const m = ptk.matchers;

const Token = enum {
    int,
};

const ptn = Pattern.create;

const Pattern = ptk.Pattern(Token);

const Tokenizer = ptk.Tokenizer(Token, &[_]Pattern{
    ptn(.int, m.decimalNumber),
});

test "number" {
    var tokens = Tokenizer.init("123", null);
    try testTokenizer(&tokens, .int, "123");
}

pub fn testTokenizer(
    t: *Tokenizer,
    kind: Token,
    value: ?[]const u8,
) !void {
    const token = (try t.next()) orelse return error.EndOfStream;
    if (value) |v| try std.testing.expectEqualStrings(v, token.text);
    try std.testing.expectEqual(kind, token.type);
}

test "syntax" {
    const source =
        \\@token int {
        \\    [0-9]+
        \\}
    ;
    _ = source;
}
