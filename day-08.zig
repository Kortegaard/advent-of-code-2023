const std = @import("std");
const utils = @import("./utils.zig");
const print = std.debug.print;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const Direction = struct {
    left: [3]u8,
    right: [3]u8,
};

pub fn main() !void {
    defer _ = gpa.deinit();

    var lineItt = try utils.ReaderFileByLine("./input/day-08-input.txt");
    defer lineItt.deinit();

    var directions: [500]u8 = undefined;

    var lineNum: u16 = 0;
    var directionHM = std.StringHashMap(*Direction).init(gpa.allocator());
    defer directionHM.deinit();
    while (try lineItt.next()) |line| {
        lineNum += 1;
        if (lineNum == 1) {
            std.mem.copyForwards(u8, &directions, line);
            continue;
        }
        if (line.len == 0) {
            continue;
        }
        var d: *Direction = try gpa.allocator().create(Direction);
        std.mem.copyForwards(u8, &d.left, line[7..10]);
        std.mem.copyForwards(u8, &d.right, line[12..15]);
        var ke = [3]u8{ line[0], line[1], line[2] };
        print("{s}, {s}, {s}\n", .{ line[0..3], line[7..10], line[12..15] });
        try directionHM.put(&ke, d);
    }

    print("\n", .{});
    print("Part 1: {d}\n", .{0});
    print("Part 2: {?}\n", .{0});
}
