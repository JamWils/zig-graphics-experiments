const zmath = @import("zmath");

pub const MVP = struct {
    model: zmath.Mat,
    view: zmath.Mat,
    projection: zmath.Mat,
};