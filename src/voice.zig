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
const Gateway = @import("gateway.zig");
const Json = @import("json.zig");
const Snowflake = @import("snowflake.zig").Snowflake;

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

/// Voice gateway opcodes.
/// https://discord.com/developers/docs/topics/voice-connections#voice-gateway-versioning
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

/// Voice gateway close codes.
/// https://discord.com/developers/docs/topics/opcodes-and-status-codes#voice-voice-close-event-codes
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

/// Bitfield for the voice `speaking` opcode flags.
/// https://discord.com/developers/docs/topics/voice-connections#speaking
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

/// Voice transport encryption modes negotiated via select_protocol.
/// Only the AEAD modes Discord still accepts are represented; legacy
/// (non-rtpsize / non-AEAD) modes were removed by Discord.
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

fn containsMode(offered: []const []const u8, target: []const u8) bool {
    for (offered) |mode| {
        if (std.mem.eql(u8, mode, target)) return true;
    }
    return false;
}

// ── Media plane: RTP framing + AEAD encryption ──────────────────────────────
//
// This covers the part of the voice media path that is dependency-light: RTP
// packet construction and per-packet AEAD encryption using `std.crypto` (the
// two current `_rtpsize` modes). It does NOT encode audio — callers supply
// already-encoded Opus frames (Discord.js likewise delegates Opus to a native
// codec). The actual UDP socket is also the caller's; these helpers build the
// exact bytes to send.

pub const rtp_header_len = 12;
pub const auth_tag_len = 16;
pub const nonce_suffix_len = 4;
pub const rtp_version_flags: u8 = 0x80;
pub const rtp_payload_type: u8 = 0x78;

pub const PacketError = error{ BufferTooSmall, PacketTooSmall };

