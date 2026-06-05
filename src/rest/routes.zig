const std = @import("std");
const Snowflake = @import("../core/snowflake.zig").Snowflake;
const Types = @import("../models/types.zig");

pub const Method = enum {
    GET,
    POST,
    PUT,
    PATCH,
    DELETE,
};

pub const Route = struct {
    method: Method,
    path: []const u8,
    bucket_path: []const u8,
    major_parameter: ?Snowflake = null,

    pub fn deinit(self: Route, allocator: std.mem.Allocator) void {
        allocator.free(self.path);
        allocator.free(self.bucket_path);
    }
};

pub fn gateway(allocator: std.mem.Allocator) !Route {
    const path = try allocator.dupe(u8, "/gateway");
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/gateway");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
    };
}

pub fn gatewayBot(allocator: std.mem.Allocator) !Route {
    const path = try allocator.dupe(u8, "/gateway/bot");
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/gateway/bot");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
    };
}

pub fn channel(allocator: std.mem.Allocator, channel_id: Snowflake) !Route {
    return channelRoute(allocator, .GET, channel_id);
}

pub fn editChannel(allocator: std.mem.Allocator, channel_id: Snowflake) !Route {
    return channelRoute(allocator, .PATCH, channel_id);
}

pub fn deleteChannel(allocator: std.mem.Allocator, channel_id: Snowflake) !Route {
    return channelRoute(allocator, .DELETE, channel_id);
}

pub fn addGroupDmRecipient(allocator: std.mem.Allocator, channel_id: Snowflake, user_id: Snowflake) !Route {
    return groupDmRecipientRoute(allocator, .PUT, channel_id, user_id);
}

pub fn removeGroupDmRecipient(allocator: std.mem.Allocator, channel_id: Snowflake, user_id: Snowflake) !Route {
    return groupDmRecipientRoute(allocator, .DELETE, channel_id, user_id);
}

