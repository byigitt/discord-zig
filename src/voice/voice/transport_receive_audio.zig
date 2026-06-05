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
const AudioResource = Root.AudioResource;
const writeDaveTransitionReady = Root.writeDaveTransitionReady;
const writeDaveMlsInvalidCommitWelcome = Root.writeDaveMlsInvalidCommitWelcome;
const AudioPlayer = Root.AudioPlayer;
const gatewayUrl = Root.gatewayUrl;
const writeIdentify = Root.writeIdentify;
const writeIdentifyWithOptions = Root.writeIdentifyWithOptions;
const writeResume = Root.writeResume;
const writeSelectProtocol = Root.writeSelectProtocol;
const writeHeartbeat = Root.writeHeartbeat;
const writeHeartbeatV8 = Root.writeHeartbeatV8;
const writeSpeaking = Root.writeSpeaking;
const dataObject = Root.dataObject;
const numberToF64 = Root.numberToF64;
const numberToU32 = Root.numberToU32;
const numberToU16 = Root.numberToU16;
const numberToU8 = Root.numberToU8;
const objectValue = Root.objectValue;
const stringField = Root.stringField;
const nullableStringField = Root.nullableStringField;
const snowflakeField = Root.snowflakeField;
const nullableSnowflakeField = Root.nullableSnowflakeField;
const parseHello = Root.parseHello;
const VoiceReady = Root.VoiceReady;
const parseReady = Root.parseReady;
const SessionDescription = Root.SessionDescription;
const parseSessionDescription = Root.parseSessionDescription;
const parseHeartbeatAck = Root.parseHeartbeatAck;
const VoiceServerUpdate = Root.VoiceServerUpdate;
const parseVoiceServerUpdate = Root.parseVoiceServerUpdate;
const VoiceConnectionInfo = Root.VoiceConnectionInfo;
const VoiceBootstrapState = Root.VoiceBootstrapState;
const VoiceBootstrap = Root.VoiceBootstrap;

pub const gateway_version: u8 = 8;

pub const VoiceIdentifyOptions = struct {
    max_dave_protocol_version: ?u8 = null,
};

pub const VoiceHeartbeat = struct {
    timestamp: u64,
    seq_ack: ?u16 = null,

    pub fn legacy(timestamp: u64) VoiceHeartbeat {
        return .{ .timestamp = timestamp };
    }

    pub fn v8(timestamp: u64, seq_ack: u16) VoiceHeartbeat {
        return .{ .timestamp = timestamp, .seq_ack = seq_ack };
    }

    pub fn writeJson(self: VoiceHeartbeat, writer: anytype) !void {
        if (self.seq_ack) |seq_ack| {
            try writer.print("{{\"op\":3,\"d\":{{\"t\":{d},\"seq_ack\":{d}}}}}", .{ self.timestamp, seq_ack });
        } else {
            try writer.print("{{\"op\":3,\"d\":{d}}}", .{self.timestamp});
        }
    }
};

pub const VoiceBinaryMessage = struct {
    sequence: ?u16 = null,
    opcode: VoiceOpcode,
    payload: []const u8,
};

pub fn writeBinaryClientMessage(opcode: VoiceOpcode, payload: []const u8, writer: anytype) !void {
    try writer.writeByte(@intFromEnum(opcode));
    try writer.writeAll(payload);
}

pub fn parseBinaryServerMessage(packet: []const u8) !VoiceBinaryMessage {
    if (packet.len < 3) return error.PacketTooSmall;
    return .{
        .sequence = std.mem.readInt(u16, packet[0..2], .big),
        .opcode = try VoiceOpcode.fromInt(packet[2]),
        .payload = packet[3..],
    };
}

