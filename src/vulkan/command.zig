const std = @import("std");
const c = @import("../clibs.zig");
const vke = @import("./error.zig");
const vkd = @import ("./device.zig");

const CommandPool = struct {
    handle: c.VkCommandPool,
};

const CommandBuffers = struct {
    handles: []c.VkCommandBuffer = &.{},
};

pub fn createCommandPool(device: c.VkDevice, queue_indices: vkd.QueueFamilyIndices) !CommandPool {
    const pool_create_info = std.mem.zeroInit(c.VkCommandPoolCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
        .queueFamilyIndex = queue_indices.graphics_queue_location,
    });

    var graphics_command_pool: c.VkCommandPool = undefined;
    try vke.checkResult(c.vkCreateCommandPool(device, &pool_create_info, null, &graphics_command_pool));

    return .{
        .handle = graphics_command_pool,
    };
}

pub fn createCommandBuffers(a: std.mem.Allocator, device: c.VkDevice, command_pool: c.VkCommandPool, framebuffer_len: usize) !CommandBuffers {
    const cb_alloc_info = std.mem.zeroInit(c.VkCommandBufferAllocateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
        .commandPool = command_pool,
        .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        .commandBufferCount = @as(u32, @intCast(framebuffer_len)),
    });

    const command_buffers: []c.VkCommandBuffer = try a.alloc(c.VkCommandBuffer, framebuffer_len);
    try vke.checkResult(c.vkAllocateCommandBuffers(device, &cb_alloc_info, command_buffers.ptr));

    return .{
        .handles = command_buffers,
    };
}

