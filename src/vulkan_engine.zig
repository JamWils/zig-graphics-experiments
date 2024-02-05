const std = @import("std");
const c = @import("clibs.zig");
const vk_init = @import("./vulkan_init.zig");
const check_vk = @import("./vulkan_error.zig").checkVk;

const log = std.log.scoped(.vulkan_engine);
const VulkanEngine = struct {
    allocator: std.mem.Allocator,
    window: *c.SDL_Window,
    instance: c.VkInstance,
    physical_device: PhysicalDevice,

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
    const physical_device = try getPhysicalDevice(alloc, instance.handler);

    c.SDL_ShowWindow(window);
    
    var engine = VulkanEngine {
        .allocator = alloc,
        .window = window,
        .instance = instance.handler,
        .physical_device = physical_device,
    };

    return engine;
}

pub const PhysicalDevice = struct {
    handle: c.VkPhysicalDevice = null,
    queue_indices: QueueFamilyIndices = undefined,
};

pub const QueueFamilyIndices = struct {
    graphics_queue_location: u32 = undefined,
    present_queue_location: u32 = undefined,

    fn isValid(self: QueueFamilyIndices) bool {
        return self.graphics_queue_location >= 0;
    }
};

fn createInstance(alloc: std.mem.Allocator, window: *c.SDL_Window) vk_init.Instance {
    var arena_alloc = std.heap.ArenaAllocator.init(alloc);
    defer arena_alloc.deinit();

    const arena = arena_alloc.allocator();
    var sdl_extensions_count: u32 = undefined;
    _ = c.SDL_Vulkan_GetInstanceExtensions(window, &sdl_extensions_count, null);
    const sdl_required_extensions = arena.alloc([*c]const u8, sdl_extensions_count) catch unreachable;
    _ = c.SDL_Vulkan_GetInstanceExtensions(window, &sdl_extensions_count, sdl_required_extensions.ptr);

    const instance = vk_init.createInstance(alloc, .{
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

fn getPhysicalDevice(alloc: std.mem.Allocator, instance: c.VkInstance) !PhysicalDevice {
        var device_count: u32 = undefined;
        try check_vk(c.vkEnumeratePhysicalDevices(instance, &device_count, null));

        if (device_count == 0) {
            return error.VulkanNotSupported;
        }

        var arena_alloc = std.heap.ArenaAllocator.init(alloc);
        defer arena_alloc.deinit();
        const arena = arena_alloc.allocator();
        const devices = try arena.alloc(c.VkPhysicalDevice, device_count);
        try check_vk(c.vkEnumeratePhysicalDevices(instance, &device_count, devices.ptr));

        var physicalDevice = PhysicalDevice{};
    
        for (devices) |device| {
            const queue_indices = try getQueueFamilies(alloc, device);
            if (queue_indices.isValid()) {
                physicalDevice.handle = device;
                physicalDevice.queue_indices = queue_indices;
                break;
            }
        }

        return physicalDevice;
    }

fn getQueueFamilies(alloc: std.mem.Allocator, device: c.VkPhysicalDevice) !QueueFamilyIndices {

    var arena_alloc = std.heap.ArenaAllocator.init(alloc);
    defer arena_alloc.deinit();
    const arena = arena_alloc.allocator();
    
    var queue_family_count: u32 = 0;
    c.vkGetPhysicalDeviceQueueFamilyProperties(device, &queue_family_count, null);
    const queue_families = try arena.alloc(c.VkQueueFamilyProperties, queue_family_count);
    c.vkGetPhysicalDeviceQueueFamilyProperties(device, &queue_family_count, queue_families.ptr);

    var indices = QueueFamilyIndices{};
    for(queue_families, 0..) |queue_family, i| {
        
        if (queue_family.queueCount > 0 and queue_family.queueFlags & c.VK_QUEUE_GRAPHICS_BIT != 0) {
            indices.graphics_queue_location = @intCast(i);
        }

        if (indices.isValid()) {
            break;
        }
    }

    return indices;
}

fn checkSdl(res: c_int) void {
    if (res != 0) {
        log.err("Vulkan engine SDL error: {s}", .{c.SDL_GetError()});
        @panic("SDL error");
    }
}