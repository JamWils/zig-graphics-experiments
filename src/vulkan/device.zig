const std = @import("std");
const vke = @import("./error.zig");
const c = @import("../clibs.zig");

const log = std.log.scoped(.vulkan_device);

pub const PhysicalDevice = struct {
    handle: c.VkPhysicalDevice = null,
    queue_indices: QueueFamilyIndices = undefined,
};

pub const Device = struct {
    handle: c.VkDevice = null,
    graphics_queue: c.VkQueue = null,
};

pub const QueueFamilyIndices = struct {
    graphics_queue_location: u32 = undefined,
    present_queue_location: u32 = undefined,

    fn isValid(self: QueueFamilyIndices) bool {
        return self.graphics_queue_location >= 0;
    }
};

pub fn createLogicalDevice(physical_device: PhysicalDevice) !Device {
    const priority: f32 = 1;
    const queue_create_info = std.mem.zeroInit(c.VkDeviceQueueCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
        .queueFamilyIndex = physical_device.queue_indices.graphics_queue_location,
        .queueCount = 1,
        .pQueuePriorities = &priority,
    });

    const device_create_info = std.mem.zeroInit(c.VkDeviceCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        .queueCreateInfoCount = 1,
        .pQueueCreateInfos = &queue_create_info,
        .enabledExtensionCount = 0,
        .ppEnabledExtensionNames = null,
        .enabledLayerCount = 0,
    });

    var device: c.VkDevice = undefined;
    try vke.checkResult(c.vkCreateDevice(physical_device.handle, &device_create_info, null, &device));

    var graphics_queue: c.VkQueue = undefined;
    c.vkGetDeviceQueue(device, physical_device.queue_indices.graphics_queue_location, 0, &graphics_queue);

    return .{
        .handle = device,
        .graphics_queue = graphics_queue,
    };
}

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
            std.debug.print("Set the physical device HANDLE", .{});
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