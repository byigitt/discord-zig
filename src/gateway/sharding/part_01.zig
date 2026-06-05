const std = @import("std");
const Gateway = @import("../protocol.zig");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;

/// Mirrors the `session_start_limit` object returned by the Discord
/// `GET /gateway/bot` endpoint.
const Root = @import("../sharding.zig");
const ShardManager = Root.ShardManager;

pub const SessionStartLimit = struct {
    total: u32,
    remaining: u32,
    reset_after: u64,
    max_concurrency: u32,
};

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

pub fn readU32(value: std.json.Value) !u32 {
    return switch (value) {
        .integer => |integer| if (integer < 0) error.InvalidGatewayBotPayload else @intCast(integer),
        else => error.InvalidGatewayBotPayload,
    };
}

pub fn readU64(value: std.json.Value) !u64 {
    return switch (value) {
        .integer => |integer| if (integer < 0) error.InvalidGatewayBotPayload else @intCast(integer),
        else => error.InvalidGatewayBotPayload,
    };
}

pub const ShardState = enum {
    idle,
    identifying,
    ready,
    resuming,
    disconnected,
};

pub const ShardInfo = struct {
    id: u32,
    total: u32,
    state: ShardState = .idle,
    latency_ms: ?u64 = null,

    pub fn rateLimitKey(self: ShardInfo, max_concurrency: u32) !u32 {
        return Gateway.identifyRateLimitKey(self.id, max_concurrency);
    }
};

pub const IdentifyGroup = struct {
    bucket_id: u32,
    shard_ids: []u32,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *IdentifyGroup) void {
        self.allocator.free(self.shard_ids);
        self.shard_ids = &.{};
    }
};

pub const ShardCluster = struct {
    id: u32,
    shard_ids: []u32,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *ShardCluster) void {
        self.allocator.free(self.shard_ids);
        self.shard_ids = &.{};
    }

    pub fn contains(self: ShardCluster, shard_id: u32) bool {
        for (self.shard_ids) |id| {
            if (id == shard_id) return true;
        }
        return false;
    }

    pub fn broadcast(self: ShardCluster, allocator: std.mem.Allocator, message: ShardIpcMessage) !ShardIpcBroadcast {
        return ShardIpcBroadcast.init(allocator, self.shard_ids, message);
    }
};

pub const ShardClusterProcessSpec = struct {
    cluster_id: u32,
    shard_ids: []u32,
    argv: []const []const u8,
    env: []const []const u8,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *ShardClusterProcessSpec) void {
        self.allocator.free(self.shard_ids);
        for (self.argv) |arg| self.allocator.free(arg);
        self.allocator.free(self.argv);
        for (self.env) |entry| self.allocator.free(entry);
        self.allocator.free(self.env);
        self.shard_ids = &.{};
        self.argv = &.{};
        self.env = &.{};
    }
};

pub fn deinitShardClusterProcessSpecs(allocator: std.mem.Allocator, specs: []ShardClusterProcessSpec) void {
    for (specs) |*spec| spec.deinit();
    allocator.free(specs);
}

pub fn deinitShardClusters(allocator: std.mem.Allocator, clusters: []ShardCluster) void {
    for (clusters) |*cluster| cluster.deinit();
    allocator.free(clusters);
}

pub const ShardClusterPlanOptions = struct {
    shards_per_cluster: u32 = 1,
};

pub const ShardProcessOptions = struct {
    executable: []const u8,
    base_args: []const []const u8 = &.{},
    token: ?[]const u8 = null,
    token_env_name: []const u8 = "DISCORD_TOKEN",
    shard_id_env_name: []const u8 = "DISCORD_SHARD_ID",
    shard_count_env_name: []const u8 = "DISCORD_SHARD_COUNT",
    shard_range_env_name: []const u8 = "DISCORD_SHARD_RANGE",
    cluster_id_env_name: []const u8 = "DISCORD_CLUSTER_ID",
    cluster_shards_env_name: []const u8 = "DISCORD_CLUSTER_SHARDS",
};

