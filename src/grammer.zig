const Token = enum {
    int,
};

fn rules(comptime t: Token) type {
    _ = t;
    return struct {
        fn repeat(r: Rule) Rule {}

        fn chice(r: Rule) Rule {}
        fn seq(r: Rule) Rule {}
    };
}

const r = rules(Token);

const grammar = r.repeat(expr);

const expr = r.choice(
    r.seq(
        Token.int,
        Token.int,
    ),
    Token.int,
);
