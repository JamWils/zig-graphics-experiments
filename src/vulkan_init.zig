const std = @import("std");
const c = @import("clibs.zig");
const check_vk = @import("./vulkan_error.zig").check_vk;

const log = std.log.scoped(.vulkan_init);

pub const VkInstanceOpts = struct {
    application_name: [:0]const u8 = "Test App",
    application_version: u32 = c.VK_MAKE_VERSION(1, 0, 0),
    engine_name: ?[:0]const u8 = null,
    engine_version: u32 = c.VK_MAKE_VERSION(1, 0, 0),
    api_version: u32 = c.VK_API_VERSION_1_3,
    debug: bool = false,
    debug_callback: c.PFN_vkDebugUtilsMessengerCallbackEXT = null,
    required_extensions: []const [*c]const u8 = &.{},
    alloc_cb: ?*c.VkAllocationCallbacks = null,
};

pub const Instance = struct {
    handler: c.VkInstance = null,
    // debug_messenger: c.VkDebugUtilsMessengerEXT,
};

pub fn create_instance(alloc: std.mem.Allocator, opts: VkInstanceOpts) !Instance {
    if (opts.api_version > c.VK_MAKE_VERSION(1, 0, 0)) {
        var api_requested = opts.api_version;
        try check_vk(c.vkEnumerateInstanceVersion(@ptrCast(&api_requested)));
    }

    var arena_alloc = std.heap.ArenaAllocator.init(alloc);
    defer arena_alloc.deinit();

    const arena = arena_alloc.allocator();

    var extension_count: u32 = undefined;
    try check_vk(c.vkEnumerateInstanceExtensionProperties(null, &extension_count, null));
    const extension_props = try arena.alloc(c.VkExtensionProperties, extension_count);
    try check_vk(c.vkEnumerateInstanceExtensionProperties(null, &extension_count, extension_props.ptr));

    var extensions = std.ArrayListUnmanaged([*c]const u8){};
    for (opts.required_extensions) |extension| {
        if (check_instance_extension_support(extension, extension_props)) { 
            try extensions.append(arena, extension);
        } else {
            log.err("Required vulkan extension not supported: {s}", .{ extension });
            return error.VulkanExtensionNotSupported;
        }
    }

    const app_info = std.mem.zeroInit(c.VkApplicationInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_APPLICATION_INFO,
        .apiVersion = opts.api_version,
        .pApplicationName = opts.application_name,
        .pEngineName = opts.engine_name orelse opts.application_name,
    });

    const instance_info = std.mem.zeroInit(c.VkInstanceCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .pApplicationInfo = &app_info,
        .enabledLayerCount = @as(u32, @intCast(0)),
        .ppEnabledLayerNames = null,
        .enabledExtensionCount = @as(u32, @intCast(extensions.items.len)),
        .ppEnabledExtensionNames = extensions.items.ptr,
    });

    var instance: c.VkInstance = undefined;
    try check_vk(c.vkCreateInstance(&instance_info, opts.alloc_cb, &instance));

    return .{
        .handler = instance,
    };
}

fn check_instance_extension_support(name: [*c]const u8, properties: []c.VkExtensionProperties) bool {
    for (properties) |property| {
        const prop_name: [*c]const u8 = @ptrCast(property.extensionName[0..]);
        if (std.mem.eql(u8, std.mem.span(name), std.mem.span(prop_name))) {
            return true;
        }
    }

    return false;
}