const std = @import("std");
const Snowflake = @import("snowflake.zig").Snowflake;

pub const MentionKind = enum {
    user,
    role,
    channel,
    everyone,
    here,
};

pub const Mention = struct {
    kind: MentionKind,
    id: ?Snowflake = null,
};

pub const TimestampStyle = enum(u8) {
    short_time,
    long_time,
    short_date,
    long_date,
    short_datetime,
    long_datetime,
    relative,

    fn code(self: TimestampStyle) u8 {
        return switch (self) {
            .short_time => 't',
            .long_time => 'T',
            .short_date => 'd',
            .long_date => 'D',
            .short_datetime => 'f',
            .long_datetime => 'F',
            .relative => 'R',
        };
    }
};

pub const MentionList = struct {
    allocator: std.mem.Allocator,
    items: []Mention,

    pub fn deinit(self: *MentionList) void {
        self.allocator.free(self.items);
        self.items = &.{};
    }
};

pub const Handler = struct {
    ptr: *anyopaque,
    callFn: *const fn (ptr: *anyopaque, mention: Mention) anyerror!void,

    pub fn call(self: Handler, mention: Mention) !void {
        try self.callFn(self.ptr, mention);
    }
};

pub fn handler(ptr: anytype, comptime function: anytype) Handler {
    const Ptr = @TypeOf(ptr);
    const wrapper = struct {
        fn call(raw: *anyopaque, mention: Mention) anyerror!void {
            const typed: Ptr = @ptrCast(@alignCast(raw));
            try function(typed, mention);
        }
    };

    return .{ .ptr = ptr, .callFn = wrapper.call };
}

pub fn user(user_id: Snowflake, allocator: std.mem.Allocator) ![]u8 {
    return userMention(allocator, user_id);
}

pub fn role(role_id: Snowflake, allocator: std.mem.Allocator) ![]u8 {
    return roleMention(allocator, role_id);
}

pub fn channel(channel_id: Snowflake, allocator: std.mem.Allocator) ![]u8 {
    return channelMention(allocator, channel_id);
}

pub fn userMention(allocator: std.mem.Allocator, user_id: Snowflake) ![]u8 {
    return std.fmt.allocPrint(allocator, "<@{d}>", .{user_id.value});
}

pub fn nicknameMention(allocator: std.mem.Allocator, user_id: Snowflake) ![]u8 {
    return std.fmt.allocPrint(allocator, "<@!{d}>", .{user_id.value});
}

pub fn memberNicknameMention(allocator: std.mem.Allocator, user_id: Snowflake) ![]u8 {
    return nicknameMention(allocator, user_id);
}

pub fn roleMention(allocator: std.mem.Allocator, role_id: Snowflake) ![]u8 {
    return std.fmt.allocPrint(allocator, "<@&{d}>", .{role_id.value});
}

pub fn channelMention(allocator: std.mem.Allocator, channel_id: Snowflake) ![]u8 {
    return std.fmt.allocPrint(allocator, "<#{d}>", .{channel_id.value});
}

pub fn emojiMention(allocator: std.mem.Allocator, name: []const u8, emoji_id: Snowflake) ![]u8 {
    if (name.len == 0) return error.InvalidEmojiName;
    return std.fmt.allocPrint(allocator, "<:{s}:{d}>", .{ name, emoji_id.value });
}

pub fn animatedEmojiMention(allocator: std.mem.Allocator, name: []const u8, emoji_id: Snowflake) ![]u8 {
    if (name.len == 0) return error.InvalidEmojiName;
    return std.fmt.allocPrint(allocator, "<a:{s}:{d}>", .{ name, emoji_id.value });
}

pub fn timestampMention(allocator: std.mem.Allocator, unix_seconds: u64, style: ?TimestampStyle) ![]u8 {
    if (style) |timestamp_style| {
        return std.fmt.allocPrint(allocator, "<t:{d}:{c}>", .{ unix_seconds, timestamp_style.code() });
    }
    return std.fmt.allocPrint(allocator, "<t:{d}>", .{unix_seconds});
}

