const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Types = @import("../../models/types.zig");
const Interactions = @import("../../interactions/mod.zig");

const Root = @import("../cache.zig");
const deinitComponents = Root.deinitComponents;
const copyTeam = Root.copyTeam;
const deinitTeam = Root.deinitTeam;
const copyStringArray = Root.copyStringArray;
const deinitStringArray = Root.deinitStringArray;
const deinitConstStringArray = Root.deinitConstStringArray;

pub fn deinitComponent(component: Interactions.Component, allocator: std.mem.Allocator) void {
    switch (component) {
        .action_row => |children| deinitComponents(@constCast(children), allocator),
        .button => |button| {
            if (button.custom_id) |value| allocator.free(value);
            if (button.label) |value| allocator.free(value);
            if (button.url) |value| allocator.free(value);
        },
        .string_select => |select| {
            allocator.free(select.custom_id);
            deinitSelectOptions(@constCast(select.options), allocator);
            if (select.placeholder) |value| allocator.free(value);
        },
        .user_select, .role_select, .mentionable_select, .channel_select => |select| {
            allocator.free(select.custom_id);
            if (select.placeholder) |value| allocator.free(value);
            allocator.free(select.channel_types);
        },
        .text_input => |input| {
            allocator.free(input.custom_id);
            allocator.free(input.label);
            if (input.placeholder) |value| allocator.free(value);
            if (input.value) |value| allocator.free(value);
        },
        .section => |value| {
            for (value.components) |text| allocator.free(text.content);
            allocator.free(@constCast(value.components));
            switch (value.accessory) {
                .button => |button| {
                    if (button.custom_id) |field| allocator.free(field);
                    if (button.label) |field| allocator.free(field);
                    if (button.url) |field| allocator.free(field);
                },
                .thumbnail => |thumbnail| deinitThumbnail(thumbnail, allocator),
            }
        },
        .text_display => |value| allocator.free(value.content),
        .thumbnail => |value| deinitThumbnail(value, allocator),
        .media_gallery => |value| {
            for (value.items) |item| deinitMediaGalleryItem(item, allocator);
            allocator.free(@constCast(value.items));
        },
        .file => |value| allocator.free(value.file.url),
        .separator => {},
        .container => |value| deinitComponents(@constCast(value.components), allocator),
    }
}

pub fn deinitSelectOptions(options: []Interactions.SelectOption, allocator: std.mem.Allocator) void {
    for (options) |option| {
        allocator.free(option.label);
        allocator.free(option.value);
        if (option.description) |value| allocator.free(value);
    }
    allocator.free(options);
}

pub fn deinitThumbnail(thumbnail: Interactions.Thumbnail, allocator: std.mem.Allocator) void {
    allocator.free(thumbnail.media.url);
    if (thumbnail.description) |value| allocator.free(value);
}

pub fn deinitMediaGalleryItem(item: Interactions.MediaGalleryItem, allocator: std.mem.Allocator) void {
    allocator.free(item.media.url);
    if (item.description) |value| allocator.free(value);
}

pub fn copyMessagePoll(allocator: std.mem.Allocator, poll: Types.MessagePoll) !Types.MessagePoll {
    const question = try copyMessagePollMedia(allocator, poll.question);
    errdefer deinitMessagePollMedia(question, allocator);
    const answers = try copyMessagePollAnswers(allocator, poll.answers);
    errdefer deinitMessagePollAnswers(answers, allocator);
    const expiry = if (poll.expiry) |value| try allocator.dupe(u8, value) else null;
    errdefer if (expiry) |value| allocator.free(value);
    const results = if (poll.results) |value| try copyMessagePollResults(allocator, value) else null;

    return .{
        .question = question,
        .answers = answers,
        .expiry = expiry,
        .allow_multiselect = poll.allow_multiselect,
        .layout_type = poll.layout_type,
        .results = results,
    };
}

