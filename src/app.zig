const std = @import("std");
const ecs = @import("flecs");
const scene = @import("scene");
const c = @import("clibs.zig");
const log = std.log.scoped(.app);

pub const CanvasSize = struct {
    width: c_int,
    height: c_int,
};

pub const Allocator = struct {
    alloc: std.mem.Allocator,
};

pub const OnStop = struct {};

pub fn cleanUpInput(it: *ecs.iter_t) callconv(.C) void {
    const input = ecs.singleton_get(it.world, scene.Input).?;
    const allocator = ecs.singleton_get(it.world, Allocator).?;
    
    allocator.alloc.free(input.keys);
}

pub fn init(world: *ecs.world_t, allocator: std.mem.Allocator) !void {
    ecs.TAG(world, OnStop);
    ecs.COMPONENT(world, Allocator);
    ecs.COMPONENT(world, CanvasSize);
    ecs.COMPONENT(world, scene.Input);
    ecs.add_pair(world, ecs.id(OnStop), ecs.DependsOn, ecs.OnStore);

    _ = ecs.singleton_set(world, Allocator, Allocator{ .alloc = allocator });
    _ = ecs.singleton_set(world, CanvasSize, .{ .width = 800, .height = 600 });

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
    _ = ecs.SYSTEM(world, "DestroyInput", ecs.id(OnStop), &input_desc);
}

pub fn run(world: *ecs.world_t) void {
    _ = ecs.enable(world, ecs.id(OnStop), false);

    var alive = true;
    while (alive) {
        alive = ecs.progress(world, 0);
        if (!alive) {
            std.debug.print("Quitting...\n", .{});
        }
    }
}