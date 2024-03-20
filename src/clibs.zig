//! This will import all of the c libraries in this project.
//! 
//! pub usingnamespace means other files can include this as:
//! `const c = @import("clibs.zig");`
//! 
//! Not using an import class can create weird conflicts during compilation, see below as two structs
//! while structurally the same aren't reconciling as they are in two separate areas of the cache.
//! 
//! ```
//! pointer type child 'vulkan-experiments.zig-cache.o.cb18774ec.cimport.struct_VkInstance_T' cannot cast 
//! into pointer type child 'vulkan-experiments.zig-cache.o.c699411.cimport.struct_VkInstance_T'
//! vulkan-experiments\zig-cache\o\\cb18774ec\cimport.zig:146:33: note: opaque declared here
//! pub const struct_VkInstance_T = opaque {};
//!                                 ^~~~~~~~~
//! vulkan-experiments\zig-cache\o\\c699411\cimport.zig:23537:33: note: opaque declared here
//! pub const struct_VkInstance_T = opaque {};
//! ```

const builtin = @import("builtin");

pub usingnamespace @cImport({
    @cInclude("imgui/cimgui.h");
    @cInclude("SDL2/SDL.h");
    @cInclude("stb_image.h");

    if (builtin.os.tag == .windows) {
        @cInclude("SDL2/SDL_vulkan.h");
        @cInclude("vulkan/vulkan.h");
        @cInclude("vma/vk_mem_alloc.h");
    }
});