pub fn relativeTimestampMention(allocator: std.mem.Allocator, unix_seconds: u64) ![]u8 {
    return timestampMention(allocator, unix_seconds, .relative);
}

pub fn everyoneMention() []const u8 {
    return "@everyone";
}

pub fn hereMention() []const u8 {
    return "@here";
}

pub fn format(allocator: std.mem.Allocator, mention: Mention) ![]u8 {
    return switch (mention.kind) {
        .user => userMention(allocator, mention.id orelse return error.MissingMentionId),
        .role => roleMention(allocator, mention.id orelse return error.MissingMentionId),
        .channel => channelMention(allocator, mention.id orelse return error.MissingMentionId),
        .everyone => std.fmt.allocPrint(allocator, "{s}", .{everyoneMention()}),
        .here => std.fmt.allocPrint(allocator, "{s}", .{hereMention()}),
    };
}

pub fn scan(content: []const u8, mention_handler: Handler) !usize {
    var count: usize = 0;
    var index: usize = 0;
    while (index < content.len) {
        if (startsWithToken(content, index, "@everyone")) {
            try mention_handler.call(.{ .kind = .everyone });
            count += 1;
            index += "@everyone".len;
            continue;
        }
        if (startsWithToken(content, index, "@here")) {
            try mention_handler.call(.{ .kind = .here });
            count += 1;
            index += "@here".len;
            continue;
        }
        if (content[index] == '<') {
            if (try parseBracketMention(content[index..])) |parsed| {
                try mention_handler.call(parsed.mention);
                count += 1;
                index += parsed.len;
                continue;
            }
        }
        index += 1;
    }
    return count;
}

pub fn parse(allocator: std.mem.Allocator, content: []const u8) !MentionList {
    const State = struct {
        mentions: std.array_list.Managed(Mention),

        fn onMention(self: *@This(), mention: Mention) !void {
            try self.mentions.append(mention);
        }
    };

    var state = State{ .mentions = std.array_list.Managed(Mention).init(allocator) };
    errdefer state.mentions.deinit();

    _ = try scan(content, handler(&state, State.onMention));
    return .{
        .allocator = allocator,
        .items = try state.mentions.toOwnedSlice(),
    };
}

const ParsedMention = struct {
    mention: Mention,
    len: usize,
};

fn parseBracketMention(content: []const u8) !?ParsedMention {
    if (content.len < 4 or content[0] != '<') return null;
    const close_index = std.mem.indexOfScalar(u8, content, '>') orelse return null;
    const token = content[0 .. close_index + 1];

    if (std.mem.startsWith(u8, token, "<#")) {
        const id = parseIdToken(token[2 .. token.len - 1]) catch return null;
        return .{ .mention = .{ .kind = .channel, .id = id }, .len = token.len };
    }
    if (std.mem.startsWith(u8, token, "<@&")) {
        const id = parseIdToken(token[3 .. token.len - 1]) catch return null;
        return .{ .mention = .{ .kind = .role, .id = id }, .len = token.len };
    }
    if (std.mem.startsWith(u8, token, "<@!")) {
        const id = parseIdToken(token[3 .. token.len - 1]) catch return null;
        return .{ .mention = .{ .kind = .user, .id = id }, .len = token.len };
    }
    if (std.mem.startsWith(u8, token, "<@")) {
        const id = parseIdToken(token[2 .. token.len - 1]) catch return null;
        return .{ .mention = .{ .kind = .user, .id = id }, .len = token.len };
    }

    return null;
}

fn parseIdToken(value: []const u8) !Snowflake {
    if (value.len == 0) return error.InvalidMention;
    for (value) |byte| {
        if (byte < '0' or byte > '9') return error.InvalidMention;
    }
    return Snowflake.parse(value);
}