pub const ShardProcessSpec = struct {
    shard_id: u32,
    total_shards: u32,
    argv: []const []const u8,
    env: []const []const u8,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *ShardProcessSpec) void {
        for (self.argv) |arg| self.allocator.free(arg);
        self.allocator.free(self.argv);
        for (self.env) |entry| self.allocator.free(entry);
        self.allocator.free(self.env);
        self.argv = &.{};
        self.env = &.{};
    }
};

pub fn buildShardProcessSpec(
    allocator: std.mem.Allocator,
    shard_id: u32,
    total_shards: u32,
    options: ShardProcessOptions,
) !ShardProcessSpec {
    if (options.executable.len == 0) return error.InvalidShardExecutable;

    const argv = try allocator.alloc([]const u8, options.base_args.len + 1);
    var argv_initialized: usize = 0;
    errdefer {
        for (argv[0..argv_initialized]) |arg| allocator.free(arg);
        allocator.free(argv);
    }
    argv[0] = try allocator.dupe(u8, options.executable);
    argv_initialized += 1;
    for (options.base_args, 0..) |arg, index| {
        argv[index + 1] = try allocator.dupe(u8, arg);
        argv_initialized += 1;
    }

    const env_len: usize = if (options.token != null) 4 else 3;
    const env = try allocator.alloc([]const u8, env_len);
    var env_initialized: usize = 0;
    errdefer {
        for (env[0..env_initialized]) |entry| allocator.free(entry);
        allocator.free(env);
    }

    env[env_initialized] = try std.fmt.allocPrint(allocator, "{s}={d}", .{ options.shard_id_env_name, shard_id });
    env_initialized += 1;
    env[env_initialized] = try std.fmt.allocPrint(allocator, "{s}={d}", .{ options.shard_count_env_name, total_shards });
    env_initialized += 1;
    env[env_initialized] = try std.fmt.allocPrint(allocator, "{s}={d},{d}", .{ options.shard_range_env_name, shard_id, total_shards });
    env_initialized += 1;
    if (options.token) |token| {
        env[env_initialized] = try std.fmt.allocPrint(allocator, "{s}={s}", .{ options.token_env_name, token });
        env_initialized += 1;
    }

    return .{
        .shard_id = shard_id,
        .total_shards = total_shards,
        .argv = argv,
        .env = env,
        .allocator = allocator,
    };
}

pub fn duplicateProcessArgv(allocator: std.mem.Allocator, options: ShardProcessOptions) ![]const []const u8 {
    if (options.executable.len == 0) return error.InvalidShardExecutable;
    const argv = try allocator.alloc([]const u8, options.base_args.len + 1);
    var initialized: usize = 0;
    errdefer {
        for (argv[0..initialized]) |arg| allocator.free(arg);
        allocator.free(argv);
    }
    argv[0] = try allocator.dupe(u8, options.executable);
    initialized += 1;
    for (options.base_args, 0..) |arg, index| {
        argv[index + 1] = try allocator.dupe(u8, arg);
        initialized += 1;
    }
    return argv;
}

pub fn shardListEnvValue(allocator: std.mem.Allocator, shard_ids: []const u32) ![]u8 {
    var out = std.Io.Writer.Allocating.init(allocator);
    errdefer out.deinit();
    for (shard_ids, 0..) |shard_id, index| {
        if (index != 0) try out.writer.writeByte(',');
        try out.writer.print("{d}", .{shard_id});
    }
    return out.toOwnedSlice();
}

