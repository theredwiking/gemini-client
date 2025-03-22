const std = @import("std");

const mem = std.mem;

pub const TokenType = enum {
    ILLEGAL,
    EOF,
    StatusLine,
    TextLine,
    LinkLine,
    HeadingLine,
    ListItem,
    QuoteLine,
};

pub const Token = struct { type: TokenType, line: []const u8 };

// This is not the final tokenizer, this is an prototype. I need to learn more about how they work.
// Probably needs to be optimized
pub fn loopText(allocator: mem.Allocator, input: std.ArrayList([]const u8)) !std.ArrayList(Token) {
    var tokens = std.ArrayList(Token).init(allocator);
    for (input.items) |chunck| {
        var splitted = mem.splitAny(u8, chunck, "\n");

        while (splitted.next()) |line| {
            if (line.len != 0) {
                switch (line[0]) {
                    '#' => {
                        try tokens.append(.{ .type = .HeadingLine, .line = line });
                    },
                    '=' => {
                        if (line[1] == '>') {
                            try tokens.append(.{ .type = .LinkLine, .line = line });
                        }
                    },
                    '*' => {
                        try tokens.append(.{ .type = .ListItem, .line = line });
                    },
                    '>' => {
                        try tokens.append(.{ .type = .QuoteLine, .line = line });
                    },
                    // TODO: Check status and take action if needed
                    '0'...'6' => {
                        try tokens.append(.{ .type = .StatusLine, .line = line });
                    },
                    else => {
                        try tokens.append(.{ .type = .TextLine, .line = line });
                    },
                }
            }
        }
    }
    for (tokens.items) |token| {
        std.debug.print("Type: {}, Line: {s}\n", .{ token.type, token.line });
    }
    return tokens;
}
