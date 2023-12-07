const std = @import("std");
const print = std.debug.print;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

// Rank loves to highest
const cardOrderPart1 = [13]u8{ '2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A' };
const cardOrderPart2 = [13]u8{ 'J', '2', '3', '4', '5', '6', '7', '8', '9', 'T', 'Q', 'K', 'A' };

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

pub fn handAlphLessThan(a: Hand, b: Hand, cardOrdering: []const u8) bool {
    for (a.cards, 0..) |card, i| {
        if (card == b.cards[i]) {
            continue;
        }
        for (cardOrdering) |c| {
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
    return handAlphLessThan(a, b, &cardOrderPart1);
}

pub fn handLessThanPart2(context: void, a: Hand, b: Hand) bool {
    _ = context;
    if (@intFromEnum(a.handTypePart2()) < @intFromEnum(b.handTypePart2())) {
        return true;
    }
    if (@intFromEnum(a.handTypePart2()) > @intFromEnum(b.handTypePart2())) {
        return false;
    }
    return handAlphLessThan(a, b, &cardOrderPart2);
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
            const index = for (cardOrderPart1, 0..) |c, i| {
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

    pub fn handTypePart2(self: Self) HandType {
        var counted: [13]u8 = [_]u8{0} ** 13;
        for (self.cards) |card| {
            const index = for (cardOrderPart2, 0..) |c, i| {
                if (c == card) break i;
            } else unreachable;
            counted[index] += 1;
        }
        // indicates number >= index+1
        var numOver = [_]u8{0} ** 6;
        for (counted[1..]) |n| {
            numOver[n] += 1;
        }
        if (numOver[5 - counted[0]] > 0) {
            return HandType.FiveOfKind;
        }
        if (numOver[4 - counted[0]] > 0) {
            return HandType.FourOfKind;
        }

        //Without joker
        if (numOver[3] > 0 and numOver[2] > 0) {
            return HandType.FullHouse;
        }

        // If there are 2 jokers, we know there are no pairs,
        // otherwise it would have qualified for a FourOfKind.
        // Therefore, 2 jokers can not result in FullHouse
        if (counted[0] > 2) {
            unreachable; // otherwise there would be four of kind
        }

        // If there is one joker, we need there to be 2 pairs
        // without the joker to give full house
        if (counted[0] == 1 and numOver[2] > 1) {
            return HandType.FullHouse;
        }

        if (numOver[3 - counted[0]] > 0) {
            return HandType.ThreeOfKind;
        }

        // Here we check if there is a pair using 'numOver'
        // but joker is not counted there, so we need to check
        // for Joker pairs. Notice if there is a joker we have
        // already seen there can not be a joker and a different
        // pair at the same time, thus to get two pairs with
        // at least one joker, there need to be two jokers
        if (counted[0] > 1 or numOver[2] > 1) {
            return HandType.TwoPair;
        }

        if (numOver[2 - counted[0]] > 0) {
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
    var sumPart1: u64 = 0;
    for (hands.items, 0..) |h, i| {
        sumPart1 += h.bet * (i + 1);
    }

    std.sort.insertion(Hand, hands.items, {}, handLessThanPart2);
    var sumPart2: u64 = 0;
    for (hands.items, 0..) |h, i| {
        sumPart2 += h.bet * (i + 1);
    }

    print("Part 1: {d}\n", .{sumPart1});
    print("Part 2: {?}\n", .{sumPart2});
}
