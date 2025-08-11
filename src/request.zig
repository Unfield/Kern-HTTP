const std = @import("std");
const Method = @import("method.zig").Method;
const Version = @import("version.zig").Version;
const Headers = @import("headers.zig").Headers;
const PrefixedReader = @import("prefixedReader.zig").PrefixedReader;

const ParseError = error{
    AllocatorInvalid,
    HeadersInvalid,
    ConnectionClosed,
    MethodInvalid,
    PathInvalid,
    VersionInvalid,
    RequestInvalid,
    BodyAlreadyConsumed,
};

const BodyState = enum {
    Unread,
    Buffered,
    Streamed,
};

pub const HttpRequest = struct {
    method: Method,
    path: []const u8,
    version: Version,
    headers: Headers,

    //Internal
    _bodyReader: ?PrefixedReader(std.net.Stream.Reader) = null,
    _bodyLength: ?usize = null,
    _bodyState: BodyState = .Unread,
    _bodyBuffer: ?std.ArrayList(u8) = null,

    pub fn deinit(self: *HttpRequest) void {
        self.headers.deinit();
        if (self._bodyBuffer) |*buf_list| {
            buf_list.deinit();
        }
    }

    pub fn shouldClose(self: *HttpRequest) bool {
        if (self.version == .Http1_0) {
            return !self.hasHeaderValue("Connection", "keep-alive");
        }
        if (self.version == .Http1_1) {
            return self.hasHeaderValue("Connection", "close");
        }
        return true;
    }

    pub fn hasHeaderValue(self: HttpRequest, name: []const u8, value: []const u8) bool {
        if (self.headers.get(name)) |v| {
            return std.ascii.eqlIgnoreCase(v, value);
        }
        return false;
    }

    pub fn body(self: *HttpRequest, allocator: std.mem.Allocator) ![]u8 {
        if (self._bodyState == .Streamed) return error.BodyAlreadyConsumed;

        if (self._bodyBuffer) |*buf_list| {
            return buf_list.items;
        }

        const len = self._bodyLength orelse 0;
        if (len == 0) return &[_]u8{};

        var list = try std.ArrayList(u8).initCapacity(allocator, len);

        var buf: [1024]u8 = undefined;
        var total_read: usize = 0;

        while (total_read < len) {
            const to_read = @min(buf.len, len - total_read);
            const n = try self._bodyReader.?.read(buf[0..to_read]);
            if (n == 0) break;
            try list.appendSlice(buf[0..n]);
            total_read += n;
        }

        self._bodyBuffer = list;

        self._bodyState = .Buffered;

        return self._bodyBuffer.?.items;
    }

    pub fn bodyString(self: *HttpRequest) ![]const u8 {
        _ = self;
        return "";
    }

    pub fn bindJson(self: *HttpRequest, allocator: std.mem.Allocator, comptime T: type, out: *T) !void {
        const body_bytes = try self.body(allocator);

        var parsed = try std.json.parseFromSlice(T, allocator, body_bytes, .{});
        defer parsed.deinit();

        out.* = parsed.value;
    }

    pub fn bodyReader(self: *HttpRequest) !?*PrefixedReader(std.net.Stream.Reader) {
        if (self._bodyState == .Streamed or self._bodyState == .Buffered) return error.BodyAlreadyConsumed;
        self._bodyState = .Streamed;
        return if (self._bodyReader) |*r| r else null;
    }
};

pub fn parseRequest(allocator: std.mem.Allocator, reader: std.net.Stream.Reader, buffer: []u8) !HttpRequest {
    var buf_len: usize = 0;
    var parsedRequest: ?HttpRequest = null;

    while (true) {
        const n = try reader.read(buffer[buf_len..]);
        if (n == 0) return ParseError.ConnectionClosed;
        buf_len += n;

        var body_start: usize = undefined;
        var already_read_buffer: []const u8 = buffer[0..0];

        if (std.mem.indexOf(u8, buffer[0..buf_len], "\r\n\r\n")) |pos| {
            const header_block = buffer[0..pos];
            var lines = std.mem.splitSequence(u8, header_block, "\r\n");

            const request_line = lines.next().?;
            var parts = std.mem.splitSequence(u8, request_line, " ");
            const method = parts.next() orelse return ParseError.MethodInvalid;
            const path = parts.next() orelse return ParseError.PathInvalid;
            const version = parts.next() orelse return ParseError.VersionInvalid;

            const headers_start = request_line.len + 2;

            parsedRequest = HttpRequest{
                .method = Method.fromBytes(method) orelse return ParseError.MethodInvalid,
                .path = path,
                .version = Version.fromBytes(version) orelse return ParseError.VersionInvalid,
                .headers = parseHeaders(allocator, header_block[headers_start..]) catch return ParseError.HeadersInvalid,
            };

            body_start = pos + 4;
            already_read_buffer = buffer[body_start..buf_len];
        }

        if (parsedRequest == null) {
            return error.RequestInvalid;
        }

        const content_length = try std.fmt.parseInt(usize, parsedRequest.?.headers.get("Content-Length") orelse "0", 10);

        if (content_length <= 0) {
            return parsedRequest orelse error.RequestInvalid;
        }

        parsedRequest.?._bodyLength = content_length;

        const PrefixedReaderType = PrefixedReader(@TypeOf(reader));
        const prefixed = PrefixedReaderType.init(already_read_buffer, reader);
        parsedRequest.?._bodyReader = prefixed;

        return parsedRequest orelse error.RequestInvalid;
    }

    return error.RequestInvalid;
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
