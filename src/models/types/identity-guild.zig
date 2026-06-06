const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Json = @import("../../core/json.zig");
const Interactions = @import("../../interactions/mod.zig");
const Permissions = @import("../../core/permissions.zig");

const Root = @import("../types.zig");
const Channel = Root.Channel;
const writeStringArray = Root.writeStringArray;
const writeStringPairObject = Root.writeStringPairObject;
const writeApplicationRoleConnectionMetadataArray = Root.writeApplicationRoleConnectionMetadataArray;
const writeOptionalStringField = Root.writeOptionalStringField;
const writeNullableStringField = Root.writeNullableStringField;
const writeNullableSnowflakeField = Root.writeNullableSnowflakeField;
const writeOptionalIntegerField = Root.writeOptionalIntegerField;
const writeOptionalBoolField = Root.writeOptionalBoolField;
const writeQuerySeparator = Root.writeQuerySeparator;
const writeComma = Root.writeComma;

pub const User = struct {
    id: Snowflake,
    username: []const u8,
    discriminator: ?[]const u8 = null,
    global_name: ?[]const u8 = null,
    avatar: ?[]const u8 = null,
    banner: ?[]const u8 = null,
    bot: bool = false,
    system: bool = false,
    mfa_enabled: ?bool = null,
    accent_color: ?u32 = null,
    locale: ?[]const u8 = null,
    verified: ?bool = null,
    email: ?[]const u8 = null,
    flags: ?u32 = null,
    public_flags: ?u32 = null,

    pub fn displayName(self: User) []const u8 {
        return self.global_name orelse self.username;
    }

    pub fn tag(self: User, allocator: std.mem.Allocator) ![]u8 {
        if (self.discriminator) |discriminator| {
            if (!std.mem.eql(u8, discriminator, "0")) {
                return std.fmt.allocPrint(allocator, "{s}#{s}", .{ self.username, discriminator });
            }
        }
        return allocator.dupe(u8, self.username);
    }
};

pub const StringPair = struct {
    key: []const u8,
    value: []const u8,
};

pub const ApplicationRoleConnectionMetadataType = enum(u8) {
    integer_less_than_or_equal = 1,
    integer_greater_than_or_equal = 2,
    integer_equal = 3,
    integer_not_equal = 4,
    datetime_less_than_or_equal = 5,
    datetime_greater_than_or_equal = 6,
    boolean_equal = 7,
    boolean_not_equal = 8,
};

pub const ApplicationRoleConnectionMetadata = struct {
    type: ApplicationRoleConnectionMetadataType,
    key: []const u8,
    name: []const u8,
    description: []const u8,
    name_localizations: ?[]const StringPair = null,
    description_localizations: ?[]const StringPair = null,

    pub fn init(
        metadata_type: ApplicationRoleConnectionMetadataType,
        key: []const u8,
        name: []const u8,
        description: []const u8,
    ) ApplicationRoleConnectionMetadata {
        return .{
            .type = metadata_type,
            .key = key,
            .name = name,
            .description = description,
        };
    }

    pub fn withNameLocalizations(
        self: ApplicationRoleConnectionMetadata,
        localizations: []const StringPair,
    ) ApplicationRoleConnectionMetadata {
        var record = self;
        record.name_localizations = localizations;
        return record;
    }

    pub fn withDescriptionLocalizations(
        self: ApplicationRoleConnectionMetadata,
        localizations: []const StringPair,
    ) ApplicationRoleConnectionMetadata {
        var record = self;
        record.description_localizations = localizations;
        return record;
    }

    pub fn writeJson(self: ApplicationRoleConnectionMetadata, writer: anytype) !void {
        try writer.print("{{\"type\":{d},\"key\":", .{@intFromEnum(self.type)});
        try Json.writeString(self.key, writer);
        try writer.writeAll(",\"name\":");
        try Json.writeString(self.name, writer);
        if (self.name_localizations) |localizations| {
            try writer.writeAll(",\"name_localizations\":");
            try writeStringPairObject(localizations, writer);
        }
        try writer.writeAll(",\"description\":");
        try Json.writeString(self.description, writer);
        if (self.description_localizations) |localizations| {
            try writer.writeAll(",\"description_localizations\":");
            try writeStringPairObject(localizations, writer);
        }
        try writer.writeByte('}');
    }
};

