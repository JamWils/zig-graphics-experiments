const std = @import("std");

const c = @cImport({
    @cInclude("foo.h");
    @cInclude("sdl.h");
});

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!

    std.debug.print("the sum of x and y is: {d}\n", .{c.foo_add(20, 8)});
    std.debug.print("{d}", .{c.SDL_INIT_VIDEO});

    if (c.SDL_Init(c.SDL_INIT_VIDEO) < 0) {
        @panic("SDL init error");
    }
    defer c.SDL_Quit();

    const window = c.SDL_CreateWindow(
        "SDL2 Test", 
        c.SDL_WINDOWPOS_CENTERED, 
        c.SDL_WINDOWPOS_CENTERED, 
        800, 
        600, 
        c.SDL_WINDOW_SHOWN
        ) orelse @panic("Failed to create SDL window");

    c.SDL_Delay(3000);

    c.SDL_DestroyWindow(window);
    // c.SDL_Quit();


}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
