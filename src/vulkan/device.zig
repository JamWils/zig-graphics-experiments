const std = @import("std");
const vke = @import("./error.zig");
const c = @import("../clibs.zig");
const vks = @import("./swapchain.zig");

const log = std.log.scoped(.vulkan_device);

pub const PhysicalDevice = struct {
    handle: c.VkPhysicalDevice = null,
    queue_indices: QueueFamilyIndices = undefined,
    use_render_pass: bool = false,
    min_uniform_buffer_offset_alignment: u64 = 0,
};

pub const PhysicalDeviceOpts = struct {
    features_12: c.VkPhysicalDeviceVulkan12Features,
    features_13: c.VkPhysicalDeviceVulkan13Features,
};

pub const Device = struct {
    handle: c.VkDevice = null,
    graphics_queue: c.VkQueue = null,
    presentation_queue: c.VkQueue = null,
};

pub const QueueFamilyIndices = struct {
    graphics_queue_location: u32 = undefined,
    presentation_queue_location: u32 = undefined,

    fn isValid(self: QueueFamilyIndices) bool {
        return self.graphics_queue_location >= 0 and self.presentation_queue_location >= 0;
    }
};

pub const DeviceQueueResult = union(enum) {
    invalid: void,
    queue_family_indicies: QueueFamilyIndices,
};

pub fn createLogicalDevice(alloc: std.mem.Allocator, physical_device: PhysicalDevice, required_extensions: []const [*c]const u8) !Device {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var queue_family_indices = std.AutoArrayHashMapUnmanaged(u32, void){};
    try queue_family_indices.put(arena, physical_device.queue_indices.graphics_queue_location, {});
    try queue_family_indices.put(arena, physical_device.queue_indices.presentation_queue_location, {});

    var queue_create_infos = std.ArrayListUnmanaged(c.VkDeviceQueueCreateInfo){};
    try queue_create_infos.ensureTotalCapacity(arena, queue_family_indices.count());
    
    const priority: f32 = 1;
    var qfi_iterator = queue_family_indices.iterator();
    while (qfi_iterator.next()) |queue_family_index| {
        try queue_create_infos.append(arena, std.mem.zeroInit(c.VkDeviceQueueCreateInfo, .{
            .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
            .queueFamilyIndex = queue_family_index.key_ptr.*,
            .queueCount = 1,
            .pQueuePriorities = &priority,
        }));
    }
    
    const device_create_info = std.mem.zeroInit(c.VkDeviceCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        .queueCreateInfoCount = @as(u32, @intCast(queue_create_infos.items.len)),
        .pQueueCreateInfos = queue_create_infos.items.ptr,
        .enabledExtensionCount = @as(u32, @intCast(required_extensions.len)),
        .ppEnabledExtensionNames = required_extensions.ptr,
        .enabledLayerCount = 0,
    });

    var device: c.VkDevice = undefined;
    try vke.checkResult(c.vkCreateDevice(physical_device.handle, &device_create_info, null, &device));

    var graphics_queue: c.VkQueue = undefined;
    c.vkGetDeviceQueue(device, physical_device.queue_indices.graphics_queue_location, 0, &graphics_queue);

    var presentation_queue: c.VkQueue = undefined;
    c.vkGetDeviceQueue(device, physical_device.queue_indices.presentation_queue_location, 0, &presentation_queue);

    return .{
        .handle = device,
        .graphics_queue = graphics_queue,
        .presentation_queue = presentation_queue,
    };
}

