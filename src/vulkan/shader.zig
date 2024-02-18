const std = @import("std");
const c = @import("../clibs.zig");
const vke = @import ("./error.zig");

const log = std.log.scoped(.shader);

pub fn createShaderModule(a: std.mem.Allocator, device: c.VkDevice, filename: []const u8) !c.VkShaderModule {
    const file = std.fs.cwd().openFile(filename, .{}) catch |err| {
        log.err("Failed to open file {s} received error: {}", .{filename, err});
        return err;
    };
    defer file.close();

    const stat = try file.stat();
    const file_size = stat.size;
    const buffer = try a.alloc(u8, file_size);
    const data: *const u32 = @alignCast(@ptrCast(buffer.ptr));

    _ = try file.readAll(buffer);
    defer a.free(buffer);
    
    var create_info = c.VkShaderModuleCreateInfo{
        .sType = c.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
        .pNext = null,
        .flags = 0,
        .codeSize = file_size,
        .pCode = data,
    };

    var shader_module: c.VkShaderModule = undefined;
    vke.checkResult(c.vkCreateShaderModule(device, &create_info, null, &shader_module)) catch |err| {
        log.err("Failed to create shader module for {s} received error: {}", .{filename, err});
        return err;
    };
 
    return shader_module;
}

