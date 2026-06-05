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

pub fn currentUserApplicationRoleConnectionRoute(
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

pub fn guildRoute(allocator: std.mem.Allocator, method: Method, guild_id: Snowflake) !Route {
    return guildRouteWithQuery(allocator, method, guild_id, null);
}

pub fn guildRouteWithQuery(
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

pub fn autoModerationRulesRoute(allocator: std.mem.Allocator, method: Method, guild_id: Snowflake) !Route {
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

pub fn autoModerationRuleRoute(
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

pub fn guildTemplatesRoute(allocator: std.mem.Allocator, method: Method, guild_id: Snowflake) !Route {
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

pub fn guildTemplateRoute(
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

pub fn guildWidgetSettingsRoute(allocator: std.mem.Allocator, method: Method, guild_id: Snowflake) !Route {
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

pub fn guildWelcomeScreenRoute(allocator: std.mem.Allocator, method: Method, guild_id: Snowflake) !Route {
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

pub fn guildOnboardingRoute(allocator: std.mem.Allocator, method: Method, guild_id: Snowflake) !Route {
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

pub fn guildScheduledEventMutationRoute(
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

pub fn guildChannelsRoute(allocator: std.mem.Allocator, method: Method, guild_id: Snowflake) !Route {
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

pub fn guildMemberRoute(
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
