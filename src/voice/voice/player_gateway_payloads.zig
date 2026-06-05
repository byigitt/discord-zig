//! Discord voice gateway protocol/state layer (control plane only).
//!
//! This module implements the voice *gateway* protocol: opcodes, close codes,
//! payload builders, and payload parsing, plus a connection-bootstrap helper.
//! The voice *media plane* (Opus audio encoding, libsodium/secretbox packet
//! encryption, and the UDP/RTP socket) is intentionally OUT OF SCOPE because it
//! requires external native dependencies (opus, libsodium) that conflict with
//! this library's dependency-light core. This layer gives a caller everything
//! needed to drive the voice websocket and negotiate a media session; the
//! actual audio transport is left to an external integration.

const std = @import("std");
const Gateway = @import("../../gateway/protocol.zig");
const Json = @import("../../core/json.zig");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;

const Root = @import("../voice.zig");
const gateway_version = Root.gateway_version;
const VoiceIdentifyOptions = Root.VoiceIdentifyOptions;
const VoiceHeartbeat = Root.VoiceHeartbeat;
const VoiceBinaryMessage = Root.VoiceBinaryMessage;
const writeBinaryClientMessage = Root.writeBinaryClientMessage;
const parseBinaryServerMessage = Root.parseBinaryServerMessage;
const VoiceOpcode = Root.VoiceOpcode;
const VoiceCloseCode = Root.VoiceCloseCode;
const SpeakingFlags = Root.SpeakingFlags;
const EncryptionMode = Root.EncryptionMode;
const containsMode = Root.containsMode;
const rtp_header_len = Root.rtp_header_len;
const auth_tag_len = Root.auth_tag_len;
const nonce_suffix_len = Root.nonce_suffix_len;
const rtp_version_flags = Root.rtp_version_flags;
const rtp_payload_type = Root.rtp_payload_type;
const PacketError = Root.PacketError;
const RtpHeader = Root.RtpHeader;
const ReceivedAudioPacket = Root.ReceivedAudioPacket;
const VoiceReceiver = Root.VoiceReceiver;
const ReceivedUserAudioPacket = Root.ReceivedUserAudioPacket;
const VoiceReceiveRouter = Root.VoiceReceiveRouter;
const BufferedVoiceFrame = Root.BufferedVoiceFrame;
const VoiceReceiveStream = Root.VoiceReceiveStream;
const encryptedPacketLen = Root.encryptedPacketLen;
const encryptPacket = Root.encryptPacket;
const decryptPacket = Root.decryptPacket;
const ip_discovery_packet_len = Root.ip_discovery_packet_len;
const IpDiscovery = Root.IpDiscovery;
const writeIpDiscovery = Root.writeIpDiscovery;
const parseIpDiscovery = Root.parseIpDiscovery;
const samples_per_frame = Root.samples_per_frame;
const opus_silence_frame = Root.opus_silence_frame;
const OpusCodec = Root.OpusCodec;
const opusCodec = Root.opusCodec;
const OpusFrameInfo = Root.OpusFrameInfo;
const validateOpusFrame = Root.validateOpusFrame;
const EncodedOpusFrames = Root.EncodedOpusFrames;
const PcmMixOptions = Root.PcmMixOptions;
const mixPcmSaturating = Root.mixPcmSaturating;
const PcmMixer = Root.PcmMixer;
const NextPacket = Root.NextPacket;
const PacketCounter = Root.PacketCounter;
const AudioPlayerStatus = Root.AudioPlayerStatus;

