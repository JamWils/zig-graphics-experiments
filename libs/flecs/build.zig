const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // const lib = b.addStaticLibrary(.{
    //     .name = "flecs",
    //     .root_source_file = .{ .path = "src/root.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });
    // setupFlecs(lib);

    const mod = b.addModule("flecs", .{
        .root_source_file = .{ .path = "./src/root.zig" },
        .imports = &.{
        },
    });
    setupFlecsMod(mod);

    // lib.installHeader("./libs/flecs/flecs.h", "flecs.h");
    // setupFlecs(lib);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });
    setupFlecs(lib_unit_tests);
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}

pub fn setupFlecs(step: *std.Build.Step.Compile) void {
    step.linkLibC();
    step.addIncludePath(.{ .cwd_relative = "libs/flecs" });
    step.addCSourceFile(.{
        .file = .{ .path = "libs/flecs/flecs.c" },
        .flags = &.{
            "-fno-sanitize=undefined",
            "-DFLECS_NO_CPP",
            "-DFLECS_USE_OS_ALLOC",
            if (@import("builtin").mode == .Debug) "-DFLECS_SANITIZE" else "",
        },
    });
    if (step.rootModuleTarget().os.tag == .windows) {
        step.linkSystemLibrary("ws2_32");
    }
}

pub fn setupFlecsMod(step: *std.Build.Module) void {
    // step.linkLibC();
    step.addIncludePath(.{ .cwd_relative = "libs/flecs" });
    step.addCSourceFile(.{
        .file = .{ .path = "libs/flecs/flecs.c" },
        .flags = &.{
            "-fno-sanitize=undefined",
            "-DFLECS_NO_CPP",
            "-DFLECS_USE_OS_ALLOC",
            if (@import("builtin").mode == .Debug) "-DFLECS_SANITIZE" else "",
        },
    });
    // if (step.result.os.tag == .windows) {
    //     step.linkSystemLibrary("ws2_32");
    // }
}
