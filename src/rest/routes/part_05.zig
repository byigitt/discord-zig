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
