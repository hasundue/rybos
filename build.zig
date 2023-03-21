const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .default_target = .{ .cpu_arch = .wasm32, .os_tag = .wasi, .abi = .musl },
    });

    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "rybos",
        .root_source_file = .{ .path = "src/tree_sitter.zig" },
        .target = target,
        .optimize = optimize,
    });

    // tree-sitter
    lib.addIncludePath("tree-sitter/lib/include");
    lib.addCSourceFile("tree-sitter/lib/src/lib.c", &[_][]const u8{});

    // tree-sitter-rybos
    lib.addIncludePath("tree-sitter-rybos/src");
    lib.addCSourceFile("tree-sitter-rybos/src/parser.c", &[_][]const u8{});

    // dependencies
    lib.addIncludePath("/usr/include");
    lib.linkLibC();
    lib.linkSystemLibrary("icuuc");

    lib.install();

    const tests = b.addTest(.{
        .root_source_file = .{ .path = "src/tree_sitter.zig" },
        .target = target,
        .optimize = optimize,
    });

    tests.addIncludePath("tree-sitter/lib/include");
    tests.addIncludePath("tree-sitter-rybos/src");
    tests.linkLibC();

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&tests.step);
}
