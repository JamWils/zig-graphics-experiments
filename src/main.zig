const std = @import("std");
const testing = std.testing;
const builtin = @import("builtin");
const VulkanEngine = @import("vulkan_engine.zig");
const MetalEngine = @import("metal_engine.zig");


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
        // std.debug.print("MacOS verision at least 14: {}\n", .{macosVersionAtLeast(15, 0, 0)});
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

// pub fn macosVersionAtLeast(major: i64, minor: i64, patch: i64) bool {
//     // Get the objc class from the runtime
//     const NSProcessInfo = objc.getClass("NSProcessInfo").?;

//     // Call a class method with no arguments that returns another objc object.
//     const info = NSProcessInfo.msgSend(objc.Object, "processInfo", .{});

//     // Call an instance method that returns a boolean and takes a single
//     // argument.
//     return info.msgSend(bool, "isOperatingSystemAtLeastVersion:", .{
//         NSOperatingSystemVersion{ .major = major, .minor = minor, .patch = patch },
//     });
// }

// const NSOperatingSystemVersion = extern struct {
//     major: i64,
//     minor: i64,
//     patch: i64,
// };

test {
    testing.refAllDecls(@This());
}