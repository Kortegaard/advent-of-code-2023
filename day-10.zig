const std = @import("std");
const utils = @import("./utils.zig");
const print = std.debug.print;

const MyErrors = error{
    NotValidIncomingDir,
    StartDoesNotExist,
    NoPossibleOut,
};

const Direction = enum(u8) {
    South = 0,
    North = 1,
    West = 2,
    East = 3,

    pub fn opposite(self: Direction) Direction {
        return switch (self) {
            Direction.South => Direction.North,
            Direction.North => Direction.South,
            Direction.East => Direction.West,
            Direction.West => Direction.East,
        };
    }
};

pub fn connections(pipe: u8) [2]Direction {
    return switch (pipe) {
        '|' => [2]Direction{ Direction.North, Direction.South },
        '-' => [2]Direction{ Direction.West, Direction.East },
        '7' => [2]Direction{ Direction.West, Direction.South },
        'L' => [2]Direction{ Direction.East, Direction.North },
        'F' => [2]Direction{ Direction.East, Direction.South },
        'J' => [2]Direction{ Direction.West, Direction.North },
        else => undefined,
    };
}

pub fn outGoingDirection(pipe: u8, inComingDirection: Direction) !Direction {
    var dirs = connections(pipe);
    if (dirs[0] == inComingDirection) {
        return dirs[1];
    } else if (dirs[1] == inComingDirection) {
        return dirs[0];
    }
    return MyErrors.NotValidIncomingDir;
}

pub fn findStartPosition(maze: std.ArrayList([]u8)) ![2]u8 {
    for (maze.items, 0..) |rows, r| {
        for (rows, 0..) |char, c| {
            if (char == 'S') {
                return [2]u8{ @truncate(r), @truncate(c) };
            }
        }
    }
    return MyErrors.StartDoesNotExist;
}

pub fn convertDirectionToCoordinatef(d: Direction) [2]i8 {
    return switch (d) {
        Direction.South => [2]i8{ 1, 0 },
        Direction.North => [2]i8{ -1, 0 },
        Direction.East => [2]i8{ 0, 1 },
        Direction.West => [2]i8{ 0, -1 },
    };
}

pub fn findStartOutDir(i: u8, j: u8, maze: std.ArrayList([]u8)) !Direction {
    if (i > 0 and (maze.items[i - 1][j] == '|' or maze.items[i - 1][j] == 'F' or maze.items[i - 1][j] == '7')) {
        return Direction.North;
    }
    if (j > 0 and (maze.items[i][j - 1] == '-' or maze.items[i][j - 1] == 'F' or maze.items[i][j - 1] == 'L')) {
        return Direction.West;
    }
    if (j < maze.items[0].len - 1 and (maze.items[i][j + 1] == '-' or maze.items[i][j + 1] == '7' or maze.items[i][j + 1] == 'J')) {
        return Direction.East;
    }
    if (i < maze.items.len - 1 and (maze.items[i + 1][j] == '|' or maze.items[i + 1][j] == 'L' or maze.items[i + 1][j] == 'J')) {
        return Direction.South;
    }

    return MyErrors.NoPossibleOut;
}

pub fn calculateCrossingNum(i: u8, j: u8, crossTracker: std.ArrayList([]u8)) u8 {
    var y: u8 = 0;
    var crossNum: u8 = 0;
    var metS = false;
    var inWall: ?u8 = null;

    while (y < crossTracker.items.len) : (y += 1) {
        if (crossTracker.items[y][j] == 'v') {
            crossNum += 1;
        }
        if (crossTracker.items[y][j] == 'r' or crossTracker.items[y][j] == 'l') {
            if (inWall) |w| {
                if (w == crossTracker.items[y][j]) {
                    crossNum += 2;
                } else {
                    crossNum += 1;
                }
                inWall = null;
            } else {
                inWall = crossTracker.items[y][j];
            }
        }
        if (crossTracker.items[y][j] == 'S') {
            metS = true;
        }
        if (y == i and !metS) {
            break;
        }
        if (y == i and metS) {
            inWall = null;
            crossNum = 0;
        }
    }
    return crossNum;
}

pub fn main() !void {
    // Memory is a bit of a pain to destroy xD
    var ar = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = ar.deinit();
    var allocator = ar.allocator();

    var lineItt = try utils.ReaderFileByLine("./input/day-10-input.txt");
    defer lineItt.deinit();

    var rows = std.ArrayList([]u8).init(allocator);
    defer {
        for (rows.items) |it| {
            allocator.free(it);
        }
        rows.deinit();
    }

    while (try lineItt.next()) |line| {
        var r = try allocator.alloc(u8, line.len);
        std.mem.copyForwards(u8, r, line);
        try rows.append(r);
    }

    var crossTracker = std.ArrayList([]u8).init(allocator);
    defer {
        for (crossTracker.items) |it| {
            allocator.free(it);
        }
        crossTracker.deinit();
    }
    for (rows.items) |r| {
        var l = try allocator.alloc(u8, r.len);
        var i: u8 = 0;
        while (i < r.len) : (i += 1) {
            l[i] = ' ';
        }
        try crossTracker.append(l);
    }
    var currPos: [2]u8 = try findStartPosition(rows);
    var outDirection = try findStartOutDir(currPos[0], currPos[1], rows);

    var numSteps: u32 = 0;
    while (true) {
        var char = rows.items[currPos[0]][currPos[1]];

        if (char == 'S') {
            crossTracker.items[currPos[0]][currPos[1]] = 'S';
        }
        if (char == '7' or char == 'J') {
            crossTracker.items[currPos[0]][currPos[1]] = 'l';
        }
        if (char == 'L' or char == 'F') {
            crossTracker.items[currPos[0]][currPos[1]] = 'r';
        }
        if (char == '|') {
            crossTracker.items[currPos[0]][currPos[1]] = 'h';
        }
        if (char == '-') {
            crossTracker.items[currPos[0]][currPos[1]] = 'v';
        }

        var dir: [2]i8 = convertDirectionToCoordinatef(outDirection);
        currPos[0] = @intCast(@as(i16, currPos[0]) + dir[0]);
        currPos[1] = @intCast(@as(i16, currPos[1]) + dir[1]);
        numSteps += 1;
        if (rows.items[currPos[0]][currPos[1]] == 'S') {
            break;
        }
        outDirection = try outGoingDirection(rows.items[currPos[0]][currPos[1]], outDirection.opposite());
    }

    var step2Answer: u32 = 0;
    var i: u8 = 0;
    while (i < rows.items.len) : (i += 1) {
        var j: u8 = 0;
        while (j < rows.items[i].len) : (j += 1) {
            if (crossTracker.items[i][j] == ' ') {
                if (@mod(calculateCrossingNum(i, j, crossTracker), 2) == 1) {
                    step2Answer += 1;
                }
            }
        }
    }
    var step1Answer: u32 = @divFloor(numSteps, 2);

    print("Part 1: {d}\n", .{step1Answer});
    print("Part 2: {d}\n", .{step2Answer});
}
