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
const stickerFormatTypeFromInt = Root.stickerFormatTypeFromInt;
const roleArrayFromJson = Root.roleArrayFromJson;
const stringArrayFromJson = Root.stringArrayFromJson;
const embedFieldArrayFromJson = Root.embedFieldArrayFromJson;
const attachmentFromJson = Root.attachmentFromJson;
const requireObject = Root.requireObject;
const requireArray = Root.requireArray;
const snowflakeField = Root.snowflakeField;
const nullableSnowflakeValue = Root.nullableSnowflakeValue;
const stringField = Root.stringField;
const intField = Root.intField;
const intValue = Root.intValue;
const optionalU8Value = Root.optionalU8Value;
const optionalStringValue = Root.optionalStringValue;
const boolValue = Root.boolValue;

pub fn attachmentArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) ![]Types.Attachment {
    const array = try requireArray(value);
    var attachments = std.array_list.Managed(Types.Attachment).init(allocator);
    errdefer attachments.deinit();
    for (array.items) |item| try attachments.append(try attachmentFromJson(item));
    return attachments.toOwnedSlice();
}

pub fn messageStickerItemArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) ![]Types.MessageStickerItem {
    const array = try requireArray(value);
    var sticker_items = std.array_list.Managed(Types.MessageStickerItem).init(allocator);
    errdefer sticker_items.deinit();
    for (array.items) |item| try sticker_items.append(try messageStickerItemFromJson(item));
    return sticker_items.toOwnedSlice();
}

pub fn messageStickerItemFromJson(value: std.json.Value) !Types.MessageStickerItem {
    const object = try requireObject(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .name = try stringField(object, "name"),
        .format_type = try stickerFormatTypeFromInt(try intField(object, "format_type")),
    };
}

pub fn componentArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) anyerror![]Interactions.Component {
    const array = try requireArray(value);
    var components = std.array_list.Managed(Interactions.Component).init(allocator);
    errdefer {
        deinitParsedComponents(components.items, allocator);
        components.deinit();
    }

    for (array.items) |item| {
        if (try componentFromJson(allocator, item)) |component| try components.append(component);
    }
    return components.toOwnedSlice();
}

pub fn componentFromJson(allocator: std.mem.Allocator, value: std.json.Value) anyerror!?Interactions.Component {
    const object = try requireObject(value);
    const component_type = try intField(object, "type");
    return switch (component_type) {
        1 => .{ .action_row = try componentArrayFromJson(allocator, object.get("components") orelse return error.MissingField) },
        2 => .{ .button = try buttonFromJson(object) },
        3 => .{ .string_select = try stringSelectFromJson(allocator, object) },
        5 => .{ .user_select = try autoSelectFromJson(allocator, object, .user_select) },
        6 => .{ .role_select = try autoSelectFromJson(allocator, object, .role_select) },
        7 => .{ .mentionable_select = try autoSelectFromJson(allocator, object, .mentionable_select) },
        8 => .{ .channel_select = try autoSelectFromJson(allocator, object, .channel_select) },
        else => null,
    };
}

pub fn buttonFromJson(object: std.json.ObjectMap) !Interactions.Button {
    return .{
        .custom_id = if (object.get("custom_id")) |field| try optionalStringValue(field) else null,
        .label = if (object.get("label")) |field| try optionalStringValue(field) else null,
        .style = try buttonStyleFromInt(if (object.get("style")) |field| try intValue(field) else 1),
        .url = if (object.get("url")) |field| try optionalStringValue(field) else null,
        .disabled = if (object.get("disabled")) |field| try boolValue(field) else false,
    };
}

pub fn stringSelectFromJson(allocator: std.mem.Allocator, object: std.json.ObjectMap) !Interactions.StringSelect {
    return .{
        .custom_id = try stringField(object, "custom_id"),
        .options = if (object.get("options")) |field| try selectOptionArrayFromJson(allocator, field) else &.{},
        .placeholder = if (object.get("placeholder")) |field| try optionalStringValue(field) else null,
        .min_values = if (object.get("min_values")) |field| @intCast(try intValue(field)) else null,
        .max_values = if (object.get("max_values")) |field| @intCast(try intValue(field)) else null,
        .disabled = if (object.get("disabled")) |field| try boolValue(field) else false,
    };
}

