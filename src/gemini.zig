const std = @import("std");
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
