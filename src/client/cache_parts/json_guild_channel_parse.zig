const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Types = @import("../../models/types.zig");
const Gateway = @import("../../gateway/protocol.zig");
const Interactions = @import("../../interactions/mod.zig");
const Permissions = @import("../../core/permissions.zig");
const Collection = @import("../../core/collection.zig").Collection;

const Root = @import("../cache.zig");
const deinit = Root.deinit;
const copyUser = Root.copyUser;
const deinitUser = Root.deinitUser;
const roleArrayFromJson = Root.roleArrayFromJson;
const stringArrayFromJson = Root.stringArrayFromJson;
const requireObject = Root.requireObject;
const requireArray = Root.requireArray;
const snowflakeField = Root.snowflakeField;
const snowflakeValue = Root.snowflakeValue;
const nullableSnowflakeValue = Root.nullableSnowflakeValue;
const permissionsValue = Root.permissionsValue;
const stringField = Root.stringField;
const intField = Root.intField;
const intValue = Root.intValue;
const nullableIntValue = Root.nullableIntValue;
const optionalU32Value = Root.optionalU32Value;
const stringValue = Root.stringValue;
const optionalStringValue = Root.optionalStringValue;
const boolValue = Root.boolValue;

pub fn reactionEmojiEql(a: Types.ReactionEmoji, b: Types.ReactionEmoji) bool {
    if (a.id != null or b.id != null) {
        return a.id != null and b.id != null and a.id.?.value == b.id.?.value;
    }
    if (a.name == null or b.name == null) return a.name == null and b.name == null;
    return std.mem.eql(u8, a.name.?, b.name.?);
}

pub fn memberKey(guild_id: Snowflake, user_id: Snowflake) u128 {
    return (@as(u128, guild_id.value) << 64) | @as(u128, user_id.value);
}

pub fn roleKey(guild_id: Snowflake, role_id: Snowflake) u128 {
    return (@as(u128, guild_id.value) << 64) | @as(u128, role_id.value);
}

pub fn replaceOwned(comptime T: type, map: anytype, allocator: std.mem.Allocator, key: anytype, value: T) !void {
    if (map.fetchRemove(key)) |old| old.value.deinit(allocator);
    try map.put(key, value);
}

pub fn clearOwnedMap(map: anytype, allocator: std.mem.Allocator) void {
    var values = map.valueIterator();
    while (values.next()) |value| value.deinit(allocator);
    map.deinit();
}

pub fn clearOwnedMapRetainingCapacity(map: anytype, allocator: std.mem.Allocator) void {
    var values = map.valueIterator();
    while (values.next()) |value| value.deinit(allocator);
    map.clearRetainingCapacity();
}

pub fn userFromJson(value: std.json.Value) !Types.User {
    const object = try requireObject(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .username = try stringField(object, "username"),
        .discriminator = if (object.get("discriminator")) |field| try stringValue(field) else null,
        .global_name = if (object.get("global_name")) |field| optionalStringValue(field) catch null else null,
        .avatar = if (object.get("avatar")) |field| optionalStringValue(field) catch null else null,
        .banner = if (object.get("banner")) |field| optionalStringValue(field) catch null else null,
        .bot = if (object.get("bot")) |field| boolValue(field) catch false else false,
        .system = if (object.get("system")) |field| boolValue(field) catch false else false,
        .mfa_enabled = if (object.get("mfa_enabled")) |field| try boolValue(field) else null,
        .accent_color = if (object.get("accent_color")) |field| try optionalU32Value(field) else null,
        .locale = if (object.get("locale")) |field| optionalStringValue(field) catch null else null,
        .verified = if (object.get("verified")) |field| try boolValue(field) else null,
        .email = if (object.get("email")) |field| optionalStringValue(field) catch null else null,
        .flags = if (object.get("flags")) |field| @intCast(try intValue(field)) else null,
        .public_flags = if (object.get("public_flags")) |field| @intCast(try intValue(field)) else null,
    };
}