/// RTP header for a voice packet. Sequence and timestamp increment per frame;
/// `ssrc` comes from the voice READY payload.
pub const RtpHeader = struct {
    sequence: u16,
    timestamp: u32,
    ssrc: u32,

    fn writeInto(self: RtpHeader, out: []u8) void {
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

/// Byte length of the encrypted RTP packet produced for `plaintext_len` bytes
/// of Opus payload: header + ciphertext + auth tag + 4-byte nonce suffix.
pub fn encryptedPacketLen(plaintext_len: usize) usize {
    return rtp_header_len + plaintext_len + auth_tag_len + nonce_suffix_len;
}

/// Encrypts an Opus frame into a complete RTP packet using one of the
/// `_rtpsize` AEAD modes. `out` must hold at least `encryptedPacketLen(plaintext.len)`
/// bytes. `nonce` is a per-packet 32-bit counter (incremented by the caller).
/// The RTP header is authenticated as additional data and the big-endian nonce
/// is appended to the packet, matching Discord's `_rtpsize` layout. Returns the
/// written packet slice.
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

/// Decrypts an `_rtpsize` voice packet back into its Opus payload. `out` must
/// hold at least `packet.len - rtp_header_len - auth_tag_len - nonce_suffix_len`
/// bytes. Returns the decrypted Opus slice. Authentication failures surface as
/// `error.AuthenticationFailed`.
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

/// External address learned from the voice UDP IP-discovery handshake.
pub const IpDiscovery = struct {
    /// Slice into the response buffer (valid as long as that buffer lives).
    address: []const u8,
    port: u16,
};

/// Builds the 74-byte IP-discovery request sent over the voice UDP socket to
/// learn the bot's external address before `select_protocol`: type 0x1,
/// length 70, the `ssrc`, and zero padding.
pub fn writeIpDiscovery(ssrc: u32, out: *[ip_discovery_packet_len]u8) void {
    @memset(out, 0);
    std.mem.writeInt(u16, out[0..2], 1, .big);
    std.mem.writeInt(u16, out[2..4], 70, .big);
    std.mem.writeInt(u32, out[4..8], ssrc, .big);
}

/// Parses the 74-byte IP-discovery response (type 0x2): the external address is
/// a null-terminated string in bytes 8..72 and the port is the trailing
/// big-endian u16. The returned address slices into `packet`.
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

/// Number of audio samples in a standard 20ms Opus frame at 48kHz; the RTP
/// timestamp advances by this much per frame.
pub const samples_per_frame: u32 = 960;

/// The Opus silence frame Discord expects after audio stops, to reset the
/// receiver's interpolation. Bots usually send a few of these when going idle.
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
        fn encode(raw: *anyopaque, pcm: []const i16, out: []u8) anyerror![]const u8 {
            const typed: Ptr = @ptrCast(@alignCast(raw));
            return encodeFn(typed, pcm, out);
        }

        fn decode(raw: *anyopaque, opus: []const u8, out: []i16) anyerror![]const i16 {
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

/// The RTP header and AEAD nonce to use for the next outgoing frame.
pub const NextPacket = struct {
    header: RtpHeader,
    nonce: u32,
};

/// Tracks the per-frame RTP sequence/timestamp and packet nonce for a voice
/// sender. `next` returns the values for the current frame, then advances the
/// counters (sequence wraps at u16; timestamp and nonce wrap at u32).
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

/// Caller-owned pre-encoded Opus frames. This deliberately does not encode or
/// decode audio; it is the dependency-light equivalent of an AudioResource for
/// callers that already have Opus frames.
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

// ── Payload builders ───────────────────────────────────────────────────────

pub fn gatewayUrl(allocator: std.mem.Allocator, endpoint: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "wss://{s}/?v={d}", .{ endpoint, gateway_version });
}

/// op 0 — identify on a fresh voice connection.
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

/// op 7 — resume a dropped voice session.
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

/// op 1 — select the UDP protocol and negotiated encryption mode.
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

/// op 5 — announce speaking state, transmit delay, and ssrc.
pub fn writeSpeaking(speaking_flags: u32, delay: u32, ssrc: u32, writer: anytype) !void {
    try writer.print(
        "{{\"op\":5,\"d\":{{\"speaking\":{d},\"delay\":{d},\"ssrc\":{d}}}}}",
        .{ speaking_flags, delay, ssrc },
    );
}

// ── Parse helpers ──────────────────────────────────────────────────────────

fn dataObject(value: std.json.Value) !std.json.Value {
    if (value != .object) return error.InvalidVoicePayload;
    const data = value.object.get("d") orelse return error.InvalidVoicePayload;
    if (data != .object) return error.InvalidVoicePayload;
    return data;
}

fn numberToF64(value: std.json.Value) !f64 {
    return switch (value) {
        .integer => |i| @floatFromInt(i),
        .float => |f| f,
        else => error.InvalidVoicePayload,
    };
}

fn numberToU32(value: std.json.Value) !u32 {
    return switch (value) {
        .integer => |i| if (i < 0 or i > std.math.maxInt(u32)) error.InvalidVoicePayload else @intCast(i),
        else => error.InvalidVoicePayload,
    };
}

fn numberToU16(value: std.json.Value) !u16 {
    return switch (value) {
        .integer => |i| if (i < 0 or i > std.math.maxInt(u16)) error.InvalidVoicePayload else @intCast(i),
        else => error.InvalidVoicePayload,
    };
}

fn numberToU8(value: std.json.Value) !u8 {
    return switch (value) {
        .integer => |i| if (i < 0 or i > std.math.maxInt(u8)) error.InvalidVoicePayload else @intCast(i),
        else => error.InvalidVoicePayload,
    };
}

fn objectValue(value: std.json.Value) !std.json.ObjectMap {
    return switch (value) {
        .object => |object| object,
        else => error.InvalidVoicePayload,
    };
}

fn stringField(object: std.json.ObjectMap, name: []const u8) ![]const u8 {
    const value = object.get(name) orelse return error.InvalidVoicePayload;
    return switch (value) {
        .string => |string| string,
        else => error.InvalidVoicePayload,
    };
}

fn nullableStringField(object: std.json.ObjectMap, name: []const u8) !?[]const u8 {
    const value = object.get(name) orelse return error.InvalidVoicePayload;
    return switch (value) {
        .null => null,
        .string => |string| string,
        else => error.InvalidVoicePayload,
    };
}

fn snowflakeField(object: std.json.ObjectMap, name: []const u8) !Snowflake {
    return Snowflake.parse(try stringField(object, name));
}

fn nullableSnowflakeField(object: std.json.ObjectMap, name: []const u8) !?Snowflake {
    const value = object.get(name) orelse return error.InvalidVoicePayload;
    return switch (value) {
        .null => null,
        .string => |string| try Snowflake.parse(string),
        else => error.InvalidVoicePayload,
    };
}

/// op 8 — extract the heartbeat interval (milliseconds) from a hello payload.
pub fn parseHello(value: std.json.Value) !f64 {
    const data = try dataObject(value);
    const interval = data.object.get("heartbeat_interval") orelse return error.InvalidVoicePayload;
    return numberToF64(interval);
}

/// op 2 — voice ready: ssrc, server IP/port for the UDP socket, and the number
/// of encryption modes offered. `ip` is owned by the struct.
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

/// op 4 — session description: negotiated mode and the secret key used for
/// secretbox encryption. Both fields are owned by the struct.
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

/// State a caller assembles from VOICE_STATE_UPDATE (session_id) +
/// VOICE_SERVER_UPDATE (endpoint, token) to bootstrap a voice connection.
/// All string fields are owned by the struct.
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

    fn refreshState(self: *VoiceBootstrap) void {
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

    fn replaceOwned(self: *VoiceBootstrap, slot: *?[]u8, value: ?[]const u8) !void {
        const owned = if (value) |slice| try self.allocator.dupe(u8, slice) else null;
        if (slot.*) |existing| self.allocator.free(existing);
        slot.* = owned;
    }
};

// ── Tests ──────────────────────────────────────────────────────────────────

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

test "writeIdentify emits exact json" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try writeIdentify(
        Snowflake.init(41771983423143937),
        Snowflake.init(104694319306248192),
        "my_session_id",
        "my_token",
        &out.writer,
    );

    try std.testing.expectEqualStrings(
        "{\"op\":0,\"d\":{\"server_id\":\"41771983423143937\",\"user_id\":\"104694319306248192\",\"session_id\":\"my_session_id\",\"token\":\"my_token\"}}",
        out.written(),
    );
}

test "voice gateway url and identify options use v8 defaults" {
    const url = try gatewayUrl(std.testing.allocator, "smart.loyal.discord.media:2048");
    defer std.testing.allocator.free(url);
    try std.testing.expectEqualStrings("wss://smart.loyal.discord.media:2048/?v=8", url);

    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();
    try writeIdentifyWithOptions(
        Snowflake.init(1),
        Snowflake.init(2),
        "sess",
        "tok",
        .{ .max_dave_protocol_version = 1 },
        &out.writer,
    );
    try std.testing.expectEqualStrings(
        "{\"op\":0,\"d\":{\"server_id\":\"1\",\"user_id\":\"2\",\"session_id\":\"sess\",\"token\":\"tok\",\"max_dave_protocol_version\":1}}",
        out.written(),
    );
}

test "writeResume emits exact json" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try writeResume(Snowflake.init(123), "sess", "tok", &out.writer);
    try std.testing.expectEqualStrings(
        "{\"op\":7,\"d\":{\"server_id\":\"123\",\"session_id\":\"sess\",\"token\":\"tok\"}}",
        out.written(),
    );
}

