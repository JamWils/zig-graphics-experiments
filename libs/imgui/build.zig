const std = @import("std");
const sdl = @import("sdl");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "imgui",
        .target = target,
        .optimize = optimize,
    });

    const lib_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    sdl.addIncludePaths(lib);

    lib.linkLibC();
    lib.linkLibCpp();

    lib.addIncludePath(.{ .path = "upstream" });
    lib.addIncludePath(.{ .path = "src" });    

    lib.installHeader("src/cimgui.h", "imgui/cimgui.h");
    lib.installHeader("src/cimgui_impl.h", "imgui/cimgui_impl.h");
    // lib.installHeadersDirectory("upstream", "imgui");

    // TODO: Fix this function
    // walkUpstream(b, lib) catch |err| {
    //     std.debug.print("Error walking upstream: {}\n", .{err});
    // };

    const c_flags = &.{"-fno-sanitize=undefined"};
    lib.addCSourceFiles(.{
        .files = &.{ 
            // "src/cimgui.cpp",
            "upstream/imgui.cpp",
            "upstream/imgui_draw.cpp",
            "upstream/imgui_widgets.cpp",
            "upstream/imgui_demo.cpp",
            "upstream/imgui_tables.cpp",
        },
        .flags = c_flags,
    });

    lib.addCSourceFiles(.{
        .files = &.{
            "/upstream/backends/imgui_impl_sdl2.cpp",
    //         "/upstream/backends/imgui_impl_vulkan.cpp",
        },
        .flags = c_flags,
    });

    b.installArtifact(lib);

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}

fn walkUpstream(b: *std.Build, step: *std.Build.Step.Compile) !void {
    var upstream_dir = std.fs.cwd().openDir("upstream", .{}) catch |err| {
        std.debug.print("Error opening upstream directory: {}\n", .{err});
        return;
    };
    defer upstream_dir.close();

    var walker = upstream_dir.walk(b.allocator) catch |err| {
        std.debug.print("Error walking upstream directory: {}\n", .{err});
        return;
    };
    defer walker.deinit();

    while (try walker.next()) |entry| {
        switch (entry.kind) {
            .file => {
                const ext = std.fs.path.extension(entry.basename);
                if (std.mem.eql(u8, ext, "h")) {
                    const final_url = try std.fmt.allocPrint(b.allocator, "imgui/{s}", .{entry.basename});
                    defer b.allocator.free(final_url);
                    step.installHeader(entry.path, final_url);
                }
            },
            .directory => {
                
            },
            else => {
                continue;
            }
        }
    }

}
