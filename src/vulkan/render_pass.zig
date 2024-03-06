const std = @import("std");
const c = @import("../clibs.zig");
const vke = @import ("./error.zig");
const vks = @import("./swapchain.zig");

pub const RenderPass = struct {
    handle: c.VkRenderPass = null,
};

pub fn createRenderPass(physical_device: c.VkPhysicalDevice, device: c.VkDevice, swapchain_format: c.VkFormat) !RenderPass {
    const color_attachment = std.mem.zeroInit(c.VkAttachmentDescription, .{
        .format = swapchain_format,
        .samples = c.VK_SAMPLE_COUNT_1_BIT,
        .loadOp = c.VK_ATTACHMENT_LOAD_OP_CLEAR,
        .storeOp = c.VK_ATTACHMENT_STORE_OP_STORE,
        .stencilLoadOp = c.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        .stencilStoreOp = c.VK_ATTACHMENT_STORE_OP_DONT_CARE,
        .initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
        .finalLayout = c.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
    });

    const color_attachment_ref = c.VkAttachmentReference{
        .attachment = 0,
        .layout = c.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
    };

    var candidates = [3]c.VkFormat{
        c.VK_FORMAT_D32_SFLOAT_S8_UINT,
        c.VK_FORMAT_D32_SFLOAT,
        c.VK_FORMAT_D24_UNORM_S8_UINT,
    };

    const format = vks.selectedSupportedFormat(physical_device, &candidates, c.VK_IMAGE_TILING_OPTIMAL, c.VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT);

    const depth_attachment = std.mem.zeroInit(c.VkAttachmentDescription, .{
        .format = format,
        .samples = c.VK_SAMPLE_COUNT_1_BIT,
        .loadOp = c.VK_ATTACHMENT_LOAD_OP_CLEAR,
        .storeOp = c.VK_ATTACHMENT_STORE_OP_DONT_CARE,
        .stencilLoadOp = c.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        .stencilStoreOp = c.VK_ATTACHMENT_STORE_OP_DONT_CARE,
        .initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
        .finalLayout = c.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
    });

    const depth_attachment_ref = c.VkAttachmentReference{
        .attachment = 1,
        .layout = c.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
    };

    const subpass = std.mem.zeroInit(c.VkSubpassDescription, .{
        .pipelineBindPoint = c.VK_PIPELINE_BIND_POINT_GRAPHICS,
        .colorAttachmentCount = 1,
        .pColorAttachments = &color_attachment_ref,
        .pDepthStencilAttachment = &depth_attachment_ref,
    });

    const subpass_dependencies = [2]c.VkSubpassDependency {
        .{
            .srcSubpass = c.VK_SUBPASS_EXTERNAL,
            .srcStageMask = c.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT,
            .srcAccessMask = c.VK_ACCESS_MEMORY_READ_BIT,
            .dstSubpass = 0,
            .dstStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
            .dstAccessMask = c.VK_ACCESS_COLOR_ATTACHMENT_READ_BIT | c.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
            .dependencyFlags = 0,
        },
        .{
            .srcSubpass = 0,
            .srcStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
            .srcAccessMask = c.VK_ACCESS_COLOR_ATTACHMENT_READ_BIT | c.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
            .dstSubpass = c.VK_SUBPASS_EXTERNAL,
            .dstStageMask = c.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT,
            .dstAccessMask = c.VK_ACCESS_MEMORY_READ_BIT,
            .dependencyFlags = 0,
        },
    };

    const attachments: [2]c.VkAttachmentDescription = .{color_attachment, depth_attachment};

    const render_pass_create_info = std.mem.zeroInit(c.VkRenderPassCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
        .attachmentCount = @as(u32, attachments.len),
        .pAttachments = &attachments,
        .subpassCount = 1,
        .pSubpasses = &subpass,
        .dependencyCount = subpass_dependencies.len,
        .pDependencies = &subpass_dependencies,
    });

    var render_pass: c.VkRenderPass = undefined;
    try vke.checkResult(c.vkCreateRenderPass(device, &render_pass_create_info, null, &render_pass));

    return .{
        .handle = render_pass,
    };
}