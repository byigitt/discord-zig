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

pub const OwnedGuildMember = struct {
    guild_id: Snowflake,
    user_id: Snowflake,
    nick: ?[]u8,
    avatar: ?[]u8,
    roles: []Snowflake,
    joined_at: ?[]u8,
    premium_since: ?[]u8,
    deaf: bool,
    mute: bool,
    pending: bool,
    communication_disabled_until: ?[]u8,
    flags: u64,
    permissions: Permissions.Bit,

    pub fn copy(allocator: std.mem.Allocator, guild_id: Snowflake, member: Types.GuildMember) !OwnedGuildMember {
        const user = member.user orelse return error.MissingField;
        const nick = if (member.nick) |value| try allocator.dupe(u8, value) else null;
        errdefer if (nick) |value| allocator.free(value);
        const avatar = if (member.avatar) |value| try allocator.dupe(u8, value) else null;
        errdefer if (avatar) |value| allocator.free(value);
        const roles = try allocator.dupe(Snowflake, member.roles);
        errdefer allocator.free(roles);
        const joined_at = if (member.joined_at) |value| try allocator.dupe(u8, value) else null;
        errdefer if (joined_at) |value| allocator.free(value);
        const premium_since = if (member.premium_since) |value| try allocator.dupe(u8, value) else null;
        errdefer if (premium_since) |value| allocator.free(value);
        const communication_disabled_until = if (member.communication_disabled_until) |value| try allocator.dupe(u8, value) else null;
        return .{
            .guild_id = guild_id,
            .user_id = user.id,
            .nick = nick,
            .avatar = avatar,
            .roles = roles,
            .joined_at = joined_at,
            .premium_since = premium_since,
            .deaf = member.deaf,
            .mute = member.mute,
            .pending = member.pending,
            .communication_disabled_until = communication_disabled_until,
            .flags = member.flags,
            .permissions = member.permissions,
        };
    }

    pub fn deinit(self: OwnedGuildMember, allocator: std.mem.Allocator) void {
        if (self.nick) |value| allocator.free(value);
        if (self.avatar) |value| allocator.free(value);
        allocator.free(self.roles);
        if (self.joined_at) |value| allocator.free(value);
        if (self.premium_since) |value| allocator.free(value);
        if (self.communication_disabled_until) |value| allocator.free(value);
    }

    pub fn view(self: OwnedGuildMember, user: ?Types.User) Types.GuildMember {
        return .{
            .user = user,
            .nick = self.nick,
            .avatar = self.avatar,
            .roles = self.roles,
            .joined_at = self.joined_at,
            .premium_since = self.premium_since,
            .deaf = self.deaf,
            .mute = self.mute,
            .pending = self.pending,
            .communication_disabled_until = self.communication_disabled_until,
            .flags = self.flags,
            .permissions = self.permissions,
        };
    }
};

pub const OwnedRole = struct {
    id: Snowflake,
    guild_id: Snowflake,
    name: []u8,
    color: u24,
    colors: ?Types.RoleColors,
    hoist: bool,
    icon: ?[]u8,
    unicode_emoji: ?[]u8,
    position: i32,
    permissions: u64,
    managed: bool,
    mentionable: bool,
    tags: ?Types.RoleTags,
    flags: ?u64,

    pub fn copy(allocator: std.mem.Allocator, guild_id: Snowflake, role: Types.Role) !OwnedRole {
        const name = try allocator.dupe(u8, role.name);
        errdefer allocator.free(name);
        const icon = if (role.icon) |value| try allocator.dupe(u8, value) else null;
        errdefer if (icon) |value| allocator.free(value);
        const unicode_emoji = if (role.unicode_emoji) |value| try allocator.dupe(u8, value) else null;
        return .{
            .id = role.id,
            .guild_id = guild_id,
            .name = name,
            .color = role.color,
            .colors = role.colors,
            .hoist = role.hoist,
            .icon = icon,
            .unicode_emoji = unicode_emoji,
            .position = role.position,
            .permissions = role.permissions,
            .managed = role.managed,
            .mentionable = role.mentionable,
            .tags = role.tags,
            .flags = role.flags,
        };
    }

    pub fn deinit(self: OwnedRole, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        if (self.icon) |value| allocator.free(value);
        if (self.unicode_emoji) |value| allocator.free(value);
    }

    pub fn view(self: OwnedRole) Types.Role {
        return .{
            .id = self.id,
            .name = self.name,
            .color = self.color,
            .colors = self.colors,
            .hoist = self.hoist,
            .icon = self.icon,
            .unicode_emoji = self.unicode_emoji,
            .position = self.position,
            .permissions = self.permissions,
            .managed = self.managed,
            .mentionable = self.mentionable,
            .tags = self.tags,
            .flags = self.flags,
        };
    }
};

