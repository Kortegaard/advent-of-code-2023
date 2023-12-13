const std = @import("std");
const utils = @import("./utils.zig");
const print = std.debug.print;

const u8Grid = std.ArrayList(std.ArrayList(u8));

const Point = struct {
    r: u8,
    c: u8,

    pub fn distance(p1: Point, p2: Point) u16 {
        return std.math.absCast(@as(i16, p1.r) - @as(i16, p2.r)) + std.math.absCast(@as(i16, p1.c) - @as(i16, p2.c));
    }
};

// Transfer ownership of return
pub fn spaceGalexyPointExtract(allocator: std.mem.Allocator, map: u8Grid) !std.ArrayList(Point) {
    var res = std.ArrayList(Point).init(allocator);
    for (map.items, 0..) |row, i| {
        for (row.items, 0..) |char, j| {
            if (char == '#') {
                try res.append(Point{ .r = @truncate(i), .c = @truncate(j) });
            }
        }
    }
    return res;
}

pub fn spaceExpand(map: *u8Grid) !void {
    var buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    var spaceRows = std.ArrayList(u8).init(allocator);
    var spaceCols = std.ArrayList(u8).init(allocator);
    defer spaceRows.deinit();
    defer spaceCols.deinit();

    for (map.items, 0..) |row, i| {
        var allSpace = true;
        for (row.items) |char| {
            if (char != '.') {
                allSpace = false;
            }
        }
        if (allSpace) {
            try spaceRows.append(@truncate(i));
        }
    }
    var width = map.items[0].items.len;
    var height = map.items.len;
    var w: u8 = 0;
    while (w < width) : (w += 1) {
        var allSpace = true;
        var h: u8 = 0;
        while (h < height) : (h += 1) {
            if (map.items[h].items[w] != '.') {
                allSpace = false;
            }
        }
        if (allSpace) {
            try spaceCols.append(@truncate(w));
        }
    }
    var j: u8 = @truncate(spaceRows.items.len);
    while (j > 0) : (j -= 1) {
        try map.insert(spaceRows.items[j - 1], map.items[spaceRows.items[j - 1]]);
    }

    j = @truncate(spaceCols.items.len);
    while (j > 0) : (j -= 1) {
        for (map.items, 0..) |_, m| {
            try map.items[m].insert(spaceCols.items[j - 1], '.');
        }
    }
}

pub fn gridPrint(map: u8Grid) void {
    for (map.items) |r| {
        for (r.items) |c| {
            print("{c}", .{c});
        }
        print("\n", .{});
    }
}

pub fn main() !void {
    // Memory is a bit of a pain to destroy xD
    var ar = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = ar.deinit();
    var allocator = ar.allocator();

    var lineItt = try utils.ReaderFileByLine("./input/day-11-input.txt");
    defer lineItt.deinit();

    var spaceMap = u8Grid.init(allocator);
    defer {
        for (spaceMap.items) |it| {
            it.deinit();
        }
        spaceMap.deinit();
    }

    while (try lineItt.next()) |line| {
        var row = std.ArrayList(u8).init(allocator);
        for (line) |c| {
            try row.append(c);
        }
        try spaceMap.append(row);
    }

    try spaceExpand(&spaceMap);
    //gridPrint(spaceMap);
    var galexies = try spaceGalexyPointExtract(allocator, spaceMap);
    defer galexies.deinit();

    var part1Sum: u64 = 0;
    for (galexies.items, 0..) |p1, i| {
        var k: usize = i + 1;
        while (k < galexies.items.len) : (k += 1) {
            part1Sum += Point.distance(p1, galexies.items[k]);
        }
    }

    print("Part 1: {d}\n", .{part1Sum});
    print("Part 2: {d}\n", .{0});
}