pub fn applicationFromJson(allocator: std.mem.Allocator, value: std.json.Value) !Types.Application {
    const object = try requireObject(value);
    const event_webhooks_types = if (object.get("event_webhooks_types")) |field|
        try stringArrayFromJson(allocator, field)
    else
        try allocator.dupe([]const u8, &.{});
    errdefer allocator.free(event_webhooks_types);
    const tags = if (object.get("tags")) |field|
        try stringArrayFromJson(allocator, field)
    else
        try allocator.dupe([]const u8, &.{});
    errdefer allocator.free(tags);
    const team = if (object.get("team")) |field| try teamFromJson(allocator, field) else null;
    errdefer if (team) |parsed_team| deinitParsedTeam(parsed_team, allocator);

    return .{
        .id = try snowflakeField(object, "id"),
        .name = if (object.get("name")) |field| try stringValue(field) else "",
        .icon = if (object.get("icon")) |field| try optionalStringValue(field) else null,
        .description = if (object.get("description")) |field| try stringValue(field) else "",
        .bot_public = if (object.get("bot_public")) |field| try boolValue(field) else true,
        .bot_require_code_grant = if (object.get("bot_require_code_grant")) |field| try boolValue(field) else false,
        .bot = if (object.get("bot")) |field| try userFromJson(field) else null,
        .owner = if (object.get("owner")) |field| try userFromJson(field) else null,
        .team = team,
        .verify_key = if (object.get("verify_key")) |field| try stringValue(field) else "",
        .guild_id = if (object.get("guild_id")) |field| try nullableSnowflakeValue(field) else null,
        .flags = if (object.get("flags")) |field| @intCast(try intValue(field)) else null,
        .approximate_guild_count = if (object.get("approximate_guild_count")) |field| @intCast(try intValue(field)) else null,
        .approximate_user_install_count = if (object.get("approximate_user_install_count")) |field| @intCast(try intValue(field)) else null,
        .interactions_endpoint_url = if (object.get("interactions_endpoint_url")) |field| try optionalStringValue(field) else null,
        .role_connections_verification_url = if (object.get("role_connections_verification_url")) |field| try optionalStringValue(field) else null,
        .event_webhooks_url = if (object.get("event_webhooks_url")) |field| try optionalStringValue(field) else null,
        .event_webhooks_status = if (object.get("event_webhooks_status")) |field| try applicationEventWebhookStatusFromInt(try intValue(field)) else null,
        .event_webhooks_types = event_webhooks_types,
        .tags = tags,
        .custom_install_url = if (object.get("custom_install_url")) |field| try optionalStringValue(field) else null,
    };
}

pub fn deinitParsedApplication(application: ?Types.Application, allocator: std.mem.Allocator) void {
    if (application) |value| {
        allocator.free(value.event_webhooks_types);
        allocator.free(value.tags);
        if (value.team) |team| deinitParsedTeam(team, allocator);
    }
}

pub fn teamFromJson(allocator: std.mem.Allocator, value: std.json.Value) !?Types.Team {
    const object = switch (value) {
        .object => |inner| inner,
        .null => return null,
        else => return error.InvalidField,
    };
    const members = try teamMembersFromJson(allocator, object.get("members"));
    errdefer allocator.free(members);
    return .{
        .id = try snowflakeField(object, "id"),
        .name = if (object.get("name")) |field| try stringValue(field) else "",
        .icon = if (object.get("icon")) |field| try optionalStringValue(field) else null,
        .owner_user_id = try snowflakeField(object, "owner_user_id"),
        .members = members,
    };
}

pub fn teamMembersFromJson(allocator: std.mem.Allocator, maybe: ?std.json.Value) ![]Types.TeamMember {
    const field = maybe orelse return allocator.alloc(Types.TeamMember, 0);
    const array = switch (field) {
        .array => |items| items,
        else => return error.InvalidField,
    };
    const members = try allocator.alloc(Types.TeamMember, array.items.len);
    errdefer allocator.free(members);
    for (array.items, 0..) |item, index| {
        members[index] = try teamMemberFromJson(item);
    }
    return members;
}

