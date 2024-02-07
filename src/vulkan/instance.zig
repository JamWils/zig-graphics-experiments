const std = @import("std");
const c = @import("../clibs.zig");
const vke = @import("./error.zig");

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
    handle: c.VkInstance = null,
    debug_messenger: c.VkDebugUtilsMessengerEXT = null,
};

pub fn createInstance(alloc: std.mem.Allocator, opts: VkInstanceOpts) !Instance {
    if (opts.api_version > c.VK_MAKE_VERSION(1, 1, 0)) {
        var api_requested = opts.api_version;
        try vke.checkResult(c.vkEnumerateInstanceVersion(@ptrCast(&api_requested)));
    }

    var arena_alloc = std.heap.ArenaAllocator.init(alloc);
    defer arena_alloc.deinit();

    const arena = arena_alloc.allocator();

    var layer_count: u32 = undefined;
    try vke.checkResult(c.vkEnumerateInstanceLayerProperties(&layer_count, null));
    const layer_props = try arena.alloc(c.VkLayerProperties, layer_count);
    try vke.checkResult(c.vkEnumerateInstanceLayerProperties(&layer_count, layer_props.ptr));

    var enable_validation = opts.debug;
    var layers = std.ArrayListUnmanaged([*c]const u8){};
    if (enable_validation) {
        enable_validation = for (layer_props) |layer_prop| {
            const layer_name: [*c]const u8 = @ptrCast(layer_prop.layerName[0..]);
            const validation_layer_name: [*c]const u8 = "VK_LAYER_KHRONOS_validation";
            if (std.mem.eql(u8, std.mem.span(validation_layer_name), std.mem.span(layer_name))) {
                try layers.append(arena, validation_layer_name);
                break true;
            }
        } else {
            log.err("Validation layers requested, but not available", .{});
            return error.ValidationLayersNotAvailable;
        };
    }

    var extension_count: u32 = undefined;
    try vke.checkResult(c.vkEnumerateInstanceExtensionProperties(null, &extension_count, null));
    const extension_props = try arena.alloc(c.VkExtensionProperties, extension_count);
    try vke.checkResult(c.vkEnumerateInstanceExtensionProperties(null, &extension_count, extension_props.ptr));

    var extensions = std.ArrayListUnmanaged([*c]const u8){};
    for (opts.required_extensions) |extension| {
        if (checkInstanceExtensionSupport(extension, extension_props)) {
            try extensions.append(arena, extension);
        } else {
            log.err("Required vulkan extension not supported: {s}", .{extension});
            return error.VulkanExtensionNotSupported;
        }
    }

    if (enable_validation and checkInstanceExtensionSupport("VK_EXT_debug_utils", extension_props)) {
        try extensions.append(arena, "VK_EXT_debug_utils");
    } else {
        enable_validation = false;
    }

    const app_info = std.mem.zeroInit(c.VkApplicationInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_APPLICATION_INFO,
        .apiVersion = opts.api_version,
        .pApplicationName = opts.application_name,
        .pEngineName = opts.engine_name orelse opts.application_name,
    });

    var instance_info = std.mem.zeroInit(c.VkInstanceCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .pApplicationInfo = &app_info,
        .enabledLayerCount = @as(u32, @intCast(layers.items.len)),
        .ppEnabledLayerNames = layers.items.ptr,
        .enabledExtensionCount = @as(u32, @intCast(extensions.items.len)),
        .ppEnabledExtensionNames = extensions.items.ptr,
    });

    var instance: c.VkInstance = undefined;
    try vke.checkResult(c.vkCreateInstance(&instance_info, null, &instance));

    const debug_messenger = if (enable_validation) 
        try createDebugCallback(instance, opts)
    else null;

    return .{
        .handle = instance,
        .debug_messenger = debug_messenger,
    };
}

pub fn getDestroyDebugUtilsMessengerFn(instance: c.VkInstance) c.PFN_vkDestroyDebugUtilsMessengerEXT {
    return getInstanceFn(
        c.PFN_vkDestroyDebugUtilsMessengerEXT, instance, "vkDestroyDebugUtilsMessengerEXT");
}

fn getInstanceFn(comptime Fn: type, instance: c.VkInstance, name: [*c]const u8) Fn {
    const get_proc_addr: c.PFN_vkGetInstanceProcAddr = @ptrCast(c.SDL_Vulkan_GetVkGetInstanceProcAddr());
    if (get_proc_addr) |get_proc_addr_fn| {
        return @ptrCast(get_proc_addr_fn(instance, name));
    }

    @panic("SDL_Vulkan_GetVkGetInstanceProcAddr returned null");
}

fn createDebugCallback(instance: c.VkInstance, opts: VkInstanceOpts) !c.VkDebugUtilsMessengerEXT {
    const create_fn_opt = getInstanceFn(
        c.PFN_vkCreateDebugUtilsMessengerEXT, instance, "vkCreateDebugUtilsMessengerEXT");
    if (create_fn_opt) |createFn| {
        const create_info = std.mem.zeroInit(c.VkDebugUtilsMessengerCreateInfoEXT, .{
            .sType = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
            .messageSeverity = c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT |
                c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT |
                c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT,
            .messageType = c.VK_DEBUG_UTILS_MESSAGE_TYPE_DEVICE_ADDRESS_BINDING_BIT_EXT |
                c.VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT |
                c.VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT |
                c.VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT,
            .pfnUserCallback = opts.debug_callback orelse defaultDebugCallback,
            .pUserData = null,
        });
        var debug_messenger: c.VkDebugUtilsMessengerEXT = undefined;
        try vke.checkResult(createFn(instance, &create_info, opts.alloc_cb, &debug_messenger));
        return debug_messenger;
    }
    return null;
}

fn defaultDebugCallback(
    severity: c.VkDebugUtilsMessageSeverityFlagBitsEXT,
    msg_type: c.VkDebugUtilsMessageTypeFlagsEXT,
    callback_data: ?* const c.VkDebugUtilsMessengerCallbackDataEXT,
    user_data: ?*anyopaque
) callconv(.C) c.VkBool32 {
    _ = user_data;
    const severity_str = switch (severity) {
        c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT => "VERBOSE",
        c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT => "INFO",
        c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT => "WARNING",
        c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT => "ERROR",
        else => "UNKNOWN",
    };

    const type_str = switch (msg_type) {
        c.VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT => "General",
        c.VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT => "Validation",
        c.VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT 
            | c.VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT => "General | Validation",
        c.VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT => "Performance",
        c.VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT 
            | c.VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT => "General | Performance",
        c.VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT
            | c.VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT => "Validation | Performance",
        c.VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT 
            | c.VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT
            | c.VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT => "General | Validation | Performance",
        c.VK_DEBUG_UTILS_MESSAGE_TYPE_DEVICE_ADDRESS_BINDING_BIT_EXT => "Device Address",
        else => "Unknown",
    };

    const message: [*c]const u8 = if (callback_data) |cb_data| cb_data.pMessage else "NO MESSAGE!";
    log.err("[{s}][{s}]. Message:\n  {s}", .{ severity_str, type_str, message });

    if (severity >= c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT) {
        @panic("Unrecoverable vulkan error.");
    }

    return c.VK_FALSE;
}

fn checkInstanceExtensionSupport(name: [*c]const u8, properties: []c.VkExtensionProperties) bool {
    for (properties) |property| {
        const prop_name: [*c]const u8 = @ptrCast(property.extensionName[0..]);
        if (std.mem.eql(u8, std.mem.span(name), std.mem.span(prop_name))) {
            return true;
        }
    }

    return false;
}
