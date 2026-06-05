const std = @import("std");
const Intents = @import("../core/intents.zig");
const Rest = @import("../rest/client.zig");
const HttpTransport = @import("../rest/http_transport.zig").HttpTransport;
const Events = @import("../gateway/events.zig");
const Gateway = @import("../gateway/protocol.zig");
const GatewaySession = @import("../gateway/session.zig");
const CacheModule = @import("cache.zig");
const Cache = CacheModule.Cache;
const Types = @import("../models/types.zig");
const Interactions = @import("../interactions/mod.zig");
const Snowflake = @import("../core/snowflake.zig").Snowflake;

pub const ClientOptions = struct {
    token: []const u8,
    intents: Intents.Bit = Intents.defaultNonPrivileged(),
    presence: ?Gateway.Presence = null,
    transport: ?Rest.Transport = null,
    cache_policy: CacheModule.CachePolicy = .default(),
};

pub const SetActivityOptions = struct {
    activity_type: Gateway.ActivityType = .playing,
    status: Gateway.PresenceStatus = .online,
    url: ?[]const u8 = null,
    since: ?u64 = null,
    afk: bool = false,

    pub fn init(activity_type: Gateway.ActivityType) SetActivityOptions {
        return .{ .activity_type = activity_type };
    }

    pub fn withStatus(self: SetActivityOptions, status: Gateway.PresenceStatus) SetActivityOptions {
        var options = self;
        options.status = status;
        return options;
    }

    pub fn withUrl(self: SetActivityOptions, url: []const u8) SetActivityOptions {
        var options = self;
        options.url = url;
        return options;
    }

    pub fn withSince(self: SetActivityOptions, since: u64) SetActivityOptions {
        var options = self;
        options.since = since;
        return options;
    }

    pub fn afkState(self: SetActivityOptions, afk: bool) SetActivityOptions {
        var options = self;
        options.afk = afk;
        return options;
    }
};

