const std = @import("std");
const ecs = @import("flecs");
const app = @import("../app.zig");
const c = @import("../clibs.zig");
const sdl = @import("../sdl.zig");
const vkc = @import("command.zig");
const vkd = @import("device.zig");
const vki = @import("instance.zig");
const vks = @import("swapchain.zig");
const vksync = @import("synchronization.zig");
const vkp = @import("pipeline.zig");
const vkr = @import("render_pass.zig");
const vkb = @import("buffer.zig");
const vkds = @import("descriptor_set.zig");
const vkt = @import("texture.zig");
const scene = @import("scene");

const MAX_OBJECTS = 1000;
const MAX_FRAME_DRAWS = 3;

const Device = struct {
    instance: c.VkInstance,
    physical: c.VkPhysicalDevice,
    logical: c.VkDevice,
    debug_messenger: c.VkDebugUtilsMessengerEXT
};

const DeviceEntity = struct {
    entity: ecs.entity_t,
};

const BufferOffset = struct {
    alignment: u64,
};

const Surface = struct {
    handle: c.VkSurfaceKHR,
};

const Queue = struct {
    graphics: c.VkQueue,
    presentation: c.VkQueue,
};

const QueueIndex = struct {
    graphics: u32,
    presentation: u32,
};

const Swapchain = struct {
    handle: c.VkSwapchainKHR,
    extent: c.VkExtent2D,
    format: c.VkFormat,
};

const BufferCount = struct {
    count: u32,
};

const ImageAssets = struct {
    images: []c.VkImage,
    image_views: []c.VkImageView,
};

pub const RenderPass = struct {
    handle: c.VkRenderPass,
};

pub const DepthImage = struct {
    image: c.VkImage,
    image_view: c.VkImageView,
    memory: c.VkDeviceMemory,
};

pub const DescriptorSetLayout = struct {
    handle: c.VkDescriptorSetLayout,
    sampler_handle: c.VkDescriptorSetLayout,
};

pub const UniformBuffers = struct {
    buffers: []vkds.BufferSet
};

pub const DescriptorPool = struct {
    handle: c.VkDescriptorPool,
    sampler_handle: c.VkDescriptorPool,
};

pub const DescriptorSets = struct {
    sets: []c.VkDescriptorSet,
};

pub const Pipeline = struct {
    graphics_handle: c.VkPipeline,
    layout: c.VkPipelineLayout,
};

pub const Framebuffers = struct {
    handles: []c.VkFramebuffer,
};

pub const CommandBuffers = struct {
    handles: []c.VkCommandBuffer,
};

pub const CommandPool = struct {
    handle: c.VkCommandPool,
};

pub const ImageAvailableSemaphores = struct {
    handles: []c.VkSemaphore,
};

pub const RenderFinishedSemaphores = struct {
    handles: []c.VkSemaphore,
};

pub const DrawFences = struct {
    handles: []c.VkFence,
};

pub const VertexBuffer = struct {
    buffer: c.VkBuffer,
    memory: c.VkDeviceMemory,
    count: u32,
};

pub const IndexBuffer = struct {
    buffer: c.VkBuffer,
    memory: c.VkDeviceMemory,
    count: u32,
};

pub const Texture = struct {
    image: c.VkImage,
    memory: c.VkDeviceMemory,
    image_view: c.VkImageView,
    sampler: c.VkSampler,
    descriptor_sets: []c.VkDescriptorSet,
};

const vk_alloc_callbacks: ?*c.VkAllocationCallbacks = null;

/// Create the device and its associated surface
fn createDevice(it: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Start up: {s}\n", .{ecs.get_name(it.world, it.system).?});
    const allocator = ecs.singleton_get(it.world, app.Allocator).?;

    for (0..it.count()) |i| {
        const e = it.entities()[i];
        const window = ecs.get(it.world, e, sdl.Window).?;

        var surface: c.VkSurfaceKHR = undefined;
        const instance = vki.createAppInstance(allocator.alloc, window.handle);
        sdl.checkSdlBool(c.SDL_Vulkan_CreateSurface(window.handle, instance.handle, &surface));

        const required_device_extensions = .{
            c.VK_KHR_SWAPCHAIN_EXTENSION_NAME,
        };
        const physical_device = vkd.getPhysicalDevice(allocator.alloc, instance.handle, surface, &required_device_extensions) catch |err| {
            std.debug.print("Failed to find a suitable GPU: {}\n", .{err});
            return;
        };
        const device = vkd.createLogicalDevice(allocator.alloc, physical_device, &required_device_extensions) catch |err| {
            std.debug.print("Failed to create logical device: {}\n", .{err});
            return;
        };

        const model_uniform_alignment = vkds.padWithBufferOffset(@sizeOf(scene.UBO), physical_device.min_uniform_buffer_offset_alignment);

        const new_entity = ecs.new_entity(it.world, "VulkanDevice");
        _ = ecs.set(it.world, new_entity, Device, .{ 
            .instance = instance.handle, 
            .physical = physical_device.handle, 
            .logical = device.handle, 
            .debug_messenger = instance.debug_messenger 
        });

        _ = ecs.set(it.world, new_entity, Surface, .{ .handle = surface });
        _ = ecs.set(it.world, new_entity, app.CanvasSize, . { .width = window.width, .height = window.height });
        _ = ecs.set(it.world, new_entity, BufferOffset, .{ .alignment = model_uniform_alignment });
        _ = ecs.set(it.world, new_entity, QueueIndex, .{ 
            .graphics = physical_device.queue_indices.graphics_queue_location,
            .presentation = physical_device.queue_indices.presentation_queue_location,
        });
        _ = ecs.set(it.world, new_entity, Queue, .{ 
            .graphics = device.graphics_queue,
            .presentation = device.presentation_queue,
        });
    }
}