pub const OwnedEmoji = struct {
    id: Snowflake,
    guild_id: Snowflake,
    name: ?[]u8,
    roles: []Snowflake,
    user_id: ?Snowflake,
    require_colons: bool,
    managed: bool,
    animated: bool,
    available: bool,

    pub fn copy(allocator: std.mem.Allocator, guild_id: Snowflake, emoji: Types.Emoji) !OwnedEmoji {
        const id = emoji.id orelse return error.MissingField;
        const name = if (emoji.name) |value| try allocator.dupe(u8, value) else null;
        errdefer if (name) |value| allocator.free(value);
        const roles = try allocator.dupe(Snowflake, emoji.roles);
        errdefer allocator.free(roles);
        return .{
            .id = id,
            .guild_id = guild_id,
            .name = name,
            .roles = roles,
            .user_id = if (emoji.user) |user| user.id else null,
            .require_colons = emoji.require_colons,
            .managed = emoji.managed,
            .animated = emoji.animated,
            .available = emoji.available,
        };
    }

    pub fn deinit(self: OwnedEmoji, allocator: std.mem.Allocator) void {
        if (self.name) |value| allocator.free(value);
        allocator.free(self.roles);
    }

    pub fn view(self: OwnedEmoji, user: ?Types.User) Types.Emoji {
        return .{
            .id = self.id,
            .name = self.name,
            .roles = self.roles,
            .user = user,
            .require_colons = self.require_colons,
            .managed = self.managed,
            .animated = self.animated,
            .available = self.available,
        };
    }
};

pub const OwnedSticker = struct {
    id: Snowflake,
    pack_id: ?Snowflake,
    name: []u8,
    description: ?[]u8,
    tags: []u8,
    type: Types.StickerType,
    format_type: Types.StickerFormatType,
    available: bool,
    guild_id: Snowflake,
    user_id: ?Snowflake,
    sort_value: ?u32,

    pub fn copy(allocator: std.mem.Allocator, guild_id: Snowflake, sticker: Types.Sticker) !OwnedSticker {
        const name = try allocator.dupe(u8, sticker.name);
        errdefer allocator.free(name);
        const description = if (sticker.description) |value| try allocator.dupe(u8, value) else null;
        errdefer if (description) |value| allocator.free(value);
        const tags = try allocator.dupe(u8, sticker.tags);
        errdefer allocator.free(tags);
        return .{
            .id = sticker.id,
            .pack_id = sticker.pack_id,
            .name = name,
            .description = description,
            .tags = tags,
            .type = sticker.type,
            .format_type = sticker.format_type,
            .available = sticker.available,
            .guild_id = sticker.guild_id orelse guild_id,
            .user_id = if (sticker.user) |user| user.id else null,
            .sort_value = sticker.sort_value,
        };
    }

    pub fn deinit(self: OwnedSticker, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        if (self.description) |value| allocator.free(value);
        allocator.free(self.tags);
    }

    pub fn view(self: OwnedSticker, user: ?Types.User) Types.Sticker {
        return .{
            .id = self.id,
            .pack_id = self.pack_id,
            .name = self.name,
            .description = self.description,
            .tags = self.tags,
            .type = self.type,
            .format_type = self.format_type,
            .available = self.available,
            .guild_id = self.guild_id,
            .user = user,
            .sort_value = self.sort_value,
        };
    }
};

