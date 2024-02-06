const std = @import("std");
const vke = @import("./error.zig");
const c = @import("../clibs.zig");

const log = std.log.scoped(.vulkan_device);

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

pub fn getPhysicalDevice(alloc: std.mem.Allocator, instance: c.VkInstance) !PhysicalDevice {
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