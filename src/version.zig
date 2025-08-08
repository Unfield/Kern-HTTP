const std = @import("std");

pub const Version = enum(u8) {
    Http1_0,
    Http1_1,

    pub fn fromBytes(bytes: []const u8) ?Version {
        if (std.mem.eql(u8, bytes, "HTTP/1.0")) return .Http1_0;
        if (std.mem.eql(u8, bytes, "HTTP/1.1")) return .Http1_1;
        return null;
    }

    pub fn toBytes(self: Version) []const u8 {
        switch (self) {
            .Http1_0 => return "HTTP/1.0",
            .Http1_1 => return "HTTP/1.1",
        }
    }

    pub fn format(self: Version, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.writeAll(self.toBytes());
    }
};
