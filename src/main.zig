const std = @import("std");
const HttpReq = @import("request.zig");
const HttpRes = @import("response.zig");

pub fn main() !void {
    try runHTTPServer();
}

// Basic http server might be removed in the future
pub fn runHTTPServer() !void {
    var gpa_alloc = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa_alloc.deinit() == .ok);
    const gpa = gpa_alloc.allocator();

    const port: u16 = 8080;
    const hostaddress: []const u8 = "0.0.0.0";

    const addr = try std.net.Address.parseIp4(hostaddress, port);
    var server = addr.listen(.{}) catch |err| {
        std.log.err("Server listening on {s}:{d} ({any})", .{ hostaddress, port, err });
        return;
    };

    std.log.info("Server listening on {s}:{d}", .{ hostaddress, port });

    while (true) {
        const conn = try server.accept();
        _ = try std.Thread.spawn(.{}, handleConnection, .{ gpa, conn });
    }
}

fn handleConnection(gpa: std.mem.Allocator, conn: std.net.Server.Connection) !void {
    defer conn.stream.close();

    const reader = conn.stream.reader();
    const writer = conn.stream.writer();
    var buffer: [4096]u8 = undefined;

    while (true) {
        var request = HttpReq.parseRequest(gpa, reader, &buffer) catch |err| {
            if (err == error.ConnectionClosed) break;
            std.log.err("Parse error: {any}", .{err});
            break;
        };
        defer request.deinit();

        var response = HttpRes.HttpResponse.init(gpa);
        defer response.deinit();

        if (request.version == .Http1_0) {
            try response.headers.insert("Connection", "keep-alive");
        }

        response.setStatus(.OK);
        try response.setBody("Hello from Kern HTTP!");

        try response.send(writer);

        if (request.shouldClose() or response.shouldClose()) {
            std.log.debug("Closed connection: {any}", .{conn.address});
            break;
        }
    }
}
