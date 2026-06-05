const std = @import("std");
const Gateway = @import("protocol.zig");
const Snowflake = @import("../core/snowflake.zig").Snowflake;

/// Mirrors the `session_start_limit` object returned by the Discord
/// `GET /gateway/bot` endpoint.
const part_01 = @import("sharding/part_01.zig");
const part_02 = @import("sharding/part_02.zig");

pub const SessionStartLimit = part_01.SessionStartLimit;
pub const GatewayBotInfo = part_01.GatewayBotInfo;
pub const readU32 = part_01.readU32;
pub const readU64 = part_01.readU64;
pub const ShardState = part_01.ShardState;
pub const ShardInfo = part_01.ShardInfo;
pub const IdentifyGroup = part_01.IdentifyGroup;
pub const ShardCluster = part_01.ShardCluster;
pub const ShardClusterProcessSpec = part_01.ShardClusterProcessSpec;
pub const deinitShardClusterProcessSpecs = part_01.deinitShardClusterProcessSpecs;
pub const deinitShardClusters = part_01.deinitShardClusters;
pub const ShardClusterPlanOptions = part_01.ShardClusterPlanOptions;
pub const ShardProcessOptions = part_01.ShardProcessOptions;
pub const ShardProcessSpec = part_01.ShardProcessSpec;
pub const buildShardProcessSpec = part_01.buildShardProcessSpec;
pub const duplicateProcessArgv = part_01.duplicateProcessArgv;
pub const shardListEnvValue = part_01.shardListEnvValue;
pub const buildShardClusterProcessSpec = part_01.buildShardClusterProcessSpec;
pub const deinitShardProcessSpecs = part_01.deinitShardProcessSpecs;
pub const ShardRestartPolicy = part_01.ShardRestartPolicy;
pub const ShardExitAction = part_01.ShardExitAction;
pub const ShardSupervisorOptions = part_01.ShardSupervisorOptions;
pub const shouldRestartShard = part_01.shouldRestartShard;
pub const canRestartShard = part_01.canRestartShard;
pub const ShardIpcMessageKind = part_01.ShardIpcMessageKind;
pub const ShardIpcMessage = part_01.ShardIpcMessage;
pub const writeJsonString = part_01.writeJsonString;
pub const ShardIpcBroadcast = part_01.ShardIpcBroadcast;
pub const ShardIpcHandler = part_01.ShardIpcHandler;
pub const shardIpcHandler = part_01.shardIpcHandler;
pub const ShardIpcRoute = part_01.ShardIpcRoute;
pub const ShardIpcRouter = part_01.ShardIpcRouter;
pub const ShardSupervisor = part_01.ShardSupervisor;
pub const putSpecEnv = part_01.putSpecEnv;
pub const ShardManager = part_02.ShardManager;