pub const AudioResource = struct {
    frames: []const []const u8,
    cursor: usize = 0,
    silence_frames: u8 = 5,
    silence_frames_remaining: u8 = 0,
    emitted_silence: bool = false,

    pub fn initOpusFrames(frames: []const []const u8) AudioResource {
        return .{ .frames = frames };
    }

    pub fn withSilenceFrames(self: AudioResource, count: u8) AudioResource {
        var resource = self;
        resource.silence_frames = count;
        return resource;
    }

    pub fn reset(self: *AudioResource) void {
        self.cursor = 0;
        self.silence_frames_remaining = 0;
        self.emitted_silence = false;
    }

    pub fn peekFrame(self: *AudioResource) ?[]const u8 {
        if (self.cursor < self.frames.len) return self.frames[self.cursor];

        if (!self.emitted_silence) {
            self.silence_frames_remaining = self.silence_frames;
            self.emitted_silence = true;
        }

        if (self.silence_frames_remaining != 0) return opus_silence_frame[0..];
        return null;
    }

    pub fn consumePeekedFrame(self: *AudioResource) void {
        if (self.cursor < self.frames.len) {
            self.cursor += 1;
        } else if (self.silence_frames_remaining != 0) {
            self.silence_frames_remaining -= 1;
        }
    }

    pub fn nextFrame(self: *AudioResource) ?[]const u8 {
        const frame = self.peekFrame() orelse return null;
        self.consumePeekedFrame();
        return frame;
    }

    pub fn isDone(self: AudioResource) bool {
        return self.cursor >= self.frames.len and
            self.emitted_silence and
            self.silence_frames_remaining == 0;
    }
};

pub fn writeDaveTransitionReady(transition_id: u16, writer: anytype) !void {
    try writer.print("{{\"op\":23,\"d\":{{\"transition_id\":{d}}}}}", .{transition_id});
}

pub fn writeDaveMlsInvalidCommitWelcome(transition_id: u16, writer: anytype) !void {
    try writer.print("{{\"op\":31,\"d\":{{\"transition_id\":{d}}}}}", .{transition_id});
}

pub const AudioPlayer = struct {
    status: AudioPlayerStatus = .idle,
    resource: ?*AudioResource = null,
    counter: PacketCounter = .{},

    pub fn play(self: *AudioPlayer, resource: *AudioResource) void {
        resource.reset();
        self.resource = resource;
        self.status = .playing;
    }

    pub fn pause(self: *AudioPlayer) void {
        if (self.status == .playing) self.status = .paused;
    }

    pub fn unpause(self: *AudioPlayer) void {
        if (self.status == .paused) self.status = .playing;
    }

    pub fn stop(self: *AudioPlayer) void {
        self.status = .idle;
        self.resource = null;
    }

    pub fn nextOpusFrame(self: *AudioPlayer) ?[]const u8 {
        if (self.status != .playing) return null;
        const resource = self.resource orelse {
            self.status = .idle;
            return null;
        };
        const frame = resource.nextFrame() orelse {
            self.stop();
            return null;
        };
        return frame;
    }

    pub fn nextEncryptedPacket(
        self: *AudioPlayer,
        mode: EncryptionMode,
        secret_key: [32]u8,
        ssrc: u32,
        out: []u8,
    ) !?[]const u8 {
        if (self.status != .playing) return null;
        const resource = self.resource orelse return null;
        const frame = resource.peekFrame() orelse {
            self.stop();
            return null;
        };
        const header = RtpHeader{
            .sequence = self.counter.sequence,
            .timestamp = self.counter.timestamp,
            .ssrc = ssrc,
        };
        const nonce = self.counter.nonce;
        const packet = try encryptPacket(mode, secret_key, header, frame, nonce, out);
        resource.consumePeekedFrame();
        self.counter.sequence +%= 1;
        self.counter.timestamp +%= samples_per_frame;
        self.counter.nonce +%= 1;
        return packet;
    }
};

pub fn gatewayUrl(allocator: std.mem.Allocator, endpoint: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "wss://{s}/?v={d}", .{ endpoint, gateway_version });
}

pub fn writeIdentify(
    server_id: Snowflake,
    user_id: Snowflake,
    session_id: []const u8,
    token: []const u8,
    writer: anytype,
) !void {
    try writeIdentifyWithOptions(server_id, user_id, session_id, token, .{}, writer);
}

