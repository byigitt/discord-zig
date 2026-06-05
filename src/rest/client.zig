const std = @import("std");
const Api = @import("../core/api.zig");
const Routes = @import("routes.zig");
const Types = @import("../models/types.zig");
const Interactions = @import("../interactions/mod.zig");
const Snowflake = @import("../core/snowflake.zig").Snowflake;

const test_messages_interactions_guild = @import("client_tests/messages_interactions_guild_test.zig");
const test_threads_invites_webhooks = @import("client_tests/threads_invites_webhooks_test.zig");
const test_users_channels = @import("client_tests/users_channels_test.zig");
const test_channels_roles = @import("client_tests/channels_roles_test.zig");
const test_emoji_lobby_stickers = @import("client_tests/emoji_lobby_stickers_test.zig");
const test_soundboard_commands = @import("client_tests/soundboard_commands_test.zig");
const test_command_permissions_uploads = @import("client_tests/command_permissions_uploads_test.zig");

pub const Header = struct {
    name: []const u8,
    value: []const u8,
};

pub const Request = struct {
    method: Routes.Method,
    url: []const u8,
    token: []const u8,
    body: ?[]const u8 = null,
    body_stream: ?BodyStream = null,
    content_type: ?[]const u8 = null,
};

pub const BodyStream = struct {
    ptr: *anyopaque,
    content_length: u64,
    writeFn: *const fn (ptr: *anyopaque, writer: *std.Io.Writer) anyerror!void,

    pub fn writeTo(self: BodyStream, writer: *std.Io.Writer) !void {
        try self.writeFn(self.ptr, writer);
    }
};

pub const Response = struct {
    status: u16,
    body: []const u8,
    headers: []const Header = &.{},
};

pub const Transport = struct {
    ptr: *anyopaque,
    sendFn: *const fn (ptr: *anyopaque, allocator: std.mem.Allocator, request: Request) anyerror!Response,

    pub fn send(self: Transport, allocator: std.mem.Allocator, request: Request) !Response {
        return self.sendFn(self.ptr, allocator, request);
    }
};

pub const RateLimitState = struct {
    remaining: ?u32 = null,
    reset_after_ms: ?u64 = null,
    bucket: ?[]const u8 = null,
    global: bool = false,

    pub fn updateFromHeaders(self: *RateLimitState, headers: []const Header) void {
        for (headers) |header| {
            if (std.ascii.eqlIgnoreCase(header.name, "X-RateLimit-Remaining")) {
                self.remaining = std.fmt.parseInt(u32, header.value, 10) catch self.remaining;
            } else if (std.ascii.eqlIgnoreCase(header.name, "X-RateLimit-Reset-After")) {
                const seconds = std.fmt.parseFloat(f64, header.value) catch continue;
                self.reset_after_ms = @intFromFloat(seconds * 1000.0);
            } else if (std.ascii.eqlIgnoreCase(header.name, "X-RateLimit-Bucket")) {
                self.bucket = header.value;
            } else if (std.ascii.eqlIgnoreCase(header.name, "X-RateLimit-Global")) {
                self.global = std.ascii.eqlIgnoreCase(header.value, "true");
            }
        }
    }
};