fn groupDmRecipientRoute(
    allocator: std.mem.Allocator,
    method: Method,
    channel_id: Snowflake,
    user_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/channels/{d}/recipients/{d}",
        .{ channel_id.value, user_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/recipients/{user_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

fn channelRoute(allocator: std.mem.Allocator, method: Method, channel_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/channels/{d}", .{channel_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn editChannelPermission(allocator: std.mem.Allocator, channel_id: Snowflake, overwrite_id: Snowflake) !Route {
    return channelPermissionRoute(allocator, .PUT, channel_id, overwrite_id);
}

pub fn deleteChannelPermission(allocator: std.mem.Allocator, channel_id: Snowflake, overwrite_id: Snowflake) !Route {
    return channelPermissionRoute(allocator, .DELETE, channel_id, overwrite_id);
}

fn channelPermissionRoute(
    allocator: std.mem.Allocator,
    method: Method,
    channel_id: Snowflake,
    overwrite_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/channels/{d}/permissions/{d}",
        .{ channel_id.value, overwrite_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/permissions/{overwrite_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn setVoiceChannelStatus(allocator: std.mem.Allocator, channel_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/channels/{d}/voice-status", .{channel_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/voice-status");
    return .{
        .method = .PUT,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn followAnnouncementChannel(allocator: std.mem.Allocator, channel_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/channels/{d}/followers", .{channel_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/followers");
    return .{
        .method = .POST,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn sendSoundboardSound(allocator: std.mem.Allocator, channel_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/channels/{d}/send-soundboard-sound", .{channel_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/send-soundboard-sound");
    return .{
        .method = .POST,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn createStageInstance(allocator: std.mem.Allocator) !Route {
    const path = try allocator.dupe(u8, "/stage-instances");
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/stage-instances");
    return .{ .method = .POST, .path = path, .bucket_path = bucket_path };
}

pub fn stageInstance(allocator: std.mem.Allocator, channel_id: Snowflake) !Route {
    return stageInstanceRoute(allocator, .GET, channel_id);
}

pub fn editStageInstance(allocator: std.mem.Allocator, channel_id: Snowflake) !Route {
    return stageInstanceRoute(allocator, .PATCH, channel_id);
}

pub fn deleteStageInstance(allocator: std.mem.Allocator, channel_id: Snowflake) !Route {
    return stageInstanceRoute(allocator, .DELETE, channel_id);
}

fn stageInstanceRoute(allocator: std.mem.Allocator, method: Method, channel_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/stage-instances/{d}", .{channel_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/stage-instances/{channel_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn currentApplication(allocator: std.mem.Allocator) !Route {
    return currentApplicationRoute(allocator, .GET);
}

pub fn currentBotApplication(allocator: std.mem.Allocator) !Route {
    const path = try allocator.dupe(u8, "/oauth2/applications/@me");
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/oauth2/applications/@me");
    return .{ .method = .GET, .path = path, .bucket_path = bucket_path };
}

pub fn editCurrentApplication(allocator: std.mem.Allocator) !Route {
    return currentApplicationRoute(allocator, .PATCH);
}

fn currentApplicationRoute(allocator: std.mem.Allocator, method: Method) !Route {
    const path = try allocator.dupe(u8, "/applications/@me");
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/applications/@me");
    return .{ .method = method, .path = path, .bucket_path = bucket_path };
}

pub fn applicationSkus(allocator: std.mem.Allocator, application_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/applications/{d}/skus", .{application_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/applications/{application_id}/skus");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = application_id,
    };
}

pub fn applicationRoleConnectionMetadataRecords(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
) !Route {
    return applicationRoleConnectionMetadataRecordsRoute(allocator, .GET, application_id);
}

pub fn updateApplicationRoleConnectionMetadataRecords(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
) !Route {
    return applicationRoleConnectionMetadataRecordsRoute(allocator, .PUT, application_id);
}

fn applicationRoleConnectionMetadataRecordsRoute(
    allocator: std.mem.Allocator,
    method: Method,
    application_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/applications/{d}/role-connections/metadata",
        .{application_id.value},
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/applications/{application_id}/role-connections/metadata");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = application_id,
    };
}

pub fn applicationEmojis(allocator: std.mem.Allocator, application_id: Snowflake) !Route {
    return applicationEmojisRoute(allocator, .GET, application_id);
}

pub fn createApplicationEmoji(allocator: std.mem.Allocator, application_id: Snowflake) !Route {
    return applicationEmojisRoute(allocator, .POST, application_id);
}

fn applicationEmojisRoute(allocator: std.mem.Allocator, method: Method, application_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/applications/{d}/emojis", .{application_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/applications/{application_id}/emojis");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = application_id,
    };
}

pub fn applicationEmoji(allocator: std.mem.Allocator, application_id: Snowflake, emoji_id: Snowflake) !Route {
    return applicationEmojiRoute(allocator, .GET, application_id, emoji_id);
}

pub fn editApplicationEmoji(allocator: std.mem.Allocator, application_id: Snowflake, emoji_id: Snowflake) !Route {
    return applicationEmojiRoute(allocator, .PATCH, application_id, emoji_id);
}

pub fn deleteApplicationEmoji(allocator: std.mem.Allocator, application_id: Snowflake, emoji_id: Snowflake) !Route {
    return applicationEmojiRoute(allocator, .DELETE, application_id, emoji_id);
}

fn applicationEmojiRoute(
    allocator: std.mem.Allocator,
    method: Method,
    application_id: Snowflake,
    emoji_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/applications/{d}/emojis/{d}",
        .{ application_id.value, emoji_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/applications/{application_id}/emojis/{emoji_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = application_id,
    };
}

pub fn applicationActivityInstance(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    instance_id: []const u8,
) !Route {
    const escaped_instance_id = try percentEncode(allocator, instance_id);
    defer allocator.free(escaped_instance_id);
    const path = try std.fmt.allocPrint(
        allocator,
        "/applications/{d}/activity-instances/{s}",
        .{ application_id.value, escaped_instance_id },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/applications/{application_id}/activity-instances/{instance_id}");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = application_id,
    };
}

pub fn createLobby(allocator: std.mem.Allocator) !Route {
    const path = try allocator.dupe(u8, "/lobbies");
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/lobbies");
    return .{ .method = .POST, .path = path, .bucket_path = bucket_path };
}

pub fn lobby(allocator: std.mem.Allocator, lobby_id: Snowflake) !Route {
    return lobbyRoute(allocator, .GET, lobby_id);
}

pub fn editLobby(allocator: std.mem.Allocator, lobby_id: Snowflake) !Route {
    return lobbyRoute(allocator, .PATCH, lobby_id);
}

pub fn deleteLobby(allocator: std.mem.Allocator, lobby_id: Snowflake) !Route {
    return lobbyRoute(allocator, .DELETE, lobby_id);
}

fn lobbyRoute(allocator: std.mem.Allocator, method: Method, lobby_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/lobbies/{d}", .{lobby_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/lobbies/{lobby_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = lobby_id,
    };
}

pub fn lobbyMember(allocator: std.mem.Allocator, lobby_id: Snowflake, user_id: Snowflake) !Route {
    return lobbyMemberRoute(allocator, .PUT, lobby_id, user_id);
}

pub fn deleteLobbyMember(allocator: std.mem.Allocator, lobby_id: Snowflake, user_id: Snowflake) !Route {
    return lobbyMemberRoute(allocator, .DELETE, lobby_id, user_id);
}

fn lobbyMemberRoute(
    allocator: std.mem.Allocator,
    method: Method,
    lobby_id: Snowflake,
    user_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(allocator, "/lobbies/{d}/members/{d}", .{ lobby_id.value, user_id.value });
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/lobbies/{lobby_id}/members/{user_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = lobby_id,
    };
}

pub fn bulkUpdateLobbyMembers(allocator: std.mem.Allocator, lobby_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/lobbies/{d}/members/bulk", .{lobby_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/lobbies/{lobby_id}/members/bulk");
    return .{
        .method = .POST,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = lobby_id,
    };
}

pub fn leaveLobby(allocator: std.mem.Allocator, lobby_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/lobbies/{d}/members/@me", .{lobby_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/lobbies/{lobby_id}/members/@me");
    return .{
        .method = .DELETE,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = lobby_id,
    };
}

pub fn linkLobbyChannel(allocator: std.mem.Allocator, lobby_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/lobbies/{d}/channel-linking", .{lobby_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/lobbies/{lobby_id}/channel-linking");
    return .{
        .method = .PATCH,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = lobby_id,
    };
}

pub fn updateLobbyMessageModerationMetadata(
    allocator: std.mem.Allocator,
    lobby_id: Snowflake,
    message_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/lobbies/{d}/messages/{d}/moderation-metadata",
        .{ lobby_id.value, message_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/lobbies/{lobby_id}/messages/{message_id}/moderation-metadata");
    return .{
        .method = .PUT,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = lobby_id,
    };
}

pub fn applicationEntitlements(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    options: Types.ListEntitlements,
) !Route {
    var query = std.Io.Writer.Allocating.init(allocator);
    defer query.deinit();
    if (options.hasQuery()) {
        try query.writer.writeByte('?');
        try options.writeQuery(&query.writer);
    }

    const path = try std.fmt.allocPrint(
        allocator,
        "/applications/{d}/entitlements{s}",
        .{ application_id.value, query.written() },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/applications/{application_id}/entitlements");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = application_id,
    };
}

pub fn createTestEntitlement(allocator: std.mem.Allocator, application_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/applications/{d}/entitlements", .{application_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/applications/{application_id}/entitlements");
    return .{
        .method = .POST,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = application_id,
    };
}

pub fn applicationEntitlement(allocator: std.mem.Allocator, application_id: Snowflake, entitlement_id: Snowflake) !Route {
    return applicationEntitlementRoute(allocator, .GET, application_id, entitlement_id);
}

pub fn deleteTestEntitlement(allocator: std.mem.Allocator, application_id: Snowflake, entitlement_id: Snowflake) !Route {
    return applicationEntitlementRoute(allocator, .DELETE, application_id, entitlement_id);
}

fn applicationEntitlementRoute(
    allocator: std.mem.Allocator,
    method: Method,
    application_id: Snowflake,
    entitlement_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/applications/{d}/entitlements/{d}",
        .{ application_id.value, entitlement_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/applications/{application_id}/entitlements/{entitlement_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = application_id,
    };
}

pub fn consumeEntitlement(allocator: std.mem.Allocator, application_id: Snowflake, entitlement_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/applications/{d}/entitlements/{d}/consume",
        .{ application_id.value, entitlement_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/applications/{application_id}/entitlements/{entitlement_id}/consume");
    return .{
        .method = .POST,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = application_id,
    };
}

pub fn skuSubscriptions(allocator: std.mem.Allocator, sku_id: Snowflake, options: Types.ListSkuSubscriptions) !Route {
    var query = std.Io.Writer.Allocating.init(allocator);
    defer query.deinit();
    if (options.hasQuery()) {
        try query.writer.writeByte('?');
        try options.writeQuery(&query.writer);
    }

    const path = try std.fmt.allocPrint(
        allocator,
        "/skus/{d}/subscriptions{s}",
        .{ sku_id.value, query.written() },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/skus/{sku_id}/subscriptions");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = sku_id,
    };
}

pub fn skuSubscription(allocator: std.mem.Allocator, sku_id: Snowflake, subscription_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/skus/{d}/subscriptions/{d}",
        .{ sku_id.value, subscription_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/skus/{sku_id}/subscriptions/{subscription_id}");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = sku_id,
    };
}

pub fn voiceRegions(allocator: std.mem.Allocator) !Route {
    const path = try allocator.dupe(u8, "/voice/regions");
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/voice/regions");
    return .{ .method = .GET, .path = path, .bucket_path = bucket_path };
}

pub fn guildVoiceRegions(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/regions", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/regions");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn currentUserVoiceState(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return userVoiceStateRoute(allocator, .GET, guild_id, null);
}

pub fn editCurrentUserVoiceState(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return userVoiceStateRoute(allocator, .PATCH, guild_id, null);
}

pub fn userVoiceState(allocator: std.mem.Allocator, guild_id: Snowflake, user_id: Snowflake) !Route {
    return userVoiceStateRoute(allocator, .GET, guild_id, user_id);
}

pub fn editUserVoiceState(allocator: std.mem.Allocator, guild_id: Snowflake, user_id: Snowflake) !Route {
    return userVoiceStateRoute(allocator, .PATCH, guild_id, user_id);
}

fn userVoiceStateRoute(
    allocator: std.mem.Allocator,
    method: Method,
    guild_id: Snowflake,
    user_id: ?Snowflake,
) !Route {
    const path = if (user_id) |id|
        try std.fmt.allocPrint(allocator, "/guilds/{d}/voice-states/{d}", .{ guild_id.value, id.value })
    else
        try std.fmt.allocPrint(allocator, "/guilds/{d}/voice-states/@me", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = if (user_id != null)
        try allocator.dupe(u8, "/guilds/{guild_id}/voice-states/{user_id}")
    else
        try allocator.dupe(u8, "/guilds/{guild_id}/voice-states/@me");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn currentUser(allocator: std.mem.Allocator) !Route {
    return currentUserRoute(allocator, .GET);
}

pub fn editCurrentUser(allocator: std.mem.Allocator) !Route {
    return currentUserRoute(allocator, .PATCH);
}

fn currentUserRoute(allocator: std.mem.Allocator, method: Method) !Route {
    const path = try allocator.dupe(u8, "/users/@me");
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/users/@me");
    return .{ .method = method, .path = path, .bucket_path = bucket_path };
}

pub fn createDmChannel(allocator: std.mem.Allocator) !Route {
    const path = try allocator.dupe(u8, "/users/@me/channels");
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/users/@me/channels");
    return .{ .method = .POST, .path = path, .bucket_path = bucket_path };
}

pub fn currentUserGuilds(allocator: std.mem.Allocator, options: Types.ListCurrentUserGuilds) !Route {
    var query = std.Io.Writer.Allocating.init(allocator);
    defer query.deinit();
    if (options.hasQuery()) {
        try query.writer.writeByte('?');
        try options.writeQuery(&query.writer);
    }

    const path = try std.fmt.allocPrint(allocator, "/users/@me/guilds{s}", .{query.written()});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/users/@me/guilds");
    return .{ .method = .GET, .path = path, .bucket_path = bucket_path };
}

pub fn currentUserGuildMember(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/users/@me/guilds/{d}/member", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/users/@me/guilds/{guild_id}/member");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn currentUserConnections(allocator: std.mem.Allocator) !Route {
    const path = try allocator.dupe(u8, "/users/@me/connections");
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/users/@me/connections");
    return .{ .method = .GET, .path = path, .bucket_path = bucket_path };
}

pub fn currentAuthorization(allocator: std.mem.Allocator) !Route {
    const path = try allocator.dupe(u8, "/oauth2/@me");
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/oauth2/@me");
    return .{ .method = .GET, .path = path, .bucket_path = bucket_path };
}

pub fn oauth2Token(allocator: std.mem.Allocator) !Route {
    const path = try allocator.dupe(u8, "/oauth2/token");
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/oauth2/token");
    return .{ .method = .POST, .path = path, .bucket_path = bucket_path };
}

pub fn revokeOAuth2Token(allocator: std.mem.Allocator) !Route {
    const path = try allocator.dupe(u8, "/oauth2/token/revoke");
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/oauth2/token/revoke");
    return .{ .method = .POST, .path = path, .bucket_path = bucket_path };
}

pub fn currentUserApplicationRoleConnection(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
) !Route {
    return currentUserApplicationRoleConnectionRoute(allocator, .GET, application_id);
}

pub fn updateCurrentUserApplicationRoleConnection(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
) !Route {
    return currentUserApplicationRoleConnectionRoute(allocator, .PUT, application_id);
}

pub fn deleteCurrentUserApplicationRoleConnection(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
) !Route {
    return currentUserApplicationRoleConnectionRoute(allocator, .DELETE, application_id);
}

fn currentUserApplicationRoleConnectionRoute(
    allocator: std.mem.Allocator,
    method: Method,
    application_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/users/@me/applications/{d}/role-connection",
        .{application_id.value},
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/users/@me/applications/{application_id}/role-connection");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = application_id,
    };
}

pub fn leaveGuild(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/users/@me/guilds/{d}", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/users/@me/guilds/{guild_id}");
    return .{
        .method = .DELETE,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn user(allocator: std.mem.Allocator, user_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/users/{d}", .{user_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/users/{user_id}");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = user_id,
    };
}

pub fn createGuild(allocator: std.mem.Allocator) !Route {
    const path = try allocator.dupe(u8, "/guilds");
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds");
    return .{ .method = .POST, .path = path, .bucket_path = bucket_path };
}

pub fn guild(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return guildRoute(allocator, .GET, guild_id);
}

pub fn guildWithOptions(allocator: std.mem.Allocator, guild_id: Snowflake, options: Types.GetGuild) !Route {
    return guildRouteWithQuery(allocator, .GET, guild_id, options);
}

pub fn editGuild(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return guildRoute(allocator, .PATCH, guild_id);
}

pub fn deleteGuild(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return guildRoute(allocator, .DELETE, guild_id);
}

fn guildRoute(allocator: std.mem.Allocator, method: Method, guild_id: Snowflake) !Route {
    return guildRouteWithQuery(allocator, method, guild_id, null);
}

fn guildRouteWithQuery(
    allocator: std.mem.Allocator,
    method: Method,
    guild_id: Snowflake,
    maybe_options: ?Types.GetGuild,
) !Route {
    var query = std.Io.Writer.Allocating.init(allocator);
    defer query.deinit();
    if (maybe_options) |options| {
        if (options.hasQuery()) {
            try query.writer.writeByte('?');
            try options.writeQuery(&query.writer);
        }
    }

    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}", .{guild_id.value});
    const path_with_query = try std.fmt.allocPrint(allocator, "{s}{s}", .{ path, query.written() });
    allocator.free(path);
    errdefer allocator.free(path_with_query);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}");
    return .{
        .method = method,
        .path = path_with_query,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildPreview(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/preview", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/preview");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn autoModerationRules(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return autoModerationRulesRoute(allocator, .GET, guild_id);
}

pub fn createAutoModerationRule(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return autoModerationRulesRoute(allocator, .POST, guild_id);
}

fn autoModerationRulesRoute(allocator: std.mem.Allocator, method: Method, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/auto-moderation/rules", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/auto-moderation/rules");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn autoModerationRule(allocator: std.mem.Allocator, guild_id: Snowflake, rule_id: Snowflake) !Route {
    return autoModerationRuleRoute(allocator, .GET, guild_id, rule_id);
}

pub fn editAutoModerationRule(allocator: std.mem.Allocator, guild_id: Snowflake, rule_id: Snowflake) !Route {
    return autoModerationRuleRoute(allocator, .PATCH, guild_id, rule_id);
}

pub fn deleteAutoModerationRule(allocator: std.mem.Allocator, guild_id: Snowflake, rule_id: Snowflake) !Route {
    return autoModerationRuleRoute(allocator, .DELETE, guild_id, rule_id);
}

fn autoModerationRuleRoute(
    allocator: std.mem.Allocator,
    method: Method,
    guild_id: Snowflake,
    rule_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/guilds/{d}/auto-moderation/rules/{d}",
        .{ guild_id.value, rule_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/auto-moderation/rules/{rule_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildTemplate(allocator: std.mem.Allocator, code: []const u8) !Route {
    const escaped_code = try percentEncode(allocator, code);
    defer allocator.free(escaped_code);

    const path = try std.fmt.allocPrint(allocator, "/guilds/templates/{s}", .{escaped_code});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/templates/{template_code}");
    return .{ .method = .GET, .path = path, .bucket_path = bucket_path };
}

pub fn createGuildFromTemplate(allocator: std.mem.Allocator, code: []const u8) !Route {
    const escaped_code = try percentEncode(allocator, code);
    defer allocator.free(escaped_code);

    const path = try std.fmt.allocPrint(allocator, "/guilds/templates/{s}", .{escaped_code});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/templates/{template_code}");
    return .{ .method = .POST, .path = path, .bucket_path = bucket_path };
}

pub fn guildTemplates(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return guildTemplatesRoute(allocator, .GET, guild_id);
}

pub fn createGuildTemplate(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return guildTemplatesRoute(allocator, .POST, guild_id);
}

fn guildTemplatesRoute(allocator: std.mem.Allocator, method: Method, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/templates", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/templates");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn syncGuildTemplate(allocator: std.mem.Allocator, guild_id: Snowflake, code: []const u8) !Route {
    return guildTemplateRoute(allocator, .PUT, guild_id, code);
}

pub fn editGuildTemplate(allocator: std.mem.Allocator, guild_id: Snowflake, code: []const u8) !Route {
    return guildTemplateRoute(allocator, .PATCH, guild_id, code);
}

pub fn deleteGuildTemplate(allocator: std.mem.Allocator, guild_id: Snowflake, code: []const u8) !Route {
    return guildTemplateRoute(allocator, .DELETE, guild_id, code);
}

fn guildTemplateRoute(
    allocator: std.mem.Allocator,
    method: Method,
    guild_id: Snowflake,
    code: []const u8,
) !Route {
    const escaped_code = try percentEncode(allocator, code);
    defer allocator.free(escaped_code);

    const path = try std.fmt.allocPrint(
        allocator,
        "/guilds/{d}/templates/{s}",
        .{ guild_id.value, escaped_code },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/templates/{template_code}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildWidgetSettings(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return guildWidgetSettingsRoute(allocator, .GET, guild_id);
}

pub fn editGuildWidgetSettings(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return guildWidgetSettingsRoute(allocator, .PATCH, guild_id);
}

fn guildWidgetSettingsRoute(allocator: std.mem.Allocator, method: Method, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/widget", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/widget");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildWidget(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/widget.json", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/widget.json");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildWidgetImage(
    allocator: std.mem.Allocator,
    guild_id: Snowflake,
    options: Types.GetGuildWidgetImage,
) !Route {
    var query = std.Io.Writer.Allocating.init(allocator);
    defer query.deinit();
    if (options.hasQuery()) {
        try query.writer.writeByte('?');
        try options.writeQuery(&query.writer);
    }

    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/widget.png{s}", .{ guild_id.value, query.written() });
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/widget.png");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildWelcomeScreen(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return guildWelcomeScreenRoute(allocator, .GET, guild_id);
}

pub fn editGuildWelcomeScreen(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return guildWelcomeScreenRoute(allocator, .PATCH, guild_id);
}

fn guildWelcomeScreenRoute(allocator: std.mem.Allocator, method: Method, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/welcome-screen", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/welcome-screen");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildOnboarding(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return guildOnboardingRoute(allocator, .GET, guild_id);
}

pub fn editGuildOnboarding(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return guildOnboardingRoute(allocator, .PATCH, guild_id);
}

fn guildOnboardingRoute(allocator: std.mem.Allocator, method: Method, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/onboarding", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/onboarding");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn editGuildIncidentActions(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/incident-actions", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/incident-actions");
    return .{
        .method = .PUT,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildVanityUrl(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/vanity-url", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/vanity-url");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildScheduledEvents(
    allocator: std.mem.Allocator,
    guild_id: Snowflake,
    options: Types.ListGuildScheduledEvents,
) !Route {
    var query = std.Io.Writer.Allocating.init(allocator);
    defer query.deinit();
    if (options.hasQuery()) {
        try query.writer.writeByte('?');
        try options.writeQuery(&query.writer);
    }

    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/scheduled-events{s}", .{ guild_id.value, query.written() });
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/scheduled-events");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn createGuildScheduledEvent(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/scheduled-events", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/scheduled-events");
    return .{
        .method = .POST,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildScheduledEvent(
    allocator: std.mem.Allocator,
    guild_id: Snowflake,
    event_id: Snowflake,
    options: Types.GetGuildScheduledEvent,
) !Route {
    var query = std.Io.Writer.Allocating.init(allocator);
    defer query.deinit();
    if (options.hasQuery()) {
        try query.writer.writeByte('?');
        try options.writeQuery(&query.writer);
    }

    const path = try std.fmt.allocPrint(
        allocator,
        "/guilds/{d}/scheduled-events/{d}{s}",
        .{ guild_id.value, event_id.value, query.written() },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/scheduled-events/{guild_scheduled_event_id}");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn editGuildScheduledEvent(allocator: std.mem.Allocator, guild_id: Snowflake, event_id: Snowflake) !Route {
    return guildScheduledEventMutationRoute(allocator, .PATCH, guild_id, event_id);
}

pub fn deleteGuildScheduledEvent(allocator: std.mem.Allocator, guild_id: Snowflake, event_id: Snowflake) !Route {
    return guildScheduledEventMutationRoute(allocator, .DELETE, guild_id, event_id);
}

fn guildScheduledEventMutationRoute(
    allocator: std.mem.Allocator,
    method: Method,
    guild_id: Snowflake,
    event_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/guilds/{d}/scheduled-events/{d}",
        .{ guild_id.value, event_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/scheduled-events/{guild_scheduled_event_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildScheduledEventUsers(
    allocator: std.mem.Allocator,
    guild_id: Snowflake,
    event_id: Snowflake,
    options: Types.ListGuildScheduledEventUsers,
) !Route {
    var query = std.Io.Writer.Allocating.init(allocator);
    defer query.deinit();
    if (options.hasQuery()) {
        try query.writer.writeByte('?');
        try options.writeQuery(&query.writer);
    }

    const path = try std.fmt.allocPrint(
        allocator,
        "/guilds/{d}/scheduled-events/{d}/users{s}",
        .{ guild_id.value, event_id.value, query.written() },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/scheduled-events/{guild_scheduled_event_id}/users");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildAuditLog(allocator: std.mem.Allocator, guild_id: Snowflake, options: Types.ListAuditLog) !Route {
    var query = std.Io.Writer.Allocating.init(allocator);
    defer query.deinit();
    if (options.hasQuery()) {
        try query.writer.writeByte('?');
        try options.writeQuery(&query.writer);
    }

    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/audit-logs{s}", .{ guild_id.value, query.written() });
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/audit-logs");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildIntegrations(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/integrations", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/integrations");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn deleteGuildIntegration(allocator: std.mem.Allocator, guild_id: Snowflake, integration_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/guilds/{d}/integrations/{d}",
        .{ guild_id.value, integration_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/integrations/{integration_id}");
    return .{
        .method = .DELETE,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildChannels(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return guildChannelsRoute(allocator, .GET, guild_id);
}

pub fn createGuildChannel(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return guildChannelsRoute(allocator, .POST, guild_id);
}

pub fn editGuildChannelPositions(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return guildChannelsRoute(allocator, .PATCH, guild_id);
}

fn guildChannelsRoute(allocator: std.mem.Allocator, method: Method, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/channels", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/channels");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildMembers(allocator: std.mem.Allocator, guild_id: Snowflake, options: Types.ListGuildMembers) !Route {
    var query = std.Io.Writer.Allocating.init(allocator);
    defer query.deinit();
    if (options.hasQuery()) {
        try query.writer.writeByte('?');
        try options.writeQuery(&query.writer);
    }

    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/members{s}", .{ guild_id.value, query.written() });
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/members");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn searchGuildMembers(allocator: std.mem.Allocator, guild_id: Snowflake, options: Types.SearchGuildMembers) !Route {
    var query = std.Io.Writer.Allocating.init(allocator);
    defer query.deinit();
    try query.writer.writeByte('?');
    try options.writeQuery(&query.writer);

    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/members/search{s}", .{ guild_id.value, query.written() });
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/members/search");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn editCurrentGuildMember(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/members/@me", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/members/@me");
    return .{
        .method = .PATCH,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn editCurrentUserNick(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/members/@me/nick", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/members/@me/nick");
    return .{
        .method = .PATCH,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildMember(allocator: std.mem.Allocator, guild_id: Snowflake, user_id: Snowflake) !Route {
    return guildMemberRoute(allocator, .GET, guild_id, user_id);
}

pub fn addGuildMember(allocator: std.mem.Allocator, guild_id: Snowflake, user_id: Snowflake) !Route {
    return guildMemberRoute(allocator, .PUT, guild_id, user_id);
}

pub fn editGuildMember(allocator: std.mem.Allocator, guild_id: Snowflake, user_id: Snowflake) !Route {
    return guildMemberRoute(allocator, .PATCH, guild_id, user_id);
}

pub fn removeGuildMember(allocator: std.mem.Allocator, guild_id: Snowflake, user_id: Snowflake) !Route {
    return guildMemberRoute(allocator, .DELETE, guild_id, user_id);
}

fn guildMemberRoute(
    allocator: std.mem.Allocator,
    method: Method,
    guild_id: Snowflake,
    user_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/guilds/{d}/members/{d}",
        .{ guild_id.value, user_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/members/{user_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildBans(allocator: std.mem.Allocator, guild_id: Snowflake, options: Types.ListGuildBans) !Route {
    var query = std.Io.Writer.Allocating.init(allocator);
    defer query.deinit();
    if (options.hasQuery()) {
        try query.writer.writeByte('?');
        try options.writeQuery(&query.writer);
    }

    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/bans{s}", .{ guild_id.value, query.written() });
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/bans");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildBan(allocator: std.mem.Allocator, guild_id: Snowflake, user_id: Snowflake) !Route {
    return guildBanRoute(allocator, .GET, guild_id, user_id);
}

pub fn guildPruneCount(allocator: std.mem.Allocator, guild_id: Snowflake, options: Types.GetGuildPruneCount) !Route {
    var query = std.Io.Writer.Allocating.init(allocator);
    defer query.deinit();
    if (options.hasQuery()) {
        try query.writer.writeByte('?');
        try options.writeQuery(&query.writer);
    }

    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/prune{s}", .{ guild_id.value, query.written() });
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/prune");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn beginGuildPrune(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/prune", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/prune");
    return .{
        .method = .POST,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn createGuildBan(allocator: std.mem.Allocator, guild_id: Snowflake, user_id: Snowflake) !Route {
    return guildBanRoute(allocator, .PUT, guild_id, user_id);
}

pub fn removeGuildBan(allocator: std.mem.Allocator, guild_id: Snowflake, user_id: Snowflake) !Route {
    return guildBanRoute(allocator, .DELETE, guild_id, user_id);
}

pub fn bulkGuildBan(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/bulk-ban", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/bulk-ban");
    return .{
        .method = .POST,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

fn guildBanRoute(
    allocator: std.mem.Allocator,
    method: Method,
    guild_id: Snowflake,
    user_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/guilds/{d}/bans/{d}",
        .{ guild_id.value, user_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/bans/{user_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildRoles(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return guildRolesRoute(allocator, .GET, guild_id);
}

pub fn createGuildRole(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return guildRolesRoute(allocator, .POST, guild_id);
}

pub fn editGuildRolePositions(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return guildRolesRoute(allocator, .PATCH, guild_id);
}

fn guildRolesRoute(allocator: std.mem.Allocator, method: Method, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/roles", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/roles");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildRoleMemberCounts(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/roles/member-counts", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/roles/member-counts");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildRole(allocator: std.mem.Allocator, guild_id: Snowflake, role_id: Snowflake) !Route {
    return guildRoleRoute(allocator, .GET, guild_id, role_id);
}

pub fn editGuildRole(allocator: std.mem.Allocator, guild_id: Snowflake, role_id: Snowflake) !Route {
    return guildRoleRoute(allocator, .PATCH, guild_id, role_id);
}

pub fn deleteGuildRole(allocator: std.mem.Allocator, guild_id: Snowflake, role_id: Snowflake) !Route {
    return guildRoleRoute(allocator, .DELETE, guild_id, role_id);
}

fn guildRoleRoute(
    allocator: std.mem.Allocator,
    method: Method,
    guild_id: Snowflake,
    role_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/guilds/{d}/roles/{d}",
        .{ guild_id.value, role_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/roles/{role_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildEmojis(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return guildEmojisRoute(allocator, .GET, guild_id);
}

pub fn createGuildEmoji(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return guildEmojisRoute(allocator, .POST, guild_id);
}

fn guildEmojisRoute(allocator: std.mem.Allocator, method: Method, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/emojis", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/emojis");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildEmoji(allocator: std.mem.Allocator, guild_id: Snowflake, emoji_id: Snowflake) !Route {
    return guildEmojiRoute(allocator, .GET, guild_id, emoji_id);
}

pub fn editGuildEmoji(allocator: std.mem.Allocator, guild_id: Snowflake, emoji_id: Snowflake) !Route {
    return guildEmojiRoute(allocator, .PATCH, guild_id, emoji_id);
}

pub fn deleteGuildEmoji(allocator: std.mem.Allocator, guild_id: Snowflake, emoji_id: Snowflake) !Route {
    return guildEmojiRoute(allocator, .DELETE, guild_id, emoji_id);
}

fn guildEmojiRoute(
    allocator: std.mem.Allocator,
    method: Method,
    guild_id: Snowflake,
    emoji_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/guilds/{d}/emojis/{d}",
        .{ guild_id.value, emoji_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/emojis/{emoji_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildStickers(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return guildStickersRoute(allocator, .GET, guild_id);
}

pub fn sticker(allocator: std.mem.Allocator, sticker_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/stickers/{d}", .{sticker_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/stickers/{sticker_id}");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = sticker_id,
    };
}

pub fn stickerPacks(allocator: std.mem.Allocator) !Route {
    const path = try allocator.dupe(u8, "/sticker-packs");
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/sticker-packs");
    return .{ .method = .GET, .path = path, .bucket_path = bucket_path };
}

pub fn createGuildSticker(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return guildStickersRoute(allocator, .POST, guild_id);
}

fn guildStickersRoute(allocator: std.mem.Allocator, method: Method, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/stickers", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/stickers");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildSticker(allocator: std.mem.Allocator, guild_id: Snowflake, sticker_id: Snowflake) !Route {
    return guildStickerRoute(allocator, .GET, guild_id, sticker_id);
}

pub fn editGuildSticker(allocator: std.mem.Allocator, guild_id: Snowflake, sticker_id: Snowflake) !Route {
    return guildStickerRoute(allocator, .PATCH, guild_id, sticker_id);
}

pub fn deleteGuildSticker(allocator: std.mem.Allocator, guild_id: Snowflake, sticker_id: Snowflake) !Route {
    return guildStickerRoute(allocator, .DELETE, guild_id, sticker_id);
}

fn guildStickerRoute(
    allocator: std.mem.Allocator,
    method: Method,
    guild_id: Snowflake,
    sticker_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/guilds/{d}/stickers/{d}",
        .{ guild_id.value, sticker_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/stickers/{sticker_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn defaultSoundboardSounds(allocator: std.mem.Allocator) !Route {
    const path = try allocator.dupe(u8, "/soundboard-default-sounds");
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/soundboard-default-sounds");
    return .{ .method = .GET, .path = path, .bucket_path = bucket_path };
}

pub fn guildSoundboardSounds(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return guildSoundboardSoundsRoute(allocator, .GET, guild_id);
}

pub fn createGuildSoundboardSound(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    return guildSoundboardSoundsRoute(allocator, .POST, guild_id);
}

fn guildSoundboardSoundsRoute(allocator: std.mem.Allocator, method: Method, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/soundboard-sounds", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/soundboard-sounds");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildSoundboardSound(allocator: std.mem.Allocator, guild_id: Snowflake, sound_id: Snowflake) !Route {
    return guildSoundboardSoundRoute(allocator, .GET, guild_id, sound_id);
}

pub fn editGuildSoundboardSound(allocator: std.mem.Allocator, guild_id: Snowflake, sound_id: Snowflake) !Route {
    return guildSoundboardSoundRoute(allocator, .PATCH, guild_id, sound_id);
}

pub fn deleteGuildSoundboardSound(allocator: std.mem.Allocator, guild_id: Snowflake, sound_id: Snowflake) !Route {
    return guildSoundboardSoundRoute(allocator, .DELETE, guild_id, sound_id);
}

fn guildSoundboardSoundRoute(
    allocator: std.mem.Allocator,
    method: Method,
    guild_id: Snowflake,
    sound_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/guilds/{d}/soundboard-sounds/{d}",
        .{ guild_id.value, sound_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/soundboard-sounds/{sound_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn addGuildMemberRole(
    allocator: std.mem.Allocator,
    guild_id: Snowflake,
    user_id: Snowflake,
    role_id: Snowflake,
) !Route {
    return guildMemberRoleRoute(allocator, .PUT, guild_id, user_id, role_id);
}

pub fn removeGuildMemberRole(
    allocator: std.mem.Allocator,
    guild_id: Snowflake,
    user_id: Snowflake,
    role_id: Snowflake,
) !Route {
    return guildMemberRoleRoute(allocator, .DELETE, guild_id, user_id, role_id);
}

fn guildMemberRoleRoute(
    allocator: std.mem.Allocator,
    method: Method,
    guild_id: Snowflake,
    user_id: Snowflake,
    role_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/guilds/{d}/members/{d}/roles/{d}",
        .{ guild_id.value, user_id.value, role_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/members/{user_id}/roles/{role_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn channelMessages(allocator: std.mem.Allocator, channel_id: Snowflake) !Route {
    return channelMessagesWithOptions(allocator, channel_id, .{});
}

pub fn bulkDeleteMessages(allocator: std.mem.Allocator, channel_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/channels/{d}/messages/bulk-delete", .{channel_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/messages/bulk-delete");
    return .{
        .method = .POST,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn triggerTyping(allocator: std.mem.Allocator, channel_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/channels/{d}/typing", .{channel_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/typing");
    return .{
        .method = .POST,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn channelMessagesWithOptions(
    allocator: std.mem.Allocator,
    channel_id: Snowflake,
    options: Types.ListMessages,
) !Route {
    var query = std.Io.Writer.Allocating.init(allocator);
    defer query.deinit();
    if (options.hasQuery()) {
        try query.writer.writeByte('?');
        try options.writeQuery(&query.writer);
    }

    const path = try std.fmt.allocPrint(
        allocator,
        "/channels/{d}/messages{s}",
        .{ channel_id.value, query.written() },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/messages");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn createThread(allocator: std.mem.Allocator, channel_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/channels/{d}/threads", .{channel_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/threads");
    return .{
        .method = .POST,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn activeGuildThreads(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/threads/active", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/threads/active");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn joinThread(allocator: std.mem.Allocator, thread_id: Snowflake) !Route {
    return currentThreadMemberRoute(allocator, .PUT, thread_id);
}

pub fn leaveThread(allocator: std.mem.Allocator, thread_id: Snowflake) !Route {
    return currentThreadMemberRoute(allocator, .DELETE, thread_id);
}

fn currentThreadMemberRoute(allocator: std.mem.Allocator, method: Method, thread_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/channels/{d}/thread-members/@me", .{thread_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/thread-members/@me");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = thread_id,
    };
}

pub fn addThreadMember(allocator: std.mem.Allocator, thread_id: Snowflake, user_id: Snowflake) !Route {
    return threadMemberRoute(allocator, .PUT, thread_id, user_id);
}

pub fn getThreadMember(allocator: std.mem.Allocator, thread_id: Snowflake, user_id: Snowflake) !Route {
    return threadMemberRoute(allocator, .GET, thread_id, user_id);
}

pub fn removeThreadMember(allocator: std.mem.Allocator, thread_id: Snowflake, user_id: Snowflake) !Route {
    return threadMemberRoute(allocator, .DELETE, thread_id, user_id);
}

fn threadMemberRoute(
    allocator: std.mem.Allocator,
    method: Method,
    thread_id: Snowflake,
    user_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/channels/{d}/thread-members/{d}",
        .{ thread_id.value, user_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/thread-members/{user_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = thread_id,
    };
}

pub fn threadMembers(allocator: std.mem.Allocator, thread_id: Snowflake) !Route {
    return threadMembersWithOptions(allocator, thread_id, .{});
}

pub fn threadMembersWithOptions(
    allocator: std.mem.Allocator,
    thread_id: Snowflake,
    options: Types.ListThreadMembers,
) !Route {
    var query = std.Io.Writer.Allocating.init(allocator);
    defer query.deinit();
    if (options.hasQuery()) {
        try query.writer.writeByte('?');
        try options.writeQuery(&query.writer);
    }

    const path = try std.fmt.allocPrint(
        allocator,
        "/channels/{d}/thread-members{s}",
        .{ thread_id.value, query.written() },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/thread-members");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = thread_id,
    };
}

pub fn publicArchivedThreads(
    allocator: std.mem.Allocator,
    channel_id: Snowflake,
    options: Types.ListArchivedThreads,
) !Route {
    return archivedThreadsRoute(
        allocator,
        channel_id,
        options,
        "/channels/{d}/threads/archived/public{s}",
        "/channels/{channel_id}/threads/archived/public",
    );
}

pub fn privateArchivedThreads(
    allocator: std.mem.Allocator,
    channel_id: Snowflake,
    options: Types.ListArchivedThreads,
) !Route {
    return archivedThreadsRoute(
        allocator,
        channel_id,
        options,
        "/channels/{d}/threads/archived/private{s}",
        "/channels/{channel_id}/threads/archived/private",
    );
}

pub fn joinedPrivateArchivedThreads(
    allocator: std.mem.Allocator,
    channel_id: Snowflake,
    options: Types.ListArchivedThreads,
) !Route {
    return archivedThreadsRoute(
        allocator,
        channel_id,
        options,
        "/channels/{d}/users/@me/threads/archived/private{s}",
        "/channels/{channel_id}/users/@me/threads/archived/private",
    );
}

fn archivedThreadsRoute(
    allocator: std.mem.Allocator,
    channel_id: Snowflake,
    options: Types.ListArchivedThreads,
    comptime path_template: []const u8,
    comptime bucket_path_template: []const u8,
) !Route {
    var query = std.Io.Writer.Allocating.init(allocator);
    defer query.deinit();
    if (options.hasQuery()) {
        try query.writer.writeByte('?');
        try options.writeQuery(&query.writer);
    }

    const path = try std.fmt.allocPrint(
        allocator,
        path_template,
        .{ channel_id.value, query.written() },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, bucket_path_template);
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn pinnedMessages(allocator: std.mem.Allocator, channel_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/channels/{d}/pins", .{channel_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/pins");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn channelPins(
    allocator: std.mem.Allocator,
    channel_id: Snowflake,
    options: Types.ListChannelPins,
) !Route {
    var query = std.Io.Writer.Allocating.init(allocator);
    defer query.deinit();
    if (options.hasQuery()) {
        try query.writer.writeByte('?');
        try options.writeQuery(&query.writer);
    }

    const path = try std.fmt.allocPrint(
        allocator,
        "/channels/{d}/messages/pins{s}",
        .{ channel_id.value, query.written() },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/messages/pins");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn pinMessage(allocator: std.mem.Allocator, channel_id: Snowflake, message_id: Snowflake) !Route {
    return pinMessageRoute(allocator, .PUT, channel_id, message_id);
}

pub fn unpinMessage(allocator: std.mem.Allocator, channel_id: Snowflake, message_id: Snowflake) !Route {
    return pinMessageRoute(allocator, .DELETE, channel_id, message_id);
}

fn pinMessageRoute(
    allocator: std.mem.Allocator,
    method: Method,
    channel_id: Snowflake,
    message_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/channels/{d}/messages/pins/{d}",
        .{ channel_id.value, message_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/messages/pins/{message_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn channelInvites(allocator: std.mem.Allocator, channel_id: Snowflake) !Route {
    return channelInvitesRoute(allocator, .GET, channel_id);
}

pub fn createChannelInvite(allocator: std.mem.Allocator, channel_id: Snowflake) !Route {
    return channelInvitesRoute(allocator, .POST, channel_id);
}

fn channelInvitesRoute(allocator: std.mem.Allocator, method: Method, channel_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/channels/{d}/invites", .{channel_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/invites");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn channelWebhooks(allocator: std.mem.Allocator, channel_id: Snowflake) !Route {
    return channelWebhooksRoute(allocator, .GET, channel_id);
}

pub fn createWebhook(allocator: std.mem.Allocator, channel_id: Snowflake) !Route {
    return channelWebhooksRoute(allocator, .POST, channel_id);
}

fn channelWebhooksRoute(allocator: std.mem.Allocator, method: Method, channel_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/channels/{d}/webhooks", .{channel_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/webhooks");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn guildWebhooks(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/webhooks", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/webhooks");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn webhook(allocator: std.mem.Allocator, webhook_id: Snowflake) !Route {
    return webhookRoute(allocator, .GET, webhook_id);
}

pub fn editWebhook(allocator: std.mem.Allocator, webhook_id: Snowflake) !Route {
    return webhookRoute(allocator, .PATCH, webhook_id);
}

pub fn deleteWebhook(allocator: std.mem.Allocator, webhook_id: Snowflake) !Route {
    return webhookRoute(allocator, .DELETE, webhook_id);
}

pub fn webhookWithToken(
    allocator: std.mem.Allocator,
    webhook_id: Snowflake,
    webhook_token: []const u8,
) !Route {
    return webhookTokenRoute(allocator, .GET, webhook_id, webhook_token);
}

pub fn editWebhookWithToken(
    allocator: std.mem.Allocator,
    webhook_id: Snowflake,
    webhook_token: []const u8,
) !Route {
    return webhookTokenRoute(allocator, .PATCH, webhook_id, webhook_token);
}

pub fn deleteWebhookWithToken(
    allocator: std.mem.Allocator,
    webhook_id: Snowflake,
    webhook_token: []const u8,
) !Route {
    return webhookTokenRoute(allocator, .DELETE, webhook_id, webhook_token);
}

pub fn executeWebhook(
    allocator: std.mem.Allocator,
    webhook_id: Snowflake,
    webhook_token: []const u8,
) !Route {
    return webhookTokenRoute(allocator, .POST, webhook_id, webhook_token);
}

pub fn executeWebhookWithOptions(
    allocator: std.mem.Allocator,
    webhook_id: Snowflake,
    webhook_token: []const u8,
    options: Types.ExecuteWebhookQuery,
) !Route {
    const escaped_token = try percentEncode(allocator, webhook_token);
    defer allocator.free(escaped_token);

    var query = std.Io.Writer.Allocating.init(allocator);
    defer query.deinit();
    if (options.hasQuery()) {
        try query.writer.writeByte('?');
        try options.writeQuery(&query.writer);
    }

    const path = try std.fmt.allocPrint(
        allocator,
        "/webhooks/{d}/{s}{s}",
        .{ webhook_id.value, escaped_token, query.written() },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/webhooks/{webhook_id}/{webhook_token}");
    return .{
        .method = .POST,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = webhook_id,
    };
}

pub fn getWebhookMessage(
    allocator: std.mem.Allocator,
    webhook_id: Snowflake,
    webhook_token: []const u8,
    message_id: Snowflake,
) !Route {
    return webhookMessageRoute(allocator, .GET, webhook_id, webhook_token, message_id);
}

pub fn editWebhookMessage(
    allocator: std.mem.Allocator,
    webhook_id: Snowflake,
    webhook_token: []const u8,
    message_id: Snowflake,
) !Route {
    return webhookMessageRoute(allocator, .PATCH, webhook_id, webhook_token, message_id);
}

pub fn deleteWebhookMessage(
    allocator: std.mem.Allocator,
    webhook_id: Snowflake,
    webhook_token: []const u8,
    message_id: Snowflake,
) !Route {
    return webhookMessageRoute(allocator, .DELETE, webhook_id, webhook_token, message_id);
}

fn webhookTokenRoute(
    allocator: std.mem.Allocator,
    method: Method,
    webhook_id: Snowflake,
    webhook_token: []const u8,
) !Route {
    const escaped_token = try percentEncode(allocator, webhook_token);
    defer allocator.free(escaped_token);
    const path = try std.fmt.allocPrint(
        allocator,
        "/webhooks/{d}/{s}",
        .{ webhook_id.value, escaped_token },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/webhooks/{webhook_id}/{webhook_token}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = webhook_id,
    };
}

fn webhookMessageRoute(
    allocator: std.mem.Allocator,
    method: Method,
    webhook_id: Snowflake,
    webhook_token: []const u8,
    message_id: Snowflake,
) !Route {
    const escaped_token = try percentEncode(allocator, webhook_token);
    defer allocator.free(escaped_token);

    const path = try std.fmt.allocPrint(
        allocator,
        "/webhooks/{d}/{s}/messages/{d}",
        .{ webhook_id.value, escaped_token, message_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/webhooks/{webhook_id}/{webhook_token}/messages/{message_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = webhook_id,
    };
}

fn webhookRoute(allocator: std.mem.Allocator, method: Method, webhook_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/webhooks/{d}", .{webhook_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/webhooks/{webhook_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = webhook_id,
    };
}

pub fn guildInvites(allocator: std.mem.Allocator, guild_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/guilds/{d}/invites", .{guild_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/guilds/{guild_id}/invites");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn invite(allocator: std.mem.Allocator, code: []const u8) !Route {
    return inviteRoute(allocator, .GET, code);
}

pub fn inviteWithOptions(allocator: std.mem.Allocator, code: []const u8, options: Types.GetInvite) !Route {
    return inviteRouteWithQuery(allocator, .GET, code, options);
}

pub fn deleteInvite(allocator: std.mem.Allocator, code: []const u8) !Route {
    return inviteRoute(allocator, .DELETE, code);
}

pub fn inviteTargetUsers(allocator: std.mem.Allocator, code: []const u8) !Route {
    return inviteChildRoute(allocator, .GET, code, "target-users");
}

pub fn updateInviteTargetUsers(allocator: std.mem.Allocator, code: []const u8) !Route {
    return inviteChildRoute(allocator, .PUT, code, "target-users");
}

pub fn inviteTargetUsersJobStatus(allocator: std.mem.Allocator, code: []const u8) !Route {
    return inviteChildRoute(allocator, .GET, code, "target-users/job-status");
}

fn inviteRoute(allocator: std.mem.Allocator, method: Method, code: []const u8) !Route {
    return inviteRouteWithQuery(allocator, method, code, null);
}

fn inviteRouteWithQuery(
    allocator: std.mem.Allocator,
    method: Method,
    code: []const u8,
    maybe_options: ?Types.GetInvite,
) !Route {
    var query = std.Io.Writer.Allocating.init(allocator);
    defer query.deinit();
    if (maybe_options) |options| {
        if (options.hasQuery()) {
            try query.writer.writeByte('?');
            try options.writeQuery(&query.writer);
        }
    }

    const escaped = try percentEncode(allocator, code);
    defer allocator.free(escaped);
    const path = try std.fmt.allocPrint(allocator, "/invites/{s}{s}", .{ escaped, query.written() });
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/invites/{code}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
    };
}

fn inviteChildRoute(
    allocator: std.mem.Allocator,
    method: Method,
    code: []const u8,
    comptime child: []const u8,
) !Route {
    const escaped = try percentEncode(allocator, code);
    defer allocator.free(escaped);
    const path = try std.fmt.allocPrint(allocator, "/invites/{s}/{s}", .{ escaped, child });
    errdefer allocator.free(path);
    const bucket_path = try std.fmt.allocPrint(allocator, "/invites/{{code}}/{s}", .{child});
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
    };
}

pub fn channelMessage(allocator: std.mem.Allocator, channel_id: Snowflake, message_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/channels/{d}/messages/{d}",
        .{ channel_id.value, message_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/messages/{message_id}");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn createThreadFromMessage(allocator: std.mem.Allocator, channel_id: Snowflake, message_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/channels/{d}/messages/{d}/threads",
        .{ channel_id.value, message_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/messages/{message_id}/threads");
    return .{
        .method = .POST,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn createMessage(allocator: std.mem.Allocator, channel_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(allocator, "/channels/{d}/messages", .{channel_id.value});
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/messages");
    return .{
        .method = .POST,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn deleteMessage(allocator: std.mem.Allocator, channel_id: Snowflake, message_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/channels/{d}/messages/{d}",
        .{ channel_id.value, message_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/messages/{message_id}");
    return .{
        .method = .DELETE,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn editMessage(allocator: std.mem.Allocator, channel_id: Snowflake, message_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/channels/{d}/messages/{d}",
        .{ channel_id.value, message_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/messages/{message_id}");
    return .{
        .method = .PATCH,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn crosspostMessage(allocator: std.mem.Allocator, channel_id: Snowflake, message_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/channels/{d}/messages/{d}/crosspost",
        .{ channel_id.value, message_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/messages/{message_id}/crosspost");
    return .{
        .method = .POST,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn createReaction(
    allocator: std.mem.Allocator,
    channel_id: Snowflake,
    message_id: Snowflake,
    emoji: []const u8,
) !Route {
    return ownReactionRoute(allocator, .PUT, channel_id, message_id, emoji);
}

pub fn deleteOwnReaction(
    allocator: std.mem.Allocator,
    channel_id: Snowflake,
    message_id: Snowflake,
    emoji: []const u8,
) !Route {
    return ownReactionRoute(allocator, .DELETE, channel_id, message_id, emoji);
}

pub fn deleteUserReaction(
    allocator: std.mem.Allocator,
    channel_id: Snowflake,
    message_id: Snowflake,
    emoji: []const u8,
    user_id: Snowflake,
) !Route {
    const escaped = try percentEncode(allocator, emoji);
    defer allocator.free(escaped);
    const path = try std.fmt.allocPrint(
        allocator,
        "/channels/{d}/messages/{d}/reactions/{s}/{d}",
        .{ channel_id.value, message_id.value, escaped, user_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/messages/{message_id}/reactions/{emoji}/{user_id}");
    return .{
        .method = .DELETE,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn listReactions(
    allocator: std.mem.Allocator,
    channel_id: Snowflake,
    message_id: Snowflake,
    emoji: []const u8,
    options: Types.ListReactions,
) !Route {
    const escaped = try percentEncode(allocator, emoji);
    defer allocator.free(escaped);

    var query = std.Io.Writer.Allocating.init(allocator);
    defer query.deinit();
    if (options.hasQuery()) {
        try query.writer.writeByte('?');
        try options.writeQuery(&query.writer);
    }

    const path = try std.fmt.allocPrint(
        allocator,
        "/channels/{d}/messages/{d}/reactions/{s}{s}",
        .{ channel_id.value, message_id.value, escaped, query.written() },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/messages/{message_id}/reactions/{emoji}");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn deleteAllReactions(
    allocator: std.mem.Allocator,
    channel_id: Snowflake,
    message_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/channels/{d}/messages/{d}/reactions",
        .{ channel_id.value, message_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/messages/{message_id}/reactions");
    return .{
        .method = .DELETE,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn deleteAllReactionsForEmoji(
    allocator: std.mem.Allocator,
    channel_id: Snowflake,
    message_id: Snowflake,
    emoji: []const u8,
) !Route {
    const escaped = try percentEncode(allocator, emoji);
    defer allocator.free(escaped);
    const path = try std.fmt.allocPrint(
        allocator,
        "/channels/{d}/messages/{d}/reactions/{s}",
        .{ channel_id.value, message_id.value, escaped },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/messages/{message_id}/reactions/{emoji}");
    return .{
        .method = .DELETE,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn pollAnswerVoters(
    allocator: std.mem.Allocator,
    channel_id: Snowflake,
    message_id: Snowflake,
    answer_id: u32,
    options: Types.ListPollAnswerVoters,
) !Route {
    var query = std.Io.Writer.Allocating.init(allocator);
    defer query.deinit();
    if (options.hasQuery()) {
        try query.writer.writeByte('?');
        try options.writeQuery(&query.writer);
    }

    const path = try std.fmt.allocPrint(
        allocator,
        "/channels/{d}/polls/{d}/answers/{d}{s}",
        .{ channel_id.value, message_id.value, answer_id, query.written() },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/polls/{message_id}/answers/{answer_id}");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn endPoll(
    allocator: std.mem.Allocator,
    channel_id: Snowflake,
    message_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/channels/{d}/polls/{d}/expire",
        .{ channel_id.value, message_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/polls/{message_id}/expire");
    return .{
        .method = .POST,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

fn ownReactionRoute(
    allocator: std.mem.Allocator,
    method: Method,
    channel_id: Snowflake,
    message_id: Snowflake,
    emoji: []const u8,
) !Route {
    const escaped = try percentEncode(allocator, emoji);
    defer allocator.free(escaped);
    const path = try std.fmt.allocPrint(
        allocator,
        "/channels/{d}/messages/{d}/reactions/{s}/@me",
        .{ channel_id.value, message_id.value, escaped },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/channels/{channel_id}/messages/{message_id}/reactions/{emoji}/@me");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = channel_id,
    };
}

pub fn globalApplicationCommands(allocator: std.mem.Allocator, application_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/applications/{d}/commands",
        .{application_id.value},
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/applications/{application_id}/commands");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = application_id,
    };
}

pub fn createGlobalApplicationCommand(allocator: std.mem.Allocator, application_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/applications/{d}/commands",
        .{application_id.value},
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/applications/{application_id}/commands");
    return .{
        .method = .POST,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = application_id,
    };
}

pub fn bulkOverwriteGlobalApplicationCommands(allocator: std.mem.Allocator, application_id: Snowflake) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/applications/{d}/commands",
        .{application_id.value},
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/applications/{application_id}/commands");
    return .{
        .method = .PUT,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = application_id,
    };
}

pub fn globalApplicationCommand(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    command_id: Snowflake,
) !Route {
    return globalApplicationCommandRoute(allocator, .GET, application_id, command_id);
}

pub fn editGlobalApplicationCommand(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    command_id: Snowflake,
) !Route {
    return globalApplicationCommandRoute(allocator, .PATCH, application_id, command_id);
}

pub fn deleteGlobalApplicationCommand(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    command_id: Snowflake,
) !Route {
    return globalApplicationCommandRoute(allocator, .DELETE, application_id, command_id);
}

fn globalApplicationCommandRoute(
    allocator: std.mem.Allocator,
    method: Method,
    application_id: Snowflake,
    command_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/applications/{d}/commands/{d}",
        .{ application_id.value, command_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/applications/{application_id}/commands/{command_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = application_id,
    };
}

pub fn guildApplicationCommands(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    guild_id: Snowflake,
) !Route {
    return guildApplicationCommandsRoute(allocator, .GET, application_id, guild_id);
}

pub fn createGuildApplicationCommand(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    guild_id: Snowflake,
) !Route {
    return guildApplicationCommandsRoute(allocator, .POST, application_id, guild_id);
}

pub fn bulkOverwriteGuildApplicationCommands(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    guild_id: Snowflake,
) !Route {
    return guildApplicationCommandsRoute(allocator, .PUT, application_id, guild_id);
}

fn guildApplicationCommandsRoute(
    allocator: std.mem.Allocator,
    method: Method,
    application_id: Snowflake,
    guild_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/applications/{d}/guilds/{d}/commands",
        .{ application_id.value, guild_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/applications/{application_id}/guilds/{guild_id}/commands");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn guildApplicationCommand(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    guild_id: Snowflake,
    command_id: Snowflake,
) !Route {
    return guildApplicationCommandRoute(allocator, .GET, application_id, guild_id, command_id);
}

pub fn editGuildApplicationCommand(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    guild_id: Snowflake,
    command_id: Snowflake,
) !Route {
    return guildApplicationCommandRoute(allocator, .PATCH, application_id, guild_id, command_id);
}

pub fn deleteGuildApplicationCommand(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    guild_id: Snowflake,
    command_id: Snowflake,
) !Route {
    return guildApplicationCommandRoute(allocator, .DELETE, application_id, guild_id, command_id);
}

pub fn guildApplicationCommandPermissions(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    guild_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/applications/{d}/guilds/{d}/commands/permissions",
        .{ application_id.value, guild_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/applications/{application_id}/guilds/{guild_id}/commands/permissions");
    return .{
        .method = .GET,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn applicationCommandPermissions(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    guild_id: Snowflake,
    command_id: Snowflake,
) !Route {
    return applicationCommandPermissionsRoute(allocator, .GET, application_id, guild_id, command_id);
}

pub fn editApplicationCommandPermissions(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    guild_id: Snowflake,
    command_id: Snowflake,
) !Route {
    return applicationCommandPermissionsRoute(allocator, .PUT, application_id, guild_id, command_id);
}

fn applicationCommandPermissionsRoute(
    allocator: std.mem.Allocator,
    method: Method,
    application_id: Snowflake,
    guild_id: Snowflake,
    command_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/applications/{d}/guilds/{d}/commands/{d}/permissions",
        .{ application_id.value, guild_id.value, command_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/applications/{application_id}/guilds/{guild_id}/commands/{command_id}/permissions");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

fn guildApplicationCommandRoute(
    allocator: std.mem.Allocator,
    method: Method,
    application_id: Snowflake,
    guild_id: Snowflake,
    command_id: Snowflake,
) !Route {
    const path = try std.fmt.allocPrint(
        allocator,
        "/applications/{d}/guilds/{d}/commands/{d}",
        .{ application_id.value, guild_id.value, command_id.value },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/applications/{application_id}/guilds/{guild_id}/commands/{command_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = guild_id,
    };
}

pub fn interactionCallback(
    allocator: std.mem.Allocator,
    interaction_id: Snowflake,
    token: []const u8,
) !Route {
    const escaped_token = try percentEncode(allocator, token);
    defer allocator.free(escaped_token);

    const path = try std.fmt.allocPrint(
        allocator,
        "/interactions/{d}/{s}/callback",
        .{ interaction_id.value, escaped_token },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/interactions/{interaction_id}/{interaction_token}/callback");
    return .{
        .method = .POST,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = interaction_id,
    };
}

pub fn getOriginalInteractionResponse(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    token: []const u8,
) !Route {
    return interactionWebhookMessageRoute(allocator, .GET, application_id, token, "@original");
}

pub fn editOriginalInteractionResponse(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    token: []const u8,
) !Route {
    return interactionWebhookMessageRoute(allocator, .PATCH, application_id, token, "@original");
}

pub fn deleteOriginalInteractionResponse(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    token: []const u8,
) !Route {
    return interactionWebhookMessageRoute(allocator, .DELETE, application_id, token, "@original");
}

pub fn createFollowupMessage(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    token: []const u8,
) !Route {
    return interactionWebhookRoute(allocator, .POST, application_id, token);
}

pub fn getFollowupMessage(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    token: []const u8,
    message_id: Snowflake,
) !Route {
    var buffer: [32]u8 = .{0} ** 32;
    const message = try std.fmt.bufPrint(&buffer, "{d}", .{message_id.value});
    return interactionWebhookMessageRoute(allocator, .GET, application_id, token, message);
}

pub fn editFollowupMessage(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    token: []const u8,
    message_id: Snowflake,
) !Route {
    var buffer: [32]u8 = .{0} ** 32;
    const message = try std.fmt.bufPrint(&buffer, "{d}", .{message_id.value});
    return interactionWebhookMessageRoute(allocator, .PATCH, application_id, token, message);
}

pub fn deleteFollowupMessage(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    token: []const u8,
    message_id: Snowflake,
) !Route {
    var buffer: [32]u8 = .{0} ** 32;
    const message = try std.fmt.bufPrint(&buffer, "{d}", .{message_id.value});
    return interactionWebhookMessageRoute(allocator, .DELETE, application_id, token, message);
}

fn interactionWebhookRoute(
    allocator: std.mem.Allocator,
    method: Method,
    application_id: Snowflake,
    token: []const u8,
) !Route {
    const escaped_token = try percentEncode(allocator, token);
    defer allocator.free(escaped_token);

    const path = try std.fmt.allocPrint(
        allocator,
        "/webhooks/{d}/{s}",
        .{ application_id.value, escaped_token },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/webhooks/{application_id}/{interaction_token}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = application_id,
    };
}

fn interactionWebhookMessageRoute(
    allocator: std.mem.Allocator,
    method: Method,
    application_id: Snowflake,
    token: []const u8,
    message: []const u8,
) !Route {
    const escaped_token = try percentEncode(allocator, token);
    defer allocator.free(escaped_token);

    const path = try std.fmt.allocPrint(
        allocator,
        "/webhooks/{d}/{s}/messages/{s}",
        .{ application_id.value, escaped_token, message },
    );
    errdefer allocator.free(path);
    const bucket_path = try allocator.dupe(u8, "/webhooks/{application_id}/{interaction_token}/messages/{message_id}");
    return .{
        .method = method,
        .path = path,
        .bucket_path = bucket_path,
        .major_parameter = application_id,
    };
}

pub fn bucketKey(allocator: std.mem.Allocator, route: Route) ![]u8 {
    if (route.major_parameter) |major| {
        return std.fmt.allocPrint(allocator, "{s}:{s}:{d}", .{
            @tagName(route.method),
            route.bucket_path,
            major.value,
        });
    }

    return std.fmt.allocPrint(allocator, "{s}:{s}", .{
        @tagName(route.method),
        route.bucket_path,
    });
}

fn percentEncode(allocator: std.mem.Allocator, value: []const u8) ![]u8 {
    var out = std.Io.Writer.Allocating.init(allocator);
    defer out.deinit();
    const hex = "0123456789ABCDEF";
    for (value) |byte| {
        const safe = (byte >= 'A' and byte <= 'Z') or
            (byte >= 'a' and byte <= 'z') or
            (byte >= '0' and byte <= '9') or
            byte == '-' or byte == '_' or byte == '.' or byte == '~';
        if (safe) {
            try out.writer.writeByte(byte);
        } else {
            try out.writer.writeByte('%');
            try out.writer.writeByte(hex[byte >> 4]);
            try out.writer.writeByte(hex[byte & 0x0f]);
        }
    }
    return try out.toOwnedSlice();
}

test "route builder creates channel message path" {
    const id = Snowflake.init(42);
    const route = try createMessage(std.testing.allocator, id);
    defer route.deinit(std.testing.allocator);
    try std.testing.expectEqualStrings("/channels/42/messages", route.path);
    try std.testing.expectEqual(.POST, route.method);
}

test "bucket key uses normalized route and major parameter" {
    const id = Snowflake.init(42);
    const route = try createMessage(std.testing.allocator, id);
    defer route.deinit(std.testing.allocator);

    const key = try bucketKey(std.testing.allocator, route);
    defer std.testing.allocator.free(key);
    try std.testing.expectEqualStrings("POST:/channels/{channel_id}/messages:42", key);
}

test "gateway routes use expected endpoints" {
    const public_route = try gateway(std.testing.allocator);
    defer public_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, public_route.method);
    try std.testing.expectEqualStrings("/gateway", public_route.path);

    const public_key = try bucketKey(std.testing.allocator, public_route);
    defer std.testing.allocator.free(public_key);
    try std.testing.expectEqualStrings("GET:/gateway", public_key);

    const route = try gatewayBot(std.testing.allocator);
    defer route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, route.method);
    try std.testing.expectEqualStrings("/gateway/bot", route.path);

    const key = try bucketKey(std.testing.allocator, route);
    defer std.testing.allocator.free(key);
    try std.testing.expectEqualStrings("GET:/gateway/bot", key);
}

test "message route bucket keeps channel as major parameter" {
    const route = try channelMessage(std.testing.allocator, Snowflake.init(42), Snowflake.init(99));
    defer route.deinit(std.testing.allocator);

    const key = try bucketKey(std.testing.allocator, route);
    defer std.testing.allocator.free(key);

    try std.testing.expectEqualStrings("GET:/channels/{channel_id}/messages/{message_id}:42", key);
}

test "list message route supports query options without changing bucket" {
    const route = try channelMessagesWithOptions(std.testing.allocator, Snowflake.init(42), .{
        .before = Snowflake.init(99),
        .limit = 25,
    });
    defer route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, route.method);
    try std.testing.expectEqualStrings("/channels/42/messages?before=99&limit=25", route.path);

    const key = try bucketKey(std.testing.allocator, route);
    defer std.testing.allocator.free(key);
    try std.testing.expectEqualStrings("GET:/channels/{channel_id}/messages:42", key);
}

test "bulk delete route keeps channel as major parameter" {
    const route = try bulkDeleteMessages(std.testing.allocator, Snowflake.init(42));
    defer route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, route.method);
    try std.testing.expectEqualStrings("/channels/42/messages/bulk-delete", route.path);

    const key = try bucketKey(std.testing.allocator, route);
    defer std.testing.allocator.free(key);
    try std.testing.expectEqualStrings("POST:/channels/{channel_id}/messages/bulk-delete:42", key);
}

test "typing route keeps channel as major parameter" {
    const route = try triggerTyping(std.testing.allocator, Snowflake.init(42));
    defer route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, route.method);
    try std.testing.expectEqualStrings("/channels/42/typing", route.path);

    const key = try bucketKey(std.testing.allocator, route);
    defer std.testing.allocator.free(key);
    try std.testing.expectEqualStrings("POST:/channels/{channel_id}/typing:42", key);
}

test "pin routes keep channel as major parameter" {
    const list_route = try pinnedMessages(std.testing.allocator, Snowflake.init(42));
    defer list_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, list_route.method);
    try std.testing.expectEqualStrings("/channels/42/pins", list_route.path);

    const list_key = try bucketKey(std.testing.allocator, list_route);
    defer std.testing.allocator.free(list_key);
    try std.testing.expectEqualStrings("GET:/channels/{channel_id}/pins:42", list_key);

    const pins_route = try channelPins(std.testing.allocator, Snowflake.init(42), .{
        .before = "2026-06-02T10:00:00.000Z",
        .limit = 25,
    });
    defer pins_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, pins_route.method);
    try std.testing.expectEqualStrings(
        "/channels/42/messages/pins?before=2026-06-02T10%3A00%3A00.000Z&limit=25",
        pins_route.path,
    );

    const pins_key = try bucketKey(std.testing.allocator, pins_route);
    defer std.testing.allocator.free(pins_key);
    try std.testing.expectEqualStrings("GET:/channels/{channel_id}/messages/pins:42", pins_key);

    const pin_route = try pinMessage(std.testing.allocator, Snowflake.init(42), Snowflake.init(99));
    defer pin_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, pin_route.method);
    try std.testing.expectEqualStrings("/channels/42/messages/pins/99", pin_route.path);

    const pin_key = try bucketKey(std.testing.allocator, pin_route);
    defer std.testing.allocator.free(pin_key);
    try std.testing.expectEqualStrings("PUT:/channels/{channel_id}/messages/pins/{message_id}:42", pin_key);
}

test "thread routes keep channel as major parameter" {
    const standalone = try createThread(std.testing.allocator, Snowflake.init(42));
    defer standalone.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, standalone.method);
    try std.testing.expectEqualStrings("/channels/42/threads", standalone.path);

    const standalone_key = try bucketKey(std.testing.allocator, standalone);
    defer std.testing.allocator.free(standalone_key);
    try std.testing.expectEqualStrings("POST:/channels/{channel_id}/threads:42", standalone_key);

    const from_message = try createThreadFromMessage(
        std.testing.allocator,
        Snowflake.init(42),
        Snowflake.init(99),
    );
    defer from_message.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, from_message.method);
    try std.testing.expectEqualStrings("/channels/42/messages/99/threads", from_message.path);

    const message_key = try bucketKey(std.testing.allocator, from_message);
    defer std.testing.allocator.free(message_key);
    try std.testing.expectEqualStrings(
        "POST:/channels/{channel_id}/messages/{message_id}/threads:42",
        message_key,
    );
}

test "guild lifecycle and group DM recipient routes use expected paths" {
    const create_guild = try createGuild(std.testing.allocator);
    defer create_guild.deinit(std.testing.allocator);
    try std.testing.expectEqual(.POST, create_guild.method);
    try std.testing.expectEqualStrings("/guilds", create_guild.path);

    const delete_guild = try deleteGuild(std.testing.allocator, Snowflake.init(99));
    defer delete_guild.deinit(std.testing.allocator);
    try std.testing.expectEqual(.DELETE, delete_guild.method);
    try std.testing.expectEqualStrings("/guilds/99", delete_guild.path);

    const from_template = try createGuildFromTemplate(std.testing.allocator, "starter pack");
    defer from_template.deinit(std.testing.allocator);
    try std.testing.expectEqual(.POST, from_template.method);
    try std.testing.expectEqualStrings("/guilds/templates/starter%20pack", from_template.path);

    const add_recipient = try addGroupDmRecipient(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer add_recipient.deinit(std.testing.allocator);
    try std.testing.expectEqual(.PUT, add_recipient.method);
    try std.testing.expectEqualStrings("/channels/10/recipients/20", add_recipient.path);

    const remove_recipient = try removeGroupDmRecipient(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer remove_recipient.deinit(std.testing.allocator);
    try std.testing.expectEqual(.DELETE, remove_recipient.method);
    try std.testing.expectEqualStrings("/channels/10/recipients/20", remove_recipient.path);
}

test "thread member routes keep thread as major parameter" {
    const join_route = try joinThread(std.testing.allocator, Snowflake.init(42));
    defer join_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, join_route.method);
    try std.testing.expectEqualStrings("/channels/42/thread-members/@me", join_route.path);

    const join_key = try bucketKey(std.testing.allocator, join_route);
    defer std.testing.allocator.free(join_key);
    try std.testing.expectEqualStrings("PUT:/channels/{channel_id}/thread-members/@me:42", join_key);

    const leave_route = try leaveThread(std.testing.allocator, Snowflake.init(42));
    defer leave_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.DELETE, leave_route.method);
    try std.testing.expectEqualStrings("/channels/42/thread-members/@me", leave_route.path);

    const add_route = try addThreadMember(std.testing.allocator, Snowflake.init(42), Snowflake.init(99));
    defer add_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, add_route.method);
    try std.testing.expectEqualStrings("/channels/42/thread-members/99", add_route.path);

    const add_key = try bucketKey(std.testing.allocator, add_route);
    defer std.testing.allocator.free(add_key);
    try std.testing.expectEqualStrings("PUT:/channels/{channel_id}/thread-members/{user_id}:42", add_key);

    const get_route = try getThreadMember(std.testing.allocator, Snowflake.init(42), Snowflake.init(99));
    defer get_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, get_route.method);
    try std.testing.expectEqualStrings("/channels/42/thread-members/99", get_route.path);

    const remove_route = try removeThreadMember(std.testing.allocator, Snowflake.init(42), Snowflake.init(99));
    defer remove_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.DELETE, remove_route.method);
    try std.testing.expectEqualStrings("/channels/42/thread-members/99", remove_route.path);

    const members_route = try threadMembers(std.testing.allocator, Snowflake.init(42));
    defer members_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, members_route.method);
    try std.testing.expectEqualStrings("/channels/42/thread-members", members_route.path);

    const optioned_members_route = try threadMembersWithOptions(std.testing.allocator, Snowflake.init(42), .{
        .with_member = true,
        .after = Snowflake.init(99),
        .limit = 100,
    });
    defer optioned_members_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, optioned_members_route.method);
    try std.testing.expectEqualStrings(
        "/channels/42/thread-members?with_member=true&after=99&limit=100",
        optioned_members_route.path,
    );

    const optioned_members_key = try bucketKey(std.testing.allocator, optioned_members_route);
    defer std.testing.allocator.free(optioned_members_key);
    try std.testing.expectEqualStrings("GET:/channels/{channel_id}/thread-members:42", optioned_members_key);
}

test "interaction webhook routes use expected paths and buckets" {
    const callback_route = try interactionCallback(std.testing.allocator, Snowflake.init(42), "tok en");
    defer callback_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, callback_route.method);
    try std.testing.expectEqualStrings("/interactions/42/tok%20en/callback", callback_route.path);

    const callback_key = try bucketKey(std.testing.allocator, callback_route);
    defer std.testing.allocator.free(callback_key);
    try std.testing.expectEqualStrings(
        "POST:/interactions/{interaction_id}/{interaction_token}/callback:42",
        callback_key,
    );

    const original_route = try editOriginalInteractionResponse(std.testing.allocator, Snowflake.init(77), "tok en");
    defer original_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, original_route.method);
    try std.testing.expectEqualStrings("/webhooks/77/tok%20en/messages/@original", original_route.path);

    const original_key = try bucketKey(std.testing.allocator, original_route);
    defer std.testing.allocator.free(original_key);
    try std.testing.expectEqualStrings(
        "PATCH:/webhooks/{application_id}/{interaction_token}/messages/{message_id}:77",
        original_key,
    );

    const followup_route = try createFollowupMessage(std.testing.allocator, Snowflake.init(77), "tok en");
    defer followup_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, followup_route.method);
    try std.testing.expectEqualStrings("/webhooks/77/tok%20en", followup_route.path);

    const followup_message_route = try deleteFollowupMessage(
        std.testing.allocator,
        Snowflake.init(77),
        "tok en",
        Snowflake.init(99),
    );
    defer followup_message_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.DELETE, followup_message_route.method);
    try std.testing.expectEqualStrings("/webhooks/77/tok%20en/messages/99", followup_message_route.path);
}

test "archived and active thread routes support query and buckets" {
    const active_route = try activeGuildThreads(std.testing.allocator, Snowflake.init(99));
    defer active_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, active_route.method);
    try std.testing.expectEqualStrings("/guilds/99/threads/active", active_route.path);

    const active_key = try bucketKey(std.testing.allocator, active_route);
    defer std.testing.allocator.free(active_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/threads/active:99", active_key);

    const public_route = try publicArchivedThreads(std.testing.allocator, Snowflake.init(42), .{
        .before = "2026-06-02T10:00:00.000Z",
        .limit = 25,
    });
    defer public_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, public_route.method);
    try std.testing.expectEqualStrings(
        "/channels/42/threads/archived/public?before=2026-06-02T10%3A00%3A00.000Z&limit=25",
        public_route.path,
    );

    const public_key = try bucketKey(std.testing.allocator, public_route);
    defer std.testing.allocator.free(public_key);
    try std.testing.expectEqualStrings(
        "GET:/channels/{channel_id}/threads/archived/public:42",
        public_key,
    );

    const private_route = try privateArchivedThreads(std.testing.allocator, Snowflake.init(42), .{
        .before = "2026-06-02T10:00:00.000Z",
        .limit = 25,
    });
    defer private_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, private_route.method);
    try std.testing.expectEqualStrings(
        "/channels/42/threads/archived/private?before=2026-06-02T10%3A00%3A00.000Z&limit=25",
        private_route.path,
    );

    const private_key = try bucketKey(std.testing.allocator, private_route);
    defer std.testing.allocator.free(private_key);
    try std.testing.expectEqualStrings(
        "GET:/channels/{channel_id}/threads/archived/private:42",
        private_key,
    );

    const joined_route = try joinedPrivateArchivedThreads(std.testing.allocator, Snowflake.init(42), .{
        .before = "2026-06-02T10:00:00.000Z",
        .limit = 25,
    });
    defer joined_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, joined_route.method);
    try std.testing.expectEqualStrings(
        "/channels/42/users/@me/threads/archived/private?before=2026-06-02T10%3A00%3A00.000Z&limit=25",
        joined_route.path,
    );

    const joined_key = try bucketKey(std.testing.allocator, joined_route);
    defer std.testing.allocator.free(joined_key);
    try std.testing.expectEqualStrings(
        "GET:/channels/{channel_id}/users/@me/threads/archived/private:42",
        joined_key,
    );
}

test "invite routes use expected paths and buckets" {
    const channel_route = try createChannelInvite(std.testing.allocator, Snowflake.init(42));
    defer channel_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, channel_route.method);
    try std.testing.expectEqualStrings("/channels/42/invites", channel_route.path);

    const channel_key = try bucketKey(std.testing.allocator, channel_route);
    defer std.testing.allocator.free(channel_key);
    try std.testing.expectEqualStrings("POST:/channels/{channel_id}/invites:42", channel_key);

    const guild_route = try guildInvites(std.testing.allocator, Snowflake.init(99));
    defer guild_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, guild_route.method);
    try std.testing.expectEqualStrings("/guilds/99/invites", guild_route.path);

    const fetch_route = try inviteWithOptions(std.testing.allocator, "abc 123", .{
        .with_counts = true,
        .guild_scheduled_event_id = Snowflake.init(77),
    });
    defer fetch_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, fetch_route.method);
    try std.testing.expectEqualStrings(
        "/invites/abc%20123?with_counts=true&guild_scheduled_event_id=77",
        fetch_route.path,
    );

    const fetch_key = try bucketKey(std.testing.allocator, fetch_route);
    defer std.testing.allocator.free(fetch_key);
    try std.testing.expectEqualStrings("GET:/invites/{code}", fetch_key);

    const target_users_route = try inviteTargetUsers(std.testing.allocator, "abc 123");
    defer target_users_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, target_users_route.method);
    try std.testing.expectEqualStrings("/invites/abc%20123/target-users", target_users_route.path);

    const target_users_key = try bucketKey(std.testing.allocator, target_users_route);
    defer std.testing.allocator.free(target_users_key);
    try std.testing.expectEqualStrings("GET:/invites/{code}/target-users", target_users_key);

    const update_target_users_route = try updateInviteTargetUsers(std.testing.allocator, "abc 123");
    defer update_target_users_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, update_target_users_route.method);
    try std.testing.expectEqualStrings("/invites/abc%20123/target-users", update_target_users_route.path);

    const update_target_users_key = try bucketKey(std.testing.allocator, update_target_users_route);
    defer std.testing.allocator.free(update_target_users_key);
    try std.testing.expectEqualStrings("PUT:/invites/{code}/target-users", update_target_users_key);

    const job_status_route = try inviteTargetUsersJobStatus(std.testing.allocator, "abc 123");
    defer job_status_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, job_status_route.method);
    try std.testing.expectEqualStrings("/invites/abc%20123/target-users/job-status", job_status_route.path);

    const job_status_key = try bucketKey(std.testing.allocator, job_status_route);
    defer std.testing.allocator.free(job_status_key);
    try std.testing.expectEqualStrings("GET:/invites/{code}/target-users/job-status", job_status_key);

    const invite_route = try deleteInvite(std.testing.allocator, "abc 123");
    defer invite_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.DELETE, invite_route.method);
    try std.testing.expectEqualStrings("/invites/abc%20123", invite_route.path);

    const invite_key = try bucketKey(std.testing.allocator, invite_route);
    defer std.testing.allocator.free(invite_key);
    try std.testing.expectEqualStrings("DELETE:/invites/{code}", invite_key);
}

test "webhook routes use expected paths and buckets" {
    const channel_route = try createWebhook(std.testing.allocator, Snowflake.init(42));
    defer channel_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, channel_route.method);
    try std.testing.expectEqualStrings("/channels/42/webhooks", channel_route.path);

    const channel_key = try bucketKey(std.testing.allocator, channel_route);
    defer std.testing.allocator.free(channel_key);
    try std.testing.expectEqualStrings("POST:/channels/{channel_id}/webhooks:42", channel_key);

    const guild_route = try guildWebhooks(std.testing.allocator, Snowflake.init(99));
    defer guild_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, guild_route.method);
    try std.testing.expectEqualStrings("/guilds/99/webhooks", guild_route.path);

    const webhook_route = try editWebhook(std.testing.allocator, Snowflake.init(77));
    defer webhook_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, webhook_route.method);
    try std.testing.expectEqualStrings("/webhooks/77", webhook_route.path);

    const webhook_key = try bucketKey(std.testing.allocator, webhook_route);
    defer std.testing.allocator.free(webhook_key);
    try std.testing.expectEqualStrings("PATCH:/webhooks/{webhook_id}:77", webhook_key);

    const token_route = try editWebhookWithToken(std.testing.allocator, Snowflake.init(77), "tok en");
    defer token_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, token_route.method);
    try std.testing.expectEqualStrings("/webhooks/77/tok%20en", token_route.path);

    const token_key = try bucketKey(std.testing.allocator, token_route);
    defer std.testing.allocator.free(token_key);
    try std.testing.expectEqualStrings("PATCH:/webhooks/{webhook_id}/{webhook_token}:77", token_key);

    const execute_route = try executeWebhook(std.testing.allocator, Snowflake.init(77), "tok en");
    defer execute_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, execute_route.method);
    try std.testing.expectEqualStrings("/webhooks/77/tok%20en", execute_route.path);

    const execute_key = try bucketKey(std.testing.allocator, execute_route);
    defer std.testing.allocator.free(execute_key);
    try std.testing.expectEqualStrings("POST:/webhooks/{webhook_id}/{webhook_token}:77", execute_key);

    const message_route = try editWebhookMessage(std.testing.allocator, Snowflake.init(77), "tok en", Snowflake.init(99));
    defer message_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, message_route.method);
    try std.testing.expectEqualStrings("/webhooks/77/tok%20en/messages/99", message_route.path);

    const message_key = try bucketKey(std.testing.allocator, message_route);
    defer std.testing.allocator.free(message_key);
    try std.testing.expectEqualStrings("PATCH:/webhooks/{webhook_id}/{webhook_token}/messages/{message_id}:77", message_key);
}

test "create DM channel route uses current user channel path" {
    const route = try createDmChannel(std.testing.allocator);
    defer route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, route.method);
    try std.testing.expectEqualStrings("/users/@me/channels", route.path);

    const key = try bucketKey(std.testing.allocator, route);
    defer std.testing.allocator.free(key);
    try std.testing.expectEqualStrings("POST:/users/@me/channels", key);
}

test "current user guild routes support pagination and leave" {
    const list_route = try currentUserGuilds(std.testing.allocator, .{
        .after = Snowflake.init(20),
        .limit = 50,
        .with_counts = true,
    });
    defer list_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, list_route.method);
    try std.testing.expectEqualStrings("/users/@me/guilds?after=20&limit=50&with_counts=true", list_route.path);

    const list_key = try bucketKey(std.testing.allocator, list_route);
    defer std.testing.allocator.free(list_key);
    try std.testing.expectEqualStrings("GET:/users/@me/guilds", list_key);

    const member_route = try currentUserGuildMember(std.testing.allocator, Snowflake.init(10));
    defer member_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, member_route.method);
    try std.testing.expectEqualStrings("/users/@me/guilds/10/member", member_route.path);

    const member_key = try bucketKey(std.testing.allocator, member_route);
    defer std.testing.allocator.free(member_key);
    try std.testing.expectEqualStrings("GET:/users/@me/guilds/{guild_id}/member:10", member_key);

    const connections_route = try currentUserConnections(std.testing.allocator);
    defer connections_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, connections_route.method);
    try std.testing.expectEqualStrings("/users/@me/connections", connections_route.path);

    const connections_key = try bucketKey(std.testing.allocator, connections_route);
    defer std.testing.allocator.free(connections_key);
    try std.testing.expectEqualStrings("GET:/users/@me/connections", connections_key);

    const authorization_route = try currentAuthorization(std.testing.allocator);
    defer authorization_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, authorization_route.method);
    try std.testing.expectEqualStrings("/oauth2/@me", authorization_route.path);

    const authorization_key = try bucketKey(std.testing.allocator, authorization_route);
    defer std.testing.allocator.free(authorization_key);
    try std.testing.expectEqualStrings("GET:/oauth2/@me", authorization_key);

    const token_route = try oauth2Token(std.testing.allocator);
    defer token_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, token_route.method);
    try std.testing.expectEqualStrings("/oauth2/token", token_route.path);

    const token_key = try bucketKey(std.testing.allocator, token_route);
    defer std.testing.allocator.free(token_key);
    try std.testing.expectEqualStrings("POST:/oauth2/token", token_key);

    const revoke_route = try revokeOAuth2Token(std.testing.allocator);
    defer revoke_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, revoke_route.method);
    try std.testing.expectEqualStrings("/oauth2/token/revoke", revoke_route.path);

    const revoke_key = try bucketKey(std.testing.allocator, revoke_route);
    defer std.testing.allocator.free(revoke_key);
    try std.testing.expectEqualStrings("POST:/oauth2/token/revoke", revoke_key);

    const role_connection_route = try currentUserApplicationRoleConnection(std.testing.allocator, Snowflake.init(99));
    defer role_connection_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, role_connection_route.method);
    try std.testing.expectEqualStrings("/users/@me/applications/99/role-connection", role_connection_route.path);

    const role_connection_key = try bucketKey(std.testing.allocator, role_connection_route);
    defer std.testing.allocator.free(role_connection_key);
    try std.testing.expectEqualStrings(
        "GET:/users/@me/applications/{application_id}/role-connection:99",
        role_connection_key,
    );

    const update_role_connection_route = try updateCurrentUserApplicationRoleConnection(
        std.testing.allocator,
        Snowflake.init(99),
    );
    defer update_role_connection_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, update_role_connection_route.method);
    try std.testing.expectEqualStrings("/users/@me/applications/99/role-connection", update_role_connection_route.path);

    const delete_role_connection_route = try deleteCurrentUserApplicationRoleConnection(
        std.testing.allocator,
        Snowflake.init(99),
    );
    defer delete_role_connection_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.DELETE, delete_role_connection_route.method);
    try std.testing.expectEqualStrings("/users/@me/applications/99/role-connection", delete_role_connection_route.path);

    const leave_route = try leaveGuild(std.testing.allocator, Snowflake.init(10));
    defer leave_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.DELETE, leave_route.method);
    try std.testing.expectEqualStrings("/users/@me/guilds/10", leave_route.path);

    const leave_key = try bucketKey(std.testing.allocator, leave_route);
    defer std.testing.allocator.free(leave_key);
    try std.testing.expectEqualStrings("DELETE:/users/@me/guilds/{guild_id}:10", leave_key);
}

test "reaction route percent-encodes emoji" {
    const route = try createReaction(std.testing.allocator, Snowflake.init(42), Snowflake.init(99), "👍");
    defer route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, route.method);
    try std.testing.expectEqualStrings("/channels/42/messages/99/reactions/%F0%9F%91%8D/@me", route.path);

    const list_route = try listReactions(std.testing.allocator, Snowflake.init(42), Snowflake.init(99), "👍", .{
        .after = Snowflake.init(10),
        .limit = 25,
        .type = .burst,
    });
    defer list_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, list_route.method);
    try std.testing.expectEqualStrings(
        "/channels/42/messages/99/reactions/%F0%9F%91%8D?after=10&limit=25&type=1",
        list_route.path,
    );

    const list_key = try bucketKey(std.testing.allocator, list_route);
    defer std.testing.allocator.free(list_key);
    try std.testing.expectEqualStrings(
        "GET:/channels/{channel_id}/messages/{message_id}/reactions/{emoji}:42",
        list_key,
    );
}

test "reaction cleanup routes use expected paths" {
    const user_route = try deleteUserReaction(
        std.testing.allocator,
        Snowflake.init(42),
        Snowflake.init(99),
        "👍",
        Snowflake.init(77),
    );
    defer user_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.DELETE, user_route.method);
    try std.testing.expectEqualStrings("/channels/42/messages/99/reactions/%F0%9F%91%8D/77", user_route.path);

    const all_route = try deleteAllReactions(std.testing.allocator, Snowflake.init(42), Snowflake.init(99));
    defer all_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.DELETE, all_route.method);
    try std.testing.expectEqualStrings("/channels/42/messages/99/reactions", all_route.path);

    const emoji_route = try deleteAllReactionsForEmoji(std.testing.allocator, Snowflake.init(42), Snowflake.init(99), "👍");
    defer emoji_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.DELETE, emoji_route.method);
    try std.testing.expectEqualStrings("/channels/42/messages/99/reactions/%F0%9F%91%8D", emoji_route.path);
}

test "poll routes use channel major parameter" {
    const voters_route = try pollAnswerVoters(std.testing.allocator, Snowflake.init(42), Snowflake.init(99), 2, .{
        .after = Snowflake.init(77),
        .limit = 25,
    });
    defer voters_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, voters_route.method);
    try std.testing.expectEqualStrings("/channels/42/polls/99/answers/2?after=77&limit=25", voters_route.path);

    const voters_key = try bucketKey(std.testing.allocator, voters_route);
    defer std.testing.allocator.free(voters_key);
    try std.testing.expectEqualStrings("GET:/channels/{channel_id}/polls/{message_id}/answers/{answer_id}:42", voters_key);

    const end_route = try endPoll(std.testing.allocator, Snowflake.init(42), Snowflake.init(99));
    defer end_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, end_route.method);
    try std.testing.expectEqualStrings("/channels/42/polls/99/expire", end_route.path);

    const end_key = try bucketKey(std.testing.allocator, end_route);
    defer std.testing.allocator.free(end_key);
    try std.testing.expectEqualStrings("POST:/channels/{channel_id}/polls/{message_id}/expire:42", end_key);
}

test "audit log route supports filters without changing bucket" {
    const route = try guildAuditLog(std.testing.allocator, Snowflake.init(10), .{
        .user_id = Snowflake.init(20),
        .action_type = 72,
        .before = Snowflake.init(40),
        .limit = 25,
    });
    defer route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, route.method);
    try std.testing.expectEqualStrings(
        "/guilds/10/audit-logs?user_id=20&action_type=72&before=40&limit=25",
        route.path,
    );

    const key = try bucketKey(std.testing.allocator, route);
    defer std.testing.allocator.free(key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/audit-logs:10", key);
}

test "guild integration routes use guild as major parameter" {
    const list_route = try guildIntegrations(std.testing.allocator, Snowflake.init(10));
    defer list_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, list_route.method);
    try std.testing.expectEqualStrings("/guilds/10/integrations", list_route.path);

    const list_key = try bucketKey(std.testing.allocator, list_route);
    defer std.testing.allocator.free(list_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/integrations:10", list_key);

    const delete_route = try deleteGuildIntegration(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer delete_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.DELETE, delete_route.method);
    try std.testing.expectEqualStrings("/guilds/10/integrations/20", delete_route.path);

    const delete_key = try bucketKey(std.testing.allocator, delete_route);
    defer std.testing.allocator.free(delete_key);
    try std.testing.expectEqualStrings("DELETE:/guilds/{guild_id}/integrations/{integration_id}:10", delete_key);
}

test "guild get and edit routes use guild as major parameter" {
    const get_route = try guild(std.testing.allocator, Snowflake.init(10));
    defer get_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, get_route.method);
    try std.testing.expectEqualStrings("/guilds/10", get_route.path);

    const get_key = try bucketKey(std.testing.allocator, get_route);
    defer std.testing.allocator.free(get_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}:10", get_key);

    const get_counts_route = try guildWithOptions(std.testing.allocator, Snowflake.init(10), .{ .with_counts = true });
    defer get_counts_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, get_counts_route.method);
    try std.testing.expectEqualStrings("/guilds/10?with_counts=true", get_counts_route.path);

    const get_counts_key = try bucketKey(std.testing.allocator, get_counts_route);
    defer std.testing.allocator.free(get_counts_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}:10", get_counts_key);

    const edit_route = try editGuild(std.testing.allocator, Snowflake.init(10));
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/guilds/10", edit_route.path);

    const preview_route = try guildPreview(std.testing.allocator, Snowflake.init(10));
    defer preview_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, preview_route.method);
    try std.testing.expectEqualStrings("/guilds/10/preview", preview_route.path);

    const preview_key = try bucketKey(std.testing.allocator, preview_route);
    defer std.testing.allocator.free(preview_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/preview:10", preview_key);
}

test "guild template routes encode codes and use guild buckets" {
    const get_route = try guildTemplate(std.testing.allocator, "abc 123");
    defer get_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, get_route.method);
    try std.testing.expectEqualStrings("/guilds/templates/abc%20123", get_route.path);

    const get_key = try bucketKey(std.testing.allocator, get_route);
    defer std.testing.allocator.free(get_key);
    try std.testing.expectEqualStrings("GET:/guilds/templates/{template_code}", get_key);

    const list_route = try guildTemplates(std.testing.allocator, Snowflake.init(10));
    defer list_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, list_route.method);
    try std.testing.expectEqualStrings("/guilds/10/templates", list_route.path);

    const create_route = try createGuildTemplate(std.testing.allocator, Snowflake.init(10));
    defer create_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, create_route.method);
    try std.testing.expectEqualStrings("/guilds/10/templates", create_route.path);

    const sync_route = try syncGuildTemplate(std.testing.allocator, Snowflake.init(10), "abc 123");
    defer sync_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, sync_route.method);
    try std.testing.expectEqualStrings("/guilds/10/templates/abc%20123", sync_route.path);

    const sync_key = try bucketKey(std.testing.allocator, sync_route);
    defer std.testing.allocator.free(sync_key);
    try std.testing.expectEqualStrings("PUT:/guilds/{guild_id}/templates/{template_code}:10", sync_key);

    const delete_route = try deleteGuildTemplate(std.testing.allocator, Snowflake.init(10), "abc 123");
    defer delete_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.DELETE, delete_route.method);
    try std.testing.expectEqualStrings("/guilds/10/templates/abc%20123", delete_route.path);
}

test "guild widget routes use guild as major parameter" {
    const settings_route = try guildWidgetSettings(std.testing.allocator, Snowflake.init(10));
    defer settings_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, settings_route.method);
    try std.testing.expectEqualStrings("/guilds/10/widget", settings_route.path);

    const settings_key = try bucketKey(std.testing.allocator, settings_route);
    defer std.testing.allocator.free(settings_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/widget:10", settings_key);

    const edit_route = try editGuildWidgetSettings(std.testing.allocator, Snowflake.init(10));
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/guilds/10/widget", edit_route.path);

    const widget_route = try guildWidget(std.testing.allocator, Snowflake.init(10));
    defer widget_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, widget_route.method);
    try std.testing.expectEqualStrings("/guilds/10/widget.json", widget_route.path);

    const image_route = try guildWidgetImage(std.testing.allocator, Snowflake.init(10), .{ .style = .banner2 });
    defer image_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, image_route.method);
    try std.testing.expectEqualStrings("/guilds/10/widget.png?style=banner2", image_route.path);

    const image_key = try bucketKey(std.testing.allocator, image_route);
    defer std.testing.allocator.free(image_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/widget.png:10", image_key);

    const welcome_route = try guildWelcomeScreen(std.testing.allocator, Snowflake.init(10));
    defer welcome_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, welcome_route.method);
    try std.testing.expectEqualStrings("/guilds/10/welcome-screen", welcome_route.path);

    const welcome_key = try bucketKey(std.testing.allocator, welcome_route);
    defer std.testing.allocator.free(welcome_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/welcome-screen:10", welcome_key);

    const edit_welcome_route = try editGuildWelcomeScreen(std.testing.allocator, Snowflake.init(10));
    defer edit_welcome_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_welcome_route.method);
    try std.testing.expectEqualStrings("/guilds/10/welcome-screen", edit_welcome_route.path);

    const onboarding_route = try guildOnboarding(std.testing.allocator, Snowflake.init(10));
    defer onboarding_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, onboarding_route.method);
    try std.testing.expectEqualStrings("/guilds/10/onboarding", onboarding_route.path);

    const onboarding_key = try bucketKey(std.testing.allocator, onboarding_route);
    defer std.testing.allocator.free(onboarding_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/onboarding:10", onboarding_key);

    const edit_onboarding_route = try editGuildOnboarding(std.testing.allocator, Snowflake.init(10));
    defer edit_onboarding_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_onboarding_route.method);
    try std.testing.expectEqualStrings("/guilds/10/onboarding", edit_onboarding_route.path);

    const incident_route = try editGuildIncidentActions(std.testing.allocator, Snowflake.init(10));
    defer incident_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, incident_route.method);
    try std.testing.expectEqualStrings("/guilds/10/incident-actions", incident_route.path);

    const incident_key = try bucketKey(std.testing.allocator, incident_route);
    defer std.testing.allocator.free(incident_key);
    try std.testing.expectEqualStrings("PUT:/guilds/{guild_id}/incident-actions:10", incident_key);

    const vanity_route = try guildVanityUrl(std.testing.allocator, Snowflake.init(10));
    defer vanity_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, vanity_route.method);
    try std.testing.expectEqualStrings("/guilds/10/vanity-url", vanity_route.path);
}

test "guild scheduled event routes use guild as major parameter" {
    const list_route = try guildScheduledEvents(std.testing.allocator, Snowflake.init(10), .{
        .with_user_count = true,
    });
    defer list_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, list_route.method);
    try std.testing.expectEqualStrings("/guilds/10/scheduled-events?with_user_count=true", list_route.path);

    const list_key = try bucketKey(std.testing.allocator, list_route);
    defer std.testing.allocator.free(list_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/scheduled-events:10", list_key);

    const create_route = try createGuildScheduledEvent(std.testing.allocator, Snowflake.init(10));
    defer create_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, create_route.method);
    try std.testing.expectEqualStrings("/guilds/10/scheduled-events", create_route.path);

    const get_route = try guildScheduledEvent(std.testing.allocator, Snowflake.init(10), Snowflake.init(20), .{
        .with_user_count = false,
    });
    defer get_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, get_route.method);
    try std.testing.expectEqualStrings("/guilds/10/scheduled-events/20?with_user_count=false", get_route.path);

    const edit_route = try editGuildScheduledEvent(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/guilds/10/scheduled-events/20", edit_route.path);

    const delete_route = try deleteGuildScheduledEvent(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer delete_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.DELETE, delete_route.method);
    try std.testing.expectEqualStrings("/guilds/10/scheduled-events/20", delete_route.path);

    const users_route = try guildScheduledEventUsers(std.testing.allocator, Snowflake.init(10), Snowflake.init(20), .{
        .limit = 25,
        .with_member = true,
        .after = Snowflake.init(30),
    });
    defer users_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, users_route.method);
    try std.testing.expectEqualStrings("/guilds/10/scheduled-events/20/users?limit=25&with_member=true&after=30", users_route.path);

    const users_key = try bucketKey(std.testing.allocator, users_route);
    defer std.testing.allocator.free(users_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/scheduled-events/{guild_scheduled_event_id}/users:10", users_key);
}

test "stage instance routes use expected methods and buckets" {
    const create_route = try createStageInstance(std.testing.allocator);
    defer create_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, create_route.method);
    try std.testing.expectEqualStrings("/stage-instances", create_route.path);

    const get_route = try stageInstance(std.testing.allocator, Snowflake.init(10));
    defer get_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, get_route.method);
    try std.testing.expectEqualStrings("/stage-instances/10", get_route.path);

    const get_key = try bucketKey(std.testing.allocator, get_route);
    defer std.testing.allocator.free(get_key);
    try std.testing.expectEqualStrings("GET:/stage-instances/{channel_id}:10", get_key);

    const edit_route = try editStageInstance(std.testing.allocator, Snowflake.init(10));
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/stage-instances/10", edit_route.path);

    const delete_route = try deleteStageInstance(std.testing.allocator, Snowflake.init(10));
    defer delete_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.DELETE, delete_route.method);
    try std.testing.expectEqualStrings("/stage-instances/10", delete_route.path);
}

test "current application routes use applications me path" {
    const get_route = try currentApplication(std.testing.allocator);
    defer get_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, get_route.method);
    try std.testing.expectEqualStrings("/applications/@me", get_route.path);

    const get_key = try bucketKey(std.testing.allocator, get_route);
    defer std.testing.allocator.free(get_key);
    try std.testing.expectEqualStrings("GET:/applications/@me", get_key);

    const oauth_route = try currentBotApplication(std.testing.allocator);
    defer oauth_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, oauth_route.method);
    try std.testing.expectEqualStrings("/oauth2/applications/@me", oauth_route.path);

    const oauth_key = try bucketKey(std.testing.allocator, oauth_route);
    defer std.testing.allocator.free(oauth_key);
    try std.testing.expectEqualStrings("GET:/oauth2/applications/@me", oauth_key);

    const edit_route = try editCurrentApplication(std.testing.allocator);
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/applications/@me", edit_route.path);

    const metadata_route = try applicationRoleConnectionMetadataRecords(std.testing.allocator, Snowflake.init(10));
    defer metadata_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, metadata_route.method);
    try std.testing.expectEqualStrings("/applications/10/role-connections/metadata", metadata_route.path);

    const metadata_key = try bucketKey(std.testing.allocator, metadata_route);
    defer std.testing.allocator.free(metadata_key);
    try std.testing.expectEqualStrings(
        "GET:/applications/{application_id}/role-connections/metadata:10",
        metadata_key,
    );

    const update_metadata_route = try updateApplicationRoleConnectionMetadataRecords(
        std.testing.allocator,
        Snowflake.init(10),
    );
    defer update_metadata_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, update_metadata_route.method);
    try std.testing.expectEqualStrings("/applications/10/role-connections/metadata", update_metadata_route.path);
}

test "current user routes use users me path" {
    const get_route = try currentUser(std.testing.allocator);
    defer get_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, get_route.method);
    try std.testing.expectEqualStrings("/users/@me", get_route.path);

    const edit_route = try editCurrentUser(std.testing.allocator);
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/users/@me", edit_route.path);
}

test "voice routes use expected paths and guild buckets" {
    const regions_route = try voiceRegions(std.testing.allocator);
    defer regions_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, regions_route.method);
    try std.testing.expectEqualStrings("/voice/regions", regions_route.path);

    const guild_regions_route = try guildVoiceRegions(std.testing.allocator, Snowflake.init(10));
    defer guild_regions_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, guild_regions_route.method);
    try std.testing.expectEqualStrings("/guilds/10/regions", guild_regions_route.path);

    const guild_regions_key = try bucketKey(std.testing.allocator, guild_regions_route);
    defer std.testing.allocator.free(guild_regions_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/regions:10", guild_regions_key);

    const current_route = try currentUserVoiceState(std.testing.allocator, Snowflake.init(10));
    defer current_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, current_route.method);
    try std.testing.expectEqualStrings("/guilds/10/voice-states/@me", current_route.path);

    const current_key = try bucketKey(std.testing.allocator, current_route);
    defer std.testing.allocator.free(current_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/voice-states/@me:10", current_key);

    const edit_current_route = try editCurrentUserVoiceState(std.testing.allocator, Snowflake.init(10));
    defer edit_current_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_current_route.method);
    try std.testing.expectEqualStrings("/guilds/10/voice-states/@me", edit_current_route.path);

    const user_route = try userVoiceState(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer user_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, user_route.method);
    try std.testing.expectEqualStrings("/guilds/10/voice-states/20", user_route.path);

    const user_key = try bucketKey(std.testing.allocator, user_route);
    defer std.testing.allocator.free(user_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/voice-states/{user_id}:10", user_key);

    const edit_user_route = try editUserVoiceState(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer edit_user_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_user_route.method);
    try std.testing.expectEqualStrings("/guilds/10/voice-states/20", edit_user_route.path);
}

test "channel management routes use expected methods and buckets" {
    const create_route = try createGuildChannel(std.testing.allocator, Snowflake.init(10));
    defer create_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, create_route.method);
    try std.testing.expectEqualStrings("/guilds/10/channels", create_route.path);

    const create_key = try bucketKey(std.testing.allocator, create_route);
    defer std.testing.allocator.free(create_key);
    try std.testing.expectEqualStrings("POST:/guilds/{guild_id}/channels:10", create_key);

    const positions_route = try editGuildChannelPositions(std.testing.allocator, Snowflake.init(10));
    defer positions_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, positions_route.method);
    try std.testing.expectEqualStrings("/guilds/10/channels", positions_route.path);

    const positions_key = try bucketKey(std.testing.allocator, positions_route);
    defer std.testing.allocator.free(positions_key);
    try std.testing.expectEqualStrings("PATCH:/guilds/{guild_id}/channels:10", positions_key);

    const edit_route = try editChannel(std.testing.allocator, Snowflake.init(20));
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/channels/20", edit_route.path);

    const edit_key = try bucketKey(std.testing.allocator, edit_route);
    defer std.testing.allocator.free(edit_key);
    try std.testing.expectEqualStrings("PATCH:/channels/{channel_id}:20", edit_key);
}

test "channel permission routes keep channel as major parameter" {
    const edit_route = try editChannelPermission(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, edit_route.method);
    try std.testing.expectEqualStrings("/channels/10/permissions/20", edit_route.path);

    const edit_key = try bucketKey(std.testing.allocator, edit_route);
    defer std.testing.allocator.free(edit_key);
    try std.testing.expectEqualStrings("PUT:/channels/{channel_id}/permissions/{overwrite_id}:10", edit_key);

    const delete_route = try deleteChannelPermission(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer delete_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.DELETE, delete_route.method);
    try std.testing.expectEqualStrings("/channels/10/permissions/20", delete_route.path);
}

test "channel utility routes keep channel as major parameter" {
    const status_route = try setVoiceChannelStatus(std.testing.allocator, Snowflake.init(10));
    defer status_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, status_route.method);
    try std.testing.expectEqualStrings("/channels/10/voice-status", status_route.path);

    const status_key = try bucketKey(std.testing.allocator, status_route);
    defer std.testing.allocator.free(status_key);
    try std.testing.expectEqualStrings("PUT:/channels/{channel_id}/voice-status:10", status_key);

    const follow_route = try followAnnouncementChannel(std.testing.allocator, Snowflake.init(10));
    defer follow_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, follow_route.method);
    try std.testing.expectEqualStrings("/channels/10/followers", follow_route.path);

    const follow_key = try bucketKey(std.testing.allocator, follow_route);
    defer std.testing.allocator.free(follow_key);
    try std.testing.expectEqualStrings("POST:/channels/{channel_id}/followers:10", follow_key);
}

test "role management routes use guild as major parameter" {
    const create_route = try createGuildRole(std.testing.allocator, Snowflake.init(10));
    defer create_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, create_route.method);
    try std.testing.expectEqualStrings("/guilds/10/roles", create_route.path);

    const create_key = try bucketKey(std.testing.allocator, create_route);
    defer std.testing.allocator.free(create_key);
    try std.testing.expectEqualStrings("POST:/guilds/{guild_id}/roles:10", create_key);

    const positions_route = try editGuildRolePositions(std.testing.allocator, Snowflake.init(10));
    defer positions_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, positions_route.method);
    try std.testing.expectEqualStrings("/guilds/10/roles", positions_route.path);

    const positions_key = try bucketKey(std.testing.allocator, positions_route);
    defer std.testing.allocator.free(positions_key);
    try std.testing.expectEqualStrings("PATCH:/guilds/{guild_id}/roles:10", positions_key);

    const counts_route = try guildRoleMemberCounts(std.testing.allocator, Snowflake.init(10));
    defer counts_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, counts_route.method);
    try std.testing.expectEqualStrings("/guilds/10/roles/member-counts", counts_route.path);

    const counts_key = try bucketKey(std.testing.allocator, counts_route);
    defer std.testing.allocator.free(counts_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/roles/member-counts:10", counts_key);

    const get_route = try guildRole(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer get_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, get_route.method);
    try std.testing.expectEqualStrings("/guilds/10/roles/20", get_route.path);

    const get_key = try bucketKey(std.testing.allocator, get_route);
    defer std.testing.allocator.free(get_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/roles/{role_id}:10", get_key);

    const edit_route = try editGuildRole(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/guilds/10/roles/20", edit_route.path);

    const edit_key = try bucketKey(std.testing.allocator, edit_route);
    defer std.testing.allocator.free(edit_key);
    try std.testing.expectEqualStrings("PATCH:/guilds/{guild_id}/roles/{role_id}:10", edit_key);
}

test "guild emoji routes use guild as major parameter" {
    const list_route = try guildEmojis(std.testing.allocator, Snowflake.init(10));
    defer list_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, list_route.method);
    try std.testing.expectEqualStrings("/guilds/10/emojis", list_route.path);

    const list_key = try bucketKey(std.testing.allocator, list_route);
    defer std.testing.allocator.free(list_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/emojis:10", list_key);

    const create_route = try createGuildEmoji(std.testing.allocator, Snowflake.init(10));
    defer create_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, create_route.method);
    try std.testing.expectEqualStrings("/guilds/10/emojis", create_route.path);

    const edit_route = try editGuildEmoji(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/guilds/10/emojis/20", edit_route.path);

    const edit_key = try bucketKey(std.testing.allocator, edit_route);
    defer std.testing.allocator.free(edit_key);
    try std.testing.expectEqualStrings("PATCH:/guilds/{guild_id}/emojis/{emoji_id}:10", edit_key);
}

test "application emoji routes use application as major parameter" {
    const list_route = try applicationEmojis(std.testing.allocator, Snowflake.init(10));
    defer list_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, list_route.method);
    try std.testing.expectEqualStrings("/applications/10/emojis", list_route.path);

    const list_key = try bucketKey(std.testing.allocator, list_route);
    defer std.testing.allocator.free(list_key);
    try std.testing.expectEqualStrings("GET:/applications/{application_id}/emojis:10", list_key);

    const create_route = try createApplicationEmoji(std.testing.allocator, Snowflake.init(10));
    defer create_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, create_route.method);
    try std.testing.expectEqualStrings("/applications/10/emojis", create_route.path);

    const edit_route = try editApplicationEmoji(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/applications/10/emojis/20", edit_route.path);

    const edit_key = try bucketKey(std.testing.allocator, edit_route);
    defer std.testing.allocator.free(edit_key);
    try std.testing.expectEqualStrings("PATCH:/applications/{application_id}/emojis/{emoji_id}:10", edit_key);

    const delete_route = try deleteApplicationEmoji(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer delete_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.DELETE, delete_route.method);
    try std.testing.expectEqualStrings("/applications/10/emojis/20", delete_route.path);

    const activity_instance_route = try applicationActivityInstance(
        std.testing.allocator,
        Snowflake.init(10),
        "abc:def 123",
    );
    defer activity_instance_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, activity_instance_route.method);
    try std.testing.expectEqualStrings("/applications/10/activity-instances/abc%3Adef%20123", activity_instance_route.path);

    const activity_instance_key = try bucketKey(std.testing.allocator, activity_instance_route);
    defer std.testing.allocator.free(activity_instance_key);
    try std.testing.expectEqualStrings(
        "GET:/applications/{application_id}/activity-instances/{instance_id}:10",
        activity_instance_key,
    );
}

test "lobby routes use lobby as major parameter" {
    const create_route = try createLobby(std.testing.allocator);
    defer create_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, create_route.method);
    try std.testing.expectEqualStrings("/lobbies", create_route.path);

    const create_key = try bucketKey(std.testing.allocator, create_route);
    defer std.testing.allocator.free(create_key);
    try std.testing.expectEqualStrings("POST:/lobbies", create_key);

    const get_route = try lobby(std.testing.allocator, Snowflake.init(10));
    defer get_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, get_route.method);
    try std.testing.expectEqualStrings("/lobbies/10", get_route.path);

    const get_key = try bucketKey(std.testing.allocator, get_route);
    defer std.testing.allocator.free(get_key);
    try std.testing.expectEqualStrings("GET:/lobbies/{lobby_id}:10", get_key);

    const edit_route = try editLobby(std.testing.allocator, Snowflake.init(10));
    defer edit_route.deinit(std.testing.allocator);
    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/lobbies/10", edit_route.path);

    const member_route = try lobbyMember(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer member_route.deinit(std.testing.allocator);
    try std.testing.expectEqual(.PUT, member_route.method);
    try std.testing.expectEqualStrings("/lobbies/10/members/20", member_route.path);

    const member_key = try bucketKey(std.testing.allocator, member_route);
    defer std.testing.allocator.free(member_key);
    try std.testing.expectEqualStrings("PUT:/lobbies/{lobby_id}/members/{user_id}:10", member_key);

    const bulk_route = try bulkUpdateLobbyMembers(std.testing.allocator, Snowflake.init(10));
    defer bulk_route.deinit(std.testing.allocator);
    try std.testing.expectEqual(.POST, bulk_route.method);
    try std.testing.expectEqualStrings("/lobbies/10/members/bulk", bulk_route.path);

    const leave_route = try leaveLobby(std.testing.allocator, Snowflake.init(10));
    defer leave_route.deinit(std.testing.allocator);
    try std.testing.expectEqual(.DELETE, leave_route.method);
    try std.testing.expectEqualStrings("/lobbies/10/members/@me", leave_route.path);

    const link_route = try linkLobbyChannel(std.testing.allocator, Snowflake.init(10));
    defer link_route.deinit(std.testing.allocator);
    try std.testing.expectEqual(.PATCH, link_route.method);
    try std.testing.expectEqualStrings("/lobbies/10/channel-linking", link_route.path);

    const moderation_route = try updateLobbyMessageModerationMetadata(
        std.testing.allocator,
        Snowflake.init(10),
        Snowflake.init(30),
    );
    defer moderation_route.deinit(std.testing.allocator);
    try std.testing.expectEqual(.PUT, moderation_route.method);
    try std.testing.expectEqualStrings("/lobbies/10/messages/30/moderation-metadata", moderation_route.path);

    const moderation_key = try bucketKey(std.testing.allocator, moderation_route);
    defer std.testing.allocator.free(moderation_key);
    try std.testing.expectEqualStrings(
        "PUT:/lobbies/{lobby_id}/messages/{message_id}/moderation-metadata:10",
        moderation_key,
    );
}

test "guild sticker routes use guild as major parameter" {
    const sticker_route = try sticker(std.testing.allocator, Snowflake.init(20));
    defer sticker_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, sticker_route.method);
    try std.testing.expectEqualStrings("/stickers/20", sticker_route.path);

    const sticker_key = try bucketKey(std.testing.allocator, sticker_route);
    defer std.testing.allocator.free(sticker_key);
    try std.testing.expectEqualStrings("GET:/stickers/{sticker_id}:20", sticker_key);

    const packs_route = try stickerPacks(std.testing.allocator);
    defer packs_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, packs_route.method);
    try std.testing.expectEqualStrings("/sticker-packs", packs_route.path);

    const packs_key = try bucketKey(std.testing.allocator, packs_route);
    defer std.testing.allocator.free(packs_key);
    try std.testing.expectEqualStrings("GET:/sticker-packs", packs_key);

    const list_route = try guildStickers(std.testing.allocator, Snowflake.init(10));
    defer list_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, list_route.method);
    try std.testing.expectEqualStrings("/guilds/10/stickers", list_route.path);

    const list_key = try bucketKey(std.testing.allocator, list_route);
    defer std.testing.allocator.free(list_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/stickers:10", list_key);

    const create_route = try createGuildSticker(std.testing.allocator, Snowflake.init(10));
    defer create_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, create_route.method);
    try std.testing.expectEqualStrings("/guilds/10/stickers", create_route.path);

    const edit_route = try editGuildSticker(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/guilds/10/stickers/20", edit_route.path);

    const edit_key = try bucketKey(std.testing.allocator, edit_route);
    defer std.testing.allocator.free(edit_key);
    try std.testing.expectEqualStrings("PATCH:/guilds/{guild_id}/stickers/{sticker_id}:10", edit_key);
}

test "member role routes use guild as major parameter" {
    const route = try addGuildMemberRole(
        std.testing.allocator,
        Snowflake.init(10),
        Snowflake.init(20),
        Snowflake.init(30),
    );
    defer route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, route.method);
    try std.testing.expectEqualStrings("/guilds/10/members/20/roles/30", route.path);

    const key = try bucketKey(std.testing.allocator, route);
    defer std.testing.allocator.free(key);
    try std.testing.expectEqualStrings(
        "PUT:/guilds/{guild_id}/members/{user_id}/roles/{role_id}:10",
        key,
    );
}

test "member moderation routes use guild as major parameter" {
    const members_route = try guildMembers(std.testing.allocator, Snowflake.init(10), .{
        .limit = 100,
        .after = Snowflake.init(20),
    });
    defer members_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, members_route.method);
    try std.testing.expectEqualStrings("/guilds/10/members?limit=100&after=20", members_route.path);

    const members_key = try bucketKey(std.testing.allocator, members_route);
    defer std.testing.allocator.free(members_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/members:10", members_key);

    const search_route = try searchGuildMembers(std.testing.allocator, Snowflake.init(10), .{
        .query = "baris dev",
        .limit = 25,
    });
    defer search_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, search_route.method);
    try std.testing.expectEqualStrings("/guilds/10/members/search?query=baris%20dev&limit=25", search_route.path);

    const search_key = try bucketKey(std.testing.allocator, search_route);
    defer std.testing.allocator.free(search_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/members/search:10", search_key);

    const edit_route = try editGuildMember(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/guilds/10/members/20", edit_route.path);

    const edit_key = try bucketKey(std.testing.allocator, edit_route);
    defer std.testing.allocator.free(edit_key);
    try std.testing.expectEqualStrings("PATCH:/guilds/{guild_id}/members/{user_id}:10", edit_key);

    const add_route = try addGuildMember(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer add_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, add_route.method);
    try std.testing.expectEqualStrings("/guilds/10/members/20", add_route.path);

    const add_key = try bucketKey(std.testing.allocator, add_route);
    defer std.testing.allocator.free(add_key);
    try std.testing.expectEqualStrings("PUT:/guilds/{guild_id}/members/{user_id}:10", add_key);

    const edit_current_route = try editCurrentGuildMember(std.testing.allocator, Snowflake.init(10));
    defer edit_current_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_current_route.method);
    try std.testing.expectEqualStrings("/guilds/10/members/@me", edit_current_route.path);

    const edit_current_key = try bucketKey(std.testing.allocator, edit_current_route);
    defer std.testing.allocator.free(edit_current_key);
    try std.testing.expectEqualStrings("PATCH:/guilds/{guild_id}/members/@me:10", edit_current_key);

    const edit_current_nick_route = try editCurrentUserNick(std.testing.allocator, Snowflake.init(10));
    defer edit_current_nick_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_current_nick_route.method);
    try std.testing.expectEqualStrings("/guilds/10/members/@me/nick", edit_current_nick_route.path);

    const edit_current_nick_key = try bucketKey(std.testing.allocator, edit_current_nick_route);
    defer std.testing.allocator.free(edit_current_nick_key);
    try std.testing.expectEqualStrings("PATCH:/guilds/{guild_id}/members/@me/nick:10", edit_current_nick_key);

    const bans_route = try guildBans(std.testing.allocator, Snowflake.init(10), .{
        .after = Snowflake.init(15),
        .limit = 50,
    });
    defer bans_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, bans_route.method);
    try std.testing.expectEqualStrings("/guilds/10/bans?after=15&limit=50", bans_route.path);

    const bans_key = try bucketKey(std.testing.allocator, bans_route);
    defer std.testing.allocator.free(bans_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/bans:10", bans_key);

    const get_ban_route = try guildBan(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer get_ban_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, get_ban_route.method);
    try std.testing.expectEqualStrings("/guilds/10/bans/20", get_ban_route.path);

    const prune_count_route = try guildPruneCount(std.testing.allocator, Snowflake.init(10), .{
        .days = 14,
        .include_roles = &.{ Snowflake.init(30), Snowflake.init(40) },
    });
    defer prune_count_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, prune_count_route.method);
    try std.testing.expectEqualStrings("/guilds/10/prune?days=14&include_roles=30,40", prune_count_route.path);

    const prune_count_key = try bucketKey(std.testing.allocator, prune_count_route);
    defer std.testing.allocator.free(prune_count_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/prune:10", prune_count_key);

    const begin_prune_route = try beginGuildPrune(std.testing.allocator, Snowflake.init(10));
    defer begin_prune_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, begin_prune_route.method);
    try std.testing.expectEqualStrings("/guilds/10/prune", begin_prune_route.path);

    const ban_route = try createGuildBan(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer ban_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, ban_route.method);
    try std.testing.expectEqualStrings("/guilds/10/bans/20", ban_route.path);

    const ban_key = try bucketKey(std.testing.allocator, ban_route);
    defer std.testing.allocator.free(ban_key);
    try std.testing.expectEqualStrings("PUT:/guilds/{guild_id}/bans/{user_id}:10", ban_key);

    const bulk_ban_route = try bulkGuildBan(std.testing.allocator, Snowflake.init(10));
    defer bulk_ban_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, bulk_ban_route.method);
    try std.testing.expectEqualStrings("/guilds/10/bulk-ban", bulk_ban_route.path);

    const bulk_ban_key = try bucketKey(std.testing.allocator, bulk_ban_route);
    defer std.testing.allocator.free(bulk_ban_key);
    try std.testing.expectEqualStrings("POST:/guilds/{guild_id}/bulk-ban:10", bulk_ban_key);
}

test "guild command routes use guild as major parameter" {
    const route = try bulkOverwriteGuildApplicationCommands(
        std.testing.allocator,
        Snowflake.init(10),
        Snowflake.init(20),
    );
    defer route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, route.method);
    try std.testing.expectEqualStrings("/applications/10/guilds/20/commands", route.path);

    const key = try bucketKey(std.testing.allocator, route);
    defer std.testing.allocator.free(key);
    try std.testing.expectEqualStrings(
        "PUT:/applications/{application_id}/guilds/{guild_id}/commands:20",
        key,
    );
}

test "application command edit routes use expected methods and major parameters" {
    const global_route = try editGlobalApplicationCommand(
        std.testing.allocator,
        Snowflake.init(10),
        Snowflake.init(30),
    );
    defer global_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, global_route.method);
    try std.testing.expectEqualStrings("/applications/10/commands/30", global_route.path);

    const global_key = try bucketKey(std.testing.allocator, global_route);
    defer std.testing.allocator.free(global_key);
    try std.testing.expectEqualStrings(
        "PATCH:/applications/{application_id}/commands/{command_id}:10",
        global_key,
    );

    const guild_route = try editGuildApplicationCommand(
        std.testing.allocator,
        Snowflake.init(10),
        Snowflake.init(20),
        Snowflake.init(30),
    );
    defer guild_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, guild_route.method);
    try std.testing.expectEqualStrings("/applications/10/guilds/20/commands/30", guild_route.path);

    const guild_key = try bucketKey(std.testing.allocator, guild_route);
    defer std.testing.allocator.free(guild_key);
    try std.testing.expectEqualStrings(
        "PATCH:/applications/{application_id}/guilds/{guild_id}/commands/{command_id}:20",
        guild_key,
    );
}

