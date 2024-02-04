const std = @import("std");

const c = @cImport({
    @cInclude("sdl.h");
    @cInclude("vulkan/vulkan.h");
    @cInclude("vk_mem_alloc.h");
});

const log = std.log.scoped(.vulkan_engine);
const VulkanEngine = struct {
    window: *c.SDL_Window,

    pub fn cleanup(self: *VulkanEngine) void {
        c.SDL_DestroyWindow(self.window);
    }

    pub fn run(self: *VulkanEngine) void {
        _ = self;
        var quit = false;

        var event: c.SDL_Event = undefined;
        while (!quit) {
            while (c.SDL_PollEvent(&event) != 0) {
                if (event.type == c.SDL_QUIT) {
                   quit = true;
                }
            }
        }
    }
};

pub fn init(a: std.mem.Allocator) VulkanEngine {
    check_sdl(c.SDL_Init(c.SDL_INIT_VIDEO));
    _ = a;

    const window = c.SDL_CreateWindow(
        "Vulkan App",
        c.SDL_WINDOWPOS_CENTERED,
        c.SDL_WINDOWPOS_CENTERED,
        800,
        600,
        c.SDL_WINDOW_VULKAN | c.SDL_WINDOW_RESIZABLE,
    ) orelse @panic("Failed to create SDL window");

    c.SDL_ShowWindow(window);
    
    var engine = VulkanEngine {
        .window = window,
    };

    return engine;
}

fn check_sdl(res: c_int) void {
    if (res != 0) {
        log.err("Vulkan engine SDL error: {s}", .{c.SDL_GetError()});
        @panic("SDL error");
    }
}