pub const Client = struct {
    allocator: std.mem.Allocator,
    token: []const u8,
    transport: Transport,
    rate_limits: std.StringHashMap(RateLimitState),

    const application_guild_methods = @import("client_methods/application_guild.zig").Methods(@This());
    const guild_assets_members_methods = @import("client_methods/guild_assets_members.zig").Methods(@This());
    const messages_threads_commands_methods = @import("client_methods/messages_threads_commands.zig").Methods(@This());
    const commands_interactions_request_methods = @import("client_methods/commands_interactions_request.zig").Methods(@This());
    pub const init = application_guild_methods.init;
    pub const deinit = application_guild_methods.deinit;
    pub const createMessage = application_guild_methods.createMessage;
    pub const getGateway = application_guild_methods.getGateway;
    pub const getGatewayBot = application_guild_methods.getGatewayBot;
    pub const getCurrentApplication = application_guild_methods.getCurrentApplication;
    pub const getCurrentBotApplication = application_guild_methods.getCurrentBotApplication;
    pub const editCurrentApplication = application_guild_methods.editCurrentApplication;
    pub const listApplicationSkus = application_guild_methods.listApplicationSkus;
    pub const listApplicationRoleConnectionMetadataRecords = application_guild_methods.listApplicationRoleConnectionMetadataRecords;
    pub const updateApplicationRoleConnectionMetadataRecords = application_guild_methods.updateApplicationRoleConnectionMetadataRecords;
    pub const listApplicationEmojis = application_guild_methods.listApplicationEmojis;
    pub const getApplicationEmoji = application_guild_methods.getApplicationEmoji;
    pub const createApplicationEmoji = application_guild_methods.createApplicationEmoji;
    pub const editApplicationEmoji = application_guild_methods.editApplicationEmoji;
    pub const deleteApplicationEmoji = application_guild_methods.deleteApplicationEmoji;
    pub const getApplicationActivityInstance = application_guild_methods.getApplicationActivityInstance;
    pub const createLobby = application_guild_methods.createLobby;
    pub const getLobby = application_guild_methods.getLobby;
    pub const editLobby = application_guild_methods.editLobby;
    pub const deleteLobby = application_guild_methods.deleteLobby;
    pub const addLobbyMember = application_guild_methods.addLobbyMember;
    pub const bulkUpdateLobbyMembers = application_guild_methods.bulkUpdateLobbyMembers;
    pub const removeLobbyMember = application_guild_methods.removeLobbyMember;
    pub const leaveLobby = application_guild_methods.leaveLobby;
    pub const linkLobbyChannel = application_guild_methods.linkLobbyChannel;
    pub const unlinkLobbyChannel = application_guild_methods.unlinkLobbyChannel;
    pub const updateLobbyMessageModerationMetadata = application_guild_methods.updateLobbyMessageModerationMetadata;
    pub const listEntitlements = application_guild_methods.listEntitlements;
    pub const getEntitlement = application_guild_methods.getEntitlement;
    pub const consumeEntitlement = application_guild_methods.consumeEntitlement;
    pub const createTestEntitlement = application_guild_methods.createTestEntitlement;
    pub const deleteTestEntitlement = application_guild_methods.deleteTestEntitlement;
    pub const listSkuSubscriptions = application_guild_methods.listSkuSubscriptions;
    pub const getSkuSubscription = application_guild_methods.getSkuSubscription;
    pub const getCurrentUser = application_guild_methods.getCurrentUser;
    pub const editCurrentUser = application_guild_methods.editCurrentUser;
    pub const getUser = application_guild_methods.getUser;
    pub const createDmChannel = application_guild_methods.createDmChannel;
    pub const listCurrentUserGuilds = application_guild_methods.listCurrentUserGuilds;
    pub const getCurrentUserGuildMember = application_guild_methods.getCurrentUserGuildMember;
    pub const listCurrentUserConnections = application_guild_methods.listCurrentUserConnections;
    pub const getCurrentAuthorization = application_guild_methods.getCurrentAuthorization;
    pub const exchangeOAuth2Token = application_guild_methods.exchangeOAuth2Token;
    pub const revokeOAuth2Token = application_guild_methods.revokeOAuth2Token;
    pub const getCurrentUserApplicationRoleConnection = application_guild_methods.getCurrentUserApplicationRoleConnection;
    pub const updateCurrentUserApplicationRoleConnection = application_guild_methods.updateCurrentUserApplicationRoleConnection;
    pub const deleteCurrentUserApplicationRoleConnection = application_guild_methods.deleteCurrentUserApplicationRoleConnection;
    pub const leaveGuild = application_guild_methods.leaveGuild;
    pub const getChannel = application_guild_methods.getChannel;
    pub const editChannel = application_guild_methods.editChannel;
    pub const deleteChannel = application_guild_methods.deleteChannel;
    pub const editChannelPermission = application_guild_methods.editChannelPermission;
    pub const deleteChannelPermission = application_guild_methods.deleteChannelPermission;
    pub const setVoiceChannelStatus = application_guild_methods.setVoiceChannelStatus;
    pub const followAnnouncementChannel = application_guild_methods.followAnnouncementChannel;
    pub const sendSoundboardSound = application_guild_methods.sendSoundboardSound;
    pub const createStageInstance = application_guild_methods.createStageInstance;
    pub const getStageInstance = application_guild_methods.getStageInstance;
    pub const editStageInstance = application_guild_methods.editStageInstance;
    pub const deleteStageInstance = application_guild_methods.deleteStageInstance;
    pub const listVoiceRegions = application_guild_methods.listVoiceRegions;
    pub const listGuildVoiceRegions = application_guild_methods.listGuildVoiceRegions;
    pub const getCurrentUserVoiceState = application_guild_methods.getCurrentUserVoiceState;
    pub const getUserVoiceState = application_guild_methods.getUserVoiceState;
    pub const editCurrentUserVoiceState = application_guild_methods.editCurrentUserVoiceState;
    pub const editUserVoiceState = application_guild_methods.editUserVoiceState;
    pub const createGuild = application_guild_methods.createGuild;
    pub const getGuild = application_guild_methods.getGuild;
    pub const getGuildWithOptions = application_guild_methods.getGuildWithOptions;
    pub const editGuild = application_guild_methods.editGuild;
    pub const deleteGuild = application_guild_methods.deleteGuild;
    pub const getGuildPreview = application_guild_methods.getGuildPreview;
    pub const listAutoModerationRules = application_guild_methods.listAutoModerationRules;
    pub const getAutoModerationRule = application_guild_methods.getAutoModerationRule;
    pub const createAutoModerationRule = application_guild_methods.createAutoModerationRule;
    pub const editAutoModerationRule = guild_assets_members_methods.editAutoModerationRule;
    pub const deleteAutoModerationRule = guild_assets_members_methods.deleteAutoModerationRule;
    pub const getGuildTemplate = guild_assets_members_methods.getGuildTemplate;
    pub const createGuildFromTemplate = guild_assets_members_methods.createGuildFromTemplate;
    pub const listGuildTemplates = guild_assets_members_methods.listGuildTemplates;
    pub const createGuildTemplate = guild_assets_members_methods.createGuildTemplate;
    pub const syncGuildTemplate = guild_assets_members_methods.syncGuildTemplate;
    pub const editGuildTemplate = guild_assets_members_methods.editGuildTemplate;
    pub const deleteGuildTemplate = guild_assets_members_methods.deleteGuildTemplate;
    pub const getGuildWidgetSettings = guild_assets_members_methods.getGuildWidgetSettings;
    pub const editGuildWidgetSettings = guild_assets_members_methods.editGuildWidgetSettings;
    pub const getGuildWidget = guild_assets_members_methods.getGuildWidget;
    pub const getGuildWidgetImage = guild_assets_members_methods.getGuildWidgetImage;
    pub const getGuildWelcomeScreen = guild_assets_members_methods.getGuildWelcomeScreen;
    pub const editGuildWelcomeScreen = guild_assets_members_methods.editGuildWelcomeScreen;
    pub const getGuildOnboarding = guild_assets_members_methods.getGuildOnboarding;
    pub const editGuildOnboarding = guild_assets_members_methods.editGuildOnboarding;
    pub const editGuildIncidentActions = guild_assets_members_methods.editGuildIncidentActions;
    pub const getGuildVanityUrl = guild_assets_members_methods.getGuildVanityUrl;
    pub const listGuildScheduledEvents = guild_assets_members_methods.listGuildScheduledEvents;
    pub const createGuildScheduledEvent = guild_assets_members_methods.createGuildScheduledEvent;
    pub const getGuildScheduledEvent = guild_assets_members_methods.getGuildScheduledEvent;
    pub const editGuildScheduledEvent = guild_assets_members_methods.editGuildScheduledEvent;
    pub const deleteGuildScheduledEvent = guild_assets_members_methods.deleteGuildScheduledEvent;
    pub const listGuildScheduledEventUsers = guild_assets_members_methods.listGuildScheduledEventUsers;
    pub const listGuildAuditLog = guild_assets_members_methods.listGuildAuditLog;
    pub const listGuildIntegrations = guild_assets_members_methods.listGuildIntegrations;
    pub const deleteGuildIntegration = guild_assets_members_methods.deleteGuildIntegration;
    pub const listGuildChannels = guild_assets_members_methods.listGuildChannels;
    pub const createGuildChannel = guild_assets_members_methods.createGuildChannel;
    pub const editGuildChannelPositions = guild_assets_members_methods.editGuildChannelPositions;
    pub const listGuildMembers = guild_assets_members_methods.listGuildMembers;
    pub const searchGuildMembers = guild_assets_members_methods.searchGuildMembers;
    pub const getGuildMember = guild_assets_members_methods.getGuildMember;
    pub const addGuildMember = guild_assets_members_methods.addGuildMember;
    pub const editGuildMember = guild_assets_members_methods.editGuildMember;
    pub const editCurrentGuildMember = guild_assets_members_methods.editCurrentGuildMember;
    pub const editCurrentUserNick = guild_assets_members_methods.editCurrentUserNick;
    pub const removeGuildMember = guild_assets_members_methods.removeGuildMember;
    pub const listGuildBans = guild_assets_members_methods.listGuildBans;
    pub const getGuildBan = guild_assets_members_methods.getGuildBan;
    pub const getGuildPruneCount = guild_assets_members_methods.getGuildPruneCount;
    pub const beginGuildPrune = guild_assets_members_methods.beginGuildPrune;
    pub const createGuildBan = guild_assets_members_methods.createGuildBan;
    pub const bulkGuildBan = guild_assets_members_methods.bulkGuildBan;
    pub const removeGuildBan = guild_assets_members_methods.removeGuildBan;
    pub const listGuildRoles = guild_assets_members_methods.listGuildRoles;
    pub const getGuildRole = guild_assets_members_methods.getGuildRole;
    pub const getGuildRoleMemberCounts = guild_assets_members_methods.getGuildRoleMemberCounts;
    pub const createGuildRole = guild_assets_members_methods.createGuildRole;
    pub const editGuildRolePositions = guild_assets_members_methods.editGuildRolePositions;
    pub const editGuildRole = guild_assets_members_methods.editGuildRole;
    pub const deleteGuildRole = guild_assets_members_methods.deleteGuildRole;
    pub const listGuildEmojis = guild_assets_members_methods.listGuildEmojis;
    pub const getGuildEmoji = guild_assets_members_methods.getGuildEmoji;
    pub const createGuildEmoji = guild_assets_members_methods.createGuildEmoji;
    pub const editGuildEmoji = guild_assets_members_methods.editGuildEmoji;
    pub const deleteGuildEmoji = guild_assets_members_methods.deleteGuildEmoji;
    pub const getSticker = guild_assets_members_methods.getSticker;
    pub const listStickerPacks = guild_assets_members_methods.listStickerPacks;
    pub const listGuildStickers = guild_assets_members_methods.listGuildStickers;
    pub const getGuildSticker = guild_assets_members_methods.getGuildSticker;
    pub const createGuildSticker = guild_assets_members_methods.createGuildSticker;
    pub const editGuildSticker = guild_assets_members_methods.editGuildSticker;
    pub const deleteGuildSticker = guild_assets_members_methods.deleteGuildSticker;
    pub const listDefaultSoundboardSounds = guild_assets_members_methods.listDefaultSoundboardSounds;
    pub const listGuildSoundboardSounds = guild_assets_members_methods.listGuildSoundboardSounds;
    pub const getGuildSoundboardSound = guild_assets_members_methods.getGuildSoundboardSound;
    pub const createGuildSoundboardSound = guild_assets_members_methods.createGuildSoundboardSound;
    pub const editGuildSoundboardSound = guild_assets_members_methods.editGuildSoundboardSound;
    pub const deleteGuildSoundboardSound = guild_assets_members_methods.deleteGuildSoundboardSound;
    pub const addGuildMemberRole = guild_assets_members_methods.addGuildMemberRole;
    pub const removeGuildMemberRole = guild_assets_members_methods.removeGuildMemberRole;
    pub const createMessageWithFiles = messages_threads_commands_methods.createMessageWithFiles;
    pub const createMessageWithFilePaths = messages_threads_commands_methods.createMessageWithFilePaths;
    pub const getMessage = messages_threads_commands_methods.getMessage;
    pub const listMessages = messages_threads_commands_methods.listMessages;
    pub const listMessagesWithOptions = messages_threads_commands_methods.listMessagesWithOptions;
    pub const bulkDeleteMessages = messages_threads_commands_methods.bulkDeleteMessages;
    pub const triggerTyping = messages_threads_commands_methods.triggerTyping;
    pub const createThread = messages_threads_commands_methods.createThread;
    pub const createForumThread = messages_threads_commands_methods.createForumThread;
    pub const startThreadInForum = messages_threads_commands_methods.startThreadInForum;
    pub const startThreadInMedia = messages_threads_commands_methods.startThreadInMedia;
    pub const listActiveGuildThreads = messages_threads_commands_methods.listActiveGuildThreads;
    pub const joinThread = messages_threads_commands_methods.joinThread;
    pub const leaveThread = messages_threads_commands_methods.leaveThread;
    pub const addThreadMember = messages_threads_commands_methods.addThreadMember;
    pub const getThreadMember = messages_threads_commands_methods.getThreadMember;
    pub const removeThreadMember = messages_threads_commands_methods.removeThreadMember;
    pub const listThreadMembers = messages_threads_commands_methods.listThreadMembers;
    pub const listThreadMembersWithOptions = messages_threads_commands_methods.listThreadMembersWithOptions;
    pub const listPublicArchivedThreads = messages_threads_commands_methods.listPublicArchivedThreads;
    pub const listPrivateArchivedThreads = messages_threads_commands_methods.listPrivateArchivedThreads;
    pub const listJoinedPrivateArchivedThreads = messages_threads_commands_methods.listJoinedPrivateArchivedThreads;
    pub const listPinnedMessages = messages_threads_commands_methods.listPinnedMessages;
    pub const listChannelPins = messages_threads_commands_methods.listChannelPins;
    pub const pinMessage = messages_threads_commands_methods.pinMessage;
    pub const unpinMessage = messages_threads_commands_methods.unpinMessage;
    pub const createThreadFromMessage = messages_threads_commands_methods.createThreadFromMessage;
    pub const addGroupDmRecipient = messages_threads_commands_methods.addGroupDmRecipient;
    pub const removeGroupDmRecipient = messages_threads_commands_methods.removeGroupDmRecipient;
    pub const listChannelInvites = messages_threads_commands_methods.listChannelInvites;
    pub const createChannelInvite = messages_threads_commands_methods.createChannelInvite;
    pub const listChannelWebhooks = messages_threads_commands_methods.listChannelWebhooks;
    pub const createWebhook = messages_threads_commands_methods.createWebhook;
    pub const listGuildWebhooks = messages_threads_commands_methods.listGuildWebhooks;
    pub const getWebhook = messages_threads_commands_methods.getWebhook;
    pub const editWebhook = messages_threads_commands_methods.editWebhook;
    pub const deleteWebhook = messages_threads_commands_methods.deleteWebhook;
    pub const getWebhookWithToken = messages_threads_commands_methods.getWebhookWithToken;
    pub const editWebhookWithToken = messages_threads_commands_methods.editWebhookWithToken;
    pub const deleteWebhookWithToken = messages_threads_commands_methods.deleteWebhookWithToken;
    pub const executeWebhook = messages_threads_commands_methods.executeWebhook;
    pub const executeWebhookWithOptions = messages_threads_commands_methods.executeWebhookWithOptions;
    pub const executeWebhookWithFiles = messages_threads_commands_methods.executeWebhookWithFiles;
    pub const executeWebhookWithOptionsAndFiles = messages_threads_commands_methods.executeWebhookWithOptionsAndFiles;
    pub const getWebhookMessage = messages_threads_commands_methods.getWebhookMessage;
    pub const editWebhookMessage = messages_threads_commands_methods.editWebhookMessage;
    pub const deleteWebhookMessage = messages_threads_commands_methods.deleteWebhookMessage;
    pub const listGuildInvites = messages_threads_commands_methods.listGuildInvites;
    pub const getInvite = messages_threads_commands_methods.getInvite;
    pub const getInviteWithOptions = messages_threads_commands_methods.getInviteWithOptions;
    pub const deleteInvite = messages_threads_commands_methods.deleteInvite;
    pub const getInviteTargetUsers = messages_threads_commands_methods.getInviteTargetUsers;
    pub const updateInviteTargetUsers = messages_threads_commands_methods.updateInviteTargetUsers;
    pub const getInviteTargetUsersJobStatus = messages_threads_commands_methods.getInviteTargetUsersJobStatus;
    pub const deleteMessage = messages_threads_commands_methods.deleteMessage;
    pub const editMessage = messages_threads_commands_methods.editMessage;
    pub const crosspostMessage = messages_threads_commands_methods.crosspostMessage;
    pub const createReaction = messages_threads_commands_methods.createReaction;
    pub const deleteOwnReaction = messages_threads_commands_methods.deleteOwnReaction;
    pub const deleteUserReaction = messages_threads_commands_methods.deleteUserReaction;
    pub const listReactions = messages_threads_commands_methods.listReactions;
    pub const deleteAllReactions = messages_threads_commands_methods.deleteAllReactions;
    pub const deleteAllReactionsForEmoji = messages_threads_commands_methods.deleteAllReactionsForEmoji;
    pub const listPollAnswerVoters = messages_threads_commands_methods.listPollAnswerVoters;
    pub const endPoll = messages_threads_commands_methods.endPoll;
    pub const listGlobalApplicationCommands = messages_threads_commands_methods.listGlobalApplicationCommands;
    pub const createGlobalApplicationCommand = commands_interactions_request_methods.createGlobalApplicationCommand;
    pub const bulkOverwriteGlobalApplicationCommands = commands_interactions_request_methods.bulkOverwriteGlobalApplicationCommands;
    pub const getGlobalApplicationCommand = commands_interactions_request_methods.getGlobalApplicationCommand;
    pub const editGlobalApplicationCommand = commands_interactions_request_methods.editGlobalApplicationCommand;
    pub const deleteGlobalApplicationCommand = commands_interactions_request_methods.deleteGlobalApplicationCommand;
    pub const listGuildApplicationCommands = commands_interactions_request_methods.listGuildApplicationCommands;
    pub const createGuildApplicationCommand = commands_interactions_request_methods.createGuildApplicationCommand;
    pub const bulkOverwriteGuildApplicationCommands = commands_interactions_request_methods.bulkOverwriteGuildApplicationCommands;
    pub const getGuildApplicationCommand = commands_interactions_request_methods.getGuildApplicationCommand;
    pub const editGuildApplicationCommand = commands_interactions_request_methods.editGuildApplicationCommand;
    pub const deleteGuildApplicationCommand = commands_interactions_request_methods.deleteGuildApplicationCommand;
    pub const listGuildApplicationCommandPermissions = commands_interactions_request_methods.listGuildApplicationCommandPermissions;
    pub const getApplicationCommandPermissions = commands_interactions_request_methods.getApplicationCommandPermissions;
    pub const editApplicationCommandPermissions = commands_interactions_request_methods.editApplicationCommandPermissions;
    pub const createInteractionResponse = commands_interactions_request_methods.createInteractionResponse;
    pub const getOriginalInteractionResponse = commands_interactions_request_methods.getOriginalInteractionResponse;
    pub const editOriginalInteractionResponse = commands_interactions_request_methods.editOriginalInteractionResponse;
    pub const deleteOriginalInteractionResponse = commands_interactions_request_methods.deleteOriginalInteractionResponse;
    pub const createFollowupMessage = commands_interactions_request_methods.createFollowupMessage;
    pub const getFollowupMessage = commands_interactions_request_methods.getFollowupMessage;
    pub const editFollowupMessage = commands_interactions_request_methods.editFollowupMessage;
    pub const deleteFollowupMessage = commands_interactions_request_methods.deleteFollowupMessage;
    pub const requestJson = commands_interactions_request_methods.requestJson;
    pub const requestJsonWithToken = commands_interactions_request_methods.requestJsonWithToken;
    pub const requestFormWithToken = commands_interactions_request_methods.requestFormWithToken;
    pub const requestMultipart = commands_interactions_request_methods.requestMultipart;
    pub const requestWebhookMultipartWithToken = commands_interactions_request_methods.requestWebhookMultipartWithToken;
    pub const requestMultipartFilePaths = commands_interactions_request_methods.requestMultipartFilePaths;
    pub const requestGuildStickerMultipart = commands_interactions_request_methods.requestGuildStickerMultipart;
    pub const requestInviteTargetUsersMultipart = commands_interactions_request_methods.requestInviteTargetUsersMultipart;
    pub const request = commands_interactions_request_methods.request;
    pub const requestWithToken = commands_interactions_request_methods.requestWithToken;
    pub const requestStream = commands_interactions_request_methods.requestStream;
    pub const finishRequest = commands_interactions_request_methods.finishRequest;
};

