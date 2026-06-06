const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Json = @import("../../core/json.zig");
const Interactions = @import("../../interactions/mod.zig");
const Permissions = @import("../../core/permissions.zig");

const Root = @import("../types.zig");
const WelcomeScreenChannel = Root.WelcomeScreenChannel;
const GuildScheduledEventPrivacyLevel = Root.GuildScheduledEventPrivacyLevel;
const GuildScheduledEventEntityType = Root.GuildScheduledEventEntityType;
const GuildScheduledEventStatus = Root.GuildScheduledEventStatus;
const StageInstancePrivacyLevel = Root.StageInstancePrivacyLevel;
const GuildScheduledEventEntityMetadata = Root.GuildScheduledEventEntityMetadata;
const CreateGuildChannel = Root.CreateGuildChannel;
const CreateGuildRole = Root.CreateGuildRole;
const writeCreateGuildRoleArray = Root.writeCreateGuildRoleArray;
const writeCreateGuildChannelArray = Root.writeCreateGuildChannelArray;
const writeWelcomeScreenChannelArray = Root.writeWelcomeScreenChannelArray;
const writeOptionalScheduledEventMetadata = Root.writeOptionalScheduledEventMetadata;
const writeOptionalStringField = Root.writeOptionalStringField;
const writeOptionalIntegerField = Root.writeOptionalIntegerField;
const writeOptionalBoolField = Root.writeOptionalBoolField;
const writeComma = Root.writeComma;

pub const CreateGuild = struct {
    name: []const u8,
    icon: ?[]const u8 = null,
    verification_level: ?u8 = null,
    default_message_notifications: ?u8 = null,
    explicit_content_filter: ?u8 = null,
    roles: []const CreateGuildRole = &.{},
    channels: []const CreateGuildChannel = &.{},
    afk_channel_id: ?Snowflake = null,
    afk_timeout: ?u32 = null,
    system_channel_id: ?Snowflake = null,
    system_channel_flags: ?u32 = null,

    pub fn init(name: []const u8) CreateGuild {
        return .{ .name = name };
    }

    pub fn withIcon(self: CreateGuild, icon: []const u8) CreateGuild {
        var payload = self;
        payload.icon = icon;
        return payload;
    }

    pub fn withRoles(self: CreateGuild, roles: []const CreateGuildRole) CreateGuild {
        var payload = self;
        payload.roles = roles;
        return payload;
    }

    pub fn withChannels(self: CreateGuild, channels: []const CreateGuildChannel) CreateGuild {
        var payload = self;
        payload.channels = channels;
        return payload;
    }

    pub fn withVerificationLevel(self: CreateGuild, level: u8) CreateGuild {
        var payload = self;
        payload.verification_level = level;
        return payload;
    }

    pub fn withDefaultMessageNotifications(self: CreateGuild, level: u8) CreateGuild {
        var payload = self;
        payload.default_message_notifications = level;
        return payload;
    }

    pub fn withExplicitContentFilter(self: CreateGuild, level: u8) CreateGuild {
        var payload = self;
        payload.explicit_content_filter = level;
        return payload;
    }

    pub fn withAfk(self: CreateGuild, channel_id: Snowflake, timeout: u32) CreateGuild {
        var payload = self;
        payload.afk_channel_id = channel_id;
        payload.afk_timeout = timeout;
        return payload;
    }

    pub fn withSystemChannel(self: CreateGuild, channel_id: Snowflake, flags: ?u32) CreateGuild {
        var payload = self;
        payload.system_channel_id = channel_id;
        payload.system_channel_flags = flags;
        return payload;
    }

    pub fn writeJson(self: CreateGuild, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);
        try writeOptionalStringField(writer, &needs_comma, "icon", self.icon);
        try writeOptionalIntegerField(writer, &needs_comma, "verification_level", self.verification_level);
        try writeOptionalIntegerField(
            writer,
            &needs_comma,
            "default_message_notifications",
            self.default_message_notifications,
        );
        try writeOptionalIntegerField(writer, &needs_comma, "explicit_content_filter", self.explicit_content_filter);
        if (self.roles.len != 0) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"roles\":");
            try writeCreateGuildRoleArray(self.roles, writer);
        }
        if (self.channels.len != 0) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"channels\":");
            try writeCreateGuildChannelArray(self.channels, writer);
        }
        if (self.afk_channel_id) |channel_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"afk_channel_id\":\"{d}\"", .{channel_id.value});
        }
        try writeOptionalIntegerField(writer, &needs_comma, "afk_timeout", self.afk_timeout);
        if (self.system_channel_id) |channel_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"system_channel_id\":\"{d}\"", .{channel_id.value});
        }
        try writeOptionalIntegerField(writer, &needs_comma, "system_channel_flags", self.system_channel_flags);

        try writer.writeByte('}');
    }
};

