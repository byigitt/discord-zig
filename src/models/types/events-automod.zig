const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Json = @import("../../core/json.zig");
const Interactions = @import("../../interactions/mod.zig");
const Permissions = @import("../../core/permissions.zig");

const Root = @import("../types.zig");
const User = Root.User;
const Channel = Root.Channel;
const writeStringArray = Root.writeStringArray;
const writeAutoModerationKeywordPresetArray = Root.writeAutoModerationKeywordPresetArray;
const writeAutoModerationRuleFields = Root.writeAutoModerationRuleFields;
const writeOptionalStringField = Root.writeOptionalStringField;
const writeOptionalIntegerField = Root.writeOptionalIntegerField;
const writeOptionalBoolField = Root.writeOptionalBoolField;
const writeSnowflakeQueryParam = Root.writeSnowflakeQueryParam;
const writeOptionalBoolQueryParam = Root.writeOptionalBoolQueryParam;
const writeQuerySeparator = Root.writeQuerySeparator;
const writeComma = Root.writeComma;

pub const ListSkuSubscriptions = struct {
    before: ?Snowflake = null,
    after: ?Snowflake = null,
    limit: ?u8 = null,
    user_id: ?Snowflake = null,

    pub fn init() ListSkuSubscriptions {
        return .{};
    }

    pub fn beforeSubscription(self: ListSkuSubscriptions, subscription_id: Snowflake) ListSkuSubscriptions {
        var options = self;
        options.before = subscription_id;
        return options;
    }

    pub fn afterSubscription(self: ListSkuSubscriptions, subscription_id: Snowflake) ListSkuSubscriptions {
        var options = self;
        options.after = subscription_id;
        return options;
    }

    pub fn withLimit(self: ListSkuSubscriptions, limit: u8) ListSkuSubscriptions {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn forUser(self: ListSkuSubscriptions, user_id: Snowflake) ListSkuSubscriptions {
        var options = self;
        options.user_id = user_id;
        return options;
    }

    pub fn hasQuery(self: ListSkuSubscriptions) bool {
        return self.before != null or self.after != null or self.limit != null or self.user_id != null;
    }

    pub fn writeQuery(self: ListSkuSubscriptions, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.before) |before| try writeSnowflakeQueryParam(writer, &needs_ampersand, "before", before);
        if (self.after) |after| try writeSnowflakeQueryParam(writer, &needs_ampersand, "after", after);
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
        if (self.user_id) |user_id| try writeSnowflakeQueryParam(writer, &needs_ampersand, "user_id", user_id);
    }
};

pub const ApplicationInstallParams = struct {
    scopes: []const []const u8 = &.{},
    permissions: []const u8 = "0",

    pub fn writeJson(self: ApplicationInstallParams, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"scopes\":");
        try writeStringArray(self.scopes, writer);

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"permissions\":");
        try Json.writeString(self.permissions, writer);

        try writer.writeByte('}');
    }
};

pub const GuildScheduledEventPrivacyLevel = enum(u8) {
    guild_only = 2,
};

pub const GuildScheduledEventEntityType = enum(u8) {
    stage_instance = 1,
    voice = 2,
    external = 3,
};

pub const GuildScheduledEventStatus = enum(u8) {
    scheduled = 1,
    active = 2,
    completed = 3,
    canceled = 4,
};

pub const StageInstancePrivacyLevel = enum(u8) {
    public = 1,
    guild_only = 2,
};

pub const GuildScheduledEvent = struct {
    id: Snowflake,
    guild_id: Snowflake,
    channel_id: ?Snowflake = null,
    creator_id: ?Snowflake = null,
    name: []const u8,
    description: ?[]const u8 = null,
    scheduled_start_time: []const u8,
    scheduled_end_time: ?[]const u8 = null,
    privacy_level: GuildScheduledEventPrivacyLevel = .guild_only,
    status: GuildScheduledEventStatus,
    entity_type: GuildScheduledEventEntityType,
    entity_id: ?Snowflake = null,
    user_count: ?u32 = null,
};

pub const StageInstance = struct {
    id: Snowflake,
    guild_id: Snowflake,
    channel_id: Snowflake,
    topic: []const u8,
    privacy_level: StageInstancePrivacyLevel = .guild_only,
    discoverable_disabled: bool = false,
    guild_scheduled_event_id: ?Snowflake = null,
};

pub const VoiceState = struct {
    guild_id: ?Snowflake = null,
    channel_id: ?Snowflake = null,
    user_id: Snowflake,
    member: ?GuildMember = null,
    session_id: []const u8,
    deaf: bool = false,
    mute: bool = false,
    self_deaf: bool = false,
    self_mute: bool = false,
    self_stream: ?bool = null,
    self_video: bool = false,
    suppress: bool = false,
    request_to_speak_timestamp: ?[]const u8 = null,
};

