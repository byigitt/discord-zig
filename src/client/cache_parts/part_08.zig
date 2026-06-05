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
const default = Root.default;
const init = Root.init;
const deinit = Root.deinit;
const userFromJson = Root.userFromJson;
const channelFromJson = Root.channelFromJson;
const deinitParsedChannel = Root.deinitParsedChannel;
const attachmentArrayFromJson = Root.attachmentArrayFromJson;
const componentArrayFromJson = Root.componentArrayFromJson;
const deinitParsedComponentArray = Root.deinitParsedComponentArray;
const embedArrayFromJson = Root.embedArrayFromJson;
const deinitParsedEmbeds = Root.deinitParsedEmbeds;
const requireObject = Root.requireObject;
const requireArray = Root.requireArray;
const snowflakeField = Root.snowflakeField;
const snowflakeValue = Root.snowflakeValue;
const nullableSnowflakeValue = Root.nullableSnowflakeValue;
const permissionsValue = Root.permissionsValue;
const stringField = Root.stringField;
const intField = Root.intField;
const intValue = Root.intValue;
const nullableU24Value = Root.nullableU24Value;
const optionalU32Value = Root.optionalU32Value;
const optionalU8Value = Root.optionalU8Value;
const stringValue = Root.stringValue;
const optionalStringValue = Root.optionalStringValue;
const boolValue = Root.boolValue;
const optionalBoolValue = Root.optionalBoolValue;
const nestedIdValue = Root.nestedIdValue;

pub fn roleFromJson(value: std.json.Value) !Types.Role {
    const object = try requireObject(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .name = try stringField(object, "name"),
        .color = if (object.get("color")) |color| @intCast(try intValue(color)) else 0,
        .colors = if (object.get("colors")) |colors| try roleColorsFromJson(colors) else null,
        .hoist = if (object.get("hoist")) |hoist| try boolValue(hoist) else false,
        .icon = if (object.get("icon")) |icon| try optionalStringValue(icon) else null,
        .unicode_emoji = if (object.get("unicode_emoji")) |unicode_emoji| try optionalStringValue(unicode_emoji) else null,
        .position = if (object.get("position")) |position| @intCast(try intValue(position)) else 0,
        .permissions = if (object.get("permissions")) |permissions| try permissionsValue(permissions) else 0,
        .managed = if (object.get("managed")) |managed| try boolValue(managed) else false,
        .mentionable = if (object.get("mentionable")) |mentionable| try boolValue(mentionable) else false,
        .tags = if (object.get("tags")) |tags| try roleTagsFromJson(tags) else null,
        .flags = if (object.get("flags")) |flags| @intCast(try intValue(flags)) else null,
    };
}

pub fn roleColorsFromJson(value: std.json.Value) !Types.RoleColors {
    const object = try requireObject(value);
    return .{
        .primary_color = @intCast(try intField(object, "primary_color")),
        .secondary_color = if (object.get("secondary_color")) |field| try nullableU24Value(field) else null,
        .tertiary_color = if (object.get("tertiary_color")) |field| try nullableU24Value(field) else null,
    };
}

pub fn roleTagsFromJson(value: std.json.Value) !Types.RoleTags {
    const object = try requireObject(value);
    return .{
        .bot_id = if (object.get("bot_id")) |field| try nullableSnowflakeValue(field) else null,
        .integration_id = if (object.get("integration_id")) |field| try nullableSnowflakeValue(field) else null,
        .premium_subscriber = object.get("premium_subscriber") != null,
        .subscription_listing_id = if (object.get("subscription_listing_id")) |field| try nullableSnowflakeValue(field) else null,
        .available_for_purchase = object.get("available_for_purchase") != null,
        .guild_connections = object.get("guild_connections") != null,
    };
}

