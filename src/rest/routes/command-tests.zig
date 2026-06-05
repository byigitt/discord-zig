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
