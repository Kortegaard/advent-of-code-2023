const std = @import("std");
const print = std.debug.print;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub fn main() !void {
    defer _ = gpa.deinit();

    var file = try std.fs.cwd().openFile("./input/day-04-input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    var ticketMultiplier = std.AutoHashMap(u32, u32).init(gpa.allocator());
    defer ticketMultiplier.deinit();

    var part1Sum: u32 = 0;
    var part2Sum: u32 = 0;
    var rowNum: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var colIndexNum = std.mem.indexOf(u8, line, ":");
        if (colIndexNum == null) {
            continue;
        }

        var splitIt = std.mem.split(u8, line[colIndexNum.?..], "|");
        var winning = splitIt.first();
        var ticket = splitIt.next().?;
        var winningNumbers = std.ArrayList(u8).init(gpa.allocator());
        defer winningNumbers.deinit();

        var winningIt = std.mem.split(u8, winning, " ");
        while (winningIt.next()) |winNumStr| {
            var winNum = std.fmt.parseInt(u8, winNumStr, 0) catch {
                continue;
            };
            try winningNumbers.append(winNum);
        }

        var TicketsIt = std.mem.split(u8, ticket, " ");
        var numberOfWinningNumOfTicket: u32 = 0;
        while (TicketsIt.next()) |ticketNumStr| {
            var ticketNum = std.fmt.parseInt(u8, ticketNumStr, 0) catch {
                continue;
            };
            const inArrayListAtIndex = for (winningNumbers.items) |num| {
                if (num == ticketNum) break true;
            } else false;
            if (inArrayListAtIndex) {
                numberOfWinningNumOfTicket += 1;
            }
        }
        var i: u8 = 1;
        var currMultiplier: u32 = 1;
        if (ticketMultiplier.get(rowNum)) |r| {
            currMultiplier = r;
        }
        while (i <= numberOfWinningNumOfTicket) : (i += 1) {
            if (ticketMultiplier.get(rowNum + i)) |r| {
                try ticketMultiplier.put(rowNum + i, r + currMultiplier);
            } else {
                try ticketMultiplier.put(rowNum + i, 1 + currMultiplier);
            }
        }
        if (numberOfWinningNumOfTicket > 0) {
            part1Sum += std.math.pow(u32, 2, numberOfWinningNumOfTicket - 1);
        }
        part2Sum += currMultiplier;
        rowNum += 1;
    }

    print("Part 1 - {d}\n", .{part1Sum});
    print("Part 2 - {d}\n", .{part2Sum});
}
