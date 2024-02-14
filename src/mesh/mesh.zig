const vec3 = @import("../glmath/vec3.zig");

pub const Vertex = struct {
    position: vec3,
    color: vec3,
};

pub const Mesh = struct {
    vertices: []Vertex,
};