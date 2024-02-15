const std = @import("std");
const c = @import("../clibs.zig");
const vke = @import ("./error.zig");
const mesh = @import("../mesh/mesh.zig");

const BufferOpts = struct {
    physical_device: c.VkPhysicalDevice, 
    device: c.VkDevice, 
    buffer_size: c.VkDeviceSize, 
    buffer_usage: c.VkBufferUsageFlags,
    buffer_properties: c.VkMemoryPropertyFlags,
};

const TransferBufferOpts = struct {
    device: c.VkDevice,
    transfer_queue: c.VkQueue,
    command_pool: c.VkCommandPool,
};

pub const VertexBufferOpts = struct {
    physical_device: c.VkPhysicalDevice, 
    device: c.VkDevice, 
    transfer_queue: c.VkQueue, 
    transfer_command_pool: c.VkCommandPool, 
};

pub const Buffer = struct {
    handle: [*c] c.VkBuffer = undefined,
    memory: [*c] c.VkDeviceMemory = undefined,

    pub fn deleteAndFree(self: *Buffer, device: c.VkDevice) void {
        c.vkDestroyBuffer(device, self.handle, null);
        c.vkFreeMemory(device, self.memory, null);
    }
};

pub const VertexBuffer = struct {
    handle: c.VkBuffer,
    memory: c.VkDeviceMemory,
    count: u32,

    pub fn deleteAndFree(self: *VertexBuffer, device: c.VkDevice) void {
        c.vkDestroyBuffer(device, self.handle, null);
        c.vkFreeMemory(device, self.memory, null);
    }
};

fn createBuffer(buffer: *const Buffer, opts: BufferOpts) !void {
    const buffer_create_info = std.mem.zeroInit(c.VkBufferCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        .size = opts.buffer_size,
        .usage = opts.buffer_usage,
        .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
    });

    try vke.checkResult(c.vkCreateBuffer(opts.device, &buffer_create_info, null, buffer.handle));

    var memory_req: c.VkMemoryRequirements = undefined;
    c.vkGetBufferMemoryRequirements(opts.device, buffer.handle.*, &memory_req);

    var memory_alloc_info = std.mem.zeroInit(c.VkMemoryAllocateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        .allocationSize = memory_req.size,
        .memoryTypeIndex = findMemoryTypeIndex(
            opts.physical_device, 
            memory_req.memoryTypeBits,
            opts.buffer_properties,
        ),
    });

    try vke.checkResult(c.vkAllocateMemory(opts.device, &memory_alloc_info, null, buffer.memory));
    try vke.checkResult(c.vkBindBufferMemory(opts.device, buffer.handle.*, buffer.memory.*, 0));
}

fn copyBuffer(src_buffer: c.VkBuffer, dst_buffer: c.VkBuffer, buffer_size: c.VkDeviceSize, opts: TransferBufferOpts) !void {
    const alloc_info = std.mem.zeroInit(c.VkCommandBufferAllocateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
        .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        .commandPool = opts.command_pool,
        .commandBufferCount = 1,
    });

    var transfer_command_buffer: c.VkCommandBuffer = undefined;
    defer c.vkFreeCommandBuffers(opts.device, opts.command_pool, 1, &transfer_command_buffer);
    try vke.checkResult(c.vkAllocateCommandBuffers(opts.device, &alloc_info, &transfer_command_buffer));

    const begin_info = std.mem.zeroInit(c.VkCommandBufferBeginInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        .flags = c.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
    });

    try vke.checkResult(c.vkBeginCommandBuffer(transfer_command_buffer, &begin_info));

    var buffer_copy_region = c.VkBufferCopy{
        .srcOffset = 0,
        .dstOffset = 0,
        .size = buffer_size,
    };
    c.vkCmdCopyBuffer(transfer_command_buffer, src_buffer, dst_buffer, 1, &buffer_copy_region);
    try vke.checkResult(c.vkEndCommandBuffer(transfer_command_buffer));

    const submit_info = std.mem.zeroInit(c.VkSubmitInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .commandBufferCount = 1,
        .pCommandBuffers = &transfer_command_buffer,
    });

    try vke.checkResult(c.vkQueueSubmit(opts.transfer_queue, 1, &submit_info, null));
    try vke.checkResult(c.vkQueueWaitIdle(opts.transfer_queue));
}

