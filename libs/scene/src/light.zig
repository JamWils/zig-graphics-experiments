const zmath = @import("zmath");

pub const Light = packed struct {
    color: @Vector(3, f32),
    direction: @Vector(3, f32),
    ambientIntensity: f32,
    diffuseIntensity: f32,
};