pub fn writeIdentifyWithOptions(
    server_id: Snowflake,
    user_id: Snowflake,
    session_id: []const u8,
    token: []const u8,
    options: VoiceIdentifyOptions,
    writer: anytype,
) !void {
    try writer.print("{{\"op\":0,\"d\":{{\"server_id\":\"{d}\",\"user_id\":\"{d}\",\"session_id\":", .{
        server_id.value,
        user_id.value,
    });
    try Json.writeString(session_id, writer);
    try writer.writeAll(",\"token\":");
    try Json.writeString(token, writer);
    if (options.max_dave_protocol_version) |version| {
        try writer.print(",\"max_dave_protocol_version\":{d}", .{version});
    }
    try writer.writeAll("}}");
}

pub fn writeResume(
    server_id: Snowflake,
    session_id: []const u8,
    token: []const u8,
    writer: anytype,
) !void {
    try writer.print("{{\"op\":7,\"d\":{{\"server_id\":\"{d}\",\"session_id\":", .{server_id.value});
    try Json.writeString(session_id, writer);
    try writer.writeAll(",\"token\":");
    try Json.writeString(token, writer);
    try writer.writeAll("}}");
}

pub fn writeSelectProtocol(
    address: []const u8,
    port: u16,
    mode: EncryptionMode,
    writer: anytype,
) !void {
    try writer.writeAll("{\"op\":1,\"d\":{\"protocol\":\"udp\",\"data\":{\"address\":");
    try Json.writeString(address, writer);
    try writer.print(",\"port\":{d},\"mode\":", .{port});
    try Json.writeString(mode.name(), writer);
    try writer.writeAll("}}}");
}

pub fn writeHeartbeat(nonce: u64, writer: anytype) !void {
    try VoiceHeartbeat.legacy(nonce).writeJson(writer);
}

pub fn writeHeartbeatV8(timestamp: u64, seq_ack: u16, writer: anytype) !void {
    try VoiceHeartbeat.v8(timestamp, seq_ack).writeJson(writer);
}

pub fn writeSpeaking(speaking_flags: u32, delay: u32, ssrc: u32, writer: anytype) !void {
    try writer.print(
        "{{\"op\":5,\"d\":{{\"speaking\":{d},\"delay\":{d},\"ssrc\":{d}}}}}",
        .{ speaking_flags, delay, ssrc },
    );
}

pub fn dataObject(value: std.json.Value) !std.json.Value {
    if (value != .object) return error.InvalidVoicePayload;
    const data = value.object.get("d") orelse return error.InvalidVoicePayload;
    if (data != .object) return error.InvalidVoicePayload;
    return data;
}

pub fn numberToF64(value: std.json.Value) !f64 {
    return switch (value) {
        .integer => |i| @floatFromInt(i),
        .float => |f| f,
        else => error.InvalidVoicePayload,
    };
}

pub fn numberToU32(value: std.json.Value) !u32 {
    return switch (value) {
        .integer => |i| if (i < 0 or i > std.math.maxInt(u32)) error.InvalidVoicePayload else @intCast(i),
        else => error.InvalidVoicePayload,
    };
}

pub fn numberToU16(value: std.json.Value) !u16 {
    return switch (value) {
        .integer => |i| if (i < 0 or i > std.math.maxInt(u16)) error.InvalidVoicePayload else @intCast(i),
        else => error.InvalidVoicePayload,
    };
}

pub fn numberToU8(value: std.json.Value) !u8 {
    return switch (value) {
        .integer => |i| if (i < 0 or i > std.math.maxInt(u8)) error.InvalidVoicePayload else @intCast(i),
        else => error.InvalidVoicePayload,
    };
}

pub fn objectValue(value: std.json.Value) !std.json.ObjectMap {
    return switch (value) {
        .object => |object| object,
        else => error.InvalidVoicePayload,
    };
}