pub fn copyMessagePollMedia(allocator: std.mem.Allocator, media: Types.MessagePollMedia) !Types.MessagePollMedia {
    const text = if (media.text) |value| try allocator.dupe(u8, value) else null;
    errdefer if (text) |value| allocator.free(value);
    const emoji = if (media.emoji) |value| try copyPollEmoji(allocator, value) else null;
    return .{ .text = text, .emoji = emoji };
}

pub fn copyPollEmoji(allocator: std.mem.Allocator, emoji: Types.PollEmoji) !Types.PollEmoji {
    return .{
        .id = emoji.id,
        .name = if (emoji.name) |value| try allocator.dupe(u8, value) else null,
    };
}

pub fn copyMessagePollAnswers(
    allocator: std.mem.Allocator,
    answers: []const Types.MessagePollAnswer,
) ![]Types.MessagePollAnswer {
    const owned = try allocator.alloc(Types.MessagePollAnswer, answers.len);
    var initialized: usize = 0;
    errdefer deinitMessagePollAnswers(owned[0..initialized], allocator);

    for (answers, 0..) |answer, index| {
        owned[index] = .{
            .answer_id = answer.answer_id,
            .poll_media = try copyMessagePollMedia(allocator, answer.poll_media),
        };
        initialized += 1;
    }
    return owned;
}

pub fn copyMessagePollResults(
    allocator: std.mem.Allocator,
    results: Types.MessagePollResults,
) !Types.MessagePollResults {
    return .{
        .is_finalized = results.is_finalized,
        .answer_counts = try allocator.dupe(Types.MessagePollAnswerCount, results.answer_counts),
    };
}

pub fn deinitMessagePoll(poll: Types.MessagePoll, allocator: std.mem.Allocator) void {
    deinitMessagePollMedia(poll.question, allocator);
    deinitMessagePollAnswers(@constCast(poll.answers), allocator);
    if (poll.expiry) |value| allocator.free(value);
    if (poll.results) |value| allocator.free(value.answer_counts);
}

pub fn deinitMessagePollAnswers(answers: []Types.MessagePollAnswer, allocator: std.mem.Allocator) void {
    for (answers) |answer| deinitMessagePollMedia(answer.poll_media, allocator);
    allocator.free(answers);
}

pub fn deinitMessagePollMedia(media: Types.MessagePollMedia, allocator: std.mem.Allocator) void {
    if (media.text) |value| allocator.free(value);
    if (media.emoji) |emoji| {
        if (emoji.name) |value| allocator.free(value);
    }
}

pub fn copyMessageCall(allocator: std.mem.Allocator, call: Types.MessageCall) !Types.MessageCall {
    const participants = try allocator.dupe(Snowflake, call.participants);
    errdefer allocator.free(participants);
    const ended_timestamp = if (call.ended_timestamp) |value| try allocator.dupe(u8, value) else null;
    return .{ .participants = participants, .ended_timestamp = ended_timestamp };
}

pub fn deinitMessageCall(call: Types.MessageCall, allocator: std.mem.Allocator) void {
    allocator.free(call.participants);
    if (call.ended_timestamp) |value| allocator.free(value);
}

pub fn copyRoleSubscriptionData(
    allocator: std.mem.Allocator,
    data: Types.RoleSubscriptionData,
) !Types.RoleSubscriptionData {
    return .{
        .role_subscription_listing_id = data.role_subscription_listing_id,
        .tier_name = try allocator.dupe(u8, data.tier_name),
        .total_months_subscribed = data.total_months_subscribed,
        .is_renewal = data.is_renewal,
    };
}

pub fn deinitRoleSubscriptionData(data: Types.RoleSubscriptionData, allocator: std.mem.Allocator) void {
    allocator.free(data.tier_name);
}

pub fn copySharedClientTheme(
    allocator: std.mem.Allocator,
    theme: Types.SharedClientTheme,
) !Types.SharedClientTheme {
    return .{
        .colors = try copyStringArray(allocator, theme.colors),
        .gradient_angle = theme.gradient_angle,
        .base_mix = theme.base_mix,
        .base_theme = theme.base_theme,
    };
}

