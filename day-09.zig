const std = @import("std");
const utils = @import("./utils.zig");
const print = std.debug.print;

pub fn main() !void {
    // Memory is a bit of a pain to destroy xD
    var ar = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = ar.deinit();
    var allocator = ar.allocator();

    var lineItt = try utils.ReaderFileByLine("./input/day-09-input.txt");
    defer lineItt.deinit();

    var directions: [501]u8 = undefined;
    _ = directions;

    var lineNum: u16 = 0;

    var part1Sum: i64 = 0;
    var part2Sum: i64 = 0;
    while (try lineItt.next()) |line| {
        var nums = try utils.extractNumbersFromString(i32, allocator, line, true);
        defer nums.deinit();
        var b = try allocator.alloc(i32, nums.items.len);
        var firstNumbers = try allocator.alloc(i32, nums.items.len);
        std.mem.copyForwards(i32, b, nums.items);
        defer allocator.free(b);
        defer allocator.free(firstNumbers);

        var i: u8 = @truncate(nums.items.len);
        i -= 1;
        firstNumbers[0] = b[0];
        while (i > 0) : (i -= 1) {
            var j: u8 = 0;
            var allZero = true;
            while (j < i) : (j += 1) {
                b[j] = b[j + 1] - b[j];
                if (b[j] != 0) {
                    allZero = false;
                }
            }
            firstNumbers[nums.items.len - i] = b[0];
            if (allZero or j == 1) {
                // Part 1
                while (j < nums.items.len) : (j += 1) {
                    b[j] = b[j] + b[j - 1];
                }

                // Part 2
                var k: u8 = 1;
                var intSum: i64 = firstNumbers[0];
                while (k < nums.items.len - i) : (k += 1) {
                    if (@mod(k, 2) == 0) {
                        intSum += firstNumbers[k];
                    } else {
                        intSum -= firstNumbers[k];
                    }
                }
                part1Sum += b[nums.items.len - 1];
                part2Sum += intSum;
                break;
            }
        }
        lineNum += 1;
    }

    print("Part 1: {d}\n", .{part1Sum});
    print("Part 2: {d}\n", .{part2Sum});
}
