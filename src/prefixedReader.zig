const std = @import("std");

pub fn PrefixedReader(comptime ReaderType: type) type {
    return struct {
        prefix: []const u8,
        prefix_pos: usize = 0,
        _reader: ReaderType,

        pub const Error = ReaderType.Error;
        pub const Reader = std.io.Reader(*@This(), Error, read);

        pub fn init(prefix: []const u8, r: ReaderType) @This() {
            return .{
                .prefix = prefix,
                .prefix_pos = 0,
                ._reader = r,
            };
        }

        pub fn reader(self: *@This()) Reader {
            return .{ .context = self };
        }

        pub fn read(self: *@This(), buf: []u8) !usize {
            if (self.prefix_pos < self.prefix.len) {
                const remaining = self.prefix[self.prefix_pos..];
                const to_copy = @min(buf.len, remaining.len);
                std.mem.copyForwards(u8, buf[0..to_copy], remaining[0..to_copy]);
                self.prefix_pos += to_copy;
                return to_copy;
            }

            return try self._reader.read(buf);
        }
    };
}
