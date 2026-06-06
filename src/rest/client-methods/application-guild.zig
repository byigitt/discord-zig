const std = @import("std");
const Routes = @import("../routes.zig");
const Types = @import("../../models/types.zig");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;

const Root = @import("../client.zig");
const Response = Root.Response;
const Transport = Root.Transport;
const RateLimitState = Root.RateLimitState;

pub fn Methods(comptime Client: type) type {
    return struct {
        pub fn init(allocator: std.mem.Allocator, token: []const u8, transport: Transport) Client {
            return .{
                .allocator = allocator,
                .token = token,
                .transport = transport,
                .rate_limits = std.StringHashMap(RateLimitState).init(allocator),
            };
        }

        pub fn deinit(self: *Client) void {
            var it = self.rate_limits.iterator();
            while (it.next()) |entry| {
                self.allocator.free(entry.key_ptr.*);
                entry.value_ptr.deinit(self.allocator);
            }
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
    };
}
