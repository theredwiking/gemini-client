const std = @import("std");
const net = std.net;

pub fn main() !void {
    var args = std.process.args();
    const stdout_file = std.io.getStdOut().writer();
    const stderr_file = std.io.getStdErr().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    var ebw = std.io.bufferedWriter(stderr_file);
    const stdout = bw.writer();
    const stderr = ebw.writer();

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

    //var splitUri = std.mem.split(u8, address, "//");
    //const protocol: []const u8 = splitUri.next() orelse {
    //    return error.NoProtocol;
    //};

    //if (std.mem.eql(u8, protocol, "gemini")) {
    //    try stderr.print("Need gemini protocol, get: {s}\n", .{protocol});
    //    try ebw.flush();
    //    return error.UnsupportedProtocol;
    //}
    const uri = std.Uri.parse(address) catch |err| {
        try stderr.print("Error parsing url: {}", .{err});
        try ebw.flush();
        return;
    };
    const host = uri.host.?.percent_encoded;

    const client: net.Stream = net.tcpConnectToHost(allocator, host, 1965) catch |err| {
        try stderr.print("Failed to connect: {?}\n", .{err});
        try ebw.flush();
        return error.FailedToConnect;
    };

    try stdout.print("Connected to: {s}\n", .{address});

    const data = try allocator.alloc(u8, address.len + 4);

    _ = try std.fmt.bufPrint(data, "{s}\r\n", .{address});

    var writer = client.writer();
    const size = try writer.write(data);
    try stdout.print("Request: {s}, wrote: {d}\n", .{ data, size });
    try bw.flush();
    allocator.free(data);

    var reader = client.reader();
    const message = reader.readAllAlloc(allocator, 1024) catch |err| {
        try stderr.print("Failed to read response: {}", .{err});
        try ebw.flush();
        return;
    };

    try stdout.print("Response: {s}", .{message});
    try bw.flush();
    allocator.free(message);
    client.close();
}
