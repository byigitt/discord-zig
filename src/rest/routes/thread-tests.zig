const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;

const Root = @import("../routes.zig");
const createDmChannel = Root.createDmChannel;
const currentUserGuilds = Root.currentUserGuilds;
const currentUserGuildMember = Root.currentUserGuildMember;
const currentUserConnections = Root.currentUserConnections;
const currentAuthorization = Root.currentAuthorization;
const oauth2Token = Root.oauth2Token;
const revokeOAuth2Token = Root.revokeOAuth2Token;
const currentUserApplicationRoleConnection = Root.currentUserApplicationRoleConnection;
const updateCurrentUserApplicationRoleConnection = Root.updateCurrentUserApplicationRoleConnection;
const deleteCurrentUserApplicationRoleConnection = Root.deleteCurrentUserApplicationRoleConnection;
const leaveGuild = Root.leaveGuild;
const guild = Root.guild;
const guildWithOptions = Root.guildWithOptions;
const editGuild = Root.editGuild;
const guildPreview = Root.guildPreview;
const guildTemplate = Root.guildTemplate;
const guildTemplates = Root.guildTemplates;
const createGuildTemplate = Root.createGuildTemplate;
const syncGuildTemplate = Root.syncGuildTemplate;
const deleteGuildTemplate = Root.deleteGuildTemplate;
const guildWidgetSettings = Root.guildWidgetSettings;
const editGuildWidgetSettings = Root.editGuildWidgetSettings;
const guildWidget = Root.guildWidget;
const guildWidgetImage = Root.guildWidgetImage;
const guildWelcomeScreen = Root.guildWelcomeScreen;
const editGuildWelcomeScreen = Root.editGuildWelcomeScreen;
const guildOnboarding = Root.guildOnboarding;
const editGuildOnboarding = Root.editGuildOnboarding;
const editGuildIncidentActions = Root.editGuildIncidentActions;
const guildVanityUrl = Root.guildVanityUrl;
const guildAuditLog = Root.guildAuditLog;
const guildIntegrations = Root.guildIntegrations;
const deleteGuildIntegration = Root.deleteGuildIntegration;
const activeGuildThreads = Root.activeGuildThreads;
const publicArchivedThreads = Root.publicArchivedThreads;
const privateArchivedThreads = Root.privateArchivedThreads;
const joinedPrivateArchivedThreads = Root.joinedPrivateArchivedThreads;
const createChannelInvite = Root.createChannelInvite;
const createWebhook = Root.createWebhook;
const guildWebhooks = Root.guildWebhooks;
const editWebhook = Root.editWebhook;
const editWebhookWithToken = Root.editWebhookWithToken;
const executeWebhook = Root.executeWebhook;
const editWebhookMessage = Root.editWebhookMessage;
const guildInvites = Root.guildInvites;
const inviteWithOptions = Root.inviteWithOptions;
const deleteInvite = Root.deleteInvite;
const inviteTargetUsers = Root.inviteTargetUsers;
const updateInviteTargetUsers = Root.updateInviteTargetUsers;
const inviteTargetUsersJobStatus = Root.inviteTargetUsersJobStatus;
const createReaction = Root.createReaction;
const deleteUserReaction = Root.deleteUserReaction;
const listReactions = Root.listReactions;
const deleteAllReactions = Root.deleteAllReactions;
const deleteAllReactionsForEmoji = Root.deleteAllReactionsForEmoji;
const pollAnswerVoters = Root.pollAnswerVoters;
const endPoll = Root.endPoll;
const bucketKey = Root.bucketKey;

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
