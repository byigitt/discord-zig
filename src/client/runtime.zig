const std = @import("std");
const Rest = @import("../rest/client.zig");
const GatewaySession = @import("../gateway/session.zig");
const Root = @import("client.zig");
const Client = Root.Client;

pub const GatewayStep = enum {
    idle,
    identified,
    resumed,
    heartbeat_sent,
    heartbeat_ack,
    dispatched,
    reconnect,
    invalid_session,
};

pub const GatewayStartMode = enum {
    identify,
    resume_session,
};

pub const ReconnectBackoff = struct {
    initial_delay_ms: u64 = 1000,
    max_delay_ms: u64 = 60_000,
    factor: u8 = 2,
    attempts: u32 = 0,

    pub fn nextDelayMs(self: *ReconnectBackoff) u64 {
        var delay = self.initial_delay_ms;
        var remaining = self.attempts;
        while (remaining > 0 and delay < self.max_delay_ms) : (remaining -= 1) {
            const multiplied = std.math.mul(u64, delay, self.factor) catch self.max_delay_ms;
            delay = @min(multiplied, self.max_delay_ms);
        }
        self.attempts += 1;
        return delay;
    }

    pub fn reset(self: *ReconnectBackoff) void {
        self.attempts = 0;
    }
};

pub const GatewayRunner = struct {
    client: *Client,
    session: GatewaySession.Session,
    next_heartbeat_ms: ?u64 = null,
    reconnect_backoff: ReconnectBackoff = .{},
    reconnect_after_ms: ?u64 = null,
    pending_start: GatewayStartMode = .identify,

    pub fn init(client: *Client, transport: GatewaySession.Transport) GatewayRunner {
        return .{
            .client = client,
            .session = client.createGatewaySession(transport),
        };
    }

    pub fn deinit(self: *GatewayRunner) void {
        self.session.deinit();
    }

    pub fn step(self: *GatewayRunner, now_ms: u64) !GatewayStep {
        if (self.reconnect_after_ms) |ready_at| {
            if (now_ms < ready_at) return .idle;
        }

        if (self.next_heartbeat_ms) |deadline| {
            if (now_ms >= deadline) {
                if (self.session.awaiting_heartbeat_ack) return error.MissedHeartbeatAck;
                try self.session.sendHeartbeat();
                self.client.markHeartbeatSent(now_ms);
                self.scheduleNextHeartbeat(now_ms);
                return .heartbeat_sent;
            }
        }

        if (try self.session.poll()) |polled_dispatch| {
            var dispatch = polled_dispatch;
            defer dispatch.deinit();
            _ = try self.client.dispatchParsedGatewayAt(dispatch, now_ms);
            self.consumeSignal();
            return .dispatched;
        }

        return switch (self.session.last_signal) {
            .none, .ignored => .idle,
            .hello => {
                const start = self.pending_start;
                if (start == .resume_session and self.session.canResume()) {
                    try self.session.resumeSession();
                    self.pending_start = .identify;
                    self.reconnect_after_ms = null;
                    self.reconnect_backoff.reset();
                    self.scheduleNextHeartbeat(now_ms);
                    self.consumeSignal();
                    return .resumed;
                }
                try self.session.identify();
                self.pending_start = .identify;
                self.reconnect_after_ms = null;
                self.reconnect_backoff.reset();
                self.scheduleNextHeartbeat(now_ms);
                self.consumeSignal();
                return .identified;
            },
            .heartbeat_ack => {
                self.client.markHeartbeatAck(now_ms);
                self.consumeSignal();
                return .heartbeat_ack;
            },
            .reconnect => {
                self.client.markGatewayDisconnected();
                self.scheduleReconnect(now_ms, .resume_session);
                self.consumeSignal();
                return .reconnect;
            },
            .invalid_session => {
                self.client.markGatewayDisconnected();
                const mode: GatewayStartMode = switch (self.session.invalid_session_mode) {
                    .resumable => .resume_session,
                    .fresh_identify, .unknown => .identify,
                };
                self.scheduleReconnect(now_ms, mode);
                self.consumeSignal();
                return .invalid_session;
            },
            .dispatch => .dispatched,
        };
    }

    pub fn replaceTransport(self: *GatewayRunner, transport: GatewaySession.Transport) void {
        self.session.transport = transport;
    }

    pub fn canResume(self: GatewayRunner) bool {
        return self.session.canResume();
    }

    pub fn sessionId(self: GatewayRunner) ?[]const u8 {
        return self.session.session_id;
    }

    pub fn sequence(self: GatewayRunner) ?u64 {
        return self.session.sequence;
    }

    pub fn nextHeartbeatMs(self: GatewayRunner) ?u64 {
        return self.next_heartbeat_ms;
    }

    pub fn heartbeatIntervalMs(self: GatewayRunner) ?u64 {
        return self.session.heartbeat_interval_ms;
    }

    pub fn awaitingHeartbeatAck(self: GatewayRunner) bool {
        return self.session.awaiting_heartbeat_ack;
    }

    pub fn reconnectAfterMs(self: GatewayRunner) ?u64 {
        return self.reconnect_after_ms;
    }

    pub fn pendingStartMode(self: GatewayRunner) GatewayStartMode {
        return self.pending_start;
    }

    pub fn isReconnectPending(self: GatewayRunner) bool {
        return self.reconnect_after_ms != null;
    }

    pub fn reconnectReady(self: GatewayRunner, now_ms: u64) bool {
        return if (self.reconnect_after_ms) |ready_at| now_ms >= ready_at else true;
    }

    pub fn resetHeartbeat(self: *GatewayRunner) void {
        self.next_heartbeat_ms = null;
        self.session.awaiting_heartbeat_ack = false;
    }

    pub fn resetReconnect(self: *GatewayRunner) void {
        self.reconnect_after_ms = null;
        self.pending_start = .identify;
        self.reconnect_backoff.reset();
    }

    fn scheduleNextHeartbeat(self: *GatewayRunner, now_ms: u64) void {
        const interval = self.session.heartbeat_interval_ms orelse return;
        self.next_heartbeat_ms = now_ms + interval;
    }

    fn scheduleReconnect(self: *GatewayRunner, now_ms: u64, start: GatewayStartMode) void {
        self.resetHeartbeat();
        self.pending_start = start;
        self.reconnect_after_ms = now_ms + self.reconnect_backoff.nextDelayMs();
    }

    fn consumeSignal(self: *GatewayRunner) void {
        self.session.last_signal = .none;
    }
};

pub fn noTransportValue() Rest.Transport {
    return .{ .ptr = &no_transport_state, .sendFn = noTransportSend };
}

var no_transport_state: u8 = 0;

pub fn noTransportSend(ptr: *anyopaque, allocator: std.mem.Allocator, request: Rest.Request) anyerror!Rest.Response {
    _ = ptr;
    _ = allocator;
    _ = request;
    return error.NoHttpTransport;
}
