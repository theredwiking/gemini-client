const std = @import("std");

pub const TokenType = enum {
    ILLEGAL,
    EOF,
    TextLine,
    LinkLine,
    HeadingLine,
    ListItem,
    QuoteLine,
};

pub const Token = struct { type: TokenType, literal: ?[]u8, line: []const u8 };

pub fn loopText(allocator: std.mem.Allocator, input: std.ArrayList([]const u8)) !std.ArrayList(Token) {
    for (input.items) |chunck| {
        var splitted = std.mem.splitAny(u8, chunck, "\n");

        while (splitted.next()) |line| {
            if (line.len != 0) {
                std.debug.print("'{s}'\n", .{line});
            }
        }
    }
    return std.ArrayList(Token).init(allocator);
}
