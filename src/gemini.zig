const std = @import("std");
const tls = @import("tls");

const mem = std.mem;
const net = std.net;

pub fn protocolCheck(address: []const u8) !void {
    var splitUri = std.mem.splitAny(u8, address, "://");
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

pub fn init(allocator: mem.Allocator, address: []const u8) !Stream {
    try protocolCheck(address);
    const host = try urlToUri(address);
    const stream: net.Stream = net.tcpConnectToHost(allocator, host, 1965) catch |err| {
        return err;
    };

    return Stream{ .socket = stream, .host = host, .allocator = allocator };
}

fn trimUrl(allocator: mem.Allocator, data: []u8) !std.ArrayList([]u8) {
    var response = std.ArrayList([]u8).init(allocator);
    const heap = std.heap.page_allocator;
    for (data) |char| {
        if (char != 0) {
            const tempBuf = try std.fmt.allocPrint(heap, "{}", .{char});
            errdefer heap.free(tempBuf);
            try response.append(tempBuf);
        }
    }
    return response;
}

const Stream = struct {
    socket: net.Stream,
    host: []const u8,
    allocator: mem.Allocator,
    root_ca: ?tls.config.CertBundle = null,
    conn: ?tls.Connection(net.Stream) = null,
    pub fn connect(self: *Stream) !void {
        self.root_ca = try tls.config.CertBundle.fromSystem(self.allocator);
        const conn = try tls.client(self.socket, .{
            .host = self.host,
            .root_ca = self.root_ca.?,
            .insecure_skip_verify = true,
        });
        self.conn = conn;
    }
    pub fn deinit(self: *Stream) !void {
        self.root_ca.?.deinit(self.allocator);
        try self.conn.?.close();
        self.socket.close();
    }
    pub fn write(self: *Stream, data: []u8) !void {
        const url = try trimUrl(self.allocator, data);
        const buf = try self.allocator.alloc(u8, url.items.len + 4);
        const req = try std.fmt.bufPrint(buf, "{s}\r\n", .{url.items});
        std.debug.print("Len: {d}\n", .{req.len});
        try self.conn.?.writeAll(req);
        self.allocator.free(buf);
    }
    pub fn read(self: *Stream) !std.ArrayList([]const u8) {
        var response = std.ArrayList([]const u8).init(self.allocator);

        const heap = std.heap.page_allocator;
        while (try self.conn.?.next()) |res| {
            const tempBuf = try std.fmt.allocPrint(heap, "{s}", .{res});
            errdefer heap.free(tempBuf);
            try response.append(tempBuf);
        }
        return response;
    }
};
