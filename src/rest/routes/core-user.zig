const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Types = @import("../../models/types.zig");

const Root = @import("../routes.zig");
const percentEncode = Root.percentEncode;

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

pub fn groupDmRecipientRoute(
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

pub fn channelRoute(allocator: std.mem.Allocator, method: Method, channel_id: Snowflake) !Route {
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

pub fn channelPermissionRoute(
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

pub fn stageInstanceRoute(allocator: std.mem.Allocator, method: Method, channel_id: Snowflake) !Route {
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

pub fn currentApplicationRoute(allocator: std.mem.Allocator, method: Method) !Route {
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

pub fn applicationRoleConnectionMetadataRecordsRoute(
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

pub fn applicationEmojisRoute(allocator: std.mem.Allocator, method: Method, application_id: Snowflake) !Route {
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

pub fn applicationEmojiRoute(
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

pub fn lobbyRoute(allocator: std.mem.Allocator, method: Method, lobby_id: Snowflake) !Route {
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

pub fn lobbyMemberRoute(
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

pub fn applicationEntitlementRoute(
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

pub fn userVoiceStateRoute(
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

pub fn currentUserRoute(allocator: std.mem.Allocator, method: Method) !Route {
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
