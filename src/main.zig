const std = @import("std");

const c = @cImport({
    @cInclude("sdl.h");
    @cInclude("vulkan/vulkan.h");
    @cInclude("vk_mem_alloc.h");
});

pub fn main() !void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) < 0) {
        @panic("SDL init error");
    }
    defer c.SDL_Quit();

    _ = c.VK_NULL_HANDLE;

    const window = c.SDL_CreateWindow(
        "Zig Graphics", 
        c.SDL_WINDOWPOS_CENTERED, 
        c.SDL_WINDOWPOS_CENTERED, 
        800, 
        600, 
        c.SDL_WINDOW_SHOWN
        ) orelse @panic("Failed to create SDL window");

    c.SDL_Delay(3000);

    c.SDL_DestroyWindow(window);
}
