const std = @import("std");
const Method = @import("method.zig").Method;
const Version = @import("version.zig").Version;
const Headers = @import("headers.zig").Headers;

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
    headers: Headers,
};

pub fn parseRequest(allocator: std.mem.Allocator, reader: std.net.Stream.Reader, buffer: []u8) !HttpRequest {
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

            return HttpRequest{
                .method = Method.fromBytes(method) orelse {
                    return ParseError.MethodInvalid;
                },
                .path = path,
                .version = Version.fromBytes(version) orelse {
                    return ParseError.VersionInvalid;
                },
                .headers = parseHeaders(allocator, header_block[headers_start..]) catch {
                    return ParseError.HeadersInvalid;
                },
            };
        }
    }

    return ParseError.ConnectionClosed;
}

fn parseHeaders(
    allocator: std.mem.Allocator,
    raw: []const u8,
) !Headers {
    var headers = Headers.init(allocator);

    var lines = std.mem.splitSequence(u8, raw, "\r\n");
    while (lines.next()) |line| {
        if (line.len == 0) break;
        if (std.mem.indexOfScalar(u8, line, ':')) |colon_index| {
            const key = std.mem.trim(u8, line[0..colon_index], " ");
            const value = std.mem.trim(u8, line[colon_index + 1 ..], " ");
            try headers.insert(key, value);
        }
    }

    return headers;
}