test "writeSelectProtocol emits exact json" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try writeSelectProtocol("127.0.0.1", 1234, .aead_aes256_gcm_rtpsize, &out.writer);
    try std.testing.expectEqualStrings(
        "{\"op\":1,\"d\":{\"protocol\":\"udp\",\"data\":{\"address\":\"127.0.0.1\",\"port\":1234,\"mode\":\"aead_aes256_gcm_rtpsize\"}}}",
        out.written(),
    );
}

test "voice binary DAVE messages preserve sequence opcode and payload" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();
    try writeBinaryClientMessage(.dave_mls_key_package, "mls-key-package", &out.writer);
    try std.testing.expectEqualSlices(u8, &[_]u8{26}, out.written()[0..1]);
    try std.testing.expectEqualStrings("mls-key-package", out.written()[1..]);

    const server_packet = [_]u8{ 0x12, 0x34, 25, 1, 2, 3 };
    const parsed = try parseBinaryServerMessage(&server_packet);
    try std.testing.expectEqual(@as(?u16, 0x1234), parsed.sequence);
    try std.testing.expectEqual(VoiceOpcode.dave_mls_external_sender, parsed.opcode);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3 }, parsed.payload);
    try std.testing.expectError(error.PacketTooSmall, parseBinaryServerMessage(&[_]u8{1}));
}

test "DAVE transition control payloads serialize exact JSON" {
    var ready = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer ready.deinit();
    try writeDaveTransitionReady(7, &ready.writer);
    try std.testing.expectEqualStrings("{\"op\":23,\"d\":{\"transition_id\":7}}", ready.written());

    var invalid = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer invalid.deinit();
    try writeDaveMlsInvalidCommitWelcome(8, &invalid.writer);
    try std.testing.expectEqualStrings("{\"op\":31,\"d\":{\"transition_id\":8}}", invalid.written());
}

test "writeHeartbeat emits numeric nonce" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try writeHeartbeat(1501184119561, &out.writer);
    try std.testing.expectEqualStrings("{\"op\":3,\"d\":1501184119561}", out.written());
}