pub const VoiceRegion = struct {
    id: []const u8,
    name: []const u8,
    optimal: bool = false,
    deprecated: bool = false,
    custom: bool = false,
};

pub const GuildScheduledEventEntityMetadata = struct {
    location: ?[]const u8 = null,

    pub fn withLocation(value: []const u8) GuildScheduledEventEntityMetadata {
        return .{ .location = value };
    }

    pub fn writeJson(self: GuildScheduledEventEntityMetadata, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        try writeOptionalStringField(writer, &needs_comma, "location", self.location);
        try writer.writeByte('}');
    }
};

pub const GuildScheduledEventUser = struct {
    guild_scheduled_event_id: Snowflake,
    user: User,
    member: ?GuildMember = null,
};

pub const ListGuildScheduledEvents = struct {
    with_user_count: ?bool = null,

    pub fn init() ListGuildScheduledEvents {
        return .{};
    }

    pub fn withUserCount(self: ListGuildScheduledEvents, with_user_count: bool) ListGuildScheduledEvents {
        var options = self;
        options.with_user_count = with_user_count;
        return options;
    }

    pub fn hasQuery(self: ListGuildScheduledEvents) bool {
        return self.with_user_count != null;
    }

    pub fn writeQuery(self: ListGuildScheduledEvents, writer: anytype) !void {
        var needs_ampersand = false;
        try writeOptionalBoolQueryParam(writer, &needs_ampersand, "with_user_count", self.with_user_count);
    }
};

pub const GetGuildScheduledEvent = struct {
    with_user_count: ?bool = null,

    pub fn init() GetGuildScheduledEvent {
        return .{};
    }

    pub fn withUserCount(self: GetGuildScheduledEvent, with_user_count: bool) GetGuildScheduledEvent {
        var options = self;
        options.with_user_count = with_user_count;
        return options;
    }

    pub fn hasQuery(self: GetGuildScheduledEvent) bool {
        return self.with_user_count != null;
    }

    pub fn writeQuery(self: GetGuildScheduledEvent, writer: anytype) !void {
        var needs_ampersand = false;
        try writeOptionalBoolQueryParam(writer, &needs_ampersand, "with_user_count", self.with_user_count);
    }
};