pub fn emojiFromJson(allocator: std.mem.Allocator, value: std.json.Value) !Types.Emoji {
    const object = try requireObject(value);
    const roles = if (object.get("roles")) |role_values| try roleArrayFromJson(allocator, role_values) else try allocator.dupe(Snowflake, &.{});
    errdefer allocator.free(roles);
    return .{
        .id = if (object.get("id")) |id| try nullableSnowflakeValue(id) else null,
        .name = if (object.get("name")) |name| try optionalStringValue(name) else null,
        .roles = roles,
        .user = if (object.get("user")) |user| try userFromJson(user) else null,
        .require_colons = if (object.get("require_colons")) |field| try boolValue(field) else false,
        .managed = if (object.get("managed")) |field| try boolValue(field) else false,
        .animated = if (object.get("animated")) |field| try boolValue(field) else false,
        .available = if (object.get("available")) |field| try boolValue(field) else true,
    };
}

pub fn stickerFromJson(value: std.json.Value, fallback_guild_id: Snowflake) !Types.Sticker {
    return stickerFromJsonOptionalFallback(value, fallback_guild_id);
}

pub fn stickerFromJsonOptionalFallback(value: std.json.Value, fallback_guild_id: ?Snowflake) !Types.Sticker {
    const object = try requireObject(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .pack_id = if (object.get("pack_id")) |pack_id| try nullableSnowflakeValue(pack_id) else null,
        .name = try stringField(object, "name"),
        .description = if (object.get("description")) |description| try optionalStringValue(description) else null,
        .tags = try stringField(object, "tags"),
        .type = try stickerTypeFromInt(try intField(object, "type")),
        .format_type = try stickerFormatTypeFromInt(try intField(object, "format_type")),
        .available = if (object.get("available")) |available| try boolValue(available) else true,
        .guild_id = if (object.get("guild_id")) |guild_id| try nullableSnowflakeValue(guild_id) else fallback_guild_id,
        .user = if (object.get("user")) |user| try userFromJson(user) else null,
        .sort_value = if (object.get("sort_value")) |sort_value| @intCast(try intValue(sort_value)) else null,
    };
}

pub fn stickerArrayFromJson(
    allocator: std.mem.Allocator,
    value: std.json.Value,
    fallback_guild_id: ?Snowflake,
) ![]Types.Sticker {
    const array = try requireArray(value);
    var stickers = std.array_list.Managed(Types.Sticker).init(allocator);
    errdefer stickers.deinit();
    for (array.items) |item| try stickers.append(try stickerFromJsonOptionalFallback(item, fallback_guild_id));
    return stickers.toOwnedSlice();
}

pub fn stickerTypeFromInt(value: i64) !Types.StickerType {
    return switch (value) {
        1 => .standard,
        2 => .guild,
        else => error.InvalidField,
    };
}

pub fn stickerFormatTypeFromInt(value: i64) !Types.StickerFormatType {
    return switch (value) {
        1 => .png,
        2 => .apng,
        3 => .lottie,
        4 => .gif,
        else => error.InvalidField,
    };
}

pub fn scheduledEventFromJson(value: std.json.Value) !Types.GuildScheduledEvent {
    const object = try requireObject(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .guild_id = try snowflakeField(object, "guild_id"),
        .channel_id = if (object.get("channel_id")) |channel_id| try nullableSnowflakeValue(channel_id) else null,
        .creator_id = if (object.get("creator_id")) |creator_id| try nullableSnowflakeValue(creator_id) else null,
        .name = try stringField(object, "name"),
        .description = if (object.get("description")) |description| try optionalStringValue(description) else null,
        .scheduled_start_time = try stringField(object, "scheduled_start_time"),
        .scheduled_end_time = if (object.get("scheduled_end_time")) |scheduled_end_time| try optionalStringValue(scheduled_end_time) else null,
        .privacy_level = try scheduledEventPrivacyLevelFromInt(try intField(object, "privacy_level")),
        .status = try scheduledEventStatusFromInt(try intField(object, "status")),
        .entity_type = try scheduledEventEntityTypeFromInt(try intField(object, "entity_type")),
        .entity_id = if (object.get("entity_id")) |entity_id| try nullableSnowflakeValue(entity_id) else null,
        .user_count = if (object.get("user_count")) |user_count| @intCast(try intValue(user_count)) else null,
    };
}

pub fn scheduledEventPrivacyLevelFromInt(value: i64) !Types.GuildScheduledEventPrivacyLevel {
    return switch (value) {
        2 => .guild_only,
        else => error.InvalidField,
    };
}

