const std = @import("std");
const Snowflake = @import("../core/snowflake.zig").Snowflake;
const Json = @import("../core/json.zig");
const Interactions = @import("../interactions/mod.zig");
const Permissions = @import("../core/permissions.zig");

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

pub const OnboardingPromptOption = struct {
    id: ?Snowflake = null,
    channel_ids: []const Snowflake = &.{},
    role_ids: []const Snowflake = &.{},
    emoji_id: ?Snowflake = null,
    emoji_name: ?[]const u8 = null,
    emoji_animated: ?bool = null,
    title: []const u8,
    description: ?[]const u8 = null,

    pub fn init(title: []const u8) OnboardingPromptOption {
        return .{ .title = title };
    }

    pub fn withId(self: OnboardingPromptOption, id: Snowflake) OnboardingPromptOption {
        var option = self;
        option.id = id;
        return option;
    }

    pub fn withChannels(self: OnboardingPromptOption, channel_ids: []const Snowflake) OnboardingPromptOption {
        var option = self;
        option.channel_ids = channel_ids;
        return option;
    }

    pub fn withRoles(self: OnboardingPromptOption, role_ids: []const Snowflake) OnboardingPromptOption {
        var option = self;
        option.role_ids = role_ids;
        return option;
    }

    pub fn withEmojiId(self: OnboardingPromptOption, emoji_id: Snowflake) OnboardingPromptOption {
        var option = self;
        option.emoji_id = emoji_id;
        return option;
    }

    pub fn withEmojiName(self: OnboardingPromptOption, emoji_name: []const u8) OnboardingPromptOption {
        var option = self;
        option.emoji_name = emoji_name;
        return option;
    }

    pub fn emojiAnimatedState(self: OnboardingPromptOption, emoji_animated: bool) OnboardingPromptOption {
        var option = self;
        option.emoji_animated = emoji_animated;
        return option;
    }

    pub fn withDescription(self: OnboardingPromptOption, description: []const u8) OnboardingPromptOption {
        var option = self;
        option.description = description;
        return option;
    }

    pub fn writeJson(self: OnboardingPromptOption, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        if (self.id) |id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"id\":\"{d}\"", .{id.value});
        }
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"channel_ids\":");
        try writeSnowflakeStringArray(self.channel_ids, writer);
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"role_ids\":");
        try writeSnowflakeStringArray(self.role_ids, writer);
        if (self.emoji_id) |emoji_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"emoji_id\":\"{d}\"", .{emoji_id.value});
        }
        try writeOptionalStringField(writer, &needs_comma, "emoji_name", self.emoji_name);
        try writeOptionalBoolField(writer, &needs_comma, "emoji_animated", self.emoji_animated);
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"title\":");
        try Json.writeString(self.title, writer);
        try writeOptionalStringField(writer, &needs_comma, "description", self.description);

        try writer.writeByte('}');
    }
};

pub const OnboardingPrompt = struct {
    id: ?Snowflake = null,
    type: OnboardingPromptType = .multiple_choice,
    options: []const OnboardingPromptOption = &.{},
    title: []const u8,
    single_select: bool = false,
    required: bool = false,
    in_onboarding: bool = true,

    pub fn init(title: []const u8) OnboardingPrompt {
        return .{ .title = title };
    }

    pub fn withId(self: OnboardingPrompt, id: Snowflake) OnboardingPrompt {
        var prompt = self;
        prompt.id = id;
        return prompt;
    }

    pub fn withType(self: OnboardingPrompt, prompt_type: OnboardingPromptType) OnboardingPrompt {
        var prompt = self;
        prompt.type = prompt_type;
        return prompt;
    }

    pub fn withOptions(self: OnboardingPrompt, options: []const OnboardingPromptOption) OnboardingPrompt {
        var prompt = self;
        prompt.options = options;
        return prompt;
    }

    pub fn singleSelectState(self: OnboardingPrompt, single_select: bool) OnboardingPrompt {
        var prompt = self;
        prompt.single_select = single_select;
        return prompt;
    }

    pub fn requiredState(self: OnboardingPrompt, required: bool) OnboardingPrompt {
        var prompt = self;
        prompt.required = required;
        return prompt;
    }

    pub fn inOnboardingState(self: OnboardingPrompt, in_onboarding: bool) OnboardingPrompt {
        var prompt = self;
        prompt.in_onboarding = in_onboarding;
        return prompt;
    }

    pub fn writeJson(self: OnboardingPrompt, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        if (self.id) |id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"id\":\"{d}\"", .{id.value});
        }
        try writeComma(writer, &needs_comma);
        try writer.print("\"type\":{d}", .{@intFromEnum(self.type)});
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"options\":");
        try writeOnboardingPromptOptionArray(self.options, writer);
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"title\":");
        try Json.writeString(self.title, writer);
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"single_select\":");
        try writer.writeAll(if (self.single_select) "true" else "false");
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"required\":");
        try writer.writeAll(if (self.required) "true" else "false");
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"in_onboarding\":");
        try writer.writeAll(if (self.in_onboarding) "true" else "false");

        try writer.writeByte('}');
    }
};

pub const EditGuildOnboarding = struct {
    prompts: ?[]const OnboardingPrompt = null,
    default_channel_ids: ?[]const Snowflake = null,
    enabled: ?bool = null,
    mode: ?OnboardingMode = null,

    pub fn init() EditGuildOnboarding {
        return .{};
    }

    pub fn withPrompts(self: EditGuildOnboarding, prompts: []const OnboardingPrompt) EditGuildOnboarding {
        var payload = self;
        payload.prompts = prompts;
        return payload;
    }

    pub fn withDefaultChannels(self: EditGuildOnboarding, default_channel_ids: []const Snowflake) EditGuildOnboarding {
        var payload = self;
        payload.default_channel_ids = default_channel_ids;
        return payload;
    }

    pub fn enabledState(self: EditGuildOnboarding, enabled: bool) EditGuildOnboarding {
        var payload = self;
        payload.enabled = enabled;
        return payload;
    }

    pub fn withMode(self: EditGuildOnboarding, mode: OnboardingMode) EditGuildOnboarding {
        var payload = self;
        payload.mode = mode;
        return payload;
    }

    pub fn writeJson(self: EditGuildOnboarding, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        if (self.prompts) |prompts| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"prompts\":");
            try writeOnboardingPromptArray(prompts, writer);
        }
        if (self.default_channel_ids) |ids| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"default_channel_ids\":");
            try writeSnowflakeStringArray(ids, writer);
        }
        try writeOptionalBoolField(writer, &needs_comma, "enabled", self.enabled);
        if (self.mode) |mode| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"mode\":{d}", .{@intFromEnum(mode)});
        }

        try writer.writeByte('}');
    }
};

pub const WelcomeScreen = struct {
    description: ?[]const u8 = null,
    welcome_channels: []const WelcomeScreenChannel = &.{},
};

pub const WelcomeScreenChannel = struct {
    channel_id: Snowflake,
    description: []const u8,
    emoji_id: ?Snowflake = null,
    emoji_name: ?[]const u8 = null,

    pub fn init(channel_id: Snowflake, description: []const u8) WelcomeScreenChannel {
        return .{
            .channel_id = channel_id,
            .description = description,
        };
    }

    pub fn withEmojiId(self: WelcomeScreenChannel, emoji_id: Snowflake) WelcomeScreenChannel {
        var channel = self;
        channel.emoji_id = emoji_id;
        channel.emoji_name = null;
        return channel;
    }

    pub fn withEmojiName(self: WelcomeScreenChannel, emoji_name: []const u8) WelcomeScreenChannel {
        var channel = self;
        channel.emoji_id = null;
        channel.emoji_name = emoji_name;
        return channel;
    }

    pub fn writeJson(self: WelcomeScreenChannel, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.print("\"channel_id\":\"{d}\"", .{self.channel_id.value});

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"description\":");
        try Json.writeString(self.description, writer);

        if (self.emoji_id) |emoji_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"emoji_id\":\"{d}\"", .{emoji_id.value});
        }
        try writeOptionalStringField(writer, &needs_comma, "emoji_name", self.emoji_name);

        try writer.writeByte('}');
    }
};

pub const PartialInvite = struct {
    code: ?[]const u8 = null,
    uses: ?u32 = null,
};

pub const ApplicationEventWebhookStatus = enum(u8) {
    disabled = 1,
    enabled = 2,
    disabled_by_discord = 3,
};

pub const ApplicationEventWebhookType = enum {
    application_authorized,
    application_deauthorized,
    entitlement_create,
    entitlement_update,
    entitlement_delete,
    quest_user_enrollment,
    lobby_message_create,
    lobby_message_update,
    lobby_message_delete,
    game_direct_message_create,
    game_direct_message_update,
    game_direct_message_delete,

    pub fn value(self: ApplicationEventWebhookType) []const u8 {
        return switch (self) {
            .application_authorized => "APPLICATION_AUTHORIZED",
            .application_deauthorized => "APPLICATION_DEAUTHORIZED",
            .entitlement_create => "ENTITLEMENT_CREATE",
            .entitlement_update => "ENTITLEMENT_UPDATE",
            .entitlement_delete => "ENTITLEMENT_DELETE",
            .quest_user_enrollment => "QUEST_USER_ENROLLMENT",
            .lobby_message_create => "LOBBY_MESSAGE_CREATE",
            .lobby_message_update => "LOBBY_MESSAGE_UPDATE",
            .lobby_message_delete => "LOBBY_MESSAGE_DELETE",
            .game_direct_message_create => "GAME_DIRECT_MESSAGE_CREATE",
            .game_direct_message_update => "GAME_DIRECT_MESSAGE_UPDATE",
            .game_direct_message_delete => "GAME_DIRECT_MESSAGE_DELETE",
        };
    }

    pub fn fromValue(raw: []const u8) ?ApplicationEventWebhookType {
        inline for (std.meta.fields(ApplicationEventWebhookType)) |field| {
            const event_type: ApplicationEventWebhookType = @enumFromInt(field.value);
            if (std.mem.eql(u8, raw, event_type.value())) return event_type;
        }
        return null;
    }
};

pub const ApplicationEventWebhookPayloadType = enum(u8) {
    ping = 0,
    event = 1,
};

pub const ApplicationEventWebhookPayload = struct {
    version: u8,
    application_id: Snowflake,
    type: ApplicationEventWebhookPayloadType,
    event: ?ApplicationEventWebhookBody = null,
};

pub const ApplicationEventWebhookBody = struct {
    type: ApplicationEventWebhookType,
    timestamp: []const u8,
};

pub const Application = struct {
    id: Snowflake,
    name: []const u8,
    icon: ?[]const u8 = null,
    cover_image: ?[]const u8 = null,
    description: []const u8 = "",
    bot_public: bool = true,
    bot_require_code_grant: bool = false,
    bot: ?User = null,
    owner: ?User = null,
    team: ?Team = null,
    verify_key: []const u8 = "",
    guild_id: ?Snowflake = null,
    flags: ?u32 = null,
    approximate_guild_count: ?u32 = null,
    approximate_user_install_count: ?u32 = null,
    interactions_endpoint_url: ?[]const u8 = null,
    role_connections_verification_url: ?[]const u8 = null,
    event_webhooks_url: ?[]const u8 = null,
    event_webhooks_status: ?ApplicationEventWebhookStatus = null,
    event_webhooks_types: []const []const u8 = &.{},
    tags: []const []const u8 = &.{},
    custom_install_url: ?[]const u8 = null,
};

pub const MembershipState = enum(u8) {
    invited = 1,
    accepted = 2,
};

pub const TeamMember = struct {
    membership_state: MembershipState,
    team_id: Snowflake,
    user: User,
    role: ?[]const u8 = null,
};

pub const Team = struct {
    id: Snowflake,
    name: []const u8,
    icon: ?[]const u8 = null,
    owner_user_id: Snowflake,
    members: []const TeamMember = &.{},
};

pub const SkuType = enum(u8) {
    durable = 2,
    consumable = 3,
    subscription = 5,
    subscription_group = 6,
};

pub const SkuFlags = struct {
    pub const Bit = u64;
    pub const available: Bit = 1 << 2;
    pub const guild_subscription: Bit = 1 << 7;
    pub const user_subscription: Bit = 1 << 8;
};

/// User account badge flags (`public_flags`), matching Discord.js `UserFlags`.
pub const UserFlags = struct {
    pub const Bit = u32;

    pub const staff: Bit = 1 << 0;
    pub const partner: Bit = 1 << 1;
    pub const hypesquad: Bit = 1 << 2;
    pub const bug_hunter_level_1: Bit = 1 << 3;
    pub const hypesquad_online_house_1: Bit = 1 << 6;
    pub const hypesquad_online_house_2: Bit = 1 << 7;
    pub const hypesquad_online_house_3: Bit = 1 << 8;
    pub const premium_early_supporter: Bit = 1 << 9;
    pub const team_pseudo_user: Bit = 1 << 10;
    pub const bug_hunter_level_2: Bit = 1 << 14;
    pub const verified_bot: Bit = 1 << 16;
    pub const verified_developer: Bit = 1 << 17;
    pub const certified_moderator: Bit = 1 << 18;
    pub const bot_http_interactions: Bit = 1 << 19;
    pub const active_developer: Bit = 1 << 22;

    pub fn has(flags: Bit, flag: Bit) bool {
        return (flags & flag) == flag;
    }
};

/// Application capability flags (`flags`), matching Discord.js `ApplicationFlags`.
pub const ApplicationFlags = struct {
    pub const Bit = u32;

    pub const auto_moderation_rule_create_badge: Bit = 1 << 6;
    pub const gateway_presence: Bit = 1 << 12;
    pub const gateway_presence_limited: Bit = 1 << 13;
    pub const gateway_guild_members: Bit = 1 << 14;
    pub const gateway_guild_members_limited: Bit = 1 << 15;
    pub const verification_pending_guild_limit: Bit = 1 << 16;
    pub const embedded: Bit = 1 << 17;
    pub const gateway_message_content: Bit = 1 << 18;
    pub const gateway_message_content_limited: Bit = 1 << 19;
    pub const application_command_badge: Bit = 1 << 23;

    pub fn has(flags: Bit, flag: Bit) bool {
        return (flags & flag) == flag;
    }
};

pub const Sku = struct {
    id: Snowflake,
    type: SkuType,
    application_id: Snowflake,
    name: []const u8,
    slug: []const u8,
    flags: SkuFlags.Bit = 0,
};

pub const EntitlementType = enum(u8) {
    purchase = 1,
    premium_subscription = 2,
    developer_gift = 3,
    test_mode_purchase = 4,
    free_purchase = 5,
    user_gift = 6,
    premium_purchase = 7,
    application_subscription = 8,
};

pub const Entitlement = struct {
    id: Snowflake,
    sku_id: Snowflake,
    application_id: Snowflake,
    type: EntitlementType,
    deleted: bool,
    user_id: ?Snowflake = null,
    guild_id: ?Snowflake = null,
    starts_at: ?[]const u8 = null,
    ends_at: ?[]const u8 = null,
    consumed: ?bool = null,
};

pub const SubscriptionStatus = enum(u8) {
    active = 0,
    ending = 1,
    inactive = 2,
};

pub const Subscription = struct {
    id: Snowflake,
    user_id: Snowflake,
    sku_ids: []const Snowflake = &.{},
    entitlement_ids: []const Snowflake = &.{},
    renewal_sku_ids: []const Snowflake = &.{},
    current_period_start: []const u8,
    current_period_end: []const u8,
    status: SubscriptionStatus,
    canceled_at: ?[]const u8 = null,
    country: ?[]const u8 = null,
};

pub const ListEntitlements = struct {
    user_id: ?Snowflake = null,
    sku_ids: []const Snowflake = &.{},
    before: ?Snowflake = null,
    after: ?Snowflake = null,
    limit: ?u8 = null,
    guild_id: ?Snowflake = null,
    exclude_ended: ?bool = null,
    exclude_deleted: ?bool = null,

    pub fn init() ListEntitlements {
        return .{};
    }

    pub fn forUser(self: ListEntitlements, user_id: Snowflake) ListEntitlements {
        var options = self;
        options.user_id = user_id;
        return options;
    }

    pub fn withSkus(self: ListEntitlements, sku_ids: []const Snowflake) ListEntitlements {
        var options = self;
        options.sku_ids = sku_ids;
        return options;
    }

    pub fn beforeEntitlement(self: ListEntitlements, entitlement_id: Snowflake) ListEntitlements {
        var options = self;
        options.before = entitlement_id;
        return options;
    }

    pub fn afterEntitlement(self: ListEntitlements, entitlement_id: Snowflake) ListEntitlements {
        var options = self;
        options.after = entitlement_id;
        return options;
    }

    pub fn withLimit(self: ListEntitlements, limit: u8) ListEntitlements {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn forGuild(self: ListEntitlements, guild_id: Snowflake) ListEntitlements {
        var options = self;
        options.guild_id = guild_id;
        return options;
    }

    pub fn excludeEnded(self: ListEntitlements, exclude_ended: bool) ListEntitlements {
        var options = self;
        options.exclude_ended = exclude_ended;
        return options;
    }

    pub fn excludeDeleted(self: ListEntitlements, exclude_deleted: bool) ListEntitlements {
        var options = self;
        options.exclude_deleted = exclude_deleted;
        return options;
    }

    pub fn hasQuery(self: ListEntitlements) bool {
        return self.user_id != null or self.sku_ids.len != 0 or self.before != null or self.after != null or
            self.limit != null or self.guild_id != null or self.exclude_ended != null or self.exclude_deleted != null;
    }

    pub fn writeQuery(self: ListEntitlements, writer: anytype) !void {
        var needs_ampersand = false;

        if (self.user_id) |user_id| try writeSnowflakeQueryParam(writer, &needs_ampersand, "user_id", user_id);
        if (self.sku_ids.len != 0) {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.writeAll("sku_ids=");
            try writeSnowflakeCommaList(self.sku_ids, writer);
        }
        if (self.before) |before| try writeSnowflakeQueryParam(writer, &needs_ampersand, "before", before);
        if (self.after) |after| try writeSnowflakeQueryParam(writer, &needs_ampersand, "after", after);
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
        if (self.guild_id) |guild_id| try writeSnowflakeQueryParam(writer, &needs_ampersand, "guild_id", guild_id);
        try writeOptionalBoolQueryParam(writer, &needs_ampersand, "exclude_ended", self.exclude_ended);
        try writeOptionalBoolQueryParam(writer, &needs_ampersand, "exclude_deleted", self.exclude_deleted);
    }
};

pub const EntitlementOwnerType = enum(u8) {
    guild = 1,
    user = 2,
};

pub const CreateTestEntitlement = struct {
    sku_id: Snowflake,
    owner_id: Snowflake,
    owner_type: EntitlementOwnerType,

    pub fn init(sku_id: Snowflake, owner_id: Snowflake, owner_type: EntitlementOwnerType) CreateTestEntitlement {
        return .{ .sku_id = sku_id, .owner_id = owner_id, .owner_type = owner_type };
    }

    pub fn writeJson(self: CreateTestEntitlement, writer: anytype) !void {
        try writer.print(
            "{{\"sku_id\":\"{d}\",\"owner_id\":\"{d}\",\"owner_type\":{d}}}",
            .{ self.sku_id.value, self.owner_id.value, @intFromEnum(self.owner_type) },
        );
    }
};

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

pub const EditAutoModerationRule = struct {
    name: ?[]const u8 = null,
    event_type: ?AutoModerationRuleEventType = null,
    trigger_metadata: ?AutoModerationTriggerMetadata = null,
    actions: ?[]const AutoModerationAction = null,
    enabled: ?bool = null,
    exempt_roles: ?[]const Snowflake = null,
    exempt_channels: ?[]const Snowflake = null,

    pub fn init() EditAutoModerationRule {
        return .{};
    }

    pub fn withName(self: EditAutoModerationRule, name: []const u8) EditAutoModerationRule {
        var payload = self;
        payload.name = name;
        return payload;
    }

    pub fn withEventType(self: EditAutoModerationRule, event_type: AutoModerationRuleEventType) EditAutoModerationRule {
        var payload = self;
        payload.event_type = event_type;
        return payload;
    }

    pub fn withTriggerMetadata(self: EditAutoModerationRule, trigger_metadata: AutoModerationTriggerMetadata) EditAutoModerationRule {
        var payload = self;
        payload.trigger_metadata = trigger_metadata;
        return payload;
    }

    pub fn withActions(self: EditAutoModerationRule, actions: []const AutoModerationAction) EditAutoModerationRule {
        var payload = self;
        payload.actions = actions;
        return payload;
    }

    pub fn enabledState(self: EditAutoModerationRule, enabled: bool) EditAutoModerationRule {
        var payload = self;
        payload.enabled = enabled;
        return payload;
    }

    pub fn withExemptRoles(self: EditAutoModerationRule, exempt_roles: []const Snowflake) EditAutoModerationRule {
        var payload = self;
        payload.exempt_roles = exempt_roles;
        return payload;
    }

    pub fn withExemptChannels(self: EditAutoModerationRule, exempt_channels: []const Snowflake) EditAutoModerationRule {
        var payload = self;
        payload.exempt_channels = exempt_channels;
        return payload;
    }

    pub fn writeJson(self: EditAutoModerationRule, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "name", self.name);
        if (self.event_type) |event_type| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"event_type\":{d}", .{@intFromEnum(event_type)});
        }
        if (self.trigger_metadata) |metadata| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"trigger_metadata\":");
            try metadata.writeJson(writer);
        }
        if (self.actions) |actions| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"actions\":");
            try writeAutoModerationActionArray(actions, writer);
        }
        try writeOptionalBoolField(writer, &needs_comma, "enabled", self.enabled);
        if (self.exempt_roles) |roles| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"exempt_roles\":");
            try writeSnowflakeStringArray(roles, writer);
        }
        if (self.exempt_channels) |channels| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"exempt_channels\":");
            try writeSnowflakeStringArray(channels, writer);
        }

        try writer.writeByte('}');
    }
};

pub const Role = struct {
    id: Snowflake,
    name: []const u8,
    color: u24 = 0,
    colors: ?RoleColors = null,
    hoist: bool = false,
    icon: ?[]const u8 = null,
    unicode_emoji: ?[]const u8 = null,
    position: i32 = 0,
    permissions: Permissions.Bit = 0,
    managed: bool = false,
    mentionable: bool = false,
    tags: ?RoleTags = null,
    flags: ?u64 = null,

    pub fn toPermissionsRole(self: Role) Permissions.RolePermissions {
        return .{ .id = self.id.value, .permissions = self.permissions };
    }
};

pub const RoleColors = struct {
    primary_color: u24,
    secondary_color: ?u24 = null,
    tertiary_color: ?u24 = null,

    pub fn init(primary_color: u24) RoleColors {
        return .{ .primary_color = primary_color };
    }

    pub fn withSecondary(self: RoleColors, secondary_color: u24) RoleColors {
        var colors = self;
        colors.secondary_color = secondary_color;
        return colors;
    }

    pub fn withTertiary(self: RoleColors, tertiary_color: u24) RoleColors {
        var colors = self;
        colors.tertiary_color = tertiary_color;
        return colors;
    }

    pub fn writeJson(self: RoleColors, writer: anytype) !void {
        try writer.print("{{\"primary_color\":{d},\"secondary_color\":", .{self.primary_color});
        if (self.secondary_color) |color| {
            try writer.print("{d}", .{color});
        } else {
            try writer.writeAll("null");
        }
        try writer.writeAll(",\"tertiary_color\":");
        if (self.tertiary_color) |color| {
            try writer.print("{d}", .{color});
        } else {
            try writer.writeAll("null");
        }
        try writer.writeByte('}');
    }
};

pub const RoleTags = struct {
    bot_id: ?Snowflake = null,
    integration_id: ?Snowflake = null,
    premium_subscriber: bool = false,
    subscription_listing_id: ?Snowflake = null,
    available_for_purchase: bool = false,
    guild_connections: bool = false,
};

pub const Emoji = struct {
    id: ?Snowflake = null,
    name: ?[]const u8 = null,
    roles: []const Snowflake = &.{},
    user: ?User = null,
    require_colons: bool = false,
    managed: bool = false,
    animated: bool = false,
    available: bool = true,
};

pub const StickerType = enum(u8) {
    standard = 1,
    guild = 2,
};

pub const StickerFormatType = enum(u8) {
    png = 1,
    apng = 2,
    lottie = 3,
    gif = 4,
};

pub const Sticker = struct {
    id: Snowflake,
    pack_id: ?Snowflake = null,
    name: []const u8,
    description: ?[]const u8 = null,
    tags: []const u8,
    type: StickerType,
    format_type: StickerFormatType,
    available: bool = true,
    guild_id: ?Snowflake = null,
    user: ?User = null,
    sort_value: ?u32 = null,
};

pub const MessageStickerItem = struct {
    id: Snowflake,
    name: []const u8,
    format_type: StickerFormatType,
};

pub const SoundboardSound = struct {
    sound_id: Snowflake,
    name: []const u8,
    volume: f64,
    emoji_id: ?Snowflake = null,
    emoji_name: ?[]const u8 = null,
    guild_id: ?Snowflake = null,
    available: bool = true,
    user: ?User = null,
};

pub const Channel = struct {
    id: Snowflake,
    type: ChannelType,
    guild_id: ?Snowflake = null,
    name: ?[]const u8 = null,
    topic: ?[]const u8 = null,
    status: ?[]const u8 = null,
    voice_start_time: ?i64 = null,
    last_message_id: ?Snowflake = null,
    last_pin_timestamp: ?[]const u8 = null,
    parent_id: ?Snowflake = null,
    owner_id: ?Snowflake = null,
    application_id: ?Snowflake = null,
    position: ?i32 = null,
    nsfw: bool = false,
    rate_limit_per_user: ?u16 = null,
    bitrate: ?u32 = null,
    user_limit: ?u16 = null,
    rtc_region: ?[]const u8 = null,
    video_quality_mode: ?u8 = null,
    message_count: ?u32 = null,
    member_count: ?u32 = null,
    managed: bool = false,
    flags: ?ChannelFlags.Bit = null,
    permission_overwrites: []const PermissionOverwrite = &.{},
    thread_metadata: ?ThreadMetadata = null,
    applied_tags: []const Snowflake = &.{},
    available_tags: []const ForumTag = &.{},
    default_reaction_emoji: ?DefaultReactionEmoji = null,
    default_thread_rate_limit_per_user: ?u16 = null,
    default_sort_order: ?ChannelSortOrder = null,
    default_forum_layout: ?ForumLayout = null,
};

pub const ThreadMetadata = struct {
    archived: bool = false,
    auto_archive_duration: u16 = 0,
    archive_timestamp: ?[]const u8 = null,
    locked: bool = false,
    invitable: ?bool = null,
    create_timestamp: ?[]const u8 = null,
};

pub const ForumTag = struct {
    id: Snowflake,
    name: []const u8,
    moderated: bool = false,
    emoji_id: ?Snowflake = null,
    emoji_name: ?[]const u8 = null,
};

pub const DefaultReactionEmoji = struct {
    emoji_id: ?Snowflake = null,
    emoji_name: ?[]const u8 = null,

    pub fn id(emoji_id: Snowflake) DefaultReactionEmoji {
        return .{ .emoji_id = emoji_id };
    }

    pub fn name(emoji_name: []const u8) DefaultReactionEmoji {
        return .{ .emoji_name = emoji_name };
    }

    pub fn writeJson(self: DefaultReactionEmoji, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        if (self.emoji_id) |emoji_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"emoji_id\":\"{d}\"", .{emoji_id.value});
        }
        try writeOptionalStringField(writer, &needs_comma, "emoji_name", self.emoji_name);
        try writer.writeByte('}');
    }
};

pub const ChannelFlags = struct {
    pub const Bit = u32;

    pub const pinned: Bit = 1 << 1;
    pub const require_tag: Bit = 1 << 4;
    pub const hide_media_download_options: Bit = 1 << 15;
};

pub const ChannelSortOrder = enum(u8) {
    latest_activity = 0,
    creation_date = 1,
};

pub const ForumLayout = enum(u8) {
    unset = 0,
    list_view = 1,
    gallery_view = 2,
};

pub const WriteForumTag = struct {
    id: ?Snowflake = null,
    name: []const u8,
    moderated: bool = false,
    emoji_id: ?Snowflake = null,
    clear_emoji_id: bool = false,
    emoji_name: ?[]const u8 = null,
    clear_emoji_name: bool = false,

    pub fn init(name: []const u8) WriteForumTag {
        return .{ .name = name };
    }

    pub fn withId(self: WriteForumTag, id: Snowflake) WriteForumTag {
        var tag = self;
        tag.id = id;
        return tag;
    }

    pub fn moderatedState(self: WriteForumTag, moderated: bool) WriteForumTag {
        var tag = self;
        tag.moderated = moderated;
        return tag;
    }

    pub fn withEmojiId(self: WriteForumTag, emoji_id: Snowflake) WriteForumTag {
        var tag = self;
        tag.emoji_id = emoji_id;
        tag.clear_emoji_id = false;
        return tag;
    }

    pub fn clearEmojiId(self: WriteForumTag) WriteForumTag {
        var tag = self;
        tag.emoji_id = null;
        tag.clear_emoji_id = true;
        return tag;
    }

    pub fn withEmojiName(self: WriteForumTag, emoji_name: []const u8) WriteForumTag {
        var tag = self;
        tag.emoji_name = emoji_name;
        tag.clear_emoji_name = false;
        return tag;
    }

    pub fn clearEmojiName(self: WriteForumTag) WriteForumTag {
        var tag = self;
        tag.emoji_name = null;
        tag.clear_emoji_name = true;
        return tag;
    }

    pub fn writeJson(self: WriteForumTag, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        if (self.id) |id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"id\":\"{d}\"", .{id.value});
        }
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);
        if (self.moderated) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"moderated\":true");
        }
        try writeNullableSnowflakeField(writer, &needs_comma, "emoji_id", self.emoji_id, self.clear_emoji_id);
        try writeNullableStringField(writer, &needs_comma, "emoji_name", self.emoji_name, self.clear_emoji_name);
        try writer.writeByte('}');
    }
};

pub const PermissionOverwriteType = enum(u8) {
    role = 0,
    member = 1,
};

pub const PermissionOverwrite = struct {
    id: Snowflake,
    type: PermissionOverwriteType,
    allow: Permissions.Bit = 0,
    deny: Permissions.Bit = 0,

    pub fn toPermissionsOverwrite(self: PermissionOverwrite) Permissions.Overwrite {
        return .{
            .id = self.id.value,
            .type = switch (self.type) {
                .role => .role,
                .member => .member,
            },
            .allow = self.allow,
            .deny = self.deny,
        };
    }
};

pub const ChannelType = enum(u8) {
    guild_text = 0,
    dm = 1,
    guild_voice = 2,
    group_dm = 3,
    guild_category = 4,
    guild_announcement = 5,
    announcement_thread = 10,
    public_thread = 11,
    private_thread = 12,
    guild_stage_voice = 13,
    guild_directory = 14,
    guild_forum = 15,
    guild_media = 16,

    /// Whether this is a thread channel (announcement/public/private thread).
    pub fn isThread(self: ChannelType) bool {
        return switch (self) {
            .announcement_thread, .public_thread, .private_thread => true,
            else => false,
        };
    }

    /// Whether this is a voice-based channel (guild voice or stage).
    pub fn isVoiceBased(self: ChannelType) bool {
        return switch (self) {
            .guild_voice, .guild_stage_voice => true,
            else => false,
        };
    }

    /// Whether messages can be sent in this channel. Matches Discord.js:
    /// text, DM, group DM, announcement, threads, and voice channels (which
    /// carry text chat) are message-capable; categories, directories, forum,
    /// and media channels are not.
    pub fn isTextBased(self: ChannelType) bool {
        return switch (self) {
            .guild_text,
            .dm,
            .group_dm,
            .guild_announcement,
            .announcement_thread,
            .public_thread,
            .private_thread,
            .guild_voice,
            .guild_stage_voice,
            => true,
            else => false,
        };
    }

    /// Whether this is a DM or group DM channel.
    pub fn isDMBased(self: ChannelType) bool {
        return switch (self) {
            .dm, .group_dm => true,
            else => false,
        };
    }

    /// Whether this channel only contains threads (forum and media channels).
    pub fn isThreadOnly(self: ChannelType) bool {
        return switch (self) {
            .guild_forum, .guild_media => true,
            else => false,
        };
    }

    /// Whether this channel belongs to a guild (everything except DM channels).
    pub fn isGuildBased(self: ChannelType) bool {
        return switch (self) {
            .dm, .group_dm => false,
            else => true,
        };
    }
};