pub const VoiceOpcode = enum(u8) {
    identify = 0,
    select_protocol = 1,
    ready = 2,
    heartbeat = 3,
    session_description = 4,
    speaking = 5,
    heartbeat_ack = 6,
    @"resume" = 7,
    hello = 8,
    resumed = 9,
    clients_connect = 11,
    client_disconnect = 13,
    dave_prepare_transition = 21,
    dave_execute_transition = 22,
    dave_transition_ready = 23,
    dave_prepare_epoch = 24,
    dave_mls_external_sender = 25,
    dave_mls_key_package = 26,
    dave_mls_proposals = 27,
    dave_mls_commit_welcome = 28,
    dave_mls_announce_commit_transition = 29,
    dave_mls_welcome = 30,
    dave_mls_invalid_commit_welcome = 31,

    pub fn fromInt(value: i64) !VoiceOpcode {
        return switch (value) {
            0 => .identify,
            1 => .select_protocol,
            2 => .ready,
            3 => .heartbeat,
            4 => .session_description,
            5 => .speaking,
            6 => .heartbeat_ack,
            7 => .@"resume",
            8 => .hello,
            9 => .resumed,
            11 => .clients_connect,
            13 => .client_disconnect,
            21 => .dave_prepare_transition,
            22 => .dave_execute_transition,
            23 => .dave_transition_ready,
            24 => .dave_prepare_epoch,
            25 => .dave_mls_external_sender,
            26 => .dave_mls_key_package,
            27 => .dave_mls_proposals,
            28 => .dave_mls_commit_welcome,
            29 => .dave_mls_announce_commit_transition,
            30 => .dave_mls_welcome,
            31 => .dave_mls_invalid_commit_welcome,
            else => error.UnknownVoiceOpcode,
        };
    }
};

pub const VoiceCloseCode = enum(u16) {
    unknown_opcode = 4001,
    failed_to_decode = 4002,
    not_authenticated = 4003,
    authentication_failed = 4004,
    already_authenticated = 4005,
    session_no_longer_valid = 4006,
    session_timeout = 4009,
    server_not_found = 4011,
    unknown_protocol = 4012,
    disconnected = 4014,
    voice_server_crashed = 4015,
    unknown_encryption_mode = 4016,
    e2ee_protocol_required = 4017,
    bad_request = 4020,
    disconnected_rate_limited = 4021,
    disconnected_call_terminated = 4022,

    pub fn fromInt(value: u16) ?VoiceCloseCode {
        return switch (value) {
            4001 => .unknown_opcode,
            4002 => .failed_to_decode,
            4003 => .not_authenticated,
            4004 => .authentication_failed,
            4005 => .already_authenticated,
            4006 => .session_no_longer_valid,
            4009 => .session_timeout,
            4011 => .server_not_found,
            4012 => .unknown_protocol,
            4014 => .disconnected,
            4015 => .voice_server_crashed,
            4016 => .unknown_encryption_mode,
            4017 => .e2ee_protocol_required,
            4020 => .bad_request,
            4021 => .disconnected_rate_limited,
            4022 => .disconnected_call_terminated,
            else => null,
        };
    }

    /// Whether a close with this code can be recovered from by resuming or
    /// re-identifying on a fresh socket.
    ///
    /// 4004 (authentication failed), 4006 (session no longer valid),
    /// 4011 (server not found), 4012 (unknown protocol),
    /// 4014 (disconnected — channel deleted/kicked/moved),
    /// 4016 (unknown encryption mode), 4017 (E2EE/DAVE required),
    /// 4020 (bad request), 4021 (rate limited disconnect), and 4022 (call
    /// terminated). Everything else (transient errors, 4009 session timeout,
    /// 4015 voice server crashed) is reconnectable.
    pub fn isReconnectable(self: VoiceCloseCode) bool {
        return switch (self) {
            .authentication_failed,
            .session_no_longer_valid,
            .server_not_found,
            .unknown_protocol,
            .disconnected,
            .unknown_encryption_mode,
            .e2ee_protocol_required,
            .bad_request,
            .disconnected_rate_limited,
            .disconnected_call_terminated,
            => false,

            .unknown_opcode,
            .failed_to_decode,
            .not_authenticated,
            .already_authenticated,
            .session_timeout,
            .voice_server_crashed,
            => true,
        };
    }
};

pub const SpeakingFlags = struct {
    pub const none: u32 = 0;
    pub const microphone: u32 = 1 << 0;
    pub const soundshare: u32 = 1 << 1;
    pub const priority: u32 = 1 << 2;

    pub fn has(flags: u32, bit: u32) bool {
        return (flags & bit) == bit;
    }

    pub fn add(a: u32, b: u32) u32 {
        return a | b;
    }
};