pub const ListGuildScheduledEventUsers = struct {
    limit: ?u8 = null,
    with_member: ?bool = null,
    before: ?Snowflake = null,
    after: ?Snowflake = null,

    pub fn init() ListGuildScheduledEventUsers {
        return .{};
    }

    pub fn withLimit(self: ListGuildScheduledEventUsers, limit: u8) ListGuildScheduledEventUsers {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn withMember(self: ListGuildScheduledEventUsers, with_member: bool) ListGuildScheduledEventUsers {
        var options = self;
        options.with_member = with_member;
        return options;
    }

    pub fn beforeUser(self: ListGuildScheduledEventUsers, user_id: Snowflake) ListGuildScheduledEventUsers {
        var options = self;
        options.before = user_id;
        return options;
    }

    pub fn afterUser(self: ListGuildScheduledEventUsers, user_id: Snowflake) ListGuildScheduledEventUsers {
        var options = self;
        options.after = user_id;
        return options;
    }

    pub fn hasQuery(self: ListGuildScheduledEventUsers) bool {
        return self.limit != null or
            self.with_member != null or
            self.before != null or
            self.after != null;
    }

    pub fn writeQuery(self: ListGuildScheduledEventUsers, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
        try writeOptionalBoolQueryParam(writer, &needs_ampersand, "with_member", self.with_member);
        if (self.before) |before| try writeSnowflakeQueryParam(writer, &needs_ampersand, "before", before);
        if (self.after) |after| try writeSnowflakeQueryParam(writer, &needs_ampersand, "after", after);
    }
};

pub const UserGuild = struct {
    id: Snowflake,
    name: []const u8,
    icon: ?[]const u8 = null,
    owner: bool = false,
    permissions: Permissions.Bit = 0,
    features: []const []const u8 = &.{},
    approximate_member_count: ?u32 = null,
    approximate_presence_count: ?u32 = null,
};

pub const AuditLog = struct {
    application_commands: []const Interactions.ApplicationCommand = &.{},
    audit_log_entries: []const AuditLogEntry = &.{},
    auto_moderation_rules: []const u8 = &.{},
    guild_scheduled_events: []const u8 = &.{},
    integrations: []const u8 = &.{},
    threads: []const Channel = &.{},
    users: []const User = &.{},
    webhooks: []const u8 = &.{},
};

pub const AuditLogEntry = struct {
    id: Snowflake,
    target_id: ?[]const u8 = null,
    user_id: ?Snowflake = null,
    action_type: u16,
    reason: ?[]const u8 = null,
};

pub const GuildMember = struct {
    user: ?User = null,
    nick: ?[]const u8 = null,
    avatar: ?[]const u8 = null,
    roles: []const Snowflake = &.{},
    joined_at: ?[]const u8 = null,
    premium_since: ?[]const u8 = null,
    deaf: bool = false,
    mute: bool = false,
    pending: bool = false,
    communication_disabled_until: ?[]const u8 = null,
    flags: u64 = 0,
    permissions: Permissions.Bit = 0,

    pub fn displayName(self: GuildMember) ?[]const u8 {
        if (self.nick) |nick| return nick;
        const member_user = self.user orelse return null;
        return member_user.displayName();
    }
};

pub const CachedGuildMember = struct {
    guild_id: Snowflake,
    member: GuildMember,
};

pub const Ban = struct {
    reason: ?[]const u8 = null,
    user: User,
};

pub const AutoModerationRuleEventType = enum(u8) {
    message_send = 1,
    member_update = 2,
};

pub const AutoModerationTriggerType = enum(u8) {
    keyword = 1,
    spam = 3,
    keyword_preset = 4,
    mention_spam = 5,
    member_profile = 6,
};

pub const AutoModerationKeywordPresetType = enum(u8) {
    profanity = 1,
    sexual_content = 2,
    slurs = 3,
};

pub const AutoModerationActionType = enum(u8) {
    block_message = 1,
    send_alert_message = 2,
    timeout = 3,
    block_member_interaction = 4,
};

pub const AutoModerationRule = struct {
    id: Snowflake,
    guild_id: Snowflake,
    name: []const u8,
    creator_id: Snowflake,
    event_type: AutoModerationRuleEventType,
    trigger_type: AutoModerationTriggerType,
    enabled: bool,
};

pub const AutoModerationTriggerMetadata = struct {
    keyword_filter: []const []const u8 = &.{},
    regex_patterns: []const []const u8 = &.{},
    presets: []const AutoModerationKeywordPresetType = &.{},
    allow_list: []const []const u8 = &.{},
    mention_total_limit: ?u8 = null,
    mention_raid_protection_enabled: ?bool = null,

    pub fn init() AutoModerationTriggerMetadata {
        return .{};
    }

    pub fn withKeywordFilter(self: AutoModerationTriggerMetadata, keyword_filter: []const []const u8) AutoModerationTriggerMetadata {
        var metadata = self;
        metadata.keyword_filter = keyword_filter;
        return metadata;
    }

    pub fn withRegexPatterns(self: AutoModerationTriggerMetadata, regex_patterns: []const []const u8) AutoModerationTriggerMetadata {
        var metadata = self;
        metadata.regex_patterns = regex_patterns;
        return metadata;
    }

    pub fn withPresets(self: AutoModerationTriggerMetadata, presets: []const AutoModerationKeywordPresetType) AutoModerationTriggerMetadata {
        var metadata = self;
        metadata.presets = presets;
        return metadata;
    }

    pub fn withAllowList(self: AutoModerationTriggerMetadata, allow_list: []const []const u8) AutoModerationTriggerMetadata {
        var metadata = self;
        metadata.allow_list = allow_list;
        return metadata;
    }

    pub fn withMentionLimit(self: AutoModerationTriggerMetadata, mention_total_limit: u8) AutoModerationTriggerMetadata {
        var metadata = self;
        metadata.mention_total_limit = mention_total_limit;
        return metadata;
    }

    pub fn mentionRaidProtection(self: AutoModerationTriggerMetadata, mention_raid_protection_enabled: bool) AutoModerationTriggerMetadata {
        var metadata = self;
        metadata.mention_raid_protection_enabled = mention_raid_protection_enabled;
        return metadata;
    }

    pub fn writeJson(self: AutoModerationTriggerMetadata, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        if (self.keyword_filter.len != 0) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"keyword_filter\":");
            try writeStringArray(self.keyword_filter, writer);
        }
        if (self.regex_patterns.len != 0) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"regex_patterns\":");
            try writeStringArray(self.regex_patterns, writer);
        }
        if (self.presets.len != 0) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"presets\":");
            try writeAutoModerationKeywordPresetArray(self.presets, writer);
        }
        if (self.allow_list.len != 0) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"allow_list\":");
            try writeStringArray(self.allow_list, writer);
        }
        try writeOptionalIntegerField(writer, &needs_comma, "mention_total_limit", self.mention_total_limit);
        try writeOptionalBoolField(
            writer,
            &needs_comma,
            "mention_raid_protection_enabled",
            self.mention_raid_protection_enabled,
        );

        try writer.writeByte('}');
    }
};