pub const Client = struct {
    allocator: std.mem.Allocator,
    token: []const u8,
    intents: Intents.Bit,
    presence: ?Gateway.Presence,
    rest: Rest.Client,
    events: Events.Dispatcher = .{},
    cache: Cache,
    ready: bool = false,
    ready_timestamp_ms: ?u64 = null,
    last_gateway_sequence: ?u64 = null,
    last_gateway_event: ?Gateway.EventName = null,
    last_heartbeat_sent_ms: ?u64 = null,
    gateway_ping_ms: ?u64 = null,
    owned_http_transport: ?*HttpTransport = null,

    pub fn init(allocator: std.mem.Allocator, options: ClientOptions) Client {
        const transport = options.transport orelse noTransportValue();
        return .{
            .allocator = allocator,
            .token = options.token,
            .intents = options.intents,
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
            .presence = options.presence,
            .rest = Rest.Client.init(allocator, options.token, transport),
            .cache = Cache.initWithPolicy(allocator, options.cache_policy),
            .owned_http_transport = owned_http_transport,
        };
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

    fn dispatchParsedGateway(self: *Client, dispatch: Gateway.ParsedDispatch) !bool {
        return self.dispatchParsedGatewayAt(dispatch, null);
    }

    fn dispatchParsedGatewayAt(self: *Client, dispatch: Gateway.ParsedDispatch, now_ms: ?u64) !bool {
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

    fn markGatewayDisconnected(self: *Client) void {
        self.ready = false;
        self.ready_timestamp_ms = null;
        self.last_heartbeat_sent_ms = null;
        self.gateway_ping_ms = null;
    }

    fn markHeartbeatSent(self: *Client, now_ms: u64) void {
        self.last_heartbeat_sent_ms = now_ms;
    }

    fn markHeartbeatAck(self: *Client, now_ms: u64) void {
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

    pub fn onceGuildMemberUpdate(self: *Client, handler: Events.RawHandler) void {
        self.once(.GUILD_MEMBER_UPDATE, handler);
    }

    pub fn onGuildMemberRemove(self: *Client, handler: Events.RawHandler) void {
        self.events.onGuildMemberRemove(handler);
    }

    pub fn onceGuildMemberRemove(self: *Client, handler: Events.RawHandler) void {
        self.once(.GUILD_MEMBER_REMOVE, handler);
    }

    pub fn onGuildMembersChunk(self: *Client, handler: Events.RawHandler) void {
        self.events.onGuildMembersChunk(handler);
    }

    pub fn onceGuildMembersChunk(self: *Client, handler: Events.RawHandler) void {
        self.once(.GUILD_MEMBERS_CHUNK, handler);
    }

    pub fn onGuildRoleCreate(self: *Client, handler: Events.RawHandler) void {
        self.events.onGuildRoleCreate(handler);
    }

    pub fn onceGuildRoleCreate(self: *Client, handler: Events.RawHandler) void {
        self.once(.GUILD_ROLE_CREATE, handler);
    }

    pub fn onGuildRoleUpdate(self: *Client, handler: Events.RawHandler) void {
        self.events.onGuildRoleUpdate(handler);
    }

    pub fn onceGuildRoleUpdate(self: *Client, handler: Events.RawHandler) void {
        self.once(.GUILD_ROLE_UPDATE, handler);
    }

    pub fn onGuildRoleDelete(self: *Client, handler: Events.RawHandler) void {
        self.events.onGuildRoleDelete(handler);
    }

    pub fn onceGuildRoleDelete(self: *Client, handler: Events.RawHandler) void {
        self.once(.GUILD_ROLE_DELETE, handler);
    }

    pub fn onGuildEmojisUpdate(self: *Client, handler: Events.RawHandler) void {
        self.events.onGuildEmojisUpdate(handler);
    }

    pub fn onceGuildEmojisUpdate(self: *Client, handler: Events.RawHandler) void {
        self.once(.GUILD_EMOJIS_UPDATE, handler);
    }

    pub fn onGuildStickersUpdate(self: *Client, handler: Events.RawHandler) void {
        self.events.onGuildStickersUpdate(handler);
    }

    pub fn onceGuildStickersUpdate(self: *Client, handler: Events.RawHandler) void {
        self.once(.GUILD_STICKERS_UPDATE, handler);
    }

    pub fn onGuildScheduledEventCreate(self: *Client, handler: Events.RawHandler) void {
        self.events.onGuildScheduledEventCreate(handler);
    }

    pub fn onceGuildScheduledEventCreate(self: *Client, handler: Events.RawHandler) void {
        self.once(.GUILD_SCHEDULED_EVENT_CREATE, handler);
    }

    pub fn onGuildScheduledEventUpdate(self: *Client, handler: Events.RawHandler) void {
        self.events.onGuildScheduledEventUpdate(handler);
    }

    pub fn onceGuildScheduledEventUpdate(self: *Client, handler: Events.RawHandler) void {
        self.once(.GUILD_SCHEDULED_EVENT_UPDATE, handler);
    }

    pub fn onGuildScheduledEventDelete(self: *Client, handler: Events.RawHandler) void {
        self.events.onGuildScheduledEventDelete(handler);
    }

    pub fn onceGuildScheduledEventDelete(self: *Client, handler: Events.RawHandler) void {
        self.once(.GUILD_SCHEDULED_EVENT_DELETE, handler);
    }

    pub fn onGuildScheduledEventUserAdd(self: *Client, handler: Events.RawHandler) void {
        self.events.onGuildScheduledEventUserAdd(handler);
    }

    pub fn onceGuildScheduledEventUserAdd(self: *Client, handler: Events.RawHandler) void {
        self.once(.GUILD_SCHEDULED_EVENT_USER_ADD, handler);
    }

    pub fn onGuildScheduledEventUserRemove(self: *Client, handler: Events.RawHandler) void {
        self.events.onGuildScheduledEventUserRemove(handler);
    }

    pub fn onceGuildScheduledEventUserRemove(self: *Client, handler: Events.RawHandler) void {
        self.once(.GUILD_SCHEDULED_EVENT_USER_REMOVE, handler);
    }

    pub fn onGuildSoundboardSoundCreate(self: *Client, handler: Events.RawHandler) void {
        self.events.onGuildSoundboardSoundCreate(handler);
    }

    pub fn onceGuildSoundboardSoundCreate(self: *Client, handler: Events.RawHandler) void {
        self.once(.GUILD_SOUNDBOARD_SOUND_CREATE, handler);
    }

    pub fn onGuildSoundboardSoundUpdate(self: *Client, handler: Events.RawHandler) void {
        self.events.onGuildSoundboardSoundUpdate(handler);
    }

    pub fn onceGuildSoundboardSoundUpdate(self: *Client, handler: Events.RawHandler) void {
        self.once(.GUILD_SOUNDBOARD_SOUND_UPDATE, handler);
    }

    pub fn onGuildSoundboardSoundDelete(self: *Client, handler: Events.RawHandler) void {
        self.events.onGuildSoundboardSoundDelete(handler);
    }

    pub fn onceGuildSoundboardSoundDelete(self: *Client, handler: Events.RawHandler) void {
        self.once(.GUILD_SOUNDBOARD_SOUND_DELETE, handler);
    }

    pub fn onGuildSoundboardSoundsUpdate(self: *Client, handler: Events.RawHandler) void {
        self.events.onGuildSoundboardSoundsUpdate(handler);
    }

    pub fn onceGuildSoundboardSoundsUpdate(self: *Client, handler: Events.RawHandler) void {
        self.once(.GUILD_SOUNDBOARD_SOUNDS_UPDATE, handler);
    }

    pub fn onSoundboardSounds(self: *Client, handler: Events.RawHandler) void {
        self.events.onSoundboardSounds(handler);
    }

    pub fn onceSoundboardSounds(self: *Client, handler: Events.RawHandler) void {
        self.once(.SOUNDBOARD_SOUNDS, handler);
    }

    pub fn onStageInstanceCreate(self: *Client, handler: Events.RawHandler) void {
        self.events.onStageInstanceCreate(handler);
    }

    pub fn onceStageInstanceCreate(self: *Client, handler: Events.RawHandler) void {
        self.once(.STAGE_INSTANCE_CREATE, handler);
    }

    pub fn onStageInstanceUpdate(self: *Client, handler: Events.RawHandler) void {
        self.events.onStageInstanceUpdate(handler);
    }

    pub fn onceStageInstanceUpdate(self: *Client, handler: Events.RawHandler) void {
        self.once(.STAGE_INSTANCE_UPDATE, handler);
    }

    pub fn onStageInstanceDelete(self: *Client, handler: Events.RawHandler) void {
        self.events.onStageInstanceDelete(handler);
    }

    pub fn onceStageInstanceDelete(self: *Client, handler: Events.RawHandler) void {
        self.once(.STAGE_INSTANCE_DELETE, handler);
    }

    pub fn onVoiceChannelEffectSend(self: *Client, handler: Events.RawHandler) void {
        self.events.onVoiceChannelEffectSend(handler);
    }

    pub fn onceVoiceChannelEffectSend(self: *Client, handler: Events.RawHandler) void {
        self.once(.VOICE_CHANNEL_EFFECT_SEND, handler);
    }

    pub fn onVoiceServerUpdate(self: *Client, handler: Events.RawHandler) void {
        self.events.onVoiceServerUpdate(handler);
    }

    pub fn onceVoiceServerUpdate(self: *Client, handler: Events.RawHandler) void {
        self.once(.VOICE_SERVER_UPDATE, handler);
    }

    pub fn onChannelCreate(self: *Client, handler: Events.RawHandler) void {
        self.events.onChannelCreate(handler);
    }

    pub fn onceChannelCreate(self: *Client, handler: Events.RawHandler) void {
        self.once(.CHANNEL_CREATE, handler);
    }

    pub fn onChannelUpdate(self: *Client, handler: Events.RawHandler) void {
        self.events.onChannelUpdate(handler);
    }

    pub fn onceChannelUpdate(self: *Client, handler: Events.RawHandler) void {
        self.once(.CHANNEL_UPDATE, handler);
    }

    pub fn onChannelDelete(self: *Client, handler: Events.RawHandler) void {
        self.events.onChannelDelete(handler);
    }

    pub fn onceChannelDelete(self: *Client, handler: Events.RawHandler) void {
        self.once(.CHANNEL_DELETE, handler);
    }

    pub fn onChannelInfo(self: *Client, handler: Events.RawHandler) void {
        self.events.onChannelInfo(handler);
    }

    pub fn onceChannelInfo(self: *Client, handler: Events.RawHandler) void {
        self.once(.CHANNEL_INFO, handler);
    }

    pub fn onVoiceChannelStatusUpdate(self: *Client, handler: Events.RawHandler) void {
        self.events.onVoiceChannelStatusUpdate(handler);
    }

    pub fn onceVoiceChannelStatusUpdate(self: *Client, handler: Events.RawHandler) void {
        self.once(.VOICE_CHANNEL_STATUS_UPDATE, handler);
    }

    pub fn onVoiceChannelStartTimeUpdate(self: *Client, handler: Events.RawHandler) void {
        self.events.onVoiceChannelStartTimeUpdate(handler);
    }

    pub fn onceVoiceChannelStartTimeUpdate(self: *Client, handler: Events.RawHandler) void {
        self.once(.VOICE_CHANNEL_START_TIME_UPDATE, handler);
    }

    pub fn onChannelPinsUpdate(self: *Client, handler: Events.RawHandler) void {
        self.events.onChannelPinsUpdate(handler);
    }

    pub fn onceChannelPinsUpdate(self: *Client, handler: Events.RawHandler) void {
        self.once(.CHANNEL_PINS_UPDATE, handler);
    }

    pub fn onTypingStart(self: *Client, handler: Events.RawHandler) void {
        self.events.onTypingStart(handler);
    }

    pub fn onceTypingStart(self: *Client, handler: Events.RawHandler) void {
        self.once(.TYPING_START, handler);
    }

    pub fn onWebhooksUpdate(self: *Client, handler: Events.RawHandler) void {
        self.events.onWebhooksUpdate(handler);
    }

    pub fn onceWebhooksUpdate(self: *Client, handler: Events.RawHandler) void {
        self.once(.WEBHOOKS_UPDATE, handler);
    }

    pub fn onInviteCreate(self: *Client, handler: Events.RawHandler) void {
        self.events.onInviteCreate(handler);
    }

    pub fn onceInviteCreate(self: *Client, handler: Events.RawHandler) void {
        self.once(.INVITE_CREATE, handler);
    }

    pub fn onInviteDelete(self: *Client, handler: Events.RawHandler) void {
        self.events.onInviteDelete(handler);
    }

    pub fn onceInviteDelete(self: *Client, handler: Events.RawHandler) void {
        self.once(.INVITE_DELETE, handler);
    }

    pub fn onThreadCreate(self: *Client, handler: Events.RawHandler) void {
        self.events.onThreadCreate(handler);
    }

    pub fn onceThreadCreate(self: *Client, handler: Events.RawHandler) void {
        self.once(.THREAD_CREATE, handler);
    }

    pub fn onThreadUpdate(self: *Client, handler: Events.RawHandler) void {
        self.events.onThreadUpdate(handler);
    }

    pub fn onceThreadUpdate(self: *Client, handler: Events.RawHandler) void {
        self.once(.THREAD_UPDATE, handler);
    }

    pub fn onThreadDelete(self: *Client, handler: Events.RawHandler) void {
        self.events.onThreadDelete(handler);
    }

    pub fn onceThreadDelete(self: *Client, handler: Events.RawHandler) void {
        self.once(.THREAD_DELETE, handler);
    }

    pub fn onThreadListSync(self: *Client, handler: Events.RawHandler) void {
        self.events.onThreadListSync(handler);
    }

    pub fn onceThreadListSync(self: *Client, handler: Events.RawHandler) void {
        self.once(.THREAD_LIST_SYNC, handler);
    }

    pub fn onThreadMemberUpdate(self: *Client, handler: Events.RawHandler) void {
        self.events.onThreadMemberUpdate(handler);
    }

    pub fn onceThreadMemberUpdate(self: *Client, handler: Events.RawHandler) void {
        self.once(.THREAD_MEMBER_UPDATE, handler);
    }

    pub fn onThreadMembersUpdate(self: *Client, handler: Events.RawHandler) void {
        self.events.onThreadMembersUpdate(handler);
    }

    pub fn onceThreadMembersUpdate(self: *Client, handler: Events.RawHandler) void {
        self.once(.THREAD_MEMBERS_UPDATE, handler);
    }

    pub fn onRateLimited(self: *Client, handler: Events.RawHandler) void {
        self.events.onRateLimited(handler);
    }

    pub fn onceRateLimited(self: *Client, handler: Events.RawHandler) void {
        self.once(.RATE_LIMITED, handler);
    }

    pub fn onUnknown(self: *Client, handler: Events.RawHandler) void {
        self.events.onUnknown(handler);
    }

    pub fn sendMessage(self: *Client, channel_id: Snowflake, payload: Types.CreateMessage) !Rest.Response {
        return self.rest.createMessage(channel_id, payload);
    }

    pub fn sendMessageWithContent(self: *Client, channel_id: Snowflake, content: []const u8) !Rest.Response {
        return self.sendMessage(channel_id, Types.CreateMessage.init(content));
    }

    pub fn sendContent(self: *Client, channel_id: Snowflake, content: []const u8) !Rest.Response {
        return self.sendMessageWithContent(channel_id, content);
    }

    pub fn sendText(self: *Client, channel_id: Snowflake, content: []const u8) !Rest.Response {
        return self.sendMessageWithContent(channel_id, content);
    }

    pub fn send(self: *Client, channel_id: Snowflake, payload: Types.CreateMessage) !Rest.Response {
        return self.sendMessage(channel_id, payload);
    }

    pub fn getGateway(self: *Client) !Rest.Response {
        return self.rest.getGateway();
    }

    pub fn fetchGateway(self: *Client) !Rest.Response {
        return self.getGateway();
    }

    pub fn getGatewayBot(self: *Client) !Rest.Response {
        return self.rest.getGatewayBot();
    }

    pub fn fetchGatewayBot(self: *Client) !Rest.Response {
        return self.getGatewayBot();
    }

    pub fn getCurrentApplication(self: *Client) !Rest.Response {
        return self.rest.getCurrentApplication();
    }

    pub fn fetchCurrentApplication(self: *Client) !Rest.Response {
        return self.getCurrentApplication();
    }

    pub fn getCurrentBotApplication(self: *Client) !Rest.Response {
        return self.rest.getCurrentBotApplication();
    }

    pub fn fetchCurrentBotApplication(self: *Client) !Rest.Response {
        return self.getCurrentBotApplication();
    }

    pub fn editCurrentApplication(self: *Client, payload: Types.EditCurrentApplication) !Rest.Response {
        return self.rest.editCurrentApplication(payload);
    }

    pub fn setCurrentApplicationDescription(self: *Client, description: []const u8) !Rest.Response {
        return self.editCurrentApplication(Types.EditCurrentApplication.init().withDescription(description));
    }

    pub fn setCurrentApplicationIcon(self: *Client, icon: []const u8) !Rest.Response {
        return self.editCurrentApplication(Types.EditCurrentApplication.init().withIcon(icon));
    }

    pub fn clearCurrentApplicationIcon(self: *Client) !Rest.Response {
        return self.editCurrentApplication(Types.EditCurrentApplication.init().clearIcon());
    }

    pub fn setCurrentApplicationCoverImage(self: *Client, cover_image: []const u8) !Rest.Response {
        return self.editCurrentApplication(Types.EditCurrentApplication.init().withCoverImage(cover_image));
    }

    pub fn clearCurrentApplicationCoverImage(self: *Client) !Rest.Response {
        return self.editCurrentApplication(Types.EditCurrentApplication.init().clearCoverImage());
    }

    pub fn listApplicationSkus(self: *Client, application_id: Snowflake) !Rest.Response {
        return self.rest.listApplicationSkus(application_id);
    }

    pub fn fetchApplicationSkus(self: *Client, application_id: Snowflake) !Rest.Response {
        return self.listApplicationSkus(application_id);
    }

    pub fn listApplicationRoleConnectionMetadataRecords(
        self: *Client,
        application_id: Snowflake,
    ) !Rest.Response {
        return self.rest.listApplicationRoleConnectionMetadataRecords(application_id);
    }

    pub fn fetchApplicationRoleConnectionMetadataRecords(
        self: *Client,
        application_id: Snowflake,
    ) !Rest.Response {
        return self.listApplicationRoleConnectionMetadataRecords(application_id);
    }

    pub fn updateApplicationRoleConnectionMetadataRecords(
        self: *Client,
        application_id: Snowflake,
        payload: Types.UpdateApplicationRoleConnectionMetadataRecords,
    ) !Rest.Response {
        return self.rest.updateApplicationRoleConnectionMetadataRecords(application_id, payload);
    }

    pub fn setApplicationRoleConnectionMetadataRecords(
        self: *Client,
        application_id: Snowflake,
        payload: Types.UpdateApplicationRoleConnectionMetadataRecords,
    ) !Rest.Response {
        return self.updateApplicationRoleConnectionMetadataRecords(application_id, payload);
    }

    pub fn listApplicationEmojis(self: *Client, application_id: Snowflake) !Rest.Response {
        return self.rest.listApplicationEmojis(application_id);
    }

    pub fn fetchApplicationEmojis(self: *Client, application_id: Snowflake) !Rest.Response {
        return self.listApplicationEmojis(application_id);
    }

    pub fn getApplicationEmoji(self: *Client, application_id: Snowflake, emoji_id: Snowflake) !Rest.Response {
        return self.rest.getApplicationEmoji(application_id, emoji_id);
    }

    pub fn fetchApplicationEmoji(self: *Client, application_id: Snowflake, emoji_id: Snowflake) !Rest.Response {
        return self.getApplicationEmoji(application_id, emoji_id);
    }

    pub fn createApplicationEmoji(
        self: *Client,
        application_id: Snowflake,
        payload: Types.CreateApplicationEmoji,
    ) !Rest.Response {
        return self.rest.createApplicationEmoji(application_id, payload);
    }

    pub fn createApplicationEmojiWithImage(
        self: *Client,
        application_id: Snowflake,
        name: []const u8,
        image: []const u8,
    ) !Rest.Response {
        return self.createApplicationEmoji(application_id, Types.CreateApplicationEmoji.init(name, image));
    }

    pub fn editApplicationEmoji(
        self: *Client,
        application_id: Snowflake,
        emoji_id: Snowflake,
        payload: Types.EditApplicationEmoji,
    ) !Rest.Response {
        return self.rest.editApplicationEmoji(application_id, emoji_id, payload);
    }

    pub fn renameApplicationEmoji(
        self: *Client,
        application_id: Snowflake,
        emoji_id: Snowflake,
        name: []const u8,
    ) !Rest.Response {
        return self.editApplicationEmoji(application_id, emoji_id, Types.EditApplicationEmoji.init(name));
    }

    pub fn deleteApplicationEmoji(self: *Client, application_id: Snowflake, emoji_id: Snowflake) !Rest.Response {
        return self.rest.deleteApplicationEmoji(application_id, emoji_id);
    }

    pub fn getApplicationActivityInstance(
        self: *Client,
        application_id: Snowflake,
        instance_id: []const u8,
    ) !Rest.Response {
        return self.rest.getApplicationActivityInstance(application_id, instance_id);
    }

    pub fn fetchApplicationActivityInstance(
        self: *Client,
        application_id: Snowflake,
        instance_id: []const u8,
    ) !Rest.Response {
        return self.getApplicationActivityInstance(application_id, instance_id);
    }

    pub fn createLobby(self: *Client, payload: Types.CreateLobby) !Rest.Response {
        return self.rest.createLobby(payload);
    }

    pub fn getLobby(self: *Client, lobby_id: Snowflake) !Rest.Response {
        return self.rest.getLobby(lobby_id);
    }

    pub fn fetchLobby(self: *Client, lobby_id: Snowflake) !Rest.Response {
        return self.getLobby(lobby_id);
    }

    pub fn editLobby(self: *Client, lobby_id: Snowflake, payload: Types.EditLobby) !Rest.Response {
        return self.rest.editLobby(lobby_id, payload);
    }

    pub fn deleteLobby(self: *Client, lobby_id: Snowflake) !Rest.Response {
        return self.rest.deleteLobby(lobby_id);
    }

    pub fn addLobbyMember(self: *Client, lobby_id: Snowflake, user_id: Snowflake, payload: Types.UpdateLobbyMember) !Rest.Response {
        return self.rest.addLobbyMember(lobby_id, user_id, payload);
    }

    pub fn setLobbyMember(self: *Client, lobby_id: Snowflake, user_id: Snowflake, payload: Types.UpdateLobbyMember) !Rest.Response {
        return self.addLobbyMember(lobby_id, user_id, payload);
    }

    pub fn bulkUpdateLobbyMembers(self: *Client, lobby_id: Snowflake, payload: Types.BulkUpdateLobbyMembers) !Rest.Response {
        return self.rest.bulkUpdateLobbyMembers(lobby_id, payload);
    }

    pub fn removeLobbyMember(self: *Client, lobby_id: Snowflake, user_id: Snowflake) !Rest.Response {
        return self.rest.removeLobbyMember(lobby_id, user_id);
    }

    pub fn leaveLobby(self: *Client, bearer_token: []const u8, lobby_id: Snowflake) !Rest.Response {
        return self.rest.leaveLobby(bearer_token, lobby_id);
    }

    pub fn linkLobbyChannel(self: *Client, bearer_token: []const u8, lobby_id: Snowflake, payload: Types.LinkLobbyChannel) !Rest.Response {
        return self.rest.linkLobbyChannel(bearer_token, lobby_id, payload);
    }

    pub fn unlinkLobbyChannel(self: *Client, bearer_token: []const u8, lobby_id: Snowflake) !Rest.Response {
        return self.rest.unlinkLobbyChannel(bearer_token, lobby_id);
    }

    pub fn updateLobbyMessageModerationMetadata(
        self: *Client,
        lobby_id: Snowflake,
        message_id: Snowflake,
        payload: Types.UpdateLobbyMessageModerationMetadata,
    ) !Rest.Response {
        return self.rest.updateLobbyMessageModerationMetadata(lobby_id, message_id, payload);
    }

    pub fn setLobbyMessageModerationMetadata(
        self: *Client,
        lobby_id: Snowflake,
        message_id: Snowflake,
        payload: Types.UpdateLobbyMessageModerationMetadata,
    ) !Rest.Response {
        return self.updateLobbyMessageModerationMetadata(lobby_id, message_id, payload);
    }

    pub fn listEntitlements(self: *Client, application_id: Snowflake, options: Types.ListEntitlements) !Rest.Response {
        return self.rest.listEntitlements(application_id, options);
    }

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

    pub fn ban(self: *Client, guild_id: Snowflake, user_id: Snowflake, payload: Types.CreateGuildBan) !Rest.Response {
        return self.createGuildBan(guild_id, user_id, payload);
    }

    pub fn banUser(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Rest.Response {
        return self.createGuildBan(guild_id, user_id, Types.CreateGuildBan.init());
    }

    pub fn banUserDeletingMessagesFor(
        self: *Client,
        guild_id: Snowflake,
        user_id: Snowflake,
        seconds: u32,
    ) !Rest.Response {
        return self.createGuildBan(guild_id, user_id, Types.CreateGuildBan.init().deleteMessagesFor(seconds));
    }

    pub fn bulkGuildBan(self: *Client, guild_id: Snowflake, payload: Types.BulkGuildBan) !Rest.Response {
        return self.rest.bulkGuildBan(guild_id, payload);
    }

    pub fn bulkBan(self: *Client, guild_id: Snowflake, payload: Types.BulkGuildBan) !Rest.Response {
        return self.bulkGuildBan(guild_id, payload);
    }

    pub fn bulkBanUsers(self: *Client, guild_id: Snowflake, user_ids: []const Snowflake) !Rest.Response {
        return self.bulkGuildBan(guild_id, Types.BulkGuildBan.init(user_ids));
    }

    pub fn bulkBanUsersDeletingMessagesFor(
        self: *Client,
        guild_id: Snowflake,
        user_ids: []const Snowflake,
        seconds: u32,
    ) !Rest.Response {
        return self.bulkGuildBan(guild_id, Types.BulkGuildBan.init(user_ids).deleteMessagesFor(seconds));
    }

    pub fn removeGuildBan(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Rest.Response {
        return self.rest.removeGuildBan(guild_id, user_id);
    }

    pub fn unban(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Rest.Response {
        return self.removeGuildBan(guild_id, user_id);
    }

    pub fn listGuildMembers(self: *Client, guild_id: Snowflake, options: Types.ListGuildMembers) !Rest.Response {
        return self.rest.listGuildMembers(guild_id, options);
    }

    pub fn fetchMembers(self: *Client, guild_id: Snowflake, options: Types.ListGuildMembers) !Rest.Response {
        return self.listGuildMembers(guild_id, options);
    }

    pub fn searchGuildMembers(self: *Client, guild_id: Snowflake, options: Types.SearchGuildMembers) !Rest.Response {
        return self.rest.searchGuildMembers(guild_id, options);
    }

    pub fn searchMembers(self: *Client, guild_id: Snowflake, options: Types.SearchGuildMembers) !Rest.Response {
        return self.searchGuildMembers(guild_id, options);
    }

    pub fn getGuildMember(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Rest.Response {
        return self.rest.getGuildMember(guild_id, user_id);
    }

    pub fn fetchMember(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Rest.Response {
        return self.getGuildMember(guild_id, user_id);
    }

    pub fn addGuildMember(
        self: *Client,
        guild_id: Snowflake,
        user_id: Snowflake,
        payload: Types.AddGuildMember,
    ) !Rest.Response {
        return self.rest.addGuildMember(guild_id, user_id, payload);
    }

    pub fn editGuildMember(
        self: *Client,
        guild_id: Snowflake,
        user_id: Snowflake,
        payload: Types.EditGuildMember,
    ) !Rest.Response {
        return self.rest.editGuildMember(guild_id, user_id, payload);
    }

    pub fn setMemberNickname(
        self: *Client,
        guild_id: Snowflake,
        user_id: Snowflake,
        nick: []const u8,
    ) !Rest.Response {
        return self.editGuildMember(guild_id, user_id, Types.EditGuildMember.init().withNick(nick));
    }

    pub fn setMemberRoles(
        self: *Client,
        guild_id: Snowflake,
        user_id: Snowflake,
        roles: []const Snowflake,
    ) !Rest.Response {
        return self.editGuildMember(guild_id, user_id, Types.EditGuildMember.init().withRoles(roles));
    }

    pub fn muteMember(
        self: *Client,
        guild_id: Snowflake,
        user_id: Snowflake,
        muted: bool,
    ) !Rest.Response {
        return self.editGuildMember(guild_id, user_id, Types.EditGuildMember.init().muteState(muted));
    }

    pub fn deafenMember(
        self: *Client,
        guild_id: Snowflake,
        user_id: Snowflake,
        deafened: bool,
    ) !Rest.Response {
        return self.editGuildMember(guild_id, user_id, Types.EditGuildMember.init().deafState(deafened));
    }

    pub fn moveMemberToVoiceChannel(
        self: *Client,
        guild_id: Snowflake,
        user_id: Snowflake,
        channel_id: Snowflake,
    ) !Rest.Response {
        return self.editGuildMember(guild_id, user_id, Types.EditGuildMember.init().moveToVoiceChannel(channel_id));
    }

    pub fn timeoutMember(
        self: *Client,
        guild_id: Snowflake,
        user_id: Snowflake,
        communication_disabled_until: []const u8,
    ) !Rest.Response {
        return self.editGuildMember(guild_id, user_id, Types.EditGuildMember.init().timeoutUntil(communication_disabled_until));
    }

    pub fn clearMemberTimeout(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Rest.Response {
        return self.editGuildMember(guild_id, user_id, Types.EditGuildMember.init().clearTimeout());
    }

    pub fn editCurrentGuildMember(self: *Client, guild_id: Snowflake, payload: Types.EditCurrentGuildMember) !Rest.Response {
        return self.rest.editCurrentGuildMember(guild_id, payload);
    }

    pub fn setCurrentGuildMemberNick(self: *Client, guild_id: Snowflake, nick: []const u8) !Rest.Response {
        return self.editCurrentGuildMember(guild_id, Types.EditCurrentGuildMember.init().withNick(nick));
    }

    pub fn clearCurrentGuildMemberNick(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.editCurrentGuildMember(guild_id, Types.EditCurrentGuildMember.init().clearNick());
    }

    pub fn setCurrentGuildMemberAvatar(self: *Client, guild_id: Snowflake, avatar: []const u8) !Rest.Response {
        return self.editCurrentGuildMember(guild_id, Types.EditCurrentGuildMember.init().withAvatar(avatar));
    }

    pub fn clearCurrentGuildMemberAvatar(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.editCurrentGuildMember(guild_id, Types.EditCurrentGuildMember.init().clearAvatar());
    }

    pub fn setCurrentGuildMemberBanner(self: *Client, guild_id: Snowflake, banner: []const u8) !Rest.Response {
        return self.editCurrentGuildMember(guild_id, Types.EditCurrentGuildMember.init().withBanner(banner));
    }

    pub fn clearCurrentGuildMemberBanner(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.editCurrentGuildMember(guild_id, Types.EditCurrentGuildMember.init().clearBanner());
    }

    pub fn setCurrentGuildMemberBio(self: *Client, guild_id: Snowflake, bio: []const u8) !Rest.Response {
        return self.editCurrentGuildMember(guild_id, Types.EditCurrentGuildMember.init().withBio(bio));
    }

    pub fn clearCurrentGuildMemberBio(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.editCurrentGuildMember(guild_id, Types.EditCurrentGuildMember.init().clearBio());
    }

    pub fn editCurrentUserNick(self: *Client, guild_id: Snowflake, payload: Types.EditCurrentUserNick) !Rest.Response {
        return self.rest.editCurrentUserNick(guild_id, payload);
    }

    pub fn setCurrentUserNick(self: *Client, guild_id: Snowflake, nick: ?[]const u8) !Rest.Response {
        const payload = if (nick) |value| Types.EditCurrentUserNick.init().withNick(value) else Types.EditCurrentUserNick.init().clearNick();
        return self.editCurrentUserNick(guild_id, payload);
    }

    pub fn setNickname(self: *Client, guild_id: Snowflake, nick: ?[]const u8) !Rest.Response {
        return self.setCurrentUserNick(guild_id, nick);
    }

    pub fn removeGuildMember(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Rest.Response {
        return self.rest.removeGuildMember(guild_id, user_id);
    }

    pub fn kick(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Rest.Response {
        return self.removeGuildMember(guild_id, user_id);
    }

    pub fn addGuildMemberRole(self: *Client, guild_id: Snowflake, user_id: Snowflake, role_id: Snowflake) !Rest.Response {
        return self.rest.addGuildMemberRole(guild_id, user_id, role_id);
    }

    pub fn addRole(self: *Client, guild_id: Snowflake, user_id: Snowflake, role_id: Snowflake) !Rest.Response {
        return self.addGuildMemberRole(guild_id, user_id, role_id);
    }

    pub fn removeGuildMemberRole(self: *Client, guild_id: Snowflake, user_id: Snowflake, role_id: Snowflake) !Rest.Response {
        return self.rest.removeGuildMemberRole(guild_id, user_id, role_id);
    }

    pub fn removeRole(self: *Client, guild_id: Snowflake, user_id: Snowflake, role_id: Snowflake) !Rest.Response {
        return self.removeGuildMemberRole(guild_id, user_id, role_id);
    }

    pub fn listGuildChannels(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.rest.listGuildChannels(guild_id);
    }

    pub fn fetchGuildChannels(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.listGuildChannels(guild_id);
    }

    pub fn createGuildChannel(self: *Client, guild_id: Snowflake, payload: Types.CreateGuildChannel) !Rest.Response {
        return self.rest.createGuildChannel(guild_id, payload);
    }

    pub fn editGuildChannelPositions(
        self: *Client,
        guild_id: Snowflake,
        positions: []const Types.GuildChannelPosition,
    ) !Rest.Response {
        return self.rest.editGuildChannelPositions(guild_id, positions);
    }

    pub fn setGuildChannelPositions(
        self: *Client,
        guild_id: Snowflake,
        positions: []const Types.GuildChannelPosition,
    ) !Rest.Response {
        return self.editGuildChannelPositions(guild_id, positions);
    }

    pub fn editChannel(self: *Client, channel_id: Snowflake, payload: Types.EditChannel) !Rest.Response {
        return self.rest.editChannel(channel_id, payload);
    }

    pub fn deleteChannel(self: *Client, channel_id: Snowflake) !Rest.Response {
        return self.rest.deleteChannel(channel_id);
    }

    pub fn editChannelPermission(
        self: *Client,
        channel_id: Snowflake,
        overwrite_id: Snowflake,
        payload: Types.EditChannelPermission,
    ) !Rest.Response {
        return self.rest.editChannelPermission(channel_id, overwrite_id, payload);
    }

    pub fn setChannelPermission(
        self: *Client,
        channel_id: Snowflake,
        overwrite_id: Snowflake,
        payload: Types.EditChannelPermission,
    ) !Rest.Response {
        return self.editChannelPermission(channel_id, overwrite_id, payload);
    }

    pub fn deleteChannelPermission(self: *Client, channel_id: Snowflake, overwrite_id: Snowflake) !Rest.Response {
        return self.rest.deleteChannelPermission(channel_id, overwrite_id);
    }

    pub fn removeChannelPermission(self: *Client, channel_id: Snowflake, overwrite_id: Snowflake) !Rest.Response {
        return self.deleteChannelPermission(channel_id, overwrite_id);
    }

    pub fn setVoiceChannelStatus(
        self: *Client,
        channel_id: Snowflake,
        payload: Types.SetVoiceChannelStatus,
    ) !Rest.Response {
        return self.rest.setVoiceChannelStatus(channel_id, payload);
    }

    pub fn setVoiceChannelStatusText(
        self: *Client,
        channel_id: Snowflake,
        status: []const u8,
    ) !Rest.Response {
        return self.setVoiceChannelStatus(channel_id, Types.SetVoiceChannelStatus.init(status));
    }

    pub fn clearVoiceChannelStatus(self: *Client, channel_id: Snowflake) !Rest.Response {
        return self.setVoiceChannelStatus(channel_id, Types.SetVoiceChannelStatus.clear());
    }

    pub fn followAnnouncementChannel(
        self: *Client,
        channel_id: Snowflake,
        payload: Types.FollowAnnouncementChannel,
    ) !Rest.Response {
        return self.rest.followAnnouncementChannel(channel_id, payload);
    }

    pub fn followAnnouncementChannelTo(
        self: *Client,
        channel_id: Snowflake,
        webhook_channel_id: Snowflake,
    ) !Rest.Response {
        return self.followAnnouncementChannel(channel_id, Types.FollowAnnouncementChannel.init(webhook_channel_id));
    }

    pub fn followNewsChannel(
        self: *Client,
        channel_id: Snowflake,
        payload: Types.FollowAnnouncementChannel,
    ) !Rest.Response {
        return self.followAnnouncementChannel(channel_id, payload);
    }

    pub fn followNewsChannelTo(
        self: *Client,
        channel_id: Snowflake,
        webhook_channel_id: Snowflake,
    ) !Rest.Response {
        return self.followAnnouncementChannelTo(channel_id, webhook_channel_id);
    }

    pub fn sendSoundboardSound(
        self: *Client,
        channel_id: Snowflake,
        payload: Types.SendSoundboardSound,
    ) !Rest.Response {
        return self.rest.sendSoundboardSound(channel_id, payload);
    }

    pub fn sendSoundboardSoundById(
        self: *Client,
        channel_id: Snowflake,
        sound_id: Snowflake,
    ) !Rest.Response {
        return self.sendSoundboardSound(channel_id, Types.SendSoundboardSound.init(sound_id));
    }

    pub fn playSoundboardSound(
        self: *Client,
        channel_id: Snowflake,
        sound_id: Snowflake,
    ) !Rest.Response {
        return self.sendSoundboardSoundById(channel_id, sound_id);
    }

    pub fn createStageInstance(self: *Client, payload: Types.CreateStageInstance) !Rest.Response {
        return self.rest.createStageInstance(payload);
    }

    pub fn getStageInstance(self: *Client, channel_id: Snowflake) !Rest.Response {
        return self.rest.getStageInstance(channel_id);
    }

    pub fn fetchStageInstance(self: *Client, channel_id: Snowflake) !Rest.Response {
        return self.getStageInstance(channel_id);
    }

    pub fn editStageInstance(self: *Client, channel_id: Snowflake, payload: Types.EditStageInstance) !Rest.Response {
        return self.rest.editStageInstance(channel_id, payload);
    }

    pub fn deleteStageInstance(self: *Client, channel_id: Snowflake) !Rest.Response {
        return self.rest.deleteStageInstance(channel_id);
    }

    pub fn listVoiceRegions(self: *Client) !Rest.Response {
        return self.rest.listVoiceRegions();
    }

    pub fn fetchVoiceRegions(self: *Client) !Rest.Response {
        return self.listVoiceRegions();
    }

    pub fn listGuildVoiceRegions(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.rest.listGuildVoiceRegions(guild_id);
    }

    pub fn fetchGuildVoiceRegions(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.listGuildVoiceRegions(guild_id);
    }

    pub fn getCurrentUserVoiceState(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.rest.getCurrentUserVoiceState(guild_id);
    }

    pub fn fetchCurrentUserVoiceState(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.getCurrentUserVoiceState(guild_id);
    }

    pub fn getUserVoiceState(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Rest.Response {
        return self.rest.getUserVoiceState(guild_id, user_id);
    }

    pub fn fetchUserVoiceState(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Rest.Response {
        return self.getUserVoiceState(guild_id, user_id);
    }

    pub fn editCurrentUserVoiceState(
        self: *Client,
        guild_id: Snowflake,
        payload: Types.EditCurrentUserVoiceState,
    ) !Rest.Response {
        return self.rest.editCurrentUserVoiceState(guild_id, payload);
    }

    pub fn editUserVoiceState(
        self: *Client,
        guild_id: Snowflake,
        user_id: Snowflake,
        payload: Types.EditUserVoiceState,
    ) !Rest.Response {
        return self.rest.editUserVoiceState(guild_id, user_id, payload);
    }

    pub fn listGuildRoles(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.rest.listGuildRoles(guild_id);
    }

    pub fn fetchRoles(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.listGuildRoles(guild_id);
    }

    pub fn getGuildRole(self: *Client, guild_id: Snowflake, role_id: Snowflake) !Rest.Response {
        return self.rest.getGuildRole(guild_id, role_id);
    }

    pub fn fetchRole(self: *Client, guild_id: Snowflake, role_id: Snowflake) !Rest.Response {
        return self.getGuildRole(guild_id, role_id);
    }

    pub fn getGuildRoleMemberCounts(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.rest.getGuildRoleMemberCounts(guild_id);
    }

    pub fn fetchRoleMemberCounts(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.getGuildRoleMemberCounts(guild_id);
    }

    pub fn createGuildRole(self: *Client, guild_id: Snowflake, payload: Types.CreateGuildRole) !Rest.Response {
        return self.rest.createGuildRole(guild_id, payload);
    }

    pub fn createRoleWithName(self: *Client, guild_id: Snowflake, name: []const u8) !Rest.Response {
        return self.createGuildRole(guild_id, Types.CreateGuildRole.init(name));
    }

    pub fn editGuildRolePositions(self: *Client, guild_id: Snowflake, positions: []const Types.GuildRolePosition) !Rest.Response {
        return self.rest.editGuildRolePositions(guild_id, positions);
    }

    pub fn editGuildRole(
        self: *Client,
        guild_id: Snowflake,
        role_id: Snowflake,
        payload: Types.EditGuildRole,
    ) !Rest.Response {
        return self.rest.editGuildRole(guild_id, role_id, payload);
    }

    pub fn renameRole(self: *Client, guild_id: Snowflake, role_id: Snowflake, name: []const u8) !Rest.Response {
        return self.editGuildRole(guild_id, role_id, Types.EditGuildRole.init().withName(name));
    }

    pub fn deleteGuildRole(self: *Client, guild_id: Snowflake, role_id: Snowflake) !Rest.Response {
        return self.rest.deleteGuildRole(guild_id, role_id);
    }

    pub fn listGuildEmojis(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.rest.listGuildEmojis(guild_id);
    }

    pub fn fetchEmojis(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.listGuildEmojis(guild_id);
    }

    pub fn getGuildEmoji(self: *Client, guild_id: Snowflake, emoji_id: Snowflake) !Rest.Response {
        return self.rest.getGuildEmoji(guild_id, emoji_id);
    }

    pub fn fetchEmoji(self: *Client, guild_id: Snowflake, emoji_id: Snowflake) !Rest.Response {
        return self.getGuildEmoji(guild_id, emoji_id);
    }

    pub fn createGuildEmoji(self: *Client, guild_id: Snowflake, payload: Types.CreateGuildEmoji) !Rest.Response {
        return self.rest.createGuildEmoji(guild_id, payload);
    }

    pub fn createEmojiWithImage(
        self: *Client,
        guild_id: Snowflake,
        name: []const u8,
        image: []const u8,
    ) !Rest.Response {
        return self.createGuildEmoji(guild_id, Types.CreateGuildEmoji.init(name, image));
    }

    pub fn editGuildEmoji(
        self: *Client,
        guild_id: Snowflake,
        emoji_id: Snowflake,
        payload: Types.EditGuildEmoji,
    ) !Rest.Response {
        return self.rest.editGuildEmoji(guild_id, emoji_id, payload);
    }

    pub fn renameEmoji(self: *Client, guild_id: Snowflake, emoji_id: Snowflake, name: []const u8) !Rest.Response {
        return self.editGuildEmoji(guild_id, emoji_id, Types.EditGuildEmoji.init().withName(name));
    }

    pub fn deleteGuildEmoji(self: *Client, guild_id: Snowflake, emoji_id: Snowflake) !Rest.Response {
        return self.rest.deleteGuildEmoji(guild_id, emoji_id);
    }

    pub fn getSticker(self: *Client, sticker_id: Snowflake) !Rest.Response {
        return self.rest.getSticker(sticker_id);
    }

    pub fn fetchStickerById(self: *Client, sticker_id: Snowflake) !Rest.Response {
        return self.getSticker(sticker_id);
    }

    pub fn listStickerPacks(self: *Client) !Rest.Response {
        return self.rest.listStickerPacks();
    }

    pub fn fetchStickerPacks(self: *Client) !Rest.Response {
        return self.listStickerPacks();
    }

    pub fn listGuildStickers(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.rest.listGuildStickers(guild_id);
    }

    pub fn fetchStickers(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.listGuildStickers(guild_id);
    }

    pub fn getGuildSticker(self: *Client, guild_id: Snowflake, sticker_id: Snowflake) !Rest.Response {
        return self.rest.getGuildSticker(guild_id, sticker_id);
    }

    pub fn fetchSticker(self: *Client, guild_id: Snowflake, sticker_id: Snowflake) !Rest.Response {
        return self.getGuildSticker(guild_id, sticker_id);
    }

    pub fn createGuildSticker(
        self: *Client,
        guild_id: Snowflake,
        payload: Types.CreateGuildSticker,
        file: Types.UploadFile,
    ) !Rest.Response {
        return self.rest.createGuildSticker(guild_id, payload, file);
    }

    pub fn editGuildSticker(
        self: *Client,
        guild_id: Snowflake,
        sticker_id: Snowflake,
        payload: Types.EditGuildSticker,
    ) !Rest.Response {
        return self.rest.editGuildSticker(guild_id, sticker_id, payload);
    }

    pub fn renameSticker(self: *Client, guild_id: Snowflake, sticker_id: Snowflake, name: []const u8) !Rest.Response {
        return self.editGuildSticker(guild_id, sticker_id, Types.EditGuildSticker.init().withName(name));
    }

    pub fn setStickerDescription(
        self: *Client,
        guild_id: Snowflake,
        sticker_id: Snowflake,
        description: []const u8,
    ) !Rest.Response {
        return self.editGuildSticker(guild_id, sticker_id, Types.EditGuildSticker.init().withDescription(description));
    }

    pub fn setStickerTags(
        self: *Client,
        guild_id: Snowflake,
        sticker_id: Snowflake,
        tags: []const u8,
    ) !Rest.Response {
        return self.editGuildSticker(guild_id, sticker_id, Types.EditGuildSticker.init().withTags(tags));
    }

    pub fn deleteGuildSticker(self: *Client, guild_id: Snowflake, sticker_id: Snowflake) !Rest.Response {
        return self.rest.deleteGuildSticker(guild_id, sticker_id);
    }

    pub fn listDefaultSoundboardSounds(self: *Client) !Rest.Response {
        return self.rest.listDefaultSoundboardSounds();
    }

    pub fn fetchDefaultSoundboardSounds(self: *Client) !Rest.Response {
        return self.listDefaultSoundboardSounds();
    }

    pub fn listGuildSoundboardSounds(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.rest.listGuildSoundboardSounds(guild_id);
    }

    pub fn fetchGuildSoundboardSounds(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.listGuildSoundboardSounds(guild_id);
    }

    pub fn getGuildSoundboardSound(self: *Client, guild_id: Snowflake, sound_id: Snowflake) !Rest.Response {
        return self.rest.getGuildSoundboardSound(guild_id, sound_id);
    }

    pub fn fetchGuildSoundboardSound(self: *Client, guild_id: Snowflake, sound_id: Snowflake) !Rest.Response {
        return self.getGuildSoundboardSound(guild_id, sound_id);
    }

    pub fn createGuildSoundboardSound(
        self: *Client,
        guild_id: Snowflake,
        payload: Types.CreateGuildSoundboardSound,
    ) !Rest.Response {
        return self.rest.createGuildSoundboardSound(guild_id, payload);
    }

    pub fn createSoundboardSoundWithData(
        self: *Client,
        guild_id: Snowflake,
        name: []const u8,
        sound: []const u8,
    ) !Rest.Response {
        return self.createGuildSoundboardSound(guild_id, Types.CreateGuildSoundboardSound.init(name, sound));
    }

    pub fn editGuildSoundboardSound(
        self: *Client,
        guild_id: Snowflake,
        sound_id: Snowflake,
        payload: Types.EditGuildSoundboardSound,
    ) !Rest.Response {
        return self.rest.editGuildSoundboardSound(guild_id, sound_id, payload);
    }

    pub fn renameSoundboardSound(
        self: *Client,
        guild_id: Snowflake,
        sound_id: Snowflake,
        name: []const u8,
    ) !Rest.Response {
        return self.editGuildSoundboardSound(guild_id, sound_id, Types.EditGuildSoundboardSound.init().withName(name));
    }

    pub fn deleteGuildSoundboardSound(self: *Client, guild_id: Snowflake, sound_id: Snowflake) !Rest.Response {
        return self.rest.deleteGuildSoundboardSound(guild_id, sound_id);
    }

    pub fn sendFiles(
        self: *Client,
        channel_id: Snowflake,
        payload: Types.CreateMessage,
        files: []const Types.UploadFile,
    ) !Rest.Response {
        return self.rest.createMessageWithFiles(channel_id, payload, files);
    }

    pub fn sendMessageWithFiles(
        self: *Client,
        channel_id: Snowflake,
        payload: Types.CreateMessage,
        files: []const Types.UploadFile,
    ) !Rest.Response {
        return self.sendFiles(channel_id, payload, files);
    }

    pub fn sendWithFiles(
        self: *Client,
        channel_id: Snowflake,
        payload: Types.CreateMessage,
        files: []const Types.UploadFile,
    ) !Rest.Response {
        return self.sendFiles(channel_id, payload, files);
    }

    pub fn sendFilePaths(
        self: *Client,
        channel_id: Snowflake,
        payload: Types.CreateMessage,
        files: []const Types.UploadFilePath,
    ) !Rest.Response {
        return self.rest.createMessageWithFilePaths(channel_id, payload, files);
    }

    pub fn sendMessageWithFilePaths(
        self: *Client,
        channel_id: Snowflake,
        payload: Types.CreateMessage,
        files: []const Types.UploadFilePath,
    ) !Rest.Response {
        return self.sendFilePaths(channel_id, payload, files);
    }

    pub fn sendWithFilePaths(
        self: *Client,
        channel_id: Snowflake,
        payload: Types.CreateMessage,
        files: []const Types.UploadFilePath,
    ) !Rest.Response {
        return self.sendFilePaths(channel_id, payload, files);
    }

    pub fn reply(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        payload: Types.CreateMessage,
    ) !Rest.Response {
        var reply_payload = payload;
        reply_payload.message_reference = .{ .type = .default, .message_id = message_id, .channel_id = channel_id };
        return self.rest.createMessage(channel_id, reply_payload);
    }

    pub fn replyMessage(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        payload: Types.CreateMessage,
    ) !Rest.Response {
        return self.reply(channel_id, message_id, payload);
    }

    pub fn replyWithContent(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        content: []const u8,
    ) !Rest.Response {
        return self.reply(channel_id, message_id, Types.CreateMessage.init(content));
    }

    pub fn replyMessageWithContent(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        content: []const u8,
    ) !Rest.Response {
        return self.replyWithContent(channel_id, message_id, content);
    }

    pub fn replyText(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        content: []const u8,
    ) !Rest.Response {
        return self.replyWithContent(channel_id, message_id, content);
    }

    pub fn forwardMessage(
        self: *Client,
        target_channel_id: Snowflake,
        source_channel_id: Snowflake,
        message_id: Snowflake,
    ) !Rest.Response {
        return self.rest.createMessage(
            target_channel_id,
            Types.CreateMessage.empty().withReference(Types.MessageReference.forward(message_id, source_channel_id)),
        );
    }

    pub fn forward(
        self: *Client,
        target_channel_id: Snowflake,
        source_channel_id: Snowflake,
        message_id: Snowflake,
    ) !Rest.Response {
        return self.forwardMessage(target_channel_id, source_channel_id, message_id);
    }

    pub fn editMessage(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        payload: Types.EditMessage,
    ) !Rest.Response {
        return self.rest.editMessage(channel_id, message_id, payload);
    }

    pub fn edit(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        payload: Types.EditMessage,
    ) !Rest.Response {
        return self.editMessage(channel_id, message_id, payload);
    }

    pub fn editMessageWithContent(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        content: []const u8,
    ) !Rest.Response {
        return self.editMessage(channel_id, message_id, Types.EditMessage.init().withContent(content));
    }

    pub fn editWithContent(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        content: []const u8,
    ) !Rest.Response {
        return self.editMessageWithContent(channel_id, message_id, content);
    }

    pub fn editText(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        content: []const u8,
    ) !Rest.Response {
        return self.editMessageWithContent(channel_id, message_id, content);
    }

    pub fn setEmbedsSuppressed(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        suppressed: bool,
    ) !Rest.Response {
        return self.editMessage(
            channel_id,
            message_id,
            Types.EditMessage.init().withFlags(if (suppressed) Types.MessageFlags.suppress_embeds else 0),
        );
    }

    pub fn suppressEmbeds(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
        return self.setEmbedsSuppressed(channel_id, message_id, true);
    }

    pub fn unsuppressEmbeds(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
        return self.setEmbedsSuppressed(channel_id, message_id, false);
    }

    pub fn deleteMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
        return self.rest.deleteMessage(channel_id, message_id);
    }

    pub fn delete(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
        return self.deleteMessage(channel_id, message_id);
    }

    pub fn crosspostMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
        return self.rest.crosspostMessage(channel_id, message_id);
    }

    pub fn crosspost(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
        return self.crosspostMessage(channel_id, message_id);
    }

    pub fn publishMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
        return self.crosspostMessage(channel_id, message_id);
    }

    pub fn publish(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
        return self.publishMessage(channel_id, message_id);
    }

    pub fn getMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
        return self.rest.getMessage(channel_id, message_id);
    }

    pub fn fetchMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
        return self.getMessage(channel_id, message_id);
    }

    pub fn listMessages(self: *Client, channel_id: Snowflake) !Rest.Response {
        return self.rest.listMessages(channel_id);
    }

    pub fn listMessagesWithOptions(self: *Client, channel_id: Snowflake, options: Types.ListMessages) !Rest.Response {
        return self.rest.listMessagesWithOptions(channel_id, options);
    }

    pub fn fetchMessages(self: *Client, channel_id: Snowflake, options: Types.ListMessages) !Rest.Response {
        return self.listMessagesWithOptions(channel_id, options);
    }

    pub fn bulkDeleteMessages(self: *Client, channel_id: Snowflake, messages: []const Snowflake) !Rest.Response {
        return self.rest.bulkDeleteMessages(channel_id, messages);
    }

    pub fn bulkDelete(self: *Client, channel_id: Snowflake, messages: []const Snowflake) !Rest.Response {
        return self.bulkDeleteMessages(channel_id, messages);
    }

    pub fn sendTyping(self: *Client, channel_id: Snowflake) !Rest.Response {
        return self.rest.triggerTyping(channel_id);
    }

    pub fn triggerTyping(self: *Client, channel_id: Snowflake) !Rest.Response {
        return self.sendTyping(channel_id);
    }

    pub fn listPinnedMessages(self: *Client, channel_id: Snowflake) !Rest.Response {
        return self.rest.listPinnedMessages(channel_id);
    }

    pub fn fetchPinnedMessages(self: *Client, channel_id: Snowflake) !Rest.Response {
        return self.listPinnedMessages(channel_id);
    }

    pub fn listChannelPins(self: *Client, channel_id: Snowflake, options: Types.ListChannelPins) !Rest.Response {
        return self.rest.listChannelPins(channel_id, options);
    }

    pub fn fetchPins(self: *Client, channel_id: Snowflake, options: Types.ListChannelPins) !Rest.Response {
        return self.listChannelPins(channel_id, options);
    }

    pub fn pinMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
        return self.rest.pinMessage(channel_id, message_id);
    }

    pub fn pin(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
        return self.pinMessage(channel_id, message_id);
    }

    pub fn unpinMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
        return self.rest.unpinMessage(channel_id, message_id);
    }

    pub fn unpin(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
        return self.unpinMessage(channel_id, message_id);
    }

    pub fn createThread(self: *Client, channel_id: Snowflake, payload: Types.CreateThread) !Rest.Response {
        return self.rest.createThread(channel_id, payload);
    }

    pub fn createThreadWithName(self: *Client, channel_id: Snowflake, name: []const u8) !Rest.Response {
        return self.createThread(channel_id, Types.CreateThread.init(name));
    }

    pub fn createForumThread(self: *Client, channel_id: Snowflake, payload: Types.CreateForumThread) !Rest.Response {
        return self.rest.createForumThread(channel_id, payload);
    }

    pub fn startThreadInForum(self: *Client, channel_id: Snowflake, payload: Types.CreateForumThread) !Rest.Response {
        return self.createForumThread(channel_id, payload);
    }

    pub fn startThreadInMedia(self: *Client, channel_id: Snowflake, payload: Types.CreateForumThread) !Rest.Response {
        return self.createForumThread(channel_id, payload);
    }

    pub fn listActiveGuildThreads(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.rest.listActiveGuildThreads(guild_id);
    }

    pub fn fetchActiveThreads(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.listActiveGuildThreads(guild_id);
    }

    pub fn joinThread(self: *Client, thread_id: Snowflake) !Rest.Response {
        return self.rest.joinThread(thread_id);
    }

    pub fn leaveThread(self: *Client, thread_id: Snowflake) !Rest.Response {
        return self.rest.leaveThread(thread_id);
    }

    pub fn addThreadMember(self: *Client, thread_id: Snowflake, user_id: Snowflake) !Rest.Response {
        return self.rest.addThreadMember(thread_id, user_id);
    }

    pub fn getThreadMember(self: *Client, thread_id: Snowflake, user_id: Snowflake) !Rest.Response {
        return self.rest.getThreadMember(thread_id, user_id);
    }

    pub fn fetchThreadMember(self: *Client, thread_id: Snowflake, user_id: Snowflake) !Rest.Response {
        return self.getThreadMember(thread_id, user_id);
    }

    pub fn removeThreadMember(self: *Client, thread_id: Snowflake, user_id: Snowflake) !Rest.Response {
        return self.rest.removeThreadMember(thread_id, user_id);
    }

    pub fn listThreadMembers(self: *Client, thread_id: Snowflake) !Rest.Response {
        return self.rest.listThreadMembers(thread_id);
    }

    pub fn fetchThreadMembers(self: *Client, thread_id: Snowflake) !Rest.Response {
        return self.listThreadMembers(thread_id);
    }

    pub fn listThreadMembersWithOptions(
        self: *Client,
        thread_id: Snowflake,
        options: Types.ListThreadMembers,
    ) !Rest.Response {
        return self.rest.listThreadMembersWithOptions(thread_id, options);
    }

    pub fn fetchThreadMembersWithOptions(
        self: *Client,
        thread_id: Snowflake,
        options: Types.ListThreadMembers,
    ) !Rest.Response {
        return self.listThreadMembersWithOptions(thread_id, options);
    }

    pub fn listPublicArchivedThreads(
        self: *Client,
        channel_id: Snowflake,
        options: Types.ListArchivedThreads,
    ) !Rest.Response {
        return self.rest.listPublicArchivedThreads(channel_id, options);
    }

    pub fn fetchPublicArchivedThreads(
        self: *Client,
        channel_id: Snowflake,
        options: Types.ListArchivedThreads,
    ) !Rest.Response {
        return self.listPublicArchivedThreads(channel_id, options);
    }

    pub fn listPrivateArchivedThreads(
        self: *Client,
        channel_id: Snowflake,
        options: Types.ListArchivedThreads,
    ) !Rest.Response {
        return self.rest.listPrivateArchivedThreads(channel_id, options);
    }

    pub fn fetchPrivateArchivedThreads(
        self: *Client,
        channel_id: Snowflake,
        options: Types.ListArchivedThreads,
    ) !Rest.Response {
        return self.listPrivateArchivedThreads(channel_id, options);
    }

    pub fn listJoinedPrivateArchivedThreads(
        self: *Client,
        channel_id: Snowflake,
        options: Types.ListArchivedThreads,
    ) !Rest.Response {
        return self.rest.listJoinedPrivateArchivedThreads(channel_id, options);
    }

    pub fn fetchJoinedPrivateArchivedThreads(
        self: *Client,
        channel_id: Snowflake,
        options: Types.ListArchivedThreads,
    ) !Rest.Response {
        return self.listJoinedPrivateArchivedThreads(channel_id, options);
    }

    pub fn createThreadFromMessage(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        payload: Types.CreateThreadFromMessage,
    ) !Rest.Response {
        return self.rest.createThreadFromMessage(channel_id, message_id, payload);
    }

    pub fn startThreadFromMessage(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        payload: Types.CreateThreadFromMessage,
    ) !Rest.Response {
        return self.createThreadFromMessage(channel_id, message_id, payload);
    }

    pub fn startThreadFromMessageWithName(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        name: []const u8,
    ) !Rest.Response {
        return self.createThreadFromMessage(channel_id, message_id, Types.CreateThreadFromMessage.init(name));
    }

    pub fn addGroupDmRecipient(
        self: *Client,
        channel_id: Snowflake,
        user_id: Snowflake,
        payload: Types.AddGroupDmRecipient,
    ) !Rest.Response {
        return self.rest.addGroupDmRecipient(channel_id, user_id, payload);
    }

    pub fn removeGroupDmRecipient(self: *Client, channel_id: Snowflake, user_id: Snowflake) !Rest.Response {
        return self.rest.removeGroupDmRecipient(channel_id, user_id);
    }

    pub fn createInvite(self: *Client, channel_id: Snowflake, payload: Types.CreateChannelInvite) !Rest.Response {
        return self.rest.createChannelInvite(channel_id, payload);
    }

    pub fn createDefaultInvite(self: *Client, channel_id: Snowflake) !Rest.Response {
        return self.createInvite(channel_id, Types.CreateChannelInvite.init());
    }

    pub fn createInviteWithMaxUses(
        self: *Client,
        channel_id: Snowflake,
        max_uses: u16,
    ) !Rest.Response {
        return self.createInvite(channel_id, Types.CreateChannelInvite.init().withMaxUses(max_uses));
    }

    pub fn createInviteWithMaxAge(
        self: *Client,
        channel_id: Snowflake,
        max_age: u32,
    ) !Rest.Response {
        return self.createInvite(channel_id, Types.CreateChannelInvite.init().withMaxAge(max_age));
    }

    pub fn createUniqueInvite(self: *Client, channel_id: Snowflake) !Rest.Response {
        return self.createInvite(channel_id, Types.CreateChannelInvite.init().uniqueState(true));
    }

    pub fn listChannelInvites(self: *Client, channel_id: Snowflake) !Rest.Response {
        return self.rest.listChannelInvites(channel_id);
    }

    pub fn fetchChannelInvites(self: *Client, channel_id: Snowflake) !Rest.Response {
        return self.listChannelInvites(channel_id);
    }

    pub fn listGuildInvites(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.rest.listGuildInvites(guild_id);
    }

    pub fn fetchGuildInvites(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.listGuildInvites(guild_id);
    }

    pub fn getInvite(self: *Client, code: []const u8) !Rest.Response {
        return self.rest.getInvite(code);
    }

    pub fn fetchInvite(self: *Client, code: []const u8) !Rest.Response {
        return self.getInvite(code);
    }

    pub fn getInviteWithOptions(self: *Client, code: []const u8, options: Types.GetInvite) !Rest.Response {
        return self.rest.getInviteWithOptions(code, options);
    }

    pub fn fetchInviteWithOptions(self: *Client, code: []const u8, options: Types.GetInvite) !Rest.Response {
        return self.getInviteWithOptions(code, options);
    }

    pub fn deleteInvite(self: *Client, code: []const u8) !Rest.Response {
        return self.rest.deleteInvite(code);
    }

    pub fn getInviteTargetUsers(self: *Client, code: []const u8) !Rest.Response {
        return self.rest.getInviteTargetUsers(code);
    }

    pub fn listInviteTargetUsers(self: *Client, code: []const u8) !Rest.Response {
        return self.getInviteTargetUsers(code);
    }

    pub fn fetchInviteTargetUsers(self: *Client, code: []const u8) !Rest.Response {
        return self.getInviteTargetUsers(code);
    }

    pub fn updateInviteTargetUsers(self: *Client, code: []const u8, file: Types.UploadFile) !Rest.Response {
        return self.rest.updateInviteTargetUsers(code, file);
    }

    pub fn setInviteTargetUsers(self: *Client, code: []const u8, file: Types.UploadFile) !Rest.Response {
        return self.updateInviteTargetUsers(code, file);
    }

    pub fn getInviteTargetUsersJobStatus(self: *Client, code: []const u8) !Rest.Response {
        return self.rest.getInviteTargetUsersJobStatus(code);
    }

    pub fn fetchInviteTargetUsersJobStatus(self: *Client, code: []const u8) !Rest.Response {
        return self.getInviteTargetUsersJobStatus(code);
    }

    pub fn listChannelWebhooks(self: *Client, channel_id: Snowflake) !Rest.Response {
        return self.rest.listChannelWebhooks(channel_id);
    }

    pub fn fetchChannelWebhooks(self: *Client, channel_id: Snowflake) !Rest.Response {
        return self.listChannelWebhooks(channel_id);
    }

    pub fn createWebhook(self: *Client, channel_id: Snowflake, payload: Types.CreateWebhook) !Rest.Response {
        return self.rest.createWebhook(channel_id, payload);
    }

    pub fn createWebhookWithName(
        self: *Client,
        channel_id: Snowflake,
        name: []const u8,
    ) !Rest.Response {
        return self.createWebhook(channel_id, Types.CreateWebhook.init(name));
    }

    pub fn createWebhookWithAvatar(
        self: *Client,
        channel_id: Snowflake,
        name: []const u8,
        avatar: []const u8,
    ) !Rest.Response {
        return self.createWebhook(channel_id, Types.CreateWebhook.init(name).withAvatar(avatar));
    }

    pub fn listGuildWebhooks(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.rest.listGuildWebhooks(guild_id);
    }

    pub fn fetchGuildWebhooks(self: *Client, guild_id: Snowflake) !Rest.Response {
        return self.listGuildWebhooks(guild_id);
    }

    pub fn getWebhook(self: *Client, webhook_id: Snowflake) !Rest.Response {
        return self.rest.getWebhook(webhook_id);
    }

    pub fn fetchWebhook(self: *Client, webhook_id: Snowflake) !Rest.Response {
        return self.getWebhook(webhook_id);
    }

    pub fn editWebhook(self: *Client, webhook_id: Snowflake, payload: Types.EditWebhook) !Rest.Response {
        return self.rest.editWebhook(webhook_id, payload);
    }

    pub fn deleteWebhook(self: *Client, webhook_id: Snowflake) !Rest.Response {
        return self.rest.deleteWebhook(webhook_id);
    }

    pub fn getWebhookWithToken(self: *Client, webhook_id: Snowflake, webhook_token: []const u8) !Rest.Response {
        return self.rest.getWebhookWithToken(webhook_id, webhook_token);
    }

    pub fn fetchWebhookWithToken(self: *Client, webhook_id: Snowflake, webhook_token: []const u8) !Rest.Response {
        return self.getWebhookWithToken(webhook_id, webhook_token);
    }

    pub fn editWebhookWithToken(
        self: *Client,
        webhook_id: Snowflake,
        webhook_token: []const u8,
        payload: Types.EditWebhookWithToken,
    ) !Rest.Response {
        return self.rest.editWebhookWithToken(webhook_id, webhook_token, payload);
    }

    pub fn deleteWebhookWithToken(self: *Client, webhook_id: Snowflake, webhook_token: []const u8) !Rest.Response {
        return self.rest.deleteWebhookWithToken(webhook_id, webhook_token);
    }

    pub fn executeWebhook(
        self: *Client,
        webhook_id: Snowflake,
        webhook_token: []const u8,
        payload: Types.ExecuteWebhook,
    ) !Rest.Response {
        return self.rest.executeWebhook(webhook_id, webhook_token, payload);
    }

    pub fn executeWebhookWithContent(
        self: *Client,
        webhook_id: Snowflake,
        webhook_token: []const u8,
        content: []const u8,
    ) !Rest.Response {
        return self.executeWebhook(webhook_id, webhook_token, Types.ExecuteWebhook.init(content));
    }

    pub fn executeWebhookWithFiles(
        self: *Client,
        webhook_id: Snowflake,
        webhook_token: []const u8,
        payload: Types.ExecuteWebhook,
        files: []const Types.UploadFile,
    ) !Rest.Response {
        return self.rest.executeWebhookWithFiles(webhook_id, webhook_token, payload, files);
    }

    pub fn executeWebhookWithOptionsAndFiles(
        self: *Client,
        webhook_id: Snowflake,
        webhook_token: []const u8,
        options: Types.ExecuteWebhookQuery,
        payload: Types.ExecuteWebhook,
        files: []const Types.UploadFile,
    ) !Rest.Response {
        return self.rest.executeWebhookWithOptionsAndFiles(webhook_id, webhook_token, options, payload, files);
    }

    pub fn getWebhookMessage(
        self: *Client,
        webhook_id: Snowflake,
        webhook_token: []const u8,
        message_id: Snowflake,
    ) !Rest.Response {
        return self.rest.getWebhookMessage(webhook_id, webhook_token, message_id);
    }

    pub fn fetchWebhookMessage(
        self: *Client,
        webhook_id: Snowflake,
        webhook_token: []const u8,
        message_id: Snowflake,
    ) !Rest.Response {
        return self.getWebhookMessage(webhook_id, webhook_token, message_id);
    }

    pub fn editWebhookMessage(
        self: *Client,
        webhook_id: Snowflake,
        webhook_token: []const u8,
        message_id: Snowflake,
        payload: Types.EditMessage,
    ) !Rest.Response {
        return self.rest.editWebhookMessage(webhook_id, webhook_token, message_id, payload);
    }

    pub fn deleteWebhookMessage(
        self: *Client,
        webhook_id: Snowflake,
        webhook_token: []const u8,
        message_id: Snowflake,
    ) !Rest.Response {
        return self.rest.deleteWebhookMessage(webhook_id, webhook_token, message_id);
    }

    pub fn listGlobalApplicationCommands(self: *Client, application_id: Snowflake) !Rest.Response {
        return self.rest.listGlobalApplicationCommands(application_id);
    }

    pub fn fetchGlobalApplicationCommands(self: *Client, application_id: Snowflake) !Rest.Response {
        return self.listGlobalApplicationCommands(application_id);
    }

    pub fn createGlobalApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        command: Interactions.ApplicationCommand,
    ) !Rest.Response {
        return self.rest.createGlobalApplicationCommand(application_id, command);
    }

    pub fn registerGlobalApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        command: Interactions.ApplicationCommand,
    ) !Rest.Response {
        return self.createGlobalApplicationCommand(application_id, command);
    }

    pub fn bulkOverwriteGlobalApplicationCommands(
        self: *Client,
        application_id: Snowflake,
        commands: []const Interactions.ApplicationCommand,
    ) !Rest.Response {
        return self.rest.bulkOverwriteGlobalApplicationCommands(application_id, commands);
    }

    pub fn setGlobalApplicationCommands(
        self: *Client,
        application_id: Snowflake,
        commands: []const Interactions.ApplicationCommand,
    ) !Rest.Response {
        return self.bulkOverwriteGlobalApplicationCommands(application_id, commands);
    }

    pub fn getGlobalApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        command_id: Snowflake,
    ) !Rest.Response {
        return self.rest.getGlobalApplicationCommand(application_id, command_id);
    }

    pub fn fetchGlobalApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        command_id: Snowflake,
    ) !Rest.Response {
        return self.getGlobalApplicationCommand(application_id, command_id);
    }

    pub fn editGlobalApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        command_id: Snowflake,
        command: Interactions.EditApplicationCommand,
    ) !Rest.Response {
        return self.rest.editGlobalApplicationCommand(application_id, command_id, command);
    }

    pub fn updateGlobalApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        command_id: Snowflake,
        command: Interactions.EditApplicationCommand,
    ) !Rest.Response {
        return self.editGlobalApplicationCommand(application_id, command_id, command);
    }

    pub fn renameGlobalApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        command_id: Snowflake,
        name: []const u8,
    ) !Rest.Response {
        return self.editGlobalApplicationCommand(
            application_id,
            command_id,
            Interactions.EditApplicationCommand.init().withName(name),
        );
    }

    pub fn setGlobalApplicationCommandDescription(
        self: *Client,
        application_id: Snowflake,
        command_id: Snowflake,
        description: []const u8,
    ) !Rest.Response {
        return self.editGlobalApplicationCommand(
            application_id,
            command_id,
            Interactions.EditApplicationCommand.init().withDescription(description),
        );
    }

    pub fn deleteGlobalApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        command_id: Snowflake,
    ) !Rest.Response {
        return self.rest.deleteGlobalApplicationCommand(application_id, command_id);
    }

    pub fn removeGlobalApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        command_id: Snowflake,
    ) !Rest.Response {
        return self.deleteGlobalApplicationCommand(application_id, command_id);
    }

    pub fn listGuildApplicationCommands(
        self: *Client,
        application_id: Snowflake,
        guild_id: Snowflake,
    ) !Rest.Response {
        return self.rest.listGuildApplicationCommands(application_id, guild_id);
    }

    pub fn fetchGuildApplicationCommands(
        self: *Client,
        application_id: Snowflake,
        guild_id: Snowflake,
    ) !Rest.Response {
        return self.listGuildApplicationCommands(application_id, guild_id);
    }

    pub fn createGuildApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        guild_id: Snowflake,
        command: Interactions.ApplicationCommand,
    ) !Rest.Response {
        return self.rest.createGuildApplicationCommand(application_id, guild_id, command);
    }

    pub fn registerGuildApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        guild_id: Snowflake,
        command: Interactions.ApplicationCommand,
    ) !Rest.Response {
        return self.createGuildApplicationCommand(application_id, guild_id, command);
    }

    pub fn bulkOverwriteGuildApplicationCommands(
        self: *Client,
        application_id: Snowflake,
        guild_id: Snowflake,
        commands: []const Interactions.ApplicationCommand,
    ) !Rest.Response {
        return self.rest.bulkOverwriteGuildApplicationCommands(application_id, guild_id, commands);
    }

    pub fn setGuildApplicationCommands(
        self: *Client,
        application_id: Snowflake,
        guild_id: Snowflake,
        commands: []const Interactions.ApplicationCommand,
    ) !Rest.Response {
        return self.bulkOverwriteGuildApplicationCommands(application_id, guild_id, commands);
    }

    pub fn getGuildApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        guild_id: Snowflake,
        command_id: Snowflake,
    ) !Rest.Response {
        return self.rest.getGuildApplicationCommand(application_id, guild_id, command_id);
    }

    pub fn fetchGuildApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        guild_id: Snowflake,
        command_id: Snowflake,
    ) !Rest.Response {
        return self.getGuildApplicationCommand(application_id, guild_id, command_id);
    }

    pub fn editGuildApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        guild_id: Snowflake,
        command_id: Snowflake,
        command: Interactions.EditApplicationCommand,
    ) !Rest.Response {
        return self.rest.editGuildApplicationCommand(application_id, guild_id, command_id, command);
    }

    pub fn updateGuildApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        guild_id: Snowflake,
        command_id: Snowflake,
        command: Interactions.EditApplicationCommand,
    ) !Rest.Response {
        return self.editGuildApplicationCommand(application_id, guild_id, command_id, command);
    }

    pub fn renameGuildApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        guild_id: Snowflake,
        command_id: Snowflake,
        name: []const u8,
    ) !Rest.Response {
        return self.editGuildApplicationCommand(
            application_id,
            guild_id,
            command_id,
            Interactions.EditApplicationCommand.init().withName(name),
        );
    }

    pub fn setGuildApplicationCommandDescription(
        self: *Client,
        application_id: Snowflake,
        guild_id: Snowflake,
        command_id: Snowflake,
        description: []const u8,
    ) !Rest.Response {
        return self.editGuildApplicationCommand(
            application_id,
            guild_id,
            command_id,
            Interactions.EditApplicationCommand.init().withDescription(description),
        );
    }

    pub fn deleteGuildApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        guild_id: Snowflake,
        command_id: Snowflake,
    ) !Rest.Response {
        return self.rest.deleteGuildApplicationCommand(application_id, guild_id, command_id);
    }

    pub fn removeGuildApplicationCommand(
        self: *Client,
        application_id: Snowflake,
        guild_id: Snowflake,
        command_id: Snowflake,
    ) !Rest.Response {
        return self.deleteGuildApplicationCommand(application_id, guild_id, command_id);
    }

    pub fn listGuildApplicationCommandPermissions(
        self: *Client,
        bearer_token: []const u8,
        application_id: Snowflake,
        guild_id: Snowflake,
    ) !Rest.Response {
        return self.rest.listGuildApplicationCommandPermissions(bearer_token, application_id, guild_id);
    }

    pub fn fetchGuildApplicationCommandPermissions(
        self: *Client,
        bearer_token: []const u8,
        application_id: Snowflake,
        guild_id: Snowflake,
    ) !Rest.Response {
        return self.listGuildApplicationCommandPermissions(bearer_token, application_id, guild_id);
    }

    pub fn getApplicationCommandPermissions(
        self: *Client,
        bearer_token: []const u8,
        application_id: Snowflake,
        guild_id: Snowflake,
        command_id: Snowflake,
    ) !Rest.Response {
        return self.rest.getApplicationCommandPermissions(bearer_token, application_id, guild_id, command_id);
    }

    pub fn fetchApplicationCommandPermissions(
        self: *Client,
        bearer_token: []const u8,
        application_id: Snowflake,
        guild_id: Snowflake,
        command_id: Snowflake,
    ) !Rest.Response {
        return self.getApplicationCommandPermissions(bearer_token, application_id, guild_id, command_id);
    }

    pub fn editApplicationCommandPermissions(
        self: *Client,
        bearer_token: []const u8,
        application_id: Snowflake,
        guild_id: Snowflake,
        command_id: Snowflake,
        permissions: []const Interactions.ApplicationCommandPermission,
    ) !Rest.Response {
        return self.rest.editApplicationCommandPermissions(bearer_token, application_id, guild_id, command_id, permissions);
    }

    pub fn createInteractionResponse(
        self: *Client,
        interaction_id: Snowflake,
        token: []const u8,
        response_payload: Interactions.InteractionResponse,
    ) !Rest.Response {
        return self.rest.createInteractionResponse(interaction_id, token, response_payload);
    }

    pub fn replyInteraction(
        self: *Client,
        interaction_id: Snowflake,
        token: []const u8,
        response_payload: Interactions.InteractionResponse,
    ) !Rest.Response {
        var payload = response_payload;
        payload.type = .channel_message_with_source;
        return self.createInteractionResponse(interaction_id, token, payload);
    }

    pub fn deferInteractionReply(
        self: *Client,
        interaction_id: Snowflake,
        token: []const u8,
        ephemeral: bool,
    ) !Rest.Response {
        return self.createInteractionResponse(interaction_id, token, Interactions.InteractionResponse.deferredMessage(ephemeral));
    }

    pub fn deferInteractionUpdate(self: *Client, interaction_id: Snowflake, token: []const u8) !Rest.Response {
        return self.createInteractionResponse(interaction_id, token, Interactions.InteractionResponse.deferredUpdate());
    }

    pub fn updateInteractionMessage(
        self: *Client,
        interaction_id: Snowflake,
        token: []const u8,
        response_payload: Interactions.InteractionResponse,
    ) !Rest.Response {
        var payload = response_payload;
        payload.type = .update_message;
        return self.createInteractionResponse(interaction_id, token, payload);
    }

    pub fn autocompleteInteraction(
        self: *Client,
        interaction_id: Snowflake,
        token: []const u8,
        choices: []const Interactions.CommandChoice,
    ) !Rest.Response {
        return self.createInteractionResponse(interaction_id, token, Interactions.InteractionResponse.autocomplete(choices));
    }

    pub fn showModal(
        self: *Client,
        interaction_id: Snowflake,
        token: []const u8,
        response_payload: Interactions.InteractionResponse,
    ) !Rest.Response {
        var payload = response_payload;
        payload.type = .modal;
        return self.createInteractionResponse(interaction_id, token, payload);
    }

    pub fn getOriginalInteractionResponse(
        self: *Client,
        application_id: Snowflake,
        token: []const u8,
    ) !Rest.Response {
        return self.rest.getOriginalInteractionResponse(application_id, token);
    }

    pub fn fetchOriginalInteractionResponse(
        self: *Client,
        application_id: Snowflake,
        token: []const u8,
    ) !Rest.Response {
        return self.getOriginalInteractionResponse(application_id, token);
    }

    pub fn fetchInteractionReply(self: *Client, token: []const u8) !Rest.Response {
        return self.getOriginalInteractionResponse(try self.requireCurrentApplicationId(), token);
    }

    pub fn editOriginalInteractionResponse(
        self: *Client,
        application_id: Snowflake,
        token: []const u8,
        payload: Types.EditMessage,
    ) !Rest.Response {
        return self.rest.editOriginalInteractionResponse(application_id, token, payload);
    }

    pub fn editInteractionReply(self: *Client, token: []const u8, payload: Types.EditMessage) !Rest.Response {
        return self.editOriginalInteractionResponse(try self.requireCurrentApplicationId(), token, payload);
    }

    pub fn deleteOriginalInteractionResponse(
        self: *Client,
        application_id: Snowflake,
        token: []const u8,
    ) !Rest.Response {
        return self.rest.deleteOriginalInteractionResponse(application_id, token);
    }

    pub fn deleteInteractionReply(self: *Client, token: []const u8) !Rest.Response {
        return self.deleteOriginalInteractionResponse(try self.requireCurrentApplicationId(), token);
    }

    pub fn createFollowupMessage(
        self: *Client,
        application_id: Snowflake,
        token: []const u8,
        payload: Types.ExecuteWebhook,
    ) !Rest.Response {
        return self.rest.createFollowupMessage(application_id, token, payload);
    }

    pub fn createFollowupMessageWithContent(
        self: *Client,
        application_id: Snowflake,
        token: []const u8,
        content: []const u8,
    ) !Rest.Response {
        return self.createFollowupMessage(application_id, token, Types.ExecuteWebhook.init(content));
    }

    pub fn followUpInteraction(self: *Client, token: []const u8, payload: Types.ExecuteWebhook) !Rest.Response {
        return self.createFollowupMessage(try self.requireCurrentApplicationId(), token, payload);
    }

    pub fn followUpInteractionWithContent(self: *Client, token: []const u8, content: []const u8) !Rest.Response {
        return self.followUpInteraction(token, Types.ExecuteWebhook.init(content));
    }

    pub fn getFollowupMessage(
        self: *Client,
        application_id: Snowflake,
        token: []const u8,
        message_id: Snowflake,
    ) !Rest.Response {
        return self.rest.getFollowupMessage(application_id, token, message_id);
    }

    pub fn fetchFollowupMessage(
        self: *Client,
        application_id: Snowflake,
        token: []const u8,
        message_id: Snowflake,
    ) !Rest.Response {
        return self.getFollowupMessage(application_id, token, message_id);
    }

    pub fn fetchFollowUpInteraction(self: *Client, token: []const u8, message_id: Snowflake) !Rest.Response {
        return self.getFollowupMessage(try self.requireCurrentApplicationId(), token, message_id);
    }

    pub fn editFollowupMessage(
        self: *Client,
        application_id: Snowflake,
        token: []const u8,
        message_id: Snowflake,
        payload: Types.EditMessage,
    ) !Rest.Response {
        return self.rest.editFollowupMessage(application_id, token, message_id, payload);
    }

    pub fn editFollowUpInteraction(
        self: *Client,
        token: []const u8,
        message_id: Snowflake,
        payload: Types.EditMessage,
    ) !Rest.Response {
        return self.editFollowupMessage(try self.requireCurrentApplicationId(), token, message_id, payload);
    }

    pub fn deleteFollowupMessage(
        self: *Client,
        application_id: Snowflake,
        token: []const u8,
        message_id: Snowflake,
    ) !Rest.Response {
        return self.rest.deleteFollowupMessage(application_id, token, message_id);
    }

    pub fn deleteFollowUpInteraction(self: *Client, token: []const u8, message_id: Snowflake) !Rest.Response {
        return self.deleteFollowupMessage(try self.requireCurrentApplicationId(), token, message_id);
    }

    fn requireCurrentApplicationId(self: *Client) !Snowflake {
        return self.currentApplicationId() orelse error.MissingCurrentApplication;
    }

    pub fn react(self: *Client, channel_id: Snowflake, message_id: Snowflake, emoji: []const u8) !Rest.Response {
        return self.rest.createReaction(channel_id, message_id, emoji);
    }

    pub fn addReaction(self: *Client, channel_id: Snowflake, message_id: Snowflake, emoji: []const u8) !Rest.Response {
        return self.react(channel_id, message_id, emoji);
    }

    pub fn unreact(self: *Client, channel_id: Snowflake, message_id: Snowflake, emoji: []const u8) !Rest.Response {
        return self.rest.deleteOwnReaction(channel_id, message_id, emoji);
    }

    pub fn deleteOwnReaction(self: *Client, channel_id: Snowflake, message_id: Snowflake, emoji: []const u8) !Rest.Response {
        return self.unreact(channel_id, message_id, emoji);
    }

    pub fn removeUserReaction(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        emoji: []const u8,
        user_id: Snowflake,
    ) !Rest.Response {
        return self.rest.deleteUserReaction(channel_id, message_id, emoji, user_id);
    }

    pub fn removeReaction(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        emoji: []const u8,
        user_id: Snowflake,
    ) !Rest.Response {
        return self.removeUserReaction(channel_id, message_id, emoji, user_id);
    }

    pub fn listReactions(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        emoji: []const u8,
        options: Types.ListReactions,
    ) !Rest.Response {
        return self.rest.listReactions(channel_id, message_id, emoji, options);
    }

    pub fn fetchReactions(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        emoji: []const u8,
        options: Types.ListReactions,
    ) !Rest.Response {
        return self.listReactions(channel_id, message_id, emoji, options);
    }

    pub fn clearReactions(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
        return self.rest.deleteAllReactions(channel_id, message_id);
    }

    pub fn deleteAllReactions(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
        return self.clearReactions(channel_id, message_id);
    }

    pub fn removeAllReactions(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
        return self.clearReactions(channel_id, message_id);
    }

    pub fn clearReactionsForEmoji(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        emoji: []const u8,
    ) !Rest.Response {
        return self.rest.deleteAllReactionsForEmoji(channel_id, message_id, emoji);
    }

    pub fn deleteAllReactionsForEmoji(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        emoji: []const u8,
    ) !Rest.Response {
        return self.clearReactionsForEmoji(channel_id, message_id, emoji);
    }

    pub fn listPollAnswerVoters(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        answer_id: u32,
        options: Types.ListPollAnswerVoters,
    ) !Rest.Response {
        return self.rest.listPollAnswerVoters(channel_id, message_id, answer_id, options);
    }

    pub fn fetchPollAnswerVoters(
        self: *Client,
        channel_id: Snowflake,
        message_id: Snowflake,
        answer_id: u32,
        options: Types.ListPollAnswerVoters,
    ) !Rest.Response {
        return self.listPollAnswerVoters(channel_id, message_id, answer_id, options);
    }

    pub fn endPoll(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
        return self.rest.endPoll(channel_id, message_id);
    }

    pub fn getCachedUser(self: *Client, user_id: Snowflake) ?Types.User {
        return self.cache.getUser(user_id);
    }

    pub fn cachedUser(self: *Client, user_id: Snowflake) ?Types.User {
        return self.getCachedUser(user_id);
    }

    pub fn hasCachedUser(self: *Client, user_id: Snowflake) bool {
        return self.cache.hasUser(user_id);
    }

    pub fn getCurrentCachedUser(self: *Client) ?Types.User {
        return self.cache.getCurrentUser();
    }

    pub fn currentUser(self: *Client) ?Types.User {
        return self.getCurrentCachedUser();
    }

    pub fn me(self: *Client) ?Types.User {
        return self.getCurrentCachedUser();
    }

    pub fn currentUserId(self: *Client) ?Snowflake {
        return self.cache.currentUserId();
    }

    pub fn hasCurrentCachedUser(self: *Client) bool {
        return self.cache.hasCurrentUser();
    }

    pub fn getCurrentCachedApplication(self: *Client) ?Types.Application {
        return self.cache.getCurrentApplication();
    }

    pub fn currentApplication(self: *Client) ?Types.Application {
        return self.getCurrentCachedApplication();
    }

    pub fn currentApplicationId(self: *Client) ?Snowflake {
        return self.cache.currentApplicationId();
    }

    pub fn hasCurrentCachedApplication(self: *Client) bool {
        return self.cache.hasCurrentApplication();
    }

    pub fn getCachedGuild(self: *Client, guild_id: Snowflake) ?Types.Guild {
        return self.cache.getGuild(guild_id);
    }

    pub fn cachedGuild(self: *Client, guild_id: Snowflake) ?Types.Guild {
        return self.getCachedGuild(guild_id);
    }

    pub fn hasCachedGuild(self: *Client, guild_id: Snowflake) bool {
        return self.cache.hasGuild(guild_id);
    }

    pub fn getCachedChannel(self: *Client, channel_id: Snowflake) ?Types.Channel {
        return self.cache.getChannel(channel_id);
    }

    pub fn cachedChannel(self: *Client, channel_id: Snowflake) ?Types.Channel {
        return self.getCachedChannel(channel_id);
    }

    pub fn hasCachedChannel(self: *Client, channel_id: Snowflake) bool {
        return self.cache.hasChannel(channel_id);
    }

    pub fn getCachedMember(self: *Client, guild_id: Snowflake, user_id: Snowflake) ?Types.GuildMember {
        return self.cache.getMember(guild_id, user_id);
    }

    pub fn cachedMember(self: *Client, guild_id: Snowflake, user_id: Snowflake) ?Types.GuildMember {
        return self.getCachedMember(guild_id, user_id);
    }

    pub fn hasCachedMember(self: *Client, guild_id: Snowflake, user_id: Snowflake) bool {
        return self.cache.hasMember(guild_id, user_id);
    }

    pub fn getCachedRole(self: *Client, guild_id: Snowflake, role_id: Snowflake) ?Types.Role {
        return self.cache.getRole(guild_id, role_id);
    }

    pub fn cachedRole(self: *Client, guild_id: Snowflake, role_id: Snowflake) ?Types.Role {
        return self.getCachedRole(guild_id, role_id);
    }

    pub fn hasCachedRole(self: *Client, guild_id: Snowflake, role_id: Snowflake) bool {
        return self.cache.hasRole(guild_id, role_id);
    }

    pub fn getCachedEmoji(self: *Client, guild_id: Snowflake, emoji_id: Snowflake) ?Types.Emoji {
        return self.cache.getEmoji(guild_id, emoji_id);
    }

    pub fn cachedEmoji(self: *Client, guild_id: Snowflake, emoji_id: Snowflake) ?Types.Emoji {
        return self.getCachedEmoji(guild_id, emoji_id);
    }

    pub fn hasCachedEmoji(self: *Client, guild_id: Snowflake, emoji_id: Snowflake) bool {
        return self.cache.hasEmoji(guild_id, emoji_id);
    }

    pub fn getCachedSticker(self: *Client, guild_id: Snowflake, sticker_id: Snowflake) ?Types.Sticker {
        return self.cache.getSticker(guild_id, sticker_id);
    }

    pub fn cachedSticker(self: *Client, guild_id: Snowflake, sticker_id: Snowflake) ?Types.Sticker {
        return self.getCachedSticker(guild_id, sticker_id);
    }

    pub fn hasCachedSticker(self: *Client, guild_id: Snowflake, sticker_id: Snowflake) bool {
        return self.cache.hasSticker(guild_id, sticker_id);
    }

    pub fn getCachedScheduledEvent(self: *Client, guild_id: Snowflake, event_id: Snowflake) ?Types.GuildScheduledEvent {
        return self.cache.getScheduledEvent(guild_id, event_id);
    }

    pub fn cachedScheduledEvent(self: *Client, guild_id: Snowflake, event_id: Snowflake) ?Types.GuildScheduledEvent {
        return self.getCachedScheduledEvent(guild_id, event_id);
    }

    pub fn hasCachedScheduledEvent(self: *Client, guild_id: Snowflake, event_id: Snowflake) bool {
        return self.cache.hasScheduledEvent(guild_id, event_id);
    }

    pub fn getCachedStageInstance(self: *Client, guild_id: Snowflake, stage_instance_id: Snowflake) ?Types.StageInstance {
        return self.cache.getStageInstance(guild_id, stage_instance_id);
    }

    pub fn cachedStageInstance(self: *Client, guild_id: Snowflake, stage_instance_id: Snowflake) ?Types.StageInstance {
        return self.getCachedStageInstance(guild_id, stage_instance_id);
    }

    pub fn hasCachedStageInstance(self: *Client, guild_id: Snowflake, stage_instance_id: Snowflake) bool {
        return self.cache.hasStageInstance(guild_id, stage_instance_id);
    }

    pub fn getCachedInvite(self: *Client, code: []const u8) ?Types.Invite {
        return self.cache.getInvite(code);
    }

    pub fn cachedInvite(self: *Client, code: []const u8) ?Types.Invite {
        return self.getCachedInvite(code);
    }

    pub fn hasCachedInvite(self: *Client, code: []const u8) bool {
        return self.cache.hasInvite(code);
    }

    pub fn getCachedPresence(self: *Client, guild_id: Snowflake, user_id: Snowflake) ?Types.Presence {
        return self.cache.getPresence(guild_id, user_id);
    }

    pub fn cachedPresence(self: *Client, guild_id: Snowflake, user_id: Snowflake) ?Types.Presence {
        return self.getCachedPresence(guild_id, user_id);
    }

    pub fn hasCachedPresence(self: *Client, guild_id: Snowflake, user_id: Snowflake) bool {
        return self.cache.hasPresence(guild_id, user_id);
    }

    pub fn getCachedVoiceState(self: *Client, guild_id: Snowflake, user_id: Snowflake) ?Types.VoiceState {
        return self.cache.getVoiceState(guild_id, user_id);
    }

    pub fn cachedVoiceState(self: *Client, guild_id: Snowflake, user_id: Snowflake) ?Types.VoiceState {
        return self.getCachedVoiceState(guild_id, user_id);
    }

    pub fn hasCachedVoiceState(self: *Client, guild_id: Snowflake, user_id: Snowflake) bool {
        return self.cache.hasVoiceState(guild_id, user_id);
    }

    pub fn getCachedMessage(self: *Client, message_id: Snowflake) ?Types.Message {
        return self.cache.getMessage(message_id);
    }

    pub fn cachedMessage(self: *Client, message_id: Snowflake) ?Types.Message {
        return self.getCachedMessage(message_id);
    }

    pub fn hasCachedMessage(self: *Client, message_id: Snowflake) bool {
        return self.cache.hasMessage(message_id);
    }

    pub fn clearCache(self: *Client) void {
        self.cache.clear();
    }

    pub fn evictCachedUser(self: *Client, user_id: Snowflake) void {
        self.cache.removeUser(user_id);
    }

    pub fn evictCurrentCachedApplication(self: *Client) void {
        self.cache.removeCurrentApplication();
    }

    pub fn evictCachedGuild(self: *Client, guild_id: Snowflake) void {
        self.cache.removeGuild(guild_id);
    }

    pub fn evictCachedChannel(self: *Client, channel_id: Snowflake) void {
        self.cache.removeChannel(channel_id);
    }

    pub fn evictCachedMember(self: *Client, guild_id: Snowflake, user_id: Snowflake) void {
        self.cache.removeMember(guild_id, user_id);
    }

    pub fn evictCachedRole(self: *Client, guild_id: Snowflake, role_id: Snowflake) void {
        self.cache.removeRole(guild_id, role_id);
    }

    pub fn evictCachedEmoji(self: *Client, guild_id: Snowflake, emoji_id: Snowflake) void {
        self.cache.removeEmoji(guild_id, emoji_id);
    }

    pub fn evictCachedSticker(self: *Client, guild_id: Snowflake, sticker_id: Snowflake) void {
        self.cache.removeSticker(guild_id, sticker_id);
    }

    pub fn evictCachedScheduledEvent(self: *Client, guild_id: Snowflake, event_id: Snowflake) void {
        self.cache.removeScheduledEvent(guild_id, event_id);
    }

    pub fn evictCachedStageInstance(self: *Client, guild_id: Snowflake, stage_instance_id: Snowflake) void {
        self.cache.removeStageInstance(guild_id, stage_instance_id);
    }

    pub fn evictCachedInvite(self: *Client, code: []const u8) void {
        self.cache.removeInvite(code);
    }

    pub fn evictCachedPresence(self: *Client, guild_id: Snowflake, user_id: Snowflake) void {
        self.cache.removePresence(guild_id, user_id);
    }

    pub fn evictCachedVoiceState(self: *Client, guild_id: Snowflake, user_id: Snowflake) void {
        self.cache.removeVoiceState(guild_id, user_id);
    }

    pub fn evictCachedMessage(self: *Client, message_id: Snowflake) void {
        self.cache.removeMessage(message_id);
    }

    pub fn cacheStats(self: *Client) CacheModule.CacheStats {
        return self.cache.stats();
    }

    pub fn cachedUserCount(self: *Client) usize {
        return self.cacheStats().users;
    }

    pub fn cachedGuildCount(self: *Client) usize {
        return self.cacheStats().guilds;
    }

    pub fn cachedChannelCount(self: *Client) usize {
        return self.cacheStats().channels;
    }

    pub fn cachedMemberCount(self: *Client) usize {
        return self.cacheStats().members;
    }

    pub fn cachedRoleCount(self: *Client) usize {
        return self.cacheStats().roles;
    }

    pub fn cachedEmojiCount(self: *Client) usize {
        return self.cacheStats().emojis;
    }

    pub fn cachedStickerCount(self: *Client) usize {
        return self.cacheStats().stickers;
    }

    pub fn cachedMessageCount(self: *Client) usize {
        return self.cacheStats().messages;
    }

    pub fn guildCacheStats(self: *Client, guild_id: Snowflake) CacheModule.GuildCacheStats {
        return self.cache.guildStats(guild_id);
    }

    pub fn channelCacheStats(self: *Client, channel_id: Snowflake) CacheModule.ChannelCacheStats {
        return self.cache.channelStats(channel_id);
    }

    pub fn listCachedUsers(self: *Client, allocator: std.mem.Allocator) ![]Types.User {
        return self.cache.listUsers(allocator);
    }

    pub fn cachedUsers(self: *Client, allocator: std.mem.Allocator) ![]Types.User {
        return self.listCachedUsers(allocator);
    }

    pub fn listCachedGuilds(self: *Client, allocator: std.mem.Allocator) ![]Types.Guild {
        return self.cache.listGuilds(allocator);
    }

    pub fn cachedGuilds(self: *Client, allocator: std.mem.Allocator) ![]Types.Guild {
        return self.listCachedGuilds(allocator);
    }

    pub fn listCachedChannels(self: *Client, allocator: std.mem.Allocator) ![]Types.Channel {
        return self.cache.listChannels(allocator);
    }

    pub fn cachedChannels(self: *Client, allocator: std.mem.Allocator) ![]Types.Channel {
        return self.listCachedChannels(allocator);
    }

    pub fn listCachedTopLevelChannels(self: *Client, allocator: std.mem.Allocator) ![]Types.Channel {
        return self.cache.listTopLevelChannels(allocator);
    }

    pub fn cachedTopLevelChannels(self: *Client, allocator: std.mem.Allocator) ![]Types.Channel {
        return self.listCachedTopLevelChannels(allocator);
    }

    pub fn listCachedGuildChannels(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Channel {
        return self.cache.listGuildChannels(allocator, guild_id);
    }

    pub fn cachedGuildChannels(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Channel {
        return self.listCachedGuildChannels(allocator, guild_id);
    }

    pub fn listCachedChannelThreads(self: *Client, allocator: std.mem.Allocator, parent_channel_id: Snowflake) ![]Types.Channel {
        return self.cache.listChannelThreads(allocator, parent_channel_id);
    }

    pub fn cachedChannelThreads(self: *Client, allocator: std.mem.Allocator, parent_channel_id: Snowflake) ![]Types.Channel {
        return self.listCachedChannelThreads(allocator, parent_channel_id);
    }

    pub fn listCachedGuildThreads(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Channel {
        return self.cache.listGuildThreads(allocator, guild_id);
    }

    pub fn cachedGuildThreads(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Channel {
        return self.listCachedGuildThreads(allocator, guild_id);
    }

    pub fn listCachedGuildMembers(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.GuildMember {
        return self.cache.listGuildMembers(allocator, guild_id);
    }

    pub fn cachedGuildMembers(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.GuildMember {
        return self.listCachedGuildMembers(allocator, guild_id);
    }

    pub fn listCachedMembers(self: *Client, allocator: std.mem.Allocator) ![]Types.CachedGuildMember {
        return self.cache.listMembers(allocator);
    }

    pub fn cachedMembers(self: *Client, allocator: std.mem.Allocator) ![]Types.CachedGuildMember {
        return self.listCachedMembers(allocator);
    }

    pub fn listCachedGuildRoles(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Role {
        return self.cache.listGuildRoles(allocator, guild_id);
    }

    pub fn cachedGuildRoles(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Role {
        return self.listCachedGuildRoles(allocator, guild_id);
    }

    pub fn listCachedRoles(self: *Client, allocator: std.mem.Allocator) ![]Types.Role {
        return self.cache.listRoles(allocator);
    }

    pub fn cachedRoles(self: *Client, allocator: std.mem.Allocator) ![]Types.Role {
        return self.listCachedRoles(allocator);
    }

    pub fn listCachedGuildEmojis(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Emoji {
        return self.cache.listGuildEmojis(allocator, guild_id);
    }

    pub fn cachedGuildEmojis(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Emoji {
        return self.listCachedGuildEmojis(allocator, guild_id);
    }

    pub fn listCachedEmojis(self: *Client, allocator: std.mem.Allocator) ![]Types.Emoji {
        return self.cache.listEmojis(allocator);
    }

    pub fn cachedEmojis(self: *Client, allocator: std.mem.Allocator) ![]Types.Emoji {
        return self.listCachedEmojis(allocator);
    }

    pub fn listCachedGuildStickers(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Sticker {
        return self.cache.listGuildStickers(allocator, guild_id);
    }

    pub fn cachedGuildStickers(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Sticker {
        return self.listCachedGuildStickers(allocator, guild_id);
    }

    pub fn listCachedStickers(self: *Client, allocator: std.mem.Allocator) ![]Types.Sticker {
        return self.cache.listStickers(allocator);
    }

    pub fn cachedStickers(self: *Client, allocator: std.mem.Allocator) ![]Types.Sticker {
        return self.listCachedStickers(allocator);
    }

    pub fn listCachedGuildScheduledEvents(
        self: *Client,
        allocator: std.mem.Allocator,
        guild_id: Snowflake,
    ) ![]Types.GuildScheduledEvent {
        return self.cache.listGuildScheduledEvents(allocator, guild_id);
    }

    pub fn cachedGuildScheduledEvents(
        self: *Client,
        allocator: std.mem.Allocator,
        guild_id: Snowflake,
    ) ![]Types.GuildScheduledEvent {
        return self.listCachedGuildScheduledEvents(allocator, guild_id);
    }

    pub fn listCachedScheduledEvents(self: *Client, allocator: std.mem.Allocator) ![]Types.GuildScheduledEvent {
        return self.cache.listScheduledEvents(allocator);
    }

    pub fn cachedScheduledEvents(self: *Client, allocator: std.mem.Allocator) ![]Types.GuildScheduledEvent {
        return self.listCachedScheduledEvents(allocator);
    }

    pub fn listCachedGuildStageInstances(
        self: *Client,
        allocator: std.mem.Allocator,
        guild_id: Snowflake,
    ) ![]Types.StageInstance {
        return self.cache.listGuildStageInstances(allocator, guild_id);
    }

    pub fn cachedGuildStageInstances(
        self: *Client,
        allocator: std.mem.Allocator,
        guild_id: Snowflake,
    ) ![]Types.StageInstance {
        return self.listCachedGuildStageInstances(allocator, guild_id);
    }

    pub fn listCachedStageInstances(self: *Client, allocator: std.mem.Allocator) ![]Types.StageInstance {
        return self.cache.listStageInstances(allocator);
    }

    pub fn cachedStageInstances(self: *Client, allocator: std.mem.Allocator) ![]Types.StageInstance {
        return self.listCachedStageInstances(allocator);
    }

    pub fn listCachedGuildInvites(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Invite {
        return self.cache.listGuildInvites(allocator, guild_id);
    }

    pub fn cachedGuildInvites(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Invite {
        return self.listCachedGuildInvites(allocator, guild_id);
    }

    pub fn listCachedInvites(self: *Client, allocator: std.mem.Allocator) ![]Types.Invite {
        return self.cache.listInvites(allocator);
    }

    pub fn cachedInvites(self: *Client, allocator: std.mem.Allocator) ![]Types.Invite {
        return self.listCachedInvites(allocator);
    }

    pub fn listCachedChannelInvites(self: *Client, allocator: std.mem.Allocator, channel_id: Snowflake) ![]Types.Invite {
        return self.cache.listChannelInvites(allocator, channel_id);
    }

    pub fn cachedChannelInvites(self: *Client, allocator: std.mem.Allocator, channel_id: Snowflake) ![]Types.Invite {
        return self.listCachedChannelInvites(allocator, channel_id);
    }

    pub fn listCachedPresences(self: *Client, allocator: std.mem.Allocator) ![]Types.Presence {
        return self.cache.listPresences(allocator);
    }

    pub fn cachedPresences(self: *Client, allocator: std.mem.Allocator) ![]Types.Presence {
        return self.listCachedPresences(allocator);
    }

    pub fn listCachedGuildPresences(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Presence {
        return self.cache.listGuildPresences(allocator, guild_id);
    }

    pub fn cachedGuildPresences(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Presence {
        return self.listCachedGuildPresences(allocator, guild_id);
    }

    pub fn listCachedVoiceStates(self: *Client, allocator: std.mem.Allocator) ![]Types.VoiceState {
        return self.cache.listVoiceStates(allocator);
    }

    pub fn cachedVoiceStates(self: *Client, allocator: std.mem.Allocator) ![]Types.VoiceState {
        return self.listCachedVoiceStates(allocator);
    }

    pub fn listCachedGuildVoiceStates(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.VoiceState {
        return self.cache.listGuildVoiceStates(allocator, guild_id);
    }

    pub fn cachedGuildVoiceStates(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.VoiceState {
        return self.listCachedGuildVoiceStates(allocator, guild_id);
    }

    pub fn listCachedChannelMessages(self: *Client, allocator: std.mem.Allocator, channel_id: Snowflake) ![]Types.Message {
        return self.cache.listChannelMessages(allocator, channel_id);
    }

    pub fn cachedChannelMessages(self: *Client, allocator: std.mem.Allocator, channel_id: Snowflake) ![]Types.Message {
        return self.listCachedChannelMessages(allocator, channel_id);
    }

    pub fn listCachedMessages(self: *Client, allocator: std.mem.Allocator) ![]Types.Message {
        return self.cache.listMessages(allocator);
    }

    pub fn cachedMessages(self: *Client, allocator: std.mem.Allocator) ![]Types.Message {
        return self.listCachedMessages(allocator);
    }

    pub fn listCachedGuildMessages(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Message {
        return self.cache.listGuildMessages(allocator, guild_id);
    }

    pub fn cachedGuildMessages(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Message {
        return self.listCachedGuildMessages(allocator, guild_id);
    }

    pub fn deinit(self: *Client) void {
        self.cache.deinit();
        self.rest.deinit();
        if (self.owned_http_transport) |http_transport| {
            http_transport.deinit();
            self.allocator.destroy(http_transport);
        }
    }

    pub fn destroy(self: *Client) void {
        self.deinit();
    }
};

pub const GatewayStep = enum {
    idle,
    identified,
    resumed,
    heartbeat_sent,
    heartbeat_ack,
    dispatched,
    reconnect,
    invalid_session,
};

pub const GatewayStartMode = enum {
    identify,
    resume_session,
};

pub const ReconnectBackoff = struct {
    initial_delay_ms: u64 = 1000,
    max_delay_ms: u64 = 60_000,
    factor: u8 = 2,
    attempts: u32 = 0,

    pub fn nextDelayMs(self: *ReconnectBackoff) u64 {
        var delay = self.initial_delay_ms;
        var remaining = self.attempts;
        while (remaining > 0 and delay < self.max_delay_ms) : (remaining -= 1) {
            const multiplied = std.math.mul(u64, delay, self.factor) catch self.max_delay_ms;
            delay = @min(multiplied, self.max_delay_ms);
        }
        self.attempts += 1;
        return delay;
    }

    pub fn reset(self: *ReconnectBackoff) void {
        self.attempts = 0;
    }
};

pub const GatewayRunner = struct {
    client: *Client,
    session: GatewaySession.Session,
    next_heartbeat_ms: ?u64 = null,
    reconnect_backoff: ReconnectBackoff = .{},
    reconnect_after_ms: ?u64 = null,
    pending_start: GatewayStartMode = .identify,

    pub fn init(client: *Client, transport: GatewaySession.Transport) GatewayRunner {
        return .{
            .client = client,
            .session = client.createGatewaySession(transport),
        };
    }

    pub fn deinit(self: *GatewayRunner) void {
        self.session.deinit();
    }

    pub fn step(self: *GatewayRunner, now_ms: u64) !GatewayStep {
        if (self.reconnect_after_ms) |ready_at| {
            if (now_ms < ready_at) return .idle;
        }

        if (self.next_heartbeat_ms) |deadline| {
            if (now_ms >= deadline) {
                if (self.session.awaiting_heartbeat_ack) return error.MissedHeartbeatAck;
                try self.session.sendHeartbeat();
                self.client.markHeartbeatSent(now_ms);
                self.scheduleNextHeartbeat(now_ms);
                return .heartbeat_sent;
            }
        }

        if (try self.session.poll()) |polled_dispatch| {
            var dispatch = polled_dispatch;
            defer dispatch.deinit();
            _ = try self.client.dispatchParsedGatewayAt(dispatch, now_ms);
            self.consumeSignal();
            return .dispatched;
        }

        return switch (self.session.last_signal) {
            .none, .ignored => .idle,
            .hello => {
                const start = self.pending_start;
                if (start == .resume_session and self.session.canResume()) {
                    try self.session.resumeSession();
                    self.pending_start = .identify;
                    self.reconnect_after_ms = null;
                    self.reconnect_backoff.reset();
                    self.scheduleNextHeartbeat(now_ms);
                    self.consumeSignal();
                    return .resumed;
                }
                try self.session.identify();
                self.pending_start = .identify;
                self.reconnect_after_ms = null;
                self.reconnect_backoff.reset();
                self.scheduleNextHeartbeat(now_ms);
                self.consumeSignal();
                return .identified;
            },
            .heartbeat_ack => {
                self.client.markHeartbeatAck(now_ms);
                self.consumeSignal();
                return .heartbeat_ack;
            },
            .reconnect => {
                self.client.markGatewayDisconnected();
                self.scheduleReconnect(now_ms, .resume_session);
                self.consumeSignal();
                return .reconnect;
            },
            .invalid_session => {
                self.client.markGatewayDisconnected();
                const mode: GatewayStartMode = switch (self.session.invalid_session_mode) {
                    .resumable => .resume_session,
                    .fresh_identify, .unknown => .identify,
                };
                self.scheduleReconnect(now_ms, mode);
                self.consumeSignal();
                return .invalid_session;
            },
            .dispatch => .dispatched,
        };
    }

    pub fn replaceTransport(self: *GatewayRunner, transport: GatewaySession.Transport) void {
        self.session.transport = transport;
    }

    pub fn canResume(self: GatewayRunner) bool {
        return self.session.canResume();
    }

    pub fn sessionId(self: GatewayRunner) ?[]const u8 {
        return self.session.session_id;
    }

    pub fn sequence(self: GatewayRunner) ?u64 {
        return self.session.sequence;
    }

    pub fn nextHeartbeatMs(self: GatewayRunner) ?u64 {
        return self.next_heartbeat_ms;
    }

    pub fn heartbeatIntervalMs(self: GatewayRunner) ?u64 {
        return self.session.heartbeat_interval_ms;
    }

    pub fn awaitingHeartbeatAck(self: GatewayRunner) bool {
        return self.session.awaiting_heartbeat_ack;
    }

    pub fn reconnectAfterMs(self: GatewayRunner) ?u64 {
        return self.reconnect_after_ms;
    }

    pub fn pendingStartMode(self: GatewayRunner) GatewayStartMode {
        return self.pending_start;
    }

    pub fn isReconnectPending(self: GatewayRunner) bool {
        return self.reconnect_after_ms != null;
    }

    pub fn reconnectReady(self: GatewayRunner, now_ms: u64) bool {
        return if (self.reconnect_after_ms) |ready_at| now_ms >= ready_at else true;
    }

    pub fn resetHeartbeat(self: *GatewayRunner) void {
        self.next_heartbeat_ms = null;
        self.session.awaiting_heartbeat_ack = false;
    }

    pub fn resetReconnect(self: *GatewayRunner) void {
        self.reconnect_after_ms = null;
        self.pending_start = .identify;
        self.reconnect_backoff.reset();
    }

    fn scheduleNextHeartbeat(self: *GatewayRunner, now_ms: u64) void {
        const interval = self.session.heartbeat_interval_ms orelse return;
        self.next_heartbeat_ms = now_ms + interval;
    }

    fn scheduleReconnect(self: *GatewayRunner, now_ms: u64, start: GatewayStartMode) void {
        self.resetHeartbeat();
        self.pending_start = start;
        self.reconnect_after_ms = now_ms + self.reconnect_backoff.nextDelayMs();
    }

    fn consumeSignal(self: *GatewayRunner) void {
        self.session.last_signal = .none;
    }
};

fn noTransportValue() Rest.Transport {
    return .{ .ptr = &no_transport_state, .sendFn = noTransportSend };
}

var no_transport_state: u8 = 0;

fn noTransportSend(ptr: *anyopaque, allocator: std.mem.Allocator, request: Rest.Request) anyerror!Rest.Response {
    _ = ptr;
    _ = allocator;
    _ = request;
    return error.NoHttpTransport;
}

test "client file send aliases delegate to multipart REST" {
    var memory = Rest.MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
        .transport = memory.transport(),
    });
    defer client.deinit();

    const memory_files = [_]Types.UploadFile{
        Types.UploadFile.init("hello.txt", "hello").withContentType("text/plain"),
    };

    _ = try client.sendMessageWithFiles(Snowflake.init(10), Types.CreateMessage.init("with file"), &memory_files);
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages", memory.last_request.?.url);
    try std.testing.expectEqualStrings("multipart/form-data; boundary=discord-zig-boundary", memory.last_request.?.content_type.?);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "name=\"files[0]\"; filename=\"hello.txt\"") != null);

    _ = try client.sendWithFiles(Snowflake.init(10), Types.CreateMessage.init("with file alias"), &memory_files);
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages", memory.last_request.?.url);
    try std.testing.expectEqualStrings("multipart/form-data; boundary=discord-zig-boundary", memory.last_request.?.content_type.?);

    const io = std.Io.Threaded.global_single_threaded.io();
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(io, .{ .sub_path = "stream.txt", .data = "hello from disk" });

    var path_buffer: [128]u8 = .{0} ** 128;
    const path = try std.fmt.bufPrint(&path_buffer, ".zig-cache/tmp/{s}/stream.txt", .{tmp.sub_path});
    const path_files = [_]Types.UploadFilePath{
        Types.UploadFilePath.init("stream.txt", path).withContentType("text/plain"),
    };

    _ = try client.sendMessageWithFilePaths(Snowflake.init(10), Types.CreateMessage.init("streamed file"), &path_files);
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("multipart/form-data; boundary=discord-zig-boundary", memory.last_request.?.content_type.?);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "hello from disk\r\n") != null);

    _ = try client.sendWithFilePaths(Snowflake.init(10), Types.CreateMessage.init("streamed file alias"), &path_files);
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("multipart/form-data; boundary=discord-zig-boundary", memory.last_request.?.content_type.?);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"attachments\":[{\"id\":\"0\",\"filename\":\"stream.txt\"}]") != null);
}

test "client convenience send reply and react delegate to REST" {
    var memory = Rest.MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
        .transport = memory.transport(),
    });
    defer client.deinit();

    _ = try client.sendMessage(Snowflake.init(10), Types.CreateMessage.init("hello"));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"hello\"}", memory.last_request.?.body.?);

    _ = try client.sendMessageWithContent(Snowflake.init(10), "hello shortcut");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"hello shortcut\"}", memory.last_request.?.body.?);

    _ = try client.sendContent(Snowflake.init(10), "content alias");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"content alias\"}", memory.last_request.?.body.?);

    _ = try client.sendText(Snowflake.init(10), "text alias");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"text alias\"}", memory.last_request.?.body.?);

    _ = try client.send(Snowflake.init(10), Types.CreateMessage.init("alias"));
    try std.testing.expectEqualStrings("{\"content\":\"alias\"}", memory.last_request.?.body.?);

    _ = try client.reply(Snowflake.init(10), Snowflake.init(20), Types.CreateMessage.init("reply"));
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"message_reference\"") != null);

    _ = try client.replyMessage(Snowflake.init(10), Snowflake.init(20), Types.CreateMessage.init("reply alias"));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages", memory.last_request.?.url);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"message_reference\"") != null);

    _ = try client.replyWithContent(Snowflake.init(10), Snowflake.init(20), "reply shortcut");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages", memory.last_request.?.url);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"content\":\"reply shortcut\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"message_reference\"") != null);

    _ = try client.replyMessageWithContent(Snowflake.init(10), Snowflake.init(20), "reply message shortcut");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages", memory.last_request.?.url);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"content\":\"reply message shortcut\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"message_reference\"") != null);

    _ = try client.replyText(Snowflake.init(10), Snowflake.init(20), "reply text shortcut");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages", memory.last_request.?.url);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"content\":\"reply text shortcut\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"message_reference\"") != null);

    _ = try client.forwardMessage(Snowflake.init(11), Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/11/messages", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"message_reference\":{\"type\":1,\"message_id\":\"20\",\"channel_id\":\"10\"}}",
        memory.last_request.?.body.?,
    );

    _ = try client.forward(Snowflake.init(11), Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/11/messages", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"message_reference\":{\"type\":1,\"message_id\":\"20\",\"channel_id\":\"10\"}}",
        memory.last_request.?.body.?,
    );

    _ = try client.getMessage(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20", memory.last_request.?.url);

    _ = try client.fetchMessage(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20", memory.last_request.?.url);

    _ = try client.edit(Snowflake.init(10), Snowflake.init(20), Types.EditMessage.init().withContent("edited alias"));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"edited alias\"}", memory.last_request.?.body.?);

    _ = try client.editMessageWithContent(Snowflake.init(10), Snowflake.init(20), "edited shortcut");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"edited shortcut\"}", memory.last_request.?.body.?);

    _ = try client.editWithContent(Snowflake.init(10), Snowflake.init(20), "edited content alias");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"edited content alias\"}", memory.last_request.?.body.?);

    _ = try client.editText(Snowflake.init(10), Snowflake.init(20), "edited text alias");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"edited text alias\"}", memory.last_request.?.body.?);

    _ = try client.setEmbedsSuppressed(Snowflake.init(10), Snowflake.init(20), true);
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"flags\":4}", memory.last_request.?.body.?);

    _ = try client.suppressEmbeds(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("{\"flags\":4}", memory.last_request.?.body.?);

    _ = try client.unsuppressEmbeds(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("{\"flags\":0}", memory.last_request.?.body.?);

    _ = try client.deleteMessage(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20", memory.last_request.?.url);

    _ = try client.delete(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20", memory.last_request.?.url);

    _ = try client.crosspostMessage(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20/crosspost", memory.last_request.?.url);

    _ = try client.crosspost(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20/crosspost", memory.last_request.?.url);

    _ = try client.publishMessage(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20/crosspost", memory.last_request.?.url);

    _ = try client.publish(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20/crosspost", memory.last_request.?.url);

    _ = try client.listMessagesWithOptions(
        Snowflake.init(10),
        Types.ListMessages.beforeMessage(Snowflake.init(20)).withLimit(10),
    );
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages?before=20&limit=10",
        memory.last_request.?.url,
    );

    _ = try client.fetchMessages(
        Snowflake.init(10),
        Types.ListMessages.beforeMessage(Snowflake.init(20)).withLimit(10),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages?before=20&limit=10",
        memory.last_request.?.url,
    );

    const messages = [_]Snowflake{ Snowflake.init(20), Snowflake.init(30) };
    _ = try client.bulkDeleteMessages(Snowflake.init(10), &messages);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/bulk-delete",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"messages\":[\"20\",\"30\"]}", memory.last_request.?.body.?);

    _ = try client.bulkDelete(Snowflake.init(10), &messages);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/bulk-delete",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"messages\":[\"20\",\"30\"]}", memory.last_request.?.body.?);

    _ = try client.sendTyping(Snowflake.init(10));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/typing", memory.last_request.?.url);
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.triggerTyping(Snowflake.init(10));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/typing", memory.last_request.?.url);
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.listChannelPins(Snowflake.init(10), Types.ListChannelPins.init().withLimit(10));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/pins?limit=10", memory.last_request.?.url);

    _ = try client.fetchPinnedMessages(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/pins", memory.last_request.?.url);

    _ = try client.fetchPins(Snowflake.init(10), Types.ListChannelPins.init().withLimit(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/pins?limit=10", memory.last_request.?.url);

    _ = try client.pinMessage(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/pins/20", memory.last_request.?.url);

    _ = try client.pin(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/pins/20", memory.last_request.?.url);

    _ = try client.unpinMessage(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);

    _ = try client.unpin(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/pins/20", memory.last_request.?.url);

    _ = try client.fetchGateway();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/gateway", memory.last_request.?.url);

    _ = try client.fetchGatewayBot();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bot test", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/gateway/bot", memory.last_request.?.url);

    _ = try client.fetchCurrentApplication();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/@me", memory.last_request.?.url);

    _ = try client.fetchCurrentBotApplication();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bot test", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/oauth2/applications/@me", memory.last_request.?.url);

    _ = try client.editCurrentApplication(Types.EditCurrentApplication.init()
        .withDescription("Fast Zig bot")
        .withEventWebhooksStatus(.disabled));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"description\":\"Fast Zig bot\",\"event_webhooks_status\":1}",
        memory.last_request.?.body.?,
    );

    _ = try client.setCurrentApplicationDescription("Fast Zig bot");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"description\":\"Fast Zig bot\"}", memory.last_request.?.body.?);

    _ = try client.setCurrentApplicationIcon("data:image/png;base64,AAAA");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"icon\":\"data:image/png;base64,AAAA\"}", memory.last_request.?.body.?);

    _ = try client.clearCurrentApplicationIcon();
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"icon\":null}", memory.last_request.?.body.?);

    _ = try client.setCurrentApplicationCoverImage("data:image/png;base64,CCCC");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"cover_image\":\"data:image/png;base64,CCCC\"}", memory.last_request.?.body.?);

    _ = try client.clearCurrentApplicationCoverImage();
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"cover_image\":null}", memory.last_request.?.body.?);

    _ = try client.getCurrentUser();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);

    _ = try client.fetchCurrentUser();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);

    _ = try client.getMe();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);

    _ = try client.fetchMe();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);

    _ = try client.getUser(Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/20", memory.last_request.?.url);

    _ = try client.fetchUser(Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/20", memory.last_request.?.url);

    _ = try client.editCurrentUser(
        Types.EditCurrentUser.init()
            .withUsername("zigbot")
            .clearAvatar(),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"username\":\"zigbot\",\"avatar\":null}", memory.last_request.?.body.?);

    _ = try client.setCurrentUsername("zigbot");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"username\":\"zigbot\"}", memory.last_request.?.body.?);

    _ = try client.setCurrentUserAvatar("data:image/png;base64,BBBB");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"avatar\":\"data:image/png;base64,BBBB\"}", memory.last_request.?.body.?);

    _ = try client.clearCurrentUserAvatar();
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"avatar\":null}", memory.last_request.?.body.?);

    _ = try client.setCurrentUserBanner("data:image/png;base64,DDDD");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"banner\":\"data:image/png;base64,DDDD\"}", memory.last_request.?.body.?);

    _ = try client.clearCurrentUserBanner();
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"banner\":null}", memory.last_request.?.body.?);

    _ = try client.editMe(Types.EditCurrentUser.init().withUsername("aliasbot"));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"username\":\"aliasbot\"}", memory.last_request.?.body.?);

    _ = try client.createDmChannel(Snowflake.init(30));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/channels", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"recipient_id\":\"30\"}", memory.last_request.?.body.?);

    _ = try client.createDm(Snowflake.init(30));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/channels", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"recipient_id\":\"30\"}", memory.last_request.?.body.?);

    _ = try client.createDM(Snowflake.init(30));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/channels", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"recipient_id\":\"30\"}", memory.last_request.?.body.?);

    _ = try client.listCurrentUserGuilds(Types.ListCurrentUserGuilds.init().withLimit(25).withCounts(false));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/users/@me/guilds?limit=25&with_counts=false",
        memory.last_request.?.url,
    );

    _ = try client.fetchCurrentUserGuilds(Types.ListCurrentUserGuilds.init().withLimit(25).withCounts(false));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/users/@me/guilds?limit=25&with_counts=false",
        memory.last_request.?.url,
    );

    _ = try client.getCurrentUserGuildMember(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/guilds/10/member", memory.last_request.?.url);

    _ = try client.fetchCurrentUserGuildMember(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/guilds/10/member", memory.last_request.?.url);

    _ = try client.fetchMeGuildMember(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/guilds/10/member", memory.last_request.?.url);

    _ = try client.listCurrentUserConnections();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/connections", memory.last_request.?.url);

    _ = try client.fetchCurrentUserConnections();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/connections", memory.last_request.?.url);

    _ = try client.getCurrentAuthorization("Bearer user-token");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/oauth2/@me", memory.last_request.?.url);

    _ = try client.fetchCurrentAuthorization("Bearer user-token");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/oauth2/@me", memory.last_request.?.url);

    _ = try client.exchangeOAuth2Token("Basic client-secret", Types.OAuth2TokenRequest.refreshToken("refresh token"));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Basic client-secret", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/oauth2/token", memory.last_request.?.url);
    try std.testing.expectEqualStrings("application/x-www-form-urlencoded", memory.last_request.?.content_type.?);
    try std.testing.expectEqualStrings(
        "grant_type=refresh_token&refresh_token=refresh%20token",
        memory.last_request.?.body.?,
    );

    _ = try client.revokeOAuth2Token("Basic client-secret", Types.OAuth2TokenRevocation.init("access token"));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Basic client-secret", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/oauth2/token/revoke", memory.last_request.?.url);
    try std.testing.expectEqualStrings("application/x-www-form-urlencoded", memory.last_request.?.content_type.?);
    try std.testing.expectEqualStrings("token=access%20token", memory.last_request.?.body.?);

    _ = try client.getCurrentUserApplicationRoleConnection("Bearer user-token", Snowflake.init(99));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/users/@me/applications/99/role-connection",
        memory.last_request.?.url,
    );

    _ = try client.fetchCurrentUserApplicationRoleConnection("Bearer user-token", Snowflake.init(99));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/users/@me/applications/99/role-connection",
        memory.last_request.?.url,
    );

    _ = try client.setCurrentUserApplicationRoleConnection(
        "Bearer user-token",
        Snowflake.init(99),
        Types.UpdateApplicationRoleConnection.init().withPlatformUsername("baris"),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings("{\"platform_username\":\"baris\"}", memory.last_request.?.body.?);

    _ = try client.deleteCurrentUserApplicationRoleConnection("Bearer user-token", Snowflake.init(99));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/users/@me/applications/99/role-connection",
        memory.last_request.?.url,
    );

    _ = try client.leaveGuild(Snowflake.init(10));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/guilds/10", memory.last_request.?.url);

    _ = try client.getGuild(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10", memory.last_request.?.url);

    _ = try client.fetchGuild(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10", memory.last_request.?.url);

    _ = try client.getGuildWithOptions(Snowflake.init(10), Types.GetGuild.init().withCounts(true));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10?with_counts=true", memory.last_request.?.url);

    _ = try client.fetchGuildWithOptions(Snowflake.init(10), Types.GetGuild.init().withCounts(true));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10?with_counts=true", memory.last_request.?.url);

    _ = try client.getGuildPreview(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/preview", memory.last_request.?.url);

    _ = try client.fetchGuildPreview(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/preview", memory.last_request.?.url);

    _ = try client.editGuild(
        Snowflake.init(10),
        Types.EditGuild.init()
            .withDescription("Zig community")
            .clearBanner(),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"banner\":null,\"description\":\"Zig community\"}", memory.last_request.?.body.?);

    _ = try client.getChannel(Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/30", memory.last_request.?.url);

    _ = try client.fetchChannel(Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/30", memory.last_request.?.url);

    _ = try client.fetchGuildTemplate("abc 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/templates/abc%20123", memory.last_request.?.url);

    _ = try client.fetchGuildTemplates(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/templates", memory.last_request.?.url);

    _ = try client.createGuildTemplate(Snowflake.init(10), Types.CreateGuildTemplate.init("starter"));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/templates", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"starter\"}", memory.last_request.?.body.?);

    _ = try client.deleteGuildTemplate(Snowflake.init(10), "abc 123");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/templates/abc%20123", memory.last_request.?.url);

    _ = try client.fetchGuildWidgetSettings(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/widget", memory.last_request.?.url);

    _ = try client.editGuildWidgetSettings(
        Snowflake.init(10),
        Types.EditGuildWidgetSettings.init().clearChannel(),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/widget", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"channel_id\":null}", memory.last_request.?.body.?);

    _ = try client.fetchGuildWidget(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/widget.json", memory.last_request.?.url);

    _ = try client.getGuildWidgetImage(Snowflake.init(10), Types.GetGuildWidgetImage.init().withStyle(.banner1));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/widget.png?style=banner1", memory.last_request.?.url);

    _ = try client.fetchGuildWidgetImage(Snowflake.init(10), Types.GetGuildWidgetImage.init());
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/widget.png", memory.last_request.?.url);

    _ = try client.fetchGuildWelcomeScreen(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/welcome-screen", memory.last_request.?.url);

    _ = try client.editGuildWelcomeScreen(
        Snowflake.init(10),
        Types.EditWelcomeScreen.init()
            .enabledState(false)
            .clearDescription(),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/welcome-screen", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"enabled\":false,\"description\":null}", memory.last_request.?.body.?);

    _ = try client.getGuildOnboarding(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/onboarding", memory.last_request.?.url);

    _ = try client.fetchGuildOnboarding(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/onboarding", memory.last_request.?.url);

    _ = try client.editGuildOnboarding(
        Snowflake.init(10),
        Types.EditGuildOnboarding.init().enabledState(false),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/onboarding", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"enabled\":false}", memory.last_request.?.body.?);

    _ = try client.setGuildOnboarding(
        Snowflake.init(10),
        Types.EditGuildOnboarding.init().withMode(.onboarding_advanced),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/onboarding", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"mode\":1}", memory.last_request.?.body.?);

    _ = try client.editGuildIncidentActions(
        Snowflake.init(10),
        Types.EditGuildIncidentActions.init().clearInvitesDisabledUntil(),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/incident-actions", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"invites_disabled_until\":null}", memory.last_request.?.body.?);

    _ = try client.setGuildIncidentActions(
        Snowflake.init(10),
        Types.EditGuildIncidentActions.init().clearDmsDisabledUntil(),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/incident-actions", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"dms_disabled_until\":null}", memory.last_request.?.body.?);

    _ = try client.getGuildVanityUrl(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/vanity-url", memory.last_request.?.url);

    _ = try client.fetchGuildVanityUrl(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/vanity-url", memory.last_request.?.url);

    _ = try client.fetchGuildScheduledEvents(Snowflake.init(10), Types.ListGuildScheduledEvents.init().withUserCount(true));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/scheduled-events?with_user_count=true",
        memory.last_request.?.url,
    );

    _ = try client.fetchGuildScheduledEvent(Snowflake.init(10), Snowflake.init(20), Types.GetGuildScheduledEvent.init().withUserCount(true));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/scheduled-events/20?with_user_count=true",
        memory.last_request.?.url,
    );

    _ = try client.createGuildScheduledEvent(
        Snowflake.init(10),
        Types.CreateGuildScheduledEvent.init("Meetup", "2026-06-02T10:00:00.000Z", .external)
            .withMetadata(Types.GuildScheduledEventEntityMetadata.withLocation("Istanbul"))
            .withEndTime("2026-06-02T12:00:00.000Z"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/scheduled-events", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"entity_metadata\":{\"location\":\"Istanbul\"},\"name\":\"Meetup\",\"privacy_level\":2,\"scheduled_start_time\":\"2026-06-02T10:00:00.000Z\",\"scheduled_end_time\":\"2026-06-02T12:00:00.000Z\",\"entity_type\":3}",
        memory.last_request.?.body.?,
    );

    _ = try client.fetchGuildScheduledEventUsers(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.ListGuildScheduledEventUsers.init().withLimit(10),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/scheduled-events/20/users?limit=10",
        memory.last_request.?.url,
    );

    _ = try client.listGuildAuditLog(Snowflake.init(10), Types.ListAuditLog.init().withLimit(5));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/audit-logs?limit=5",
        memory.last_request.?.url,
    );

    _ = try client.fetchAuditLog(Snowflake.init(10), Types.ListAuditLog.init().withLimit(5));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/audit-logs?limit=5",
        memory.last_request.?.url,
    );

    _ = try client.listGuildIntegrations(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/integrations", memory.last_request.?.url);

    _ = try client.fetchGuildIntegrations(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/integrations", memory.last_request.?.url);

    _ = try client.deleteGuildIntegration(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/integrations/20", memory.last_request.?.url);

    _ = try client.fetchApplicationSkus(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/skus", memory.last_request.?.url);

    _ = try client.fetchApplicationRoleConnectionMetadataRecords(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/role-connections/metadata",
        memory.last_request.?.url,
    );

    const metadata_records = [_]Types.ApplicationRoleConnectionMetadata{
        Types.ApplicationRoleConnectionMetadata.init(.boolean_equal, "verified", "Verified", "Account verified"),
    };
    _ = try client.setApplicationRoleConnectionMetadataRecords(
        Snowflake.init(10),
        Types.UpdateApplicationRoleConnectionMetadataRecords.init(&metadata_records),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/role-connections/metadata",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "[{\"type\":7,\"key\":\"verified\",\"name\":\"Verified\",\"description\":\"Account verified\"}]",
        memory.last_request.?.body.?,
    );

    _ = try client.fetchApplicationEmojis(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/emojis", memory.last_request.?.url);

    _ = try client.fetchApplicationEmoji(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/emojis/20", memory.last_request.?.url);

    _ = try client.createApplicationEmoji(
        Snowflake.init(10),
        Types.CreateApplicationEmoji.init("zig", "data:image/webp;base64,abc"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/emojis", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"zig\",\"image\":\"data:image/webp;base64,abc\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.createApplicationEmojiWithImage(Snowflake.init(10), "zig-shortcut", "data:image/webp;base64,def");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/emojis", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"zig-shortcut\",\"image\":\"data:image/webp;base64,def\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.editApplicationEmoji(Snowflake.init(10), Snowflake.init(20), Types.EditApplicationEmoji.init("ziggy"));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/emojis/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"ziggy\"}", memory.last_request.?.body.?);

    _ = try client.renameApplicationEmoji(Snowflake.init(10), Snowflake.init(20), "zig-app-renamed");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/emojis/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"zig-app-renamed\"}", memory.last_request.?.body.?);

    _ = try client.deleteApplicationEmoji(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/emojis/20", memory.last_request.?.url);

    _ = try client.getApplicationActivityInstance(Snowflake.init(10), "abc:def 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/activity-instances/abc%3Adef%20123",
        memory.last_request.?.url,
    );

    _ = try client.fetchApplicationActivityInstance(Snowflake.init(10), "abc:def 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/activity-instances/abc%3Adef%20123",
        memory.last_request.?.url,
    );

    const lobby_metadata = [_]Types.StringPair{.{ .key = "mode", .value = "duo" }};

    _ = try client.createLobby(Types.CreateLobby.init().withMetadata(&lobby_metadata).withIdleTimeout(60));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies", memory.last_request.?.url);

    _ = try client.fetchLobby(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10", memory.last_request.?.url);

    _ = try client.editLobby(Snowflake.init(10), Types.EditLobby.init().clearMetadata());
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("{\"metadata\":null}", memory.last_request.?.body.?);

    _ = try client.setLobbyMember(Snowflake.init(10), Snowflake.init(20), Types.UpdateLobbyMember.init().withMetadata(&lobby_metadata).withFlags(1));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10/members/20", memory.last_request.?.url);

    const lobby_members = [_]Types.LobbyMember{Types.LobbyMember.init(Snowflake.init(20)).removeState(true)};
    _ = try client.bulkUpdateLobbyMembers(Snowflake.init(10), Types.BulkUpdateLobbyMembers.init(&lobby_members));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10/members/bulk", memory.last_request.?.url);

    _ = try client.removeLobbyMember(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10/members/20", memory.last_request.?.url);

    _ = try client.leaveLobby("Bearer user-token", Snowflake.init(10));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10/members/@me", memory.last_request.?.url);

    _ = try client.linkLobbyChannel("Bearer user-token", Snowflake.init(10), Types.LinkLobbyChannel.init(Snowflake.init(30)));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
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
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/lobbies/10/messages/30/moderation-metadata",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"action\":\"replace\",\"replacement\":\"Be kind\"}", memory.last_request.?.body.?);

    _ = try client.setLobbyMessageModerationMetadata(
        Snowflake.init(10),
        Snowflake.init(30),
        Types.UpdateLobbyMessageModerationMetadata.init(&moderation_metadata),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/lobbies/10/messages/30/moderation-metadata",
        memory.last_request.?.url,
    );

    _ = try client.deleteLobby(Snowflake.init(10));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10", memory.last_request.?.url);

    _ = try client.fetchEntitlements(
        Snowflake.init(10),
        Types.ListEntitlements.init().withLimit(10).forGuild(Snowflake.init(20)),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/entitlements?limit=10&guild_id=20",
        memory.last_request.?.url,
    );

    _ = try client.fetchEntitlement(Snowflake.init(10), Snowflake.init(40));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/entitlements/40", memory.last_request.?.url);

    _ = try client.consumeEntitlement(Snowflake.init(10), Snowflake.init(40));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/entitlements/40/consume", memory.last_request.?.url);

    _ = try client.markEntitlementConsumed(Snowflake.init(10), Snowflake.init(40));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/entitlements/40/consume", memory.last_request.?.url);

    _ = try client.createTestEntitlement(
        Snowflake.init(10),
        Types.CreateTestEntitlement.init(Snowflake.init(30), Snowflake.init(20), .guild),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "{\"sku_id\":\"30\",\"owner_id\":\"20\",\"owner_type\":1}",
        memory.last_request.?.body.?,
    );

    _ = try client.fetchSkuSubscriptions(
        Snowflake.init(30),
        Types.ListSkuSubscriptions.init().forUser(Snowflake.init(20)),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/skus/30/subscriptions?user_id=20",
        memory.last_request.?.url,
    );

    _ = try client.fetchSkuSubscription(Snowflake.init(30), Snowflake.init(60));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/skus/30/subscriptions/60", memory.last_request.?.url);

    _ = try client.listGuildBans(
        Snowflake.init(10),
        Types.ListGuildBans.init().afterUser(Snowflake.init(20)).withLimit(10),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/bans?after=20&limit=10",
        memory.last_request.?.url,
    );

    _ = try client.fetchBans(
        Snowflake.init(10),
        Types.ListGuildBans.init().afterUser(Snowflake.init(20)).withLimit(10),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/bans?after=20&limit=10",
        memory.last_request.?.url,
    );

    _ = try client.getGuildBan(Snowflake.init(10), Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bans/30", memory.last_request.?.url);

    _ = try client.fetchBan(Snowflake.init(10), Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bans/30", memory.last_request.?.url);

    _ = try client.getGuildPruneCount(Snowflake.init(10), Types.GetGuildPruneCount.init().withDays(14));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/prune?days=14", memory.last_request.?.url);

    _ = try client.fetchPruneCount(Snowflake.init(10), Types.GetGuildPruneCount.init().withDays(14));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/prune?days=14", memory.last_request.?.url);

    _ = try client.beginGuildPrune(Snowflake.init(10), Types.BeginGuildPrune.init().computeCount(false));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/prune", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"compute_prune_count\":false}", memory.last_request.?.body.?);

    _ = try client.prune(Snowflake.init(10), Types.BeginGuildPrune.init().computeCount(false));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/prune", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"compute_prune_count\":false}", memory.last_request.?.body.?);

    _ = try client.pruneMembers(Snowflake.init(10));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/prune", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{}", memory.last_request.?.body.?);

    _ = try client.pruneMembersWithDays(Snowflake.init(10), 14);
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/prune", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"days\":14}", memory.last_request.?.body.?);

    _ = try client.pruneMembersWithDaysAndCount(Snowflake.init(10), 14, false);
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/prune", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"days\":14,\"compute_prune_count\":false}", memory.last_request.?.body.?);

    _ = try client.createGuildBan(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.CreateGuildBan.init().deleteMessagesFor(3600),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bans/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"delete_message_seconds\":3600}", memory.last_request.?.body.?);

    _ = try client.ban(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.CreateGuildBan.init().deleteMessagesFor(60),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bans/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"delete_message_seconds\":60}", memory.last_request.?.body.?);

    _ = try client.banUser(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bans/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{}", memory.last_request.?.body.?);

    _ = try client.banUserDeletingMessagesFor(Snowflake.init(10), Snowflake.init(20), 120);
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bans/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"delete_message_seconds\":120}", memory.last_request.?.body.?);

    const bulk_user_ids = [_]Snowflake{ Snowflake.init(20), Snowflake.init(30) };
    _ = try client.bulkGuildBan(Snowflake.init(10), Types.BulkGuildBan.init(&bulk_user_ids).deleteMessagesFor(120));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bulk-ban", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"user_ids\":[\"20\",\"30\"],\"delete_message_seconds\":120}",
        memory.last_request.?.body.?,
    );

    _ = try client.bulkBan(Snowflake.init(10), Types.BulkGuildBan.init(&bulk_user_ids));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bulk-ban", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"user_ids\":[\"20\",\"30\"]}", memory.last_request.?.body.?);

    _ = try client.bulkBanUsers(Snowflake.init(10), &bulk_user_ids);
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bulk-ban", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"user_ids\":[\"20\",\"30\"]}", memory.last_request.?.body.?);

    _ = try client.bulkBanUsersDeletingMessagesFor(Snowflake.init(10), &bulk_user_ids, 180);
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bulk-ban", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"user_ids\":[\"20\",\"30\"],\"delete_message_seconds\":180}",
        memory.last_request.?.body.?,
    );

    _ = try client.removeGuildBan(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bans/20", memory.last_request.?.url);

    _ = try client.unban(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bans/20", memory.last_request.?.url);

    _ = try client.listGuildMembers(Snowflake.init(10), Types.ListGuildMembers.init().withLimit(50));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/members?limit=50",
        memory.last_request.?.url,
    );

    _ = try client.fetchMembers(Snowflake.init(10), Types.ListGuildMembers.init().withLimit(50));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/members?limit=50",
        memory.last_request.?.url,
    );

    _ = try client.searchGuildMembers(
        Snowflake.init(10),
        Types.SearchGuildMembers.init("helper bot").withLimit(10),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/members/search?query=helper%20bot&limit=10",
        memory.last_request.?.url,
    );

    _ = try client.searchMembers(
        Snowflake.init(10),
        Types.SearchGuildMembers.init("helper bot").withLimit(10),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/members/search?query=helper%20bot&limit=10",
        memory.last_request.?.url,
    );

    _ = try client.getGuildMember(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);

    _ = try client.fetchMember(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);

    const member_roles = [_]Snowflake{Snowflake.init(30)};
    _ = try client.addGuildMember(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.AddGuildMember.init("oauth-access")
            .withNick("helper")
            .withRoles(&member_roles)
            .deafState(true),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"access_token\":\"oauth-access\",\"nick\":\"helper\",\"roles\":[\"30\"],\"deaf\":true}",
        memory.last_request.?.body.?,
    );

    _ = try client.editCurrentGuildMember(
        Snowflake.init(10),
        Types.EditCurrentGuildMember.init()
            .clearNick()
            .withBio("Built with Zig"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"nick\":null,\"bio\":\"Built with Zig\"}", memory.last_request.?.body.?);

    _ = try client.setCurrentGuildMemberNick(Snowflake.init(10), "ziggy");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"nick\":\"ziggy\"}", memory.last_request.?.body.?);

    _ = try client.clearCurrentGuildMemberNick(Snowflake.init(10));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"nick\":null}", memory.last_request.?.body.?);

    _ = try client.setCurrentGuildMemberAvatar(Snowflake.init(10), "data:image/png;base64,AAAA");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"avatar\":\"data:image/png;base64,AAAA\"}", memory.last_request.?.body.?);

    _ = try client.clearCurrentGuildMemberAvatar(Snowflake.init(10));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"avatar\":null}", memory.last_request.?.body.?);

    _ = try client.setCurrentGuildMemberBanner(Snowflake.init(10), "data:image/png;base64,BBBB");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"banner\":\"data:image/png;base64,BBBB\"}", memory.last_request.?.body.?);

    _ = try client.clearCurrentGuildMemberBanner(Snowflake.init(10));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"banner\":null}", memory.last_request.?.body.?);

    _ = try client.setCurrentGuildMemberBio(Snowflake.init(10), "Built with Zig");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"bio\":\"Built with Zig\"}", memory.last_request.?.body.?);

    _ = try client.clearCurrentGuildMemberBio(Snowflake.init(10));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"bio\":null}", memory.last_request.?.body.?);

    _ = try client.editCurrentUserNick(Snowflake.init(10), Types.EditCurrentUserNick.init().withNick("ziggy"));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me/nick", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"nick\":\"ziggy\"}", memory.last_request.?.body.?);

    _ = try client.setCurrentUserNick(Snowflake.init(10), null);
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me/nick", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"nick\":null}", memory.last_request.?.body.?);

    _ = try client.setNickname(Snowflake.init(10), "zig");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me/nick", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"nick\":\"zig\"}", memory.last_request.?.body.?);

    _ = try client.editGuildMember(Snowflake.init(10), Snowflake.init(20), Types.EditGuildMember.init().withNick("helper"));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"nick\":\"helper\"}", memory.last_request.?.body.?);

    _ = try client.setMemberNickname(Snowflake.init(10), Snowflake.init(20), "helper-2");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"nick\":\"helper-2\"}", memory.last_request.?.body.?);

    _ = try client.setMemberRoles(Snowflake.init(10), Snowflake.init(20), &.{ Snowflake.init(30), Snowflake.init(31) });
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"roles\":[\"30\",\"31\"]}", memory.last_request.?.body.?);

    _ = try client.muteMember(Snowflake.init(10), Snowflake.init(20), true);
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"mute\":true}", memory.last_request.?.body.?);

    _ = try client.deafenMember(Snowflake.init(10), Snowflake.init(20), true);
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"deaf\":true}", memory.last_request.?.body.?);

    _ = try client.moveMemberToVoiceChannel(Snowflake.init(10), Snowflake.init(20), Snowflake.init(40));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"channel_id\":\"40\"}", memory.last_request.?.body.?);

    _ = try client.timeoutMember(Snowflake.init(10), Snowflake.init(20), "2026-06-02T10:00:00.000Z");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"communication_disabled_until\":\"2026-06-02T10:00:00.000Z\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.clearMemberTimeout(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"communication_disabled_until\":null}", memory.last_request.?.body.?);

    _ = try client.kick(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);

    _ = try client.addGuildMemberRole(Snowflake.init(10), Snowflake.init(20), Snowflake.init(30));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20/roles/30", memory.last_request.?.url);

    _ = try client.addRole(Snowflake.init(10), Snowflake.init(20), Snowflake.init(30));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20/roles/30", memory.last_request.?.url);

    _ = try client.removeGuildMemberRole(Snowflake.init(10), Snowflake.init(20), Snowflake.init(30));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20/roles/30", memory.last_request.?.url);

    _ = try client.removeRole(Snowflake.init(10), Snowflake.init(20), Snowflake.init(30));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20/roles/30", memory.last_request.?.url);

    _ = try client.listGuildChannels(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/channels", memory.last_request.?.url);

    _ = try client.fetchGuildChannels(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/channels", memory.last_request.?.url);

    _ = try client.createGuildChannel(
        Snowflake.init(10),
        Types.CreateGuildChannel.init("general")
            .withType(.guild_forum)
            .withFlags(Types.ChannelFlags.require_tag)
            .withAvailableTags(&.{Types.WriteForumTag.init("Help").moderatedState(true)})
            .withDefaultReactionEmoji(Types.DefaultReactionEmoji.name("👋"))
            .withDefaultThreadRateLimit(5)
            .withDefaultSortOrder(.creation_date),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/channels", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"general\",\"type\":15,\"flags\":16,\"available_tags\":[{\"name\":\"Help\",\"moderated\":true}],\"default_reaction_emoji\":{\"emoji_name\":\"👋\"},\"default_thread_rate_limit_per_user\":5,\"default_sort_order\":1}",
        memory.last_request.?.body.?,
    );

    const channel_positions = [_]Types.GuildChannelPosition{
        Types.GuildChannelPosition.init(Snowflake.init(20))
            .withPosition(4)
            .lockPermissions(true),
    };
    _ = try client.editGuildChannelPositions(Snowflake.init(10), &channel_positions);
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/channels", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "[{\"id\":\"20\",\"position\":4,\"lock_permissions\":true}]",
        memory.last_request.?.body.?,
    );

    _ = try client.setGuildChannelPositions(Snowflake.init(10), &channel_positions);
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/channels", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "[{\"id\":\"20\",\"position\":4,\"lock_permissions\":true}]",
        memory.last_request.?.body.?,
    );

    _ = try client.editChannel(
        Snowflake.init(20),
        Types.EditChannel.init()
            .withName("announcements")
            .archivedState(true)
            .lockedState(true)
            .withAutoArchiveDuration(1440),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"announcements\",\"archived\":true,\"auto_archive_duration\":1440,\"locked\":true}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteChannel(Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/20", memory.last_request.?.url);

    _ = try client.editChannelPermission(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.EditChannelPermission.init(.role).withAllow(1024),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/permissions/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"type\":0,\"allow\":\"1024\"}", memory.last_request.?.body.?);

    _ = try client.setChannelPermission(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.EditChannelPermission.init(.role).withAllow(1024),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/permissions/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"type\":0,\"allow\":\"1024\"}", memory.last_request.?.body.?);

    _ = try client.deleteChannelPermission(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/permissions/20", memory.last_request.?.url);

    _ = try client.removeChannelPermission(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/permissions/20", memory.last_request.?.url);

    _ = try client.setVoiceChannelStatus(Snowflake.init(10), Types.SetVoiceChannelStatus.clear());
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/voice-status", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"status\":null}", memory.last_request.?.body.?);

    _ = try client.setVoiceChannelStatusText(Snowflake.init(10), "Focus room");
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/voice-status", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"status\":\"Focus room\"}", memory.last_request.?.body.?);

    _ = try client.clearVoiceChannelStatus(Snowflake.init(10));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/voice-status", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"status\":null}", memory.last_request.?.body.?);

    _ = try client.followAnnouncementChannel(Snowflake.init(10), Types.FollowAnnouncementChannel.init(Snowflake.init(30)));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/followers", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"webhook_channel_id\":\"30\"}", memory.last_request.?.body.?);

    _ = try client.followAnnouncementChannelTo(Snowflake.init(10), Snowflake.init(31));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/followers", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"webhook_channel_id\":\"31\"}", memory.last_request.?.body.?);

    _ = try client.followNewsChannel(Snowflake.init(10), Types.FollowAnnouncementChannel.init(Snowflake.init(32)));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/followers", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"webhook_channel_id\":\"32\"}", memory.last_request.?.body.?);

    _ = try client.followNewsChannelTo(Snowflake.init(10), Snowflake.init(33));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/followers", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"webhook_channel_id\":\"33\"}", memory.last_request.?.body.?);

    _ = try client.sendSoundboardSound(Snowflake.init(10), Types.SendSoundboardSound.init(Snowflake.init(40)));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/send-soundboard-sound",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"sound_id\":\"40\"}", memory.last_request.?.body.?);

    _ = try client.sendSoundboardSoundById(Snowflake.init(10), Snowflake.init(41));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/send-soundboard-sound",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"sound_id\":\"41\"}", memory.last_request.?.body.?);

    _ = try client.playSoundboardSound(Snowflake.init(10), Snowflake.init(42));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/send-soundboard-sound",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"sound_id\":\"42\"}", memory.last_request.?.body.?);

    _ = try client.createStageInstance(
        Types.CreateStageInstance.init(Snowflake.init(10), "Live Q&A")
            .withScheduledEvent(Snowflake.init(40)),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/stage-instances", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"channel_id\":\"10\",\"topic\":\"Live Q&A\",\"guild_scheduled_event_id\":\"40\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.fetchStageInstance(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/stage-instances/10", memory.last_request.?.url);

    _ = try client.editStageInstance(Snowflake.init(10), Types.EditStageInstance.init().withTopic("Aftershow"));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/stage-instances/10", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"topic\":\"Aftershow\"}", memory.last_request.?.body.?);

    _ = try client.fetchVoiceRegions();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/voice/regions", memory.last_request.?.url);

    _ = try client.listGuildVoiceRegions(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/regions", memory.last_request.?.url);

    _ = try client.fetchGuildVoiceRegions(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/regions", memory.last_request.?.url);

    _ = try client.fetchCurrentUserVoiceState(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/voice-states/@me", memory.last_request.?.url);

    _ = try client.fetchUserVoiceState(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/voice-states/20", memory.last_request.?.url);

    _ = try client.editCurrentUserVoiceState(
        Snowflake.init(10),
        Types.EditCurrentUserVoiceState.init()
            .suppressState(false)
            .requestToSpeakAt("2026-06-02T10:00:00.000Z"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/voice-states/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"suppress\":false,\"request_to_speak_timestamp\":\"2026-06-02T10:00:00.000Z\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.fetchRoles(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/roles", memory.last_request.?.url);

    _ = try client.fetchRole(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/roles/20", memory.last_request.?.url);

    _ = try client.getGuildRoleMemberCounts(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/roles/member-counts", memory.last_request.?.url);

    _ = try client.fetchRoleMemberCounts(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/roles/member-counts", memory.last_request.?.url);

    _ = try client.createRoleWithName(Snowflake.init(10), "helpers");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/roles", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"helpers\"}", memory.last_request.?.body.?);

    const positions = [_]Types.GuildRolePosition{Types.GuildRolePosition.init(Snowflake.init(20)).withPosition(3)};
    _ = try client.editGuildRolePositions(Snowflake.init(10), &positions);
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/roles", memory.last_request.?.url);
    try std.testing.expectEqualStrings("[{\"id\":\"20\",\"position\":3}]", memory.last_request.?.body.?);

    _ = try client.editGuildRole(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.EditGuildRole.init()
            .withColors(Types.RoleColors.init(5793266))
            .mentionableState(true)
            .clearUnicodeEmoji(),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/roles/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"colors\":{\"primary_color\":5793266,\"secondary_color\":null,\"tertiary_color\":null},\"unicode_emoji\":null,\"mentionable\":true}",
        memory.last_request.?.body.?,
    );

    _ = try client.renameRole(Snowflake.init(10), Snowflake.init(20), "helpers-renamed");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/roles/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"helpers-renamed\"}", memory.last_request.?.body.?);

    _ = try client.fetchEmojis(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/emojis", memory.last_request.?.url);

    _ = try client.fetchEmoji(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/emojis/20", memory.last_request.?.url);

    _ = try client.createGuildEmoji(Snowflake.init(10), Types.CreateGuildEmoji.init("zig", "data:image/webp;base64,abc"));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/emojis", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"zig\",\"image\":\"data:image/webp;base64,abc\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.createEmojiWithImage(Snowflake.init(10), "ziggy", "data:image/webp;base64,def");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/emojis", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"ziggy\",\"image\":\"data:image/webp;base64,def\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.renameEmoji(Snowflake.init(10), Snowflake.init(20), "zig-renamed");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/emojis/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"zig-renamed\"}", memory.last_request.?.body.?);

    _ = try client.deleteGuildEmoji(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/emojis/20", memory.last_request.?.url);

    _ = try client.fetchStickerById(Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/stickers/20", memory.last_request.?.url);

    _ = try client.fetchStickerPacks();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/sticker-packs", memory.last_request.?.url);

    _ = try client.fetchStickers(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/stickers", memory.last_request.?.url);

    _ = try client.fetchSticker(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/stickers/20", memory.last_request.?.url);

    _ = try client.createGuildSticker(
        Snowflake.init(10),
        Types.CreateGuildSticker.init("zig", "zap"),
        .{ .filename = "zig.png", .content = "PNG", .content_type = "image/png" },
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/stickers", memory.last_request.?.url);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "name=\"file\"; filename=\"zig.png\"") != null);

    _ = try client.renameSticker(Snowflake.init(10), Snowflake.init(20), "zig-renamed");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/stickers/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"zig-renamed\"}", memory.last_request.?.body.?);

    _ = try client.setStickerDescription(Snowflake.init(10), Snowflake.init(20), "Zig sticker");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/stickers/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"description\":\"Zig sticker\"}", memory.last_request.?.body.?);

    _ = try client.setStickerTags(Snowflake.init(10), Snowflake.init(20), "zig,zap");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/stickers/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"tags\":\"zig,zap\"}", memory.last_request.?.body.?);

    _ = try client.deleteGuildSticker(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/stickers/20", memory.last_request.?.url);

    _ = try client.fetchDefaultSoundboardSounds();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/soundboard-default-sounds", memory.last_request.?.url);

    _ = try client.fetchGuildSoundboardSounds(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/soundboard-sounds", memory.last_request.?.url);

    _ = try client.fetchGuildSoundboardSound(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/soundboard-sounds/20", memory.last_request.?.url);

    _ = try client.createGuildSoundboardSound(
        Snowflake.init(10),
        Types.CreateGuildSoundboardSound.init("launch", "data:audio/ogg;base64,T0dH"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/soundboard-sounds", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"launch\",\"sound\":\"data:audio/ogg;base64,T0dH\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.createSoundboardSoundWithData(Snowflake.init(10), "launch-2", "data:audio/ogg;base64,QUJD");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/soundboard-sounds", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"launch-2\",\"sound\":\"data:audio/ogg;base64,QUJD\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.renameSoundboardSound(Snowflake.init(10), Snowflake.init(20), "launch-renamed");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/soundboard-sounds/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"launch-renamed\"}", memory.last_request.?.body.?);

    _ = try client.deleteGuildSoundboardSound(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/soundboard-sounds/20", memory.last_request.?.url);

    _ = try client.fetchAutoModerationRules(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/auto-moderation/rules",
        memory.last_request.?.url,
    );

    _ = try client.fetchAutoModerationRule(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/auto-moderation/rules/20",
        memory.last_request.?.url,
    );

    _ = try client.createAutoModerationRule(Snowflake.init(10), Types.CreateAutoModerationRule.init(
        "spam guard",
        .spam,
        &.{Types.AutoModerationAction.blockMessage(null)},
    ));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/auto-moderation/rules",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"spam guard\",\"event_type\":1,\"trigger_type\":3,\"actions\":[{\"type\":1}]}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteAutoModerationRule(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/auto-moderation/rules/20",
        memory.last_request.?.url,
    );

    _ = try client.createThreadWithName(Snowflake.init(10), "standalone");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/threads", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"standalone\",\"type\":11}", memory.last_request.?.body.?);

    _ = try client.createThreadFromMessage(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.CreateThreadFromMessage.init("debug"),
    );
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/threads",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"name\":\"debug\"}", memory.last_request.?.body.?);

    _ = try client.startThreadFromMessage(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.CreateThreadFromMessage.init("debug"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/threads",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"name\":\"debug\"}", memory.last_request.?.body.?);

    _ = try client.startThreadFromMessageWithName(Snowflake.init(10), Snowflake.init(20), "debug shortcut");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/threads",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"name\":\"debug shortcut\"}", memory.last_request.?.body.?);

    _ = try client.joinThread(Snowflake.init(10));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members/@me",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.getThreadMember(Snowflake.init(10), Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members/30",
        memory.last_request.?.url,
    );

    _ = try client.fetchThreadMember(Snowflake.init(10), Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members/30",
        memory.last_request.?.url,
    );

    _ = try client.fetchThreadMembers(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members",
        memory.last_request.?.url,
    );

    _ = try client.listThreadMembersWithOptions(
        Snowflake.init(10),
        Types.ListThreadMembers.init()
            .withMemberExpansion(true)
            .afterMember(Snowflake.init(30))
            .withLimit(100),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members?with_member=true&after=30&limit=100",
        memory.last_request.?.url,
    );

    _ = try client.fetchThreadMembersWithOptions(
        Snowflake.init(10),
        Types.ListThreadMembers.init()
            .withMemberExpansion(false)
            .withLimit(25),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members?with_member=false&limit=25",
        memory.last_request.?.url,
    );

    _ = try client.listActiveGuildThreads(Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/30/threads/active",
        memory.last_request.?.url,
    );

    _ = try client.fetchActiveThreads(Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/30/threads/active",
        memory.last_request.?.url,
    );

    _ = try client.listPublicArchivedThreads(Snowflake.init(10), Types.ListArchivedThreads.init().withLimit(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/threads/archived/public?limit=10",
        memory.last_request.?.url,
    );

    _ = try client.fetchPublicArchivedThreads(Snowflake.init(10), Types.ListArchivedThreads.init().withLimit(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/threads/archived/public?limit=10",
        memory.last_request.?.url,
    );

    _ = try client.listPrivateArchivedThreads(Snowflake.init(10), Types.ListArchivedThreads.init().withLimit(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/threads/archived/private?limit=10",
        memory.last_request.?.url,
    );

    _ = try client.fetchPrivateArchivedThreads(Snowflake.init(10), Types.ListArchivedThreads.init().withLimit(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/threads/archived/private?limit=10",
        memory.last_request.?.url,
    );

    _ = try client.listJoinedPrivateArchivedThreads(Snowflake.init(10), Types.ListArchivedThreads.init().withLimit(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/users/@me/threads/archived/private?limit=10",
        memory.last_request.?.url,
    );

    _ = try client.fetchJoinedPrivateArchivedThreads(Snowflake.init(10), Types.ListArchivedThreads.init().withLimit(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/users/@me/threads/archived/private?limit=10",
        memory.last_request.?.url,
    );

    _ = try client.createInvite(Snowflake.init(10), Types.CreateChannelInvite.init().withMaxUses(1));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/invites", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"max_uses\":1}", memory.last_request.?.body.?);

    _ = try client.createDefaultInvite(Snowflake.init(10));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/invites", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{}", memory.last_request.?.body.?);

    _ = try client.createInviteWithMaxUses(Snowflake.init(10), 2);
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/invites", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"max_uses\":2}", memory.last_request.?.body.?);

    _ = try client.createInviteWithMaxAge(Snowflake.init(10), 3600);
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/invites", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"max_age\":3600}", memory.last_request.?.body.?);

    _ = try client.createUniqueInvite(Snowflake.init(10));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/invites", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"unique\":true}", memory.last_request.?.body.?);

    _ = try client.listChannelInvites(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/invites", memory.last_request.?.url);

    _ = try client.fetchChannelInvites(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/invites", memory.last_request.?.url);

    _ = try client.listGuildInvites(Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/20/invites", memory.last_request.?.url);

    _ = try client.fetchGuildInvites(Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/20/invites", memory.last_request.?.url);

    _ = try client.getInvite("abc 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/invites/abc%20123", memory.last_request.?.url);

    _ = try client.fetchInvite("abc 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/invites/abc%20123", memory.last_request.?.url);

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

    _ = try client.fetchInviteWithOptions("abc 123", Types.GetInvite.init().withCounts(true));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123?with_counts=true",
        memory.last_request.?.url,
    );

    _ = try client.deleteInvite("abc 123");
    try std.testing.expectEqualStrings("https://discord.com/api/v10/invites/abc%20123", memory.last_request.?.url);

    _ = try client.getInviteTargetUsers("abc 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123/target-users",
        memory.last_request.?.url,
    );

    _ = try client.fetchInviteTargetUsers("abc 123");
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
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "name=\"target_users_file\"; filename=\"targets.csv\"") != null);

    _ = try client.setInviteTargetUsers(
        "abc 123",
        Types.UploadFile.init("targets.csv", "user_id\n42\n").withContentType("text/csv"),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123/target-users",
        memory.last_request.?.url,
    );
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "name=\"target_users_file\"; filename=\"targets.csv\"") != null);

    _ = try client.getInviteTargetUsersJobStatus("abc 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123/target-users/job-status",
        memory.last_request.?.url,
    );

    _ = try client.fetchInviteTargetUsersJobStatus("abc 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123/target-users/job-status",
        memory.last_request.?.url,
    );

    _ = try client.listChannelWebhooks(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/webhooks", memory.last_request.?.url);

    _ = try client.fetchChannelWebhooks(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/webhooks", memory.last_request.?.url);

    _ = try client.createWebhook(Snowflake.init(10), Types.CreateWebhook.init("deploys"));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/webhooks", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"deploys\"}", memory.last_request.?.body.?);

    _ = try client.createWebhookWithName(Snowflake.init(10), "alerts");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/webhooks", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"alerts\"}", memory.last_request.?.body.?);

    _ = try client.createWebhookWithAvatar(Snowflake.init(10), "alerts", "data:image/png;base64,AAAA");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/webhooks", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"alerts\",\"avatar\":\"data:image/png;base64,AAAA\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.listGuildWebhooks(Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/20/webhooks", memory.last_request.?.url);

    _ = try client.fetchGuildWebhooks(Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/20/webhooks", memory.last_request.?.url);

    _ = try client.getWebhook(Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30", memory.last_request.?.url);

    _ = try client.fetchWebhook(Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30", memory.last_request.?.url);

    _ = try client.editWebhook(Snowflake.init(30), Types.EditWebhook.init().withName("deploys-updated"));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"deploys-updated\"}", memory.last_request.?.body.?);

    _ = try client.deleteWebhook(Snowflake.init(30));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30", memory.last_request.?.url);

    _ = try client.getWebhookWithToken(Snowflake.init(30), "tok en");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30/tok%20en", memory.last_request.?.url);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);

    _ = try client.fetchWebhookWithToken(Snowflake.init(30), "tok en");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30/tok%20en", memory.last_request.?.url);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);

    _ = try client.editWebhookWithToken(
        Snowflake.init(30),
        "tok en",
        Types.EditWebhookWithToken.init().withName("token-deploys"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30/tok%20en", memory.last_request.?.url);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings("{\"name\":\"token-deploys\"}", memory.last_request.?.body.?);

    _ = try client.deleteWebhookWithToken(Snowflake.init(30), "tok en");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30/tok%20en", memory.last_request.?.url);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);

    _ = try client.executeWebhook(Snowflake.init(30), "tok en", Types.ExecuteWebhook.init("deploy complete"));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30/tok%20en", memory.last_request.?.url);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);

    _ = try client.executeWebhookWithContent(Snowflake.init(30), "tok en", "deploy shortcut");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30/tok%20en", memory.last_request.?.url);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings("{\"content\":\"deploy shortcut\"}", memory.last_request.?.body.?);

    const webhook_files = [_]Types.UploadFile{
        Types.UploadFile.init("deploy.txt", "ship").withContentType("text/plain"),
    };
    _ = try client.executeWebhookWithFiles(
        Snowflake.init(30),
        "tok en",
        Types.ExecuteWebhook.init("deploy with file"),
        &webhook_files,
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30/tok%20en", memory.last_request.?.url);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "multipart/form-data; boundary=discord-zig-boundary",
        memory.last_request.?.content_type.?,
    );
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"content\":\"deploy with file\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "name=\"files[0]\"; filename=\"deploy.txt\"") != null);

    _ = try client.getWebhookMessage(Snowflake.init(30), "tok en", Snowflake.init(50));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30/tok%20en/messages/50", memory.last_request.?.url);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);

    _ = try client.fetchWebhookMessage(Snowflake.init(30), "tok en", Snowflake.init(50));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30/tok%20en/messages/50", memory.last_request.?.url);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);

    _ = try client.editWebhookMessage(
        Snowflake.init(30),
        "tok en",
        Snowflake.init(50),
        Types.EditMessage.init().withContent("edited webhook"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30/tok%20en/messages/50", memory.last_request.?.url);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings("{\"content\":\"edited webhook\"}", memory.last_request.?.body.?);

    _ = try client.deleteWebhookMessage(Snowflake.init(30), "tok en", Snowflake.init(50));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30/tok%20en/messages/50", memory.last_request.?.url);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);

    _ = try client.fetchGlobalApplicationCommands(Snowflake.init(40));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/commands", memory.last_request.?.url);

    _ = try client.registerGlobalApplicationCommand(
        Snowflake.init(40),
        Interactions.ApplicationCommand.chatInput("ping", "Replies with pong"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/commands", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"ping\",\"description\":\"Replies with pong\",\"type\":1}",
        memory.last_request.?.body.?,
    );

    _ = try client.bulkOverwriteGlobalApplicationCommands(Snowflake.init(40), &.{
        Interactions.ApplicationCommand.chatInput("ping", "Replies with pong"),
    });
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/commands", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "[{\"name\":\"ping\",\"description\":\"Replies with pong\",\"type\":1}]",
        memory.last_request.?.body.?,
    );

    _ = try client.setGlobalApplicationCommands(Snowflake.init(40), &.{
        Interactions.ApplicationCommand.chatInput("ping", "Replies with pong"),
    });
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/commands", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "[{\"name\":\"ping\",\"description\":\"Replies with pong\",\"type\":1}]",
        memory.last_request.?.body.?,
    );

    _ = try client.fetchGlobalApplicationCommand(Snowflake.init(40), Snowflake.init(60));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/commands/60", memory.last_request.?.url);

    _ = try client.updateGlobalApplicationCommand(
        Snowflake.init(40),
        Snowflake.init(60),
        Interactions.EditApplicationCommand.init().withDescription("Updated global"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/commands/60", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"description\":\"Updated global\"}", memory.last_request.?.body.?);

    _ = try client.renameGlobalApplicationCommand(Snowflake.init(40), Snowflake.init(60), "pong");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/commands/60", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"pong\"}", memory.last_request.?.body.?);

    _ = try client.setGlobalApplicationCommandDescription(Snowflake.init(40), Snowflake.init(60), "Replies with pong");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/commands/60", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"description\":\"Replies with pong\"}", memory.last_request.?.body.?);

    _ = try client.removeGlobalApplicationCommand(Snowflake.init(40), Snowflake.init(60));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/commands/60", memory.last_request.?.url);

    _ = try client.fetchGuildApplicationCommands(Snowflake.init(40), Snowflake.init(50));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/guilds/50/commands", memory.last_request.?.url);

    _ = try client.registerGuildApplicationCommand(
        Snowflake.init(40),
        Snowflake.init(50),
        Interactions.ApplicationCommand.chatInput("echo", "Echoes text"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/guilds/50/commands", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"echo\",\"description\":\"Echoes text\",\"type\":1}",
        memory.last_request.?.body.?,
    );

    _ = try client.bulkOverwriteGuildApplicationCommands(Snowflake.init(40), Snowflake.init(50), &.{
        Interactions.ApplicationCommand.chatInput("echo", "Echoes text"),
    });
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/guilds/50/commands", memory.last_request.?.url);

    _ = try client.setGuildApplicationCommands(Snowflake.init(40), Snowflake.init(50), &.{
        Interactions.ApplicationCommand.chatInput("echo", "Echoes text"),
    });
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/guilds/50/commands", memory.last_request.?.url);

    _ = try client.fetchGuildApplicationCommand(Snowflake.init(40), Snowflake.init(50), Snowflake.init(60));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/guilds/50/commands/60", memory.last_request.?.url);

    _ = try client.editGuildApplicationCommand(
        Snowflake.init(40),
        Snowflake.init(50),
        Snowflake.init(60),
        Interactions.EditApplicationCommand.init().withDescription("Updated"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/guilds/50/commands/60", memory.last_request.?.url);

    _ = try client.updateGuildApplicationCommand(
        Snowflake.init(40),
        Snowflake.init(50),
        Snowflake.init(60),
        Interactions.EditApplicationCommand.init().withDescription("Updated guild"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/guilds/50/commands/60", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"description\":\"Updated guild\"}", memory.last_request.?.body.?);

    _ = try client.renameGuildApplicationCommand(Snowflake.init(40), Snowflake.init(50), Snowflake.init(60), "guild-pong");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/guilds/50/commands/60", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"guild-pong\"}", memory.last_request.?.body.?);

    _ = try client.setGuildApplicationCommandDescription(
        Snowflake.init(40),
        Snowflake.init(50),
        Snowflake.init(60),
        "Guild command",
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/guilds/50/commands/60", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"description\":\"Guild command\"}", memory.last_request.?.body.?);

    _ = try client.removeGuildApplicationCommand(Snowflake.init(40), Snowflake.init(50), Snowflake.init(60));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/guilds/50/commands/60", memory.last_request.?.url);

    const command_permissions = [_]Interactions.ApplicationCommandPermission{
        Interactions.ApplicationCommandPermission.role(Snowflake.init(70), true),
    };

    _ = try client.fetchGuildApplicationCommandPermissions(
        "Bearer user-token",
        Snowflake.init(40),
        Snowflake.init(50),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/40/guilds/50/commands/permissions",
        memory.last_request.?.url,
    );

    _ = try client.fetchApplicationCommandPermissions(
        "Bearer user-token",
        Snowflake.init(40),
        Snowflake.init(50),
        Snowflake.init(60),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/40/guilds/50/commands/60/permissions",
        memory.last_request.?.url,
    );

    _ = try client.editApplicationCommandPermissions(
        "Bearer user-token",
        Snowflake.init(40),
        Snowflake.init(50),
        Snowflake.init(60),
        &command_permissions,
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/40/guilds/50/commands/60/permissions",
        memory.last_request.?.url,
    );

    _ = try client.createInteractionResponse(
        Snowflake.init(80),
        "tok en",
        Interactions.InteractionResponse.message("ack"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/interactions/80/tok%20en/callback", memory.last_request.?.url);

    _ = try client.replyInteraction(
        Snowflake.init(80),
        "tok en",
        Interactions.InteractionResponse.message("reply").ephemeralState(true),
    );
    try std.testing.expectEqualStrings("{\"type\":4,\"data\":{\"content\":\"reply\",\"flags\":64}}", memory.last_request.?.body.?);

    _ = try client.deferInteractionReply(Snowflake.init(80), "tok en", true);
    try std.testing.expectEqualStrings("{\"type\":5,\"data\":{\"flags\":64}}", memory.last_request.?.body.?);

    _ = try client.deferInteractionUpdate(Snowflake.init(80), "tok en");
    try std.testing.expectEqualStrings("{\"type\":6}", memory.last_request.?.body.?);

    _ = try client.updateInteractionMessage(
        Snowflake.init(80),
        "tok en",
        Interactions.InteractionResponse.updateMessage("updated"),
    );
    try std.testing.expectEqualStrings("{\"type\":7,\"data\":{\"content\":\"updated\"}}", memory.last_request.?.body.?);

    const autocomplete_choices = [_]Interactions.CommandChoice{
        Interactions.CommandChoice.string("Public", "public"),
    };
    _ = try client.autocompleteInteraction(Snowflake.init(80), "tok en", &autocomplete_choices);
    try std.testing.expectEqualStrings(
        "{\"type\":8,\"data\":{\"choices\":[{\"name\":\"Public\",\"value\":\"public\"}]}}",
        memory.last_request.?.body.?,
    );

    const modal_inputs = [_]Interactions.Component{
        .{ .text_input = Interactions.TextInput.short("name", "Name") },
    };
    const modal_rows = [_]Interactions.Component{
        Interactions.Component.actionRow(&modal_inputs),
    };
    _ = try client.showModal(
        Snowflake.init(80),
        "tok en",
        Interactions.InteractionResponse.modal("profile", "Profile", &modal_rows),
    );
    try std.testing.expectEqualStrings(
        "{\"type\":9,\"data\":{\"custom_id\":\"profile\",\"title\":\"Profile\",\"components\":[{\"type\":1,\"components\":[{\"type\":4,\"custom_id\":\"name\",\"label\":\"Name\",\"style\":1}]}]}}",
        memory.last_request.?.body.?,
    );

    _ = try client.editOriginalInteractionResponse(
        Snowflake.init(40),
        "tok en",
        Types.EditMessage.init().withContent("done"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/40/tok%20en/messages/@original",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"content\":\"done\"}", memory.last_request.?.body.?);

    _ = try client.fetchOriginalInteractionResponse(Snowflake.init(40), "tok en");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/40/tok%20en/messages/@original",
        memory.last_request.?.url,
    );

    try std.testing.expectError(error.MissingCurrentApplication, client.fetchInteractionReply("tok en"));
    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":30,\"t\":\"READY\",\"d\":{\"session_id\":\"abc\",\"application\":{\"id\":\"40\",\"name\":\"app\"}}}",
    );

    _ = try client.fetchInteractionReply("tok en");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/40/tok%20en/messages/@original",
        memory.last_request.?.url,
    );

    _ = try client.editInteractionReply("tok en", Types.EditMessage.init().withContent("edited reply"));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("{\"content\":\"edited reply\"}", memory.last_request.?.body.?);

    _ = try client.deleteInteractionReply("tok en");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/40/tok%20en/messages/@original",
        memory.last_request.?.url,
    );

    _ = try client.createFollowupMessage(
        Snowflake.init(40),
        "tok en",
        Types.ExecuteWebhook.init("follow up"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/40/tok%20en", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"follow up\"}", memory.last_request.?.body.?);

    _ = try client.createFollowupMessageWithContent(Snowflake.init(40), "tok en", "follow up shortcut");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/40/tok%20en", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"follow up shortcut\"}", memory.last_request.?.body.?);

    _ = try client.fetchFollowupMessage(Snowflake.init(40), "tok en", Snowflake.init(50));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/40/tok%20en/messages/50",
        memory.last_request.?.url,
    );

    _ = try client.followUpInteraction("tok en", Types.ExecuteWebhook.init("follow up alias"));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/40/tok%20en", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"follow up alias\"}", memory.last_request.?.body.?);

    _ = try client.followUpInteractionWithContent("tok en", "follow up content alias");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/40/tok%20en", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"follow up content alias\"}", memory.last_request.?.body.?);

    _ = try client.fetchFollowUpInteraction("tok en", Snowflake.init(50));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/40/tok%20en/messages/50",
        memory.last_request.?.url,
    );

    _ = try client.editFollowUpInteraction(
        "tok en",
        Snowflake.init(50),
        Types.EditMessage.init().withContent("edited follow up"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/40/tok%20en/messages/50",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"content\":\"edited follow up\"}", memory.last_request.?.body.?);

    _ = try client.deleteFollowUpInteraction("tok en", Snowflake.init(50));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/40/tok%20en/messages/50",
        memory.last_request.?.url,
    );

    _ = try client.deleteFollowupMessage(Snowflake.init(40), "tok en", Snowflake.init(50));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/40/tok%20en/messages/50",
        memory.last_request.?.url,
    );

    _ = try client.react(Snowflake.init(10), Snowflake.init(20), "👍");
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions/%F0%9F%91%8D/@me",
        memory.last_request.?.url,
    );

    _ = try client.addReaction(Snowflake.init(10), Snowflake.init(20), "👍");
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions/%F0%9F%91%8D/@me",
        memory.last_request.?.url,
    );

    _ = try client.unreact(Snowflake.init(10), Snowflake.init(20), "👍");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions/%F0%9F%91%8D/@me",
        memory.last_request.?.url,
    );

    _ = try client.deleteOwnReaction(Snowflake.init(10), Snowflake.init(20), "👍");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions/%F0%9F%91%8D/@me",
        memory.last_request.?.url,
    );

    _ = try client.removeUserReaction(Snowflake.init(10), Snowflake.init(20), "👍", Snowflake.init(30));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions/%F0%9F%91%8D/30",
        memory.last_request.?.url,
    );

    _ = try client.removeReaction(Snowflake.init(10), Snowflake.init(20), "👍", Snowflake.init(30));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions/%F0%9F%91%8D/30",
        memory.last_request.?.url,
    );

    _ = try client.listReactions(
        Snowflake.init(10),
        Snowflake.init(20),
        "👍",
        Types.ListReactions.init().withLimit(10).withType(.normal),
    );
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions/%F0%9F%91%8D?limit=10&type=0",
        memory.last_request.?.url,
    );

    _ = try client.fetchReactions(
        Snowflake.init(10),
        Snowflake.init(20),
        "👍",
        Types.ListReactions.init().withLimit(10).withType(.normal),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions/%F0%9F%91%8D?limit=10&type=0",
        memory.last_request.?.url,
    );

    _ = try client.clearReactions(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions",
        memory.last_request.?.url,
    );

    _ = try client.deleteAllReactions(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions",
        memory.last_request.?.url,
    );

    _ = try client.removeAllReactions(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions",
        memory.last_request.?.url,
    );

    _ = try client.clearReactionsForEmoji(Snowflake.init(10), Snowflake.init(20), "👍");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions/%F0%9F%91%8D",
        memory.last_request.?.url,
    );

    _ = try client.deleteAllReactionsForEmoji(Snowflake.init(10), Snowflake.init(20), "👍");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions/%F0%9F%91%8D",
        memory.last_request.?.url,
    );

    _ = try client.listPollAnswerVoters(
        Snowflake.init(10),
        Snowflake.init(20),
        1,
        Types.ListPollAnswerVoters.init().withLimit(10),
    );
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/polls/20/answers/1?limit=10",
        memory.last_request.?.url,
    );

    _ = try client.fetchPollAnswerVoters(
        Snowflake.init(10),
        Snowflake.init(20),
        1,
        Types.ListPollAnswerVoters.init().withLimit(10),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/polls/20/answers/1?limit=10",
        memory.last_request.?.url,
    );

    _ = try client.endPoll(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/polls/20/expire",
        memory.last_request.?.url,
    );
}

