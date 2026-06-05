const std = @import("std");
const Intents = @import("../../core/intents.zig");
const Rest = @import("../../rest/client.zig");
const HttpTransport = @import("../../rest/http_transport.zig").HttpTransport;
const Events = @import("../../gateway/events.zig");
const Gateway = @import("../../gateway/protocol.zig");
const GatewaySession = @import("../../gateway/session.zig");
const CacheModule = @import("../cache.zig");
const Interactions = @import("../../interactions/mod.zig");
const Cache = CacheModule.Cache;
const Types = @import("../../models/types.zig");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Root = @import("../client.zig");
const ClientOptions = Root.ClientOptions;
const SetActivityOptions = Root.SetActivityOptions;
const GatewayStep = Root.GatewayStep;
const GatewayStartMode = Root.GatewayStartMode;
const ReconnectBackoff = Root.ReconnectBackoff;
const GatewayRunner = Root.GatewayRunner;
const noTransportValue = Root.noTransportValue;
const noTransportSend = Root.noTransportSend;

pub fn Methods(comptime Client: type) type {
    return struct {
        pub fn fetchEntitlements(self: *Client, application_id: Snowflake, options: Types.ListEntitlements) !Rest.Response {
            return self.listEntitlements(application_id, options);
        }

        pub fn getEntitlement(self: *Client, application_id: Snowflake, entitlement_id: Snowflake) !Rest.Response {
            return self.rest.getEntitlement(application_id, entitlement_id);
        }

        pub fn fetchEntitlement(self: *Client, application_id: Snowflake, entitlement_id: Snowflake) !Rest.Response {
            return self.getEntitlement(application_id, entitlement_id);
        }

        pub fn consumeEntitlement(self: *Client, application_id: Snowflake, entitlement_id: Snowflake) !Rest.Response {
            return self.rest.consumeEntitlement(application_id, entitlement_id);
        }

        pub fn markEntitlementConsumed(self: *Client, application_id: Snowflake, entitlement_id: Snowflake) !Rest.Response {
            return self.consumeEntitlement(application_id, entitlement_id);
        }

        pub fn createTestEntitlement(
            self: *Client,
            application_id: Snowflake,
            payload: Types.CreateTestEntitlement,
        ) !Rest.Response {
            return self.rest.createTestEntitlement(application_id, payload);
        }

        pub fn deleteTestEntitlement(self: *Client, application_id: Snowflake, entitlement_id: Snowflake) !Rest.Response {
            return self.rest.deleteTestEntitlement(application_id, entitlement_id);
        }

        pub fn listSkuSubscriptions(self: *Client, sku_id: Snowflake, options: Types.ListSkuSubscriptions) !Rest.Response {
            return self.rest.listSkuSubscriptions(sku_id, options);
        }

        pub fn fetchSkuSubscriptions(self: *Client, sku_id: Snowflake, options: Types.ListSkuSubscriptions) !Rest.Response {
            return self.listSkuSubscriptions(sku_id, options);
        }

        pub fn getSkuSubscription(self: *Client, sku_id: Snowflake, subscription_id: Snowflake) !Rest.Response {
            return self.rest.getSkuSubscription(sku_id, subscription_id);
        }

        pub fn fetchSkuSubscription(self: *Client, sku_id: Snowflake, subscription_id: Snowflake) !Rest.Response {
            return self.getSkuSubscription(sku_id, subscription_id);
        }

        pub fn editCurrentUser(self: *Client, payload: Types.EditCurrentUser) !Rest.Response {
            return self.rest.editCurrentUser(payload);
        }

        pub fn setCurrentUsername(self: *Client, username: []const u8) !Rest.Response {
            return self.editCurrentUser(Types.EditCurrentUser.init().withUsername(username));
        }

        pub fn setCurrentUserAvatar(self: *Client, avatar: []const u8) !Rest.Response {
            return self.editCurrentUser(Types.EditCurrentUser.init().withAvatar(avatar));
        }

        pub fn clearCurrentUserAvatar(self: *Client) !Rest.Response {
            return self.editCurrentUser(Types.EditCurrentUser.init().clearAvatar());
        }

        pub fn setCurrentUserBanner(self: *Client, banner: []const u8) !Rest.Response {
            return self.editCurrentUser(Types.EditCurrentUser.init().withBanner(banner));
        }

        pub fn clearCurrentUserBanner(self: *Client) !Rest.Response {
            return self.editCurrentUser(Types.EditCurrentUser.init().clearBanner());
        }

        pub fn editMe(self: *Client, payload: Types.EditCurrentUser) !Rest.Response {
            return self.editCurrentUser(payload);
        }

        pub fn getCurrentUser(self: *Client) !Rest.Response {
            return self.rest.getCurrentUser();
        }

        pub fn fetchCurrentUser(self: *Client) !Rest.Response {
            return self.getCurrentUser();
        }

        pub fn getMe(self: *Client) !Rest.Response {
            return self.getCurrentUser();
        }

        pub fn fetchMe(self: *Client) !Rest.Response {
            return self.getCurrentUser();
        }

        pub fn getUser(self: *Client, user_id: Snowflake) !Rest.Response {
            return self.rest.getUser(user_id);
        }

        pub fn fetchUser(self: *Client, user_id: Snowflake) !Rest.Response {
            return self.getUser(user_id);
        }

        pub fn createDmChannel(self: *Client, user_id: Snowflake) !Rest.Response {
            return self.rest.createDmChannel(user_id);
        }

        pub fn createDm(self: *Client, user_id: Snowflake) !Rest.Response {
            return self.createDmChannel(user_id);
        }

        pub fn createDM(self: *Client, user_id: Snowflake) !Rest.Response {
            return self.createDmChannel(user_id);
        }

        pub fn listCurrentUserGuilds(self: *Client, options: Types.ListCurrentUserGuilds) !Rest.Response {
            return self.rest.listCurrentUserGuilds(options);
        }

        pub fn fetchCurrentUserGuilds(self: *Client, options: Types.ListCurrentUserGuilds) !Rest.Response {
            return self.listCurrentUserGuilds(options);
        }

        pub fn getCurrentUserGuildMember(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.getCurrentUserGuildMember(guild_id);
        }

        pub fn fetchCurrentUserGuildMember(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.getCurrentUserGuildMember(guild_id);
        }

        pub fn fetchMeGuildMember(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.getCurrentUserGuildMember(guild_id);
        }

        pub fn listCurrentUserConnections(self: *Client) !Rest.Response {
            return self.rest.listCurrentUserConnections();
        }

        pub fn fetchCurrentUserConnections(self: *Client) !Rest.Response {
            return self.listCurrentUserConnections();
        }

        pub fn getCurrentAuthorization(self: *Client, bearer_token: []const u8) !Rest.Response {
            return self.rest.getCurrentAuthorization(bearer_token);
        }

        pub fn fetchCurrentAuthorization(self: *Client, bearer_token: []const u8) !Rest.Response {
            return self.getCurrentAuthorization(bearer_token);
        }

        pub fn exchangeOAuth2Token(
            self: *Client,
            authorization: []const u8,
            payload: Types.OAuth2TokenRequest,
        ) !Rest.Response {
            return self.rest.exchangeOAuth2Token(authorization, payload);
        }

        pub fn revokeOAuth2Token(
            self: *Client,
            authorization: []const u8,
            payload: Types.OAuth2TokenRevocation,
        ) !Rest.Response {
            return self.rest.revokeOAuth2Token(authorization, payload);
        }

        pub fn getCurrentUserApplicationRoleConnection(
            self: *Client,
            bearer_token: []const u8,
            application_id: Snowflake,
        ) !Rest.Response {
            return self.rest.getCurrentUserApplicationRoleConnection(bearer_token, application_id);
        }

        pub fn fetchCurrentUserApplicationRoleConnection(
            self: *Client,
            bearer_token: []const u8,
            application_id: Snowflake,
        ) !Rest.Response {
            return self.getCurrentUserApplicationRoleConnection(bearer_token, application_id);
        }

        pub fn updateCurrentUserApplicationRoleConnection(
            self: *Client,
            bearer_token: []const u8,
            application_id: Snowflake,
            payload: Types.UpdateApplicationRoleConnection,
        ) !Rest.Response {
            return self.rest.updateCurrentUserApplicationRoleConnection(bearer_token, application_id, payload);
        }

        pub fn setCurrentUserApplicationRoleConnection(
            self: *Client,
            bearer_token: []const u8,
            application_id: Snowflake,
            payload: Types.UpdateApplicationRoleConnection,
        ) !Rest.Response {
            return self.updateCurrentUserApplicationRoleConnection(bearer_token, application_id, payload);
        }

        pub fn deleteCurrentUserApplicationRoleConnection(
            self: *Client,
            bearer_token: []const u8,
            application_id: Snowflake,
        ) !Rest.Response {
            return self.rest.deleteCurrentUserApplicationRoleConnection(bearer_token, application_id);
        }

        pub fn leaveGuild(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.leaveGuild(guild_id);
        }

        pub fn createGuild(self: *Client, payload: Types.CreateGuild) !Rest.Response {
            return self.rest.createGuild(payload);
        }

        pub fn getGuild(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.getGuild(guild_id);
        }

        pub fn fetchGuild(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.getGuild(guild_id);
        }

        pub fn getGuildWithOptions(self: *Client, guild_id: Snowflake, options: Types.GetGuild) !Rest.Response {
            return self.rest.getGuildWithOptions(guild_id, options);
        }

        pub fn fetchGuildWithOptions(self: *Client, guild_id: Snowflake, options: Types.GetGuild) !Rest.Response {
            return self.getGuildWithOptions(guild_id, options);
        }

        pub fn editGuild(self: *Client, guild_id: Snowflake, payload: Types.EditGuild) !Rest.Response {
            return self.rest.editGuild(guild_id, payload);
        }

        pub fn deleteGuild(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.deleteGuild(guild_id);
        }

        pub fn getGuildPreview(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.getGuildPreview(guild_id);
        }

        pub fn fetchGuildPreview(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.getGuildPreview(guild_id);
        }

        pub fn getChannel(self: *Client, channel_id: Snowflake) !Rest.Response {
            return self.rest.getChannel(channel_id);
        }

        pub fn fetchChannel(self: *Client, channel_id: Snowflake) !Rest.Response {
            return self.getChannel(channel_id);
        }

        pub fn listAutoModerationRules(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.listAutoModerationRules(guild_id);
        }

        pub fn fetchAutoModerationRules(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.listAutoModerationRules(guild_id);
        }

        pub fn getAutoModerationRule(self: *Client, guild_id: Snowflake, rule_id: Snowflake) !Rest.Response {
            return self.rest.getAutoModerationRule(guild_id, rule_id);
        }

        pub fn fetchAutoModerationRule(self: *Client, guild_id: Snowflake, rule_id: Snowflake) !Rest.Response {
            return self.getAutoModerationRule(guild_id, rule_id);
        }

        pub fn createAutoModerationRule(
            self: *Client,
            guild_id: Snowflake,
            payload: Types.CreateAutoModerationRule,
        ) !Rest.Response {
            return self.rest.createAutoModerationRule(guild_id, payload);
        }

        pub fn editAutoModerationRule(
            self: *Client,
            guild_id: Snowflake,
            rule_id: Snowflake,
            payload: Types.EditAutoModerationRule,
        ) !Rest.Response {
            return self.rest.editAutoModerationRule(guild_id, rule_id, payload);
        }

        pub fn deleteAutoModerationRule(self: *Client, guild_id: Snowflake, rule_id: Snowflake) !Rest.Response {
            return self.rest.deleteAutoModerationRule(guild_id, rule_id);
        }

        pub fn getGuildTemplate(self: *Client, code: []const u8) !Rest.Response {
            return self.rest.getGuildTemplate(code);
        }

        pub fn fetchGuildTemplate(self: *Client, code: []const u8) !Rest.Response {
            return self.getGuildTemplate(code);
        }

        pub fn createGuildFromTemplate(self: *Client, code: []const u8, payload: Types.CreateGuildFromTemplate) !Rest.Response {
            return self.rest.createGuildFromTemplate(code, payload);
        }

        pub fn listGuildTemplates(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.listGuildTemplates(guild_id);
        }

        pub fn fetchGuildTemplates(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.listGuildTemplates(guild_id);
        }

        pub fn createGuildTemplate(self: *Client, guild_id: Snowflake, payload: Types.CreateGuildTemplate) !Rest.Response {
            return self.rest.createGuildTemplate(guild_id, payload);
        }

        pub fn syncGuildTemplate(self: *Client, guild_id: Snowflake, code: []const u8) !Rest.Response {
            return self.rest.syncGuildTemplate(guild_id, code);
        }

        pub fn editGuildTemplate(
            self: *Client,
            guild_id: Snowflake,
            code: []const u8,
            payload: Types.EditGuildTemplate,
        ) !Rest.Response {
            return self.rest.editGuildTemplate(guild_id, code, payload);
        }

        pub fn deleteGuildTemplate(self: *Client, guild_id: Snowflake, code: []const u8) !Rest.Response {
            return self.rest.deleteGuildTemplate(guild_id, code);
        }

        pub fn getGuildWidgetSettings(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.getGuildWidgetSettings(guild_id);
        }

        pub fn fetchGuildWidgetSettings(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.getGuildWidgetSettings(guild_id);
        }

        pub fn editGuildWidgetSettings(
            self: *Client,
            guild_id: Snowflake,
            payload: Types.EditGuildWidgetSettings,
        ) !Rest.Response {
            return self.rest.editGuildWidgetSettings(guild_id, payload);
        }

        pub fn getGuildWidget(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.getGuildWidget(guild_id);
        }

        pub fn fetchGuildWidget(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.getGuildWidget(guild_id);
        }

        pub fn getGuildWidgetImage(self: *Client, guild_id: Snowflake, options: Types.GetGuildWidgetImage) !Rest.Response {
            return self.rest.getGuildWidgetImage(guild_id, options);
        }

        pub fn fetchGuildWidgetImage(self: *Client, guild_id: Snowflake, options: Types.GetGuildWidgetImage) !Rest.Response {
            return self.getGuildWidgetImage(guild_id, options);
        }

        pub fn getGuildWelcomeScreen(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.getGuildWelcomeScreen(guild_id);
        }

        pub fn fetchGuildWelcomeScreen(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.getGuildWelcomeScreen(guild_id);
        }

        pub fn editGuildWelcomeScreen(
            self: *Client,
            guild_id: Snowflake,
            payload: Types.EditWelcomeScreen,
        ) !Rest.Response {
            return self.rest.editGuildWelcomeScreen(guild_id, payload);
        }

        pub fn getGuildOnboarding(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.getGuildOnboarding(guild_id);
        }

        pub fn fetchGuildOnboarding(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.getGuildOnboarding(guild_id);
        }

        pub fn editGuildOnboarding(self: *Client, guild_id: Snowflake, payload: Types.EditGuildOnboarding) !Rest.Response {
            return self.rest.editGuildOnboarding(guild_id, payload);
        }

        pub fn setGuildOnboarding(self: *Client, guild_id: Snowflake, payload: Types.EditGuildOnboarding) !Rest.Response {
            return self.editGuildOnboarding(guild_id, payload);
        }

        pub fn editGuildIncidentActions(
            self: *Client,
            guild_id: Snowflake,
            payload: Types.EditGuildIncidentActions,
        ) !Rest.Response {
            return self.rest.editGuildIncidentActions(guild_id, payload);
        }

        pub fn setGuildIncidentActions(
            self: *Client,
            guild_id: Snowflake,
            payload: Types.EditGuildIncidentActions,
        ) !Rest.Response {
            return self.editGuildIncidentActions(guild_id, payload);
        }

        pub fn getGuildVanityUrl(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.getGuildVanityUrl(guild_id);
        }

        pub fn fetchGuildVanityUrl(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.getGuildVanityUrl(guild_id);
        }

        pub fn listGuildScheduledEvents(self: *Client, guild_id: Snowflake, options: Types.ListGuildScheduledEvents) !Rest.Response {
            return self.rest.listGuildScheduledEvents(guild_id, options);
        }

        pub fn fetchGuildScheduledEvents(self: *Client, guild_id: Snowflake, options: Types.ListGuildScheduledEvents) !Rest.Response {
            return self.listGuildScheduledEvents(guild_id, options);
        }

        pub fn createGuildScheduledEvent(
            self: *Client,
            guild_id: Snowflake,
            payload: Types.CreateGuildScheduledEvent,
        ) !Rest.Response {
            return self.rest.createGuildScheduledEvent(guild_id, payload);
        }

        pub fn getGuildScheduledEvent(
            self: *Client,
            guild_id: Snowflake,
            event_id: Snowflake,
            options: Types.GetGuildScheduledEvent,
        ) !Rest.Response {
            return self.rest.getGuildScheduledEvent(guild_id, event_id, options);
        }

        pub fn fetchGuildScheduledEvent(
            self: *Client,
            guild_id: Snowflake,
            event_id: Snowflake,
            options: Types.GetGuildScheduledEvent,
        ) !Rest.Response {
            return self.getGuildScheduledEvent(guild_id, event_id, options);
        }

        pub fn editGuildScheduledEvent(
            self: *Client,
            guild_id: Snowflake,
            event_id: Snowflake,
            payload: Types.EditGuildScheduledEvent,
        ) !Rest.Response {
            return self.rest.editGuildScheduledEvent(guild_id, event_id, payload);
        }

        pub fn deleteGuildScheduledEvent(self: *Client, guild_id: Snowflake, event_id: Snowflake) !Rest.Response {
            return self.rest.deleteGuildScheduledEvent(guild_id, event_id);
        }

        pub fn listGuildScheduledEventUsers(
            self: *Client,
            guild_id: Snowflake,
            event_id: Snowflake,
            options: Types.ListGuildScheduledEventUsers,
        ) !Rest.Response {
            return self.rest.listGuildScheduledEventUsers(guild_id, event_id, options);
        }

        pub fn fetchGuildScheduledEventUsers(
            self: *Client,
            guild_id: Snowflake,
            event_id: Snowflake,
            options: Types.ListGuildScheduledEventUsers,
        ) !Rest.Response {
            return self.listGuildScheduledEventUsers(guild_id, event_id, options);
        }

        pub fn listGuildAuditLog(self: *Client, guild_id: Snowflake, options: Types.ListAuditLog) !Rest.Response {
            return self.rest.listGuildAuditLog(guild_id, options);
        }

        pub fn fetchAuditLog(self: *Client, guild_id: Snowflake, options: Types.ListAuditLog) !Rest.Response {
            return self.listGuildAuditLog(guild_id, options);
        }

        pub fn listGuildIntegrations(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.listGuildIntegrations(guild_id);
        }

        pub fn fetchGuildIntegrations(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.listGuildIntegrations(guild_id);
        }

        pub fn deleteGuildIntegration(self: *Client, guild_id: Snowflake, integration_id: Snowflake) !Rest.Response {
            return self.rest.deleteGuildIntegration(guild_id, integration_id);
        }

        pub fn listGuildBans(self: *Client, guild_id: Snowflake, options: Types.ListGuildBans) !Rest.Response {
            return self.rest.listGuildBans(guild_id, options);
        }

        pub fn fetchBans(self: *Client, guild_id: Snowflake, options: Types.ListGuildBans) !Rest.Response {
            return self.listGuildBans(guild_id, options);
        }

        pub fn getGuildBan(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Rest.Response {
            return self.rest.getGuildBan(guild_id, user_id);
        }

        pub fn fetchBan(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Rest.Response {
            return self.getGuildBan(guild_id, user_id);
        }

        pub fn getGuildPruneCount(self: *Client, guild_id: Snowflake, options: Types.GetGuildPruneCount) !Rest.Response {
            return self.rest.getGuildPruneCount(guild_id, options);
        }

        pub fn fetchPruneCount(self: *Client, guild_id: Snowflake, options: Types.GetGuildPruneCount) !Rest.Response {
            return self.getGuildPruneCount(guild_id, options);
        }

        pub fn beginGuildPrune(self: *Client, guild_id: Snowflake, payload: Types.BeginGuildPrune) !Rest.Response {
            return self.rest.beginGuildPrune(guild_id, payload);
        }

        pub fn prune(self: *Client, guild_id: Snowflake, payload: Types.BeginGuildPrune) !Rest.Response {
            return self.beginGuildPrune(guild_id, payload);
        }

        pub fn pruneMembers(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.beginGuildPrune(guild_id, Types.BeginGuildPrune.init());
        }

        pub fn pruneMembersWithDays(self: *Client, guild_id: Snowflake, days: u8) !Rest.Response {
            return self.beginGuildPrune(guild_id, Types.BeginGuildPrune.init().withDays(days));
        }

        pub fn pruneMembersWithDaysAndCount(
            self: *Client,
            guild_id: Snowflake,
            days: u8,
            compute_prune_count: bool,
        ) !Rest.Response {
            return self.beginGuildPrune(guild_id, Types.BeginGuildPrune.init().withDays(days).computeCount(compute_prune_count));
        }

        pub fn createGuildBan(
            self: *Client,
            guild_id: Snowflake,
            user_id: Snowflake,
            payload: Types.CreateGuildBan,
        ) !Rest.Response {
            return self.rest.createGuildBan(guild_id, user_id, payload);
        }
    };
}
