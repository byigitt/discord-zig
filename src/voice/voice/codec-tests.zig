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
const writeBinaryClientMessage = Root.writeBinaryClientMessage;
const parseBinaryServerMessage = Root.parseBinaryServerMessage;
const VoiceOpcode = Root.VoiceOpcode;
const SpeakingFlags = Root.SpeakingFlags;
const EncryptionMode = Root.EncryptionMode;
const rtp_version_flags = Root.rtp_version_flags;
const rtp_payload_type = Root.rtp_payload_type;
const RtpHeader = Root.RtpHeader;
const VoiceReceiver = Root.VoiceReceiver;
const VoiceReceiveRouter = Root.VoiceReceiveRouter;
const VoiceReceiveStream = Root.VoiceReceiveStream;
const encryptedPacketLen = Root.encryptedPacketLen;
const encryptPacket = Root.encryptPacket;
const decryptPacket = Root.decryptPacket;
const ip_discovery_packet_len = Root.ip_discovery_packet_len;
const writeIpDiscovery = Root.writeIpDiscovery;
const parseIpDiscovery = Root.parseIpDiscovery;
const samples_per_frame = Root.samples_per_frame;
const opus_silence_frame = Root.opus_silence_frame;
const opusCodec = Root.opusCodec;
const OpusFrameInfo = Root.OpusFrameInfo;
const validateOpusFrame = Root.validateOpusFrame;
const EncodedOpusFrames = Root.EncodedOpusFrames;
const mixPcmSaturating = Root.mixPcmSaturating;
const PcmMixer = Root.PcmMixer;
const PacketCounter = Root.PacketCounter;
const AudioPlayerStatus = Root.AudioPlayerStatus;
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
const parseHello = Root.parseHello;
const parseReady = Root.parseReady;
const parseSessionDescription = Root.parseSessionDescription;
const parseHeartbeatAck = Root.parseHeartbeatAck;
const parseVoiceServerUpdate = Root.parseVoiceServerUpdate;
const VoiceConnectionInfo = Root.VoiceConnectionInfo;
const VoiceBootstrapState = Root.VoiceBootstrapState;
const VoiceBootstrap = Root.VoiceBootstrap;

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

        pub fn encode(self: *@This(), pcm: []const i16, out: []u8) ![]const u8 {
            self.encode_calls += 1;
            if (out.len < pcm.len) return error.BufferTooSmall;
            for (pcm, 0..) |sample, index| out[index] = @intCast(@as(u16, @bitCast(sample)) & 0xff);
            return out[0..pcm.len];
        }

        pub fn decode(self: *@This(), opus: []const u8, out: []i16) ![]const i16 {
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
