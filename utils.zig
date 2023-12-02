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
