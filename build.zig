const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const writer = std.io.getStdErr().writer();
    _ = writer;

    const exe = b.addExecutable(.{
        .name = "vulkan-experiments",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibC();
    exe.linkLibCpp();

    const root_target = (std.zig.system.NativeTargetInfo.detect(exe.target) catch @panic("failed to detect native target info")).target;
    
    const vk_lib_name = if(root_target.os.tag == .windows) "vulkan-1" else "vulkan";
    exe.linkSystemLibrary(vk_lib_name);
    if (b.env_map.get("VK_SDK_PATH")) |path| {
        exe.addLibraryPath(.{ .cwd_relative = std.fmt.allocPrint(b.allocator, "{s}/Lib", .{ path }) catch @panic("Could not add Vulkan library") });
        exe.addIncludePath(.{ .cwd_relative = std.fmt.allocPrint(b.allocator, "{s}/Include", .{ path }) catch @panic("Could not add Vulkan headers")});
    }

    exe.linkSystemLibrary("SDL2");
    exe.addLibraryPath(.{ .cwd_relative = "thirdparty/sdl2/lib" });
    exe.addIncludePath(.{ .cwd_relative = "thirdparty/sdl2/include" });

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);
    if (root_target.os.tag == .windows) {
        b.installBinFile("thirdparty/sdl2/lib/SDL2.dll", "SDL2.dll");
    }

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