const MultipartFilePathStream = struct {
    allocator: std.mem.Allocator,
    boundary: []const u8,
    payload: Types.CreateMessage,
    files: []const Types.UploadFilePath,
    file_sizes: []u64,
    content_length: u64,

    fn init(
        allocator: std.mem.Allocator,
        boundary: []const u8,
        payload: Types.CreateMessage,
        files: []const Types.UploadFilePath,
    ) !MultipartFilePathStream {
        const file_sizes = try allocator.alloc(u64, files.len);
        errdefer allocator.free(file_sizes);

        var stream = MultipartFilePathStream{
            .allocator = allocator,
            .boundary = boundary,
            .payload = payload,
            .files = files,
            .file_sizes = file_sizes,
            .content_length = 0,
        };

        const io = std.Io.Threaded.global_single_threaded.io();
        for (files, 0..) |file, index| {
            const opened = try std.Io.Dir.cwd().openFile(io, file.path, .{});
            defer opened.close(io);
            const stat = try opened.stat(io);
            file_sizes[index] = stat.size;
        }

        stream.content_length = try stream.computeContentLength();
        return stream;
    }

    fn deinit(self: *MultipartFilePathStream) void {
        self.allocator.free(self.file_sizes);
    }

    fn bodyStream(self: *MultipartFilePathStream) BodyStream {
        return .{
            .ptr = self,
            .content_length = self.content_length,
            .writeFn = writeBody,
        };
    }

    fn writeBody(ptr: *anyopaque, writer: *std.Io.Writer) !void {
        const self: *MultipartFilePathStream = @ptrCast(@alignCast(ptr));
        try writeMessageMultipartFilePaths(self.boundary, self.payload, self.files, writer);
    }

    fn computeContentLength(self: *MultipartFilePathStream) !u64 {
        var metadata = std.Io.Writer.Allocating.init(self.allocator);
        defer metadata.deinit();

        try writeMessageMultipartFilePathMetadata(
            self.boundary,
            self.payload,
            self.files,
            self.file_sizes,
            &metadata.writer,
        );

        var total: u64 = metadata.written().len;
        for (self.file_sizes) |size| total += size;
        return total;
    }
};