pub fn stringField(object: std.json.ObjectMap, name: []const u8) ![]const u8 {
    const value = object.get(name) orelse return error.InvalidVoicePayload;
    return switch (value) {
        .string => |string| string,
        else => error.InvalidVoicePayload,
    };
}

pub fn nullableStringField(object: std.json.ObjectMap, name: []const u8) !?[]const u8 {
    const value = object.get(name) orelse return error.InvalidVoicePayload;
    return switch (value) {
        .null => null,
        .string => |string| string,
        else => error.InvalidVoicePayload,
    };
}

pub fn snowflakeField(object: std.json.ObjectMap, name: []const u8) !Snowflake {
    return Snowflake.parse(try stringField(object, name));
}

pub fn nullableSnowflakeField(object: std.json.ObjectMap, name: []const u8) !?Snowflake {
    const value = object.get(name) orelse return error.InvalidVoicePayload;
    return switch (value) {
        .null => null,
        .string => |string| try Snowflake.parse(string),
        else => error.InvalidVoicePayload,
    };
}

pub fn parseHello(value: std.json.Value) !f64 {
    const data = try dataObject(value);
    const interval = data.object.get("heartbeat_interval") orelse return error.InvalidVoicePayload;
    return numberToF64(interval);
}

pub const VoiceReady = struct {
    ssrc: u32,
    ip: []const u8,
    port: u16,
    modes_count: usize,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *VoiceReady) void {
        self.allocator.free(self.ip);
    }
};

pub fn parseReady(allocator: std.mem.Allocator, value: std.json.Value) !VoiceReady {
    const data = try dataObject(value);

    const ssrc_value = data.object.get("ssrc") orelse return error.InvalidVoicePayload;
    const ip_value = data.object.get("ip") orelse return error.InvalidVoicePayload;
    const port_value = data.object.get("port") orelse return error.InvalidVoicePayload;
    if (ip_value != .string) return error.InvalidVoicePayload;

    const ssrc = try numberToU32(ssrc_value);
    const port = try numberToU16(port_value);

    var modes_count: usize = 0;
    if (data.object.get("modes")) |modes_value| {
        if (modes_value != .array) return error.InvalidVoicePayload;
        modes_count = modes_value.array.items.len;
    }

    const ip = try allocator.dupe(u8, ip_value.string);
    return .{
        .ssrc = ssrc,
        .ip = ip,
        .port = port,
        .modes_count = modes_count,
        .allocator = allocator,
    };
}

pub const SessionDescription = struct {
    mode: []const u8,
    secret_key: []u8,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *SessionDescription) void {
        self.allocator.free(self.mode);
        self.allocator.free(self.secret_key);
    }
};

pub fn parseSessionDescription(allocator: std.mem.Allocator, value: std.json.Value) !SessionDescription {
    const data = try dataObject(value);

    const mode_value = data.object.get("mode") orelse return error.InvalidVoicePayload;
    if (mode_value != .string) return error.InvalidVoicePayload;

    const key_value = data.object.get("secret_key") orelse return error.InvalidVoicePayload;
    if (key_value != .array) return error.InvalidVoicePayload;

    const mode = try allocator.dupe(u8, mode_value.string);
    errdefer allocator.free(mode);

    const items = key_value.array.items;
    const secret_key = try allocator.alloc(u8, items.len);
    errdefer allocator.free(secret_key);
    for (items, 0..) |byte_value, index| {
        secret_key[index] = try numberToU8(byte_value);
    }

    return .{ .mode = mode, .secret_key = secret_key, .allocator = allocator };
}

pub fn parseHeartbeatAck(value: std.json.Value) !u64 {
    const data = switch (value) {
        .object => |object| object.get("d") orelse return error.InvalidVoicePayload,
        else => return error.InvalidVoicePayload,
    };
    return switch (data) {
        .integer => |integer| if (integer < 0) error.InvalidVoicePayload else @intCast(integer),
        .object => |object| switch (object.get("t") orelse return error.InvalidVoicePayload) {
            .integer => |integer| if (integer < 0) error.InvalidVoicePayload else @intCast(integer),
            else => error.InvalidVoicePayload,
        },
        else => error.InvalidVoicePayload,
    };
}

