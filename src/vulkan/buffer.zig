const std = @import("std");
const c = @import("../clibs.zig");
const vke = @import("./error.zig");
const scene = @import("scene");

const BufferOpts = struct {
    physical_device: c.VkPhysicalDevice,
    device: c.VkDevice,
    buffer_size: c.VkDeviceSize,
    buffer_usage: c.VkBufferUsageFlags,
    buffer_properties: c.VkMemoryPropertyFlags,
};

pub const TransferBufferOpts = struct {
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
    handle: c.VkBuffer = undefined,
    memory: c.VkDeviceMemory = undefined,

    pub fn deleteAndFree(self: Buffer, device: c.VkDevice) void {
        c.vkDestroyBuffer(device, self.handle, null);
        c.vkFreeMemory(device, self.memory, null);
    }
};

pub const MeshBuffer = struct {
    vertex_buffer: c.VkBuffer,
    vertex_memory: c.VkDeviceMemory,
    vertex_count: u32,

    index_buffer: c.VkBuffer,
    index_memory: c.VkDeviceMemory,
    index_count: u32,

    pub fn deleteAndFree(self: MeshBuffer, device: c.VkDevice) void {
        c.vkDestroyBuffer(device, self.vertex_buffer, null);
        c.vkFreeMemory(device, self.vertex_memory, null);
        c.vkDestroyBuffer(device, self.index_buffer, null);
        c.vkFreeMemory(device, self.index_memory, null);
    }
};

pub fn createBuffer(opts: BufferOpts) !Buffer {
    const buffer_create_info = std.mem.zeroInit(c.VkBufferCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        .size = opts.buffer_size,
        .usage = opts.buffer_usage,
        .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
    });

    var handle: c.VkBuffer = undefined;
    try vke.checkResult(c.vkCreateBuffer(opts.device, &buffer_create_info, null, &handle));

    var memory_req: c.VkMemoryRequirements = undefined;
    c.vkGetBufferMemoryRequirements(opts.device, handle, &memory_req);

    var memory_alloc_info = std.mem.zeroInit(c.VkMemoryAllocateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        .allocationSize = memory_req.size,
        .memoryTypeIndex = findMemoryTypeIndex(
            opts.physical_device,
            memory_req.memoryTypeBits,
            opts.buffer_properties,
        ),
    });

    var memory: c.VkDeviceMemory = undefined;
    try vke.checkResult(c.vkAllocateMemory(opts.device, &memory_alloc_info, null, &memory));
    try vke.checkResult(c.vkBindBufferMemory(opts.device, handle, memory, 0));

    return .{
        .handle = handle,
        .memory = memory,
    };
}

pub fn allocAndBeginCommandBuffer(device: c.VkDevice, command_pool: c.VkCommandPool) !c.VkCommandBuffer {
    const alloc_info = std.mem.zeroInit(c.VkCommandBufferAllocateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
        .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        .commandPool = command_pool,
        .commandBufferCount = 1,
    });

    var command_buffer: c.VkCommandBuffer = undefined;
    try vke.checkResult(c.vkAllocateCommandBuffers(device, &alloc_info, &command_buffer));

    const begin_info = std.mem.zeroInit(c.VkCommandBufferBeginInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        .flags = c.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
    });

    try vke.checkResult(c.vkBeginCommandBuffer(command_buffer, &begin_info));
    return command_buffer;
}

/// End the command buffer and submit it to the queue.
pub fn endAndFreeCommandBuffer(device: c.VkDevice, command_pool: c.VkCommandPool, command_buffer: c.VkCommandBuffer, queue: c.VkQueue) !void {
    try vke.checkResult(c.vkEndCommandBuffer(command_buffer));

    const submit_info = std.mem.zeroInit(c.VkSubmitInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .commandBufferCount = 1,
        .pCommandBuffers = &command_buffer,
    });

    try vke.checkResult(c.vkQueueSubmit(queue, 1, &submit_info, null));
    try vke.checkResult(c.vkQueueWaitIdle(queue));

    c.vkFreeCommandBuffers(device, command_pool, 1, &command_buffer);
}

fn copyBuffer(src_buffer: c.VkBuffer, dst_buffer: c.VkBuffer, buffer_size: c.VkDeviceSize, opts: TransferBufferOpts) !void {
    const transfer_command_buffer = try allocAndBeginCommandBuffer(opts.device, opts.command_pool);
    var buffer_copy_region = c.VkBufferCopy{
        .srcOffset = 0,
        .dstOffset = 0,
        .size = buffer_size,
    };
    c.vkCmdCopyBuffer(transfer_command_buffer, src_buffer, dst_buffer, 1, &buffer_copy_region);
    try endAndFreeCommandBuffer(opts.device, opts.command_pool, transfer_command_buffer, opts.transfer_queue);
}