test "client auto moderation event convenience registers handlers" {
    const State = struct {
        rule_created: bool = false,
        action_executed: bool = false,

        fn onAutoModerationRuleCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.AUTO_MODERATION_RULE_CREATE, dispatch.event);
            self.rule_created = true;
        }

        fn onAutoModerationActionExecution(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.AUTO_MODERATION_ACTION_EXECUTION, dispatch.event);
            self.action_executed = true;
        }
    };

    var memory = Rest.MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var state = State{};
    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
        .transport = memory.transport(),
    });
    defer client.deinit();

    client.onAutoModerationRuleCreate(Events.rawHandler(&state, State.onAutoModerationRuleCreate));
    client.onAutoModerationActionExecution(Events.rawHandler(&state, State.onAutoModerationActionExecution));

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":1,\"t\":\"AUTO_MODERATION_RULE_CREATE\",\"d\":{\"id\":\"20\",\"guild_id\":\"10\",\"name\":\"keyword guard\"}}",
    );
    try std.testing.expect(state.rule_created);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":2,\"t\":\"AUTO_MODERATION_ACTION_EXECUTION\",\"d\":{\"guild_id\":\"10\",\"rule_id\":\"20\",\"rule_trigger_type\":1,\"user_id\":\"30\",\"action\":{\"type\":1}}}",
    );
    try std.testing.expect(state.action_executed);
}