pub const CreateGuildChannel = struct {
    name: []const u8,
    type: ?ChannelType = null,
    topic: ?[]const u8 = null,
    nsfw: bool = false,
    rate_limit_per_user: ?u16 = null,
    bitrate: ?u32 = null,
    user_limit: ?u16 = null,
    flags: ?ChannelFlags.Bit = null,
    parent_id: ?Snowflake = null,
    position: ?i32 = null,
    available_tags: ?[]const WriteForumTag = null,
    default_reaction_emoji: ?DefaultReactionEmoji = null,
    default_thread_rate_limit_per_user: ?u16 = null,
    default_sort_order: ?ChannelSortOrder = null,
    default_forum_layout: ?ForumLayout = null,

    pub fn init(name: []const u8) CreateGuildChannel {
        return .{ .name = name };
    }

    pub fn withType(self: CreateGuildChannel, channel_type: ChannelType) CreateGuildChannel {
        var payload = self;
        payload.type = channel_type;
        return payload;
    }

    pub fn withTopic(self: CreateGuildChannel, topic: []const u8) CreateGuildChannel {
        var payload = self;
        payload.topic = topic;
        return payload;
    }

    pub fn nsfwState(self: CreateGuildChannel, nsfw: bool) CreateGuildChannel {
        var payload = self;
        payload.nsfw = nsfw;
        return payload;
    }

    pub fn withRateLimit(self: CreateGuildChannel, seconds: u16) CreateGuildChannel {
        var payload = self;
        payload.rate_limit_per_user = seconds;
        return payload;
    }

    pub fn withBitrate(self: CreateGuildChannel, bitrate: u32) CreateGuildChannel {
        var payload = self;
        payload.bitrate = bitrate;
        return payload;
    }

    pub fn withUserLimit(self: CreateGuildChannel, user_limit: u16) CreateGuildChannel {
        var payload = self;
        payload.user_limit = user_limit;
        return payload;
    }

    pub fn withFlags(self: CreateGuildChannel, flags: ChannelFlags.Bit) CreateGuildChannel {
        var payload = self;
        payload.flags = flags;
        return payload;
    }

    pub fn withParent(self: CreateGuildChannel, parent_id: Snowflake) CreateGuildChannel {
        var payload = self;
        payload.parent_id = parent_id;
        return payload;
    }

    pub fn withPosition(self: CreateGuildChannel, position: i32) CreateGuildChannel {
        var payload = self;
        payload.position = position;
        return payload;
    }

    pub fn withAvailableTags(self: CreateGuildChannel, tags: []const WriteForumTag) CreateGuildChannel {
        var payload = self;
        payload.available_tags = tags;
        return payload;
    }

    pub fn withDefaultReactionEmoji(self: CreateGuildChannel, emoji: DefaultReactionEmoji) CreateGuildChannel {
        var payload = self;
        payload.default_reaction_emoji = emoji;
        return payload;
    }

    pub fn withDefaultThreadRateLimit(self: CreateGuildChannel, seconds: u16) CreateGuildChannel {
        var payload = self;
        payload.default_thread_rate_limit_per_user = seconds;
        return payload;
    }

    pub fn withDefaultSortOrder(self: CreateGuildChannel, sort_order: ChannelSortOrder) CreateGuildChannel {
        var payload = self;
        payload.default_sort_order = sort_order;
        return payload;
    }

    pub fn withDefaultForumLayout(self: CreateGuildChannel, layout: ForumLayout) CreateGuildChannel {
        var payload = self;
        payload.default_forum_layout = layout;
        return payload;
    }

    pub fn writeJson(self: CreateGuildChannel, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);

        try writeChannelFields(.{
            .type = self.type,
            .topic = self.topic,
            .nsfw = self.nsfw,
            .rate_limit_per_user = self.rate_limit_per_user,
            .bitrate = self.bitrate,
            .user_limit = self.user_limit,
            .flags = self.flags,
            .parent_id = self.parent_id,
            .position = self.position,
            .available_tags = self.available_tags,
            .default_reaction_emoji = self.default_reaction_emoji,
            .default_thread_rate_limit_per_user = self.default_thread_rate_limit_per_user,
            .default_sort_order = self.default_sort_order,
            .default_forum_layout = self.default_forum_layout,
        }, writer, &needs_comma);

        try writer.writeByte('}');
    }
};

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

pub const EditCurrentUserVoiceState = struct {
    channel_id: ?Snowflake = null,
    suppress: ?bool = null,
    request_to_speak_timestamp: ?[]const u8 = null,
    clear_request_to_speak_timestamp: bool = false,

    pub fn init() EditCurrentUserVoiceState {
        return .{};
    }

    pub fn withChannel(self: EditCurrentUserVoiceState, channel_id: Snowflake) EditCurrentUserVoiceState {
        var payload = self;
        payload.channel_id = channel_id;
        return payload;
    }

    pub fn suppressState(self: EditCurrentUserVoiceState, suppress: bool) EditCurrentUserVoiceState {
        var payload = self;
        payload.suppress = suppress;
        return payload;
    }

    pub fn requestToSpeakAt(self: EditCurrentUserVoiceState, timestamp: []const u8) EditCurrentUserVoiceState {
        var payload = self;
        payload.request_to_speak_timestamp = timestamp;
        payload.clear_request_to_speak_timestamp = false;
        return payload;
    }

    pub fn clearRequestToSpeak(self: EditCurrentUserVoiceState) EditCurrentUserVoiceState {
        var payload = self;
        payload.request_to_speak_timestamp = null;
        payload.clear_request_to_speak_timestamp = true;
        return payload;
    }

    pub fn writeJson(self: EditCurrentUserVoiceState, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        if (self.channel_id) |channel_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"channel_id\":\"{d}\"", .{channel_id.value});
        }
        try writeOptionalBoolField(writer, &needs_comma, "suppress", self.suppress);
        if (self.clear_request_to_speak_timestamp) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"request_to_speak_timestamp\":null");
        } else {
            try writeOptionalStringField(
                writer,
                &needs_comma,
                "request_to_speak_timestamp",
                self.request_to_speak_timestamp,
            );
        }

        try writer.writeByte('}');
    }
};

pub const EditUserVoiceState = struct {
    channel_id: ?Snowflake = null,
    suppress: ?bool = null,

    pub fn init() EditUserVoiceState {
        return .{};
    }

    pub fn withChannel(self: EditUserVoiceState, channel_id: Snowflake) EditUserVoiceState {
        var payload = self;
        payload.channel_id = channel_id;
        return payload;
    }

    pub fn suppressState(self: EditUserVoiceState, suppress: bool) EditUserVoiceState {
        var payload = self;
        payload.suppress = suppress;
        return payload;
    }

    pub fn writeJson(self: EditUserVoiceState, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        if (self.channel_id) |channel_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"channel_id\":\"{d}\"", .{channel_id.value});
        }
        try writeOptionalBoolField(writer, &needs_comma, "suppress", self.suppress);

        try writer.writeByte('}');
    }
};

pub const EditCurrentApplication = struct {
    custom_install_url: ?[]const u8 = null,
    description: ?[]const u8 = null,
    role_connections_verification_url: ?[]const u8 = null,
    install_params: ?ApplicationInstallParams = null,
    flags: ?u32 = null,
    icon: ?[]const u8 = null,
    clear_icon: bool = false,
    cover_image: ?[]const u8 = null,
    clear_cover_image: bool = false,
    interactions_endpoint_url: ?[]const u8 = null,
    tags: ?[]const []const u8 = null,
    event_webhooks_url: ?[]const u8 = null,
    event_webhooks_status: ?ApplicationEventWebhookStatus = null,
    event_webhooks_types: ?[]const []const u8 = null,

    pub fn init() EditCurrentApplication {
        return .{};
    }

    pub fn withCustomInstallUrl(self: EditCurrentApplication, custom_install_url: []const u8) EditCurrentApplication {
        var payload = self;
        payload.custom_install_url = custom_install_url;
        return payload;
    }

    pub fn withDescription(self: EditCurrentApplication, description: []const u8) EditCurrentApplication {
        var payload = self;
        payload.description = description;
        return payload;
    }

    pub fn withRoleConnectionsVerificationUrl(self: EditCurrentApplication, role_connections_verification_url: []const u8) EditCurrentApplication {
        var payload = self;
        payload.role_connections_verification_url = role_connections_verification_url;
        return payload;
    }

    pub fn withInstallParams(self: EditCurrentApplication, install_params: ApplicationInstallParams) EditCurrentApplication {
        var payload = self;
        payload.install_params = install_params;
        return payload;
    }

    pub fn withFlags(self: EditCurrentApplication, flags: u32) EditCurrentApplication {
        var payload = self;
        payload.flags = flags;
        return payload;
    }

    pub fn withIcon(self: EditCurrentApplication, icon: []const u8) EditCurrentApplication {
        var payload = self;
        payload.icon = icon;
        payload.clear_icon = false;
        return payload;
    }

    pub fn clearIcon(self: EditCurrentApplication) EditCurrentApplication {
        var payload = self;
        payload.icon = null;
        payload.clear_icon = true;
        return payload;
    }

    pub fn withCoverImage(self: EditCurrentApplication, cover_image: []const u8) EditCurrentApplication {
        var payload = self;
        payload.cover_image = cover_image;
        payload.clear_cover_image = false;
        return payload;
    }

    pub fn clearCoverImage(self: EditCurrentApplication) EditCurrentApplication {
        var payload = self;
        payload.cover_image = null;
        payload.clear_cover_image = true;
        return payload;
    }

    pub fn withInteractionsEndpointUrl(self: EditCurrentApplication, interactions_endpoint_url: []const u8) EditCurrentApplication {
        var payload = self;
        payload.interactions_endpoint_url = interactions_endpoint_url;
        return payload;
    }

    pub fn withTags(self: EditCurrentApplication, tags: []const []const u8) EditCurrentApplication {
        var payload = self;
        payload.tags = tags;
        return payload;
    }

    pub fn withEventWebhooksUrl(self: EditCurrentApplication, event_webhooks_url: []const u8) EditCurrentApplication {
        var payload = self;
        payload.event_webhooks_url = event_webhooks_url;
        return payload;
    }

    pub fn withEventWebhooksStatus(self: EditCurrentApplication, event_webhooks_status: ApplicationEventWebhookStatus) EditCurrentApplication {
        var payload = self;
        payload.event_webhooks_status = event_webhooks_status;
        return payload;
    }

    pub fn withEventWebhookTypes(self: EditCurrentApplication, event_webhooks_types: []const []const u8) EditCurrentApplication {
        var payload = self;
        payload.event_webhooks_types = event_webhooks_types;
        return payload;
    }

    pub fn writeJson(self: EditCurrentApplication, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "custom_install_url", self.custom_install_url);
        try writeOptionalStringField(writer, &needs_comma, "description", self.description);
        try writeOptionalStringField(
            writer,
            &needs_comma,
            "role_connections_verification_url",
            self.role_connections_verification_url,
        );
        if (self.install_params) |install_params| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"install_params\":");
            try install_params.writeJson(writer);
        }
        if (self.flags) |flags| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"flags\":{d}", .{flags});
        }
        if (self.clear_icon) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"icon\":null");
        } else {
            try writeOptionalStringField(writer, &needs_comma, "icon", self.icon);
        }
        if (self.clear_cover_image) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"cover_image\":null");
        } else {
            try writeOptionalStringField(writer, &needs_comma, "cover_image", self.cover_image);
        }
        try writeOptionalStringField(writer, &needs_comma, "interactions_endpoint_url", self.interactions_endpoint_url);
        if (self.tags) |tags| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"tags\":");
            try writeStringArray(tags, writer);
        }
        try writeOptionalStringField(writer, &needs_comma, "event_webhooks_url", self.event_webhooks_url);
        if (self.event_webhooks_status) |status| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"event_webhooks_status\":{d}", .{@intFromEnum(status)});
        }
        if (self.event_webhooks_types) |event_types| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"event_webhooks_types\":");
            try writeStringArray(event_types, writer);
        }

        try writer.writeByte('}');
    }
};

pub const OAuth2TokenRequest = struct {
    grant_type: []const u8,
    code: ?[]const u8 = null,
    refresh_token: ?[]const u8 = null,
    redirect_uri: ?[]const u8 = null,
    client_id: ?[]const u8 = null,
    client_secret: ?[]const u8 = null,
    scope: ?[]const u8 = null,
    code_verifier: ?[]const u8 = null,

    pub fn init(grant_type: []const u8) OAuth2TokenRequest {
        return .{ .grant_type = grant_type };
    }

    pub fn authorizationCode(code: []const u8) OAuth2TokenRequest {
        return .{ .grant_type = "authorization_code", .code = code };
    }

    pub fn refreshToken(refresh_token: []const u8) OAuth2TokenRequest {
        return .{ .grant_type = "refresh_token", .refresh_token = refresh_token };
    }

    pub fn withCode(self: OAuth2TokenRequest, code: []const u8) OAuth2TokenRequest {
        var payload = self;
        payload.code = code;
        return payload;
    }

    pub fn withRefreshToken(self: OAuth2TokenRequest, refresh_token: []const u8) OAuth2TokenRequest {
        var payload = self;
        payload.refresh_token = refresh_token;
        return payload;
    }

    pub fn withRedirectUri(self: OAuth2TokenRequest, redirect_uri: []const u8) OAuth2TokenRequest {
        var payload = self;
        payload.redirect_uri = redirect_uri;
        return payload;
    }

    pub fn withClientId(self: OAuth2TokenRequest, client_id: []const u8) OAuth2TokenRequest {
        var payload = self;
        payload.client_id = client_id;
        return payload;
    }

    pub fn withClientSecret(self: OAuth2TokenRequest, client_secret: []const u8) OAuth2TokenRequest {
        var payload = self;
        payload.client_secret = client_secret;
        return payload;
    }

    pub fn withScope(self: OAuth2TokenRequest, scope: []const u8) OAuth2TokenRequest {
        var payload = self;
        payload.scope = scope;
        return payload;
    }

    pub fn withCodeVerifier(self: OAuth2TokenRequest, code_verifier: []const u8) OAuth2TokenRequest {
        var payload = self;
        payload.code_verifier = code_verifier;
        return payload;
    }

    pub fn writeForm(self: OAuth2TokenRequest, writer: anytype) !void {
        var needs_ampersand = false;
        try writeStringQueryParam(writer, &needs_ampersand, "grant_type", self.grant_type);
        try writeOptionalStringQueryParam(writer, &needs_ampersand, "code", self.code);
        try writeOptionalStringQueryParam(writer, &needs_ampersand, "refresh_token", self.refresh_token);
        try writeOptionalStringQueryParam(writer, &needs_ampersand, "redirect_uri", self.redirect_uri);
        try writeOptionalStringQueryParam(writer, &needs_ampersand, "client_id", self.client_id);
        try writeOptionalStringQueryParam(writer, &needs_ampersand, "client_secret", self.client_secret);
        try writeOptionalStringQueryParam(writer, &needs_ampersand, "scope", self.scope);
        try writeOptionalStringQueryParam(writer, &needs_ampersand, "code_verifier", self.code_verifier);
    }
};

pub const OAuth2TokenRevocation = struct {
    token: []const u8,
    token_type_hint: ?[]const u8 = null,
    client_id: ?[]const u8 = null,
    client_secret: ?[]const u8 = null,

    pub fn init(token: []const u8) OAuth2TokenRevocation {
        return .{ .token = token };
    }

    pub fn withTokenTypeHint(self: OAuth2TokenRevocation, token_type_hint: []const u8) OAuth2TokenRevocation {
        var payload = self;
        payload.token_type_hint = token_type_hint;
        return payload;
    }

    pub fn withClientId(self: OAuth2TokenRevocation, client_id: []const u8) OAuth2TokenRevocation {
        var payload = self;
        payload.client_id = client_id;
        return payload;
    }

    pub fn withClientSecret(self: OAuth2TokenRevocation, client_secret: []const u8) OAuth2TokenRevocation {
        var payload = self;
        payload.client_secret = client_secret;
        return payload;
    }

    pub fn writeForm(self: OAuth2TokenRevocation, writer: anytype) !void {
        var needs_ampersand = false;
        try writeStringQueryParam(writer, &needs_ampersand, "token", self.token);
        try writeOptionalStringQueryParam(writer, &needs_ampersand, "token_type_hint", self.token_type_hint);
        try writeOptionalStringQueryParam(writer, &needs_ampersand, "client_id", self.client_id);
        try writeOptionalStringQueryParam(writer, &needs_ampersand, "client_secret", self.client_secret);
    }
};

/// Audit log entry action types, matching Discord.js `AuditLogEvent`. Use with
/// `ListAuditLog.withAuditEvent` to filter the audit log by action.
pub const AuditLogEvent = enum(u16) {
    guild_update = 1,
    channel_create = 10,
    channel_update = 11,
    channel_delete = 12,
    channel_overwrite_create = 13,
    channel_overwrite_update = 14,
    channel_overwrite_delete = 15,
    member_kick = 20,
    member_prune = 21,
    member_ban_add = 22,
    member_ban_remove = 23,
    member_update = 24,
    member_role_update = 25,
    member_move = 26,
    member_disconnect = 27,
    bot_add = 28,
    role_create = 30,
    role_update = 31,
    role_delete = 32,
    invite_create = 40,
    invite_update = 41,
    invite_delete = 42,
    webhook_create = 50,
    webhook_update = 51,
    webhook_delete = 52,
    emoji_create = 60,
    emoji_update = 61,
    emoji_delete = 62,
    message_delete = 72,
    message_bulk_delete = 73,
    message_pin = 74,
    message_unpin = 75,
    integration_create = 80,
    integration_update = 81,
    integration_delete = 82,
    stage_instance_create = 83,
    stage_instance_update = 84,
    stage_instance_delete = 85,
    sticker_create = 90,
    sticker_update = 91,
    sticker_delete = 92,
    guild_scheduled_event_create = 100,
    guild_scheduled_event_update = 101,
    guild_scheduled_event_delete = 102,
    thread_create = 110,
    thread_update = 111,
    thread_delete = 112,
    application_command_permission_update = 121,
    auto_moderation_rule_create = 140,
    auto_moderation_rule_update = 141,
    auto_moderation_rule_delete = 142,
    auto_moderation_block_message = 143,
    auto_moderation_flag_to_channel = 144,
    auto_moderation_user_communication_disabled = 145,
    creator_monetization_request_created = 150,
    creator_monetization_terms_accepted = 151,
    onboarding_prompt_create = 163,
    onboarding_prompt_update = 164,
    onboarding_prompt_delete = 165,
    onboarding_create = 166,
    onboarding_update = 167,
    home_settings_create = 190,
    home_settings_update = 191,
};

pub const ListAuditLog = struct {
    user_id: ?Snowflake = null,
    action_type: ?u16 = null,
    before: ?Snowflake = null,
    after: ?Snowflake = null,
    limit: ?u8 = null,

    pub fn init() ListAuditLog {
        return .{};
    }

    pub fn forUser(self: ListAuditLog, user_id: Snowflake) ListAuditLog {
        var options = self;
        options.user_id = user_id;
        return options;
    }

    pub fn withActionType(self: ListAuditLog, action_type: u16) ListAuditLog {
        var options = self;
        options.action_type = action_type;
        return options;
    }

    pub fn withAuditEvent(self: ListAuditLog, event: AuditLogEvent) ListAuditLog {
        var options = self;
        options.action_type = @intFromEnum(event);
        return options;
    }

    pub fn beforeEntry(self: ListAuditLog, entry_id: Snowflake) ListAuditLog {
        var options = self;
        options.before = entry_id;
        return options;
    }

    pub fn afterEntry(self: ListAuditLog, entry_id: Snowflake) ListAuditLog {
        var options = self;
        options.after = entry_id;
        return options;
    }

    pub fn withLimit(self: ListAuditLog, limit: u8) ListAuditLog {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn hasQuery(self: ListAuditLog) bool {
        return self.user_id != null or
            self.action_type != null or
            self.before != null or
            self.after != null or
            self.limit != null;
    }

    pub fn writeQuery(self: ListAuditLog, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.user_id) |user_id| try writeSnowflakeQueryParam(writer, &needs_ampersand, "user_id", user_id);
        if (self.action_type) |action_type| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("action_type={d}", .{action_type});
        }
        if (self.before) |before| try writeSnowflakeQueryParam(writer, &needs_ampersand, "before", before);
        if (self.after) |after| try writeSnowflakeQueryParam(writer, &needs_ampersand, "after", after);
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
    }
};

pub const ListCurrentUserGuilds = struct {
    before: ?Snowflake = null,
    after: ?Snowflake = null,
    limit: ?u8 = null,
    with_counts: ?bool = null,

    pub fn init() ListCurrentUserGuilds {
        return .{};
    }

    pub fn beforeGuild(self: ListCurrentUserGuilds, guild_id: Snowflake) ListCurrentUserGuilds {
        var options = self;
        options.before = guild_id;
        return options;
    }

    pub fn afterGuild(self: ListCurrentUserGuilds, guild_id: Snowflake) ListCurrentUserGuilds {
        var options = self;
        options.after = guild_id;
        return options;
    }

    pub fn withLimit(self: ListCurrentUserGuilds, limit: u8) ListCurrentUserGuilds {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn withCounts(self: ListCurrentUserGuilds, with_counts: bool) ListCurrentUserGuilds {
        var options = self;
        options.with_counts = with_counts;
        return options;
    }

    pub fn hasQuery(self: ListCurrentUserGuilds) bool {
        return self.before != null or
            self.after != null or
            self.limit != null or
            self.with_counts != null;
    }

    pub fn writeQuery(self: ListCurrentUserGuilds, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.before) |before| try writeSnowflakeQueryParam(writer, &needs_ampersand, "before", before);
        if (self.after) |after| try writeSnowflakeQueryParam(writer, &needs_ampersand, "after", after);
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
        if (self.with_counts) |with_counts| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.writeAll("with_counts=");
            try writer.writeAll(if (with_counts) "true" else "false");
        }
    }
};

pub const GetGuild = struct {
    with_counts: ?bool = null,

    pub fn init() GetGuild {
        return .{};
    }

    pub fn withCounts(self: GetGuild, with_counts: bool) GetGuild {
        var options = self;
        options.with_counts = with_counts;
        return options;
    }

    pub fn hasQuery(self: GetGuild) bool {
        return self.with_counts != null;
    }

    pub fn writeQuery(self: GetGuild, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.with_counts) |with_counts| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.writeAll("with_counts=");
            try writer.writeAll(if (with_counts) "true" else "false");
        }
    }
};

pub const ListGuildBans = struct {
    before: ?Snowflake = null,
    after: ?Snowflake = null,
    limit: ?u16 = null,

    pub fn init() ListGuildBans {
        return .{};
    }

    pub fn beforeUser(self: ListGuildBans, user_id: Snowflake) ListGuildBans {
        var options = self;
        options.before = user_id;
        return options;
    }

    pub fn afterUser(self: ListGuildBans, user_id: Snowflake) ListGuildBans {
        var options = self;
        options.after = user_id;
        return options;
    }

    pub fn withLimit(self: ListGuildBans, limit: u16) ListGuildBans {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn hasQuery(self: ListGuildBans) bool {
        return self.before != null or self.after != null or self.limit != null;
    }

    pub fn writeQuery(self: ListGuildBans, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.before) |before| try writeSnowflakeQueryParam(writer, &needs_ampersand, "before", before);
        if (self.after) |after| try writeSnowflakeQueryParam(writer, &needs_ampersand, "after", after);
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
    }
};

pub const ListGuildMembers = struct {
    limit: ?u16 = null,
    after: ?Snowflake = null,

    pub fn init() ListGuildMembers {
        return .{};
    }

    pub fn withLimit(self: ListGuildMembers, limit: u16) ListGuildMembers {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn afterMember(self: ListGuildMembers, user_id: Snowflake) ListGuildMembers {
        var options = self;
        options.after = user_id;
        return options;
    }

    pub fn hasQuery(self: ListGuildMembers) bool {
        return self.limit != null or self.after != null;
    }

    pub fn writeQuery(self: ListGuildMembers, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
        if (self.after) |after| try writeSnowflakeQueryParam(writer, &needs_ampersand, "after", after);
    }
};

pub const GetGuildPruneCount = struct {
    days: ?u8 = null,
    include_roles: []const Snowflake = &.{},

    pub fn init() GetGuildPruneCount {
        return .{};
    }

    pub fn withDays(self: GetGuildPruneCount, days: u8) GetGuildPruneCount {
        var options = self;
        options.days = days;
        return options;
    }

    pub fn withRoles(self: GetGuildPruneCount, include_roles: []const Snowflake) GetGuildPruneCount {
        var options = self;
        options.include_roles = include_roles;
        return options;
    }

    pub fn hasQuery(self: GetGuildPruneCount) bool {
        return self.days != null or self.include_roles.len != 0;
    }

    pub fn writeQuery(self: GetGuildPruneCount, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.days) |days| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("days={d}", .{days});
        }
        if (self.include_roles.len != 0) {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.writeAll("include_roles=");
            try writeSnowflakeCommaList(self.include_roles, writer);
        }
    }
};

pub const BeginGuildPrune = struct {
    days: ?u8 = null,
    compute_prune_count: ?bool = null,
    include_roles: []const Snowflake = &.{},

    pub fn init() BeginGuildPrune {
        return .{};
    }

    pub fn withDays(self: BeginGuildPrune, days: u8) BeginGuildPrune {
        var payload = self;
        payload.days = days;
        return payload;
    }

    pub fn computeCount(self: BeginGuildPrune, compute_prune_count: bool) BeginGuildPrune {
        var payload = self;
        payload.compute_prune_count = compute_prune_count;
        return payload;
    }

    pub fn withRoles(self: BeginGuildPrune, include_roles: []const Snowflake) BeginGuildPrune {
        var payload = self;
        payload.include_roles = include_roles;
        return payload;
    }

    pub fn writeJson(self: BeginGuildPrune, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        if (self.days) |days| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"days\":{d}", .{days});
        }
        try writeOptionalBoolField(writer, &needs_comma, "compute_prune_count", self.compute_prune_count);
        if (self.include_roles.len != 0) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"include_roles\":");
            try writeSnowflakeStringArray(self.include_roles, writer);
        }
        try writer.writeByte('}');
    }
};

pub const SearchGuildMembers = struct {
    query: []const u8,
    limit: ?u16 = null,

    pub fn init(query: []const u8) SearchGuildMembers {
        return .{ .query = query };
    }

    pub fn withLimit(self: SearchGuildMembers, limit: u16) SearchGuildMembers {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn writeQuery(self: SearchGuildMembers, writer: anytype) !void {
        var needs_ampersand = false;
        try writeQuerySeparator(writer, &needs_ampersand);
        try writer.writeAll("query=");
        try writeQueryStringValue(self.query, writer);
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
    }
};

pub const EditChannel = struct {
    name: ?[]const u8 = null,
    type: ?ChannelType = null,
    topic: ?[]const u8 = null,
    nsfw: bool = false,
    rate_limit_per_user: ?u16 = null,
    bitrate: ?u32 = null,
    user_limit: ?u16 = null,
    flags: ?ChannelFlags.Bit = null,
    parent_id: ?Snowflake = null,
    position: ?i32 = null,
    archived: ?bool = null,
    auto_archive_duration: ?u16 = null,
    locked: ?bool = null,
    invitable: ?bool = null,
    applied_tags: ?[]const Snowflake = null,
    available_tags: ?[]const WriteForumTag = null,
    default_reaction_emoji: ?DefaultReactionEmoji = null,
    default_thread_rate_limit_per_user: ?u16 = null,
    default_sort_order: ?ChannelSortOrder = null,
    default_forum_layout: ?ForumLayout = null,

    pub fn init() EditChannel {
        return .{};
    }

    pub fn withName(self: EditChannel, name: []const u8) EditChannel {
        var payload = self;
        payload.name = name;
        return payload;
    }

    pub fn withType(self: EditChannel, channel_type: ChannelType) EditChannel {
        var payload = self;
        payload.type = channel_type;
        return payload;
    }

    pub fn withTopic(self: EditChannel, topic: []const u8) EditChannel {
        var payload = self;
        payload.topic = topic;
        return payload;
    }

    pub fn nsfwState(self: EditChannel, nsfw: bool) EditChannel {
        var payload = self;
        payload.nsfw = nsfw;
        return payload;
    }

    pub fn withRateLimit(self: EditChannel, seconds: u16) EditChannel {
        var payload = self;
        payload.rate_limit_per_user = seconds;
        return payload;
    }

    pub fn withBitrate(self: EditChannel, bitrate: u32) EditChannel {
        var payload = self;
        payload.bitrate = bitrate;
        return payload;
    }

    pub fn withUserLimit(self: EditChannel, user_limit: u16) EditChannel {
        var payload = self;
        payload.user_limit = user_limit;
        return payload;
    }

    pub fn withFlags(self: EditChannel, flags: ChannelFlags.Bit) EditChannel {
        var payload = self;
        payload.flags = flags;
        return payload;
    }

    pub fn withParent(self: EditChannel, parent_id: Snowflake) EditChannel {
        var payload = self;
        payload.parent_id = parent_id;
        return payload;
    }

    pub fn withPosition(self: EditChannel, position: i32) EditChannel {
        var payload = self;
        payload.position = position;
        return payload;
    }

    pub fn archivedState(self: EditChannel, archived: bool) EditChannel {
        var payload = self;
        payload.archived = archived;
        return payload;
    }

    pub fn withAutoArchiveDuration(self: EditChannel, minutes: u16) EditChannel {
        var payload = self;
        payload.auto_archive_duration = minutes;
        return payload;
    }

    pub fn lockedState(self: EditChannel, locked: bool) EditChannel {
        var payload = self;
        payload.locked = locked;
        return payload;
    }

    pub fn invitableState(self: EditChannel, invitable: bool) EditChannel {
        var payload = self;
        payload.invitable = invitable;
        return payload;
    }

    pub fn withAppliedTags(self: EditChannel, tags: []const Snowflake) EditChannel {
        var payload = self;
        payload.applied_tags = tags;
        return payload;
    }

    pub fn clearAppliedTags(self: EditChannel) EditChannel {
        var payload = self;
        payload.applied_tags = &.{};
        return payload;
    }

    pub fn withAvailableTags(self: EditChannel, tags: []const WriteForumTag) EditChannel {
        var payload = self;
        payload.available_tags = tags;
        return payload;
    }

    pub fn clearAvailableTags(self: EditChannel) EditChannel {
        var payload = self;
        payload.available_tags = &.{};
        return payload;
    }

    pub fn withDefaultReactionEmoji(self: EditChannel, emoji: DefaultReactionEmoji) EditChannel {
        var payload = self;
        payload.default_reaction_emoji = emoji;
        return payload;
    }

    pub fn withDefaultThreadRateLimit(self: EditChannel, seconds: u16) EditChannel {
        var payload = self;
        payload.default_thread_rate_limit_per_user = seconds;
        return payload;
    }

    pub fn withDefaultSortOrder(self: EditChannel, sort_order: ChannelSortOrder) EditChannel {
        var payload = self;
        payload.default_sort_order = sort_order;
        return payload;
    }

    pub fn withDefaultForumLayout(self: EditChannel, layout: ForumLayout) EditChannel {
        var payload = self;
        payload.default_forum_layout = layout;
        return payload;
    }

    pub fn writeJson(self: EditChannel, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "name", self.name);
        try writeChannelFields(.{
            .type = self.type,
            .topic = self.topic,
            .nsfw = self.nsfw,
            .rate_limit_per_user = self.rate_limit_per_user,
            .bitrate = self.bitrate,
            .user_limit = self.user_limit,
            .flags = self.flags,
            .parent_id = self.parent_id,
            .position = self.position,
            .available_tags = self.available_tags,
            .default_reaction_emoji = self.default_reaction_emoji,
            .default_thread_rate_limit_per_user = self.default_thread_rate_limit_per_user,
            .default_sort_order = self.default_sort_order,
            .default_forum_layout = self.default_forum_layout,
        }, writer, &needs_comma);
        try writeThreadEditFields(.{
            .archived = self.archived,
            .auto_archive_duration = self.auto_archive_duration,
            .locked = self.locked,
            .invitable = self.invitable,
            .applied_tags = self.applied_tags,
        }, writer, &needs_comma);

        try writer.writeByte('}');
    }
};

