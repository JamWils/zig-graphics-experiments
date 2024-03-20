const std = @import("std");

pub fn build(_: *std.Build) void {
    
}

/// Add the Vulkan SDK include path to the compile step
pub fn addIncludePaths(b: *std.Build, step: *std.Build.Step.Compile) void {
    if (b.graph.env_map.get("VK_SDK_PATH")) |path| {
        const include_path = std.fmt.allocPrint(b.allocator, "{s}/Include", .{ path }) catch @panic("Could not add Vulkan headers");
        defer b.allocator.free(include_path);
        step.addIncludePath(.{ .cwd_relative = include_path });
    } else {
        @panic("VK_SDK_PATH not set, cannot find Vulkan SDK");
    }
}

/// Add the Vulkan SDK include and library paths to the compile step
pub fn addToCompileStep(b: *std.Build, target: std.Build.ResolvedTarget, step: *std.Build.Step.Compile) void {
    const vk_lib_name = if(target.result.os.tag == .windows) "vulkan-1" else "vulkan";
    step.linkSystemLibrary(vk_lib_name);
    if (b.graph.env_map.get("VK_SDK_PATH")) |path| {
        const lib_path = std.fmt.allocPrint(b.allocator, "{s}/Lib", .{ path }) catch @panic("Could not add Vulkan library");
        const include_path = std.fmt.allocPrint(b.allocator, "{s}/Include", .{ path }) catch @panic("Could not add Vulkan headers");
        defer b.allocator.free(lib_path);
        defer b.allocator.free(include_path);

        step.addLibraryPath(.{ .cwd_relative = lib_path });
        step.addIncludePath(.{ .cwd_relative = include_path });

        const dll_path = std.fmt.allocPrint(b.allocator, "{s}/Bin", .{ path }) catch @panic("Could not add Vulkan DLL");
        defer b.allocator.free(dll_path);
        // lib.installHeadersDirectory(include_path, ".");

    } else {
        @panic("VK_SDK_PATH not set, cannot find Vulkan SDK");
    }
}

fn sdkPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
}