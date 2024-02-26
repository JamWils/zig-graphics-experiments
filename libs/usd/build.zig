const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // const lib = b.addStaticLibrary(.{
    //     .name = "usd",
    //     // In this case the main source file is merely a path, however, in more
    //     // complicated build scripts, this could be a generated file.
    //     .root_source_file = .{ .path = "src/main.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });

    // lib.linkLibC();
    // lib.linkLibCpp();
    // addOpenUsd(&lib.root_module);
    // lib.addIncludePath(.{ .path = thisDir() ++ "/src/include" });
    // lib.addCSourceFile(.{ .file = .{ .path = thisDir() ++ "/src/hello.cpp" }, .flags = &.{ "-std=c++17", "-fno-sanitize=undefined" } });

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    // b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "usd",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibC();
    exe.linkLibCpp();
    addOpenUsd(&exe.root_module);

    // exe.addIncludePath(.{ .path = thisDir() ++ "/src/include" });
    // exe.addCSourceFile(.{ .file = .{ .path = thisDir() ++ "/src/hello.cpp" }, .flags = &.{ "-std=c++17", "-fno-sanitize=undefined" } });

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // const lib_unit_tests = b.addTest(.{
    //     .root_source_file = .{ .path = "src/root.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}

fn materialXLibName(comptime base: []const u8) []const u8 {
    // return "MaterialX" ++ base ++ ".1.38.7";
    return "MaterialX" ++ base;
}

fn addOpenUsd(mod: *std.Build.Module) void {
    mod.addIncludePath(.{ .path = thisDir() ++ "/src/include" });
    mod.addCSourceFile(.{ .file = .{ .path = thisDir() ++ "/src/hello.cpp" }, .flags = &.{ "-std=c++17", "-fno-sanitize=undefined" } });

    // mod.linkFramework("OpenSubdiv_static", .{});
    mod.addIncludePath(.{ .path = "./OpenUSD/include" });

    mod.addFrameworkPath(.{ .path = "./OpenUSD/lib" });
    mod.linkFramework("OpenSubdiv_static", .{});
    mod.addRPath(.{ .path = "./OpenUSD/lib" });

    mod.addLibraryPath(.{ .path = "./OpenUSD/lib" });
    mod.linkSystemLibrary("boost_atomic", .{});
    mod.linkSystemLibrary("boost_regex", .{});
    mod.linkSystemLibrary(materialXLibName("Core"), .{});
    mod.linkSystemLibrary(materialXLibName("Format"), .{});
    mod.linkSystemLibrary(materialXLibName("GenGlsl"), .{});
    mod.linkSystemLibrary(materialXLibName("GenMdl"), .{});
    mod.linkSystemLibrary(materialXLibName("GenMsl"), .{});
    mod.linkSystemLibrary(materialXLibName("GenOsl"), .{});
    mod.linkSystemLibrary(materialXLibName("GenShader"), .{});
    mod.linkSystemLibrary(materialXLibName("Render"), .{});
    mod.linkSystemLibrary(materialXLibName("RenderGlsl"), .{});
    mod.linkSystemLibrary(materialXLibName("RenderHw"), .{});
    mod.linkSystemLibrary(materialXLibName("RenderMsl"), .{});
    mod.linkSystemLibrary(materialXLibName("RenderOsl"), .{});
    mod.linkSystemLibrary("osdCPU", .{});
    mod.linkSystemLibrary("osdGPU", .{});
    mod.linkSystemLibrary("tbb", .{});
    // mod.linkSystemLibrary("tbbmalloc", .{});
    // mod.linkSystemLibrary("tbbmalloc_debug", .{});
    // mod.linkSystemLibrary("tbbmalloc_proxy", .{});
    // mod.linkSystemLibrary("tbbmalloc_proxy_debug", .{});
    mod.linkSystemLibrary("usd_ar", .{});
    mod.linkSystemLibrary("usd_cameraUtil", .{});
    mod.linkSystemLibrary("usd_garch", .{});
    mod.linkSystemLibrary("usd_geomUtil", .{});
    mod.linkSystemLibrary("usd_gf", .{});
    mod.linkSystemLibrary("usd_glf", .{});
    mod.linkSystemLibrary("usd_hd", .{});
    mod.linkSystemLibrary("usd_hdar", .{});
    mod.linkSystemLibrary("usd_hdGp", .{});
    mod.linkSystemLibrary("usd_hdMtlx", .{});
    mod.linkSystemLibrary("usd_hdsi", .{});
    mod.linkSystemLibrary("usd_hdSt", .{});
    mod.linkSystemLibrary("usd_hdx", .{});
    mod.linkSystemLibrary("usd_hf", .{});
    mod.linkSystemLibrary("usd_hgi", .{});
    mod.linkSystemLibrary("usd_hgiGL", .{});
    mod.linkSystemLibrary("usd_hgiInterop", .{});
    mod.linkSystemLibrary("usd_hgiMetal", .{});
    mod.linkSystemLibrary("usd_hio", .{});
    mod.linkSystemLibrary("usd_js", .{});
    mod.linkSystemLibrary("usd_kind", .{});
    mod.linkSystemLibrary("usd_ndr", .{});
    mod.linkSystemLibrary("usd_pcp", .{});
    mod.linkSystemLibrary("usd_plug", .{});
    mod.linkSystemLibrary("usd_pxOsd", .{});
    mod.linkSystemLibrary("usd_sdf", .{});
    mod.linkSystemLibrary("usd_sdr", .{});
    mod.linkSystemLibrary("usd_tf", .{});
    mod.linkSystemLibrary("usd_trace", .{});
    mod.linkSystemLibrary("usd_ts", .{});
    mod.linkSystemLibrary("usd_usd", .{});
    mod.linkSystemLibrary("usd_usdAppUtils", .{});
    mod.linkSystemLibrary("usd_usdBakeMtlx", .{});
    mod.linkSystemLibrary("usd_usdGeom", .{});
    mod.linkSystemLibrary("usd_usdHydra", .{});
    mod.linkSystemLibrary("usd_usdImaging", .{});
    mod.linkSystemLibrary("usd_usdImagingGL", .{});
    mod.linkSystemLibrary("usd_usdLux", .{});
    mod.linkSystemLibrary("usd_usdMedia", .{});
    mod.linkSystemLibrary("usd_usdMtlx", .{});
    mod.linkSystemLibrary("usd_usdPhysics", .{});
    mod.linkSystemLibrary("usd_usdProc", .{});
    mod.linkSystemLibrary("usd_usdProcImaging", .{});
    mod.linkSystemLibrary("usd_usdRender", .{});
    mod.linkSystemLibrary("usd_usdRi", .{});
    mod.linkSystemLibrary("usd_usdRiPxrImaging", .{});
    mod.linkSystemLibrary("usd_usdShade", .{});
    mod.linkSystemLibrary("usd_usdSkel", .{});
    mod.linkSystemLibrary("usd_usdSkelImaging", .{});
    mod.linkSystemLibrary("usd_usdUI", .{});
    mod.linkSystemLibrary("usd_usdUtils", .{});
    mod.linkSystemLibrary("usd_usdVol", .{});
    mod.linkSystemLibrary("usd_usdVolImaging", .{});
    mod.linkSystemLibrary("usd_vt", .{});
    mod.linkSystemLibrary("usd_work", .{});
    mod.linkSystemLibrary("z.1.2.13", .{});
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
