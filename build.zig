const std = @import("std");
const flecs = @import("flecs");
const vulkan = @import("vulkan");

const LibtoolStep = @import("./build/libtool_step.zig");
const LipoStep = @import("./build/lipo_step.zig");
const XCFrameworkStep = @import("./build/xcframework_step.zig");

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

    // const vulkan = b.dependency("vulkan", .{ .target = target, .optimize = optimize });
    // exe.linkLibrary(vulkan.artifact("vulkan"));

    exe.linkLibC();
    unit_tests.linkLibC();
    exe.linkLibCpp();
    unit_tests.linkLibCpp();

    @import("stb").addPathsToModule(&exe.root_module);

    buildFramework(b, optimize);

    const root_target = target.result;

    switch (root_target.os.tag) {
        .windows => {
            compileShaders(b);
            const imgui = b.dependency("imgui", .{ .target = target,.optimize = optimize });
            exe.linkLibrary(imgui.artifact("imgui"));

            const sdl = b.dependency("sdl", .{ .target = target, .optimize = optimize });
            exe.linkLibrary(sdl.artifact("sdl"));

            vulkan.addToCompileStep(b, target, exe);

            // exe.addIncludePath(.{ .path = "thirdparty/vma"});
            // unit_tests.addIncludePath(.{ .path = "thirdparty/vma"});
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

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}

fn buildFramework(b: *std.Build, optimize: std.builtin.OptimizeMode) void {
    var lib_step = b.step("darwin_lib", "this will build a static library for Apple OS");
    var build_libs_step = b.step("build-libs", "something");
    
    const target_count: comptime_int = 3;
    const target_ios_sim = std.zig.CrossTarget{ .os_tag = .ios, .cpu_arch = .aarch64, .abi = .simulator }; 
    const target_ios = std.zig.CrossTarget{ .os_tag = .ios, .cpu_arch = .aarch64 }; 
    const target_mac = std.zig.CrossTarget{ .os_tag = .macos, .cpu_arch = .aarch64 }; 
    // const target_mac_intel = std.zig.CrossTarget{ .os_tag = .macos, .cpu_arch = .x86_64 }; 
    const targets: [target_count]std.zig.CrossTarget = .{ target_ios_sim, target_ios, target_mac }; 

    const clib_files: [target_count]std.Build.LazyPath = .{
        .{ .path = "build/libc_ios.txt" },
        .{ .path = "build/libc_ios.txt" },
        .{ .path = "build/libc_macos.txt" },
        // .{ .path = "build/libc_macos.txt" },
    };

    var lipo_list = std.ArrayList(std.Build.LazyPath).init(b.allocator);
    defer lipo_list.deinit();
    for (targets, clib_files, 0..target_count) |t, clib_file, i| {
        const target_lib = b.resolveTargetQuery(t);
        const lib_name = std.fmt.allocPrint(b.allocator, "experiment-{}", .{i}) catch @panic("Failed to create a library name");
        const lib = b.addStaticLibrary(.{
            .name = lib_name,
            .root_source_file = .{ .path = "src/main_c.zig" },
            .target = target_lib,
            .optimize = optimize,
        });
        lib.bundle_compiler_rt = true;
        lib.linkLibC();
        
        // const lib_flecs_module = b.dependency("flecs", .{
        //     .target = target_lib,
        //     .optimize = optimize,
        // }).module("flecs");

        // lib.root_module.addImport("flecs", lib_flecs_module);
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
            lib.root_module.addImport(e.key_ptr.*, e.value_ptr.*);
        }
        
        lib.setLibCFile(clib_file);

        var lib_list = std.ArrayList(std.Build.LazyPath).init(b.allocator);
        defer lib_list.deinit();
        lib_list.append(.{ .generated = lib.getEmittedBin().generated }) catch |err| {
            std.debug.print("append to lib_list: {}", .{err});
        };

        var libtool_list = std.ArrayList(std.Build.LazyPath).init(b.allocator);
        defer libtool_list.deinit();
        const libtool = LibtoolStep.create(b, .{
            .name = "experiment",
            .output_name = "libexperiment",
            .sources = lib_list.items,
        });
        libtool.step.dependOn(&lib.step);
        libtool_list.append(libtool.output) catch |err| {
            std.debug.print("append to libtool_list: {}", .{err});
        };

        const static_lib_universal = LipoStep.create(b, .{
            .name = "experimentlipo",
            .output_name = "libexperimentlipo.a",
            .inputs = libtool_list.items,
        });
        // static_lib_universal.step.dependOn(build_libs_step);

        lipo_list.append(static_lib_universal.output) catch |err| {
            std.debug.print("append to lipo_list: {}", .{err});
        };
        static_lib_universal.step.dependOn(libtool.step);
        build_libs_step.dependOn(static_lib_universal.step);
        // lib_step.dependOn(static_lib_universal.step);
    }

    const xcframework = XCFrameworkStep.create(b, .{
        .name = "experimentKit",
        .output_path = "frameworks/experiment.xcframework",
        .library = lipo_list.items,
        .headers = .{ .path = "include" },
    });

    xcframework.step.dependOn(build_libs_step);
    lib_step.dependOn(xcframework.step);
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