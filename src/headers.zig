const std = @import("std");

pub const Headers = struct {
    allocator: std.mem.Allocator,
    map: std.StringHashMap([]const u8),

    pub fn init(allocator: std.mem.Allocator) Headers {
        return Headers{
            .allocator = allocator,
            .map = std.StringHashMap([]const u8).init(allocator),
        };
    }

    pub fn deinit(self: *Headers) void {
        var it = self.map.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
        }
        self.map.deinit();
    }

    pub fn insert(self: *Headers, key: []const u8, value: []const u8) !void {
        const lower_key = try self.toLowerAlloc(key);
        if (self.map.get(lower_key)) |_| {
            self.allocator.free(lower_key);
        }
        try self.map.put(lower_key, value);
    }

    pub fn get(self: *const Headers, key: []const u8) ?[]const u8 {
        var buf: [256]u8 = undefined;
        var len = key.len;
        if (len > buf.len) len = buf.len;
        for (key[0..len], 0..) |c, i| {
            buf[i] = std.ascii.toLower(c);
        }
        return self.map.get(buf[0..len]);
    }

    fn toLowerAlloc(self: *Headers, s: []const u8) ![]u8 {
        var buf = try self.allocator.alloc(u8, s.len);
        for (s, 0..) |c, i| {
            buf[i] = std.ascii.toLower(c);
        }
        return buf;
    }
};
