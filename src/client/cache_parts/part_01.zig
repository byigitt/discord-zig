const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Types = @import("../../models/types.zig");
const Gateway = @import("../../gateway/protocol.zig");
const Interactions = @import("../../interactions/mod.zig");
const Permissions = @import("../../core/permissions.zig");
const Collection = @import("../../core/collection.zig").Collection;

const test_part_01 = @import("../cache_tests/part_01.zig");
const test_part_02 = @import("../cache_tests/part_02.zig");
const test_part_03 = @import("../cache_tests/part_03.zig");
const test_part_04 = @import("../cache_tests/part_04.zig");
const test_part_05 = @import("../cache_tests/part_05.zig");
const test_part_06 = @import("../cache_tests/part_06.zig");
const test_part_07 = @import("../cache_tests/part_07.zig");

const Root = @import("../cache.zig");
const deinit = Root.deinit;
const copyDefaultReactionEmoji = Root.copyDefaultReactionEmoji;
const copyForumTags = Root.copyForumTags;
const copyThreadMetadata = Root.copyThreadMetadata;
const deinitDefaultReactionEmoji = Root.deinitDefaultReactionEmoji;
const deinitForumTags = Root.deinitForumTags;
const deinitThreadMetadata = Root.deinitThreadMetadata;
const copyStringArray = Root.copyStringArray;
const deinitStringArray = Root.deinitStringArray;

pub const OwnedUser = struct {
    id: Snowflake,
    username: []u8,
    discriminator: ?[]u8,
    global_name: ?[]u8,
    avatar: ?[]u8,
    banner: ?[]u8,
    bot: bool,
    system: bool,
    mfa_enabled: ?bool,
    accent_color: ?u32,
    locale: ?[]u8,
    verified: ?bool,
    email: ?[]u8,
    flags: ?u32,
    public_flags: ?u32,

    pub fn copy(allocator: std.mem.Allocator, user: Types.User) !OwnedUser {
        const username = try allocator.dupe(u8, user.username);
        errdefer allocator.free(username);
        const discriminator = if (user.discriminator) |value| try allocator.dupe(u8, value) else null;
        errdefer if (discriminator) |value| allocator.free(value);
        const global_name = if (user.global_name) |value| try allocator.dupe(u8, value) else null;
        errdefer if (global_name) |value| allocator.free(value);
        const avatar = if (user.avatar) |value| try allocator.dupe(u8, value) else null;
        errdefer if (avatar) |value| allocator.free(value);
        const banner = if (user.banner) |value| try allocator.dupe(u8, value) else null;
        errdefer if (banner) |value| allocator.free(value);
        const locale = if (user.locale) |value| try allocator.dupe(u8, value) else null;
        errdefer if (locale) |value| allocator.free(value);
        const email = if (user.email) |value| try allocator.dupe(u8, value) else null;
        return .{
            .id = user.id,
            .username = username,
            .discriminator = discriminator,
            .global_name = global_name,
            .avatar = avatar,
            .banner = banner,
            .bot = user.bot,
            .system = user.system,
            .mfa_enabled = user.mfa_enabled,
            .accent_color = user.accent_color,
            .locale = locale,
            .verified = user.verified,
            .email = email,
            .flags = user.flags,
            .public_flags = user.public_flags,
        };
    }

    pub fn deinit(self: OwnedUser, allocator: std.mem.Allocator) void {
        allocator.free(self.username);
        if (self.discriminator) |value| allocator.free(value);
        if (self.global_name) |value| allocator.free(value);
        if (self.avatar) |value| allocator.free(value);
        if (self.banner) |value| allocator.free(value);
        if (self.locale) |value| allocator.free(value);
        if (self.email) |value| allocator.free(value);
    }

    pub fn view(self: OwnedUser) Types.User {
        return .{
            .id = self.id,
            .username = self.username,
            .discriminator = self.discriminator,
            .global_name = self.global_name,
            .avatar = self.avatar,
            .banner = self.banner,
            .bot = self.bot,
            .system = self.system,
            .mfa_enabled = self.mfa_enabled,
            .accent_color = self.accent_color,
            .locale = self.locale,
            .verified = self.verified,
            .email = self.email,
            .flags = self.flags,
            .public_flags = self.public_flags,
        };
    }
};

