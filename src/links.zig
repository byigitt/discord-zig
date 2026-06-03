const std = @import("std");
const Snowflake = @import("snowflake.zig").Snowflake;

pub const MessageLink = struct {
    guild_id: ?Snowflake = null,
    channel_id: Snowflake,
    message_id: Snowflake,
};

pub const ChannelLink = struct {
    guild_id: ?Snowflake = null,
    channel_id: Snowflake,
};

pub const ApplicationIntegrationType = enum(u8) {
    guild_install = 0,
    user_install = 1,
};

pub const AuthorizationUrlOptions = struct {
    client_id: Snowflake,
    scopes: []const []const u8,
    permissions: ?u64 = null,
    guild_id: ?Snowflake = null,
    disable_guild_select: ?bool = null,
    redirect_uri: ?[]const u8 = null,
    response_type: ?[]const u8 = null,
    state: ?[]const u8 = null,
    prompt: ?[]const u8 = null,
    integration_type: ?ApplicationIntegrationType = null,
};

pub fn messageLink(allocator: std.mem.Allocator, link: MessageLink) ![]u8 {
    if (link.guild_id) |guild_id| {
        return std.fmt.allocPrint(
            allocator,
            "https://discord.com/channels/{d}/{d}/{d}",
            .{ guild_id.value, link.channel_id.value, link.message_id.value },
        );
    }
    return std.fmt.allocPrint(
        allocator,
        "https://discord.com/channels/@me/{d}/{d}",
        .{ link.channel_id.value, link.message_id.value },
    );
}

pub fn messageUrl(
    allocator: std.mem.Allocator,
    guild_id: ?Snowflake,
    channel_id: Snowflake,
    message_id: Snowflake,
) ![]u8 {
    return messageLink(allocator, .{ .guild_id = guild_id, .channel_id = channel_id, .message_id = message_id });
}

pub fn channelLink(allocator: std.mem.Allocator, link: ChannelLink) ![]u8 {
    if (link.guild_id) |guild_id| {
        return std.fmt.allocPrint(
            allocator,
            "https://discord.com/channels/{d}/{d}",
            .{ guild_id.value, link.channel_id.value },
        );
    }
    return std.fmt.allocPrint(allocator, "https://discord.com/channels/@me/{d}", .{link.channel_id.value});
}

pub fn channelUrl(allocator: std.mem.Allocator, guild_id: ?Snowflake, channel_id: Snowflake) ![]u8 {
    return channelLink(allocator, .{ .guild_id = guild_id, .channel_id = channel_id });
}

pub fn inviteLink(allocator: std.mem.Allocator, code: []const u8) ![]u8 {
    if (code.len == 0) return error.InvalidInviteCode;
    return std.fmt.allocPrint(allocator, "https://discord.gg/{s}", .{code});
}

pub fn inviteUrl(allocator: std.mem.Allocator, code: []const u8) ![]u8 {
    return inviteLink(allocator, code);
}

pub fn authorizationUrl(allocator: std.mem.Allocator, options: AuthorizationUrlOptions) ![]u8 {
    if (options.scopes.len == 0) return error.MissingOAuthScopes;

    var out = std.Io.Writer.Allocating.init(allocator);
    errdefer out.deinit();

    try out.writer.print("https://discord.com/oauth2/authorize?client_id={d}&scope=", .{options.client_id.value});
    for (options.scopes, 0..) |scope, index| {
        if (index != 0) try out.writer.writeAll("%20");
        try writeQueryStringValue(scope, &out.writer);
    }
    if (options.permissions) |permissions| try out.writer.print("&permissions={d}", .{permissions});
    if (options.guild_id) |guild_id| try out.writer.print("&guild_id={d}", .{guild_id.value});
    if (options.disable_guild_select) |disable| {
        try out.writer.writeAll("&disable_guild_select=");
        try out.writer.writeAll(if (disable) "true" else "false");
    }
    if (options.redirect_uri) |redirect_uri| {
        try out.writer.writeAll("&redirect_uri=");
        try writeQueryStringValue(redirect_uri, &out.writer);
    }
    if (options.response_type) |response_type| {
        try out.writer.writeAll("&response_type=");
        try writeQueryStringValue(response_type, &out.writer);
    }
    if (options.state) |state| {
        try out.writer.writeAll("&state=");
        try writeQueryStringValue(state, &out.writer);
    }
    if (options.prompt) |prompt| {
        try out.writer.writeAll("&prompt=");
        try writeQueryStringValue(prompt, &out.writer);
    }
    if (options.integration_type) |integration_type| {
        try out.writer.print("&integration_type={d}", .{@intFromEnum(integration_type)});
    }

    return out.toOwnedSlice();
}