pub const UpdateApplicationRoleConnectionMetadataRecords = struct {
    records: []const ApplicationRoleConnectionMetadata,

    pub fn init(records: []const ApplicationRoleConnectionMetadata) UpdateApplicationRoleConnectionMetadataRecords {
        return .{ .records = records };
    }

    pub fn writeJson(self: UpdateApplicationRoleConnectionMetadataRecords, writer: anytype) !void {
        try writeApplicationRoleConnectionMetadataArray(self.records, writer);
    }
};

pub const Presence = struct {
    guild_id: ?Snowflake = null,
    user_id: Snowflake,
    status: []const u8,
    activities_count: usize = 0,
};

pub const Guild = struct {
    id: Snowflake,
    name: []const u8,
    icon: ?[]const u8 = null,
    splash: ?[]const u8 = null,
    discovery_splash: ?[]const u8 = null,
    banner: ?[]const u8 = null,
    owner_id: ?Snowflake = null,
    description: ?[]const u8 = null,
    afk_channel_id: ?Snowflake = null,
    afk_timeout: ?u32 = null,
    system_channel_id: ?Snowflake = null,
    rules_channel_id: ?Snowflake = null,
    public_updates_channel_id: ?Snowflake = null,
    safety_alerts_channel_id: ?Snowflake = null,
    features: []const []const u8 = &.{},
    preferred_locale: ?[]const u8 = null,
    verification_level: ?u8 = null,
    default_message_notifications: ?u8 = null,
    explicit_content_filter: ?u8 = null,
    mfa_level: ?u8 = null,
    nsfw_level: ?u8 = null,
    max_presences: ?u32 = null,
    max_members: ?u32 = null,
    premium_tier: ?u8 = null,
    premium_subscription_count: ?u32 = null,
    premium_progress_bar_enabled: ?bool = null,
    approximate_member_count: ?u32 = null,
    approximate_presence_count: ?u32 = null,
    incidents_data: ?IncidentsData = null,
};