test "writeHeartbeatV8 and parseHeartbeatAck support legacy and v8 payloads" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();
    try writeHeartbeatV8(1501184119561, 10, &out.writer);
    try std.testing.expectEqualStrings("{\"op\":3,\"d\":{\"t\":1501184119561,\"seq_ack\":10}}", out.written());

    var parsed_v8 = try std.json.parseFromSlice(
        std.json.Value,
        std.testing.allocator,
        "{\"op\":6,\"d\":{\"t\":1501184119561}}",
        .{},
    );
    defer parsed_v8.deinit();
    try std.testing.expectEqual(@as(u64, 1501184119561), try parseHeartbeatAck(parsed_v8.value));

    var parsed_legacy = try std.json.parseFromSlice(
        std.json.Value,
        std.testing.allocator,
        "{\"op\":6,\"d\":1501184119561}",
        .{},
    );
    defer parsed_legacy.deinit();
    try std.testing.expectEqual(@as(u64, 1501184119561), try parseHeartbeatAck(parsed_legacy.value));
}

test "writeSpeaking emits exact json" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try writeSpeaking(SpeakingFlags.microphone, 0, 5520, &out.writer);
    try std.testing.expectEqualStrings(
        "{\"op\":5,\"d\":{\"speaking\":1,\"delay\":0,\"ssrc\":5520}}",
        out.written(),
    );
}

test "preferredMode selection logic" {
    const both = [_][]const u8{ "aead_aes256_gcm_rtpsize", "aead_xchacha20_poly1305_rtpsize" };
    try std.testing.expectEqual(EncryptionMode.aead_aes256_gcm_rtpsize, EncryptionMode.preferredMode(&both).?);

    const only_xchacha = [_][]const u8{"aead_xchacha20_poly1305_rtpsize"};
    try std.testing.expectEqual(
        EncryptionMode.aead_xchacha20_poly1305_rtpsize,
        EncryptionMode.preferredMode(&only_xchacha).?,
    );

    const legacy = [_][]const u8{ "xsalsa20_poly1305", "xsalsa20_poly1305_suffix" };
    try std.testing.expectEqual(@as(?EncryptionMode, null), EncryptionMode.preferredMode(&legacy));

    const empty = [_][]const u8{};
    try std.testing.expectEqual(@as(?EncryptionMode, null), EncryptionMode.preferredMode(&empty));
}

test "parseHello reads heartbeat interval as float" {
    const allocator = std.testing.allocator;
    const payload = "{\"op\":8,\"d\":{\"heartbeat_interval\":41250.0,\"v\":8}}";
    var parsed = try std.json.parseFromSlice(std.json.Value, allocator, payload, .{});
    defer parsed.deinit();

    try std.testing.expectEqual(@as(f64, 41250.0), try parseHello(parsed.value));
}

test "parseReady extracts ssrc, ip, port and modes count" {
    const allocator = std.testing.allocator;
    const payload =
        "{\"op\":2,\"d\":{\"ssrc\":4567,\"ip\":\"203.0.113.7\",\"port\":40404," ++
        "\"modes\":[\"aead_aes256_gcm_rtpsize\",\"aead_xchacha20_poly1305_rtpsize\"]," ++
        "\"heartbeat_interval\":1}}";
    var parsed = try std.json.parseFromSlice(std.json.Value, allocator, payload, .{});
    defer parsed.deinit();

    var ready = try parseReady(allocator, parsed.value);
    defer ready.deinit();

    try std.testing.expectEqual(@as(u32, 4567), ready.ssrc);
    try std.testing.expectEqualStrings("203.0.113.7", ready.ip);
    try std.testing.expectEqual(@as(u16, 40404), ready.port);
    try std.testing.expectEqual(@as(usize, 2), ready.modes_count);
}

test "parseSessionDescription extracts mode and secret key bytes" {
    const allocator = std.testing.allocator;
    const payload =
        "{\"op\":4,\"d\":{\"mode\":\"aead_aes256_gcm_rtpsize\"," ++
        "\"secret_key\":[1,2,3,250,255]}}";
    var parsed = try std.json.parseFromSlice(std.json.Value, allocator, payload, .{});
    defer parsed.deinit();

    var description = try parseSessionDescription(allocator, parsed.value);
    defer description.deinit();

    try std.testing.expectEqualStrings("aead_aes256_gcm_rtpsize", description.mode);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3, 250, 255 }, description.secret_key);
}

test "parseSessionDescription rejects out-of-range byte" {
    const allocator = std.testing.allocator;
    const payload = "{\"op\":4,\"d\":{\"mode\":\"x\",\"secret_key\":[300]}}";
    var parsed = try std.json.parseFromSlice(std.json.Value, allocator, payload, .{});
    defer parsed.deinit();

    try std.testing.expectError(error.InvalidVoicePayload, parseSessionDescription(allocator, parsed.value));
}

