const zmath = @import("zmath");



pub const Camera = struct {
    view: zmath.Mat,
    projection: zmath.Mat,
};