pub fn writeMessageMultipart(
    boundary: []const u8,
    payload: Types.CreateMessage,
    files: []const Types.UploadFile,
    writer: anytype,
) !void {
    try writer.print("--{s}\r\n", .{boundary});
    try writer.writeAll("Content-Disposition: form-data; name=\"payload_json\"\r\n");
    try writer.writeAll("Content-Type: application/json\r\n\r\n");
    try Types.writeCreateMessageJsonWithAttachments(payload, files, writer);
    try writer.writeAll("\r\n");

    for (files, 0..) |file, index| {
        try writer.print("--{s}\r\n", .{boundary});
        try writer.print("Content-Disposition: form-data; name=\"files[{d}]\"; filename=\"", .{index});
        try writeMultipartQuoted(file.filename, writer);
        try writer.writeAll("\"\r\n");
        try writer.print("Content-Type: {s}\r\n\r\n", .{file.content_type});
        try writer.writeAll(file.content);
        try writer.writeAll("\r\n");
    }

    try writer.print("--{s}--\r\n", .{boundary});
}

pub fn writeExecuteWebhookMultipart(
    boundary: []const u8,
    payload: Types.ExecuteWebhook,
    files: []const Types.UploadFile,
    writer: anytype,
) !void {
    try writer.print("--{s}\r\n", .{boundary});
    try writer.writeAll("Content-Disposition: form-data; name=\"payload_json\"\r\n");
    try writer.writeAll("Content-Type: application/json\r\n\r\n");
    try Types.writeExecuteWebhookJsonWithAttachments(payload, files, writer);
    try writer.writeAll("\r\n");

    for (files, 0..) |file, index| {
        try writer.print("--{s}\r\n", .{boundary});
        try writer.print("Content-Disposition: form-data; name=\"files[{d}]\"; filename=\"", .{index});
        try writeMultipartQuoted(file.filename, writer);
        try writer.writeAll("\"\r\n");
        try writer.print("Content-Type: {s}\r\n\r\n", .{file.content_type});
        try writer.writeAll(file.content);
        try writer.writeAll("\r\n");
    }

    try writer.print("--{s}--\r\n", .{boundary});
}