test "application command permission routes use guild as major parameter" {
    const route = try editApplicationCommandPermissions(
        std.testing.allocator,
        Snowflake.init(10),
        Snowflake.init(20),
        Snowflake.init(30),
    );
    defer route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, route.method);
    try std.testing.expectEqualStrings("/applications/10/guilds/20/commands/30/permissions", route.path);

    const key = try bucketKey(std.testing.allocator, route);
    defer std.testing.allocator.free(key);
    try std.testing.expectEqualStrings(
        "PUT:/applications/{application_id}/guilds/{guild_id}/commands/{command_id}/permissions:20",
        key,
    );
}

test "execute webhook with options appends query without changing bucket" {
    const route = try executeWebhookWithOptions(
        std.testing.allocator,
        Snowflake.init(77),
        "tok en",
        .{ .wait = true, .thread_id = Snowflake.init(55) },
    );
    defer route.deinit(std.testing.allocator);
    try std.testing.expectEqual(.POST, route.method);
    try std.testing.expectEqualStrings("/webhooks/77/tok%20en?wait=true&thread_id=55", route.path);

    const key = try bucketKey(std.testing.allocator, route);
    defer std.testing.allocator.free(key);
    try std.testing.expectEqualStrings("POST:/webhooks/{webhook_id}/{webhook_token}:77", key);

    const plain = try executeWebhookWithOptions(std.testing.allocator, Snowflake.init(77), "tok", .{});
    defer plain.deinit(std.testing.allocator);
    try std.testing.expectEqualStrings("/webhooks/77/tok", plain.path);
}
