const Build = @import("std").Build;

const main = Build.FileSource{
    .path = "src/main.zig",
};

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ptk = b.dependency("ptk", .{});

    const rybos = b.addModule("rybos", .{
        .source_file = main,
    });
    try rybos.dependencies.put("ptk", ptk.module("parser-toolkit"));

    const tests = b.addTest(.{
        .root_source_file = main,
        .target = target,
        .optimize = optimize,
    });
    tests.addModule("ptk", ptk.module("parser-toolkit"));

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&tests.run().step);
}
