const std = @import("std");
const vke = @import("./error.zig");
const c = @import("../clibs.zig");
const vkb = @import ("./buffer.zig");
const vkd = @import ("./device.zig");
const scene = @import("scene");
const testing = std.testing;

pub const DescriptorSetLayout = struct {
    handle: c.VkDescriptorSetLayout,
};

pub const UniformBufferOpts = struct {
    physical_device: c.VkPhysicalDevice,
    device: c.VkDevice,
    buffer_count: u32,
    model_memory_alignment: usize,
    max_objects: u32,
};

pub const BufferSet = struct {
    camera: vkb.Buffer = undefined,
    // model: UniformBuffer = undefined,

    pub fn deleteAndFree(self: BufferSet, device: c.VkDevice) void {
        self.camera.deleteAndFree(device);
        // self.model.deleteAndFree(device);
    }
};


pub const DescriptorPool = struct {
    handle: c.VkDescriptorPool,
};

// This creates the descriptor set layout for the uniform buffer that will be used in the vertex shader.
pub fn createDescriptorSetLayout(device: c.VkDevice) !DescriptorSetLayout {
    const camera_binding_info = std.mem.zeroInit(c.VkDescriptorSetLayoutBinding, .{
        .binding = 0,
        .descriptorType = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        .descriptorCount = 1,
        .stageFlags = c.VK_SHADER_STAGE_VERTEX_BIT,
        .pImmutableSamplers = null,
    });

    // const model_binding_info = std.mem.zeroInit(c.VkDescriptorSetLayoutBinding, .{
    //     .binding = 1,
    //     .descriptorType = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC,
    //     .descriptorCount = 1,
    //     .stageFlags = c.VK_SHADER_STAGE_VERTEX_BIT,
    //     .pImmutableSamplers = null,
    // });

    // const bindings = [_]c.VkDescriptorSetLayoutBinding{ camera_binding_info, model_binding_info};
    const bindings = [_]c.VkDescriptorSetLayoutBinding{ camera_binding_info };

    var layout_info = std.mem.zeroInit(c.VkDescriptorSetLayoutCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
        .bindingCount = @as(u32, bindings.len),
        .pBindings = &bindings,
    });

    var layout: c.VkDescriptorSetLayout = undefined;
    try vke.checkResult(c.vkCreateDescriptorSetLayout(device, &layout_info, null, &layout));
    return DescriptorSetLayout{ .handle = layout };
}

/// This creates the uniform buffers and allocates the memory for them based on the number frame buffers
/// that will be used. You own the returned buffers and must free them when done.
pub fn createUniformBuffers(a: std.mem.Allocator, opts: UniformBufferOpts) ![]BufferSet {
    var buffer_set: []BufferSet = try a.alloc(BufferSet, opts.buffer_count);

    // const model_buffer_size = opts.model_memory_alignment * opts.max_objects;

    const buffer_size = @sizeOf(scene.Camera);
    for (0..opts.buffer_count) |i| {
       

        const buffer = try vkb.createBuffer(.{
            .physical_device = opts.physical_device,
            .device = opts.device,
            .buffer_size = buffer_size,
            .buffer_usage = c.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT,
            .buffer_properties = c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        });

        buffer_set[i].camera = .{
            .handle = buffer.handle,
            .memory = buffer.memory,
        };

        // var model_buffer_handle: c.VkBuffer = undefined;
        // var model_buffer_memory: c.VkDeviceMemory = undefined;
        // const model_buffer = .{
        //     .handle = @as([*c]c.VkBuffer, @ptrCast(&model_buffer_handle)),
        //     .memory = @as([*c]c.VkDeviceMemory, @ptrCast(&model_buffer_memory)),
        // };

        // try vkb.createBuffer(&model_buffer, .{
        //     .physical_device = opts.physical_device,
        //     .device = opts.device,
        //     .buffer_size = model_buffer_size,
        //     .buffer_usage = c.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT,
        //     .buffer_properties = c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        // });

        // buffer_set[i].model = .{
        //     .handle = model_buffer.handle.*,
        //     .memory = model_buffer.memory.*,
        // };
    }

    return buffer_set;
}

