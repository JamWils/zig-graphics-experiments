const std = @import("std");
const c = @import("clibs.zig");
const vki = @import("./vulkan/instance.zig");
const vkc = @import("./vulkan/command.zig");
const vkd = @import("./vulkan/device.zig");
const vke = @import("./vulkan/error.zig");
const vks = @import("./vulkan/swapchain.zig");
const vksync = @import("./vulkan/synchronization.zig");
const vkp = @import("./vulkan/pipeline.zig");
const vkr = @import("./vulkan/render_pass.zig");
const vkb = @import("./vulkan/buffer.zig");
const vkds = @import("./vulkan/descriptor_set.zig");
const scene = @import("scene");
const zmath = @import("zmath");

const log = std.log.scoped(.vulkan_engine);
const max_frame_draws = 3;
const max_objects = 2;
const vk_alloc_callbacks: ?*c.VkAllocationCallbacks = null;

const VulkanEngine = struct {
    allocator: std.mem.Allocator,
    window: *c.SDL_Window,
    instance: c.VkInstance,
    debug_messenger: c.VkDebugUtilsMessengerEXT,
    physical_device: vkd.PhysicalDevice,
    device: c.VkDevice,
    surface: c.VkSurfaceKHR,
    graphics_queue: c.VkQueue,
    presentation_queue: c.VkQueue,
    swapchain: c.VkSwapchainKHR,
    swapchain_image_format: c.VkFormat,
    swapchain_extent: c.VkExtent2D,

    swapchain_images: []c.VkImage,
    swapchain_image_views: []c.VkImageView,
    swapchain_framebuffers: []c.VkFramebuffer,
    command_buffers: []c.VkCommandBuffer,

    descriptor_set_layout: c.VkDescriptorSetLayout,
    descriptor_pool: c.VkDescriptorPool,
    descriptor_sets: []c.VkDescriptorSet,
    uniform_buffers: []vkds.BufferSet,
    model_uniform_alignment: usize,
    model_transfer_space: []scene.UBO,

    graphics_command_pool: c.VkCommandPool,

    render_pass: c.VkRenderPass,
    pipeline_layout: c.VkPipelineLayout,
    graphics_pipeline: c.VkPipeline,

    image_available_semaphores: []c.VkSemaphore,
    render_finished_semaphores: []c.VkSemaphore,
    draw_fences: []c.VkFence,

    current_frame: usize = 0,

    mesh_buffers: []vkb.MeshBuffer,
    meshes: []scene.Mesh,

    camera: scene.Camera,

    pub fn cleanup(self: *VulkanEngine) void {
        _ = c.vkDeviceWaitIdle(self.device);

        self.allocator.free(self.meshes);
        self.allocator.free(self.model_transfer_space);

        for (self.mesh_buffers) |mesh_buffer| {
            mesh_buffer.deleteAndFree(self.device);
        }
        self.allocator.free(self.mesh_buffers);

        for (0..max_frame_draws) |i| {
            c.vkDestroyFence(self.device, self.draw_fences[i], null);
            c.vkDestroySemaphore(self.device, self.render_finished_semaphores[i], null);
            c.vkDestroySemaphore(self.device, self.image_available_semaphores[i], null);
        }

        self.allocator.free(self.draw_fences);
        self.allocator.free(self.render_finished_semaphores);
        self.allocator.free(self.image_available_semaphores);

        c.vkDestroyCommandPool(self.device, self.graphics_command_pool, null);
        self.allocator.free(self.command_buffers);

        for (self.swapchain_framebuffers) |framebuffer| {
            c.vkDestroyFramebuffer(self.device, framebuffer, null);
        }

        self.allocator.free(self.swapchain_framebuffers);

        c.vkDestroyPipeline(self.device, self.graphics_pipeline, null);

        for (self.uniform_buffers) |uniform_buffer| {
            uniform_buffer.deleteAndFree(self.device);
        }
        self.allocator.free(self.uniform_buffers);

        c.vkDestroyDescriptorPool(self.device, self.descriptor_pool, null);
        self.allocator.free(self.descriptor_sets);

        c.vkDestroyPipelineLayout(self.device, self.pipeline_layout, null);
        c.vkDestroyDescriptorSetLayout(self.device, self.descriptor_set_layout, null);
        c.vkDestroyRenderPass(self.device, self.render_pass, null);

        for (self.swapchain_image_views) |image_view| {
            c.vkDestroyImageView(self.device, image_view, null);
        }

        self.allocator.free(self.swapchain_image_views);
        self.allocator.free(self.swapchain_images);

        c.vkDestroySwapchainKHR(self.device, self.swapchain, null);
        c.vkDestroySurfaceKHR(self.instance, self.surface, null);
        c.vkDestroyDevice(self.device, null);
        if (self.debug_messenger != null) {
            const destroyFn = vki.getDestroyDebugUtilsMessengerFn(self.instance).?;
            destroyFn(self.instance, self.debug_messenger, vk_alloc_callbacks);
        }
        c.vkDestroyInstance(self.instance, null);
        c.SDL_DestroyWindow(self.window);
    }

    pub fn run(self: *VulkanEngine) !void {
        var quit = false;

        var event: c.SDL_Event = undefined;

        var last_time: u64 = c.SDL_GetTicks64();
        var angle: f32 = 0.0;
        while (!quit) {
            while (c.SDL_PollEvent(&event) != 0) {
                if (event.type == c.SDL_QUIT) {
                    quit = true;
                }
            }

            const current_time = c.SDL_GetTicks64();
            const delta_time = current_time - last_time;
            last_time = current_time;

            angle += 0.01 * @as(f32, @floatFromInt(delta_time));
            if (angle > 360) {
                angle -= 360;
            }

            var m1 = zmath.identity();
            var m2 = zmath.identity();

            m1 = zmath.mul(zmath.translationV(.{-2, 0, -5, 1}), m1);
            m1 = zmath.mul(zmath.rotationZ(std.math.degreesToRadians(f32, angle)), m1);

            m2 = zmath.mul(zmath.translationV(.{2, 0, -5, 1}), m2);
            m2 = zmath.mul(zmath.rotationZ(std.math.degreesToRadians(f32, -angle*20)), m2);

            self.meshes[0].model.model = m1;
            self.meshes[1].model.model = m2;

            try self.draw();
        }
    }

    pub fn updateUniformBuffers(self: *VulkanEngine, image_index: u32) !void {
        const camera_buffer = self.uniform_buffers[image_index].camera;
        var data: ?*align(@alignOf(u32)) anyopaque = undefined;
        try vke.checkResult(c.vkMapMemory(self.device, camera_buffer.memory, 0, @sizeOf(scene.Camera), 0, &data));

        @memcpy(@as([*]u8, @ptrCast(data)), std.mem.asBytes(&self.camera));
        c.vkUnmapMemory(self.device, camera_buffer.memory);

        const model_buffer = self.uniform_buffers[image_index].model;
        
        var object_data: ?*align(@alignOf(scene.UBO)) anyopaque = undefined;
        var i: usize = 0;
        while (i < self.meshes.len): (i += 1) {
            const this_model = &self.model_transfer_space[i];
            this_model.* = self.meshes[i].model;
        }

        const copy_size = self.model_uniform_alignment * self.meshes.len;
        try vke.checkResult(c.vkMapMemory(self.device, model_buffer.memory, 0, copy_size, 0, &object_data));
        @memcpy(@as([*]scene.UBO, @ptrCast(object_data)), self.model_transfer_space[0..copy_size]);
        c.vkUnmapMemory(self.device, model_buffer.memory);
    }

    pub fn draw(self: *VulkanEngine) !void {
        try vke.checkResult(c.vkWaitForFences(self.device, 1, &self.draw_fences[self.current_frame], c.VK_TRUE, std.math.maxInt(u64)));
        try vke.checkResult(c.vkResetFences(self.device, 1, &self.draw_fences[self.current_frame]));

        var image_index: u32 = undefined;
        try vke.checkResult(c.vkAcquireNextImageKHR(self.device, self.swapchain, std.math.maxInt(u64), self.image_available_semaphores[self.current_frame], null, &image_index));
        try self.updateUniformBuffers(image_index);
        const wait_stages: [1]c.VkPipelineStageFlags = .{
            c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
        };

        const submit_info = std.mem.zeroInit(c.VkSubmitInfo, .{
            .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
            .waitSemaphoreCount = 1,
            .pWaitSemaphores = &self.image_available_semaphores[self.current_frame],
            .pWaitDstStageMask = &wait_stages,
            .commandBufferCount = 1,
            .pCommandBuffers = &self.command_buffers[image_index],
            .signalSemaphoreCount = 1,
            .pSignalSemaphores = &self.render_finished_semaphores[self.current_frame],
        });

        try vke.checkResult(c.vkQueueSubmit(self.graphics_queue, 1, &submit_info, self.draw_fences[self.current_frame]));

        const present_info = std.mem.zeroInit(c.VkPresentInfoKHR, .{
            .sType = c.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
            .waitSemaphoreCount = 1,
            .pWaitSemaphores = &self.render_finished_semaphores[self.current_frame],
            .swapchainCount = 1,
            .pSwapchains = &self.swapchain,
            .pImageIndices = &image_index,
        });

        try vke.checkResult(c.vkQueuePresentKHR(self.presentation_queue, &present_info));

        self.current_frame = (self.current_frame + 1) % max_frame_draws;
    }

    fn recordCommands(self: *VulkanEngine) !void {
        const buffer_begin_info = std.mem.zeroInit(c.VkCommandBufferBeginInfo, .{
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
            // .flags = c.VK_COMMAND_BUFFER_USAGE_SIMULTANEOUS_USE_BIT,
        });

        const color_clear_value = c.VkClearValue{ .color = .{ .float32 = [_]f32{ 0.3, 0.3, 0.4, 1.0 } } };

        var clear_values = [1]c.VkClearValue{
            color_clear_value,
        };

        var render_pass_begin_info = std.mem.zeroInit(c.VkRenderPassBeginInfo, .{
            .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
            .renderPass = self.render_pass,
            .renderArea = .{
                .offset = .{
                    .x = 0,
                    .y = 0,
                },
                .extent = self.swapchain_extent,
            },
            .clearValueCount = @as(u32, @intCast(clear_values.len)),
            .pClearValues = &clear_values,
        });

        for (self.command_buffers, 0..) |command_buffer, i| {
            try vke.checkResult(c.vkBeginCommandBuffer(command_buffer, &buffer_begin_info));

            render_pass_begin_info.framebuffer = self.swapchain_framebuffers[i];
            c.vkCmdBeginRenderPass(command_buffer, &render_pass_begin_info, c.VK_SUBPASS_CONTENTS_INLINE);
            c.vkCmdBindPipeline(command_buffer, c.VK_PIPELINE_BIND_POINT_GRAPHICS, self.graphics_pipeline);

            for (self.mesh_buffers, 0..) |mesh_buffer, j| {
                const vertex_buffers = [_]c.VkBuffer{
                    mesh_buffer.vertex_buffer,
                };

                const offsets = [_]c.VkDeviceSize{
                    0,
                };

                c.vkCmdBindVertexBuffers(command_buffer, 0, 1, &vertex_buffers, &offsets);
                c.vkCmdBindIndexBuffer(command_buffer, mesh_buffer.index_buffer, 0, c.VK_INDEX_TYPE_UINT32);

                const dynamic_offset = @as(u32, @intCast(self.model_uniform_alignment * j));
                c.vkCmdBindDescriptorSets(command_buffer, c.VK_PIPELINE_BIND_POINT_GRAPHICS, self.pipeline_layout, 0, 1, &self.descriptor_sets[i], 1, &dynamic_offset);
                c.vkCmdDrawIndexed(command_buffer, mesh_buffer.index_count, 1, 0, 0, 0);
            }

            c.vkCmdEndRenderPass(command_buffer);
            try vke.checkResult(c.vkEndCommandBuffer(command_buffer));
        }
    }
};

