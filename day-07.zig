const std = @import("std");
const print = std.debug.print;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

// Rank loves to highest
const cardOrder = [13]u8{ '2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A' };

// Rank loves to highest
const HandType = enum(u4) {
    HighCard = 0,
    OnePair = 1,
    TwoPair = 2,
    ThreeOfKind = 3,
    FullHouse = 4,
    FourOfKind = 5,
    FiveOfKind = 6,
};

pub fn handAlphLessThan(a: Hand, b: Hand) bool {
    for (a.cards, 0..) |card, i| {
        if (card == b.cards[i]) {
            continue;
        }
        for (cardOrder) |c| {
            if (card == c) {
                return true;
            }
            if (b.cards[i] == c) {
                return false;
            }
        }
    }
    return false;
}

pub fn handLessThan(context: void, a: Hand, b: Hand) bool {
    _ = context;
    if (@intFromEnum(a.handType()) < @intFromEnum(b.handType())) {
        return true;
    }
    if (@intFromEnum(a.handType()) > @intFromEnum(b.handType())) {
        return false;
    }
    return handAlphLessThan(a, b);
}

const Hand = struct {
    const Self = @This();
    cards: [5]u8,
    bet: u32,

    pub fn init(str: [5]u8, bet: u32) Self {
        return Self{
            .cards = str,
            .bet = bet,
        };
    }

    pub fn handType(self: Self) HandType {
        var counted: [13]u8 = [_]u8{0} ** 13;
        for (self.cards) |card| {
            const index = for (cardOrder, 0..) |c, i| {
                if (c == card) break i;
            } else unreachable;
            counted[index] += 1;
        }
        // indicates number >= index+1
        var numOver = [_]u8{0} ** 5;
        for (counted) |n| {
            if (n > 0) {
                numOver[n - 1] += 1;
            }
        }
        if (numOver[4] > 0) {
            return HandType.FiveOfKind;
        }
        if (numOver[3] > 0) {
            return HandType.FourOfKind;
        }
        if (numOver[2] > 0 and numOver[1] > 0) {
            return HandType.FullHouse;
        }
        if (numOver[2] > 0) {
            return HandType.ThreeOfKind;
        }
        if (numOver[1] > 1) {
            return HandType.TwoPair;
        }
        if (numOver[1] > 0) {
            return HandType.OnePair;
        }
        return HandType.HighCard;
    }
};

pub fn main() !void {
    defer _ = gpa.deinit();

    var file = try std.fs.cwd().openFile("./input/day-07-input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [100]u8 = undefined;

    var hands = std.ArrayList(Hand).init(gpa.allocator());
    defer hands.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len < 5) {
            continue;
        }
        var lin = [5]u8{ line[0], line[1], line[2], line[3], line[4] };
        var h = Hand.init(
            lin,
            try std.fmt.parseInt(u32, line[6..], 0),
        );

        try hands.append(h);
    }

    std.sort.insertion(Hand, hands.items, {}, handLessThan);

    var sum: u64 = 0;
    for (hands.items, 0..) |h, i| {
        print("{s} - {d}\n", .{ h.cards, h.bet });
        sum += h.bet * (i + 1);
    }
    print("Part 1: {d}\n", .{sum});
    print("Part 2: {?}\n", .{0});
}