test "parseVoiceServerUpdate and bootstrap wait for both voice updates" {
    var server_payload = try std.json.parseFromSlice(
        std.json.Value,
        std.testing.allocator,
        "{\"op\":0,\"d\":{\"guild_id\":\"41771983423143937\",\"token\":\"my_token\",\"endpoint\":\"sweetwater-12345.discord.media:2048\"}}",
        .{},
    );
    defer server_payload.deinit();

    var update = try parseVoiceServerUpdate(std.testing.allocator, server_payload.value);
    defer update.deinit();
    try std.testing.expectEqual(@as(u64, 41771983423143937), update.guild_id.value);
    try std.testing.expectEqualStrings("my_token", update.token);
    try std.testing.expectEqualStrings("sweetwater-12345.discord.media:2048", update.endpoint.?);

    const ws_url = (try update.websocketUrl(std.testing.allocator)).?;
    defer std.testing.allocator.free(ws_url);
    try std.testing.expectEqualStrings("wss://sweetwater-12345.discord.media:2048/?v=8", ws_url);

    var bootstrap = VoiceBootstrap.init(
        std.testing.allocator,
        Snowflake.init(41771983423143937),
        Snowflake.init(104694319306248192),
    );
    defer bootstrap.deinit();

    const join = bootstrap.requestJoin(Snowflake.init(127121515262115840), false, false);
    try std.testing.expectEqual(Snowflake.init(127121515262115840), join.channel_id.?);
    try std.testing.expectEqual(VoiceBootstrapState.awaiting_voice_state, bootstrap.state);

    var other_user = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"VOICE_STATE_UPDATE\",\"d\":{\"guild_id\":\"41771983423143937\",\"channel_id\":\"127121515262115840\",\"user_id\":\"9\",\"session_id\":\"ignore\"}}",
    );
    defer other_user.deinit();
    try std.testing.expect(!(try bootstrap.applyDispatch(other_user)));
    try std.testing.expectEqual(VoiceBootstrapState.awaiting_voice_state, bootstrap.state);

    var own_state = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"VOICE_STATE_UPDATE\",\"d\":{\"guild_id\":\"41771983423143937\",\"channel_id\":\"127121515262115840\",\"user_id\":\"104694319306248192\",\"session_id\":\"my_session_id\"}}",
    );
    defer own_state.deinit();
    try std.testing.expect(try bootstrap.applyDispatch(own_state));
    try std.testing.expectEqual(VoiceBootstrapState.awaiting_voice_server, bootstrap.state);

    var server_dispatch = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"VOICE_SERVER_UPDATE\",\"d\":{\"guild_id\":\"41771983423143937\",\"token\":\"my_token\",\"endpoint\":\"sweetwater-12345.discord.media:2048\"}}",
    );
    defer server_dispatch.deinit();
    try std.testing.expect(try bootstrap.applyDispatch(server_dispatch));
    try std.testing.expect(bootstrap.isReady());

    var info = (try bootstrap.connectionInfo()).?;
    defer info.deinit();
    try std.testing.expectEqualStrings("my_session_id", info.session_id);
    try std.testing.expectEqualStrings("sweetwater-12345.discord.media:2048", info.endpoint);
    try std.testing.expectEqualStrings("my_token", info.token);

    const info_url = try info.websocketUrl(std.testing.allocator);
    defer std.testing.allocator.free(info_url);
    try std.testing.expectEqualStrings("wss://sweetwater-12345.discord.media:2048/?v=8", info_url);

    _ = bootstrap.requestLeave();
    var leave_state = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":4,\"t\":\"VOICE_STATE_UPDATE\",\"d\":{\"guild_id\":\"41771983423143937\",\"channel_id\":null,\"user_id\":\"104694319306248192\",\"session_id\":\"my_session_id\"}}",
    );
    defer leave_state.deinit();
    try std.testing.expect(try bootstrap.applyDispatch(leave_state));
    try std.testing.expectEqual(VoiceBootstrapState.disconnected, bootstrap.state);
    try std.testing.expect((try bootstrap.connectionInfo()) == null);
}

test "VoiceConnectionInfo owns duplicated strings" {
    const allocator = std.testing.allocator;
    var info = try VoiceConnectionInfo.fromUpdates(
        allocator,
        Snowflake.init(41771983423143937),
        Snowflake.init(104694319306248192),
        "session_abc",
        "smart.loyal.discord.gg",
        "tinytoken",
    );
    defer info.deinit();

    try std.testing.expectEqual(@as(u64, 41771983423143937), info.guild_id.value);
    try std.testing.expectEqual(@as(u64, 104694319306248192), info.user_id.value);
    try std.testing.expectEqualStrings("session_abc", info.session_id);
    try std.testing.expectEqualStrings("smart.loyal.discord.gg", info.endpoint);
    try std.testing.expectEqualStrings("tinytoken", info.token);
}

