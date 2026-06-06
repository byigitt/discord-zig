const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Types = @import("../../models/types.zig");

const Root = @import("../routes.zig");
const Method = Root.Method;
const Route = Root.Route;
const gateway = Root.gateway;
const gatewayBot = Root.gatewayBot;
const channel = Root.channel;
const addGroupDmRecipient = Root.addGroupDmRecipient;
const removeGroupDmRecipient = Root.removeGroupDmRecipient;
const createGuild = Root.createGuild;
const guild = Root.guild;
const deleteGuild = Root.deleteGuild;
const createGuildFromTemplate = Root.createGuildFromTemplate;
const bulkDeleteMessages = Root.bulkDeleteMessages;
const triggerTyping = Root.triggerTyping;
const channelMessagesWithOptions = Root.channelMessagesWithOptions;
const createThread = Root.createThread;
const joinThread = Root.joinThread;
const leaveThread = Root.leaveThread;
const addThreadMember = Root.addThreadMember;
const getThreadMember = Root.getThreadMember;
const removeThreadMember = Root.removeThreadMember;
const threadMembers = Root.threadMembers;
const threadMembersWithOptions = Root.threadMembersWithOptions;
const pinnedMessages = Root.pinnedMessages;
const channelPins = Root.channelPins;
const pinMessage = Root.pinMessage;
const webhook = Root.webhook;
const channelMessage = Root.channelMessage;
const createThreadFromMessage = Root.createThreadFromMessage;
const createMessage = Root.createMessage;

pub fn deleteGlobalApplicationCommand(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    command_id: Snowflake,
) !Route {
    return globalApplicationCommandRoute(allocator, .DELETE, application_id, command_id);
}

pub fn globalApplicationCommandRoute(
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

pub fn guildApplicationCommandsRoute(
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

pub fn applicationCommandPermissionsRoute(
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

pub fn guildApplicationCommandRoute(
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

pub fn interactionWebhookRoute(
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

pub fn interactionWebhookMessageRoute(
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

pub fn percentEncode(allocator: std.mem.Allocator, value: []const u8) ![]u8 {
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
