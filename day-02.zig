const std = @import("std");
const print = std.debug.print;
const fh = @import("./utils.zig");

const ColorError = error{NotAColor};
pub const Color = enum { blue, red, green };

pub fn parseColor(colStr: []const u8) !Color {
    if (std.mem.eql(u8, colStr, "blue")) {
        return Color.blue;
    }
    if (std.mem.eql(u8, colStr, "green")) {
        return Color.green;
    }
    if (std.mem.eql(u8, colStr, "red")) {
        return Color.red;
    }
    return ColorError.NotAColor;
}

pub fn main() !void {
    var it = try fh.ReaderFileByLine("./input/day-2-input.txt");
    var indexSum: u16 = 0;
    const numRedBalls = 12;
    const numGreenBalls = 13;
    const numBlueBalls = 14;

    var sumOfGamePower: u32 = 0;
    while (try it.next()) |line| {
        // A single game
        var maxRed: u16 = 0;
        var maxGreen: u16 = 0;
        var maxBlue: u16 = 0;

        var colSplitIrr = std.mem.split(u8, line, ":");
        const gameTitle: []const u8 = colSplitIrr.first();
        if (gameTitle.len < 5) {
            continue;
        }
        var gameNum: u8 = try std.fmt.parseInt(u8, gameTitle[5..], 0);

        while (colSplitIrr.next()) |colseg| {
            var semcolSplitIrr = std.mem.split(u8, colseg, ";");
            while (semcolSplitIrr.next()) |semcolseg| {
                var comIrr = std.mem.split(u8, semcolseg, ",");
                while (comIrr.next()) |part| {
                    var m = std.mem.split(u8, part[1..], " ");
                    const num = try std.fmt.parseInt(u16, m.first(), 0);
                    if (m.next()) |c| {
                        var col: Color = try parseColor(c);
                        if (col == Color.blue and num > maxBlue) {
                            maxBlue = num;
                        }
                        if (col == Color.red and num > maxRed) {
                            maxRed = num;
                        }
                        if (col == Color.green and num > maxGreen) {
                            maxGreen = num;
                        }
                    }
                }
            }
            if (numGreenBalls >= maxGreen and numRedBalls >= maxRed and numBlueBalls >= maxBlue) {
                indexSum += gameNum;
            }
            sumOfGamePower += maxGreen * maxRed * maxBlue;
        }
    }

    print("Part 1 - Sum of indexes: {d}\n", .{indexSum});
    print("Part 2 - Sum of powers: {d}\n", .{sumOfGamePower});
}
