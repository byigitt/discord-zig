const std = @import("std");
const ClientModule = @import("../client/client.zig");
const GatewaySession = @import("session.zig");
const GatewayTransport = @import("transport.zig");

pub const RunOptions = struct {
    gateway: GatewayTransport.ConnectOptions = .{},
    max_steps: ?usize = null,
};

pub fn login(allocator: std.mem.Allocator, client: *ClientModule.Client, options: RunOptions) !void {
    var runtime = BlockingRuntime.init(allocator, client);
    defer runtime.deinit();
    try runtime.run(options);
}

pub const NonblockingStep = union(enum) {
    stopped,
    connect_required,
    wait_reconnect_ms: u64,
    gateway: ClientModule.GatewayStep,
};

pub const NonblockingRuntime = struct {
    client: *ClientModule.Client,
    runner: ClientModule.GatewayRunner,
    connected: bool = true,
    stopped: bool = false,

    pub fn init(client: *ClientModule.Client, transport: GatewaySession.Transport) NonblockingRuntime {
        return .{
            .client = client,
            .runner = client.createGatewayRunner(transport),
        };
    }

    pub fn initDisconnected(client: *ClientModule.Client, transport: GatewaySession.Transport) NonblockingRuntime {
        return .{
            .client = client,
            .runner = client.createGatewayRunner(transport),
            .connected = false,
        };
    }

    pub fn deinit(self: *NonblockingRuntime) void {
        self.runner.deinit();
    }

    pub fn replaceTransport(self: *NonblockingRuntime, transport: GatewaySession.Transport) void {
        self.runner.replaceTransport(transport);
        self.connected = true;
    }

    pub fn markConnected(self: *NonblockingRuntime) void {
        self.connected = true;
    }

    pub fn markDisconnected(self: *NonblockingRuntime) void {
        self.connected = false;
    }

    pub fn stop(self: *NonblockingRuntime) void {
        self.stopped = true;
        self.connected = false;
    }

    pub fn resetStop(self: *NonblockingRuntime) void {
        self.stopped = false;
    }

    pub fn isStopped(self: NonblockingRuntime) bool {
        return self.stopped;
    }

    pub fn isConnected(self: NonblockingRuntime) bool {
        return self.connected;
    }

    pub fn reconnectAfterMs(self: NonblockingRuntime) ?u64 {
        return self.runner.reconnectAfterMs();
    }

    pub fn isReconnectPending(self: NonblockingRuntime) bool {
        return self.runner.isReconnectPending();
    }

    pub fn reconnectReady(self: NonblockingRuntime, now_ms: u64) bool {
        return self.runner.reconnectReady(now_ms);
    }

    pub fn step(self: *NonblockingRuntime, now_ms: u64) !NonblockingStep {
        if (self.stopped) return .stopped;
        if (!self.connected) return .connect_required;

        if (self.runner.reconnectAfterMs()) |ready_at| {
            if (now_ms < ready_at) return .{ .wait_reconnect_ms = ready_at - now_ms };
        }

        const result = self.runner.step(now_ms) catch |err| switch (err) {
            error.MissedHeartbeatAck => {
                scheduleReconnect(&self.runner, now_ms, .resume_session);
                self.connected = false;
                return .{ .gateway = .reconnect };
            },
            else => |e| return e,
        };

        switch (result) {
            .reconnect, .invalid_session => self.connected = false,
            else => {},
        }
        return .{ .gateway = result };
    }
};

