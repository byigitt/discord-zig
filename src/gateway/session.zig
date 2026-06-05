const std = @import("std");
const Gateway = @import("protocol.zig");
const WebSocket = @import("websocket.zig");

pub const Transport = struct {
    ptr: *anyopaque,
    sendTextFn: *const fn (ptr: *anyopaque, payload: []const u8) anyerror!void,
    recvTextFn: *const fn (ptr: *anyopaque, allocator: std.mem.Allocator) anyerror!?[]u8,

    pub fn sendText(self: Transport, payload: []const u8) !void {
        try self.sendTextFn(self.ptr, payload);
    }

    pub fn recvText(self: Transport, allocator: std.mem.Allocator) !?[]u8 {
        return self.recvTextFn(self.ptr, allocator);
    }
};

pub const Options = struct {
    token: []const u8,
    intents: u32,
    presence: ?Gateway.Presence = null,
};

pub const State = enum {
    disconnected,
    connected,
    identified,
    ready,
    resuming,
};

pub const Signal = enum {
    none,
    hello,
    heartbeat_ack,
    reconnect,
    invalid_session,
    dispatch,
    ignored,
};

pub const InvalidSessionMode = enum {
    unknown,
    resumable,
    fresh_identify,
};

pub const Session = struct {
    allocator: std.mem.Allocator,
    transport: Transport,
    options: Options,
    state: State = .disconnected,
    sequence: ?u64 = null,
    session_id: ?[]u8 = null,
    heartbeat_interval_ms: ?u64 = null,
    awaiting_heartbeat_ack: bool = false,
    last_signal: Signal = .none,
    invalid_session_mode: InvalidSessionMode = .unknown,

    pub fn init(allocator: std.mem.Allocator, transport: Transport, options: Options) Session {
        return .{
            .allocator = allocator,
            .transport = transport,
            .options = options,
        };
    }

    pub fn deinit(self: *Session) void {
        if (self.session_id) |session_id| self.allocator.free(session_id);
        self.session_id = null;
    }

    pub fn identify(self: *Session) !void {
        var out = std.Io.Writer.Allocating.init(self.allocator);
        defer out.deinit();

        try Gateway.writeIdentifyPayload(.{
            .token = self.options.token,
            .intents = self.options.intents,
            .presence = self.options.presence,
        }, &out.writer);
        try self.transport.sendText(out.written());
        self.state = .identified;
    }

    pub fn resumeSession(self: *Session) !void {
        const session_id = self.session_id orelse return error.MissingSessionId;
        const sequence = self.sequence orelse return error.MissingSequence;

        var out = std.Io.Writer.Allocating.init(self.allocator);
        defer out.deinit();

        try Gateway.writeResumePayload(.{
            .token = self.options.token,
            .session_id = session_id,
            .sequence = sequence,
        }, &out.writer);
        try self.transport.sendText(out.written());
        self.state = .resuming;
    }

    pub fn sendHeartbeat(self: *Session) !void {
        var out = std.Io.Writer.Allocating.init(self.allocator);
        defer out.deinit();

        try Gateway.writeHeartbeatPayload(self.sequence, &out.writer);
        try self.transport.sendText(out.written());
        self.awaiting_heartbeat_ack = true;
    }

    pub fn updatePresence(self: *Session, presence: Gateway.Presence) !void {
        var out = std.Io.Writer.Allocating.init(self.allocator);
        defer out.deinit();

        try Gateway.writePresenceUpdatePayload(presence, &out.writer);
        try self.transport.sendText(out.written());
    }

    pub fn updateVoiceState(self: *Session, update: Gateway.VoiceStateUpdate) !void {
        var out = std.Io.Writer.Allocating.init(self.allocator);
        defer out.deinit();

        try Gateway.writeVoiceStateUpdatePayload(update, &out.writer);
        try self.transport.sendText(out.written());
    }

    pub fn requestGuildMembers(self: *Session, request: Gateway.RequestGuildMembers) !void {
        var out = std.Io.Writer.Allocating.init(self.allocator);
        defer out.deinit();

        try Gateway.writeRequestGuildMembersPayload(request, &out.writer);
        try self.transport.sendText(out.written());
    }

    pub fn requestSoundboardSounds(self: *Session, request: Gateway.RequestSoundboardSounds) !void {
        var out = std.Io.Writer.Allocating.init(self.allocator);
        defer out.deinit();

        try Gateway.writeRequestSoundboardSoundsPayload(request, &out.writer);
        try self.transport.sendText(out.written());
    }

    pub fn requestChannelInfo(self: *Session, request: Gateway.RequestChannelInfo) !void {
        var out = std.Io.Writer.Allocating.init(self.allocator);
        defer out.deinit();

        try Gateway.writeRequestChannelInfoPayload(request, &out.writer);
        try self.transport.sendText(out.written());
    }

    pub fn handleText(self: *Session, payload: []const u8) !?Gateway.ParsedDispatch {
        self.last_signal = .none;
        var parsed = try std.json.parseFromSlice(std.json.Value, self.allocator, payload, .{});
        errdefer parsed.deinit();

        const root = parsed.value.object;
        const op_value = root.get("op") orelse return error.InvalidGatewayPayload;
        const op: u8 = @intCast(op_value.integer);

        switch (op) {
            @intFromEnum(Gateway.Opcode.hello) => {
                const data = root.get("d") orelse return error.InvalidGatewayPayload;
                const interval = data.object.get("heartbeat_interval") orelse return error.InvalidGatewayPayload;
                self.heartbeat_interval_ms = @intCast(interval.integer);
                self.state = .connected;
                self.last_signal = .hello;
                parsed.deinit();
                return null;
            },
            @intFromEnum(Gateway.Opcode.heartbeat_ack) => {
                self.awaiting_heartbeat_ack = false;
                self.last_signal = .heartbeat_ack;
                parsed.deinit();
                return null;
            },
            @intFromEnum(Gateway.Opcode.reconnect) => {
                self.state = .resuming;
                self.last_signal = .reconnect;
                parsed.deinit();
                return null;
            },
            @intFromEnum(Gateway.Opcode.invalid_session) => {
                const data = root.get("d") orelse return error.InvalidGatewayPayload;
                const resumable = switch (data) {
                    .bool => |value| value,
                    else => return error.InvalidGatewayPayload,
                };
                if (resumable) {
                    self.state = .resuming;
                    self.invalid_session_mode = .resumable;
                } else {
                    self.state = .connected;
                    self.sequence = null;
                    if (self.session_id) |session_id| self.allocator.free(session_id);
                    self.session_id = null;
                    self.invalid_session_mode = .fresh_identify;
                }
                self.last_signal = .invalid_session;
                parsed.deinit();
                return null;
            },
            @intFromEnum(Gateway.Opcode.dispatch) => {
                parsed.deinit();
                var dispatch = try Gateway.parseDispatch(self.allocator, payload);
                errdefer dispatch.deinit();
                self.sequence = dispatch.sequence;
                self.last_signal = .dispatch;
                if (dispatch.event == .READY) {
                    try self.captureReadySessionId(dispatch.data);
                    self.state = .ready;
                } else if (dispatch.event == .RESUMED) {
                    self.state = .ready;
                }
                return dispatch;
            },
            else => {
                self.last_signal = .ignored;
                parsed.deinit();
                return null;
            },
        }
    }

    pub fn canResume(self: Session) bool {
        return self.session_id != null and self.sequence != null;
    }

    pub fn poll(self: *Session) !?Gateway.ParsedDispatch {
        const payload = try self.transport.recvText(self.allocator) orelse return null;
        defer self.allocator.free(payload);
        return self.handleText(payload);
    }

    fn captureReadySessionId(self: *Session, data: std.json.Value) !void {
        const session_id_value = data.object.get("session_id") orelse return;
        const session_id = switch (session_id_value) {
            .string => |value| value,
            else => return error.InvalidGatewayPayload,
        };
        const owned = try self.allocator.dupe(u8, session_id);
        errdefer self.allocator.free(owned);

        if (self.session_id) |old| self.allocator.free(old);
        self.session_id = owned;
    }
};