pub const EncryptionMode = enum {
    aead_aes256_gcm_rtpsize,
    aead_xchacha20_poly1305_rtpsize,

    /// Wire string sent to Discord and matched against the offered `modes`.
    pub fn name(self: EncryptionMode) []const u8 {
        return switch (self) {
            .aead_aes256_gcm_rtpsize => "aead_aes256_gcm_rtpsize",
            .aead_xchacha20_poly1305_rtpsize => "aead_xchacha20_poly1305_rtpsize",
        };
    }

    /// Pick the strongest supported mode from the server-offered list.
    /// Prefers AES-256-GCM (hardware accelerated where available), falling back
    /// to XChaCha20-Poly1305. Returns null if neither is offered.
    pub fn preferredMode(offered: []const []const u8) ?EncryptionMode {
        if (containsMode(offered, EncryptionMode.aead_aes256_gcm_rtpsize.name())) {
            return .aead_aes256_gcm_rtpsize;
        }
        if (containsMode(offered, EncryptionMode.aead_xchacha20_poly1305_rtpsize.name())) {
            return .aead_xchacha20_poly1305_rtpsize;
        }
        return null;
    }
};

pub fn containsMode(offered: []const []const u8, target: []const u8) bool {
    for (offered) |mode| {
        if (std.mem.eql(u8, mode, target)) return true;
    }
    return false;
}

pub const rtp_header_len = 12;

pub const auth_tag_len = 16;

pub const nonce_suffix_len = 4;

pub const rtp_version_flags: u8 = 0x80;

pub const rtp_payload_type: u8 = 0x78;

pub const PacketError = error{ BufferTooSmall, PacketTooSmall };

pub const RtpHeader = struct {
    sequence: u16,
    timestamp: u32,
    ssrc: u32,

    pub fn writeInto(self: RtpHeader, out: []u8) void {
        out[0] = rtp_version_flags;
        out[1] = rtp_payload_type;
        std.mem.writeInt(u16, out[2..4], self.sequence, .big);
        std.mem.writeInt(u32, out[4..8], self.timestamp, .big);
        std.mem.writeInt(u32, out[8..12], self.ssrc, .big);
    }

    pub fn readFrom(packet: []const u8) PacketError!RtpHeader {
        if (packet.len < rtp_header_len) return error.PacketTooSmall;
        return .{
            .sequence = std.mem.readInt(u16, packet[2..4], .big),
            .timestamp = std.mem.readInt(u32, packet[4..8], .big),
            .ssrc = std.mem.readInt(u32, packet[8..12], .big),
        };
    }

    pub fn hasExpectedVoicePrefix(packet: []const u8) bool {
        return packet.len >= rtp_header_len and packet[0] == rtp_version_flags and packet[1] == rtp_payload_type;
    }
};

pub const ReceivedAudioPacket = struct {
    header: RtpHeader,
    opus: []const u8,
};

pub const VoiceReceiver = struct {
    mode: EncryptionMode,
    secret_key: [32]u8,

    pub fn init(mode: EncryptionMode, secret_key: [32]u8) VoiceReceiver {
        return .{ .mode = mode, .secret_key = secret_key };
    }

    pub fn decodePacket(self: VoiceReceiver, packet: []const u8, out: []u8) !ReceivedAudioPacket {
        const header = try RtpHeader.readFrom(packet);
        const opus = try decryptPacket(self.mode, self.secret_key, packet, out);
        return .{ .header = header, .opus = opus };
    }
};

pub const ReceivedUserAudioPacket = struct {
    user_id: Snowflake,
    packet: ReceivedAudioPacket,
};

pub const VoiceReceiveRouter = struct {
    allocator: std.mem.Allocator,
    receiver: VoiceReceiver,
    ssrc_users: std.array_hash_map.Auto(u32, Snowflake),

    pub fn init(allocator: std.mem.Allocator, receiver: VoiceReceiver) VoiceReceiveRouter {
        return .{
            .allocator = allocator,
            .receiver = receiver,
            .ssrc_users = .empty,
        };
    }

    pub fn deinit(self: *VoiceReceiveRouter) void {
        self.ssrc_users.deinit(self.allocator);
    }

    pub fn registerSsrc(self: *VoiceReceiveRouter, ssrc: u32, user_id: Snowflake) !void {
        try self.ssrc_users.put(self.allocator, ssrc, user_id);
    }

    pub fn unregisterSsrc(self: *VoiceReceiveRouter, ssrc: u32) bool {
        return self.ssrc_users.orderedRemove(ssrc);
    }

    pub fn userForSsrc(self: VoiceReceiveRouter, ssrc: u32) ?Snowflake {
        return self.ssrc_users.get(ssrc);
    }

    pub fn decodePacket(self: VoiceReceiveRouter, packet: []const u8, out: []u8) !ReceivedUserAudioPacket {
        const decoded = try self.receiver.decodePacket(packet, out);
        const user_id = self.userForSsrc(decoded.header.ssrc) orelse return error.UnknownVoiceSsrc;
        return .{ .user_id = user_id, .packet = decoded };
    }
};

