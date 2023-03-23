const Build = @import("std").Build;

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{
        .default_target = .{ .cpu_arch = .wasm32, .os_tag = .freestanding, .abi = .musl },
    });

    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "rybos",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const tests = b.addTest(.{
        .root_source_file = .{ .path = "src/tree_sitter.zig" },
        .optimize = optimize,
    });

    for ([_]*Build.CompileStep{ lib, tests }) |task| {
        // tree-sitter
        task.addIncludePath("lib/tree-sitter/lib/include");
        task.addCSourceFile("lib/tree-sitter/lib/src/lib.c", &[_][]const u8{});

        // tree-sitter-rybos
        task.addIncludePath("lib/tree-sitter-rybos/src");
        task.addCSourceFile("lib/tree-sitter-rybos/src/parser.c", &[_][]const u8{});

        // dependencies
        task.addIncludePath("/usr/include");
        task.linkLibC();
        task.linkSystemLibrary("icuuc");
    }

    lib.install();

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&tests.run().step);
}
