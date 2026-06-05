const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Types = @import("../../models/types.zig");
const Gateway = @import("../../gateway/protocol.zig");
const Interactions = @import("../../interactions/mod.zig");
const Permissions = @import("../../core/permissions.zig");
const Collection = @import("../../core/collection.zig").Collection;

const Root = @import("../cache.zig");
const init = Root.init;
const deinit = Root.deinit;
const stringArrayFromJson = Root.stringArrayFromJson;

pub fn embedFieldArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) ![]Types.EmbedField {
    const array = try requireArray(value);
    var fields = std.array_list.Managed(Types.EmbedField).init(allocator);
    errdefer fields.deinit();
    for (array.items) |item| try fields.append(try embedFieldFromJson(item));
    return fields.toOwnedSlice();
}

pub fn embedFieldFromJson(value: std.json.Value) !Types.EmbedField {
    const object = try requireObject(value);
    return .{
        .name = try stringField(object, "name"),
        .value = try stringField(object, "value"),
        .is_inline = if (object.get("inline")) |field| try boolValue(field) else false,
    };
}

pub fn attachmentFromJson(value: std.json.Value) !Types.Attachment {
    const object = try requireObject(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .filename = try stringField(object, "filename"),
        .description = if (object.get("description")) |field| try optionalStringValue(field) else null,
        .content_type = if (object.get("content_type")) |field| try optionalStringValue(field) else null,
        .size = if (object.get("size")) |field| @intCast(try intValue(field)) else 0,
        .url = try stringField(object, "url"),
        .proxy_url = try stringField(object, "proxy_url"),
        .height = if (object.get("height")) |field| try optionalU32Value(field) else null,
        .width = if (object.get("width")) |field| try optionalU32Value(field) else null,
        .ephemeral = if (object.get("ephemeral")) |field| try boolValue(field) else false,
    };
}

pub fn reactionArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) ![]Types.MessageReaction {
    const array = try requireArray(value);
    var reactions = std.array_list.Managed(Types.MessageReaction).init(allocator);
    errdefer {
        deinitParsedReactionFields(reactions.items, allocator);
        reactions.deinit();
    }
    for (array.items) |item| try reactions.append(try reactionFromJson(allocator, item));
    return reactions.toOwnedSlice();
}

pub fn reactionFromJson(allocator: std.mem.Allocator, value: std.json.Value) !Types.MessageReaction {
    const object = try requireObject(value);
    return .{
        .emoji = try reactionEmojiFromJson(object.get("emoji") orelse return error.MissingField),
        .count = if (object.get("count")) |field| @intCast(try intValue(field)) else 0,
        .count_details = if (object.get("count_details")) |field| try reactionCountDetailsFromJson(field) else .{},
        .me = if (object.get("me")) |field| try boolValue(field) else false,
        .me_burst = if (object.get("me_burst")) |field| try boolValue(field) else false,
        .burst_colors = if (object.get("burst_colors")) |field| try stringArrayFromJson(allocator, field) else try allocator.dupe([]const u8, &.{}),
    };
}

pub fn reactionCountDetailsFromJson(value: std.json.Value) !Types.ReactionCountDetails {
    const object = try requireObject(value);
    return .{
        .burst = if (object.get("burst")) |field| @intCast(try intValue(field)) else 0,
        .normal = if (object.get("normal")) |field| @intCast(try intValue(field)) else 0,
    };
}

pub fn deinitParsedReactions(reactions: []Types.MessageReaction, allocator: std.mem.Allocator) void {
    deinitParsedReactionFields(reactions, allocator);
    allocator.free(reactions);
}

pub fn deinitParsedReactionFields(reactions: []Types.MessageReaction, allocator: std.mem.Allocator) void {
    for (reactions) |reaction| allocator.free(reaction.burst_colors);
}

pub const ReactionEvent = struct {
    message_id: Snowflake,
    emoji: Types.ReactionEmoji,
};

pub fn reactionEventFromJson(value: std.json.Value) !ReactionEvent {
    const object = try requireObject(value);
    return .{
        .message_id = try snowflakeField(object, "message_id"),
        .emoji = try reactionEmojiFromJson(object.get("emoji") orelse return error.MissingField),
    };
}