pub const CreateGuildFromTemplate = struct {
    name: []const u8,
    icon: ?[]const u8 = null,

    pub fn init(name: []const u8) CreateGuildFromTemplate {
        return .{ .name = name };
    }

    pub fn withIcon(self: CreateGuildFromTemplate, icon: []const u8) CreateGuildFromTemplate {
        var payload = self;
        payload.icon = icon;
        return payload;
    }

    pub fn writeJson(self: CreateGuildFromTemplate, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);
        try writeOptionalStringField(writer, &needs_comma, "icon", self.icon);
        try writer.writeByte('}');
    }
};

pub const CreateGuildTemplate = struct {
    name: []const u8,
    description: ?[]const u8 = null,

    pub fn init(name: []const u8) CreateGuildTemplate {
        return .{ .name = name };
    }

    pub fn withDescription(self: CreateGuildTemplate, description: []const u8) CreateGuildTemplate {
        var payload = self;
        payload.description = description;
        return payload;
    }

    pub fn writeJson(self: CreateGuildTemplate, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);
        try writeOptionalStringField(writer, &needs_comma, "description", self.description);

        try writer.writeByte('}');
    }
};

pub const EditGuildTemplate = struct {
    name: ?[]const u8 = null,
    description: ?[]const u8 = null,

    pub fn init() EditGuildTemplate {
        return .{};
    }

    pub fn withName(self: EditGuildTemplate, name: []const u8) EditGuildTemplate {
        var payload = self;
        payload.name = name;
        return payload;
    }

    pub fn withDescription(self: EditGuildTemplate, description: []const u8) EditGuildTemplate {
        var payload = self;
        payload.description = description;
        return payload;
    }

    pub fn writeJson(self: EditGuildTemplate, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "name", self.name);
        try writeOptionalStringField(writer, &needs_comma, "description", self.description);

        try writer.writeByte('}');
    }
};

pub const EditGuildWidgetSettings = struct {
    enabled: ?bool = null,
    channel_id: ?Snowflake = null,
    clear_channel_id: bool = false,

    pub fn init() EditGuildWidgetSettings {
        return .{};
    }

    pub fn enabledState(self: EditGuildWidgetSettings, enabled: bool) EditGuildWidgetSettings {
        var payload = self;
        payload.enabled = enabled;
        return payload;
    }

    pub fn withChannel(self: EditGuildWidgetSettings, channel_id: Snowflake) EditGuildWidgetSettings {
        var payload = self;
        payload.channel_id = channel_id;
        payload.clear_channel_id = false;
        return payload;
    }

    pub fn clearChannel(self: EditGuildWidgetSettings) EditGuildWidgetSettings {
        var payload = self;
        payload.channel_id = null;
        payload.clear_channel_id = true;
        return payload;
    }

    pub fn writeJson(self: EditGuildWidgetSettings, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalBoolField(writer, &needs_comma, "enabled", self.enabled);
        if (self.clear_channel_id) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"channel_id\":null");
        } else if (self.channel_id) |channel_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"channel_id\":\"{d}\"", .{channel_id.value});
        }

        try writer.writeByte('}');
    }
};