test "voice rtp packet encrypts and round-trips for both AEAD modes" {
    const key = [_]u8{7} ** 32;
    const header = RtpHeader{ .sequence = 0x1234, .timestamp = 0xAABBCCDD, .ssrc = 0x01020304 };
    const opus = "opus-payload";

    inline for ([_]EncryptionMode{ .aead_aes256_gcm_rtpsize, .aead_xchacha20_poly1305_rtpsize }) |mode| {
        var packet_buf = [_]u8{0} ** 64;
        const packet = try encryptPacket(mode, key, header, opus, 42, &packet_buf);
        try std.testing.expectEqual(encryptedPacketLen(opus.len), packet.len);

        // RTP header is emitted in the clear and authenticated.
        try std.testing.expectEqual(rtp_version_flags, packet[0]);
        try std.testing.expectEqual(rtp_payload_type, packet[1]);
        try std.testing.expectEqual(@as(u16, 0x1234), std.mem.readInt(u16, packet[2..][0..2], .big));
        try std.testing.expectEqual(@as(u32, 0xAABBCCDD), std.mem.readInt(u32, packet[4..][0..4], .big));
        try std.testing.expectEqual(@as(u32, 0x01020304), std.mem.readInt(u32, packet[8..][0..4], .big));
        // The 32-bit nonce counter is appended big-endian.
        try std.testing.expectEqual(@as(u32, 42), std.mem.readInt(u32, packet[packet.len - 4 ..][0..4], .big));

        var out = [_]u8{0} ** 64;
        const decrypted = try decryptPacket(mode, key, packet, &out);
        try std.testing.expectEqualStrings(opus, decrypted);
        try std.testing.expect(RtpHeader.hasExpectedVoicePrefix(packet));
        const parsed_header = try RtpHeader.readFrom(packet);
        try std.testing.expectEqual(header.sequence, parsed_header.sequence);
        try std.testing.expectEqual(header.timestamp, parsed_header.timestamp);
        try std.testing.expectEqual(header.ssrc, parsed_header.ssrc);

        const receiver = VoiceReceiver.init(mode, key);
        var received_buf = [_]u8{0} ** 64;
        const received = try receiver.decodePacket(packet, &received_buf);
        try std.testing.expectEqual(header.sequence, received.header.sequence);
        try std.testing.expectEqual(header.timestamp, received.header.timestamp);
        try std.testing.expectEqual(header.ssrc, received.header.ssrc);
        try std.testing.expectEqualStrings(opus, received.opus);

        var router = VoiceReceiveRouter.init(std.testing.allocator, receiver);
        defer router.deinit();
        try router.registerSsrc(header.ssrc, Snowflake.init(99));
        var routed_buf = [_]u8{0} ** 64;
        const routed = try router.decodePacket(packet, &routed_buf);
        try std.testing.expect(routed.user_id.eql(Snowflake.init(99)));
        try std.testing.expectEqual(header.ssrc, routed.packet.header.ssrc);
        try std.testing.expectEqualStrings(opus, routed.packet.opus);

        var stream = VoiceReceiveStream.init(std.testing.allocator, Snowflake.init(99));
        defer stream.deinit();
        try stream.push(routed);
        try std.testing.expectEqual(@as(usize, 1), stream.frameCount());
        const buffered = stream.popOwned().?;
        defer std.testing.allocator.free(buffered.opus);
        try std.testing.expectEqual(header.sequence, buffered.header.sequence);
        try std.testing.expectEqualStrings(opus, buffered.opus);
        try std.testing.expectEqual(@as(usize, 0), stream.frameCount());
        try std.testing.expectError(error.UnexpectedVoiceUser, stream.push(.{
            .user_id = Snowflake.init(100),
            .packet = routed.packet,
        }));
        try std.testing.expect(router.unregisterSsrc(header.ssrc));
        try std.testing.expectError(error.UnknownVoiceSsrc, router.decodePacket(packet, &routed_buf));

        // Tampering with the authenticated header breaks decryption.
        var tampered = [_]u8{0} ** 64;
        @memcpy(tampered[0..packet.len], packet);
        tampered[8] ^= 0xFF;
        try std.testing.expectError(error.AuthenticationFailed, decryptPacket(mode, key, tampered[0..packet.len], &out));
    }
}

test "voice rtp encrypt rejects an undersized buffer" {
    const key = [_]u8{0} ** 32;
    const header = RtpHeader{ .sequence = 1, .timestamp = 1, .ssrc = 1 };
    var tiny = [_]u8{0} ** 8;
    try std.testing.expectError(
        error.BufferTooSmall,
        encryptPacket(.aead_aes256_gcm_rtpsize, key, header, "frame", 1, &tiny),
    );
}