pub fn deinitSharedClientTheme(theme: Types.SharedClientTheme, allocator: std.mem.Allocator) void {
    deinitConstStringArray(theme.colors, allocator);
}

pub fn copyMessageActivity(allocator: std.mem.Allocator, activity: Types.MessageActivity) !Types.MessageActivity {
    return .{
        .type = activity.type,
        .party_id = if (activity.party_id) |value| try allocator.dupe(u8, value) else null,
    };
}

pub fn deinitMessageActivity(activity: Types.MessageActivity, allocator: std.mem.Allocator) void {
    if (activity.party_id) |value| allocator.free(value);
}

pub fn copyMessageInteractionMetadata(
    allocator: std.mem.Allocator,
    metadata: Types.MessageInteractionMetadata,
) !Types.MessageInteractionMetadata {
    const user = try copyUser(allocator, metadata.user);
    errdefer deinitUser(user, allocator);
    const target_user = if (metadata.target_user) |value| try copyUser(allocator, value) else null;

    return .{
        .id = metadata.id,
        .type = metadata.type,
        .user = user,
        .original_response_message_id = metadata.original_response_message_id,
        .interacted_message_id = metadata.interacted_message_id,
        .target_user = target_user,
        .target_message_id = metadata.target_message_id,
    };
}

pub fn deinitMessageInteractionMetadata(
    metadata: Types.MessageInteractionMetadata,
    allocator: std.mem.Allocator,
) void {
    deinitUser(metadata.user, allocator);
    if (metadata.target_user) |value| deinitUser(value, allocator);
}