pub fn buildShardClusterProcessSpec(
    allocator: std.mem.Allocator,
    cluster: ShardCluster,
    total_shards: u32,
    options: ShardProcessOptions,
) !ShardClusterProcessSpec {
    const argv = try duplicateProcessArgv(allocator, options);
    errdefer {
        for (argv) |arg| allocator.free(arg);
        allocator.free(argv);
    }

    const shard_ids = try allocator.dupe(u32, cluster.shard_ids);
    errdefer allocator.free(shard_ids);

    const shard_list = try shardListEnvValue(allocator, cluster.shard_ids);
    defer allocator.free(shard_list);

    const env_len: usize = if (options.token != null) 4 else 3;
    const env = try allocator.alloc([]const u8, env_len);
    var initialized: usize = 0;
    errdefer {
        for (env[0..initialized]) |entry| allocator.free(entry);
        allocator.free(env);
    }

    env[initialized] = try std.fmt.allocPrint(allocator, "{s}={d}", .{ options.cluster_id_env_name, cluster.id });
    initialized += 1;
    env[initialized] = try std.fmt.allocPrint(allocator, "{s}={s}", .{ options.cluster_shards_env_name, shard_list });
    initialized += 1;
    env[initialized] = try std.fmt.allocPrint(allocator, "{s}={d}", .{ options.shard_count_env_name, total_shards });
    initialized += 1;
    if (options.token) |token| {
        env[initialized] = try std.fmt.allocPrint(allocator, "{s}={s}", .{ options.token_env_name, token });
        initialized += 1;
    }

    return .{
        .cluster_id = cluster.id,
        .shard_ids = shard_ids,
        .argv = argv,
        .env = env,
        .allocator = allocator,
    };
}

pub fn deinitShardProcessSpecs(allocator: std.mem.Allocator, specs: []ShardProcessSpec) void {
    for (specs) |*spec| spec.deinit();
    allocator.free(specs);
}

pub const ShardRestartPolicy = enum {
    never,
    on_failure,
    always,
};

pub const ShardExitAction = enum {
    stopped,
    restarted,
};

pub const ShardSupervisorOptions = struct {
    process: ShardProcessOptions,
    restart_policy: ShardRestartPolicy = .never,
    max_restarts_per_shard: ?u32 = null,
};

pub fn shouldRestartShard(policy: ShardRestartPolicy, term: std.process.Child.Term) bool {
    return switch (policy) {
        .never => false,
        .always => true,
        .on_failure => switch (term) {
            .exited => |code| code != 0,
            .signal, .stopped, .unknown => true,
        },
    };
}

pub fn canRestartShard(count: u32, max_restarts: ?u32) bool {
    return if (max_restarts) |max| count < max else true;
}

pub const ShardIpcMessageKind = enum {
    dispatch,
    eval,
    result,
    failure,
    shutdown,
    heartbeat,
};

pub const ShardIpcMessage = struct {
    kind: ShardIpcMessageKind,
    shard_id: ?u32 = null,
    nonce: ?u64 = null,
    payload: ?[]const u8 = null,

    pub fn dispatch(shard_id: u32, payload: []const u8) ShardIpcMessage {
        return .{ .kind = .dispatch, .shard_id = shard_id, .payload = payload };
    }

    pub fn eval(shard_id: u32, nonce: u64, payload: []const u8) ShardIpcMessage {
        return .{ .kind = .eval, .shard_id = shard_id, .nonce = nonce, .payload = payload };
    }

    pub fn result(shard_id: u32, nonce: u64, payload: []const u8) ShardIpcMessage {
        return .{ .kind = .result, .shard_id = shard_id, .nonce = nonce, .payload = payload };
    }

    pub fn shutdown(shard_id: u32) ShardIpcMessage {
        return .{ .kind = .shutdown, .shard_id = shard_id };
    }

    pub fn writeJson(self: ShardIpcMessage, writer: anytype) !void {
        try writer.writeByte('{');
        try writer.writeAll("\"type\":");
        try writeJsonString(@tagName(self.kind), writer);
        if (self.shard_id) |shard_id| try writer.print(",\"shard_id\":{d}", .{shard_id});
        if (self.nonce) |nonce| try writer.print(",\"nonce\":{d}", .{nonce});
        if (self.payload) |payload| {
            try writer.writeAll(",\"payload\":");
            try writeJsonString(payload, writer);
        }
        try writer.writeByte('}');
    }
};