pub const VoiceServerUpdate = struct {
    guild_id: Snowflake,
    endpoint: ?[]u8,
    token: []u8,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *VoiceServerUpdate) void {
        if (self.endpoint) |endpoint| self.allocator.free(endpoint);
        self.allocator.free(self.token);
        self.endpoint = null;
        self.token = &.{};
    }

    pub fn websocketUrl(self: VoiceServerUpdate, allocator: std.mem.Allocator) !?[]u8 {
        const endpoint = self.endpoint orelse return null;
        return try gatewayUrl(allocator, endpoint);
    }
};

pub fn parseVoiceServerUpdate(allocator: std.mem.Allocator, value: std.json.Value) !VoiceServerUpdate {
    const data = try dataObject(value);
    const object = data.object;
    const guild_id = try snowflakeField(object, "guild_id");
    const token_value = try stringField(object, "token");
    const endpoint_value = try nullableStringField(object, "endpoint");

    const token = try allocator.dupe(u8, token_value);
    errdefer allocator.free(token);
    const endpoint = if (endpoint_value) |text| try allocator.dupe(u8, text) else null;
    errdefer if (endpoint) |owned| allocator.free(owned);

    return .{
        .guild_id = guild_id,
        .endpoint = endpoint,
        .token = token,
        .allocator = allocator,
    };
}

pub const VoiceConnectionInfo = struct {
    guild_id: Snowflake,
    user_id: Snowflake,
    session_id: []u8,
    endpoint: []u8,
    token: []u8,
    allocator: std.mem.Allocator,

    pub fn fromUpdates(
        allocator: std.mem.Allocator,
        guild_id: Snowflake,
        user_id: Snowflake,
        session_id: []const u8,
        endpoint: []const u8,
        token: []const u8,
    ) !VoiceConnectionInfo {
        const session_copy = try allocator.dupe(u8, session_id);
        errdefer allocator.free(session_copy);
        const endpoint_copy = try allocator.dupe(u8, endpoint);
        errdefer allocator.free(endpoint_copy);
        const token_copy = try allocator.dupe(u8, token);
        errdefer allocator.free(token_copy);

        return .{
            .guild_id = guild_id,
            .user_id = user_id,
            .session_id = session_copy,
            .endpoint = endpoint_copy,
            .token = token_copy,
            .allocator = allocator,
        };
    }

    pub fn websocketUrl(self: VoiceConnectionInfo, allocator: std.mem.Allocator) ![]u8 {
        return gatewayUrl(allocator, self.endpoint);
    }

    pub fn deinit(self: *VoiceConnectionInfo) void {
        self.allocator.free(self.session_id);
        self.allocator.free(self.endpoint);
        self.allocator.free(self.token);
    }
};

pub const VoiceBootstrapState = enum {
    idle,
    awaiting_voice_state,
    awaiting_voice_server,
    ready,
    disconnected,
};

