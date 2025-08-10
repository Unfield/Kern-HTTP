const std = @import("std");
const Version = @import("version.zig").Version;
const Status = @import("status.zig").HttpStatus;
const Headers = @import("headers.zig").Headers;

const KERN_VERSION = "KernHTTP/0.1";

pub const HttpResponse = struct {
    version: Version = .Http1_1,
    status_code: Status = .OK,
    headers: Headers,
    body: []const u8 = "",

    pub fn init(allocator: std.mem.Allocator) HttpResponse {
        var h = Headers.init(allocator);
        h.insert("Server", KERN_VERSION) catch {};
        return HttpResponse{ .headers = h };
    }

    pub fn deinit(self: *HttpResponse) void {
        self.headers.deinit();
    }

    pub fn setStatus(self: *HttpResponse, status: Status) void {
        self.status_code = status;
    }

    pub fn setBody(self: *HttpResponse, body: []const u8) !void {
        self.body = body;
        var buf: [32]u8 = undefined;
        const len_str = try std.fmt.bufPrint(&buf, "{}", .{body.len});
        try self.headers.insert("Content-Length", len_str);
    }

    pub fn send(self: *const HttpResponse, writer: std.net.Stream.Writer) !void {
        try writer.print("{s} {} {s}\r\n", .{ self.version, self.status_code.toInt(), self.status_code.reasonPhrase() });

        var it = self.headers.map.iterator();
        while (it.next()) |entry| {
            try writer.print("{s}: {s}\r\n", .{ entry.key_ptr.*, entry.value_ptr.* });
        }

        try writer.writeAll("\r\n");

        if (self.body.len > 0) {
            try writer.writeAll(self.body);
        }
    }

    pub fn shouldClose(self: *HttpResponse) bool {
        return self.hasHeaderValue("Connection", "close");
    }

    pub fn hasHeaderValue(self: HttpResponse, name: []const u8, value: []const u8) bool {
        if (self.headers.get(name)) |v| {
            return std.ascii.eqlIgnoreCase(v, value);
        }
        return false;
    }
};