pub fn reactionEmojiFromJson(value: std.json.Value) !Types.ReactionEmoji {
    const object = try requireObject(value);
    return .{
        .id = if (object.get("id")) |field| try nullableSnowflakeValue(field) else null,
        .name = if (object.get("name")) |field| try optionalStringValue(field) else null,
        .animated = if (object.get("animated")) |field| try boolValue(field) else false,
    };
}

pub fn requireObject(value: std.json.Value) !std.json.ObjectMap {
    return switch (value) {
        .object => |object| object,
        else => error.InvalidField,
    };
}

pub fn requireArray(value: std.json.Value) !std.json.Array {
    return switch (value) {
        .array => |array| array,
        else => error.InvalidField,
    };
}

pub fn snowflakeField(object: std.json.ObjectMap, field: []const u8) !Snowflake {
    return snowflakeValue(object.get(field) orelse return error.MissingField);
}

pub fn snowflakeValue(value: std.json.Value) !Snowflake {
    return Snowflake.parse(try stringValue(value));
}

pub fn nullableSnowflakeValue(value: std.json.Value) !?Snowflake {
    return switch (value) {
        .string => |string| try Snowflake.parse(string),
        .null => null,
        else => error.InvalidField,
    };
}

pub fn permissionsValue(value: std.json.Value) !u64 {
    return switch (value) {
        .integer => |integer| @intCast(integer),
        .string => |string| std.fmt.parseInt(u64, string, 10) catch return error.InvalidField,
        else => error.InvalidField,
    };
}

pub fn stringField(object: std.json.ObjectMap, field: []const u8) ![]const u8 {
    return stringValue(object.get(field) orelse return error.MissingField);
}

pub fn intField(object: std.json.ObjectMap, field: []const u8) !i64 {
    return intValue(object.get(field) orelse return error.MissingField);
}

pub fn intValue(value: std.json.Value) !i64 {
    return switch (value) {
        .integer => |integer| @intCast(integer),
        else => error.InvalidField,
    };
}

pub fn nullableIntValue(value: std.json.Value) !?i64 {
    return switch (value) {
        .integer => |integer| @intCast(integer),
        .null => null,
        else => error.InvalidField,
    };
}

pub fn nullableU24Value(value: std.json.Value) !?u24 {
    return switch (value) {
        .integer => |integer| @intCast(integer),
        .null => null,
        else => error.InvalidField,
    };
}

pub const ParsedMessageNonce = struct {
    value: []const u8,
    owned: bool = false,

    pub fn deinit(self: ParsedMessageNonce, allocator: std.mem.Allocator) void {
        if (self.owned) allocator.free(self.value);
    }
};

pub fn messageNonceFromJson(allocator: std.mem.Allocator, value: std.json.Value) !?ParsedMessageNonce {
    return switch (value) {
        .string => |string| .{ .value = string },
        .integer => |integer| .{ .value = try std.fmt.allocPrint(allocator, "{d}", .{integer}), .owned = true },
        .null => null,
        else => error.InvalidField,
    };
}

pub fn optionalU32Value(value: std.json.Value) !?u32 {
    return switch (value) {
        .integer => |integer| @intCast(integer),
        .null => null,
        else => error.InvalidField,
    };
}

pub fn optionalU8Value(value: std.json.Value) !?u8 {
    return switch (value) {
        .integer => |integer| @intCast(integer),
        .null => null,
        else => error.InvalidField,
    };
}

pub fn stringValue(value: std.json.Value) ![]const u8 {
    return switch (value) {
        .string => |string| string,
        else => error.InvalidField,
    };
}

pub fn optionalStringValue(value: std.json.Value) !?[]const u8 {
    return switch (value) {
        .string => |string| string,
        .null => null,
        else => error.InvalidField,
    };
}

pub fn boolValue(value: std.json.Value) !bool {
    return switch (value) {
        .bool => |boolean| boolean,
        else => error.InvalidField,
    };
}

pub fn optionalBoolValue(value: std.json.Value) !?bool {
    return switch (value) {
        .bool => |boolean| boolean,
        .null => null,
        else => error.InvalidField,
    };
}

pub fn nestedIdValue(object: std.json.ObjectMap, key: []const u8) !?Snowflake {
    const value = object.get(key) orelse return null;
    const nested = switch (value) {
        .object => |inner| inner,
        .null => return null,
        else => return error.InvalidField,
    };
    return try snowflakeField(nested, "id");
}
