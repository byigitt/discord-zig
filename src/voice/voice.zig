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

const transport_receive_audio = @import("voice/receive-audio.zig");
const player_gateway_payloads = @import("voice/player-gateway.zig");

test {
    _ = @import("voice/codec-tests.zig");
}

pub const gateway_version = transport_receive_audio.gateway_version;
pub const VoiceIdentifyOptions = transport_receive_audio.VoiceIdentifyOptions;
pub const VoiceHeartbeat = transport_receive_audio.VoiceHeartbeat;
pub const VoiceBinaryMessage = transport_receive_audio.VoiceBinaryMessage;
pub const writeBinaryClientMessage = transport_receive_audio.writeBinaryClientMessage;
pub const parseBinaryServerMessage = transport_receive_audio.parseBinaryServerMessage;
pub const VoiceOpcode = transport_receive_audio.VoiceOpcode;
pub const VoiceCloseCode = transport_receive_audio.VoiceCloseCode;
pub const SpeakingFlags = transport_receive_audio.SpeakingFlags;
pub const EncryptionMode = transport_receive_audio.EncryptionMode;
pub const containsMode = transport_receive_audio.containsMode;
pub const rtp_header_len = transport_receive_audio.rtp_header_len;
pub const auth_tag_len = transport_receive_audio.auth_tag_len;
pub const nonce_suffix_len = transport_receive_audio.nonce_suffix_len;
pub const rtp_version_flags = transport_receive_audio.rtp_version_flags;
pub const rtp_payload_type = transport_receive_audio.rtp_payload_type;
pub const PacketError = transport_receive_audio.PacketError;
pub const RtpHeader = transport_receive_audio.RtpHeader;
pub const ReceivedAudioPacket = transport_receive_audio.ReceivedAudioPacket;
pub const VoiceReceiver = transport_receive_audio.VoiceReceiver;
pub const ReceivedUserAudioPacket = transport_receive_audio.ReceivedUserAudioPacket;
pub const VoiceReceiveRouter = transport_receive_audio.VoiceReceiveRouter;
pub const BufferedVoiceFrame = transport_receive_audio.BufferedVoiceFrame;
pub const VoiceReceiveStream = transport_receive_audio.VoiceReceiveStream;
pub const encryptedPacketLen = transport_receive_audio.encryptedPacketLen;
pub const encryptPacket = transport_receive_audio.encryptPacket;
pub const decryptPacket = transport_receive_audio.decryptPacket;
pub const ip_discovery_packet_len = transport_receive_audio.ip_discovery_packet_len;
pub const IpDiscovery = transport_receive_audio.IpDiscovery;
pub const writeIpDiscovery = transport_receive_audio.writeIpDiscovery;
pub const parseIpDiscovery = transport_receive_audio.parseIpDiscovery;
pub const samples_per_frame = transport_receive_audio.samples_per_frame;
pub const opus_silence_frame = transport_receive_audio.opus_silence_frame;
pub const OpusCodec = transport_receive_audio.OpusCodec;
pub const opusCodec = transport_receive_audio.opusCodec;
pub const OpusFrameInfo = transport_receive_audio.OpusFrameInfo;
pub const validateOpusFrame = transport_receive_audio.validateOpusFrame;
pub const EncodedOpusFrames = transport_receive_audio.EncodedOpusFrames;
pub const PcmMixOptions = transport_receive_audio.PcmMixOptions;
pub const mixPcmSaturating = transport_receive_audio.mixPcmSaturating;
pub const PcmMixer = transport_receive_audio.PcmMixer;
pub const NextPacket = transport_receive_audio.NextPacket;
pub const PacketCounter = transport_receive_audio.PacketCounter;
pub const AudioPlayerStatus = transport_receive_audio.AudioPlayerStatus;
pub const AudioResource = player_gateway_payloads.AudioResource;
pub const writeDaveTransitionReady = player_gateway_payloads.writeDaveTransitionReady;
pub const writeDaveMlsInvalidCommitWelcome = player_gateway_payloads.writeDaveMlsInvalidCommitWelcome;
pub const AudioPlayer = player_gateway_payloads.AudioPlayer;
pub const gatewayUrl = player_gateway_payloads.gatewayUrl;
pub const writeIdentify = player_gateway_payloads.writeIdentify;
pub const writeIdentifyWithOptions = player_gateway_payloads.writeIdentifyWithOptions;
pub const writeResume = player_gateway_payloads.writeResume;
pub const writeSelectProtocol = player_gateway_payloads.writeSelectProtocol;
pub const writeHeartbeat = player_gateway_payloads.writeHeartbeat;
pub const writeHeartbeatV8 = player_gateway_payloads.writeHeartbeatV8;
pub const writeSpeaking = player_gateway_payloads.writeSpeaking;
pub const dataObject = player_gateway_payloads.dataObject;
pub const numberToF64 = player_gateway_payloads.numberToF64;
pub const numberToU32 = player_gateway_payloads.numberToU32;
pub const numberToU16 = player_gateway_payloads.numberToU16;
pub const numberToU8 = player_gateway_payloads.numberToU8;
pub const objectValue = player_gateway_payloads.objectValue;
pub const stringField = player_gateway_payloads.stringField;
pub const nullableStringField = player_gateway_payloads.nullableStringField;
pub const snowflakeField = player_gateway_payloads.snowflakeField;
pub const nullableSnowflakeField = player_gateway_payloads.nullableSnowflakeField;
pub const parseHello = player_gateway_payloads.parseHello;
pub const VoiceReady = player_gateway_payloads.VoiceReady;
pub const parseReady = player_gateway_payloads.parseReady;
pub const SessionDescription = player_gateway_payloads.SessionDescription;
pub const parseSessionDescription = player_gateway_payloads.parseSessionDescription;
pub const parseHeartbeatAck = player_gateway_payloads.parseHeartbeatAck;
pub const VoiceServerUpdate = player_gateway_payloads.VoiceServerUpdate;
pub const parseVoiceServerUpdate = player_gateway_payloads.parseVoiceServerUpdate;
pub const VoiceConnectionInfo = player_gateway_payloads.VoiceConnectionInfo;
pub const VoiceBootstrapState = player_gateway_payloads.VoiceBootstrapState;
pub const VoiceBootstrap = player_gateway_payloads.VoiceBootstrap;
