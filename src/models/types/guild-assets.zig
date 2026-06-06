const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Json = @import("../../core/json.zig");
const Interactions = @import("../../interactions/mod.zig");
const Permissions = @import("../../core/permissions.zig");

const Root = @import("../types.zig");
const RoleColors = Root.RoleColors;
const writeRoleFields = Root.writeRoleFields;
const writeSnowflakeStringArray = Root.writeSnowflakeStringArray;
const writeOptionalStringField = Root.writeOptionalStringField;
const writeNullableStringField = Root.writeNullableStringField;
const writeNullableSnowflakeField = Root.writeNullableSnowflakeField;
const writeOptionalFloatField = Root.writeOptionalFloatField;
const writeOptionalBoolField = Root.writeOptionalBoolField;
const writeComma = Root.writeComma;

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