pub fn parseMessageLink(value: []const u8) !MessageLink {
    const path = try discordPath(value);
    var parts = std.mem.splitScalar(u8, path, '/');

    if (!eqlNext(&parts, "channels")) return error.InvalidDiscordLink;
    const guild_id = try guildPathId(parts.next() orelse return error.InvalidDiscordLink);
    const channel_id = try Snowflake.parse(parts.next() orelse return error.InvalidDiscordLink);
    const message_id = try Snowflake.parse(stripSuffix(parts.next() orelse return error.InvalidDiscordLink));
    if (parts.next() != null) return error.InvalidDiscordLink;

    return .{
        .guild_id = guild_id,
        .channel_id = channel_id,
        .message_id = message_id,
    };
}

pub fn parseChannelLink(value: []const u8) !ChannelLink {
    const path = try discordPath(value);
    var parts = std.mem.splitScalar(u8, path, '/');

    if (!eqlNext(&parts, "channels")) return error.InvalidDiscordLink;
    const guild_id = try guildPathId(parts.next() orelse return error.InvalidDiscordLink);
    const channel_id = try Snowflake.parse(stripSuffix(parts.next() orelse return error.InvalidDiscordLink));
    if (parts.next() != null) return error.InvalidDiscordLink;

    return .{
        .guild_id = guild_id,
        .channel_id = channel_id,
    };
}

pub fn parseInviteCode(value: []const u8) ![]const u8 {
    const normalized = stripScheme(value);
    if (std.mem.startsWith(u8, normalized, "discord.gg/")) {
        return firstPathSegment(normalized["discord.gg/".len..]);
    }
    if (std.mem.startsWith(u8, normalized, "www.discord.gg/")) {
        return firstPathSegment(normalized["www.discord.gg/".len..]);
    }

    const path = try discordPath(value);
    var parts = std.mem.splitScalar(u8, path, '/');
    if (!eqlNext(&parts, "invite")) return error.InvalidDiscordLink;
    return firstPathSegment(parts.next() orelse return error.InvalidDiscordLink);
}

fn discordPath(value: []const u8) ![]const u8 {
    const normalized = stripScheme(value);
    const host_end = std.mem.indexOfScalar(u8, normalized, '/') orelse return error.InvalidDiscordLink;
    const host = normalized[0..host_end];
    if (!isDiscordHost(host)) return error.InvalidDiscordLink;
    return normalized[host_end + 1 ..];
}

fn stripScheme(value: []const u8) []const u8 {
    if (std.mem.startsWith(u8, value, "https://")) return value["https://".len..];
    if (std.mem.startsWith(u8, value, "http://")) return value["http://".len..];
    return value;
}

fn isDiscordHost(host: []const u8) bool {
    return std.mem.eql(u8, host, "discord.com") or
        std.mem.eql(u8, host, "www.discord.com") or
        std.mem.eql(u8, host, "canary.discord.com") or
        std.mem.eql(u8, host, "ptb.discord.com");
}

fn guildPathId(value: []const u8) !?Snowflake {
    if (std.mem.eql(u8, value, "@me")) return null;
    return try Snowflake.parse(value);
}

fn eqlNext(parts: *std.mem.SplitIterator(u8, .scalar), expected: []const u8) bool {
    const next = parts.next() orelse return false;
    return std.mem.eql(u8, next, expected);
}

fn stripSuffix(value: []const u8) []const u8 {
    const query = std.mem.indexOfScalar(u8, value, '?') orelse value.len;
    const hash = std.mem.indexOfScalar(u8, value, '#') orelse value.len;
    return value[0..@min(query, hash)];
}

fn firstPathSegment(value: []const u8) ![]const u8 {
    const stripped = stripSuffix(value);
    const slash = std.mem.indexOfScalar(u8, stripped, '/') orelse stripped.len;
    const code = stripped[0..slash];
    if (code.len == 0) return error.InvalidDiscordLink;
    return code;
}

fn writeQueryStringValue(value: []const u8, writer: anytype) !void {
    const hex = "0123456789ABCDEF";
    for (value) |byte| {
        if (std.ascii.isAlphanumeric(byte) or byte == '-' or byte == '_' or byte == '.' or byte == '~') {
            try writer.writeByte(byte);
        } else {
            try writer.writeByte('%');
            try writer.writeByte(hex[byte >> 4]);
            try writer.writeByte(hex[byte & 0x0f]);
        }
    }
}

