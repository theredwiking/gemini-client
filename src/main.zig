const std = @import("std");
const net = std.net;
const openssl = @cImport({
    @cInclude("openssl/ssl.h");
});

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

    var splitUri = std.mem.split(u8, address, "://");
    const protocol: []const u8 = splitUri.next() orelse {
        return error.NoProtocol;
    };

    if (!std.mem.eql(u8, protocol, "gemini")) {
        try stderr.print("Need gemini protocol, get: {s}\n", .{protocol});
        try ebw.flush();
        return error.UnsupportedProtocol;
    }

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
    try bw.flush();

    _ = openssl.OPENSSL_init_crypto(openssl.OPENSSL_INIT_ADD_ALL_CIPHERS | openssl.OPENSSL_INIT_ADD_ALL_DIGESTS | openssl.OPENSSL_INIT_LOAD_CONFIG, null);
    _ = openssl.OPENSSL_init_ssl(openssl.OPENSSL_INIT_LOAD_SSL_STRINGS | openssl.OPENSSL_INIT_LOAD_CRYPTO_STRINGS, null);

    const ctx: ?*openssl.SSL_CTX = openssl.SSL_CTX_new(openssl.TLS_client_method());
    defer openssl.SSL_CTX_free(ctx);
    if (ctx == null) {
        try stderr.print("Error getting ssl context\n", .{});
        try ebw.flush();
        return error.SslCtx;
    }

    const ssl: ?*openssl.SSL = openssl.SSL_new(ctx);
    defer openssl.SSL_free(ssl);
    if (ssl == null) {
        try stdout.print("Failed to create new SSL\n", .{});
        try ebw.flush();
        return error.NewSsl;
    }

    if (openssl.SSL_set_fd(ssl, client.handle) <= 0) {
        try stderr.print("Error setting stream to use ssl\n", .{});
        try ebw.flush();
        return error.StreamAsTls;
    }

    if (openssl.SSL_connect(ssl) < 0) {
        try stderr.print("Failed to connect using ssl\n", .{});
        try ebw.flush();
        return error.FailedSslConnect;
    }

    defer {
        openssl.SSL_set_shutdown(ssl, openssl.SSL_RECEIVED_SHUTDOWN | openssl.SSL_SENT_SHUTDOWN);
        _ = openssl.SSL_shutdown(ssl);
    }

    const data = try allocator.alloc(u8, address.len + 4);

    _ = try std.fmt.bufPrint(data, "{s}\r\n", .{address});
    const data_len: c_int = @intCast(data.len);

    if (openssl.SSL_write(ssl, data.ptr, data_len) <= 0) {
        try stderr.print("Could not write to server\n", .{});
        try ebw.flush();
        return error.WriteFailed;
    }
    allocator.free(data);

    const buf = try allocator.alloc(u8, 1024);
    var response = std.ArrayList([]const u8).init(allocator);
    const buf_len: c_int = @intCast(buf.len);

    const heap = std.heap.page_allocator;
    var n = openssl.SSL_read(ssl, buf.ptr, buf_len);
    while (n > 0) {
        const tempInt: usize = @intCast(n);
        const tempBuf = try std.fmt.allocPrint(heap, "{s}", .{buf[0..tempInt]});
        errdefer heap.free(tempBuf);
        try response.append(tempBuf);
        n = openssl.SSL_read(ssl, buf.ptr, buf_len);
    }
    allocator.free(buf);

    for (response.items) |line| {
        try stdout.print("{s}", .{line});
        try bw.flush();
    }
    response.deinit();
    client.close();
}
