const std = @import("std");
const print = std.debug.print;

pub const ReadFileByByteIterator = struct {
    file: std.fs.File,
    bufferedReader: std.io.BufferedReader(4096, std.fs.File.Reader),
    reader: std.io.BufferedReader(4096, std.fs.File.Reader).Reader,

    pub fn next(self: *@This()) !?u8 {
        return self.reader.readByte() catch |err| switch (err) {
            error.EndOfStream => return null,
            else => return err,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.file.close();
    }
};

pub fn ReaderFileByByte(filename: []const u8) !ReadFileByByteIterator {
    var file: std.fs.File = try std.fs.cwd().openFile(filename, .{});
    var bufferedRead: std.io.BufferedReader(4096, std.fs.File.Reader) = std.io.bufferedReader(file.reader());
    var reader: std.io.BufferedReader(4096, std.fs.File.Reader).Reader = bufferedRead.reader();

    return ReadFileByByteIterator{ .file = file, .bufferedReader = bufferedRead, .reader = reader };
}

pub const ReadFileByLineIterator = struct {
    file: std.fs.File,
    bufferedReader: std.io.BufferedReader(4096, std.fs.File.Reader),
    reader: std.io.BufferedReader(4096, std.fs.File.Reader).Reader,
    buffer: [4096]u8,

    pub fn next(self: *@This()) !?[]u8 {
        return self.reader.readUntilDelimiter(&self.buffer, '\n') catch |err| switch (err) {
            error.EndOfStream => return null,
            else => return err,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.file.close();
    }
};
pub fn ReaderFileByLine(filename: []const u8) !ReadFileByLineIterator {
    var file: std.fs.File = try std.fs.cwd().openFile(filename, .{});
    var bufferedRead: std.io.BufferedReader(4096, std.fs.File.Reader) = std.io.bufferedReader(file.reader());
    var reader: std.io.BufferedReader(4096, std.fs.File.Reader).Reader = bufferedRead.reader();

    return ReadFileByLineIterator{ .file = file, .bufferedReader = bufferedRead, .reader = reader, .buffer = undefined };
}

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
    var it = try ReaderFileByLine("./input/day-2-input.txt");
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
        var gtSplitIrr = std.mem.split(u8, gameTitle, " ");
        _ = gtSplitIrr.first();
        var gameNum: u16 = 0;
        if (gtSplitIrr.next()) |n| {
            gameNum = try std.fmt.parseInt(u16, n, 0);
        }
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