pub const GuildChannelPosition = struct {
    id: Snowflake,
    position: ?i32 = null,
    lock_permissions: ?bool = null,
    parent_id: ?Snowflake = null,
    clear_parent_id: bool = false,

    pub fn init(id: Snowflake) GuildChannelPosition {
        return .{ .id = id };
    }

    pub fn withPosition(self: GuildChannelPosition, position: i32) GuildChannelPosition {
        var payload = self;
        payload.position = position;
        return payload;
    }

    pub fn lockPermissions(self: GuildChannelPosition, lock_permissions: bool) GuildChannelPosition {
        var payload = self;
        payload.lock_permissions = lock_permissions;
        return payload;
    }

    pub fn withParent(self: GuildChannelPosition, parent_id: Snowflake) GuildChannelPosition {
        var payload = self;
        payload.parent_id = parent_id;
        payload.clear_parent_id = false;
        return payload;
    }

    pub fn clearParent(self: GuildChannelPosition) GuildChannelPosition {
        var payload = self;
        payload.parent_id = null;
        payload.clear_parent_id = true;
        return payload;
    }

    pub fn writeJson(self: GuildChannelPosition, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.print("\"id\":\"{d}\"", .{self.id.value});
        try writeOptionalIntegerField(writer, &needs_comma, "position", self.position);
        try writeOptionalBoolField(writer, &needs_comma, "lock_permissions", self.lock_permissions);
        try writeNullableSnowflakeField(writer, &needs_comma, "parent_id", self.parent_id, self.clear_parent_id);

        try writer.writeByte('}');
    }
};

pub const EditChannelPermission = struct {
    type: PermissionOverwriteType,
    allow: ?Permissions.Bit = null,
    deny: ?Permissions.Bit = null,

    pub fn init(overwrite_type: PermissionOverwriteType) EditChannelPermission {
        return .{ .type = overwrite_type };
    }

    pub fn withAllow(self: EditChannelPermission, allow: Permissions.Bit) EditChannelPermission {
        var payload = self;
        payload.allow = allow;
        return payload;
    }

    pub fn withDeny(self: EditChannelPermission, deny: Permissions.Bit) EditChannelPermission {
        var payload = self;
        payload.deny = deny;
        return payload;
    }

    pub fn writeJson(self: EditChannelPermission, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.print("\"type\":{d}", .{@intFromEnum(self.type)});
        if (self.allow) |allow| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"allow\":\"{d}\"", .{allow});
        }
        if (self.deny) |deny| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"deny\":\"{d}\"", .{deny});
        }

        try writer.writeByte('}');
    }
};

pub const SetVoiceChannelStatus = struct {
    status: ?[]const u8,

    pub fn init(status: []const u8) SetVoiceChannelStatus {
        return .{ .status = status };
    }

    pub fn clear() SetVoiceChannelStatus {
        return .{ .status = null };
    }

    pub fn writeJson(self: SetVoiceChannelStatus, writer: anytype) !void {
        try writer.writeAll("{\"status\":");
        if (self.status) |status| {
            try Json.writeString(status, writer);
        } else {
            try writer.writeAll("null");
        }
        try writer.writeByte('}');
    }
};

pub const FollowAnnouncementChannel = struct {
    webhook_channel_id: Snowflake,

    pub fn init(webhook_channel_id: Snowflake) FollowAnnouncementChannel {
        return .{ .webhook_channel_id = webhook_channel_id };
    }

    pub fn writeJson(self: FollowAnnouncementChannel, writer: anytype) !void {
        try writer.print("{{\"webhook_channel_id\":\"{d}\"}}", .{self.webhook_channel_id.value});
    }
};

pub const CreateGuildRole = struct {
    name: []const u8,
    permissions: ?Permissions.Bit = null,
    color: ?u24 = null,
    colors: ?RoleColors = null,
    hoist: ?bool = null,
    icon: ?[]const u8 = null,
    unicode_emoji: ?[]const u8 = null,
    mentionable: ?bool = null,

    pub fn init(name: []const u8) CreateGuildRole {
        return .{ .name = name };
    }

    pub fn withPermissions(self: CreateGuildRole, permissions: Permissions.Bit) CreateGuildRole {
        var role = self;
        role.permissions = permissions;
        return role;
    }

    pub fn withColor(self: CreateGuildRole, color: u24) CreateGuildRole {
        var role = self;
        role.color = color;
        return role;
    }

    pub fn withColors(self: CreateGuildRole, colors: RoleColors) CreateGuildRole {
        var role = self;
        role.colors = colors;
        return role;
    }

    pub fn hoisted(self: CreateGuildRole, hoist: bool) CreateGuildRole {
        var role = self;
        role.hoist = hoist;
        return role;
    }

    pub fn withIcon(self: CreateGuildRole, icon: []const u8) CreateGuildRole {
        var role = self;
        role.icon = icon;
        return role;
    }

    pub fn withUnicodeEmoji(self: CreateGuildRole, unicode_emoji: []const u8) CreateGuildRole {
        var role = self;
        role.unicode_emoji = unicode_emoji;
        return role;
    }

    pub fn mentionableState(self: CreateGuildRole, mentionable: bool) CreateGuildRole {
        var role = self;
        role.mentionable = mentionable;
        return role;
    }

    pub fn writeJson(self: CreateGuildRole, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);

        try writeRoleFields(.{
            .permissions = self.permissions,
            .color = self.color,
            .colors = self.colors,
            .hoist = self.hoist,
            .icon = self.icon,
            .unicode_emoji = self.unicode_emoji,
            .mentionable = self.mentionable,
        }, writer, &needs_comma);

        try writer.writeByte('}');
    }
};

pub const EditGuildRole = struct {
    name: ?[]const u8 = null,
    permissions: ?Permissions.Bit = null,
    color: ?u24 = null,
    colors: ?RoleColors = null,
    hoist: ?bool = null,
    icon: ?[]const u8 = null,
    clear_icon: bool = false,
    unicode_emoji: ?[]const u8 = null,
    clear_unicode_emoji: bool = false,
    mentionable: ?bool = null,

    pub fn init() EditGuildRole {
        return .{};
    }

    pub fn withName(self: EditGuildRole, name: []const u8) EditGuildRole {
        var role = self;
        role.name = name;
        return role;
    }

    pub fn withPermissions(self: EditGuildRole, permissions: Permissions.Bit) EditGuildRole {
        var role = self;
        role.permissions = permissions;
        return role;
    }

    pub fn withColor(self: EditGuildRole, color: u24) EditGuildRole {
        var role = self;
        role.color = color;
        return role;
    }

    pub fn withColors(self: EditGuildRole, colors: RoleColors) EditGuildRole {
        var role = self;
        role.colors = colors;
        return role;
    }

    pub fn hoisted(self: EditGuildRole, hoist: bool) EditGuildRole {
        var role = self;
        role.hoist = hoist;
        return role;
    }

    pub fn withIcon(self: EditGuildRole, icon: []const u8) EditGuildRole {
        var role = self;
        role.icon = icon;
        role.clear_icon = false;
        return role;
    }

    pub fn clearIcon(self: EditGuildRole) EditGuildRole {
        var role = self;
        role.icon = null;
        role.clear_icon = true;
        return role;
    }

    pub fn withUnicodeEmoji(self: EditGuildRole, unicode_emoji: []const u8) EditGuildRole {
        var role = self;
        role.unicode_emoji = unicode_emoji;
        role.clear_unicode_emoji = false;
        return role;
    }

    pub fn clearUnicodeEmoji(self: EditGuildRole) EditGuildRole {
        var role = self;
        role.unicode_emoji = null;
        role.clear_unicode_emoji = true;
        return role;
    }

    pub fn mentionableState(self: EditGuildRole, mentionable: bool) EditGuildRole {
        var role = self;
        role.mentionable = mentionable;
        return role;
    }

    pub fn writeJson(self: EditGuildRole, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "name", self.name);
        try writeRoleFields(.{
            .permissions = self.permissions,
            .color = self.color,
            .colors = self.colors,
            .hoist = self.hoist,
            .icon = self.icon,
            .clear_icon = self.clear_icon,
            .unicode_emoji = self.unicode_emoji,
            .clear_unicode_emoji = self.clear_unicode_emoji,
            .mentionable = self.mentionable,
        }, writer, &needs_comma);

        try writer.writeByte('}');
    }
};

pub const GuildRolePosition = struct {
    id: Snowflake,
    position: ?i32 = null,
    clear_position: bool = false,

    pub fn init(id: Snowflake) GuildRolePosition {
        return .{ .id = id };
    }

    pub fn withPosition(self: GuildRolePosition, position: i32) GuildRolePosition {
        var payload = self;
        payload.position = position;
        payload.clear_position = false;
        return payload;
    }

    pub fn clearPosition(self: GuildRolePosition) GuildRolePosition {
        var payload = self;
        payload.position = null;
        payload.clear_position = true;
        return payload;
    }

    pub fn writeJson(self: GuildRolePosition, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.print("\"id\":\"{d}\"", .{self.id.value});
        if (self.clear_position) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"position\":null");
        } else if (self.position) |position| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"position\":{d}", .{position});
        }

        try writer.writeByte('}');
    }
};

pub const CreateGuildEmoji = struct {
    name: []const u8,
    image: []const u8,
    roles: []const Snowflake = &.{},

    pub fn init(name: []const u8, image: []const u8) CreateGuildEmoji {
        return .{ .name = name, .image = image };
    }

    pub fn withRoles(self: CreateGuildEmoji, roles: []const Snowflake) CreateGuildEmoji {
        var payload = self;
        payload.roles = roles;
        return payload;
    }

    pub fn writeJson(self: CreateGuildEmoji, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"image\":");
        try Json.writeString(self.image, writer);

        if (self.roles.len != 0) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"roles\":");
            try writeSnowflakeStringArray(self.roles, writer);
        }

        try writer.writeByte('}');
    }
};

pub const EditGuildEmoji = struct {
    name: ?[]const u8 = null,
    roles: ?[]const Snowflake = null,

    pub fn init() EditGuildEmoji {
        return .{};
    }

    pub fn withName(self: EditGuildEmoji, name: []const u8) EditGuildEmoji {
        var payload = self;
        payload.name = name;
        return payload;
    }

    pub fn withRoles(self: EditGuildEmoji, roles: []const Snowflake) EditGuildEmoji {
        var payload = self;
        payload.roles = roles;
        return payload;
    }

    pub fn writeJson(self: EditGuildEmoji, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "name", self.name);
        if (self.roles) |roles| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"roles\":");
            try writeSnowflakeStringArray(roles, writer);
        }

        try writer.writeByte('}');
    }
};

pub const CreateApplicationEmoji = struct {
    name: []const u8,
    image: []const u8,

    pub fn init(name: []const u8, image: []const u8) CreateApplicationEmoji {
        return .{ .name = name, .image = image };
    }

    pub fn writeJson(self: CreateApplicationEmoji, writer: anytype) !void {
        try writer.writeByte('{');
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);
        try writer.writeAll(",\"image\":");
        try Json.writeString(self.image, writer);
        try writer.writeByte('}');
    }
};

pub const EditApplicationEmoji = struct {
    name: []const u8,

    pub fn init(name: []const u8) EditApplicationEmoji {
        return .{ .name = name };
    }

    pub fn writeJson(self: EditApplicationEmoji, writer: anytype) !void {
        try writer.writeByte('{');
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);
        try writer.writeByte('}');
    }
};

pub const CreateGuildSticker = struct {
    name: []const u8,
    description: ?[]const u8 = null,
    tags: []const u8,

    pub fn init(name: []const u8, tags: []const u8) CreateGuildSticker {
        return .{ .name = name, .tags = tags };
    }

    pub fn withDescription(self: CreateGuildSticker, description: []const u8) CreateGuildSticker {
        var payload = self;
        payload.description = description;
        return payload;
    }
};

pub const EditGuildSticker = struct {
    name: ?[]const u8 = null,
    description: ?[]const u8 = null,
    tags: ?[]const u8 = null,

    pub fn init() EditGuildSticker {
        return .{};
    }

    pub fn withName(self: EditGuildSticker, name: []const u8) EditGuildSticker {
        var payload = self;
        payload.name = name;
        return payload;
    }

    pub fn withDescription(self: EditGuildSticker, description: []const u8) EditGuildSticker {
        var payload = self;
        payload.description = description;
        return payload;
    }

    pub fn withTags(self: EditGuildSticker, tags: []const u8) EditGuildSticker {
        var payload = self;
        payload.tags = tags;
        return payload;
    }

    pub fn writeJson(self: EditGuildSticker, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "name", self.name);
        try writeOptionalStringField(writer, &needs_comma, "description", self.description);
        try writeOptionalStringField(writer, &needs_comma, "tags", self.tags);

        try writer.writeByte('}');
    }
};

pub const SendSoundboardSound = struct {
    sound_id: Snowflake,
    source_guild_id: ?Snowflake = null,

    pub fn init(sound_id: Snowflake) SendSoundboardSound {
        return .{ .sound_id = sound_id };
    }

    pub fn fromGuild(self: SendSoundboardSound, source_guild_id: Snowflake) SendSoundboardSound {
        var payload = self;
        payload.source_guild_id = source_guild_id;
        return payload;
    }

    pub fn writeJson(self: SendSoundboardSound, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.print("\"sound_id\":\"{d}\"", .{self.sound_id.value});
        if (self.source_guild_id) |guild_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"source_guild_id\":\"{d}\"", .{guild_id.value});
        }

        try writer.writeByte('}');
    }
};

pub const CreateGuildSoundboardSound = struct {
    name: []const u8,
    sound: []const u8,
    volume: ?f64 = null,
    emoji_id: ?Snowflake = null,
    emoji_name: ?[]const u8 = null,

    pub fn init(name: []const u8, sound: []const u8) CreateGuildSoundboardSound {
        return .{ .name = name, .sound = sound };
    }

    pub fn withVolume(self: CreateGuildSoundboardSound, volume: f64) CreateGuildSoundboardSound {
        var payload = self;
        payload.volume = volume;
        return payload;
    }

    pub fn withEmojiId(self: CreateGuildSoundboardSound, emoji_id: Snowflake) CreateGuildSoundboardSound {
        var payload = self;
        payload.emoji_id = emoji_id;
        return payload;
    }

    pub fn withEmojiName(self: CreateGuildSoundboardSound, emoji_name: []const u8) CreateGuildSoundboardSound {
        var payload = self;
        payload.emoji_name = emoji_name;
        return payload;
    }

    pub fn writeJson(self: CreateGuildSoundboardSound, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"sound\":");
        try Json.writeString(self.sound, writer);

        try writeOptionalFloatField(writer, &needs_comma, "volume", self.volume);
        if (self.emoji_id) |emoji_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"emoji_id\":\"{d}\"", .{emoji_id.value});
        }
        try writeOptionalStringField(writer, &needs_comma, "emoji_name", self.emoji_name);

        try writer.writeByte('}');
    }
};

pub const EditGuildSoundboardSound = struct {
    name: ?[]const u8 = null,
    volume: ?f64 = null,
    emoji_id: ?Snowflake = null,
    clear_emoji_id: bool = false,
    emoji_name: ?[]const u8 = null,
    clear_emoji_name: bool = false,

    pub fn init() EditGuildSoundboardSound {
        return .{};
    }

    pub fn withName(self: EditGuildSoundboardSound, name: []const u8) EditGuildSoundboardSound {
        var payload = self;
        payload.name = name;
        return payload;
    }

    pub fn withVolume(self: EditGuildSoundboardSound, volume: f64) EditGuildSoundboardSound {
        var payload = self;
        payload.volume = volume;
        return payload;
    }

    pub fn withEmojiId(self: EditGuildSoundboardSound, emoji_id: Snowflake) EditGuildSoundboardSound {
        var payload = self;
        payload.emoji_id = emoji_id;
        payload.clear_emoji_id = false;
        return payload;
    }

    pub fn clearEmojiId(self: EditGuildSoundboardSound) EditGuildSoundboardSound {
        var payload = self;
        payload.emoji_id = null;
        payload.clear_emoji_id = true;
        return payload;
    }

    pub fn withEmojiName(self: EditGuildSoundboardSound, emoji_name: []const u8) EditGuildSoundboardSound {
        var payload = self;
        payload.emoji_name = emoji_name;
        payload.clear_emoji_name = false;
        return payload;
    }

    pub fn clearEmojiName(self: EditGuildSoundboardSound) EditGuildSoundboardSound {
        var payload = self;
        payload.emoji_name = null;
        payload.clear_emoji_name = true;
        return payload;
    }

    pub fn writeJson(self: EditGuildSoundboardSound, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "name", self.name);
        try writeOptionalFloatField(writer, &needs_comma, "volume", self.volume);
        try writeNullableSnowflakeField(writer, &needs_comma, "emoji_id", self.emoji_id, self.clear_emoji_id);
        try writeNullableStringField(writer, &needs_comma, "emoji_name", self.emoji_name, self.clear_emoji_name);

        try writer.writeByte('}');
    }
};

pub const EditGuildMember = struct {
    nick: ?[]const u8 = null,
    roles: ?[]const Snowflake = null,
    mute: ?bool = null,
    deaf: ?bool = null,
    channel_id: ?Snowflake = null,
    communication_disabled_until: ?[]const u8 = null,
    clear_communication_disabled_until: bool = false,

    pub fn init() EditGuildMember {
        return .{};
    }

    pub fn withNick(self: EditGuildMember, nick: []const u8) EditGuildMember {
        var payload = self;
        payload.nick = nick;
        return payload;
    }

    pub fn withRoles(self: EditGuildMember, roles: []const Snowflake) EditGuildMember {
        var payload = self;
        payload.roles = roles;
        return payload;
    }

    pub fn muteState(self: EditGuildMember, mute: bool) EditGuildMember {
        var payload = self;
        payload.mute = mute;
        return payload;
    }

    pub fn deafState(self: EditGuildMember, deaf: bool) EditGuildMember {
        var payload = self;
        payload.deaf = deaf;
        return payload;
    }

    pub fn moveToVoiceChannel(self: EditGuildMember, channel_id: Snowflake) EditGuildMember {
        var payload = self;
        payload.channel_id = channel_id;
        return payload;
    }

    pub fn timeoutUntil(self: EditGuildMember, timestamp: []const u8) EditGuildMember {
        var payload = self;
        payload.communication_disabled_until = timestamp;
        payload.clear_communication_disabled_until = false;
        return payload;
    }

    pub fn clearTimeout(self: EditGuildMember) EditGuildMember {
        var payload = self;
        payload.communication_disabled_until = null;
        payload.clear_communication_disabled_until = true;
        return payload;
    }

    pub fn writeJson(self: EditGuildMember, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "nick", self.nick);
        if (self.roles) |roles| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"roles\":");
            try writeSnowflakeStringArray(roles, writer);
        }
        try writeOptionalBoolField(writer, &needs_comma, "mute", self.mute);
        try writeOptionalBoolField(writer, &needs_comma, "deaf", self.deaf);
        if (self.channel_id) |channel_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"channel_id\":\"{d}\"", .{channel_id.value});
        }
        try writeNullableStringField(
            writer,
            &needs_comma,
            "communication_disabled_until",
            self.communication_disabled_until,
            self.clear_communication_disabled_until,
        );

        try writer.writeByte('}');
    }
};

pub const AddGuildMember = struct {
    access_token: []const u8,
    nick: ?[]const u8 = null,
    roles: ?[]const Snowflake = null,
    mute: ?bool = null,
    deaf: ?bool = null,

    pub fn init(access_token: []const u8) AddGuildMember {
        return .{ .access_token = access_token };
    }

    pub fn withNick(self: AddGuildMember, nick: []const u8) AddGuildMember {
        var payload = self;
        payload.nick = nick;
        return payload;
    }

    pub fn withRoles(self: AddGuildMember, roles: []const Snowflake) AddGuildMember {
        var payload = self;
        payload.roles = roles;
        return payload;
    }

    pub fn muteState(self: AddGuildMember, mute: bool) AddGuildMember {
        var payload = self;
        payload.mute = mute;
        return payload;
    }

    pub fn deafState(self: AddGuildMember, deaf: bool) AddGuildMember {
        var payload = self;
        payload.deaf = deaf;
        return payload;
    }

    pub fn writeJson(self: AddGuildMember, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "access_token", self.access_token);
        try writeOptionalStringField(writer, &needs_comma, "nick", self.nick);
        if (self.roles) |roles| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"roles\":");
            try writeSnowflakeStringArray(roles, writer);
        }
        try writeOptionalBoolField(writer, &needs_comma, "mute", self.mute);
        try writeOptionalBoolField(writer, &needs_comma, "deaf", self.deaf);

        try writer.writeByte('}');
    }
};

pub const EditCurrentGuildMember = struct {
    nick: ?[]const u8 = null,
    clear_nick: bool = false,
    avatar: ?[]const u8 = null,
    clear_avatar: bool = false,
    banner: ?[]const u8 = null,
    clear_banner: bool = false,
    bio: ?[]const u8 = null,
    clear_bio: bool = false,

    pub fn init() EditCurrentGuildMember {
        return .{};
    }

    pub fn withNick(self: EditCurrentGuildMember, nick: []const u8) EditCurrentGuildMember {
        var payload = self;
        payload.nick = nick;
        payload.clear_nick = false;
        return payload;
    }

    pub fn clearNick(self: EditCurrentGuildMember) EditCurrentGuildMember {
        var payload = self;
        payload.nick = null;
        payload.clear_nick = true;
        return payload;
    }

    pub fn withAvatar(self: EditCurrentGuildMember, avatar: []const u8) EditCurrentGuildMember {
        var payload = self;
        payload.avatar = avatar;
        payload.clear_avatar = false;
        return payload;
    }

    pub fn clearAvatar(self: EditCurrentGuildMember) EditCurrentGuildMember {
        var payload = self;
        payload.avatar = null;
        payload.clear_avatar = true;
        return payload;
    }

    pub fn withBanner(self: EditCurrentGuildMember, banner: []const u8) EditCurrentGuildMember {
        var payload = self;
        payload.banner = banner;
        payload.clear_banner = false;
        return payload;
    }

    pub fn clearBanner(self: EditCurrentGuildMember) EditCurrentGuildMember {
        var payload = self;
        payload.banner = null;
        payload.clear_banner = true;
        return payload;
    }

    pub fn withBio(self: EditCurrentGuildMember, bio: []const u8) EditCurrentGuildMember {
        var payload = self;
        payload.bio = bio;
        payload.clear_bio = false;
        return payload;
    }

    pub fn clearBio(self: EditCurrentGuildMember) EditCurrentGuildMember {
        var payload = self;
        payload.bio = null;
        payload.clear_bio = true;
        return payload;
    }

    pub fn writeJson(self: EditCurrentGuildMember, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeNullableStringField(writer, &needs_comma, "nick", self.nick, self.clear_nick);
        try writeNullableStringField(writer, &needs_comma, "avatar", self.avatar, self.clear_avatar);
        try writeNullableStringField(writer, &needs_comma, "banner", self.banner, self.clear_banner);
        try writeNullableStringField(writer, &needs_comma, "bio", self.bio, self.clear_bio);

        try writer.writeByte('}');
    }
};

pub const EditCurrentUserNick = struct {
    nick: ?[]const u8 = null,
    clear_nick: bool = false,

    pub fn init() EditCurrentUserNick {
        return .{};
    }

    pub fn withNick(self: EditCurrentUserNick, nick: []const u8) EditCurrentUserNick {
        var payload = self;
        payload.nick = nick;
        payload.clear_nick = false;
        return payload;
    }

    pub fn clearNick(self: EditCurrentUserNick) EditCurrentUserNick {
        var payload = self;
        payload.nick = null;
        payload.clear_nick = true;
        return payload;
    }

    pub fn writeJson(self: EditCurrentUserNick, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeNullableStringField(writer, &needs_comma, "nick", self.nick, self.clear_nick);

        try writer.writeByte('}');
    }
};

pub const EditCurrentUser = struct {
    username: ?[]const u8 = null,
    avatar: ?[]const u8 = null,
    clear_avatar: bool = false,
    banner: ?[]const u8 = null,
    clear_banner: bool = false,

    pub fn init() EditCurrentUser {
        return .{};
    }

    pub fn withUsername(self: EditCurrentUser, username: []const u8) EditCurrentUser {
        var payload = self;
        payload.username = username;
        return payload;
    }

    pub fn withAvatar(self: EditCurrentUser, avatar: []const u8) EditCurrentUser {
        var payload = self;
        payload.avatar = avatar;
        payload.clear_avatar = false;
        return payload;
    }

    pub fn clearAvatar(self: EditCurrentUser) EditCurrentUser {
        var payload = self;
        payload.avatar = null;
        payload.clear_avatar = true;
        return payload;
    }

    pub fn withBanner(self: EditCurrentUser, banner: []const u8) EditCurrentUser {
        var payload = self;
        payload.banner = banner;
        payload.clear_banner = false;
        return payload;
    }

    pub fn clearBanner(self: EditCurrentUser) EditCurrentUser {
        var payload = self;
        payload.banner = null;
        payload.clear_banner = true;
        return payload;
    }

    pub fn writeJson(self: EditCurrentUser, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "username", self.username);
        try writeNullableStringField(writer, &needs_comma, "avatar", self.avatar, self.clear_avatar);
        try writeNullableStringField(writer, &needs_comma, "banner", self.banner, self.clear_banner);

        try writer.writeByte('}');
    }
};

pub const UpdateApplicationRoleConnection = struct {
    platform_name: ?[]const u8 = null,
    platform_username: ?[]const u8 = null,
    metadata: ?[]const StringPair = null,

    pub fn init() UpdateApplicationRoleConnection {
        return .{};
    }

    pub fn withPlatformName(self: UpdateApplicationRoleConnection, platform_name: []const u8) UpdateApplicationRoleConnection {
        var payload = self;
        payload.platform_name = platform_name;
        return payload;
    }

    pub fn withPlatformUsername(self: UpdateApplicationRoleConnection, platform_username: []const u8) UpdateApplicationRoleConnection {
        var payload = self;
        payload.platform_username = platform_username;
        return payload;
    }

    pub fn withMetadata(self: UpdateApplicationRoleConnection, metadata: []const StringPair) UpdateApplicationRoleConnection {
        var payload = self;
        payload.metadata = metadata;
        return payload;
    }

    pub fn writeJson(self: UpdateApplicationRoleConnection, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "platform_name", self.platform_name);
        try writeOptionalStringField(writer, &needs_comma, "platform_username", self.platform_username);
        if (self.metadata) |metadata| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"metadata\":");
            try writeStringPairObject(metadata, writer);
        }

        try writer.writeByte('}');
    }
};

pub const CreateDmChannel = struct {
    recipient_id: Snowflake,

    pub fn init(recipient_id: Snowflake) CreateDmChannel {
        return .{ .recipient_id = recipient_id };
    }

    pub fn writeJson(self: CreateDmChannel, writer: anytype) !void {
        try writer.print("{{\"recipient_id\":\"{d}\"}}", .{self.recipient_id.value});
    }
};

pub const AddGroupDmRecipient = struct {
    access_token: []const u8,
    nick: ?[]const u8 = null,

    pub fn init(access_token: []const u8) AddGroupDmRecipient {
        return .{ .access_token = access_token };
    }

    pub fn withNick(self: AddGroupDmRecipient, nick: []const u8) AddGroupDmRecipient {
        var payload = self;
        payload.nick = nick;
        return payload;
    }

    pub fn writeJson(self: AddGroupDmRecipient, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        try writeOptionalStringField(writer, &needs_comma, "access_token", self.access_token);
        try writeOptionalStringField(writer, &needs_comma, "nick", self.nick);
        try writer.writeByte('}');
    }
};

pub const CreateThreadFromMessage = struct {
    name: []const u8,
    auto_archive_duration: ?u16 = null,
    rate_limit_per_user: ?u16 = null,

    pub fn init(name: []const u8) CreateThreadFromMessage {
        return .{ .name = name };
    }

    pub fn withAutoArchiveDuration(self: CreateThreadFromMessage, auto_archive_duration: u16) CreateThreadFromMessage {
        var payload = self;
        payload.auto_archive_duration = auto_archive_duration;
        return payload;
    }

    pub fn withRateLimit(self: CreateThreadFromMessage, rate_limit_per_user: u16) CreateThreadFromMessage {
        var payload = self;
        payload.rate_limit_per_user = rate_limit_per_user;
        return payload;
    }

    pub fn writeJson(self: CreateThreadFromMessage, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);
        try writeThreadFields(.{
            .auto_archive_duration = self.auto_archive_duration,
            .rate_limit_per_user = self.rate_limit_per_user,
        }, writer, &needs_comma);

        try writer.writeByte('}');
    }
};

pub const CreateThread = struct {
    name: []const u8,
    type: ChannelType = .public_thread,
    auto_archive_duration: ?u16 = null,
    rate_limit_per_user: ?u16 = null,
    invitable: ?bool = null,

    pub fn init(name: []const u8) CreateThread {
        return .{ .name = name };
    }

    pub fn withType(self: CreateThread, thread_type: ChannelType) CreateThread {
        var payload = self;
        payload.type = thread_type;
        return payload;
    }

    pub fn withAutoArchiveDuration(self: CreateThread, auto_archive_duration: u16) CreateThread {
        var payload = self;
        payload.auto_archive_duration = auto_archive_duration;
        return payload;
    }

    pub fn withRateLimit(self: CreateThread, rate_limit_per_user: u16) CreateThread {
        var payload = self;
        payload.rate_limit_per_user = rate_limit_per_user;
        return payload;
    }

    pub fn invitableState(self: CreateThread, invitable: bool) CreateThread {
        var payload = self;
        payload.invitable = invitable;
        return payload;
    }

    pub fn writeJson(self: CreateThread, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);
        try writer.print(",\"type\":{d}", .{@intFromEnum(self.type)});
        needs_comma = true;
        try writeThreadFields(.{
            .auto_archive_duration = self.auto_archive_duration,
            .rate_limit_per_user = self.rate_limit_per_user,
            .invitable = self.invitable,
        }, writer, &needs_comma);

        try writer.writeByte('}');
    }
};