pub const EditWelcomeScreen = struct {
    enabled: ?bool = null,
    welcome_channels: ?[]const WelcomeScreenChannel = null,
    clear_welcome_channels: bool = false,
    description: ?[]const u8 = null,
    clear_description: bool = false,

    pub fn init() EditWelcomeScreen {
        return .{};
    }

    pub fn enabledState(self: EditWelcomeScreen, enabled: bool) EditWelcomeScreen {
        var payload = self;
        payload.enabled = enabled;
        return payload;
    }

    pub fn withChannels(self: EditWelcomeScreen, channels: []const WelcomeScreenChannel) EditWelcomeScreen {
        var payload = self;
        payload.welcome_channels = channels;
        payload.clear_welcome_channels = false;
        return payload;
    }

    pub fn clearChannels(self: EditWelcomeScreen) EditWelcomeScreen {
        var payload = self;
        payload.welcome_channels = null;
        payload.clear_welcome_channels = true;
        return payload;
    }

    pub fn withDescription(self: EditWelcomeScreen, description: []const u8) EditWelcomeScreen {
        var payload = self;
        payload.description = description;
        payload.clear_description = false;
        return payload;
    }

    pub fn clearDescription(self: EditWelcomeScreen) EditWelcomeScreen {
        var payload = self;
        payload.description = null;
        payload.clear_description = true;
        return payload;
    }

    pub fn writeJson(self: EditWelcomeScreen, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalBoolField(writer, &needs_comma, "enabled", self.enabled);
        if (self.clear_welcome_channels) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"welcome_channels\":null");
        } else if (self.welcome_channels) |channels| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"welcome_channels\":");
            try writeWelcomeScreenChannelArray(channels, writer);
        }
        if (self.clear_description) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"description\":null");
        } else {
            try writeOptionalStringField(writer, &needs_comma, "description", self.description);
        }

        try writer.writeByte('}');
    }
};

pub const CreateGuildScheduledEvent = struct {
    channel_id: ?Snowflake = null,
    entity_metadata: ?GuildScheduledEventEntityMetadata = null,
    name: []const u8,
    privacy_level: GuildScheduledEventPrivacyLevel = .guild_only,
    scheduled_start_time: []const u8,
    scheduled_end_time: ?[]const u8 = null,
    description: ?[]const u8 = null,
    entity_type: GuildScheduledEventEntityType,
    image: ?[]const u8 = null,

    pub fn init(name: []const u8, scheduled_start_time: []const u8, entity_type: GuildScheduledEventEntityType) CreateGuildScheduledEvent {
        return .{ .name = name, .scheduled_start_time = scheduled_start_time, .entity_type = entity_type };
    }

    pub fn withChannel(self: CreateGuildScheduledEvent, channel_id: Snowflake) CreateGuildScheduledEvent {
        var payload = self;
        payload.channel_id = channel_id;
        return payload;
    }

    pub fn withMetadata(self: CreateGuildScheduledEvent, entity_metadata: GuildScheduledEventEntityMetadata) CreateGuildScheduledEvent {
        var payload = self;
        payload.entity_metadata = entity_metadata;
        return payload;
    }

    pub fn withPrivacyLevel(self: CreateGuildScheduledEvent, privacy_level: GuildScheduledEventPrivacyLevel) CreateGuildScheduledEvent {
        var payload = self;
        payload.privacy_level = privacy_level;
        return payload;
    }

    pub fn withEndTime(self: CreateGuildScheduledEvent, scheduled_end_time: []const u8) CreateGuildScheduledEvent {
        var payload = self;
        payload.scheduled_end_time = scheduled_end_time;
        return payload;
    }

    pub fn withDescription(self: CreateGuildScheduledEvent, description: []const u8) CreateGuildScheduledEvent {
        var payload = self;
        payload.description = description;
        return payload;
    }

    pub fn withImage(self: CreateGuildScheduledEvent, image: []const u8) CreateGuildScheduledEvent {
        var payload = self;
        payload.image = image;
        return payload;
    }

    pub fn writeJson(self: CreateGuildScheduledEvent, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        if (self.channel_id) |channel_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"channel_id\":\"{d}\"", .{channel_id.value});
        }
        try writeOptionalScheduledEventMetadata(writer, &needs_comma, self.entity_metadata);

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);

        try writeComma(writer, &needs_comma);
        try writer.print("\"privacy_level\":{d}", .{@intFromEnum(self.privacy_level)});

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"scheduled_start_time\":");
        try Json.writeString(self.scheduled_start_time, writer);

        try writeOptionalStringField(writer, &needs_comma, "scheduled_end_time", self.scheduled_end_time);
        try writeOptionalStringField(writer, &needs_comma, "description", self.description);

        try writeComma(writer, &needs_comma);
        try writer.print("\"entity_type\":{d}", .{@intFromEnum(self.entity_type)});

        try writeOptionalStringField(writer, &needs_comma, "image", self.image);

        try writer.writeByte('}');
    }
};