pub const BufferedVoiceFrame = struct {
    header: RtpHeader,
    opus: []u8,
};

pub const VoiceReceiveStream = struct {
    allocator: std.mem.Allocator,
    user_id: Snowflake,
    frames: std.array_list.Managed(BufferedVoiceFrame),

    pub fn init(allocator: std.mem.Allocator, user_id: Snowflake) VoiceReceiveStream {
        return .{
            .allocator = allocator,
            .user_id = user_id,
            .frames = std.array_list.Managed(BufferedVoiceFrame).init(allocator),
        };
    }

    pub fn deinit(self: *VoiceReceiveStream) void {
        for (self.frames.items) |frame| self.allocator.free(frame.opus);
        self.frames.deinit();
    }

    pub fn frameCount(self: VoiceReceiveStream) usize {
        return self.frames.items.len;
    }

    pub fn push(self: *VoiceReceiveStream, packet: ReceivedUserAudioPacket) !void {
        if (!packet.user_id.eql(self.user_id)) return error.UnexpectedVoiceUser;
        const opus = try self.allocator.dupe(u8, packet.packet.opus);
        errdefer self.allocator.free(opus);
        try self.frames.append(.{ .header = packet.packet.header, .opus = opus });
    }

    pub fn popOwned(self: *VoiceReceiveStream) ?BufferedVoiceFrame {
        if (self.frames.items.len == 0) return null;
        return self.frames.orderedRemove(0);
    }

    pub fn clear(self: *VoiceReceiveStream) void {
        while (self.popOwned()) |frame| self.allocator.free(frame.opus);
    }
};

pub fn encryptedPacketLen(plaintext_len: usize) usize {
    return rtp_header_len + plaintext_len + auth_tag_len + nonce_suffix_len;
}

pub fn encryptPacket(
    mode: EncryptionMode,
    secret_key: [32]u8,
    header: RtpHeader,
    plaintext: []const u8,
    nonce: u32,
    out: []u8,
) PacketError![]u8 {
    const total = encryptedPacketLen(plaintext.len);
    if (out.len < total) return error.BufferTooSmall;

    header.writeInto(out[0..rtp_header_len]);
    const aad = out[0..rtp_header_len];
    const ciphertext = out[rtp_header_len .. rtp_header_len + plaintext.len];
    std.mem.writeInt(u32, out[rtp_header_len + plaintext.len + auth_tag_len ..][0..nonce_suffix_len], nonce, .big);

    switch (mode) {
        .aead_aes256_gcm_rtpsize => {
            const Gcm = std.crypto.aead.aes_gcm.Aes256Gcm;
            var npub = [_]u8{0} ** Gcm.nonce_length;
            std.mem.writeInt(u32, npub[0..nonce_suffix_len], nonce, .big);
            Gcm.encrypt(ciphertext, out[rtp_header_len + plaintext.len ..][0..Gcm.tag_length], plaintext, aad, npub, secret_key);
        },
        .aead_xchacha20_poly1305_rtpsize => {
            const XChaCha = std.crypto.aead.chacha_poly.XChaCha20Poly1305;
            var npub = [_]u8{0} ** XChaCha.nonce_length;
            std.mem.writeInt(u32, npub[0..nonce_suffix_len], nonce, .big);
            XChaCha.encrypt(ciphertext, out[rtp_header_len + plaintext.len ..][0..XChaCha.tag_length], plaintext, aad, npub, secret_key);
        },
    }
    return out[0..total];
}

