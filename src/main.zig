const std = @import("std");
const tls = @import("tls");
const window = @import("window.zig");
const gemini = @import("gemini.zig");

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

    try gemini.protocolCheck(address);

    const host = try gemini.urlToUri(address);

    const stream: net.Stream = net.tcpConnectToHost(allocator, host, 1965) catch |err| {
        try stderr.print("Failed to connect: {?}\n", .{err});
        try ebw.flush();
        return error.FailedToConnect;
    };

    try stdout.print("Connected to: {s}\n", .{address});
    try bw.flush();

    var root_ca = try tls.CertBundle.fromSystem(allocator);
    defer root_ca.deinit(allocator);

    var conn = try tls.client(stream, .{
        .host = host,
        .root_ca = root_ca,
        .insecure_skip_verify = true,
    });

    const data = try allocator.alloc(u8, address.len + 4);
    const req = try std.fmt.bufPrint(data, "{s}\r\n", .{address});
    try conn.writeAll(req);
    allocator.free(data);

    const buf = try allocator.alloc(u8, 1024);
    var response = std.ArrayList([]const u8).init(allocator);

    const heap = std.heap.page_allocator;
    //var n = openssl.SSL_read(ssl, buf.ptr, buf_len);
    while (try conn.next()) |res| {
        const tempBuf = try std.fmt.allocPrint(heap, "{s}", .{res});
        errdefer heap.free(tempBuf);
        try response.append(tempBuf);
    }
    allocator.free(buf);

    for (response.items) |line| {
        try stdout.print("{s}", .{line});
        try bw.flush();
    }
    response.deinit();
    try conn.close();
    stream.close();
    try window.window(allocator);
}
