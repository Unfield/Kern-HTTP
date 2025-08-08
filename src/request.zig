const std = @import("std");
const Method = @import("method.zig").Method;
const Version = @import("version.zig").Version;

const ParseError = error{
    AllocatorInvalid,
    HeadersInvalid,
    ConnectionClosed,
    MethodInvalid,
    PathInvalid,
    VersionInvalid,
};

pub const HttpRequest = struct {
    method: Method,
    path: []const u8,
    version: Version,
    headers: []const u8,
};

pub fn parseRequest(reader: std.net.Stream.Reader, buffer: []u8) !HttpRequest {
    var buf_len: usize = 0;

    while (true) {
        const n = try reader.read(buffer[buf_len..]);
        if (n == 0) return ParseError.ConnectionClosed;
        buf_len += n;

        if (std.mem.indexOf(u8, buffer[0..buf_len], "\r\n\r\n")) |pos| {
            const header_block = buffer[0..pos];
            var lines = std.mem.splitSequence(u8, header_block, "\r\n");

            const request_line = lines.next().?;
            var parts = std.mem.splitSequence(u8, request_line, " ");
            const method = parts.next() orelse {
                return ParseError.MethodInvalid;
            };
            const path = parts.next() orelse {
                return ParseError.PathInvalid;
            };
            const version = parts.next() orelse {
                return ParseError.VersionInvalid;
            };

            const headers_start = request_line.len + 2;
            const headers = header_block[headers_start..];

            return HttpRequest{
                .method = Method.fromBytes(method) orelse {
                    return ParseError.MethodInvalid;
                },
                .path = path,
                .version = Version.fromBytes(version) orelse {
                    return ParseError.VersionInvalid;
                },
                .headers = headers,
            };
        }
    }

    return ParseError.ConnectionClosed;
}
