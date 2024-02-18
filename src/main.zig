const std = @import("std");
const builtin = @import("builtin");
const VulkanEngine = @import("vulkan_engine.zig");
const MetalEngine = @import("metal_engine.zig");
const darwin = @import("darwin");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) {
        @panic("Leaked memory");
    };

    if (builtin.os.tag == .windows) {
        var engine = VulkanEngine.init(gpa.allocator()) catch |err| {
            std.debug.print("Unable to create vulkan engine: {}\n", .{err});
            @panic("Unable to create vulkan engine");
        };
        defer engine.cleanup();
        try engine.run();
    } else if (builtin.os.tag == .macos) {
        var engine = MetalEngine.init(gpa.allocator()) catch |err| {
            std.debug.print("Unable to create metal engine: {}\n", .{err});
            @panic("Unable to create metal engine");
        };
        defer engine.cleanup();
        try engine.run();
    } else {
        @panic("platform not supported");
    }
}