pub fn writeGuildStickerMultipart(
    boundary: []const u8,
    payload: Types.CreateGuildSticker,
    file: Types.UploadFile,
    writer: anytype,
) !void {
    try writeMultipartTextField(boundary, "name", payload.name, writer);
    if (payload.description) |description| {
        try writeMultipartTextField(boundary, "description", description, writer);
    }
    try writeMultipartTextField(boundary, "tags", payload.tags, writer);

    try writer.print("--{s}\r\n", .{boundary});
    try writer.writeAll("Content-Disposition: form-data; name=\"file\"; filename=\"");
    try writeMultipartQuoted(file.filename, writer);
    try writer.writeAll("\"\r\n");
    try writer.print("Content-Type: {s}\r\n\r\n", .{file.content_type});
    try writer.writeAll(file.content);
    try writer.writeAll("\r\n");

    try writer.print("--{s}--\r\n", .{boundary});
}

pub fn writeInviteTargetUsersMultipart(
    boundary: []const u8,
    file: Types.UploadFile,
    writer: anytype,
) !void {
    try writer.print("--{s}\r\n", .{boundary});
    try writer.writeAll("Content-Disposition: form-data; name=\"target_users_file\"; filename=\"");
    try writeMultipartQuoted(file.filename, writer);
    try writer.writeAll("\"\r\n");
    try writer.print("Content-Type: {s}\r\n\r\n", .{file.content_type});
    try writer.writeAll(file.content);
    try writer.writeAll("\r\n");

    try writer.print("--{s}--\r\n", .{boundary});
}

