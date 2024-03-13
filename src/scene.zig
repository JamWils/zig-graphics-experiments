const std = @import("std");
const ecs = @import("flecs");
const scene = @import("scene");
const zmath = @import("zmath");
const app = @import("app.zig");

fn simpleSceneSetUp(it: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Start up: {s}\n", .{ecs.get_name(it.world, it.system).?});
    const allocator = ecs.singleton_get(it.world, app.Allocator).?;
    const canvas_size = ecs.singleton_get(it.world, app.CanvasSize).?;

    const dimension: f32 = @as(f32, @floatFromInt(canvas_size.width)) / @as(f32, @floatFromInt(canvas_size.height));
    var camera = scene.Camera{
        .view = zmath.lookAtRh(.{0, 0, 2, 1}, .{0, 0, 0, 1}, .{0, 1, 0, 1}),
        .projection = zmath.perspectiveFovRh(std.math.degreesToRadians(f32, 45), dimension, 0.1, 10),
    };
    camera.projection[1][1] *= -1;

    const camera_entity = ecs.new_id(it.world);
    _ = ecs.set(it.world, camera_entity, scene.Camera, camera);

    const vertices = [_]scene.Vertex{
        .{
            .position = .{-0.4, 0.4, 0.0},
            .color = .{1, 0, 0},
            .uv = .{1, 1},
        },
        .{
            .position = .{-0.4, -0.4, 0.0},
            .color = .{0, 1, 0},
            .uv = .{1, 0},
        },
        .{
            .position = .{0.4, -0.4, 0.0},
            .color = .{0, 0, 1},
            .uv = .{0, 0},
        },
        .{
            .position = .{0.4, 0.4, 0.0},
            .color = .{1, 1, 0},
            .uv = .{0, 1},
        },
    };

    const vertices_two = [_]scene.Vertex{
        .{
            .position = .{-0.25, 0.6, 0.0},
            .color = .{1, 0, 0},
            .uv = .{1, 1},
        },
        .{
            .position = .{-0.25, -0.6, 0.0},
            .color = .{1, 1, 0},
            .uv = .{1, 0},
        },
        .{
            .position = .{0.25, -0.6, 0.0},
            .color = .{1, 0, 1},
            .uv = .{0, 0},
        },
        .{
            .position = .{0.25, 0.6, 0.0},
            .color = .{1, 1, 0},
            .uv = .{0, 1},
        },
    };

    const indices = [_]u32{
        0, 1, 2,
        2, 3, 0,
    };

    const first_mesh = scene.Mesh{
        .vertices = allocator.alloc.dupe(scene.Vertex, vertices[0..]) catch @panic("Out of memory"),
        .indices = allocator.alloc.dupe(u32, indices[0..]) catch @panic("Out of memory"),
        .texture_id = 0,
    };

    const second_mesh = scene.Mesh{
        .vertices = allocator.alloc.dupe(scene.Vertex, vertices_two[0..]) catch @panic("Out of memory"),
        .indices = allocator.alloc.dupe(u32, indices[0..]) catch @panic("Out of memory"),
        .texture_id = 0,
    };

    const entity = ecs.new_id(it.world);
    _ = ecs.add(it.world, entity, scene.UpdateBuffer);
    _ = ecs.set(it.world, entity, scene.Mesh, first_mesh);
    _ = ecs.set(it.world, entity, scene.Speed, scene.Speed{.value = 20});

    var t1 = zmath.identity();
    t1 = zmath.mul(zmath.translationV(.{0, 0, -2.5, 1}), t1);
    _ = ecs.set(it.world, entity, scene.Transform, scene.Transform{
        .value = t1,
    });

    const entity2 = ecs.new_id(it.world);
    _ = ecs.add(it.world, entity2, scene.UpdateBuffer);
    _ = ecs.set(it.world, entity2, scene.Mesh, second_mesh);
    _ = ecs.set(it.world, entity2, scene.Speed, scene.Speed{.value = 50});

    var t2 = zmath.identity();
    t2 = zmath.mul(zmath.translationV(.{0, 0, -3, 1}), t2);
    _ = ecs.set(it.world, entity2, scene.Transform, scene.Transform{
        .value = t2,
    });
}

fn cleanUpMeshAllocations(it: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Clean up: {s}\n", .{ecs.get_name(it.world, it.system).?});
    const allocator = ecs.singleton_get(it.world, app.Allocator).?;
    const meshes = ecs.field(it, scene.Mesh, 1).?;

    for (meshes) |mesh| {
        allocator.alloc.free(mesh.vertices);
        allocator.alloc.free(mesh.indices);
    }
}

fn spinTransform(it: *ecs.iter_t) callconv(.C) void {
    // std.debug.print("Update: {s}\n", .{ecs.get_name(it.world, it.system).?});
    const transforms = ecs.field(it, scene.Transform, 1).?;
    const speeds = ecs.field(it, scene.Speed, 2).?;

    for (transforms, speeds, it.entities()) |transform, speed, e| {
        const newValue = zmath.mul(zmath.rotationZ(std.math.degreesToRadians(f32, it.delta_time * speed.value)), transform.value);
        _ = ecs.set(it.world, e, scene.Transform, .{
            .value = newValue,
        });
    }
}

pub fn init(world: *ecs.world_t) void {
    ecs.COMPONENT(world, scene.Camera);
    ecs.COMPONENT(world, scene.Mesh);
    ecs.COMPONENT(world, scene.Transform);
    ecs.COMPONENT(world, scene.Speed);
    ecs.TAG(world, scene.UpdateBuffer);

    var simple_scene_desc = ecs.system_desc_t{};
    simple_scene_desc.callback = simpleSceneSetUp;
    simple_scene_desc.query.filter.terms[0] = .{ 
        .id = ecs.id(app.Allocator),
        .src = .{ .id = ecs.id(app.Allocator) },
    };
    simple_scene_desc.query.filter.terms[1] = .{ 
        .id = ecs.id(app.CanvasSize), 
        .src = .{
            .id = ecs.id(app.CanvasSize), 
        },
    };
    ecs.SYSTEM(world, "SimpleSceneSetUp", ecs.OnStart, &simple_scene_desc);

    var spin_transform_desc = ecs.system_desc_t{};
    spin_transform_desc.callback = spinTransform;
    spin_transform_desc.query.filter.terms[0] = .{ .id = ecs.id(scene.Transform), .inout = ecs.inout_kind_t.InOut, };
    spin_transform_desc.query.filter.terms[1] = .{ .id = ecs.id(scene.Speed), .inout = ecs.inout_kind_t.In, };
    ecs.SYSTEM(world, "SpinTransform", ecs.OnUpdate, &spin_transform_desc);

    var clean_up_mesh_allocations_desc = ecs.system_desc_t{};
    clean_up_mesh_allocations_desc.callback = cleanUpMeshAllocations;
    clean_up_mesh_allocations_desc.query.filter.terms[0] = .{ .id = ecs.id(scene.Mesh), .inout = ecs.inout_kind_t.InOut, };
    ecs.SYSTEM(world, "CleanUpMeshAllocations", ecs.id(app.OnStop), &clean_up_mesh_allocations_desc);
}