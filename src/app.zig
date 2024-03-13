const std = @import("std");
const ecs = @import("flecs");
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

pub fn init(world: *ecs.world_t, allocator: std.mem.Allocator) void {
    ecs.TAG(world, OnStop);
    ecs.COMPONENT(world, Allocator);
    ecs.COMPONENT(world, CanvasSize);
    ecs.add_pair(world, ecs.id(OnStop), ecs.DependsOn, ecs.OnStore);

    _ = ecs.singleton_set(world, Allocator, Allocator{ .alloc = allocator });
    _ = ecs.singleton_set(world, CanvasSize, .{ .width = 800, .height = 600 });
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