pub fn writeMessageMultipartFilePaths(
    boundary: []const u8,
    payload: Types.CreateMessage,
    files: []const Types.UploadFilePath,
    writer: *std.Io.Writer,
) !void {
    try writeMultipartPayloadJson(boundary, payload, files, writer);

    const io = std.Io.Threaded.global_single_threaded.io();
    for (files, 0..) |file, index| {
        try writeMultipartFileHeader(boundary, index, file.filename, file.content_type, writer);
        const opened = try std.Io.Dir.cwd().openFile(io, file.path, .{});
        defer opened.close(io);

        var buffer: [8192]u8 = .{0} ** 8192;
        var reader = opened.readerStreaming(io, &buffer);
        _ = try reader.interface.streamRemaining(writer);
        try writer.writeAll("\r\n");
    }

    try writer.print("--{s}--\r\n", .{boundary});
}

fn writeMessageMultipartFilePathMetadata(
    boundary: []const u8,
    payload: Types.CreateMessage,
    files: []const Types.UploadFilePath,
    file_sizes: []const u64,
    writer: *std.Io.Writer,
) !void {
    try writeMultipartPayloadJson(boundary, payload, files, writer);
    for (files, 0..) |file, index| {
        _ = file_sizes[index];
        try writeMultipartFileHeader(boundary, index, file.filename, file.content_type, writer);
        try writer.writeAll("\r\n");
    }
    try writer.print("--{s}--\r\n", .{boundary});
}