fn startsWithToken(content: []const u8, index: usize, token: []const u8) bool {
    if (index + token.len > content.len) return false;
    if (!std.mem.eql(u8, content[index .. index + token.len], token)) return false;
    if (index != 0 and isMentionWord(content[index - 1])) return false;
    const after = index + token.len;
    if (after < content.len and isMentionWord(content[after])) return false;
    return true;
}

fn isMentionWord(byte: u8) bool {
    return std.ascii.isAlphanumeric(byte) or byte == '_';
}

test "mention scanner finds user role channel and broadcast mentions" {
    const State = struct {
        kinds: [6]MentionKind = .{ .user, .user, .user, .user, .user, .user },
        ids: [6]u64 = .{0} ** 6,
        len: usize = 0,

        fn onMention(self: *@This(), mention: Mention) !void {
            self.kinds[self.len] = mention.kind;
            self.ids[self.len] = if (mention.id) |id| id.value else 0;
            self.len += 1;
        }
    };

    var state = State{};
    const count = try scan(
        "hello <@10> <@!11> <@&12> <#13> @everyone @here",
        handler(&state, State.onMention),
    );

    try std.testing.expectEqual(@as(usize, 6), count);
    try std.testing.expectEqual(@as(usize, 6), state.len);
    try std.testing.expectEqual(MentionKind.user, state.kinds[0]);
    try std.testing.expectEqual(@as(u64, 10), state.ids[0]);
    try std.testing.expectEqual(MentionKind.user, state.kinds[1]);
    try std.testing.expectEqual(@as(u64, 11), state.ids[1]);
    try std.testing.expectEqual(MentionKind.role, state.kinds[2]);
    try std.testing.expectEqual(@as(u64, 12), state.ids[2]);
    try std.testing.expectEqual(MentionKind.channel, state.kinds[3]);
    try std.testing.expectEqual(@as(u64, 13), state.ids[3]);
    try std.testing.expectEqual(MentionKind.everyone, state.kinds[4]);
    try std.testing.expectEqual(MentionKind.here, state.kinds[5]);
}

test "mention formatters build Discord mention strings" {
    const user_text = try userMention(std.testing.allocator, Snowflake.init(10));
    defer std.testing.allocator.free(user_text);
    try std.testing.expectEqualStrings("<@10>", user_text);

    const user_alias = try user(Snowflake.init(11), std.testing.allocator);
    defer std.testing.allocator.free(user_alias);
    try std.testing.expectEqualStrings("<@11>", user_alias);

    const nickname_text = try nicknameMention(std.testing.allocator, Snowflake.init(12));
    defer std.testing.allocator.free(nickname_text);
    try std.testing.expectEqualStrings("<@!12>", nickname_text);

    const member_nick_text = try memberNicknameMention(std.testing.allocator, Snowflake.init(13));
    defer std.testing.allocator.free(member_nick_text);
    try std.testing.expectEqualStrings("<@!13>", member_nick_text);

    const role_text = try roleMention(std.testing.allocator, Snowflake.init(20));
    defer std.testing.allocator.free(role_text);
    try std.testing.expectEqualStrings("<@&20>", role_text);

    const role_alias = try role(Snowflake.init(21), std.testing.allocator);
    defer std.testing.allocator.free(role_alias);
    try std.testing.expectEqualStrings("<@&21>", role_alias);

    const channel_text = try channelMention(std.testing.allocator, Snowflake.init(30));
    defer std.testing.allocator.free(channel_text);
    try std.testing.expectEqualStrings("<#30>", channel_text);

    const channel_alias = try channel(Snowflake.init(31), std.testing.allocator);
    defer std.testing.allocator.free(channel_alias);
    try std.testing.expectEqualStrings("<#31>", channel_alias);

    const emoji_text = try emojiMention(std.testing.allocator, "zig", Snowflake.init(40));
    defer std.testing.allocator.free(emoji_text);
    try std.testing.expectEqualStrings("<:zig:40>", emoji_text);

    const animated_emoji_text = try animatedEmojiMention(std.testing.allocator, "wave", Snowflake.init(41));
    defer std.testing.allocator.free(animated_emoji_text);
    try std.testing.expectEqualStrings("<a:wave:41>", animated_emoji_text);

    const timestamp_text = try timestampMention(std.testing.allocator, 1_717_350_000, .short_datetime);
    defer std.testing.allocator.free(timestamp_text);
    try std.testing.expectEqualStrings("<t:1717350000:f>", timestamp_text);

    const plain_timestamp_text = try timestampMention(std.testing.allocator, 1_717_350_000, null);
    defer std.testing.allocator.free(plain_timestamp_text);
    try std.testing.expectEqualStrings("<t:1717350000>", plain_timestamp_text);

    const relative_timestamp_text = try relativeTimestampMention(std.testing.allocator, 1_717_350_000);
    defer std.testing.allocator.free(relative_timestamp_text);
    try std.testing.expectEqualStrings("<t:1717350000:R>", relative_timestamp_text);

    try std.testing.expectEqualStrings("@everyone", everyoneMention());
    try std.testing.expectEqualStrings("@here", hereMention());
    try std.testing.expectError(error.InvalidEmojiName, emojiMention(std.testing.allocator, "", Snowflake.init(40)));
}

