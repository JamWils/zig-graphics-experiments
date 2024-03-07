const std = @import("std");
const testing = std.testing;
const builtin = @import("builtin");
const ecs = @import("flecs");
const VulkanEngine = @import("vulkan_engine.zig");
const MetalEngine = @import("metal_engine.zig");

const Position = struct { x: f32, y: f32 };
const Velocity = struct { x: f32, y: f32 };
const Eats = struct {};
const Apples = struct {};

fn startUp(_: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Start up\n", .{});
}

fn update(it: *ecs.iter_t) callconv(.C) void {
    const type_str = ecs.table_str(it.world, it.table).?;
    std.debug.print("Updating with [{s}]\n", .{type_str});
    defer ecs.os.free(type_str);
}

fn move(it: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Moving\n", .{});
    var p = ecs.field(it, Position, 1).?;
    const v = ecs.field(it, Velocity, 2).?;

    const type_str = ecs.table_str(it.world, it.table).?;
    std.debug.print("Move entities with [{s}]\n", .{type_str});
    defer ecs.os.free(type_str);

    std.debug.print("Count: {}\n", .{it.entities().len});

    for (0..it.count()) |i| {
        std.debug.print("{}\n", .{i});
        p[i].x += v[i].x;
        p[i].y += v[i].y;
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) {
        @panic("Leaked memory");
    };

    const world = ecs.init();
    defer _ = ecs.fini(world);

    ecs.COMPONENT(world, Position);
    ecs.COMPONENT(world, Velocity);

    ecs.TAG(world, Eats);
    ecs.TAG(world, Apples);

    var desc = ecs.system_desc_t{
        .callback = startUp,
    };
    ecs.SYSTEM(world, "start up", ecs.OnStart, &desc);

    var update_desc = ecs.system_desc_t{};
    update_desc.callback = update;
    update_desc.query.filter.terms[0] = .{ .id = ecs.id(Position) };
    ecs.SYSTEM(world, "update", ecs.OnUpdate, &update_desc);
    {
        var system_desc = ecs.system_desc_t{};
        system_desc.callback = move;
        system_desc.query.filter.terms[0] = .{ .id = ecs.id(Position) };
        system_desc.query.filter.terms[1] = .{ .id = ecs.id(Velocity) };
        ecs.SYSTEM(world, "move system", ecs.OnUpdate, &system_desc);
    }

    const bob = ecs.new_entity(world, "Bob");
    _ = ecs.set(world, bob, Position, .{ .x = 0, .y = 0 });
    _ = ecs.set(world, bob, Velocity, .{ .x = 1, .y = 2 });
    ecs.add_pair(world, bob, ecs.id(Eats), ecs.id(Apples));

    _ = ecs.progress(world, 0);
    _ = ecs.progress(world, 0);

    const p = ecs.get(world, bob, Position).?;
    std.debug.print("Bob's position is ({d}, {d})\n", .{ p.x, p.y });

    if (builtin.os.tag == .windows) {
        var engine = VulkanEngine.init(gpa.allocator()) catch |err| {
            std.debug.print("Unable to create vulkan engine: {}\n", .{err});
            @panic("Unable to create vulkan engine");
        };
        defer engine.cleanup();
        try engine.run();
    } else if (builtin.os.tag == .macos) {
        // std.debug.print("MacOS verision at least 14: {}\n", .{macosVersionAtLeast(15, 0, 0)});
        var engine = MetalEngine.init(gpa.allocator()) catch |err| {
            std.debug.print("Unable to create metal engine: {}\n", .{err});
            @panic("Unable to create metal engine");
        };
        defer engine.cleanup();
        try engine.run();
        
    } else {
        @panic("platform not supported");
    }
}

// pub fn macosVersionAtLeast(major: i64, minor: i64, patch: i64) bool {
//     // Get the objc class from the runtime
//     const NSProcessInfo = objc.getClass("NSProcessInfo").?;

//     // Call a class method with no arguments that returns another objc object.
//     const info = NSProcessInfo.msgSend(objc.Object, "processInfo", .{});

//     // Call an instance method that returns a boolean and takes a single
//     // argument.
//     return info.msgSend(bool, "isOperatingSystemAtLeastVersion:", .{
//         NSOperatingSystemVersion{ .major = major, .minor = minor, .patch = patch },
//     });
// }

// const NSOperatingSystemVersion = extern struct {
//     major: i64,
//     minor: i64,
//     patch: i64,
// };

test {
    testing.refAllDecls(@This());
}