const std = @import("std");
const core = @import("core");
const ecs = @import("flecs");
const scene = @import("scene");
const c = @import("clibs.zig");
const log = std.log.scoped(.app);

pub fn cleanUpInput(it: *ecs.iter_t) callconv(.C) void {
    const input = ecs.singleton_get(it.world, scene.Input).?;
    const allocator = ecs.singleton_get(it.world, core.Allocator).?;
    
    allocator.alloc.free(input.keys);
}

pub fn init(world: *ecs.world_t, allocator: std.mem.Allocator) !void {
    ecs.TAG(world, core.OnStop);
    ecs.COMPONENT(world, core.Allocator);
    ecs.COMPONENT(world, core.CanvasSize);
    ecs.COMPONENT(world, scene.Input);
    ecs.add_pair(world, ecs.id(core.OnStop), ecs.DependsOn, ecs.OnStore);

    _ = ecs.singleton_set(world, core.Allocator, core.Allocator{ .alloc = allocator });
    _ = ecs.singleton_set(world, core.CanvasSize, .{ .width = 800, .height = 600 });

    const keys = allocator.alloc(scene.KeyState, scene.KEY_COUNT) catch @panic( "OOM!");
    _ = ecs.singleton_set(world, scene.Input, .{
        .keys = keys,
        .mouse = std.mem.zeroInit(scene.MouseState, .{}),
    });

    var input_desc = ecs.system_desc_t{};
    input_desc.callback = cleanUpInput;
    input_desc.query.filter.terms[0] = .{ 
        .id = ecs.id(scene.Input), 
        .src = .{
            .id = ecs.id(scene.Input), 
        },
    };
    _ = ecs.SYSTEM(world, "DestroyInput", ecs.id(core.OnStop), &input_desc);
}

pub fn run(world: *ecs.world_t) void {
    _ = ecs.enable(world, ecs.id(core.OnStop), false);

    var alive = true;
    while (alive) {
        alive = ecs.progress(world, 0);
        if (!alive) {
            std.debug.print("Quitting...\n", .{});
        }
    }
}