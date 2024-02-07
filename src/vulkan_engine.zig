const std = @import("std");
const c = @import("clibs.zig");
const vki = @import("./vulkan/instance.zig");
const vkd = @import("./vulkan/device.zig");
const vke = @import("./vulkan/error.zig");

const log = std.log.scoped(.vulkan_engine);
const vk_alloc_callbacks: ?*c.VkAllocationCallbacks = null;

const VulkanEngine = struct {
    allocator: std.mem.Allocator,
    window: *c.SDL_Window,
    instance: c.VkInstance,
    debug_messenger: c.VkDebugUtilsMessengerEXT,
    physical_device: vkd.PhysicalDevice,
    device: c.VkDevice,
    surface: c.VkSurfaceKHR,
    graphics_queue: c.VkQueue,

    pub fn cleanup(self: *VulkanEngine) void {
        c.vkDestroySurfaceKHR(self.instance, self.surface, null);
        c.vkDestroyDevice(self.device, null);
        if (self.debug_messenger != null) {
            const destroyFn = vki.getDestroyDebugUtilsMessengerFn(self.instance).?;
            destroyFn(self.instance, self.debug_messenger, vk_alloc_callbacks);
        }
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
};

pub fn init(alloc: std.mem.Allocator) !VulkanEngine {
    checkSdl(c.SDL_Init(c.SDL_INIT_VIDEO));

    const window = c.SDL_CreateWindow(
        "Vulkan App",
        c.SDL_WINDOWPOS_CENTERED,
        c.SDL_WINDOWPOS_CENTERED,
        800,
        600,
        c.SDL_WINDOW_VULKAN | c.SDL_WINDOW_RESIZABLE,
    ) orelse @panic("Failed to create SDL window");

    const instance = createInstance(alloc, window);
    const physical_device = try vkd.getPhysicalDevice(alloc, instance.handle);
    const device = try vkd.createLogicalDevice(physical_device);

    c.SDL_ShowWindow(window);
    
    var engine = VulkanEngine {
        .allocator = alloc,
        .window = window,
        .instance = instance.handle,
        .debug_messenger = instance.debug_messenger,
        .physical_device = physical_device,
        .device = device.handle,
        .surface = null,
        .graphics_queue = device.graphics_queue,
    };

    checkSdlBool(c.SDL_Vulkan_CreateSurface(window, instance.handle, &engine.surface));

    return engine;
}

fn createInstance(alloc: std.mem.Allocator, window: *c.SDL_Window) vki.Instance {
    var arena_alloc = std.heap.ArenaAllocator.init(alloc);
    defer arena_alloc.deinit();

    const arena = arena_alloc.allocator();
    var sdl_extensions_count: u32 = undefined;
    _ = c.SDL_Vulkan_GetInstanceExtensions(window, &sdl_extensions_count, null);
    const sdl_required_extensions = arena.alloc([*c]const u8, sdl_extensions_count) catch unreachable;
    _ = c.SDL_Vulkan_GetInstanceExtensions(window, &sdl_extensions_count, sdl_required_extensions.ptr);

    const instance = vki.createInstance(alloc, .{
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
    
    return instance;
}

fn checkSdl(res: c_int) void {
    if (res != 0) {
        log.err("Vulkan engine SDL error: {s}", .{c.SDL_GetError()});
        @panic("SDL error");
    }
}

fn checkSdlBool(res: c.SDL_bool) void {
    if (res != c.SDL_TRUE) {
        log.err("Vulkan engine SDL error: {s}", .{c.SDL_GetError()});
        @panic("SDL error");
    }
}