pub const MemoryTransport = struct {
    allocator: std.mem.Allocator,
    sent: std.array_list.Managed([]u8),
    incoming: std.array_list.Managed([]u8),

    pub fn init(allocator: std.mem.Allocator) MemoryTransport {
        return .{
            .allocator = allocator,
            .sent = std.array_list.Managed([]u8).init(allocator),
            .incoming = std.array_list.Managed([]u8).init(allocator),
        };
    }

    pub fn deinit(self: *MemoryTransport) void {
        for (self.sent.items) |item| self.allocator.free(item);
        self.sent.deinit();
        for (self.incoming.items) |item| self.allocator.free(item);
        self.incoming.deinit();
    }

    pub fn transport(self: *MemoryTransport) Transport {
        return .{ .ptr = self, .sendTextFn = sendText, .recvTextFn = recvText };
    }

    pub fn pushIncoming(self: *MemoryTransport, payload: []const u8) !void {
        try self.incoming.append(try self.allocator.dupe(u8, payload));
    }

    fn sendText(ptr: *anyopaque, payload: []const u8) !void {
        const self: *MemoryTransport = @ptrCast(@alignCast(ptr));
        try self.sent.append(try self.allocator.dupe(u8, payload));
    }

    fn recvText(ptr: *anyopaque, allocator: std.mem.Allocator) !?[]u8 {
        _ = allocator;
        const self: *MemoryTransport = @ptrCast(@alignCast(ptr));
        if (self.incoming.items.len == 0) return null;
        return self.incoming.orderedRemove(0);
    }
};

