const std = @import("std");
const print = std.debug.print;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

fn compareMapStrBySource(context: void, a: []u64, b: []u64) bool {
    _ = context;
    if (a[1] < b[1]) {
        return true;
    } else {
        return false;
    }
}

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

    pub fn addLine(self: *mapStr, line: []u64) !void {
        if (line.len >= 3) {
            var res: []u64 = try self.allocator.alloc(u64, 3);
            var it = std.mem.copy(u64, res, line);
            _ = it;
            try self.lines.append(res);
            return;
        }
        print("Should not be here, you messed up...\n", .{});
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

    pub fn sort(self: *mapStr) void {
        std.sort.insertion([]u64, self.lines.items, {}, compareMapStrBySource);
    }

    // Returns length of that range
    pub fn longestRangeStartingAt(self: *mapStr, source: u64) ?u64 {
        var lowestOver: ?u64 = null;

        for (self.lines.items) |lin| {
            if (source < lin[1]) {
                if (lowestOver == null or lowestOver.? > lin[1]) {
                    lowestOver = lin[1];
                }
                continue;
            }
            var diff: u64 = source - lin[1];
            if (diff < lin[2]) {
                // todo : corr? think so
                return lin[2] - diff;
            }
        }

        if (lowestOver) |val| {
            return val - source;
        }
        return null;
    }
};
//
// map1 followed by map2
pub fn composeMapStr(map1: *mapStr, map2: *mapStr, allocator: std.mem.Allocator) !*mapStr {
    var res = try mapStr.init(allocator);

    var curr_start: u64 = 0;
    while (true) {
        var map1_maxRange: ?u64 = map1.longestRangeStartingAt(curr_start);
        var map1_curr_dest = map1.findDest(curr_start);

        var map2_maxRange: ?u64 = map2.longestRangeStartingAt(map1_curr_dest);
        var map2_curr_dest = map2.findDest(map1_curr_dest);

        var minRange: ?u64 = map1_maxRange;
        if (map1_maxRange == null) {
            minRange = map2_maxRange;
        } else if (map2_maxRange != null and map2_maxRange.? < map1_maxRange.?) {
            minRange = map2_maxRange;
        }
        if (minRange == null) {
            break;
        }
        var line = [3]u64{ map2_curr_dest, curr_start, minRange.? };
        try res.addLine(&line);
        curr_start += minRange.?;
    }
    return res;
}
pub fn composeMultipleMapStr(maps: []*mapStr, allocator: std.mem.Allocator) !*mapStr {
    if (maps.len == 1) {
        return maps[0];
    }
    var res: *mapStr = maps[0];
    var i: u64 = 1;
    while (i < maps.len) : (i += 1) {
        var temp: *mapStr = try composeMapStr(res, maps[i], allocator);
        if (i > 1) {
            res.deinit();
        }
        res = temp;
    }
    return res;
}

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
                cm.sort();
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
        cm.sort();
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

    var comp: *mapStr = try composeMultipleMapStr(maps.items, gpa.allocator());
    defer comp.deinit();
    var lowestLocPart2: ?u64 = null;
    var i: u64 = 0;
    while (i < seeds.items.len / 2) : (i += 1) {
        var j: u64 = 0;
        while (j < seeds.items[2 * i + 1]) {
            var currN: u64 = comp.findDest(seeds.items[2 * i] + j);
            var longestRange = comp.longestRangeStartingAt(seeds.items[2 * i] + j);
            if (lowestLocPart2 == null or currN < lowestLocPart2.?) {
                lowestLocPart2 = currN;
            }
            if (longestRange) |lr| {
                j += lr;
            } else {
                j += 1;
            }
        }
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