pub fn init(alloc: std.mem.Allocator) !VulkanEngine {
    checkSdl(c.SDL_Init(c.SDL_INIT_VIDEO));

    const window = c.SDL_CreateWindow(
        "Vulkan App",
        c.SDL_WINDOWPOS_CENTERED,
        c.SDL_WINDOWPOS_CENTERED,
        800,
        600,
        c.SDL_WINDOW_VULKAN | c.SDL_WINDOW_RESIZABLE,
    ) orelse @panic("Failed to create SDL window");

    var window_width: c_int = 0;
    var window_height: c_int = 0;
    c.SDL_GetWindowSize(window, &window_width, &window_height);

    const instance = createInstance(alloc, window);

    const required_device_extensions = .{
        c.VK_KHR_SWAPCHAIN_EXTENSION_NAME,
    };

    var surface: c.VkSurfaceKHR = undefined;
    checkSdlBool(c.SDL_Vulkan_CreateSurface(window, instance.handle, &surface));
    const physical_device = try vkd.getPhysicalDevice(alloc, instance.handle, surface, &required_device_extensions);
    const device = try vkd.createLogicalDevice(alloc, physical_device, &required_device_extensions);

    const swapchain = try vks.createSwapchain(alloc, physical_device.handle, device.handle, surface, .{
        .graphics_queue_index = physical_device.queue_indices.graphics_queue_location,
        .presentation_queue_index = physical_device.queue_indices.presentation_queue_location,
        .window_height = @intCast(window_height),
        .window_width = @intCast(window_width),
    });

    const model_uniform_alignment = vkds.pad_with_buffer_offset(@sizeOf(scene.UBO), physical_device.min_uniform_buffer_offset_alignment);

    const render_pass = try vkr.createRenderPass(device.handle, swapchain.surface_format.format);
    const descriptor_set_layout = try vkds.createDescriptorSetLayout(device.handle);
    const buffer_count: u32 = @as(u32, @intCast(swapchain.images.len));
    const uniform_buffers = try vkds.createUniformBuffers(alloc, .{
        .physical_device = physical_device.handle,
        .device = device.handle,
        .buffer_count = buffer_count,
        .model_memory_alignment = model_uniform_alignment,
        .max_objects = max_objects,
    });
    const descriptor_pool = try vkds.createDescriptorPool(device.handle, buffer_count);
    const descriptor_sets = try vkds.createDescriptorSets(alloc, buffer_count, device.handle, descriptor_pool.handle, descriptor_set_layout.handle, uniform_buffers, model_uniform_alignment);

    const pipeline = try vkp.createGraphicsPipeline(alloc, .{
        .device = device.handle,
        .swapchain_extent = swapchain.image_extent,
        .render_pass = render_pass.handle,
        .descriptor_set_layout = descriptor_set_layout.handle,
    });
    const swapchain_framebuffers = try vks.createFramebuffer(alloc, device.handle, swapchain, render_pass.handle);
    const graphics_command_pool = try vkc.createCommandPool(device.handle, physical_device.queue_indices);
    const command_buffers = try vkc.createCommandBuffers(alloc, device.handle, graphics_command_pool.handle, swapchain_framebuffers.handles.len);

    const image_available_semaphores = try vksync.createSemaphores(alloc, device.handle, max_frame_draws);
    const render_finished_semaphores = try vksync.createSemaphores(alloc, device.handle, max_frame_draws);
    const draw_fences = try vksync.createFences(alloc, device.handle, max_frame_draws);

    const dimension: f32 = @as(f32, @floatFromInt(swapchain.image_extent.width)) / @as(f32, @floatFromInt(swapchain.image_extent.height));
    var camera = scene.Camera{
        .view = zmath.lookAtRh(.{0, 0, 2, 1}, .{0, 0, 0, 1}, .{0, 1, 0, 1}),
        .projection = zmath.perspectiveFovRh(std.math.degreesToRadians(f32, 45), dimension, 0.1, 10),
    };
    camera.projection[1][1] *= -1;

    const model_transfer_space = try vkds.allocate_model_transfer_space(alloc, physical_device.min_uniform_buffer_offset_alignment, max_objects);

    const vertices = [_]scene.Vertex{
        .{
            .position = .{-0.4, 0.4, 0.0},
            .color = .{1, 0, 0},
        },
        .{
            .position = .{-0.4, -0.4, 0.0},
            .color = .{0, 1, 0},
        },
        .{
            .position = .{0.4, -0.4, 0.0},
            .color = .{0, 0, 1},
        },
        .{
            .position = .{0.4, 0.4, 0.0},
            .color = .{1, 1, 0},
        },
    };

    const vertices_two = [_]scene.Vertex{
        .{
            .position = .{-0.25, 0.6, 0.0},
            .color = .{1, 0, 0},
        },
        .{
            .position = .{-0.25, -0.6, 0.0},
            .color = .{0, 1, 0},
        },
        .{
            .position = .{0.25, -0.6, 0.0},
            .color = .{0, 0, 1},
        },
        .{
            .position = .{0.25, 0.6, 0.0},
            .color = .{1, 1, 0},
        },
    };

    const indices = [_]u32{
        0, 1, 2,
        2, 3, 0,
    };

    const first_mesh = scene.Mesh{
        .vertices = alloc.dupe(scene.Vertex, vertices[0..]) catch @panic("Out of memory"),
        .indices = alloc.dupe(u32, indices[0..]) catch @panic("Out of memory"),
        .model = scene.UBO{
            .model = zmath.identity(),//zmath.rotationZ(std.math.degreesToRadians(f32, 45)),
        },
    };
    defer alloc.free(first_mesh.vertices);
    defer alloc.free(first_mesh.indices);

    // var transform = zmath.identity();
    // const quat = zmath.matToQuat(transform);
    // zmath.rotate(quat, .{ 0, 1, 0, 0});
    // transform = zmath.quatToMat(quat);
    const second_mesh = scene.Mesh{
        .vertices = alloc.dupe(scene.Vertex, vertices_two[0..]) catch @panic("Out of memory"),
        .indices = alloc.dupe(u32, indices[0..]) catch @panic("Out of memory"),
        .model = scene.UBO{
            .model = zmath.identity(),
        },
    };
    defer alloc.free(second_mesh.vertices);
    defer alloc.free(second_mesh.indices);

    var first_mesh_buffer = try vkb.createVertexBuffer(first_mesh.vertices, .{
        .device = device.handle,
        .physical_device = physical_device.handle,
        .transfer_queue = device.graphics_queue,
        .transfer_command_pool = graphics_command_pool.handle,
    });

    try vkb.createIndexBuffer(first_mesh.indices, .{
        .device = device.handle,
        .physical_device = physical_device.handle,
        .transfer_queue = device.graphics_queue,
        .transfer_command_pool = graphics_command_pool.handle,
    }, &first_mesh_buffer);

    var second_mesh_buffer = try vkb.createVertexBuffer(second_mesh.vertices, .{
        .device = device.handle,
        .physical_device = physical_device.handle,
        .transfer_queue = device.graphics_queue,
        .transfer_command_pool = graphics_command_pool.handle,
    });

    try vkb.createIndexBuffer(second_mesh.indices, .{
        .device = device.handle,
        .physical_device = physical_device.handle,
        .transfer_queue = device.graphics_queue,
        .transfer_command_pool = graphics_command_pool.handle,
    }, &second_mesh_buffer);

    var mesh_buffers = try alloc.alloc(vkb.MeshBuffer, 2);
    mesh_buffers[0] = first_mesh_buffer;
    mesh_buffers[1] = second_mesh_buffer;

    const meshes = try alloc.alloc(scene.Mesh, 2);
    meshes[0] = first_mesh;
    meshes[1] = second_mesh;

    c.SDL_ShowWindow(window);

    var engine = VulkanEngine{
        .allocator = alloc,
        .window = window,
        .instance = instance.handle,
        .debug_messenger = instance.debug_messenger,
        .physical_device = physical_device,
        .device = device.handle,
        .surface = surface,
        .graphics_queue = device.graphics_queue,
        .presentation_queue = device.presentation_queue,
        .swapchain = swapchain.handle,
        .swapchain_image_format = swapchain.surface_format.format,
        .swapchain_extent = swapchain.image_extent,
        .swapchain_images = swapchain.images,
        .swapchain_image_views = swapchain.image_views,
        .swapchain_framebuffers = swapchain_framebuffers.handles,
        .command_buffers = command_buffers.handles,
        .graphics_command_pool = graphics_command_pool.handle,
        .render_pass = render_pass.handle,
        .pipeline_layout = pipeline.layout,
        .descriptor_set_layout = descriptor_set_layout.handle,
        .descriptor_pool = descriptor_pool.handle,
        .descriptor_sets = descriptor_sets,
        .uniform_buffers = uniform_buffers,
        .model_uniform_alignment = model_uniform_alignment,
        .model_transfer_space = model_transfer_space,
        .graphics_pipeline = pipeline.graphics_pipeline_handle,
        .image_available_semaphores = image_available_semaphores.handles,
        .render_finished_semaphores = render_finished_semaphores.handles,
        .draw_fences = draw_fences.handles,
        .mesh_buffers = mesh_buffers,
        .meshes = meshes,
        .camera = camera,
    };

    try engine.recordCommands();

    return engine;
}