/// Destroy the device and its associated surface, this will also destroy the instance
fn destroyDevice(it: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Shut down: {s}\n", .{ecs.get_name(it.world, it.system).?});
    const devices = ecs.field(it, Device, 1).?;
    const surfaces = ecs.field(it, Surface, 2).?;

    for (0..it.count()) |i| {
        const device = devices[i];
        const surface = surfaces[i];

        c.vkDestroySurfaceKHR(device.instance, surface.handle, null);
        c.vkDestroyDevice(device.logical, null);
        if (device.debug_messenger != null) {
            const destroyFn = vki.getDestroyDebugUtilsMessengerFn(device.instance).?;
            destroyFn(device.instance, device.debug_messenger, vk_alloc_callbacks);
        }
        c.vkDestroyInstance(device.instance, null);
    }

    ecs.quit(it.world);
}

/// Create the swapchain and its associated image assets
fn createSwapchain(it: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Start up: {s}\n", .{ecs.get_name(it.world, it.system).?});
    const allocator = ecs.singleton_get(it.world, app.Allocator).?;

    const devices = ecs.field(it, Device, 1).?;
    const surfaces = ecs.field(it, Surface, 2).?;
    const queue_indexes = ecs.field(it, QueueIndex, 3).?;
    const canvas_sizes = ecs.field(it, app.CanvasSize, 4).?;

    for (0..it.count()) |i| {
        const device = devices[i];
        const surface = surfaces[i];
        const queue_index = queue_indexes[i];
        const canvas_size = canvas_sizes[i];

        const swapchain = vks.createSwapchain(allocator.alloc, device.physical, device.logical, surface.handle, .{
            .graphics_queue_index = queue_index.graphics,
            .presentation_queue_index = queue_index.presentation,
            .window_height = @intCast(canvas_size.width),
            .window_width = @intCast(canvas_size.height),
        }) catch |err| {
            std.debug.print("Failed to create swapchain: {}\n", .{err});
            return;
        };

        const depth_image = vks.createDepthBufferImage(device.physical, device.logical, swapchain.image_extent) catch |err| {
            std.debug.print("Failed to create depth image: {}\n", .{err});
            return;
        };

        _ = ecs.set(it.world, it.entities()[i], Swapchain, .{ 
            .handle = swapchain.handle, 
            .extent = swapchain.image_extent,
            .format = swapchain.surface_format.format,
        });
        _ = ecs.set(it.world, it.entities()[i], ImageAssets, .{ 
            .images = swapchain.images, 
            .image_views = swapchain.image_views,
        });
        _ = ecs.set(it.world, it.entities()[i], DepthImage, .{ 
            .image = depth_image.image, 
            .image_view = depth_image.image_view, 
            .memory = depth_image.memory,
        });
        _ = ecs.set(it.world, it.entities()[i], BufferCount, .{ .count = @as(u32, @intCast(swapchain.images.len)) });
        ecs.enable_id(it.world, it.entities()[i], ecs.id(app.CanvasSize), false);
    }
}

/// Destroy the swapchain and its associated image assets
fn destroySwapchain(it: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Shut down: {s}\n", .{ecs.get_name(it.world, it.system).?});
    const allocator = ecs.singleton_get(it.world, app.Allocator).?;

    const devices = ecs.field(it, Device, 1).?;
    const swapchains = ecs.field(it, Swapchain, 2).?;
    const image_assets = ecs.field(it, ImageAssets, 3).?;
    const depth_images = ecs.field(it, DepthImage, 4).?;

    for (0..it.count()) |i| {
        const device = devices[i];
        const swapchain = swapchains[i];
        const assets = image_assets[i];
        const depth_image = depth_images[i];

        c.vkDestroyImageView(device.logical, depth_image.image_view, null);
        c.vkDestroyImage(device.logical, depth_image.image, null);
        c.vkFreeMemory(device.logical, depth_image.memory, null);

        for (assets.image_views) |image_view| {
            c.vkDestroyImageView(device.logical, image_view, null);
        }
        c.vkDestroySwapchainKHR(device.logical, swapchain.handle, null);
        allocator.alloc.free(assets.images);
        allocator.alloc.free(assets.image_views);

        ecs.remove(it.world, it.entities()[i], ImageAssets);
        ecs.remove(it.world, it.entities()[i], Swapchain);
    }
}

