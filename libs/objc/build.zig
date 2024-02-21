const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "objc",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    _ = b.dependency("darwin", .{
        .target = target,
        .optimize = optimize,
    });

    // lib.root_module.addImport("darwin", darwin_dep.module("darwin"));
    // addPathsToModule(&lib.root_module);

    @import("darwin").addPaths(lib);

    _ = b.addModule("objc", .{
        .root_source_file = .{ .path = "./src/main.zig" },
    });

    lib.linkLibC();
    b.installArtifact(lib);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    
    @import("darwin").addPaths(lib_unit_tests);
    lib_unit_tests.linkSystemLibrary("objc");
    lib_unit_tests.linkFramework("Foundation");
    lib_unit_tests.linkLibC();
    b.installArtifact(lib_unit_tests);

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}

pub fn addPathsToModule(mod: *std.Build.Module) void {
    @import("darwin").addPathsToModule(mod);
}