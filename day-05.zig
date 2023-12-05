const std = @import("std");
const print = std.debug.print;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const mapStr = struct {
    const Self = @This();

    lines: std.ArrayList([]u64),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !*mapStr {
        var st = try allocator.create(mapStr);
        st.allocator = allocator;
        st.lines = std.ArrayList([]u64).init(allocator);
        return st;
    }

    pub fn deinit(self: *mapStr) void {
        for (self.lines.items) |it| {
            self.allocator.free(it);
        }
        self.lines.deinit();
        self.allocator.destroy(self);
    }

    pub fn addLineFromString(self: *mapStr, line: []const u8) !void {
        if (line.len == 0) {
            return;
        }

        var res: []u64 = try self.allocator.alloc(u64, 3);
        var it = std.mem.split(u8, line, " ");

        var k: u8 = 0;
        while (it.next()) |strNum| {
            if (k > 2) {
                unreachable;
            }
            res[k] = try std.fmt.parseInt(u64, strNum, 0);
            k += 1;
        }
        try self.lines.append(res);
    }

    pub fn findDest(self: *mapStr, source: u64) u64 {
        for (self.lines.items) |lin| {
            if (source < lin[1]) {
                continue;
            }
            var diff: u64 = source - lin[1];
            if (diff < lin[2]) {
                return lin[0] + diff;
            }
        }

        return source;
    }
};

pub fn main() !void {
    defer _ = gpa.deinit();

    var file = try std.fs.cwd().openFile("./input/day-05-input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    var seeds = std.ArrayList(u64).init(gpa.allocator());
    defer seeds.deinit();

    var maps = std.ArrayList(*mapStr).init(gpa.allocator());
    defer maps.deinit();
    defer {
        for (maps.items) |po| {
            po.*.deinit();
        }
    }

    var currMap: ?*mapStr = null;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) {
            if (currMap) |cm| {
                try maps.append(cm);
                currMap = null;
            }
            continue;
        }
        if (std.mem.startsWith(u8, line, "seeds")) {
            var it = std.mem.split(u8, line, " ");
            _ = it.first();
            while (it.next()) |seedNumStr| {
                var num: u64 = try std.fmt.parseInt(u64, seedNumStr, 0);
                try seeds.append(num);
            }
            continue;
        }
        if (!std.ascii.isDigit(line[0]) and currMap == null) {
            currMap = try mapStr.init(gpa.allocator());
            continue;
        }
        if (std.ascii.isDigit(line[0])) {
            if (currMap == null) {
                unreachable;
            }
            try currMap.?.addLineFromString(line);
        }
    }
    if (currMap) |cm| {
        try maps.append(cm);
    }

    var lowestLocPart1: ?u64 = null;
    for (seeds.items) |seed| {
        var currN: u64 = seed;
        for (maps.items) |mi| {
            currN = mi.findDest(currN);
        }
        if (lowestLocPart1 == null or currN < lowestLocPart1.?) {
            lowestLocPart1 = currN;
        }
    }

    var lowestLocPart2: ?u64 = null;
    var i: u64 = 0;
    while (i < seeds.items.len / 2) : (i += 1) {
        var j: u64 = 0;
        while (j < seeds.items[2 * i + 1]) : (j += 1) {
            //print("seed: {d}\n", .{seeds.items[2 * i] + j});
            var currN: u64 = seeds.items[2 * i] + j;
            for (maps.items) |mi| {
                currN = mi.findDest(currN);
            }
            if (lowestLocPart2 == null or currN < lowestLocPart2.?) {
                lowestLocPart2 = currN;
            }
        }
        print("{d}\n", .{i});
    }
    for (seeds.items) |seed| {
        var currN: u64 = seed;
        for (maps.items) |mi| {
            currN = mi.findDest(currN);
        }
        if (lowestLocPart1 == null or currN < lowestLocPart1.?) {
            lowestLocPart1 = currN;
        }
    }

    print("Part 1: {?}\n", .{lowestLocPart1});
    print("Part 2: {?}\n", .{lowestLocPart2});
}
