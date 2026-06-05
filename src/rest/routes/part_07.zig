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
