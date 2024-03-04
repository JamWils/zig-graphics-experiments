const std = @import("std");
const vkb = @import("./buffer.zig");
const vke = @import("./error.zig");
const vks = @import("./swapchain.zig");
const c = @import("../clibs.zig");

// pub const AllocatedImage = struct {
//     image: c.VkImage,
//     allocation: c.VmaAllocation,
// };

pub const ImageOpts = struct {
    physical_device: c.VkPhysicalDevice,
    device: c.VkDevice,
    transfer_queue: c.VkQueue,
    command_pool: c.VkCommandPool,
};

pub fn loadImageFromFile(filepath: []const u8, opts: ImageOpts) !vks.Image {
    var width: c_int = undefined;
    var height: c_int = undefined;
    var channels: c_int = undefined;

    const image_data = c.stbi_load(filepath.ptr, &width, &height, &channels, c.STBI_rgb_alpha);
    if (image_data == null) {
        return error.ImageLoadFailure;
    }
    defer c.stbi_image_free(image_data);

    const image_size = @as(c.VkDeviceSize, @as(u64, @intCast(width)) * @as(u64, @intCast(height)) * 4);
    const format = c.VK_FORMAT_R8G8B8A8_UNORM;

    const staging_buffer = try vkb.createBuffer(.{
        .physical_device = opts.physical_device,
        .device = opts.device,
        .buffer_size = image_size,
        .buffer_usage = c.VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
        .buffer_properties = c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
    });
    defer staging_buffer.deleteAndFree(opts.device);


    var image_data_slice: []const u8 = undefined;
    image_data_slice.ptr = @as([*]const u8, @ptrCast(image_data));
    image_data_slice.len = image_size;

    var staging_data: ?*align(@alignOf(u8)) anyopaque = undefined;
    try vke.checkResult(c.vkMapMemory(opts.device, staging_buffer.memory, 0, image_size, 0, &staging_data));
    @memcpy(@as([*]u8, @ptrCast(staging_data orelse unreachable)), image_data_slice);
    c.vkUnmapMemory(opts.device, staging_buffer.memory);

    const w = @as(u32, @intCast(width));
    const h = @as(u32, @intCast(height));
    const image = try vks.createImage(opts.physical_device, opts.device, w, h, format, c.VK_IMAGE_TILING_OPTIMAL, c.VK_IMAGE_USAGE_TRANSFER_DST_BIT | c.VK_IMAGE_USAGE_SAMPLED_BIT, c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);

    try vks.transitionImageLayout(opts.device, opts.command_pool, opts.transfer_queue, image.handle, c.VK_IMAGE_LAYOUT_UNDEFINED, c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL);

    try vkb.copyImageBuffer(staging_buffer.handle, image.handle, w, h, vkb.TransferBufferOpts{
        .device = opts.device,
        .transfer_queue = opts.transfer_queue,
        .command_pool = opts.command_pool,
    });

    return image;
}