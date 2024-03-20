const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "sdl",
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    const lib_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    const steps = [2]*std.Build.Step.Compile { lib, lib_unit_tests};
    for (steps) |step| {
        step.linkLibC();
        step.linkSystemLibrary("SDL2");
        step.addLibraryPath(.{ .path = thisDir() ++ "/upstream/sdl2/lib" });
        step.addIncludePath(.{ .path = thisDir() ++ "/upstream/sdl2/include" });
    }

    lib.installHeadersDirectory("upstream/sdl2/include", "SDL2");
    // b.installBinFile(sdkPath("/upstream/sdl2/lib/SDL2.dll"), "SDL2.dll");
    b.installArtifact(lib);


    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}

// pub fn addPaths(b: *std.Build, step: *std.Build.Step.Compile) void {
//     const sdl_path = "/libs/sdl2";
//     step.root_module.linkSystemLibrary("SDL2", .{});
//     step.root_module.addSystemIncludePath(.{ .cwd_relative = sdkPath(sdl_path ++ "/include") });
//     step.root_module.addLibraryPath(.{ .cwd_relative = sdkPath(sdl_path ++ "/lib") });
//     b.installBinFile(sdkPath("/libs/sdl2/lib/SDL2.dll"), "SDL2.dll");
// }

fn sdkPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}