const std = @import("std");
const fs = std.fs;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "darwin",
        .root_source_file = b.addWriteFiles().add("empty.c", ""),
        .target = target,
        .optimize = optimize,
    });

    lib.linkLibC();
    addPaths(lib);
    b.installArtifact(lib);

    var step = b.step("get-metal", "this will copy the necessary frameworks for Metal");
    step.makeFn = &getMetalFrameworks;
    step.dependOn(b.default_step);
}

pub fn addPaths(step: *std.Build.Step.Compile) void {
    const macos_path = "/libs/system-sdk/macos";
    step.addSystemFrameworkPath(.{ .cwd_relative = sdkPath(macos_path ++ "/Frameworks") });
    step.addSystemIncludePath(.{ .cwd_relative = sdkPath(macos_path ++ "/include") });
    step.addLibraryPath(.{ .cwd_relative = sdkPath(macos_path ++ "/lib") });
}

pub fn addPathsToModule(mod: *std.Build.Module) void {
    const macos_path = "/libs/system-sdk/macos";
    mod.addSystemFrameworkPath(.{ .cwd_relative = sdkPath(macos_path ++ "/Frameworks") });
    mod.addSystemIncludePath(.{ .cwd_relative = sdkPath(macos_path ++ "/include") });
    mod.addLibraryPath(.{ .cwd_relative = sdkPath(macos_path ++ "/lib") });
}

fn sdkPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
}

fn getMetalFrameworks(_: *std.Build.Step, _: *std.Progress.Node) anyerror!void {
    const cwd = fs.cwd();
    const dst_macos_path = "libs/system-sdk/macos";
    try cwd.deleteTree(dst_macos_path);
    try cwd.makeDir(dst_macos_path);
    try cwd.makeDir(dst_macos_path ++ "/Frameworks");
    try cwd.makeDir(dst_macos_path ++ "/lib");

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) {
        @panic("Leaked memory");
    };

    const sdk_path = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX14.2.sdk";
    const src_path = sdk_path ++ "/System/Library/Frameworks";
    const dst_path = dst_macos_path ++ "/Frameworks";

    try walkFramework(gpa.allocator(), src_path ++ "/CoreFoundation.framework", dst_path ++ "/CoreFoundation.framework");
    try walkFramework(gpa.allocator(), src_path ++ "/Foundation.framework", dst_path ++ "/Foundation.framework");
    try walkFramework(gpa.allocator(), src_path ++ "/Metal.framework", dst_path ++ "/Metal.framework");
    try walkFramework(gpa.allocator(), src_path ++ "/MetalKit.framework", dst_path ++ "/MetalKit.framework");
    try walkFramework(gpa.allocator(), src_path ++ "/QuartzCore.framework", dst_path ++ "/QuartzCore.framework");
    try walkFramework(gpa.allocator(), sdk_path ++ "/usr/include", dst_macos_path ++ "/include");
    try cwd.deleteTree(dst_macos_path ++ "/include/apache2");

    const lib_path = sdk_path ++ "/usr/lib";
    const src_lib = try cwd.openDir(lib_path, .{});
    const dst_lib = try cwd.openDir(dst_macos_path ++ "/lib", .{});
    src_lib.copyFile("libobjc.tbd", dst_lib, "libobjc.tbd", .{}) catch |err| std.debug.print("Error copying libobjc.tbd: {}\n", .{err});
    src_lib.copyFile("libobjc.A.tbd", dst_lib, "libobjc.A.tbd", .{}) catch |err| std.debug.print("Error copying libobjc.A.tbd: {}\n", .{err});
}

fn walkFramework(alloc: std.mem.Allocator, src_path: []const u8, dst_path: []const u8) anyerror!void {
    const cwd = fs.cwd();

    var framework = cwd.openDir(src_path, .{ .iterate = true }) catch |err| {
        std.debug.print("Error opening source directory {s}: {}\n", .{ src_path, err });
        return error.UnexpectedEntryKind;
    };
    defer framework.close();

    try cwd.makeDir(dst_path);
    var dst_dir = cwd.openDir(dst_path, .{}) catch |err| {
        std.debug.print("Error opening destination directory {s}: {}\n", .{ dst_path, err });
        return error.FileNotFound;
    };
    defer dst_dir.close();

    var walker = try framework.walk(alloc);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        switch (entry.kind) {
            .file => {
                entry.dir.copyFile(entry.basename, dst_dir, entry.path, .{}) catch |err| std.debug.print("Error copying {s}: {}\n", .{ entry.path, err });
            },
            .directory => {
                const new_dst_path = try std.fmt.allocPrint(alloc, "{s}/{s}", .{ dst_path, entry.path });
                defer alloc.free(new_dst_path);

                cwd.makeDir(new_dst_path) catch |err| std.debug.print("Error creating directory {s}: {}\n", .{ new_dst_path, err });
            },
            .sym_link => {
                std.debug.print("Symlinks are not supported\n", .{});
            },
            else => {
                std.debug.print("Unexpected entry kind: {}\n", .{entry.kind});
            },
        }
    }
}