pub fn getPhysicalDevice(alloc: std.mem.Allocator, instance: c.VkInstance, surface: c.VkSurfaceKHR, required_extensions: []const [*c]const u8) !PhysicalDevice {
    var device_count: u32 = undefined;
    try vke.checkResult(c.vkEnumeratePhysicalDevices(instance, &device_count, null));

    if (device_count == 0) {
        return error.VulkanNotSupported;
    }

    var arena_alloc = std.heap.ArenaAllocator.init(alloc);
    defer arena_alloc.deinit();
    const arena = arena_alloc.allocator();
    const devices = try arena.alloc(c.VkPhysicalDevice, device_count);
    try vke.checkResult(c.vkEnumeratePhysicalDevices(instance, &device_count, devices.ptr));

    var physical_device = PhysicalDevice{};
    _ = device_loop: for (devices) |device| {
        const device_result = try isDeviceSuitable(alloc, device, surface, required_extensions);

        switch (device_result) {
            .invalid => {},
            .queue_family_indicies => |qfi| {
                physical_device.handle = device;
                physical_device.queue_indices = qfi;
                std.debug.print("Set the physical device handle\n", .{});
                break :device_loop;
            }
        }
    };

    var features_1_3 = std.mem.zeroInit(c.VkPhysicalDeviceVulkan13Features, .{
        .sType = c.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES,
    });

    var features_1_2 = std.mem.zeroInit(c.VkPhysicalDeviceVulkan12Features, .{
        .sType = c.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES,
    });
    features_1_2.pNext = &features_1_3;

    var physical_features = std.mem.zeroInit(c.VkPhysicalDeviceFeatures2, .{
        .sType = c.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2,
    });
    physical_features.pNext = &features_1_2;
    c.vkGetPhysicalDeviceFeatures2(physical_device.handle, &physical_features);

    if (features_1_2.bufferDeviceAddress == c.VK_FALSE) {
        return error.MissingFeatureBufferDeviceAddress;
    }

    if (features_1_2.descriptorIndexing == c.VK_FALSE) {
        return error.MissingFeatureDescriptorIndexing;
    }

    if (features_1_3.dynamicRendering == c.VK_FALSE) {
        physical_device.use_render_pass = true;
    }

    if (features_1_3.synchronization2 == c.VK_FALSE) {
        return error.MissingFeatureSynchronization2;
    }

    var device_properties: c.VkPhysicalDeviceProperties = undefined;
    c.vkGetPhysicalDeviceProperties(physical_device.handle, &device_properties);
    physical_device.min_uniform_buffer_offset_alignment = device_properties.limits.minUniformBufferOffsetAlignment;

    return physical_device;
}

fn getQueueFamilies(alloc: std.mem.Allocator, device: c.VkPhysicalDevice, surface: c.VkSurfaceKHR) !QueueFamilyIndices {

    var arena_alloc = std.heap.ArenaAllocator.init(alloc);
    defer arena_alloc.deinit();
    const arena = arena_alloc.allocator();
    
    var queue_family_count: u32 = 0;
    c.vkGetPhysicalDeviceQueueFamilyProperties(device, &queue_family_count, null);
    const queue_families = try arena.alloc(c.VkQueueFamilyProperties, queue_family_count);
    c.vkGetPhysicalDeviceQueueFamilyProperties(device, &queue_family_count, queue_families.ptr);

    var indices = QueueFamilyIndices{};
    for(queue_families, 0..) |queue_family, i| {
        const index: u32 = @intCast(i);
        if (queue_family.queueCount > 0 and queue_family.queueFlags & c.VK_QUEUE_GRAPHICS_BIT != 0) {
            indices.graphics_queue_location = index;
        }

        var presentation_support: c.VkBool32 = 0;
        try vke.checkResult(c.vkGetPhysicalDeviceSurfaceSupportKHR(device, index, surface, &presentation_support));
        if (queue_family.queueCount > 0 and presentation_support == c.VK_TRUE) {
            indices.presentation_queue_location = @intCast(index);
        }

        if (indices.isValid()) {
            break;
        }
    }

    return indices;
}

fn checkDeviceExtensionSupport(alloc: std.mem.Allocator, device: c.VkPhysicalDevice, required_extensions: []const [*c]const u8) !bool {
    var arena_alloc = std.heap.ArenaAllocator.init(alloc);
    defer arena_alloc.deinit();
    const arena = arena_alloc.allocator();

    var extension_count: u32 = 0;
    try vke.checkResult(c.vkEnumerateDeviceExtensionProperties(device, null, &extension_count, null));

    if (extension_count == 0) return false;

    const extensions = try arena.alloc(c.VkExtensionProperties, extension_count);
    try vke.checkResult(c.vkEnumerateDeviceExtensionProperties(device, null, &extension_count, extensions.ptr));

    var has_extension = false;
    for (required_extensions) |required_extension| {
        for (extensions) |extension| {
            const extension_name: [*c]const u8 = @ptrCast(extension.extensionName[0..]);
            if (std.mem.eql(u8, std.mem.span(required_extension), std.mem.span(extension_name))) {
                has_extension = true;
            }
        }

        if (!has_extension) {
            return false;
        }
    }

    return has_extension;
}

fn isDeviceSuitable(alloc: std.mem.Allocator, device: c.VkPhysicalDevice, surface: c.VkSurfaceKHR, required_extensions: []const [*c]const u8) !DeviceQueueResult {
    const queue_family_indices = try getQueueFamilies(alloc, device, surface);
    if (!queue_family_indices.isValid()) return .{ .invalid = {} };

    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const swapchain_details = try vks.SwapchainDetails.createAlloc(arena, device, surface);
    defer swapchain_details.deinit(arena);
    if (swapchain_details.surface_formats.len == 0 or swapchain_details.presentation_modes.len == 0) {
        return . { .invalid = {} };
    }

    const extensions_supported = try checkDeviceExtensionSupport(alloc, device, required_extensions);
    if (extensions_supported) {
        return .{ .queue_family_indicies = queue_family_indices };
    } else {
        return . { .invalid = {} };
    }
}