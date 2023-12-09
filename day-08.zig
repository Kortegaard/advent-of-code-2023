const std = @import("std");
const utils = @import("./utils.zig");
const print = std.debug.print;

const Direction = struct {
    //allocator: std.mem.Allocator,
    left: [3]u8,
    right: [3]u8,
};

pub fn main() !void {
    // Memory is a bit of a pain to destroy xD
    var ar = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = ar.deinit();
    var allocator = ar.allocator();

    var lineItt = try utils.ReaderFileByLine("./input/day-08-input.txt");
    defer lineItt.deinit();

    var directions: [501]u8 = undefined;

    var lineNum: u16 = 0;
    var directionHM = std.StringHashMap(Direction).init(allocator);
    defer directionHM.deinit();
    var ghosts = std.ArrayList([]u8).init(allocator);

    while (try lineItt.next()) |line| {
        lineNum += 1;
        if (lineNum == 1) {
            std.mem.copyForwards(u8, &directions, line);
            continue;
        }
        if (line.len == 0) {
            continue;
        }
        var left: [3]u8 = undefined;
        var right: [3]u8 = undefined;
        std.mem.copyForwards(u8, &left, line[7..10]);
        std.mem.copyForwards(u8, &right, line[12..15]);
        var d = Direction{ .left = left, .right = right };

        var name = try allocator.dupe(u8, line[0..3]);
        var n2 = try allocator.dupe(u8, line[0..3]);
        if (n2[2] == 'A') {
            try ghosts.append(n2);
        }

        try directionHM.putNoClobber(name, d);
    }

    var done = false;
    var numSteps: u32 = 0;
    var currLoc = [3]u8{ 'A', 'A', 'A' };
    while (!done) {
        var nn: u32 = 0;
        for (directions) |d| {
            var Dir = directionHM.get(&currLoc);
            if (Dir == null) {
                continue;
            }
            nn += 1;
            if (d == 'R') {
                currLoc = Dir.?.right;
            } else if (d == 'L') {
                currLoc = Dir.?.left;
            } else {
                break;
            }
            numSteps += 1;
            if (std.mem.startsWith(u8, &currLoc, "ZZZ")) {
                done = true;
            }
        }
    }

    done = false;
    var numStepsPart2: u64 = 0;
    var allEndInZ = false;
    var a = [_]u64{0} ** 10;
    var numFound: u8 = 0;
    while (!allEndInZ and numFound < ghosts.items.len) {
        var nn: u64 = 0;
        for (directions) |d| {
            if (d != 'R' and d != 'L') {
                break;
            }
            allEndInZ = true;
            numStepsPart2 += 1;
            for (ghosts.items, 0..) |ghost, i| {
                var Dir = directionHM.get(ghost);
                if (Dir == null) {
                    continue;
                }
                nn += 1;
                if (d == 'R') {
                    std.mem.copyForwards(u8, ghost, &Dir.?.right);
                } else if (d == 'L') {
                    std.mem.copyForwards(u8, ghost, &Dir.?.left);
                }
                if (ghost[2] == 'Z' and a[i] == 0) {
                    a[i] = numStepsPart2;
                    numFound += 1;
                }
                if (ghost[2] != 'Z') {
                    allEndInZ = false;
                }
            }
            if (allEndInZ) {
                break;
            }
        }
    }

    var part2Answer: u64 = 1;
    var i: u8 = 0;
    while (i < a.len) : (i += 1) {
        if (a[i] == 0) {
            break;
        }
        var m: u64 = part2Answer * a[i];
        var o: u64 = std.math.gcd(part2Answer, a[i]);
        part2Answer = @divExact(m, o);
    }

    print("Part 1: {d}\n", .{numSteps});
    print("Part 2: {d}\n", .{part2Answer});
}
