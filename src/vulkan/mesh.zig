const std = @import("std");
const c = @import("../clibs.zig");
const vke = @import ("./error.zig");
const mesh = @import("../mesh/mesh.zig");

pub const Buffer = struct {
    handle: c.VkBuffer,
    memory: c.VkDeviceMemory,
    vertex_count: u32,

    pub fn deleteAndFree(self: *Buffer, device: c.VkDevice) void {
        c.vkDestroyBuffer(device, self.handle, null);
        c.vkFreeMemory(device, self.memory, null);
    }
};

pub fn createVertexBuffer(physical_device: c.VkPhysicalDevice, device: c.VkDevice, vertices: []mesh.Vertex) !Buffer {
    const buffer_create_info = std.mem.zeroInit(c.VkBufferCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        .size = @sizeOf(mesh.Vertex) * vertices.len,
        .usage = c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
        .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
    });

    var buffer: c.VkBuffer = undefined;
    try vke.checkResult(c.vkCreateBuffer(device, &buffer_create_info, null, &buffer));

    var memory_req: c.VkMemoryRequirements = undefined;
    c.vkGetBufferMemoryRequirements(device, buffer, &memory_req);

    var memory_alloc_info = std.mem.zeroInit(c.VkMemoryAllocateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        .allocationSize = memory_req.size,
        .memoryTypeIndex = findMemoryTypeIndex(
            physical_device, 
            memory_req.memoryTypeBits,
            c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
            ),
    });

    var buffer_memory: c.VkDeviceMemory = undefined;
    try vke.checkResult(c.vkAllocateMemory(device, &memory_alloc_info, null, &buffer_memory));
    try vke.checkResult(c.vkBindBufferMemory(device, buffer, buffer_memory, 0));

    var data: ?*align(@alignOf(mesh.Vertex)) anyopaque = undefined;
    try vke.checkResult(c.vkMapMemory(device, buffer_memory, 0, buffer_create_info.size, 0, &data));
    @memcpy(@as([*]mesh.Vertex, @ptrCast(data)), vertices);
    c.vkUnmapMemory(device, buffer_memory);

    return .{
        .handle = buffer,
        .memory = buffer_memory,
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