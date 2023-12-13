const std = @import("std");
const utils = @import("./utils.zig");
const print = std.debug.print;

const u8Grid = std.ArrayList(std.ArrayList(u8));

const Point = struct {
    r: u8,
    c: u8,
};

const SpaceMap = struct {
    const Self = @This();
    allocator: std.mem.Allocator,
    map: u8Grid,
    expansionRate: u64,
    emptySpaceRows: ?std.ArrayList(u8) = null,
    emptySpaceCols: ?std.ArrayList(u8) = null,
    galexyPoints: ?std.ArrayList(Point) = null,

    pub fn setExpansionRate(self: *Self, rate: u64) void {
        self.expansionRate = rate;
    }

    pub fn init(allocator: std.mem.Allocator) Self {
        var spaceMap = u8Grid.init(allocator);
        return .{
            .allocator = allocator,
            .map = spaceMap,
            .expansionRate = 1,
        };
    }

    pub fn readFromFile(self: *Self, filename: []const u8) !void {
        var lineItt = try utils.ReaderFileByLine(filename);
        defer lineItt.deinit();

        while (try lineItt.next()) |line| {
            var row = std.ArrayList(u8).init(self.allocator);
            for (line) |c| {
                try row.append(c);
            }
            try self.map.append(row);
        }

        try self.parseEmptySpace();
        try self.extractGalexies();
    }

    pub fn deinit(self: *Self) void {
        for (self.map.items) |it| {
            it.deinit();
        }
        self.map.deinit();
        if (self.emptySpaceRows != null) {
            self.emptySpaceRows.?.deinit();
        }
        if (self.emptySpaceCols != null) {
            self.emptySpaceCols.?.deinit();
        }
        if (self.galexyPoints != null) {
            self.galexyPoints.?.deinit();
        }
    }

    pub fn calculateAOC(self: *Self) !u64 {
        if (self.galexyPoints == null) {
            try self.extractGalexies();
        }
        if (self.emptySpaceRows == null) {
            try self.parseEmptySpace();
        }

        var sum: u64 = 0;
        for (self.galexyPoints.?.items, 0..) |p1, i| {
            var k: usize = i + 1;
            while (k < self.galexyPoints.?.items.len) : (k += 1) {
                sum += self.pointDistance(p1, self.galexyPoints.?.items[k]);
            }
        }

        return sum;
    }

    pub fn pointDistance(self: *Self, p1: Point, p2: Point) u64 {
        var rowDist: u64 = std.math.absCast(@as(i16, p1.r) - @as(i16, p2.r));
        var colDist: u64 = std.math.absCast(@as(i16, p1.c) - @as(i16, p2.c));
        for (self.emptySpaceRows.?.items) |r| {
            if ((p1.r < r and r < p2.r) or (p2.r < r and r < p1.r)) {
                rowDist += self.expansionRate - 1;
            }
        }

        for (self.emptySpaceCols.?.items) |c| {
            if ((p1.c < c and c < p2.c) or (p2.c < c and c < p1.c)) {
                colDist += self.expansionRate - 1;
            }
        }

        return colDist + rowDist;
    }

    fn extractGalexies(self: *Self) !void {
        if (self.galexyPoints != null) {
            self.galexyPoints.?.deinit();
            self.galexyPoints = null;
        }

        self.galexyPoints = std.ArrayList(Point).init(self.allocator);

        for (self.map.items, 0..) |row, i| {
            for (row.items, 0..) |char, j| {
                if (char == '#') {
                    try self.galexyPoints.?.append(Point{ .r = @truncate(i), .c = @truncate(j) });
                }
            }
        }
    }

    fn parseEmptySpace(self: *Self) !void {
        if (self.emptySpaceRows != null) {
            self.emptySpaceRows.?.deinit();
            self.emptySpaceRows = null;
        }
        if (self.emptySpaceCols != null) {
            self.emptySpaceCols.?.deinit();
            self.emptySpaceCols = null;
        }

        self.emptySpaceRows = std.ArrayList(u8).init(self.allocator);
        self.emptySpaceCols = std.ArrayList(u8).init(self.allocator);

        for (self.map.items, 0..) |row, i| {
            var allSpace = true;
            for (row.items) |char| {
                if (char != '.') {
                    allSpace = false;
                }
            }
            if (allSpace) {
                try self.emptySpaceRows.?.append(@truncate(i));
            }
        }

        var width = self.map.items[0].items.len;
        var height = self.map.items.len;
        var w: u8 = 0;
        while (w < width) : (w += 1) {
            var allSpace = true;
            var h: u8 = 0;
            while (h < height) : (h += 1) {
                if (self.map.items[h].items[w] != '.') {
                    allSpace = false;
                }
            }
            if (allSpace) {
                try self.emptySpaceCols.?.append(@truncate(w));
            }
        }
    }
};

pub fn gridPrint(map: u8Grid) void {
    for (map.items) |r| {
        for (r.items) |c| {
            print("{c}", .{c});
        }
        print("\n", .{});
    }
}

pub fn main() !void {
    var ar = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = ar.deinit();
    var allocator = ar.allocator();

    var spaceMap = SpaceMap.init(allocator);
    defer spaceMap.deinit();
    try spaceMap.readFromFile("./input/day-11-input.txt");

    spaceMap.setExpansionRate(2);
    print("Part 1: {d}\n", .{try spaceMap.calculateAOC()});
    spaceMap.setExpansionRate(1_000_000);
    print("Part 2: {d}\n", .{try spaceMap.calculateAOC()});
}
