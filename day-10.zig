const std = @import("std");
const utils = @import("./utils.zig");
const print = std.debug.print;

pub fn main() !void {
    // Memory is a bit of a pain to destroy xD
    var ar = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = ar.deinit();
    var allocator = ar.allocator();
    _ = allocator;

    var lineItt = try utils.ReaderFileByLine("./input/day-10-input-example.txt");
    defer lineItt.deinit();

    while (try lineItt.next()) |line| {
        _ = line;
    }

    print("Part 1: {d}\n", .{0});
    print("Part 2: {d}\n", .{0});
}