pub const EditGuild = struct {
    name: ?[]const u8 = null,
    verification_level: ?u8 = null,
    default_message_notifications: ?u8 = null,
    explicit_content_filter: ?u8 = null,
    afk_channel_id: ?Snowflake = null,
    clear_afk_channel_id: bool = false,
    afk_timeout: ?u32 = null,
    icon: ?[]const u8 = null,
    clear_icon: bool = false,
    splash: ?[]const u8 = null,
    clear_splash: bool = false,
    discovery_splash: ?[]const u8 = null,
    clear_discovery_splash: bool = false,
    banner: ?[]const u8 = null,
    clear_banner: bool = false,
    system_channel_id: ?Snowflake = null,
    clear_system_channel_id: bool = false,
    system_channel_flags: ?u32 = null,
    rules_channel_id: ?Snowflake = null,
    clear_rules_channel_id: bool = false,
    public_updates_channel_id: ?Snowflake = null,
    clear_public_updates_channel_id: bool = false,
    preferred_locale: ?[]const u8 = null,
    clear_preferred_locale: bool = false,
    features: ?[]const []const u8 = null,
    description: ?[]const u8 = null,
    clear_description: bool = false,
    premium_progress_bar_enabled: ?bool = null,
    safety_alerts_channel_id: ?Snowflake = null,
    clear_safety_alerts_channel_id: bool = false,

    pub fn init() EditGuild {
        return .{};
    }

    pub fn withName(self: EditGuild, name: []const u8) EditGuild {
        var payload = self;
        payload.name = name;
        return payload;
    }

    pub fn withVerificationLevel(self: EditGuild, verification_level: u8) EditGuild {
        var payload = self;
        payload.verification_level = verification_level;
        return payload;
    }

    pub fn withDefaultMessageNotifications(self: EditGuild, default_message_notifications: u8) EditGuild {
        var payload = self;
        payload.default_message_notifications = default_message_notifications;
        return payload;
    }

    pub fn withExplicitContentFilter(self: EditGuild, explicit_content_filter: u8) EditGuild {
        var payload = self;
        payload.explicit_content_filter = explicit_content_filter;
        return payload;
    }

    pub fn withAfkChannel(self: EditGuild, afk_channel_id: Snowflake) EditGuild {
        var payload = self;
        payload.afk_channel_id = afk_channel_id;
        payload.clear_afk_channel_id = false;
        return payload;
    }

    pub fn clearAfkChannel(self: EditGuild) EditGuild {
        var payload = self;
        payload.afk_channel_id = null;
        payload.clear_afk_channel_id = true;
        return payload;
    }

    pub fn withAfkTimeout(self: EditGuild, afk_timeout: u32) EditGuild {
        var payload = self;
        payload.afk_timeout = afk_timeout;
        return payload;
    }

    pub fn withIcon(self: EditGuild, icon: []const u8) EditGuild {
        var payload = self;
        payload.icon = icon;
        payload.clear_icon = false;
        return payload;
    }

    pub fn clearIcon(self: EditGuild) EditGuild {
        var payload = self;
        payload.icon = null;
        payload.clear_icon = true;
        return payload;
    }

    pub fn withSplash(self: EditGuild, splash: []const u8) EditGuild {
        var payload = self;
        payload.splash = splash;
        payload.clear_splash = false;
        return payload;
    }

    pub fn clearSplash(self: EditGuild) EditGuild {
        var payload = self;
        payload.splash = null;
        payload.clear_splash = true;
        return payload;
    }

    pub fn withDiscoverySplash(self: EditGuild, discovery_splash: []const u8) EditGuild {
        var payload = self;
        payload.discovery_splash = discovery_splash;
        payload.clear_discovery_splash = false;
        return payload;
    }

    pub fn clearDiscoverySplash(self: EditGuild) EditGuild {
        var payload = self;
        payload.discovery_splash = null;
        payload.clear_discovery_splash = true;
        return payload;
    }

    pub fn withBanner(self: EditGuild, banner: []const u8) EditGuild {
        var payload = self;
        payload.banner = banner;
        payload.clear_banner = false;
        return payload;
    }

    pub fn clearBanner(self: EditGuild) EditGuild {
        var payload = self;
        payload.banner = null;
        payload.clear_banner = true;
        return payload;
    }

    pub fn withSystemChannel(self: EditGuild, system_channel_id: Snowflake) EditGuild {
        var payload = self;
        payload.system_channel_id = system_channel_id;
        payload.clear_system_channel_id = false;
        return payload;
    }

    pub fn clearSystemChannel(self: EditGuild) EditGuild {
        var payload = self;
        payload.system_channel_id = null;
        payload.clear_system_channel_id = true;
        return payload;
    }

    pub fn withSystemChannelFlags(self: EditGuild, system_channel_flags: u32) EditGuild {
        var payload = self;
        payload.system_channel_flags = system_channel_flags;
        return payload;
    }

    pub fn withRulesChannel(self: EditGuild, rules_channel_id: Snowflake) EditGuild {
        var payload = self;
        payload.rules_channel_id = rules_channel_id;
        payload.clear_rules_channel_id = false;
        return payload;
    }

    pub fn clearRulesChannel(self: EditGuild) EditGuild {
        var payload = self;
        payload.rules_channel_id = null;
        payload.clear_rules_channel_id = true;
        return payload;
    }

    pub fn withPublicUpdatesChannel(self: EditGuild, public_updates_channel_id: Snowflake) EditGuild {
        var payload = self;
        payload.public_updates_channel_id = public_updates_channel_id;
        payload.clear_public_updates_channel_id = false;
        return payload;
    }

    pub fn clearPublicUpdatesChannel(self: EditGuild) EditGuild {
        var payload = self;
        payload.public_updates_channel_id = null;
        payload.clear_public_updates_channel_id = true;
        return payload;
    }

    pub fn withPreferredLocale(self: EditGuild, preferred_locale: []const u8) EditGuild {
        var payload = self;
        payload.preferred_locale = preferred_locale;
        payload.clear_preferred_locale = false;
        return payload;
    }

    pub fn clearPreferredLocale(self: EditGuild) EditGuild {
        var payload = self;
        payload.preferred_locale = null;
        payload.clear_preferred_locale = true;
        return payload;
    }

    pub fn withFeatures(self: EditGuild, features: []const []const u8) EditGuild {
        var payload = self;
        payload.features = features;
        return payload;
    }

    pub fn withDescription(self: EditGuild, description: []const u8) EditGuild {
        var payload = self;
        payload.description = description;
        payload.clear_description = false;
        return payload;
    }

    pub fn clearDescription(self: EditGuild) EditGuild {
        var payload = self;
        payload.description = null;
        payload.clear_description = true;
        return payload;
    }

    pub fn premiumProgressBarState(self: EditGuild, enabled: bool) EditGuild {
        var payload = self;
        payload.premium_progress_bar_enabled = enabled;
        return payload;
    }

    pub fn withSafetyAlertsChannel(self: EditGuild, safety_alerts_channel_id: Snowflake) EditGuild {
        var payload = self;
        payload.safety_alerts_channel_id = safety_alerts_channel_id;
        payload.clear_safety_alerts_channel_id = false;
        return payload;
    }

    pub fn clearSafetyAlertsChannel(self: EditGuild) EditGuild {
        var payload = self;
        payload.safety_alerts_channel_id = null;
        payload.clear_safety_alerts_channel_id = true;
        return payload;
    }

    pub fn writeJson(self: EditGuild, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "name", self.name);
        try writeOptionalIntegerField(writer, &needs_comma, "verification_level", self.verification_level);
        try writeOptionalIntegerField(
            writer,
            &needs_comma,
            "default_message_notifications",
            self.default_message_notifications,
        );
        try writeOptionalIntegerField(writer, &needs_comma, "explicit_content_filter", self.explicit_content_filter);
        try writeNullableSnowflakeField(writer, &needs_comma, "afk_channel_id", self.afk_channel_id, self.clear_afk_channel_id);
        try writeOptionalIntegerField(writer, &needs_comma, "afk_timeout", self.afk_timeout);
        try writeNullableStringField(writer, &needs_comma, "icon", self.icon, self.clear_icon);
        try writeNullableStringField(writer, &needs_comma, "splash", self.splash, self.clear_splash);
        try writeNullableStringField(
            writer,
            &needs_comma,
            "discovery_splash",
            self.discovery_splash,
            self.clear_discovery_splash,
        );
        try writeNullableStringField(writer, &needs_comma, "banner", self.banner, self.clear_banner);
        try writeNullableSnowflakeField(
            writer,
            &needs_comma,
            "system_channel_id",
            self.system_channel_id,
            self.clear_system_channel_id,
        );
        try writeOptionalIntegerField(writer, &needs_comma, "system_channel_flags", self.system_channel_flags);
        try writeNullableSnowflakeField(
            writer,
            &needs_comma,
            "rules_channel_id",
            self.rules_channel_id,
            self.clear_rules_channel_id,
        );
        try writeNullableSnowflakeField(
            writer,
            &needs_comma,
            "public_updates_channel_id",
            self.public_updates_channel_id,
            self.clear_public_updates_channel_id,
        );
        try writeNullableStringField(
            writer,
            &needs_comma,
            "preferred_locale",
            self.preferred_locale,
            self.clear_preferred_locale,
        );
        if (self.features) |features| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"features\":");
            try writeStringArray(features, writer);
        }
        try writeNullableStringField(writer, &needs_comma, "description", self.description, self.clear_description);
        try writeOptionalBoolField(
            writer,
            &needs_comma,
            "premium_progress_bar_enabled",
            self.premium_progress_bar_enabled,
        );
        try writeNullableSnowflakeField(
            writer,
            &needs_comma,
            "safety_alerts_channel_id",
            self.safety_alerts_channel_id,
            self.clear_safety_alerts_channel_id,
        );

        try writer.writeByte('}');
    }
};