fn createRenderPass(it: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Start up: {s}\n", .{ecs.get_name(it.world, it.system).?});
    const allocator = ecs.singleton_get(it.world, app.Allocator).?;
    const devices = ecs.field(it, Device, 1).?;
    const swapchains = ecs.field(it, Swapchain, 2).?;
    const buffer_counts = ecs.field(it, BufferCount, 3).?;
    const buffer_offsets = ecs.field(it, BufferOffset, 4).?;
    const depth_images = ecs.field(it, DepthImage, 5).?;
    const images_assets = ecs.field(it, ImageAssets, 6).?;


    for (0..it.count()) |i| {
        const device = devices[i];
        const swapchain = swapchains[i];
        const buffer_count = buffer_counts[i];
        const buffer_offset = buffer_offsets[i];
        const depth_image = depth_images[i];
        const image_assets = images_assets[i];

        const render_pass = vkr.createRenderPass(device.physical, device.logical, swapchain.format) catch |err| {
            std.debug.print("Failed to create render pass: {}\n", .{err});
            return;
        };

        const descriptor_set_layout = vkds.createDescriptorSetLayout(device.logical) catch |err| {
            std.debug.print("Failed to create descriptor set layout: {}\n", .{err});
            return;
        };

        const sampler_descriptor_set_layout = vkds.createSamplerDescriptorSetLayout(device.logical) catch |err| {
            std.debug.print("Failed to create sampler descriptor set layout: {}\n", .{err});
            return;
        };

        const uniform_buffers = vkds.createUniformBuffers(allocator.alloc, .{
            .physical_device = device.physical,
            .device = device.logical,
            .buffer_count = buffer_count.count,
            .model_memory_alignment = buffer_offset.alignment,
            .max_objects = MAX_OBJECTS,
        }) catch |err| {
            std.debug.print("Failed to create uniform buffers: {}\n", .{err});
            return;
        };

        const descriptor_pool = vkds.createDescriptorPool(device.logical, buffer_count.count) catch |err| {
            std.debug.print("Failed to create descriptor pool: {}\n", .{err});
            return;
        };

        const sampler_descriptor_pool = vkds.createSamplerDescriptorPool(device.logical, MAX_OBJECTS) catch |err| {
            std.debug.print("Failed to create sampler descriptor pool: {}\n", .{err});
            return;
        };

        const descriptor_sets = vkds.createDescriptorSets(allocator.alloc, buffer_count.count, device.logical, descriptor_pool.handle, descriptor_set_layout.handle, uniform_buffers, buffer_offset.alignment) catch |err| {
            std.debug.print("Failed to create descriptor sets: {}\n", .{err});
            return;
        };

        const push_constant_range = c.VkPushConstantRange{
            .stageFlags = c.VK_SHADER_STAGE_VERTEX_BIT,
            .offset = 0,
            .size = @sizeOf(scene.UBO),
        };

        const pipeline = vkp.createGraphicsPipeline(allocator.alloc, .{
            .device = device.logical,
            .swapchain_extent = swapchain.extent,
            .render_pass = render_pass.handle,
            .descriptor_set_layout = descriptor_set_layout.handle,
            .sampler_descriptor_set_layout = sampler_descriptor_set_layout.handle,
            .push_constant_range = push_constant_range,
        }) catch |err| {
            std.debug.print("Failed to create graphics pipeline: {}\n", .{err});
            return;
        };

        const swapchain_framebuffers = vks.createFramebuffer2(allocator.alloc, .{
            .device = device.logical,
            .extent = swapchain.extent,
            .image_views = image_assets.image_views,
            .image_count = buffer_count.count,
            .render_pass = render_pass.handle,
            .depth_image_view = depth_image.image_view,
        }) catch |err| {
            std.debug.print("Failed to create framebuffers: {}\n", .{err});
            return;
        };

        _ = ecs.set(it.world, it.entities()[i], RenderPass, .{ .handle = render_pass.handle });
        _ = ecs.set(it.world, it.entities()[i], DescriptorSetLayout, .{ .handle = descriptor_set_layout.handle, .sampler_handle = sampler_descriptor_set_layout.handle});
        _ = ecs.set(it.world, it.entities()[i], UniformBuffers, .{ .buffers = uniform_buffers });
        _ = ecs.set(it.world, it.entities()[i], DescriptorPool, .{ .handle = descriptor_pool.handle, .sampler_handle = sampler_descriptor_pool.handle});
        _ = ecs.set(it.world, it.entities()[i], DescriptorSets, .{ .sets = descriptor_sets });
        _ = ecs.set(it.world, it.entities()[i], Pipeline, .{ .graphics_handle = pipeline.graphics_pipeline_handle, .layout = pipeline.layout });
        _ = ecs.set(it.world, it.entities()[i], Framebuffers, .{ .handles = swapchain_framebuffers.handles });
    } 
}

