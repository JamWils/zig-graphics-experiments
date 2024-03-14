const std = @import("std");
const ecs = @import("flecs");
const app = @import("app.zig");
const vulkan_eng = @import("./vulkan/engine.zig");
const scene = @import("scene");
const sdl = @import("sdl.zig");
const testing = std.testing;
const builtin = @import("builtin");
const c = @import("clibs.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) {
        @panic("Leaked memory");
    };

    const world = ecs.init();
    defer _ = ecs.fini(world);
    
    try app.init(world, gpa.allocator());
    sdl.init(world);
    scene.init(world);

    if (builtin.os.tag == .windows) {
        std.debug.print("Windows {}\n", .{c.ImGuiWindowFlags});
        vulkan_eng.init(world);
    } else if (builtin.os.tag == .macos) {
        // std.debug.print("MacOS verision at least 14: {}\n", .{macosVersionAtLeast(15, 0, 0)});
        
    } else {
        @panic("platform not supported");
    }

    app.run(world);

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