pub fn writeJsonString(value: []const u8, writer: anytype) !void {
    try writer.writeByte('"');
    for (value) |byte| {
        switch (byte) {
            '\\' => try writer.writeAll("\\\\"),
            '"' => try writer.writeAll("\\\""),
            '\n' => try writer.writeAll("\\n"),
            '\r' => try writer.writeAll("\\r"),
            '\t' => try writer.writeAll("\\t"),
            else => try writer.writeByte(byte),
        }
    }
    try writer.writeByte('"');
}

pub const ShardIpcBroadcast = struct {
    shard_ids: []u32,
    message: ShardIpcMessage,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, shard_ids: []const u32, message: ShardIpcMessage) !ShardIpcBroadcast {
        return .{
            .shard_ids = try allocator.dupe(u32, shard_ids),
            .message = message,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *ShardIpcBroadcast) void {
        self.allocator.free(self.shard_ids);
        self.shard_ids = &.{};
    }

    pub fn writeJson(self: ShardIpcBroadcast, writer: anytype) !void {
        try writer.writeAll("{\"shard_ids\":[");
        for (self.shard_ids, 0..) |shard_id, index| {
            if (index != 0) try writer.writeByte(',');
            try writer.print("{d}", .{shard_id});
        }
        try writer.writeAll("],\"message\":");
        try self.message.writeJson(writer);
        try writer.writeByte('}');
    }
};

pub const ShardIpcHandler = struct {
    ptr: *anyopaque,
    callFn: *const fn (ptr: *anyopaque, message: ShardIpcMessage) anyerror!void,

    pub fn call(self: ShardIpcHandler, message: ShardIpcMessage) !void {
        try self.callFn(self.ptr, message);
    }
};

pub fn shardIpcHandler(ptr: anytype, comptime function: anytype) ShardIpcHandler {
    const Ptr = @TypeOf(ptr);
    const wrapper = struct {
        pub fn call(raw: *anyopaque, message: ShardIpcMessage) anyerror!void {
            const typed: Ptr = @ptrCast(@alignCast(raw));
            try function(typed, message);
        }
    };
    return .{ .ptr = ptr, .callFn = wrapper.call };
}

pub const ShardIpcRoute = struct {
    kind: ShardIpcMessageKind,
    handler: ShardIpcHandler,
};

pub const ShardIpcRouter = struct {
    routes: []const ShardIpcRoute = &.{},
    fallback: ?ShardIpcHandler = null,

    pub fn dispatch(self: ShardIpcRouter, message: ShardIpcMessage) !bool {
        for (self.routes) |route| {
            if (route.kind == message.kind) {
                try route.handler.call(message);
                return true;
            }
        }
        if (self.fallback) |handler| {
            try handler.call(message);
            return true;
        }
        return false;
    }
};