pub fn createDescriptorPool(device: c.VkDevice, buffer_count: u32) !DescriptorPool {
    const camera_pool_sizes = std.mem.zeroInit(c.VkDescriptorPoolSize, .{
        .type = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
        .descriptorCount = buffer_count,
    });

    // const model_pool_sizes = std.mem.zeroInit(c.VkDescriptorPoolSize, .{
    //     .type = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC,
    //     .descriptorCount = buffer_count,
    // });

    // const pool_sizes = [_]c.VkDescriptorPoolSize{ camera_pool_sizes, model_pool_sizes };
    const pool_sizes = [_]c.VkDescriptorPoolSize{ camera_pool_sizes };

    const pool_info = std.mem.zeroInit(c.VkDescriptorPoolCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
        .poolSizeCount = @as(u32, pool_sizes.len),
        .pPoolSizes = &pool_sizes,
        .maxSets = buffer_count,
    });

    var pool: c.VkDescriptorPool = undefined;
    try vke.checkResult(c.vkCreateDescriptorPool(device, &pool_info, null, &pool));
    return .{ .handle = pool };
}

pub fn createDescriptorSets(a: std.mem.Allocator, buffer_count: u32, device: c.VkDevice, descriptor_pool: c.VkDescriptorPool, descriptor_set_layout: c.VkDescriptorSetLayout, buffer_set: []BufferSet, _: u64) ![]c.VkDescriptorSet {
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
        const camera_buffer_info = std.mem.zeroInit(c.VkDescriptorBufferInfo, .{
            .buffer = buffer_set[i].camera.handle,
            .offset = 0,
            .range = @sizeOf(scene.Camera),
        });

        const camera_set_writes = std.mem.zeroInit(c.VkWriteDescriptorSet, .{
            .sType = c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
            .dstSet = set,
            .dstBinding = 0,
            .dstArrayElement = 0,
            .descriptorType = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
            .descriptorCount = 1,
            .pBufferInfo = &camera_buffer_info,
        });

        // const model_buffer_info = std.mem.zeroInit(c.VkDescriptorBufferInfo, .{
        //     .buffer = buffer_set[i].model.handle,
        //     .offset = 0,
        //     .range = model_memory_alignment,
        // });

        // const model_set_writes = std.mem.zeroInit(c.VkWriteDescriptorSet, .{
        //     .sType = c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
        //     .dstSet = set,
        //     .dstBinding = 1,
        //     .dstArrayElement = 0,
        //     .descriptorType = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC,
        //     .descriptorCount = 1,
        //     .pBufferInfo = &model_buffer_info,
        // });

        // const descriptor_writes = [_]c.VkWriteDescriptorSet{ camera_set_writes, model_set_writes };
        const descriptor_writes = [_]c.VkWriteDescriptorSet{ camera_set_writes };
        c.vkUpdateDescriptorSets(device, @as(u32, descriptor_writes.len), &descriptor_writes, 0, null);
    }

    return sets;
}

pub fn allocate_model_transfer_space(a: std.mem.Allocator, offset_alignment: u64, max_objects: u32) ![]scene.UBO {
    const padded_alignment = pad_with_buffer_offset(@sizeOf(scene.UBO), offset_alignment);
    const data_size = padded_alignment * max_objects;

    const transfer_space = try a.alloc(scene.UBO, data_size);

    return transfer_space;
}

/// This calculates the size of the dynamic uniform buffer padding since the size of the object needs to
/// align to the device's buffer offset.
pub fn pad_with_buffer_offset(size: usize, min_buffer_offset: u64) usize {
    const val = (size + min_buffer_offset - 1) & ~(min_buffer_offset - 1);
    return val;
}

test "pad_with_buffer_offset size is zero" {
    try testing.expectEqual(pad_with_buffer_offset(0, 32), 0);
}

test "pad_with_buffer_offset size is one less than minimum buffer offset" {
    try testing.expectEqual(pad_with_buffer_offset(31, 32), 32);
}

test "pad_with_buffer_offset size is equal to minimum buffer offset" {
    try testing.expectEqual(pad_with_buffer_offset(32, 32), 32);
}

test "pad_with_buffer_offset size is double minimum buffer offset" {
    try testing.expectEqual(pad_with_buffer_offset(64, 32), 64);
}

test "pad_with_buffer_offset size is one more than minimum buffer offset" {
    try testing.expectEqual(pad_with_buffer_offset(33, 32), 64);
}

test "pad_with_buffer_offset size is one less than double minimum buffer offset" {
    try testing.expectEqual(pad_with_buffer_offset(63, 32), 64);
}

test "pad_with_buffer_offset size is double plus one more than minimum buffer offset" {
    try testing.expectEqual(pad_with_buffer_offset(65, 32), 96);
}