pub fn teamMemberFromJson(value: std.json.Value) !Types.TeamMember {
    const object = try requireObject(value);
    const state = try membershipStateFromInt(try intValue(object.get("membership_state") orelse return error.MissingField));
    return .{
        .membership_state = state,
        .team_id = try snowflakeField(object, "team_id"),
        .user = try userFromJson(object.get("user") orelse return error.MissingField),
        .role = if (object.get("role")) |field| try optionalStringValue(field) else null,
    };
}

pub fn membershipStateFromInt(value: i64) !Types.MembershipState {
    return switch (value) {
        1 => .invited,
        2 => .accepted,
        else => error.InvalidField,
    };
}

pub fn deinitParsedTeam(team: Types.Team, allocator: std.mem.Allocator) void {
    allocator.free(team.members);
}

pub fn copyTeam(allocator: std.mem.Allocator, team: Types.Team) !Types.Team {
    const name = try allocator.dupe(u8, team.name);
    errdefer allocator.free(name);
    const icon = if (team.icon) |value| try allocator.dupe(u8, value) else null;
    errdefer if (icon) |value| allocator.free(value);
    const members = try allocator.alloc(Types.TeamMember, team.members.len);
    var initialized: usize = 0;
    errdefer {
        for (members[0..initialized]) |member| deinitTeamMember(member, allocator);
        allocator.free(members);
    }
    for (team.members, 0..) |member, index| {
        members[index] = try copyTeamMember(allocator, member);
        initialized += 1;
    }
    return .{
        .id = team.id,
        .name = name,
        .icon = icon,
        .owner_user_id = team.owner_user_id,
        .members = members,
    };
}

pub fn copyTeamMember(allocator: std.mem.Allocator, member: Types.TeamMember) !Types.TeamMember {
    const user = try copyUser(allocator, member.user);
    errdefer deinitUser(user, allocator);
    const role = if (member.role) |value| try allocator.dupe(u8, value) else null;
    return .{
        .membership_state = member.membership_state,
        .team_id = member.team_id,
        .user = user,
        .role = role,
    };
}

pub fn deinitTeam(team: Types.Team, allocator: std.mem.Allocator) void {
    allocator.free(team.name);
    if (team.icon) |value| allocator.free(value);
    for (team.members) |member| deinitTeamMember(member, allocator);
    allocator.free(team.members);
}

pub fn deinitTeamMember(member: Types.TeamMember, allocator: std.mem.Allocator) void {
    deinitUser(member.user, allocator);
    if (member.role) |value| allocator.free(value);
}

pub fn applicationEventWebhookStatusFromInt(value: i64) !Types.ApplicationEventWebhookStatus {
    return switch (value) {
        1 => .disabled,
        2 => .enabled,
        3 => .disabled_by_discord,
        else => error.InvalidField,
    };
}

