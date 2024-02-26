const std = @import("std");

const c = @cImport({
    @cInclude("hello.h");
});

pub fn main() !void {
    c.createStage();
}
