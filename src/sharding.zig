const std = @import("std");
const Gateway = @import("gateway.zig");
const Snowflake = @import("snowflake.zig").Snowflake;

/// Mirrors the `session_start_limit` object returned by the Discord
/// `GET /gateway/bot` endpoint.
pub const SessionStartLimit = struct {
    total: u32,
    remaining: u32,
    reset_after: u64,
    max_concurrency: u32,
};

/// Parsed `GET /gateway/bot` response. `url` is owned by this struct and must
/// be released with `deinit`.
pub const GatewayBotInfo = struct {
    url: []const u8,
    shards: u32,
    session_start_limit: SessionStartLimit,

    pub fn parse(allocator: std.mem.Allocator, json_bytes: []const u8) !GatewayBotInfo {
        var parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{});
        defer parsed.deinit();

        const root = switch (parsed.value) {
            .object => |object| object,
            else => return error.InvalidGatewayBotPayload,
        };

        const url_value = root.get("url") orelse return error.InvalidGatewayBotPayload;
        const url_text = switch (url_value) {
            .string => |string| string,
            else => return error.InvalidGatewayBotPayload,
        };

        const shards = try readU32(root.get("shards") orelse return error.InvalidGatewayBotPayload);

        const limit_value = root.get("session_start_limit") orelse return error.InvalidGatewayBotPayload;
        const limit_object = switch (limit_value) {
            .object => |object| object,
            else => return error.InvalidGatewayBotPayload,
        };

        const limit = SessionStartLimit{
            .total = try readU32(limit_object.get("total") orelse return error.InvalidGatewayBotPayload),
            .remaining = try readU32(limit_object.get("remaining") orelse return error.InvalidGatewayBotPayload),
            .reset_after = try readU64(limit_object.get("reset_after") orelse return error.InvalidGatewayBotPayload),
            .max_concurrency = try readU32(limit_object.get("max_concurrency") orelse return error.InvalidGatewayBotPayload),
        };

        const url = try allocator.dupe(u8, url_text);
        return .{ .url = url, .shards = shards, .session_start_limit = limit };
    }

    pub fn deinit(self: *GatewayBotInfo, allocator: std.mem.Allocator) void {
        allocator.free(self.url);
        self.url = &.{};
    }
};

fn readU32(value: std.json.Value) !u32 {
    return switch (value) {
        .integer => |integer| if (integer < 0) error.InvalidGatewayBotPayload else @intCast(integer),
        else => error.InvalidGatewayBotPayload,
    };
}

fn readU64(value: std.json.Value) !u64 {
    return switch (value) {
        .integer => |integer| if (integer < 0) error.InvalidGatewayBotPayload else @intCast(integer),
        else => error.InvalidGatewayBotPayload,
    };
}

/// Lifecycle state of a single shard connection.
pub const ShardState = enum {
    idle,
    identifying,
    ready,
    resuming,
    disconnected,
};

/// Snapshot of a single shard within a `ShardManager`.
pub const ShardInfo = struct {
    id: u32,
    total: u32,
    state: ShardState = .idle,
    latency_ms: ?u64 = null,

    pub fn rateLimitKey(self: ShardInfo, max_concurrency: u32) !u32 {
        return Gateway.identifyRateLimitKey(self.id, max_concurrency);
    }
};

/// Coordinates a fixed set of shards: tracks per-shard state and resolves which
/// shard owns a given guild, mirroring the testable parts of discord.js
/// sharding.
pub const ShardManager = struct {
    allocator: std.mem.Allocator,
    total_shards: u32,
    max_concurrency: u32,
    shards: []ShardInfo,

    pub fn init(allocator: std.mem.Allocator, total_shards: u32, max_concurrency: u32) !ShardManager {
        if (total_shards == 0) return error.InvalidShardCount;
        if (max_concurrency == 0) return error.InvalidMaxConcurrency;

        const shards = try allocator.alloc(ShardInfo, total_shards);
        for (shards, 0..) |*shard, index| {
            shard.* = .{ .id = @intCast(index), .total = total_shards, .state = .idle };
        }
        return .{
            .allocator = allocator,
            .total_shards = total_shards,
            .max_concurrency = max_concurrency,
            .shards = shards,
        };
    }

    pub fn initFromGatewayBot(allocator: std.mem.Allocator, info: GatewayBotInfo) !ShardManager {
        return init(allocator, info.shards, info.session_start_limit.max_concurrency);
    }

    pub fn deinit(self: *ShardManager) void {
        self.allocator.free(self.shards);
        self.shards = &.{};
    }

    pub fn shardIdForGuild(self: ShardManager, guild_id: Snowflake) !u32 {
        return Gateway.shardIdForGuild(guild_id, self.total_shards);
    }

    pub fn shardForGuild(self: *ShardManager, guild_id: Snowflake) !*ShardInfo {
        const shard_id = try self.shardIdForGuild(guild_id);
        return &self.shards[shard_id];
    }

    pub fn setState(self: *ShardManager, shard_id: u32, state: ShardState) !void {
        if (shard_id >= self.total_shards) return error.InvalidShard;
        self.shards[shard_id].state = state;
    }

    pub fn rateLimitKey(self: ShardManager, shard_id: u32) !u32 {
        if (shard_id >= self.total_shards) return error.InvalidShard;
        return Gateway.identifyRateLimitKey(shard_id, self.max_concurrency);
    }

    pub fn readyCount(self: ShardManager) usize {
        var count: usize = 0;
        for (self.shards) |shard| {
            if (shard.state == .ready) count += 1;
        }
        return count;
    }

    pub fn allReady(self: ShardManager) bool {
        return self.readyCount() == self.shards.len;
    }

    /// Number of distinct identify rate-limit buckets in use.
    pub fn bucketCount(self: ShardManager) u32 {
        return @min(self.total_shards, self.max_concurrency);
    }
};

