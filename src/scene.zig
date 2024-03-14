const std = @import("std");
const ecs = @import("flecs");
const scene = @import("scene");
const zmath = @import("zmath");
const app = @import("app.zig");

const CameraDeceleration: f32 = 70;
const CameraAcceleration: f32 = 50 + CameraDeceleration;
const CameraAngularDeceleration: f32 = 15;
const CameraAngularAcceleration: f32 = 5 + CameraAngularDeceleration;
const CameraMaxSpeed: f32 = 40;

const CameraController = struct {};

fn createCamera(it: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Create camera: {s}\n", .{ecs.get_name(it.world, it.system).?});
    const canvas_size = ecs.singleton_get(it.world, app.CanvasSize).?;

    const camera_entity = ecs.new_id(it.world);
    _ = ecs.add(it.world, camera_entity, scene.CameraController);
    _ = ecs.set(it.world, camera_entity, scene.Position, .{.x = 0, .y = 0, .z = 5});
    _ = ecs.set(it.world, camera_entity, scene.Orientation, .{.quat = zmath.qidentity()});
    _ = ecs.set(it.world, camera_entity, scene.Velocity, std.mem.zeroInit(scene.Velocity, .{}));
    _ = ecs.set(it.world, camera_entity, scene.AngularVelocity, std.mem.zeroInit(scene.AngularVelocity, .{}));

    const dimension: f32 = @as(f32, @floatFromInt(canvas_size.width)) / @as(f32, @floatFromInt(canvas_size.height));
    const projection: scene.Perspective = .{
        .fov = std.math.degreesToRadians(f32, 30), 
        .aspect = dimension, 
        .near = 0.1, 
        .far = 1000
    };
    _ = ecs.set(it.world, camera_entity, scene.Perspective, projection);

    var camera = scene.Camera{
        .view = zmath.lookAtRh(.{0, 0, 2, 1}, .{0, 0, 0, 1}, .{0, 1, 0, 1}),
        .projection = zmath.perspectiveFovRh(projection.fov, projection.aspect, projection.near, projection.far),
    };
    camera.projection[1][1] *= -1;
    _ = ecs.set(it.world, camera_entity, scene.Camera, camera);
}

fn updateCamera(it: *ecs.iter_t) callconv(.C) void {
    const input = ecs.singleton_get(it.world, scene.Input).?;
    const velocities = ecs.field(it, scene.Velocity, 1).?;
    const orientations = ecs.field(it, scene.Orientation, 2).?;
    const angular_velocities = ecs.field(it, scene.AngularVelocity, 3).?;
    
    for (orientations, velocities, angular_velocities, it.entities()) |orientation, v, av, e| {
        const mat = zmath.quatToMat(orientation.quat);
        const forward = zmath.Vec{mat[2][0], mat[2][1], mat[2][2], 1};
        const right = zmath.cross3(forward, zmath.Vec{0, 1, 0, 1});
        const up = zmath.cross3(right, forward);

        const acceleration = CameraAcceleration * it.delta_time;
        const angular_acceleration = CameraAngularAcceleration * it.delta_time;

        var vel = v;
        var angular_vel = av;

        if (input.keys[scene.KEY_W].state) {
            vel.x -= forward[0] * acceleration;
            vel.z -= forward[2] * acceleration;
        }
        if (input.keys[scene.KEY_S].state) {
            vel.x += forward[0] * acceleration;
            vel.z += forward[2] * acceleration;
        }
        if (input.keys[scene.KEY_A].state) {
            vel.x += right[0] * acceleration;
            vel.z += right[2] * acceleration;
        }
        if (input.keys[scene.KEY_D].state) {
            vel.x -= right[0] * acceleration;
            vel.z -= right[2] * acceleration;
        }

        if (input.keys[scene.KEY_Q].state) {
            vel.y -= up[1] * acceleration;
        }
        if (input.keys[scene.KEY_E].state) {
            vel.y += up[1] * acceleration;
        }

        if (input.keys[scene.KEY_LEFT].state) {
            angular_vel.y += angular_acceleration;
        }
        if (input.keys[scene.KEY_RIGHT].state) {
            angular_vel.y -= angular_acceleration;
        }

        if (input.keys[scene.KEY_UP].state) {
            angular_vel.x -= angular_acceleration;
        }
        if (input.keys[scene.KEY_DOWN].state) {
            angular_vel.x += angular_acceleration;
        }

        _ = ecs.set(it.world, e, scene.Velocity, vel);
        _ = ecs.set(it.world, e, scene.AngularVelocity, angular_vel);
    }

}

fn cameraControllerDecel(a: f32, dt: f32, v: f32) f32 {
    if (v > 0) {
        return std.math.clamp(v - a * dt, 0, v);
    }
    if (v < 0) {
        return std.math.clamp(v + a * dt, v, 0);
    }
    return v;
}

