const std = @import("std");
const Gateway = @import("protocol.zig");
const Snowflake = @import("../core/snowflake.zig").Snowflake;

/// Mirrors the `session_start_limit` object returned by the Discord
/// `GET /gateway/bot` endpoint.
const supervisor_ipc = @import("sharding/supervisor_ipc.zig");
const manager = @import("sharding/manager.zig");

pub const SessionStartLimit = supervisor_ipc.SessionStartLimit;
pub const GatewayBotInfo = supervisor_ipc.GatewayBotInfo;
pub const readU32 = supervisor_ipc.readU32;
pub const readU64 = supervisor_ipc.readU64;
pub const ShardState = supervisor_ipc.ShardState;
pub const ShardInfo = supervisor_ipc.ShardInfo;
pub const IdentifyGroup = supervisor_ipc.IdentifyGroup;
pub const ShardCluster = supervisor_ipc.ShardCluster;
pub const ShardClusterProcessSpec = supervisor_ipc.ShardClusterProcessSpec;
pub const deinitShardClusterProcessSpecs = supervisor_ipc.deinitShardClusterProcessSpecs;
pub const deinitShardClusters = supervisor_ipc.deinitShardClusters;
pub const ShardClusterPlanOptions = supervisor_ipc.ShardClusterPlanOptions;
pub const ShardProcessOptions = supervisor_ipc.ShardProcessOptions;
pub const ShardProcessSpec = supervisor_ipc.ShardProcessSpec;
pub const buildShardProcessSpec = supervisor_ipc.buildShardProcessSpec;
pub const duplicateProcessArgv = supervisor_ipc.duplicateProcessArgv;
pub const shardListEnvValue = supervisor_ipc.shardListEnvValue;
pub const buildShardClusterProcessSpec = supervisor_ipc.buildShardClusterProcessSpec;
pub const deinitShardProcessSpecs = supervisor_ipc.deinitShardProcessSpecs;
pub const ShardRestartPolicy = supervisor_ipc.ShardRestartPolicy;
pub const ShardExitAction = supervisor_ipc.ShardExitAction;
pub const ShardSupervisorOptions = supervisor_ipc.ShardSupervisorOptions;
pub const shouldRestartShard = supervisor_ipc.shouldRestartShard;
pub const canRestartShard = supervisor_ipc.canRestartShard;
pub const ShardIpcMessageKind = supervisor_ipc.ShardIpcMessageKind;
pub const ShardIpcMessage = supervisor_ipc.ShardIpcMessage;
pub const writeJsonString = supervisor_ipc.writeJsonString;
pub const ShardIpcBroadcast = supervisor_ipc.ShardIpcBroadcast;
pub const ShardIpcHandler = supervisor_ipc.ShardIpcHandler;
pub const shardIpcHandler = supervisor_ipc.shardIpcHandler;
pub const ShardIpcRoute = supervisor_ipc.ShardIpcRoute;
pub const ShardIpcRouter = supervisor_ipc.ShardIpcRouter;
pub const ShardSupervisor = supervisor_ipc.ShardSupervisor;
pub const putSpecEnv = supervisor_ipc.putSpecEnv;
pub const ShardManager = manager.ShardManager;
