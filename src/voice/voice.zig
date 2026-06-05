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
const Gateway = @import("../gateway/protocol.zig");
const Json = @import("../core/json.zig");
const Snowflake = @import("../core/snowflake.zig").Snowflake;

const part_01 = @import("voice/part_01.zig");
const part_02 = @import("voice/part_02.zig");
const part_03 = @import("voice/part_03.zig");

pub const gateway_version = part_01.gateway_version;
pub const VoiceIdentifyOptions = part_01.VoiceIdentifyOptions;
pub const VoiceHeartbeat = part_01.VoiceHeartbeat;
pub const VoiceBinaryMessage = part_01.VoiceBinaryMessage;
pub const writeBinaryClientMessage = part_01.writeBinaryClientMessage;
pub const parseBinaryServerMessage = part_01.parseBinaryServerMessage;
pub const VoiceOpcode = part_01.VoiceOpcode;
pub const VoiceCloseCode = part_01.VoiceCloseCode;
pub const SpeakingFlags = part_01.SpeakingFlags;
pub const EncryptionMode = part_01.EncryptionMode;
pub const containsMode = part_01.containsMode;
pub const rtp_header_len = part_01.rtp_header_len;
pub const auth_tag_len = part_01.auth_tag_len;
pub const nonce_suffix_len = part_01.nonce_suffix_len;
pub const rtp_version_flags = part_01.rtp_version_flags;
pub const rtp_payload_type = part_01.rtp_payload_type;
pub const PacketError = part_01.PacketError;
pub const RtpHeader = part_01.RtpHeader;
pub const ReceivedAudioPacket = part_01.ReceivedAudioPacket;
pub const VoiceReceiver = part_01.VoiceReceiver;
pub const ReceivedUserAudioPacket = part_01.ReceivedUserAudioPacket;
pub const VoiceReceiveRouter = part_01.VoiceReceiveRouter;
pub const BufferedVoiceFrame = part_01.BufferedVoiceFrame;
pub const VoiceReceiveStream = part_01.VoiceReceiveStream;
pub const encryptedPacketLen = part_01.encryptedPacketLen;
pub const encryptPacket = part_01.encryptPacket;
pub const decryptPacket = part_01.decryptPacket;
pub const ip_discovery_packet_len = part_01.ip_discovery_packet_len;
pub const IpDiscovery = part_01.IpDiscovery;
pub const writeIpDiscovery = part_01.writeIpDiscovery;
pub const parseIpDiscovery = part_01.parseIpDiscovery;
pub const samples_per_frame = part_01.samples_per_frame;
pub const opus_silence_frame = part_01.opus_silence_frame;
pub const OpusCodec = part_01.OpusCodec;
pub const opusCodec = part_01.opusCodec;
pub const OpusFrameInfo = part_01.OpusFrameInfo;
pub const validateOpusFrame = part_01.validateOpusFrame;
pub const EncodedOpusFrames = part_01.EncodedOpusFrames;
pub const PcmMixOptions = part_01.PcmMixOptions;
pub const mixPcmSaturating = part_01.mixPcmSaturating;
pub const PcmMixer = part_01.PcmMixer;
pub const NextPacket = part_01.NextPacket;
pub const PacketCounter = part_01.PacketCounter;
pub const AudioPlayerStatus = part_01.AudioPlayerStatus;
pub const AudioResource = part_02.AudioResource;
pub const writeDaveTransitionReady = part_02.writeDaveTransitionReady;
pub const writeDaveMlsInvalidCommitWelcome = part_02.writeDaveMlsInvalidCommitWelcome;
pub const AudioPlayer = part_02.AudioPlayer;
pub const gatewayUrl = part_02.gatewayUrl;
pub const writeIdentify = part_02.writeIdentify;
pub const writeIdentifyWithOptions = part_02.writeIdentifyWithOptions;
pub const writeResume = part_02.writeResume;
pub const writeSelectProtocol = part_02.writeSelectProtocol;
pub const writeHeartbeat = part_02.writeHeartbeat;
pub const writeHeartbeatV8 = part_02.writeHeartbeatV8;
pub const writeSpeaking = part_02.writeSpeaking;
pub const dataObject = part_02.dataObject;
pub const numberToF64 = part_02.numberToF64;
pub const numberToU32 = part_02.numberToU32;
pub const numberToU16 = part_02.numberToU16;
pub const numberToU8 = part_02.numberToU8;
pub const objectValue = part_02.objectValue;
pub const stringField = part_02.stringField;
pub const nullableStringField = part_02.nullableStringField;
pub const snowflakeField = part_02.snowflakeField;
pub const nullableSnowflakeField = part_02.nullableSnowflakeField;
pub const parseHello = part_02.parseHello;
pub const VoiceReady = part_02.VoiceReady;
pub const parseReady = part_02.parseReady;
pub const SessionDescription = part_02.SessionDescription;
pub const parseSessionDescription = part_02.parseSessionDescription;
pub const parseHeartbeatAck = part_02.parseHeartbeatAck;
pub const VoiceServerUpdate = part_02.VoiceServerUpdate;
pub const parseVoiceServerUpdate = part_02.parseVoiceServerUpdate;
pub const VoiceConnectionInfo = part_02.VoiceConnectionInfo;
pub const VoiceBootstrapState = part_02.VoiceBootstrapState;
pub const VoiceBootstrap = part_02.VoiceBootstrap;