test "client entitlement and subscription event convenience registers handlers" {
    const State = struct {
        created: bool = false,
        deleted: bool = false,
        subscription_created: bool = false,
        subscription_updated: bool = false,
        subscription_deleted: bool = false,

        fn onEntitlementCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.ENTITLEMENT_CREATE, dispatch.event);
            self.created = true;
        }

        fn onEntitlementDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.ENTITLEMENT_DELETE, dispatch.event);
            self.deleted = true;
        }

        fn onSubscriptionCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.SUBSCRIPTION_CREATE, dispatch.event);
            self.subscription_created = true;
        }

        fn onSubscriptionUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.SUBSCRIPTION_UPDATE, dispatch.event);
            self.subscription_updated = true;
        }

        fn onSubscriptionDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.SUBSCRIPTION_DELETE, dispatch.event);
            self.subscription_deleted = true;
        }
    };

    var memory = Rest.MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var state = State{};
    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
        .transport = memory.transport(),
    });
    defer client.deinit();

    client.onEntitlementCreate(Events.rawHandler(&state, State.onEntitlementCreate));
    client.onEntitlementDelete(Events.rawHandler(&state, State.onEntitlementDelete));
    client.onSubscriptionCreate(Events.rawHandler(&state, State.onSubscriptionCreate));
    client.onSubscriptionUpdate(Events.rawHandler(&state, State.onSubscriptionUpdate));
    client.onSubscriptionDelete(Events.rawHandler(&state, State.onSubscriptionDelete));

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":1,\"t\":\"ENTITLEMENT_CREATE\",\"d\":{\"id\":\"10\",\"sku_id\":\"20\",\"application_id\":\"30\",\"type\":8,\"deleted\":false}}",
    );
    try std.testing.expect(state.created);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":2,\"t\":\"ENTITLEMENT_DELETE\",\"d\":{\"id\":\"10\",\"sku_id\":\"20\",\"application_id\":\"30\",\"type\":8,\"deleted\":true}}",
    );
    try std.testing.expect(state.deleted);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":3,\"t\":\"SUBSCRIPTION_CREATE\",\"d\":{\"id\":\"40\",\"user_id\":\"50\",\"sku_ids\":[\"20\"],\"entitlement_ids\":[\"10\"],\"current_period_start\":\"2026-01-01T00:00:00.000000+00:00\",\"current_period_end\":\"2026-02-01T00:00:00.000000+00:00\",\"status\":0}}",
    );
    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":4,\"t\":\"SUBSCRIPTION_UPDATE\",\"d\":{\"id\":\"40\",\"user_id\":\"50\",\"sku_ids\":[\"20\"],\"entitlement_ids\":[\"10\"],\"current_period_start\":\"2026-01-01T00:00:00.000000+00:00\",\"current_period_end\":\"2026-02-01T00:00:00.000000+00:00\",\"status\":1}}",
    );
    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":5,\"t\":\"SUBSCRIPTION_DELETE\",\"d\":{\"id\":\"40\",\"user_id\":\"50\",\"sku_ids\":[\"20\"],\"entitlement_ids\":[\"10\"],\"current_period_start\":\"2026-01-01T00:00:00.000000+00:00\",\"current_period_end\":\"2026-02-01T00:00:00.000000+00:00\",\"status\":2}}",
    );
    try std.testing.expect(state.subscription_created);
    try std.testing.expect(state.subscription_updated);
    try std.testing.expect(state.subscription_deleted);
}