pub const BlockingRuntime = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    client: *ClientModule.Client,
    transport: GatewayTransport.Transport,
    runner: ClientModule.GatewayRunner,
    connected: bool = false,
    stopped: bool = false,

    pub fn init(allocator: std.mem.Allocator, client: *ClientModule.Client) BlockingRuntime {
        var transport = GatewayTransport.Transport.init(allocator);
        return .{
            .allocator = allocator,
            .io = std.Io.Threaded.global_single_threaded.io(),
            .client = client,
            .runner = client.createGatewayRunner(transport.sessionTransport()),
            .transport = transport,
        };
    }

    pub fn deinit(self: *BlockingRuntime) void {
        self.runner.deinit();
        self.transport.deinit();
    }

    pub fn stop(self: *BlockingRuntime) void {
        self.stopped = true;
        self.disconnectAfterSignal();
    }

    pub fn resetStop(self: *BlockingRuntime) void {
        self.stopped = false;
    }

    pub fn isStopped(self: BlockingRuntime) bool {
        return self.stopped;
    }

    pub fn isConnected(self: BlockingRuntime) bool {
        return self.connected;
    }

    pub fn reconnectAfterMs(self: BlockingRuntime) ?u64 {
        return self.runner.reconnectAfterMs();
    }

    pub fn isReconnectPending(self: BlockingRuntime) bool {
        return self.runner.isReconnectPending();
    }

    pub fn reconnectReady(self: BlockingRuntime, now_ms: u64) bool {
        return self.runner.reconnectReady(now_ms);
    }

    pub fn connect(self: *BlockingRuntime, options: GatewayTransport.ConnectOptions) !void {
        try self.transport.connect(options);
        self.runner.replaceTransport(self.transport.sessionTransport());
        self.connected = true;
    }

    pub fn step(self: *BlockingRuntime, options: GatewayTransport.ConnectOptions) !ClientModule.GatewayStep {
        if (self.stopped) return .idle;

        const now = nowMs(self.io);
        if (!self.connected or !self.runner.reconnectReady(now)) {
            try self.waitUntilReconnectReady(now);
        }

        if (!self.connected) {
            try self.connect(options);
        }

        const result = self.runner.step(nowMs(self.io)) catch |err| switch (err) {
            error.MissedHeartbeatAck => {
                self.disconnectForReconnect(nowMs(self.io), .resume_session);
                return .reconnect;
            },
            else => |e| return e,
        };

        switch (result) {
            .reconnect, .invalid_session => self.disconnectAfterSignal(),
            else => {},
        }
        return result;
    }

    pub fn run(self: *BlockingRuntime, options: RunOptions) !void {
        var steps: usize = 0;
        while (!self.stopped and (options.max_steps == null or steps < options.max_steps.?)) : (steps += 1) {
            _ = try self.step(options.gateway);
        }
    }

    fn disconnectAfterSignal(self: *BlockingRuntime) void {
        self.transport.close();
        self.connected = false;
    }

    fn disconnectForReconnect(self: *BlockingRuntime, now_ms: u64, start: ClientModule.GatewayStartMode) void {
        self.transport.close();
        self.connected = false;
        scheduleReconnect(&self.runner, now_ms, start);
    }

    fn waitUntilReconnectReady(self: *BlockingRuntime, now_ms: u64) !void {
        if (self.runner.reconnectAfterMs()) |ready_at| {
            if (now_ms < ready_at) {
                const delay = ready_at - now_ms;
                try sleepMs(self.io, delay);
            }
        }
    }
};

fn scheduleReconnect(runner: *ClientModule.GatewayRunner, now_ms: u64, start: ClientModule.GatewayStartMode) void {
    runner.resetHeartbeat();
    runner.pending_start = start;
    runner.reconnect_after_ms = now_ms + runner.reconnect_backoff.nextDelayMs();
}

fn nowMs(io: std.Io) u64 {
    const timestamp = std.Io.Clock.awake.now(io);
    const millis = timestamp.toMilliseconds();
    return if (millis <= 0) 0 else @intCast(millis);
}

fn sleepMs(io: std.Io, millis: u64) !void {
    if (millis == 0) return;
    const nanos = std.math.mul(u64, millis, std.time.ns_per_ms) catch std.math.maxInt(i64);
    const clamped = @min(nanos, @as(u64, @intCast(std.math.maxInt(i64))));
    try std.Io.sleep(io, .fromNanoseconds(@intCast(clamped)), .awake);
}

test "blocking runtime constructs and deinitializes" {
    var client = ClientModule.Client.init(std.testing.allocator, .{
        .token = "Bot test",
    });
    defer client.deinit();

    var runtime = BlockingRuntime.init(std.testing.allocator, &client);
    defer runtime.deinit();

    try std.testing.expect(!runtime.isConnected());
    try std.testing.expect(!runtime.isReconnectPending());
    try std.testing.expect(runtime.reconnectAfterMs() == null);
}

test "blocking runtime stop breaks run loop" {
    var client = ClientModule.Client.init(std.testing.allocator, .{
        .token = "Bot test",
    });
    defer client.deinit();

    var runtime = BlockingRuntime.init(std.testing.allocator, &client);
    defer runtime.deinit();

    runtime.stop();
    try runtime.run(.{});
    try std.testing.expect(runtime.isStopped());
    try std.testing.expect(!runtime.isConnected());

    runtime.resetStop();
    try std.testing.expect(!runtime.isStopped());
}

