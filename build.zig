const std = @import("std");
const flecs = @import("flecs");

pub fn build(b: *std.Build) !void {
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

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const scene_module = b.addModule("scene", .{
        .root_source_file = .{ .path = "src/main.zig" },
        .imports = &.{
            .{ .name = "core", .module = b.dependency("core", .{}).module("core") },
            .{ .name = "flecs", .module = b.dependency("flecs", .{}).module("flecs") },
            .{ .name = "scene", .module = b.dependency("scene", .{}).module("scene") },
            .{ .name = "zmath", .module = b.dependency("zmath", .{}).module("zmath") },
        }
    });

    var scene_iter = scene_module.import_table.iterator();
    while (scene_iter.next()) |e| {
        exe.root_module.addImport(e.key_ptr.*, e.value_ptr.*);
        unit_tests.root_module.addImport(e.key_ptr.*, e.value_ptr.*);
    }

    const imgui = b.dependency("imgui", .{ .target = target,.optimize = optimize });
    exe.linkLibrary(imgui.artifact("imgui"));

    const sdl = b.dependency("sdl", .{ .target = target, .optimize = optimize });
    exe.linkLibrary(sdl.artifact("sdl"));

    exe.linkLibC();
    unit_tests.linkLibC();
    exe.linkLibCpp();
    unit_tests.linkLibCpp();

    @import("stb").addPathsToModule(&exe.root_module);

    const root_target = target.result;

    switch (root_target.os.tag) {
        .windows => {
            compileShaders(b);
            const vk_lib_name = if(root_target.os.tag == .windows) "vulkan-1" else "vulkan";
            exe.linkSystemLibrary(vk_lib_name);
            unit_tests.linkSystemLibrary(vk_lib_name);
            if (b.graph.env_map.get("VK_SDK_PATH")) |path| {
                exe.addLibraryPath(.{ .cwd_relative = std.fmt.allocPrint(b.allocator, "{s}/Lib", .{ path }) catch @panic("Could not add Vulkan library") });
                unit_tests.addLibraryPath(.{ .cwd_relative = std.fmt.allocPrint(b.allocator, "{s}/Lib", .{ path }) catch @panic("Could not add Vulkan library") });
                exe.addIncludePath(.{ .cwd_relative = std.fmt.allocPrint(b.allocator, "{s}/Include", .{ path }) catch @panic("Could not add Vulkan headers")});
                unit_tests.addIncludePath(.{ .cwd_relative = std.fmt.allocPrint(b.allocator, "{s}/Include", .{ path }) catch @panic("Could not add Vulkan headers")});
            }

            exe.addIncludePath(.{ .path = "thirdparty/vma"});
            unit_tests.addIncludePath(.{ .path = "thirdparty/vma"});
        },
        .macos => {
            exe.root_module.addImport("objc", b.dependency("objc", .{
                .target = target,
                .optimize = optimize,
            }).module("objc"));
            exe.linkFramework("Foundation");
            exe.linkFramework("Metal");
            exe.linkFramework("QuartzCore");

            unit_tests.root_module.addImport("objc", b.dependency("objc", .{
                .target = target,
                .optimize = optimize,
            }).module("objc"));
            unit_tests.linkFramework("Foundation");
            unit_tests.linkFramework("Metal");
            unit_tests.linkFramework("QuartzCore");

        },
        else => unreachable
    } 

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

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

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}

fn compileShaders(b: *std.Build) void {
    const shaders_dir = if (@hasDecl(@TypeOf(b.build_root.handle), "openIterableDir"))
        b.build_root.handle.openIterableDir("shaders", .{}) catch @panic("Failed to open shaders iterable directory")
    else std.fs.cwd().openDir("shaders", .{ .iterate = true }) catch @panic("Failed to open shaders directory");

    var dir_iterator = shaders_dir.iterate();
    while(dir_iterator.next() catch @panic("cannot iterate directory")) |item| {
        if (item.kind == .file) {
            const extension = std.fs.path.extension(item.name);
            if (std.mem.eql(u8, extension, ".glsl")) {
                const basename = std.fs.path.basename(item.name);
                const name = basename[0..basename.len - extension.len];

                std.debug.print("Compiling shader: {s}\n", .{item.name});
                
                const validator_cmd = b.addSystemCommand(&.{ "glslangValidator"});

                const source_path = std.fmt.allocPrint(b.allocator, "shaders/{s}.glsl", .{name}) catch @panic("Failed to create sourc e path");
                validator_cmd.addArg("-V");
                validator_cmd.addFileArg(.{ .path = source_path});
                
                const output_path = std.fmt.allocPrint(b.allocator, "shaders/{s}.spv", .{name}) catch @panic("Failed to create output path");
                validator_cmd.addArg("-o");
                const out_file = validator_cmd.addOutputFileArg(output_path);

                validator_cmd.stdio = .zig_test;

                const install_shader = b.addInstallFileWithDir(out_file, .prefix, output_path);
                b.getInstallStep().dependOn(&install_shader.step);
            }
        }
    }
}