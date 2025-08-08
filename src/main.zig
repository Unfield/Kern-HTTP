const std = @import("std");
const req = @import("request.zig");

pub fn main() !void {
    runHTTPServer();
}

// Basic http server might be removed in the future
pub fn runHTTPServer() void {
    var gpa_alloc = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa_alloc.deinit() == .ok);
    const gpa = gpa_alloc.allocator();

    _ = gpa;

    const port: u16 = 8080;
    const hostaddress: [4]u8 = .{ 0, 0, 0, 0 };

    const addr = std.net.Address.initIp4(hostaddress, port);
    var server = addr.listen(.{}) catch |err| {
        std.log.err("Server listening on {s}:{d} ({any})", .{ hostaddress, port, err });
        return;
    };

    std.log.info("Server listening on {s}:{d}", .{ hostaddress, port });

    while (true) {
        var client = server.accept() catch |err| {
            std.log.err("Failed to accept connection: {any}", .{err});
            continue;
        };
        std.log.info("Client connected", .{});
        defer client.stream.close();

        const client_reader = client.stream.reader();
        //const client_writer = client.stream.writer();

        var buffer: [1024]u8 = undefined;

        while (true) {
            const request = req.parseRequest(client_reader, &buffer) catch |err| {
                if (err == error.ConnectionClosed) {
                    std.log.info("Client closed connection", .{});
                    break;
                }
                std.log.err("Failed to parse http request: {any}", .{err});
                break;
            };

            std.log.info("Version: {s}, Method: {s}, Path: {s}", .{ request.version, request.method, request.path });
        }
    }
}
