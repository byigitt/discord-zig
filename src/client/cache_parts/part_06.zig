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
pub const OwnedMessage = Root.OwnedMessage;
const reactionEmojiEql = Root.reactionEmojiEql;
const copyStringArray = Root.copyStringArray;
const deinitConstStringArray = Root.deinitConstStringArray;

pub fn copyChannels(allocator: std.mem.Allocator, channels: []const Types.Channel) ![]Types.Channel {
    const owned = try allocator.alloc(Types.Channel, channels.len);
    var initialized: usize = 0;
    errdefer deinitChannels(owned[0..initialized], allocator);

    for (channels, 0..) |channel, index| {
        owned[index] = try copyChannel(allocator, channel);
        initialized += 1;
    }
    return owned;
}

pub fn copyChannel(allocator: std.mem.Allocator, channel: Types.Channel) !Types.Channel {
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

pub fn copyDefaultReactionEmoji(
    allocator: std.mem.Allocator,
    emoji: Types.DefaultReactionEmoji,
) !Types.DefaultReactionEmoji {
    return .{
        .emoji_id = emoji.emoji_id,
        .emoji_name = if (emoji.emoji_name) |value| try allocator.dupe(u8, value) else null,
    };
}

pub fn copyForumTags(allocator: std.mem.Allocator, tags: []const Types.ForumTag) ![]Types.ForumTag {
    const owned = try allocator.alloc(Types.ForumTag, tags.len);
    var initialized: usize = 0;
    errdefer deinitForumTags(owned[0..initialized], allocator);

    for (tags, 0..) |tag, index| {
        owned[index] = try copyForumTag(allocator, tag);
        initialized += 1;
    }
    return owned;
}

pub fn copyForumTag(allocator: std.mem.Allocator, tag: Types.ForumTag) !Types.ForumTag {
    const name = try allocator.dupe(u8, tag.name);
    errdefer allocator.free(name);
    const emoji_name = if (tag.emoji_name) |value| try allocator.dupe(u8, value) else null;
    return .{
        .id = tag.id,
        .name = name,
        .moderated = tag.moderated,
        .emoji_id = tag.emoji_id,
        .emoji_name = emoji_name,
    };
}

pub fn copyThreadMetadata(
    allocator: std.mem.Allocator,
    metadata: Types.ThreadMetadata,
) !Types.ThreadMetadata {
    const archive_timestamp = if (metadata.archive_timestamp) |value| try allocator.dupe(u8, value) else null;
    errdefer if (archive_timestamp) |value| allocator.free(value);
    const create_timestamp = if (metadata.create_timestamp) |value| try allocator.dupe(u8, value) else null;
    return .{
        .archived = metadata.archived,
        .auto_archive_duration = metadata.auto_archive_duration,
        .archive_timestamp = archive_timestamp,
        .locked = metadata.locked,
        .invitable = metadata.invitable,
        .create_timestamp = create_timestamp,
    };
}

pub fn deinitChannels(channels: []Types.Channel, allocator: std.mem.Allocator) void {
    for (channels) |channel| deinitChannel(channel, allocator);
    allocator.free(channels);
}

pub fn deinitChannel(channel: Types.Channel, allocator: std.mem.Allocator) void {
    if (channel.name) |value| allocator.free(value);
    if (channel.topic) |value| allocator.free(value);
    if (channel.status) |value| allocator.free(value);
    if (channel.last_pin_timestamp) |value| allocator.free(@constCast(value));
    if (channel.rtc_region) |value| allocator.free(@constCast(value));
    allocator.free(@constCast(channel.permission_overwrites));
    if (channel.thread_metadata) |value| deinitThreadMetadata(value, allocator);
    allocator.free(channel.applied_tags);
    deinitForumTags(channel.available_tags, allocator);
    if (channel.default_reaction_emoji) |value| deinitDefaultReactionEmoji(value, allocator);
}

pub fn deinitDefaultReactionEmoji(emoji: Types.DefaultReactionEmoji, allocator: std.mem.Allocator) void {
    if (emoji.emoji_name) |value| allocator.free(value);
}

pub fn deinitForumTags(tags: []const Types.ForumTag, allocator: std.mem.Allocator) void {
    for (tags) |tag| {
        allocator.free(tag.name);
        if (tag.emoji_name) |value| allocator.free(value);
    }
    allocator.free(@constCast(tags));
}

pub fn deinitThreadMetadata(metadata: Types.ThreadMetadata, allocator: std.mem.Allocator) void {
    if (metadata.archive_timestamp) |value| allocator.free(value);
    if (metadata.create_timestamp) |value| allocator.free(value);
}

pub fn copyEmbeds(allocator: std.mem.Allocator, embeds: []const Types.Embed) ![]Types.Embed {
    const owned = try allocator.alloc(Types.Embed, embeds.len);
    var initialized: usize = 0;
    errdefer deinitEmbeds(owned[0..initialized], allocator);

    for (embeds, 0..) |embed, index| {
        owned[index] = try copyEmbed(allocator, embed);
        initialized += 1;
    }
    return owned;
}

pub fn copyEmbed(allocator: std.mem.Allocator, embed: Types.Embed) !Types.Embed {
    const title = if (embed.title) |value| try allocator.dupe(u8, value) else null;
    errdefer if (title) |value| allocator.free(value);
    const description = if (embed.description) |value| try allocator.dupe(u8, value) else null;
    errdefer if (description) |value| allocator.free(value);
    const url = if (embed.url) |value| try allocator.dupe(u8, value) else null;
    errdefer if (url) |value| allocator.free(value);
    const timestamp = if (embed.timestamp) |value| try allocator.dupe(u8, value) else null;
    errdefer if (timestamp) |value| allocator.free(value);
    const footer = if (embed.footer) |value| try copyEmbedFooter(allocator, value) else null;
    errdefer if (footer) |value| deinitEmbedFooter(value, allocator);
    const image = if (embed.image) |value| try copyEmbedMedia(allocator, value) else null;
    errdefer if (image) |value| deinitEmbedMedia(value, allocator);
    const thumbnail = if (embed.thumbnail) |value| try copyEmbedMedia(allocator, value) else null;
    errdefer if (thumbnail) |value| deinitEmbedMedia(value, allocator);
    const author = if (embed.author) |value| try copyEmbedAuthor(allocator, value) else null;
    errdefer if (author) |value| deinitEmbedAuthor(value, allocator);
    const fields = try copyEmbedFields(allocator, embed.fields);

    return .{
        .title = title,
        .description = description,
        .url = url,
        .timestamp = timestamp,
        .color = embed.color,
        .footer = footer,
        .image = image,
        .thumbnail = thumbnail,
        .author = author,
        .fields = fields,
    };
}

pub fn copyEmbedFooter(allocator: std.mem.Allocator, footer: Types.EmbedFooter) !Types.EmbedFooter {
    const text = try allocator.dupe(u8, footer.text);
    errdefer allocator.free(text);
    const icon_url = if (footer.icon_url) |value| try allocator.dupe(u8, value) else null;
    return .{ .text = text, .icon_url = icon_url };
}

pub fn copyEmbedMedia(allocator: std.mem.Allocator, media: Types.EmbedMedia) !Types.EmbedMedia {
    return .{ .url = try allocator.dupe(u8, media.url) };
}

pub fn copyEmbedAuthor(allocator: std.mem.Allocator, author: Types.EmbedAuthor) !Types.EmbedAuthor {
    const name = try allocator.dupe(u8, author.name);
    errdefer allocator.free(name);
    const url = if (author.url) |value| try allocator.dupe(u8, value) else null;
    errdefer if (url) |value| allocator.free(value);
    const icon_url = if (author.icon_url) |value| try allocator.dupe(u8, value) else null;
    return .{ .name = name, .url = url, .icon_url = icon_url };
}

pub fn copyEmbedFields(allocator: std.mem.Allocator, fields: []const Types.EmbedField) ![]Types.EmbedField {
    const owned = try allocator.alloc(Types.EmbedField, fields.len);
    var initialized: usize = 0;
    errdefer {
        for (owned[0..initialized]) |field| deinitEmbedField(field, allocator);
        allocator.free(owned);
    }

    for (fields, 0..) |field, index| {
        const name = try allocator.dupe(u8, field.name);
        errdefer allocator.free(name);
        const value = try allocator.dupe(u8, field.value);
        owned[index] = .{
            .name = name,
            .value = value,
            .is_inline = field.is_inline,
        };
        initialized += 1;
    }
    return owned;
}

pub fn deinitEmbeds(embeds: []Types.Embed, allocator: std.mem.Allocator) void {
    for (embeds) |embed| deinitEmbed(embed, allocator);
    allocator.free(embeds);
}

pub fn deinitEmbed(embed: Types.Embed, allocator: std.mem.Allocator) void {
    if (embed.title) |value| allocator.free(value);
    if (embed.description) |value| allocator.free(value);
    if (embed.url) |value| allocator.free(value);
    if (embed.timestamp) |value| allocator.free(value);
    if (embed.footer) |value| deinitEmbedFooter(value, allocator);
    if (embed.image) |value| deinitEmbedMedia(value, allocator);
    if (embed.thumbnail) |value| deinitEmbedMedia(value, allocator);
    if (embed.author) |value| deinitEmbedAuthor(value, allocator);
    for (embed.fields) |field| deinitEmbedField(field, allocator);
    allocator.free(embed.fields);
}

pub fn deinitEmbedFooter(footer: Types.EmbedFooter, allocator: std.mem.Allocator) void {
    allocator.free(footer.text);
    if (footer.icon_url) |value| allocator.free(value);
}

pub fn deinitEmbedMedia(media: Types.EmbedMedia, allocator: std.mem.Allocator) void {
    allocator.free(media.url);
}

pub fn deinitEmbedAuthor(author: Types.EmbedAuthor, allocator: std.mem.Allocator) void {
    allocator.free(author.name);
    if (author.url) |value| allocator.free(value);
    if (author.icon_url) |value| allocator.free(value);
}

pub fn deinitEmbedField(field: Types.EmbedField, allocator: std.mem.Allocator) void {
    allocator.free(field.name);
    allocator.free(field.value);
}

pub fn copyReactions(allocator: std.mem.Allocator, reactions: []const Types.MessageReaction) ![]Types.MessageReaction {
    const owned = try allocator.alloc(Types.MessageReaction, reactions.len);
    var initialized: usize = 0;
    errdefer deinitReactions(owned[0..initialized], allocator);

    for (reactions, 0..) |reaction, index| {
        owned[index] = try copyReaction(allocator, reaction);
        initialized += 1;
    }
    return owned;
}

pub fn copyReaction(allocator: std.mem.Allocator, reaction: Types.MessageReaction) !Types.MessageReaction {
    const emoji = try copyReactionEmoji(allocator, reaction.emoji);
    errdefer deinitReactionEmoji(emoji, allocator);
    const burst_colors = try copyStringArray(allocator, reaction.burst_colors);
    return .{
        .emoji = emoji,
        .count = reaction.count,
        .count_details = reaction.count_details,
        .me = reaction.me,
        .me_burst = reaction.me_burst,
        .burst_colors = burst_colors,
    };
}

pub fn copyReactionEmoji(allocator: std.mem.Allocator, emoji: Types.ReactionEmoji) !Types.ReactionEmoji {
    return .{
        .id = emoji.id,
        .name = if (emoji.name) |value| try allocator.dupe(u8, value) else null,
        .animated = emoji.animated,
    };
}

pub fn deinitReactions(reactions: []Types.MessageReaction, allocator: std.mem.Allocator) void {
    for (reactions) |reaction| {
        deinitReactionEmoji(reaction.emoji, allocator);
        deinitConstStringArray(reaction.burst_colors, allocator);
    }
    allocator.free(reactions);
}

pub fn deinitReactionEmoji(emoji: Types.ReactionEmoji, allocator: std.mem.Allocator) void {
    if (emoji.name) |value| allocator.free(value);
}

pub fn incrementReaction(allocator: std.mem.Allocator, message: *OwnedMessage, emoji: Types.ReactionEmoji) !void {
    for (message.reactions) |*reaction| {
        if (reactionEmojiEql(reaction.emoji, emoji)) {
            reaction.count += 1;
            reaction.count_details.normal += 1;
            return;
        }
    }

    const reactions = try allocator.alloc(Types.MessageReaction, message.reactions.len + 1);
    @memcpy(reactions[0..message.reactions.len], message.reactions);
    errdefer allocator.free(reactions);
    const owned_emoji = try copyReactionEmoji(allocator, emoji);
    errdefer deinitReactionEmoji(owned_emoji, allocator);
    const burst_colors = try allocator.dupe([]const u8, &.{});
    reactions[message.reactions.len] = .{
        .emoji = owned_emoji,
        .count = 1,
        .count_details = .{ .normal = 1 },
        .burst_colors = burst_colors,
    };
    allocator.free(message.reactions);
    message.reactions = reactions;
}

pub fn decrementReaction(allocator: std.mem.Allocator, message: *OwnedMessage, emoji: Types.ReactionEmoji) !void {
    for (message.reactions, 0..) |*reaction, index| {
        if (!reactionEmojiEql(reaction.emoji, emoji)) continue;
        if (reaction.count > 1) {
            reaction.count -= 1;
            if (reaction.count_details.normal > 0) reaction.count_details.normal -= 1;
            return;
        }
        try removeReactionAt(allocator, message, index);
        return;
    }
}

pub fn removeReactionEmoji(allocator: std.mem.Allocator, message: *OwnedMessage, emoji: Types.ReactionEmoji) !void {
    for (message.reactions, 0..) |reaction, index| {
        if (reactionEmojiEql(reaction.emoji, emoji)) {
            try removeReactionAt(allocator, message, index);
            return;
        }
    }
}

pub fn removeReactionAt(allocator: std.mem.Allocator, message: *OwnedMessage, index: usize) !void {
    deinitReactionEmoji(message.reactions[index].emoji, allocator);
    deinitConstStringArray(message.reactions[index].burst_colors, allocator);
    if (message.reactions.len == 1) {
        allocator.free(message.reactions);
        message.reactions = try allocator.dupe(Types.MessageReaction, &.{});
        return;
    }

    const reactions = try allocator.alloc(Types.MessageReaction, message.reactions.len - 1);
    if (index > 0) @memcpy(reactions[0..index], message.reactions[0..index]);
    if (index + 1 < message.reactions.len) {
        @memcpy(reactions[index..], message.reactions[index + 1 ..]);
    }
    allocator.free(message.reactions);
    message.reactions = reactions;
}