test "GatewayBotInfo.parse round-trips all fields" {
    const json =
        \\{"url":"wss://gateway.discord.gg","shards":9,"session_start_limit":{"total":1000,"remaining":999,"reset_after":86400000,"max_concurrency":16}}
    ;
    var info = try GatewayBotInfo.parse(std.testing.allocator, json);
    defer info.deinit(std.testing.allocator);

    try std.testing.expectEqualStrings("wss://gateway.discord.gg", info.url);
    try std.testing.expectEqual(@as(u32, 9), info.shards);
    try std.testing.expectEqual(@as(u32, 1000), info.session_start_limit.total);
    try std.testing.expectEqual(@as(u32, 999), info.session_start_limit.remaining);
    try std.testing.expectEqual(@as(u64, 86400000), info.session_start_limit.reset_after);
    try std.testing.expectEqual(@as(u32, 16), info.session_start_limit.max_concurrency);
}

test "ShardManager init, state transitions, readiness, and guild routing" {
    var manager = try ShardManager.init(std.testing.allocator, 5, 2);
    defer manager.deinit();

    try std.testing.expectEqual(@as(usize, 5), manager.shards.len);
    try std.testing.expectEqual(@as(u32, 4), manager.shards[4].id);
    try std.testing.expectEqual(@as(u32, 5), manager.shards[0].total);
    try std.testing.expectEqual(ShardState.idle, manager.shards[0].state);
    try std.testing.expectEqual(@as(usize, 0), manager.readyCount());
    try std.testing.expect(!manager.allReady());

    // Known example shared with gateway.zig: guild (42<<22)+1 with 5 shards -> shard 2.
    const guild = Snowflake.init((42 << 22) + 1);
    try std.testing.expectEqual(@as(u32, 2), try manager.shardIdForGuild(guild));

    const shard = try manager.shardForGuild(guild);
    try std.testing.expectEqual(@as(u32, 2), shard.id);

    try manager.setState(2, .identifying);
    try std.testing.expectEqual(ShardState.identifying, manager.shards[2].state);
    try manager.setState(2, .ready);
    try std.testing.expectEqual(@as(usize, 1), manager.readyCount());

    for (0..manager.total_shards) |index| {
        try manager.setState(@intCast(index), .ready);
    }
    try std.testing.expectEqual(@as(usize, 5), manager.readyCount());
    try std.testing.expect(manager.allReady());

    // bucketCount = min(total_shards, max_concurrency) = min(5, 2) = 2.
    try std.testing.expectEqual(@as(u32, 2), manager.bucketCount());
    // identify rate-limit key = shard_id % max_concurrency.
    try std.testing.expectEqual(@as(u32, 1), try manager.rateLimitKey(3));
    try std.testing.expectEqual(@as(u32, 1), try manager.shards[3].rateLimitKey(manager.max_concurrency));
}

test "ShardManager error cases" {
    try std.testing.expectError(error.InvalidShardCount, ShardManager.init(std.testing.allocator, 0, 4));
    try std.testing.expectError(error.InvalidMaxConcurrency, ShardManager.init(std.testing.allocator, 4, 0));

    var manager = try ShardManager.init(std.testing.allocator, 3, 1);
    defer manager.deinit();

    try std.testing.expectError(error.InvalidShard, manager.setState(3, .ready));
    try std.testing.expectError(error.InvalidShard, manager.rateLimitKey(3));
}

test "initFromGatewayBot derives shards and concurrency" {
    const json =
        \\{"url":"wss://gateway.discord.gg","shards":4,"session_start_limit":{"total":1000,"remaining":1000,"reset_after":0,"max_concurrency":1}}
    ;
    var info = try GatewayBotInfo.parse(std.testing.allocator, json);
    defer info.deinit(std.testing.allocator);

    var manager = try ShardManager.initFromGatewayBot(std.testing.allocator, info);
    defer manager.deinit();

    try std.testing.expectEqual(@as(u32, 4), manager.total_shards);
    try std.testing.expectEqual(@as(u32, 1), manager.max_concurrency);
    try std.testing.expectEqual(@as(u32, 1), manager.bucketCount());
}
