const std = @import("std");

pub const discord_epoch_ms: u64 = 1420070400000;

pub const SnowflakeParts = struct {
    timestamp_ms: u64,
    timestamp_offset_ms: u64,
    worker_id: u8,
    process_id: u8,
    increment: u16,
};

pub const Snowflake = struct {
    value: u64,

    pub fn init(value: u64) Snowflake {
        return .{ .value = value };
    }

    pub fn fromTimestampMillis(timestamp_ms: u64) !Snowflake {
        if (timestamp_ms < discord_epoch_ms) return error.InvalidSnowflakeTimestamp;
        return .{ .value = (timestamp_ms - discord_epoch_ms) << 22 };
    }

    pub fn fromTimestampSeconds(timestamp_seconds: u64) !Snowflake {
        return fromTimestampMillis(timestamp_seconds * std.time.ms_per_s);
    }

    pub fn parse(text: []const u8) !Snowflake {
        if (text.len == 0) return error.InvalidSnowflake;
        return .{ .value = std.fmt.parseInt(u64, text, 10) catch return error.InvalidSnowflake };
    }

    pub fn format(self: Snowflake, allocator: std.mem.Allocator) ![]u8 {
        return std.fmt.allocPrint(allocator, "{d}", .{self.value});
    }

    pub fn eql(self: Snowflake, other: Snowflake) bool {
        return self.value == other.value;
    }

    pub fn timestampOffsetMillis(self: Snowflake) u64 {
        return self.value >> 22;
    }

    pub fn timestampMillis(self: Snowflake) u64 {
        return self.timestampOffsetMillis() + discord_epoch_ms;
    }

    pub fn timestampSeconds(self: Snowflake) u64 {
        return self.timestampMillis() / std.time.ms_per_s;
    }

    pub fn workerId(self: Snowflake) u8 {
        return @intCast((self.value >> 17) & 0x1F);
    }

    pub fn processId(self: Snowflake) u8 {
        return @intCast((self.value >> 12) & 0x1F);
    }

    pub fn increment(self: Snowflake) u16 {
        return @intCast(self.value & 0xFFF);
    }

    pub fn deconstruct(self: Snowflake) SnowflakeParts {
        return .{
            .timestamp_ms = self.timestampMillis(),
            .timestamp_offset_ms = self.timestampOffsetMillis(),
            .worker_id = self.workerId(),
            .process_id = self.processId(),
            .increment = self.increment(),
        };
    }
};

test "snowflake parse format and timestamps" {
    const snowflake = try Snowflake.parse("123456789012345678");
    try std.testing.expectEqual(@as(u64, 123456789012345678), snowflake.value);

    const text = try snowflake.format(std.testing.allocator);
    defer std.testing.allocator.free(text);
    try std.testing.expectEqualStrings("123456789012345678", text);

    const one_ms_after_epoch = Snowflake.init(1 << 22);
    try std.testing.expectEqual(@as(u64, 1), one_ms_after_epoch.timestampOffsetMillis());
    try std.testing.expectEqual(@as(u64, 1420070400001), one_ms_after_epoch.timestampMillis());
    try std.testing.expectEqual(@as(u64, 1420070400), one_ms_after_epoch.timestampSeconds());

    const from_millis = try Snowflake.fromTimestampMillis(1420070400001);
    try std.testing.expectEqual(@as(u64, 1 << 22), from_millis.value);

    const from_seconds = try Snowflake.fromTimestampSeconds(1420070401);
    try std.testing.expectEqual(@as(u64, 1000 << 22), from_seconds.value);

    try std.testing.expectError(error.InvalidSnowflakeTimestamp, Snowflake.fromTimestampMillis(1420070399999));
}

test "snowflake deconstructs worker process and increment bits" {
    const snowflake = Snowflake.init((1234 << 22) | (17 << 17) | (9 << 12) | 4095);
    try std.testing.expectEqual(@as(u64, 1234), snowflake.timestampOffsetMillis());
    try std.testing.expectEqual(@as(u8, 17), snowflake.workerId());
    try std.testing.expectEqual(@as(u8, 9), snowflake.processId());
    try std.testing.expectEqual(@as(u16, 4095), snowflake.increment());

    const parts = snowflake.deconstruct();
    try std.testing.expectEqual(@as(u64, discord_epoch_ms + 1234), parts.timestamp_ms);
    try std.testing.expectEqual(@as(u64, 1234), parts.timestamp_offset_ms);
    try std.testing.expectEqual(@as(u8, 17), parts.worker_id);
    try std.testing.expectEqual(@as(u8, 9), parts.process_id);
    try std.testing.expectEqual(@as(u16, 4095), parts.increment);
}
