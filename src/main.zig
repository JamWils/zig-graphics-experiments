const std = @import("std");
const builtin = @import("builtin");
const VulkanEngine = @import("vulkan_engine.zig");

const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

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
        std.debug.print("This is a build on macOS {d}\n", .{c.SDL_INIT_VIDEO});
    } else {
        @panic("platform not supported");
    }
}