pub const WebSocketMemoryTransport = struct {
    allocator: std.mem.Allocator,
    mask_key: [4]u8 = .{ 0, 0, 0, 0 },
    sent_frames: std.array_list.Managed([]u8),
    incoming_frames: std.array_list.Managed([]u8),

    pub fn init(allocator: std.mem.Allocator) WebSocketMemoryTransport {
        return .{
            .allocator = allocator,
            .sent_frames = std.array_list.Managed([]u8).init(allocator),
            .incoming_frames = std.array_list.Managed([]u8).init(allocator),
        };
    }

    pub fn deinit(self: *WebSocketMemoryTransport) void {
        for (self.sent_frames.items) |item| self.allocator.free(item);
        self.sent_frames.deinit();
        for (self.incoming_frames.items) |item| self.allocator.free(item);
        self.incoming_frames.deinit();
    }

    pub fn transport(self: *WebSocketMemoryTransport) Transport {
        return .{ .ptr = self, .sendTextFn = sendText, .recvTextFn = recvText };
    }

    pub fn pushServerText(self: *WebSocketMemoryTransport, payload: []const u8) !void {
        var out = std.Io.Writer.Allocating.init(self.allocator);
        defer out.deinit();
        try writeUnmaskedServerTextFrame(payload, &out.writer);
        try self.incoming_frames.append(try self.allocator.dupe(u8, out.written()));
    }

    fn sendText(ptr: *anyopaque, payload: []const u8) !void {
        const self: *WebSocketMemoryTransport = @ptrCast(@alignCast(ptr));
        var out = std.Io.Writer.Allocating.init(self.allocator);
        defer out.deinit();
        try WebSocket.writeTextFrame(payload, self.mask_key, &out.writer);
        try self.sent_frames.append(try self.allocator.dupe(u8, out.written()));
    }

    fn recvText(ptr: *anyopaque, allocator: std.mem.Allocator) !?[]u8 {
        const self: *WebSocketMemoryTransport = @ptrCast(@alignCast(ptr));
        if (self.incoming_frames.items.len == 0) return null;
        const bytes = self.incoming_frames.orderedRemove(0);
        defer self.allocator.free(bytes);
        const frame = try WebSocket.decodeFrame(allocator, bytes);
        if (frame.opcode != .text) {
            WebSocket.frameDeinit(allocator, frame);
            return error.UnsupportedOpcode;
        }
        return @constCast(frame.payload);
    }
};

fn writeUnmaskedServerTextFrame(payload: []const u8, writer: anytype) !void {
    try writer.writeByte(0x80 | @as(u8, @intFromEnum(WebSocket.Opcode.text)));
    if (payload.len <= 125) {
        try writer.writeByte(@intCast(payload.len));
    } else if (payload.len <= std.math.maxInt(u16)) {
        try writer.writeByte(126);
        try writer.writeByte(@intCast((payload.len >> 8) & 0xff));
        try writer.writeByte(@intCast(payload.len & 0xff));
    } else {
        try writer.writeByte(127);
        var shift: i32 = 56;
        while (shift >= 0) : (shift -= 8) {
            try writer.writeByte(@intCast((payload.len >> @intCast(shift)) & 0xff));
        }
    }
    try writer.writeAll(payload);
}