fn writeMultipartPayloadJson(
    boundary: []const u8,
    payload: Types.CreateMessage,
    files: anytype,
    writer: anytype,
) !void {
    try writer.print("--{s}\r\n", .{boundary});
    try writer.writeAll("Content-Disposition: form-data; name=\"payload_json\"\r\n");
    try writer.writeAll("Content-Type: application/json\r\n\r\n");
    try Types.writeCreateMessageJsonWithAttachmentMetadata(payload, files, writer);
    try writer.writeAll("\r\n");
}

fn writeMultipartTextField(boundary: []const u8, name: []const u8, value: []const u8, writer: anytype) !void {
    try writer.print("--{s}\r\n", .{boundary});
    try writer.writeAll("Content-Disposition: form-data; name=\"");
    try writeMultipartQuoted(name, writer);
    try writer.writeAll("\"\r\n\r\n");
    try writer.writeAll(value);
    try writer.writeAll("\r\n");
}

fn writeMultipartFileHeader(
    boundary: []const u8,
    index: usize,
    filename: []const u8,
    content_type: []const u8,
    writer: anytype,
) !void {
    try writer.print("--{s}\r\n", .{boundary});
    try writer.print("Content-Disposition: form-data; name=\"files[{d}]\"; filename=\"", .{index});
    try writeMultipartQuoted(filename, writer);
    try writer.writeAll("\"\r\n");
    try writer.print("Content-Type: {s}\r\n\r\n", .{content_type});
}