pub const VoiceBootstrap = struct {
    allocator: std.mem.Allocator,
    guild_id: Snowflake,
    user_id: Snowflake,
    desired_channel_id: ?Snowflake = null,
    self_mute: bool = false,
    self_deaf: bool = false,
    state: VoiceBootstrapState = .idle,
    session_id: ?[]u8 = null,
    endpoint: ?[]u8 = null,
    token: ?[]u8 = null,

    pub fn init(allocator: std.mem.Allocator, guild_id: Snowflake, user_id: Snowflake) VoiceBootstrap {
        return .{
            .allocator = allocator,
            .guild_id = guild_id,
            .user_id = user_id,
        };
    }

    pub fn deinit(self: *VoiceBootstrap) void {
        self.replaceOwned(&self.session_id, null) catch unreachable;
        self.replaceOwned(&self.endpoint, null) catch unreachable;
        self.replaceOwned(&self.token, null) catch unreachable;
    }

    pub fn requestJoin(
        self: *VoiceBootstrap,
        channel_id: Snowflake,
        self_mute: bool,
        self_deaf: bool,
    ) Gateway.VoiceStateUpdate {
        self.desired_channel_id = channel_id;
        self.self_mute = self_mute;
        self.self_deaf = self_deaf;
        self.replaceOwned(&self.session_id, null) catch unreachable;
        self.replaceOwned(&self.endpoint, null) catch unreachable;
        self.replaceOwned(&self.token, null) catch unreachable;
        self.state = .awaiting_voice_state;
        return Gateway.VoiceStateUpdate.init(self.guild_id)
            .withChannel(channel_id)
            .muteState(self_mute)
            .deafState(self_deaf);
    }

    pub fn requestLeave(self: *VoiceBootstrap) Gateway.VoiceStateUpdate {
        self.desired_channel_id = null;
        self.state = .awaiting_voice_state;
        return Gateway.VoiceStateUpdate.init(self.guild_id)
            .clearChannel()
            .muteState(self.self_mute)
            .deafState(self.self_deaf);
    }

    pub fn applyDispatch(self: *VoiceBootstrap, dispatch: Gateway.ParsedDispatch) !bool {
        return switch (dispatch.event) {
            .VOICE_STATE_UPDATE => try self.applyVoiceStateUpdate(dispatch.data),
            .VOICE_SERVER_UPDATE => try self.applyVoiceServerUpdate(dispatch.data),
            else => false,
        };
    }

    pub fn applyVoiceStateUpdate(self: *VoiceBootstrap, data: std.json.Value) !bool {
        const object = try objectValue(data);
        if (!(try snowflakeField(object, "user_id")).eql(self.user_id)) return false;
        if (object.get("guild_id")) |guild_value| {
            if (guild_value != .null) {
                const guild_id = try Snowflake.parse(switch (guild_value) {
                    .string => |string| string,
                    else => return error.InvalidVoicePayload,
                });
                if (!guild_id.eql(self.guild_id)) return false;
            }
        }

        const channel_id = try nullableSnowflakeField(object, "channel_id");
        if (channel_id) |joined_channel_id| {
            self.desired_channel_id = joined_channel_id;
            try self.replaceOwned(&self.session_id, try stringField(object, "session_id"));
        } else {
            self.desired_channel_id = null;
            try self.replaceOwned(&self.session_id, null);
            try self.replaceOwned(&self.endpoint, null);
            try self.replaceOwned(&self.token, null);
        }
        self.refreshState();
        return true;
    }

    pub fn applyVoiceServerUpdate(self: *VoiceBootstrap, data: std.json.Value) !bool {
        const object = try objectValue(data);
        if (!(try snowflakeField(object, "guild_id")).eql(self.guild_id)) return false;

        try self.replaceOwned(&self.token, try stringField(object, "token"));
        try self.replaceOwned(&self.endpoint, try nullableStringField(object, "endpoint"));
        self.refreshState();
        return true;
    }

    pub fn isReady(self: VoiceBootstrap) bool {
        return self.state == .ready;
    }

    pub fn connectionInfo(self: VoiceBootstrap) !?VoiceConnectionInfo {
        const session_id = self.session_id orelse return null;
        const endpoint = self.endpoint orelse return null;
        const token = self.token orelse return null;
        return try VoiceConnectionInfo.fromUpdates(
            self.allocator,
            self.guild_id,
            self.user_id,
            session_id,
            endpoint,
            token,
        );
    }

    pub fn refreshState(self: *VoiceBootstrap) void {
        if (self.desired_channel_id == null) {
            self.state = .disconnected;
        } else if (self.session_id != null and self.endpoint != null and self.token != null) {
            self.state = .ready;
        } else if (self.session_id != null) {
            self.state = .awaiting_voice_server;
        } else {
            self.state = .awaiting_voice_state;
        }
    }

    pub fn replaceOwned(self: *VoiceBootstrap, slot: *?[]u8, value: ?[]const u8) !void {
        const owned = if (value) |slice| try self.allocator.dupe(u8, slice) else null;
        if (slot.*) |existing| self.allocator.free(existing);
        slot.* = owned;
    }
};

