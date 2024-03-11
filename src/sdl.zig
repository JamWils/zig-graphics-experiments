const std = @import("std");
const ecs = @import("flecs");
const c = @import("clibs.zig");
const app = @import("app.zig");
const log = std.log.scoped(.sdl);

pub const Window = struct {
    handle: *c.SDL_Window,
    width: c_int,
    height: c_int,
};

fn createWindow(it: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Start up: {s}\n", .{ecs.get_name(it.world, it.system).?});
    const window = ecs.field(it, Window, 2).?;

    for (0..it.count()) |i| {
        const e = it.entities()[i];
        const size = ecs.get(it.world, e, app.CanvasSize).?;

        const sdl_window = c.SDL_CreateWindow(
            "App Engine",
            c.SDL_WINDOWPOS_CENTERED,
            c.SDL_WINDOWPOS_CENTERED,
            size.width,
            size.height,
            c.SDL_WINDOW_VULKAN | c.SDL_WINDOW_RESIZABLE,
        ) orelse @panic("Failed to create SDL window");

        var window_width: c_int = 0;
        var window_height: c_int = 0;
        c.SDL_GetWindowSize(sdl_window, &window_width, &window_height);

        window[i].handle = sdl_window;
        window[i].width = window_width;
        window[i].height = window_height;

        _ = ecs.singleton_set(it.world, app.CanvasSize, .{ .width = window_width, .height = window_height });
    }
}

fn destroyWindow(it: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Destroying window\n", .{});
    const window = ecs.field(it, Window, 1).?;
    for (0..it.count()) |i| {
        c.SDL_DestroyWindow(window[i].handle);
    }
}

fn processEvents(it: *ecs.iter_t) callconv(.C) void {
    var event: c.SDL_Event = undefined;
    while (c.SDL_PollEvent(&event) != 0) {
        if(event.type == c.SDL_QUIT) {
            // ecs.quit(it.world);
            ecs.enable(it.world, ecs.id(app.OnStop), true);
        }
    }
}

pub fn init(world: *ecs.world_t) void {
    checkSdl(c.SDL_Init(c.SDL_INIT_VIDEO));
    
    ecs.COMPONENT(world, Window);

    var desc = ecs.system_desc_t{
        .callback = createWindow,
    };
    desc.query.filter.terms[0] = .{ .id = ecs.id(app.CanvasSize), .inout = ecs.inout_kind_t.In };
    desc.query.filter.terms[1] = .{ .id = ecs.id(Window), .inout = ecs.inout_kind_t.Out };
    ecs.SYSTEM(world, "InitWindowSystem", ecs.OnStart, &desc);

    var destroy_desc = ecs.observer_desc_t{
        .callback = destroyWindow,
    };
    destroy_desc.filter.terms[0] = .{ .id = ecs.id(Window), .inout = ecs.inout_kind_t.In };
    destroy_desc.events[0] = ecs.UnSet;
    ecs.OBSERVER(world, "DestroySystem", &destroy_desc);

    var event_desc = ecs.system_desc_t{};
    event_desc.callback = processEvents;
    ecs.SYSTEM(world, "EventSystem", ecs.OnUpdate, &event_desc);

    const window = ecs.new_entity(world, "Window");
    _ = ecs.set(world, window, Window, .{ .handle = undefined, .width = 0, .height = 0 });
    _ = ecs.set(world, window, app.CanvasSize, .{ .width = 800, .height = 600 });
}

pub fn checkSdl(res: c_int) void {
    if (res != 0) {
        log.err("Vulkan engine SDL error: {s}", .{c.SDL_GetError()});
        @panic("SDL error");
    }
}

pub fn checkSdlBool(res: c.SDL_bool) void {
    if (res != c.SDL_TRUE) {
        log.err("Vulkan engine SDL error: {s}", .{c.SDL_GetError()});
        @panic("SDL error");
    }
}