pub const ForumThreadMessage = struct {
    content: []const u8 = "",
    embeds: []const Embed = &.{},
    allowed_mentions: ?AllowedMentions = null,
    components: []const Interactions.Component = &.{},
    sticker_ids: []const Snowflake = &.{},
    attachments: []const UploadFile = &.{},
    flags: ?MessageFlags.Bit = null,

    pub fn init(content: []const u8) ForumThreadMessage {
        return .{ .content = content };
    }

    pub fn empty() ForumThreadMessage {
        return .{};
    }

    pub fn withEmbeds(self: ForumThreadMessage, embeds: []const Embed) ForumThreadMessage {
        var message = self;
        message.embeds = embeds;
        return message;
    }

    pub fn withAllowedMentions(self: ForumThreadMessage, allowed_mentions: AllowedMentions) ForumThreadMessage {
        var message = self;
        message.allowed_mentions = allowed_mentions;
        return message;
    }

    pub fn withComponents(self: ForumThreadMessage, components: []const Interactions.Component) ForumThreadMessage {
        var message = self;
        message.components = components;
        return message;
    }

    pub fn withStickers(self: ForumThreadMessage, sticker_ids: []const Snowflake) ForumThreadMessage {
        var message = self;
        message.sticker_ids = sticker_ids;
        return message;
    }

    pub fn withAttachments(self: ForumThreadMessage, attachments: []const UploadFile) ForumThreadMessage {
        var message = self;
        message.attachments = attachments;
        return message;
    }

    pub fn withFlags(self: ForumThreadMessage, flags: MessageFlags.Bit) ForumThreadMessage {
        var message = self;
        message.flags = flags;
        return message;
    }

    pub fn writeJson(self: ForumThreadMessage, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        try writeMessagePayloadFields(.{
            .content = if (self.content.len != 0) self.content else null,
            .embeds = self.embeds,
            .sticker_ids = self.sticker_ids,
            .allowed_mentions = self.allowed_mentions,
            .components = self.components,
            .flags = self.flags,
        }, writer, &needs_comma);
        if (self.attachments.len != 0) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"attachments\":");
            try writeUploadAttachmentArray(self.attachments, writer);
        }
        try writer.writeByte('}');
    }
};

pub const CreateForumThread = struct {
    name: []const u8,
    message: ForumThreadMessage,
    auto_archive_duration: ?u16 = null,
    rate_limit_per_user: ?u16 = null,
    applied_tags: []const Snowflake = &.{},

    pub fn init(name: []const u8, message: ForumThreadMessage) CreateForumThread {
        return .{ .name = name, .message = message };
    }

    pub fn withAutoArchiveDuration(self: CreateForumThread, auto_archive_duration: u16) CreateForumThread {
        var payload = self;
        payload.auto_archive_duration = auto_archive_duration;
        return payload;
    }

    pub fn withRateLimit(self: CreateForumThread, rate_limit_per_user: u16) CreateForumThread {
        var payload = self;
        payload.rate_limit_per_user = rate_limit_per_user;
        return payload;
    }

    pub fn withAppliedTags(self: CreateForumThread, applied_tags: []const Snowflake) CreateForumThread {
        var payload = self;
        payload.applied_tags = applied_tags;
        return payload;
    }

    pub fn writeJson(self: CreateForumThread, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);
        try writeThreadFields(.{
            .auto_archive_duration = self.auto_archive_duration,
            .rate_limit_per_user = self.rate_limit_per_user,
        }, writer, &needs_comma);
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"message\":");
        try self.message.writeJson(writer);
        if (self.applied_tags.len != 0) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"applied_tags\":");
            try writeSnowflakeStringArray(self.applied_tags, writer);
        }
        try writer.writeByte('}');
    }
};

pub const Invite = struct {
    code: []const u8,
    type: ?u8 = null,
    guild_id: ?Snowflake = null,
    channel_id: ?Snowflake = null,
    inviter_id: ?Snowflake = null,
    target_type: ?u8 = null,
    target_user_id: ?Snowflake = null,
    target_application_id: ?Snowflake = null,
    approximate_presence_count: ?u32 = null,
    approximate_member_count: ?u32 = null,
    expires_at: ?[]const u8 = null,
    uses: ?u32 = null,
    max_uses: ?u32 = null,
    max_age: ?u32 = null,
    temporary: ?bool = null,
    created_at: ?[]const u8 = null,
    guild_scheduled_event_id: ?Snowflake = null,
};

pub const GetInvite = struct {
    with_counts: ?bool = null,
    guild_scheduled_event_id: ?Snowflake = null,

    pub fn init() GetInvite {
        return .{};
    }

    pub fn withCounts(self: GetInvite, with_counts: bool) GetInvite {
        var options = self;
        options.with_counts = with_counts;
        return options;
    }

    pub fn withScheduledEvent(self: GetInvite, event_id: Snowflake) GetInvite {
        var options = self;
        options.guild_scheduled_event_id = event_id;
        return options;
    }

    pub fn hasQuery(self: GetInvite) bool {
        return self.with_counts != null or self.guild_scheduled_event_id != null;
    }

    pub fn writeQuery(self: GetInvite, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.with_counts) |with_counts| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.writeAll("with_counts=");
            try writer.writeAll(if (with_counts) "true" else "false");
        }
        if (self.guild_scheduled_event_id) |event_id| {
            try writeSnowflakeQueryParam(writer, &needs_ampersand, "guild_scheduled_event_id", event_id);
        }
    }
};

pub const LobbyMember = struct {
    id: Snowflake,
    metadata: ?[]const StringPair = null,
    clear_metadata: bool = false,
    flags: ?u32 = null,
    remove_member: ?bool = null,

    pub fn init(id: Snowflake) LobbyMember {
        return .{ .id = id };
    }

    pub fn withMetadata(self: LobbyMember, metadata: []const StringPair) LobbyMember {
        var member = self;
        member.metadata = metadata;
        member.clear_metadata = false;
        return member;
    }

    pub fn clearMetadata(self: LobbyMember) LobbyMember {
        var member = self;
        member.metadata = null;
        member.clear_metadata = true;
        return member;
    }

    pub fn withFlags(self: LobbyMember, flags: u32) LobbyMember {
        var member = self;
        member.flags = flags;
        return member;
    }

    pub fn removeState(self: LobbyMember, remove_member: bool) LobbyMember {
        var member = self;
        member.remove_member = remove_member;
        return member;
    }

    pub fn writeJson(self: LobbyMember, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.print("\"id\":\"{d}\"", .{self.id.value});
        try writeNullableStringPairObjectField(writer, &needs_comma, "metadata", self.metadata, self.clear_metadata);
        if (self.flags) |flags| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"flags\":{d}", .{flags});
        }
        try writeOptionalBoolField(writer, &needs_comma, "remove_member", self.remove_member);

        try writer.writeByte('}');
    }
};

pub const CreateLobby = struct {
    metadata: ?[]const StringPair = null,
    clear_metadata: bool = false,
    members: []const LobbyMember = &.{},
    idle_timeout_seconds: ?u32 = null,

    pub fn init() CreateLobby {
        return .{};
    }

    pub fn withMetadata(self: CreateLobby, metadata: []const StringPair) CreateLobby {
        var payload = self;
        payload.metadata = metadata;
        payload.clear_metadata = false;
        return payload;
    }

    pub fn clearMetadata(self: CreateLobby) CreateLobby {
        var payload = self;
        payload.metadata = null;
        payload.clear_metadata = true;
        return payload;
    }

    pub fn withMembers(self: CreateLobby, members: []const LobbyMember) CreateLobby {
        var payload = self;
        payload.members = members;
        return payload;
    }

    pub fn withIdleTimeout(self: CreateLobby, idle_timeout_seconds: u32) CreateLobby {
        var payload = self;
        payload.idle_timeout_seconds = idle_timeout_seconds;
        return payload;
    }

    pub fn writeJson(self: CreateLobby, writer: anytype) !void {
        try writeLobbyPayloadJson(.{
            .metadata = self.metadata,
            .clear_metadata = self.clear_metadata,
            .members = self.members,
            .idle_timeout_seconds = self.idle_timeout_seconds,
        }, writer);
    }
};

pub const EditLobby = struct {
    metadata: ?[]const StringPair = null,
    clear_metadata: bool = false,
    members: []const LobbyMember = &.{},
    idle_timeout_seconds: ?u32 = null,

    pub fn init() EditLobby {
        return .{};
    }

    pub fn withMetadata(self: EditLobby, metadata: []const StringPair) EditLobby {
        var payload = self;
        payload.metadata = metadata;
        payload.clear_metadata = false;
        return payload;
    }

    pub fn clearMetadata(self: EditLobby) EditLobby {
        var payload = self;
        payload.metadata = null;
        payload.clear_metadata = true;
        return payload;
    }

    pub fn withMembers(self: EditLobby, members: []const LobbyMember) EditLobby {
        var payload = self;
        payload.members = members;
        return payload;
    }

    pub fn withIdleTimeout(self: EditLobby, idle_timeout_seconds: u32) EditLobby {
        var payload = self;
        payload.idle_timeout_seconds = idle_timeout_seconds;
        return payload;
    }

    pub fn writeJson(self: EditLobby, writer: anytype) !void {
        try writeLobbyPayloadJson(.{
            .metadata = self.metadata,
            .clear_metadata = self.clear_metadata,
            .members = self.members,
            .idle_timeout_seconds = self.idle_timeout_seconds,
        }, writer);
    }
};

pub const UpdateLobbyMember = struct {
    metadata: ?[]const StringPair = null,
    clear_metadata: bool = false,
    flags: ?u32 = null,

    pub fn init() UpdateLobbyMember {
        return .{};
    }

    pub fn withMetadata(self: UpdateLobbyMember, metadata: []const StringPair) UpdateLobbyMember {
        var payload = self;
        payload.metadata = metadata;
        payload.clear_metadata = false;
        return payload;
    }

    pub fn clearMetadata(self: UpdateLobbyMember) UpdateLobbyMember {
        var payload = self;
        payload.metadata = null;
        payload.clear_metadata = true;
        return payload;
    }

    pub fn withFlags(self: UpdateLobbyMember, flags: u32) UpdateLobbyMember {
        var payload = self;
        payload.flags = flags;
        return payload;
    }

    pub fn writeJson(self: UpdateLobbyMember, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeNullableStringPairObjectField(writer, &needs_comma, "metadata", self.metadata, self.clear_metadata);
        if (self.flags) |flags| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"flags\":{d}", .{flags});
        }

        try writer.writeByte('}');
    }
};

pub const BulkUpdateLobbyMembers = struct {
    members: []const LobbyMember,

    pub fn init(members: []const LobbyMember) BulkUpdateLobbyMembers {
        return .{ .members = members };
    }

    pub fn writeJson(self: BulkUpdateLobbyMembers, writer: anytype) !void {
        try writeLobbyMemberArray(self.members, writer);
    }
};

pub const LinkLobbyChannel = struct {
    channel_id: ?Snowflake = null,
    clear_channel_id: bool = false,

    pub fn init(channel_id: Snowflake) LinkLobbyChannel {
        return .{ .channel_id = channel_id };
    }

    pub fn unlink() LinkLobbyChannel {
        return .{ .clear_channel_id = true };
    }

    pub fn writeJson(self: LinkLobbyChannel, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        try writeNullableSnowflakeField(writer, &needs_comma, "channel_id", self.channel_id, self.clear_channel_id);
        try writer.writeByte('}');
    }
};

pub const UpdateLobbyMessageModerationMetadata = struct {
    metadata: []const StringPair,

    pub fn init(metadata: []const StringPair) UpdateLobbyMessageModerationMetadata {
        return .{ .metadata = metadata };
    }

    pub fn writeJson(self: UpdateLobbyMessageModerationMetadata, writer: anytype) !void {
        try writeStringPairObject(self.metadata, writer);
    }
};

pub const CreateChannelInvite = struct {
    max_age: ?u32 = null,
    max_uses: ?u16 = null,
    temporary: ?bool = null,
    unique: ?bool = null,

    pub fn init() CreateChannelInvite {
        return .{};
    }

    pub fn withMaxAge(self: CreateChannelInvite, max_age: u32) CreateChannelInvite {
        var payload = self;
        payload.max_age = max_age;
        return payload;
    }

    pub fn withMaxUses(self: CreateChannelInvite, max_uses: u16) CreateChannelInvite {
        var payload = self;
        payload.max_uses = max_uses;
        return payload;
    }

    pub fn temporaryState(self: CreateChannelInvite, temporary: bool) CreateChannelInvite {
        var payload = self;
        payload.temporary = temporary;
        return payload;
    }

    pub fn uniqueState(self: CreateChannelInvite, unique: bool) CreateChannelInvite {
        var payload = self;
        payload.unique = unique;
        return payload;
    }

    pub fn writeJson(self: CreateChannelInvite, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        if (self.max_age) |max_age| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"max_age\":{d}", .{max_age});
        }
        if (self.max_uses) |max_uses| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"max_uses\":{d}", .{max_uses});
        }
        try writeOptionalBoolField(writer, &needs_comma, "temporary", self.temporary);
        try writeOptionalBoolField(writer, &needs_comma, "unique", self.unique);

        try writer.writeByte('}');
    }
};

pub const Webhook = struct {
    id: Snowflake,
    guild_id: ?Snowflake = null,
    channel_id: ?Snowflake = null,
    name: ?[]const u8 = null,
};

pub const CreateWebhook = struct {
    name: []const u8,
    avatar: ?[]const u8 = null,

    pub fn init(name: []const u8) CreateWebhook {
        return .{ .name = name };
    }

    pub fn withAvatar(self: CreateWebhook, avatar: []const u8) CreateWebhook {
        var webhook = self;
        webhook.avatar = avatar;
        return webhook;
    }

    pub fn writeJson(self: CreateWebhook, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);
        try writeOptionalStringField(writer, &needs_comma, "avatar", self.avatar);

        try writer.writeByte('}');
    }
};

pub const EditWebhook = struct {
    name: ?[]const u8 = null,
    avatar: ?[]const u8 = null,
    channel_id: ?Snowflake = null,

    pub fn init() EditWebhook {
        return .{};
    }

    pub fn withName(self: EditWebhook, name: []const u8) EditWebhook {
        var webhook = self;
        webhook.name = name;
        return webhook;
    }

    pub fn withAvatar(self: EditWebhook, avatar: []const u8) EditWebhook {
        var webhook = self;
        webhook.avatar = avatar;
        return webhook;
    }

    pub fn withChannel(self: EditWebhook, channel_id: Snowflake) EditWebhook {
        var webhook = self;
        webhook.channel_id = channel_id;
        return webhook;
    }

    pub fn writeJson(self: EditWebhook, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "name", self.name);
        try writeOptionalStringField(writer, &needs_comma, "avatar", self.avatar);
        if (self.channel_id) |channel_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"channel_id\":\"{d}\"", .{channel_id.value});
        }

        try writer.writeByte('}');
    }
};

pub const EditWebhookWithToken = struct {
    name: ?[]const u8 = null,
    avatar: ?[]const u8 = null,

    pub fn init() EditWebhookWithToken {
        return .{};
    }

    pub fn withName(self: EditWebhookWithToken, name: []const u8) EditWebhookWithToken {
        var webhook = self;
        webhook.name = name;
        return webhook;
    }

    pub fn withAvatar(self: EditWebhookWithToken, avatar: []const u8) EditWebhookWithToken {
        var webhook = self;
        webhook.avatar = avatar;
        return webhook;
    }

    pub fn writeJson(self: EditWebhookWithToken, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "name", self.name);
        try writeOptionalStringField(writer, &needs_comma, "avatar", self.avatar);

        try writer.writeByte('}');
    }
};

pub const ExecuteWebhook = struct {
    content: []const u8 = "",
    username: ?[]const u8 = null,
    avatar_url: ?[]const u8 = null,
    tts: bool = false,
    flags: ?MessageFlags.Bit = null,
    embeds: []const Embed = &.{},
    allowed_mentions: ?AllowedMentions = null,
    components: []const Interactions.Component = &.{},
    thread_name: ?[]const u8 = null,

    pub fn init(content: []const u8) ExecuteWebhook {
        return .{ .content = content };
    }

    pub fn empty() ExecuteWebhook {
        return .{};
    }

    pub fn withUsername(self: ExecuteWebhook, username: []const u8) ExecuteWebhook {
        var webhook = self;
        webhook.username = username;
        return webhook;
    }

    pub fn withAvatarUrl(self: ExecuteWebhook, avatar_url: []const u8) ExecuteWebhook {
        var webhook = self;
        webhook.avatar_url = avatar_url;
        return webhook;
    }

    pub fn ttsState(self: ExecuteWebhook, tts: bool) ExecuteWebhook {
        var webhook = self;
        webhook.tts = tts;
        return webhook;
    }

    pub fn withFlags(self: ExecuteWebhook, flags: MessageFlags.Bit) ExecuteWebhook {
        var webhook = self;
        webhook.flags = flags;
        return webhook;
    }

    pub fn withEmbeds(self: ExecuteWebhook, embeds: []const Embed) ExecuteWebhook {
        var webhook = self;
        webhook.embeds = embeds;
        return webhook;
    }

    pub fn withAllowedMentions(self: ExecuteWebhook, allowed_mentions: AllowedMentions) ExecuteWebhook {
        var webhook = self;
        webhook.allowed_mentions = allowed_mentions;
        return webhook;
    }

    pub fn withComponents(self: ExecuteWebhook, components: []const Interactions.Component) ExecuteWebhook {
        var webhook = self;
        webhook.components = components;
        return webhook;
    }

    pub fn withThreadName(self: ExecuteWebhook, thread_name: []const u8) ExecuteWebhook {
        var webhook = self;
        webhook.thread_name = thread_name;
        return webhook;
    }

    pub fn writeJson(self: ExecuteWebhook, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeMessagePayloadFields(.{
            .content = if (self.content.len != 0) self.content else null,
            .embeds = self.embeds,
            .allowed_mentions = self.allowed_mentions,
            .components = self.components,
            .flags = self.flags,
        }, writer, &needs_comma);
        try writeOptionalStringField(writer, &needs_comma, "username", self.username);
        try writeOptionalStringField(writer, &needs_comma, "avatar_url", self.avatar_url);
        if (self.tts) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"tts\":true");
        }
        try writeOptionalStringField(writer, &needs_comma, "thread_name", self.thread_name);

        try writer.writeByte('}');
    }
};

pub fn writeExecuteWebhookJsonWithAttachments(
    payload: ExecuteWebhook,
    files: []const UploadFile,
    writer: anytype,
) !void {
    try writeExecuteWebhookJsonWithAttachmentMetadata(payload, files, writer);
}

pub fn writeExecuteWebhookJsonWithAttachmentMetadata(
    payload: ExecuteWebhook,
    files: anytype,
    writer: anytype,
) !void {
    try writer.writeByte('{');
    var needs_comma = false;
    try writeMessagePayloadFields(.{
        .content = if (payload.content.len != 0) payload.content else null,
        .embeds = payload.embeds,
        .allowed_mentions = payload.allowed_mentions,
        .components = payload.components,
        .flags = payload.flags,
    }, writer, &needs_comma);
    try writeOptionalStringField(writer, &needs_comma, "username", payload.username);
    try writeOptionalStringField(writer, &needs_comma, "avatar_url", payload.avatar_url);
    if (payload.tts) {
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"tts\":true");
    }
    try writeOptionalStringField(writer, &needs_comma, "thread_name", payload.thread_name);
    if (files.len != 0) {
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"attachments\":");
        try writeUploadAttachmentArray(files, writer);
    }
    try writer.writeByte('}');
}

/// Query parameters for executing a webhook: `wait` to receive the created
/// message in the response, and `thread_id` to post into an existing thread.
pub const ExecuteWebhookQuery = struct {
    wait: bool = false,
    thread_id: ?Snowflake = null,

    pub fn hasQuery(self: ExecuteWebhookQuery) bool {
        return self.wait or self.thread_id != null;
    }

    pub fn writeQuery(self: ExecuteWebhookQuery, writer: anytype) !void {
        var first = true;
        if (self.wait) {
            try writer.writeAll("wait=true");
            first = false;
        }
        if (self.thread_id) |thread_id| {
            if (!first) try writer.writeByte('&');
            try writer.print("thread_id={d}", .{thread_id.value});
        }
    }
};

pub const CreateGuildBan = struct {
    delete_message_seconds: ?u32 = null,

    pub fn init() CreateGuildBan {
        return .{};
    }

    pub fn deleteMessagesFor(self: CreateGuildBan, seconds: u32) CreateGuildBan {
        var payload = self;
        payload.delete_message_seconds = seconds;
        return payload;
    }

    pub fn writeJson(self: CreateGuildBan, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        if (self.delete_message_seconds) |seconds| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"delete_message_seconds\":{d}", .{seconds});
        }
        try writer.writeByte('}');
    }
};

pub const BulkGuildBan = struct {
    user_ids: []const Snowflake,
    delete_message_seconds: ?u32 = null,

    pub fn init(user_ids: []const Snowflake) BulkGuildBan {
        return .{ .user_ids = user_ids };
    }

    pub fn deleteMessagesFor(self: BulkGuildBan, seconds: u32) BulkGuildBan {
        var payload = self;
        payload.delete_message_seconds = seconds;
        return payload;
    }

    pub fn writeJson(self: BulkGuildBan, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"user_ids\":");
        try writeSnowflakeStringArray(self.user_ids, writer);
        if (self.delete_message_seconds) |seconds| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"delete_message_seconds\":{d}", .{seconds});
        }

        try writer.writeByte('}');
    }
};

pub const Message = struct {
    id: Snowflake,
    channel_id: Snowflake,
    guild_id: ?Snowflake = null,
    author: ?User = null,
    member: ?GuildMember = null,
    message_reference: ?MessageReferenceInfo = null,
    referenced_message_id: ?Snowflake = null,
    message_snapshots: []const MessageSnapshot = &.{},
    thread: ?Channel = null,
    call: ?MessageCall = null,
    role_subscription_data: ?RoleSubscriptionData = null,
    shared_client_theme: ?SharedClientTheme = null,
    webhook_id: ?Snowflake = null,
    application_id: ?Snowflake = null,
    application: ?Application = null,
    activity: ?MessageActivity = null,
    interaction_metadata: ?MessageInteractionMetadata = null,
    type: u8 = 0,
    nonce: ?[]const u8 = null,
    content: []const u8 = "",
    timestamp: ?[]const u8 = null,
    edited_timestamp: ?[]const u8 = null,
    tts: bool = false,
    mention_everyone: bool = false,
    pinned: bool = false,
    position: ?i32 = null,
    flags: ?u32 = null,
    mentions: []const User = &.{},
    mention_roles: []const Snowflake = &.{},
    mention_channels: []const Channel = &.{},
    embeds: []const Embed = &.{},
    attachments: []const Attachment = &.{},
    sticker_items: []const MessageStickerItem = &.{},
    stickers: []const Sticker = &.{},
    components: []const Interactions.Component = &.{},
    poll: ?MessagePoll = null,
    reactions: []const MessageReaction = &.{},
};

pub const MessagePin = struct {
    pinned_at: []const u8,
    message: Message,
};

pub const ChannelPins = struct {
    items: []const MessagePin = &.{},
    has_more: bool = false,
};

pub const MessageFlags = struct {
    pub const Bit = u32;

    pub const crossposted: Bit = 1 << 0;
    pub const is_crosspost: Bit = 1 << 1;
    pub const suppress_embeds: Bit = 1 << 2;
    pub const source_message_deleted: Bit = 1 << 3;
    pub const urgent: Bit = 1 << 4;
    pub const has_thread: Bit = 1 << 5;
    pub const ephemeral: Bit = 1 << 6;
    pub const loading: Bit = 1 << 7;
    pub const failed_to_mention_some_roles_in_thread: Bit = 1 << 8;
    pub const suppress_notifications: Bit = 1 << 12;
    pub const is_voice_message: Bit = 1 << 13;
    pub const has_snapshot: Bit = 1 << 14;
    pub const is_components_v2: Bit = 1 << 15;
};

/// Message types, matching Discord.js `MessageType`. A regular user message is
/// `default`; the rest mark system/notification messages.
pub const MessageType = enum(u8) {
    default = 0,
    recipient_add = 1,
    recipient_remove = 2,
    call = 3,
    channel_name_change = 4,
    channel_icon_change = 5,
    channel_pinned_message = 6,
    user_join = 7,
    guild_boost = 8,
    guild_boost_tier_1 = 9,
    guild_boost_tier_2 = 10,
    guild_boost_tier_3 = 11,
    channel_follow_add = 12,
    guild_discovery_disqualified = 14,
    guild_discovery_requalified = 15,
    guild_discovery_grace_period_initial_warning = 16,
    guild_discovery_grace_period_final_warning = 17,
    thread_created = 18,
    reply = 19,
    chat_input_command = 20,
    thread_starter_message = 21,
    guild_invite_reminder = 22,
    context_menu_command = 23,
    auto_moderation_action = 24,
    role_subscription_purchase = 25,
    interaction_premium_upsell = 26,
    stage_start = 27,
    stage_end = 28,
    stage_speaker = 29,
    stage_topic = 31,
    guild_application_premium_subscription = 32,
    guild_incident_alert_mode_enabled = 36,
    guild_incident_alert_mode_disabled = 37,
    guild_incident_report_raid = 38,
    guild_incident_report_false_alarm = 39,
    purchase_notification = 44,
    poll_result = 46,
};

/// Guild member flags, matching Discord.js `GuildMemberFlags`.
pub const GuildMemberFlags = struct {
    pub const Bit = u32;

    pub const did_rejoin: Bit = 1 << 0;
    pub const completed_onboarding: Bit = 1 << 1;
    pub const bypasses_verification: Bit = 1 << 2;
    pub const started_onboarding: Bit = 1 << 3;
    pub const is_guest: Bit = 1 << 4;
    pub const started_home_actions: Bit = 1 << 5;
    pub const completed_home_actions: Bit = 1 << 6;
    pub const automod_quarantined_username: Bit = 1 << 7;
    pub const dm_settings_upsell_acknowledged: Bit = 1 << 9;

    pub fn has(flags: Bit, flag: Bit) bool {
        return (flags & flag) == flag;
    }
};

pub const MessageReferenceInfo = struct {
    type: ?MessageReferenceType = null,
    message_id: ?Snowflake = null,
    channel_id: ?Snowflake = null,
    guild_id: ?Snowflake = null,
};

pub const MessageReferenceType = enum(u8) {
    default = 0,
    forward = 1,
};

pub const MessageSnapshot = struct {
    type: u8 = 0,
    content: []const u8 = "",
    timestamp: ?[]const u8 = null,
    edited_timestamp: ?[]const u8 = null,
    flags: ?u32 = null,
    mentions: []const User = &.{},
    mention_roles: []const Snowflake = &.{},
    embeds: []const Embed = &.{},
    attachments: []const Attachment = &.{},
    components: []const Interactions.Component = &.{},
};

pub const MessageCall = struct {
    participants: []const Snowflake = &.{},
    ended_timestamp: ?[]const u8 = null,
};

pub const RoleSubscriptionData = struct {
    role_subscription_listing_id: Snowflake,
    tier_name: []const u8,
    total_months_subscribed: u32,
    is_renewal: bool,
};

pub const SharedClientThemeBase = enum(u8) {
    unset = 0,
    dark = 1,
    light = 2,
    darker = 3,
    midnight = 4,
};

pub const SharedClientTheme = struct {
    colors: []const []const u8 = &.{},
    gradient_angle: u16 = 0,
    base_mix: u8 = 0,
    base_theme: ?SharedClientThemeBase = null,

    pub fn writeJson(self: SharedClientTheme, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        if (self.colors.len != 0) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"colors\":");
            try writeStringArray(self.colors, writer);
        }
        if (self.gradient_angle != 0) {
            try writeComma(writer, &needs_comma);
            try writer.print("\"gradient_angle\":{d}", .{self.gradient_angle});
        }
        if (self.base_mix != 0) {
            try writeComma(writer, &needs_comma);
            try writer.print("\"base_mix\":{d}", .{self.base_mix});
        }
        if (self.base_theme) |base_theme| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"base_theme\":{d}", .{@intFromEnum(base_theme)});
        }
        try writer.writeByte('}');
    }
};

pub const MessageActivityType = enum(u8) {
    join = 1,
    spectate = 2,
    listen = 3,
    join_request = 5,
};

pub const MessageActivity = struct {
    type: MessageActivityType,
    party_id: ?[]const u8 = null,
};

pub const MessageInteractionMetadata = struct {
    id: Snowflake,
    type: Interactions.InteractionType,
    user: User,
    original_response_message_id: ?Snowflake = null,
    interacted_message_id: ?Snowflake = null,
    target_user: ?User = null,
    target_message_id: ?Snowflake = null,
};

pub const Attachment = struct {
    id: Snowflake,
    filename: []const u8,
    description: ?[]const u8 = null,
    content_type: ?[]const u8 = null,
    size: u64 = 0,
    url: []const u8,
    proxy_url: []const u8,
    height: ?u32 = null,
    width: ?u32 = null,
    ephemeral: bool = false,
};

pub const ReactionEmoji = struct {
    id: ?Snowflake = null,
    name: ?[]const u8 = null,
    animated: bool = false,
};

pub const ReactionCountDetails = struct {
    burst: u32 = 0,
    normal: u32 = 0,
};

pub const ReactionType = enum(u8) {
    normal = 0,
    burst = 1,
};

pub const MessageReaction = struct {
    emoji: ReactionEmoji,
    count: u32 = 0,
    count_details: ReactionCountDetails = .{},
    me: bool = false,
    me_burst: bool = false,
    burst_colors: []const []const u8 = &.{},
};

pub const MessagePollMedia = struct {
    text: ?[]const u8 = null,
    emoji: ?PollEmoji = null,
};

pub const MessagePollAnswer = struct {
    answer_id: u32,
    poll_media: MessagePollMedia,
};

pub const MessagePollAnswerCount = struct {
    id: u32,
    count: u32,
    me_voted: bool = false,
};

pub const MessagePollResults = struct {
    is_finalized: bool = false,
    answer_counts: []const MessagePollAnswerCount = &.{},
};

pub const MessagePoll = struct {
    question: MessagePollMedia,
    answers: []const MessagePollAnswer = &.{},
    expiry: ?[]const u8 = null,
    allow_multiselect: bool = false,
    layout_type: ?u8 = null,
    results: ?MessagePollResults = null,
};

pub const EmbedMedia = struct {
    url: []const u8,

    pub fn init(url: []const u8) EmbedMedia {
        return .{ .url = url };
    }

    fn writeJson(self: EmbedMedia, writer: anytype) !void {
        try writer.writeAll("{\"url\":");
        try Json.writeString(self.url, writer);
        try writer.writeByte('}');
    }
};

pub const EmbedFooter = struct {
    text: []const u8,
    icon_url: ?[]const u8 = null,

    pub fn init(text: []const u8) EmbedFooter {
        return .{ .text = text };
    }

    pub fn withIcon(self: EmbedFooter, icon_url: []const u8) EmbedFooter {
        var footer = self;
        footer.icon_url = icon_url;
        return footer;
    }

    fn writeJson(self: EmbedFooter, writer: anytype) !void {
        try writer.writeAll("{\"text\":");
        try Json.writeString(self.text, writer);
        if (self.icon_url) |icon_url| {
            try writer.writeAll(",\"icon_url\":");
            try Json.writeString(icon_url, writer);
        }
        try writer.writeByte('}');
    }
};

pub const EmbedAuthor = struct {
    name: []const u8,
    url: ?[]const u8 = null,
    icon_url: ?[]const u8 = null,

    pub fn init(name: []const u8) EmbedAuthor {
        return .{ .name = name };
    }

    pub fn withUrl(self: EmbedAuthor, url: []const u8) EmbedAuthor {
        var author = self;
        author.url = url;
        return author;
    }

    pub fn withIcon(self: EmbedAuthor, icon_url: []const u8) EmbedAuthor {
        var author = self;
        author.icon_url = icon_url;
        return author;
    }

    fn writeJson(self: EmbedAuthor, writer: anytype) !void {
        try writer.writeAll("{\"name\":");
        try Json.writeString(self.name, writer);
        if (self.url) |url| {
            try writer.writeAll(",\"url\":");
            try Json.writeString(url, writer);
        }
        if (self.icon_url) |icon_url| {
            try writer.writeAll(",\"icon_url\":");
            try Json.writeString(icon_url, writer);
        }
        try writer.writeByte('}');
    }
};

