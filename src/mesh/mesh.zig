pub const Vertex = struct {
    position: @Vector(3, f32),
    color: @Vector(3, f32),
};

pub const Mesh = struct {
    vertices: []Vertex,
    indices: []u32,
};