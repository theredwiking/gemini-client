const std = @import("std");
const tls = @import("tls");

const mem = std.mem;
const net = std.net;

pub fn protocolCheck(address: []const u8) !void {
    var splitUri = std.mem.split(u8, address, "://");
    const protocol: []const u8 = splitUri.next() orelse {
        return error.NoProtocol;
    };

    if (!std.mem.eql(u8, protocol, "gemini")) {
        return error.UnsupportedProtocol;
    }
}

pub fn urlToUri(address: []const u8) !([]const u8) {
    const uri = std.Uri.parse(address) catch |err| {
        return err;
    };
    return uri.host.?.percent_encoded;
}

pub fn connect(allocator: mem.Allocator, address: []const u8) !Stream {
    try protocolCheck(address);
    const host = try urlToUri(address);
    const stream: net.Stream = net.tcpConnectToHost(allocator, host, 1965) catch |err| {
        return err;
    };

    return Stream{ .socket = stream, .host = host, .allocator = allocator };
}

const Stream = struct {
    socket: net.Stream,
    host: []const u8,
    allocator: mem.Allocator,
    root_ca: ?tls.CertBundle = null,
    pub fn tlsConnect(self: *Stream) !tls.Connection(@TypeOf(self.socket)) {
        self.root_ca = try tls.CertBundle.fromSystem(self.allocator);
        const conn = try tls.client(self.socket, .{
            .host = self.host,
            .root_ca = self.root_ca.?,
            .insecure_skip_verify = true,
        });
        return conn;
    }
    pub fn deinit(self: *Stream) !void {
        self.root_ca.?.deinit(self.allocator);
        self.socket.close();
    }
};
