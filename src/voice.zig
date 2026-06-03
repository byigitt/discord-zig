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
const Json = @import("json.zig");
const Snowflake = @import("snowflake.zig").Snowflake;

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
            else => null,
        };
    }

    /// Whether a close with this code can be recovered from by resuming or
    /// re-identifying on a fresh socket.
    ///
    /// Per Discord docs the following are terminal / NOT reconnectable:
    /// 4004 (authentication failed), 4006 (session no longer valid),
    /// 4011 (server not found), 4012 (unknown protocol),
    /// 4014 (disconnected — channel deleted/kicked/moved),
    /// 4016 (unknown encryption mode). Everything else (transient errors,
    /// 4009 session timeout, 4015 voice server crashed) is reconnectable.
    pub fn isReconnectable(self: VoiceCloseCode) bool {
        return switch (self) {
            .authentication_failed,
            .session_no_longer_valid,
            .server_not_found,
            .unknown_protocol,
            .disconnected,
            .unknown_encryption_mode,
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

// ── Payload builders ───────────────────────────────────────────────────────

/// op 0 — identify on a fresh voice connection.
pub fn writeIdentify(
    server_id: Snowflake,
    user_id: Snowflake,
    session_id: []const u8,
    token: []const u8,
    writer: anytype,
) !void {
    try writer.print("{{\"op\":0,\"d\":{{\"server_id\":\"{d}\",\"user_id\":\"{d}\",\"session_id\":", .{
        server_id.value,
        user_id.value,
    });
    try Json.writeString(session_id, writer);
    try writer.writeAll(",\"token\":");
    try Json.writeString(token, writer);
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

/// op 3 — heartbeat carrying the client nonce.
pub fn writeHeartbeat(nonce: u64, writer: anytype) !void {
    try writer.print("{{\"op\":3,\"d\":{d}}}", .{nonce});
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

    pub fn deinit(self: *VoiceConnectionInfo) void {
        self.allocator.free(self.session_id);
        self.allocator.free(self.endpoint);
        self.allocator.free(self.token);
    }
};

// ── Tests ──────────────────────────────────────────────────────────────────

test "voice opcode fromInt round trips and rejects unknown" {
    try std.testing.expectEqual(VoiceOpcode.identify, try VoiceOpcode.fromInt(0));
    try std.testing.expectEqual(VoiceOpcode.session_description, try VoiceOpcode.fromInt(4));
    try std.testing.expectEqual(VoiceOpcode.clients_connect, try VoiceOpcode.fromInt(11));
    try std.testing.expectEqual(VoiceOpcode.client_disconnect, try VoiceOpcode.fromInt(13));
    try std.testing.expectError(error.UnknownVoiceOpcode, VoiceOpcode.fromInt(10));
    try std.testing.expectError(error.UnknownVoiceOpcode, VoiceOpcode.fromInt(99));
}

test "voice close code fromInt and reconnectability" {
    try std.testing.expectEqual(VoiceCloseCode.session_timeout, VoiceCloseCode.fromInt(4009).?);
    try std.testing.expectEqual(VoiceCloseCode.voice_server_crashed, VoiceCloseCode.fromInt(4015).?);
    try std.testing.expectEqual(@as(?VoiceCloseCode, null), VoiceCloseCode.fromInt(4000));
    try std.testing.expectEqual(@as(?VoiceCloseCode, null), VoiceCloseCode.fromInt(5000));

    // Reconnectable (transient / recoverable).
    try std.testing.expect(VoiceCloseCode.session_timeout.isReconnectable());
    try std.testing.expect(VoiceCloseCode.voice_server_crashed.isReconnectable());
    try std.testing.expect(VoiceCloseCode.unknown_opcode.isReconnectable());

    // Terminal / non-resumable.
    try std.testing.expect(!VoiceCloseCode.authentication_failed.isReconnectable());
    try std.testing.expect(!VoiceCloseCode.session_no_longer_valid.isReconnectable());
    try std.testing.expect(!VoiceCloseCode.server_not_found.isReconnectable());
    try std.testing.expect(!VoiceCloseCode.unknown_protocol.isReconnectable());
    try std.testing.expect(!VoiceCloseCode.disconnected.isReconnectable());
    try std.testing.expect(!VoiceCloseCode.unknown_encryption_mode.isReconnectable());
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

test "writeHeartbeat emits numeric nonce" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try writeHeartbeat(1501184119561, &out.writer);
    try std.testing.expectEqualStrings("{\"op\":3,\"d\":1501184119561}", out.written());
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
