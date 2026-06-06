const std = @import("std");
const Partials = @import("../../core/partials.zig");
const Rest = @import("../../rest/client.zig");
const HttpTransport = @import("../../rest/http-transport.zig").HttpTransport;
const Events = @import("../../gateway/events.zig");
const Gateway = @import("../../gateway/protocol.zig");
const GatewaySession = @import("../../gateway/session.zig");
const CacheModule = @import("../cache.zig");
const Cache = CacheModule.Cache;
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Root = @import("../client.zig");
const ClientOptions = Root.ClientOptions;
const SetActivityOptions = Root.SetActivityOptions;
const GatewayRunner = Root.GatewayRunner;
const noTransportValue = Root.noTransportValue;

pub fn Methods(comptime Client: type) type {
    return struct {
        pub fn init(allocator: std.mem.Allocator, options: ClientOptions) Client {
            const transport = options.transport orelse noTransportValue();
            return .{
                .allocator = allocator,
                .token = options.token,
                .intents = options.intents,
                .partials = options.partials,
                .presence = options.presence,
                .rest = Rest.Client.init(allocator, options.token, transport),
                .cache = Cache.initWithPolicy(allocator, options.cache_policy),
            };
        }

        pub fn initHttp(allocator: std.mem.Allocator, options: ClientOptions) !Client {
            var owned_http_transport: ?*HttpTransport = null;
            const transport = if (options.transport) |transport|
                transport
            else blk: {
                const http_transport = try allocator.create(HttpTransport);
                errdefer allocator.destroy(http_transport);
                http_transport.* = HttpTransport.init(allocator);
                owned_http_transport = http_transport;
                break :blk http_transport.transport();
            };

            return .{
                .allocator = allocator,
                .token = options.token,
                .intents = options.intents,
                .partials = options.partials,
                .presence = options.presence,
                .rest = Rest.Client.init(allocator, options.token, transport),
                .cache = Cache.initWithPolicy(allocator, options.cache_policy),
                .owned_http_transport = owned_http_transport,
            };
        }

        pub fn hasPartial(self: Client, partial: Partials.Bit) bool {
            return Partials.has(self.partials, partial);
        }

        pub fn hasPartials(self: Client, partials: Partials.Bit) bool {
            return Partials.hasAll(self.partials, partials);
        }

        pub fn dispatchGatewayPayload(self: *Client, payload: []const u8) !bool {
            var dispatch = try Gateway.parseDispatch(self.allocator, payload);
            defer dispatch.deinit();
            return self.dispatchParsedGateway(dispatch);
        }

        pub fn isReady(self: Client) bool {
            return self.ready;
        }

        pub fn readyTimestampMs(self: Client) ?u64 {
            return if (self.ready) self.ready_timestamp_ms else null;
        }

        pub fn uptimeMs(self: Client, now_ms: u64) ?u64 {
            const ready_at = self.readyTimestampMs() orelse return null;
            return if (now_ms >= ready_at) now_ms - ready_at else 0;
        }

        pub fn lastGatewaySequence(self: Client) ?u64 {
            return self.last_gateway_sequence;
        }

        pub fn lastGatewayEvent(self: Client) ?Gateway.EventName {
            return self.last_gateway_event;
        }

        pub fn gatewayPingMs(self: Client) ?u64 {
            return self.gateway_ping_ms;
        }

        pub fn resetGatewayState(self: *Client) void {
            self.ready = false;
            self.ready_timestamp_ms = null;
            self.last_gateway_sequence = null;
            self.last_gateway_event = null;
            self.last_heartbeat_sent_ms = null;
            self.gateway_ping_ms = null;
        }

        pub fn dispatchParsedGateway(self: *Client, dispatch: Gateway.ParsedDispatch) !bool {
            return self.dispatchParsedGatewayAt(dispatch, null);
        }

        pub fn dispatchParsedGatewayAt(self: *Client, dispatch: Gateway.ParsedDispatch, now_ms: ?u64) !bool {
            self.last_gateway_sequence = dispatch.sequence;
            self.last_gateway_event = dispatch.event;
            switch (dispatch.event) {
                .READY, .RESUMED => {
                    self.ready = true;
                    if (now_ms) |ready_at| self.ready_timestamp_ms = ready_at;
                },
                else => {},
            }
            try self.cache.applyDispatch(dispatch);
            return self.events.dispatch(dispatch);
        }

        pub fn markGatewayDisconnected(self: *Client) void {
            self.ready = false;
            self.ready_timestamp_ms = null;
            self.last_heartbeat_sent_ms = null;
            self.gateway_ping_ms = null;
        }

        pub fn markHeartbeatSent(self: *Client, now_ms: u64) void {
            self.last_heartbeat_sent_ms = now_ms;
        }

        pub fn markHeartbeatAck(self: *Client, now_ms: u64) void {
            const sent_at = self.last_heartbeat_sent_ms orelse return;
            self.gateway_ping_ms = if (now_ms >= sent_at) now_ms - sent_at else 0;
        }

        pub fn createGatewaySession(self: *Client, transport: GatewaySession.Transport) GatewaySession.Session {
            return GatewaySession.Session.init(self.allocator, transport, .{
                .token = self.token,
                .intents = self.intents,
                .presence = self.presence,
            });
        }

        pub fn createGatewayRunner(self: *Client, transport: GatewaySession.Transport) GatewayRunner {
            return GatewayRunner.init(self, transport);
        }

        pub fn updatePresence(self: *Client, session: *GatewaySession.Session, presence: Gateway.Presence) !void {
            _ = self;
            try session.updatePresence(presence);
        }

        pub fn setPresence(self: *Client, session: *GatewaySession.Session, presence: Gateway.Presence) !void {
            try self.updatePresence(session, presence);
        }

        pub fn setActivity(
            self: *Client,
            session: *GatewaySession.Session,
            name: []const u8,
            options: SetActivityOptions,
        ) !void {
            const activity = if (options.url) |url|
                Gateway.Activity.init(name, options.activity_type).withUrl(url)
            else
                Gateway.Activity.init(name, options.activity_type);
            const activities = [_]Gateway.Activity{activity};
            var presence = Gateway.Presence.init(options.status)
                .withActivities(&activities)
                .afkState(options.afk);
            if (options.since) |since| presence = presence.withSince(since);
            try self.setPresence(session, presence);
        }

        pub fn updateVoiceState(self: *Client, session: *GatewaySession.Session, update: Gateway.VoiceStateUpdate) !void {
            _ = self;
            try session.updateVoiceState(update);
        }

        pub fn joinVoiceChannel(
            self: *Client,
            session: *GatewaySession.Session,
            guild_id: Snowflake,
            channel_id: Snowflake,
            self_mute: bool,
            self_deaf: bool,
        ) !void {
            try self.updateVoiceState(
                session,
                Gateway.VoiceStateUpdate.init(guild_id)
                    .withChannel(channel_id)
                    .muteState(self_mute)
                    .deafState(self_deaf),
            );
        }

        pub fn leaveVoiceChannel(self: *Client, session: *GatewaySession.Session, guild_id: Snowflake) !void {
            try self.updateVoiceState(session, Gateway.VoiceStateUpdate.init(guild_id).clearChannel());
        }

        pub fn requestGuildMembers(self: *Client, session: *GatewaySession.Session, request: Gateway.RequestGuildMembers) !void {
            _ = self;
            try session.requestGuildMembers(request);
        }

        pub fn requestSoundboardSounds(self: *Client, session: *GatewaySession.Session, request: Gateway.RequestSoundboardSounds) !void {
            _ = self;
            try session.requestSoundboardSounds(request);
        }

        pub fn requestChannelInfo(self: *Client, session: *GatewaySession.Session, request: Gateway.RequestChannelInfo) !void {
            _ = self;
            try session.requestChannelInfo(request);
        }

        pub fn on(self: *Client, event: Gateway.EventName, handler: Events.RawHandler) void {
            self.events.on(event, handler);
        }

        pub fn once(self: *Client, event: Gateway.EventName, handler: Events.RawHandler) void {
            self.events.once(event, handler);
        }

        pub fn clearListener(self: *Client, event: Gateway.EventName) void {
            self.events.clear(event);
        }

        pub fn hasListener(self: *Client, event: Gateway.EventName) bool {
            return self.events.hasListener(event);
        }

        pub fn listenerCount(self: *Client, event: Gateway.EventName) usize {
            return self.events.listenerCount(event);
        }

        pub fn eventNames(self: *Client, allocator: std.mem.Allocator) ![]Gateway.EventName {
            return self.events.eventNames(allocator);
        }

        pub fn off(self: *Client, event: Gateway.EventName) void {
            self.clearListener(event);
        }

        pub fn removeListener(self: *Client, event: Gateway.EventName) void {
            self.clearListener(event);
        }

        pub fn removeAllListeners(self: *Client) void {
            self.events.clearAll();
        }

        pub fn clearListeners(self: *Client) void {
            self.removeAllListeners();
        }

        pub fn onReady(self: *Client, handler: Events.RawHandler) void {
            self.events.onReady(handler);
        }

        pub fn onceReady(self: *Client, handler: Events.RawHandler) void {
            self.once(.READY, handler);
        }

        pub fn onResumed(self: *Client, handler: Events.RawHandler) void {
            self.events.onResumed(handler);
        }

        pub fn onceResumed(self: *Client, handler: Events.RawHandler) void {
            self.once(.RESUMED, handler);
        }

        pub fn onMessageCreate(self: *Client, handler: Events.RawHandler) void {
            self.events.onMessageCreate(handler);
        }

        pub fn onceMessageCreate(self: *Client, handler: Events.RawHandler) void {
            self.once(.MESSAGE_CREATE, handler);
        }

        pub fn onMessageUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onMessageUpdate(handler);
        }

        pub fn onceMessageUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.MESSAGE_UPDATE, handler);
        }

        pub fn onMessageDelete(self: *Client, handler: Events.RawHandler) void {
            self.events.onMessageDelete(handler);
        }

        pub fn onceMessageDelete(self: *Client, handler: Events.RawHandler) void {
            self.once(.MESSAGE_DELETE, handler);
        }

        pub fn onMessageDeleteBulk(self: *Client, handler: Events.RawHandler) void {
            self.events.onMessageDeleteBulk(handler);
        }

        pub fn onceMessageDeleteBulk(self: *Client, handler: Events.RawHandler) void {
            self.once(.MESSAGE_DELETE_BULK, handler);
        }

        pub fn onMessageReactionAdd(self: *Client, handler: Events.RawHandler) void {
            self.events.onMessageReactionAdd(handler);
        }

        pub fn onceMessageReactionAdd(self: *Client, handler: Events.RawHandler) void {
            self.once(.MESSAGE_REACTION_ADD, handler);
        }

        pub fn onMessageReactionRemove(self: *Client, handler: Events.RawHandler) void {
            self.events.onMessageReactionRemove(handler);
        }

        pub fn onceMessageReactionRemove(self: *Client, handler: Events.RawHandler) void {
            self.once(.MESSAGE_REACTION_REMOVE, handler);
        }

        pub fn onMessageReactionRemoveAll(self: *Client, handler: Events.RawHandler) void {
            self.events.onMessageReactionRemoveAll(handler);
        }

        pub fn onceMessageReactionRemoveAll(self: *Client, handler: Events.RawHandler) void {
            self.once(.MESSAGE_REACTION_REMOVE_ALL, handler);
        }

        pub fn onMessageReactionRemoveEmoji(self: *Client, handler: Events.RawHandler) void {
            self.events.onMessageReactionRemoveEmoji(handler);
        }

        pub fn onceMessageReactionRemoveEmoji(self: *Client, handler: Events.RawHandler) void {
            self.once(.MESSAGE_REACTION_REMOVE_EMOJI, handler);
        }

        pub fn onMessagePollVoteAdd(self: *Client, handler: Events.RawHandler) void {
            self.events.onMessagePollVoteAdd(handler);
        }

        pub fn onceMessagePollVoteAdd(self: *Client, handler: Events.RawHandler) void {
            self.once(.MESSAGE_POLL_VOTE_ADD, handler);
        }

        pub fn onMessagePollVoteRemove(self: *Client, handler: Events.RawHandler) void {
            self.events.onMessagePollVoteRemove(handler);
        }

        pub fn onceMessagePollVoteRemove(self: *Client, handler: Events.RawHandler) void {
            self.once(.MESSAGE_POLL_VOTE_REMOVE, handler);
        }

        pub fn onUserUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onUserUpdate(handler);
        }

        pub fn onceUserUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.USER_UPDATE, handler);
        }

        pub fn onPresenceUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onPresenceUpdate(handler);
        }

        pub fn oncePresenceUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.PRESENCE_UPDATE, handler);
        }

        pub fn onVoiceStateUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onVoiceStateUpdate(handler);
        }

        pub fn onceVoiceStateUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.VOICE_STATE_UPDATE, handler);
        }

        pub fn onInteractionCreate(self: *Client, handler: Events.RawHandler) void {
            self.events.onInteractionCreate(handler);
        }

        pub fn onceInteractionCreate(self: *Client, handler: Events.RawHandler) void {
            self.once(.INTERACTION_CREATE, handler);
        }

        pub fn onApplicationCommandPermissionsUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onApplicationCommandPermissionsUpdate(handler);
        }

        pub fn onceApplicationCommandPermissionsUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.APPLICATION_COMMAND_PERMISSIONS_UPDATE, handler);
        }

        pub fn onApplicationCommand(self: *Client, handler: Events.RawHandler) void {
            self.events.onApplicationCommand(handler);
        }

        pub fn onceApplicationCommand(self: *Client, handler: Events.RawHandler) void {
            self.events.onceApplicationCommand(handler);
        }

        pub fn onMessageComponent(self: *Client, handler: Events.RawHandler) void {
            self.events.onMessageComponent(handler);
        }

        pub fn onceMessageComponent(self: *Client, handler: Events.RawHandler) void {
            self.events.onceMessageComponent(handler);
        }

        pub fn onApplicationCommandAutocomplete(self: *Client, handler: Events.RawHandler) void {
            self.events.onApplicationCommandAutocomplete(handler);
        }

        pub fn onceApplicationCommandAutocomplete(self: *Client, handler: Events.RawHandler) void {
            self.events.onceApplicationCommandAutocomplete(handler);
        }

        pub fn onModalSubmit(self: *Client, handler: Events.RawHandler) void {
            self.events.onModalSubmit(handler);
        }

        pub fn onceModalSubmit(self: *Client, handler: Events.RawHandler) void {
            self.events.onceModalSubmit(handler);
        }

        pub fn onAutoModerationRuleCreate(self: *Client, handler: Events.RawHandler) void {
            self.events.onAutoModerationRuleCreate(handler);
        }

        pub fn onceAutoModerationRuleCreate(self: *Client, handler: Events.RawHandler) void {
            self.once(.AUTO_MODERATION_RULE_CREATE, handler);
        }

        pub fn onAutoModerationRuleUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onAutoModerationRuleUpdate(handler);
        }

        pub fn onceAutoModerationRuleUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.AUTO_MODERATION_RULE_UPDATE, handler);
        }

        pub fn onAutoModerationRuleDelete(self: *Client, handler: Events.RawHandler) void {
            self.events.onAutoModerationRuleDelete(handler);
        }

        pub fn onceAutoModerationRuleDelete(self: *Client, handler: Events.RawHandler) void {
            self.once(.AUTO_MODERATION_RULE_DELETE, handler);
        }

        pub fn onAutoModerationActionExecution(self: *Client, handler: Events.RawHandler) void {
            self.events.onAutoModerationActionExecution(handler);
        }

        pub fn onceAutoModerationActionExecution(self: *Client, handler: Events.RawHandler) void {
            self.once(.AUTO_MODERATION_ACTION_EXECUTION, handler);
        }

        pub fn onEntitlementCreate(self: *Client, handler: Events.RawHandler) void {
            self.events.onEntitlementCreate(handler);
        }

        pub fn onceEntitlementCreate(self: *Client, handler: Events.RawHandler) void {
            self.once(.ENTITLEMENT_CREATE, handler);
        }

        pub fn onEntitlementUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onEntitlementUpdate(handler);
        }

        pub fn onceEntitlementUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.ENTITLEMENT_UPDATE, handler);
        }

        pub fn onEntitlementDelete(self: *Client, handler: Events.RawHandler) void {
            self.events.onEntitlementDelete(handler);
        }

        pub fn onceEntitlementDelete(self: *Client, handler: Events.RawHandler) void {
            self.once(.ENTITLEMENT_DELETE, handler);
        }

        pub fn onSubscriptionCreate(self: *Client, handler: Events.RawHandler) void {
            self.events.onSubscriptionCreate(handler);
        }

        pub fn onceSubscriptionCreate(self: *Client, handler: Events.RawHandler) void {
            self.once(.SUBSCRIPTION_CREATE, handler);
        }

        pub fn onSubscriptionUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onSubscriptionUpdate(handler);
        }

        pub fn onceSubscriptionUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.SUBSCRIPTION_UPDATE, handler);
        }

        pub fn onSubscriptionDelete(self: *Client, handler: Events.RawHandler) void {
            self.events.onSubscriptionDelete(handler);
        }

        pub fn onceSubscriptionDelete(self: *Client, handler: Events.RawHandler) void {
            self.once(.SUBSCRIPTION_DELETE, handler);
        }

        pub fn onGuildCreate(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildCreate(handler);
        }

        pub fn onceGuildCreate(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_CREATE, handler);
        }

        pub fn onGuildUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildUpdate(handler);
        }

        pub fn onceGuildUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_UPDATE, handler);
        }

        pub fn onGuildDelete(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildDelete(handler);
        }

        pub fn onceGuildDelete(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_DELETE, handler);
        }

        pub fn onGuildAuditLogEntryCreate(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildAuditLogEntryCreate(handler);
        }

        pub fn onceGuildAuditLogEntryCreate(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_AUDIT_LOG_ENTRY_CREATE, handler);
        }

        pub fn onGuildBanAdd(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildBanAdd(handler);
        }

        pub fn onceGuildBanAdd(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_BAN_ADD, handler);
        }

        pub fn onGuildBanRemove(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildBanRemove(handler);
        }

        pub fn onceGuildBanRemove(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_BAN_REMOVE, handler);
        }

        pub fn onGuildIntegrationsUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildIntegrationsUpdate(handler);
        }

        pub fn onceGuildIntegrationsUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_INTEGRATIONS_UPDATE, handler);
        }

        pub fn onIntegrationCreate(self: *Client, handler: Events.RawHandler) void {
            self.events.onIntegrationCreate(handler);
        }

        pub fn onceIntegrationCreate(self: *Client, handler: Events.RawHandler) void {
            self.once(.INTEGRATION_CREATE, handler);
        }

        pub fn onIntegrationUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onIntegrationUpdate(handler);
        }

        pub fn onceIntegrationUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.INTEGRATION_UPDATE, handler);
        }

        pub fn onIntegrationDelete(self: *Client, handler: Events.RawHandler) void {
            self.events.onIntegrationDelete(handler);
        }

        pub fn onceIntegrationDelete(self: *Client, handler: Events.RawHandler) void {
            self.once(.INTEGRATION_DELETE, handler);
        }

        pub fn onGuildMemberAdd(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildMemberAdd(handler);
        }

        pub fn onceGuildMemberAdd(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_MEMBER_ADD, handler);
        }

        pub fn onGuildMemberUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildMemberUpdate(handler);
        }
    };
}