test "client soundboard event convenience registers handlers" {
    const State = struct {
        sound_created: bool = false,
        sounds_response: bool = false,
        voice_effect: bool = false,

        fn onGuildSoundboardSoundCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_SOUNDBOARD_SOUND_CREATE, dispatch.event);
            self.sound_created = true;
        }

        fn onSoundboardSounds(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.SOUNDBOARD_SOUNDS, dispatch.event);
            self.sounds_response = true;
        }

        fn onVoiceChannelEffectSend(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.VOICE_CHANNEL_EFFECT_SEND, dispatch.event);
            self.voice_effect = true;
        }
    };

    var memory = Rest.MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var state = State{};
    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
        .transport = memory.transport(),
    });
    defer client.deinit();

    client.onGuildSoundboardSoundCreate(Events.rawHandler(&state, State.onGuildSoundboardSoundCreate));
    client.onSoundboardSounds(Events.rawHandler(&state, State.onSoundboardSounds));
    client.onVoiceChannelEffectSend(Events.rawHandler(&state, State.onVoiceChannelEffectSend));

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":1,\"t\":\"GUILD_SOUNDBOARD_SOUND_CREATE\",\"d\":{\"sound_id\":\"20\",\"guild_id\":\"10\",\"name\":\"launch\"}}",
    );
    try std.testing.expect(state.sound_created);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":2,\"t\":\"SOUNDBOARD_SOUNDS\",\"d\":{\"guild_id\":\"10\",\"soundboard_sounds\":[]}}",
    );
    try std.testing.expect(state.sounds_response);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":3,\"t\":\"VOICE_CHANNEL_EFFECT_SEND\",\"d\":{\"channel_id\":\"30\",\"guild_id\":\"10\",\"user_id\":\"40\",\"sound_id\":\"20\"}}",
    );
    try std.testing.expect(state.voice_effect);
}

