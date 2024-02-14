const std = @import("std");
const c = @import("../clibs.zig");
const vke = @import ("./error.zig");
const mesh = @import("../mesh/mesh.zig");

pub const BufferOpts = struct {
    physical_device: c.VkPhysicalDevice = undefined, 
    device: c.VkDevice = undefined, 
    buffer_size: c.VkDeviceSize = undefined, 
    buffer_usage: c.VkBufferUsageFlags = undefined,
    buffer_properties: c.VkMemoryPropertyFlags = undefined,
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
    vertex_count: u32,

    pub fn deleteAndFree(self: *VertexBuffer, device: c.VkDevice) void {
        c.vkDestroyBuffer(device, self.handle, null);
        c.vkFreeMemory(device, self.memory, null);
    }
};

pub fn createBuffer(buffer: *const Buffer, opts: BufferOpts) !void {
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

pub fn createVertexBuffer(physical_device: c.VkPhysicalDevice, device: c.VkDevice, vertices: []mesh.Vertex) !VertexBuffer {
    const buffer_size = @sizeOf(mesh.Vertex) * vertices.len;
    var buffer_handle: c.VkBuffer = undefined;
    var buffer_memory: c.VkDeviceMemory = undefined;
    var buffer: Buffer = .{
        .handle = @as([*c] c.VkBuffer, @ptrCast(&buffer_handle)),
        .memory = @as([*c] c.VkDeviceMemory, @ptrCast(&buffer_memory)),
    };
    try createBuffer(&buffer, .{
        .physical_device = physical_device,
        .device = device,
        .buffer_properties = c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        .buffer_size = buffer_size,
        .buffer_usage = c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
    });

    var data: ?*align(@alignOf(mesh.Vertex)) anyopaque = undefined;
    try vke.checkResult(c.vkMapMemory(device, buffer.memory.*, 0, buffer_size, 0, &data));
    @memcpy(@as([*]mesh.Vertex, @ptrCast(data)), vertices);
    c.vkUnmapMemory(device, buffer.memory.*);

    return .{
        .handle = buffer.handle.*,
        .memory = buffer.memory.*,
        .vertex_count = @as(u32, @intCast(vertices.len)),
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