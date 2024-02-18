const std = @import("std");
const c = @import("../clibs.zig");
const vke = @import("./error.zig");

pub const SwapchainOpts = struct {
    graphics_queue_index: u32,
    presentation_queue_index: u32,
    window_width: u32,
    window_height: u32,
};

pub const Swapchain = struct {
    handle: c.VkSwapchainKHR = null,
    surface_format: c.VkSurfaceFormatKHR = undefined,
    image_extent: c.VkExtent2D = undefined,
    images: []c.VkImage = &.{},
    image_views: []c.VkImageView = &.{},
};

pub const SwapchainImage = struct {
    image: c.VkImage,
    image_view: c.VkImageView,
};

pub const SwapchainFramebuffers = struct {
    handles: []c.VkFramebuffer = &.{},
};

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

pub fn createSwapchain(a: std.mem.Allocator, physical_device: c.VkPhysicalDevice, device: c.VkDevice, surface: c.VkSurfaceKHR, opts: SwapchainOpts) !Swapchain {
    const swapchain_details = try SwapchainDetails.createAlloc(a, physical_device, surface);
    defer swapchain_details.deinit(a);

    const surface_format = selectSurfaceFormat(swapchain_details.surface_formats);
    const presentation_mode = selectPresentationMode(swapchain_details.presentation_modes);
    const image_extent = getImageExtent(swapchain_details.surface_capabilities, opts.window_width, opts.window_height);
    
    var image_count: u32 = swapchain_details.surface_capabilities.minImageCount + 1;

    // If max count is zero then it is unlimited
    if (swapchain_details.surface_capabilities.maxImageCount > 0) {
        image_count = @min(image_count, swapchain_details.surface_capabilities.maxImageCount);
    }

    var swapchain_info = std.mem.zeroInit(c.VkSwapchainCreateInfoKHR, .{
        .sType = c.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
        .surface = surface,
        .imageFormat = surface_format.format,
        .imageColorSpace = surface_format.colorSpace,
        .presentMode = presentation_mode,
        .imageExtent = image_extent,
        .minImageCount = image_count,
        .imageArrayLayers = 1,
        .imageUsage = c.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
        .preTransform = swapchain_details.surface_capabilities.currentTransform,
        .compositeAlpha = c.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
        .clipped = c.VK_TRUE,
        .oldSwapchain = null,
    });

    if (opts.graphics_queue_index == opts.presentation_queue_index) {
        swapchain_info.imageSharingMode = c.VK_SHARING_MODE_EXCLUSIVE;
        swapchain_info.queueFamilyIndexCount = 0;
        swapchain_info.pQueueFamilyIndices = null;
    } else {
        const queue_family_indices: []const u32 = &.{
            opts.graphics_queue_index,
            opts.presentation_queue_index,
        };

        swapchain_info.imageSharingMode = c.VK_SHARING_MODE_CONCURRENT;
        swapchain_info.queueFamilyIndexCount = 2;
        swapchain_info.pQueueFamilyIndices = queue_family_indices.ptr;
    }

    var swapchain: c.VkSwapchainKHR = undefined;
    try vke.checkResult(c.vkCreateSwapchainKHR(device, &swapchain_info, null, &swapchain));

    var swapchain_image_count: u32 = undefined;
    try vke.checkResult(c.vkGetSwapchainImagesKHR(device, swapchain, &swapchain_image_count, null));
    const images = try a.alloc(c.VkImage, swapchain_image_count);
    errdefer a.free(images);
    try vke.checkResult(c.vkGetSwapchainImagesKHR(device, swapchain, &swapchain_image_count, images.ptr));

    const image_views = try a.alloc(c.VkImageView, swapchain_image_count);
    errdefer a.free(image_views);

    for (images, image_views) |image, *image_view| {
        image_view.* = try createImageView(device, image, surface_format.format, c.VK_IMAGE_ASPECT_COLOR_BIT);
    }

    return Swapchain{
        .handle = swapchain,
        .surface_format = surface_format,
        .image_extent = image_extent,
        .images = images,
        .image_views = image_views,
    };
}

