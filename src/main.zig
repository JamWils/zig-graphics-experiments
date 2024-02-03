const std = @import("std");

const c = @cImport({
    @cInclude("sdl.h");
    @cInclude("vulkan/vulkan.h");
});

pub fn main() !void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) < 0) {
        @panic("SDL init error");
    }
    defer c.SDL_Quit();

    _ = c.VK_NULL_HANDLE;

    const window = c.SDL_CreateWindow(
        "SDL2 Test", 
        c.SDL_WINDOWPOS_CENTERED, 
        c.SDL_WINDOWPOS_CENTERED, 
        800, 
        600, 
        c.SDL_WINDOW_SHOWN
        ) orelse @panic("Failed to create SDL window");

    c.SDL_Delay(3000);

    c.SDL_DestroyWindow(window);
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