pub fn copyImageBuffer(src_buffer: c.VkBuffer, dst_image: c.VkImage, width: u32, height: u32, opts: TransferBufferOpts) !void {
    const transfer_command_buffer = try allocAndBeginCommandBuffer(opts.device, opts.command_pool);

    const image_region = std.mem.zeroInit(c.VkBufferImageCopy, .{
        .bufferOffset = 0,
        .bufferRowLength = 0,
        .bufferImageHeight = 0,
        .imageSubresource = c.VkImageSubresourceLayers{
            .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
            .mipLevel = 0,
            .baseArrayLayer = 0,
            .layerCount = 1,
        },
        .imageOffset = .{ .x = 0, .y = 0, .z = 0 },
        .imageExtent = .{ .width = width, .height = height, .depth = 1 },
    });

    c.vkCmdCopyBufferToImage(transfer_command_buffer, src_buffer, dst_image, c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &image_region);
    try endAndFreeCommandBuffer(opts.device, opts.command_pool, transfer_command_buffer, opts.transfer_queue);
}

pub fn createVertexBuffer(vertices: []scene.Vertex, opts: VertexBufferOpts) !MeshBuffer {
    const buffer_size = @sizeOf(scene.Vertex) * vertices.len;

    var staging_buffer = try createBuffer(.{
        .physical_device = opts.physical_device,
        .device = opts.device,
        .buffer_properties = c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        .buffer_size = buffer_size,
        .buffer_usage = c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
    });
    defer staging_buffer.deleteAndFree(opts.device);

    var staging_data: ?*align(@alignOf(scene.Vertex)) anyopaque = undefined;
    try vke.checkResult(c.vkMapMemory(opts.device, staging_buffer.memory, 0, buffer_size, 0, &staging_data));
    @memcpy(@as([*]scene.Vertex, @ptrCast(staging_data)), vertices);
    c.vkUnmapMemory(opts.device, staging_buffer.memory);

    const vertex_buffer = try createBuffer(.{
        .physical_device = opts.physical_device,
        .device = opts.device,
        .buffer_properties = c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
        .buffer_size = buffer_size,
        .buffer_usage = c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
    });

    try copyBuffer(staging_buffer.handle, vertex_buffer.handle, buffer_size, .{
        .device = opts.device,
        .transfer_queue = opts.transfer_queue,
        .command_pool = opts.transfer_command_pool,
    });

    return .{
        .vertex_buffer = vertex_buffer.handle,
        .vertex_memory = vertex_buffer.memory,
        .vertex_count = @as(u32, @intCast(vertices.len)),
        .index_buffer = undefined,
        .index_memory = undefined,
        .index_count = 0,
    };
}

pub fn createIndexBuffer(indices: []u32, opts: VertexBufferOpts, mesh_buffer: *MeshBuffer) !void {
    const buffer_size = @sizeOf(u32) * indices.len;

    const staging_buffer = try createBuffer(.{
        .physical_device = opts.physical_device,
        .device = opts.device,
        .buffer_properties = c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        .buffer_size = buffer_size,
        .buffer_usage = c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
    });
    defer staging_buffer.deleteAndFree(opts.device);

    var staging_data: ?*align(@alignOf(u32)) anyopaque = undefined;
    try vke.checkResult(c.vkMapMemory(opts.device, staging_buffer.memory, 0, buffer_size, 0, &staging_data));
    @memcpy(@as([*]u32, @ptrCast(staging_data)), indices);
    c.vkUnmapMemory(opts.device, staging_buffer.memory);

    const index_buffer = try createBuffer(.{
        .physical_device = opts.physical_device,
        .device = opts.device,
        .buffer_properties = c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
        .buffer_size = buffer_size,
        .buffer_usage = c.VK_BUFFER_USAGE_TRANSFER_DST_BIT | c.VK_BUFFER_USAGE_INDEX_BUFFER_BIT,
    });

    try copyBuffer(staging_buffer.handle, index_buffer.handle, buffer_size, .{
        .device = opts.device,
        .transfer_queue = opts.transfer_queue,
        .command_pool = opts.transfer_command_pool,
    });

    mesh_buffer.index_buffer = index_buffer.handle;
    mesh_buffer.index_memory = index_buffer.memory;
    mesh_buffer.index_count = @as(u32, @intCast(indices.len));
}

pub fn findMemoryTypeIndex(physical_device: c.VkPhysicalDevice, allowed_types: u32, property_flags: c.VkMemoryPropertyFlags) u32 {
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