pub fn createFramebuffer(a: std.mem.Allocator, device: c.VkDevice, swapchain: Swapchain, render_pass: c.VkRenderPass) !SwapchainFramebuffers {

    const framebuffers = try a.alloc(c.VkFramebuffer, swapchain.images.len);
    for (swapchain.image_views, framebuffers) |image_view, *framebuffer| {
        const attachments = [1]c.VkImageView{
            image_view,
        };

        var framebuffer_create_info = std.mem.zeroInit(c.VkFramebufferCreateInfo, .{
            .sType = c.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
            .renderPass = render_pass,
            .attachmentCount = @as(u32, @intCast(attachments.len)),
            .pAttachments = &attachments,
            .width = swapchain.image_extent.width,
            .height = swapchain.image_extent.height,
            .layers = 1,
        });

        try vke.checkResult(c.vkCreateFramebuffer(device, &framebuffer_create_info, null, framebuffer));
    }

    return .{
        .handles = framebuffers,
    };
}

fn createImageView(device: c.VkDevice, image: c.VkImage, format: c.VkFormat, aspectFlags: c.VkImageAspectFlags) !c.VkImageView {
    const image_view_info = std.mem.zeroInit(c.VkImageViewCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
        .image = image,
        .viewType = c.VK_IMAGE_VIEW_TYPE_2D,
        .format = format,
        .components = .{
            .r = c.VK_COMPONENT_SWIZZLE_IDENTITY,
            .g = c.VK_COMPONENT_SWIZZLE_IDENTITY,
            .b = c.VK_COMPONENT_SWIZZLE_IDENTITY,
            .a = c.VK_COMPONENT_SWIZZLE_IDENTITY,
        },
        .subresourceRange = .{
            .aspectMask = aspectFlags,
            .baseMipLevel = 0,
            .levelCount = 1,
            .baseArrayLayer = 0,
            .layerCount = 1,
        },
    }); 

    var image_view: c.VkImageView = undefined;
    try vke.checkResult(c.vkCreateImageView(device, &image_view_info, null, &image_view));

    return image_view;
}

fn selectSurfaceFormat(formats: []c.VkSurfaceFormatKHR) c.VkSurfaceFormatKHR {
    if (formats.len == 0 and formats[0].format == c.VK_FORMAT_UNDEFINED) {
        return c.VkSurfaceFormatKHR {
            .format = c.VK_FORMAT_R8G8B8A8_UNORM,
            .colorSpace = c.VK_COLORSPACE_SRGB_NONLINEAR_KHR, 
        };
    }

    for (formats) |format| {
        if ((format.format == c.VK_FORMAT_R8G8B8A8_UNORM or format.format == c.VK_FORMAT_B8G8R8A8_UNORM) and format.colorSpace == c.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR) {
            return format;
        }
    }

    return formats[0];
}

fn selectPresentationMode(modes: []c.VkPresentModeKHR) c.VkPresentModeKHR {
    for (modes) |mode| {
        if (mode == c.VK_PRESENT_MODE_MAILBOX_KHR) {
            return mode;
        }
    }

    return c.VK_PRESENT_MODE_FIFO_KHR;
}

fn getImageExtent(surface_capabilities: c.VkSurfaceCapabilitiesKHR, window_width: u32, window_height: u32) c.VkExtent2D {
    if (surface_capabilities.currentExtent.width != std.math.maxInt(u32)) {
        return surface_capabilities.currentExtent;
    }

    var extent = c.VkExtent2D {
        .width = window_width,
        .height = window_height,
    };

    extent.width = @max(
        surface_capabilities.minImageExtent.width, 
        @min(surface_capabilities.maxImageExtent.width, extent.width));

    extent.height = @max(
        surface_capabilities.minImageExtent.height, 
        @min(surface_capabilities.maxImageExtent.height, extent.height));

    return extent;
}