pub const EditGuildScheduledEvent = struct {
    channel_id: ?Snowflake = null,
    clear_channel_id: bool = false,
    entity_metadata: ?GuildScheduledEventEntityMetadata = null,
    clear_entity_metadata: bool = false,
    name: ?[]const u8 = null,
    privacy_level: ?GuildScheduledEventPrivacyLevel = null,
    scheduled_start_time: ?[]const u8 = null,
    scheduled_end_time: ?[]const u8 = null,
    description: ?[]const u8 = null,
    clear_description: bool = false,
    entity_type: ?GuildScheduledEventEntityType = null,
    status: ?GuildScheduledEventStatus = null,
    image: ?[]const u8 = null,

    pub fn init() EditGuildScheduledEvent {
        return .{};
    }

    pub fn withChannel(self: EditGuildScheduledEvent, channel_id: Snowflake) EditGuildScheduledEvent {
        var payload = self;
        payload.channel_id = channel_id;
        payload.clear_channel_id = false;
        return payload;
    }

    pub fn clearChannel(self: EditGuildScheduledEvent) EditGuildScheduledEvent {
        var payload = self;
        payload.channel_id = null;
        payload.clear_channel_id = true;
        return payload;
    }

    pub fn withMetadata(self: EditGuildScheduledEvent, entity_metadata: GuildScheduledEventEntityMetadata) EditGuildScheduledEvent {
        var payload = self;
        payload.entity_metadata = entity_metadata;
        payload.clear_entity_metadata = false;
        return payload;
    }

    pub fn clearMetadata(self: EditGuildScheduledEvent) EditGuildScheduledEvent {
        var payload = self;
        payload.entity_metadata = null;
        payload.clear_entity_metadata = true;
        return payload;
    }

    pub fn withName(self: EditGuildScheduledEvent, name: []const u8) EditGuildScheduledEvent {
        var payload = self;
        payload.name = name;
        return payload;
    }

    pub fn withPrivacyLevel(self: EditGuildScheduledEvent, privacy_level: GuildScheduledEventPrivacyLevel) EditGuildScheduledEvent {
        var payload = self;
        payload.privacy_level = privacy_level;
        return payload;
    }

    pub fn withStartTime(self: EditGuildScheduledEvent, scheduled_start_time: []const u8) EditGuildScheduledEvent {
        var payload = self;
        payload.scheduled_start_time = scheduled_start_time;
        return payload;
    }

    pub fn withEndTime(self: EditGuildScheduledEvent, scheduled_end_time: []const u8) EditGuildScheduledEvent {
        var payload = self;
        payload.scheduled_end_time = scheduled_end_time;
        return payload;
    }

    pub fn withDescription(self: EditGuildScheduledEvent, description: []const u8) EditGuildScheduledEvent {
        var payload = self;
        payload.description = description;
        payload.clear_description = false;
        return payload;
    }

    pub fn clearDescription(self: EditGuildScheduledEvent) EditGuildScheduledEvent {
        var payload = self;
        payload.description = null;
        payload.clear_description = true;
        return payload;
    }

    pub fn withEntityType(self: EditGuildScheduledEvent, entity_type: GuildScheduledEventEntityType) EditGuildScheduledEvent {
        var payload = self;
        payload.entity_type = entity_type;
        return payload;
    }

    pub fn withStatus(self: EditGuildScheduledEvent, status: GuildScheduledEventStatus) EditGuildScheduledEvent {
        var payload = self;
        payload.status = status;
        return payload;
    }

    pub fn withImage(self: EditGuildScheduledEvent, image: []const u8) EditGuildScheduledEvent {
        var payload = self;
        payload.image = image;
        return payload;
    }

    pub fn writeJson(self: EditGuildScheduledEvent, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        if (self.clear_channel_id) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"channel_id\":null");
        } else if (self.channel_id) |channel_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"channel_id\":\"{d}\"", .{channel_id.value});
        }
        if (self.clear_entity_metadata) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"entity_metadata\":null");
        } else {
            try writeOptionalScheduledEventMetadata(writer, &needs_comma, self.entity_metadata);
        }
        try writeOptionalStringField(writer, &needs_comma, "name", self.name);
        if (self.privacy_level) |privacy_level| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"privacy_level\":{d}", .{@intFromEnum(privacy_level)});
        }
        try writeOptionalStringField(writer, &needs_comma, "scheduled_start_time", self.scheduled_start_time);
        try writeOptionalStringField(writer, &needs_comma, "scheduled_end_time", self.scheduled_end_time);
        if (self.clear_description) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"description\":null");
        } else {
            try writeOptionalStringField(writer, &needs_comma, "description", self.description);
        }
        if (self.entity_type) |entity_type| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"entity_type\":{d}", .{@intFromEnum(entity_type)});
        }
        if (self.status) |status| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"status\":{d}", .{@intFromEnum(status)});
        }
        try writeOptionalStringField(writer, &needs_comma, "image", self.image);

        try writer.writeByte('}');
    }
};

