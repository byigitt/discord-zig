const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Types = @import("../../models/types.zig");

const Root = @import("../routes.zig");
const Method = Root.Method;
const Route = Root.Route;
const globalApplicationCommandRoute = Root.globalApplicationCommandRoute;
const percentEncode = Root.percentEncode;

pub fn pinMessageRoute(
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

pub fn channelInvitesRoute(allocator: std.mem.Allocator, method: Method, channel_id: Snowflake) !Route {
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

pub fn channelWebhooksRoute(allocator: std.mem.Allocator, method: Method, channel_id: Snowflake) !Route {
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

pub fn webhookTokenRoute(
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

pub fn webhookMessageRoute(
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

pub fn webhookRoute(allocator: std.mem.Allocator, method: Method, webhook_id: Snowflake) !Route {
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

pub fn inviteRoute(allocator: std.mem.Allocator, method: Method, code: []const u8) !Route {
    return inviteRouteWithQuery(allocator, method, code, null);
}

pub fn inviteRouteWithQuery(
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

pub fn inviteChildRoute(
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

pub fn ownReactionRoute(
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