test "voice ip discovery request and response round-trip" {
    var request = [_]u8{0xFF} ** ip_discovery_packet_len;
    writeIpDiscovery(0xDEADBEEF, &request);
    try std.testing.expectEqual(@as(u16, 1), std.mem.readInt(u16, request[0..2], .big));
    try std.testing.expectEqual(@as(u16, 70), std.mem.readInt(u16, request[2..4], .big));
    try std.testing.expectEqual(@as(u32, 0xDEADBEEF), std.mem.readInt(u32, request[4..8], .big));

    // Craft a server response: type 2, address "203.0.113.5", port 50000.
    var response = [_]u8{0} ** ip_discovery_packet_len;
    std.mem.writeInt(u16, response[0..2], 2, .big);
    std.mem.writeInt(u16, response[2..4], 70, .big);
    std.mem.writeInt(u32, response[4..8], 0xDEADBEEF, .big);
    const addr = "203.0.113.5";
    @memcpy(response[8 .. 8 + addr.len], addr);
    std.mem.writeInt(u16, response[72..74], 50000, .big);

    const discovery = try parseIpDiscovery(&response);
    try std.testing.expectEqualStrings("203.0.113.5", discovery.address);
    try std.testing.expectEqual(@as(u16, 50000), discovery.port);

    // A request-typed packet (type 1) is rejected as a response.
    try std.testing.expectError(error.InvalidDiscoveryResponse, parseIpDiscovery(&request));
}

test "voice packet counter advances sequence timestamp and nonce" {
    var counter = PacketCounter{};
    const first = counter.next(0xABCD);
    try std.testing.expectEqual(@as(u16, 0), first.header.sequence);
    try std.testing.expectEqual(@as(u32, 0), first.header.timestamp);
    try std.testing.expectEqual(@as(u32, 0xABCD), first.header.ssrc);
    try std.testing.expectEqual(@as(u32, 0), first.nonce);

    const second = counter.next(0xABCD);
    try std.testing.expectEqual(@as(u16, 1), second.header.sequence);
    try std.testing.expectEqual(@as(u32, samples_per_frame), second.header.timestamp);
    try std.testing.expectEqual(@as(u32, 1), second.nonce);

    // Sequence wraps at u16 without disturbing the timestamp progression.
    counter.sequence = std.math.maxInt(u16);
    _ = counter.next(1);
    const wrapped = counter.next(1);
    try std.testing.expectEqual(@as(u16, 0), wrapped.header.sequence);

    try std.testing.expectEqual(@as(usize, 3), opus_silence_frame.len);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0xF8, 0xFF, 0xFE }, &opus_silence_frame);
}

test "Opus frame info parses TOC frame count and mode bits" {
    const one = try OpusFrameInfo.parse(&[_]u8{0b0010_1000});
    try std.testing.expectEqual(@as(u8, 1), one.frame_count);
    try std.testing.expectEqual(@as(u8, 5), one.config);
    try std.testing.expect(!one.stereo);

    const two = try OpusFrameInfo.parse(&[_]u8{0b0010_1101});
    try std.testing.expectEqual(@as(u8, 2), two.frame_count);
    try std.testing.expect(two.stereo);

    const many = try OpusFrameInfo.parse(&[_]u8{ 0b0010_1011, 0x03 });
    try std.testing.expectEqual(@as(u8, 3), many.frame_count);
    try validateOpusFrame(&[_]u8{0b0010_1000});
    try std.testing.expectError(error.InvalidOpusFrame, validateOpusFrame(&.{}));
    try std.testing.expectError(error.InvalidOpusFrame, validateOpusFrame(&[_]u8{0b0010_1011}));
    try std.testing.expectError(error.InvalidOpusFrame, validateOpusFrame(&[_]u8{ 0b0010_1011, 0 }));
}

test "PCM mixer saturates and clears output tail" {
    const a = [_]i16{ 20_000, -20_000, 10, 5 };
    const b = [_]i16{ 20_000, -20_000, -20 };
    var out = [_]i16{ 9, 9, 9, 9, 9 };
    const sources = [_][]const i16{ &a, &b };

    const mixed = try mixPcmSaturating(&sources, &out, .{});
    try std.testing.expectEqualSlices(i16, &[_]i16{ 32767, -32768, -10, 5 }, mixed);
    try std.testing.expectEqual(@as(i16, 0), out[4]);

    var mixer = PcmMixer.init(std.testing.allocator);
    defer mixer.deinit();
    try mixer.addSource(&a);
    try mixer.addSource(&b);
    var out2 = [_]i16{0} ** 4;
    try std.testing.expectEqualSlices(i16, mixed, try mixer.mix(&out2));
    mixer.clear();
    try std.testing.expectEqual(@as(usize, 0), (try mixer.mix(&out2)).len);
}

