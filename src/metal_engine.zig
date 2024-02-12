const std = @import("std");
const c = @import("clibs.zig");

const log = std.log.scoped(.metal_engine);

const MetalEngine = struct {
    window: *c.SDL_Window,

    pub fn cleanup(self: *MetalEngine) void {
        c.SDL_DestroyWindow(self.window);
    }

    pub fn run(self: *MetalEngine) !void {
        _ = self;
        var quit = false;

        var event: c.SDL_Event = undefined;
        while (!quit) {
            while (c.SDL_PollEvent(&event) != 0) {
                if (event.type == c.SDL_QUIT) {
                   quit = true;
                }
            }
        }
    }
};

pub fn init(_: std.mem.Allocator) !MetalEngine {
    checkSdl(c.SDL_Init(c.SDL_INIT_VIDEO));

    const window = c.SDL_CreateWindow(
        "Metal App",
        c.SDL_WINDOWPOS_CENTERED,
        c.SDL_WINDOWPOS_CENTERED,
        800,
        600,
        c.SDL_WINDOW_RESIZABLE,
    ) orelse @panic("Failed to create SDL window");

    c.SDL_ShowWindow(window);

    const engine = MetalEngine{
        .window = window,
    };

    return engine;
}

fn checkSdl(res: c_int) void {
    if (res != 0) {
        log.err("Metal engine SDL error: {s}", .{c.SDL_GetError()});
        @panic("SDL error");
    }
}

fn checkSdlBool(res: c.SDL_bool) void {
    if (res != c.SDL_TRUE) {
        log.err("Metal engine SDL error: {s}", .{c.SDL_GetError()});
        @panic("SDL error");
    }
}