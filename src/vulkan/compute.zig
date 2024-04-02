const std = @import("std");
const c = @import("../clibs.zig");
const shader = @import("./shader.zig");

const ComputePipelineOpts = struct {
    device: c.VkDevice,
    queue_family_index: u32,
    allocator: std.mem.Allocator,
};

fn createBackgroundPipeline(_: std.mem.Allocator, _: ComputePipelineOpts) void {
    // const gradient_shader = try shader.createShaderModule(a, opts.device, "zig-out/shaders/gradient.comp.spv");

    // const pipeline_layout_create_info = c.VkPipelineLayoutCreateInfo{
    //     .sType = c.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
    //     .setLayoutCount = 0,
    //     .pSetLayouts = null,
    //     .pushConstantRangeCount = 0,
    //     .pPushConstantRanges = null,
    // };
}

fn clear() void {

}