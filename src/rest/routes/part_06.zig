const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Types = @import("../../models/types.zig");

const Root = @import("../routes.zig");
const Method = Root.Method;
const Route = Root.Route;
const gateway = Root.gateway;
const gatewayBot = Root.gatewayBot;
const channel = Root.channel;
const editChannel = Root.editChannel;
const deleteChannel = Root.deleteChannel;
const addGroupDmRecipient = Root.addGroupDmRecipient;
const removeGroupDmRecipient = Root.removeGroupDmRecipient;
const groupDmRecipientRoute = Root.groupDmRecipientRoute;
const channelRoute = Root.channelRoute;
const editChannelPermission = Root.editChannelPermission;
const deleteChannelPermission = Root.deleteChannelPermission;
const channelPermissionRoute = Root.channelPermissionRoute;
const setVoiceChannelStatus = Root.setVoiceChannelStatus;
const followAnnouncementChannel = Root.followAnnouncementChannel;
const sendSoundboardSound = Root.sendSoundboardSound;
const createStageInstance = Root.createStageInstance;
const stageInstance = Root.stageInstance;
const editStageInstance = Root.editStageInstance;
const deleteStageInstance = Root.deleteStageInstance;
const stageInstanceRoute = Root.stageInstanceRoute;
const currentApplication = Root.currentApplication;
const currentBotApplication = Root.currentBotApplication;
const editCurrentApplication = Root.editCurrentApplication;
const currentApplicationRoute = Root.currentApplicationRoute;
const applicationSkus = Root.applicationSkus;
const applicationRoleConnectionMetadataRecords = Root.applicationRoleConnectionMetadataRecords;
const updateApplicationRoleConnectionMetadataRecords = Root.updateApplicationRoleConnectionMetadataRecords;
const applicationRoleConnectionMetadataRecordsRoute = Root.applicationRoleConnectionMetadataRecordsRoute;
const applicationEmojis = Root.applicationEmojis;
const createApplicationEmoji = Root.createApplicationEmoji;
const applicationEmojisRoute = Root.applicationEmojisRoute;
const applicationEmoji = Root.applicationEmoji;
const editApplicationEmoji = Root.editApplicationEmoji;
const deleteApplicationEmoji = Root.deleteApplicationEmoji;
const applicationEmojiRoute = Root.applicationEmojiRoute;
const applicationActivityInstance = Root.applicationActivityInstance;
const createLobby = Root.createLobby;
const lobby = Root.lobby;
const editLobby = Root.editLobby;
const deleteLobby = Root.deleteLobby;
const lobbyRoute = Root.lobbyRoute;
const lobbyMember = Root.lobbyMember;
const deleteLobbyMember = Root.deleteLobbyMember;
const lobbyMemberRoute = Root.lobbyMemberRoute;
const bulkUpdateLobbyMembers = Root.bulkUpdateLobbyMembers;
const leaveLobby = Root.leaveLobby;
const linkLobbyChannel = Root.linkLobbyChannel;
const updateLobbyMessageModerationMetadata = Root.updateLobbyMessageModerationMetadata;
const applicationEntitlements = Root.applicationEntitlements;
const createTestEntitlement = Root.createTestEntitlement;
const applicationEntitlement = Root.applicationEntitlement;
const deleteTestEntitlement = Root.deleteTestEntitlement;
const applicationEntitlementRoute = Root.applicationEntitlementRoute;
const consumeEntitlement = Root.consumeEntitlement;
const skuSubscriptions = Root.skuSubscriptions;
const skuSubscription = Root.skuSubscription;
const voiceRegions = Root.voiceRegions;
const guildVoiceRegions = Root.guildVoiceRegions;
const currentUserVoiceState = Root.currentUserVoiceState;
const editCurrentUserVoiceState = Root.editCurrentUserVoiceState;
const userVoiceState = Root.userVoiceState;
const editUserVoiceState = Root.editUserVoiceState;
const userVoiceStateRoute = Root.userVoiceStateRoute;
const currentUser = Root.currentUser;
const editCurrentUser = Root.editCurrentUser;
const currentUserRoute = Root.currentUserRoute;
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
const currentUserApplicationRoleConnectionRoute = Root.currentUserApplicationRoleConnectionRoute;
const leaveGuild = Root.leaveGuild;
const user = Root.user;
const createGuild = Root.createGuild;
const guild = Root.guild;
const guildWithOptions = Root.guildWithOptions;
const editGuild = Root.editGuild;
const deleteGuild = Root.deleteGuild;
const guildRoute = Root.guildRoute;
const guildRouteWithQuery = Root.guildRouteWithQuery;
const guildPreview = Root.guildPreview;
const autoModerationRules = Root.autoModerationRules;
const createAutoModerationRule = Root.createAutoModerationRule;
const autoModerationRulesRoute = Root.autoModerationRulesRoute;
const autoModerationRule = Root.autoModerationRule;
const editAutoModerationRule = Root.editAutoModerationRule;
const deleteAutoModerationRule = Root.deleteAutoModerationRule;
const autoModerationRuleRoute = Root.autoModerationRuleRoute;
const guildTemplate = Root.guildTemplate;
const createGuildFromTemplate = Root.createGuildFromTemplate;
const guildTemplates = Root.guildTemplates;
const createGuildTemplate = Root.createGuildTemplate;
const guildTemplatesRoute = Root.guildTemplatesRoute;
const syncGuildTemplate = Root.syncGuildTemplate;
const editGuildTemplate = Root.editGuildTemplate;
const deleteGuildTemplate = Root.deleteGuildTemplate;
const guildTemplateRoute = Root.guildTemplateRoute;
const guildWidgetSettings = Root.guildWidgetSettings;
const editGuildWidgetSettings = Root.editGuildWidgetSettings;
const guildWidgetSettingsRoute = Root.guildWidgetSettingsRoute;
const guildWidget = Root.guildWidget;
const guildWidgetImage = Root.guildWidgetImage;
const guildWelcomeScreen = Root.guildWelcomeScreen;
const editGuildWelcomeScreen = Root.editGuildWelcomeScreen;
const guildWelcomeScreenRoute = Root.guildWelcomeScreenRoute;
const guildOnboarding = Root.guildOnboarding;
const editGuildOnboarding = Root.editGuildOnboarding;
const guildOnboardingRoute = Root.guildOnboardingRoute;
const editGuildIncidentActions = Root.editGuildIncidentActions;
const guildVanityUrl = Root.guildVanityUrl;
const guildScheduledEvents = Root.guildScheduledEvents;
const createGuildScheduledEvent = Root.createGuildScheduledEvent;
const guildScheduledEvent = Root.guildScheduledEvent;
const editGuildScheduledEvent = Root.editGuildScheduledEvent;
const deleteGuildScheduledEvent = Root.deleteGuildScheduledEvent;
const guildScheduledEventMutationRoute = Root.guildScheduledEventMutationRoute;
const guildScheduledEventUsers = Root.guildScheduledEventUsers;
const guildAuditLog = Root.guildAuditLog;
const guildIntegrations = Root.guildIntegrations;
const deleteGuildIntegration = Root.deleteGuildIntegration;
const guildChannels = Root.guildChannels;
const createGuildChannel = Root.createGuildChannel;
const editGuildChannelPositions = Root.editGuildChannelPositions;
const guildChannelsRoute = Root.guildChannelsRoute;
const guildMembers = Root.guildMembers;
const searchGuildMembers = Root.searchGuildMembers;
const editCurrentGuildMember = Root.editCurrentGuildMember;
const editCurrentUserNick = Root.editCurrentUserNick;
const guildMember = Root.guildMember;
const addGuildMember = Root.addGuildMember;
const editGuildMember = Root.editGuildMember;
const removeGuildMember = Root.removeGuildMember;
const guildMemberRoute = Root.guildMemberRoute;
const guildBans = Root.guildBans;
const guildBan = Root.guildBan;
const guildPruneCount = Root.guildPruneCount;
const beginGuildPrune = Root.beginGuildPrune;
const createGuildBan = Root.createGuildBan;
const removeGuildBan = Root.removeGuildBan;
const bulkGuildBan = Root.bulkGuildBan;
const guildBanRoute = Root.guildBanRoute;
const guildRoles = Root.guildRoles;
const createGuildRole = Root.createGuildRole;
const editGuildRolePositions = Root.editGuildRolePositions;
const guildRolesRoute = Root.guildRolesRoute;
const guildRoleMemberCounts = Root.guildRoleMemberCounts;
const guildRole = Root.guildRole;
const editGuildRole = Root.editGuildRole;
const deleteGuildRole = Root.deleteGuildRole;
const guildRoleRoute = Root.guildRoleRoute;
const guildEmojis = Root.guildEmojis;
const createGuildEmoji = Root.createGuildEmoji;
const guildEmojisRoute = Root.guildEmojisRoute;
const guildEmoji = Root.guildEmoji;
const editGuildEmoji = Root.editGuildEmoji;
const deleteGuildEmoji = Root.deleteGuildEmoji;
const guildEmojiRoute = Root.guildEmojiRoute;
const guildStickers = Root.guildStickers;
const sticker = Root.sticker;
const stickerPacks = Root.stickerPacks;
const createGuildSticker = Root.createGuildSticker;
const guildStickersRoute = Root.guildStickersRoute;
const guildSticker = Root.guildSticker;
const editGuildSticker = Root.editGuildSticker;
const deleteGuildSticker = Root.deleteGuildSticker;
const guildStickerRoute = Root.guildStickerRoute;
const defaultSoundboardSounds = Root.defaultSoundboardSounds;
const guildSoundboardSounds = Root.guildSoundboardSounds;
const createGuildSoundboardSound = Root.createGuildSoundboardSound;
const guildSoundboardSoundsRoute = Root.guildSoundboardSoundsRoute;
const guildSoundboardSound = Root.guildSoundboardSound;
const editGuildSoundboardSound = Root.editGuildSoundboardSound;
const deleteGuildSoundboardSound = Root.deleteGuildSoundboardSound;
const guildSoundboardSoundRoute = Root.guildSoundboardSoundRoute;
const addGuildMemberRole = Root.addGuildMemberRole;
const removeGuildMemberRole = Root.removeGuildMemberRole;
const guildMemberRoleRoute = Root.guildMemberRoleRoute;
const channelMessages = Root.channelMessages;
const bulkDeleteMessages = Root.bulkDeleteMessages;
const triggerTyping = Root.triggerTyping;
const channelMessagesWithOptions = Root.channelMessagesWithOptions;
const createThread = Root.createThread;
const activeGuildThreads = Root.activeGuildThreads;
const joinThread = Root.joinThread;
const leaveThread = Root.leaveThread;
const currentThreadMemberRoute = Root.currentThreadMemberRoute;
const addThreadMember = Root.addThreadMember;
const getThreadMember = Root.getThreadMember;
const removeThreadMember = Root.removeThreadMember;
const threadMemberRoute = Root.threadMemberRoute;
const threadMembers = Root.threadMembers;
const threadMembersWithOptions = Root.threadMembersWithOptions;
const publicArchivedThreads = Root.publicArchivedThreads;
const privateArchivedThreads = Root.privateArchivedThreads;
const joinedPrivateArchivedThreads = Root.joinedPrivateArchivedThreads;
const archivedThreadsRoute = Root.archivedThreadsRoute;
const pinnedMessages = Root.pinnedMessages;
const channelPins = Root.channelPins;
const pinMessage = Root.pinMessage;
const unpinMessage = Root.unpinMessage;
const pinMessageRoute = Root.pinMessageRoute;
const channelInvites = Root.channelInvites;
const createChannelInvite = Root.createChannelInvite;
const channelInvitesRoute = Root.channelInvitesRoute;
const channelWebhooks = Root.channelWebhooks;
const createWebhook = Root.createWebhook;
const channelWebhooksRoute = Root.channelWebhooksRoute;
const guildWebhooks = Root.guildWebhooks;
const webhook = Root.webhook;
const editWebhook = Root.editWebhook;
const deleteWebhook = Root.deleteWebhook;
const webhookWithToken = Root.webhookWithToken;
const editWebhookWithToken = Root.editWebhookWithToken;
const deleteWebhookWithToken = Root.deleteWebhookWithToken;
const executeWebhook = Root.executeWebhook;
const executeWebhookWithOptions = Root.executeWebhookWithOptions;
const getWebhookMessage = Root.getWebhookMessage;
const editWebhookMessage = Root.editWebhookMessage;
const deleteWebhookMessage = Root.deleteWebhookMessage;
const webhookTokenRoute = Root.webhookTokenRoute;
const webhookMessageRoute = Root.webhookMessageRoute;
const webhookRoute = Root.webhookRoute;
const guildInvites = Root.guildInvites;
const invite = Root.invite;
const inviteWithOptions = Root.inviteWithOptions;
const deleteInvite = Root.deleteInvite;
const inviteTargetUsers = Root.inviteTargetUsers;
const updateInviteTargetUsers = Root.updateInviteTargetUsers;
const inviteTargetUsersJobStatus = Root.inviteTargetUsersJobStatus;
const inviteRoute = Root.inviteRoute;
const inviteRouteWithQuery = Root.inviteRouteWithQuery;
const inviteChildRoute = Root.inviteChildRoute;
const channelMessage = Root.channelMessage;
const createThreadFromMessage = Root.createThreadFromMessage;
const createMessage = Root.createMessage;
const deleteMessage = Root.deleteMessage;
const editMessage = Root.editMessage;
const crosspostMessage = Root.crosspostMessage;
const createReaction = Root.createReaction;
const deleteOwnReaction = Root.deleteOwnReaction;
const deleteUserReaction = Root.deleteUserReaction;
const listReactions = Root.listReactions;
const deleteAllReactions = Root.deleteAllReactions;
const deleteAllReactionsForEmoji = Root.deleteAllReactionsForEmoji;
const pollAnswerVoters = Root.pollAnswerVoters;
const endPoll = Root.endPoll;
const ownReactionRoute = Root.ownReactionRoute;
const globalApplicationCommands = Root.globalApplicationCommands;
const createGlobalApplicationCommand = Root.createGlobalApplicationCommand;
const bulkOverwriteGlobalApplicationCommands = Root.bulkOverwriteGlobalApplicationCommands;
const globalApplicationCommand = Root.globalApplicationCommand;
const editGlobalApplicationCommand = Root.editGlobalApplicationCommand;
const deleteGlobalApplicationCommand = Root.deleteGlobalApplicationCommand;
const globalApplicationCommandRoute = Root.globalApplicationCommandRoute;
const guildApplicationCommands = Root.guildApplicationCommands;
const createGuildApplicationCommand = Root.createGuildApplicationCommand;
const bulkOverwriteGuildApplicationCommands = Root.bulkOverwriteGuildApplicationCommands;
const guildApplicationCommandsRoute = Root.guildApplicationCommandsRoute;
const guildApplicationCommand = Root.guildApplicationCommand;
const editGuildApplicationCommand = Root.editGuildApplicationCommand;
const deleteGuildApplicationCommand = Root.deleteGuildApplicationCommand;
const guildApplicationCommandPermissions = Root.guildApplicationCommandPermissions;
const applicationCommandPermissions = Root.applicationCommandPermissions;
const editApplicationCommandPermissions = Root.editApplicationCommandPermissions;
const applicationCommandPermissionsRoute = Root.applicationCommandPermissionsRoute;
const guildApplicationCommandRoute = Root.guildApplicationCommandRoute;
const interactionCallback = Root.interactionCallback;
const getOriginalInteractionResponse = Root.getOriginalInteractionResponse;
const editOriginalInteractionResponse = Root.editOriginalInteractionResponse;
const deleteOriginalInteractionResponse = Root.deleteOriginalInteractionResponse;
const createFollowupMessage = Root.createFollowupMessage;
const getFollowupMessage = Root.getFollowupMessage;
const editFollowupMessage = Root.editFollowupMessage;
const deleteFollowupMessage = Root.deleteFollowupMessage;
const interactionWebhookRoute = Root.interactionWebhookRoute;
const interactionWebhookMessageRoute = Root.interactionWebhookMessageRoute;
const bucketKey = Root.bucketKey;
const percentEncode = Root.percentEncode;

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
