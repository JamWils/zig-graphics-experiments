const std = @import("std");
const core = @import("core");
const ecs = @import("flecs");
const zmath = @import("zmath");
const mesh = @import("mesh.zig");
const transform = @import("transform.zig");
const ux = @import("input.zig");
const Camera = @import("camera.zig").Camera;
const Perspective = @import("camera.zig").Perspective;
const Light = @import("light.zig").Light;

const CameraDeceleration: f32 = 70;
const CameraAcceleration: f32 = 50 + CameraDeceleration;
const CameraAngularDeceleration: f32 = 15;
const CameraAngularAcceleration: f32 = 5 + CameraAngularDeceleration;
const CameraMaxSpeed: f32 = 40;

const CameraController = struct {};

fn createCamera(it: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Create camera: {s}\n", .{ecs.get_name(it.world, it.system).?});
    const canvas_size = ecs.singleton_get(it.world, core.CanvasSize).?;

    const camera_entity = ecs.new_id(it.world);
    _ = ecs.add(it.world, camera_entity, CameraController);
    _ = ecs.set(it.world, camera_entity, transform.Position, .{ .x = 0, .y = 0.1, .z = 5 });
    _ = ecs.set(it.world, camera_entity, transform.Orientation, .{ .quat = zmath.qidentity() });
    _ = ecs.set(it.world, camera_entity, transform.Velocity, std.mem.zeroInit(transform.Velocity, .{}));
    _ = ecs.set(it.world, camera_entity, transform.AngularVelocity, std.mem.zeroInit(transform.AngularVelocity, .{}));

    const dimension: f32 = @as(f32, @floatFromInt(canvas_size.width)) / @as(f32, @floatFromInt(canvas_size.height));
    const projection: Perspective = .{ .fov = std.math.degreesToRadians(f32, 30), .aspect = dimension, .near = 0.1, .far = 1000 };
    _ = ecs.set(it.world, camera_entity, Perspective, projection);

    var camera = Camera{
        .view = zmath.lookAtRh(.{ 0, 0, 2, 1 }, .{ 0, 0, 0, 1 }, .{ 0, 1, 0, 1 }),
        .projection = zmath.perspectiveFovRh(projection.fov, projection.aspect, projection.near, projection.far),
    };
    camera.projection[1][1] *= -1;
    _ = ecs.set(it.world, camera_entity, Camera, camera);

    _ = ecs.set(it.world, camera_entity, Light, .{
        .color = .{ 1, 1, 1, 1 },
        .direction = .{ 0.0, 0.4, 1.0, 1.0 },
        .ambientIntensity = 0.4,
        .diffuseIntensity = 0.8,
    });
}

