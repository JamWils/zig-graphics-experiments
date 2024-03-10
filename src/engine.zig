const std = @import("std");
const ecs = @import("flecs");
const app = @import("app.zig");

const c = @import("clibs.zig");
const sdl = @import("sdl.zig");
const vkd = @import("vulkan/device.zig");
const vki = @import("vulkan/instance.zig");
const vks = @import("vulkan/swapchain.zig");

const Device = struct {
    instance: c.VkInstance,
    physical: c.VkPhysicalDevice,
    logical: c.VkDevice,
    debug_messenger: c.VkDebugUtilsMessengerEXT
};

const Surface = struct {
    handle: c.VkSurfaceKHR,
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

const ImageAssets = struct {
    images: []c.VkImage,
    image_views: []c.VkImageView,
};


const vk_alloc_callbacks: ?*c.VkAllocationCallbacks = null;

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

        const new_entity = ecs.new_entity(it.world, "VulkanDevice");
        _ = ecs.set(it.world, new_entity, Device, .{ 
            .instance = instance.handle, 
            .physical = physical_device.handle, 
            .logical = device.handle, 
            .debug_messenger = instance.debug_messenger 
        });

        _ = ecs.set(it.world, new_entity, Surface, .{ .handle = surface });
        _ = ecs.set(it.world, new_entity, app.CanvasSize, . { .width = window.width, .height = window.height });
        _ = ecs.set(it.world, new_entity, QueueIndex, .{ 
            .graphics = physical_device.queue_indices.graphics_queue_location,
            .presentation = physical_device.queue_indices.presentation_queue_location,
        });
    }
}

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

        _ = ecs.set(it.world, it.entities()[i], Swapchain, .{ 
            .handle = swapchain.handle, 
            .extent = swapchain.image_extent,
            .format = swapchain.surface_format.format,
        });
        _ = ecs.set(it.world, it.entities()[i], ImageAssets, .{ 
            .images = swapchain.images, 
            .image_views = swapchain.image_views,
        });
        ecs.enable_id(it.world, it.entities()[i], ecs.id(app.CanvasSize), false);
    }
}

fn destroySwapchain(it: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Shut down: {s}\n", .{ecs.get_name(it.world, it.system).?});
    const allocator = ecs.singleton_get(it.world, app.Allocator).?;

    const devices = ecs.field(it, Device, 1).?;
    const swapchains = ecs.field(it, Swapchain, 2).?;
    const image_assets = ecs.field(it, ImageAssets, 3).?;

    for (0..it.count()) |i| {
        const device = devices[i];
        const swapchain = swapchains[i];
        const assets = image_assets[i];

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


pub fn init(world: *ecs.world_t) void {
    ecs.COMPONENT(world, Device);
    ecs.COMPONENT(world, Surface);
    ecs.COMPONENT(world, QueueIndex);
    ecs.COMPONENT(world, Swapchain);
    ecs.COMPONENT(world, ImageAssets);

    var device_desc = ecs.system_desc_t{};
    device_desc.callback = createDevice;
    device_desc.query.filter.terms[0] = .{ .id = ecs.id(sdl.Window), .inout = ecs.inout_kind_t.In };
    ecs.SYSTEM(world, "VulkanDeviceSystem", ecs.OnStart, &device_desc);

    var swapchain_desc = ecs.system_desc_t{};
    swapchain_desc.callback = createSwapchain;
    swapchain_desc.query.filter.terms[0] = .{ .id = ecs.id(Device), .inout = ecs.inout_kind_t.In };
    swapchain_desc.query.filter.terms[1] = .{ .id = ecs.id(Surface), .inout = ecs.inout_kind_t.In };
    swapchain_desc.query.filter.terms[2] = .{ .id = ecs.id(QueueIndex), .inout = ecs.inout_kind_t.In };
    swapchain_desc.query.filter.terms[3] = .{ .id = ecs.id(app.CanvasSize), .inout = ecs.inout_kind_t.In };
    ecs.SYSTEM(world, "VulkanSwapchainSystem", ecs.PreFrame, &swapchain_desc);

    var destroy_swapchain_decs = ecs.system_desc_t{};
    destroy_swapchain_decs.callback = destroySwapchain;
    destroy_swapchain_decs.query.filter.terms[0] = .{ .id = ecs.id(Device), .inout = ecs.inout_kind_t.In };
    destroy_swapchain_decs.query.filter.terms[1] = .{ .id = ecs.id(Swapchain), .inout = ecs.inout_kind_t.In };
    destroy_swapchain_decs.query.filter.terms[2] = .{ .id = ecs.id(ImageAssets), .inout = ecs.inout_kind_t.In };
    ecs.SYSTEM(world, "DestroySwapchainSystem", ecs.id(app.OnStop), &destroy_swapchain_decs);

    var destroy_decs = ecs.system_desc_t{};
    destroy_decs.callback = destroyDevice;
    destroy_decs.query.filter.terms[0] = .{ .id = ecs.id(Device), .inout = ecs.inout_kind_t.In };
    destroy_decs.query.filter.terms[1] = .{ .id = ecs.id(Surface), .inout = ecs.inout_kind_t.In };
    ecs.SYSTEM(world, "DestroyDeviceSystem", ecs.id(app.OnStop), &destroy_decs);
}