pub const AutoModerationActionMetadata = struct {
    channel_id: ?Snowflake = null,
    duration_seconds: ?u32 = null,
    custom_message: ?[]const u8 = null,

    pub fn init() AutoModerationActionMetadata {
        return .{};
    }

    pub fn withChannel(self: AutoModerationActionMetadata, channel_id: Snowflake) AutoModerationActionMetadata {
        var metadata = self;
        metadata.channel_id = channel_id;
        return metadata;
    }

    pub fn withDuration(self: AutoModerationActionMetadata, duration_seconds: u32) AutoModerationActionMetadata {
        var metadata = self;
        metadata.duration_seconds = duration_seconds;
        return metadata;
    }

    pub fn withCustomMessage(self: AutoModerationActionMetadata, custom_message: []const u8) AutoModerationActionMetadata {
        var metadata = self;
        metadata.custom_message = custom_message;
        return metadata;
    }

    pub fn writeJson(self: AutoModerationActionMetadata, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        if (self.channel_id) |channel_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"channel_id\":\"{d}\"", .{channel_id.value});
        }
        try writeOptionalIntegerField(writer, &needs_comma, "duration_seconds", self.duration_seconds);
        try writeOptionalStringField(writer, &needs_comma, "custom_message", self.custom_message);

        try writer.writeByte('}');
    }
};

pub const AutoModerationAction = struct {
    type: AutoModerationActionType,
    metadata: ?AutoModerationActionMetadata = null,

    pub fn blockMessage(custom_message: ?[]const u8) AutoModerationAction {
        return .{
            .type = .block_message,
            .metadata = if (custom_message) |message| .{ .custom_message = message } else null,
        };
    }

    pub fn sendAlertMessage(channel_id: Snowflake) AutoModerationAction {
        return .{ .type = .send_alert_message, .metadata = .{ .channel_id = channel_id } };
    }

    pub fn timeout(duration_seconds: u32) AutoModerationAction {
        return .{ .type = .timeout, .metadata = .{ .duration_seconds = duration_seconds } };
    }

    pub fn blockMemberInteraction() AutoModerationAction {
        return .{ .type = .block_member_interaction };
    }

    pub fn writeJson(self: AutoModerationAction, writer: anytype) !void {
        try writer.writeByte('{');
        try writer.print("\"type\":{d}", .{@intFromEnum(self.type)});
        if (self.metadata) |metadata| {
            try writer.writeAll(",\"metadata\":");
            try metadata.writeJson(writer);
        }
        try writer.writeByte('}');
    }
};

pub const CreateAutoModerationRule = struct {
    name: []const u8,
    event_type: AutoModerationRuleEventType = .message_send,
    trigger_type: AutoModerationTriggerType,
    trigger_metadata: ?AutoModerationTriggerMetadata = null,
    actions: []const AutoModerationAction,
    enabled: ?bool = null,
    exempt_roles: []const Snowflake = &.{},
    exempt_channels: []const Snowflake = &.{},

    pub fn init(name: []const u8, trigger_type: AutoModerationTriggerType, actions: []const AutoModerationAction) CreateAutoModerationRule {
        return .{ .name = name, .trigger_type = trigger_type, .actions = actions };
    }

    pub fn withEventType(self: CreateAutoModerationRule, event_type: AutoModerationRuleEventType) CreateAutoModerationRule {
        var payload = self;
        payload.event_type = event_type;
        return payload;
    }

    pub fn withTriggerMetadata(self: CreateAutoModerationRule, trigger_metadata: AutoModerationTriggerMetadata) CreateAutoModerationRule {
        var payload = self;
        payload.trigger_metadata = trigger_metadata;
        return payload;
    }

    pub fn enabledState(self: CreateAutoModerationRule, enabled: bool) CreateAutoModerationRule {
        var payload = self;
        payload.enabled = enabled;
        return payload;
    }

    pub fn withExemptRoles(self: CreateAutoModerationRule, exempt_roles: []const Snowflake) CreateAutoModerationRule {
        var payload = self;
        payload.exempt_roles = exempt_roles;
        return payload;
    }

    pub fn withExemptChannels(self: CreateAutoModerationRule, exempt_channels: []const Snowflake) CreateAutoModerationRule {
        var payload = self;
        payload.exempt_channels = exempt_channels;
        return payload;
    }

    pub fn writeJson(self: CreateAutoModerationRule, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);

        try writeAutoModerationRuleFields(.{
            .event_type = self.event_type,
            .trigger_type = self.trigger_type,
            .trigger_metadata = self.trigger_metadata,
            .actions = self.actions,
            .enabled = self.enabled,
            .exempt_roles = self.exempt_roles,
            .exempt_channels = self.exempt_channels,
        }, writer, &needs_comma);

        try writer.writeByte('}');
    }
};