pub const ShardSupervisor = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    manager: ShardManager,
    specs: []ShardProcessSpec,
    children: []?std.process.Child,
    restart_counts: []u32,
    restart_policy: ShardRestartPolicy = .never,
    max_restarts_per_shard: ?u32 = null,

    pub fn init(
        allocator: std.mem.Allocator,
        io: std.Io,
        total_shards: u32,
        max_concurrency: u32,
        options: ShardProcessOptions,
    ) !ShardSupervisor {
        return initWithOptions(allocator, io, total_shards, max_concurrency, .{ .process = options });
    }

    pub fn initWithOptions(
        allocator: std.mem.Allocator,
        io: std.Io,
        total_shards: u32,
        max_concurrency: u32,
        options: ShardSupervisorOptions,
    ) !ShardSupervisor {
        var manager = try ShardManager.init(allocator, total_shards, max_concurrency);
        errdefer manager.deinit();

        const specs = try manager.processSpecs(allocator, options.process);
        errdefer deinitShardProcessSpecs(allocator, specs);

        const children = try allocator.alloc(?std.process.Child, total_shards);
        errdefer allocator.free(children);
        @memset(children, null);

        const restart_counts = try allocator.alloc(u32, total_shards);
        @memset(restart_counts, 0);

        return .{
            .allocator = allocator,
            .io = io,
            .manager = manager,
            .specs = specs,
            .children = children,
            .restart_counts = restart_counts,
            .restart_policy = options.restart_policy,
            .max_restarts_per_shard = options.max_restarts_per_shard,
        };
    }

    pub fn deinit(self: *ShardSupervisor) void {
        self.killAll();
        self.allocator.free(self.restart_counts);
        self.allocator.free(self.children);
        deinitShardProcessSpecs(self.allocator, self.specs);
        self.manager.deinit();
        self.children = &.{};
        self.restart_counts = &.{};
        self.specs = &.{};
    }

    pub fn spawnShard(self: *ShardSupervisor, shard_id: u32) !void {
        if (shard_id >= self.manager.total_shards) return error.InvalidShard;
        if (self.children[shard_id] != null) return error.ShardAlreadyRunning;

        var env_map = std.process.Environ.Map.init(self.allocator);
        defer env_map.deinit();
        try putSpecEnv(&env_map, self.specs[shard_id].env);

        self.children[shard_id] = try std.process.spawn(self.io, .{
            .argv = self.specs[shard_id].argv,
            .environ_map = &env_map,
            .stdin = .ignore,
            .stdout = .inherit,
            .stderr = .inherit,
        });
        try self.manager.setState(shard_id, .identifying);
    }

    pub fn spawnAll(self: *ShardSupervisor) !void {
        var spawned: u32 = 0;
        errdefer {
            var index: u32 = 0;
            while (index < spawned) : (index += 1) self.killShard(index);
        }

        while (spawned < self.manager.total_shards) : (spawned += 1) {
            try self.spawnShard(spawned);
        }
    }

    pub fn waitShard(self: *ShardSupervisor, shard_id: u32) !std.process.Child.Term {
        if (shard_id >= self.manager.total_shards) return error.InvalidShard;
        var child = self.children[shard_id] orelse return error.ShardNotRunning;
        self.children[shard_id] = null;
        const term = try child.wait(self.io);
        try self.manager.setState(shard_id, .disconnected);
        return term;
    }

    pub fn waitShardAndMaybeRestart(self: *ShardSupervisor, shard_id: u32) !ShardExitAction {
        if (shard_id >= self.manager.total_shards) return error.InvalidShard;
        var child = self.children[shard_id] orelse return error.ShardNotRunning;
        self.children[shard_id] = null;
        const term = try child.wait(self.io);
        try self.manager.setState(shard_id, .disconnected);

        if (shouldRestartShard(self.restart_policy, term) and
            canRestartShard(self.restart_counts[shard_id], self.max_restarts_per_shard))
        {
            self.restart_counts[shard_id] += 1;
            try self.spawnShard(shard_id);
            return .restarted;
        }
        return .stopped;
    }

    pub fn killShard(self: *ShardSupervisor, shard_id: u32) void {
        if (shard_id >= self.manager.total_shards) return;
        if (self.children[shard_id]) |*child| {
            child.kill(self.io);
            self.children[shard_id] = null;
            self.manager.setState(shard_id, .disconnected) catch {};
        }
    }

    pub fn killAll(self: *ShardSupervisor) void {
        var index: u32 = 0;
        while (index < self.manager.total_shards) : (index += 1) self.killShard(index);
    }

    pub fn runningCount(self: ShardSupervisor) usize {
        var count: usize = 0;
        for (self.children) |child| {
            if (child != null) count += 1;
        }
        return count;
    }
};

pub fn putSpecEnv(env_map: *std.process.Environ.Map, env: []const []const u8) !void {
    for (env) |entry| {
        const split = std.mem.indexOfScalar(u8, entry, '=') orelse return error.InvalidShardEnvironment;
        try env_map.put(entry[0..split], entry[split + 1 ..]);
    }
}