pub fn decryptPacket(
    mode: EncryptionMode,
    secret_key: [32]u8,
    packet: []const u8,
    out: []u8,
) ![]u8 {
    if (packet.len < rtp_header_len + auth_tag_len + nonce_suffix_len) return error.PacketTooSmall;
    const ciphertext_len = packet.len - rtp_header_len - auth_tag_len - nonce_suffix_len;
    if (out.len < ciphertext_len) return error.BufferTooSmall;

    const aad = packet[0..rtp_header_len];
    const ciphertext = packet[rtp_header_len .. rtp_header_len + ciphertext_len];
    const nonce = std.mem.readInt(u32, packet[packet.len - nonce_suffix_len ..][0..nonce_suffix_len], .big);

    switch (mode) {
        .aead_aes256_gcm_rtpsize => {
            const Gcm = std.crypto.aead.aes_gcm.Aes256Gcm;
            var npub = [_]u8{0} ** Gcm.nonce_length;
            std.mem.writeInt(u32, npub[0..nonce_suffix_len], nonce, .big);
            const tag = packet[rtp_header_len + ciphertext_len ..][0..Gcm.tag_length];
            try Gcm.decrypt(out[0..ciphertext_len], ciphertext, tag.*, aad, npub, secret_key);
        },
        .aead_xchacha20_poly1305_rtpsize => {
            const XChaCha = std.crypto.aead.chacha_poly.XChaCha20Poly1305;
            var npub = [_]u8{0} ** XChaCha.nonce_length;
            std.mem.writeInt(u32, npub[0..nonce_suffix_len], nonce, .big);
            const tag = packet[rtp_header_len + ciphertext_len ..][0..XChaCha.tag_length];
            try XChaCha.decrypt(out[0..ciphertext_len], ciphertext, tag.*, aad, npub, secret_key);
        },
    }
    return out[0..ciphertext_len];
}

pub const ip_discovery_packet_len = 74;

pub const IpDiscovery = struct {
    /// Slice into the response buffer (valid as long as that buffer lives).
    address: []const u8,
    port: u16,
};

pub fn writeIpDiscovery(ssrc: u32, out: *[ip_discovery_packet_len]u8) void {
    @memset(out, 0);
    std.mem.writeInt(u16, out[0..2], 1, .big);
    std.mem.writeInt(u16, out[2..4], 70, .big);
    std.mem.writeInt(u32, out[4..8], ssrc, .big);
}

pub fn parseIpDiscovery(packet: []const u8) !IpDiscovery {
    if (packet.len < ip_discovery_packet_len) return error.PacketTooSmall;
    if (std.mem.readInt(u16, packet[0..][0..2], .big) != 2) return error.InvalidDiscoveryResponse;
    const address_field = packet[8..72];
    const end = std.mem.indexOfScalar(u8, address_field, 0) orelse address_field.len;
    return .{
        .address = address_field[0..end],
        .port = std.mem.readInt(u16, packet[72..][0..2], .big),
    };
}

pub const samples_per_frame: u32 = 960;

pub const opus_silence_frame = [_]u8{ 0xF8, 0xFF, 0xFE };

pub const OpusCodec = struct {
    ptr: *anyopaque,
    encodeFn: *const fn (ptr: *anyopaque, pcm: []const i16, out: []u8) anyerror![]const u8,
    decodeFn: *const fn (ptr: *anyopaque, opus: []const u8, out: []i16) anyerror![]const i16,

    pub fn encode(self: OpusCodec, pcm: []const i16, out: []u8) ![]const u8 {
        return self.encodeFn(self.ptr, pcm, out);
    }

    pub fn decode(self: OpusCodec, opus: []const u8, out: []i16) ![]const i16 {
        return self.decodeFn(self.ptr, opus, out);
    }
};

pub fn opusCodec(ptr: anytype, comptime encodeFn: anytype, comptime decodeFn: anytype) OpusCodec {
    const Ptr = @TypeOf(ptr);
    const wrapper = struct {
        pub fn encode(raw: *anyopaque, pcm: []const i16, out: []u8) anyerror![]const u8 {
            const typed: Ptr = @ptrCast(@alignCast(raw));
            return encodeFn(typed, pcm, out);
        }

        pub fn decode(raw: *anyopaque, opus: []const u8, out: []i16) anyerror![]const i16 {
            const typed: Ptr = @ptrCast(@alignCast(raw));
            return decodeFn(typed, opus, out);
        }
    };
    return .{ .ptr = ptr, .encodeFn = wrapper.encode, .decodeFn = wrapper.decode };
}

