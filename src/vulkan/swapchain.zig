const std = @import("std");
const c = @import("../clibs.zig");
const vke = @import("./error.zig");
const vkb = @import("./buffer.zig");

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

pub const DepthImage = struct {
    image: c.VkImage,
    image_view: c.VkImageView,
    memory: c.VkDeviceMemory,
};

pub const SwapchainFramebuffers = struct {
    handles: []c.VkFramebuffer = &.{},
};

pub const Image = struct {
    handle: c.VkImage = null,
    memory: c.VkDeviceMemory = null,
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

pub fn createDepthBufferImage(physical_device: c.VkPhysicalDevice, device: c.VkDevice, image_extent: c.VkExtent2D) !DepthImage {
    const depth_format = selectedSupportedFormat(physical_device, &.{
        c.VK_FORMAT_D32_SFLOAT_S8_UINT,
        c.VK_FORMAT_D32_SFLOAT,
        c.VK_FORMAT_D24_UNORM_S8_UINT,
    }, c.VK_IMAGE_TILING_OPTIMAL, c.VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT);
    const depth_image = try createImage(physical_device, device, image_extent.width, image_extent.height, depth_format, c.VK_IMAGE_TILING_OPTIMAL, c.VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT, c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
    const depth_image_view = try createImageView(device, depth_image.handle, depth_format, c.VK_IMAGE_ASPECT_DEPTH_BIT);

    return DepthImage{
        .image = depth_image.handle,
        .image_view = depth_image_view,
        .memory = depth_image.memory,
    };
}

pub fn createFramebuffer(a: std.mem.Allocator, device: c.VkDevice, swapchain: Swapchain, depth_image: DepthImage, render_pass: c.VkRenderPass) !SwapchainFramebuffers {

    const framebuffers = try a.alloc(c.VkFramebuffer, swapchain.images.len);
    for (swapchain.image_views, framebuffers) |image_view, *framebuffer| {
        const attachments = [2]c.VkImageView{
            image_view,
            depth_image.image_view,
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

pub fn selectedSupportedFormat(physical_device: c.VkPhysicalDevice, candidates: []const c.VkFormat, tiling: c.VkImageTiling, features: c.VkFormatFeatureFlags) c.VkFormat {
    for (candidates) |format| {
        var props = std.mem.zeroInit(c.VkFormatProperties, .{});
        c.vkGetPhysicalDeviceFormatProperties(physical_device, format, &props);

        if (tiling == c.VK_IMAGE_TILING_LINEAR and (props.linearTilingFeatures & features) == features) {
            return format;
        } else if (tiling == c.VK_IMAGE_TILING_OPTIMAL and (props.optimalTilingFeatures & features) == features) {
            return format;
        }
    }

    // TODO: Throw error instead of returning undefined
    return c.VK_FORMAT_UNDEFINED;
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

pub fn createImage(physical_device: c.VkPhysicalDevice, device: c.VkDevice, width: u32, height: u32, format: c.VkFormat, tiling: c.VkImageTiling, usage: c.VkImageUsageFlags, properties: c.VkMemoryPropertyFlags) !Image {
    var image_info = std.mem.zeroInit(c.VkImageCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
        .imageType = c.VK_IMAGE_TYPE_2D,
        .extent = .{
            .width = width,
            .height = height,
            .depth = 1,
        },
        .mipLevels = 1,
        .arrayLayers = 1,
        .format = format,
        .tiling = tiling,
        .initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
        .usage = usage,
        .samples = c.VK_SAMPLE_COUNT_1_BIT,
        .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
    });

    var image: c.VkImage = undefined;
    try vke.checkResult(c.vkCreateImage(device, &image_info, null, &image));

    var memory_requirements = std.mem.zeroInit(c.VkMemoryRequirements, .{});
    c.vkGetImageMemoryRequirements(device, image, &memory_requirements);

    const memory_type_index: u32 = vkb.findMemoryTypeIndex(physical_device, memory_requirements.memoryTypeBits, properties);
    var memory_info = std.mem.zeroInit(c.VkMemoryAllocateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        .allocationSize = memory_requirements.size,
        .memoryTypeIndex = memory_type_index,
    });

    var memory: c.VkDeviceMemory = undefined;
    try vke.checkResult(c.vkAllocateMemory(device, &memory_info, null, &memory));
    try vke.checkResult(c.vkBindImageMemory(device, image, memory, 0));

    return Image{
        .handle = image,
        .memory = memory,
    };
}

pub fn transitionImageLayout(device: c.VkDevice, command_pool: c.VkCommandPool, queue: c.VkQueue, image: c.VkImage, old_layout: c.VkImageLayout, new_layout: c.VkImageLayout) !void {
    const command_buffer = try vkb.allocAndBeginCommandBuffer(device, command_pool);
    var barrier = std.mem.zeroInit(c.VkImageMemoryBarrier, .{
        .sType = c.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
        .oldLayout = old_layout,
        .newLayout = new_layout,
        .srcQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
        .dstQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
        .image = image,
        .subresourceRange = .{
            .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
            .baseMipLevel = 0,
            .levelCount = 1,
            .baseArrayLayer = 0,
            .layerCount = 1,
        },
    });

    var srcStage: c.VkPipelineStageFlags = 0;
    var dstStage: c.VkPipelineStageFlags = 0;

    if (old_layout == c.VK_IMAGE_LAYOUT_UNDEFINED and new_layout == c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL) {
        // Memory barrier access stage transition must happen after...
        barrier.srcAccessMask = 0;
        // ...and before the transfer write stage
        barrier.dstAccessMask = c.VK_ACCESS_TRANSFER_WRITE_BIT;

        srcStage = c.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;
        dstStage = c.VK_PIPELINE_STAGE_TRANSFER_BIT;
    } else if (old_layout == c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL and new_layout == c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL) {
        barrier.srcAccessMask = c.VK_ACCESS_TRANSFER_WRITE_BIT;
        barrier.dstAccessMask = c.VK_ACCESS_SHADER_READ_BIT;

        srcStage = c.VK_PIPELINE_STAGE_TRANSFER_BIT;
        dstStage = c.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT;
    } else {
        return error.UnsupportedLayoutTransition;
    }

    c.vkCmdPipelineBarrier(command_buffer, srcStage, dstStage, 0, 0, null, 0, null, 1, &barrier);

    try vkb.endAndFreeCommandBuffer(device, command_pool, command_buffer, queue);
}