test "voice opcode fromInt round trips and rejects unknown" {
    try std.testing.expectEqual(VoiceOpcode.identify, try VoiceOpcode.fromInt(0));
    try std.testing.expectEqual(VoiceOpcode.session_description, try VoiceOpcode.fromInt(4));
    try std.testing.expectEqual(VoiceOpcode.clients_connect, try VoiceOpcode.fromInt(11));
    try std.testing.expectEqual(VoiceOpcode.client_disconnect, try VoiceOpcode.fromInt(13));
    try std.testing.expectEqual(VoiceOpcode.dave_prepare_transition, try VoiceOpcode.fromInt(21));
    try std.testing.expectEqual(VoiceOpcode.dave_mls_invalid_commit_welcome, try VoiceOpcode.fromInt(31));
    try std.testing.expectError(error.UnknownVoiceOpcode, VoiceOpcode.fromInt(10));
    try std.testing.expectError(error.UnknownVoiceOpcode, VoiceOpcode.fromInt(99));
}

test "voice close code fromInt and reconnectability" {
    try std.testing.expectEqual(VoiceCloseCode.session_timeout, VoiceCloseCode.fromInt(4009).?);
    try std.testing.expectEqual(VoiceCloseCode.voice_server_crashed, VoiceCloseCode.fromInt(4015).?);
    try std.testing.expectEqual(VoiceCloseCode.e2ee_protocol_required, VoiceCloseCode.fromInt(4017).?);
    try std.testing.expectEqual(VoiceCloseCode.disconnected_call_terminated, VoiceCloseCode.fromInt(4022).?);
    try std.testing.expectEqual(@as(?VoiceCloseCode, null), VoiceCloseCode.fromInt(4000));
    try std.testing.expectEqual(@as(?VoiceCloseCode, null), VoiceCloseCode.fromInt(5000));

    try std.testing.expect(VoiceCloseCode.session_timeout.isReconnectable());
    try std.testing.expect(VoiceCloseCode.voice_server_crashed.isReconnectable());
    try std.testing.expect(VoiceCloseCode.unknown_opcode.isReconnectable());

    try std.testing.expect(!VoiceCloseCode.authentication_failed.isReconnectable());
    try std.testing.expect(!VoiceCloseCode.session_no_longer_valid.isReconnectable());
    try std.testing.expect(!VoiceCloseCode.server_not_found.isReconnectable());
    try std.testing.expect(!VoiceCloseCode.unknown_protocol.isReconnectable());
    try std.testing.expect(!VoiceCloseCode.disconnected.isReconnectable());
    try std.testing.expect(!VoiceCloseCode.unknown_encryption_mode.isReconnectable());
    try std.testing.expect(!VoiceCloseCode.e2ee_protocol_required.isReconnectable());
    try std.testing.expect(!VoiceCloseCode.bad_request.isReconnectable());
    try std.testing.expect(!VoiceCloseCode.disconnected_rate_limited.isReconnectable());
    try std.testing.expect(!VoiceCloseCode.disconnected_call_terminated.isReconnectable());
}

test "speaking flags bitfield helpers" {
    const flags = SpeakingFlags.add(SpeakingFlags.microphone, SpeakingFlags.priority);
    try std.testing.expectEqual(@as(u32, 0b101), flags);
    try std.testing.expect(SpeakingFlags.has(flags, SpeakingFlags.microphone));
    try std.testing.expect(SpeakingFlags.has(flags, SpeakingFlags.priority));
    try std.testing.expect(!SpeakingFlags.has(flags, SpeakingFlags.soundshare));
}