pub const OwnedScheduledEvent = struct {
    id: Snowflake,
    guild_id: Snowflake,
    channel_id: ?Snowflake,
    creator_id: ?Snowflake,
    name: []u8,
    description: ?[]u8,
    scheduled_start_time: []u8,
    scheduled_end_time: ?[]u8,
    privacy_level: Types.GuildScheduledEventPrivacyLevel,
    status: Types.GuildScheduledEventStatus,
    entity_type: Types.GuildScheduledEventEntityType,
    entity_id: ?Snowflake,
    user_count: ?u32,

    pub fn copy(allocator: std.mem.Allocator, event: Types.GuildScheduledEvent) !OwnedScheduledEvent {
        const name = try allocator.dupe(u8, event.name);
        errdefer allocator.free(name);
        const description = if (event.description) |value| try allocator.dupe(u8, value) else null;
        errdefer if (description) |value| allocator.free(value);
        const scheduled_start_time = try allocator.dupe(u8, event.scheduled_start_time);
        errdefer allocator.free(scheduled_start_time);
        const scheduled_end_time = if (event.scheduled_end_time) |value| try allocator.dupe(u8, value) else null;
        return .{
            .id = event.id,
            .guild_id = event.guild_id,
            .channel_id = event.channel_id,
            .creator_id = event.creator_id,
            .name = name,
            .description = description,
            .scheduled_start_time = scheduled_start_time,
            .scheduled_end_time = scheduled_end_time,
            .privacy_level = event.privacy_level,
            .status = event.status,
            .entity_type = event.entity_type,
            .entity_id = event.entity_id,
            .user_count = event.user_count,
        };
    }

    pub fn deinit(self: OwnedScheduledEvent, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        if (self.description) |value| allocator.free(value);
        allocator.free(self.scheduled_start_time);
        if (self.scheduled_end_time) |value| allocator.free(value);
    }

    pub fn view(self: OwnedScheduledEvent) Types.GuildScheduledEvent {
        return .{
            .id = self.id,
            .guild_id = self.guild_id,
            .channel_id = self.channel_id,
            .creator_id = self.creator_id,
            .name = self.name,
            .description = self.description,
            .scheduled_start_time = self.scheduled_start_time,
            .scheduled_end_time = self.scheduled_end_time,
            .privacy_level = self.privacy_level,
            .status = self.status,
            .entity_type = self.entity_type,
            .entity_id = self.entity_id,
            .user_count = self.user_count,
        };
    }
};

pub const OwnedStageInstance = struct {
    id: Snowflake,
    guild_id: Snowflake,
    channel_id: Snowflake,
    topic: []u8,
    privacy_level: Types.StageInstancePrivacyLevel,
    discoverable_disabled: bool,
    guild_scheduled_event_id: ?Snowflake,

    pub fn copy(allocator: std.mem.Allocator, stage_instance: Types.StageInstance) !OwnedStageInstance {
        return .{
            .id = stage_instance.id,
            .guild_id = stage_instance.guild_id,
            .channel_id = stage_instance.channel_id,
            .topic = try allocator.dupe(u8, stage_instance.topic),
            .privacy_level = stage_instance.privacy_level,
            .discoverable_disabled = stage_instance.discoverable_disabled,
            .guild_scheduled_event_id = stage_instance.guild_scheduled_event_id,
        };
    }

    pub fn deinit(self: OwnedStageInstance, allocator: std.mem.Allocator) void {
        allocator.free(self.topic);
    }

    pub fn view(self: OwnedStageInstance) Types.StageInstance {
        return .{
            .id = self.id,
            .guild_id = self.guild_id,
            .channel_id = self.channel_id,
            .topic = self.topic,
            .privacy_level = self.privacy_level,
            .discoverable_disabled = self.discoverable_disabled,
            .guild_scheduled_event_id = self.guild_scheduled_event_id,
        };
    }
};