test "login convenience runs bounded blocking runtime" {
    var client = ClientModule.Client.init(std.testing.allocator, .{
        .token = "Bot test",
    });
    defer client.deinit();

    try login(std.testing.allocator, &client, .{ .max_steps = 0 });
}

test "nonblocking runtime reports connect required without sleeping" {
    var gateway_memory = GatewaySession.MemoryTransport.init(std.testing.allocator);
    defer gateway_memory.deinit();

    var client = ClientModule.Client.init(std.testing.allocator, .{
        .token = "Bot test",
    });
    defer client.deinit();

    var runtime = NonblockingRuntime.initDisconnected(&client, gateway_memory.transport());
    defer runtime.deinit();

    try std.testing.expect(!runtime.isConnected());
    const result = try runtime.step(100);
    try std.testing.expectEqual(NonblockingStep.connect_required, result);
}

test "nonblocking runtime stop reports stopped step" {
    var gateway_memory = GatewaySession.MemoryTransport.init(std.testing.allocator);
    defer gateway_memory.deinit();

    var client = ClientModule.Client.init(std.testing.allocator, .{
        .token = "Bot test",
    });
    defer client.deinit();

    var runtime = NonblockingRuntime.init(&client, gateway_memory.transport());
    defer runtime.deinit();

    runtime.stop();
    try std.testing.expect(runtime.isStopped());
    try std.testing.expect(!runtime.isConnected());
    try std.testing.expectEqual(NonblockingStep.stopped, try runtime.step(100));

    runtime.resetStop();
    try std.testing.expect(!runtime.isStopped());
    try std.testing.expectEqual(NonblockingStep.connect_required, try runtime.step(100));
}

test "nonblocking runtime reports reconnect wait duration" {
    var gateway_memory = GatewaySession.MemoryTransport.init(std.testing.allocator);
    defer gateway_memory.deinit();

    var client = ClientModule.Client.init(std.testing.allocator, .{
        .token = "Bot test",
    });
    defer client.deinit();

    var runtime = NonblockingRuntime.init(&client, gateway_memory.transport());
    defer runtime.deinit();
    runtime.runner.reconnect_after_ms = 250;

    try std.testing.expect(runtime.isConnected());
    try std.testing.expect(runtime.isReconnectPending());
    try std.testing.expectEqual(@as(?u64, 250), runtime.reconnectAfterMs());
    try std.testing.expect(!runtime.reconnectReady(100));
    const result = try runtime.step(100);
    switch (result) {
        .wait_reconnect_ms => |delay| try std.testing.expectEqual(@as(u64, 150), delay),
        else => return error.UnexpectedRuntimeStep,
    }
}

test "nonblocking runtime steps gateway without owning event loop sleeps" {
    var gateway_memory = GatewaySession.MemoryTransport.init(std.testing.allocator);
    defer gateway_memory.deinit();
    try gateway_memory.pushIncoming("{\"op\":10,\"d\":{\"heartbeat_interval\":100}}");

    var client = ClientModule.Client.init(std.testing.allocator, .{
        .token = "Bot test",
    });
    defer client.deinit();

    var runtime = NonblockingRuntime.init(&client, gateway_memory.transport());
    defer runtime.deinit();

    const result = try runtime.step(10);
    switch (result) {
        .gateway => |step| try std.testing.expectEqual(ClientModule.GatewayStep.identified, step),
        else => return error.UnexpectedRuntimeStep,
    }
    try std.testing.expect(runtime.isConnected());
    try std.testing.expectEqual(@as(usize, 1), gateway_memory.sent.items.len);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[0], "\"op\":2") != null);
}

test "nonblocking runtime disconnects after reconnect signal" {
    var gateway_memory = GatewaySession.MemoryTransport.init(std.testing.allocator);
    defer gateway_memory.deinit();
    try gateway_memory.pushIncoming("{\"op\":7,\"d\":null}");

    var client = ClientModule.Client.init(std.testing.allocator, .{
        .token = "Bot test",
    });
    defer client.deinit();

    var runtime = NonblockingRuntime.init(&client, gateway_memory.transport());
    defer runtime.deinit();

    const result = try runtime.step(10);
    switch (result) {
        .gateway => |step| try std.testing.expectEqual(ClientModule.GatewayStep.reconnect, step),
        else => return error.UnexpectedRuntimeStep,
    }
    try std.testing.expect(!runtime.isConnected());
    try std.testing.expect(runtime.isReconnectPending());
    try std.testing.expect(runtime.reconnectAfterMs() != null);
}
