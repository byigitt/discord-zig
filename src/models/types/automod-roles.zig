const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Json = @import("../../core/json.zig");
const Interactions = @import("../../interactions/mod.zig");
const Permissions = @import("../../core/permissions.zig");

const Root = @import("../types.zig");
const User = Root.User;
const AutoModerationRuleEventType = Root.AutoModerationRuleEventType;
const AutoModerationTriggerMetadata = Root.AutoModerationTriggerMetadata;
const AutoModerationAction = Root.AutoModerationAction;
const writeChannelFields = Root.writeChannelFields;
const writeSnowflakeStringArray = Root.writeSnowflakeStringArray;
const writeAutoModerationActionArray = Root.writeAutoModerationActionArray;
const writeOptionalStringField = Root.writeOptionalStringField;
const writeNullableStringField = Root.writeNullableStringField;
const writeNullableSnowflakeField = Root.writeNullableSnowflakeField;
const writeOptionalBoolField = Root.writeOptionalBoolField;
const writeComma = Root.writeComma;

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

    pub const GuildText: @This() = .guild_text;
    pub const DM: @This() = .dm;
    pub const GuildVoice: @This() = .guild_voice;
    pub const GroupDM: @This() = .group_dm;
    pub const GuildCategory: @This() = .guild_category;
    pub const GuildAnnouncement: @This() = .guild_announcement;
    pub const AnnouncementThread: @This() = .announcement_thread;
    pub const PublicThread: @This() = .public_thread;
    pub const PrivateThread: @This() = .private_thread;
    pub const GuildStageVoice: @This() = .guild_stage_voice;
    pub const GuildDirectory: @This() = .guild_directory;
    pub const GuildForum: @This() = .guild_forum;
    pub const GuildMedia: @This() = .guild_media;

    pub const ChannelTypeInfo = struct {
        value: ChannelType,
        name: []const u8,
    };

    pub const all_channel_types = [_]ChannelTypeInfo{
        .{ .value = GuildText, .name = "GuildText" },
        .{ .value = DM, .name = "DM" },
        .{ .value = GuildVoice, .name = "GuildVoice" },
        .{ .value = GroupDM, .name = "GroupDM" },
        .{ .value = GuildCategory, .name = "GuildCategory" },
        .{ .value = GuildAnnouncement, .name = "GuildAnnouncement" },
        .{ .value = AnnouncementThread, .name = "AnnouncementThread" },
        .{ .value = PublicThread, .name = "PublicThread" },
        .{ .value = PrivateThread, .name = "PrivateThread" },
        .{ .value = GuildStageVoice, .name = "GuildStageVoice" },
        .{ .value = GuildDirectory, .name = "GuildDirectory" },
        .{ .value = GuildForum, .name = "GuildForum" },
        .{ .value = GuildMedia, .name = "GuildMedia" },
    };

    pub fn discordJsName(self: ChannelType) []const u8 {
        return switch (self) {
            .guild_text => "GuildText",
            .dm => "DM",
            .guild_voice => "GuildVoice",
            .group_dm => "GroupDM",
            .guild_category => "GuildCategory",
            .guild_announcement => "GuildAnnouncement",
            .announcement_thread => "AnnouncementThread",
            .public_thread => "PublicThread",
            .private_thread => "PrivateThread",
            .guild_stage_voice => "GuildStageVoice",
            .guild_directory => "GuildDirectory",
            .guild_forum => "GuildForum",
            .guild_media => "GuildMedia",
        };
    }

    pub fn fromDiscordJsName(name: []const u8) ?ChannelType {
        for (all_channel_types) |channel_type| {
            if (std.mem.eql(u8, channel_type.name, name)) return channel_type.value;
        }
        return null;
    }

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