fn destroyRenderPass(it: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Shut down: {s}\n", .{ecs.get_name(it.world, it.system).?});

    const allocator = ecs.singleton_get(it.world, app.Allocator).?;
    const devices = ecs.field(it, Device, 1).?;
    const render_passes = ecs.field(it, RenderPass, 2).?;
    const descriptor_set_layouts = ecs.field(it, DescriptorSetLayout, 3).?;
    const uniform_buffers = ecs.field(it, UniformBuffers, 4).?;
    const descriptor_pools = ecs.field(it, DescriptorPool, 5).?;
    const descriptor_sets = ecs.field(it, DescriptorSets, 6).?;
    const pipelines = ecs.field(it, Pipeline, 7).?;
    const framebuffers = ecs.field(it, Framebuffers, 8).?;

    for (0..it.count()) |i| {
        const device = devices[i];

        for (framebuffers[i].handles) |handle| {
            c.vkDestroyFramebuffer(device.logical, handle, null);
        }
        allocator.alloc.free(framebuffers[i].handles);
        c.vkDestroyPipeline(device.logical, pipelines[i].graphics_handle, null);

        for (uniform_buffers[i].buffers) |uniform_buffer| {
            uniform_buffer.deleteAndFree(device.logical);
        }
        allocator.alloc.free(uniform_buffers[i].buffers);

        c.vkDestroyDescriptorPool(device.logical, descriptor_pools[i].handle, null);
        c.vkDestroyDescriptorPool(device.logical, descriptor_pools[i].sampler_handle, null);
        allocator.alloc.free(descriptor_sets[i].sets);

        c.vkDestroyPipelineLayout(device.logical, pipelines[i].layout, null);
        c.vkDestroyDescriptorSetLayout(device.logical, descriptor_set_layouts[i].handle, null);
        c.vkDestroyDescriptorSetLayout(device.logical, descriptor_set_layouts[i].sampler_handle, null);

        c.vkDestroyRenderPass(device.logical, render_passes[i].handle, null);
    }
}

fn createCommandBuffers(it: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Start up: {s}\n", .{ecs.get_name(it.world, it.system).?});
    const allocator = ecs.singleton_get(it.world, app.Allocator).?;
    const devices = ecs.field(it, Device, 1).?;
    const queue = ecs.field(it, QueueIndex, 2).?;
    const buffer_counts = ecs.field(it, BufferCount, 3).?;

    for (0..it.count()) |i| {
        const device = devices[i];
        const queue_index = queue[i];
        const buffer_count = buffer_counts[i];

        const graphics_command_pool = vkc.createCommandPool(device.logical, queue_index.graphics) catch |err| {
            std.debug.print("Failed to create command pool: {}\n", .{err});
            return;
        };

        const command_buffers = vkc.createCommandBuffers(allocator.alloc, device.logical, graphics_command_pool.handle, buffer_count.count) catch |err| {
            std.debug.print("Failed to create command buffers: {}\n", .{err});
            return;
        };

        const image_available_semaphores = vksync.createSemaphores(allocator.alloc, device.logical, MAX_FRAME_DRAWS) catch |err| {
            std.debug.print("Failed to create image available semaphores: {}\n", .{err});
            return;
        };

        const render_finished_semaphores = vksync.createSemaphores(allocator.alloc, device.logical, MAX_FRAME_DRAWS) catch |err| {
            std.debug.print("Failed to create render finished semaphores: {}\n", .{err});
            return;
        };

        const draw_fences = vksync.createFences(allocator.alloc, device.logical, MAX_FRAME_DRAWS) catch |err| {
            std.debug.print("Failed to create draw fences: {}\n", .{err});
            return;
        };

        _ = ecs.set(it.world, it.entities()[i], CommandPool, .{ .handle = graphics_command_pool.handle });
        _ = ecs.set(it.world, it.entities()[i], CommandBuffers, .{ .handles = command_buffers.handles });
        _ = ecs.set(it.world, it.entities()[i], ImageAvailableSemaphores, .{ .handles = image_available_semaphores.handles });
        _ = ecs.set(it.world, it.entities()[i], RenderFinishedSemaphores, .{ .handles = render_finished_semaphores.handles });
        _ = ecs.set(it.world, it.entities()[i], DrawFences, .{ .handles = draw_fences.handles });
    }
}

