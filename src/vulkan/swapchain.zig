const std = @import("std");
const c = @import("../clibs.zig");
const vke = @import("./error.zig");

pub const SwapchainDetails = struct {
    /// Surface properties, e.g. image size and extent
    surface_capabilities: c.VkSurfaceCapabilitiesKHR = undefined,

    /// Surface image formats, e.g. RGBA and size of each color
    surface_formats: []c.VkSurfaceFormatKHR = &.{},

    /// How images should be presented to the screen
    presentation_modes: []c.VkPresentModeKHR = &.{},

    pub fn createAlloc(a: std.mem.Allocator, device: c.VkPhysicalDevice, surface: c.VkSurfaceKHR) !SwapchainDetails {
        var surface_capabilities: c.VkSurfaceCapabilitiesKHR = undefined;
        try vke.checkResult(c.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(device, surface, &surface_capabilities));

        var format_count: u32 = undefined;
        try vke.checkResult(c.vkGetPhysicalDeviceSurfaceFormatsKHR(device, surface, &format_count, null));
        const surface_formats = try a.alloc(c.VkSurfaceFormatKHR, format_count);
        try vke.checkResult(c.vkGetPhysicalDeviceSurfaceFormatsKHR(device, surface, &format_count, surface_formats.ptr));

        var presentation_count: u32 = undefined;
        try vke.checkResult(c.vkGetPhysicalDeviceSurfacePresentModesKHR(device, surface, &presentation_count, null));
        const presentation_modes = try a.alloc(c.VkPresentModeKHR, presentation_count);
        try vke.checkResult(c.vkGetPhysicalDeviceSurfacePresentModesKHR(device, surface, &presentation_count, presentation_modes.ptr));

        return SwapchainDetails{
            .surface_capabilities = surface_capabilities,
            .surface_formats = surface_formats,
            .presentation_modes = presentation_modes,
        };
    }

    pub fn deinit(self: *const SwapchainDetails, alloc: std.mem.Allocator) void {
        alloc.free(self.surface_formats);
        alloc.free(self.presentation_modes);
    }
};


