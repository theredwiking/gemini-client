const std = @import("std");
const window = @import("window.zig");
const gemini = @import("gemini.zig");

const net = std.net;

pub fn main() !void {
    var args = std.process.args();
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    _ = args.skip();

    const address = args.next() orelse {
        try stdout.print("Address needs to be specificed\n./gemini-protocol gemini://geminiprotocol.net/\n", .{});
        try bw.flush();
        return error.NoAddress;
    };

    try stdout.print("Connecting to: {s}\n", .{address});
    try bw.flush(); // don't forget to flush!

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            @panic("LEAK DETECTED");
        }
    }

    var stream = try gemini.init(allocator, address);
    try stream.connect();

    try stream.write(address);
    var response = try stream.read();

    for (response.items) |line| {
        try stdout.print("{s}", .{line});
        try bw.flush();
    }
    response.deinit();
    try stream.deinit();
    try window.window(allocator);
}