pub fn channelFromJson(
    allocator: std.mem.Allocator,
    value: std.json.Value,
    fallback_guild_id: ?Snowflake,
) !Types.Channel {
    const object = try requireObject(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .type = try channelTypeFromInt(try intField(object, "type")),
        .guild_id = if (object.get("guild_id")) |guild_id| try snowflakeValue(guild_id) else fallback_guild_id,
        .name = if (object.get("name")) |name| try stringValue(name) else null,
        .topic = if (object.get("topic")) |topic| try optionalStringValue(topic) else null,
        .status = if (object.get("status")) |status| try optionalStringValue(status) else null,
        .voice_start_time = if (object.get("voice_start_time")) |field| try nullableIntValue(field) else null,
        .last_message_id = if (object.get("last_message_id")) |field| try nullableSnowflakeValue(field) else null,
        .last_pin_timestamp = if (object.get("last_pin_timestamp")) |field| try optionalStringValue(field) else null,
        .parent_id = if (object.get("parent_id")) |parent_id| try nullableSnowflakeValue(parent_id) else null,
        .owner_id = if (object.get("owner_id")) |field| try nullableSnowflakeValue(field) else null,
        .application_id = if (object.get("application_id")) |field| try nullableSnowflakeValue(field) else null,
        .position = if (object.get("position")) |position| @intCast(try intValue(position)) else null,
        .nsfw = if (object.get("nsfw")) |nsfw| try boolValue(nsfw) else false,
        .rate_limit_per_user = if (object.get("rate_limit_per_user")) |rate_limit| @intCast(try intValue(rate_limit)) else null,
        .bitrate = if (object.get("bitrate")) |bitrate| @intCast(try intValue(bitrate)) else null,
        .user_limit = if (object.get("user_limit")) |user_limit| @intCast(try intValue(user_limit)) else null,
        .rtc_region = if (object.get("rtc_region")) |field| try optionalStringValue(field) else null,
        .video_quality_mode = if (object.get("video_quality_mode")) |field| @intCast(try intValue(field)) else null,
        .message_count = if (object.get("message_count")) |field| @intCast(try intValue(field)) else null,
        .member_count = if (object.get("member_count")) |field| @intCast(try intValue(field)) else null,
        .managed = if (object.get("managed")) |field| try boolValue(field) else false,
        .flags = if (object.get("flags")) |flags| @intCast(try intValue(flags)) else null,
        .permission_overwrites = if (object.get("permission_overwrites")) |field| try permissionOverwriteArrayFromJson(allocator, field) else try allocator.dupe(Types.PermissionOverwrite, &.{}),
        .thread_metadata = if (object.get("thread_metadata")) |thread_metadata| try threadMetadataFromJson(thread_metadata) else null,
        .applied_tags = if (object.get("applied_tags")) |applied_tags| try roleArrayFromJson(allocator, applied_tags) else try allocator.dupe(Snowflake, &.{}),
        .available_tags = if (object.get("available_tags")) |available_tags| try forumTagArrayFromJson(allocator, available_tags) else try allocator.dupe(Types.ForumTag, &.{}),
        .default_reaction_emoji = if (object.get("default_reaction_emoji")) |field| try nullableDefaultReactionEmojiFromJson(field) else null,
        .default_thread_rate_limit_per_user = if (object.get("default_thread_rate_limit_per_user")) |field| @intCast(try intValue(field)) else null,
        .default_sort_order = if (object.get("default_sort_order")) |field| try nullableChannelSortOrderFromJson(field) else null,
        .default_forum_layout = if (object.get("default_forum_layout")) |field| try nullableForumLayoutFromJson(field) else null,
    };
}

pub fn deinitParsedChannel(channel: Types.Channel, allocator: std.mem.Allocator) void {
    allocator.free(@constCast(channel.permission_overwrites));
    allocator.free(channel.applied_tags);
    deinitParsedForumTags(channel.available_tags, allocator);
}

pub fn deinitParsedChannels(channels: []Types.Channel, allocator: std.mem.Allocator) void {
    for (channels) |channel| deinitParsedChannel(channel, allocator);
    allocator.free(channels);
}

pub fn threadMetadataFromJson(value: std.json.Value) !Types.ThreadMetadata {
    const object = try requireObject(value);
    return .{
        .archived = if (object.get("archived")) |field| try boolValue(field) else false,
        .auto_archive_duration = if (object.get("auto_archive_duration")) |field| @intCast(try intValue(field)) else 0,
        .archive_timestamp = if (object.get("archive_timestamp")) |field| try optionalStringValue(field) else null,
        .locked = if (object.get("locked")) |field| try boolValue(field) else false,
        .invitable = if (object.get("invitable")) |field| try boolValue(field) else null,
        .create_timestamp = if (object.get("create_timestamp")) |field| try optionalStringValue(field) else null,
    };
}