test "mention formatter renders parsed mention values" {
    const user_text = try format(std.testing.allocator, .{ .kind = .user, .id = Snowflake.init(10) });
    defer std.testing.allocator.free(user_text);
    try std.testing.expectEqualStrings("<@10>", user_text);

    const role_text = try format(std.testing.allocator, .{ .kind = .role, .id = Snowflake.init(20) });
    defer std.testing.allocator.free(role_text);
    try std.testing.expectEqualStrings("<@&20>", role_text);

    const channel_text = try format(std.testing.allocator, .{ .kind = .channel, .id = Snowflake.init(30) });
    defer std.testing.allocator.free(channel_text);
    try std.testing.expectEqualStrings("<#30>", channel_text);

    const everyone_text = try format(std.testing.allocator, .{ .kind = .everyone });
    defer std.testing.allocator.free(everyone_text);
    try std.testing.expectEqualStrings("@everyone", everyone_text);

    const here_text = try format(std.testing.allocator, .{ .kind = .here });
    defer std.testing.allocator.free(here_text);
    try std.testing.expectEqualStrings("@here", here_text);

    try std.testing.expectError(error.MissingMentionId, format(std.testing.allocator, .{ .kind = .user }));
}

test "mention scanner ignores embedded words and invalid bracket mentions" {
    const State = struct {
        count: usize = 0,

        fn onMention(self: *@This(), mention: Mention) !void {
            _ = mention;
            self.count += 1;
        }
    };

    var state = State{};
    const count = try scan("email@here not@everyone <@abc> <#>", handler(&state, State.onMention));
    try std.testing.expectEqual(@as(usize, 0), count);
    try std.testing.expectEqual(@as(usize, 0), state.count);
}

test "mention parser returns owned mention list" {
    var mentions = try parse(std.testing.allocator, "<@10> <@&20> <#30>");
    defer mentions.deinit();

    try std.testing.expectEqual(@as(usize, 3), mentions.items.len);
    try std.testing.expectEqual(MentionKind.user, mentions.items[0].kind);
    try std.testing.expectEqual(@as(u64, 10), mentions.items[0].id.?.value);
    try std.testing.expectEqual(MentionKind.role, mentions.items[1].kind);
    try std.testing.expectEqual(@as(u64, 20), mentions.items[1].id.?.value);
    try std.testing.expectEqual(MentionKind.channel, mentions.items[2].kind);
    try std.testing.expectEqual(@as(u64, 30), mentions.items[2].id.?.value);
}