test "parse message links for guild and dm channels" {
    const guild = try parseMessageLink("https://discord.com/channels/10/20/30");
    try std.testing.expectEqual(@as(u64, 10), guild.guild_id.?.value);
    try std.testing.expectEqual(@as(u64, 20), guild.channel_id.value);
    try std.testing.expectEqual(@as(u64, 30), guild.message_id.value);

    const dm = try parseMessageLink("https://ptb.discord.com/channels/@me/40/50?jump=true");
    try std.testing.expect(dm.guild_id == null);
    try std.testing.expectEqual(@as(u64, 40), dm.channel_id.value);
    try std.testing.expectEqual(@as(u64, 50), dm.message_id.value);
}

test "build message channel and invite links" {
    const guild_message = try messageLink(std.testing.allocator, .{
        .guild_id = Snowflake.init(10),
        .channel_id = Snowflake.init(20),
        .message_id = Snowflake.init(30),
    });
    defer std.testing.allocator.free(guild_message);
    try std.testing.expectEqualStrings("https://discord.com/channels/10/20/30", guild_message);

    const dm_message = try messageUrl(std.testing.allocator, null, Snowflake.init(40), Snowflake.init(50));
    defer std.testing.allocator.free(dm_message);
    try std.testing.expectEqualStrings("https://discord.com/channels/@me/40/50", dm_message);

    const guild_channel = try channelLink(std.testing.allocator, .{
        .guild_id = Snowflake.init(10),
        .channel_id = Snowflake.init(20),
    });
    defer std.testing.allocator.free(guild_channel);
    try std.testing.expectEqualStrings("https://discord.com/channels/10/20", guild_channel);

    const dm_channel = try channelUrl(std.testing.allocator, null, Snowflake.init(40));
    defer std.testing.allocator.free(dm_channel);
    try std.testing.expectEqualStrings("https://discord.com/channels/@me/40", dm_channel);

    const invite = try inviteLink(std.testing.allocator, "abc123");
    defer std.testing.allocator.free(invite);
    try std.testing.expectEqualStrings("https://discord.gg/abc123", invite);

    const invite_alias = try inviteUrl(std.testing.allocator, "xyz");
    defer std.testing.allocator.free(invite_alias);
    try std.testing.expectEqualStrings("https://discord.gg/xyz", invite_alias);
    try std.testing.expectError(error.InvalidInviteCode, inviteLink(std.testing.allocator, ""));
}

test "parse channel links" {
    const channel = try parseChannelLink("discord.com/channels/10/20");
    try std.testing.expectEqual(@as(u64, 10), channel.guild_id.?.value);
    try std.testing.expectEqual(@as(u64, 20), channel.channel_id.value);
}

test "parse invite codes from supported links" {
    try std.testing.expectEqualStrings("abc123", try parseInviteCode("https://discord.gg/abc123"));
    try std.testing.expectEqualStrings("xyz", try parseInviteCode("discord.com/invite/xyz?source=bot"));
}

test "authorization URL builds bot invite parameters" {
    const url = try authorizationUrl(std.testing.allocator, .{
        .client_id = Snowflake.init(10),
        .scopes = &.{ "bot", "applications.commands" },
        .permissions = 2048,
        .guild_id = Snowflake.init(20),
        .disable_guild_select = true,
        .integration_type = .guild_install,
    });
    defer std.testing.allocator.free(url);

    try std.testing.expectEqualStrings(
        "https://discord.com/oauth2/authorize?client_id=10&scope=bot%20applications.commands&permissions=2048&guild_id=20&disable_guild_select=true&integration_type=0",
        url,
    );
}

test "authorization URL percent-encodes redirect state and prompt" {
    const url = try authorizationUrl(std.testing.allocator, .{
        .client_id = Snowflake.init(10),
        .scopes = &.{ "identify", "guilds.join" },
        .redirect_uri = "https://example.com/callback path",
        .response_type = "code",
        .state = "csrf token",
        .prompt = "consent",
        .integration_type = .user_install,
    });
    defer std.testing.allocator.free(url);

    try std.testing.expectEqualStrings(
        "https://discord.com/oauth2/authorize?client_id=10&scope=identify%20guilds.join&redirect_uri=https%3A%2F%2Fexample.com%2Fcallback%20path&response_type=code&state=csrf%20token&prompt=consent&integration_type=1",
        url,
    );
}

test "authorization URL requires at least one scope" {
    try std.testing.expectError(error.MissingOAuthScopes, authorizationUrl(std.testing.allocator, .{
        .client_id = Snowflake.init(10),
        .scopes = &.{},
    }));
}

test "reject unsupported discord links" {
    try std.testing.expectError(error.InvalidDiscordLink, parseMessageLink("https://example.com/channels/10/20/30"));
    try std.testing.expectError(error.InvalidDiscordLink, parseInviteCode("https://discord.com/channels/10/20"));
}
