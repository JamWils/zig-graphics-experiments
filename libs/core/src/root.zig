const std = @import("std");
const testing = std.testing;

pub const Allocator = struct {
    alloc: std.mem.Allocator,
};

pub const OnStop = extern struct {};

pub const CanvasSize = extern struct {
    width: c_int,
    height: c_int,
};