fn createInstance(alloc: std.mem.Allocator, window: *c.SDL_Window) vki.Instance {
    var arena_alloc = std.heap.ArenaAllocator.init(alloc);
    defer arena_alloc.deinit();

    const arena = arena_alloc.allocator();
    var sdl_extensions_count: u32 = undefined;
    _ = c.SDL_Vulkan_GetInstanceExtensions(window, &sdl_extensions_count, null);
    const sdl_required_extensions = arena.alloc([*c]const u8, sdl_extensions_count) catch unreachable;
    _ = c.SDL_Vulkan_GetInstanceExtensions(window, &sdl_extensions_count, sdl_required_extensions.ptr);

    const instance = vki.createInstance(alloc, .{ .application_name = "Vulkan App", .application_version = c.VK_MAKE_VERSION(0, 1, 0), .engine_name = "Snap Engine", .engine_version = c.VK_MAKE_VERSION(0, 1, 0), .api_version = c.VK_API_VERSION_1_3, .debug = true, .required_extensions = sdl_required_extensions }) catch |err| {
        log.err("Failed to create a Vulkan Instance with error: {s}", .{@errorName(err)});
        unreachable;
    };

    return instance;
}

fn checkSdl(res: c_int) void {
    if (res != 0) {
        log.err("Vulkan engine SDL error: {s}", .{c.SDL_GetError()});
        @panic("SDL error");
    }
}

fn checkSdlBool(res: c.SDL_bool) void {
    if (res != c.SDL_TRUE) {
        log.err("Vulkan engine SDL error: {s}", .{c.SDL_GetError()});
        @panic("SDL error");
    }
}
