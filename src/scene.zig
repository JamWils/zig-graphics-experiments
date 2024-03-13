const std = @import("std");
const ecs = @import("flecs");
const scene = @import("scene");
const zmath = @import("zmath");
const app = @import("app.zig");

// fn simpleTextureSetUp(it: *ecs.iter_t) callconv(.C) void {
//     std.debug.print("Start up: {s}\n", .{ecs.get_name(it.world, it.system).?});

//     const sample_image = try vkt.loadImageFromFile("assets/sample_floor.png", .{
//         .physical_device = physical_device.handle,
//         .device = device.handle,
//         .transfer_queue = device.graphics_queue,
//         .command_pool = graphics_command_pool.handle,
//     });
//     const texture_sampler = try vkt.createTextureSampler(device.handle);
//     const sampler_image_view = try vkt.createTextureImageView(alloc, device.handle, sample_image.handle, sampler_descriptor_pool.handle, sampler_descriptor_set_layout.handle, texture_sampler);
// }

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
    defer allocator.alloc.free(first_mesh.vertices);
    defer allocator.alloc.free(first_mesh.indices);

    const second_mesh = scene.Mesh{
        .vertices = allocator.alloc.dupe(scene.Vertex, vertices_two[0..]) catch @panic("Out of memory"),
        .indices = allocator.alloc.dupe(u32, indices[0..]) catch @panic("Out of memory"),
        .texture_id = 0,
    };
    defer allocator.alloc.free(second_mesh.vertices);
    defer allocator.alloc.free(second_mesh.indices);

    const entity = ecs.new_id(it.world);
    _ = ecs.add(it.world, entity, scene.UpdateBuffer);
    _ = ecs.set(it.world, entity, scene.Mesh, first_mesh);
    _ = ecs.set(it.world, entity, scene.Transform, scene.Transform{
        .value = zmath.identity(),
    });

    const entity2 = ecs.new_id(it.world);
    _ = ecs.add(it.world, entity2, scene.UpdateBuffer);
    _ = ecs.set(it.world, entity2, scene.Mesh, second_mesh);
    _ = ecs.set(it.world, entity2, scene.Transform, scene.Transform{
        .value = zmath.identity(),
    });
}

pub fn init(world: *ecs.world_t) void {
    ecs.COMPONENT(world, scene.Camera);
    ecs.COMPONENT(world, scene.Mesh);
    ecs.COMPONENT(world, scene.Transform);
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
}