const std = @import("std");
const vke = @import("./error.zig");
const c = @import("../clibs.zig");
const vkb = @import ("./buffer.zig");
const scene = @import("../mesh/scene.zig");

pub const DescriptorSetLayout = struct {
    handle: c.VkDescriptorSetLayout,
};

pub const UniformBufferOpts = struct {
    physical_device: c.VkPhysicalDevice,
    device: c.VkDevice,
    buffer_count: u32,
};

pub const UniformBuffer = struct {
    handle: c.VkBuffer = undefined,
    memory: c.VkDeviceMemory = undefined,

    pub fn deleteAndFree(self: UniformBuffer, device: c.VkDevice) void {
        c.vkDestroyBuffer(device, self.handle, null);
        c.vkFreeMemory(device, self.memory, null);
    }
};

pub const DescriptorPool = struct {
    handle: c.VkDescriptorPool,
};

// This creates the descriptor set layout for the uniform buffer that will be used in the vertex shader.
pub fn createDescriptorSetLayout(device: c.VkDevice) !DescriptorSetLayout {
    const mvp_binding_info = std.mem.zeroInit(c.VkDescriptorSetLayoutBinding, .{
        .binding = 0,
        .descriptorType = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        .descriptorCount = 1,
        .stageFlags = c.VK_SHADER_STAGE_VERTEX_BIT,
        .pImmutableSamplers = null,
    });

    const bindings = [_]c.VkDescriptorSetLayoutBinding{ mvp_binding_info };

    var layout_info = std.mem.zeroInit(c.VkDescriptorSetLayoutCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
        .bindingCount = 1,
        .pBindings = &bindings,
    });

    var layout: c.VkDescriptorSetLayout = undefined;
    try vke.checkResult(c.vkCreateDescriptorSetLayout(device, &layout_info, null, &layout));
    return DescriptorSetLayout{ .handle = layout };
}

/// This creates the uniform buffers and allocates the memory for them based on the number frame buffers
/// that will be used. You own the returned buffers and must free them when done.
pub fn createUniformBuffers(a: std.mem.Allocator, opts: UniformBufferOpts) ![]UniformBuffer {
    var uniform_buffers: []UniformBuffer = try a.alloc(UniformBuffer, opts.buffer_count);

    const buffer_size = @sizeOf(scene.MVP);
    for (uniform_buffers, 0..) |_, i| {
        var staging_buffer_handle: c.VkBuffer = undefined;
        var staging_buffer_memory: c.VkDeviceMemory = undefined;
        const buffer = .{
            .handle = @as([*c]c.VkBuffer, @ptrCast(&staging_buffer_handle)),
            .memory = @as([*c]c.VkDeviceMemory, @ptrCast(&staging_buffer_memory)),
        };

        try vkb.createBuffer(&buffer, .{
            .physical_device = opts.physical_device,
            .device = opts.device,
            .buffer_size = buffer_size,
            .buffer_usage = c.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT,
            .buffer_properties = c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        });

        uniform_buffers[i] = .{
            .handle = buffer.handle.*,
            .memory = buffer.memory.*,
        };
    }

    return uniform_buffers;
}

pub fn createDescriptorPool(device: c.VkDevice, buffer_count: u32) !DescriptorPool {
    var pool_sizes = std.mem.zeroInit(c.VkDescriptorPoolSize, .{
        .type = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        .descriptorCount = buffer_count,
    });

    var pool_info = std.mem.zeroInit(c.VkDescriptorPoolCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
        .poolSizeCount = 1,
        .pPoolSizes = &pool_sizes,
        .maxSets = buffer_count,
    });

    var pool: c.VkDescriptorPool = undefined;
    try vke.checkResult(c.vkCreateDescriptorPool(device, &pool_info, null, &pool));
    return .{ .handle = pool };
}

pub fn createDescriptorSets(a: std.mem.Allocator, buffer_count: u32, device: c.VkDevice, descriptor_pool: c.VkDescriptorPool, descriptor_set_layout: c.VkDescriptorSetLayout, uniform_buffers: []UniformBuffer) ![]c.VkDescriptorSet {
    var layouts = [_]c.VkDescriptorSetLayout{ descriptor_set_layout, descriptor_set_layout };

    var alloc_info = std.mem.zeroInit(c.VkDescriptorSetAllocateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
        .descriptorPool = descriptor_pool,
        .descriptorSetCount = buffer_count,
        .pSetLayouts = &layouts,
    });
    
    const sets = try a.alloc(c.VkDescriptorSet, buffer_count);
    try vke.checkResult(c.vkAllocateDescriptorSets(device, &alloc_info, sets.ptr));

    for (sets, 0..) |set, i| {
        var buffer_info = std.mem.zeroInit(c.VkDescriptorBufferInfo, .{
            .buffer = uniform_buffers[i].handle,
            .offset = 0,
            .range = @sizeOf(scene.MVP),
        });

        var mvp_set_writes = std.mem.zeroInit(c.VkWriteDescriptorSet, .{
            .sType = c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
            .dstSet = set,
            .dstBinding = 0,
            .dstArrayElement = 0,
            .descriptorType = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
            .descriptorCount = 1,
            .pBufferInfo = &buffer_info,
        });

        c.vkUpdateDescriptorSets(device, 1, &mvp_set_writes, 0, null);
    }

    return sets;
}