pub const EmbedField = struct {
    name: []const u8,
    value: []const u8,
    is_inline: bool = false,

    /// Discord per-field character limits.
    pub const max_name_len = 256;
    pub const max_value_len = 1024;

    pub fn init(name: []const u8, value: []const u8) EmbedField {
        return .{ .name = name, .value = value };
    }

    pub fn inlineField(name: []const u8, value: []const u8) EmbedField {
        return .{ .name = name, .value = value, .is_inline = true };
    }

    pub fn inlineState(self: EmbedField, is_inline: bool) EmbedField {
        var field = self;
        field.is_inline = is_inline;
        return field;
    }

    fn writeJson(self: EmbedField, writer: anytype) !void {
        try writer.writeAll("{\"name\":");
        try Json.writeString(self.name, writer);
        try writer.writeAll(",\"value\":");
        try Json.writeString(self.value, writer);
        if (self.is_inline) try writer.writeAll(",\"inline\":true");
        try writer.writeByte('}');
    }
};
/// Common Discord brand and embed colors, matching Discord.js `Colors`. Values
/// are `0xRRGGBB` and usable anywhere a `u24` color is expected (embeds, roles).
pub const Colors = struct {
    pub const default: u24 = 0x000000;
    pub const white: u24 = 0xFFFFFF;
    pub const aqua: u24 = 0x1ABC9C;
    pub const green: u24 = 0x57F287;
    pub const blue: u24 = 0x3498DB;
    pub const yellow: u24 = 0xFEE75C;
    pub const purple: u24 = 0x9B59B6;
    pub const luminous_vivid_pink: u24 = 0xE91E63;
    pub const fuchsia: u24 = 0xEB459E;
    pub const gold: u24 = 0xF1C40F;
    pub const orange: u24 = 0xE67E22;
    pub const red: u24 = 0xED4245;
    pub const grey: u24 = 0x95A5A6;
    pub const navy: u24 = 0x34495E;
    pub const dark_aqua: u24 = 0x11806A;
    pub const dark_green: u24 = 0x1F8B4C;
    pub const dark_blue: u24 = 0x206694;
    pub const dark_purple: u24 = 0x71368A;
    pub const dark_vivid_pink: u24 = 0xAD1457;
    pub const dark_gold: u24 = 0xC27C0E;
    pub const dark_orange: u24 = 0xA84300;
    pub const dark_red: u24 = 0x992D22;
    pub const dark_grey: u24 = 0x979C9F;
    pub const darker_grey: u24 = 0x7F8C8D;
    pub const light_grey: u24 = 0xBCC0C0;
    pub const dark_navy: u24 = 0x2C3E50;
    pub const blurple: u24 = 0x5865F2;
    pub const greyple: u24 = 0x99AAB5;
    pub const dark_but_not_black: u24 = 0x2C2F33;
    pub const not_quite_black: u24 = 0x23272A;
};

pub const Embed = struct {
    title: ?[]const u8 = null,
    description: ?[]const u8 = null,
    url: ?[]const u8 = null,
    timestamp: ?[]const u8 = null,
    color: ?u24 = null,
    footer: ?EmbedFooter = null,
    image: ?EmbedMedia = null,
    thumbnail: ?EmbedMedia = null,
    author: ?EmbedAuthor = null,
    fields: []const EmbedField = &.{},

    pub fn init() Embed {
        return .{};
    }

    pub fn withTitle(self: Embed, title: []const u8) Embed {
        var embed = self;
        embed.title = title;
        return embed;
    }

    pub fn withDescription(self: Embed, description: []const u8) Embed {
        var embed = self;
        embed.description = description;
        return embed;
    }

    pub fn withUrl(self: Embed, url: []const u8) Embed {
        var embed = self;
        embed.url = url;
        return embed;
    }

    pub fn withTimestamp(self: Embed, timestamp: []const u8) Embed {
        var embed = self;
        embed.timestamp = timestamp;
        return embed;
    }

    pub fn withColor(self: Embed, color: u24) Embed {
        var embed = self;
        embed.color = color;
        return embed;
    }

    pub fn withFooter(self: Embed, footer: EmbedFooter) Embed {
        var embed = self;
        embed.footer = footer;
        return embed;
    }

    pub fn withImage(self: Embed, image_url: []const u8) Embed {
        var embed = self;
        embed.image = EmbedMedia.init(image_url);
        return embed;
    }

    pub fn withThumbnail(self: Embed, thumbnail_url: []const u8) Embed {
        var embed = self;
        embed.thumbnail = EmbedMedia.init(thumbnail_url);
        return embed;
    }

    pub fn withAuthor(self: Embed, author: EmbedAuthor) Embed {
        var embed = self;
        embed.author = author;
        return embed;
    }

    pub fn withFields(self: Embed, fields: []const EmbedField) Embed {
        var embed = self;
        embed.fields = fields;
        return embed;
    }

    pub fn withField(self: Embed, field: *const EmbedField) Embed {
        var embed = self;
        embed.fields = field[0..1];
        return embed;
    }

    /// Discord embed character/count limits.
    pub const max_fields = 25;
    pub const max_title_len = 256;
    pub const max_description_len = 4096;
    pub const max_footer_len = 2048;
    pub const max_author_name_len = 256;
    /// Combined character budget across title, description, field names/values,
    /// footer text, and author name for a single embed.
    pub const max_total_len = 6000;

    pub const ValidationError = error{
        TooManyFields,
        TitleTooLong,
        DescriptionTooLong,
        FooterTooLong,
        AuthorNameTooLong,
        FieldNameTooLong,
        FieldValueTooLong,
        EmbedTooLong,
        InvalidUtf8,
    };

    /// Rejects an embed that violates a documented Discord limit, turning a
    /// guaranteed API rejection into a local, allocation-free error. Lengths are
    /// measured in Unicode code points, matching how Discord counts characters.
    pub fn validate(self: Embed) ValidationError!void {
        if (self.fields.len > max_fields) return error.TooManyFields;
        var total: usize = 0;
        if (self.title) |title| {
            const len = try Json.codepointLen(title);
            if (len > max_title_len) return error.TitleTooLong;
            total += len;
        }
        if (self.description) |description| {
            const len = try Json.codepointLen(description);
            if (len > max_description_len) return error.DescriptionTooLong;
            total += len;
        }
        if (self.footer) |footer| {
            const len = try Json.codepointLen(footer.text);
            if (len > max_footer_len) return error.FooterTooLong;
            total += len;
        }
        if (self.author) |author| {
            const len = try Json.codepointLen(author.name);
            if (len > max_author_name_len) return error.AuthorNameTooLong;
            total += len;
        }
        for (self.fields) |field| {
            const name_len = try Json.codepointLen(field.name);
            if (name_len > EmbedField.max_name_len) return error.FieldNameTooLong;
            const value_len = try Json.codepointLen(field.value);
            if (value_len > EmbedField.max_value_len) return error.FieldValueTooLong;
            total += name_len + value_len;
        }
        if (total > max_total_len) return error.EmbedTooLong;
    }

    pub fn writeJson(self: Embed, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        try writeOptionalStringField(writer, &needs_comma, "title", self.title);
        try writeOptionalStringField(writer, &needs_comma, "description", self.description);
        try writeOptionalStringField(writer, &needs_comma, "url", self.url);
        try writeOptionalStringField(writer, &needs_comma, "timestamp", self.timestamp);
        if (self.color) |color| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"color\":{d}", .{color});
        }
        if (self.footer) |footer| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"footer\":");
            try footer.writeJson(writer);
        }
        if (self.image) |image| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"image\":");
            try image.writeJson(writer);
        }
        if (self.thumbnail) |thumbnail| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"thumbnail\":");
            try thumbnail.writeJson(writer);
        }
        if (self.author) |author| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"author\":");
            try author.writeJson(writer);
        }
        if (self.fields.len != 0) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"fields\":");
            try writeEmbedFieldArray(self.fields, writer);
        }
        try writer.writeByte('}');
    }
};

pub const AllowedMentionType = enum {
    roles,
    users,
    everyone,
};

pub const AllowedMentions = struct {
    parse: []const AllowedMentionType = &.{},
    users: []const Snowflake = &.{},
    roles: []const Snowflake = &.{},
    replied_user: bool = false,

    pub fn none() AllowedMentions {
        return .{};
    }

    pub fn all() AllowedMentions {
        return .{ .parse = &.{ .roles, .users, .everyone } };
    }

    pub fn usersOnly() AllowedMentions {
        return .{ .parse = &.{.users} };
    }

    pub fn rolesOnly() AllowedMentions {
        return .{ .parse = &.{.roles} };
    }

    pub fn everyoneOnly() AllowedMentions {
        return .{ .parse = &.{.everyone} };
    }

    pub fn repliedUserOnly() AllowedMentions {
        return .{ .replied_user = true };
    }

    pub fn withUsers(self: AllowedMentions, users: []const Snowflake) AllowedMentions {
        var mentions = self;
        mentions.users = users;
        return mentions;
    }

    pub fn withUser(self: AllowedMentions, user: *const Snowflake) AllowedMentions {
        var mentions = self;
        mentions.users = user[0..1];
        return mentions;
    }

    pub fn withRoles(self: AllowedMentions, roles: []const Snowflake) AllowedMentions {
        var mentions = self;
        mentions.roles = roles;
        return mentions;
    }

    pub fn withRole(self: AllowedMentions, role: *const Snowflake) AllowedMentions {
        var mentions = self;
        mentions.roles = role[0..1];
        return mentions;
    }

    pub fn withParse(self: AllowedMentions, parse: []const AllowedMentionType) AllowedMentions {
        var mentions = self;
        mentions.parse = parse;
        return mentions;
    }

    pub fn repliedUser(self: AllowedMentions, allow: bool) AllowedMentions {
        var mentions = self;
        mentions.replied_user = allow;
        return mentions;
    }

    /// Discord allows at most 100 explicit user and 100 explicit role mentions.
    pub const max_users = 100;
    pub const max_roles = 100;

    pub const ValidationError = error{
        TooManyUsers,
        TooManyRoles,
        UserParseConflict,
        RoleParseConflict,
    };

    /// Rejects an allowed-mentions payload Discord would reject: more than 100
    /// explicit ids of either kind, or an explicit allowlist combined with the
    /// matching broad `parse` entry (Discord forbids mixing the two).
    pub fn validate(self: AllowedMentions) ValidationError!void {
        if (self.users.len > max_users) return error.TooManyUsers;
        if (self.roles.len > max_roles) return error.TooManyRoles;
        for (self.parse) |kind| {
            switch (kind) {
                .users => if (self.users.len != 0) return error.UserParseConflict,
                .roles => if (self.roles.len != 0) return error.RoleParseConflict,
                .everyone => {},
            }
        }
    }

    pub fn writeJson(self: AllowedMentions, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"parse\":");
        try writeAllowedMentionTypeArray(self.parse, writer);
        if (self.users.len != 0) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"users\":");
            try writeSnowflakeStringArray(self.users, writer);
        }
        if (self.roles.len != 0) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"roles\":");
            try writeSnowflakeStringArray(self.roles, writer);
        }
        if (self.replied_user) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"replied_user\":true");
        }
        try writer.writeByte('}');
    }
};

pub const PollLayoutType = enum(u8) {
    default = 1,
};

pub const PollEmoji = struct {
    id: ?Snowflake = null,
    name: ?[]const u8 = null,

    pub fn unicode(name: []const u8) PollEmoji {
        return .{ .name = name };
    }

    pub fn custom(id: Snowflake) PollEmoji {
        return .{ .id = id };
    }

    pub fn writeJson(self: PollEmoji, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        if (self.id) |id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"id\":\"{d}\"", .{id.value});
        }
        try writeOptionalStringField(writer, &needs_comma, "name", self.name);
        try writer.writeByte('}');
    }
};

pub const PollMedia = struct {
    text: []const u8,
    emoji: ?PollEmoji = null,

    pub fn textOnly(text: []const u8) PollMedia {
        return .{ .text = text };
    }

    pub fn withEmoji(text: []const u8, emoji: PollEmoji) PollMedia {
        return .{ .text = text, .emoji = emoji };
    }

    pub fn writeJson(self: PollMedia, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"text\":");
        try Json.writeString(self.text, writer);
        if (self.emoji) |emoji| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"emoji\":");
            try emoji.writeJson(writer);
        }

        try writer.writeByte('}');
    }
};

pub const PollAnswer = struct {
    poll_media: PollMedia,

    pub fn text(value: []const u8) PollAnswer {
        return .{ .poll_media = PollMedia.textOnly(value) };
    }

    pub fn withEmoji(value: []const u8, emoji: PollEmoji) PollAnswer {
        return .{ .poll_media = PollMedia.withEmoji(value, emoji) };
    }

    pub fn writeJson(self: PollAnswer, writer: anytype) !void {
        try writer.writeAll("{\"poll_media\":");
        try self.poll_media.writeJson(writer);
        try writer.writeByte('}');
    }
};

pub const CreatePoll = struct {
    question: PollMedia,
    answers: []const PollAnswer,
    duration: ?u16 = null,
    allow_multiselect: ?bool = null,
    layout_type: ?PollLayoutType = null,

    pub fn init(question: []const u8, answers: []const PollAnswer) CreatePoll {
        return .{ .question = PollMedia.textOnly(question), .answers = answers };
    }

    pub fn withQuestionEmoji(self: CreatePoll, emoji: PollEmoji) CreatePoll {
        var poll = self;
        poll.question.emoji = emoji;
        return poll;
    }

    pub fn withDuration(self: CreatePoll, duration: u16) CreatePoll {
        var poll = self;
        poll.duration = duration;
        return poll;
    }

    pub fn multiselect(self: CreatePoll, allow_multiselect: bool) CreatePoll {
        var poll = self;
        poll.allow_multiselect = allow_multiselect;
        return poll;
    }

    pub fn withLayout(self: CreatePoll, layout_type: PollLayoutType) CreatePoll {
        var poll = self;
        poll.layout_type = layout_type;
        return poll;
    }

    pub fn writeJson(self: CreatePoll, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"question\":");
        try self.question.writeJson(writer);

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"answers\":");
        try writePollAnswerArray(self.answers, writer);

        if (self.duration) |duration| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"duration\":{d}", .{duration});
        }
        try writeOptionalBoolField(writer, &needs_comma, "allow_multiselect", self.allow_multiselect);
        if (self.layout_type) |layout_type| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"layout_type\":{d}", .{@intFromEnum(layout_type)});
        }

        try writer.writeByte('}');
    }
};

pub const max_message_content_len = 2000;
pub const max_message_nonce_len = 25;
pub const max_message_embeds = 10;
pub const max_message_stickers = 3;

pub const MessageValidationError = error{
    ContentTooLong,
    NonceTooLong,
    TooManyEmbeds,
    TooManyStickers,
    ComponentsV2Exclusive,
    TooManyFields,
    TitleTooLong,
    DescriptionTooLong,
    FooterTooLong,
    AuthorNameTooLong,
    FieldNameTooLong,
    FieldValueTooLong,
    EmbedTooLong,
    TooManyUsers,
    TooManyRoles,
    UserParseConflict,
    RoleParseConflict,
    TooManyActionRows,
    TooManyRowComponents,
    TooManySelectOptions,
    TooManyCommandOptions,
    TooManyCommandChoices,
    CustomIdTooLong,
    ButtonLabelTooLong,
    ButtonCustomIdRequired,
    ButtonUrlRequired,
    ButtonSkuIdRequired,
    ButtonFieldConflict,
    SelectPlaceholderTooLong,
    SelectOptionLabelTooLong,
    SelectOptionValueTooLong,
    SelectOptionDescriptionTooLong,
    SelectValueRangeInvalid,
    TextInputLabelTooLong,
    TextInputPlaceholderTooLong,
    TextInputValueTooLong,
    CommandNameInvalid,
    CommandDescriptionInvalid,
    OptionNameInvalid,
    OptionDescriptionInvalid,
    ChoiceNameTooLong,
    ChoiceValueTooLong,
    SectionComponentCountInvalid,
    MediaGalleryItemCountInvalid,
    InvalidUtf8,
};

fn validateMessagePayload(
    content: ?[]const u8,
    flags: ?MessageFlags.Bit,
    embeds: []const Embed,
    sticker_ids: []const Snowflake,
    allowed_mentions: ?AllowedMentions,
    components: []const Interactions.Component,
    poll: ?CreatePoll,
    shared_client_theme: ?SharedClientTheme,
) MessageValidationError!void {
    if (content) |value| {
        const len = try Json.codepointLen(value);
        if (len > max_message_content_len) return error.ContentTooLong;
    }
    if (embeds.len > max_message_embeds) return error.TooManyEmbeds;
    for (embeds) |embed| try embed.validate();
    if (sticker_ids.len > max_message_stickers) return error.TooManyStickers;
    if (allowed_mentions) |mentions| try mentions.validate();
    try Interactions.Component.validateLayout(components);

    if (flags) |bits| {
        if ((bits & MessageFlags.is_components_v2) != 0) {
            var has_non_component_body = embeds.len != 0 or
                sticker_ids.len != 0 or
                poll != null or
                shared_client_theme != null;
            if (content) |value| has_non_component_body = has_non_component_body or value.len != 0;
            if (has_non_component_body) return error.ComponentsV2Exclusive;
        }
    }
}

pub const CreateMessage = struct {
    content: []const u8 = "",
    nonce: ?[]const u8 = null,
    enforce_nonce: bool = false,
    tts: bool = false,
    flags: ?MessageFlags.Bit = null,
    embeds: []const Embed = &.{},
    sticker_ids: []const Snowflake = &.{},
    allowed_mentions: ?AllowedMentions = null,
    components: []const Interactions.Component = &.{},
    message_reference: ?MessageReference = null,
    poll: ?CreatePoll = null,
    shared_client_theme: ?SharedClientTheme = null,

    pub fn init(content: []const u8) CreateMessage {
        return .{ .content = content };
    }

    pub fn empty() CreateMessage {
        return .{};
    }

    pub fn withNonce(self: CreateMessage, nonce: []const u8, enforce: bool) CreateMessage {
        var message = self;
        message.nonce = nonce;
        message.enforce_nonce = enforce;
        return message;
    }

    pub fn ttsState(self: CreateMessage, tts: bool) CreateMessage {
        var message = self;
        message.tts = tts;
        return message;
    }

    pub fn withFlags(self: CreateMessage, flags: MessageFlags.Bit) CreateMessage {
        var message = self;
        message.flags = flags;
        return message;
    }

    pub fn withEmbeds(self: CreateMessage, embeds: []const Embed) CreateMessage {
        var message = self;
        message.embeds = embeds;
        return message;
    }

    pub fn withStickers(self: CreateMessage, sticker_ids: []const Snowflake) CreateMessage {
        var message = self;
        message.sticker_ids = sticker_ids;
        return message;
    }

    pub fn withAllowedMentions(self: CreateMessage, allowed_mentions: AllowedMentions) CreateMessage {
        var message = self;
        message.allowed_mentions = allowed_mentions;
        return message;
    }

    pub fn withComponents(self: CreateMessage, components: []const Interactions.Component) CreateMessage {
        var message = self;
        message.components = components;
        return message;
    }

    pub fn withReference(self: CreateMessage, message_reference: MessageReference) CreateMessage {
        var message = self;
        message.message_reference = message_reference;
        return message;
    }

    pub fn withPoll(self: CreateMessage, poll: CreatePoll) CreateMessage {
        var message = self;
        message.poll = poll;
        return message;
    }

    pub fn withSharedClientTheme(self: CreateMessage, shared_client_theme: SharedClientTheme) CreateMessage {
        var message = self;
        message.shared_client_theme = shared_client_theme;
        return message;
    }

    pub fn validate(self: CreateMessage) MessageValidationError!void {
        try validateMessagePayload(
            if (self.content.len != 0) self.content else null,
            self.flags,
            self.embeds,
            self.sticker_ids,
            self.allowed_mentions,
            self.components,
            self.poll,
            self.shared_client_theme,
        );
        if (self.nonce) |nonce| {
            const len = try Json.codepointLen(nonce);
            if (len > max_message_nonce_len) return error.NonceTooLong;
        }
    }

    pub fn writeJson(self: CreateMessage, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        try writeMessagePayloadFields(.{
            .content = if (self.content.len != 0) self.content else null,
            .embeds = self.embeds,
            .sticker_ids = self.sticker_ids,
            .allowed_mentions = self.allowed_mentions,
            .components = self.components,
            .poll = self.poll,
            .flags = self.flags,
            .shared_client_theme = self.shared_client_theme,
        }, writer, &needs_comma);
        if (self.nonce) |nonce| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"nonce\":");
            try Json.writeString(nonce, writer);
        }
        if (self.enforce_nonce) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"enforce_nonce\":true");
        }
        if (self.tts) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"tts\":true");
        }
        if (self.message_reference) |reference| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"message_reference\":");
            try reference.writeJson(writer);
        }
        try writer.writeByte('}');
    }
};

pub const ListMessages = struct {
    around: ?Snowflake = null,
    before: ?Snowflake = null,
    after: ?Snowflake = null,
    limit: ?u8 = null,

    pub fn init() ListMessages {
        return .{};
    }

    pub fn aroundMessage(message_id: Snowflake) ListMessages {
        return .{ .around = message_id };
    }

    pub fn beforeMessage(message_id: Snowflake) ListMessages {
        return .{ .before = message_id };
    }

    pub fn afterMessage(message_id: Snowflake) ListMessages {
        return .{ .after = message_id };
    }

    pub fn withLimit(self: ListMessages, limit: u8) ListMessages {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn hasQuery(self: ListMessages) bool {
        return self.around != null or self.before != null or self.after != null or self.limit != null;
    }

    pub fn writeQuery(self: ListMessages, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.around) |around| try writeSnowflakeQueryParam(writer, &needs_ampersand, "around", around);
        if (self.before) |before| try writeSnowflakeQueryParam(writer, &needs_ampersand, "before", before);
        if (self.after) |after| try writeSnowflakeQueryParam(writer, &needs_ampersand, "after", after);
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
    }
};

pub const ListReactions = struct {
    after: ?Snowflake = null,
    limit: ?u8 = null,
    type: ?ReactionType = null,

    pub fn init() ListReactions {
        return .{};
    }

    pub fn afterUser(user_id: Snowflake) ListReactions {
        return .{ .after = user_id };
    }

    pub fn withLimit(self: ListReactions, limit: u8) ListReactions {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn withType(self: ListReactions, reaction_type: ReactionType) ListReactions {
        var options = self;
        options.type = reaction_type;
        return options;
    }

    pub fn hasQuery(self: ListReactions) bool {
        return self.after != null or self.limit != null or self.type != null;
    }

    pub fn writeQuery(self: ListReactions, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.after) |after| try writeSnowflakeQueryParam(writer, &needs_ampersand, "after", after);
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
        if (self.type) |reaction_type| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("type={d}", .{@intFromEnum(reaction_type)});
        }
    }
};

pub const ListPollAnswerVoters = struct {
    after: ?Snowflake = null,
    limit: ?u8 = null,

    pub fn init() ListPollAnswerVoters {
        return .{};
    }

    pub fn afterUser(user_id: Snowflake) ListPollAnswerVoters {
        return .{ .after = user_id };
    }

    pub fn withLimit(self: ListPollAnswerVoters, limit: u8) ListPollAnswerVoters {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn hasQuery(self: ListPollAnswerVoters) bool {
        return self.after != null or self.limit != null;
    }

    pub fn writeQuery(self: ListPollAnswerVoters, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.after) |after| try writeSnowflakeQueryParam(writer, &needs_ampersand, "after", after);
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
    }
};

pub const ListArchivedThreads = struct {
    before: ?[]const u8 = null,
    limit: ?u8 = null,

    pub fn init() ListArchivedThreads {
        return .{};
    }

    pub fn beforeTimestamp(before: []const u8) ListArchivedThreads {
        return .{ .before = before };
    }

    pub fn withLimit(self: ListArchivedThreads, limit: u8) ListArchivedThreads {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn hasQuery(self: ListArchivedThreads) bool {
        return self.before != null or self.limit != null;
    }

    pub fn writeQuery(self: ListArchivedThreads, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.before) |before| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.writeAll("before=");
            try writeQueryStringValue(before, writer);
        }
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
    }
};

pub const ListThreadMembers = struct {
    with_member: ?bool = null,
    after: ?Snowflake = null,
    limit: ?u16 = null,

    pub fn init() ListThreadMembers {
        return .{};
    }

    pub fn withMemberExpansion(self: ListThreadMembers, with_member: bool) ListThreadMembers {
        var options = self;
        options.with_member = with_member;
        return options;
    }

    pub fn afterMember(self: ListThreadMembers, user_id: Snowflake) ListThreadMembers {
        var options = self;
        options.after = user_id;
        return options;
    }

    pub fn withLimit(self: ListThreadMembers, limit: u16) ListThreadMembers {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn hasQuery(self: ListThreadMembers) bool {
        return self.with_member != null or self.after != null or self.limit != null;
    }

    pub fn writeQuery(self: ListThreadMembers, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.with_member) |with_member| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("with_member={}", .{with_member});
        }
        if (self.after) |after| try writeSnowflakeQueryParam(writer, &needs_ampersand, "after", after);
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
    }
};

pub const ListChannelPins = struct {
    before: ?[]const u8 = null,
    limit: ?u8 = null,

    pub fn init() ListChannelPins {
        return .{};
    }

    pub fn beforeTimestamp(before: []const u8) ListChannelPins {
        return .{ .before = before };
    }

    pub fn withLimit(self: ListChannelPins, limit: u8) ListChannelPins {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn hasQuery(self: ListChannelPins) bool {
        return self.before != null or self.limit != null;
    }

    pub fn writeQuery(self: ListChannelPins, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.before) |before| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.writeAll("before=");
            try writeQueryStringValue(before, writer);
        }
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
    }
};

pub const EditMessage = struct {
    content: ?[]const u8 = null,
    flags: ?MessageFlags.Bit = null,
    embeds: []const Embed = &.{},
    allowed_mentions: ?AllowedMentions = null,
    components: []const Interactions.Component = &.{},

    pub fn init() EditMessage {
        return .{};
    }

    pub fn withContent(self: EditMessage, content: []const u8) EditMessage {
        var message = self;
        message.content = content;
        return message;
    }

    pub fn withFlags(self: EditMessage, flags: MessageFlags.Bit) EditMessage {
        var message = self;
        message.flags = flags;
        return message;
    }

    pub fn withEmbeds(self: EditMessage, embeds: []const Embed) EditMessage {
        var message = self;
        message.embeds = embeds;
        return message;
    }

    pub fn withAllowedMentions(self: EditMessage, allowed_mentions: AllowedMentions) EditMessage {
        var message = self;
        message.allowed_mentions = allowed_mentions;
        return message;
    }

    pub fn withComponents(self: EditMessage, components: []const Interactions.Component) EditMessage {
        var message = self;
        message.components = components;
        return message;
    }

    pub fn validate(self: EditMessage) MessageValidationError!void {
        try validateMessagePayload(
            self.content,
            self.flags,
            self.embeds,
            &.{},
            self.allowed_mentions,
            self.components,
            null,
            null,
        );
    }

    pub fn writeJson(self: EditMessage, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        try writeMessagePayloadFields(.{
            .content = self.content,
            .embeds = self.embeds,
            .allowed_mentions = self.allowed_mentions,
            .components = self.components,
            .flags = self.flags,
        }, writer, &needs_comma);
        try writer.writeByte('}');
    }
};

pub const BulkDeleteMessages = struct {
    messages: []const Snowflake,

    pub fn writeJson(self: BulkDeleteMessages, writer: anytype) !void {
        try writer.writeAll("{\"messages\":");
        try writeSnowflakeStringArray(self.messages, writer);
        try writer.writeByte('}');
    }
};

pub const MessageReference = struct {
    type: ?MessageReferenceType = null,
    message_id: Snowflake,
    channel_id: ?Snowflake = null,
    guild_id: ?Snowflake = null,
    fail_if_not_exists: bool = true,

    pub fn writeJson(self: MessageReference, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        if (self.type) |reference_type| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"type\":{d}", .{@intFromEnum(reference_type)});
        }
        try writeComma(writer, &needs_comma);
        try writer.print("\"message_id\":\"{d}\"", .{self.message_id.value});
        if (self.channel_id) |channel_id| try writer.print(",\"channel_id\":\"{d}\"", .{channel_id.value});
        if (self.guild_id) |guild_id| try writer.print(",\"guild_id\":\"{d}\"", .{guild_id.value});
        if (!self.fail_if_not_exists) try writer.writeAll(",\"fail_if_not_exists\":false");
        try writer.writeByte('}');
    }

    pub fn reply(message_id: Snowflake) MessageReference {
        return .{ .type = .default, .message_id = message_id };
    }

    pub fn forward(message_id: Snowflake, channel_id: Snowflake) MessageReference {
        return .{ .type = .forward, .message_id = message_id, .channel_id = channel_id };
    }
};

pub const UploadFile = struct {
    filename: []const u8,
    content: []const u8,
    content_type: []const u8 = "application/octet-stream",
    description: ?[]const u8 = null,

    pub fn init(filename: []const u8, content: []const u8) UploadFile {
        return .{ .filename = filename, .content = content };
    }

    pub fn withContentType(self: UploadFile, content_type: []const u8) UploadFile {
        var file = self;
        file.content_type = content_type;
        return file;
    }

    pub fn withDescription(self: UploadFile, description: []const u8) UploadFile {
        var file = self;
        file.description = description;
        return file;
    }
};

pub const UploadFilePath = struct {
    filename: []const u8,
    path: []const u8,
    content_type: []const u8 = "application/octet-stream",
    description: ?[]const u8 = null,

    pub fn init(filename: []const u8, path: []const u8) UploadFilePath {
        return .{ .filename = filename, .path = path };
    }

    pub fn withContentType(self: UploadFilePath, content_type: []const u8) UploadFilePath {
        var file = self;
        file.content_type = content_type;
        return file;
    }

    pub fn withDescription(self: UploadFilePath, description: []const u8) UploadFilePath {
        var file = self;
        file.description = description;
        return file;
    }
};

pub const EmbedBuilder = Embed;
pub const AttachmentBuilder = UploadFile;
pub const AttachmentPathBuilder = UploadFilePath;
pub const AllowedMentionsBuilder = AllowedMentions;
pub const PollBuilder = CreatePoll;

pub fn writeCreateMessageJsonWithAttachments(
    payload: CreateMessage,
    files: []const UploadFile,
    writer: anytype,
) !void {
    try writeCreateMessageJsonWithAttachmentMetadata(payload, files, writer);
}

pub fn writeCreateMessageJsonWithAttachmentMetadata(
    payload: CreateMessage,
    files: anytype,
    writer: anytype,
) !void {
    try writer.writeByte('{');
    var needs_comma = false;
    if (payload.content.len != 0) {
        try writeMessagePayloadFields(.{
            .content = payload.content,
            .embeds = payload.embeds,
            .sticker_ids = payload.sticker_ids,
            .allowed_mentions = payload.allowed_mentions,
            .components = payload.components,
            .poll = payload.poll,
            .flags = payload.flags,
            .shared_client_theme = payload.shared_client_theme,
        }, writer, &needs_comma);
    }
    if (payload.nonce) |nonce| {
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"nonce\":");
        try Json.writeString(nonce, writer);
    }
    if (payload.enforce_nonce) {
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"enforce_nonce\":true");
    }
    if (payload.tts) {
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"tts\":true");
    }
    if (payload.content.len == 0) {
        try writeMessagePayloadFields(.{
            .content = null,
            .embeds = payload.embeds,
            .sticker_ids = payload.sticker_ids,
            .allowed_mentions = payload.allowed_mentions,
            .components = payload.components,
            .poll = payload.poll,
            .flags = payload.flags,
            .shared_client_theme = payload.shared_client_theme,
        }, writer, &needs_comma);
    }
    if (files.len != 0) {
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"attachments\":");
        try writeUploadAttachmentArray(files, writer);
    }
    try writer.writeByte('}');
}

