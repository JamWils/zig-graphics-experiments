const c = @import("../clibs.zig");

pub const Pipeline = struct {
    handle: c.VkPipeline,
    layout: c.VkPipelineLayout = undefined,
};