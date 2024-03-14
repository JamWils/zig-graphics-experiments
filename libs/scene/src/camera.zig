const zmath = @import("zmath");

pub const LookAt = struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
};

pub const CameraController = struct {};

pub const Perspective = struct {
    /// Field of view in radians
    fov: f32,

    /// Aspect ratio
    aspect: f32,

    /// Near clipping plane
    near: f32,

    /// Far clipping plane
    far: f32,
};

pub const Camera = struct {
    /// Position of the camera
    view: zmath.Mat,

    /// Perspective of the camera
    projection: zmath.Mat,
};