fn updateCamera(it: *ecs.iter_t) callconv(.C) void {
    // std.debug.print("Update camera: {s}\n", .{ecs.get_name(it.world, it.system).?});
    const input = ecs.singleton_get(it.world, ux.Input).?;
    const velocities = ecs.field(it, transform.Velocity, 1).?;
    const orientations = ecs.field(it, transform.Orientation, 2).?;
    const angular_velocities = ecs.field(it, transform.AngularVelocity, 3).?;

    for (orientations, velocities, angular_velocities, it.entities()) |orientation, v, av, e| {
        const mat = zmath.quatToMat(orientation.quat);
        const forward = zmath.Vec{ mat[2][0], mat[2][1], mat[2][2], 1 };
        const right = zmath.cross3(forward, zmath.Vec{ 0, 1, 0, 1 });
        const up = zmath.cross3(right, forward);

        const acceleration = CameraAcceleration * it.delta_time;
        const angular_acceleration = CameraAngularAcceleration * it.delta_time;

        var vel = v;
        var angular_vel = av;

        if (input.keys[ux.KEY_W].state) {
            vel.x -= forward[0] * acceleration;
            vel.z -= forward[2] * acceleration;
        }
        if (input.keys[ux.KEY_S].state) {
            vel.x += forward[0] * acceleration;
            vel.z += forward[2] * acceleration;
        }
        if (input.keys[ux.KEY_A].state) {
            vel.x += right[0] * acceleration;
            vel.z += right[2] * acceleration;
        }
        if (input.keys[ux.KEY_D].state) {
            vel.x -= right[0] * acceleration;
            vel.z -= right[2] * acceleration;
        }

        if (input.keys[ux.KEY_Q].state) {
            vel.y -= up[1] * acceleration;
        }
        if (input.keys[ux.KEY_E].state) {
            vel.y += up[1] * acceleration;
        }

        if (input.keys[ux.KEY_LEFT].state) {
            angular_vel.y += angular_acceleration;
        }
        if (input.keys[ux.KEY_RIGHT].state) {
            angular_vel.y -= angular_acceleration;
        }

        if (input.keys[ux.KEY_UP].state) {
            angular_vel.x += angular_acceleration;
        }
        if (input.keys[ux.KEY_DOWN].state) {
            angular_vel.x -= angular_acceleration;
        }

        _ = ecs.set(it.world, e, transform.Velocity, vel);
        _ = ecs.set(it.world, e, transform.AngularVelocity, angular_vel);
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
    const velocities = ecs.field(it, transform.Velocity, 1).?;
    const angular_velocities = ecs.field(it, transform.AngularVelocity, 2).?;
    const orientations = ecs.field(it, transform.Orientation, 3).?;

    const dt = it.delta_time;

    for (velocities, angular_velocities, orientations, it.entities()) |vel, ang_vel, orientation, e| {
        const v: zmath.Vec = .{ vel.x, vel.y, vel.z, 1 };
        const vel_normalized = zmath.normalize3(v);

        // TODO: Fix the camera speed
        // const speed = zmath.length3(v);

        // if (speed > CameraMaxSpeed) {
        //     v = v * (CameraMaxSpeed / speed);
        // }

        const new_velocity = transform.Velocity{
            .x = cameraControllerDecel(CameraDeceleration * zmath.abs(vel_normalized[0]), dt, v[0]),
            .y = cameraControllerDecel(CameraDeceleration * zmath.abs(vel_normalized[1]), dt, v[1]),
            .z = cameraControllerDecel(CameraDeceleration * zmath.abs(vel_normalized[2]), dt, v[2]),
        };
        _ = ecs.set(it.world, e, transform.Velocity, new_velocity);

        var new_ang_velocity = transform.AngularVelocity{
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

        _ = ecs.set(it.world, e, transform.AngularVelocity, new_ang_velocity);
    }
}

fn applyVelocityToPosition(it: *ecs.iter_t) callconv(.C) void {
    const positions = ecs.field(it, transform.Position, 1).?;
    const velocities = ecs.field(it, transform.Velocity, 2).?;

    for (positions, velocities, it.entities()) |pos, vel, e| {
        _ = ecs.set(it.world, e, transform.Position, .{
            .x = pos.x + vel.x * it.delta_time,
            .y = pos.y + vel.y * it.delta_time,
            .z = pos.z + vel.z * it.delta_time,
        });
    }
}

fn applyAngularVelocityToRotation(it: *ecs.iter_t) callconv(.C) void {
    const rotations = ecs.field(it, transform.Orientation, 1).?;
    const angular_velocities = ecs.field(it, transform.AngularVelocity, 2).?;

    for (rotations, angular_velocities, it.entities()) |rot, ang_vel, e| {
        const delta_quat_x = zmath.quatFromAxisAngle(.{ 1, 0, 0, 1 }, ang_vel.x * it.delta_time);
        const delta_quat_y = zmath.quatFromAxisAngle(.{ 0, 1, 0, 1 }, ang_vel.y * it.delta_time);
        const delta_quat = zmath.qmul(delta_quat_x, delta_quat_y);
        const new_rot = zmath.qmul(rot.quat, delta_quat);
        _ = ecs.set(it.world, e, transform.Orientation, .{
            .quat = new_rot,
        });
    }
}

fn calculateViewProjection(it: *ecs.iter_t) callconv(.C) void {
    // std.debug.print("Calculate view projection: {s}\n", .{ecs.get_name(it.world, it.system).?});
    const positions = ecs.field(it, transform.Position, 1).?;
    const orientations = ecs.field(it, transform.Orientation, 2).?;
    const perspectives = ecs.field(it, Perspective, 3).?;

    for (positions, orientations, perspectives, it.entities()) |pos, orientation, pers, e| {
        const rot_mat = zmath.quatToMat(orientation.quat);
        const pos_mat = zmath.translation(-pos.x, -pos.y, -pos.z);
        const view_mat = zmath.mul(rot_mat, pos_mat);

        const look_at = -zmath.Vec{ view_mat[2][0], view_mat[2][1], view_mat[2][2], 1 };
        const adjusted_look_at = zmath.Vec{ pos.x, pos.y, pos.z, 1 } + look_at;

        var camera = Camera{
            .view = zmath.lookAtRh(.{ pos.x, pos.y, pos.z, 1 }, adjusted_look_at, .{ 0, 1, 0, 1 }),
            .projection = zmath.perspectiveFovRh(pers.fov, pers.aspect, pers.near, pers.far),
        };
        camera.projection[1][1] *= -1;

        _ = ecs.set(it.world, e, Camera, camera);
    }
}

fn simpleSceneSetUp(it: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Start up: {s}\n", .{ecs.get_name(it.world, it.system).?});
    const allocator = ecs.singleton_get(it.world, core.Allocator).?;

    const vertices = [_]mesh.Vertex{
        .{
            .position = .{ -0.4, 0.4, 0.0 },
            .color = .{ 1, 0, 0 },
            .normal = .{ 0, 0, -1 },
            .uv = .{ 1, 1 },
        },
        .{
            .position = .{ -0.4, -0.4, 0.0 },
            .color = .{ 0, 1, 0 },
            .normal = .{ 0, 0, -1 },
            .uv = .{ 1, 0 },
        },
        .{
            .position = .{ 0.4, -0.4, 0.0 },
            .color = .{ 0, 0, 1 },
            .normal = .{ 0, 0, -1 },
            .uv = .{ 0, 0 },
        },
        .{
            .position = .{ 0.4, 0.4, 0.0 },
            .color = .{ 1, 1, 0 },
            .normal = .{ 0, 0, -1 },
            .uv = .{ 0, 1 },
        },
    };

    const vertices_two = [_]mesh.Vertex{
        .{
            .position = .{ -0.25, 0.6, 0.0 },
            .color = .{ 1, 0, 0 },
            .normal = .{ 0, 0, 1 },
            .uv = .{ 1, 1 },
        },
        .{
            .position = .{ -0.25, -0.6, 0.0 },
            .color = .{ 1, 1, 0 },
            .normal = .{ 0, 0, 1 },
            .uv = .{ 1, 0 },
        },
        .{
            .position = .{ 0.25, -0.6, 0.0 },
            .color = .{ 1, 0, 1 },
            .normal = .{ 0, 0, 1 },
            .uv = .{ 0, 0 },
        },
        .{
            .position = .{ 0.25, 0.6, 0.0 },
            .color = .{ 1, 1, 0 },
            .normal = .{ 0, 0, 1 },
            .uv = .{ 0, 1 },
        },
    };

    const indices = [_]u32{
        0, 1, 2,
        2, 3, 0,
    };

    const first_mesh = mesh.Mesh{
        .vertices = allocator.alloc.dupe(mesh.Vertex, vertices[0..]) catch @panic("Out of memory"),
        .indices = allocator.alloc.dupe(u32, indices[0..]) catch @panic("Out of memory"),
        .texture_id = 0,
    };

    const second_mesh = mesh.Mesh{
        .vertices = allocator.alloc.dupe(mesh.Vertex, vertices_two[0..]) catch @panic("Out of memory"),
        .indices = allocator.alloc.dupe(u32, indices[0..]) catch @panic("Out of memory"),
        .texture_id = 0,
    };

    const entity = ecs.new_id(it.world);
    _ = ecs.add(it.world, entity, mesh.UpdateBuffer);
    _ = ecs.set(it.world, entity, mesh.Mesh, first_mesh);
    _ = ecs.set(it.world, entity, transform.Speed, transform.Speed{ .value = 20 });

    var t1 = zmath.identity();
    t1 = zmath.mul(zmath.translationV(.{ 0, 0, -4.5, 1 }), t1);
    _ = ecs.set(it.world, entity, transform.Transform, transform.Transform{
        .value = t1,
    });

    const entity2 = ecs.new_id(it.world);
    _ = ecs.add(it.world, entity2, mesh.UpdateBuffer);
    _ = ecs.set(it.world, entity2, mesh.Mesh, second_mesh);
    _ = ecs.set(it.world, entity2, transform.Speed, transform.Speed{ .value = 50 });

    var t2 = zmath.identity();
    t2 = zmath.mul(zmath.translationV(.{ 0, 0, -8, 1 }), t2);
    _ = ecs.set(it.world, entity2, transform.Transform, transform.Transform{
        .value = t2,
    });
}

fn cleanUpMeshAllocations(it: *ecs.iter_t) callconv(.C) void {
    std.debug.print("Clean up: {s}\n", .{ecs.get_name(it.world, it.system).?});
    const allocator = ecs.singleton_get(it.world, core.Allocator).?;
    const meshes = ecs.field(it, mesh.Mesh, 1).?;

    for (meshes) |m| {
        allocator.alloc.free(m.vertices);
        allocator.alloc.free(m.indices);
    }
}

fn spinTransform(it: *ecs.iter_t) callconv(.C) void {
    const transforms = ecs.field(it, transform.Transform, 1).?;
    const speeds = ecs.field(it, transform.Speed, 2).?;

    for (transforms, speeds, it.entities()) |t, speed, e| {
        const newValue = zmath.mul(zmath.rotationZ(std.math.degreesToRadians(f32, it.delta_time * speed.value)), t.value);
        _ = ecs.set(it.world, e, transform.Transform, .{
            .value = newValue,
        });
    }
}

pub fn init(world: *ecs.world_t) void {
    ecs.COMPONENT(world, Camera);
    ecs.COMPONENT(world, Light);
    ecs.COMPONENT(world, mesh.Mesh);
    ecs.COMPONENT(world, transform.Position);
    ecs.COMPONENT(world, transform.Orientation);
    ecs.COMPONENT(world, transform.Velocity);
    ecs.COMPONENT(world, transform.AngularVelocity);
    ecs.COMPONENT(world, transform.Transform);
    ecs.COMPONENT(world, transform.Speed);
    ecs.COMPONENT(world, Perspective);
    ecs.TAG(world, CameraController);
    ecs.TAG(world, mesh.UpdateBuffer);

    var camera_desc = ecs.system_desc_t{};
    camera_desc.callback = createCamera;
    camera_desc.query.filter.terms[0] = .{
        .id = ecs.id(core.CanvasSize),
        .src = .{
            .id = ecs.id(core.CanvasSize),
        },
    };
    ecs.SYSTEM(world, "CreateCamera", ecs.OnStart, &camera_desc);

    var simple_scene_desc = ecs.system_desc_t{};
    simple_scene_desc.callback = simpleSceneSetUp;
    simple_scene_desc.query.filter.terms[0] = .{
        .id = ecs.id(core.Allocator),
        .src = .{ .id = ecs.id(core.Allocator) },
    };
    ecs.SYSTEM(world, "SimpleSceneSetUp", ecs.OnStart, &simple_scene_desc);

    var update_camera_desc = ecs.system_desc_t{};
    update_camera_desc.callback = updateCamera;
    update_camera_desc.query.filter.terms[0] = .{
        .id = ecs.id(transform.Velocity),
        .inout = ecs.inout_kind_t.InOut,
    };
    update_camera_desc.query.filter.terms[1] = .{
        .id = ecs.id(transform.Orientation),
        .inout = ecs.inout_kind_t.In,
    };
    update_camera_desc.query.filter.terms[2] = .{
        .id = ecs.id(transform.AngularVelocity),
        .inout = ecs.inout_kind_t.InOut,
    };
    update_camera_desc.query.filter.terms[4] = .{
        .id = ecs.id(CameraController),
        .inout = ecs.inout_kind_t.InOutNone,
    };
    ecs.SYSTEM(world, "UpdateCamera", ecs.OnUpdate, &update_camera_desc);

    var camera_controller_decel_desc = ecs.system_desc_t{};
    camera_controller_decel_desc.callback = cameraControllerDecelerate;
    camera_controller_decel_desc.query.filter.terms[0] = .{
        .id = ecs.id(transform.Velocity),
        .inout = ecs.inout_kind_t.InOut,
    };
    camera_controller_decel_desc.query.filter.terms[1] = .{
        .id = ecs.id(transform.AngularVelocity),
        .inout = ecs.inout_kind_t.InOut,
    };
    camera_controller_decel_desc.query.filter.terms[2] = .{
        .id = ecs.id(transform.Orientation),
        .inout = ecs.inout_kind_t.In,
    };
    camera_controller_decel_desc.query.filter.terms[3] = .{
        .id = ecs.id(CameraController),
        .inout = ecs.inout_kind_t.InOutNone,
    };
    ecs.SYSTEM(world, "CameraControllerDecelerate", ecs.OnUpdate, &camera_controller_decel_desc);

    var apply_velocity_to_position_desc = ecs.system_desc_t{};
    apply_velocity_to_position_desc.callback = applyVelocityToPosition;
    apply_velocity_to_position_desc.query.filter.terms[0] = .{
        .id = ecs.id(transform.Position),
        .inout = ecs.inout_kind_t.InOut,
    };
    apply_velocity_to_position_desc.query.filter.terms[1] = .{
        .id = ecs.id(transform.Velocity),
        .inout = ecs.inout_kind_t.In,
    };
    ecs.SYSTEM(world, "ApplyVelocityTo.Position", ecs.OnUpdate, &apply_velocity_to_position_desc);

    var apply_angular_velocity_to_rotation_desc = ecs.system_desc_t{};
    apply_angular_velocity_to_rotation_desc.callback = applyAngularVelocityToRotation;
    apply_angular_velocity_to_rotation_desc.query.filter.terms[0] = .{
        .id = ecs.id(transform.Orientation),
        .inout = ecs.inout_kind_t.InOut,
    };
    apply_angular_velocity_to_rotation_desc.query.filter.terms[1] = .{
        .id = ecs.id(transform.AngularVelocity),
        .inout = ecs.inout_kind_t.In,
    };
    ecs.SYSTEM(world, "ApplyAngularVelocityToRotation", ecs.OnUpdate, &apply_angular_velocity_to_rotation_desc);

    var calculate_view_projection_desc = ecs.system_desc_t{};
    calculate_view_projection_desc.callback = calculateViewProjection;
    calculate_view_projection_desc.query.filter.terms[0] = .{
        .id = ecs.id(transform.Position),
        .inout = ecs.inout_kind_t.In,
    };
    calculate_view_projection_desc.query.filter.terms[1] = .{
        .id = ecs.id(transform.Orientation),
        .inout = ecs.inout_kind_t.In,
    };
    calculate_view_projection_desc.query.filter.terms[2] = .{
        .id = ecs.id(Perspective),
        .inout = ecs.inout_kind_t.In,
    };
    calculate_view_projection_desc.query.filter.terms[3] = .{
        .id = ecs.id(Camera),
        .inout = ecs.inout_kind_t.Out,
    };
    ecs.SYSTEM(world, "CalculateViewProjection", ecs.OnUpdate, &calculate_view_projection_desc);

    var spin_transform_desc = ecs.system_desc_t{};
    spin_transform_desc.callback = spinTransform;
    spin_transform_desc.query.filter.terms[0] = .{
        .id = ecs.id(transform.Transform),
        .inout = ecs.inout_kind_t.InOut,
    };
    spin_transform_desc.query.filter.terms[1] = .{
        .id = ecs.id(transform.Speed),
        .inout = ecs.inout_kind_t.In,
    };
    ecs.SYSTEM(world, "SpinTransform", ecs.OnUpdate, &spin_transform_desc);

    var clean_up_mesh_allocations_desc = ecs.system_desc_t{};
    clean_up_mesh_allocations_desc.callback = cleanUpMeshAllocations;
    clean_up_mesh_allocations_desc.query.filter.terms[0] = .{
        .id = ecs.id(mesh.Mesh),
        .inout = ecs.inout_kind_t.InOut,
    };
    ecs.SYSTEM(world, "CleanUpMeshAllocations", ecs.id(core.OnStop), &clean_up_mesh_allocations_desc);
}
