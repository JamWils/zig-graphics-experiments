const std = @import("std");
const Step = std.Build.Step;
const StepRun = Step.Run;
const LazyPath = std.Build.LazyPath;

const XCFrameworkStep = @This();

step: *Step,

pub const Options = struct {
    name: []const u8,
    output_path: []const u8,
    library: []LazyPath,
    headers: LazyPath,
};

pub fn create(b: *std.Build, opts: Options) *XCFrameworkStep {
    const self = b.allocator.create(XCFrameworkStep) catch @panic("OOM");

    const run = StepRun.create(b, b.fmt("xcframework {s}", .{opts.name}));
    run.has_side_effects = true;
    run.addArgs(&.{ "xcodebuild", "-create-xcframework" });

    for (opts.library) |lib| {
        run.addArg("-library");
        run.addFileArg(lib);

        run.addArg("-headers");
        run.addFileArg(opts.headers);
    }

    run.addArg("-output");
    run.addArg(opts.output_path);

    self.* = .{
        .step = &run.step,
    };

    return self;
}
