const std = @import("std");
const Gateway = @import("../protocol.zig");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;

/// Mirrors the `session_start_limit` object returned by the Discord
/// `GET /gateway/bot` endpoint.
const Root = @import("../sharding.zig");
const GatewayBotInfo = Root.GatewayBotInfo;
const ShardState = Root.ShardState;
const ShardInfo = Root.ShardInfo;
const IdentifyGroup = Root.IdentifyGroup;
const ShardCluster = Root.ShardCluster;
const ShardClusterProcessSpec = Root.ShardClusterProcessSpec;
const deinitShardClusterProcessSpecs = Root.deinitShardClusterProcessSpecs;
const deinitShardClusters = Root.deinitShardClusters;
const ShardClusterPlanOptions = Root.ShardClusterPlanOptions;
const ShardProcessOptions = Root.ShardProcessOptions;
const ShardProcessSpec = Root.ShardProcessSpec;
const buildShardProcessSpec = Root.buildShardProcessSpec;
const buildShardClusterProcessSpec = Root.buildShardClusterProcessSpec;
const deinitShardProcessSpecs = Root.deinitShardProcessSpecs;
const ShardRestartPolicy = Root.ShardRestartPolicy;
const shouldRestartShard = Root.shouldRestartShard;
const ShardIpcMessageKind = Root.ShardIpcMessageKind;
const ShardIpcMessage = Root.ShardIpcMessage;
const shardIpcHandler = Root.shardIpcHandler;
const ShardIpcRoute = Root.ShardIpcRoute;
const ShardIpcRouter = Root.ShardIpcRouter;
const ShardSupervisor = Root.ShardSupervisor;

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

    pub fn stateCount(self: ShardManager, state: ShardState) usize {
        var count: usize = 0;
        for (self.shards) |shard| {
            if (shard.state == state) count += 1;
        }
        return count;
    }

    pub fn disconnectedCount(self: ShardManager) usize {
        return self.stateCount(.disconnected);
    }

    pub fn setLatency(self: *ShardManager, shard_id: u32, latency_ms: ?u64) !void {
        if (shard_id >= self.total_shards) return error.InvalidShard;
        self.shards[shard_id].latency_ms = latency_ms;
    }

    pub fn averageLatencyMs(self: ShardManager) ?u64 {
        var sum: u128 = 0;
        var count: u64 = 0;
        for (self.shards) |shard| {
            if (shard.latency_ms) |latency_ms| {
                sum += latency_ms;
                count += 1;
            }
        }
        if (count == 0) return null;
        return @intCast(sum / count);
    }

    pub fn clusterProcessSpecs(
        self: ShardManager,
        allocator: std.mem.Allocator,
        clusters: []const ShardCluster,
        options: ShardProcessOptions,
    ) ![]ShardClusterProcessSpec {
        const specs = try allocator.alloc(ShardClusterProcessSpec, clusters.len);
        var initialized: usize = 0;
        errdefer {
            for (specs[0..initialized]) |*spec| spec.deinit();
            allocator.free(specs);
        }

        for (specs, clusters) |*spec, cluster| {
            spec.* = try buildShardClusterProcessSpec(allocator, cluster, self.total_shards, options);
            initialized += 1;
        }
        return specs;
    }

    pub fn shardIdsForBucket(self: ShardManager, allocator: std.mem.Allocator, bucket_id: u32) ![]u32 {
        if (bucket_id >= self.bucketCount()) return error.InvalidShardBucket;

        var count: usize = 0;
        for (self.shards) |shard| {
            if (try shard.rateLimitKey(self.max_concurrency) == bucket_id) count += 1;
        }

        const shard_ids = try allocator.alloc(u32, count);
        errdefer allocator.free(shard_ids);
        var index: usize = 0;
        for (self.shards) |shard| {
            if (try shard.rateLimitKey(self.max_concurrency) == bucket_id) {
                shard_ids[index] = shard.id;
                index += 1;
            }
        }
        return shard_ids;
    }

    pub fn identifyGroups(self: ShardManager, allocator: std.mem.Allocator) ![]IdentifyGroup {
        const groups = try allocator.alloc(IdentifyGroup, self.bucketCount());
        var initialized: usize = 0;
        errdefer {
            for (groups[0..initialized]) |*group| group.deinit();
            allocator.free(groups);
        }

        for (groups, 0..) |*group, index| {
            group.* = .{
                .bucket_id = @intCast(index),
                .shard_ids = try self.shardIdsForBucket(allocator, @intCast(index)),
                .allocator = allocator,
            };
            initialized += 1;
        }
        return groups;
    }

    pub fn clusterPlan(
        self: ShardManager,
        allocator: std.mem.Allocator,
        options: ShardClusterPlanOptions,
    ) ![]ShardCluster {
        if (options.shards_per_cluster == 0) return error.InvalidShardClusterSize;
        const cluster_count_u32 = (self.total_shards + options.shards_per_cluster - 1) / options.shards_per_cluster;
        const clusters = try allocator.alloc(ShardCluster, cluster_count_u32);
        var initialized: usize = 0;
        errdefer {
            for (clusters[0..initialized]) |*cluster| cluster.deinit();
            allocator.free(clusters);
        }

        for (clusters, 0..) |*cluster, index| {
            const cluster_id: u32 = @intCast(index);
            const first_shard = cluster_id * options.shards_per_cluster;
            const end = @min(first_shard + options.shards_per_cluster, self.total_shards);
            const count = end - first_shard;
            const shard_ids = try allocator.alloc(u32, count);
            for (shard_ids, 0..) |*slot, offset| slot.* = first_shard + @as(u32, @intCast(offset));
            cluster.* = .{ .id = cluster_id, .shard_ids = shard_ids, .allocator = allocator };
            initialized += 1;
        }
        return clusters;
    }

    pub fn deinitIdentifyGroups(allocator: std.mem.Allocator, groups: []IdentifyGroup) void {
        for (groups) |*group| group.deinit();
        allocator.free(groups);
    }

    pub fn processSpecs(self: ShardManager, allocator: std.mem.Allocator, options: ShardProcessOptions) ![]ShardProcessSpec {
        const specs = try allocator.alloc(ShardProcessSpec, self.total_shards);
        var initialized: usize = 0;
        errdefer {
            for (specs[0..initialized]) |*spec| spec.deinit();
            allocator.free(specs);
        }

        for (specs, 0..) |*spec, index| {
            spec.* = try buildShardProcessSpec(allocator, @intCast(index), self.total_shards, options);
            initialized += 1;
        }
        return specs;
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

test "ShardManager identify groups and latency aggregation" {
    var manager = try ShardManager.init(std.testing.allocator, 5, 2);
    defer manager.deinit();

    const even_bucket = try manager.shardIdsForBucket(std.testing.allocator, 0);
    defer std.testing.allocator.free(even_bucket);
    try std.testing.expectEqualSlices(u32, &.{ 0, 2, 4 }, even_bucket);

    const odd_bucket = try manager.shardIdsForBucket(std.testing.allocator, 1);
    defer std.testing.allocator.free(odd_bucket);
    try std.testing.expectEqualSlices(u32, &.{ 1, 3 }, odd_bucket);

    const groups = try manager.identifyGroups(std.testing.allocator);
    defer ShardManager.deinitIdentifyGroups(std.testing.allocator, groups);
    try std.testing.expectEqual(@as(usize, 2), groups.len);
    try std.testing.expectEqual(@as(u32, 0), groups[0].bucket_id);
    try std.testing.expectEqualSlices(u32, &.{ 0, 2, 4 }, groups[0].shard_ids);
    try std.testing.expectEqual(@as(u32, 1), groups[1].bucket_id);
    try std.testing.expectEqualSlices(u32, &.{ 1, 3 }, groups[1].shard_ids);

    try std.testing.expectEqual(@as(?u64, null), manager.averageLatencyMs());
    try manager.setLatency(0, 120);
    try manager.setLatency(2, 180);
    try std.testing.expectEqual(@as(?u64, 150), manager.averageLatencyMs());

    try manager.setState(0, .disconnected);
    try manager.setState(3, .disconnected);
    try std.testing.expectEqual(@as(usize, 2), manager.disconnectedCount());
    try std.testing.expectEqual(@as(usize, 2), manager.stateCount(.disconnected));

    const clusters = try manager.clusterPlan(std.testing.allocator, .{ .shards_per_cluster = 2 });
    defer deinitShardClusters(std.testing.allocator, clusters);
    try std.testing.expectEqual(@as(usize, 3), clusters.len);
    try std.testing.expectEqualSlices(u32, &.{ 0, 1 }, clusters[0].shard_ids);
    try std.testing.expectEqualSlices(u32, &.{ 2, 3 }, clusters[1].shard_ids);
    try std.testing.expectEqualSlices(u32, &.{4}, clusters[2].shard_ids);
    try std.testing.expectError(error.InvalidShardClusterSize, manager.clusterPlan(std.testing.allocator, .{ .shards_per_cluster = 0 }));

    const cluster_specs = try manager.clusterProcessSpecs(std.testing.allocator, clusters, .{
        .executable = "zig",
        .base_args = &.{"run"},
        .token = "token",
    });
    defer deinitShardClusterProcessSpecs(std.testing.allocator, cluster_specs);
    try std.testing.expectEqual(@as(usize, 3), cluster_specs.len);
    try std.testing.expectEqual(@as(u32, 0), cluster_specs[0].cluster_id);
    try std.testing.expectEqualSlices(u32, &.{ 0, 1 }, cluster_specs[0].shard_ids);
    try std.testing.expectEqualStrings("zig", cluster_specs[0].argv[0]);
    try std.testing.expectEqualStrings("run", cluster_specs[0].argv[1]);
    try std.testing.expectEqualStrings("DISCORD_CLUSTER_ID=0", cluster_specs[0].env[0]);
    try std.testing.expectEqualStrings("DISCORD_CLUSTER_SHARDS=0,1", cluster_specs[0].env[1]);
    try std.testing.expectEqualStrings("DISCORD_SHARD_COUNT=5", cluster_specs[0].env[2]);
    try std.testing.expectEqualStrings("DISCORD_TOKEN=token", cluster_specs[0].env[3]);
}

test "ShardManager error cases" {
    try std.testing.expectError(error.InvalidShardCount, ShardManager.init(std.testing.allocator, 0, 4));
    try std.testing.expectError(error.InvalidMaxConcurrency, ShardManager.init(std.testing.allocator, 4, 0));

    var manager = try ShardManager.init(std.testing.allocator, 3, 1);
    defer manager.deinit();

    try std.testing.expectError(error.InvalidShard, manager.setState(3, .ready));
    try std.testing.expectError(error.InvalidShard, manager.rateLimitKey(3));
}

test "ShardManager builds process specs for worker orchestration" {
    var manager = try ShardManager.init(std.testing.allocator, 2, 1);
    defer manager.deinit();

    const args = [_][]const u8{ "run", "bot" };
    const specs = try manager.processSpecs(std.testing.allocator, .{
        .executable = "zig",
        .base_args = &args,
        .token = "token",
    });
    defer deinitShardProcessSpecs(std.testing.allocator, specs);

    try std.testing.expectEqual(@as(usize, 2), specs.len);
    try std.testing.expectEqual(@as(u32, 0), specs[0].shard_id);
    try std.testing.expectEqual(@as(u32, 2), specs[0].total_shards);
    try std.testing.expectEqual(@as(usize, 3), specs[0].argv.len);
    try std.testing.expectEqualStrings("zig", specs[0].argv[0]);
    try std.testing.expectEqualStrings("run", specs[0].argv[1]);
    try std.testing.expectEqualStrings("bot", specs[0].argv[2]);
    try std.testing.expectEqual(@as(usize, 4), specs[0].env.len);
    try std.testing.expectEqualStrings("DISCORD_SHARD_ID=0", specs[0].env[0]);
    try std.testing.expectEqualStrings("DISCORD_SHARD_COUNT=2", specs[0].env[1]);
    try std.testing.expectEqualStrings("DISCORD_SHARD_RANGE=0,2", specs[0].env[2]);
    try std.testing.expectEqualStrings("DISCORD_TOKEN=token", specs[0].env[3]);

    try std.testing.expectEqualStrings("DISCORD_SHARD_ID=1", specs[1].env[0]);
    try std.testing.expectEqualStrings("DISCORD_SHARD_COUNT=2", specs[1].env[1]);
    try std.testing.expectEqualStrings("DISCORD_SHARD_RANGE=1,2", specs[1].env[2]);
    try std.testing.expectEqualStrings("DISCORD_TOKEN=token", specs[1].env[3]);
}

test "ShardSupervisor owns specs and tracks running count without spawning" {
    const io = std.Io.Threaded.global_single_threaded.io();
    var supervisor = try ShardSupervisor.init(std.testing.allocator, io, 2, 1, .{
        .executable = "zig",
        .base_args = &.{"version"},
    });
    defer supervisor.deinit();

    try std.testing.expectEqual(@as(u32, 2), supervisor.manager.total_shards);
    try std.testing.expectEqual(@as(usize, 2), supervisor.specs.len);
    try std.testing.expectEqual(@as(usize, 0), supervisor.runningCount());
    try std.testing.expectEqualStrings("zig", supervisor.specs[0].argv[0]);
    try std.testing.expectEqualStrings("version", supervisor.specs[0].argv[1]);
    try std.testing.expectEqualStrings("DISCORD_SHARD_ID=1", supervisor.specs[1].env[0]);
}

test "ShardSupervisor restart policy helpers classify exits" {
    try std.testing.expect(!shouldRestartShard(.never, .{ .exited = 1 }));
    try std.testing.expect(shouldRestartShard(.always, .{ .exited = 0 }));
    try std.testing.expect(!shouldRestartShard(.on_failure, .{ .exited = 0 }));
    try std.testing.expect(shouldRestartShard(.on_failure, .{ .exited = 1 }));
    try std.testing.expect(shouldRestartShard(.on_failure, .{ .unknown = 1 }));

    const io = std.Io.Threaded.global_single_threaded.io();
    var supervisor = try ShardSupervisor.initWithOptions(std.testing.allocator, io, 1, 1, .{
        .process = .{ .executable = "zig" },
        .restart_policy = .on_failure,
        .max_restarts_per_shard = 2,
    });
    defer supervisor.deinit();

    try std.testing.expectEqual(ShardRestartPolicy.on_failure, supervisor.restart_policy);
    try std.testing.expectEqual(@as(?u32, 2), supervisor.max_restarts_per_shard);
    try std.testing.expectEqual(@as(u32, 0), supervisor.restart_counts[0]);
}

test "ShardIpcMessage serializes Discord.js style shard messages" {
    var dispatch_out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer dispatch_out.deinit();
    try ShardIpcMessage.dispatch(2, "READY").writeJson(&dispatch_out.writer);
    try std.testing.expectEqualStrings(
        "{\"type\":\"dispatch\",\"shard_id\":2,\"payload\":\"READY\"}",
        dispatch_out.written(),
    );

    var eval_out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer eval_out.deinit();
    try ShardIpcMessage.eval(1, 99, "return \"ok\"\n").writeJson(&eval_out.writer);
    try std.testing.expectEqualStrings(
        "{\"type\":\"eval\",\"shard_id\":1,\"nonce\":99,\"payload\":\"return \\\"ok\\\"\\n\"}",
        eval_out.written(),
    );

    var shutdown_out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer shutdown_out.deinit();
    try ShardIpcMessage.shutdown(1).writeJson(&shutdown_out.writer);
    try std.testing.expectEqualStrings("{\"type\":\"shutdown\",\"shard_id\":1}", shutdown_out.written());

    var manager = try ShardManager.init(std.testing.allocator, 4, 1);
    defer manager.deinit();
    const clusters = try manager.clusterPlan(std.testing.allocator, .{ .shards_per_cluster = 2 });
    defer deinitShardClusters(std.testing.allocator, clusters);
    try std.testing.expect(clusters[0].contains(1));
    try std.testing.expect(!clusters[0].contains(2));

    var broadcast = try clusters[0].broadcast(std.testing.allocator, ShardIpcMessage.dispatch(0, "reload"));
    defer broadcast.deinit();
    var broadcast_out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer broadcast_out.deinit();
    try broadcast.writeJson(&broadcast_out.writer);
    try std.testing.expectEqualStrings(
        "{\"shard_ids\":[0,1],\"message\":{\"type\":\"dispatch\",\"shard_id\":0,\"payload\":\"reload\"}}",
        broadcast_out.written(),
    );
}

test "ShardIpcRouter dispatches kind handlers and fallback" {
    const State = struct {
        dispatches: usize = 0,
        fallback: usize = 0,

        pub fn onDispatch(self: *@This(), message: ShardIpcMessage) !void {
            try std.testing.expectEqual(ShardIpcMessageKind.dispatch, message.kind);
            self.dispatches += 1;
        }

        pub fn onFallback(self: *@This(), message: ShardIpcMessage) !void {
            try std.testing.expectEqual(ShardIpcMessageKind.shutdown, message.kind);
            self.fallback += 1;
        }
    };

    var state = State{};
    const routes = [_]ShardIpcRoute{
        .{ .kind = .dispatch, .handler = shardIpcHandler(&state, State.onDispatch) },
    };
    const router = ShardIpcRouter{
        .routes = &routes,
        .fallback = shardIpcHandler(&state, State.onFallback),
    };

    try std.testing.expect(try router.dispatch(ShardIpcMessage.dispatch(1, "READY")));
    try std.testing.expect(try router.dispatch(ShardIpcMessage.shutdown(1)));
    try std.testing.expectEqual(@as(usize, 1), state.dispatches);
    try std.testing.expectEqual(@as(usize, 1), state.fallback);
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