pub const OpusFrameInfo = struct {
    toc: u8,
    frame_count: u8,
    config: u8,
    stereo: bool,

    pub fn parse(frame: []const u8) !OpusFrameInfo {
        if (frame.len == 0) return error.InvalidOpusFrame;
        const toc = frame[0];
        const code = toc & 0b11;
        const frame_count: u8 = switch (code) {
            0 => 1,
            1, 2 => 2,
            3 => blk: {
                if (frame.len < 2) return error.InvalidOpusFrame;
                const count = frame[1] & 0x3f;
                if (count == 0) return error.InvalidOpusFrame;
                break :blk count;
            },
            else => unreachable,
        };
        return .{
            .toc = toc,
            .frame_count = frame_count,
            .config = toc >> 3,
            .stereo = ((toc >> 2) & 1) != 0,
        };
    }
};

pub fn validateOpusFrame(frame: []const u8) !void {
    _ = try OpusFrameInfo.parse(frame);
}

pub const EncodedOpusFrames = struct {
    frames: []const []const u8,
    allocator: std.mem.Allocator,

    pub fn fromPcm(
        allocator: std.mem.Allocator,
        codec: OpusCodec,
        pcm_frames: []const []const i16,
        scratch: []u8,
    ) !EncodedOpusFrames {
        const frames = try allocator.alloc([]const u8, pcm_frames.len);
        var initialized: usize = 0;
        errdefer {
            for (frames[0..initialized]) |frame| allocator.free(frame);
            allocator.free(frames);
        }

        for (pcm_frames, 0..) |pcm, index| {
            const encoded = try codec.encode(pcm, scratch);
            try validateOpusFrame(encoded);
            frames[index] = try allocator.dupe(u8, encoded);
            initialized += 1;
        }
        return .{ .frames = frames, .allocator = allocator };
    }

    pub fn deinit(self: *EncodedOpusFrames) void {
        for (self.frames) |frame| self.allocator.free(frame);
        self.allocator.free(self.frames);
        self.frames = &.{};
    }

    pub fn resource(self: EncodedOpusFrames) AudioResource {
        return AudioResource.initOpusFrames(self.frames);
    }
};

pub const PcmMixOptions = struct {
    clear_output_tail: bool = true,
};

pub fn mixPcmSaturating(
    sources: []const []const i16,
    out: []i16,
    options: PcmMixOptions,
) ![]const i16 {
    var frame_len: usize = 0;
    for (sources) |source| frame_len = @max(frame_len, source.len);
    if (out.len < frame_len) return error.BufferTooSmall;

    for (out[0..frame_len], 0..) |*sample, index| {
        var mixed: i32 = 0;
        for (sources) |source| {
            if (index < source.len) mixed += source[index];
        }
        sample.* = @intCast(std.math.clamp(
            mixed,
            @as(i32, std.math.minInt(i16)),
            @as(i32, std.math.maxInt(i16)),
        ));
    }
    if (options.clear_output_tail) {
        for (out[frame_len..]) |*sample| sample.* = 0;
    }
    return out[0..frame_len];
}

pub const PcmMixer = struct {
    sources: std.array_list.Managed([]const i16),

    pub fn init(allocator: std.mem.Allocator) PcmMixer {
        return .{ .sources = std.array_list.Managed([]const i16).init(allocator) };
    }

    pub fn deinit(self: *PcmMixer) void {
        self.sources.deinit();
    }

    pub fn addSource(self: *PcmMixer, pcm: []const i16) !void {
        try self.sources.append(pcm);
    }

    pub fn clear(self: *PcmMixer) void {
        self.sources.clearRetainingCapacity();
    }

    pub fn mix(self: PcmMixer, out: []i16) ![]const i16 {
        return mixPcmSaturating(self.sources.items, out, .{});
    }
};

pub const NextPacket = struct {
    header: RtpHeader,
    nonce: u32,
};

pub const PacketCounter = struct {
    sequence: u16 = 0,
    timestamp: u32 = 0,
    nonce: u32 = 0,

    pub fn next(self: *PacketCounter, ssrc: u32) NextPacket {
        const packet = NextPacket{
            .header = .{ .sequence = self.sequence, .timestamp = self.timestamp, .ssrc = ssrc },
            .nonce = self.nonce,
        };
        self.sequence +%= 1;
        self.timestamp +%= samples_per_frame;
        self.nonce +%= 1;
        return packet;
    }
};

pub const AudioPlayerStatus = enum {
    idle,
    playing,
    paused,
};