pub fn autoSelectFromJson(
    allocator: std.mem.Allocator,
    object: std.json.ObjectMap,
    component_type: Interactions.ComponentType,
) !Interactions.AutoSelect {
    return .{
        .type = component_type,
        .custom_id = try stringField(object, "custom_id"),
        .placeholder = if (object.get("placeholder")) |field| try optionalStringValue(field) else null,
        .min_values = if (object.get("min_values")) |field| @intCast(try intValue(field)) else null,
        .max_values = if (object.get("max_values")) |field| @intCast(try intValue(field)) else null,
        .disabled = if (object.get("disabled")) |field| try boolValue(field) else false,
        .channel_types = if (object.get("channel_types")) |field| try u8ArrayFromJson(allocator, field) else &.{},
    };
}

pub fn u8ArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) ![]u8 {
    const array = try requireArray(value);
    var values = std.array_list.Managed(u8).init(allocator);
    errdefer values.deinit();
    for (array.items) |item| try values.append(@intCast(try intValue(item)));
    return values.toOwnedSlice();
}

pub fn selectOptionArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) ![]Interactions.SelectOption {
    const array = try requireArray(value);
    var options = std.array_list.Managed(Interactions.SelectOption).init(allocator);
    errdefer options.deinit();
    for (array.items) |item| try options.append(try selectOptionFromJson(item));
    return options.toOwnedSlice();
}

pub fn selectOptionFromJson(value: std.json.Value) !Interactions.SelectOption {
    const object = try requireObject(value);
    return .{
        .label = try stringField(object, "label"),
        .value = try stringField(object, "value"),
        .description = if (object.get("description")) |field| try optionalStringValue(field) else null,
        .default = if (object.get("default")) |field| try boolValue(field) else false,
    };
}

pub fn deinitParsedComponents(components: []Interactions.Component, allocator: std.mem.Allocator) void {
    for (components) |component| {
        switch (component) {
            .action_row => |children| {
                deinitParsedComponents(@constCast(children), allocator);
                allocator.free(@constCast(children));
            },
            .string_select => |select| if (select.options.len != 0) allocator.free(select.options),
            .channel_select => |select| if (select.channel_types.len != 0) allocator.free(select.channel_types),
            else => {},
        }
    }
}

pub fn deinitParsedComponentArray(components: []Interactions.Component, allocator: std.mem.Allocator) void {
    deinitParsedComponents(components, allocator);
    allocator.free(components);
}

pub fn buttonStyleFromInt(value: i64) !Interactions.ButtonStyle {
    return switch (value) {
        1 => .primary,
        2 => .secondary,
        3 => .success,
        4 => .danger,
        5 => .link,
        else => error.InvalidField,
    };
}

pub fn messagePollFromJson(allocator: std.mem.Allocator, value: std.json.Value) !?Types.MessagePoll {
    if (value == .null) return null;
    const object = try requireObject(value);
    const answers = if (object.get("answers")) |field| try messagePollAnswerArrayFromJson(allocator, field) else try allocator.dupe(Types.MessagePollAnswer, &.{});
    errdefer allocator.free(answers);
    const results = if (object.get("results")) |field| try messagePollResultsFromJson(allocator, field) else null;
    errdefer if (results) |field| allocator.free(field.answer_counts);

    return .{
        .question = try messagePollMediaFromJson(object.get("question") orelse return error.MissingField),
        .answers = answers,
        .expiry = if (object.get("expiry")) |field| try optionalStringValue(field) else null,
        .allow_multiselect = if (object.get("allow_multiselect")) |field| try boolValue(field) else false,
        .layout_type = if (object.get("layout_type")) |field| try optionalU8Value(field) else null,
        .results = results,
    };
}

pub fn messageInteractionMetadataFromJson(value: std.json.Value) !Types.MessageInteractionMetadata {
    const object = try requireObject(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .type = try interactionTypeFromInt(try intField(object, "type")),
        .user = try userFromJson(object.get("user") orelse return error.MissingField),
        .original_response_message_id = if (object.get("original_response_message_id")) |field| try nullableSnowflakeValue(field) else null,
        .interacted_message_id = if (object.get("interacted_message_id")) |field| try nullableSnowflakeValue(field) else null,
        .target_user = if (object.get("target_user")) |field| try userFromJson(field) else null,
        .target_message_id = if (object.get("target_message_id")) |field| try nullableSnowflakeValue(field) else null,
    };
}

