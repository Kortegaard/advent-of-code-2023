const std = @import("std");
const print = std.debug.print;
const fh = @import("./utils.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var list = std.ArrayList(std.ArrayList(u8)).init(gpa.allocator());

pub fn lookAroundForSymbol(i: u32, j: u32) bool {
    var iStart: u32 = if (i == 0) 0 else i - 1;
    var jStart: u32 = if (j == 0) 0 else j - 1;
    for (iStart..i + 2) |k| {
        for (jStart..j + 2) |l| {
            if (i == k and j == l) {
                continue;
            }
            if (k >= list.items.len or l >= list.items[k].items.len) {
                continue;
            }
            if (k == i and !std.ascii.isDigit(list.items[k].items[l]) and list.items[k].items[l] != '.') {
                return true;
            } else if (k != i and list.items[k].items[l] != '.') {
                return true;
            }
        }
    }
    return false;
}

pub fn part1() !u32 {
    var i: u32 = 0;
    var j: u32 = 0;
    var sum: u32 = 0;

    for (list.items) |line| {
        var numl = [_]u8{ 0, 0, 0, 0, 0, 0 };
        var maxIndex: u8 = 0;

        var nextToSym = false;
        for (line.items) |ch| {
            if (std.ascii.isDigit(ch)) {
                numl[maxIndex] = ch;
                maxIndex += 1;

                nextToSym = nextToSym or lookAroundForSymbol(i, j);
            }
            if (!std.ascii.isDigit(ch) or j == line.items.len - 1) {
                if (maxIndex > 0 and nextToSym) {
                    var dig = try std.fmt.parseInt(u32, numl[0..maxIndex], 0);
                    sum += dig;
                }

                nextToSym = false;
                maxIndex = 0;
            }
            j += 1;
        }
        j = 0;
        i += 1;
    }
    return sum;
}

pub fn adjecentToGear(i: u8, j: u8) ?[2]u8 {
    var iStart: u8 = if (i == 0) 0 else i - 1;
    var jStart: u8 = if (j == 0) 0 else j - 1;
    var k: u8 = iStart;
    while (k < i + 2) : (k += 1) {
        var l: u8 = jStart;
        while (l < j + 2) : (l += 1) {
            if (i == k and j == l) {
                continue;
            }
            if (k >= list.items.len or l >= list.items[k].items.len) {
                continue;
            }
            if (list.items[k].items[l] == '*') {
                var b = [2]u8{ k, l };
                return b;
            }
        }
    }

    return null;
}
const Gear = struct {
    i: u8,
    j: u8,
    num1: u32,
    num2: u32,
};

pub fn part2() !u32 {
    var i: u8 = 0;
    var j: u8 = 0;
    var sum: u32 = 0;

    var gList = std.ArrayList(*Gear).init(gpa.allocator());
    defer gList.deinit();

    for (list.items) |line| {
        var numl = [_]u8{ 0, 0, 0, 0, 0, 0 };
        var maxIndex: u8 = 0;

        var nextToGear = false;
        var theGear: ?[2]u8 = null;
        for (line.items) |ch| {
            //print("{d}, {d}, {}\n", .{ i, j, lookAroundForSymbol(i, j) });
            if (std.ascii.isDigit(ch)) {
                numl[maxIndex] = ch;
                maxIndex += 1;

                // Look aruond for symbol
                if (theGear == null) {
                    theGear = adjecentToGear(i, j);
                    //print("here{any}\n", .{theGear});
                }
            }
            if (!std.ascii.isDigit(ch) or j == line.items.len - 1) {
                if (maxIndex > 0) {
                    if (theGear) |theG| {
                        var dig = try std.fmt.parseInt(u32, numl[0..maxIndex], 0);
                        var gearWasFoundInList = false;
                        for (gList.items) |gearInList| {
                            if (!(theG[0] == gearInList.*.i) or !(theG[1] == gearInList.*.j)) {
                                continue;
                            }
                            gearWasFoundInList = true;
                            if (gearInList.*.num1 == 0) {
                                gearInList.*.num1 = dig;
                            } else if (gearInList.*.num2 == 0) {
                                gearInList.*.num2 = dig;
                            }
                            break;
                        }
                        if (!gearWasFoundInList) {
                            var newGear = try gpa.allocator().create(Gear);
                            newGear.*.i = theG[0];
                            newGear.*.j = theG[1];
                            newGear.*.num1 = dig;
                            newGear.*.num2 = 0;
                            try gList.append(newGear);
                        }
                    }
                    theGear = null;
                }

                nextToGear = false;
                maxIndex = 0;
            }
            j += 1;
        }
        j = 0;
        i += 1;
    }
    for (gList.items) |gear| {
        if (gear.*.num1 != 0 and gear.*.num2 != 0) {
            sum += gear.*.num1 * gear.*.num2;
        }
    }
    for (gList.items) |gear| {
        defer gpa.allocator().destroy(gear);
    }
    return sum;
}

pub fn main() !void {
    defer _ = gpa.deinit();
    defer list.deinit();

    var file = try std.fs.cwd().openFile("./input/day-03-input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var nList = std.ArrayList(u8).init(gpa.allocator());
        for (line) |ch| {
            try nList.append(ch);
        }
        try list.append(nList);
    }

    var p1: u32 = try part1();
    print("Part 1 - {d}\n", .{p1});
    var p2: u32 = try part2();
    print("Part 2 - {d}\n", .{p2});
    for (list.items) |item| {
        item.deinit();
    }
}