fn cameraControllerDecelerate(it: *ecs.iter_t) callconv(.C) void {
    const velocities = ecs.field(it, scene.Velocity, 1).?;
    const angular_velocities = ecs.field(it, scene.AngularVelocity, 2).?;
    const orientations = ecs.field(it, scene.Orientation, 3).?;

    const dt = it.delta_time;

    for (velocities, angular_velocities, orientations, it.entities()) |vel, ang_vel, orientation, e| {
        const v: zmath.Vec = .{vel.x, vel.y, vel.z, 1};
        const vel_normalized = zmath.normalize3(v);

        // TODO: Fix the camera speed
        // const speed = zmath.length3(v);

        // if (speed > CameraMaxSpeed) {
        //     v = v * (CameraMaxSpeed / speed);
        // }

        const new_velocity = scene.Velocity{
            .x = cameraControllerDecel(CameraDeceleration * zmath.abs(vel_normalized[0]), dt, v[0]),
            .y = cameraControllerDecel(CameraDeceleration * zmath.abs(vel_normalized[1]), dt, v[1]),
            .z = cameraControllerDecel(CameraDeceleration * zmath.abs(vel_normalized[2]), dt, v[2]),
        };
        _ = ecs.set(it.world, e, scene.Velocity, new_velocity);

        var new_ang_velocity = scene.AngularVelocity {
            .x = cameraControllerDecel(CameraAngularDeceleration, dt, ang_vel.x),
            .y = cameraControllerDecel(CameraAngularDeceleration, dt, ang_vel.y),
            .z = 0,
        };

        // TODO: This is a hack to prevent the camera from flipping over, but it's not a good solution
        const rot = zmath.quatToRollPitchYaw(orientation.quat);
        if (rot[1] > std.math.pi / 2.0) {
            new_ang_velocity.x -= 0.00001;
        }

        if (rot[1] < -std.math.pi / 2.0) {
            new_ang_velocity.x -= 0.00001;
        }

        _ = ecs.set(it.world, e, scene.AngularVelocity, new_ang_velocity);
    }
}

fn applyVelocityToPosition(it: *ecs.iter_t) callconv(.C) void {
    const positions = ecs.field(it, scene.Position, 1).?;
    const velocities = ecs.field(it, scene.Velocity, 2).?;

    for (positions, velocities, it.entities()) |pos, vel, e| {
        _ = ecs.set(it.world, e, scene.Position, .{
            .x = pos.x + vel.x * it.delta_time,
            .y = pos.y + vel.y * it.delta_time,
            .z = pos.z + vel.z * it.delta_time,
        });
    }
}

fn applyAngularVelocityToRotation(it: *ecs.iter_t) callconv(.C) void {
    const rotations = ecs.field(it, scene.Orientation, 1).?;
    const angular_velocities = ecs.field(it, scene.AngularVelocity, 2).?;

    for (rotations, angular_velocities, it.entities()) |rot, ang_vel, e| {
        const delta_quat_x = zmath.quatFromAxisAngle(.{1, 0, 0, 1}, ang_vel.x * it.delta_time);
        const delta_quat_y = zmath.quatFromAxisAngle(.{0, 1, 0, 1}, ang_vel.y * it.delta_time);
        const delta_quat = zmath.qmul(delta_quat_x, delta_quat_y);
        const new_rot = zmath.qmul(rot.quat, delta_quat);
        _ = ecs.set(it.world, e, scene.Orientation, .{
            .quat = new_rot,
        });
    }
}

fn calculateViewProjection(it: *ecs.iter_t) callconv(.C) void {
    const positions = ecs.field(it, scene.Position, 1).?;
    const orientations = ecs.field(it, scene.Orientation, 2).?;
    const perspectives = ecs.field(it, scene.Perspective, 3).?;

    for (positions, orientations, perspectives) |pos, orientation, pers| {
        const rot_mat = zmath.quatToMat(orientation.quat);
        const pos_mat = zmath.translation(-pos.x, -pos.y, -pos.z);
        const view_mat = zmath.mul(rot_mat, pos_mat);

        const look_at = -zmath.Vec{view_mat[2][0], view_mat[2][1], view_mat[2][2], 1};
        const adjusted_look_at = zmath.Vec {pos.x, pos.y, pos.z, 1} + look_at;

        var camera = scene.Camera{
            .view = zmath.lookAtRh(.{pos.x, pos.y, pos.z, 1}, adjusted_look_at, .{0, 1, 0, 1}),
            .projection = zmath.perspectiveFovRh(pers.fov, pers.aspect, pers.near, pers.far),
        };
        camera.projection[1][1] *= -1;

        _ = ecs.set(it.world, it.system, scene.Camera, camera);
    }

}

