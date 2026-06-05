const std = @import("std");
const Api = @import("../core/api.zig");
const Routes = @import("routes.zig");
const Types = @import("../models/types.zig");
const Interactions = @import("../interactions/mod.zig");
const Snowflake = @import("../core/snowflake.zig").Snowflake;

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

    pub fn init(allocator: std.mem.Allocator, token: []const u8, transport: Transport) Client {
        return .{
            .allocator = allocator,
            .token = token,
            .transport = transport,
            .rate_limits = std.StringHashMap(RateLimitState).init(allocator),
        };
    }

    pub fn deinit(self: *Client) void {
        var it = self.rate_limits.keyIterator();
        while (it.next()) |key| self.allocator.free(key.*);
        self.rate_limits.deinit();
    }

    pub fn createMessage(self: *Client, channel_id: Snowflake, payload: Types.CreateMessage) !Response {
        const route = try Routes.createMessage(self.allocator, channel_id);
        defer route.deinit(self.allocator);

        return self.requestJson(route, payload);
    }

    pub fn getGateway(self: *Client) !Response {
        const route = try Routes.gateway(self.allocator);
        defer route.deinit(self.allocator);
        return self.requestWithToken(route, "", null, null);
    }

    pub fn getGatewayBot(self: *Client) !Response {
        const route = try Routes.gatewayBot(self.allocator);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getCurrentApplication(self: *Client) !Response {
        const route = try Routes.currentApplication(self.allocator);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getCurrentBotApplication(self: *Client) !Response {
        const route = try Routes.currentBotApplication(self.allocator);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn editCurrentApplication(self: *Client, payload: Types.EditCurrentApplication) !Response {
        const route = try Routes.editCurrentApplication(self.allocator);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn listApplicationSkus(self: *Client, application_id: Snowflake) !Response {
        const route = try Routes.applicationSkus(self.allocator, application_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listApplicationRoleConnectionMetadataRecords(self: *Client, application_id: Snowflake) !Response {
        const route = try Routes.applicationRoleConnectionMetadataRecords(self.allocator, application_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn updateApplicationRoleConnectionMetadataRecords(
        self: *Client,
        application_id: Snowflake,
        payload: Types.UpdateApplicationRoleConnectionMetadataRecords,
    ) !Response {
        const route = try Routes.updateApplicationRoleConnectionMetadataRecords(self.allocator, application_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn listApplicationEmojis(self: *Client, application_id: Snowflake) !Response {
        const route = try Routes.applicationEmojis(self.allocator, application_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getApplicationEmoji(self: *Client, application_id: Snowflake, emoji_id: Snowflake) !Response {
        const route = try Routes.applicationEmoji(self.allocator, application_id, emoji_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn createApplicationEmoji(
        self: *Client,
        application_id: Snowflake,
        payload: Types.CreateApplicationEmoji,
    ) !Response {
        const route = try Routes.createApplicationEmoji(self.allocator, application_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn editApplicationEmoji(
        self: *Client,
        application_id: Snowflake,
        emoji_id: Snowflake,
        payload: Types.EditApplicationEmoji,
    ) !Response {
        const route = try Routes.editApplicationEmoji(self.allocator, application_id, emoji_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn deleteApplicationEmoji(self: *Client, application_id: Snowflake, emoji_id: Snowflake) !Response {
        const route = try Routes.deleteApplicationEmoji(self.allocator, application_id, emoji_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getApplicationActivityInstance(
        self: *Client,
        application_id: Snowflake,
        instance_id: []const u8,
    ) !Response {
        const route = try Routes.applicationActivityInstance(self.allocator, application_id, instance_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn createLobby(self: *Client, payload: Types.CreateLobby) !Response {
        const route = try Routes.createLobby(self.allocator);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn getLobby(self: *Client, lobby_id: Snowflake) !Response {
        const route = try Routes.lobby(self.allocator, lobby_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn editLobby(self: *Client, lobby_id: Snowflake, payload: Types.EditLobby) !Response {
        const route = try Routes.editLobby(self.allocator, lobby_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn deleteLobby(self: *Client, lobby_id: Snowflake) !Response {
        const route = try Routes.deleteLobby(self.allocator, lobby_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn addLobbyMember(self: *Client, lobby_id: Snowflake, user_id: Snowflake, payload: Types.UpdateLobbyMember) !Response {
        const route = try Routes.lobbyMember(self.allocator, lobby_id, user_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn bulkUpdateLobbyMembers(self: *Client, lobby_id: Snowflake, payload: Types.BulkUpdateLobbyMembers) !Response {
        const route = try Routes.bulkUpdateLobbyMembers(self.allocator, lobby_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn removeLobbyMember(self: *Client, lobby_id: Snowflake, user_id: Snowflake) !Response {
        const route = try Routes.deleteLobbyMember(self.allocator, lobby_id, user_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn leaveLobby(self: *Client, bearer_token: []const u8, lobby_id: Snowflake) !Response {
        const route = try Routes.leaveLobby(self.allocator, lobby_id);
        defer route.deinit(self.allocator);
        return self.requestWithToken(route, bearer_token, null, null);
    }

    pub fn linkLobbyChannel(self: *Client, bearer_token: []const u8, lobby_id: Snowflake, payload: Types.LinkLobbyChannel) !Response {
        const route = try Routes.linkLobbyChannel(self.allocator, lobby_id);
        defer route.deinit(self.allocator);
        return self.requestJsonWithToken(route, bearer_token, payload);
    }

    pub fn unlinkLobbyChannel(self: *Client, bearer_token: []const u8, lobby_id: Snowflake) !Response {
        return self.linkLobbyChannel(bearer_token, lobby_id, Types.LinkLobbyChannel.unlink());
    }

    pub fn updateLobbyMessageModerationMetadata(
        self: *Client,
        lobby_id: Snowflake,
        message_id: Snowflake,
        payload: Types.UpdateLobbyMessageModerationMetadata,
    ) !Response {
        const route = try Routes.updateLobbyMessageModerationMetadata(self.allocator, lobby_id, message_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn listEntitlements(self: *Client, application_id: Snowflake, options: Types.ListEntitlements) !Response {
        const route = try Routes.applicationEntitlements(self.allocator, application_id, options);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getEntitlement(self: *Client, application_id: Snowflake, entitlement_id: Snowflake) !Response {
        const route = try Routes.applicationEntitlement(self.allocator, application_id, entitlement_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn consumeEntitlement(self: *Client, application_id: Snowflake, entitlement_id: Snowflake) !Response {
        const route = try Routes.consumeEntitlement(self.allocator, application_id, entitlement_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn createTestEntitlement(
        self: *Client,
        application_id: Snowflake,
        payload: Types.CreateTestEntitlement,
    ) !Response {
        const route = try Routes.createTestEntitlement(self.allocator, application_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn deleteTestEntitlement(self: *Client, application_id: Snowflake, entitlement_id: Snowflake) !Response {
        const route = try Routes.deleteTestEntitlement(self.allocator, application_id, entitlement_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listSkuSubscriptions(self: *Client, sku_id: Snowflake, options: Types.ListSkuSubscriptions) !Response {
        const route = try Routes.skuSubscriptions(self.allocator, sku_id, options);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getSkuSubscription(self: *Client, sku_id: Snowflake, subscription_id: Snowflake) !Response {
        const route = try Routes.skuSubscription(self.allocator, sku_id, subscription_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getCurrentUser(self: *Client) !Response {
        const route = try Routes.currentUser(self.allocator);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn editCurrentUser(self: *Client, payload: Types.EditCurrentUser) !Response {
        const route = try Routes.editCurrentUser(self.allocator);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn getUser(self: *Client, user_id: Snowflake) !Response {
        const route = try Routes.user(self.allocator, user_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn createDmChannel(self: *Client, user_id: Snowflake) !Response {
        const route = try Routes.createDmChannel(self.allocator);
        defer route.deinit(self.allocator);
        return self.requestJson(route, Types.CreateDmChannel{ .recipient_id = user_id });
    }

    pub fn listCurrentUserGuilds(self: *Client, options: Types.ListCurrentUserGuilds) !Response {
        const route = try Routes.currentUserGuilds(self.allocator, options);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getCurrentUserGuildMember(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.currentUserGuildMember(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listCurrentUserConnections(self: *Client) !Response {
        const route = try Routes.currentUserConnections(self.allocator);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getCurrentAuthorization(self: *Client, bearer_token: []const u8) !Response {
        const route = try Routes.currentAuthorization(self.allocator);
        defer route.deinit(self.allocator);
        return self.requestWithToken(route, bearer_token, null, null);
    }

    pub fn exchangeOAuth2Token(self: *Client, authorization: []const u8, payload: Types.OAuth2TokenRequest) !Response {
        const route = try Routes.oauth2Token(self.allocator);
        defer route.deinit(self.allocator);
        return self.requestFormWithToken(route, authorization, payload);
    }

    pub fn revokeOAuth2Token(self: *Client, authorization: []const u8, payload: Types.OAuth2TokenRevocation) !Response {
        const route = try Routes.revokeOAuth2Token(self.allocator);
        defer route.deinit(self.allocator);
        return self.requestFormWithToken(route, authorization, payload);
    }

    pub fn getCurrentUserApplicationRoleConnection(
        self: *Client,
        bearer_token: []const u8,
        application_id: Snowflake,
    ) !Response {
        const route = try Routes.currentUserApplicationRoleConnection(self.allocator, application_id);
        defer route.deinit(self.allocator);
        return self.requestWithToken(route, bearer_token, null, null);
    }

    pub fn updateCurrentUserApplicationRoleConnection(
        self: *Client,
        bearer_token: []const u8,
        application_id: Snowflake,
        payload: Types.UpdateApplicationRoleConnection,
    ) !Response {
        const route = try Routes.updateCurrentUserApplicationRoleConnection(self.allocator, application_id);
        defer route.deinit(self.allocator);
        return self.requestJsonWithToken(route, bearer_token, payload);
    }

    pub fn deleteCurrentUserApplicationRoleConnection(
        self: *Client,
        bearer_token: []const u8,
        application_id: Snowflake,
    ) !Response {
        const route = try Routes.deleteCurrentUserApplicationRoleConnection(self.allocator, application_id);
        defer route.deinit(self.allocator);
        return self.requestWithToken(route, bearer_token, null, null);
    }

    pub fn leaveGuild(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.leaveGuild(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getChannel(self: *Client, channel_id: Snowflake) !Response {
        const route = try Routes.channel(self.allocator, channel_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn editChannel(self: *Client, channel_id: Snowflake, payload: Types.EditChannel) !Response {
        const route = try Routes.editChannel(self.allocator, channel_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn deleteChannel(self: *Client, channel_id: Snowflake) !Response {
        const route = try Routes.deleteChannel(self.allocator, channel_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn editChannelPermission(
        self: *Client,
        channel_id: Snowflake,
        overwrite_id: Snowflake,
        payload: Types.EditChannelPermission,
    ) !Response {
        const route = try Routes.editChannelPermission(self.allocator, channel_id, overwrite_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn deleteChannelPermission(self: *Client, channel_id: Snowflake, overwrite_id: Snowflake) !Response {
        const route = try Routes.deleteChannelPermission(self.allocator, channel_id, overwrite_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn setVoiceChannelStatus(self: *Client, channel_id: Snowflake, payload: Types.SetVoiceChannelStatus) !Response {
        const route = try Routes.setVoiceChannelStatus(self.allocator, channel_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn followAnnouncementChannel(
        self: *Client,
        channel_id: Snowflake,
        payload: Types.FollowAnnouncementChannel,
    ) !Response {
        const route = try Routes.followAnnouncementChannel(self.allocator, channel_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn sendSoundboardSound(
        self: *Client,
        channel_id: Snowflake,
        payload: Types.SendSoundboardSound,
    ) !Response {
        const route = try Routes.sendSoundboardSound(self.allocator, channel_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn createStageInstance(self: *Client, payload: Types.CreateStageInstance) !Response {
        const route = try Routes.createStageInstance(self.allocator);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn getStageInstance(self: *Client, channel_id: Snowflake) !Response {
        const route = try Routes.stageInstance(self.allocator, channel_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn editStageInstance(self: *Client, channel_id: Snowflake, payload: Types.EditStageInstance) !Response {
        const route = try Routes.editStageInstance(self.allocator, channel_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn deleteStageInstance(self: *Client, channel_id: Snowflake) !Response {
        const route = try Routes.deleteStageInstance(self.allocator, channel_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listVoiceRegions(self: *Client) !Response {
        const route = try Routes.voiceRegions(self.allocator);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listGuildVoiceRegions(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.guildVoiceRegions(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getCurrentUserVoiceState(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.currentUserVoiceState(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getUserVoiceState(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Response {
        const route = try Routes.userVoiceState(self.allocator, guild_id, user_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn editCurrentUserVoiceState(
        self: *Client,
        guild_id: Snowflake,
        payload: Types.EditCurrentUserVoiceState,
    ) !Response {
        const route = try Routes.editCurrentUserVoiceState(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn editUserVoiceState(
        self: *Client,
        guild_id: Snowflake,
        user_id: Snowflake,
        payload: Types.EditUserVoiceState,
    ) !Response {
        const route = try Routes.editUserVoiceState(self.allocator, guild_id, user_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn createGuild(self: *Client, payload: Types.CreateGuild) !Response {
        const route = try Routes.createGuild(self.allocator);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn getGuild(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.guild(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getGuildWithOptions(self: *Client, guild_id: Snowflake, options: Types.GetGuild) !Response {
        const route = try Routes.guildWithOptions(self.allocator, guild_id, options);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn editGuild(self: *Client, guild_id: Snowflake, payload: Types.EditGuild) !Response {
        const route = try Routes.editGuild(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn deleteGuild(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.deleteGuild(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getGuildPreview(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.guildPreview(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listAutoModerationRules(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.autoModerationRules(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getAutoModerationRule(self: *Client, guild_id: Snowflake, rule_id: Snowflake) !Response {
        const route = try Routes.autoModerationRule(self.allocator, guild_id, rule_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn createAutoModerationRule(
        self: *Client,
        guild_id: Snowflake,
        payload: Types.CreateAutoModerationRule,
    ) !Response {
        const route = try Routes.createAutoModerationRule(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn editAutoModerationRule(
        self: *Client,
        guild_id: Snowflake,
        rule_id: Snowflake,
        payload: Types.EditAutoModerationRule,
    ) !Response {
        const route = try Routes.editAutoModerationRule(self.allocator, guild_id, rule_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn deleteAutoModerationRule(self: *Client, guild_id: Snowflake, rule_id: Snowflake) !Response {
        const route = try Routes.deleteAutoModerationRule(self.allocator, guild_id, rule_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getGuildTemplate(self: *Client, code: []const u8) !Response {
        const route = try Routes.guildTemplate(self.allocator, code);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn createGuildFromTemplate(self: *Client, code: []const u8, payload: Types.CreateGuildFromTemplate) !Response {
        const route = try Routes.createGuildFromTemplate(self.allocator, code);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn listGuildTemplates(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.guildTemplates(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn createGuildTemplate(self: *Client, guild_id: Snowflake, payload: Types.CreateGuildTemplate) !Response {
        const route = try Routes.createGuildTemplate(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn syncGuildTemplate(self: *Client, guild_id: Snowflake, code: []const u8) !Response {
        const route = try Routes.syncGuildTemplate(self.allocator, guild_id, code);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn editGuildTemplate(
        self: *Client,
        guild_id: Snowflake,
        code: []const u8,
        payload: Types.EditGuildTemplate,
    ) !Response {
        const route = try Routes.editGuildTemplate(self.allocator, guild_id, code);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn deleteGuildTemplate(self: *Client, guild_id: Snowflake, code: []const u8) !Response {
        const route = try Routes.deleteGuildTemplate(self.allocator, guild_id, code);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getGuildWidgetSettings(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.guildWidgetSettings(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn editGuildWidgetSettings(
        self: *Client,
        guild_id: Snowflake,
        payload: Types.EditGuildWidgetSettings,
    ) !Response {
        const route = try Routes.editGuildWidgetSettings(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn getGuildWidget(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.guildWidget(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getGuildWidgetImage(self: *Client, guild_id: Snowflake, options: Types.GetGuildWidgetImage) !Response {
        const route = try Routes.guildWidgetImage(self.allocator, guild_id, options);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getGuildWelcomeScreen(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.guildWelcomeScreen(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn editGuildWelcomeScreen(
        self: *Client,
        guild_id: Snowflake,
        payload: Types.EditWelcomeScreen,
    ) !Response {
        const route = try Routes.editGuildWelcomeScreen(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn getGuildOnboarding(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.guildOnboarding(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn editGuildOnboarding(self: *Client, guild_id: Snowflake, payload: Types.EditGuildOnboarding) !Response {
        const route = try Routes.editGuildOnboarding(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn editGuildIncidentActions(
        self: *Client,
        guild_id: Snowflake,
        payload: Types.EditGuildIncidentActions,
    ) !Response {
        const route = try Routes.editGuildIncidentActions(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn getGuildVanityUrl(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.guildVanityUrl(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listGuildScheduledEvents(self: *Client, guild_id: Snowflake, options: Types.ListGuildScheduledEvents) !Response {
        const route = try Routes.guildScheduledEvents(self.allocator, guild_id, options);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn createGuildScheduledEvent(
        self: *Client,
        guild_id: Snowflake,
        payload: Types.CreateGuildScheduledEvent,
    ) !Response {
        const route = try Routes.createGuildScheduledEvent(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn getGuildScheduledEvent(
        self: *Client,
        guild_id: Snowflake,
        event_id: Snowflake,
        options: Types.GetGuildScheduledEvent,
    ) !Response {
        const route = try Routes.guildScheduledEvent(self.allocator, guild_id, event_id, options);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn editGuildScheduledEvent(
        self: *Client,
        guild_id: Snowflake,
        event_id: Snowflake,
        payload: Types.EditGuildScheduledEvent,
    ) !Response {
        const route = try Routes.editGuildScheduledEvent(self.allocator, guild_id, event_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn deleteGuildScheduledEvent(self: *Client, guild_id: Snowflake, event_id: Snowflake) !Response {
        const route = try Routes.deleteGuildScheduledEvent(self.allocator, guild_id, event_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listGuildScheduledEventUsers(
        self: *Client,
        guild_id: Snowflake,
        event_id: Snowflake,
        options: Types.ListGuildScheduledEventUsers,
    ) !Response {
        const route = try Routes.guildScheduledEventUsers(self.allocator, guild_id, event_id, options);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listGuildAuditLog(self: *Client, guild_id: Snowflake, options: Types.ListAuditLog) !Response {
        const route = try Routes.guildAuditLog(self.allocator, guild_id, options);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listGuildIntegrations(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.guildIntegrations(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn deleteGuildIntegration(self: *Client, guild_id: Snowflake, integration_id: Snowflake) !Response {
        const route = try Routes.deleteGuildIntegration(self.allocator, guild_id, integration_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listGuildChannels(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.guildChannels(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn createGuildChannel(self: *Client, guild_id: Snowflake, payload: Types.CreateGuildChannel) !Response {
        const route = try Routes.createGuildChannel(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn editGuildChannelPositions(self: *Client, guild_id: Snowflake, positions: []const Types.GuildChannelPosition) !Response {
        const route = try Routes.editGuildChannelPositions(self.allocator, guild_id);
        defer route.deinit(self.allocator);

        var body = std.Io.Writer.Allocating.init(self.allocator);
        defer body.deinit();
        try Types.writeGuildChannelPositionArray(positions, &body.writer);

        return self.request(route, body.written(), "application/json");
    }

    pub fn listGuildMembers(self: *Client, guild_id: Snowflake, options: Types.ListGuildMembers) !Response {
        const route = try Routes.guildMembers(self.allocator, guild_id, options);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn searchGuildMembers(self: *Client, guild_id: Snowflake, options: Types.SearchGuildMembers) !Response {
        const route = try Routes.searchGuildMembers(self.allocator, guild_id, options);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getGuildMember(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Response {
        const route = try Routes.guildMember(self.allocator, guild_id, user_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn addGuildMember(self: *Client, guild_id: Snowflake, user_id: Snowflake, payload: Types.AddGuildMember) !Response {
        const route = try Routes.addGuildMember(self.allocator, guild_id, user_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn editGuildMember(self: *Client, guild_id: Snowflake, user_id: Snowflake, payload: Types.EditGuildMember) !Response {
        const route = try Routes.editGuildMember(self.allocator, guild_id, user_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn editCurrentGuildMember(self: *Client, guild_id: Snowflake, payload: Types.EditCurrentGuildMember) !Response {
        const route = try Routes.editCurrentGuildMember(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn editCurrentUserNick(self: *Client, guild_id: Snowflake, payload: Types.EditCurrentUserNick) !Response {
        const route = try Routes.editCurrentUserNick(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn removeGuildMember(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Response {
        const route = try Routes.removeGuildMember(self.allocator, guild_id, user_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listGuildBans(self: *Client, guild_id: Snowflake, options: Types.ListGuildBans) !Response {
        const route = try Routes.guildBans(self.allocator, guild_id, options);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getGuildBan(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Response {
        const route = try Routes.guildBan(self.allocator, guild_id, user_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getGuildPruneCount(self: *Client, guild_id: Snowflake, options: Types.GetGuildPruneCount) !Response {
        const route = try Routes.guildPruneCount(self.allocator, guild_id, options);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn beginGuildPrune(self: *Client, guild_id: Snowflake, payload: Types.BeginGuildPrune) !Response {
        const route = try Routes.beginGuildPrune(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn createGuildBan(self: *Client, guild_id: Snowflake, user_id: Snowflake, payload: Types.CreateGuildBan) !Response {
        const route = try Routes.createGuildBan(self.allocator, guild_id, user_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn bulkGuildBan(self: *Client, guild_id: Snowflake, payload: Types.BulkGuildBan) !Response {
        const route = try Routes.bulkGuildBan(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn removeGuildBan(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Response {
        const route = try Routes.removeGuildBan(self.allocator, guild_id, user_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listGuildRoles(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.guildRoles(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getGuildRole(self: *Client, guild_id: Snowflake, role_id: Snowflake) !Response {
        const route = try Routes.guildRole(self.allocator, guild_id, role_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getGuildRoleMemberCounts(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.guildRoleMemberCounts(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn createGuildRole(self: *Client, guild_id: Snowflake, payload: Types.CreateGuildRole) !Response {
        const route = try Routes.createGuildRole(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn editGuildRolePositions(self: *Client, guild_id: Snowflake, positions: []const Types.GuildRolePosition) !Response {
        const route = try Routes.editGuildRolePositions(self.allocator, guild_id);
        defer route.deinit(self.allocator);

        var body = std.Io.Writer.Allocating.init(self.allocator);
        defer body.deinit();
        try Types.writeGuildRolePositionArray(positions, &body.writer);

        return self.request(route, body.written(), "application/json");
    }

    pub fn editGuildRole(self: *Client, guild_id: Snowflake, role_id: Snowflake, payload: Types.EditGuildRole) !Response {
        const route = try Routes.editGuildRole(self.allocator, guild_id, role_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn deleteGuildRole(self: *Client, guild_id: Snowflake, role_id: Snowflake) !Response {
        const route = try Routes.deleteGuildRole(self.allocator, guild_id, role_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listGuildEmojis(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.guildEmojis(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getGuildEmoji(self: *Client, guild_id: Snowflake, emoji_id: Snowflake) !Response {
        const route = try Routes.guildEmoji(self.allocator, guild_id, emoji_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn createGuildEmoji(self: *Client, guild_id: Snowflake, payload: Types.CreateGuildEmoji) !Response {
        const route = try Routes.createGuildEmoji(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn editGuildEmoji(
        self: *Client,
        guild_id: Snowflake,
        emoji_id: Snowflake,
        payload: Types.EditGuildEmoji,
    ) !Response {
        const route = try Routes.editGuildEmoji(self.allocator, guild_id, emoji_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn deleteGuildEmoji(self: *Client, guild_id: Snowflake, emoji_id: Snowflake) !Response {
        const route = try Routes.deleteGuildEmoji(self.allocator, guild_id, emoji_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getSticker(self: *Client, sticker_id: Snowflake) !Response {
        const route = try Routes.sticker(self.allocator, sticker_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listStickerPacks(self: *Client) !Response {
        const route = try Routes.stickerPacks(self.allocator);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listGuildStickers(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.guildStickers(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getGuildSticker(self: *Client, guild_id: Snowflake, sticker_id: Snowflake) !Response {
        const route = try Routes.guildSticker(self.allocator, guild_id, sticker_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn createGuildSticker(
        self: *Client,
        guild_id: Snowflake,
        payload: Types.CreateGuildSticker,
        file: Types.UploadFile,
    ) !Response {
        const route = try Routes.createGuildSticker(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.requestGuildStickerMultipart(route, payload, file);
    }

    pub fn editGuildSticker(
        self: *Client,
        guild_id: Snowflake,
        sticker_id: Snowflake,
        payload: Types.EditGuildSticker,
    ) !Response {
        const route = try Routes.editGuildSticker(self.allocator, guild_id, sticker_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn deleteGuildSticker(self: *Client, guild_id: Snowflake, sticker_id: Snowflake) !Response {
        const route = try Routes.deleteGuildSticker(self.allocator, guild_id, sticker_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listDefaultSoundboardSounds(self: *Client) !Response {
        const route = try Routes.defaultSoundboardSounds(self.allocator);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listGuildSoundboardSounds(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.guildSoundboardSounds(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getGuildSoundboardSound(self: *Client, guild_id: Snowflake, sound_id: Snowflake) !Response {
        const route = try Routes.guildSoundboardSound(self.allocator, guild_id, sound_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn createGuildSoundboardSound(
        self: *Client,
        guild_id: Snowflake,
        payload: Types.CreateGuildSoundboardSound,
    ) !Response {
        const route = try Routes.createGuildSoundboardSound(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn editGuildSoundboardSound(
        self: *Client,
        guild_id: Snowflake,
        sound_id: Snowflake,
        payload: Types.EditGuildSoundboardSound,
    ) !Response {
        const route = try Routes.editGuildSoundboardSound(self.allocator, guild_id, sound_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn deleteGuildSoundboardSound(self: *Client, guild_id: Snowflake, sound_id: Snowflake) !Response {
        const route = try Routes.deleteGuildSoundboardSound(self.allocator, guild_id, sound_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn addGuildMemberRole(self: *Client, guild_id: Snowflake, user_id: Snowflake, role_id: Snowflake) !Response {
        const route = try Routes.addGuildMemberRole(self.allocator, guild_id, user_id, role_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn removeGuildMemberRole(self: *Client, guild_id: Snowflake, user_id: Snowflake, role_id: Snowflake) !Response {
        const route = try Routes.removeGuildMemberRole(self.allocator, guild_id, user_id, role_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn createMessageWithFiles(
        self: *Client,
        channel_id: Snowflake,
        payload: Types.CreateMessage,
        files: []const Types.UploadFile,
    ) !Response {
        const route = try Routes.createMessage(self.allocator, channel_id);
        defer route.deinit(self.allocator);

        return self.requestMultipart(route, payload, files);
    }

    pub fn createMessageWithFilePaths(
        self: *Client,
        channel_id: Snowflake,
        payload: Types.CreateMessage,
        files: []const Types.UploadFilePath,
    ) !Response {
        const route = try Routes.createMessage(self.allocator, channel_id);
        defer route.deinit(self.allocator);

        return self.requestMultipartFilePaths(route, payload, files);
    }

    pub fn getMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Response {
        const route = try Routes.channelMessage(self.allocator, channel_id, message_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listMessages(self: *Client, channel_id: Snowflake) !Response {
        return self.listMessagesWithOptions(channel_id, .{});
    }

    pub fn listMessagesWithOptions(self: *Client, channel_id: Snowflake, options: Types.ListMessages) !Response {
        const route = try Routes.channelMessagesWithOptions(self.allocator, channel_id, options);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn bulkDeleteMessages(self: *Client, channel_id: Snowflake, messages: []const Snowflake) !Response {
        const route = try Routes.bulkDeleteMessages(self.allocator, channel_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, Types.BulkDeleteMessages{ .messages = messages });
    }

    pub fn triggerTyping(self: *Client, channel_id: Snowflake) !Response {
        const route = try Routes.triggerTyping(self.allocator, channel_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn createThread(self: *Client, channel_id: Snowflake, payload: Types.CreateThread) !Response {
        const route = try Routes.createThread(self.allocator, channel_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn createForumThread(self: *Client, channel_id: Snowflake, payload: Types.CreateForumThread) !Response {
        const route = try Routes.createThread(self.allocator, channel_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn startThreadInForum(self: *Client, channel_id: Snowflake, payload: Types.CreateForumThread) !Response {
        return self.createForumThread(channel_id, payload);
    }

    pub fn startThreadInMedia(self: *Client, channel_id: Snowflake, payload: Types.CreateForumThread) !Response {
        return self.createForumThread(channel_id, payload);
    }

    pub fn listActiveGuildThreads(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.activeGuildThreads(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn joinThread(self: *Client, thread_id: Snowflake) !Response {
        const route = try Routes.joinThread(self.allocator, thread_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn leaveThread(self: *Client, thread_id: Snowflake) !Response {
        const route = try Routes.leaveThread(self.allocator, thread_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn addThreadMember(self: *Client, thread_id: Snowflake, user_id: Snowflake) !Response {
        const route = try Routes.addThreadMember(self.allocator, thread_id, user_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getThreadMember(self: *Client, thread_id: Snowflake, user_id: Snowflake) !Response {
        const route = try Routes.getThreadMember(self.allocator, thread_id, user_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn removeThreadMember(self: *Client, thread_id: Snowflake, user_id: Snowflake) !Response {
        const route = try Routes.removeThreadMember(self.allocator, thread_id, user_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listThreadMembers(self: *Client, thread_id: Snowflake) !Response {
        const route = try Routes.threadMembers(self.allocator, thread_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listThreadMembersWithOptions(
        self: *Client,
        thread_id: Snowflake,
        options: Types.ListThreadMembers,
    ) !Response {
        const route = try Routes.threadMembersWithOptions(self.allocator, thread_id, options);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listPublicArchivedThreads(
        self: *Client,
        channel_id: Snowflake,
        options: Types.ListArchivedThreads,
    ) !Response {
        const route = try Routes.publicArchivedThreads(self.allocator, channel_id, options);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listPrivateArchivedThreads(
        self: *Client,
        channel_id: Snowflake,
        options: Types.ListArchivedThreads,
    ) !Response {
        const route = try Routes.privateArchivedThreads(self.allocator, channel_id, options);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listJoinedPrivateArchivedThreads(
        self: *Client,
        channel_id: Snowflake,
        options: Types.ListArchivedThreads,
    ) !Response {
        const route = try Routes.joinedPrivateArchivedThreads(self.allocator, channel_id, options);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listPinnedMessages(self: *Client, channel_id: Snowflake) !Response {
        const route = try Routes.pinnedMessages(self.allocator, channel_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listChannelPins(self: *Client, channel_id: Snowflake, options: Types.ListChannelPins) !Response {
        const route = try Routes.channelPins(self.allocator, channel_id, options);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn pinMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Response {
        const route = try Routes.pinMessage(self.allocator, channel_id, message_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn unpinMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Response {
        const route = try Routes.unpinMessage(self.allocator, channel_id, message_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn createThreadFromMessage(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        payload: Types.CreateThreadFromMessage,
    ) !Response {
        const route = try Routes.createThreadFromMessage(self.allocator, channel_id, message_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn addGroupDmRecipient(
        self: *Client,
        channel_id: Snowflake,
        user_id: Snowflake,
        payload: Types.AddGroupDmRecipient,
    ) !Response {
        const route = try Routes.addGroupDmRecipient(self.allocator, channel_id, user_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn removeGroupDmRecipient(self: *Client, channel_id: Snowflake, user_id: Snowflake) !Response {
        const route = try Routes.removeGroupDmRecipient(self.allocator, channel_id, user_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listChannelInvites(self: *Client, channel_id: Snowflake) !Response {
        const route = try Routes.channelInvites(self.allocator, channel_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn createChannelInvite(self: *Client, channel_id: Snowflake, payload: Types.CreateChannelInvite) !Response {
        const route = try Routes.createChannelInvite(self.allocator, channel_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn listChannelWebhooks(self: *Client, channel_id: Snowflake) !Response {
        const route = try Routes.channelWebhooks(self.allocator, channel_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn createWebhook(self: *Client, channel_id: Snowflake, payload: Types.CreateWebhook) !Response {
        const route = try Routes.createWebhook(self.allocator, channel_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn listGuildWebhooks(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.guildWebhooks(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getWebhook(self: *Client, webhook_id: Snowflake) !Response {
        const route = try Routes.webhook(self.allocator, webhook_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn editWebhook(self: *Client, webhook_id: Snowflake, payload: Types.EditWebhook) !Response {
        const route = try Routes.editWebhook(self.allocator, webhook_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn deleteWebhook(self: *Client, webhook_id: Snowflake) !Response {
        const route = try Routes.deleteWebhook(self.allocator, webhook_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getWebhookWithToken(self: *Client, webhook_id: Snowflake, webhook_token: []const u8) !Response {
        const route = try Routes.webhookWithToken(self.allocator, webhook_id, webhook_token);
        defer route.deinit(self.allocator);
        return self.requestWithToken(route, "", null, null);
    }

    pub fn editWebhookWithToken(
        self: *Client,
        webhook_id: Snowflake,
        webhook_token: []const u8,
        payload: Types.EditWebhookWithToken,
    ) !Response {
        const route = try Routes.editWebhookWithToken(self.allocator, webhook_id, webhook_token);
        defer route.deinit(self.allocator);
        return self.requestJsonWithToken(route, "", payload);
    }

    pub fn deleteWebhookWithToken(self: *Client, webhook_id: Snowflake, webhook_token: []const u8) !Response {
        const route = try Routes.deleteWebhookWithToken(self.allocator, webhook_id, webhook_token);
        defer route.deinit(self.allocator);
        return self.requestWithToken(route, "", null, null);
    }

    pub fn executeWebhook(
        self: *Client,
        webhook_id: Snowflake,
        webhook_token: []const u8,
        payload: Types.ExecuteWebhook,
    ) !Response {
        const route = try Routes.executeWebhook(self.allocator, webhook_id, webhook_token);
        defer route.deinit(self.allocator);
        return self.requestJsonWithToken(route, "", payload);
    }

    pub fn executeWebhookWithOptions(
        self: *Client,
        webhook_id: Snowflake,
        webhook_token: []const u8,
        options: Types.ExecuteWebhookQuery,
        payload: Types.ExecuteWebhook,
    ) !Response {
        const route = try Routes.executeWebhookWithOptions(self.allocator, webhook_id, webhook_token, options);
        defer route.deinit(self.allocator);
        return self.requestJsonWithToken(route, "", payload);
    }

    pub fn executeWebhookWithFiles(
        self: *Client,
        webhook_id: Snowflake,
        webhook_token: []const u8,
        payload: Types.ExecuteWebhook,
        files: []const Types.UploadFile,
    ) !Response {
        const route = try Routes.executeWebhook(self.allocator, webhook_id, webhook_token);
        defer route.deinit(self.allocator);
        return self.requestWebhookMultipartWithToken(route, "", payload, files);
    }

    pub fn executeWebhookWithOptionsAndFiles(
        self: *Client,
        webhook_id: Snowflake,
        webhook_token: []const u8,
        options: Types.ExecuteWebhookQuery,
        payload: Types.ExecuteWebhook,
        files: []const Types.UploadFile,
    ) !Response {
        const route = try Routes.executeWebhookWithOptions(self.allocator, webhook_id, webhook_token, options);
        defer route.deinit(self.allocator);
        return self.requestWebhookMultipartWithToken(route, "", payload, files);
    }

    pub fn getWebhookMessage(
        self: *Client,
        webhook_id: Snowflake,
        webhook_token: []const u8,
        message_id: Snowflake,
    ) !Response {
        const route = try Routes.getWebhookMessage(self.allocator, webhook_id, webhook_token, message_id);
        defer route.deinit(self.allocator);
        return self.requestWithToken(route, "", null, null);
    }

    pub fn editWebhookMessage(
        self: *Client,
        webhook_id: Snowflake,
        webhook_token: []const u8,
        message_id: Snowflake,
        payload: Types.EditMessage,
    ) !Response {
        const route = try Routes.editWebhookMessage(self.allocator, webhook_id, webhook_token, message_id);
        defer route.deinit(self.allocator);
        return self.requestJsonWithToken(route, "", payload);
    }

    pub fn deleteWebhookMessage(
        self: *Client,
        webhook_id: Snowflake,
        webhook_token: []const u8,
        message_id: Snowflake,
    ) !Response {
        const route = try Routes.deleteWebhookMessage(self.allocator, webhook_id, webhook_token, message_id);
        defer route.deinit(self.allocator);
        return self.requestWithToken(route, "", null, null);
    }

    pub fn listGuildInvites(self: *Client, guild_id: Snowflake) !Response {
        const route = try Routes.guildInvites(self.allocator, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getInvite(self: *Client, code: []const u8) !Response {
        const route = try Routes.invite(self.allocator, code);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getInviteWithOptions(self: *Client, code: []const u8, options: Types.GetInvite) !Response {
        const route = try Routes.inviteWithOptions(self.allocator, code, options);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn deleteInvite(self: *Client, code: []const u8) !Response {
        const route = try Routes.deleteInvite(self.allocator, code);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn getInviteTargetUsers(self: *Client, code: []const u8) !Response {
        const route = try Routes.inviteTargetUsers(self.allocator, code);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn updateInviteTargetUsers(self: *Client, code: []const u8, file: Types.UploadFile) !Response {
        const route = try Routes.updateInviteTargetUsers(self.allocator, code);
        defer route.deinit(self.allocator);
        return self.requestInviteTargetUsersMultipart(route, file);
    }

    pub fn getInviteTargetUsersJobStatus(self: *Client, code: []const u8) !Response {
        const route = try Routes.inviteTargetUsersJobStatus(self.allocator, code);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn deleteMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Response {
        const route = try Routes.deleteMessage(self.allocator, channel_id, message_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn editMessage(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        payload: Types.EditMessage,
    ) !Response {
        const route = try Routes.editMessage(self.allocator, channel_id, message_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn crosspostMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Response {
        const route = try Routes.crosspostMessage(self.allocator, channel_id, message_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn createReaction(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        emoji: []const u8,
    ) !Response {
        const route = try Routes.createReaction(self.allocator, channel_id, message_id, emoji);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn deleteOwnReaction(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        emoji: []const u8,
    ) !Response {
        const route = try Routes.deleteOwnReaction(self.allocator, channel_id, message_id, emoji);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn deleteUserReaction(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        emoji: []const u8,
        user_id: Snowflake,
    ) !Response {
        const route = try Routes.deleteUserReaction(self.allocator, channel_id, message_id, emoji, user_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listReactions(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        emoji: []const u8,
        options: Types.ListReactions,
    ) !Response {
        const route = try Routes.listReactions(self.allocator, channel_id, message_id, emoji, options);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn deleteAllReactions(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Response {
        const route = try Routes.deleteAllReactions(self.allocator, channel_id, message_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn deleteAllReactionsForEmoji(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        emoji: []const u8,
    ) !Response {
        const route = try Routes.deleteAllReactionsForEmoji(self.allocator, channel_id, message_id, emoji);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listPollAnswerVoters(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        answer_id: u32,
        options: Types.ListPollAnswerVoters,
    ) !Response {
        const route = try Routes.pollAnswerVoters(self.allocator, channel_id, message_id, answer_id, options);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn endPoll(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Response {
        const route = try Routes.endPoll(self.allocator, channel_id, message_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listGlobalApplicationCommands(self: *Client, application_id: Snowflake) !Response {
        const route = try Routes.globalApplicationCommands(self.allocator, application_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn createGlobalApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        command: Interactions.ApplicationCommand,
    ) !Response {
        const route = try Routes.createGlobalApplicationCommand(self.allocator, application_id);
        defer route.deinit(self.allocator);

        return self.requestJson(route, command);
    }

    pub fn bulkOverwriteGlobalApplicationCommands(
        self: *Client,
        application_id: Snowflake,
        commands: []const Interactions.ApplicationCommand,
    ) !Response {
        const route = try Routes.bulkOverwriteGlobalApplicationCommands(self.allocator, application_id);
        defer route.deinit(self.allocator);

        var body = std.Io.Writer.Allocating.init(self.allocator);
        defer body.deinit();
        try Interactions.writeApplicationCommandArray(commands, &body.writer);

        return self.request(route, body.written(), "application/json");
    }

    pub fn getGlobalApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        command_id: Snowflake,
    ) !Response {
        const route = try Routes.globalApplicationCommand(self.allocator, application_id, command_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn editGlobalApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        command_id: Snowflake,
        command: Interactions.EditApplicationCommand,
    ) !Response {
        const route = try Routes.editGlobalApplicationCommand(self.allocator, application_id, command_id);
        defer route.deinit(self.allocator);

        return self.requestJson(route, command);
    }

    pub fn deleteGlobalApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        command_id: Snowflake,
    ) !Response {
        const route = try Routes.deleteGlobalApplicationCommand(self.allocator, application_id, command_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listGuildApplicationCommands(
        self: *Client,
        application_id: Snowflake,
        guild_id: Snowflake,
    ) !Response {
        const route = try Routes.guildApplicationCommands(self.allocator, application_id, guild_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn createGuildApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        guild_id: Snowflake,
        command: Interactions.ApplicationCommand,
    ) !Response {
        const route = try Routes.createGuildApplicationCommand(self.allocator, application_id, guild_id);
        defer route.deinit(self.allocator);

        return self.requestJson(route, command);
    }

    pub fn bulkOverwriteGuildApplicationCommands(
        self: *Client,
        application_id: Snowflake,
        guild_id: Snowflake,
        commands: []const Interactions.ApplicationCommand,
    ) !Response {
        const route = try Routes.bulkOverwriteGuildApplicationCommands(self.allocator, application_id, guild_id);
        defer route.deinit(self.allocator);

        var body = std.Io.Writer.Allocating.init(self.allocator);
        defer body.deinit();
        try Interactions.writeApplicationCommandArray(commands, &body.writer);

        return self.request(route, body.written(), "application/json");
    }

    pub fn getGuildApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        guild_id: Snowflake,
        command_id: Snowflake,
    ) !Response {
        const route = try Routes.guildApplicationCommand(self.allocator, application_id, guild_id, command_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn editGuildApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        guild_id: Snowflake,
        command_id: Snowflake,
        command: Interactions.EditApplicationCommand,
    ) !Response {
        const route = try Routes.editGuildApplicationCommand(self.allocator, application_id, guild_id, command_id);
        defer route.deinit(self.allocator);

        return self.requestJson(route, command);
    }

    pub fn deleteGuildApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        guild_id: Snowflake,
        command_id: Snowflake,
    ) !Response {
        const route = try Routes.deleteGuildApplicationCommand(self.allocator, application_id, guild_id, command_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn listGuildApplicationCommandPermissions(
        self: *Client,
        bearer_token: []const u8,
        application_id: Snowflake,
        guild_id: Snowflake,
    ) !Response {
        const route = try Routes.guildApplicationCommandPermissions(self.allocator, application_id, guild_id);
        defer route.deinit(self.allocator);
        return self.requestWithToken(route, bearer_token, null, null);
    }

    pub fn getApplicationCommandPermissions(
        self: *Client,
        bearer_token: []const u8,
        application_id: Snowflake,
        guild_id: Snowflake,
        command_id: Snowflake,
    ) !Response {
        const route = try Routes.applicationCommandPermissions(self.allocator, application_id, guild_id, command_id);
        defer route.deinit(self.allocator);
        return self.requestWithToken(route, bearer_token, null, null);
    }

    pub fn editApplicationCommandPermissions(
        self: *Client,
        bearer_token: []const u8,
        application_id: Snowflake,
        guild_id: Snowflake,
        command_id: Snowflake,
        permissions: []const Interactions.ApplicationCommandPermission,
    ) !Response {
        const route = try Routes.editApplicationCommandPermissions(self.allocator, application_id, guild_id, command_id);
        defer route.deinit(self.allocator);

        return self.requestJsonWithToken(
            route,
            bearer_token,
            Interactions.ApplicationCommandPermissionsUpdate{ .permissions = permissions },
        );
    }

    pub fn createInteractionResponse(
        self: *Client,
        interaction_id: Snowflake,
        token: []const u8,
        response_payload: Interactions.InteractionResponse,
    ) !Response {
        const route = try Routes.interactionCallback(self.allocator, interaction_id, token);
        defer route.deinit(self.allocator);

        return self.requestJson(route, response_payload);
    }

    pub fn getOriginalInteractionResponse(
        self: *Client,
        application_id: Snowflake,
        token: []const u8,
    ) !Response {
        const route = try Routes.getOriginalInteractionResponse(self.allocator, application_id, token);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn editOriginalInteractionResponse(
        self: *Client,
        application_id: Snowflake,
        token: []const u8,
        payload: Types.EditMessage,
    ) !Response {
        const route = try Routes.editOriginalInteractionResponse(self.allocator, application_id, token);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn deleteOriginalInteractionResponse(
        self: *Client,
        application_id: Snowflake,
        token: []const u8,
    ) !Response {
        const route = try Routes.deleteOriginalInteractionResponse(self.allocator, application_id, token);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn createFollowupMessage(
        self: *Client,
        application_id: Snowflake,
        token: []const u8,
        payload: Types.ExecuteWebhook,
    ) !Response {
        const route = try Routes.createFollowupMessage(self.allocator, application_id, token);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn getFollowupMessage(
        self: *Client,
        application_id: Snowflake,
        token: []const u8,
        message_id: Snowflake,
    ) !Response {
        const route = try Routes.getFollowupMessage(self.allocator, application_id, token, message_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    pub fn editFollowupMessage(
        self: *Client,
        application_id: Snowflake,
        token: []const u8,
        message_id: Snowflake,
        payload: Types.EditMessage,
    ) !Response {
        const route = try Routes.editFollowupMessage(self.allocator, application_id, token, message_id);
        defer route.deinit(self.allocator);
        return self.requestJson(route, payload);
    }

    pub fn deleteFollowupMessage(
        self: *Client,
        application_id: Snowflake,
        token: []const u8,
        message_id: Snowflake,
    ) !Response {
        const route = try Routes.deleteFollowupMessage(self.allocator, application_id, token, message_id);
        defer route.deinit(self.allocator);
        return self.request(route, null, null);
    }

    fn requestJson(self: *Client, route: Routes.Route, payload: anytype) !Response {
        var body = std.Io.Writer.Allocating.init(self.allocator);
        defer body.deinit();
        try payload.writeJson(&body.writer);

        return self.request(route, body.written(), "application/json");
    }

    fn requestJsonWithToken(
        self: *Client,
        route: Routes.Route,
        token: []const u8,
        payload: anytype,
    ) !Response {
        var body = std.Io.Writer.Allocating.init(self.allocator);
        defer body.deinit();
        try payload.writeJson(&body.writer);

        return self.requestWithToken(route, token, body.written(), "application/json");
    }

    fn requestFormWithToken(
        self: *Client,
        route: Routes.Route,
        token: []const u8,
        payload: anytype,
    ) !Response {
        var body = std.Io.Writer.Allocating.init(self.allocator);
        defer body.deinit();
        try payload.writeForm(&body.writer);

        return self.requestWithToken(route, token, body.written(), "application/x-www-form-urlencoded");
    }

    fn requestMultipart(
        self: *Client,
        route: Routes.Route,
        payload: Types.CreateMessage,
        files: []const Types.UploadFile,
    ) !Response {
        const boundary = "discord-zig-boundary";
        var body = std.Io.Writer.Allocating.init(self.allocator);
        defer body.deinit();

        try writeMessageMultipart(boundary, payload, files, &body.writer);

        const content_type = "multipart/form-data; boundary=" ++ boundary;
        return self.request(route, body.written(), content_type);
    }

    fn requestWebhookMultipartWithToken(
        self: *Client,
        route: Routes.Route,
        token: []const u8,
        payload: Types.ExecuteWebhook,
        files: []const Types.UploadFile,
    ) !Response {
        const boundary = "discord-zig-boundary";
        var body = std.Io.Writer.Allocating.init(self.allocator);
        defer body.deinit();

        try writeExecuteWebhookMultipart(boundary, payload, files, &body.writer);

        const content_type = "multipart/form-data; boundary=" ++ boundary;
        return self.requestWithToken(route, token, body.written(), content_type);
    }

    fn requestMultipartFilePaths(
        self: *Client,
        route: Routes.Route,
        payload: Types.CreateMessage,
        files: []const Types.UploadFilePath,
    ) !Response {
        const boundary = "discord-zig-boundary";
        var stream = try MultipartFilePathStream.init(self.allocator, boundary, payload, files);
        defer stream.deinit();

        const content_type = "multipart/form-data; boundary=" ++ boundary;
        return self.requestStream(route, stream.bodyStream(), content_type);
    }

    fn requestGuildStickerMultipart(
        self: *Client,
        route: Routes.Route,
        payload: Types.CreateGuildSticker,
        file: Types.UploadFile,
    ) !Response {
        const boundary = "discord-zig-boundary";
        var body = std.Io.Writer.Allocating.init(self.allocator);
        defer body.deinit();

        try writeGuildStickerMultipart(boundary, payload, file, &body.writer);

        const content_type = "multipart/form-data; boundary=" ++ boundary;
        return self.request(route, body.written(), content_type);
    }

    fn requestInviteTargetUsersMultipart(
        self: *Client,
        route: Routes.Route,
        file: Types.UploadFile,
    ) !Response {
        const boundary = "discord-zig-boundary";
        var body = std.Io.Writer.Allocating.init(self.allocator);
        defer body.deinit();

        try writeInviteTargetUsersMultipart(boundary, file, &body.writer);

        const content_type = "multipart/form-data; boundary=" ++ boundary;
        return self.request(route, body.written(), content_type);
    }

    pub fn request(
        self: *Client,
        route: Routes.Route,
        body: ?[]const u8,
        content_type: ?[]const u8,
    ) !Response {
        return self.requestWithToken(route, self.token, body, content_type);
    }

    pub fn requestWithToken(
        self: *Client,
        route: Routes.Route,
        token: []const u8,
        body: ?[]const u8,
        content_type: ?[]const u8,
    ) !Response {
        const url = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ Api.base_url, route.path });
        defer self.allocator.free(url);

        const response = try self.transport.send(self.allocator, .{
            .method = route.method,
            .url = url,
            .token = token,
            .body = body,
            .content_type = content_type,
        });

        return self.finishRequest(route, response);
    }

    pub fn requestStream(
        self: *Client,
        route: Routes.Route,
        body_stream: BodyStream,
        content_type: ?[]const u8,
    ) !Response {
        const url = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ Api.base_url, route.path });
        defer self.allocator.free(url);

        const response = try self.transport.send(self.allocator, .{
            .method = route.method,
            .url = url,
            .token = self.token,
            .body_stream = body_stream,
            .content_type = content_type,
        });

        return self.finishRequest(route, response);
    }

    fn finishRequest(self: *Client, route: Routes.Route, response: Response) !Response {
        const key = try Routes.bucketKey(self.allocator, route);
        errdefer self.allocator.free(key);
        var state = self.rate_limits.get(key) orelse RateLimitState{};
        state.updateFromHeaders(response.headers);

        const existing = try self.rate_limits.getOrPut(key);
        if (existing.found_existing) {
            self.allocator.free(key);
            existing.value_ptr.* = state;
        } else {
            existing.value_ptr.* = state;
        }

        return response;
    }
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

test "REST createMessage serializes payload and records rate limit headers" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{\"id\":\"1\"}",
        .headers = &.{
            .{ .name = "X-RateLimit-Remaining", .value = "4" },
            .{ .name = "X-RateLimit-Reset-After", .value = "0.250" },
        },
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    const result = try client.createMessage(Snowflake.init(123), Types.CreateMessage.init("pong"));
    try std.testing.expectEqual(@as(u16, 200), result.status);
    try std.testing.expect(memory.last_request != null);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/123/messages", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"pong\"}", memory.last_request.?.body.?);
}

test "REST createInteractionResponse serializes callback payload" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 204,
        .body = "",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    const result = try client.createInteractionResponse(
        Snowflake.init(99),
        "interaction-token",
        Interactions.InteractionResponse.message("pong"),
    );
    try std.testing.expectEqual(@as(u16, 204), result.status);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/interactions/99/interaction-token/callback",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"type\":4,\"data\":{\"content\":\"pong\"}}",
        memory.last_request.?.body.?,
    );

    const choices = [_]Interactions.CommandChoice{
        Interactions.CommandChoice.string("Public", "public"),
    };
    _ = try client.createInteractionResponse(
        Snowflake.init(99),
        "interaction-token",
        Interactions.InteractionResponse.autocomplete(&choices),
    );
    try std.testing.expectEqualStrings(
        "{\"type\":8,\"data\":{\"choices\":[{\"name\":\"Public\",\"value\":\"public\"}]}}",
        memory.last_request.?.body.?,
    );
}

test "REST interaction webhook helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot token", memory.transport());
    defer client.deinit();

    _ = try client.getOriginalInteractionResponse(Snowflake.init(77), "tok en");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/77/tok%20en/messages/@original",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.editOriginalInteractionResponse(
        Snowflake.init(77),
        "tok en",
        Types.EditMessage.init().withContent("done"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/77/tok%20en/messages/@original",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"content\":\"done\"}", memory.last_request.?.body.?);

    _ = try client.createFollowupMessage(
        Snowflake.init(77),
        "tok en",
        Types.ExecuteWebhook.init("follow up"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/77/tok%20en",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"content\":\"follow up\"}", memory.last_request.?.body.?);

    _ = try client.getFollowupMessage(Snowflake.init(77), "tok en", Snowflake.init(99));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/77/tok%20en/messages/99",
        memory.last_request.?.url,
    );

    _ = try client.editFollowupMessage(
        Snowflake.init(77),
        "tok en",
        Snowflake.init(99),
        Types.EditMessage.init().withContent("updated"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/77/tok%20en/messages/99",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"content\":\"updated\"}", memory.last_request.?.body.?);

    _ = try client.deleteFollowupMessage(Snowflake.init(77), "tok en", Snowflake.init(99));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/77/tok%20en/messages/99",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.deleteOriginalInteractionResponse(Snowflake.init(77), "tok en");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/77/tok%20en/messages/@original",
        memory.last_request.?.url,
    );
}

test "REST get and delete message use expected routes" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.getMessage(Snowflake.init(123), Snowflake.init(456));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/456",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.listMessagesWithOptions(
        Snowflake.init(123),
        Types.ListMessages.afterMessage(Snowflake.init(111)).withLimit(25),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages?after=111&limit=25",
        memory.last_request.?.url,
    );

    const messages = [_]Snowflake{ Snowflake.init(111), Snowflake.init(222) };
    _ = try client.bulkDeleteMessages(Snowflake.init(123), &messages);
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/bulk-delete",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"messages\":[\"111\",\"222\"]}",
        memory.last_request.?.body.?,
    );

    _ = try client.triggerTyping(Snowflake.init(123));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/typing",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.deleteMessage(Snowflake.init(123), Snowflake.init(456));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/456",
        memory.last_request.?.url,
    );
}

test "REST pin message helpers use expected routes" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.listPinnedMessages(Snowflake.init(123));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/pins",
        memory.last_request.?.url,
    );

    _ = try client.listChannelPins(
        Snowflake.init(123),
        Types.ListChannelPins.beforeTimestamp("2026-06-02T10:00:00.000Z").withLimit(25),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/pins?before=2026-06-02T10%3A00%3A00.000Z&limit=25",
        memory.last_request.?.url,
    );

    _ = try client.pinMessage(Snowflake.init(123), Snowflake.init(456));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/pins/456",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.unpinMessage(Snowflake.init(123), Snowflake.init(456));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/pins/456",
        memory.last_request.?.url,
    );
}

test "REST thread creation helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.createThread(
        Snowflake.init(10),
        Types.CreateThread.init("private")
            .withType(.private_thread)
            .invitableState(false),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/threads",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"private\",\"type\":12,\"invitable\":false}",
        memory.last_request.?.body.?,
    );

    _ = try client.createThreadFromMessage(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.CreateThreadFromMessage.init("debug").withAutoArchiveDuration(1440),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/threads",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"debug\",\"auto_archive_duration\":1440}",
        memory.last_request.?.body.?,
    );
}

test "REST guild lifecycle and group DM helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();
    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.createGuild(Types.CreateGuild.init("zig"));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"zig\"}", memory.last_request.?.body.?);

    _ = try client.createGuildFromTemplate("starter pack", Types.CreateGuildFromTemplate.init("templated"));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/templates/starter%20pack",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"name\":\"templated\"}", memory.last_request.?.body.?);

    _ = try client.deleteGuild(Snowflake.init(99));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/99", memory.last_request.?.url);

    _ = try client.addGroupDmRecipient(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.AddGroupDmRecipient.init("oauth").withNick("zig"),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/recipients/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"access_token\":\"oauth\",\"nick\":\"zig\"}", memory.last_request.?.body.?);

    _ = try client.removeGroupDmRecipient(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/recipients/20",
        memory.last_request.?.url,
    );
}

test "REST forum thread helper serializes initial message" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();
    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    const tags = [_]Snowflake{Snowflake.init(55)};
    _ = try client.createForumThread(
        Snowflake.init(10),
        Types.CreateForumThread.init("help", Types.ForumThreadMessage.init("first")).withAppliedTags(&tags),
    );

    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/threads", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"help\",\"message\":{\"content\":\"first\"},\"applied_tags\":[\"55\"]}",
        memory.last_request.?.body.?,
    );
}

test "REST thread member helpers use expected routes" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.joinThread(Snowflake.init(10));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members/@me",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.leaveThread(Snowflake.init(10));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members/@me",
        memory.last_request.?.url,
    );

    _ = try client.addThreadMember(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members/20",
        memory.last_request.?.url,
    );

    _ = try client.getThreadMember(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members/20",
        memory.last_request.?.url,
    );

    _ = try client.removeThreadMember(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members/20",
        memory.last_request.?.url,
    );

    _ = try client.listThreadMembers(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members",
        memory.last_request.?.url,
    );

    _ = try client.listThreadMembersWithOptions(
        Snowflake.init(10),
        Types.ListThreadMembers.init()
            .withMemberExpansion(true)
            .afterMember(Snowflake.init(20))
            .withLimit(100),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members?with_member=true&after=20&limit=100",
        memory.last_request.?.url,
    );

    _ = try client.listActiveGuildThreads(Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/30/threads/active",
        memory.last_request.?.url,
    );

    _ = try client.listPublicArchivedThreads(
        Snowflake.init(10),
        Types.ListArchivedThreads.beforeTimestamp("2026-06-02T10:00:00.000Z").withLimit(25),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/threads/archived/public?before=2026-06-02T10%3A00%3A00.000Z&limit=25",
        memory.last_request.?.url,
    );

    _ = try client.listPrivateArchivedThreads(
        Snowflake.init(10),
        Types.ListArchivedThreads.beforeTimestamp("2026-06-02T10:00:00.000Z").withLimit(25),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/threads/archived/private?before=2026-06-02T10%3A00%3A00.000Z&limit=25",
        memory.last_request.?.url,
    );

    _ = try client.listJoinedPrivateArchivedThreads(
        Snowflake.init(10),
        Types.ListArchivedThreads.beforeTimestamp("2026-06-02T10:00:00.000Z").withLimit(25),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/users/@me/threads/archived/private?before=2026-06-02T10%3A00%3A00.000Z&limit=25",
        memory.last_request.?.url,
    );
}

test "REST invite helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.listChannelInvites(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/invites",
        memory.last_request.?.url,
    );

    _ = try client.createChannelInvite(
        Snowflake.init(10),
        Types.CreateChannelInvite.init()
            .withMaxAge(3600)
            .temporaryState(false)
            .uniqueState(true),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "{\"max_age\":3600,\"temporary\":false,\"unique\":true}",
        memory.last_request.?.body.?,
    );

    _ = try client.listGuildInvites(Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/20/invites",
        memory.last_request.?.url,
    );

    _ = try client.getInvite("abc 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123",
        memory.last_request.?.url,
    );

    _ = try client.getInviteWithOptions(
        "abc 123",
        Types.GetInvite.init()
            .withCounts(true)
            .withScheduledEvent(Snowflake.init(77)),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123?with_counts=true&guild_scheduled_event_id=77",
        memory.last_request.?.url,
    );

    _ = try client.deleteInvite("abc 123");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123",
        memory.last_request.?.url,
    );

    _ = try client.getInviteTargetUsers("abc 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123/target-users",
        memory.last_request.?.url,
    );

    _ = try client.updateInviteTargetUsers(
        "abc 123",
        Types.UploadFile.init("targets.csv", "user_id\n42\n").withContentType("text/csv"),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123/target-users",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "multipart/form-data; boundary=discord-zig-boundary",
        memory.last_request.?.content_type.?,
    );
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "name=\"target_users_file\"; filename=\"targets.csv\"") != null);

    _ = try client.getInviteTargetUsersJobStatus("abc 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123/target-users/job-status",
        memory.last_request.?.url,
    );
}

test "REST webhook helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.listChannelWebhooks(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/webhooks",
        memory.last_request.?.url,
    );

    _ = try client.createWebhook(Snowflake.init(10), Types.CreateWebhook.init("deploys"));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "{\"name\":\"deploys\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.listGuildWebhooks(Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/20/webhooks",
        memory.last_request.?.url,
    );

    _ = try client.getWebhook(Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/30",
        memory.last_request.?.url,
    );

    _ = try client.editWebhook(
        Snowflake.init(30),
        Types.EditWebhook.init()
            .withName("alerts")
            .withChannel(Snowflake.init(40)),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "{\"name\":\"alerts\",\"channel_id\":\"40\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteWebhook(Snowflake.init(30));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/30",
        memory.last_request.?.url,
    );

    _ = try client.getWebhookWithToken(Snowflake.init(30), "tok en");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/30/tok%20en",
        memory.last_request.?.url,
    );

    _ = try client.editWebhookWithToken(
        Snowflake.init(30),
        "tok en",
        Types.EditWebhookWithToken.init().withName("token-alerts"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/30/tok%20en",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"name\":\"token-alerts\"}", memory.last_request.?.body.?);

    _ = try client.deleteWebhookWithToken(Snowflake.init(30), "tok en");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/30/tok%20en",
        memory.last_request.?.url,
    );

    _ = try client.executeWebhook(Snowflake.init(30), "tok en", Types.ExecuteWebhook.init("deploy complete"));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/30/tok%20en",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"content\":\"deploy complete\"}",
        memory.last_request.?.body.?,
    );

    const webhook_files = [_]Types.UploadFile{
        Types.UploadFile.init("deploy.txt", "ok").withContentType("text/plain"),
    };
    _ = try client.executeWebhookWithFiles(
        Snowflake.init(30),
        "tok en",
        Types.ExecuteWebhook.init("deploy with file"),
        &webhook_files,
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/30/tok%20en",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "multipart/form-data; boundary=discord-zig-boundary",
        memory.last_request.?.content_type.?,
    );
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"content\":\"deploy with file\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "name=\"files[0]\"; filename=\"deploy.txt\"") != null);

    _ = try client.getWebhookMessage(Snowflake.init(30), "tok en", Snowflake.init(40));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/30/tok%20en/messages/40",
        memory.last_request.?.url,
    );

    _ = try client.editWebhookMessage(
        Snowflake.init(30),
        "tok en",
        Snowflake.init(40),
        Types.EditMessage.init().withContent("edited"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/30/tok%20en/messages/40",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"content\":\"edited\"}", memory.last_request.?.body.?);

    _ = try client.deleteWebhookMessage(Snowflake.init(30), "tok en", Snowflake.init(40));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/30/tok%20en/messages/40",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);
}

test "REST user guild and channel helpers use expected routes" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.getGateway();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/gateway", memory.last_request.?.url);

    _ = try client.getGatewayBot();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bot test", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/gateway/bot", memory.last_request.?.url);

    _ = try client.getCurrentApplication();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/@me", memory.last_request.?.url);

    _ = try client.getCurrentBotApplication();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bot test", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/oauth2/applications/@me", memory.last_request.?.url);

    _ = try client.editCurrentApplication(Types.EditCurrentApplication.init()
        .withDescription("Fast Zig bot")
        .withTags(&.{ "zig", "bot" })
        .clearIcon());
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"description\":\"Fast Zig bot\",\"icon\":null,\"tags\":[\"zig\",\"bot\"]}",
        memory.last_request.?.body.?,
    );

    _ = try client.listApplicationSkus(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/skus", memory.last_request.?.url);

    _ = try client.listApplicationRoleConnectionMetadataRecords(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/role-connections/metadata",
        memory.last_request.?.url,
    );

    const metadata_records = [_]Types.ApplicationRoleConnectionMetadata{
        Types.ApplicationRoleConnectionMetadata.init(.integer_greater_than_or_equal, "level", "Level", "Player level"),
    };
    _ = try client.updateApplicationRoleConnectionMetadataRecords(
        Snowflake.init(10),
        Types.UpdateApplicationRoleConnectionMetadataRecords.init(&metadata_records),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/role-connections/metadata",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "[{\"type\":2,\"key\":\"level\",\"name\":\"Level\",\"description\":\"Player level\"}]",
        memory.last_request.?.body.?,
    );

    _ = try client.listEntitlements(
        Snowflake.init(10),
        Types.ListEntitlements.init()
            .forUser(Snowflake.init(20))
            .withSkus(&.{Snowflake.init(30)})
            .withLimit(25)
            .excludeDeleted(false),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/entitlements?user_id=20&sku_ids=30&limit=25&exclude_deleted=false",
        memory.last_request.?.url,
    );

    _ = try client.getEntitlement(Snowflake.init(10), Snowflake.init(40));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/entitlements/40", memory.last_request.?.url);

    _ = try client.consumeEntitlement(Snowflake.init(10), Snowflake.init(40));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/entitlements/40/consume", memory.last_request.?.url);
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.createTestEntitlement(
        Snowflake.init(10),
        Types.CreateTestEntitlement.init(Snowflake.init(30), Snowflake.init(50), .user),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/entitlements", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"sku_id\":\"30\",\"owner_id\":\"50\",\"owner_type\":2}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteTestEntitlement(Snowflake.init(10), Snowflake.init(40));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/entitlements/40", memory.last_request.?.url);

    _ = try client.listSkuSubscriptions(
        Snowflake.init(30),
        Types.ListSkuSubscriptions.init()
            .forUser(Snowflake.init(20))
            .withLimit(50),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/skus/30/subscriptions?limit=50&user_id=20",
        memory.last_request.?.url,
    );

    _ = try client.getSkuSubscription(Snowflake.init(30), Snowflake.init(60));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/skus/30/subscriptions/60", memory.last_request.?.url);

    _ = try client.listGuildIntegrations(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/integrations", memory.last_request.?.url);

    _ = try client.deleteGuildIntegration(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/integrations/20", memory.last_request.?.url);

    _ = try client.getCurrentUser();
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);

    _ = try client.editCurrentUser(
        Types.EditCurrentUser.init()
            .withUsername("zigbot")
            .clearBanner(),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"username\":\"zigbot\",\"banner\":null}", memory.last_request.?.body.?);

    _ = try client.createDmChannel(Snowflake.init(40));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/channels", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"recipient_id\":\"40\"}", memory.last_request.?.body.?);

    _ = try client.listCurrentUserGuilds(.{
        .after = Snowflake.init(20),
        .limit = 50,
        .with_counts = true,
    });
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/users/@me/guilds?after=20&limit=50&with_counts=true",
        memory.last_request.?.url,
    );

    _ = try client.getCurrentUserGuildMember(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/guilds/10/member", memory.last_request.?.url);

    _ = try client.listCurrentUserConnections();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/connections", memory.last_request.?.url);

    _ = try client.getCurrentAuthorization("Bearer user-token");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/oauth2/@me", memory.last_request.?.url);

    _ = try client.exchangeOAuth2Token("Basic client-secret", Types.OAuth2TokenRequest.authorizationCode("code value")
        .withRedirectUri("https://example.com/callback"));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Basic client-secret", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/oauth2/token", memory.last_request.?.url);
    try std.testing.expectEqualStrings("application/x-www-form-urlencoded", memory.last_request.?.content_type.?);
    try std.testing.expectEqualStrings(
        "grant_type=authorization_code&code=code%20value&redirect_uri=https%3A%2F%2Fexample.com%2Fcallback",
        memory.last_request.?.body.?,
    );

    _ = try client.revokeOAuth2Token(
        "Basic client-secret",
        Types.OAuth2TokenRevocation.init("refresh token").withTokenTypeHint("refresh_token"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Basic client-secret", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/oauth2/token/revoke", memory.last_request.?.url);
    try std.testing.expectEqualStrings("application/x-www-form-urlencoded", memory.last_request.?.content_type.?);
    try std.testing.expectEqualStrings(
        "token=refresh%20token&token_type_hint=refresh_token",
        memory.last_request.?.body.?,
    );

    _ = try client.getCurrentUserApplicationRoleConnection("Bearer user-token", Snowflake.init(99));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/users/@me/applications/99/role-connection",
        memory.last_request.?.url,
    );

    _ = try client.updateCurrentUserApplicationRoleConnection(
        "Bearer user-token",
        Snowflake.init(99),
        Types.UpdateApplicationRoleConnection.init()
            .withPlatformName("zig league")
            .withMetadata(&.{.{ .key = "level", .value = "42" }}),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "{\"platform_name\":\"zig league\",\"metadata\":{\"level\":\"42\"}}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteCurrentUserApplicationRoleConnection("Bearer user-token", Snowflake.init(99));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/users/@me/applications/99/role-connection",
        memory.last_request.?.url,
    );

    _ = try client.leaveGuild(Snowflake.init(10));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/users/@me/guilds/10",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.getGuild(Snowflake.init(10));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10", memory.last_request.?.url);

    _ = try client.getGuildWithOptions(Snowflake.init(10), Types.GetGuild.init().withCounts(true));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10?with_counts=true",
        memory.last_request.?.url,
    );

    _ = try client.getGuildPreview(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/preview", memory.last_request.?.url);

    _ = try client.editGuild(
        Snowflake.init(10),
        Types.EditGuild.init()
            .withName("zig guild")
            .clearIcon()
            .withSafetyAlertsChannel(Snowflake.init(30)),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"zig guild\",\"icon\":null,\"safety_alerts_channel_id\":\"30\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.listAutoModerationRules(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/auto-moderation/rules",
        memory.last_request.?.url,
    );

    _ = try client.getAutoModerationRule(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/auto-moderation/rules/20",
        memory.last_request.?.url,
    );

    _ = try client.createAutoModerationRule(Snowflake.init(10), Types.CreateAutoModerationRule.init(
        "keyword guard",
        .keyword,
        &.{Types.AutoModerationAction.blockMessage("Please reword that")},
    )
        .withTriggerMetadata(Types.AutoModerationTriggerMetadata.init().withKeywordFilter(&.{"cat*"}))
        .enabledState(true));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/auto-moderation/rules",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"keyword guard\",\"event_type\":1,\"trigger_type\":1,\"trigger_metadata\":{\"keyword_filter\":[\"cat*\"]},\"actions\":[{\"type\":1,\"metadata\":{\"custom_message\":\"Please reword that\"}}],\"enabled\":true}",
        memory.last_request.?.body.?,
    );

    _ = try client.editAutoModerationRule(Snowflake.init(10), Snowflake.init(20), Types.EditAutoModerationRule.init()
        .enabledState(false)
        .withActions(&.{Types.AutoModerationAction.timeout(60)})
        .withExemptChannels(&.{Snowflake.init(30)}));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/auto-moderation/rules/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"actions\":[{\"type\":3,\"metadata\":{\"duration_seconds\":60}}],\"enabled\":false,\"exempt_channels\":[\"30\"]}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteAutoModerationRule(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/auto-moderation/rules/20",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.getGuildTemplate("abc 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/templates/abc%20123", memory.last_request.?.url);

    _ = try client.listGuildTemplates(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/templates", memory.last_request.?.url);

    _ = try client.createGuildTemplate(
        Snowflake.init(10),
        Types.CreateGuildTemplate.init("starter").withDescription("Project starter"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/templates", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"starter\",\"description\":\"Project starter\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.syncGuildTemplate(Snowflake.init(10), "abc 123");
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/templates/abc%20123", memory.last_request.?.url);

    _ = try client.editGuildTemplate(
        Snowflake.init(10),
        "abc 123",
        Types.EditGuildTemplate.init().withDescription("Updated"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/templates/abc%20123", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"description\":\"Updated\"}", memory.last_request.?.body.?);

    _ = try client.deleteGuildTemplate(Snowflake.init(10), "abc 123");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/templates/abc%20123", memory.last_request.?.url);

    _ = try client.getGuildWidgetSettings(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/widget", memory.last_request.?.url);

    _ = try client.editGuildWidgetSettings(
        Snowflake.init(10),
        Types.EditGuildWidgetSettings.init()
            .enabledState(true)
            .withChannel(Snowflake.init(20)),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/widget", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"enabled\":true,\"channel_id\":\"20\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.getGuildWidget(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/widget.json", memory.last_request.?.url);

    _ = try client.getGuildWidgetImage(Snowflake.init(10), Types.GetGuildWidgetImage.init());
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/widget.png", memory.last_request.?.url);

    _ = try client.getGuildWidgetImage(Snowflake.init(10), Types.GetGuildWidgetImage.init().withStyle(.banner3));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/widget.png?style=banner3", memory.last_request.?.url);

    _ = try client.getGuildWelcomeScreen(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/welcome-screen", memory.last_request.?.url);

    const welcome_channels = [_]Types.WelcomeScreenChannel{
        Types.WelcomeScreenChannel.init(Snowflake.init(20), "Read rules")
            .withEmojiName("wave"),
    };
    _ = try client.editGuildWelcomeScreen(
        Snowflake.init(10),
        Types.EditWelcomeScreen.init()
            .enabledState(true)
            .withChannels(&welcome_channels)
            .withDescription("Start here"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/welcome-screen", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"enabled\":true,\"welcome_channels\":[{\"channel_id\":\"20\",\"description\":\"Read rules\",\"emoji_name\":\"wave\"}],\"description\":\"Start here\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.getGuildOnboarding(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/onboarding", memory.last_request.?.url);

    _ = try client.editGuildOnboarding(
        Snowflake.init(10),
        Types.EditGuildOnboarding.init()
            .withDefaultChannels(&.{ Snowflake.init(20), Snowflake.init(21) })
            .enabledState(true)
            .withMode(.onboarding_default),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/onboarding", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"default_channel_ids\":[\"20\",\"21\"],\"enabled\":true,\"mode\":0}",
        memory.last_request.?.body.?,
    );

    _ = try client.editGuildIncidentActions(
        Snowflake.init(10),
        Types.EditGuildIncidentActions.init()
            .disableInvitesUntil("2026-06-03T12:00:00.000Z")
            .clearDmsDisabledUntil(),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/incident-actions", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"invites_disabled_until\":\"2026-06-03T12:00:00.000Z\",\"dms_disabled_until\":null}",
        memory.last_request.?.body.?,
    );

    _ = try client.getGuildVanityUrl(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/vanity-url", memory.last_request.?.url);

    _ = try client.listGuildScheduledEvents(Snowflake.init(10), Types.ListGuildScheduledEvents.init().withUserCount(true));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/scheduled-events?with_user_count=true",
        memory.last_request.?.url,
    );

    _ = try client.createGuildScheduledEvent(
        Snowflake.init(10),
        Types.CreateGuildScheduledEvent.init("Launch", "2026-06-02T10:00:00.000Z", .voice)
            .withChannel(Snowflake.init(40)),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/scheduled-events", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"channel_id\":\"40\",\"name\":\"Launch\",\"privacy_level\":2,\"scheduled_start_time\":\"2026-06-02T10:00:00.000Z\",\"entity_type\":2}",
        memory.last_request.?.body.?,
    );

    _ = try client.getGuildScheduledEvent(Snowflake.init(10), Snowflake.init(20), Types.GetGuildScheduledEvent.init().withUserCount(false));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/scheduled-events/20?with_user_count=false",
        memory.last_request.?.url,
    );

    _ = try client.editGuildScheduledEvent(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.EditGuildScheduledEvent.init()
            .withStatus(.active)
            .clearDescription(),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/scheduled-events/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"description\":null,\"status\":2}", memory.last_request.?.body.?);

    _ = try client.listGuildScheduledEventUsers(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.ListGuildScheduledEventUsers.init()
            .withLimit(25)
            .withMember(true)
            .afterUser(Snowflake.init(30)),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/scheduled-events/20/users?limit=25&with_member=true&after=30",
        memory.last_request.?.url,
    );

    _ = try client.deleteGuildScheduledEvent(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/scheduled-events/20", memory.last_request.?.url);

    _ = try client.listGuildAuditLog(
        Snowflake.init(10),
        Types.ListAuditLog.init()
            .forUser(Snowflake.init(20))
            .withActionType(72)
            .afterEntry(Snowflake.init(30))
            .withLimit(10),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/audit-logs?user_id=20&action_type=72&after=30&limit=10",
        memory.last_request.?.url,
    );

    _ = try client.listGuildAuditLog(Snowflake.init(10), Types.ListAuditLog.init());
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/audit-logs", memory.last_request.?.url);

    _ = try client.listGuildChannels(Snowflake.init(10));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/channels", memory.last_request.?.url);

    _ = try client.getGuildMember(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);

    _ = try client.getChannel(Snowflake.init(30));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/30", memory.last_request.?.url);
}

test "REST channel management helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.createGuildChannel(
        Snowflake.init(10),
        Types.CreateGuildChannel.init("general")
            .withType(.guild_text)
            .withTopic("Project chat"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/channels",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"general\",\"type\":0,\"topic\":\"Project chat\"}",
        memory.last_request.?.body.?,
    );

    const positions = [_]Types.GuildChannelPosition{
        Types.GuildChannelPosition.init(Snowflake.init(20)).withPosition(2),
        Types.GuildChannelPosition.init(Snowflake.init(30)).clearParent(),
    };
    _ = try client.editGuildChannelPositions(Snowflake.init(10), &positions);
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/channels",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "[{\"id\":\"20\",\"position\":2},{\"id\":\"30\",\"parent_id\":null}]",
        memory.last_request.?.body.?,
    );

    _ = try client.editChannel(
        Snowflake.init(20),
        Types.EditChannel.init()
            .withName("renamed")
            .archivedState(false)
            .lockedState(false)
            .invitableState(true)
            .withAppliedTags(&.{Snowflake.init(40)})
            .withFlags(Types.ChannelFlags.require_tag)
            .withAvailableTags(&.{Types.WriteForumTag.init("Help").withEmojiName("❓")})
            .withDefaultReactionEmoji(Types.DefaultReactionEmoji.name("❓"))
            .withDefaultSortOrder(.creation_date)
            .withDefaultForumLayout(.gallery_view),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"renamed\",\"flags\":16,\"available_tags\":[{\"name\":\"Help\",\"emoji_name\":\"❓\"}],\"default_reaction_emoji\":{\"emoji_name\":\"❓\"},\"default_sort_order\":1,\"default_forum_layout\":2,\"archived\":false,\"locked\":false,\"invitable\":true,\"applied_tags\":[\"40\"]}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteChannel(Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/20",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);
}

test "REST channel permission helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 204,
        .body = "",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.editChannelPermission(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.EditChannelPermission.init(.member)
            .withAllow(1024)
            .withDeny(2048),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/permissions/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"type\":1,\"allow\":\"1024\",\"deny\":\"2048\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteChannelPermission(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/permissions/20",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);
}

test "REST channel utility helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.setVoiceChannelStatus(Snowflake.init(10), Types.SetVoiceChannelStatus.init("Focus room"));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/voice-status",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"status\":\"Focus room\"}", memory.last_request.?.body.?);

    _ = try client.followAnnouncementChannel(Snowflake.init(10), Types.FollowAnnouncementChannel.init(Snowflake.init(20)));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/followers",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"webhook_channel_id\":\"20\"}", memory.last_request.?.body.?);

    _ = try client.sendSoundboardSound(
        Snowflake.init(10),
        Types.SendSoundboardSound.init(Snowflake.init(40)).fromGuild(Snowflake.init(50)),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/send-soundboard-sound",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"sound_id\":\"40\",\"source_guild_id\":\"50\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.createStageInstance(
        Types.CreateStageInstance.init(Snowflake.init(30), "Live Q&A").sendStartNotification(true),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/stage-instances", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"channel_id\":\"30\",\"topic\":\"Live Q&A\",\"send_start_notification\":true}",
        memory.last_request.?.body.?,
    );

    _ = try client.getStageInstance(Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/stage-instances/30", memory.last_request.?.url);

    _ = try client.editStageInstance(Snowflake.init(30), Types.EditStageInstance.init().withTopic("Aftershow"));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/stage-instances/30", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"topic\":\"Aftershow\"}", memory.last_request.?.body.?);

    _ = try client.deleteStageInstance(Snowflake.init(30));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/stage-instances/30", memory.last_request.?.url);

    _ = try client.listVoiceRegions();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/voice/regions", memory.last_request.?.url);

    _ = try client.listGuildVoiceRegions(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/regions", memory.last_request.?.url);

    _ = try client.getCurrentUserVoiceState(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/voice-states/@me", memory.last_request.?.url);

    _ = try client.getUserVoiceState(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/voice-states/20", memory.last_request.?.url);

    _ = try client.editCurrentUserVoiceState(
        Snowflake.init(10),
        Types.EditCurrentUserVoiceState.init()
            .withChannel(Snowflake.init(30))
            .clearRequestToSpeak(),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/voice-states/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"channel_id\":\"30\",\"request_to_speak_timestamp\":null}",
        memory.last_request.?.body.?,
    );

    _ = try client.editUserVoiceState(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.EditUserVoiceState.init()
            .withChannel(Snowflake.init(30))
            .suppressState(true),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/voice-states/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"channel_id\":\"30\",\"suppress\":true}",
        memory.last_request.?.body.?,
    );
}

test "REST role management helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.listGuildRoles(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/roles",
        memory.last_request.?.url,
    );

    _ = try client.getGuildRole(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/roles/20",
        memory.last_request.?.url,
    );

    _ = try client.getGuildRoleMemberCounts(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/roles/member-counts",
        memory.last_request.?.url,
    );

    _ = try client.createGuildRole(
        Snowflake.init(10),
        Types.CreateGuildRole.init("moderator")
            .withPermissions(8192)
            .withColors(Types.RoleColors.init(0x5865F2).withSecondary(0xE558F2))
            .withIcon("data:image/png;base64,abc")
            .mentionableState(true),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "{\"name\":\"moderator\",\"permissions\":\"8192\",\"colors\":{\"primary_color\":5793266,\"secondary_color\":15030514,\"tertiary_color\":null},\"icon\":\"data:image/png;base64,abc\",\"mentionable\":true}",
        memory.last_request.?.body.?,
    );

    const positions = [_]Types.GuildRolePosition{
        Types.GuildRolePosition.init(Snowflake.init(20)).withPosition(2),
        Types.GuildRolePosition.init(Snowflake.init(30)).clearPosition(),
    };
    _ = try client.editGuildRolePositions(Snowflake.init(10), &positions);
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/roles",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "[{\"id\":\"20\",\"position\":2},{\"id\":\"30\",\"position\":null}]",
        memory.last_request.?.body.?,
    );

    _ = try client.editGuildRole(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.EditGuildRole.init()
            .withName("helpers")
            .hoisted(false)
            .clearIcon()
            .withUnicodeEmoji("⚡"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/roles/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"helpers\",\"hoist\":false,\"icon\":null,\"unicode_emoji\":\"⚡\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteGuildRole(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/roles/20",
        memory.last_request.?.url,
    );
}

test "REST guild emoji helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.listGuildEmojis(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/emojis",
        memory.last_request.?.url,
    );

    _ = try client.getGuildEmoji(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/emojis/20",
        memory.last_request.?.url,
    );

    const roles = [_]Snowflake{Snowflake.init(30)};
    _ = try client.createGuildEmoji(
        Snowflake.init(10),
        Types.CreateGuildEmoji.init("zig", "data:image/webp;base64,abc").withRoles(&roles),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/emojis",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"zig\",\"image\":\"data:image/webp;base64,abc\",\"roles\":[\"30\"]}",
        memory.last_request.?.body.?,
    );

    _ = try client.editGuildEmoji(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.EditGuildEmoji.init().withName("ziggy").withRoles(&.{}),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/emojis/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"ziggy\",\"roles\":[]}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteGuildEmoji(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/emojis/20",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);
}

test "REST application emoji helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.listApplicationEmojis(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/emojis",
        memory.last_request.?.url,
    );

    _ = try client.getApplicationEmoji(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/emojis/20",
        memory.last_request.?.url,
    );

    _ = try client.createApplicationEmoji(
        Snowflake.init(10),
        Types.CreateApplicationEmoji.init("zig", "data:image/webp;base64,abc"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/emojis",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"zig\",\"image\":\"data:image/webp;base64,abc\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.editApplicationEmoji(Snowflake.init(10), Snowflake.init(20), Types.EditApplicationEmoji.init("ziggy"));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/emojis/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"name\":\"ziggy\"}", memory.last_request.?.body.?);

    _ = try client.deleteApplicationEmoji(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/emojis/20",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.getApplicationActivityInstance(Snowflake.init(10), "abc:def 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/activity-instances/abc%3Adef%20123",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);
}

test "REST lobby helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    const metadata = [_]Types.StringPair{.{ .key = "mode", .value = "duo" }};

    _ = try client.createLobby(Types.CreateLobby.init().withMetadata(&metadata).withIdleTimeout(60));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"metadata\":{\"mode\":\"duo\"},\"idle_timeout_seconds\":60}", memory.last_request.?.body.?);

    _ = try client.getLobby(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10", memory.last_request.?.url);

    _ = try client.editLobby(Snowflake.init(10), Types.EditLobby.init().clearMetadata());
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"metadata\":null}", memory.last_request.?.body.?);

    _ = try client.addLobbyMember(Snowflake.init(10), Snowflake.init(20), Types.UpdateLobbyMember.init().withMetadata(&metadata).withFlags(1));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10/members/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"metadata\":{\"mode\":\"duo\"},\"flags\":1}", memory.last_request.?.body.?);

    const bulk_members = [_]Types.LobbyMember{Types.LobbyMember.init(Snowflake.init(20)).removeState(true)};
    _ = try client.bulkUpdateLobbyMembers(Snowflake.init(10), Types.BulkUpdateLobbyMembers.init(&bulk_members));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10/members/bulk", memory.last_request.?.url);
    try std.testing.expectEqualStrings("[{\"id\":\"20\",\"remove_member\":true}]", memory.last_request.?.body.?);

    _ = try client.removeLobbyMember(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10/members/20", memory.last_request.?.url);

    _ = try client.leaveLobby("Bearer user-token", Snowflake.init(10));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10/members/@me", memory.last_request.?.url);

    _ = try client.linkLobbyChannel("Bearer user-token", Snowflake.init(10), Types.LinkLobbyChannel.init(Snowflake.init(30)));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10/channel-linking", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"channel_id\":\"30\"}", memory.last_request.?.body.?);

    _ = try client.unlinkLobbyChannel("Bearer user-token", Snowflake.init(10));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("{\"channel_id\":null}", memory.last_request.?.body.?);

    const moderation_metadata = [_]Types.StringPair{
        .{ .key = "action", .value = "replace" },
        .{ .key = "replacement", .value = "Be kind" },
    };
    _ = try client.updateLobbyMessageModerationMetadata(
        Snowflake.init(10),
        Snowflake.init(30),
        Types.UpdateLobbyMessageModerationMetadata.init(&moderation_metadata),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bot test", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/lobbies/10/messages/30/moderation-metadata",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"action\":\"replace\",\"replacement\":\"Be kind\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteLobby(Snowflake.init(10));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10", memory.last_request.?.url);
}

test "writeGuildStickerMultipart emits text fields and file" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try writeGuildStickerMultipart(
        "test-boundary",
        Types.CreateGuildSticker.init("zig", "zap").withDescription("Zig mascot"),
        .{ .filename = "zig.png", .content = "PNG", .content_type = "image/png" },
        &out.writer,
    );

    try std.testing.expect(std.mem.indexOf(u8, out.written(), "name=\"name\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "zig\r\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "name=\"description\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "name=\"tags\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "name=\"file\"; filename=\"zig.png\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "Content-Type: image/png") != null);
    try std.testing.expect(std.mem.endsWith(u8, out.written(), "--test-boundary--\r\n"));
}

test "writeInviteTargetUsersMultipart emits csv file field" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try writeInviteTargetUsersMultipart(
        "test-boundary",
        .{ .filename = "targets.csv", .content = "user_id\n42\n", .content_type = "text/csv" },
        &out.writer,
    );

    try std.testing.expect(std.mem.indexOf(u8, out.written(), "--test-boundary\r\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "name=\"target_users_file\"; filename=\"targets.csv\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "Content-Type: text/csv") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "user_id\n42\n") != null);
    try std.testing.expect(std.mem.endsWith(u8, out.written(), "--test-boundary--\r\n"));
}

test "REST guild sticker helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.getSticker(Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/stickers/20",
        memory.last_request.?.url,
    );

    _ = try client.listStickerPacks();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/sticker-packs",
        memory.last_request.?.url,
    );

    _ = try client.listGuildStickers(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/stickers",
        memory.last_request.?.url,
    );

    _ = try client.getGuildSticker(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/stickers/20",
        memory.last_request.?.url,
    );

    _ = try client.createGuildSticker(
        Snowflake.init(10),
        .{ .name = "zig", .description = "Zig mascot", .tags = "zap" },
        .{ .filename = "zig.png", .content = "PNG", .content_type = "image/png" },
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/stickers",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "multipart/form-data; boundary=discord-zig-boundary",
        memory.last_request.?.content_type.?,
    );
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "name=\"file\"; filename=\"zig.png\"") != null);

    _ = try client.editGuildSticker(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.EditGuildSticker.init().withName("ziggy").withTags("spark"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/stickers/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"ziggy\",\"tags\":\"spark\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteGuildSticker(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/stickers/20",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);
}

test "REST soundboard helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.listDefaultSoundboardSounds();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/soundboard-default-sounds",
        memory.last_request.?.url,
    );

    _ = try client.listGuildSoundboardSounds(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/soundboard-sounds",
        memory.last_request.?.url,
    );

    _ = try client.getGuildSoundboardSound(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/soundboard-sounds/20",
        memory.last_request.?.url,
    );

    _ = try client.createGuildSoundboardSound(
        Snowflake.init(10),
        Types.CreateGuildSoundboardSound.init("launch", "data:audio/ogg;base64,T0dH")
            .withVolume(0.5)
            .withEmojiId(Snowflake.init(30)),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/soundboard-sounds",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"launch\",\"sound\":\"data:audio/ogg;base64,T0dH\",\"volume\":0.5,\"emoji_id\":\"30\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.editGuildSoundboardSound(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.EditGuildSoundboardSound.init().withName("ship").clearEmojiName(),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/soundboard-sounds/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"ship\",\"emoji_name\":null}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteGuildSoundboardSound(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/soundboard-sounds/20",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);
}

test "REST member role helpers use expected routes" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 204,
        .body = "",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.addGuildMemberRole(Snowflake.init(10), Snowflake.init(20), Snowflake.init(30));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/members/20/roles/30",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.removeGuildMemberRole(Snowflake.init(10), Snowflake.init(20), Snowflake.init(30));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/members/20/roles/30",
        memory.last_request.?.url,
    );
}

test "REST member moderation helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 204,
        .body = "",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.listGuildMembers(
        Snowflake.init(10),
        Types.ListGuildMembers.init().withLimit(100).afterMember(Snowflake.init(20)),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/members?limit=100&after=20",
        memory.last_request.?.url,
    );

    _ = try client.searchGuildMembers(Snowflake.init(10), Types.SearchGuildMembers.init("baris dev").withLimit(25));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/members/search?query=baris%20dev&limit=25",
        memory.last_request.?.url,
    );

    const roles = [_]Snowflake{Snowflake.init(30)};
    _ = try client.addGuildMember(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.AddGuildMember.init("oauth-access")
            .withNick("helper")
            .withRoles(&roles)
            .muteState(false),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/members/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"access_token\":\"oauth-access\",\"nick\":\"helper\",\"roles\":[\"30\"],\"mute\":false}",
        memory.last_request.?.body.?,
    );

    _ = try client.editGuildMember(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.EditGuildMember.init()
            .withRoles(&roles)
            .muteState(false),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/members/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"roles\":[\"30\"],\"mute\":false}",
        memory.last_request.?.body.?,
    );

    _ = try client.editCurrentGuildMember(
        Snowflake.init(10),
        Types.EditCurrentGuildMember.init()
            .withNick("ziggy")
            .clearAvatar(),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"nick\":\"ziggy\",\"avatar\":null}", memory.last_request.?.body.?);

    _ = try client.editCurrentUserNick(Snowflake.init(10), Types.EditCurrentUserNick.init().clearNick());
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me/nick", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"nick\":null}", memory.last_request.?.body.?);

    _ = try client.removeGuildMember(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/members/20",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.listGuildBans(
        Snowflake.init(10),
        Types.ListGuildBans.init().beforeUser(Snowflake.init(30)).withLimit(25),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/bans?before=30&limit=25",
        memory.last_request.?.url,
    );

    _ = try client.getGuildBan(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/bans/20",
        memory.last_request.?.url,
    );

    _ = try client.getGuildPruneCount(
        Snowflake.init(10),
        Types.GetGuildPruneCount.init()
            .withDays(14)
            .withRoles(&.{ Snowflake.init(30), Snowflake.init(40) }),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/prune?days=14&include_roles=30,40",
        memory.last_request.?.url,
    );

    _ = try client.beginGuildPrune(
        Snowflake.init(10),
        Types.BeginGuildPrune.init()
            .withDays(14)
            .computeCount(false)
            .withRoles(&.{Snowflake.init(30)}),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/prune",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"days\":14,\"compute_prune_count\":false,\"include_roles\":[\"30\"]}",
        memory.last_request.?.body.?,
    );

    _ = try client.createGuildBan(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.CreateGuildBan.init().deleteMessagesFor(60),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/bans/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"delete_message_seconds\":60}",
        memory.last_request.?.body.?,
    );

    const bulk_user_ids = [_]Snowflake{ Snowflake.init(20), Snowflake.init(30) };
    _ = try client.bulkGuildBan(Snowflake.init(10), Types.BulkGuildBan.init(&bulk_user_ids).deleteMessagesFor(120));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/bulk-ban",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"user_ids\":[\"20\",\"30\"],\"delete_message_seconds\":120}",
        memory.last_request.?.body.?,
    );

    _ = try client.removeGuildBan(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/bans/20",
        memory.last_request.?.url,
    );
}

test "REST bulkOverwriteGlobalApplicationCommands serializes command array" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "[]",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.bulkOverwriteGlobalApplicationCommands(Snowflake.init(987), &.{
        Interactions.ApplicationCommand.chatInput("ping", "Replies with pong"),
    });

    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/987/commands",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "[{\"name\":\"ping\",\"description\":\"Replies with pong\",\"type\":1}]",
        memory.last_request.?.body.?,
    );
}

test "REST guild application command helpers use expected routes" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "[]",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.listGuildApplicationCommands(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/guilds/20/commands",
        memory.last_request.?.url,
    );

    _ = try client.createGuildApplicationCommand(
        Snowflake.init(10),
        Snowflake.init(20),
        Interactions.ApplicationCommand.chatInput("ping", "Replies with pong"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "{\"name\":\"ping\",\"description\":\"Replies with pong\",\"type\":1}",
        memory.last_request.?.body.?,
    );

    _ = try client.bulkOverwriteGuildApplicationCommands(Snowflake.init(10), Snowflake.init(20), &.{
        Interactions.ApplicationCommand.chatInput("echo", "Echoes text"),
    });
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "[{\"name\":\"echo\",\"description\":\"Echoes text\",\"type\":1}]",
        memory.last_request.?.body.?,
    );

    _ = try client.getGuildApplicationCommand(Snowflake.init(10), Snowflake.init(20), Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/guilds/20/commands/30",
        memory.last_request.?.url,
    );

    _ = try client.deleteGuildApplicationCommand(Snowflake.init(10), Snowflake.init(20), Snowflake.init(30));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
}

test "REST application command edit helpers serialize patch payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.editGlobalApplicationCommand(
        Snowflake.init(10),
        Snowflake.init(30),
        Interactions.EditApplicationCommand.init().withDescription("Updated description"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/commands/30",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"description\":\"Updated description\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.editGuildApplicationCommand(
        Snowflake.init(10),
        Snowflake.init(20),
        Snowflake.init(30),
        Interactions.EditApplicationCommand.init().withName("echo"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/guilds/20/commands/30",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"echo\"}",
        memory.last_request.?.body.?,
    );
}

test "REST application command permission helpers use bearer token" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot bot-token", memory.transport());
    defer client.deinit();

    _ = try client.listGuildApplicationCommandPermissions(
        "Bearer user-token",
        Snowflake.init(10),
        Snowflake.init(20),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/guilds/20/commands/permissions",
        memory.last_request.?.url,
    );

    _ = try client.getApplicationCommandPermissions(
        "Bearer user-token",
        Snowflake.init(10),
        Snowflake.init(20),
        Snowflake.init(30),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/guilds/20/commands/30/permissions",
        memory.last_request.?.url,
    );

    const permissions = [_]Interactions.ApplicationCommandPermission{
        Interactions.ApplicationCommandPermission.user(Snowflake.init(40), true),
    };
    _ = try client.editApplicationCommandPermissions(
        "Bearer user-token",
        Snowflake.init(10),
        Snowflake.init(20),
        Snowflake.init(30),
        &permissions,
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "{\"permissions\":[{\"id\":\"40\",\"type\":2,\"permission\":true}]}",
        memory.last_request.?.body.?,
    );
}

test "REST editMessage serializes patch payload" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.editMessage(
        Snowflake.init(123),
        Snowflake.init(456),
        Types.EditMessage.init()
            .withContent("edited")
            .withFlags(Types.MessageFlags.suppress_embeds),
    );

    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/456",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"content\":\"edited\",\"flags\":4}", memory.last_request.?.body.?);
}

test "REST reaction routes use expected methods" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 204,
        .body = "",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.createReaction(Snowflake.init(123), Snowflake.init(456), "👍");
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/456/reactions/%F0%9F%91%8D/@me",
        memory.last_request.?.url,
    );

    _ = try client.deleteOwnReaction(Snowflake.init(123), Snowflake.init(456), "👍");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);

    _ = try client.listReactions(
        Snowflake.init(123),
        Snowflake.init(456),
        "👍",
        Types.ListReactions.afterUser(Snowflake.init(99))
            .withLimit(25)
            .withType(.burst),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/456/reactions/%F0%9F%91%8D?after=99&limit=25&type=1",
        memory.last_request.?.url,
    );

    _ = try client.deleteUserReaction(Snowflake.init(123), Snowflake.init(456), "👍", Snowflake.init(789));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/456/reactions/%F0%9F%91%8D/789",
        memory.last_request.?.url,
    );

    _ = try client.deleteAllReactions(Snowflake.init(123), Snowflake.init(456));
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/456/reactions",
        memory.last_request.?.url,
    );

    _ = try client.deleteAllReactionsForEmoji(Snowflake.init(123), Snowflake.init(456), "👍");
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/456/reactions/%F0%9F%91%8D",
        memory.last_request.?.url,
    );
}

test "REST poll routes use expected methods" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.listPollAnswerVoters(
        Snowflake.init(123),
        Snowflake.init(456),
        2,
        Types.ListPollAnswerVoters.afterUser(Snowflake.init(789)).withLimit(25),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/polls/456/answers/2?after=789&limit=25",
        memory.last_request.?.url,
    );

    _ = try client.endPoll(Snowflake.init(123), Snowflake.init(456));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/polls/456/expire",
        memory.last_request.?.url,
    );
}

test "writeMessageMultipart emits payload_json and files" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const files = [_]Types.UploadFile{
        Types.UploadFile.init("hello.txt", "hello").withContentType("text/plain"),
    };

    try writeMessageMultipart("test-boundary", Types.CreateMessage.init("with file"), &files, &out.writer);

    try std.testing.expect(std.mem.indexOf(u8, out.written(), "--test-boundary\r\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "name=\"payload_json\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "\"attachments\":[{\"id\":\"0\",\"filename\":\"hello.txt\"}]") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "name=\"files[0]\"; filename=\"hello.txt\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "Content-Type: text/plain\r\n\r\nhello\r\n") != null);
    try std.testing.expect(std.mem.endsWith(u8, out.written(), "--test-boundary--\r\n"));
}

test "REST createMessageWithFiles sends multipart body" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    const files = [_]Types.UploadFile{
        Types.UploadFile.init("hello.txt", "hello").withContentType("text/plain"),
    };

    _ = try client.createMessageWithFiles(Snowflake.init(123), Types.CreateMessage.init("with file"), &files);

    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "multipart/form-data; boundary=discord-zig-boundary",
        memory.last_request.?.content_type.?,
    );
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "name=\"files[0]\"; filename=\"hello.txt\"") != null);
}

test "REST executeWebhookWithFiles sends multipart body" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    const files = [_]Types.UploadFile{
        Types.UploadFile.init("deploy.txt", "ship").withContentType("text/plain"),
    };

    _ = try client.executeWebhookWithOptionsAndFiles(
        Snowflake.init(123),
        "tok en",
        .{ .wait = true, .thread_id = Snowflake.init(555) },
        Types.ExecuteWebhook.init("with file"),
        &files,
    );

    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/123/tok%20en?wait=true&thread_id=555",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "multipart/form-data; boundary=discord-zig-boundary",
        memory.last_request.?.content_type.?,
    );
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"attachments\":[{\"id\":\"0\",\"filename\":\"deploy.txt\"}]") != null);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "name=\"files[0]\"; filename=\"deploy.txt\"") != null);
}

test "REST createMessageWithFilePaths streams multipart body" {
    const io = std.Io.Threaded.global_single_threaded.io();
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(io, .{ .sub_path = "hello.txt", .data = "hello from disk" });

    var path_buffer: [128]u8 = .{0} ** 128;
    const path = try std.fmt.bufPrint(&path_buffer, ".zig-cache/tmp/{s}/hello.txt", .{tmp.sub_path});

    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    const files = [_]Types.UploadFilePath{
        Types.UploadFilePath.init("hello.txt", path).withContentType("text/plain"),
    };

    _ = try client.createMessageWithFilePaths(Snowflake.init(123), Types.CreateMessage.init("with file"), &files);

    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "multipart/form-data; boundary=discord-zig-boundary",
        memory.last_request.?.content_type.?,
    );
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"attachments\":[{\"id\":\"0\",\"filename\":\"hello.txt\"}]") != null);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "hello from disk\r\n") != null);
}
