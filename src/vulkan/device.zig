const std = @import("std");
const vke = @import("./error.zig");
const c = @import("../clibs.zig");

const log = std.log.scoped(.vulkan_device);

pub const PhysicalDevice = struct {
    handle: c.VkPhysicalDevice = null,
    queue_indices: QueueFamilyIndices = undefined,
    use_render_pass: bool = false,
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

pub fn createLogicalDevice(alloc: std.mem.Allocator, physical_device: PhysicalDevice) !Device {
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
        .enabledExtensionCount = 0,
        .ppEnabledExtensionNames = null,
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

pub fn getPhysicalDevice(alloc: std.mem.Allocator, instance: c.VkInstance, surface: c.VkSurfaceKHR) !PhysicalDevice {
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
    for (devices) |device| {
        const queue_indices = try getQueueFamilies(alloc, device, surface);
        if (queue_indices.isValid()) {
            physical_device.handle = device;
            physical_device.queue_indices = queue_indices;
            std.debug.print("Set the physical device HANDLE", .{});
            break;
        }
    }

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
        // var index: u32 = @as(u32, i);
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