test "opus codec adapter delegates encode and decode" {
    const State = struct {
        encode_calls: usize = 0,
        decode_calls: usize = 0,

        fn encode(self: *@This(), pcm: []const i16, out: []u8) ![]const u8 {
            self.encode_calls += 1;
            if (out.len < pcm.len) return error.BufferTooSmall;
            for (pcm, 0..) |sample, index| out[index] = @intCast(@as(u16, @bitCast(sample)) & 0xff);
            return out[0..pcm.len];
        }

        fn decode(self: *@This(), opus: []const u8, out: []i16) ![]const i16 {
            self.decode_calls += 1;
            if (out.len < opus.len) return error.BufferTooSmall;
            for (opus, 0..) |byte, index| out[index] = byte;
            return out[0..opus.len];
        }
    };

    var state = State{};
    const codec = opusCodec(&state, State.encode, State.decode);

    const pcm = [_]i16{ 1, 2, 255 };
    var opus_out = [_]u8{0} ** 8;
    const encoded = try codec.encode(&pcm, &opus_out);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 255 }, encoded);

    var pcm_out = [_]i16{0} ** 8;
    const decoded = try codec.decode(encoded, &pcm_out);
    try std.testing.expectEqualSlices(i16, &[_]i16{ 1, 2, 255 }, decoded);
    try std.testing.expectEqual(@as(usize, 1), state.encode_calls);
    try std.testing.expectEqual(@as(usize, 1), state.decode_calls);

    const pcm_two = [_]i16{ 1, 2, 3 };
    const pcm_frames = [_][]const i16{ &pcm, &pcm_two };
    var scratch = [_]u8{0} ** 8;
    var owned = try EncodedOpusFrames.fromPcm(std.testing.allocator, codec, &pcm_frames, &scratch);
    defer owned.deinit();
    try std.testing.expectEqual(@as(usize, 2), owned.frames.len);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 255 }, owned.frames[0]);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3 }, owned.frames[1]);
    var resource = owned.resource();
    try std.testing.expectEqualSlices(u8, owned.frames[0], resource.nextFrame().?);
}

test "voice audio resource and player stream pre-encoded opus frames" {
    const frames = [_][]const u8{ "opus-1", "opus-2" };
    var resource = AudioResource.initOpusFrames(&frames).withSilenceFrames(2);
    var player = AudioPlayer{};

    player.play(&resource);
    try std.testing.expectEqual(AudioPlayerStatus.playing, player.status);
    try std.testing.expectEqualStrings("opus-1", player.nextOpusFrame().?);

    player.pause();
    try std.testing.expectEqual(@as(?[]const u8, null), player.nextOpusFrame());
    player.unpause();
    try std.testing.expectEqualStrings("opus-2", player.nextOpusFrame().?);
    try std.testing.expectEqualSlices(u8, &opus_silence_frame, player.nextOpusFrame().?);
    try std.testing.expectEqualSlices(u8, &opus_silence_frame, player.nextOpusFrame().?);
    try std.testing.expectEqual(@as(?[]const u8, null), player.nextOpusFrame());
    try std.testing.expectEqual(AudioPlayerStatus.idle, player.status);
    try std.testing.expect(resource.isDone());
}

test "voice audio player packetizes encrypted opus frames without advancing on encryption failure" {
    const frames = [_][]const u8{"opus-1"};
    var resource = AudioResource.initOpusFrames(&frames).withSilenceFrames(0);
    var player = AudioPlayer{};
    player.play(&resource);

    const key = [_]u8{9} ** 32;
    var tiny = [_]u8{0} ** 8;
    try std.testing.expectError(
        error.BufferTooSmall,
        player.nextEncryptedPacket(.aead_aes256_gcm_rtpsize, key, 0x12345678, &tiny),
    );
    try std.testing.expectEqual(@as(u16, 0), player.counter.sequence);
    try std.testing.expectEqual(@as(usize, 0), resource.cursor);

    var packet_buf = [_]u8{0} ** 64;
    const packet = (try player.nextEncryptedPacket(.aead_aes256_gcm_rtpsize, key, 0x12345678, &packet_buf)).?;
    try std.testing.expectEqual(@as(u16, 1), player.counter.sequence);
    try std.testing.expectEqual(@as(u32, samples_per_frame), player.counter.timestamp);
    try std.testing.expectEqual(@as(usize, 1), resource.cursor);
    try std.testing.expectEqual(@as(u32, 0x12345678), std.mem.readInt(u32, packet[8..][0..4], .big));

    var decrypted_buf = [_]u8{0} ** 64;
    const decrypted = try decryptPacket(.aead_aes256_gcm_rtpsize, key, packet, &decrypted_buf);
    try std.testing.expectEqualStrings("opus-1", decrypted);
}
