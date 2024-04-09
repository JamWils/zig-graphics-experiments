const std = @import("std");
const Step = std.Build.Step;
const StepRun = std.Build.Step.Run;
const LazyPath = std.Build.LazyPath;

const LibtoolStep = @This();

/// The step to depend on.
step: *Step,

/// The output file from the step to link.
output: LazyPath,

pub const Options = struct {
    /// The name of the step.
    name: []const u8,

    /// The name of the output file.
    output_name: []const u8,

    /// The list of input files to link.
    sources: []LazyPath,
};

pub fn create(b: *std.Build, opts: Options) *LibtoolStep {
    const self = b.allocator.create(LibtoolStep) catch @panic("OOM");
    const step_run = StepRun.create(b, b.fmt("libtool: {s}", .{opts.name}));

    step_run.addArgs(&.{ "libtool", "-static", "-o" });
    const output = step_run.addOutputFileArg(opts.output_name);

    for (opts.sources) |source| {
        step_run.addFileArg(source);
    }

    self.* = .{
        .step = &step_run.step,
        .output = output,
    };

    return self;
}