test "client runtime event convenience registers handlers" {
    const State = struct {
        permissions_updated: bool = false,
        audit_log_entry_created: bool = false,
        members_chunked: bool = false,
        voice_server_updated: bool = false,
        channel_info: bool = false,
        voice_status_updated: bool = false,
        voice_start_time_updated: bool = false,
        rate_limited: bool = false,

        fn onApplicationCommandPermissionsUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.APPLICATION_COMMAND_PERMISSIONS_UPDATE, dispatch.event);
            self.permissions_updated = true;
        }

        fn onGuildAuditLogEntryCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_AUDIT_LOG_ENTRY_CREATE, dispatch.event);
            self.audit_log_entry_created = true;
        }

        fn onGuildMembersChunk(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_MEMBERS_CHUNK, dispatch.event);
            self.members_chunked = true;
        }

        fn onVoiceServerUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.VOICE_SERVER_UPDATE, dispatch.event);
            self.voice_server_updated = true;
        }

        fn onChannelInfo(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.CHANNEL_INFO, dispatch.event);
            self.channel_info = true;
        }

        fn onVoiceChannelStatusUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.VOICE_CHANNEL_STATUS_UPDATE, dispatch.event);
            self.voice_status_updated = true;
        }

        fn onVoiceChannelStartTimeUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.VOICE_CHANNEL_START_TIME_UPDATE, dispatch.event);
            self.voice_start_time_updated = true;
        }

        fn onRateLimited(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.RATE_LIMITED, dispatch.event);
            self.rate_limited = true;
        }
    };

    var memory = Rest.MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var state = State{};
    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
        .transport = memory.transport(),
    });
    defer client.deinit();

    client.onApplicationCommandPermissionsUpdate(Events.rawHandler(&state, State.onApplicationCommandPermissionsUpdate));
    client.onGuildAuditLogEntryCreate(Events.rawHandler(&state, State.onGuildAuditLogEntryCreate));
    client.onGuildMembersChunk(Events.rawHandler(&state, State.onGuildMembersChunk));
    client.onVoiceServerUpdate(Events.rawHandler(&state, State.onVoiceServerUpdate));
    client.onChannelInfo(Events.rawHandler(&state, State.onChannelInfo));
    client.onVoiceChannelStatusUpdate(Events.rawHandler(&state, State.onVoiceChannelStatusUpdate));
    client.onVoiceChannelStartTimeUpdate(Events.rawHandler(&state, State.onVoiceChannelStartTimeUpdate));
    client.onRateLimited(Events.rawHandler(&state, State.onRateLimited));

    _ = try client.dispatchGatewayPayload("{\"op\":0,\"s\":1,\"t\":\"APPLICATION_COMMAND_PERMISSIONS_UPDATE\",\"d\":{}}");
    _ = try client.dispatchGatewayPayload("{\"op\":0,\"s\":2,\"t\":\"GUILD_AUDIT_LOG_ENTRY_CREATE\",\"d\":{}}");
    _ = try client.dispatchGatewayPayload("{\"op\":0,\"s\":3,\"t\":\"GUILD_MEMBERS_CHUNK\",\"d\":{}}");
    _ = try client.dispatchGatewayPayload("{\"op\":0,\"s\":4,\"t\":\"VOICE_SERVER_UPDATE\",\"d\":{}}");
    _ = try client.dispatchGatewayPayload("{\"op\":0,\"s\":5,\"t\":\"CHANNEL_INFO\",\"d\":{}}");
    _ = try client.dispatchGatewayPayload("{\"op\":0,\"s\":6,\"t\":\"VOICE_CHANNEL_STATUS_UPDATE\",\"d\":{}}");
    _ = try client.dispatchGatewayPayload("{\"op\":0,\"s\":7,\"t\":\"VOICE_CHANNEL_START_TIME_UPDATE\",\"d\":{}}");
    _ = try client.dispatchGatewayPayload("{\"op\":0,\"s\":8,\"t\":\"RATE_LIMITED\",\"d\":{\"retry_after\":1,\"limit\":1,\"method\":\"GET\",\"route\":\"/test\"}}");

    try std.testing.expect(state.permissions_updated);
    try std.testing.expect(state.audit_log_entry_created);
    try std.testing.expect(state.members_chunked);
    try std.testing.expect(state.voice_server_updated);
    try std.testing.expect(state.channel_info);
    try std.testing.expect(state.voice_status_updated);
    try std.testing.expect(state.voice_start_time_updated);
    try std.testing.expect(state.rate_limited);
}

