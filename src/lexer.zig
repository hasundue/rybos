const tokens = .{
    .int = "[0-9]+",
    .float = "[0-9]+\\.[0-9]+",
};

const int = token("[0-9]+");

const Token = [2]([]const u8);

const Lexer = struct {
    pub fn init(comptime ts: []Token) Lexer {
        _ = ts;
        return null;
    }
};
