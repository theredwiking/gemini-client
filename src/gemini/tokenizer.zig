const std = @import("std");

const mem = std.mem;

pub const TokenType = enum {
    ILLEGAL,
    EOF,
    TextLine,
    LinkLine,
    HeadingLine,
    ListItem,
    QuoteLine,
};

pub const Token = struct { type: TokenType, line: []const u8 };

// This is not the final tokenizer, this is an prototype. I need to learn more about how they work.
// Also need to learn how to do this most optimal
pub fn loopText(allocator: mem.Allocator, input: std.ArrayList([]const u8)) !std.ArrayList(Token) {
    for (input.items) |chunck| {
        var splitted = mem.splitAny(u8, chunck, "\n");

        //while (splitted.next()) |line| {
        //    if (line.len != 0) {
        //        std.debug.print("'{s}'\n", .{line});
        //        const result = switch (line[0]) {
        //            '#' => Token{ .type = .HeadingLine, .line = line },
        //            '=' => Token{ .type = .LinkLine, .line = line },
        //            else => Token{ .type = .TextLine, .line = line },
        //        };
        //        std.debug.print("{}", .{result.type});
        //    }
        //}
    }
    return std.ArrayList(Token).init(allocator);
}
