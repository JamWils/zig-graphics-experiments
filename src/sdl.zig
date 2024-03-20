const std = @import("std");
const core = @import("core");
const ecs = @import("flecs");
const scene = @import("scene");
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
        const size = ecs.get(it.world, e, core.CanvasSize).?;

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

        // _ = ecs.set(it.world, ecs.id(app.App), core.CanvasSize, .{ .width = window_width, .height = window_height });
    }
}

fn destroyWindow(it: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Destroying window\n", .{});
    const window = ecs.field(it, Window, 1).?;
    for (0..it.count()) |i| {
        c.SDL_DestroyWindow(window[i].handle);
    }
    c.SDL_Quit();
}

fn keySymbol(sdl_symbol: i32, shift: bool) usize {
    if (sdl_symbol < 128) {
        if (shift) {
            if (sdl_symbol == scene.KEY_EQUAL) {
                std.debug.print("Key: {c}\n", .{'+'});
            } else if (sdl_symbol == scene.KEY_UNDERSCORE) {
                std.debug.print("Key: {c}\n", .{'-'});
            } else {
                return @as(usize, @intCast(sdl_symbol));
            }
        }

        return @as(usize, @intCast(sdl_symbol));
    }

    const sym = switch(sdl_symbol) {
        c.SDLK_RIGHT => scene.KEY_RIGHT,
        c.SDLK_LEFT => scene.KEY_LEFT,
        c.SDLK_DOWN => scene.KEY_DOWN,
        c.SDLK_UP => scene.KEY_UP,
        c.SDLK_LCTRL => scene.KEY_LEFT_CTRL,
        c.SDLK_RCTRL => scene.KEY_LEFT_CTRL,
        c.SDLK_LSHIFT => scene.KEY_LEFT_SHIFT,
        c.SDLK_RSHIFT => scene.KEY_LEFT_SHIFT,
        c.SDLK_LALT => scene.KEY_LEFT_ALT,
        c.SDLK_RALT => scene.KEY_LEFT_ALT,
        else => 0,
    };

    return @as(usize, @intCast(sym));
}

fn processEvents(it: *ecs.iter_t) callconv(.C) void {
    // std.debug.print("Processing events\n", .{});
    var input = ecs.singleton_get_mut(it.world, scene.Input).?;
    // ecs.os.free(input);

    for (0..scene.KEY_COUNT) |j| {
        scene.keyReset(&input.keys[j]);
    }

    var event: c.SDL_Event = undefined;
    while (c.SDL_PollEvent(&event) != 0) {
        if(event.type == c.SDL_QUIT) {
            ecs.enable(it.world, ecs.id(core.OnStop), true);
        } else if (event.type == c.SDL_KEYDOWN) {
            if (event.key.keysym.sym == c.SDLK_ESCAPE) {
                ecs.enable(it.world, ecs.id(core.OnStop), true);
            }
            const sym = keySymbol(event.key.keysym.sym, false);
            scene.keyDown(&input.keys[sym]);
        } else if (event.type == c.SDL_KEYUP) {
            const sym = keySymbol(event.key.keysym.sym, false);
            scene.keyUp(&input.keys[sym]);
        } else if (event.type == c.SDL_MOUSEBUTTONDOWN) {
            if (event.button.button == c.SDL_BUTTON_LEFT) {
                scene.keyDown(&input.mouse.left);
            } else if (event.button.button == c.SDL_BUTTON_RIGHT) {
                scene.keyDown(&input.mouse.right);
            }
        } else if (event.type == c.SDL_MOUSEBUTTONUP) {
            if (event.button.button == c.SDL_BUTTON_LEFT) {
                scene.keyUp(&input.mouse.left);
            } else if (event.button.button == c.SDL_BUTTON_RIGHT) {
                scene.keyUp(&input.mouse.right);
            }
        } else if (event.type == c.SDL_MOUSEMOTION) {
            input.mouse.window.x = event.motion.x;
            input.mouse.window.y = event.motion.y;
            input.mouse.relative.x = event.motion.xrel;
            input.mouse.relative.y = event.motion.yrel;
        } else if (event.type == c.SDL_MOUSEWHEEL) {
            input.mouse.scroll.x = event.wheel.x;
            input.mouse.scroll.y = event.wheel.y;
        } else if (event.type == c.SDL_WINDOWEVENT) {
            // TODO: Need to update the canvas, destroy swapchains, images, etc.  Then recreate them with the proper size.
            // if (event.window.event == c.SDL_WINDOWEVENT_RESIZED) {
            //     std.debug.print("Window resized: {d}, {d}\n", .{event.window.data1, event.window.data2});
            //     // _ = ecs.set(it.world, ecs.id(app.App), core.CanvasSize, .{ .width = event.window.data1, .height = event.window.data2 });
            // }
        }
    }

    // ecs.singleton_set(it.world, scene.Input, input.*);
}

pub fn init(world: *ecs.world_t) void {
    checkSdl(c.SDL_Init(c.SDL_INIT_VIDEO));
    
    ecs.COMPONENT(world, Window);

    var desc = ecs.system_desc_t{
        .callback = createWindow,
    };
    desc.query.filter.terms[0] = .{ .id = ecs.id(core.CanvasSize), .inout = ecs.inout_kind_t.In };
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
    // event_desc.query.filter.terms[0] = .{ .id = ecs.id(scene.Input), .inout = ecs.inout_kind_t.InOut };
    ecs.SYSTEM(world, "EventSystem", ecs.OnUpdate, &event_desc);

    const window = ecs.new_entity(world, "Window");
    _ = ecs.set(world, window, Window, .{ .handle = undefined, .width = 0, .height = 0 });
    _ = ecs.set(world, window, core.CanvasSize, .{ .width = 800, .height = 600 });
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