pub fn createVertexBuffer(vertices: []mesh.Vertex, opts: VertexBufferOpts) !VertexBuffer {
    const buffer_size = @sizeOf(mesh.Vertex) * vertices.len;

    var staging_buffer_handle: c.VkBuffer = undefined;
    defer c.vkDestroyBuffer(opts.device, staging_buffer_handle, null);
    var staging_buffer_memory: c.VkDeviceMemory = undefined;
    defer c.vkFreeMemory(opts.device, staging_buffer_memory, null);

    const staging_buffer: Buffer = .{
        .handle = @as([*c] c.VkBuffer, @ptrCast(&staging_buffer_handle)),
        .memory = @as([*c] c.VkDeviceMemory, @ptrCast(&staging_buffer_memory)),
    };
    try createBuffer(&staging_buffer, .{
        .physical_device = opts.physical_device,
        .device = opts.device,
        .buffer_properties = c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        .buffer_size = buffer_size,
        .buffer_usage = c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
    });

    var staging_data: ?*align(@alignOf(mesh.Vertex)) anyopaque = undefined;
    try vke.checkResult(c.vkMapMemory(opts.device, staging_buffer_memory, 0, buffer_size, 0, &staging_data));
    @memcpy(@as([*]mesh.Vertex, @ptrCast(staging_data)), vertices);
    c.vkUnmapMemory(opts.device, staging_buffer_memory);

    var vertex_buffer_handle: c.VkBuffer = undefined;
    var vertex_buffer_memory: c.VkDeviceMemory = undefined;
    const vertex_buffer: Buffer = .{
        .handle = @as([*c] c.VkBuffer, @ptrCast(&vertex_buffer_handle)),
        .memory = @as([*c] c.VkDeviceMemory, @ptrCast(&vertex_buffer_memory)),
    };
    try createBuffer(&vertex_buffer, .{
        .physical_device = opts.physical_device,
        .device = opts.device,
        .buffer_properties = c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
        .buffer_size = buffer_size,
        .buffer_usage = c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
    });

    try copyBuffer(staging_buffer_handle, vertex_buffer_handle, buffer_size, .{
        .device = opts.device,
        .transfer_queue = opts.transfer_queue,
        .command_pool = opts.transfer_command_pool,
    });

    return .{
        .handle = vertex_buffer_handle,
        .memory = vertex_buffer_memory,
        .count = @as(u32, @intCast(vertices.len)),
    };
}

pub fn createIndexBuffer(indices: []u32, opts: VertexBufferOpts) !VertexBuffer {
    var buffer_size = @sizeOf(u32) * indices.len;

    var staging_buffer_handle: c.VkBuffer = undefined;
    defer c.vkDestroyBuffer(opts.device, staging_buffer_handle, null);

    var staging_buffer_memory: c.VkDeviceMemory = undefined;
    defer c.vkFreeMemory(opts.device, staging_buffer_memory, null);

    const staging_buffer: Buffer = .{
        .handle = @as([*c] c.VkBuffer, @ptrCast(&staging_buffer_handle)),
        .memory = @as([*c] c.VkDeviceMemory, @ptrCast(&staging_buffer_memory)),
    };

    try createBuffer(&staging_buffer, .{
        .physical_device = opts.physical_device,
        .device = opts.device,
        .buffer_properties = c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        .buffer_size = buffer_size,
        .buffer_usage = c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
    });

    var staging_data: ?*align(@alignOf(u32)) anyopaque = undefined;
    try vke.checkResult(c.vkMapMemory(opts.device, staging_buffer_memory, 0, buffer_size, 0, &staging_data));
    @memcpy(@as([*]u32, @ptrCast(staging_data)), indices);
    c.vkUnmapMemory(opts.device, staging_buffer_memory);

    var index_buffer_handle: c.VkBuffer = undefined;
    var index_buffer_memory: c.VkDeviceMemory = undefined;
    const index_buffer: Buffer = .{
        .handle = @as([*c] c.VkBuffer, @ptrCast(&index_buffer_handle)),
        .memory = @as([*c] c.VkDeviceMemory, @ptrCast(&index_buffer_memory)),
    };

    try createBuffer(&index_buffer, .{
        .physical_device = opts.physical_device,
        .device = opts.device,
        .buffer_properties = c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
        .buffer_size = buffer_size,
        .buffer_usage = c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_INDEX_BUFFER_BIT,
    });

    try copyBuffer(staging_buffer_handle, index_buffer_handle, buffer_size, .{
        .device = opts.device,
        .transfer_queue = opts.transfer_queue,
        .command_pool = opts.transfer_command_pool,
    });

    return .{
        .handle = index_buffer_handle,
        .memory = index_buffer_memory,
        .count = @as(u32, @intCast(indices.len)),
    };
}

fn findMemoryTypeIndex(physical_device: c.VkPhysicalDevice, allowed_types: u32, property_flags: c.VkMemoryPropertyFlags) u32 {
    var mem_props: c.VkPhysicalDeviceMemoryProperties = undefined;
    c.vkGetPhysicalDeviceMemoryProperties(physical_device, &mem_props);

    for (0..mem_props.memoryTypeCount) |i| {
        const value = @as(u64, 1) << @intCast(i);
        if ((allowed_types & value) != 0 and (mem_props.memoryTypes[i].propertyFlags & property_flags) == property_flags) {
            return @as(u32, @intCast(i));
        }
    }

    return 0;
}