pub fn copyGuildMember(allocator: std.mem.Allocator, member: Types.GuildMember) !Types.GuildMember {
    const user = if (member.user) |value| try copyUser(allocator, value) else null;
    errdefer if (user) |value| deinitUser(value, allocator);
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
        .user = user,
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

pub fn deinitGuildMember(member: Types.GuildMember, allocator: std.mem.Allocator) void {
    if (member.user) |value| deinitUser(value, allocator);
    if (member.nick) |value| allocator.free(value);
    if (member.avatar) |value| allocator.free(value);
    allocator.free(member.roles);
    if (member.joined_at) |value| allocator.free(value);
    if (member.premium_since) |value| allocator.free(value);
    if (member.communication_disabled_until) |value| allocator.free(value);
}

pub fn copyUsers(allocator: std.mem.Allocator, users: []const Types.User) ![]Types.User {
    const owned = try allocator.alloc(Types.User, users.len);
    var initialized: usize = 0;
    errdefer deinitUsers(owned[0..initialized], allocator);

    for (users, 0..) |user, index| {
        owned[index] = try copyUser(allocator, user);
        initialized += 1;
    }
    return owned;
}

pub fn copyUser(allocator: std.mem.Allocator, user: Types.User) !Types.User {
    const username = try allocator.dupe(u8, user.username);
    errdefer allocator.free(username);
    const discriminator = if (user.discriminator) |value| try allocator.dupe(u8, value) else null;
    errdefer if (discriminator) |value| allocator.free(value);
    const global_name = if (user.global_name) |value| try allocator.dupe(u8, value) else null;
    errdefer if (global_name) |value| allocator.free(value);
    const avatar = if (user.avatar) |value| try allocator.dupe(u8, value) else null;
    errdefer if (avatar) |value| allocator.free(value);
    const banner = if (user.banner) |value| try allocator.dupe(u8, value) else null;

    return .{
        .id = user.id,
        .username = username,
        .discriminator = discriminator,
        .global_name = global_name,
        .avatar = avatar,
        .banner = banner,
        .bot = user.bot,
    };
}

pub fn deinitUsers(users: []Types.User, allocator: std.mem.Allocator) void {
    for (users) |user| deinitUser(user, allocator);
    allocator.free(users);
}

pub fn deinitUser(user: Types.User, allocator: std.mem.Allocator) void {
    allocator.free(user.username);
    if (user.discriminator) |value| allocator.free(value);
    if (user.global_name) |value| allocator.free(value);
    if (user.avatar) |value| allocator.free(value);
    if (user.banner) |value| allocator.free(value);
}

pub fn copyApplication(allocator: std.mem.Allocator, application: Types.Application) !Types.Application {
    const name = try allocator.dupe(u8, application.name);
    errdefer allocator.free(name);
    const icon = if (application.icon) |value| try allocator.dupe(u8, value) else null;
    errdefer if (icon) |value| allocator.free(value);
    const description = try allocator.dupe(u8, application.description);
    errdefer allocator.free(description);
    const bot = if (application.bot) |value| try copyUser(allocator, value) else null;
    errdefer if (bot) |value| deinitUser(value, allocator);
    const owner = if (application.owner) |value| try copyUser(allocator, value) else null;
    errdefer if (owner) |value| deinitUser(value, allocator);
    const verify_key = try allocator.dupe(u8, application.verify_key);
    errdefer allocator.free(verify_key);
    const interactions_endpoint_url = if (application.interactions_endpoint_url) |value| try allocator.dupe(u8, value) else null;
    errdefer if (interactions_endpoint_url) |value| allocator.free(value);
    const role_connections_verification_url = if (application.role_connections_verification_url) |value| try allocator.dupe(u8, value) else null;
    errdefer if (role_connections_verification_url) |value| allocator.free(value);
    const event_webhooks_url = if (application.event_webhooks_url) |value| try allocator.dupe(u8, value) else null;
    errdefer if (event_webhooks_url) |value| allocator.free(value);
    const event_webhooks_types = try copyStringArray(allocator, application.event_webhooks_types);
    errdefer deinitStringArray(event_webhooks_types, allocator);
    const tags = try copyStringArray(allocator, application.tags);
    errdefer deinitStringArray(tags, allocator);
    const custom_install_url = if (application.custom_install_url) |value| try allocator.dupe(u8, value) else null;
    errdefer if (custom_install_url) |value| allocator.free(value);
    const team = if (application.team) |value| try copyTeam(allocator, value) else null;
    errdefer if (team) |value| deinitTeam(value, allocator);

    return .{
        .id = application.id,
        .name = name,
        .icon = icon,
        .description = description,
        .bot_public = application.bot_public,
        .bot_require_code_grant = application.bot_require_code_grant,
        .bot = bot,
        .owner = owner,
        .team = team,
        .verify_key = verify_key,
        .guild_id = application.guild_id,
        .flags = application.flags,
        .approximate_guild_count = application.approximate_guild_count,
        .approximate_user_install_count = application.approximate_user_install_count,
        .interactions_endpoint_url = interactions_endpoint_url,
        .role_connections_verification_url = role_connections_verification_url,
        .event_webhooks_url = event_webhooks_url,
        .event_webhooks_status = application.event_webhooks_status,
        .event_webhooks_types = event_webhooks_types,
        .tags = tags,
        .custom_install_url = custom_install_url,
    };
}

pub fn deinitApplication(application: Types.Application, allocator: std.mem.Allocator) void {
    allocator.free(application.name);
    if (application.icon) |value| allocator.free(value);
    allocator.free(application.description);
    if (application.bot) |value| deinitUser(value, allocator);
    if (application.owner) |value| deinitUser(value, allocator);
    allocator.free(application.verify_key);
    if (application.interactions_endpoint_url) |value| allocator.free(value);
    if (application.role_connections_verification_url) |value| allocator.free(value);
    if (application.event_webhooks_url) |value| allocator.free(value);
    deinitConstStringArray(application.event_webhooks_types, allocator);
    deinitConstStringArray(application.tags, allocator);
    if (application.custom_install_url) |value| allocator.free(value);
    if (application.team) |team| deinitTeam(team, allocator);
}