pub const GuildTemplate = struct {
    code: []const u8,
    name: []const u8,
    description: ?[]const u8 = null,
    usage_count: u32 = 0,
    creator_id: Snowflake,
    creator: User,
    created_at: []const u8,
    updated_at: []const u8,
    source_guild_id: Snowflake,
    is_dirty: ?bool = null,
};

pub const GuildWidgetSettings = struct {
    enabled: bool,
    channel_id: ?Snowflake = null,
};

pub const GuildWidget = struct {
    id: Snowflake,
    name: []const u8,
    instant_invite: ?[]const u8 = null,
    channels: []const Channel = &.{},
    members: []const User = &.{},
    presence_count: u32 = 0,
};

pub const GuildWidgetImageStyle = enum {
    shield,
    banner1,
    banner2,
    banner3,
    banner4,

    pub fn queryValue(self: GuildWidgetImageStyle) []const u8 {
        return switch (self) {
            .shield => "shield",
            .banner1 => "banner1",
            .banner2 => "banner2",
            .banner3 => "banner3",
            .banner4 => "banner4",
        };
    }
};

pub const GetGuildWidgetImage = struct {
    style: ?GuildWidgetImageStyle = null,

    pub fn init() GetGuildWidgetImage {
        return .{};
    }

    pub fn withStyle(self: GetGuildWidgetImage, style: GuildWidgetImageStyle) GetGuildWidgetImage {
        var options = self;
        options.style = style;
        return options;
    }

    pub fn hasQuery(self: GetGuildWidgetImage) bool {
        return self.style != null;
    }

    pub fn writeQuery(self: GetGuildWidgetImage, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.style) |style| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.writeAll("style=");
            try writer.writeAll(style.queryValue());
        }
    }
};

