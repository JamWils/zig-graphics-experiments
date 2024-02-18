const std = @import("std");
const c = @import("../clibs.zig");
const vke = @import ("./error.zig");
const shader = @import("./shader.zig");
const mesh = @import("../mesh/mesh.zig");

const GraphicsPipelineOpts = struct {
    device: c.VkDevice,
    render_pass: c.VkRenderPass,
    descriptor_set_layout: c.VkDescriptorSetLayout,
    swapchain_extent: c.VkExtent2D,
};

const Pipeline = struct {
    graphics_pipeline_handle: c.VkPipeline,
    layout: c.VkPipelineLayout = undefined,
};

pub fn createGraphicsPipeline(a: std.mem.Allocator, opts: GraphicsPipelineOpts) !Pipeline {
    const vertex_shader = try shader.createShaderModule(a, opts.device, "zig-out/shaders/shader.vert.spv");
    const fragment_shader = try shader.createShaderModule(a, opts.device, "zig-out/shaders/shader.frag.spv");

    const vertex_shader_create_info = std.mem.zeroInit(c.VkPipelineShaderStageCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
        .stage = c.VK_SHADER_STAGE_VERTEX_BIT,
        .module = vertex_shader,
        .pName = "main",
    });

    const frag_shader_create_info = std.mem.zeroInit(c.VkPipelineShaderStageCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
        .stage = c.VK_SHADER_STAGE_FRAGMENT_BIT,
        .module = fragment_shader,
        .pName = "main",
    });

    var shader_stages = [_]c.VkPipelineShaderStageCreateInfo {
        vertex_shader_create_info,
        frag_shader_create_info,
    }; 

    const binding_description: c.VkVertexInputBindingDescription = .{
        .binding = 0,
        .stride = @sizeOf(mesh.Vertex),
        .inputRate = c.VK_VERTEX_INPUT_RATE_VERTEX,
    };

    const attribute_descriptions = [_]c.VkVertexInputAttributeDescription{
        .{
            .binding = 0,
            .location = 0,
            .format = c.VK_FORMAT_R32G32B32_SFLOAT,
            .offset = @offsetOf(mesh.Vertex, "position"),
        },
        .{
            .binding = 0,
            .location = 1,
            .format = c.VK_FORMAT_R32G32B32_SFLOAT,
            .offset = @offsetOf(mesh.Vertex, "color"),
        }
    };

    const vertex_input_create_info = std.mem.zeroInit(c.VkPipelineVertexInputStateCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
        .vertexBindingDescriptionCount = 1,
        .pVertexBindingDescriptions = &binding_description,
        .vertexAttributeDescriptionCount = @as(u32, @intCast(attribute_descriptions.len)),
        .pVertexAttributeDescriptions = &attribute_descriptions,
    });

    const input_assembly_create_info = std.mem.zeroInit(c.VkPipelineInputAssemblyStateCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
        .topology = c.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
        .primitiveRestartEnable = c.VK_FALSE,
    });

    const viewport = c.VkViewport {
        .x = 0.0,
        .y = 0.0,
        .width = @as(f32, @floatFromInt(opts.swapchain_extent.width)),
        .height = @as(f32, @floatFromInt(opts.swapchain_extent.height)),
        .minDepth = 0.0,
        .maxDepth = 1.0,
    };

    const scissor = c.VkRect2D {
        .offset = .{
            .x = 0,
            .y = 0,
        }, 
        .extent = opts.swapchain_extent,
    };

    const viewport_create_info = std.mem.zeroInit(c.VkPipelineViewportStateCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
        .viewportCount = 1,
        .pViewports = &viewport,
        .scissorCount = 1,
        .pScissors = &scissor,
    });

    const rasterization_create_info = std.mem.zeroInit(c.VkPipelineRasterizationStateCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
        .depthClampEnable = c.VK_FALSE,
        .rasterizerDiscardEnable = c.VK_FALSE,
        .polygonMode = c.VK_POLYGON_MODE_FILL,
        .lineWidth = 1.0,
        .cullMode = c.VK_CULL_MODE_BACK_BIT,
        .frontFace = c.VK_FRONT_FACE_COUNTER_CLOCKWISE,
        .depthBiasEnable = c.VK_FALSE,
    });

    const multisample_create_info = std.mem.zeroInit(c.VkPipelineMultisampleStateCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
        .sampleShadingEnable = c.VK_FALSE,
        .rasterizationSamples = c.VK_SAMPLE_COUNT_1_BIT,
        .minSampleShading = 1.0,
    });

    const color_blend_attachment = std.mem.zeroInit(c.VkPipelineColorBlendAttachmentState, .{
        .colorWriteMask = c.VK_COLOR_COMPONENT_R_BIT
            | c.VK_COLOR_COMPONENT_G_BIT
            | c.VK_COLOR_COMPONENT_B_BIT
            | c.VK_COLOR_COMPONENT_A_BIT,
        .blendEnable = c.VK_TRUE,
        .srcColorBlendFactor = c.VK_BLEND_FACTOR_SRC_ALPHA,
        .dstColorBlendFactor = c.VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
        .colorBlendOp = c.VK_BLEND_OP_ADD,
        .srcAlphaBlendFactor = c.VK_BLEND_FACTOR_ONE,
        .dstAlphaBlendFactor = c.VK_BLEND_FACTOR_ZERO,
    });

    const color_blending_create_info = std.mem.zeroInit(c.VkPipelineColorBlendStateCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
        .logicOpEnable = c.VK_FALSE,
        .attachmentCount = 1,
        .pAttachments = &color_blend_attachment,
    });

    const descriptor_set_layouts = [_]c.VkDescriptorSetLayout{opts.descriptor_set_layout};

    const pipeline_layout_create_info = std.mem.zeroInit(c.VkPipelineLayoutCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
        .setLayoutCount = 1,
        .pSetLayouts = &descriptor_set_layouts[0],
    });

    var pipeline_layout: c.VkPipelineLayout = undefined;
    try vke.checkResult(c.vkCreatePipelineLayout(opts.device, &pipeline_layout_create_info, null, &pipeline_layout));

    // TODO: Set up depth stencil testing

    var graphics_pipeline_create_info = std.mem.zeroInit(c.VkGraphicsPipelineCreateInfo, .{
        .sType = c.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
        .stageCount = shader_stages.len,
        .pStages = &shader_stages,
        .pVertexInputState = &vertex_input_create_info,
        .pInputAssemblyState = &input_assembly_create_info,
        .pViewportState = &viewport_create_info,
        .pDynamicState = null,
        .pRasterizationState = &rasterization_create_info,
        .pMultisampleState = &multisample_create_info,
        .pColorBlendState = &color_blending_create_info,
        .pDepthStencilState = null,
        .layout = pipeline_layout,
        .renderPass = opts.render_pass,
        .subpass = 0,
        .basePipelineHandle = null,
        .basePipelineIndex = -1,
    });

    var graphics_pipeline: c.VkPipeline = undefined;
    try vke.checkResult(c.vkCreateGraphicsPipelines(opts.device, null, 1, &graphics_pipeline_create_info, null, &graphics_pipeline));

    c.vkDestroyShaderModule(opts.device, fragment_shader, null);
    c.vkDestroyShaderModule(opts.device, vertex_shader, null);

    return .{
        .graphics_pipeline_handle = graphics_pipeline,
        .layout = pipeline_layout,
    };
}