const std = @import("std");
const Api = @import("../core/api.zig");
const Routes = @import("routes.zig");
const Types = @import("../models/types.zig");
const Interactions = @import("../interactions/mod.zig");
const Snowflake = @import("../core/snowflake.zig").Snowflake;

const test_part_01 = @import("client_tests/part_01.zig");
const test_part_02 = @import("client_tests/part_02.zig");
const test_part_03 = @import("client_tests/part_03.zig");
const test_part_04 = @import("client_tests/part_04.zig");
const test_part_05 = @import("client_tests/part_05.zig");
const test_part_06 = @import("client_tests/part_06.zig");
const test_part_07 = @import("client_tests/part_07.zig");

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

    const Methods01 = @import("client_methods/part_01.zig").Methods(@This());
    const Methods02 = @import("client_methods/part_02.zig").Methods(@This());
    const Methods03 = @import("client_methods/part_03.zig").Methods(@This());
    const Methods04 = @import("client_methods/part_04.zig").Methods(@This());
    pub const init = Methods01.init;
    pub const deinit = Methods01.deinit;
    pub const createMessage = Methods01.createMessage;
    pub const getGateway = Methods01.getGateway;
    pub const getGatewayBot = Methods01.getGatewayBot;
    pub const getCurrentApplication = Methods01.getCurrentApplication;
    pub const getCurrentBotApplication = Methods01.getCurrentBotApplication;
    pub const editCurrentApplication = Methods01.editCurrentApplication;
    pub const listApplicationSkus = Methods01.listApplicationSkus;
    pub const listApplicationRoleConnectionMetadataRecords = Methods01.listApplicationRoleConnectionMetadataRecords;
    pub const updateApplicationRoleConnectionMetadataRecords = Methods01.updateApplicationRoleConnectionMetadataRecords;
    pub const listApplicationEmojis = Methods01.listApplicationEmojis;
    pub const getApplicationEmoji = Methods01.getApplicationEmoji;
    pub const createApplicationEmoji = Methods01.createApplicationEmoji;
    pub const editApplicationEmoji = Methods01.editApplicationEmoji;
    pub const deleteApplicationEmoji = Methods01.deleteApplicationEmoji;
    pub const getApplicationActivityInstance = Methods01.getApplicationActivityInstance;
    pub const createLobby = Methods01.createLobby;
    pub const getLobby = Methods01.getLobby;
    pub const editLobby = Methods01.editLobby;
    pub const deleteLobby = Methods01.deleteLobby;
    pub const addLobbyMember = Methods01.addLobbyMember;
    pub const bulkUpdateLobbyMembers = Methods01.bulkUpdateLobbyMembers;
    pub const removeLobbyMember = Methods01.removeLobbyMember;
    pub const leaveLobby = Methods01.leaveLobby;
    pub const linkLobbyChannel = Methods01.linkLobbyChannel;
    pub const unlinkLobbyChannel = Methods01.unlinkLobbyChannel;
    pub const updateLobbyMessageModerationMetadata = Methods01.updateLobbyMessageModerationMetadata;
    pub const listEntitlements = Methods01.listEntitlements;
    pub const getEntitlement = Methods01.getEntitlement;
    pub const consumeEntitlement = Methods01.consumeEntitlement;
    pub const createTestEntitlement = Methods01.createTestEntitlement;
    pub const deleteTestEntitlement = Methods01.deleteTestEntitlement;
    pub const listSkuSubscriptions = Methods01.listSkuSubscriptions;
    pub const getSkuSubscription = Methods01.getSkuSubscription;
    pub const getCurrentUser = Methods01.getCurrentUser;
    pub const editCurrentUser = Methods01.editCurrentUser;
    pub const getUser = Methods01.getUser;
    pub const createDmChannel = Methods01.createDmChannel;
    pub const listCurrentUserGuilds = Methods01.listCurrentUserGuilds;
    pub const getCurrentUserGuildMember = Methods01.getCurrentUserGuildMember;
    pub const listCurrentUserConnections = Methods01.listCurrentUserConnections;
    pub const getCurrentAuthorization = Methods01.getCurrentAuthorization;
    pub const exchangeOAuth2Token = Methods01.exchangeOAuth2Token;
    pub const revokeOAuth2Token = Methods01.revokeOAuth2Token;
    pub const getCurrentUserApplicationRoleConnection = Methods01.getCurrentUserApplicationRoleConnection;
    pub const updateCurrentUserApplicationRoleConnection = Methods01.updateCurrentUserApplicationRoleConnection;
    pub const deleteCurrentUserApplicationRoleConnection = Methods01.deleteCurrentUserApplicationRoleConnection;
    pub const leaveGuild = Methods01.leaveGuild;
    pub const getChannel = Methods01.getChannel;
    pub const editChannel = Methods01.editChannel;
    pub const deleteChannel = Methods01.deleteChannel;
    pub const editChannelPermission = Methods01.editChannelPermission;
    pub const deleteChannelPermission = Methods01.deleteChannelPermission;
    pub const setVoiceChannelStatus = Methods01.setVoiceChannelStatus;
    pub const followAnnouncementChannel = Methods01.followAnnouncementChannel;
    pub const sendSoundboardSound = Methods01.sendSoundboardSound;
    pub const createStageInstance = Methods01.createStageInstance;
    pub const getStageInstance = Methods01.getStageInstance;
    pub const editStageInstance = Methods01.editStageInstance;
    pub const deleteStageInstance = Methods01.deleteStageInstance;
    pub const listVoiceRegions = Methods01.listVoiceRegions;
    pub const listGuildVoiceRegions = Methods01.listGuildVoiceRegions;
    pub const getCurrentUserVoiceState = Methods01.getCurrentUserVoiceState;
    pub const getUserVoiceState = Methods01.getUserVoiceState;
    pub const editCurrentUserVoiceState = Methods01.editCurrentUserVoiceState;
    pub const editUserVoiceState = Methods01.editUserVoiceState;
    pub const createGuild = Methods01.createGuild;
    pub const getGuild = Methods01.getGuild;
    pub const getGuildWithOptions = Methods01.getGuildWithOptions;
    pub const editGuild = Methods01.editGuild;
    pub const deleteGuild = Methods01.deleteGuild;
    pub const getGuildPreview = Methods01.getGuildPreview;
    pub const listAutoModerationRules = Methods01.listAutoModerationRules;
    pub const getAutoModerationRule = Methods01.getAutoModerationRule;
    pub const createAutoModerationRule = Methods01.createAutoModerationRule;
    pub const editAutoModerationRule = Methods02.editAutoModerationRule;
    pub const deleteAutoModerationRule = Methods02.deleteAutoModerationRule;
    pub const getGuildTemplate = Methods02.getGuildTemplate;
    pub const createGuildFromTemplate = Methods02.createGuildFromTemplate;
    pub const listGuildTemplates = Methods02.listGuildTemplates;
    pub const createGuildTemplate = Methods02.createGuildTemplate;
    pub const syncGuildTemplate = Methods02.syncGuildTemplate;
    pub const editGuildTemplate = Methods02.editGuildTemplate;
    pub const deleteGuildTemplate = Methods02.deleteGuildTemplate;
    pub const getGuildWidgetSettings = Methods02.getGuildWidgetSettings;
    pub const editGuildWidgetSettings = Methods02.editGuildWidgetSettings;
    pub const getGuildWidget = Methods02.getGuildWidget;
    pub const getGuildWidgetImage = Methods02.getGuildWidgetImage;
    pub const getGuildWelcomeScreen = Methods02.getGuildWelcomeScreen;
    pub const editGuildWelcomeScreen = Methods02.editGuildWelcomeScreen;
    pub const getGuildOnboarding = Methods02.getGuildOnboarding;
    pub const editGuildOnboarding = Methods02.editGuildOnboarding;
    pub const editGuildIncidentActions = Methods02.editGuildIncidentActions;
    pub const getGuildVanityUrl = Methods02.getGuildVanityUrl;
    pub const listGuildScheduledEvents = Methods02.listGuildScheduledEvents;
    pub const createGuildScheduledEvent = Methods02.createGuildScheduledEvent;
    pub const getGuildScheduledEvent = Methods02.getGuildScheduledEvent;
    pub const editGuildScheduledEvent = Methods02.editGuildScheduledEvent;
    pub const deleteGuildScheduledEvent = Methods02.deleteGuildScheduledEvent;
    pub const listGuildScheduledEventUsers = Methods02.listGuildScheduledEventUsers;
    pub const listGuildAuditLog = Methods02.listGuildAuditLog;
    pub const listGuildIntegrations = Methods02.listGuildIntegrations;
    pub const deleteGuildIntegration = Methods02.deleteGuildIntegration;
    pub const listGuildChannels = Methods02.listGuildChannels;
    pub const createGuildChannel = Methods02.createGuildChannel;
    pub const editGuildChannelPositions = Methods02.editGuildChannelPositions;
    pub const listGuildMembers = Methods02.listGuildMembers;
    pub const searchGuildMembers = Methods02.searchGuildMembers;
    pub const getGuildMember = Methods02.getGuildMember;
    pub const addGuildMember = Methods02.addGuildMember;
    pub const editGuildMember = Methods02.editGuildMember;
    pub const editCurrentGuildMember = Methods02.editCurrentGuildMember;
    pub const editCurrentUserNick = Methods02.editCurrentUserNick;
    pub const removeGuildMember = Methods02.removeGuildMember;
    pub const listGuildBans = Methods02.listGuildBans;
    pub const getGuildBan = Methods02.getGuildBan;
    pub const getGuildPruneCount = Methods02.getGuildPruneCount;
    pub const beginGuildPrune = Methods02.beginGuildPrune;
    pub const createGuildBan = Methods02.createGuildBan;
    pub const bulkGuildBan = Methods02.bulkGuildBan;
    pub const removeGuildBan = Methods02.removeGuildBan;
    pub const listGuildRoles = Methods02.listGuildRoles;
    pub const getGuildRole = Methods02.getGuildRole;
    pub const getGuildRoleMemberCounts = Methods02.getGuildRoleMemberCounts;
    pub const createGuildRole = Methods02.createGuildRole;
    pub const editGuildRolePositions = Methods02.editGuildRolePositions;
    pub const editGuildRole = Methods02.editGuildRole;
    pub const deleteGuildRole = Methods02.deleteGuildRole;
    pub const listGuildEmojis = Methods02.listGuildEmojis;
    pub const getGuildEmoji = Methods02.getGuildEmoji;
    pub const createGuildEmoji = Methods02.createGuildEmoji;
    pub const editGuildEmoji = Methods02.editGuildEmoji;
    pub const deleteGuildEmoji = Methods02.deleteGuildEmoji;
    pub const getSticker = Methods02.getSticker;
    pub const listStickerPacks = Methods02.listStickerPacks;
    pub const listGuildStickers = Methods02.listGuildStickers;
    pub const getGuildSticker = Methods02.getGuildSticker;
    pub const createGuildSticker = Methods02.createGuildSticker;
    pub const editGuildSticker = Methods02.editGuildSticker;
    pub const deleteGuildSticker = Methods02.deleteGuildSticker;
    pub const listDefaultSoundboardSounds = Methods02.listDefaultSoundboardSounds;
    pub const listGuildSoundboardSounds = Methods02.listGuildSoundboardSounds;
    pub const getGuildSoundboardSound = Methods02.getGuildSoundboardSound;
    pub const createGuildSoundboardSound = Methods02.createGuildSoundboardSound;
    pub const editGuildSoundboardSound = Methods02.editGuildSoundboardSound;
    pub const deleteGuildSoundboardSound = Methods02.deleteGuildSoundboardSound;
    pub const addGuildMemberRole = Methods02.addGuildMemberRole;
    pub const removeGuildMemberRole = Methods02.removeGuildMemberRole;
    pub const createMessageWithFiles = Methods03.createMessageWithFiles;
    pub const createMessageWithFilePaths = Methods03.createMessageWithFilePaths;
    pub const getMessage = Methods03.getMessage;
    pub const listMessages = Methods03.listMessages;
    pub const listMessagesWithOptions = Methods03.listMessagesWithOptions;
    pub const bulkDeleteMessages = Methods03.bulkDeleteMessages;
    pub const triggerTyping = Methods03.triggerTyping;
    pub const createThread = Methods03.createThread;
    pub const createForumThread = Methods03.createForumThread;
    pub const startThreadInForum = Methods03.startThreadInForum;
    pub const startThreadInMedia = Methods03.startThreadInMedia;
    pub const listActiveGuildThreads = Methods03.listActiveGuildThreads;
    pub const joinThread = Methods03.joinThread;
    pub const leaveThread = Methods03.leaveThread;
    pub const addThreadMember = Methods03.addThreadMember;
    pub const getThreadMember = Methods03.getThreadMember;
    pub const removeThreadMember = Methods03.removeThreadMember;
    pub const listThreadMembers = Methods03.listThreadMembers;
    pub const listThreadMembersWithOptions = Methods03.listThreadMembersWithOptions;
    pub const listPublicArchivedThreads = Methods03.listPublicArchivedThreads;
    pub const listPrivateArchivedThreads = Methods03.listPrivateArchivedThreads;
    pub const listJoinedPrivateArchivedThreads = Methods03.listJoinedPrivateArchivedThreads;
    pub const listPinnedMessages = Methods03.listPinnedMessages;
    pub const listChannelPins = Methods03.listChannelPins;
    pub const pinMessage = Methods03.pinMessage;
    pub const unpinMessage = Methods03.unpinMessage;
    pub const createThreadFromMessage = Methods03.createThreadFromMessage;
    pub const addGroupDmRecipient = Methods03.addGroupDmRecipient;
    pub const removeGroupDmRecipient = Methods03.removeGroupDmRecipient;
    pub const listChannelInvites = Methods03.listChannelInvites;
    pub const createChannelInvite = Methods03.createChannelInvite;
    pub const listChannelWebhooks = Methods03.listChannelWebhooks;
    pub const createWebhook = Methods03.createWebhook;
    pub const listGuildWebhooks = Methods03.listGuildWebhooks;
    pub const getWebhook = Methods03.getWebhook;
    pub const editWebhook = Methods03.editWebhook;
    pub const deleteWebhook = Methods03.deleteWebhook;
    pub const getWebhookWithToken = Methods03.getWebhookWithToken;
    pub const editWebhookWithToken = Methods03.editWebhookWithToken;
    pub const deleteWebhookWithToken = Methods03.deleteWebhookWithToken;
    pub const executeWebhook = Methods03.executeWebhook;
    pub const executeWebhookWithOptions = Methods03.executeWebhookWithOptions;
    pub const executeWebhookWithFiles = Methods03.executeWebhookWithFiles;
    pub const executeWebhookWithOptionsAndFiles = Methods03.executeWebhookWithOptionsAndFiles;
    pub const getWebhookMessage = Methods03.getWebhookMessage;
    pub const editWebhookMessage = Methods03.editWebhookMessage;
    pub const deleteWebhookMessage = Methods03.deleteWebhookMessage;
    pub const listGuildInvites = Methods03.listGuildInvites;
    pub const getInvite = Methods03.getInvite;
    pub const getInviteWithOptions = Methods03.getInviteWithOptions;
    pub const deleteInvite = Methods03.deleteInvite;
    pub const getInviteTargetUsers = Methods03.getInviteTargetUsers;
    pub const updateInviteTargetUsers = Methods03.updateInviteTargetUsers;
    pub const getInviteTargetUsersJobStatus = Methods03.getInviteTargetUsersJobStatus;
    pub const deleteMessage = Methods03.deleteMessage;
    pub const editMessage = Methods03.editMessage;
    pub const crosspostMessage = Methods03.crosspostMessage;
    pub const createReaction = Methods03.createReaction;
    pub const deleteOwnReaction = Methods03.deleteOwnReaction;
    pub const deleteUserReaction = Methods03.deleteUserReaction;
    pub const listReactions = Methods03.listReactions;
    pub const deleteAllReactions = Methods03.deleteAllReactions;
    pub const deleteAllReactionsForEmoji = Methods03.deleteAllReactionsForEmoji;
    pub const listPollAnswerVoters = Methods03.listPollAnswerVoters;
    pub const endPoll = Methods03.endPoll;
    pub const listGlobalApplicationCommands = Methods03.listGlobalApplicationCommands;
    pub const createGlobalApplicationCommand = Methods04.createGlobalApplicationCommand;
    pub const bulkOverwriteGlobalApplicationCommands = Methods04.bulkOverwriteGlobalApplicationCommands;
    pub const getGlobalApplicationCommand = Methods04.getGlobalApplicationCommand;
    pub const editGlobalApplicationCommand = Methods04.editGlobalApplicationCommand;
    pub const deleteGlobalApplicationCommand = Methods04.deleteGlobalApplicationCommand;
    pub const listGuildApplicationCommands = Methods04.listGuildApplicationCommands;
    pub const createGuildApplicationCommand = Methods04.createGuildApplicationCommand;
    pub const bulkOverwriteGuildApplicationCommands = Methods04.bulkOverwriteGuildApplicationCommands;
    pub const getGuildApplicationCommand = Methods04.getGuildApplicationCommand;
    pub const editGuildApplicationCommand = Methods04.editGuildApplicationCommand;
    pub const deleteGuildApplicationCommand = Methods04.deleteGuildApplicationCommand;
    pub const listGuildApplicationCommandPermissions = Methods04.listGuildApplicationCommandPermissions;
    pub const getApplicationCommandPermissions = Methods04.getApplicationCommandPermissions;
    pub const editApplicationCommandPermissions = Methods04.editApplicationCommandPermissions;
    pub const createInteractionResponse = Methods04.createInteractionResponse;
    pub const getOriginalInteractionResponse = Methods04.getOriginalInteractionResponse;
    pub const editOriginalInteractionResponse = Methods04.editOriginalInteractionResponse;
    pub const deleteOriginalInteractionResponse = Methods04.deleteOriginalInteractionResponse;
    pub const createFollowupMessage = Methods04.createFollowupMessage;
    pub const getFollowupMessage = Methods04.getFollowupMessage;
    pub const editFollowupMessage = Methods04.editFollowupMessage;
    pub const deleteFollowupMessage = Methods04.deleteFollowupMessage;
    pub const requestJson = Methods04.requestJson;
    pub const requestJsonWithToken = Methods04.requestJsonWithToken;
    pub const requestFormWithToken = Methods04.requestFormWithToken;
    pub const requestMultipart = Methods04.requestMultipart;
    pub const requestWebhookMultipartWithToken = Methods04.requestWebhookMultipartWithToken;
    pub const requestMultipartFilePaths = Methods04.requestMultipartFilePaths;
    pub const requestGuildStickerMultipart = Methods04.requestGuildStickerMultipart;
    pub const requestInviteTargetUsersMultipart = Methods04.requestInviteTargetUsersMultipart;
    pub const request = Methods04.request;
    pub const requestWithToken = Methods04.requestWithToken;
    pub const requestStream = Methods04.requestStream;
    pub const finishRequest = Methods04.finishRequest;
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