test "client supports generic one-shot event listeners" {
    const State = struct {
        ready_count: usize = 0,
        resumed_count: usize = 0,
        message_count: usize = 0,
        message_update_count: usize = 0,
        message_delete_count: usize = 0,
        message_delete_bulk_count: usize = 0,
        reaction_add_count: usize = 0,
        reaction_remove_count: usize = 0,
        reaction_remove_all_count: usize = 0,
        reaction_remove_emoji_count: usize = 0,
        poll_vote_add_count: usize = 0,
        poll_vote_remove_count: usize = 0,
        interaction_count: usize = 0,
        application_command_count: usize = 0,
        component_count: usize = 0,
        autocomplete_count: usize = 0,
        modal_count: usize = 0,
        permissions_count: usize = 0,
        unknown_count: usize = 0,

        fn onReady(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.READY, dispatch.event);
            self.ready_count += 1;
        }

        fn onResumed(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.RESUMED, dispatch.event);
            self.resumed_count += 1;
        }

        fn onMessage(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_CREATE, dispatch.event);
            self.message_count += 1;
        }

        fn onMessageUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_UPDATE, dispatch.event);
            self.message_update_count += 1;
        }

        fn onMessageDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_DELETE, dispatch.event);
            self.message_delete_count += 1;
        }

        fn onMessageDeleteBulk(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_DELETE_BULK, dispatch.event);
            self.message_delete_bulk_count += 1;
        }

        fn onReactionAdd(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_REACTION_ADD, dispatch.event);
            self.reaction_add_count += 1;
        }

        fn onReactionRemove(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_REACTION_REMOVE, dispatch.event);
            self.reaction_remove_count += 1;
        }

        fn onReactionRemoveAll(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_REACTION_REMOVE_ALL, dispatch.event);
            self.reaction_remove_all_count += 1;
        }

        fn onReactionRemoveEmoji(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_REACTION_REMOVE_EMOJI, dispatch.event);
            self.reaction_remove_emoji_count += 1;
        }

        fn onPollVoteAdd(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_POLL_VOTE_ADD, dispatch.event);
            self.poll_vote_add_count += 1;
        }

        fn onPollVoteRemove(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_POLL_VOTE_REMOVE, dispatch.event);
            self.poll_vote_remove_count += 1;
        }

        fn onInteraction(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTERACTION_CREATE, dispatch.event);
            self.interaction_count += 1;
        }

        fn onApplicationCommand(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTERACTION_CREATE, dispatch.event);
            self.application_command_count += 1;
        }

        fn onComponent(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTERACTION_CREATE, dispatch.event);
            self.component_count += 1;
        }

        fn onAutocomplete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTERACTION_CREATE, dispatch.event);
            self.autocomplete_count += 1;
        }

        fn onModal(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTERACTION_CREATE, dispatch.event);
            self.modal_count += 1;
        }

        fn onPermissions(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.APPLICATION_COMMAND_PERMISSIONS_UPDATE, dispatch.event);
            self.permissions_count += 1;
        }

        fn onUnknown(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.unknown, dispatch.event);
            self.unknown_count += 1;
        }
    };

    var state = State{};
    var client = Client.init(std.testing.allocator, .{ .token = "Bot test" });
    defer client.deinit();

    try std.testing.expect(!client.hasListener(.READY));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.READY));

    client.onceReady(Events.rawHandler(&state, State.onReady));
    try std.testing.expect(client.hasListener(.READY));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.READY));
    try std.testing.expect(!client.isReady());
    try std.testing.expect(client.readyTimestampMs() == null);
    try std.testing.expect(client.uptimeMs(100) == null);
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":1,\"t\":\"READY\",\"d\":{\"session_id\":\"abc\",\"resume_gateway_url\":\"wss://gateway.discord.gg\"}}"));
    try std.testing.expect(client.isReady());
    try std.testing.expect(client.readyTimestampMs() == null);
    try std.testing.expect(client.uptimeMs(100) == null);
    try std.testing.expectEqual(@as(?u64, 1), client.lastGatewaySequence());
    try std.testing.expectEqual(@as(?Gateway.EventName, .READY), client.lastGatewayEvent());
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":2,\"t\":\"READY\",\"d\":{\"session_id\":\"def\",\"resume_gateway_url\":\"wss://gateway.discord.gg\"}}"));
    try std.testing.expectEqual(@as(?u64, 2), client.lastGatewaySequence());
    try std.testing.expectEqual(@as(usize, 1), state.ready_count);
    try std.testing.expect(!client.hasListener(.READY));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.READY));

    client.on(.READY, Events.rawHandler(&state, State.onReady));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.READY));
    client.clearListener(.READY);
    try std.testing.expect(!client.hasListener(.READY));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":3,\"t\":\"READY\",\"d\":{\"session_id\":\"ghi\",\"resume_gateway_url\":\"wss://gateway.discord.gg\"}}"));
    try std.testing.expectEqual(@as(usize, 1), state.ready_count);

    client.on(.READY, Events.rawHandler(&state, State.onReady));
    client.off(.READY);
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":4,\"t\":\"READY\",\"d\":{\"session_id\":\"jkl\",\"resume_gateway_url\":\"wss://gateway.discord.gg\"}}"));
    try std.testing.expectEqual(@as(usize, 1), state.ready_count);

    client.on(.READY, Events.rawHandler(&state, State.onReady));
    client.removeListener(.READY);
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":5,\"t\":\"READY\",\"d\":{\"session_id\":\"mno\",\"resume_gateway_url\":\"wss://gateway.discord.gg\"}}"));
    try std.testing.expectEqual(@as(usize, 1), state.ready_count);

    client.on(.READY, Events.rawHandler(&state, State.onReady));
    client.onceResumed(Events.rawHandler(&state, State.onResumed));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.READY));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.RESUMED));
    const names = try client.eventNames(std.testing.allocator);
    defer std.testing.allocator.free(names);
    try std.testing.expectEqual(@as(usize, 2), names.len);
    try std.testing.expect(std.mem.indexOfScalar(Gateway.EventName, names, .READY) != null);
    try std.testing.expect(std.mem.indexOfScalar(Gateway.EventName, names, .RESUMED) != null);

    client.removeAllListeners();
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.READY));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.RESUMED));
    const empty_names = try client.eventNames(std.testing.allocator);
    defer std.testing.allocator.free(empty_names);
    try std.testing.expectEqual(@as(usize, 0), empty_names.len);
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":6,\"t\":\"READY\",\"d\":{\"session_id\":\"pqr\",\"resume_gateway_url\":\"wss://gateway.discord.gg\"}}"));
    try std.testing.expectEqual(@as(usize, 1), state.ready_count);

    client.on(.READY, Events.rawHandler(&state, State.onReady));
    client.clearListeners();
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":7,\"t\":\"READY\",\"d\":{\"session_id\":\"stu\",\"resume_gateway_url\":\"wss://gateway.discord.gg\"}}"));
    try std.testing.expectEqual(@as(usize, 1), state.ready_count);

    client.resetGatewayState();
    try std.testing.expect(!client.isReady());
    try std.testing.expect(client.readyTimestampMs() == null);
    try std.testing.expect(client.uptimeMs(100) == null);
    try std.testing.expectEqual(@as(?u64, null), client.lastGatewaySequence());
    try std.testing.expectEqual(@as(?Gateway.EventName, null), client.lastGatewayEvent());
    try std.testing.expectEqual(@as(?u64, null), client.gatewayPingMs());

    client.onceResumed(Events.rawHandler(&state, State.onResumed));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":8,\"t\":\"RESUMED\",\"d\":{}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":9,\"t\":\"RESUMED\",\"d\":{}}"));
    try std.testing.expect(client.isReady());
    try std.testing.expectEqual(@as(?u64, 9), client.lastGatewaySequence());
    try std.testing.expectEqual(@as(?Gateway.EventName, .RESUMED), client.lastGatewayEvent());
    try std.testing.expectEqual(@as(usize, 1), state.resumed_count);

    client.onceMessageCreate(Events.rawHandler(&state, State.onMessage));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":10,\"t\":\"MESSAGE_CREATE\",\"d\":{\"id\":\"10\",\"channel_id\":\"20\",\"content\":\"hello\",\"author\":{\"id\":\"30\",\"username\":\"bot\"}}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":11,\"t\":\"MESSAGE_CREATE\",\"d\":{\"id\":\"11\",\"channel_id\":\"20\",\"content\":\"again\",\"author\":{\"id\":\"30\",\"username\":\"bot\"}}}"));
    try std.testing.expectEqual(@as(usize, 1), state.message_count);

    client.onceMessageUpdate(Events.rawHandler(&state, State.onMessageUpdate));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":12,\"t\":\"MESSAGE_UPDATE\",\"d\":{\"id\":\"10\",\"channel_id\":\"20\",\"content\":\"edited\",\"author\":{\"id\":\"30\",\"username\":\"bot\"}}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":13,\"t\":\"MESSAGE_UPDATE\",\"d\":{\"id\":\"10\",\"channel_id\":\"20\",\"content\":\"edited again\",\"author\":{\"id\":\"30\",\"username\":\"bot\"}}}"));
    try std.testing.expectEqual(@as(usize, 1), state.message_update_count);

    client.onceMessageDelete(Events.rawHandler(&state, State.onMessageDelete));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":14,\"t\":\"MESSAGE_DELETE\",\"d\":{\"id\":\"10\",\"channel_id\":\"20\"}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":15,\"t\":\"MESSAGE_DELETE\",\"d\":{\"id\":\"11\",\"channel_id\":\"20\"}}"));
    try std.testing.expectEqual(@as(usize, 1), state.message_delete_count);

    client.onceMessageDeleteBulk(Events.rawHandler(&state, State.onMessageDeleteBulk));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":16,\"t\":\"MESSAGE_DELETE_BULK\",\"d\":{\"ids\":[\"10\",\"11\"],\"channel_id\":\"20\"}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":17,\"t\":\"MESSAGE_DELETE_BULK\",\"d\":{\"ids\":[\"12\"],\"channel_id\":\"20\"}}"));
    try std.testing.expectEqual(@as(usize, 1), state.message_delete_bulk_count);

    client.onceMessageReactionAdd(Events.rawHandler(&state, State.onReactionAdd));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":18,\"t\":\"MESSAGE_REACTION_ADD\",\"d\":{\"user_id\":\"30\",\"channel_id\":\"20\",\"message_id\":\"10\",\"emoji\":{\"name\":\"👍\"}}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":19,\"t\":\"MESSAGE_REACTION_ADD\",\"d\":{\"user_id\":\"30\",\"channel_id\":\"20\",\"message_id\":\"10\",\"emoji\":{\"name\":\"👍\"}}}"));
    try std.testing.expectEqual(@as(usize, 1), state.reaction_add_count);

    client.onceMessageReactionRemove(Events.rawHandler(&state, State.onReactionRemove));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":20,\"t\":\"MESSAGE_REACTION_REMOVE\",\"d\":{\"user_id\":\"30\",\"channel_id\":\"20\",\"message_id\":\"10\",\"emoji\":{\"name\":\"👍\"}}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":21,\"t\":\"MESSAGE_REACTION_REMOVE\",\"d\":{\"user_id\":\"30\",\"channel_id\":\"20\",\"message_id\":\"10\",\"emoji\":{\"name\":\"👍\"}}}"));
    try std.testing.expectEqual(@as(usize, 1), state.reaction_remove_count);

    client.onceMessageReactionRemoveAll(Events.rawHandler(&state, State.onReactionRemoveAll));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":22,\"t\":\"MESSAGE_REACTION_REMOVE_ALL\",\"d\":{\"channel_id\":\"20\",\"message_id\":\"10\"}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":23,\"t\":\"MESSAGE_REACTION_REMOVE_ALL\",\"d\":{\"channel_id\":\"20\",\"message_id\":\"11\"}}"));
    try std.testing.expectEqual(@as(usize, 1), state.reaction_remove_all_count);

    client.onceMessageReactionRemoveEmoji(Events.rawHandler(&state, State.onReactionRemoveEmoji));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":24,\"t\":\"MESSAGE_REACTION_REMOVE_EMOJI\",\"d\":{\"channel_id\":\"20\",\"message_id\":\"10\",\"emoji\":{\"name\":\"👍\"}}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":25,\"t\":\"MESSAGE_REACTION_REMOVE_EMOJI\",\"d\":{\"channel_id\":\"20\",\"message_id\":\"11\",\"emoji\":{\"name\":\"👍\"}}}"));
    try std.testing.expectEqual(@as(usize, 1), state.reaction_remove_emoji_count);

    client.onceMessagePollVoteAdd(Events.rawHandler(&state, State.onPollVoteAdd));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":26,\"t\":\"MESSAGE_POLL_VOTE_ADD\",\"d\":{\"user_id\":\"30\",\"channel_id\":\"20\",\"message_id\":\"10\",\"answer_id\":1}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":27,\"t\":\"MESSAGE_POLL_VOTE_ADD\",\"d\":{\"user_id\":\"30\",\"channel_id\":\"20\",\"message_id\":\"10\",\"answer_id\":2}}"));
    try std.testing.expectEqual(@as(usize, 1), state.poll_vote_add_count);

    client.onceMessagePollVoteRemove(Events.rawHandler(&state, State.onPollVoteRemove));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":28,\"t\":\"MESSAGE_POLL_VOTE_REMOVE\",\"d\":{\"user_id\":\"30\",\"channel_id\":\"20\",\"message_id\":\"10\",\"answer_id\":1}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":29,\"t\":\"MESSAGE_POLL_VOTE_REMOVE\",\"d\":{\"user_id\":\"30\",\"channel_id\":\"20\",\"message_id\":\"10\",\"answer_id\":2}}"));
    try std.testing.expectEqual(@as(usize, 1), state.poll_vote_remove_count);

    client.onceInteractionCreate(Events.rawHandler(&state, State.onInteraction));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":30,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"3\",\"name\":\"ping\",\"type\":1}}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":31,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"4\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"ping\",\"type\":1}}}"));
    try std.testing.expectEqual(@as(usize, 1), state.interaction_count);

    client.onceApplicationCommand(Events.rawHandler(&state, State.onApplicationCommand));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":32,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"6\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"7\",\"name\":\"ping\",\"type\":1}}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":33,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"8\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"9\",\"name\":\"ping\",\"type\":1}}}"));
    try std.testing.expectEqual(@as(usize, 1), state.application_command_count);

    client.onceMessageComponent(Events.rawHandler(&state, State.onComponent));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":34,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"10\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"data\":{\"custom_id\":\"ok\",\"component_type\":2}}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":35,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"11\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"data\":{\"custom_id\":\"again\",\"component_type\":2}}}"));
    try std.testing.expectEqual(@as(usize, 1), state.component_count);

    client.onceApplicationCommandAutocomplete(Events.rawHandler(&state, State.onAutocomplete));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":36,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"12\",\"application_id\":\"2\",\"type\":4,\"token\":\"tok\",\"data\":{\"id\":\"13\",\"name\":\"ping\",\"type\":1}}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":37,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"14\",\"application_id\":\"2\",\"type\":4,\"token\":\"tok\",\"data\":{\"id\":\"15\",\"name\":\"ping\",\"type\":1}}}"));
    try std.testing.expectEqual(@as(usize, 1), state.autocomplete_count);

    client.onceModalSubmit(Events.rawHandler(&state, State.onModal));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":38,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"16\",\"application_id\":\"2\",\"type\":5,\"token\":\"tok\",\"data\":{\"custom_id\":\"modal\"}}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":39,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"17\",\"application_id\":\"2\",\"type\":5,\"token\":\"tok\",\"data\":{\"custom_id\":\"modal-again\"}}}"));
    try std.testing.expectEqual(@as(usize, 1), state.modal_count);

    client.onceApplicationCommandPermissionsUpdate(Events.rawHandler(&state, State.onPermissions));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":40,\"t\":\"APPLICATION_COMMAND_PERMISSIONS_UPDATE\",\"d\":{}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":41,\"t\":\"APPLICATION_COMMAND_PERMISSIONS_UPDATE\",\"d\":{}}"));
    try std.testing.expectEqual(@as(usize, 1), state.permissions_count);

    client.onUnknown(Events.rawHandler(&state, State.onUnknown));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":42,\"t\":\"NEW_GATEWAY_EVENT\",\"d\":{}}"));
    try std.testing.expectEqual(@as(?u64, 42), client.lastGatewaySequence());
    try std.testing.expectEqual(@as(?Gateway.EventName, .unknown), client.lastGatewayEvent());
    try std.testing.expectEqual(@as(usize, 1), state.unknown_count);

    client.onceGuildCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildDelete(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildMemberAdd(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildMemberUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildMemberRemove(Events.rawHandler(&state, State.onUnknown));
    client.onceChannelCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceChannelUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceChannelDelete(Events.rawHandler(&state, State.onUnknown));
    client.onceUserUpdate(Events.rawHandler(&state, State.onUnknown));
    client.oncePresenceUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceVoiceStateUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceTypingStart(Events.rawHandler(&state, State.onUnknown));
    client.onceWebhooksUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceInviteCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceInviteDelete(Events.rawHandler(&state, State.onUnknown));
    client.onceAutoModerationRuleCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceAutoModerationRuleUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceAutoModerationRuleDelete(Events.rawHandler(&state, State.onUnknown));
    client.onceAutoModerationActionExecution(Events.rawHandler(&state, State.onUnknown));
    client.onceEntitlementCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceEntitlementUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceEntitlementDelete(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildSoundboardSoundCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildSoundboardSoundUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildSoundboardSoundDelete(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildSoundboardSoundsUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceSoundboardSounds(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildRoleCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildRoleUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildRoleDelete(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildEmojisUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildStickersUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildScheduledEventCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildScheduledEventUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildScheduledEventDelete(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildScheduledEventUserAdd(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildScheduledEventUserRemove(Events.rawHandler(&state, State.onUnknown));
    client.onceStageInstanceCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceStageInstanceUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceStageInstanceDelete(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildAuditLogEntryCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildBanAdd(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildBanRemove(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildIntegrationsUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceIntegrationCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceIntegrationUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceIntegrationDelete(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildMembersChunk(Events.rawHandler(&state, State.onUnknown));
    client.onceVoiceChannelEffectSend(Events.rawHandler(&state, State.onUnknown));
    client.onceVoiceServerUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceChannelInfo(Events.rawHandler(&state, State.onUnknown));
    client.onceVoiceChannelStatusUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceVoiceChannelStartTimeUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceChannelPinsUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceThreadCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceThreadUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceThreadDelete(Events.rawHandler(&state, State.onUnknown));
    client.onceThreadListSync(Events.rawHandler(&state, State.onUnknown));
    client.onceThreadMemberUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceThreadMembersUpdate(Events.rawHandler(&state, State.onUnknown));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_DELETE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_MEMBER_ADD));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_MEMBER_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_MEMBER_REMOVE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.CHANNEL_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.CHANNEL_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.CHANNEL_DELETE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.USER_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.PRESENCE_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.VOICE_STATE_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.TYPING_START));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.WEBHOOKS_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.INVITE_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.INVITE_DELETE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.AUTO_MODERATION_RULE_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.AUTO_MODERATION_RULE_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.AUTO_MODERATION_RULE_DELETE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.AUTO_MODERATION_ACTION_EXECUTION));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.ENTITLEMENT_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.ENTITLEMENT_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.ENTITLEMENT_DELETE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_SOUNDBOARD_SOUND_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_SOUNDBOARD_SOUND_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_SOUNDBOARD_SOUND_DELETE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_SOUNDBOARD_SOUNDS_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.SOUNDBOARD_SOUNDS));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_ROLE_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_ROLE_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_ROLE_DELETE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_EMOJIS_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_STICKERS_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_SCHEDULED_EVENT_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_SCHEDULED_EVENT_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_SCHEDULED_EVENT_DELETE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_SCHEDULED_EVENT_USER_ADD));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_SCHEDULED_EVENT_USER_REMOVE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.STAGE_INSTANCE_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.STAGE_INSTANCE_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.STAGE_INSTANCE_DELETE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_AUDIT_LOG_ENTRY_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_BAN_ADD));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_BAN_REMOVE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_INTEGRATIONS_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.INTEGRATION_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.INTEGRATION_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.INTEGRATION_DELETE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_MEMBERS_CHUNK));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.VOICE_CHANNEL_EFFECT_SEND));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.VOICE_SERVER_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.CHANNEL_INFO));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.VOICE_CHANNEL_STATUS_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.VOICE_CHANNEL_START_TIME_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.CHANNEL_PINS_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.THREAD_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.THREAD_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.THREAD_DELETE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.THREAD_LIST_SYNC));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.THREAD_MEMBER_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.THREAD_MEMBERS_UPDATE));
    client.clearListeners();
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_DELETE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_MEMBER_ADD));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_MEMBER_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_MEMBER_REMOVE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.CHANNEL_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.CHANNEL_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.CHANNEL_DELETE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.USER_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.PRESENCE_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.VOICE_STATE_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.TYPING_START));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.WEBHOOKS_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.INVITE_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.INVITE_DELETE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.AUTO_MODERATION_RULE_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.AUTO_MODERATION_RULE_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.AUTO_MODERATION_RULE_DELETE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.AUTO_MODERATION_ACTION_EXECUTION));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.ENTITLEMENT_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.ENTITLEMENT_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.ENTITLEMENT_DELETE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_SOUNDBOARD_SOUND_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_SOUNDBOARD_SOUND_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_SOUNDBOARD_SOUND_DELETE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_SOUNDBOARD_SOUNDS_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.SOUNDBOARD_SOUNDS));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_ROLE_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_ROLE_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_ROLE_DELETE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_EMOJIS_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_STICKERS_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_SCHEDULED_EVENT_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_SCHEDULED_EVENT_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_SCHEDULED_EVENT_DELETE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_SCHEDULED_EVENT_USER_ADD));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_SCHEDULED_EVENT_USER_REMOVE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.STAGE_INSTANCE_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.STAGE_INSTANCE_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.STAGE_INSTANCE_DELETE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_AUDIT_LOG_ENTRY_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_BAN_ADD));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_BAN_REMOVE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_INTEGRATIONS_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.INTEGRATION_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.INTEGRATION_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.INTEGRATION_DELETE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_MEMBERS_CHUNK));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.VOICE_CHANNEL_EFFECT_SEND));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.VOICE_SERVER_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.CHANNEL_INFO));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.VOICE_CHANNEL_STATUS_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.VOICE_CHANNEL_START_TIME_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.CHANNEL_PINS_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.THREAD_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.THREAD_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.THREAD_DELETE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.THREAD_LIST_SYNC));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.THREAD_MEMBER_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.THREAD_MEMBERS_UPDATE));
}

test "client exposes current cached user from gateway ready" {
    var client = Client.init(std.testing.allocator, .{ .token = "Bot test" });
    defer client.deinit();

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":1,\"t\":\"READY\",\"d\":{\"session_id\":\"abc\",\"resume_gateway_url\":\"wss://gateway.discord.gg\",\"user\":{\"id\":\"40\",\"username\":\"zigbot\",\"global_name\":\"Zig Bot\",\"bot\":true}}}",
    );
    try std.testing.expectEqualStrings("zigbot", client.getCurrentCachedUser().?.username);
    try std.testing.expectEqual(@as(u64, 40), client.getCurrentCachedUser().?.id.value);
    try std.testing.expectEqualStrings("zigbot", client.currentUser().?.username);
    try std.testing.expectEqualStrings("zigbot", client.me().?.username);
    try std.testing.expectEqualStrings("zigbot", client.cachedUser(Snowflake.init(40)).?.username);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":2,\"t\":\"USER_UPDATE\",\"d\":{\"id\":\"40\",\"username\":\"renamed\",\"global_name\":\"Renamed Bot\",\"bot\":true}}",
    );
    try std.testing.expectEqualStrings("renamed", client.getCurrentCachedUser().?.username);
    try std.testing.expectEqualStrings("Renamed Bot", client.getCurrentCachedUser().?.global_name.?);
}

test "client exposes current cached application from gateway ready" {
    var client = Client.init(std.testing.allocator, .{ .token = "Bot test" });
    defer client.deinit();

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":1,\"t\":\"READY\",\"d\":{\"session_id\":\"abc\",\"resume_gateway_url\":\"wss://gateway.discord.gg\",\"application\":{\"id\":\"80\",\"name\":\"discord.zig\",\"description\":\"Fast Zig bot\",\"flags\":64}}}",
    );

    try std.testing.expectEqual(@as(u64, 80), client.getCurrentCachedApplication().?.id.value);
    try std.testing.expectEqualStrings("discord.zig", client.getCurrentCachedApplication().?.name);
    try std.testing.expectEqualStrings("discord.zig", client.currentApplication().?.name);
    try std.testing.expectEqualStrings("Fast Zig bot", client.getCurrentCachedApplication().?.description);
    try std.testing.expectEqual(@as(u32, 64), client.getCurrentCachedApplication().?.flags.?);
}

test "client exposes cache stats" {
    var client = Client.init(std.testing.allocator, .{ .token = "Bot test" });
    defer client.deinit();

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":1,\"t\":\"READY\",\"d\":{\"session_id\":\"abc\",\"user\":{\"id\":\"1\",\"username\":\"bot\"},\"application\":{\"id\":\"2\",\"name\":\"app\"}}}",
    );
    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":2,\"t\":\"MESSAGE_CREATE\",\"d\":{\"id\":\"10\",\"channel_id\":\"20\",\"content\":\"pong\",\"author\":{\"id\":\"1\",\"username\":\"bot\"}}}",
    );
    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":3,\"t\":\"GUILD_CREATE\",\"d\":{\"id\":\"40\",\"name\":\"Guild\",\"channels\":[{\"id\":\"50\",\"type\":0,\"name\":\"general\"}],\"threads\":[{\"id\":\"51\",\"type\":11,\"parent_id\":\"50\",\"name\":\"thread\"}]}}",
    );

    const stats = client.cacheStats();
    try std.testing.expect(stats.current_user);
    try std.testing.expect(stats.current_application);
    try std.testing.expectEqual(@as(usize, 1), stats.users);
    try std.testing.expectEqual(@as(usize, 1), stats.messages);
    try std.testing.expectEqual(@as(usize, 1), client.cachedUserCount());
    try std.testing.expectEqual(@as(usize, 1), client.cachedGuildCount());
    try std.testing.expectEqual(@as(usize, 2), client.cachedChannelCount());
    try std.testing.expectEqual(@as(usize, 0), client.cachedMemberCount());
    try std.testing.expectEqual(@as(usize, 0), client.cachedRoleCount());
    try std.testing.expectEqual(@as(usize, 0), client.cachedEmojiCount());
    try std.testing.expectEqual(@as(usize, 0), client.cachedStickerCount());
    try std.testing.expectEqual(@as(usize, 1), client.cachedMessageCount());

    const guild_stats = client.guildCacheStats(Snowflake.init(40));
    try std.testing.expectEqual(@as(usize, 1), guild_stats.channels);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.threads);

    const channel_stats = client.channelCacheStats(Snowflake.init(50));
    try std.testing.expectEqual(@as(usize, 1), channel_stats.threads);

    try std.testing.expect(client.hasCurrentCachedUser());
    try std.testing.expect(client.hasCurrentCachedApplication());
    try std.testing.expectEqual(@as(u64, 1), client.currentUserId().?.value);
    try std.testing.expectEqual(@as(u64, 2), client.currentApplicationId().?.value);
    try std.testing.expect(client.hasCachedUser(Snowflake.init(1)));
    try std.testing.expect(client.hasCachedGuild(Snowflake.init(40)));
    try std.testing.expect(client.hasCachedChannel(Snowflake.init(50)));
    try std.testing.expect(client.hasCachedChannel(Snowflake.init(51)));
    try std.testing.expect(client.hasCachedMessage(Snowflake.init(10)));
    try std.testing.expect(!client.hasCachedMessage(Snowflake.init(11)));
    try std.testing.expectEqualStrings("bot", client.cachedUser(Snowflake.init(1)).?.username);
    try std.testing.expectEqualStrings("Guild", client.cachedGuild(Snowflake.init(40)).?.name);
    try std.testing.expectEqualStrings("general", client.cachedChannel(Snowflake.init(50)).?.name.?);
    try std.testing.expectEqualStrings("pong", client.cachedMessage(Snowflake.init(10)).?.content);

    client.evictCachedMessage(Snowflake.init(10));
    try std.testing.expect(!client.hasCachedMessage(Snowflake.init(10)));

    client.evictCachedChannel(Snowflake.init(50));
    try std.testing.expect(!client.hasCachedChannel(Snowflake.init(50)));
    try std.testing.expect(!client.hasCachedChannel(Snowflake.init(51)));

    client.evictCachedUser(Snowflake.init(1));
    try std.testing.expect(!client.hasCachedUser(Snowflake.init(1)));
    try std.testing.expect(!client.hasCurrentCachedUser());
    try std.testing.expect(client.currentUserId() == null);

    client.evictCurrentCachedApplication();
    try std.testing.expect(!client.hasCurrentCachedApplication());
    try std.testing.expect(client.currentApplicationId() == null);

    client.clearCache();
    const cleared_stats = client.cacheStats();
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.users);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.guilds);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.channels);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.messages);
    try std.testing.expectEqual(@as(usize, 0), client.cachedUserCount());
    try std.testing.expectEqual(@as(usize, 0), client.cachedGuildCount());
    try std.testing.expectEqual(@as(usize, 0), client.cachedChannelCount());
    try std.testing.expectEqual(@as(usize, 0), client.cachedMemberCount());
    try std.testing.expectEqual(@as(usize, 0), client.cachedRoleCount());
    try std.testing.expectEqual(@as(usize, 0), client.cachedEmojiCount());
    try std.testing.expectEqual(@as(usize, 0), client.cachedStickerCount());
    try std.testing.expectEqual(@as(usize, 0), client.cachedMessageCount());
}

