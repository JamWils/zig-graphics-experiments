const Self = @This();

x: f32,
y: f32,
z: f32,

pub fn init(x: f32, y: f32, z: f32) Self {
    return .{
        .x = x,
        .y = y,
        .z = z,
    };
}

pub fn zero() Self {
    return .{
        .x = 0,
        .y = 0,
        .z = 0,
    };
}