const MessagePayloadFields = struct {
    content: ?[]const u8 = null,
    embeds: []const Embed = &.{},
    sticker_ids: []const Snowflake = &.{},
    allowed_mentions: ?AllowedMentions = null,
    components: []const Interactions.Component = &.{},
    poll: ?CreatePoll = null,
    flags: ?MessageFlags.Bit = null,
    shared_client_theme: ?SharedClientTheme = null,
};

const ChannelFields = struct {
    type: ?ChannelType = null,
    topic: ?[]const u8 = null,
    nsfw: bool = false,
    rate_limit_per_user: ?u16 = null,
    bitrate: ?u32 = null,
    user_limit: ?u16 = null,
    flags: ?ChannelFlags.Bit = null,
    parent_id: ?Snowflake = null,
    position: ?i32 = null,
    available_tags: ?[]const WriteForumTag = null,
    default_reaction_emoji: ?DefaultReactionEmoji = null,
    default_thread_rate_limit_per_user: ?u16 = null,
    default_sort_order: ?ChannelSortOrder = null,
    default_forum_layout: ?ForumLayout = null,
};

const RoleFields = struct {
    permissions: ?Permissions.Bit = null,
    color: ?u24 = null,
    colors: ?RoleColors = null,
    hoist: ?bool = null,
    icon: ?[]const u8 = null,
    clear_icon: bool = false,
    unicode_emoji: ?[]const u8 = null,
    clear_unicode_emoji: bool = false,
    mentionable: ?bool = null,
};

const ThreadFields = struct {
    auto_archive_duration: ?u16 = null,
    rate_limit_per_user: ?u16 = null,
    invitable: ?bool = null,
};

const ThreadEditFields = struct {
    archived: ?bool = null,
    auto_archive_duration: ?u16 = null,
    locked: ?bool = null,
    invitable: ?bool = null,
    applied_tags: ?[]const Snowflake = null,
};

fn writeRoleFields(fields: RoleFields, writer: anytype, needs_comma: *bool) !void {
    if (fields.permissions) |permissions| {
        try writeComma(writer, needs_comma);
        try writer.print("\"permissions\":\"{d}\"", .{permissions});
    }
    if (fields.color) |color| {
        try writeComma(writer, needs_comma);
        try writer.print("\"color\":{d}", .{color});
    }
    if (fields.colors) |colors| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"colors\":");
        try colors.writeJson(writer);
    }
    if (fields.hoist) |hoist| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"hoist\":");
        try writer.writeAll(if (hoist) "true" else "false");
    }
    try writeNullableStringField(writer, needs_comma, "icon", fields.icon, fields.clear_icon);
    try writeNullableStringField(
        writer,
        needs_comma,
        "unicode_emoji",
        fields.unicode_emoji,
        fields.clear_unicode_emoji,
    );
    if (fields.mentionable) |mentionable| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"mentionable\":");
        try writer.writeAll(if (mentionable) "true" else "false");
    }
}

fn writeThreadFields(fields: ThreadFields, writer: anytype, needs_comma: *bool) !void {
    if (fields.auto_archive_duration) |duration| {
        try writeComma(writer, needs_comma);
        try writer.print("\"auto_archive_duration\":{d}", .{duration});
    }
    if (fields.rate_limit_per_user) |rate_limit_per_user| {
        try writeComma(writer, needs_comma);
        try writer.print("\"rate_limit_per_user\":{d}", .{rate_limit_per_user});
    }
    try writeOptionalBoolField(writer, needs_comma, "invitable", fields.invitable);
}

fn writeThreadEditFields(fields: ThreadEditFields, writer: anytype, needs_comma: *bool) !void {
    try writeOptionalBoolField(writer, needs_comma, "archived", fields.archived);
    if (fields.auto_archive_duration) |duration| {
        try writeComma(writer, needs_comma);
        try writer.print("\"auto_archive_duration\":{d}", .{duration});
    }
    try writeOptionalBoolField(writer, needs_comma, "locked", fields.locked);
    try writeOptionalBoolField(writer, needs_comma, "invitable", fields.invitable);
    if (fields.applied_tags) |applied_tags| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"applied_tags\":");
        try writeSnowflakeStringArray(applied_tags, writer);
    }
}

fn writeChannelFields(fields: ChannelFields, writer: anytype, needs_comma: *bool) !void {
    if (fields.type) |channel_type| {
        try writeComma(writer, needs_comma);
        try writer.print("\"type\":{d}", .{@intFromEnum(channel_type)});
    }
    try writeOptionalStringField(writer, needs_comma, "topic", fields.topic);
    if (fields.nsfw) {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"nsfw\":true");
    }
    if (fields.rate_limit_per_user) |rate_limit_per_user| {
        try writeComma(writer, needs_comma);
        try writer.print("\"rate_limit_per_user\":{d}", .{rate_limit_per_user});
    }
    if (fields.bitrate) |bitrate| {
        try writeComma(writer, needs_comma);
        try writer.print("\"bitrate\":{d}", .{bitrate});
    }
    if (fields.user_limit) |user_limit| {
        try writeComma(writer, needs_comma);
        try writer.print("\"user_limit\":{d}", .{user_limit});
    }
    if (fields.flags) |flags| {
        try writeComma(writer, needs_comma);
        try writer.print("\"flags\":{d}", .{flags});
    }
    if (fields.parent_id) |parent_id| {
        try writeComma(writer, needs_comma);
        try writer.print("\"parent_id\":\"{d}\"", .{parent_id.value});
    }
    if (fields.position) |position| {
        try writeComma(writer, needs_comma);
        try writer.print("\"position\":{d}", .{position});
    }
    if (fields.available_tags) |available_tags| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"available_tags\":");
        try writeForumTagArray(available_tags, writer);
    }
    if (fields.default_reaction_emoji) |default_reaction_emoji| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"default_reaction_emoji\":");
        try default_reaction_emoji.writeJson(writer);
    }
    if (fields.default_thread_rate_limit_per_user) |rate_limit| {
        try writeComma(writer, needs_comma);
        try writer.print("\"default_thread_rate_limit_per_user\":{d}", .{rate_limit});
    }
    if (fields.default_sort_order) |sort_order| {
        try writeComma(writer, needs_comma);
        try writer.print("\"default_sort_order\":{d}", .{@intFromEnum(sort_order)});
    }
    if (fields.default_forum_layout) |layout| {
        try writeComma(writer, needs_comma);
        try writer.print("\"default_forum_layout\":{d}", .{@intFromEnum(layout)});
    }
}

fn writeForumTagArray(tags: []const WriteForumTag, writer: anytype) !void {
    try writer.writeByte('[');
    for (tags, 0..) |tag, index| {
        if (index != 0) try writer.writeByte(',');
        try tag.writeJson(writer);
    }
    try writer.writeByte(']');
}

fn writeMessagePayloadFields(fields: MessagePayloadFields, writer: anytype, needs_comma: *bool) !void {
    if (fields.content) |content| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"content\":");
        try Json.writeString(content, writer);
    }
    if (fields.embeds.len != 0) {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"embeds\":");
        try writeEmbedArray(fields.embeds, writer);
    }
    if (fields.sticker_ids.len != 0) {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"sticker_ids\":");
        try writeSnowflakeStringArray(fields.sticker_ids, writer);
    }
    if (fields.allowed_mentions) |allowed_mentions| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"allowed_mentions\":");
        try allowed_mentions.writeJson(writer);
    }
    if (fields.components.len != 0) {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"components\":");
        try Interactions.writeComponentArray(fields.components, writer);
    }
    if (fields.poll) |poll| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"poll\":");
        try poll.writeJson(writer);
    }
    if (fields.shared_client_theme) |shared_client_theme| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"shared_client_theme\":");
        try shared_client_theme.writeJson(writer);
    }
    if (fields.flags) |flags| {
        try writeComma(writer, needs_comma);
        try writer.print("\"flags\":{d}", .{flags});
    }
}

pub fn writeEmbedArray(embeds: []const Embed, writer: anytype) !void {
    try writer.writeByte('[');
    for (embeds, 0..) |embed, index| {
        if (index != 0) try writer.writeByte(',');
        try embed.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn writePollAnswerArray(answers: []const PollAnswer, writer: anytype) !void {
    try writer.writeByte('[');
    for (answers, 0..) |answer, index| {
        if (index != 0) try writer.writeByte(',');
        try answer.writeJson(writer);
    }
    try writer.writeByte(']');
}

fn writeUploadAttachmentArray(files: anytype, writer: anytype) !void {
    try writer.writeByte('[');
    for (files, 0..) |file, index| {
        if (index != 0) try writer.writeByte(',');
        try writer.print("{{\"id\":\"{d}\",\"filename\":", .{index});
        try Json.writeString(file.filename, writer);
        if (file.description) |description| {
            try writer.writeAll(",\"description\":");
            try Json.writeString(description, writer);
        }
        try writer.writeByte('}');
    }
    try writer.writeByte(']');
}

fn writeCreateGuildRoleArray(roles: []const CreateGuildRole, writer: anytype) !void {
    try writer.writeByte('[');
    for (roles, 0..) |role, index| {
        if (index != 0) try writer.writeByte(',');
        try role.writeJson(writer);
    }
    try writer.writeByte(']');
}

fn writeCreateGuildChannelArray(channels: []const CreateGuildChannel, writer: anytype) !void {
    try writer.writeByte('[');
    for (channels, 0..) |channel, index| {
        if (index != 0) try writer.writeByte(',');
        try channel.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn writeEmbedFieldArray(fields: []const EmbedField, writer: anytype) !void {
    try writer.writeByte('[');
    for (fields, 0..) |field, index| {
        if (index != 0) try writer.writeByte(',');
        try field.writeJson(writer);
    }
    try writer.writeByte(']');
}

fn writeAllowedMentionTypeArray(types: []const AllowedMentionType, writer: anytype) !void {
    try writer.writeByte('[');
    for (types, 0..) |mention_type, index| {
        if (index != 0) try writer.writeByte(',');
        const value = switch (mention_type) {
            .roles => "roles",
            .users => "users",
            .everyone => "everyone",
        };
        try Json.writeString(value, writer);
    }
    try writer.writeByte(']');
}

fn writeStringArray(values: []const []const u8, writer: anytype) !void {
    try writer.writeByte('[');
    for (values, 0..) |value, index| {
        if (index != 0) try writer.writeByte(',');
        try Json.writeString(value, writer);
    }
    try writer.writeByte(']');
}

fn writeStringPairObject(values: []const StringPair, writer: anytype) !void {
    try writer.writeByte('{');
    for (values, 0..) |entry, index| {
        if (index != 0) try writer.writeByte(',');
        try Json.writeString(entry.key, writer);
        try writer.writeByte(':');
        try Json.writeString(entry.value, writer);
    }
    try writer.writeByte('}');
}

fn writeNullableStringPairObjectField(
    writer: anytype,
    needs_comma: *bool,
    comptime field: []const u8,
    values: ?[]const StringPair,
    clear: bool,
) !void {
    if (clear) {
        try writeComma(writer, needs_comma);
        try writer.print("\"{s}\":null", .{field});
    } else if (values) |entries| {
        try writeComma(writer, needs_comma);
        try writer.print("\"{s}\":", .{field});
        try writeStringPairObject(entries, writer);
    }
}

fn writeLobbyPayloadJson(
    fields: struct {
        metadata: ?[]const StringPair,
        clear_metadata: bool,
        members: []const LobbyMember,
        idle_timeout_seconds: ?u32,
    },
    writer: anytype,
) !void {
    try writer.writeByte('{');
    var needs_comma = false;

    try writeNullableStringPairObjectField(writer, &needs_comma, "metadata", fields.metadata, fields.clear_metadata);
    if (fields.members.len != 0) {
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"members\":");
        try writeLobbyMemberArray(fields.members, writer);
    }
    if (fields.idle_timeout_seconds) |seconds| {
        try writeComma(writer, &needs_comma);
        try writer.print("\"idle_timeout_seconds\":{d}", .{seconds});
    }

    try writer.writeByte('}');
}

fn writeLobbyMemberArray(members: []const LobbyMember, writer: anytype) !void {
    try writer.writeByte('[');
    for (members, 0..) |member, index| {
        if (index != 0) try writer.writeByte(',');
        try member.writeJson(writer);
    }
    try writer.writeByte(']');
}

fn writeApplicationRoleConnectionMetadataArray(
    records: []const ApplicationRoleConnectionMetadata,
    writer: anytype,
) !void {
    try writer.writeByte('[');
    for (records, 0..) |record, index| {
        if (index != 0) try writer.writeByte(',');
        try record.writeJson(writer);
    }
    try writer.writeByte(']');
}

fn writeSnowflakeStringArray(ids: []const Snowflake, writer: anytype) !void {
    try writer.writeByte('[');
    for (ids, 0..) |id, index| {
        if (index != 0) try writer.writeByte(',');
        try writer.print("\"{d}\"", .{id.value});
    }
    try writer.writeByte(']');
}

fn writeAutoModerationKeywordPresetArray(presets: []const AutoModerationKeywordPresetType, writer: anytype) !void {
    try writer.writeByte('[');
    for (presets, 0..) |preset, index| {
        if (index != 0) try writer.writeByte(',');
        try writer.print("{d}", .{@intFromEnum(preset)});
    }
    try writer.writeByte(']');
}

fn writeAutoModerationActionArray(actions: []const AutoModerationAction, writer: anytype) !void {
    try writer.writeByte('[');
    for (actions, 0..) |action, index| {
        if (index != 0) try writer.writeByte(',');
        try action.writeJson(writer);
    }
    try writer.writeByte(']');
}

fn writeAutoModerationRuleFields(
    fields: struct {
        event_type: AutoModerationRuleEventType,
        trigger_type: AutoModerationTriggerType,
        trigger_metadata: ?AutoModerationTriggerMetadata,
        actions: []const AutoModerationAction,
        enabled: ?bool,
        exempt_roles: []const Snowflake,
        exempt_channels: []const Snowflake,
    },
    writer: anytype,
    needs_comma: *bool,
) !void {
    try writeComma(writer, needs_comma);
    try writer.print("\"event_type\":{d}", .{@intFromEnum(fields.event_type)});

    try writeComma(writer, needs_comma);
    try writer.print("\"trigger_type\":{d}", .{@intFromEnum(fields.trigger_type)});

    if (fields.trigger_metadata) |metadata| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"trigger_metadata\":");
        try metadata.writeJson(writer);
    }

    try writeComma(writer, needs_comma);
    try writer.writeAll("\"actions\":");
    try writeAutoModerationActionArray(fields.actions, writer);

    try writeOptionalBoolField(writer, needs_comma, "enabled", fields.enabled);
    if (fields.exempt_roles.len != 0) {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"exempt_roles\":");
        try writeSnowflakeStringArray(fields.exempt_roles, writer);
    }
    if (fields.exempt_channels.len != 0) {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"exempt_channels\":");
        try writeSnowflakeStringArray(fields.exempt_channels, writer);
    }
}

fn writeWelcomeScreenChannelArray(channels: []const WelcomeScreenChannel, writer: anytype) !void {
    try writer.writeByte('[');
    for (channels, 0..) |channel, index| {
        if (index != 0) try writer.writeByte(',');
        try channel.writeJson(writer);
    }
    try writer.writeByte(']');
}

fn writeOnboardingPromptOptionArray(options: []const OnboardingPromptOption, writer: anytype) !void {
    try writer.writeByte('[');
    for (options, 0..) |option, index| {
        if (index != 0) try writer.writeByte(',');
        try option.writeJson(writer);
    }
    try writer.writeByte(']');
}

fn writeOnboardingPromptArray(prompts: []const OnboardingPrompt, writer: anytype) !void {
    try writer.writeByte('[');
    for (prompts, 0..) |prompt, index| {
        if (index != 0) try writer.writeByte(',');
        try prompt.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn writeGuildRolePositionArray(positions: []const GuildRolePosition, writer: anytype) !void {
    try writer.writeByte('[');
    for (positions, 0..) |position, index| {
        if (index != 0) try writer.writeByte(',');
        try position.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn writeGuildChannelPositionArray(positions: []const GuildChannelPosition, writer: anytype) !void {
    try writer.writeByte('[');
    for (positions, 0..) |position, index| {
        if (index != 0) try writer.writeByte(',');
        try position.writeJson(writer);
    }
    try writer.writeByte(']');
}

fn writeOptionalScheduledEventMetadata(
    writer: anytype,
    needs_comma: *bool,
    metadata: ?GuildScheduledEventEntityMetadata,
) !void {
    if (metadata) |value| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"entity_metadata\":");
        try value.writeJson(writer);
    }
}

fn writeSnowflakeCommaList(ids: []const Snowflake, writer: anytype) !void {
    for (ids, 0..) |id, index| {
        if (index != 0) try writer.writeByte(',');
        try writer.print("{d}", .{id.value});
    }
}

fn writeOptionalStringField(writer: anytype, needs_comma: *bool, comptime field: []const u8, value: ?[]const u8) !void {
    if (value) |text| {
        try writeComma(writer, needs_comma);
        try writer.print("\"{s}\":", .{field});
        try Json.writeString(text, writer);
    }
}

fn writeNullableStringField(
    writer: anytype,
    needs_comma: *bool,
    comptime field: []const u8,
    value: ?[]const u8,
    clear: bool,
) !void {
    if (clear) {
        try writeComma(writer, needs_comma);
        try writer.print("\"{s}\":null", .{field});
    } else {
        try writeOptionalStringField(writer, needs_comma, field, value);
    }
}

fn writeNullableSnowflakeField(
    writer: anytype,
    needs_comma: *bool,
    comptime field: []const u8,
    value: ?Snowflake,
    clear: bool,
) !void {
    if (clear) {
        try writeComma(writer, needs_comma);
        try writer.print("\"{s}\":null", .{field});
    } else if (value) |snowflake| {
        try writeComma(writer, needs_comma);
        try writer.print("\"{s}\":\"{d}\"", .{ field, snowflake.value });
    }
}

fn writeOptionalIntegerField(writer: anytype, needs_comma: *bool, comptime field: []const u8, value: anytype) !void {
    if (value) |integer| {
        try writeComma(writer, needs_comma);
        try writer.print("\"{s}\":{d}", .{ field, integer });
    }
}

fn writeOptionalFloatField(writer: anytype, needs_comma: *bool, comptime field: []const u8, value: ?f64) !void {
    if (value) |float| {
        try writeComma(writer, needs_comma);
        try writer.print("\"{s}\":{d}", .{ field, float });
    }
}

fn writeOptionalBoolField(writer: anytype, needs_comma: *bool, comptime field: []const u8, value: ?bool) !void {
    if (value) |enabled| {
        try writeComma(writer, needs_comma);
        try writer.print("\"{s}\":", .{field});
        try writer.writeAll(if (enabled) "true" else "false");
    }
}

fn writeSnowflakeQueryParam(writer: anytype, needs_ampersand: *bool, comptime field: []const u8, value: Snowflake) !void {
    try writeQuerySeparator(writer, needs_ampersand);
    try writer.print("{s}={d}", .{ field, value.value });
}

fn writeStringQueryParam(writer: anytype, needs_ampersand: *bool, comptime field: []const u8, value: []const u8) !void {
    try writeQuerySeparator(writer, needs_ampersand);
    try writer.print("{s}=", .{field});
    try writeQueryStringValue(value, writer);
}

fn writeOptionalStringQueryParam(
    writer: anytype,
    needs_ampersand: *bool,
    comptime field: []const u8,
    value: ?[]const u8,
) !void {
    if (value) |present| try writeStringQueryParam(writer, needs_ampersand, field, present);
}

fn writeOptionalBoolQueryParam(writer: anytype, needs_ampersand: *bool, comptime field: []const u8, value: ?bool) !void {
    if (value) |enabled| {
        try writeQuerySeparator(writer, needs_ampersand);
        try writer.print("{s}=", .{field});
        try writer.writeAll(if (enabled) "true" else "false");
    }
}

fn writeQueryStringValue(value: []const u8, writer: anytype) !void {
    const hex = "0123456789ABCDEF";
    for (value) |byte| {
        const safe = (byte >= 'A' and byte <= 'Z') or
            (byte >= 'a' and byte <= 'z') or
            (byte >= '0' and byte <= '9') or
            byte == '-' or byte == '_' or byte == '.' or byte == '~';
        if (safe) {
            try writer.writeByte(byte);
        } else {
            try writer.writeByte('%');
            try writer.writeByte(hex[byte >> 4]);
            try writer.writeByte(hex[byte & 0x0f]);
        }
    }
}

fn writeQuerySeparator(writer: anytype, needs_ampersand: *bool) !void {
    if (needs_ampersand.*) try writer.writeByte('&');
    needs_ampersand.* = true;
}

fn writeComma(writer: anytype, needs_comma: *bool) !void {
    if (needs_comma.*) try writer.writeByte(',');
    needs_comma.* = true;
}

test "create message JSON escapes content" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try (CreateMessage{ .content = "hello \"zig\"" }).writeJson(&out.writer);
    try std.testing.expectEqualStrings("{\"content\":\"hello \\\"zig\\\"\"}", out.written());
}

test "list audit log query writes filters in stable order" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try ListAuditLog.init()
        .forUser(Snowflake.init(10))
        .withActionType(72)
        .beforeEntry(Snowflake.init(30))
        .afterEntry(Snowflake.init(20))
        .withLimit(50)
        .writeQuery(&out.writer);

    try std.testing.expectEqualStrings(
        "user_id=10&action_type=72&before=30&after=20&limit=50",
        out.written(),
    );
}

test "user and guild member display helpers prefer Discord display names" {
    const legacy_user = User{
        .id = Snowflake.init(10),
        .username = "zig",
        .discriminator = "1337",
        .global_name = "Zig Bot",
    };
    try std.testing.expectEqualStrings("Zig Bot", legacy_user.displayName());

    const legacy_tag = try legacy_user.tag(std.testing.allocator);
    defer std.testing.allocator.free(legacy_tag);
    try std.testing.expectEqualStrings("zig#1337", legacy_tag);

    const migrated_user = User{
        .id = Snowflake.init(11),
        .username = "baris",
        .discriminator = "0",
    };
    try std.testing.expectEqualStrings("baris", migrated_user.displayName());

    const migrated_tag = try migrated_user.tag(std.testing.allocator);
    defer std.testing.allocator.free(migrated_tag);
    try std.testing.expectEqualStrings("baris", migrated_tag);

    try std.testing.expectEqualStrings(
        "mod",
        (GuildMember{ .user = migrated_user, .nick = "mod" }).displayName().?,
    );
    try std.testing.expectEqualStrings("baris", (GuildMember{ .user = migrated_user }).displayName().?);
    try std.testing.expect((GuildMember{}).displayName() == null);
}

test "list current user guilds query writes pagination and counts" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try ListCurrentUserGuilds.init()
        .beforeGuild(Snowflake.init(30))
        .afterGuild(Snowflake.init(20))
        .withLimit(100)
        .withCounts(true)
        .writeQuery(&out.writer);

    try std.testing.expectEqualStrings(
        "before=30&after=20&limit=100&with_counts=true",
        out.written(),
    );
}

test "get guild query writes counts flag" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try GetGuild.init().withCounts(true).writeQuery(&out.writer);

    try std.testing.expectEqualStrings("with_counts=true", out.written());
}

test "list guild bans query writes pagination filters" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try ListGuildBans.init()
        .beforeUser(Snowflake.init(30))
        .afterUser(Snowflake.init(20))
        .withLimit(100)
        .writeQuery(&out.writer);

    try std.testing.expectEqualStrings("before=30&after=20&limit=100", out.written());
}

test "guild member queries write pagination and search filters" {
    var list = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer list.deinit();

    try ListGuildMembers.init()
        .withLimit(100)
        .afterMember(Snowflake.init(20))
        .writeQuery(&list.writer);
    try std.testing.expectEqualStrings("limit=100&after=20", list.written());

    var search = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer search.deinit();

    try SearchGuildMembers.init("baris dev")
        .withLimit(25)
        .writeQuery(&search.writer);
    try std.testing.expectEqualStrings("query=baris%20dev&limit=25", search.written());
}

test "guild prune query and JSON include days roles and count flag" {
    const roles = [_]Snowflake{ Snowflake.init(10), Snowflake.init(20) };

    var query = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer query.deinit();

    try GetGuildPruneCount.init()
        .withDays(14)
        .withRoles(&roles)
        .writeQuery(&query.writer);
    try std.testing.expectEqualStrings("days=14&include_roles=10,20", query.written());

    var body = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer body.deinit();

    try BeginGuildPrune.init()
        .withDays(14)
        .computeCount(false)
        .withRoles(&roles)
        .writeJson(&body.writer);
    try std.testing.expectEqualStrings(
        "{\"days\":14,\"compute_prune_count\":false,\"include_roles\":[\"10\",\"20\"]}",
        body.written(),
    );
}

test "guild scheduled event queries write counts users and pagination" {
    var list = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer list.deinit();

    try ListGuildScheduledEvents.init().withUserCount(true).writeQuery(&list.writer);
    try std.testing.expectEqualStrings("with_user_count=true", list.written());

    var get = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer get.deinit();

    try GetGuildScheduledEvent.init().withUserCount(false).writeQuery(&get.writer);
    try std.testing.expectEqualStrings("with_user_count=false", get.written());

    var users = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer users.deinit();

    try ListGuildScheduledEventUsers.init()
        .withLimit(50)
        .withMember(true)
        .beforeUser(Snowflake.init(30))
        .afterUser(Snowflake.init(20))
        .writeQuery(&users.writer);
    try std.testing.expectEqualStrings("limit=50&with_member=true&before=30&after=20", users.written());
}

