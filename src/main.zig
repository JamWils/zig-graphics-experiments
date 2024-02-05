const std = @import("std");
const VulkanEngine = @import("vulkan_engine.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) {
        @panic("Leaked memory");
    };

    var engine = VulkanEngine.init(gpa.allocator()) catch |err| {
        std.debug.print("Unable to create vulkan engine: {}\n", .{err});
        @panic("Unable to create vulkan engine");
    };
    defer engine.cleanup();

    engine.run();
}