fn destroyCommandBuffers(it: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Shut down: {s}\n", .{ecs.get_name(it.world, it.system).?});
    const allocator = ecs.singleton_get(it.world, app.Allocator).?;
    const devices = ecs.field(it, Device, 1).?;
    const command_pools = ecs.field(it, CommandPool, 2).?;
    const command_buffers = ecs.field(it, CommandBuffers, 3).?;
    const image_available_semaphores = ecs.field(it, ImageAvailableSemaphores, 4).?;
    const render_finished_semaphores = ecs.field(it, RenderFinishedSemaphores, 5).?;
    const draw_fences = ecs.field(it, DrawFences, 6).?;

    for (0..it.count()) |i| {
        const device = devices[i];
        const command_pool = command_pools[i];
        const command_buffer = command_buffers[i];
        const image_available_semaphore = image_available_semaphores[i];
        const render_finished_semaphore = render_finished_semaphores[i];
        const draw_fence = draw_fences[i];

        for (0..MAX_FRAME_DRAWS) |j| {
            c.vkDestroyFence(device.logical, draw_fence.handles[j], null);
            c.vkDestroySemaphore(device.logical, image_available_semaphore.handles[j], null);
            c.vkDestroySemaphore(device.logical, render_finished_semaphore.handles[j], null);
        }

        c.vkDestroyCommandPool(device.logical, command_pool.handle, null);
        // TODO: Do I need to destroy these buffers?
        allocator.alloc.free(command_buffer.handles);
        allocator.alloc.free(image_available_semaphore.handles);
        allocator.alloc.free(render_finished_semaphore.handles);
        allocator.alloc.free(draw_fence.handles);
    }
}

// Create a new system that will add a mesh and vertex buffer to the vulkan system, this is looking for a scene.Mesh component and a scene.UpdateBuffer tag
fn createMeshBuffers(it: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Update Mesh System: {s}\n", .{ecs.get_name(it.world, it.system).?});
    const meshes = ecs.field(it, scene.Mesh, 1).?;

    var device_query_desc = ecs.filter_desc_t{};
    device_query_desc.terms[0] = .{ .id = ecs.id(Device), .inout = ecs.inout_kind_t.In };
    device_query_desc.terms[1] = .{ .id = ecs.id(Queue), .inout = ecs.inout_kind_t.In };
    device_query_desc.terms[2] = .{ .id = ecs.id(CommandPool), .inout = ecs.inout_kind_t.In };
    const filter = ecs.filter_init(it.world, &device_query_desc) catch |err| {
        std.debug.print("Failed to create device query: {}\n", .{err});
        return;
    };
    defer ecs.filter_fini(filter);

    var query_iter = ecs.filter_iter(it.world, filter);
    while (ecs.filter_next(&query_iter)) {
        for(query_iter.entities()) |e| {
            const device = ecs.get(query_iter.world, e, Device).?;
            const queue = ecs.get(query_iter.world, e, Queue).?;
            const command_pool = ecs.get(query_iter.world, e, CommandPool).?;

            for (0..it.count()) |i| {
                const mesh = meshes[i];
                var buffer = vkb.createVertexBuffer(mesh.vertices, .{
                    .device = device.logical,
                    .physical_device = device.physical,
                    .transfer_queue = queue.graphics,
                    .transfer_command_pool = command_pool.handle
                }) catch |err| {
                    std.debug.print("Failed to create vertex buffer: {}\n", .{err});
                    return;
                };

                const buffer_entity = ecs.new_id(it.world);
                _ = ecs.set(it.world, buffer_entity, VertexBuffer, .{ .buffer = buffer.vertex_buffer, .memory = buffer.vertex_memory, .count = @as(u32, @intCast(mesh.vertices.len)) });

                vkb.createIndexBuffer(mesh.indices, .{
                    .device = device.logical,
                    .physical_device = device.physical,
                    .transfer_queue = queue.graphics,
                    .transfer_command_pool = command_pool.handle
                }, &buffer) catch |err| {
                    std.debug.print("Failed to create index buffer: {}\n", .{err});
                    return;
                };
                _ = ecs.set(it.world, buffer_entity, IndexBuffer, .{ .buffer = buffer.index_buffer, .memory = buffer.index_memory, .count = @as(u32, @intCast(mesh.indices.len)) });
                _ = ecs.set(it.world, buffer_entity, DeviceEntity, .{ .entity = e });

                ecs.remove(it.world, it.entities()[i], scene.UpdateBuffer);
            }

        }
    }   
}

