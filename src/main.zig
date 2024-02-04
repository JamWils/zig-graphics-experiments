const std = @import("std");
const VulkanEngine = @import("vulkan_engine.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) {
        @panic("Leaked memory");
    };

    var engine = VulkanEngine.init(gpa.allocator());
    defer engine.cleanup();

    engine.run();
}