fn simpleSceneSetUp(it: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Start up: {s}\n", .{ecs.get_name(it.world, it.system).?});
    const allocator = ecs.singleton_get(it.world, app.Allocator).?;

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
    ecs.COMPONENT(world, scene.Position);
    ecs.COMPONENT(world, scene.Orientation);
    ecs.COMPONENT(world, scene.Velocity);
    ecs.COMPONENT(world, scene.AngularVelocity);
    ecs.COMPONENT(world, scene.Transform);
    ecs.COMPONENT(world, scene.Speed);
    ecs.COMPONENT(world, scene.Perspective);
    ecs.TAG(world, scene.CameraController);
    ecs.TAG(world, scene.UpdateBuffer);

    var camera_desc = ecs.system_desc_t{};
    camera_desc.callback = createCamera;
    camera_desc.query.filter.terms[0] = .{ 
        .id = ecs.id(app.CanvasSize), 
        .src = .{
            .id = ecs.id(app.CanvasSize), 
        },
    };
    ecs.SYSTEM(world, "CreateCamera", ecs.OnStart, &camera_desc);

    var simple_scene_desc = ecs.system_desc_t{};
    simple_scene_desc.callback = simpleSceneSetUp;
    simple_scene_desc.query.filter.terms[0] = .{ 
        .id = ecs.id(app.Allocator),
        .src = .{ .id = ecs.id(app.Allocator) },
    };
    ecs.SYSTEM(world, "SimpleSceneSetUp", ecs.OnStart, &simple_scene_desc);

    var update_camera_desc = ecs.system_desc_t{};
    update_camera_desc.callback = updateCamera;
    update_camera_desc.query.filter.terms[0] = .{ .id = ecs.id(scene.Velocity), .inout = ecs.inout_kind_t.InOut, };
    update_camera_desc.query.filter.terms[1] = .{ .id = ecs.id(scene.Orientation), .inout = ecs.inout_kind_t.In, };
    update_camera_desc.query.filter.terms[2] = .{ .id = ecs.id(scene.AngularVelocity), .inout = ecs.inout_kind_t.InOut, };
    update_camera_desc.query.filter.terms[4] = .{ .id = ecs.id(scene.CameraController), .inout = ecs.inout_kind_t.InOutNone, };
    ecs.SYSTEM(world, "UpdateCamera", ecs.OnUpdate, &update_camera_desc);

    var camera_controller_decel_desc = ecs.system_desc_t{};
    camera_controller_decel_desc.callback = cameraControllerDecelerate;
    camera_controller_decel_desc.query.filter.terms[0] = .{ .id = ecs.id(scene.Velocity), .inout = ecs.inout_kind_t.InOut, };
    camera_controller_decel_desc.query.filter.terms[1] = .{ .id = ecs.id(scene.AngularVelocity), .inout = ecs.inout_kind_t.InOut, };
    camera_controller_decel_desc.query.filter.terms[2] = .{ .id = ecs.id(scene.Orientation), .inout = ecs.inout_kind_t.In, };
    camera_controller_decel_desc.query.filter.terms[3] = .{ .id = ecs.id(scene.CameraController), .inout = ecs.inout_kind_t.InOutNone, };
    ecs.SYSTEM(world, "CameraControllerDecelerate", ecs.OnUpdate, &camera_controller_decel_desc);

    var apply_velocity_to_position_desc = ecs.system_desc_t{};
    apply_velocity_to_position_desc.callback = applyVelocityToPosition;
    apply_velocity_to_position_desc.query.filter.terms[0] = .{ .id = ecs.id(scene.Position), .inout = ecs.inout_kind_t.InOut, };
    apply_velocity_to_position_desc.query.filter.terms[1] = .{ .id = ecs.id(scene.Velocity), .inout = ecs.inout_kind_t.In, };
    ecs.SYSTEM(world, "ApplyVelocityToPosition", ecs.OnUpdate, &apply_velocity_to_position_desc);

    var apply_angular_velocity_to_rotation_desc = ecs.system_desc_t{};
    apply_angular_velocity_to_rotation_desc.callback = applyAngularVelocityToRotation;
    apply_angular_velocity_to_rotation_desc.query.filter.terms[0] = .{ .id = ecs.id(scene.Orientation), .inout = ecs.inout_kind_t.InOut, };
    apply_angular_velocity_to_rotation_desc.query.filter.terms[1] = .{ .id = ecs.id(scene.AngularVelocity), .inout = ecs.inout_kind_t.In, };
    ecs.SYSTEM(world, "ApplyAngularVelocityToRotation", ecs.OnUpdate, &apply_angular_velocity_to_rotation_desc);

    var calculate_view_projection_desc = ecs.system_desc_t{};
    calculate_view_projection_desc.callback = calculateViewProjection;
    calculate_view_projection_desc.query.filter.terms[0] = .{ .id = ecs.id(scene.Position), .inout = ecs.inout_kind_t.In, };
    calculate_view_projection_desc.query.filter.terms[1] = .{ .id = ecs.id(scene.Orientation), .inout = ecs.inout_kind_t.In, };
    calculate_view_projection_desc.query.filter.terms[2] = .{ .id = ecs.id(scene.Perspective), .inout = ecs.inout_kind_t.In, };
    calculate_view_projection_desc.query.filter.terms[3] = .{ .id = ecs.id(scene.Camera), .inout = ecs.inout_kind_t.Out, };
    ecs.SYSTEM(world, "CalculateViewProjection", ecs.OnUpdate, &calculate_view_projection_desc);

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