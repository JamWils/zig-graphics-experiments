const std = @import("std");
const c = @import("clibs.zig");
const vki = @import("./vulkan/instance.zig");
const vkd = @import("./vulkan/device.zig");
const vke = @import("./vulkan/error.zig");
const vks = @import("./vulkan/swapchain.zig");
const vkp = @import("./vulkan/pipeline.zig");
const vkr = @import("./vulkan/render_pass.zig");

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
    presentation_queue: c.VkQueue,
    swapchain: c.VkSwapchainKHR,
    swapchain_image_format: c.VkFormat,
    swapchain_extent: c.VkExtent2D,
    swapchain_images: []c.VkImage,
    swapchain_image_views: []c.VkImageView,
    render_pass: c.VkRenderPass,
    pipeline_layout: c.VkPipelineLayout,
    graphics_pipeline: c.VkPipeline,

    pub fn cleanup(self: *VulkanEngine) void {
        c.vkDestroyPipeline(self.device, self.graphics_pipeline, null);
        c.vkDestroyPipelineLayout(self.device, self.pipeline_layout, null);
        c.vkDestroyRenderPass(self.device, self.render_pass, null);

        for (self.swapchain_image_views) |image_view| {
            c.vkDestroyImageView(self.device, image_view, null);
        }

        self.allocator.free(self.swapchain_image_views);
        self.allocator.free(self.swapchain_images);

        c.vkDestroySwapchainKHR(self.device, self.swapchain, null);
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

    var window_width: c_int = 0;
    var window_height: c_int = 0;
    c.SDL_GetWindowSize(window, &window_width, &window_height);

    const instance = createInstance(alloc, window);

    const required_device_extensions = .{
        c.VK_KHR_SWAPCHAIN_EXTENSION_NAME,
    };

    var surface: c.VkSurfaceKHR = undefined;
    checkSdlBool(c.SDL_Vulkan_CreateSurface(window, instance.handle, &surface));
    const physical_device = try vkd.getPhysicalDevice(alloc, instance.handle, surface, &required_device_extensions);
    const device = try vkd.createLogicalDevice(alloc, physical_device, &required_device_extensions);
    
    const swapchain = try vks.createSwapchain(alloc, physical_device.handle, device.handle, surface, .{
        .graphics_queue_index = physical_device.queue_indices.graphics_queue_location,
        .presentation_queue_index = physical_device.queue_indices.presentation_queue_location,
        .window_height = @intCast(window_height),
        .window_width = @intCast(window_width),
    });

    const render_pass = try vkr.createRenderPass(device.handle, swapchain.surface_format.format);
    const pipeline = try vkp.createGraphicsPipeline(alloc, device.handle, render_pass.handle, swapchain.image_extent);

    c.SDL_ShowWindow(window);
    
    var engine = VulkanEngine {
        .allocator = alloc,
        .window = window,
        .instance = instance.handle,
        .debug_messenger = instance.debug_messenger,
        .physical_device = physical_device,
        .device = device.handle,
        .surface = surface,
        .graphics_queue = device.graphics_queue,
        .presentation_queue = device.presentation_queue,
        .swapchain = swapchain.handle,
        .swapchain_image_format = swapchain.surface_format.format,
        .swapchain_extent = swapchain.image_extent,
        .swapchain_images = swapchain.images,
        .swapchain_image_views = swapchain.image_views,
        .render_pass = render_pass.handle,
        .pipeline_layout = pipeline.layout,
        .graphics_pipeline = pipeline.graphics_pipeline_handle,
    };

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