pub const OwnedGuild = struct {
    id: Snowflake,
    name: []u8,
    icon: ?[]u8,
    banner: ?[]u8,
    owner_id: ?Snowflake,
    description: ?[]u8,
    afk_channel_id: ?Snowflake,
    afk_timeout: ?u32,
    system_channel_id: ?Snowflake,
    rules_channel_id: ?Snowflake,
    public_updates_channel_id: ?Snowflake,
    safety_alerts_channel_id: ?Snowflake,
    features: [][]u8,
    preferred_locale: ?[]u8,
    verification_level: ?u8,
    default_message_notifications: ?u8,
    explicit_content_filter: ?u8,
    mfa_level: ?u8,
    nsfw_level: ?u8,
    max_presences: ?u32,
    max_members: ?u32,
    premium_tier: ?u8,
    premium_subscription_count: ?u32,
    premium_progress_bar_enabled: ?bool,
    approximate_member_count: ?u32,
    approximate_presence_count: ?u32,

    pub fn copy(allocator: std.mem.Allocator, guild: Types.Guild) !OwnedGuild {
        const name = try allocator.dupe(u8, guild.name);
        errdefer allocator.free(name);
        const icon = if (guild.icon) |value| try allocator.dupe(u8, value) else null;
        errdefer if (icon) |value| allocator.free(value);
        const banner = if (guild.banner) |value| try allocator.dupe(u8, value) else null;
        errdefer if (banner) |value| allocator.free(value);
        const description = if (guild.description) |value| try allocator.dupe(u8, value) else null;
        errdefer if (description) |value| allocator.free(value);
        const features = try copyStringArray(allocator, guild.features);
        errdefer deinitStringArray(features, allocator);
        const preferred_locale = if (guild.preferred_locale) |value| try allocator.dupe(u8, value) else null;
        return .{
            .id = guild.id,
            .name = name,
            .icon = icon,
            .banner = banner,
            .owner_id = guild.owner_id,
            .description = description,
            .afk_channel_id = guild.afk_channel_id,
            .afk_timeout = guild.afk_timeout,
            .system_channel_id = guild.system_channel_id,
            .rules_channel_id = guild.rules_channel_id,
            .public_updates_channel_id = guild.public_updates_channel_id,
            .safety_alerts_channel_id = guild.safety_alerts_channel_id,
            .features = features,
            .preferred_locale = preferred_locale,
            .verification_level = guild.verification_level,
            .default_message_notifications = guild.default_message_notifications,
            .explicit_content_filter = guild.explicit_content_filter,
            .mfa_level = guild.mfa_level,
            .nsfw_level = guild.nsfw_level,
            .max_presences = guild.max_presences,
            .max_members = guild.max_members,
            .premium_tier = guild.premium_tier,
            .premium_subscription_count = guild.premium_subscription_count,
            .premium_progress_bar_enabled = guild.premium_progress_bar_enabled,
            .approximate_member_count = guild.approximate_member_count,
            .approximate_presence_count = guild.approximate_presence_count,
        };
    }

    pub fn deinit(self: OwnedGuild, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        if (self.icon) |value| allocator.free(value);
        if (self.banner) |value| allocator.free(value);
        if (self.description) |value| allocator.free(value);
        deinitStringArray(self.features, allocator);
        if (self.preferred_locale) |value| allocator.free(value);
    }

    pub fn view(self: OwnedGuild) Types.Guild {
        return .{
            .id = self.id,
            .name = self.name,
            .icon = self.icon,
            .banner = self.banner,
            .owner_id = self.owner_id,
            .description = self.description,
            .afk_channel_id = self.afk_channel_id,
            .afk_timeout = self.afk_timeout,
            .system_channel_id = self.system_channel_id,
            .rules_channel_id = self.rules_channel_id,
            .public_updates_channel_id = self.public_updates_channel_id,
            .safety_alerts_channel_id = self.safety_alerts_channel_id,
            .features = self.features,
            .preferred_locale = self.preferred_locale,
            .verification_level = self.verification_level,
            .default_message_notifications = self.default_message_notifications,
            .explicit_content_filter = self.explicit_content_filter,
            .mfa_level = self.mfa_level,
            .nsfw_level = self.nsfw_level,
            .max_presences = self.max_presences,
            .max_members = self.max_members,
            .premium_tier = self.premium_tier,
            .premium_subscription_count = self.premium_subscription_count,
            .premium_progress_bar_enabled = self.premium_progress_bar_enabled,
            .approximate_member_count = self.approximate_member_count,
            .approximate_presence_count = self.approximate_presence_count,
        };
    }
};

