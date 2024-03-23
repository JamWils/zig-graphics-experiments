const zmath = @import("zmath");

pub const Light = struct {
    color: @Vector(4, f32),
    direction: @Vector(4, f32),
    ambientIntensity: f32,
    diffuseIntensity: f32,
};