fn destroyMeshBuffers(it: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Shut down: {s}\n", .{ecs.get_name(it.world, it.system).?});
    const vertex_buffers = ecs.field(it, VertexBuffer, 1).?;
    const index_buffers = ecs.field(it, IndexBuffer, 2).?;
    const device_entities = ecs.field(it, DeviceEntity, 3).?;

    for (0..it.count()) |i| {
        const vertex_buffer = vertex_buffers[i];
        const index_buffer = index_buffers[i];
        const device_entity = device_entities[i];

        const device = ecs.get(it.world, device_entity.entity, Device).?;

        c.vkDestroyBuffer(device.logical, vertex_buffer.buffer, null);
        c.vkFreeMemory(device.logical, vertex_buffer.memory, null);
        c.vkDestroyBuffer(device.logical, index_buffer.buffer, null);
        c.vkFreeMemory(device.logical, index_buffer.memory, null);
    }
}

fn simpleTextureSetUp(it: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Start up: {s}\n", .{ecs.get_name(it.world, it.system).?});
    const allocator = ecs.singleton_get(it.world, app.Allocator).?;
    const devices = ecs.field(it, Device, 1).?;
    const queues = ecs.field(it, Queue, 2).?;
    const command_pools = ecs.field(it, CommandPool, 3).?;
    const descriptor_pools = ecs.field(it, DescriptorPool, 4).?;
    const descriptor_set_layouts = ecs.field(it, DescriptorSetLayout, 5).?;

    for (devices, queues, command_pools, descriptor_pools, descriptor_set_layouts, it.entities()) |device, queue, command_pool, descriptor_pool, descriptor_set_layout, e| {
        const sample_image = vkt.loadImageFromFile("assets/sample_floor.png", .{
            .physical_device = device.physical,
            .device = device.logical,
            .transfer_queue = queue.graphics,
            .command_pool = command_pool.handle,
        }) catch |err| {
            std.debug.print("Failed to load image: {}\n", .{err});
            return;
        };

        const texture_sampler = vkt.createTextureSampler(device.logical) catch |err| {
            std.debug.print("Failed to create texture sampler: {}\n", .{err});
            return;
        };

        const sampler_image_view = vkt.createTextureImageView(allocator.alloc, device.logical, sample_image.handle, descriptor_pool.sampler_handle, descriptor_set_layout.sampler_handle, texture_sampler) catch |err| {
            std.debug.print("Failed to create texture image view: {}\n", .{err});
            return;
        };
    
        _ = ecs.set(it.world, e, Texture, .{ 
            .image = sample_image.handle, 
            .memory = sample_image.memory, 
            .image_view = sampler_image_view.image_view, 
            .descriptor_sets = sampler_image_view.descriptor_sets,
            .sampler = texture_sampler 
        });
    }
}

fn destroySimpleTexture(it : *ecs.iter_t) callconv(.C) void {
    std.debug.print("Shut down: {s}\n", .{ecs.get_name(it.world, it.system).?});
    const allocator = ecs.singleton_get(it.world, app.Allocator).?;
    const textures = ecs.field(it, Texture, 1).?;
    const devices = ecs.field(it, Device, 2).?;

    for (textures, devices) |texture, device| {
        allocator.alloc.free(texture.descriptor_sets);
        c.vkDestroySampler(device.logical, texture.sampler, null);
        c.vkDestroyImageView(device.logical, texture.image_view, null);
        c.vkDestroyImage(device.logical, texture.image, null);
        c.vkFreeMemory(device.logical, texture.memory, null);
    }
}