pub fn scheduledEventEntityTypeFromInt(value: i64) !Types.GuildScheduledEventEntityType {
    return switch (value) {
        1 => .stage_instance,
        2 => .voice,
        3 => .external,
        else => error.InvalidField,
    };
}

pub fn scheduledEventStatusFromInt(value: i64) !Types.GuildScheduledEventStatus {
    return switch (value) {
        1 => .scheduled,
        2 => .active,
        3 => .completed,
        4 => .canceled,
        else => error.InvalidField,
    };
}

pub fn stageInstanceFromJson(value: std.json.Value) !Types.StageInstance {
    const object = try requireObject(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .guild_id = try snowflakeField(object, "guild_id"),
        .channel_id = try snowflakeField(object, "channel_id"),
        .topic = try stringField(object, "topic"),
        .privacy_level = if (object.get("privacy_level")) |privacy_level| try stageInstancePrivacyLevelFromInt(try intValue(privacy_level)) else .guild_only,
        .discoverable_disabled = if (object.get("discoverable_disabled")) |disabled| try boolValue(disabled) else false,
        .guild_scheduled_event_id = if (object.get("guild_scheduled_event_id")) |event_id| try nullableSnowflakeValue(event_id) else null,
    };
}

pub fn stageInstancePrivacyLevelFromInt(value: i64) !Types.StageInstancePrivacyLevel {
    return switch (value) {
        1 => .public,
        2 => .guild_only,
        else => error.InvalidField,
    };
}

pub fn inviteFromJson(value: std.json.Value) !Types.Invite {
    const object = try requireObject(value);
    return .{
        .code = try stringField(object, "code"),
        .type = if (object.get("type")) |field| try optionalU8Value(field) else null,
        .guild_id = if (object.get("guild_id")) |guild_id| try nullableSnowflakeValue(guild_id) else null,
        .channel_id = if (object.get("channel_id")) |channel_id| try nullableSnowflakeValue(channel_id) else null,
        .inviter_id = try nestedIdValue(object, "inviter"),
        .target_type = if (object.get("target_type")) |field| try optionalU8Value(field) else null,
        .target_user_id = try nestedIdValue(object, "target_user"),
        .target_application_id = try nestedIdValue(object, "target_application"),
        .approximate_presence_count = if (object.get("approximate_presence_count")) |field| try optionalU32Value(field) else null,
        .approximate_member_count = if (object.get("approximate_member_count")) |field| try optionalU32Value(field) else null,
        .expires_at = if (object.get("expires_at")) |field| try optionalStringValue(field) else null,
        .uses = if (object.get("uses")) |field| try optionalU32Value(field) else null,
        .max_uses = if (object.get("max_uses")) |field| try optionalU32Value(field) else null,
        .max_age = if (object.get("max_age")) |field| try optionalU32Value(field) else null,
        .temporary = if (object.get("temporary")) |field| try optionalBoolValue(field) else null,
        .created_at = if (object.get("created_at")) |field| try optionalStringValue(field) else null,
        .guild_scheduled_event_id = if (object.get("guild_scheduled_event_id")) |field| try nullableSnowflakeValue(field) else null,
    };
}

pub fn presenceFromJson(value: std.json.Value) !Types.Presence {
    const object = try requireObject(value);
    const user = try requireObject(object.get("user") orelse return error.MissingField);
    const activities_count = if (object.get("activities")) |activities| (try requireArray(activities)).items.len else 0;
    return .{
        .guild_id = try snowflakeField(object, "guild_id"),
        .user_id = try snowflakeField(user, "id"),
        .status = try stringField(object, "status"),
        .activities_count = activities_count,
    };
}

