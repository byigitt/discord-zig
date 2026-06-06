const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Types = @import("../../models/types.zig");

const Root = @import("../routes.zig");
const Method = Root.Method;
const Route = Root.Route;
const pinMessageRoute = Root.pinMessageRoute;

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

pub fn guildBanRoute(
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

pub fn guildRolesRoute(allocator: std.mem.Allocator, method: Method, guild_id: Snowflake) !Route {
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

pub fn guildRoleRoute(
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

pub fn guildEmojisRoute(allocator: std.mem.Allocator, method: Method, guild_id: Snowflake) !Route {
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

pub fn guildEmojiRoute(
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

pub fn guildStickersRoute(allocator: std.mem.Allocator, method: Method, guild_id: Snowflake) !Route {
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

pub fn guildStickerRoute(
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

pub fn guildSoundboardSoundsRoute(allocator: std.mem.Allocator, method: Method, guild_id: Snowflake) !Route {
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

pub fn guildSoundboardSoundRoute(
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

pub fn guildMemberRoleRoute(
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

pub fn currentThreadMemberRoute(allocator: std.mem.Allocator, method: Method, thread_id: Snowflake) !Route {
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

pub fn threadMemberRoute(
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

pub fn archivedThreadsRoute(
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
