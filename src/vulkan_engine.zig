const std = @import("std");
const c = @import("clibs.zig");
const vk_init = @import("./vulkan_init.zig");

const log = std.log.scoped(.vulkan_engine);
const VulkanEngine = struct {
    window: *c.SDL_Window,
    instance: c.VkInstance,

    pub fn cleanup(self: *VulkanEngine) void {
        c.vkDestroyInstance(self.instance, null);
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

    fn init_instance(self: *VulkanEngine, alloc: std.mem.Allocator) void {
        _ = alloc;
        var arena_alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena_alloc.deinit();

        const arena = arena_alloc.allocator();
        var sdl_extensions_count: u32 = undefined;
        _ = c.SDL_Vulkan_GetInstanceExtensions(self.window, &sdl_extensions_count, null);
        const sdl_required_extensions = arena.alloc([*c]const u8, sdl_extensions_count) catch unreachable;
        _ = c.SDL_Vulkan_GetInstanceExtensions(self.window, &sdl_extensions_count, sdl_required_extensions.ptr);

        const instance = vk_init.create_instance(std.heap.page_allocator, .{
            .application_name = "Vulkan App",
            .application_version = c.VK_MAKE_VERSION(0, 1, 0),
            .engine_name = "Snap Engine",
            .engine_version = c.VK_MAKE_VERSION(0, 1, 0),
            .api_version = c.VK_API_VERSION_1_3,
            .debug = true,
            .required_extensions = sdl_required_extensions
        }) catch |err| {
            log.err("Failed to create a Vulkan Instance with error: {s}", .{ @errorName(err) });
            unreachable;
        };

        self.instance = instance.handler;
        // TODO: Debug messenger
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
        .instance = null,
    };

    engine.init_instance();

    return engine;
}

fn check_sdl(res: c_int) void {
    if (res != 0) {
        log.err("Vulkan engine SDL error: {s}", .{c.SDL_GetError()});
        @panic("SDL error");
    }
}