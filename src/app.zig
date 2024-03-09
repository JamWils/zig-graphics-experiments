const std = @import("std");
const ecs = @import("flecs");
const c = @import("clibs.zig");
const log = std.log.scoped(.app);

pub const Allocator = struct {
    alloc: std.mem.Allocator,
};

pub fn run(world: *ecs.world_t) void {
    var alive = true;
    while (alive) {
        alive = ecs.progress(world, 0);
        if (!alive) {
            std.debug.print("Quitting...\n", .{});
        }
    }
}