test "client event convenience registers handler" {
    const State = struct {
        called: bool = false,
        deleted: bool = false,
        reaction_added: bool = false,
        poll_vote_added: bool = false,
        poll_vote_removed: bool = false,
        user_updated: bool = false,
        presence_updated: bool = false,
        voice_state_updated: bool = false,
        typing_started: bool = false,
        webhooks_updated: bool = false,
        invite_created: bool = false,
        invite_deleted: bool = false,
        guild_ban_added: bool = false,
        guild_ban_removed: bool = false,
        guild_integrations_updated: bool = false,
        integration_created: bool = false,
        integration_updated: bool = false,
        integration_deleted: bool = false,
        channel_pins_updated: bool = false,
        thread_created: bool = false,
        guild_emojis_updated: bool = false,
        guild_stickers_updated: bool = false,
        guild_scheduled_event_created: bool = false,
        stage_instance_created: bool = false,
        application_command: bool = false,
        guild_created: bool = false,

        fn onMessage(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            _ = dispatch;
            self.called = true;
        }

        fn onMessageDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_DELETE, dispatch.event);
            self.deleted = true;
        }

        fn onMessageReactionAdd(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_REACTION_ADD, dispatch.event);
            self.reaction_added = true;
        }

        fn onMessagePollVoteAdd(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_POLL_VOTE_ADD, dispatch.event);
            self.poll_vote_added = true;
        }

        fn onMessagePollVoteRemove(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_POLL_VOTE_REMOVE, dispatch.event);
            self.poll_vote_removed = true;
        }

        fn onUserUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.USER_UPDATE, dispatch.event);
            self.user_updated = true;
        }

        fn onPresenceUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.PRESENCE_UPDATE, dispatch.event);
            self.presence_updated = true;
        }

        fn onVoiceStateUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.VOICE_STATE_UPDATE, dispatch.event);
            self.voice_state_updated = true;
        }

        fn onTypingStart(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.TYPING_START, dispatch.event);
            self.typing_started = true;
        }

        fn onWebhooksUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.WEBHOOKS_UPDATE, dispatch.event);
            self.webhooks_updated = true;
        }

        fn onInviteCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INVITE_CREATE, dispatch.event);
            self.invite_created = true;
        }

        fn onInviteDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INVITE_DELETE, dispatch.event);
            self.invite_deleted = true;
        }

        fn onGuildBanAdd(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_BAN_ADD, dispatch.event);
            self.guild_ban_added = true;
        }

        fn onGuildCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_CREATE, dispatch.event);
            self.guild_created = true;
        }

        fn onGuildBanRemove(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_BAN_REMOVE, dispatch.event);
            self.guild_ban_removed = true;
        }

        fn onGuildIntegrationsUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_INTEGRATIONS_UPDATE, dispatch.event);
            self.guild_integrations_updated = true;
        }

        fn onIntegrationCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTEGRATION_CREATE, dispatch.event);
            self.integration_created = true;
        }

        fn onIntegrationUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTEGRATION_UPDATE, dispatch.event);
            self.integration_updated = true;
        }

        fn onIntegrationDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTEGRATION_DELETE, dispatch.event);
            self.integration_deleted = true;
        }

        fn onChannelPinsUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.CHANNEL_PINS_UPDATE, dispatch.event);
            self.channel_pins_updated = true;
        }

        fn onThreadCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.THREAD_CREATE, dispatch.event);
            self.thread_created = true;
        }

        fn onGuildEmojisUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_EMOJIS_UPDATE, dispatch.event);
            self.guild_emojis_updated = true;
        }

        fn onGuildStickersUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_STICKERS_UPDATE, dispatch.event);
            self.guild_stickers_updated = true;
        }

        fn onGuildScheduledEventCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_SCHEDULED_EVENT_CREATE, dispatch.event);
            self.guild_scheduled_event_created = true;
        }

        fn onStageInstanceCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.STAGE_INSTANCE_CREATE, dispatch.event);
            self.stage_instance_created = true;
        }

        fn onApplicationCommand(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTERACTION_CREATE, dispatch.event);
            self.application_command = true;
        }
    };

    var memory = Rest.MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var state = State{};
    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
        .transport = memory.transport(),
    });
    defer client.deinit();

    client.onMessageCreate(Events.rawHandler(&state, State.onMessage));
    client.onMessageDelete(Events.rawHandler(&state, State.onMessageDelete));
    client.onMessageReactionAdd(Events.rawHandler(&state, State.onMessageReactionAdd));
    client.onMessagePollVoteAdd(Events.rawHandler(&state, State.onMessagePollVoteAdd));
    client.onMessagePollVoteRemove(Events.rawHandler(&state, State.onMessagePollVoteRemove));
    client.onUserUpdate(Events.rawHandler(&state, State.onUserUpdate));
    client.onPresenceUpdate(Events.rawHandler(&state, State.onPresenceUpdate));
    client.onVoiceStateUpdate(Events.rawHandler(&state, State.onVoiceStateUpdate));
    client.onTypingStart(Events.rawHandler(&state, State.onTypingStart));
    client.onWebhooksUpdate(Events.rawHandler(&state, State.onWebhooksUpdate));
    client.onInviteCreate(Events.rawHandler(&state, State.onInviteCreate));
    client.onInviteDelete(Events.rawHandler(&state, State.onInviteDelete));
    client.onGuildCreate(Events.rawHandler(&state, State.onGuildCreate));
    client.onGuildBanAdd(Events.rawHandler(&state, State.onGuildBanAdd));
    client.onGuildBanRemove(Events.rawHandler(&state, State.onGuildBanRemove));
    client.onGuildIntegrationsUpdate(Events.rawHandler(&state, State.onGuildIntegrationsUpdate));
    client.onIntegrationCreate(Events.rawHandler(&state, State.onIntegrationCreate));
    client.onIntegrationUpdate(Events.rawHandler(&state, State.onIntegrationUpdate));
    client.onIntegrationDelete(Events.rawHandler(&state, State.onIntegrationDelete));
    client.onChannelPinsUpdate(Events.rawHandler(&state, State.onChannelPinsUpdate));
    client.onThreadCreate(Events.rawHandler(&state, State.onThreadCreate));
    client.onGuildEmojisUpdate(Events.rawHandler(&state, State.onGuildEmojisUpdate));
    client.onGuildStickersUpdate(Events.rawHandler(&state, State.onGuildStickersUpdate));
    client.onGuildScheduledEventCreate(Events.rawHandler(&state, State.onGuildScheduledEventCreate));
    client.onStageInstanceCreate(Events.rawHandler(&state, State.onStageInstanceCreate));
    client.onApplicationCommand(Events.rawHandler(&state, State.onApplicationCommand));
    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":1,\"t\":\"MESSAGE_CREATE\",\"d\":{\"id\":\"10\",\"channel_id\":\"20\",\"guild_id\":\"40\",\"content\":\"pong\",\"author\":{\"id\":\"30\",\"username\":\"bot\"}}}",
    );

    try std.testing.expect(state.called);
    try std.testing.expect(client.getCachedMessage(Snowflake.init(10)) != null);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":2,\"t\":\"MESSAGE_CREATE\",\"d\":{\"id\":\"11\",\"channel_id\":\"21\",\"content\":\"dm\",\"author\":{\"id\":\"31\",\"username\":\"friend\"}}}",
    );

    const channel_messages = try client.listCachedChannelMessages(std.testing.allocator, Snowflake.init(20));
    defer std.testing.allocator.free(channel_messages);
    try std.testing.expectEqual(@as(usize, 1), channel_messages.len);
    try std.testing.expectEqualStrings("pong", channel_messages[0].content);
    const channel_messages_alias = try client.cachedChannelMessages(std.testing.allocator, Snowflake.init(20));
    defer std.testing.allocator.free(channel_messages_alias);
    try std.testing.expectEqual(@as(usize, 1), channel_messages_alias.len);

    const all_messages = try client.listCachedMessages(std.testing.allocator);
    defer std.testing.allocator.free(all_messages);
    try std.testing.expectEqual(@as(usize, 2), all_messages.len);
    try std.testing.expectEqualStrings("pong", all_messages[0].content);
    try std.testing.expectEqualStrings("dm", all_messages[1].content);
    const all_messages_alias = try client.cachedMessages(std.testing.allocator);
    defer std.testing.allocator.free(all_messages_alias);
    try std.testing.expectEqual(@as(usize, 2), all_messages_alias.len);

    const guild_messages = try client.listCachedGuildMessages(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(guild_messages);
    try std.testing.expectEqual(@as(usize, 1), guild_messages.len);
    try std.testing.expectEqualStrings("pong", guild_messages[0].content);
    const guild_messages_alias = try client.cachedGuildMessages(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(guild_messages_alias);
    try std.testing.expectEqual(@as(usize, 1), guild_messages_alias.len);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":3,\"t\":\"MESSAGE_DELETE\",\"d\":{\"id\":\"10\",\"channel_id\":\"20\"}}",
    );

    try std.testing.expect(state.deleted);
    try std.testing.expect(client.getCachedMessage(Snowflake.init(10)) == null);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":4,\"t\":\"MESSAGE_REACTION_ADD\",\"d\":{\"user_id\":\"30\",\"channel_id\":\"20\",\"message_id\":\"10\",\"emoji\":{\"name\":\"👍\"}}}",
    );

    try std.testing.expect(state.reaction_added);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":4,\"t\":\"MESSAGE_POLL_VOTE_ADD\",\"d\":{\"user_id\":\"30\",\"channel_id\":\"20\",\"message_id\":\"10\",\"answer_id\":1}}",
    );

    try std.testing.expect(state.poll_vote_added);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":5,\"t\":\"MESSAGE_POLL_VOTE_REMOVE\",\"d\":{\"user_id\":\"30\",\"channel_id\":\"20\",\"message_id\":\"10\",\"answer_id\":1}}",
    );

    try std.testing.expect(state.poll_vote_removed);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":6,\"t\":\"USER_UPDATE\",\"d\":{\"id\":\"30\",\"username\":\"renamed\",\"global_name\":\"Renamed Bot\"}}",
    );

    try std.testing.expect(state.user_updated);
    try std.testing.expectEqualStrings("renamed", client.getCachedUser(Snowflake.init(30)).?.username);
    const cached_users = try client.listCachedUsers(std.testing.allocator);
    defer std.testing.allocator.free(cached_users);
    try std.testing.expectEqual(@as(usize, 2), cached_users.len);
    const cached_users_alias = try client.cachedUsers(std.testing.allocator);
    defer std.testing.allocator.free(cached_users_alias);
    try std.testing.expectEqual(@as(usize, 2), cached_users_alias.len);
    var saw_renamed_user = false;
    var saw_friend_user = false;
    for (cached_users) |user| {
        if (user.id.value == 30 and std.mem.eql(u8, user.username, "renamed")) saw_renamed_user = true;
        if (user.id.value == 31 and std.mem.eql(u8, user.username, "friend")) saw_friend_user = true;
    }
    try std.testing.expect(saw_renamed_user);
    try std.testing.expect(saw_friend_user);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":7,\"t\":\"PRESENCE_UPDATE\",\"d\":{\"guild_id\":\"40\",\"user\":{\"id\":\"30\"},\"status\":\"dnd\",\"activities\":[{\"name\":\"debug\",\"type\":0}]}}",
    );

    try std.testing.expect(state.presence_updated);
    try std.testing.expectEqualStrings("dnd", client.getCachedPresence(Snowflake.init(40), Snowflake.init(30)).?.status);
    try std.testing.expectEqualStrings("dnd", client.cachedPresence(Snowflake.init(40), Snowflake.init(30)).?.status);
    const all_cached_presences = try client.listCachedPresences(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_presences);
    try std.testing.expectEqual(@as(usize, 1), all_cached_presences.len);
    try std.testing.expectEqualStrings("dnd", all_cached_presences[0].status);
    const all_cached_presences_alias = try client.cachedPresences(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_presences_alias);
    try std.testing.expectEqual(@as(usize, 1), all_cached_presences_alias.len);
    const cached_presences = try client.listCachedGuildPresences(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_presences);
    try std.testing.expectEqual(@as(usize, 1), cached_presences.len);
    try std.testing.expectEqualStrings("dnd", cached_presences[0].status);
    const cached_presences_alias = try client.cachedGuildPresences(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_presences_alias);
    try std.testing.expectEqual(@as(usize, 1), cached_presences_alias.len);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":8,\"t\":\"VOICE_STATE_UPDATE\",\"d\":{\"guild_id\":\"40\",\"channel_id\":\"80\",\"user_id\":\"30\",\"session_id\":\"voice-session\",\"deaf\":false,\"mute\":false,\"self_deaf\":false,\"self_mute\":true,\"self_video\":false,\"suppress\":false}}",
    );

    try std.testing.expect(state.voice_state_updated);
    try std.testing.expectEqual(@as(u64, 80), client.getCachedVoiceState(Snowflake.init(40), Snowflake.init(30)).?.channel_id.?.value);
    try std.testing.expectEqualStrings("voice-session", client.cachedVoiceState(Snowflake.init(40), Snowflake.init(30)).?.session_id);
    const all_cached_voice_states = try client.listCachedVoiceStates(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_voice_states);
    try std.testing.expectEqual(@as(usize, 1), all_cached_voice_states.len);
    try std.testing.expectEqualStrings("voice-session", all_cached_voice_states[0].session_id);
    const all_cached_voice_states_alias = try client.cachedVoiceStates(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_voice_states_alias);
    try std.testing.expectEqual(@as(usize, 1), all_cached_voice_states_alias.len);
    const cached_voice_states = try client.listCachedGuildVoiceStates(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_voice_states);
    try std.testing.expectEqual(@as(usize, 1), cached_voice_states.len);
    try std.testing.expectEqualStrings("voice-session", cached_voice_states[0].session_id);
    const cached_voice_states_alias = try client.cachedGuildVoiceStates(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_voice_states_alias);
    try std.testing.expectEqual(@as(usize, 1), cached_voice_states_alias.len);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":9,\"t\":\"CHANNEL_PINS_UPDATE\",\"d\":{\"guild_id\":\"40\",\"channel_id\":\"20\",\"last_pin_timestamp\":\"2026-06-02T10:00:00.000Z\"}}",
    );

    try std.testing.expect(state.channel_pins_updated);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":10,\"t\":\"TYPING_START\",\"d\":{\"channel_id\":\"20\",\"guild_id\":\"40\",\"user_id\":\"30\",\"timestamp\":1717350000}}",
    );

    try std.testing.expect(state.typing_started);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":11,\"t\":\"WEBHOOKS_UPDATE\",\"d\":{\"guild_id\":\"40\",\"channel_id\":\"20\"}}",
    );

    try std.testing.expect(state.webhooks_updated);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":12,\"t\":\"GUILD_CREATE\",\"d\":{\"id\":\"40\",\"name\":\"Guild\"}}",
    );

    try std.testing.expect(state.guild_created);
    try std.testing.expectEqualStrings("Guild", client.getCachedGuild(Snowflake.init(40)).?.name);
    const cached_guilds = try client.listCachedGuilds(std.testing.allocator);
    defer std.testing.allocator.free(cached_guilds);
    try std.testing.expectEqual(@as(usize, 1), cached_guilds.len);
    try std.testing.expectEqualStrings("Guild", cached_guilds[0].name);
    const cached_guilds_alias = try client.cachedGuilds(std.testing.allocator);
    defer std.testing.allocator.free(cached_guilds_alias);
    try std.testing.expectEqual(@as(usize, 1), cached_guilds_alias.len);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":13,\"t\":\"INVITE_CREATE\",\"d\":{\"code\":\"abc123\",\"guild_id\":\"40\",\"channel_id\":\"20\"}}",
    );

    try std.testing.expect(state.invite_created);
    try std.testing.expectEqualStrings("abc123", client.getCachedInvite("abc123").?.code);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":14,\"t\":\"INVITE_DELETE\",\"d\":{\"code\":\"abc123\",\"guild_id\":\"40\",\"channel_id\":\"20\"}}",
    );

    try std.testing.expect(state.invite_deleted);
    try std.testing.expect(client.getCachedInvite("abc123") == null);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":15,\"t\":\"GUILD_BAN_ADD\",\"d\":{\"guild_id\":\"40\",\"user\":{\"id\":\"60\",\"username\":\"spammer\"}}}",
    );

    try std.testing.expect(state.guild_ban_added);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":16,\"t\":\"GUILD_BAN_REMOVE\",\"d\":{\"guild_id\":\"40\",\"user\":{\"id\":\"60\",\"username\":\"spammer\"}}}",
    );

    try std.testing.expect(state.guild_ban_removed);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":17,\"t\":\"GUILD_INTEGRATIONS_UPDATE\",\"d\":{\"guild_id\":\"40\"}}",
    );

    try std.testing.expect(state.guild_integrations_updated);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":18,\"t\":\"INTEGRATION_CREATE\",\"d\":{\"id\":\"100\",\"guild_id\":\"40\",\"name\":\"Twitch\"}}",
    );

    try std.testing.expect(state.integration_created);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":19,\"t\":\"INTEGRATION_UPDATE\",\"d\":{\"id\":\"100\",\"guild_id\":\"40\",\"name\":\"Twitch\"}}",
    );

    try std.testing.expect(state.integration_updated);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":20,\"t\":\"INTEGRATION_DELETE\",\"d\":{\"id\":\"100\",\"guild_id\":\"40\",\"application_id\":null}}",
    );

    try std.testing.expect(state.integration_deleted);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":21,\"t\":\"GUILD_MEMBER_ADD\",\"d\":{\"guild_id\":\"40\",\"user\":{\"id\":\"50\",\"username\":\"helper\"},\"nick\":\"ziggy\",\"roles\":[\"60\"]}}",
    );

    const member = client.getCachedMember(Snowflake.init(40), Snowflake.init(50)).?;
    try std.testing.expectEqualStrings("ziggy", member.nick.?);
    try std.testing.expectEqual(@as(u64, 60), member.roles[0].value);
    const cached_members = try client.listCachedGuildMembers(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_members);
    try std.testing.expectEqual(@as(usize, 1), cached_members.len);
    try std.testing.expectEqualStrings("helper", cached_members[0].user.?.username);
    try std.testing.expectEqualStrings("helper", client.cachedMember(Snowflake.init(40), Snowflake.init(50)).?.user.?.username);
    const cached_members_alias = try client.cachedGuildMembers(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_members_alias);
    try std.testing.expectEqual(@as(usize, 1), cached_members_alias.len);
    const all_cached_members = try client.listCachedMembers(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_members);
    try std.testing.expectEqual(@as(usize, 1), all_cached_members.len);
    try std.testing.expectEqual(@as(u64, 40), all_cached_members[0].guild_id.value);
    try std.testing.expectEqualStrings("helper", all_cached_members[0].member.user.?.username);
    const all_cached_members_alias = try client.cachedMembers(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_members_alias);
    try std.testing.expectEqual(@as(usize, 1), all_cached_members_alias.len);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":22,\"t\":\"GUILD_ROLE_CREATE\",\"d\":{\"guild_id\":\"40\",\"role\":{\"id\":\"70\",\"name\":\"Helper\",\"permissions\":\"8\"}}}",
    );

    const role = client.getCachedRole(Snowflake.init(40), Snowflake.init(70)).?;
    try std.testing.expectEqualStrings("Helper", role.name);
    try std.testing.expectEqual(@as(u64, 8), role.permissions);
    try std.testing.expectEqualStrings("Helper", client.cachedRole(Snowflake.init(40), Snowflake.init(70)).?.name);
    const cached_roles = try client.listCachedGuildRoles(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_roles);
    try std.testing.expectEqual(@as(usize, 1), cached_roles.len);
    try std.testing.expectEqualStrings("Helper", cached_roles[0].name);
    const cached_roles_alias = try client.cachedGuildRoles(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_roles_alias);
    try std.testing.expectEqual(@as(usize, 1), cached_roles_alias.len);
    const all_cached_roles = try client.listCachedRoles(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_roles);
    try std.testing.expectEqual(@as(usize, 1), all_cached_roles.len);
    try std.testing.expectEqualStrings("Helper", all_cached_roles[0].name);
    const all_cached_roles_alias = try client.cachedRoles(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_roles_alias);
    try std.testing.expectEqual(@as(usize, 1), all_cached_roles_alias.len);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":23,\"t\":\"THREAD_CREATE\",\"d\":{\"id\":\"90\",\"type\":11,\"guild_id\":\"40\",\"parent_id\":\"80\",\"name\":\"debug\"}}",
    );

    try std.testing.expect(state.thread_created);
    try std.testing.expectEqual(Types.ChannelType.public_thread, client.getCachedChannel(Snowflake.init(90)).?.type);
    const all_cached_channels = try client.listCachedChannels(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_channels);
    try std.testing.expectEqual(@as(usize, 1), all_cached_channels.len);
    try std.testing.expectEqual(@as(u64, 90), all_cached_channels[0].id.value);
    const all_cached_channels_alias = try client.cachedChannels(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_channels_alias);
    try std.testing.expectEqual(@as(usize, 1), all_cached_channels_alias.len);
    const top_level_cached_channels = try client.listCachedTopLevelChannels(std.testing.allocator);
    defer std.testing.allocator.free(top_level_cached_channels);
    try std.testing.expectEqual(@as(usize, 0), top_level_cached_channels.len);
    const top_level_cached_channels_alias = try client.cachedTopLevelChannels(std.testing.allocator);
    defer std.testing.allocator.free(top_level_cached_channels_alias);
    try std.testing.expectEqual(@as(usize, 0), top_level_cached_channels_alias.len);
    const cached_channels = try client.listCachedGuildChannels(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_channels);
    try std.testing.expectEqual(@as(usize, 0), cached_channels.len);
    const cached_threads = try client.listCachedChannelThreads(std.testing.allocator, Snowflake.init(80));
    defer std.testing.allocator.free(cached_threads);
    try std.testing.expectEqual(@as(usize, 1), cached_threads.len);
    try std.testing.expectEqualStrings("debug", cached_threads[0].name.?);

    const cached_guild_threads = try client.listCachedGuildThreads(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_guild_threads);
    try std.testing.expectEqual(@as(usize, 1), cached_guild_threads.len);
    try std.testing.expectEqualStrings("debug", cached_guild_threads[0].name.?);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":24,\"t\":\"GUILD_EMOJIS_UPDATE\",\"d\":{\"guild_id\":\"40\",\"emojis\":[{\"id\":\"91\",\"name\":\"zig\",\"roles\":[\"70\"],\"user\":{\"id\":\"30\",\"username\":\"renamed\"},\"animated\":true}]}}",
    );

    try std.testing.expect(state.guild_emojis_updated);
    const emoji = client.getCachedEmoji(Snowflake.init(40), Snowflake.init(91)).?;
    try std.testing.expectEqualStrings("zig", emoji.name.?);
    try std.testing.expectEqual(@as(u64, 70), emoji.roles[0].value);
    try std.testing.expect(emoji.animated);
    try std.testing.expectEqualStrings("zig", client.cachedEmoji(Snowflake.init(40), Snowflake.init(91)).?.name.?);
    const cached_emojis = try client.listCachedGuildEmojis(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_emojis);
    try std.testing.expectEqual(@as(usize, 1), cached_emojis.len);
    try std.testing.expectEqualStrings("zig", cached_emojis[0].name.?);
    const all_cached_emojis = try client.listCachedEmojis(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_emojis);
    try std.testing.expectEqual(@as(usize, 1), all_cached_emojis.len);
    try std.testing.expectEqualStrings("zig", all_cached_emojis[0].name.?);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":25,\"t\":\"GUILD_STICKERS_UPDATE\",\"d\":{\"guild_id\":\"40\",\"stickers\":[{\"id\":\"92\",\"name\":\"ziggy\",\"description\":\"mascot\",\"tags\":\"zig\",\"type\":2,\"format_type\":1,\"guild_id\":\"40\",\"user\":{\"id\":\"30\",\"username\":\"renamed\"}}]}}",
    );

    try std.testing.expect(state.guild_stickers_updated);
    const sticker = client.getCachedSticker(Snowflake.init(40), Snowflake.init(92)).?;
    try std.testing.expectEqualStrings("ziggy", sticker.name);
    try std.testing.expectEqualStrings("mascot", sticker.description.?);
    try std.testing.expectEqual(Types.StickerFormatType.png, sticker.format_type);
    try std.testing.expectEqualStrings("ziggy", client.cachedSticker(Snowflake.init(40), Snowflake.init(92)).?.name);
    const cached_stickers = try client.listCachedGuildStickers(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_stickers);
    try std.testing.expectEqual(@as(usize, 1), cached_stickers.len);
    try std.testing.expectEqualStrings("ziggy", cached_stickers[0].name);
    const all_cached_stickers = try client.listCachedStickers(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_stickers);
    try std.testing.expectEqual(@as(usize, 1), all_cached_stickers.len);
    try std.testing.expectEqualStrings("ziggy", all_cached_stickers[0].name);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":26,\"t\":\"GUILD_SCHEDULED_EVENT_CREATE\",\"d\":{\"id\":\"93\",\"guild_id\":\"40\",\"channel_id\":\"80\",\"name\":\"Launch\",\"description\":\"Ship\",\"scheduled_start_time\":\"2026-06-02T10:00:00.000Z\",\"privacy_level\":2,\"status\":1,\"entity_type\":2,\"user_count\":3}}",
    );

    try std.testing.expect(state.guild_scheduled_event_created);
    const scheduled_event = client.getCachedScheduledEvent(Snowflake.init(40), Snowflake.init(93)).?;
    try std.testing.expectEqualStrings("Launch", scheduled_event.name);
    try std.testing.expectEqualStrings("Ship", scheduled_event.description.?);
    try std.testing.expectEqual(Types.GuildScheduledEventStatus.scheduled, scheduled_event.status);
    try std.testing.expectEqualStrings("Launch", client.cachedScheduledEvent(Snowflake.init(40), Snowflake.init(93)).?.name);
    const cached_scheduled_events = try client.listCachedGuildScheduledEvents(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_scheduled_events);
    try std.testing.expectEqual(@as(usize, 1), cached_scheduled_events.len);
    try std.testing.expectEqualStrings("Launch", cached_scheduled_events[0].name);
    const all_cached_scheduled_events = try client.listCachedScheduledEvents(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_scheduled_events);
    try std.testing.expectEqual(@as(usize, 1), all_cached_scheduled_events.len);
    try std.testing.expectEqualStrings("Launch", all_cached_scheduled_events[0].name);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":27,\"t\":\"STAGE_INSTANCE_CREATE\",\"d\":{\"id\":\"94\",\"guild_id\":\"40\",\"channel_id\":\"80\",\"topic\":\"Live Q&A\",\"privacy_level\":2,\"discoverable_disabled\":false,\"guild_scheduled_event_id\":\"93\"}}",
    );

    try std.testing.expect(state.stage_instance_created);
    const stage_instance = client.getCachedStageInstance(Snowflake.init(40), Snowflake.init(94)).?;
    try std.testing.expectEqualStrings("Live Q&A", stage_instance.topic);
    try std.testing.expectEqual(@as(u64, 93), stage_instance.guild_scheduled_event_id.?.value);
    try std.testing.expectEqualStrings("Live Q&A", client.cachedStageInstance(Snowflake.init(40), Snowflake.init(94)).?.topic);
    const cached_stage_instances = try client.listCachedGuildStageInstances(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_stage_instances);
    try std.testing.expectEqual(@as(usize, 1), cached_stage_instances.len);
    try std.testing.expectEqualStrings("Live Q&A", cached_stage_instances[0].topic);
    const all_cached_stage_instances = try client.listCachedStageInstances(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_stage_instances);
    try std.testing.expectEqual(@as(usize, 1), all_cached_stage_instances.len);
    try std.testing.expectEqualStrings("Live Q&A", all_cached_stage_instances[0].topic);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":28,\"t\":\"INVITE_CREATE\",\"d\":{\"code\":\"xyz789\",\"guild_id\":\"40\",\"channel_id\":\"80\"}}",
    );

    const all_cached_invites = try client.listCachedInvites(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_invites);
    try std.testing.expectEqual(@as(usize, 1), all_cached_invites.len);
    try std.testing.expectEqualStrings("xyz789", all_cached_invites[0].code);
    try std.testing.expectEqualStrings("xyz789", client.cachedInvite("xyz789").?.code);
    const cached_guild_invites = try client.listCachedGuildInvites(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_guild_invites);
    try std.testing.expectEqual(@as(usize, 1), cached_guild_invites.len);
    try std.testing.expectEqualStrings("xyz789", cached_guild_invites[0].code);
    const cached_channel_invites = try client.listCachedChannelInvites(std.testing.allocator, Snowflake.init(80));
    defer std.testing.allocator.free(cached_channel_invites);
    try std.testing.expectEqual(@as(usize, 1), cached_channel_invites.len);
    try std.testing.expectEqualStrings("xyz789", cached_channel_invites[0].code);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":29,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"3\",\"name\":\"ping\",\"type\":1}}}",
    );

    try std.testing.expect(state.application_command);
}

test "client initHttp owns live REST transport" {
    var client = try Client.initHttp(std.testing.allocator, .{
        .token = "Bot test",
    });
    defer client.destroy();

    try std.testing.expect(client.owned_http_transport != null);
}

test "gateway runner identifies after hello and schedules heartbeat" {
    var gateway_memory = GatewaySession.MemoryTransport.init(std.testing.allocator);
    defer gateway_memory.deinit();
    try gateway_memory.pushIncoming("{\"op\":10,\"d\":{\"heartbeat_interval\":50}}");

    const startup_activities = [_]Gateway.Activity{Gateway.Activity.init("discord.zig", .watching)};
    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
        .presence = Gateway.Presence.init(.idle).withActivities(&startup_activities),
    });
    defer client.deinit();

    var runner = client.createGatewayRunner(gateway_memory.transport());
    defer runner.deinit();

    try std.testing.expectEqual(GatewayStep.identified, try runner.step(100));
    try std.testing.expectEqual(@as(usize, 1), gateway_memory.sent.items.len);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[0], "\"op\":2") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[0], "\"presence\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[0], "\"status\":\"idle\"") != null);
    try std.testing.expectEqual(@as(?u64, 150), runner.next_heartbeat_ms);
    try std.testing.expectEqual(@as(?u64, 150), runner.nextHeartbeatMs());
    try std.testing.expectEqual(@as(?u64, 50), runner.heartbeatIntervalMs());
    try std.testing.expect(!runner.canResume());

    try std.testing.expectEqual(GatewayStep.heartbeat_sent, try runner.step(150));
    try std.testing.expect(runner.awaitingHeartbeatAck());
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[1], "\"op\":1") != null);
    try std.testing.expectEqual(@as(?u64, null), client.gatewayPingMs());

    try gateway_memory.pushIncoming("{\"op\":11,\"d\":null}");
    try std.testing.expectEqual(GatewayStep.heartbeat_ack, try runner.step(175));
    try std.testing.expect(!runner.awaitingHeartbeatAck());
    try std.testing.expectEqual(@as(?u64, 25), client.gatewayPingMs());
}

test "client updates presence through gateway session" {
    var gateway_memory = GatewaySession.MemoryTransport.init(std.testing.allocator);
    defer gateway_memory.deinit();

    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
    });
    defer client.deinit();

    var session = client.createGatewaySession(gateway_memory.transport());
    defer session.deinit();

    const activities = [_]Gateway.Activity{Gateway.Activity.init("discord.zig", .playing)};
    try client.updatePresence(
        &session,
        Gateway.Presence.init(.online).withActivities(&activities),
    );

    try std.testing.expectEqual(@as(usize, 1), gateway_memory.sent.items.len);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[0], "\"op\":3") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[0], "\"status\":\"online\"") != null);

    try client.setPresence(&session, Gateway.Presence.init(.idle));

    try std.testing.expectEqual(@as(usize, 2), gateway_memory.sent.items.len);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[1], "\"op\":3") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[1], "\"status\":\"idle\"") != null);

    try client.setActivity(
        &session,
        "Zig bots",
        SetActivityOptions.init(.watching)
            .withStatus(.dnd)
            .withSince(123)
            .afkState(true),
    );

    try std.testing.expectEqual(@as(usize, 3), gateway_memory.sent.items.len);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[2], "\"op\":3") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[2], "\"name\":\"Zig bots\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[2], "\"type\":3") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[2], "\"since\":123") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[2], "\"status\":\"dnd\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[2], "\"afk\":true") != null);

    try client.requestGuildMembers(
        &session,
        Gateway.RequestGuildMembers.init(Snowflake.init(10))
            .withQuery("zig")
            .withLimit(10)
            .withNonce("members-1"),
    );

    try std.testing.expectEqual(@as(usize, 4), gateway_memory.sent.items.len);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[3], "\"op\":8") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[3], "\"query\":\"zig\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[3], "\"nonce\":\"members-1\"") != null);

    try client.requestChannelInfo(
        &session,
        Gateway.RequestChannelInfo.init(Snowflake.init(10), &.{ .status, .voice_start_time }),
    );

    try std.testing.expectEqual(@as(usize, 5), gateway_memory.sent.items.len);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[4], "\"op\":43") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[4], "\"fields\":[\"status\",\"voice_start_time\"]") != null);

    try client.updateVoiceState(
        &session,
        Gateway.VoiceStateUpdate.init(Snowflake.init(10))
            .withChannel(Snowflake.init(20))
            .deafState(true),
    );

    try std.testing.expectEqual(@as(usize, 6), gateway_memory.sent.items.len);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[5], "\"op\":4") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[5], "\"self_deaf\":true") != null);

    try client.joinVoiceChannel(
        &session,
        Snowflake.init(10),
        Snowflake.init(30),
        true,
        false,
    );
    try std.testing.expectEqual(@as(usize, 7), gateway_memory.sent.items.len);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[6], "\"channel_id\":\"30\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[6], "\"self_mute\":true") != null);

    try client.leaveVoiceChannel(&session, Snowflake.init(10));
    try std.testing.expectEqual(@as(usize, 8), gateway_memory.sent.items.len);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[7], "\"channel_id\":null") != null);
}

test "gateway runner dispatches through cache and event handlers" {
    const State = struct {
        called: bool = false,

        fn onMessage(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            _ = dispatch;
            self.called = true;
        }
    };

    var gateway_memory = GatewaySession.MemoryTransport.init(std.testing.allocator);
    defer gateway_memory.deinit();
    try gateway_memory.pushIncoming(
        "{\"op\":0,\"s\":0,\"t\":\"READY\",\"d\":{\"session_id\":\"abc\",\"resume_gateway_url\":\"wss://gateway.discord.gg\"}}",
    );
    try gateway_memory.pushIncoming(
        "{\"op\":0,\"s\":1,\"t\":\"MESSAGE_CREATE\",\"d\":{\"id\":\"10\",\"channel_id\":\"20\",\"content\":\"pong\",\"author\":{\"id\":\"30\",\"username\":\"bot\"}}}",
    );

    var state = State{};
    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
    });
    defer client.deinit();
    client.onMessageCreate(Events.rawHandler(&state, State.onMessage));

    var runner = client.createGatewayRunner(gateway_memory.transport());
    defer runner.deinit();

    try std.testing.expectEqual(GatewayStep.dispatched, try runner.step(0));
    try std.testing.expect(client.isReady());
    try std.testing.expectEqual(@as(?u64, 0), client.readyTimestampMs());
    try std.testing.expectEqual(@as(?u64, 25), client.uptimeMs(25));
    try std.testing.expectEqual(@as(?u64, 0), client.lastGatewaySequence());
    try std.testing.expectEqual(@as(?Gateway.EventName, .READY), client.lastGatewayEvent());
    try std.testing.expect(runner.canResume());
    try std.testing.expectEqualStrings("abc", runner.sessionId().?);
    try std.testing.expectEqual(@as(?u64, 0), runner.sequence());

    try std.testing.expectEqual(GatewayStep.dispatched, try runner.step(0));
    try std.testing.expect(state.called);
    try std.testing.expect(client.isReady());
    try std.testing.expectEqual(@as(?u64, 0), client.readyTimestampMs());
    try std.testing.expectEqual(@as(?u64, 1), client.lastGatewaySequence());
    try std.testing.expectEqual(@as(?Gateway.EventName, .MESSAGE_CREATE), client.lastGatewayEvent());
    try std.testing.expect(client.getCachedMessage(Snowflake.init(10)) != null);
}

test "gateway runner reports reconnect and invalid session signals" {
    var gateway_memory = GatewaySession.MemoryTransport.init(std.testing.allocator);
    defer gateway_memory.deinit();
    try gateway_memory.pushIncoming("{\"op\":7,\"d\":null}");
    try gateway_memory.pushIncoming("{\"op\":9,\"d\":false}");

    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
    });
    defer client.deinit();

    var runner = client.createGatewayRunner(gateway_memory.transport());
    defer runner.deinit();

    client.ready = true;
    try std.testing.expectEqual(GatewayStep.reconnect, try runner.step(0));
    try std.testing.expect(!client.isReady());
    try std.testing.expectEqual(@as(?u64, 1000), runner.reconnect_after_ms);
    try std.testing.expect(runner.isReconnectPending());
    try std.testing.expectEqual(@as(?u64, 1000), runner.reconnectAfterMs());
    try std.testing.expectEqual(GatewayStartMode.resume_session, runner.pendingStartMode());
    try std.testing.expect(!runner.reconnectReady(999));
    client.ready = true;
    try std.testing.expectEqual(GatewayStep.invalid_session, try runner.step(1000));
    try std.testing.expect(!client.isReady());
    try std.testing.expectEqual(GatewayStartMode.identify, runner.pending_start);
    try std.testing.expectEqual(GatewayStartMode.identify, runner.pendingStartMode());
    try std.testing.expectEqual(@as(?u64, 3000), runner.reconnect_after_ms);
}

test "gateway runner resumes after reconnect when session is resumable" {
    var gateway_memory = GatewaySession.MemoryTransport.init(std.testing.allocator);
    defer gateway_memory.deinit();
    try gateway_memory.pushIncoming("{\"op\":0,\"s\":42,\"t\":\"READY\",\"d\":{\"session_id\":\"session-a\"}}");
    try gateway_memory.pushIncoming("{\"op\":7,\"d\":null}");
    try gateway_memory.pushIncoming("{\"op\":10,\"d\":{\"heartbeat_interval\":50}}");

    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
    });
    defer client.deinit();

    var runner = client.createGatewayRunner(gateway_memory.transport());
    defer runner.deinit();

    try std.testing.expectEqual(GatewayStep.dispatched, try runner.step(0));
    try std.testing.expect(runner.session.canResume());
    try std.testing.expect(client.isReady());
    try std.testing.expectEqual(GatewayStep.reconnect, try runner.step(0));
    try std.testing.expect(!client.isReady());
    try std.testing.expectEqual(GatewayStartMode.resume_session, runner.pending_start);
    try std.testing.expectEqual(GatewayStep.idle, try runner.step(999));

    try std.testing.expectEqual(GatewayStep.resumed, try runner.step(1000));
    try std.testing.expect(!client.isReady());
    try std.testing.expectEqual(@as(usize, 1), gateway_memory.sent.items.len);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[0], "\"op\":6") != null);
    try std.testing.expectEqual(@as(?u64, 1050), runner.next_heartbeat_ms);
    try std.testing.expectEqual(@as(?u64, null), runner.reconnect_after_ms);
}

test "gateway runner keeps resumable invalid session state" {
    var gateway_memory = GatewaySession.MemoryTransport.init(std.testing.allocator);
    defer gateway_memory.deinit();
    try gateway_memory.pushIncoming("{\"op\":0,\"s\":7,\"t\":\"READY\",\"d\":{\"session_id\":\"session-b\"}}");
    try gateway_memory.pushIncoming("{\"op\":9,\"d\":true}");

    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
    });
    defer client.deinit();

    var runner = client.createGatewayRunner(gateway_memory.transport());
    defer runner.deinit();

    try std.testing.expectEqual(GatewayStep.dispatched, try runner.step(0));
    try std.testing.expectEqual(GatewayStep.invalid_session, try runner.step(0));
    try std.testing.expect(runner.session.canResume());
    try std.testing.expectEqual(GatewayStartMode.resume_session, runner.pending_start);
}