test "guild scheduled event JSON supports create edit and null clears" {
    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();

    try CreateGuildScheduledEvent.init("Launch", "2026-06-02T10:00:00.000Z", .voice)
        .withChannel(Snowflake.init(20))
        .withDescription("Ship discord.zig")
        .writeJson(&create.writer);
    try std.testing.expectEqualStrings(
        "{\"channel_id\":\"20\",\"name\":\"Launch\",\"privacy_level\":2,\"scheduled_start_time\":\"2026-06-02T10:00:00.000Z\",\"description\":\"Ship discord.zig\",\"entity_type\":2}",
        create.written(),
    );

    var external = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer external.deinit();

    try CreateGuildScheduledEvent.init("Meetup", "2026-06-02T10:00:00.000Z", .external)
        .withMetadata(.{ .location = "Istanbul" })
        .withEndTime("2026-06-02T12:00:00.000Z")
        .writeJson(&external.writer);
    try std.testing.expectEqualStrings(
        "{\"entity_metadata\":{\"location\":\"Istanbul\"},\"name\":\"Meetup\",\"privacy_level\":2,\"scheduled_start_time\":\"2026-06-02T10:00:00.000Z\",\"scheduled_end_time\":\"2026-06-02T12:00:00.000Z\",\"entity_type\":3}",
        external.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    try EditGuildScheduledEvent.init()
        .clearChannel()
        .withMetadata(.{ .location = "Remote" })
        .withEntityType(.external)
        .withStatus(.active)
        .clearDescription()
        .writeJson(&edit.writer);
    try std.testing.expectEqualStrings(
        "{\"channel_id\":null,\"entity_metadata\":{\"location\":\"Remote\"},\"description\":null,\"entity_type\":3,\"status\":2}",
        edit.written(),
    );
}

test "stage instance JSON supports create and edit payloads" {
    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();

    try CreateStageInstance.init(Snowflake.init(20), "Live Q&A")
        .withPrivacyLevel(.guild_only)
        .sendStartNotification(true)
        .withScheduledEvent(Snowflake.init(30))
        .writeJson(&create.writer);
    try std.testing.expectEqualStrings(
        "{\"channel_id\":\"20\",\"topic\":\"Live Q&A\",\"privacy_level\":2,\"send_start_notification\":true,\"guild_scheduled_event_id\":\"30\"}",
        create.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    try EditStageInstance.init()
        .withTopic("Aftershow")
        .withPrivacyLevel(.guild_only)
        .writeJson(&edit.writer);
    try std.testing.expectEqualStrings(
        "{\"topic\":\"Aftershow\",\"privacy_level\":2}",
        edit.written(),
    );
}

test "voice state JSON supports current user and moderator updates" {
    var current = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer current.deinit();

    try EditCurrentUserVoiceState.init()
        .withChannel(Snowflake.init(20))
        .suppressState(false)
        .requestToSpeakAt("2026-06-02T10:00:00.000Z")
        .writeJson(&current.writer);
    try std.testing.expectEqualStrings(
        "{\"channel_id\":\"20\",\"suppress\":false,\"request_to_speak_timestamp\":\"2026-06-02T10:00:00.000Z\"}",
        current.written(),
    );

    var clear = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear.deinit();

    try EditCurrentUserVoiceState.init().clearRequestToSpeak().writeJson(&clear.writer);
    try std.testing.expectEqualStrings("{\"request_to_speak_timestamp\":null}", clear.written());

    var user = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer user.deinit();

    try EditUserVoiceState.init()
        .withChannel(Snowflake.init(20))
        .suppressState(true)
        .writeJson(&user.writer);
    try std.testing.expectEqualStrings("{\"channel_id\":\"20\",\"suppress\":true}", user.written());
}

test "application role connection JSON writes platform fields and metadata" {
    const metadata = [_]StringPair{
        .{ .key = "level", .value = "42" },
        .{ .key = "rank", .value = "diamond" },
    };

    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try UpdateApplicationRoleConnection.init()
        .withPlatformName("zig league")
        .withPlatformUsername("baris")
        .withMetadata(&metadata)
        .writeJson(&out.writer);
    try std.testing.expectEqualStrings(
        "{\"platform_name\":\"zig league\",\"platform_username\":\"baris\",\"metadata\":{\"level\":\"42\",\"rank\":\"diamond\"}}",
        out.written(),
    );
}

test "application role connection metadata records JSON writes array payload" {
    const name_localizations = [_]StringPair{
        .{ .key = "tr", .value = "Seviye" },
    };
    const description_localizations = [_]StringPair{
        .{ .key = "tr", .value = "Oyuncu seviyesi" },
    };
    const records = [_]ApplicationRoleConnectionMetadata{
        .{
            .type = .integer_greater_than_or_equal,
            .key = "level",
            .name = "Level",
            .name_localizations = &name_localizations,
            .description = "Player level",
            .description_localizations = &description_localizations,
        },
        .{
            .type = .boolean_equal,
            .key = "verified",
            .name = "Verified",
            .description = "Account verified",
        },
    };

    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try (UpdateApplicationRoleConnectionMetadataRecords{ .records = &records }).writeJson(&out.writer);
    try std.testing.expectEqualStrings(
        "[{\"type\":2,\"key\":\"level\",\"name\":\"Level\",\"name_localizations\":{\"tr\":\"Seviye\"},\"description\":\"Player level\",\"description_localizations\":{\"tr\":\"Oyuncu seviyesi\"}},{\"type\":7,\"key\":\"verified\",\"name\":\"Verified\",\"description\":\"Account verified\"}]",
        out.written(),
    );
}

test "current application JSON supports install params metadata and clears" {
    var install = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer install.deinit();

    try (ApplicationInstallParams{
        .scopes = &.{ "bot", "applications.commands" },
        .permissions = "2048",
    }).writeJson(&install.writer);
    try std.testing.expectEqualStrings(
        "{\"scopes\":[\"bot\",\"applications.commands\"],\"permissions\":\"2048\"}",
        install.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    try EditCurrentApplication.init()
        .withCustomInstallUrl("https://example.com/install")
        .withDescription("Fast Zig bot")
        .withInstallParams(.{
            .scopes = &.{ "bot", "applications.commands" },
            .permissions = "2048",
        })
        .withFlags(524288)
        .withTags(&.{ "zig", "bot" })
        .withEventWebhooksUrl("https://example.com/events")
        .withEventWebhooksStatus(.enabled)
        .withEventWebhookTypes(&.{ApplicationEventWebhookType.application_authorized.value()})
        .writeJson(&edit.writer);
    try std.testing.expectEqualStrings(
        "{\"custom_install_url\":\"https://example.com/install\",\"description\":\"Fast Zig bot\",\"install_params\":{\"scopes\":[\"bot\",\"applications.commands\"],\"permissions\":\"2048\"},\"flags\":524288,\"tags\":[\"zig\",\"bot\"],\"event_webhooks_url\":\"https://example.com/events\",\"event_webhooks_status\":2,\"event_webhooks_types\":[\"APPLICATION_AUTHORIZED\"]}",
        edit.written(),
    );

    var clear = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear.deinit();

    try EditCurrentApplication.init()
        .clearIcon()
        .clearCoverImage()
        .withInteractionsEndpointUrl("https://example.com/interactions")
        .writeJson(&clear.writer);
    try std.testing.expectEqualStrings(
        "{\"icon\":null,\"cover_image\":null,\"interactions_endpoint_url\":\"https://example.com/interactions\"}",
        clear.written(),
    );
}

test "application event webhook types expose documented values" {
    try std.testing.expectEqualStrings(
        "APPLICATION_AUTHORIZED",
        ApplicationEventWebhookType.application_authorized.value(),
    );
    try std.testing.expectEqualStrings(
        "APPLICATION_DEAUTHORIZED",
        ApplicationEventWebhookType.application_deauthorized.value(),
    );
    try std.testing.expectEqualStrings(
        "ENTITLEMENT_CREATE",
        ApplicationEventWebhookType.entitlement_create.value(),
    );
    try std.testing.expectEqualStrings(
        "LOBBY_MESSAGE_DELETE",
        ApplicationEventWebhookType.lobby_message_delete.value(),
    );
    try std.testing.expectEqual(
        ApplicationEventWebhookType.game_direct_message_update,
        ApplicationEventWebhookType.fromValue("GAME_DIRECT_MESSAGE_UPDATE").?,
    );
    try std.testing.expectEqual(null, ApplicationEventWebhookType.fromValue("UNKNOWN_EVENT"));

    const payload = ApplicationEventWebhookPayload{
        .version = 1,
        .application_id = Snowflake{ .value = 42 },
        .type = .event,
        .event = .{
            .type = .application_authorized,
            .timestamp = "2026-06-03T12:00:00.000000",
        },
    };
    try std.testing.expectEqual(ApplicationEventWebhookPayloadType.event, payload.type);
    try std.testing.expectEqual(ApplicationEventWebhookType.application_authorized, payload.event.?.type);
}

test "OAuth2 token forms percent encode fields" {
    var exchange = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer exchange.deinit();

    try OAuth2TokenRequest.authorizationCode("code value")
        .withRedirectUri("https://example.com/callback path")
        .withClientId("10")
        .withClientSecret("secret/value")
        .withScope("identify guilds.join")
        .withCodeVerifier("pkce verifier")
        .writeForm(&exchange.writer);
    try std.testing.expectEqualStrings(
        "grant_type=authorization_code&code=code%20value&redirect_uri=https%3A%2F%2Fexample.com%2Fcallback%20path&client_id=10&client_secret=secret%2Fvalue&scope=identify%20guilds.join&code_verifier=pkce%20verifier",
        exchange.written(),
    );

    var revoke = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer revoke.deinit();

    try OAuth2TokenRevocation.init("refresh token")
        .withTokenTypeHint("refresh_token")
        .withClientId("10")
        .writeForm(&revoke.writer);
    try std.testing.expectEqualStrings(
        "token=refresh%20token&token_type_hint=refresh_token&client_id=10",
        revoke.written(),
    );
}

test "monetization queries and test entitlement JSON" {
    var entitlements = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer entitlements.deinit();

    try ListEntitlements.init()
        .forUser(Snowflake.init(10))
        .withSkus(&.{ Snowflake.init(20), Snowflake.init(30) })
        .beforeEntitlement(Snowflake.init(40))
        .afterEntitlement(Snowflake.init(50))
        .withLimit(25)
        .forGuild(Snowflake.init(60))
        .excludeEnded(true)
        .excludeDeleted(false)
        .writeQuery(&entitlements.writer);
    try std.testing.expectEqualStrings(
        "user_id=10&sku_ids=20,30&before=40&after=50&limit=25&guild_id=60&exclude_ended=true&exclude_deleted=false",
        entitlements.written(),
    );

    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();

    try CreateTestEntitlement.init(Snowflake.init(20), Snowflake.init(30), .guild).writeJson(&create.writer);
    try std.testing.expectEqualStrings(
        "{\"sku_id\":\"20\",\"owner_id\":\"30\",\"owner_type\":1}",
        create.written(),
    );

    var subscriptions = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer subscriptions.deinit();

    try ListSkuSubscriptions.init()
        .beforeSubscription(Snowflake.init(10))
        .afterSubscription(Snowflake.init(20))
        .withLimit(50)
        .forUser(Snowflake.init(30))
        .writeQuery(&subscriptions.writer);
    try std.testing.expectEqualStrings(
        "before=10&after=20&limit=50&user_id=30",
        subscriptions.written(),
    );
}

test "list messages query writes snowflake filters and limit" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    var options = ListMessages.beforeMessage(Snowflake.init(20)).withLimit(50);
    options.after = Snowflake.init(10);
    try options.writeQuery(&out.writer);

    try std.testing.expectEqualStrings("before=20&after=10&limit=50", out.written());
}

test "list reactions query writes after and limit" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try ListReactions.afterUser(Snowflake.init(10))
        .withLimit(25)
        .withType(.burst)
        .writeQuery(&out.writer);
    try std.testing.expectEqualStrings("after=10&limit=25&type=1", out.written());
}

test "list poll answer voters query writes after and limit" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try ListPollAnswerVoters.afterUser(Snowflake.init(10))
        .withLimit(25)
        .writeQuery(&out.writer);

    try std.testing.expectEqualStrings("after=10&limit=25", out.written());
}

test "list archived threads query percent encodes timestamp" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try ListArchivedThreads.beforeTimestamp("2026-06-02T10:00:00.000Z")
        .withLimit(50)
        .writeQuery(&out.writer);

    try std.testing.expectEqualStrings("before=2026-06-02T10%3A00%3A00.000Z&limit=50", out.written());
}

test "list thread members query writes pagination and member expansion" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try ListThreadMembers.init()
        .withMemberExpansion(true)
        .afterMember(Snowflake.init(10))
        .withLimit(100)
        .writeQuery(&out.writer);

    try std.testing.expectEqualStrings("with_member=true&after=10&limit=100", out.written());
}

test "list channel pins query percent encodes timestamp" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try ListChannelPins.beforeTimestamp("2026-06-02T10:30:00.000Z")
        .withLimit(50)
        .writeQuery(&out.writer);

    try std.testing.expectEqualStrings("before=2026-06-02T10%3A30%3A00.000Z&limit=50", out.written());
}

test "bulk delete messages JSON writes message id array" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const messages = [_]Snowflake{ Snowflake.init(10), Snowflake.init(20) };
    try (BulkDeleteMessages{ .messages = &messages }).writeJson(&out.writer);

    try std.testing.expectEqualStrings("{\"messages\":[\"10\",\"20\"]}", out.written());
}

test "guild channel payload JSON includes common fields" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try CreateGuildChannel.init("general")
        .withType(.guild_text)
        .withTopic("Project chat")
        .withRateLimit(5)
        .withParent(Snowflake.init(99))
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"name\":\"general\",\"type\":0,\"topic\":\"Project chat\",\"rate_limit_per_user\":5,\"parent_id\":\"99\"}",
        out.written(),
    );
}

test "guild channel payload JSON supports forum available tags" {
    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();

    const tags = [_]WriteForumTag{
        WriteForumTag.init("Help").moderatedState(true).withEmojiId(Snowflake.init(80)),
        WriteForumTag.init("Ship").withEmojiName("🚀"),
    };
    try CreateGuildChannel.init("forum")
        .withType(.guild_forum)
        .withFlags(ChannelFlags.require_tag)
        .withAvailableTags(&tags)
        .withDefaultReactionEmoji(DefaultReactionEmoji.name("👋"))
        .withDefaultThreadRateLimit(30)
        .withDefaultSortOrder(.creation_date)
        .withDefaultForumLayout(.gallery_view)
        .writeJson(&create.writer);

    try std.testing.expectEqualStrings(
        "{\"name\":\"forum\",\"type\":15,\"flags\":16,\"available_tags\":[{\"name\":\"Help\",\"moderated\":true,\"emoji_id\":\"80\"},{\"name\":\"Ship\",\"emoji_name\":\"🚀\"}],\"default_reaction_emoji\":{\"emoji_name\":\"👋\"},\"default_thread_rate_limit_per_user\":30,\"default_sort_order\":1,\"default_forum_layout\":2}",
        create.written(),
    );
}

test "edit guild JSON supports settings media channels and clears" {
    var update = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer update.deinit();

    try EditGuild.init()
        .withName("zig guild")
        .withVerificationLevel(2)
        .withAfkChannel(Snowflake.init(20))
        .withAfkTimeout(300)
        .withIcon("data:image/png;base64,abc")
        .withSystemChannelFlags(3)
        .withRulesChannel(Snowflake.init(30))
        .withPreferredLocale("en-US")
        .withFeatures(&.{ "COMMUNITY", "NEWS" })
        .premiumProgressBarState(true)
        .writeJson(&update.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"zig guild\",\"verification_level\":2,\"afk_channel_id\":\"20\",\"afk_timeout\":300,\"icon\":\"data:image/png;base64,abc\",\"system_channel_flags\":3,\"rules_channel_id\":\"30\",\"preferred_locale\":\"en-US\",\"features\":[\"COMMUNITY\",\"NEWS\"],\"premium_progress_bar_enabled\":true}",
        update.written(),
    );

    var clear = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear.deinit();

    try EditGuild.init()
        .clearAfkChannel()
        .clearIcon()
        .clearBanner()
        .clearSystemChannel()
        .clearPublicUpdatesChannel()
        .clearDescription()
        .clearSafetyAlertsChannel()
        .writeJson(&clear.writer);
    try std.testing.expectEqualStrings(
        "{\"afk_channel_id\":null,\"icon\":null,\"banner\":null,\"system_channel_id\":null,\"public_updates_channel_id\":null,\"description\":null,\"safety_alerts_channel_id\":null}",
        clear.written(),
    );
}

test "guild template JSON supports create and edit payloads" {
    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();

    try CreateGuildTemplate.init("starter")
        .withDescription("Project starter")
        .writeJson(&create.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"starter\",\"description\":\"Project starter\"}",
        create.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    try EditGuildTemplate.init().withDescription("Updated").writeJson(&edit.writer);
    try std.testing.expectEqualStrings("{\"description\":\"Updated\"}", edit.written());
}

test "guild lifecycle and group DM payload JSON" {
    var guild = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer guild.deinit();

    const roles = [_]CreateGuildRole{CreateGuildRole.init("mod").withPermissions(Permissions.manage_messages)};
    const channels = [_]CreateGuildChannel{CreateGuildChannel.init("general").withType(.guild_text)};
    try CreateGuild.init("zig")
        .withIcon("data:image/png;base64,abc")
        .withRoles(&roles)
        .withChannels(&channels)
        .withVerificationLevel(1)
        .writeJson(&guild.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"zig\",\"icon\":\"data:image/png;base64,abc\",\"verification_level\":1,\"roles\":[{\"name\":\"mod\",\"permissions\":\"8192\"}],\"channels\":[{\"name\":\"general\",\"type\":0}]}",
        guild.written(),
    );

    var template = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer template.deinit();
    try CreateGuildFromTemplate.init("from-template").withIcon("data:image/png;base64,xyz").writeJson(&template.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"from-template\",\"icon\":\"data:image/png;base64,xyz\"}",
        template.written(),
    );

    var recipient = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer recipient.deinit();
    try AddGroupDmRecipient.init("oauth-token").withNick("baris").writeJson(&recipient.writer);
    try std.testing.expectEqualStrings("{\"access_token\":\"oauth-token\",\"nick\":\"baris\"}", recipient.written());
}

test "forum thread payload JSON includes first message and tags" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const tags = [_]Snowflake{ Snowflake.init(10), Snowflake.init(20) };
    const embeds = [_]Embed{Embed.init().withTitle("Launch")};
    try CreateForumThread.init(
        "release",
        ForumThreadMessage.init("ship").withEmbeds(&embeds),
    )
        .withAutoArchiveDuration(1440)
        .withRateLimit(5)
        .withAppliedTags(&tags)
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"name\":\"release\",\"auto_archive_duration\":1440,\"rate_limit_per_user\":5,\"message\":{\"content\":\"ship\",\"embeds\":[{\"title\":\"Launch\"}]},\"applied_tags\":[\"10\",\"20\"]}",
        out.written(),
    );
}

test "guild widget settings JSON supports update and clear channel" {
    var update = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer update.deinit();

    try EditGuildWidgetSettings.init()
        .enabledState(true)
        .withChannel(Snowflake.init(42))
        .writeJson(&update.writer);
    try std.testing.expectEqualStrings("{\"enabled\":true,\"channel_id\":\"42\"}", update.written());

    var clear = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear.deinit();

    try EditGuildWidgetSettings.init().clearChannel().writeJson(&clear.writer);
    try std.testing.expectEqualStrings("{\"channel_id\":null}", clear.written());
}

test "guild widget image query supports style option" {
    var query = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer query.deinit();

    const options = GetGuildWidgetImage.init().withStyle(.banner4);
    try std.testing.expect(options.hasQuery());
    try options.writeQuery(&query.writer);
    try std.testing.expectEqualStrings("style=banner4", query.written());

    try std.testing.expect(!GetGuildWidgetImage.init().hasQuery());
}

test "guild incident actions JSON supports set and clear fields" {
    var set = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer set.deinit();

    try EditGuildIncidentActions.init()
        .disableInvitesUntil("2026-06-03T12:00:00.000Z")
        .disableDmsUntil("2026-06-03T13:00:00.000Z")
        .writeJson(&set.writer);
    try std.testing.expectEqualStrings(
        "{\"invites_disabled_until\":\"2026-06-03T12:00:00.000Z\",\"dms_disabled_until\":\"2026-06-03T13:00:00.000Z\"}",
        set.written(),
    );

    var clear = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear.deinit();

    try EditGuildIncidentActions.init()
        .clearInvitesDisabledUntil()
        .clearDmsDisabledUntil()
        .writeJson(&clear.writer);
    try std.testing.expectEqualStrings("{\"invites_disabled_until\":null,\"dms_disabled_until\":null}", clear.written());
}

test "guild onboarding JSON supports prompts default channels and mode" {
    const option_channels = [_]Snowflake{Snowflake.init(20)};
    const option_roles = [_]Snowflake{Snowflake.init(30)};
    const options = [_]OnboardingPromptOption{
        OnboardingPromptOption.init("General chat")
            .withId(Snowflake.init(11))
            .withChannels(&option_channels)
            .withRoles(&option_roles)
            .withEmojiName("wave")
            .emojiAnimatedState(false)
            .withDescription("Meet the community"),
    };
    const prompts = [_]OnboardingPrompt{
        OnboardingPrompt.init("Choose your channels")
            .withId(Snowflake.init(10))
            .withType(.dropdown)
            .withOptions(&options)
            .singleSelectState(true)
            .requiredState(true)
            .inOnboardingState(false),
    };
    const default_channels = [_]Snowflake{ Snowflake.init(40), Snowflake.init(41) };

    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try EditGuildOnboarding.init()
        .withPrompts(&prompts)
        .withDefaultChannels(&default_channels)
        .enabledState(true)
        .withMode(.onboarding_advanced)
        .writeJson(&out.writer);
    try std.testing.expectEqualStrings(
        "{\"prompts\":[{\"id\":\"10\",\"type\":1,\"options\":[{\"id\":\"11\",\"channel_ids\":[\"20\"],\"role_ids\":[\"30\"],\"emoji_name\":\"wave\",\"emoji_animated\":false,\"title\":\"General chat\",\"description\":\"Meet the community\"}],\"title\":\"Choose your channels\",\"single_select\":true,\"required\":true,\"in_onboarding\":false}],\"default_channel_ids\":[\"40\",\"41\"],\"enabled\":true,\"mode\":1}",
        out.written(),
    );
}

test "welcome screen JSON supports channels update and clear fields" {
    var channel = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer channel.deinit();

    try WelcomeScreenChannel.init(Snowflake.init(10), "Read rules")
        .withEmojiName("wave")
        .writeJson(&channel.writer);
    try std.testing.expectEqualStrings(
        "{\"channel_id\":\"10\",\"description\":\"Read rules\",\"emoji_name\":\"wave\"}",
        channel.written(),
    );

    var update = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer update.deinit();

    const channels = [_]WelcomeScreenChannel{
        WelcomeScreenChannel.init(Snowflake.init(10), "Read rules")
            .withEmojiId(Snowflake.init(30)),
    };
    try EditWelcomeScreen.init()
        .enabledState(true)
        .withChannels(&channels)
        .withDescription("Start here")
        .writeJson(&update.writer);
    try std.testing.expectEqualStrings(
        "{\"enabled\":true,\"welcome_channels\":[{\"channel_id\":\"10\",\"description\":\"Read rules\",\"emoji_id\":\"30\"}],\"description\":\"Start here\"}",
        update.written(),
    );

    var clear = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear.deinit();

    try EditWelcomeScreen.init()
        .clearChannels()
        .clearDescription()
        .writeJson(&clear.writer);
    try std.testing.expectEqualStrings("{\"welcome_channels\":null,\"description\":null}", clear.written());
}

test "edit channel JSON emits only provided fields" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try EditChannel.init()
        .withName("voice")
        .withBitrate(64000)
        .withUserLimit(10)
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"name\":\"voice\",\"bitrate\":64000,\"user_limit\":10}",
        out.written(),
    );
}

test "edit channel JSON supports thread lifecycle fields" {
    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    const tags = [_]Snowflake{ Snowflake.init(40), Snowflake.init(50) };
    try EditChannel.init()
        .withName("resolved")
        .archivedState(true)
        .withAutoArchiveDuration(1440)
        .lockedState(true)
        .invitableState(false)
        .withAppliedTags(&tags)
        .writeJson(&edit.writer);

    try std.testing.expectEqualStrings(
        "{\"name\":\"resolved\",\"archived\":true,\"auto_archive_duration\":1440,\"locked\":true,\"invitable\":false,\"applied_tags\":[\"40\",\"50\"]}",
        edit.written(),
    );

    var clear_tags = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear_tags.deinit();

    try EditChannel.init().clearAppliedTags().writeJson(&clear_tags.writer);
    try std.testing.expectEqualStrings("{\"applied_tags\":[]}", clear_tags.written());
}

test "edit channel JSON supports forum available tags" {
    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    const tags = [_]WriteForumTag{
        WriteForumTag.init("No emoji")
            .withId(Snowflake.init(70))
            .clearEmojiId()
            .clearEmojiName(),
    };
    try EditChannel.init()
        .withFlags(ChannelFlags.require_tag | ChannelFlags.hide_media_download_options)
        .withAvailableTags(&tags)
        .withDefaultReactionEmoji(DefaultReactionEmoji.id(Snowflake.init(90)))
        .withDefaultThreadRateLimit(15)
        .withDefaultSortOrder(.latest_activity)
        .withDefaultForumLayout(.list_view)
        .writeJson(&edit.writer);
    try std.testing.expectEqualStrings(
        "{\"flags\":32784,\"available_tags\":[{\"id\":\"70\",\"name\":\"No emoji\",\"emoji_id\":null,\"emoji_name\":null}],\"default_reaction_emoji\":{\"emoji_id\":\"90\"},\"default_thread_rate_limit_per_user\":15,\"default_sort_order\":0,\"default_forum_layout\":1}",
        edit.written(),
    );

    var clear = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear.deinit();

    try EditChannel.init().clearAvailableTags().writeJson(&clear.writer);
    try std.testing.expectEqualStrings("{\"available_tags\":[]}", clear.written());
}

test "guild channel position JSON supports arrays parent moves and clears" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const positions = [_]GuildChannelPosition{
        GuildChannelPosition.init(Snowflake.init(10))
            .withPosition(2)
            .lockPermissions(true)
            .withParent(Snowflake.init(30)),
        GuildChannelPosition.init(Snowflake.init(20)).clearParent(),
    };
    try writeGuildChannelPositionArray(&positions, &out.writer);

    try std.testing.expectEqualStrings(
        "[{\"id\":\"10\",\"position\":2,\"lock_permissions\":true,\"parent_id\":\"30\"},{\"id\":\"20\",\"parent_id\":null}]",
        out.written(),
    );
}

test "edit channel permission JSON writes bitmasks as strings" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try EditChannelPermission.init(.role)
        .withAllow(Permissions.view_channel)
        .withDeny(Permissions.send_messages)
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"type\":0,\"allow\":\"1024\",\"deny\":\"2048\"}",
        out.written(),
    );

    const resolved = (PermissionOverwrite{
        .id = Snowflake.init(10),
        .type = .member,
        .allow = Permissions.view_channel,
        .deny = Permissions.send_messages,
    }).toPermissionsOverwrite();
    try std.testing.expectEqual(Permissions.OverwriteType.member, resolved.type);
    try std.testing.expectEqual(@as(u64, 10), resolved.id);
    try std.testing.expectEqual(Permissions.view_channel, resolved.allow);
    try std.testing.expectEqual(Permissions.send_messages, resolved.deny);
}

test "channel utility JSON supports voice status and announcement follow" {
    var status = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer status.deinit();

    try SetVoiceChannelStatus.clear().writeJson(&status.writer);
    try std.testing.expectEqualStrings("{\"status\":null}", status.written());

    var follow = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer follow.deinit();

    try FollowAnnouncementChannel.init(Snowflake.init(42)).writeJson(&follow.writer);
    try std.testing.expectEqualStrings("{\"webhook_channel_id\":\"42\"}", follow.written());
}

test "guild role payload JSON writes permissions as string bitmask" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try CreateGuildRole.init("moderator")
        .withPermissions(Permissions.add(Permissions.manage_messages, Permissions.kick_members))
        .withColor(0x5865F2)
        .withColors(RoleColors.init(0x5865F2).withSecondary(0xE558F2))
        .hoisted(true)
        .withIcon("data:image/png;base64,abc")
        .withUnicodeEmoji("⚡")
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"name\":\"moderator\",\"permissions\":\"8194\",\"color\":5793266,\"colors\":{\"primary_color\":5793266,\"secondary_color\":15030514,\"tertiary_color\":null},\"hoist\":true,\"icon\":\"data:image/png;base64,abc\",\"unicode_emoji\":\"⚡\"}",
        out.written(),
    );

    const role = (Role{
        .id = Snowflake.init(10),
        .name = "moderator",
        .colors = RoleColors.init(0x5865F2).withSecondary(0xE558F2),
        .permissions = Permissions.manage_messages,
    });
    const permissions_role = role.toPermissionsRole();
    try std.testing.expectEqual(@as(u24, 0x5865F2), role.colors.?.primary_color);
    try std.testing.expectEqual(@as(u24, 0xE558F2), role.colors.?.secondary_color.?);
    try std.testing.expect(role.colors.?.tertiary_color == null);
    try std.testing.expectEqual(@as(u64, 10), permissions_role.id);
    try std.testing.expectEqual(Permissions.manage_messages, permissions_role.permissions);
}

test "edit guild role JSON can explicitly disable booleans" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try EditGuildRole.init()
        .withName("helpers")
        .withColors(RoleColors.init(11127295).withSecondary(16759788).withTertiary(16761760))
        .hoisted(false)
        .clearIcon()
        .clearUnicodeEmoji()
        .mentionableState(false)
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"name\":\"helpers\",\"colors\":{\"primary_color\":11127295,\"secondary_color\":16759788,\"tertiary_color\":16761760},\"hoist\":false,\"icon\":null,\"unicode_emoji\":null,\"mentionable\":false}",
        out.written(),
    );

    var set_assets = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer set_assets.deinit();

    try EditGuildRole.init()
        .withPermissions(Permissions.manage_roles)
        .withColor(0x2ECC71)
        .withIcon("data:image/png;base64,role")
        .withUnicodeEmoji("✅")
        .mentionableState(true)
        .writeJson(&set_assets.writer);

    try std.testing.expectEqualStrings(
        "{\"permissions\":\"268435456\",\"color\":3066993,\"icon\":\"data:image/png;base64,role\",\"unicode_emoji\":\"✅\",\"mentionable\":true}",
        set_assets.written(),
    );
}

test "guild role position JSON supports arrays and nullable position" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const positions = [_]GuildRolePosition{
        GuildRolePosition.init(Snowflake.init(10)).withPosition(2),
        GuildRolePosition.init(Snowflake.init(20)).clearPosition(),
    };
    try writeGuildRolePositionArray(&positions, &out.writer);

    try std.testing.expectEqualStrings(
        "[{\"id\":\"10\",\"position\":2},{\"id\":\"20\",\"position\":null}]",
        out.written(),
    );
}

test "guild emoji JSON supports create and edit payloads" {
    const roles = [_]Snowflake{ Snowflake.init(10), Snowflake.init(20) };

    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();

    try CreateGuildEmoji.init("zig", "data:image/webp;base64,abc")
        .withRoles(&roles)
        .writeJson(&create.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"zig\",\"image\":\"data:image/webp;base64,abc\",\"roles\":[\"10\",\"20\"]}",
        create.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    try EditGuildEmoji.init()
        .withName("ziggy")
        .withRoles(&.{})
        .writeJson(&edit.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"ziggy\",\"roles\":[]}",
        edit.written(),
    );
}

test "application emoji JSON supports create and edit payloads" {
    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();

    try CreateApplicationEmoji.init("zig", "data:image/webp;base64,abc").writeJson(&create.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"zig\",\"image\":\"data:image/webp;base64,abc\"}",
        create.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    try EditApplicationEmoji.init("ziggy").writeJson(&edit.writer);
    try std.testing.expectEqualStrings("{\"name\":\"ziggy\"}", edit.written());
}

test "edit guild sticker JSON emits optional fields" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try EditGuildSticker.init()
        .withName("ziggy")
        .withDescription("Zig mascot")
        .withTags("zap")
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"name\":\"ziggy\",\"description\":\"Zig mascot\",\"tags\":\"zap\"}",
        out.written(),
    );
}

test "soundboard JSON supports send create and edit payloads" {
    var send = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer send.deinit();

    try SendSoundboardSound.init(Snowflake.init(10))
        .fromGuild(Snowflake.init(20))
        .writeJson(&send.writer);
    try std.testing.expectEqualStrings(
        "{\"sound_id\":\"10\",\"source_guild_id\":\"20\"}",
        send.written(),
    );

    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();

    try CreateGuildSoundboardSound.init("launch", "data:audio/ogg;base64,T0dH")
        .withVolume(0.5)
        .withEmojiName("🚀")
        .writeJson(&create.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"launch\",\"sound\":\"data:audio/ogg;base64,T0dH\",\"volume\":0.5,\"emoji_name\":\"🚀\"}",
        create.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    try EditGuildSoundboardSound.init()
        .withName("ship")
        .withVolume(1.0)
        .clearEmojiId()
        .clearEmojiName()
        .writeJson(&edit.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"ship\",\"volume\":1,\"emoji_id\":null,\"emoji_name\":null}",
        edit.written(),
    );
}

test "edit guild member JSON supports roles voice and timeout fields" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const roles = [_]Snowflake{ Snowflake.init(10), Snowflake.init(20) };
    try EditGuildMember.init()
        .withNick("helper")
        .withRoles(&roles)
        .muteState(false)
        .deafState(true)
        .moveToVoiceChannel(Snowflake.init(30))
        .timeoutUntil("2026-06-02T10:00:00.000Z")
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"nick\":\"helper\",\"roles\":[\"10\",\"20\"],\"mute\":false,\"deaf\":true,\"channel_id\":\"30\",\"communication_disabled_until\":\"2026-06-02T10:00:00.000Z\"}",
        out.written(),
    );

    var clear = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear.deinit();
    try EditGuildMember.init().clearTimeout().writeJson(&clear.writer);
    try std.testing.expectEqualStrings("{\"communication_disabled_until\":null}", clear.written());
}

test "edit current guild member JSON supports profile fields and clears" {
    var update = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer update.deinit();

    try EditCurrentGuildMember.init()
        .withNick("ziggy")
        .withAvatar("data:image/png;base64,abc")
        .withBio("Built with Zig")
        .writeJson(&update.writer);
    try std.testing.expectEqualStrings(
        "{\"nick\":\"ziggy\",\"avatar\":\"data:image/png;base64,abc\",\"bio\":\"Built with Zig\"}",
        update.written(),
    );

    var clear = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear.deinit();

    try EditCurrentGuildMember.init()
        .clearNick()
        .clearAvatar()
        .clearBanner()
        .clearBio()
        .writeJson(&clear.writer);
    try std.testing.expectEqualStrings(
        "{\"nick\":null,\"avatar\":null,\"banner\":null,\"bio\":null}",
        clear.written(),
    );
}

test "edit current user nick JSON supports set and clear" {
    var set = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer set.deinit();

    try EditCurrentUserNick.init().withNick("ziggy").writeJson(&set.writer);
    try std.testing.expectEqualStrings("{\"nick\":\"ziggy\"}", set.written());

    var clear = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear.deinit();

    try EditCurrentUserNick.init().clearNick().writeJson(&clear.writer);
    try std.testing.expectEqualStrings("{\"nick\":null}", clear.written());
}

test "edit current user JSON supports username image fields and clears" {
    var update = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer update.deinit();

    try EditCurrentUser.init()
        .withUsername("zigbot")
        .withAvatar("data:image/png;base64,abc")
        .writeJson(&update.writer);
    try std.testing.expectEqualStrings(
        "{\"username\":\"zigbot\",\"avatar\":\"data:image/png;base64,abc\"}",
        update.written(),
    );

    var clear = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear.deinit();

    try EditCurrentUser.init()
        .clearAvatar()
        .clearBanner()
        .writeJson(&clear.writer);
    try std.testing.expectEqualStrings("{\"avatar\":null,\"banner\":null}", clear.written());
}

test "create guild ban JSON supports delete message seconds" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try CreateGuildBan.init().deleteMessagesFor(3600).writeJson(&out.writer);
    try std.testing.expectEqualStrings("{\"delete_message_seconds\":3600}", out.written());

    var bulk = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer bulk.deinit();

    const user_ids = [_]Snowflake{ Snowflake.init(10), Snowflake.init(20) };
    try BulkGuildBan.init(&user_ids).deleteMessagesFor(60).writeJson(&bulk.writer);
    try std.testing.expectEqualStrings(
        "{\"user_ids\":[\"10\",\"20\"],\"delete_message_seconds\":60}",
        bulk.written(),
    );
}

