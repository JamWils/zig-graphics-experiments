const std = @import("std");
const c = @import("../clibs.zig");
const vke = @import("./error.zig");

pub const Semaphore = struct {
    handle: c.VkSemaphore = null,
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