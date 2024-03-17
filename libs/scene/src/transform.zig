const zmath = @import("zmath");

pub const Position = struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
};

pub const Scale = struct {
    x: f32 = 1,
    y: f32 = 1,
    z: f32 = 1,
};

pub const Velocity = struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
};

pub const AngularVelocity = struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
};

pub const Orientation = struct {
    quat: zmath.Quat
};

pub const Transform = struct {
    value: zmath.Mat
};

pub const Speed = struct {
    value: f32 = 0,
};