pub fn init(world: *ecs.world_t) void {
    ecs.COMPONENT(world, Device);
    ecs.COMPONENT(world, DeviceEntity);
    ecs.COMPONENT(world, Surface);
    ecs.COMPONENT(world, Queue);
    ecs.COMPONENT(world, QueueIndex);
    ecs.COMPONENT(world, Swapchain);
    ecs.COMPONENT(world, ImageAssets);
    ecs.COMPONENT(world, BufferCount);
    ecs.COMPONENT(world, BufferOffset);
    ecs.COMPONENT(world, DepthImage);
    ecs.COMPONENT(world, RenderPass);
    ecs.COMPONENT(world, DescriptorSetLayout);
    ecs.COMPONENT(world, UniformBuffers);
    ecs.COMPONENT(world, DescriptorPool);
    ecs.COMPONENT(world, DescriptorSets);
    ecs.COMPONENT(world, Pipeline);
    ecs.COMPONENT(world, Framebuffers);
    ecs.COMPONENT(world, CommandPool);
    ecs.COMPONENT(world, CommandBuffers);
    ecs.COMPONENT(world, ImageAvailableSemaphores);
    ecs.COMPONENT(world, RenderFinishedSemaphores);
    ecs.COMPONENT(world, DrawFences);
    ecs.COMPONENT(world, VertexBuffer);
    ecs.COMPONENT(world, IndexBuffer);
    ecs.COMPONENT(world, Texture);

    var device_desc = ecs.system_desc_t{};
    device_desc.callback = createDevice;
    device_desc.query.filter.terms[0] = .{ .id = ecs.id(sdl.Window), .inout = ecs.inout_kind_t.In };
    ecs.SYSTEM(world, "VkStartDeviceSystem", ecs.OnStart, &device_desc);

    var swapchain_desc = ecs.system_desc_t{};
    swapchain_desc.callback = createSwapchain;
    swapchain_desc.query.filter.terms[0] = .{ .id = ecs.id(Device), .inout = ecs.inout_kind_t.In };
    swapchain_desc.query.filter.terms[1] = .{ .id = ecs.id(Surface), .inout = ecs.inout_kind_t.In };
    swapchain_desc.query.filter.terms[2] = .{ .id = ecs.id(QueueIndex), .inout = ecs.inout_kind_t.In };
    swapchain_desc.query.filter.terms[3] = .{ .id = ecs.id(app.CanvasSize), .inout = ecs.inout_kind_t.In };
    ecs.SYSTEM(world, "VkStartSwapchainSystem", ecs.OnStart, &swapchain_desc);

    var render_pass_desc = ecs.system_desc_t{};
    render_pass_desc.callback = createRenderPass;
    render_pass_desc.query.filter.terms[0] = .{ .id = ecs.id(Device), .inout = ecs.inout_kind_t.In };
    render_pass_desc.query.filter.terms[1] = .{ .id = ecs.id(Swapchain), .inout = ecs.inout_kind_t.In };
    render_pass_desc.query.filter.terms[2] = .{ .id = ecs.id(BufferCount), .inout = ecs.inout_kind_t.In };
    render_pass_desc.query.filter.terms[3] = .{ .id = ecs.id(BufferOffset), .inout = ecs.inout_kind_t.In };
    render_pass_desc.query.filter.terms[4] = .{ .id = ecs.id(DepthImage), .inout = ecs.inout_kind_t.In };
    render_pass_desc.query.filter.terms[5] = .{ .id = ecs.id(ImageAssets), .inout = ecs.inout_kind_t.In };
    ecs.SYSTEM(world, "VkStartRenderPassSystem", ecs.OnStart, &render_pass_desc);

    var command_buffer_desc = ecs.system_desc_t{};
    command_buffer_desc.callback = createCommandBuffers;
    command_buffer_desc.query.filter.terms[0] = .{ .id = ecs.id(Device), .inout = ecs.inout_kind_t.In };
    command_buffer_desc.query.filter.terms[1] = .{ .id = ecs.id(QueueIndex), .inout = ecs.inout_kind_t.In };
    command_buffer_desc.query.filter.terms[2] = .{ .id = ecs.id(BufferCount), .inout = ecs.inout_kind_t.In };
    ecs.SYSTEM(world, "VkStartCommandBufferSystem", ecs.OnStart, &command_buffer_desc);

    var texture_desc = ecs.system_desc_t{};
    texture_desc.callback = simpleTextureSetUp;
    texture_desc.query.filter.terms[0] = .{ .id = ecs.id(Device), .inout = ecs.inout_kind_t.In };
    texture_desc.query.filter.terms[1] = .{ .id = ecs.id(Queue), .inout = ecs.inout_kind_t.In };
    texture_desc.query.filter.terms[2] = .{ .id = ecs.id(CommandPool), .inout = ecs.inout_kind_t.In };
    texture_desc.query.filter.terms[3] = .{ .id = ecs.id(DescriptorPool), .inout = ecs.inout_kind_t.In };
    texture_desc.query.filter.terms[4] = .{ .id = ecs.id(DescriptorSetLayout), .inout = ecs.inout_kind_t.In };
    ecs.SYSTEM(world, "VkStartTextureSystem", ecs.OnStart, &texture_desc);

    var create_mesh_desc = ecs.system_desc_t{};
    create_mesh_desc.callback = createMeshBuffers;
    create_mesh_desc.query.filter.terms[0] = .{ .id = ecs.id(scene.Mesh), .inout = ecs.inout_kind_t.In };
    create_mesh_desc.query.filter.terms[1] = .{ .id = ecs.id(scene.UpdateBuffer), .inout = ecs.inout_kind_t.In };
    ecs.SYSTEM(world, "VkCreateMeshBufferSystem", ecs.OnUpdate, &create_mesh_desc);

    var destroy_mesh_desc = ecs.system_desc_t{};
    destroy_mesh_desc.callback = destroyMeshBuffers;
    destroy_mesh_desc.query.filter.terms[0] = .{ .id = ecs.id(VertexBuffer), .inout = ecs.inout_kind_t.In };
    destroy_mesh_desc.query.filter.terms[1] = .{ .id = ecs.id(IndexBuffer), .inout = ecs.inout_kind_t.In };
    destroy_mesh_desc.query.filter.terms[2] = .{ .id = ecs.id(DeviceEntity), .inout = ecs.inout_kind_t.In };
    ecs.SYSTEM(world, "VkDestroyMeshBufferSystem", ecs.id(app.OnStop), &destroy_mesh_desc);
    
    var destroy_texture_desc = ecs.system_desc_t{};
    destroy_texture_desc.callback = destroySimpleTexture;
    destroy_texture_desc.query.filter.terms[0] = .{ .id = ecs.id(Texture), .inout = ecs.inout_kind_t.In };
    destroy_texture_desc.query.filter.terms[1] = .{ .id = ecs.id(Device), .inout = ecs.inout_kind_t.In };
    ecs.SYSTEM(world, "VkDestroyTextureSystem", ecs.id(app.OnStop), &destroy_texture_desc);

    var destroy_command_buffer_desc = ecs.system_desc_t{};
    destroy_command_buffer_desc.callback = destroyCommandBuffers;
    destroy_command_buffer_desc.query.filter.terms[0] = .{ .id = ecs.id(Device), .inout = ecs.inout_kind_t.In };
    destroy_command_buffer_desc.query.filter.terms[1] = .{ .id = ecs.id(CommandPool), .inout = ecs.inout_kind_t.In };
    destroy_command_buffer_desc.query.filter.terms[2] = .{ .id = ecs.id(CommandBuffers), .inout = ecs.inout_kind_t.In };
    destroy_command_buffer_desc.query.filter.terms[3] = .{ .id = ecs.id(ImageAvailableSemaphores), .inout = ecs.inout_kind_t.In };
    destroy_command_buffer_desc.query.filter.terms[4] = .{ .id = ecs.id(RenderFinishedSemaphores), .inout = ecs.inout_kind_t.In };
    destroy_command_buffer_desc.query.filter.terms[5] = .{ .id = ecs.id(DrawFences), .inout = ecs.inout_kind_t.In };
    ecs.SYSTEM(world, "VkDestroyCommandBufferSystem", ecs.id(app.OnStop), &destroy_command_buffer_desc);

    var destroy_render_pass_desc = ecs.system_desc_t{};
    destroy_render_pass_desc.callback = destroyRenderPass;
    destroy_render_pass_desc.query.filter.terms[0] = .{ .id = ecs.id(Device), .inout = ecs.inout_kind_t.In };
    destroy_render_pass_desc.query.filter.terms[1] = .{ .id = ecs.id(RenderPass), .inout = ecs.inout_kind_t.In };
    destroy_render_pass_desc.query.filter.terms[2] = .{ .id = ecs.id(DescriptorSetLayout), .inout = ecs.inout_kind_t.In };
    destroy_render_pass_desc.query.filter.terms[3] = .{ .id = ecs.id(UniformBuffers), .inout = ecs.inout_kind_t.In };
    destroy_render_pass_desc.query.filter.terms[4] = .{ .id = ecs.id(DescriptorPool), .inout = ecs.inout_kind_t.In };
    destroy_render_pass_desc.query.filter.terms[5] = .{ .id = ecs.id(DescriptorSets), .inout = ecs.inout_kind_t.In };
    destroy_render_pass_desc.query.filter.terms[6] = .{ .id = ecs.id(Pipeline), .inout = ecs.inout_kind_t.In };
    destroy_render_pass_desc.query.filter.terms[7] = .{ .id = ecs.id(Framebuffers), .inout = ecs.inout_kind_t.In };
    ecs.SYSTEM(world, "VkDestroyRenderPassSystem", ecs.id(app.OnStop), &destroy_render_pass_desc);

    var destroy_swapchain_decs = ecs.system_desc_t{};
    destroy_swapchain_decs.callback = destroySwapchain;
    destroy_swapchain_decs.query.filter.terms[0] = .{ .id = ecs.id(Device), .inout = ecs.inout_kind_t.In };
    destroy_swapchain_decs.query.filter.terms[1] = .{ .id = ecs.id(Swapchain), .inout = ecs.inout_kind_t.In };
    destroy_swapchain_decs.query.filter.terms[2] = .{ .id = ecs.id(ImageAssets), .inout = ecs.inout_kind_t.In };
    destroy_swapchain_decs.query.filter.terms[3] = .{ .id = ecs.id(DepthImage), .inout = ecs.inout_kind_t.In };
    ecs.SYSTEM(world, "VkDestroySwapchainSystem", ecs.id(app.OnStop), &destroy_swapchain_decs);

    var destroy_decs = ecs.system_desc_t{};
    destroy_decs.callback = destroyDevice;
    destroy_decs.query.filter.terms[0] = .{ .id = ecs.id(Device), .inout = ecs.inout_kind_t.In };
    destroy_decs.query.filter.terms[1] = .{ .id = ecs.id(Surface), .inout = ecs.inout_kind_t.In };
    ecs.SYSTEM(world, "VkDestroyDeviceSystem", ecs.id(app.OnStop), &destroy_decs);
}