test "session identifies and heartbeats" {
    var memory = MemoryTransport.init(std.testing.allocator);
    defer memory.deinit();

    var session = Session.init(std.testing.allocator, memory.transport(), .{
        .token = "Bot token",
        .intents = 513,
        .presence = .{
            .activities = &.{.{ .name = "discord.zig", .type = .playing }},
            .status = .dnd,
        },
    });
    defer session.deinit();

    try session.identify();
    try std.testing.expectEqual(State.identified, session.state);
    try std.testing.expect(std.mem.indexOf(u8, memory.sent.items[0], "\"op\":2") != null);
    try std.testing.expect(std.mem.indexOf(u8, memory.sent.items[0], "\"presence\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, memory.sent.items[0], "\"status\":\"dnd\"") != null);

    session.sequence = 11;
    try session.sendHeartbeat();
    try std.testing.expect(session.awaiting_heartbeat_ack);
    try std.testing.expectEqualStrings("{\"op\":1,\"d\":11}", memory.sent.items[1]);

    try session.updatePresence(.{ .status = .idle });
    try std.testing.expect(std.mem.indexOf(u8, memory.sent.items[2], "\"op\":3") != null);
    try std.testing.expect(std.mem.indexOf(u8, memory.sent.items[2], "\"status\":\"idle\"") != null);

    try session.requestGuildMembers(.{
        .guild_id = @import("../core/snowflake.zig").Snowflake.init(10),
        .query = "",
        .limit = 0,
    });
    try std.testing.expect(std.mem.indexOf(u8, memory.sent.items[3], "\"op\":8") != null);
    try std.testing.expect(std.mem.indexOf(u8, memory.sent.items[3], "\"guild_id\":\"10\"") != null);

    try session.requestSoundboardSounds(.{
        .guild_ids = &.{@import("../core/snowflake.zig").Snowflake.init(10)},
    });
    try std.testing.expect(std.mem.indexOf(u8, memory.sent.items[4], "\"op\":31") != null);
    try std.testing.expect(std.mem.indexOf(u8, memory.sent.items[4], "\"guild_ids\":[\"10\"]") != null);

    try session.requestChannelInfo(.{
        .guild_id = @import("../core/snowflake.zig").Snowflake.init(10),
        .fields = &.{ .status, .voice_start_time },
    });
    try std.testing.expect(std.mem.indexOf(u8, memory.sent.items[5], "\"op\":43") != null);
    try std.testing.expect(std.mem.indexOf(u8, memory.sent.items[5], "\"fields\":[\"status\",\"voice_start_time\"]") != null);

    try session.updateVoiceState(.{
        .guild_id = @import("../core/snowflake.zig").Snowflake.init(10),
        .channel_id = @import("../core/snowflake.zig").Snowflake.init(20),
        .self_mute = true,
    });
    try std.testing.expect(std.mem.indexOf(u8, memory.sent.items[6], "\"op\":4") != null);
    try std.testing.expect(std.mem.indexOf(u8, memory.sent.items[6], "\"channel_id\":\"20\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, memory.sent.items[6], "\"self_mute\":true") != null);
}

test "session handles hello ack and ready dispatch" {
    var memory = MemoryTransport.init(std.testing.allocator);
    defer memory.deinit();

    var session = Session.init(std.testing.allocator, memory.transport(), .{
        .token = "Bot token",
        .intents = 513,
    });
    defer session.deinit();

    try std.testing.expect((try session.handleText("{\"op\":10,\"d\":{\"heartbeat_interval\":45000}}")) == null);
    try std.testing.expectEqual(@as(?u64, 45000), session.heartbeat_interval_ms);
    try std.testing.expectEqual(State.connected, session.state);

    session.awaiting_heartbeat_ack = true;
    try std.testing.expect((try session.handleText("{\"op\":11,\"d\":null}")) == null);
    try std.testing.expect(!session.awaiting_heartbeat_ack);

    var dispatch = (try session.handleText(
        "{\"op\":0,\"s\":3,\"t\":\"READY\",\"d\":{\"session_id\":\"abc\"}}",
    )).?;
    defer dispatch.deinit();

    try std.testing.expectEqual(Gateway.EventName.READY, dispatch.event);
    try std.testing.expectEqual(@as(?u64, 3), session.sequence);
    try std.testing.expectEqualStrings("abc", session.session_id.?);
    try std.testing.expectEqual(State.ready, session.state);
}

test "websocket memory transport adapts frames to session text transport" {
    var memory = WebSocketMemoryTransport.init(std.testing.allocator);
    defer memory.deinit();

    var session = Session.init(std.testing.allocator, memory.transport(), .{
        .token = "Bot token",
        .intents = 513,
    });
    defer session.deinit();

    try session.identify();
    try std.testing.expectEqual(@as(usize, 1), memory.sent_frames.items.len);
    try std.testing.expectEqual(@as(u8, 0x81), memory.sent_frames.items[0][0]);

    try memory.pushServerText("{\"op\":10,\"d\":{\"heartbeat_interval\":45000}}");
    try std.testing.expect((try session.poll()) == null);
    try std.testing.expectEqual(@as(?u64, 45000), session.heartbeat_interval_ms);
}