pub const CreateStageInstance = struct {
    channel_id: Snowflake,
    topic: []const u8,
    privacy_level: ?StageInstancePrivacyLevel = null,
    send_start_notification: ?bool = null,
    guild_scheduled_event_id: ?Snowflake = null,

    pub fn init(channel_id: Snowflake, topic: []const u8) CreateStageInstance {
        return .{ .channel_id = channel_id, .topic = topic };
    }

    pub fn withPrivacyLevel(self: CreateStageInstance, privacy_level: StageInstancePrivacyLevel) CreateStageInstance {
        var payload = self;
        payload.privacy_level = privacy_level;
        return payload;
    }

    pub fn sendStartNotification(self: CreateStageInstance, send_start_notification: bool) CreateStageInstance {
        var payload = self;
        payload.send_start_notification = send_start_notification;
        return payload;
    }

    pub fn withScheduledEvent(self: CreateStageInstance, event_id: Snowflake) CreateStageInstance {
        var payload = self;
        payload.guild_scheduled_event_id = event_id;
        return payload;
    }

    pub fn writeJson(self: CreateStageInstance, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.print("\"channel_id\":\"{d}\"", .{self.channel_id.value});

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"topic\":");
        try Json.writeString(self.topic, writer);

        if (self.privacy_level) |privacy_level| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"privacy_level\":{d}", .{@intFromEnum(privacy_level)});
        }
        try writeOptionalBoolField(writer, &needs_comma, "send_start_notification", self.send_start_notification);
        if (self.guild_scheduled_event_id) |event_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"guild_scheduled_event_id\":\"{d}\"", .{event_id.value});
        }

        try writer.writeByte('}');
    }
};

pub const EditStageInstance = struct {
    topic: ?[]const u8 = null,
    privacy_level: ?StageInstancePrivacyLevel = null,

    pub fn init() EditStageInstance {
        return .{};
    }

    pub fn withTopic(self: EditStageInstance, topic: []const u8) EditStageInstance {
        var payload = self;
        payload.topic = topic;
        return payload;
    }

    pub fn withPrivacyLevel(self: EditStageInstance, privacy_level: StageInstancePrivacyLevel) EditStageInstance {
        var payload = self;
        payload.privacy_level = privacy_level;
        return payload;
    }

    pub fn writeJson(self: EditStageInstance, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "topic", self.topic);
        if (self.privacy_level) |privacy_level| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"privacy_level\":{d}", .{@intFromEnum(privacy_level)});
        }

        try writer.writeByte('}');
    }
};
