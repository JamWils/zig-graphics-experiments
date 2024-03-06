const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "stb",
        .root_source_file = b.addWriteFiles().add("empty.c", ""),
        .target = target,
        .optimize = optimize,
    });

    lib.linkLibC();
    b.installArtifact(lib);
}

pub fn addPathsToModule(mod: *std.Build.Module) void {
    mod.addIncludePath(.{ .cwd_relative = "libs/stb/libs/stb" });
    mod.addCSourceFile(.{ .file = .{ .cwd_relative = "libs/stb/src/stb_impl.c" }, .flags = &.{}});
}