pub fn voiceStateFromJson(value: std.json.Value) !Types.VoiceState {
    const object = try requireObject(value);
    return .{
        .guild_id = try snowflakeField(object, "guild_id"),
        .channel_id = if (object.get("channel_id")) |channel_id| try nullableSnowflakeValue(channel_id) else null,
        .user_id = try snowflakeField(object, "user_id"),
        .session_id = try stringField(object, "session_id"),
        .deaf = if (object.get("deaf")) |deaf| try boolValue(deaf) else false,
        .mute = if (object.get("mute")) |mute| try boolValue(mute) else false,
        .self_deaf = if (object.get("self_deaf")) |self_deaf| try boolValue(self_deaf) else false,
        .self_mute = if (object.get("self_mute")) |self_mute| try boolValue(self_mute) else false,
        .self_stream = if (object.get("self_stream")) |self_stream| try boolValue(self_stream) else null,
        .self_video = if (object.get("self_video")) |self_video| try boolValue(self_video) else false,
        .suppress = if (object.get("suppress")) |suppress| try boolValue(suppress) else false,
        .request_to_speak_timestamp = if (object.get("request_to_speak_timestamp")) |timestamp| try optionalStringValue(timestamp) else null,
    };
}

pub fn messageReferenceFromJson(value: std.json.Value) !Types.MessageReferenceInfo {
    const object = try requireObject(value);
    return .{
        .type = if (object.get("type")) |field| try messageReferenceTypeFromInt(try intValue(field)) else null,
        .message_id = if (object.get("message_id")) |field| try nullableSnowflakeValue(field) else null,
        .channel_id = if (object.get("channel_id")) |field| try nullableSnowflakeValue(field) else null,
        .guild_id = if (object.get("guild_id")) |field| try nullableSnowflakeValue(field) else null,
    };
}

pub fn messageReferenceTypeFromInt(value: i64) !Types.MessageReferenceType {
    return switch (value) {
        0 => .default,
        1 => .forward,
        else => error.InvalidField,
    };
}

pub fn referencedMessageIdFromJson(value: std.json.Value) !?Snowflake {
    if (value == .null) return null;
    const object = try requireObject(value);
    return try snowflakeField(object, "id");
}

pub fn messageSnapshotArrayFromJson(
    allocator: std.mem.Allocator,
    value: std.json.Value,
) ![]Types.MessageSnapshot {
    const array = try requireArray(value);
    const snapshots = try allocator.alloc(Types.MessageSnapshot, array.items.len);
    var initialized: usize = 0;
    errdefer deinitParsedMessageSnapshots(snapshots[0..initialized], allocator);

    for (array.items, 0..) |item, index| {
        snapshots[index] = try messageSnapshotFromJson(allocator, item);
        initialized += 1;
    }
    return snapshots;
}

pub fn messageSnapshotFromJson(
    allocator: std.mem.Allocator,
    value: std.json.Value,
) !Types.MessageSnapshot {
    const object = try requireObject(value);
    const message = try requireObject(object.get("message") orelse return error.MissingField);
    const mentions = if (message.get("mentions")) |field| try userArrayFromJson(allocator, field) else try allocator.dupe(Types.User, &.{});
    errdefer allocator.free(mentions);
    const mention_roles = if (message.get("mention_roles")) |field| try roleArrayFromJson(allocator, field) else try allocator.dupe(Snowflake, &.{});
    errdefer allocator.free(mention_roles);
    const embeds = if (message.get("embeds")) |field| try embedArrayFromJson(allocator, field) else try allocator.dupe(Types.Embed, &.{});
    errdefer deinitParsedEmbeds(embeds, allocator);
    const attachments = if (message.get("attachments")) |field| try attachmentArrayFromJson(allocator, field) else try allocator.dupe(Types.Attachment, &.{});
    errdefer allocator.free(attachments);
    const components = if (message.get("components")) |field| try componentArrayFromJson(allocator, field) else try allocator.dupe(Interactions.Component, &.{});
    errdefer deinitParsedComponentArray(components, allocator);

    return .{
        .type = if (message.get("type")) |field| @intCast(try intValue(field)) else 0,
        .content = if (message.get("content")) |field| try stringValue(field) else "",
        .timestamp = if (message.get("timestamp")) |field| try stringValue(field) else null,
        .edited_timestamp = if (message.get("edited_timestamp")) |field| try optionalStringValue(field) else null,
        .flags = if (message.get("flags")) |field| @intCast(try intValue(field)) else null,
        .mentions = mentions,
        .mention_roles = mention_roles,
        .embeds = embeds,
        .attachments = attachments,
        .components = components,
    };
}