pub fn permissionOverwriteArrayFromJson(
    allocator: std.mem.Allocator,
    value: std.json.Value,
) ![]Types.PermissionOverwrite {
    const array = try requireArray(value);
    const overwrites = try allocator.alloc(Types.PermissionOverwrite, array.items.len);
    errdefer allocator.free(overwrites);

    for (array.items, 0..) |item, index| overwrites[index] = try permissionOverwriteFromJson(item);
    return overwrites;
}

pub fn permissionOverwriteFromJson(value: std.json.Value) !Types.PermissionOverwrite {
    const object = try requireObject(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .type = try permissionOverwriteTypeFromInt(try intField(object, "type")),
        .allow = if (object.get("allow")) |field| try permissionsValue(field) else 0,
        .deny = if (object.get("deny")) |field| try permissionsValue(field) else 0,
    };
}

pub fn forumTagArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) ![]Types.ForumTag {
    const array = try requireArray(value);
    const tags = try allocator.alloc(Types.ForumTag, array.items.len);
    var initialized: usize = 0;
    errdefer deinitParsedForumTags(tags[0..initialized], allocator);

    for (array.items, 0..) |item, index| {
        tags[index] = try forumTagFromJson(item);
        initialized += 1;
    }
    return tags;
}

pub fn forumTagFromJson(value: std.json.Value) !Types.ForumTag {
    const object = try requireObject(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .name = try stringField(object, "name"),
        .moderated = if (object.get("moderated")) |field| try boolValue(field) else false,
        .emoji_id = if (object.get("emoji_id")) |field| try nullableSnowflakeValue(field) else null,
        .emoji_name = if (object.get("emoji_name")) |field| try optionalStringValue(field) else null,
    };
}

pub fn nullableDefaultReactionEmojiFromJson(value: std.json.Value) !?Types.DefaultReactionEmoji {
    if (value == .null) return null;
    const object = try requireObject(value);
    return .{
        .emoji_id = if (object.get("emoji_id")) |field| try nullableSnowflakeValue(field) else null,
        .emoji_name = if (object.get("emoji_name")) |field| try optionalStringValue(field) else null,
    };
}

pub fn nullableChannelSortOrderFromJson(value: std.json.Value) !?Types.ChannelSortOrder {
    if (value == .null) return null;
    return switch (try intValue(value)) {
        0 => .latest_activity,
        1 => .creation_date,
        else => error.InvalidField,
    };
}

pub fn nullableForumLayoutFromJson(value: std.json.Value) !?Types.ForumLayout {
    if (value == .null) return null;
    return switch (try intValue(value)) {
        0 => .unset,
        1 => .list_view,
        2 => .gallery_view,
        else => error.InvalidField,
    };
}

pub fn permissionOverwriteTypeFromInt(value: i64) !Types.PermissionOverwriteType {
    return switch (value) {
        0 => .role,
        1 => .member,
        else => error.InvalidField,
    };
}

pub fn deinitParsedForumTags(tags: []const Types.ForumTag, allocator: std.mem.Allocator) void {
    allocator.free(@constCast(tags));
}

pub fn channelTypeFromInt(value: i64) !Types.ChannelType {
    return switch (value) {
        0 => .guild_text,
        1 => .dm,
        2 => .guild_voice,
        3 => .group_dm,
        4 => .guild_category,
        5 => .guild_announcement,
        10 => .announcement_thread,
        11 => .public_thread,
        12 => .private_thread,
        13 => .guild_stage_voice,
        14 => .guild_directory,
        15 => .guild_forum,
        16 => .guild_media,
        else => error.InvalidField,
    };
}

pub fn channelTypeIsThread(channel_type: Types.ChannelType) bool {
    return switch (channel_type) {
        .announcement_thread, .public_thread, .private_thread => true,
        else => false,
    };
}