pub fn messageCallFromJson(allocator: std.mem.Allocator, value: std.json.Value) !?Types.MessageCall {
    if (value == .null) return null;
    const object = try requireObject(value);
    return .{
        .participants = if (object.get("participants")) |field| try roleArrayFromJson(allocator, field) else try allocator.dupe(Snowflake, &.{}),
        .ended_timestamp = if (object.get("ended_timestamp")) |field| try optionalStringValue(field) else null,
    };
}

pub fn deinitParsedMessageCall(call: ?Types.MessageCall, allocator: std.mem.Allocator) void {
    if (call) |value| allocator.free(value.participants);
}

pub fn nullableRoleSubscriptionDataFromJson(value: std.json.Value) !?Types.RoleSubscriptionData {
    if (value == .null) return null;
    const object = try requireObject(value);
    return .{
        .role_subscription_listing_id = try snowflakeField(object, "role_subscription_listing_id"),
        .tier_name = try stringField(object, "tier_name"),
        .total_months_subscribed = @intCast(try intField(object, "total_months_subscribed")),
        .is_renewal = try boolValue(object.get("is_renewal") orelse return error.MissingField),
    };
}

pub fn sharedClientThemeFromJson(
    allocator: std.mem.Allocator,
    value: std.json.Value,
) !?Types.SharedClientTheme {
    if (value == .null) return null;
    const object = try requireObject(value);
    return .{
        .colors = if (object.get("colors")) |field| try stringArrayFromJson(allocator, field) else try allocator.dupe([]const u8, &.{}),
        .gradient_angle = if (object.get("gradient_angle")) |field| @intCast(try intValue(field)) else 0,
        .base_mix = if (object.get("base_mix")) |field| @intCast(try intValue(field)) else 0,
        .base_theme = if (object.get("base_theme")) |field| try nullableSharedClientThemeBaseFromJson(field) else null,
    };
}

pub fn deinitParsedSharedClientTheme(theme: ?Types.SharedClientTheme, allocator: std.mem.Allocator) void {
    if (theme) |value| allocator.free(value.colors);
}

pub fn nullableSharedClientThemeBaseFromJson(value: std.json.Value) !?Types.SharedClientThemeBase {
    if (value == .null) return null;
    return switch (try intValue(value)) {
        0 => .unset,
        1 => .dark,
        2 => .light,
        3 => .darker,
        4 => .midnight,
        else => error.InvalidField,
    };
}

pub fn nullableMessageActivityFromJson(value: std.json.Value) !?Types.MessageActivity {
    if (value == .null) return null;
    const object = try requireObject(value);
    return .{
        .type = try messageActivityTypeFromInt(try intField(object, "type")),
        .party_id = if (object.get("party_id")) |field| try optionalStringValue(field) else null,
    };
}

pub fn messageActivityTypeFromInt(value: i64) !Types.MessageActivityType {
    return switch (value) {
        1 => .join,
        2 => .spectate,
        3 => .listen,
        5 => .join_request,
        else => error.InvalidField,
    };
}

pub fn interactionTypeFromInt(value: i64) !Interactions.InteractionType {
    return switch (value) {
        1 => .ping,
        2 => .application_command,
        3 => .message_component,
        4 => .application_command_autocomplete,
        5 => .modal_submit,
        else => error.InvalidField,
    };
}

pub fn messagePollMediaFromJson(value: std.json.Value) !Types.MessagePollMedia {
    const object = try requireObject(value);
    return .{
        .text = if (object.get("text")) |field| try optionalStringValue(field) else null,
        .emoji = if (object.get("emoji")) |field| try pollEmojiFromJson(field) else null,
    };
}

pub fn pollEmojiFromJson(value: std.json.Value) !Types.PollEmoji {
    const object = try requireObject(value);
    return .{
        .id = if (object.get("id")) |field| try nullableSnowflakeValue(field) else null,
        .name = if (object.get("name")) |field| try optionalStringValue(field) else null,
    };
}

pub fn messagePollAnswerArrayFromJson(
    allocator: std.mem.Allocator,
    value: std.json.Value,
) ![]Types.MessagePollAnswer {
    const array = try requireArray(value);
    var answers = std.array_list.Managed(Types.MessagePollAnswer).init(allocator);
    errdefer answers.deinit();
    for (array.items) |item| try answers.append(try messagePollAnswerFromJson(item));
    return answers.toOwnedSlice();
}

