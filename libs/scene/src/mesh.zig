const zmath = @import("zmath");

pub const Vertex = struct {
    position: @Vector(3, f32),
    color: @Vector(3, f32),
};

pub const UBO = struct {
    model: zmath.Mat,
};

pub const Mesh = struct {
    vertices: []Vertex,
    indices: []u32,
    texture_id: u32,
    model: UBO = .{.model = zmath.identity()},
};

