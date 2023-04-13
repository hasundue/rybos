const std = @import("std");
const m = @import("mecha/mecha.zig");

const testing = std.testing;

const source = m.many(.{ ws, expr });

const ws = m.discard(m.many(m.oneOf(.{
    m.utf8.char(0x0020),
    m.utf8.char(0x000A),
    m.utf8.char(0x000D),
    m.utf8.char(0x0009),
}), .{ .collect = false }));

const expr = ws;
