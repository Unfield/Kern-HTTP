const std = @import("std");

pub const Method = enum(u8) {
    GET,
    HEAD,
    POST,
    PUT,
    DELETE,
    CONNECT,
    OPTIONS,
    TRACE,
    PATCH,

    pub fn fromBytes(bytes: []const u8) ?Method {
        if (std.mem.eql(u8, bytes, "GET")) return .GET;
        if (std.mem.eql(u8, bytes, "HEAD")) return .HEAD;
        if (std.mem.eql(u8, bytes, "POST")) return .POST;
        if (std.mem.eql(u8, bytes, "PUT")) return .PUT;
        if (std.mem.eql(u8, bytes, "DELETE")) return .DELETE;
        if (std.mem.eql(u8, bytes, "CONNECT")) return .CONNECT;
        if (std.mem.eql(u8, bytes, "OPTIONS")) return .OPTIONS;
        if (std.mem.eql(u8, bytes, "TRACE")) return .TRACE;
        if (std.mem.eql(u8, bytes, "PATCH")) return .PATCH;
        return null;
    }

    pub fn toBytes(self: Method) []const u8 {
        switch (self) {
            .GET => return "GET",
            .HEAD => return "HEAD",
            .POST => return "POST",
            .PUT => return "PUT",
            .DELETE => return "DELETE",
            .CONNECT => return "CONNECT",
            .OPTIONS => return "OPTIONS",
            .TRACE => return "TRACE",
            .PATCH => return "PATCH",
        }
    }

    pub fn format(self: Method, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.writeAll(self.toBytes());
    }
};
