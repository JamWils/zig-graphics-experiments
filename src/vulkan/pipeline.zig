const std = @import("std");
const c = @import("../clibs.zig");
const vke = @import ("./error.zig");
const shader = @import("./shader.zig");

pub fn createGraphicsPipeline(a: std.mem.Allocator, device: c.VkDevice) !void {
    const vertex_shader = try shader.createShaderModule(a, device, "zig-out/shaders/shader.vert.spv");
    const fragment_shader = try shader.createShaderModule(a, device, "zig-out/shaders/shader.frag.spv");



    c.vkDestroyShaderModule(device, fragment_shader, null);
    c.vkDestroyShaderModule(device, vertex_shader, null);
}