pub const OwnedChannel = struct {
    id: Snowflake,
    type: Types.ChannelType,
    guild_id: ?Snowflake,
    name: ?[]u8,
    topic: ?[]u8,
    status: ?[]u8,
    voice_start_time: ?i64,
    last_message_id: ?Snowflake,
    last_pin_timestamp: ?[]u8,
    parent_id: ?Snowflake,
    owner_id: ?Snowflake,
    application_id: ?Snowflake,
    position: ?i32,
    nsfw: bool,
    rate_limit_per_user: ?u16,
    bitrate: ?u32,
    user_limit: ?u16,
    rtc_region: ?[]u8,
    video_quality_mode: ?u8,
    message_count: ?u32,
    member_count: ?u32,
    managed: bool,
    flags: ?Types.ChannelFlags.Bit,
    permission_overwrites: []Types.PermissionOverwrite,
    thread_metadata: ?Types.ThreadMetadata,
    applied_tags: []Snowflake,
    available_tags: []Types.ForumTag,
    default_reaction_emoji: ?Types.DefaultReactionEmoji,
    default_thread_rate_limit_per_user: ?u16,
    default_sort_order: ?Types.ChannelSortOrder,
    default_forum_layout: ?Types.ForumLayout,

    pub fn copy(allocator: std.mem.Allocator, channel: Types.Channel) !OwnedChannel {
        const name = if (channel.name) |value| try allocator.dupe(u8, value) else null;
        errdefer if (name) |value| allocator.free(value);
        const topic = if (channel.topic) |value| try allocator.dupe(u8, value) else null;
        errdefer if (topic) |value| allocator.free(value);
        const status = if (channel.status) |value| try allocator.dupe(u8, value) else null;
        errdefer if (status) |value| allocator.free(value);
        const last_pin_timestamp = if (channel.last_pin_timestamp) |value| try allocator.dupe(u8, value) else null;
        errdefer if (last_pin_timestamp) |value| allocator.free(value);
        const rtc_region = if (channel.rtc_region) |value| try allocator.dupe(u8, value) else null;
        errdefer if (rtc_region) |value| allocator.free(value);
        const permission_overwrites = try allocator.dupe(Types.PermissionOverwrite, channel.permission_overwrites);
        errdefer allocator.free(permission_overwrites);
        const thread_metadata = if (channel.thread_metadata) |value| try copyThreadMetadata(allocator, value) else null;
        errdefer if (thread_metadata) |value| deinitThreadMetadata(value, allocator);
        const applied_tags = try allocator.dupe(Snowflake, channel.applied_tags);
        errdefer allocator.free(applied_tags);
        const available_tags = try copyForumTags(allocator, channel.available_tags);
        errdefer deinitForumTags(available_tags, allocator);
        const default_reaction_emoji = if (channel.default_reaction_emoji) |value| try copyDefaultReactionEmoji(allocator, value) else null;
        return .{
            .id = channel.id,
            .type = channel.type,
            .guild_id = channel.guild_id,
            .name = name,
            .topic = topic,
            .status = status,
            .voice_start_time = channel.voice_start_time,
            .last_message_id = channel.last_message_id,
            .last_pin_timestamp = last_pin_timestamp,
            .parent_id = channel.parent_id,
            .owner_id = channel.owner_id,
            .application_id = channel.application_id,
            .position = channel.position,
            .nsfw = channel.nsfw,
            .rate_limit_per_user = channel.rate_limit_per_user,
            .bitrate = channel.bitrate,
            .user_limit = channel.user_limit,
            .rtc_region = rtc_region,
            .video_quality_mode = channel.video_quality_mode,
            .message_count = channel.message_count,
            .member_count = channel.member_count,
            .managed = channel.managed,
            .flags = channel.flags,
            .permission_overwrites = permission_overwrites,
            .thread_metadata = thread_metadata,
            .applied_tags = applied_tags,
            .available_tags = available_tags,
            .default_reaction_emoji = default_reaction_emoji,
            .default_thread_rate_limit_per_user = channel.default_thread_rate_limit_per_user,
            .default_sort_order = channel.default_sort_order,
            .default_forum_layout = channel.default_forum_layout,
        };
    }

    pub fn deinit(self: OwnedChannel, allocator: std.mem.Allocator) void {
        if (self.name) |value| allocator.free(value);
        if (self.topic) |value| allocator.free(value);
        if (self.status) |value| allocator.free(value);
        if (self.last_pin_timestamp) |value| allocator.free(value);
        if (self.rtc_region) |value| allocator.free(value);
        allocator.free(self.permission_overwrites);
        if (self.thread_metadata) |value| deinitThreadMetadata(value, allocator);
        allocator.free(self.applied_tags);
        deinitForumTags(self.available_tags, allocator);
        if (self.default_reaction_emoji) |value| deinitDefaultReactionEmoji(value, allocator);
    }

    pub fn view(self: OwnedChannel) Types.Channel {
        return .{
            .id = self.id,
            .type = self.type,
            .guild_id = self.guild_id,
            .name = self.name,
            .topic = self.topic,
            .status = self.status,
            .voice_start_time = self.voice_start_time,
            .last_message_id = self.last_message_id,
            .last_pin_timestamp = self.last_pin_timestamp,
            .parent_id = self.parent_id,
            .owner_id = self.owner_id,
            .application_id = self.application_id,
            .position = self.position,
            .nsfw = self.nsfw,
            .rate_limit_per_user = self.rate_limit_per_user,
            .bitrate = self.bitrate,
            .user_limit = self.user_limit,
            .rtc_region = self.rtc_region,
            .video_quality_mode = self.video_quality_mode,
            .message_count = self.message_count,
            .member_count = self.member_count,
            .managed = self.managed,
            .flags = self.flags,
            .permission_overwrites = self.permission_overwrites,
            .thread_metadata = self.thread_metadata,
            .applied_tags = self.applied_tags,
            .available_tags = self.available_tags,
            .default_reaction_emoji = self.default_reaction_emoji,
            .default_thread_rate_limit_per_user = self.default_thread_rate_limit_per_user,
            .default_sort_order = self.default_sort_order,
            .default_forum_layout = self.default_forum_layout,
        };
    }
};