pub const IncidentsData = struct {
    invites_disabled_until: ?[]const u8 = null,
    dms_disabled_until: ?[]const u8 = null,
    dm_spam_detected_at: ?[]const u8 = null,
    raid_detected_at: ?[]const u8 = null,
};

pub const EditGuildIncidentActions = struct {
    invites_disabled_until: ?[]const u8 = null,
    clear_invites_disabled_until: bool = false,
    dms_disabled_until: ?[]const u8 = null,
    clear_dms_disabled_until: bool = false,

    pub fn init() EditGuildIncidentActions {
        return .{};
    }

    pub fn disableInvitesUntil(self: EditGuildIncidentActions, timestamp: []const u8) EditGuildIncidentActions {
        var payload = self;
        payload.invites_disabled_until = timestamp;
        payload.clear_invites_disabled_until = false;
        return payload;
    }

    pub fn clearInvitesDisabledUntil(self: EditGuildIncidentActions) EditGuildIncidentActions {
        var payload = self;
        payload.invites_disabled_until = null;
        payload.clear_invites_disabled_until = true;
        return payload;
    }

    pub fn disableDmsUntil(self: EditGuildIncidentActions, timestamp: []const u8) EditGuildIncidentActions {
        var payload = self;
        payload.dms_disabled_until = timestamp;
        payload.clear_dms_disabled_until = false;
        return payload;
    }

    pub fn clearDmsDisabledUntil(self: EditGuildIncidentActions) EditGuildIncidentActions {
        var payload = self;
        payload.dms_disabled_until = null;
        payload.clear_dms_disabled_until = true;
        return payload;
    }

    pub fn writeJson(self: EditGuildIncidentActions, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeNullableStringField(
            writer,
            &needs_comma,
            "invites_disabled_until",
            self.invites_disabled_until,
            self.clear_invites_disabled_until,
        );
        try writeNullableStringField(
            writer,
            &needs_comma,
            "dms_disabled_until",
            self.dms_disabled_until,
            self.clear_dms_disabled_until,
        );

        try writer.writeByte('}');
    }
};

pub const OnboardingMode = enum(u8) {
    onboarding_default = 0,
    onboarding_advanced = 1,
};

pub const OnboardingPromptType = enum(u8) {
    multiple_choice = 0,
    dropdown = 1,
};