pub fn deinitParsedMessageSnapshots(
    snapshots: []Types.MessageSnapshot,
    allocator: std.mem.Allocator,
) void {
    for (snapshots) |snapshot| {
        allocator.free(snapshot.mentions);
        allocator.free(snapshot.mention_roles);
        deinitParsedEmbeds(@constCast(snapshot.embeds), allocator);
        allocator.free(snapshot.attachments);
        deinitParsedComponentArray(@constCast(snapshot.components), allocator);
    }
    allocator.free(snapshots);
}

pub fn memberFromJson(allocator: std.mem.Allocator, value: std.json.Value) !Types.GuildMember {
    const object = try requireObject(value);
    const roles = if (object.get("roles")) |role_values| try roleArrayFromJson(allocator, role_values) else try allocator.dupe(Snowflake, &.{});
    errdefer allocator.free(roles);
    return .{
        .user = if (object.get("user")) |user| try userFromJson(user) else null,
        .nick = if (object.get("nick")) |nick| try optionalStringValue(nick) else null,
        .avatar = if (object.get("avatar")) |avatar| try optionalStringValue(avatar) else null,
        .roles = roles,
        .joined_at = if (object.get("joined_at")) |joined_at| try optionalStringValue(joined_at) else null,
        .premium_since = if (object.get("premium_since")) |premium_since| try optionalStringValue(premium_since) else null,
        .deaf = if (object.get("deaf")) |deaf| try boolValue(deaf) else false,
        .mute = if (object.get("mute")) |mute| try boolValue(mute) else false,
        .pending = if (object.get("pending")) |pending| try boolValue(pending) else false,
        .communication_disabled_until = if (object.get("communication_disabled_until")) |timeout| try optionalStringValue(timeout) else null,
        .flags = if (object.get("flags")) |flags| @intCast(try intValue(flags)) else 0,
        .permissions = if (object.get("permissions")) |permissions| try permissionsValue(permissions) else 0,
    };
}

pub fn roleArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) ![]const Snowflake {
    const array = try requireArray(value);
    var roles = std.array_list.Managed(Snowflake).init(allocator);
    errdefer roles.deinit();
    for (array.items) |item| try roles.append(try snowflakeValue(item));
    return roles.toOwnedSlice();
}

pub fn userArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) ![]Types.User {
    const array = try requireArray(value);
    var users = std.array_list.Managed(Types.User).init(allocator);
    errdefer users.deinit();
    for (array.items) |item| try users.append(try userFromJson(item));
    return users.toOwnedSlice();
}

pub fn channelArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value, fallback_guild_id: ?Snowflake) ![]Types.Channel {
    const array = try requireArray(value);
    var channels = std.array_list.Managed(Types.Channel).init(allocator);
    errdefer {
        for (channels.items) |channel| deinitParsedChannel(channel, allocator);
        channels.deinit();
    }
    for (array.items) |item| try channels.append(try channelFromJson(allocator, item, fallback_guild_id));
    return channels.toOwnedSlice();
}

pub fn stringArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) ![]const []const u8 {
    const array = try requireArray(value);
    var strings = std.array_list.Managed([]const u8).init(allocator);
    errdefer strings.deinit();
    for (array.items) |item| try strings.append(try stringValue(item));
    return strings.toOwnedSlice();
}

pub fn copyStringArray(allocator: std.mem.Allocator, values: []const []const u8) ![][]u8 {
    const owned = try allocator.alloc([]u8, values.len);
    var initialized: usize = 0;
    errdefer deinitStringArray(owned[0..initialized], allocator);

    for (values, 0..) |value, index| {
        owned[index] = try allocator.dupe(u8, value);
        initialized += 1;
    }
    return owned;
}

pub fn deinitStringArray(values: [][]u8, allocator: std.mem.Allocator) void {
    for (values) |value| allocator.free(value);
    allocator.free(values);
}

pub fn deinitConstStringArray(values: []const []const u8, allocator: std.mem.Allocator) void {
    for (values) |value| allocator.free(value);
    allocator.free(values);
}
