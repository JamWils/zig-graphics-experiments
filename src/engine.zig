const std = @import("std");
const ecs = @import("flecs");
const app = @import("app.zig");

const c = @import("clibs.zig");
const sdl = @import("sdl.zig");
const vkd = @import("vulkan/device.zig");
const vki = @import("vulkan/instance.zig");

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
}

pub fn init(world: *ecs.world_t) void {
    ecs.COMPONENT(world, Device);
    ecs.COMPONENT(world, Surface);
    ecs.COMPONENT(world, QueueIndex);

    var device_desc = ecs.system_desc_t{};
    device_desc.callback = createDevice;
    device_desc.query.filter.terms[0] = .{ .id = ecs.id(sdl.Window), .inout = ecs.inout_kind_t.In };
    ecs.SYSTEM(world, "VulkanDeviceSystem", ecs.OnStart, &device_desc);

    var destroy_desc = ecs.observer_desc_t{
        .callback = destroyDevice,
    };
    destroy_desc.filter.terms[0] = .{ .id = ecs.id(Device), .inout = ecs.inout_kind_t.In };
    destroy_desc.filter.terms[1] = .{ .id = ecs.id(Surface), .inout = ecs.inout_kind_t.In };
    destroy_desc.events[0] = ecs.UnSet;
    ecs.OBSERVER(world, "DestroyDeviceSystem", &destroy_desc);
}