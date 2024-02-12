const std = @import("std");
const c = @import("../clibs.zig");
const vke = @import("./error.zig");

pub const Semaphore = struct {
    handle: c.VkSemaphore = null,
};

pub const Semaphores = struct {
    handles: []c.VkSemaphore = &.{}
};

pub const Fences = struct {
    handles: []c.VkFence = &.{}
};

pub fn createSemaphore(device: c.VkDevice) !Semaphore {
    const create_info = std.mem.zeroInit(c.VkSemaphoreCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
    });

    var semaphore: c.VkSemaphore = undefined;
    try vke.checkResult(c.vkCreateSemaphore(device, &create_info, null, &semaphore));

    return .{
        .handle = semaphore,
    };
}

pub fn createSemaphores(a: std.mem.Allocator, device: c.VkDevice, semaphore_count: usize) !Semaphores {
    var semaphores: []c.VkSemaphore = try a.alloc(c.VkSemaphore, semaphore_count);

    for (semaphores) |*semaphore| {
        const create_info = std.mem.zeroInit(c.VkSemaphoreCreateInfo, .{
            .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
        });

        try vke.checkResult(c.vkCreateSemaphore(device, &create_info, null, semaphore));
    }

    return .{
        .handles = semaphores,
    };
}

pub fn createFences(a: std.mem.Allocator, device: c.VkDevice, semaphore_count: usize) !Fences {
    var fences: []c.VkFence = try a.alloc(c.VkFence, semaphore_count);

    for (fences) |*fence| {
        const create_info = std.mem.zeroInit(c.VkFenceCreateInfo, .{
            .sType = c.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
            .flags = c.VK_FENCE_CREATE_SIGNALED_BIT,
        });

        try vke.checkResult(c.vkCreateFence(device, &create_info, null, fence));
    }

    return .{
        .handles = fences,
    };
}