pub fn messagePollAnswerFromJson(value: std.json.Value) !Types.MessagePollAnswer {
    const object = try requireObject(value);
    return .{
        .answer_id = @intCast(try intField(object, "answer_id")),
        .poll_media = try messagePollMediaFromJson(object.get("poll_media") orelse return error.MissingField),
    };
}

pub fn messagePollResultsFromJson(
    allocator: std.mem.Allocator,
    value: std.json.Value,
) !Types.MessagePollResults {
    const object = try requireObject(value);
    return .{
        .is_finalized = if (object.get("is_finalized")) |field| try boolValue(field) else false,
        .answer_counts = if (object.get("answer_counts")) |field| try messagePollAnswerCountArrayFromJson(allocator, field) else try allocator.dupe(Types.MessagePollAnswerCount, &.{}),
    };
}

pub fn messagePollAnswerCountArrayFromJson(
    allocator: std.mem.Allocator,
    value: std.json.Value,
) ![]Types.MessagePollAnswerCount {
    const array = try requireArray(value);
    var counts = std.array_list.Managed(Types.MessagePollAnswerCount).init(allocator);
    errdefer counts.deinit();
    for (array.items) |item| try counts.append(try messagePollAnswerCountFromJson(item));
    return counts.toOwnedSlice();
}

pub fn messagePollAnswerCountFromJson(value: std.json.Value) !Types.MessagePollAnswerCount {
    const object = try requireObject(value);
    return .{
        .id = @intCast(try intField(object, "id")),
        .count = @intCast(try intField(object, "count")),
        .me_voted = if (object.get("me_voted")) |field| try boolValue(field) else false,
    };
}

pub fn deinitParsedMessagePoll(poll: ?Types.MessagePoll, allocator: std.mem.Allocator) void {
    if (poll) |value| {
        allocator.free(value.answers);
        if (value.results) |results| allocator.free(results.answer_counts);
    }
}

pub fn embedArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) ![]Types.Embed {
    const array = try requireArray(value);
    const embeds = try allocator.alloc(Types.Embed, array.items.len);
    var initialized: usize = 0;
    errdefer deinitParsedEmbeds(embeds[0..initialized], allocator);

    for (array.items, 0..) |item, index| {
        embeds[index] = try embedFromJson(allocator, item);
        initialized += 1;
    }
    return embeds;
}

pub fn deinitParsedEmbeds(embeds: []Types.Embed, allocator: std.mem.Allocator) void {
    for (embeds) |embed| {
        if (embed.fields.len != 0) allocator.free(embed.fields);
    }
    allocator.free(embeds);
}

pub fn embedFromJson(allocator: std.mem.Allocator, value: std.json.Value) !Types.Embed {
    const object = try requireObject(value);
    return .{
        .title = if (object.get("title")) |field| try optionalStringValue(field) else null,
        .description = if (object.get("description")) |field| try optionalStringValue(field) else null,
        .url = if (object.get("url")) |field| try optionalStringValue(field) else null,
        .timestamp = if (object.get("timestamp")) |field| try optionalStringValue(field) else null,
        .color = if (object.get("color")) |field| @intCast(try intValue(field)) else null,
        .footer = if (object.get("footer")) |field| try embedFooterFromJson(field) else null,
        .image = if (object.get("image")) |field| try embedMediaFromJson(field) else null,
        .thumbnail = if (object.get("thumbnail")) |field| try embedMediaFromJson(field) else null,
        .author = if (object.get("author")) |field| try embedAuthorFromJson(field) else null,
        .fields = if (object.get("fields")) |field| try embedFieldArrayFromJson(allocator, field) else &.{},
    };
}

pub fn embedFooterFromJson(value: std.json.Value) !Types.EmbedFooter {
    const object = try requireObject(value);
    return .{
        .text = try stringField(object, "text"),
        .icon_url = if (object.get("icon_url")) |field| try optionalStringValue(field) else null,
    };
}

pub fn embedMediaFromJson(value: std.json.Value) !Types.EmbedMedia {
    const object = try requireObject(value);
    return .{ .url = try stringField(object, "url") };
}

pub fn embedAuthorFromJson(value: std.json.Value) !Types.EmbedAuthor {
    const object = try requireObject(value);
    return .{
        .name = try stringField(object, "name"),
        .url = if (object.get("url")) |field| try optionalStringValue(field) else null,
        .icon_url = if (object.get("icon_url")) |field| try optionalStringValue(field) else null,
    };
}
