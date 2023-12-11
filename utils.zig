const std = @import("std");
const expect = @import("std").testing.expect;
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
    fileRead: std.fs.File.Reader,
    bufferedReader: std.io.BufferedReader(4096, std.fs.File.Reader),
    reader: ?std.io.BufferedReader(4096, std.fs.File.Reader).Reader,
    buffer: [4096]u8,

    pub fn next(self: *@This()) !?[]u8 {
        if (self.reader == null) {
            self.reader = self.bufferedReader.reader();
        }
        if (self.reader) |r| {
            return r.readUntilDelimiterOrEof(&self.buffer, '\n');
        }
        unreachable;
    }

    pub fn deinit(self: *@This()) void {
        self.file.close();
    }
};
pub fn ReaderFileByLine(filename: []const u8) !ReadFileByLineIterator {
    var file: std.fs.File = try std.fs.cwd().openFile(filename, .{});
    var fileReader = file.reader();
    var bufferedRead: std.io.BufferedReader(4096, std.fs.File.Reader) = std.io.bufferedReader(fileReader);

    return ReadFileByLineIterator{ .file = file, .fileRead = fileReader, .bufferedReader = bufferedRead, .reader = null, .buffer = undefined };
}

pub fn extractNumbersFromString(comptime T: type, allocator: std.mem.Allocator, str: []const u8, considerNegative: bool) !std.ArrayList(T) {
    var intStartPos: ?u64 = null;
    var nums = std.ArrayList(T).init(allocator);
    var isNeg = false;
    errdefer nums.deinit();
    for (str, 0..) |c, i| {
        if (std.ascii.isDigit(c) and intStartPos == null) {
            intStartPos = i;
        }
        if (i == str.len - 1 or (!std.ascii.isDigit(c) and intStartPos != null)) {
            const index = if (i == str.len - 1) i + 1 else i;
            var num: T = try std.fmt.parseInt(T, str[intStartPos.?..index], 0);
            if (isNeg and considerNegative) {
                num = num * -1;
            }
            try nums.append(num);
            intStartPos = null;
            isNeg = false;
        }
        if (!std.ascii.isDigit(c)) {
            isNeg = (c == '-');
        }
    }
    return nums;
}

test "Extract Numbers" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var a = [_]u8{ ' ', '1', '2', '3', ' ', '-', '4', ' ', ' ', '4', '5' };
    var nums = try extractNumbersFromString(i16, gpa.allocator(), &a);
    print("{any}", .{nums});
    defer nums.deinit();
}