test "auto moderation rule JSON supports create and edit payloads" {
    const actions = [_]AutoModerationAction{
        AutoModerationAction.blockMessage("Use #finance for finance talk"),
        AutoModerationAction.sendAlertMessage(Snowflake.init(40)),
        AutoModerationAction.timeout(60),
    };
    const roles = [_]Snowflake{Snowflake.init(10)};
    const channels = [_]Snowflake{Snowflake.init(20)};

    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();

    try CreateAutoModerationRule.init("keyword guard", .keyword, &actions)
        .withTriggerMetadata(AutoModerationTriggerMetadata.init()
            .withKeywordFilter(&.{ "cat*", "*dog" })
            .withRegexPatterns(&.{"(b|c)at"})
            .withAllowList(&.{"educational cat"}))
        .enabledState(true)
        .withExemptRoles(&roles)
        .withExemptChannels(&channels)
        .writeJson(&create.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"keyword guard\",\"event_type\":1,\"trigger_type\":1,\"trigger_metadata\":{\"keyword_filter\":[\"cat*\",\"*dog\"],\"regex_patterns\":[\"(b|c)at\"],\"allow_list\":[\"educational cat\"]},\"actions\":[{\"type\":1,\"metadata\":{\"custom_message\":\"Use #finance for finance talk\"}},{\"type\":2,\"metadata\":{\"channel_id\":\"40\"}},{\"type\":3,\"metadata\":{\"duration_seconds\":60}}],\"enabled\":true,\"exempt_roles\":[\"10\"],\"exempt_channels\":[\"20\"]}",
        create.written(),
    );

    var preset = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer preset.deinit();

    try CreateAutoModerationRule.init("preset guard", .keyword_preset, &.{AutoModerationAction.blockMemberInteraction()})
        .withTriggerMetadata(AutoModerationTriggerMetadata.init().withPresets(&.{ .profanity, .slurs }))
        .writeJson(&preset.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"preset guard\",\"event_type\":1,\"trigger_type\":4,\"trigger_metadata\":{\"presets\":[1,3]},\"actions\":[{\"type\":4}]}",
        preset.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    try EditAutoModerationRule.init()
        .withName("mention guard")
        .withEventType(.member_update)
        .withTriggerMetadata(AutoModerationTriggerMetadata.init()
            .withMentionLimit(8)
            .mentionRaidProtection(true))
        .withActions(&.{AutoModerationAction.timeout(300)})
        .enabledState(false)
        .withExemptRoles(&.{})
        .withExemptChannels(&channels)
        .writeJson(&edit.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"mention guard\",\"event_type\":2,\"trigger_metadata\":{\"mention_total_limit\":8,\"mention_raid_protection_enabled\":true},\"actions\":[{\"type\":3,\"metadata\":{\"duration_seconds\":300}}],\"enabled\":false,\"exempt_roles\":[],\"exempt_channels\":[\"20\"]}",
        edit.written(),
    );
}

test "create DM channel JSON writes recipient id as string" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try CreateDmChannel.init(Snowflake.init(42)).writeJson(&out.writer);
    try std.testing.expectEqualStrings("{\"recipient_id\":\"42\"}", out.written());
}

test "thread creation JSON supports message and standalone variants" {
    var from_message = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer from_message.deinit();

    try CreateThreadFromMessage.init("debug")
        .withAutoArchiveDuration(1440)
        .withRateLimit(5)
        .writeJson(&from_message.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"debug\",\"auto_archive_duration\":1440,\"rate_limit_per_user\":5}",
        from_message.written(),
    );

    var standalone = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer standalone.deinit();

    try CreateThread.init("private")
        .withType(.private_thread)
        .invitableState(false)
        .writeJson(&standalone.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"private\",\"type\":12,\"invitable\":false}",
        standalone.written(),
    );
}

test "create channel invite JSON emits optional settings" {
    var query = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer query.deinit();

    try GetInvite.init()
        .withCounts(true)
        .withScheduledEvent(Snowflake.init(99))
        .writeQuery(&query.writer);
    try std.testing.expectEqualStrings(
        "with_counts=true&guild_scheduled_event_id=99",
        query.written(),
    );

    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try CreateChannelInvite.init()
        .withMaxAge(3600)
        .withMaxUses(5)
        .temporaryState(false)
        .uniqueState(true)
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"max_age\":3600,\"max_uses\":5,\"temporary\":false,\"unique\":true}",
        out.written(),
    );
}

test "lobby JSON supports metadata members bulk updates and channel links" {
    const metadata = [_]StringPair{.{ .key = "mode", .value = "duo" }};
    const member_metadata = [_]StringPair{.{ .key = "rank", .value = "gold" }};
    const members = [_]LobbyMember{
        LobbyMember.init(Snowflake.init(20)).withMetadata(&member_metadata).withFlags(1),
    };

    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();
    try CreateLobby.init()
        .withMetadata(&metadata)
        .withMembers(&members)
        .withIdleTimeout(60)
        .writeJson(&create.writer);
    try std.testing.expectEqualStrings(
        "{\"metadata\":{\"mode\":\"duo\"},\"members\":[{\"id\":\"20\",\"metadata\":{\"rank\":\"gold\"},\"flags\":1}],\"idle_timeout_seconds\":60}",
        create.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();
    try EditLobby.init().clearMetadata().writeJson(&edit.writer);
    try std.testing.expectEqualStrings("{\"metadata\":null}", edit.written());

    var bulk = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer bulk.deinit();
    const bulk_members = [_]LobbyMember{LobbyMember.init(Snowflake.init(21)).removeState(true)};
    try BulkUpdateLobbyMembers.init(&bulk_members).writeJson(&bulk.writer);
    try std.testing.expectEqualStrings("[{\"id\":\"21\",\"remove_member\":true}]", bulk.written());

    var link = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer link.deinit();
    try LinkLobbyChannel.init(Snowflake.init(30)).writeJson(&link.writer);
    try std.testing.expectEqualStrings("{\"channel_id\":\"30\"}", link.written());

    var unlink = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer unlink.deinit();
    try LinkLobbyChannel.unlink().writeJson(&unlink.writer);
    try std.testing.expectEqualStrings("{\"channel_id\":null}", unlink.written());

    var moderation = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer moderation.deinit();
    const moderation_metadata = [_]StringPair{
        .{ .key = "action", .value = "replace" },
        .{ .key = "replacement", .value = "Be kind" },
    };
    try UpdateLobbyMessageModerationMetadata.init(&moderation_metadata).writeJson(&moderation.writer);
    try std.testing.expectEqualStrings("{\"action\":\"replace\",\"replacement\":\"Be kind\"}", moderation.written());
}

test "webhook JSON supports create and edit payloads" {
    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();

    try CreateWebhook.init("deploys").withAvatar("data:image/png;base64,abc").writeJson(&create.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"deploys\",\"avatar\":\"data:image/png;base64,abc\"}",
        create.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    try EditWebhook.init().withName("alerts").withChannel(Snowflake.init(42)).writeJson(&edit.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"alerts\",\"channel_id\":\"42\"}",
        edit.written(),
    );

    var edit_with_token = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit_with_token.deinit();

    try EditWebhookWithToken.init()
        .withName("token-alerts")
        .withAvatar("data:image/png;base64,def")
        .writeJson(&edit_with_token.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"token-alerts\",\"avatar\":\"data:image/png;base64,def\"}",
        edit_with_token.written(),
    );
}

test "execute webhook JSON supports message override fields" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try ExecuteWebhook.init("deploy complete")
        .withFlags(MessageFlags.suppress_notifications)
        .withUsername("deploys")
        .withAvatarUrl("https://example.com/avatar.png")
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"content\":\"deploy complete\",\"flags\":4096,\"username\":\"deploys\",\"avatar_url\":\"https://example.com/avatar.png\"}",
        out.written(),
    );

    var rich = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer rich.deinit();

    const embeds = [_]Embed{Embed.init().withTitle("Deploy")};
    const buttons = [_]Interactions.Component{.{ .button = Interactions.Button.primary("ack", "Ack") }};
    const rows = [_]Interactions.Component{Interactions.Component.actionRow(&buttons)};

    try ExecuteWebhook.empty()
        .withEmbeds(&embeds)
        .withComponents(&rows)
        .withAllowedMentions(AllowedMentions.none())
        .ttsState(true)
        .writeJson(&rich.writer);

    try std.testing.expectEqualStrings(
        "{\"embeds\":[{\"title\":\"Deploy\"}],\"allowed_mentions\":{\"parse\":[]},\"components\":[{\"type\":1,\"components\":[{\"type\":2,\"style\":1,\"custom_id\":\"ack\",\"label\":\"Ack\"}]}],\"tts\":true}",
        rich.written(),
    );
}

test "execute webhook payload_json includes attachments" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const files = [_]UploadFile{
        UploadFile.init("deploy.txt", "done").withDescription("Release notes"),
    };

    try writeExecuteWebhookJsonWithAttachments(
        ExecuteWebhook.init("ship")
            .withUsername("deploys")
            .withThreadName("release-thread"),
        &files,
        &out.writer,
    );

    try std.testing.expectEqualStrings(
        "{\"content\":\"ship\",\"username\":\"deploys\",\"thread_name\":\"release-thread\",\"attachments\":[{\"id\":\"0\",\"filename\":\"deploy.txt\",\"description\":\"Release notes\"}]}",
        out.written(),
    );
}

test "message JSON supports flags for create and edit" {
    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();

    try CreateMessage.init("quiet")
        .withFlags(MessageFlags.suppress_embeds | MessageFlags.suppress_notifications)
        .writeJson(&create.writer);
    try std.testing.expectEqualStrings(
        "{\"content\":\"quiet\",\"flags\":4100}",
        create.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    try EditMessage.init().withFlags(MessageFlags.suppress_embeds).writeJson(&edit.writer);
    try std.testing.expectEqualStrings("{\"flags\":4}", edit.written());
}

test "create message JSON supports stickers and nonce enforcement" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const stickers = [_]Snowflake{ Snowflake.init(60), Snowflake.init(61) };

    try CreateMessage.empty()
        .withNonce("client-1", true)
        .withStickers(&stickers)
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"sticker_ids\":[\"60\",\"61\"],\"nonce\":\"client-1\",\"enforce_nonce\":true}",
        out.written(),
    );
}

test "create message JSON includes embeds and allowed mentions" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const fields = [_]EmbedField{
        .{ .name = "Runtime", .value = "Zig", .is_inline = true },
    };
    const embeds = [_]Embed{
        .{
            .title = "discord.zig",
            .description = "Fast bot core",
            .color = 0x5865F2,
            .footer = .{ .text = "v0.1" },
            .fields = &fields,
        },
    };
    const users = [_]Snowflake{Snowflake.init(42)};

    try CreateMessage.init("hello")
        .withEmbeds(&embeds)
        .withAllowedMentions(AllowedMentions.usersOnly().withUsers(&users))
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"content\":\"hello\",\"embeds\":[{\"title\":\"discord.zig\",\"description\":\"Fast bot core\",\"color\":5793266,\"footer\":{\"text\":\"v0.1\"},\"fields\":[{\"name\":\"Runtime\",\"value\":\"Zig\",\"inline\":true}]}],\"allowed_mentions\":{\"parse\":[\"users\"],\"users\":[\"42\"]}}",
        out.written(),
    );
}

test "embed helper supports single field storage" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const field = EmbedField.inlineField("Runtime", "Zig");
    try Embed.init()
        .withTitle("Status")
        .withField(&field)
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"title\":\"Status\",\"fields\":[{\"name\":\"Runtime\",\"value\":\"Zig\",\"inline\":true}]}",
        out.written(),
    );
}

test "allowed mentions helper JSON covers common mention policies" {
    var none = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer none.deinit();
    try AllowedMentions.none().writeJson(&none.writer);
    try std.testing.expectEqualStrings("{\"parse\":[]}", none.written());

    var all_mentions = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer all_mentions.deinit();
    try AllowedMentions.all().repliedUser(true).writeJson(&all_mentions.writer);
    try std.testing.expectEqualStrings("{\"parse\":[\"roles\",\"users\",\"everyone\"],\"replied_user\":true}", all_mentions.written());

    var reply_only = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer reply_only.deinit();
    try AllowedMentions.repliedUserOnly().writeJson(&reply_only.writer);
    try std.testing.expectEqualStrings("{\"parse\":[],\"replied_user\":true}", reply_only.written());

    var allowlists = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer allowlists.deinit();
    const users = [_]Snowflake{Snowflake.init(10)};
    const roles = [_]Snowflake{Snowflake.init(20)};
    try AllowedMentions.none()
        .withUsers(&users)
        .withRoles(&roles)
        .repliedUser(true)
        .writeJson(&allowlists.writer);
    try std.testing.expectEqualStrings(
        "{\"parse\":[],\"users\":[\"10\"],\"roles\":[\"20\"],\"replied_user\":true}",
        allowlists.written(),
    );

    var single_allowlist = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer single_allowlist.deinit();
    const single_user = Snowflake.init(30);
    const single_role = Snowflake.init(40);
    try AllowedMentions.none()
        .withUser(&single_user)
        .withRole(&single_role)
        .writeJson(&single_allowlist.writer);
    try std.testing.expectEqualStrings(
        "{\"parse\":[],\"users\":[\"30\"],\"roles\":[\"40\"]}",
        single_allowlist.written(),
    );
}

test "embed builder helpers stream expected JSON" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const fields = [_]EmbedField{
        EmbedField.inlineField("Runtime", "Zig"),
        EmbedField.init("Transport", "REST").inlineState(false),
    };
    const embed = Embed.init()
        .withTitle("discord.zig")
        .withDescription("Fast bot core")
        .withUrl("https://example.com")
        .withTimestamp("2026-06-02T00:00:00.000Z")
        .withColor(0x5865F2)
        .withFooter(EmbedFooter.init("v0.1").withIcon("https://example.com/footer.png"))
        .withImage("https://example.com/image.png")
        .withThumbnail("https://example.com/thumb.png")
        .withAuthor(EmbedAuthor.init("Deploys").withUrl("https://example.com/deploys").withIcon("https://example.com/author.png"))
        .withFields(&fields);

    try embed.writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"title\":\"discord.zig\",\"description\":\"Fast bot core\",\"url\":\"https://example.com\",\"timestamp\":\"2026-06-02T00:00:00.000Z\",\"color\":5793266,\"footer\":{\"text\":\"v0.1\",\"icon_url\":\"https://example.com/footer.png\"},\"image\":{\"url\":\"https://example.com/image.png\"},\"thumbnail\":{\"url\":\"https://example.com/thumb.png\"},\"author\":{\"name\":\"Deploys\",\"url\":\"https://example.com/deploys\",\"icon_url\":\"https://example.com/author.png\"},\"fields\":[{\"name\":\"Runtime\",\"value\":\"Zig\",\"inline\":true},{\"name\":\"Transport\",\"value\":\"REST\"}]}",
        out.written(),
    );
}

test "create message JSON includes components" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const buttons = [_]Interactions.Component{
        .{ .button = Interactions.Button.primary("ok", "OK") },
    };
    const rows = [_]Interactions.Component{
        Interactions.Component.actionRow(&buttons),
    };

    try (CreateMessage{
        .content = "choose",
        .components = &rows,
    }).writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"content\":\"choose\",\"components\":[{\"type\":1,\"components\":[{\"type\":2,\"style\":1,\"custom_id\":\"ok\",\"label\":\"OK\"}]}]}",
        out.written(),
    );
}

test "create message JSON includes poll" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const answers = [_]PollAnswer{
        PollAnswer.text("Zig"),
        PollAnswer.withEmoji("C", PollEmoji.unicode("🇨")),
    };

    try (CreateMessage{
        .poll = CreatePoll.init("Runtime?", &answers)
            .withDuration(24)
            .multiselect(false)
            .withLayout(.default),
    }).writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"poll\":{\"question\":{\"text\":\"Runtime?\"},\"answers\":[{\"poll_media\":{\"text\":\"Zig\"}},{\"poll_media\":{\"text\":\"C\",\"emoji\":{\"name\":\"🇨\"}}}],\"duration\":24,\"allow_multiselect\":false,\"layout_type\":1}}",
        out.written(),
    );

    var question_emoji = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer question_emoji.deinit();

    try CreatePoll.init("Ship?", &answers)
        .withQuestionEmoji(PollEmoji.unicode("🚀"))
        .multiselect(true)
        .writeJson(&question_emoji.writer);

    try std.testing.expectEqualStrings(
        "{\"question\":{\"text\":\"Ship?\",\"emoji\":{\"name\":\"🚀\"}},\"answers\":[{\"poll_media\":{\"text\":\"Zig\"}},{\"poll_media\":{\"text\":\"C\",\"emoji\":{\"name\":\"🇨\"}}}],\"allow_multiselect\":true}",
        question_emoji.written(),
    );
}

test "create message JSON includes shared client theme" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try CreateMessage.init("theme").withSharedClientTheme(.{
        .colors = &.{ "5865F2", "E558F2" },
        .gradient_angle = 45,
        .base_mix = 58,
        .base_theme = .dark,
    }).writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"content\":\"theme\",\"shared_client_theme\":{\"colors\":[\"5865F2\",\"E558F2\"],\"gradient_angle\":45,\"base_mix\":58,\"base_theme\":1}}",
        out.written(),
    );
}

test "create message builder helpers compose components poll and tts" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const buttons = [_]Interactions.Component{
        .{ .button = Interactions.Button.primary("ok", "OK") },
    };
    const rows = [_]Interactions.Component{
        Interactions.Component.actionRow(&buttons),
    };
    const answers = [_]PollAnswer{
        PollAnswer.text("yes"),
        PollAnswer.text("no"),
    };

    try CreateMessage.init("choose")
        .withComponents(&rows)
        .withPoll(CreatePoll.init("Ship?", &answers))
        .ttsState(true)
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"content\":\"choose\",\"components\":[{\"type\":1,\"components\":[{\"type\":2,\"style\":1,\"custom_id\":\"ok\",\"label\":\"OK\"}]}],\"poll\":{\"question\":{\"text\":\"Ship?\"},\"answers\":[{\"poll_media\":{\"text\":\"yes\"}},{\"poll_media\":{\"text\":\"no\"}}]},\"tts\":true}",
        out.written(),
    );
}

test "discordjs style type aliases compile to existing builders" {
    var embed_out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer embed_out.deinit();
    try EmbedBuilder.init().withTitle("Deploy").writeJson(&embed_out.writer);
    try std.testing.expectEqualStrings("{\"title\":\"Deploy\"}", embed_out.written());

    const attachment = AttachmentBuilder.init("hello.txt", "hi").withDescription("Greeting");
    try std.testing.expectEqualStrings("hello.txt", attachment.filename);

    const attachment_path = AttachmentPathBuilder.init("hello.txt", "fixtures/hello.txt");
    try std.testing.expectEqualStrings("fixtures/hello.txt", attachment_path.path);

    var mentions_out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer mentions_out.deinit();
    try AllowedMentionsBuilder.none().withUsers(&.{Snowflake.init(10)}).writeJson(&mentions_out.writer);
    try std.testing.expectEqualStrings("{\"parse\":[],\"users\":[\"10\"]}", mentions_out.written());

    var poll_out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer poll_out.deinit();
    const answers = [_]PollAnswer{ PollAnswer.text("yes"), PollAnswer.text("no") };
    try PollBuilder.init("Ship?", &answers).writeJson(&poll_out.writer);
    try std.testing.expect(std.mem.indexOf(u8, poll_out.written(), "\"question\":{\"text\":\"Ship?\"}") != null);
}
test "create message payload_json includes upload attachments" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const stickers = [_]Snowflake{Snowflake.init(60)};
    const files = [_]UploadFile{
        UploadFile.init("hello.txt", "hello")
            .withContentType("text/plain")
            .withDescription("Greeting"),
    };

    try writeCreateMessageJsonWithAttachments(.{
        .content = "with file",
        .nonce = "upload-1",
        .enforce_nonce = true,
        .sticker_ids = &stickers,
    }, &files, &out.writer);
    try std.testing.expectEqualStrings(
        "{\"content\":\"with file\",\"sticker_ids\":[\"60\"],\"nonce\":\"upload-1\",\"enforce_nonce\":true,\"attachments\":[{\"id\":\"0\",\"filename\":\"hello.txt\",\"description\":\"Greeting\"}]}",
        out.written(),
    );
}

test "create message payload_json includes shared client theme with attachments" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const files = [_]UploadFile{
        UploadFile.init("hello.txt", "hello"),
    };

    try writeCreateMessageJsonWithAttachments(.{
        .shared_client_theme = .{
            .colors = &.{"111111"},
            .base_theme = .light,
        },
    }, &files, &out.writer);
    try std.testing.expectEqualStrings(
        "{\"shared_client_theme\":{\"colors\":[\"111111\"],\"base_theme\":2},\"attachments\":[{\"id\":\"0\",\"filename\":\"hello.txt\"}]}",
        out.written(),
    );
}

test "create message payload_json includes poll with attachments" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const answers = [_]PollAnswer{
        PollAnswer.text("yes"),
        PollAnswer.text("no"),
    };
    const files = [_]UploadFile{
        UploadFile.init("context.txt", "details"),
    };

    try writeCreateMessageJsonWithAttachments(.{
        .poll = CreatePoll.init("Ship?", &answers),
    }, &files, &out.writer);
    try std.testing.expectEqualStrings(
        "{\"poll\":{\"question\":{\"text\":\"Ship?\"},\"answers\":[{\"poll_media\":{\"text\":\"yes\"}},{\"poll_media\":{\"text\":\"no\"}}]},\"attachments\":[{\"id\":\"0\",\"filename\":\"context.txt\"}]}",
        out.written(),
    );
}

test "upload file path builder helpers include attachment metadata" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const files = [_]UploadFilePath{
        UploadFilePath.init("report.json", "fixtures/report.json")
            .withContentType("application/json")
            .withDescription("Build report"),
    };

    try writeCreateMessageJsonWithAttachmentMetadata(.{
        .content = "path file",
    }, &files, &out.writer);

    try std.testing.expectEqualStrings(
        "{\"content\":\"path file\",\"attachments\":[{\"id\":\"0\",\"filename\":\"report.json\",\"description\":\"Build report\"}]}",
        out.written(),
    );
}

test "create message JSON includes reply reference" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try (CreateMessage{
        .content = "reply",
        .message_reference = .{
            .message_id = Snowflake.init(10),
            .channel_id = Snowflake.init(20),
            .fail_if_not_exists = false,
        },
    }).writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"content\":\"reply\",\"message_reference\":{\"message_id\":\"10\",\"channel_id\":\"20\",\"fail_if_not_exists\":false}}",
        out.written(),
    );

    var forward = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer forward.deinit();

    try (CreateMessage{
        .message_reference = MessageReference.forward(Snowflake.init(10), Snowflake.init(20)),
    }).writeJson(&forward.writer);

    try std.testing.expectEqualStrings(
        "{\"message_reference\":{\"type\":1,\"message_id\":\"10\",\"channel_id\":\"20\"}}",
        forward.written(),
    );
}

test "edit message JSON supports content and embeds" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const embeds = [_]Embed{.{ .title = "edited" }};
    try EditMessage.init()
        .withContent("updated")
        .withEmbeds(&embeds)
        .withAllowedMentions(AllowedMentions.none())
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"content\":\"updated\",\"embeds\":[{\"title\":\"edited\"}],\"allowed_mentions\":{\"parse\":[]}}",
        out.written(),
    );
}

test "message payload validate enforces content embed sticker mention and component limits" {
    const long_content = "x" ** (max_message_content_len + 1);
    try std.testing.expectError(error.ContentTooLong, CreateMessage.init(long_content).validate());

    const too_many_embeds = [_]Embed{Embed.init()} ** (max_message_embeds + 1);
    try std.testing.expectError(error.TooManyEmbeds, CreateMessage.empty().withEmbeds(&too_many_embeds).validate());

    const too_many_stickers = [_]Snowflake{Snowflake.init(1)} ** (max_message_stickers + 1);
    try std.testing.expectError(error.TooManyStickers, CreateMessage.empty().withStickers(&too_many_stickers).validate());

    const users = [_]Snowflake{Snowflake.init(2)} ** (AllowedMentions.max_users + 1);
    try std.testing.expectError(
        error.TooManyUsers,
        CreateMessage.init("hi").withAllowedMentions(AllowedMentions.none().withUsers(&users)).validate(),
    );

    const row_children = [_]Interactions.Component{.{ .button = Interactions.Button.primary("id", "ok") }} ** (Interactions.max_row_components + 1);
    const rows = [_]Interactions.Component{Interactions.Component.actionRow(&row_children)};
    try std.testing.expectError(error.TooManyRowComponents, CreateMessage.empty().withComponents(&rows).validate());
}

test "message payload validate handles components v2 exclusivity and nonce length" {
    const text = [_]Interactions.TextDisplay{Interactions.TextDisplay.init("body")};
    const components = [_]Interactions.Component{.{ .section = Interactions.Section.withButton(&text, Interactions.Button.primary("id", "ok")) }};

    try CreateMessage.empty()
        .withFlags(MessageFlags.is_components_v2)
        .withComponents(&components)
        .validate();

    try std.testing.expectError(
        error.ComponentsV2Exclusive,
        CreateMessage.init("not allowed")
            .withFlags(MessageFlags.is_components_v2)
            .withComponents(&components)
            .validate(),
    );

    const long_nonce = "n" ** (max_message_nonce_len + 1);
    try std.testing.expectError(error.NonceTooLong, CreateMessage.init("hi").withNonce(long_nonce, true).validate());

    try std.testing.expectError(error.ContentTooLong, EditMessage.init().withContent("x" ** (max_message_content_len + 1)).validate());
}

test "embed validate rejects field overflow at the limit boundary" {
    const at_limit = [_]EmbedField{EmbedField.init("n", "v")} ** Embed.max_fields;
    try Embed.init().withFields(&at_limit).validate();

    const over_limit = [_]EmbedField{EmbedField.init("n", "v")} ** (Embed.max_fields + 1);
    try std.testing.expectError(error.TooManyFields, Embed.init().withFields(&over_limit).validate());
}

test "embed validate enforces per-field and total character limits" {
    const long_title = "x" ** (Embed.max_title_len + 1);
    try std.testing.expectError(error.TitleTooLong, Embed.init().withTitle(long_title).validate());

    const long_value = "y" ** (EmbedField.max_value_len + 1);
    const big_field = [_]EmbedField{EmbedField.init("ok", long_value)};
    try std.testing.expectError(error.FieldValueTooLong, Embed.init().withFields(&big_field).validate());

    // Each field is within its own limit, but together they exceed the 6000 total.
    const chunk = "z" ** 1000;
    const heavy = [_]EmbedField{EmbedField.init("name", chunk)} ** 7;
    try std.testing.expectError(error.EmbedTooLong, Embed.init().withFields(&heavy).validate());

    // Multi-byte characters are counted as single code points, not bytes.
    const two_byte = "é" ** Embed.max_title_len; // 2 bytes each, 256 code points
    try Embed.init().withTitle(two_byte).validate();

    try std.testing.expectError(error.InvalidUtf8, Embed.init().withTitle("\xff\xfe").validate());
}

test "allowed mentions validate enforces id limits and parse conflicts" {
    const id = Snowflake.init(1);
    const too_many = [_]Snowflake{id} ** (AllowedMentions.max_users + 1);
    try std.testing.expectError(error.TooManyUsers, AllowedMentions.none().withUsers(&too_many).validate());

    // Explicit allowlist plus the broad parse entry of the same kind is rejected.
    const one = [_]Snowflake{id};
    const conflict = AllowedMentions.usersOnly().withUsers(&one);
    try std.testing.expectError(error.UserParseConflict, conflict.validate());

    // Explicit roles with a users-only parse policy is allowed.
    try AllowedMentions.usersOnly().withRoles(&one).validate();
    try AllowedMentions.all().validate();
}

test "execute webhook thread name and query options" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();
    try ExecuteWebhook.init("hi").withThreadName("forum post").writeJson(&out.writer);
    try std.testing.expectEqualStrings("{\"content\":\"hi\",\"thread_name\":\"forum post\"}", out.written());

    var query = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer query.deinit();
    const options = ExecuteWebhookQuery{ .wait = true, .thread_id = Snowflake.init(55) };
    try std.testing.expect(options.hasQuery());
    try options.writeQuery(&query.writer);
    try std.testing.expectEqualStrings("wait=true&thread_id=55", query.written());

    try std.testing.expect(!(ExecuteWebhookQuery{}).hasQuery());
}

test "channel type guards classify channels like Discord.js" {
    try std.testing.expect(ChannelType.public_thread.isThread());
    try std.testing.expect(!ChannelType.guild_text.isThread());

    try std.testing.expect(ChannelType.guild_voice.isVoiceBased());
    try std.testing.expect(ChannelType.guild_stage_voice.isVoiceBased());
    try std.testing.expect(!ChannelType.guild_text.isVoiceBased());

    // Voice channels and threads are text-based; categories/forums are not.
    try std.testing.expect(ChannelType.guild_text.isTextBased());
    try std.testing.expect(ChannelType.guild_voice.isTextBased());
    try std.testing.expect(ChannelType.public_thread.isTextBased());
    try std.testing.expect(!ChannelType.guild_category.isTextBased());
    try std.testing.expect(!ChannelType.guild_forum.isTextBased());

    try std.testing.expect(ChannelType.dm.isDMBased());
    try std.testing.expect(ChannelType.group_dm.isDMBased());
    try std.testing.expect(!ChannelType.guild_text.isDMBased());

    try std.testing.expect(ChannelType.guild_forum.isThreadOnly());
    try std.testing.expect(ChannelType.guild_media.isThreadOnly());
    try std.testing.expect(!ChannelType.guild_text.isThreadOnly());

    try std.testing.expect(ChannelType.guild_text.isGuildBased());
    try std.testing.expect(!ChannelType.dm.isGuildBased());
}

test "embed color uses Discord color palette" {
    try std.testing.expectEqual(@as(u24, 0x5865F2), Colors.blurple);
    try std.testing.expectEqual(@as(u24, 0xED4245), Colors.red);

    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();
    try Embed.init().withColor(Colors.blurple).writeJson(&out.writer);
    try std.testing.expectEqualStrings("{\"color\":5793266}", out.written());
}

test "user and application flag helpers detect set bits" {
    const badges = UserFlags.active_developer | UserFlags.verified_bot;
    try std.testing.expect(UserFlags.has(badges, UserFlags.active_developer));
    try std.testing.expect(UserFlags.has(badges, UserFlags.verified_bot));
    try std.testing.expect(!UserFlags.has(badges, UserFlags.staff));
    try std.testing.expectEqual(@as(u32, 1) << 22, UserFlags.active_developer);

    const app = ApplicationFlags.gateway_message_content | ApplicationFlags.embedded;
    try std.testing.expect(ApplicationFlags.has(app, ApplicationFlags.embedded));
    try std.testing.expect(!ApplicationFlags.has(app, ApplicationFlags.gateway_presence));
}

test "message type and guild member flags expose Discord values" {
    try std.testing.expectEqual(@as(u8, 19), @intFromEnum(MessageType.reply));
    try std.testing.expectEqual(@as(u8, 0), @intFromEnum(MessageType.default));
    try std.testing.expectEqual(@as(u8, 46), @intFromEnum(MessageType.poll_result));

    const flags = GuildMemberFlags.completed_onboarding | GuildMemberFlags.did_rejoin;
    try std.testing.expect(GuildMemberFlags.has(flags, GuildMemberFlags.completed_onboarding));
    try std.testing.expect(!GuildMemberFlags.has(flags, GuildMemberFlags.is_guest));
}

test "audit log event enum filters the audit log query" {
    try std.testing.expectEqual(@as(u16, 72), @intFromEnum(AuditLogEvent.message_delete));
    try std.testing.expectEqual(@as(u16, 1), @intFromEnum(AuditLogEvent.guild_update));
    try std.testing.expectEqual(@as(u16, 145), @intFromEnum(AuditLogEvent.auto_moderation_user_communication_disabled));

    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();
    const options = ListAuditLog.init().withAuditEvent(.member_ban_add).withLimit(10);
    try options.writeQuery(&out.writer);
    try std.testing.expectEqualStrings("action_type=22&limit=10", out.written());
}
