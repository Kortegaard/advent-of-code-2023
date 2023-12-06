/// Plan of attack:
///
/// Given a race with times t, acceleration a, and holding time t_h,
/// you can calculate the distance by
/// distance = a * t_h * (t - t_h)
///
/// Using this we can simply check when it is greater than the record
/// by running through all the differen holding times possible.
///
/// ---
///
/// Ways of improving:
/// Notice that time is given by a quadratic equation, and we can
/// differentiate it to see its max value it halfway through.
/// So we could simply start checking the time t_h = t/2,
/// and make a kind of binary search for the two end points.
///
const std = @import("std");
const print = std.debug.print;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub fn pow(a: u64, b: u64) u64 {
    var i: u64 = 0;
    var mult: u64 = 1;
    while (i < b) : (i += 1) {
        mult = mult * a;
    }
    return mult;
}

pub fn calcDistance(time: u64, holdingTime: u64, acceleration: u64) u64 {
    return holdingTime * acceleration * (time - holdingTime);
}

pub fn findWinningRangeLin(time: u64, recordDist: u64, acceleration: u64) u64 {
    var lowestTimeBetter: ?u64 = null;
    var i: u64 = 0;
    while (i <= time) : (i += 1) {
        if (calcDistance(time, i, acceleration) <= recordDist) {
            if (lowestTimeBetter) |ltb| {
                return i - ltb;
            }
            continue;
        }
        if (lowestTimeBetter == null) {
            lowestTimeBetter = i;
        }
    }
    if (lowestTimeBetter) |ltb| {
        return time + 1 - ltb;
    }
    return 0;
}

pub fn main() !void {
    defer _ = gpa.deinit();

    var file = try std.fs.cwd().openFile("./input/day-06-input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [100]u8 = undefined;

    var acceleration: u8 = 1;
    var times = std.ArrayList(u64).init(gpa.allocator());
    var dists = std.ArrayList(u64).init(gpa.allocator());

    defer times.deinit();
    defer dists.deinit();

    var linenum: u8 = 0;

    var totalTime: u64 = 0;
    var totalDist: u64 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var it = std.mem.split(u8, line[11..], " ");

        while (it.next()) |numStr| {
            if (numStr.len == 0) {
                continue;
            }
            var num: u64 = try std.fmt.parseInt(u32, numStr, 0);
            if (linenum == 0) {
                try times.append(num);
                totalTime = totalTime * pow(10, @as(u32, @intCast(numStr.len))) + num;
            } else if (linenum == 1) {
                try dists.append(num);
                totalDist = totalDist * pow(10, @as(u64, @intCast(numStr.len))) + num;
            } else {
                unreachable;
            }
        }
        linenum += 1;
    }

    var mult: u64 = 1;
    var i: u8 = 0;
    while (i < times.items.len) : (i += 1) {
        var range = findWinningRangeLin(times.items[i], dists.items[i], acceleration);
        mult = mult * range;
    }

    print("Part 1: {?}\n", .{mult});
    print("Part 2: {?}\n", .{findWinningRangeLin(totalTime, totalDist, acceleration)});
}
