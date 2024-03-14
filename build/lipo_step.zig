const LipoStep = @This();

const std = @import("std");
const Step = std.Build.Step;
const StepRun = std.Build.Step.Run;
const LazyPath = std.Build.LazyPath;

step: *Step,
output: LazyPath,

pub const Options = struct {
    name: []const u8,
    output_name: []const u8,

    inputs: []LazyPath,
    // input_b: LazyPath,
};

pub fn create(b: *std.Build, opts: Options) *LipoStep {
    const self = b.allocator.create(LipoStep) catch @panic("OOM");

    const step_run = StepRun.create(b, b.fmt("lipo {s}", .{opts.name}));
    step_run.addArgs(&.{ "lipo", "-create", "-output" });

    const output = step_run.addOutputFileArg(opts.output_name);
    // step_run.addFileArg(opts.input_a);
    // run_step.addFileArg(opts.input_b);

    for (opts.inputs) |input| {
        step_run.addFileArg(input);
    }

    self.* = .{
        .step = &step_run.step,
        .output = output,
    };

    return self;
}