fn writeMultipartQuoted(value: []const u8, writer: anytype) !void {
    for (value) |byte| {
        switch (byte) {
            '"' => try writer.writeAll("\\\""),
            '\\' => try writer.writeAll("\\\\"),
            '\r', '\n' => try writer.writeByte('_'),
            else => try writer.writeByte(byte),
        }
    }
}

pub const MemoryTransport = struct {
    allocator: std.mem.Allocator,
    last_request: ?StoredRequest = null,
    response: Response,

    pub const StoredRequest = struct {
        method: Routes.Method,
        url: []u8,
        token: []u8,
        body: ?[]u8,
        content_type: ?[]u8,

        fn deinit(self: StoredRequest, allocator: std.mem.Allocator) void {
            allocator.free(self.url);
            allocator.free(self.token);
            if (self.body) |body| allocator.free(body);
            if (self.content_type) |content_type| allocator.free(content_type);
        }
    };

    pub fn init(allocator: std.mem.Allocator, response: Response) MemoryTransport {
        return .{ .allocator = allocator, .response = response };
    }

    pub fn deinit(self: *MemoryTransport) void {
        if (self.last_request) |last| last.deinit(self.allocator);
        self.last_request = null;
    }

    pub fn transport(self: *MemoryTransport) Transport {
        return .{ .ptr = self, .sendFn = send };
    }

    fn send(ptr: *anyopaque, allocator: std.mem.Allocator, request: Request) !Response {
        _ = allocator;
        const self: *MemoryTransport = @ptrCast(@alignCast(ptr));
        if (self.last_request) |last| last.deinit(self.allocator);
        const url = try self.allocator.dupe(u8, request.url);
        errdefer self.allocator.free(url);
        const token = try self.allocator.dupe(u8, request.token);
        errdefer self.allocator.free(token);
        const body = if (request.body) |request_body| try self.allocator.dupe(u8, request_body) else null;
        const stream_body = if (request.body_stream) |body_stream| blk: {
            var out = std.Io.Writer.Allocating.init(self.allocator);
            errdefer out.deinit();
            try body_stream.writeTo(&out.writer);
            break :blk try out.toOwnedSlice();
        } else null;
        errdefer {
            if (body) |owned_body| self.allocator.free(owned_body);
            if (stream_body) |owned_body| self.allocator.free(owned_body);
        }
        const content_type = if (request.content_type) |request_content_type| try self.allocator.dupe(u8, request_content_type) else null;
        self.last_request = .{
            .method = request.method,
            .url = url,
            .token = token,
            .body = body orelse stream_body,
            .content_type = content_type,
        };
        return self.response;
    }
};
