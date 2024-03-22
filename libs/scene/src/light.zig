const zmath = @import("zmath");

pub const Light = struct {
    color: zmath.Vec,
    ambientIntensity: f32,
};

pub fn newLight(red: f32, green: f32, blue: f32, ambientIntensity: f32) Light {
    return Light {
        .color = .{red, green, blue, 1},
        .ambientIntensity = ambientIntensity,
    };
}