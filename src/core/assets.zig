const std = @import("std");
const Snowflake = @import("snowflake.zig").Snowflake;
const Types = @import("../models/types.zig");

pub const cdn_base = "https://cdn.discordapp.com";

pub const ImageFormat = enum {
    png,
    jpg,
    jpeg,
    webp,
    gif,

    pub fn extension(self: ImageFormat) []const u8 {
        return switch (self) {
            .png => "png",
            .jpg => "jpg",
            .jpeg => "jpeg",
            .webp => "webp",
            .gif => "gif",
        };
    }

    /// Parses a file-extension string into an `ImageFormat`, or null if unknown.
    pub fn fromExtension(text: []const u8) ?ImageFormat {
        if (std.mem.eql(u8, text, "png")) return .png;
        if (std.mem.eql(u8, text, "jpg")) return .jpg;
        if (std.mem.eql(u8, text, "jpeg")) return .jpeg;
        if (std.mem.eql(u8, text, "webp")) return .webp;
        if (std.mem.eql(u8, text, "gif")) return .gif;
        return null;
    }

    /// Whether this format can represent animated assets (only GIF).
    pub fn isAnimatedCapable(self: ImageFormat) bool {
        return self == .gif;
    }
};

pub const ImageOptions = struct {
    format: ?ImageFormat = null,
    size: ?u16 = null,
};

pub const min_image_size: u16 = 16;
pub const max_image_size: u16 = 4096;

/// Whether `size` is a power of two within Discord's accepted CDN range.
pub fn isValidSize(size: u16) bool {
    return size >= min_image_size and size <= max_image_size and (size & (size - 1)) == 0;
}

/// Clamps `size` into the valid CDN range and rounds up to the nearest accepted
/// power of two (16..4096).
pub fn nearestValidSize(size: u16) u16 {
    if (size <= min_image_size) return min_image_size;
    if (size >= max_image_size) return max_image_size;
    var candidate: u16 = min_image_size;
    while (candidate < size) : (candidate <<= 1) {}
    return candidate;
}

/// Whether a CDN asset hash refers to an animated image (the `a_` prefix).
pub fn isAnimatedHash(hash: []const u8) bool {
    return std.mem.startsWith(u8, hash, "a_");
}

/// Resolves the format for a hashed asset: the caller's `preferred` format when
/// set, otherwise GIF for animated hashes and PNG for static ones.
pub fn dynamicFormat(hash: []const u8, preferred: ?ImageFormat) ImageFormat {
    if (preferred) |format| return format;
    return if (isAnimatedHash(hash)) .gif else .png;
}

pub fn userAvatarUrl(
    allocator: std.mem.Allocator,
    user_id: Snowflake,
    avatar_hash: []const u8,
    options: ImageOptions,
) ![]u8 {
    return assetUrl(
        allocator,
        "/avatars/{d}/{s}.{s}",
        .{ user_id.value, avatar_hash, resolveFormat(avatar_hash, options).extension() },
        options,
    );
}

pub fn userAvatarUrlFor(allocator: std.mem.Allocator, user: Types.User, options: ImageOptions) !?[]u8 {
    const avatar_hash = user.avatar orelse return null;
    return try userAvatarUrl(allocator, user.id, avatar_hash, options);
}

pub fn defaultUserAvatarIndexFor(user: Types.User) u8 {
    if (user.discriminator) |discriminator| {
        const parsed = std.fmt.parseUnsigned(u16, discriminator, 10) catch 0;
        if (parsed != 0) return @intCast(parsed % 5);
    }
    return @intCast((user.id.value >> 22) % 6);
}

pub fn defaultUserAvatarUrl(allocator: std.mem.Allocator, index: u8) ![]u8 {
    if (index > 5) return error.InvalidAssetIndex;
    return std.fmt.allocPrint(allocator, "{s}/embed/avatars/{d}.png", .{ cdn_base, index });
}

pub fn defaultUserAvatarUrlFor(allocator: std.mem.Allocator, user: Types.User) ![]u8 {
    return defaultUserAvatarUrl(allocator, defaultUserAvatarIndexFor(user));
}

pub fn userDisplayAvatarUrlFor(allocator: std.mem.Allocator, user: Types.User, options: ImageOptions) ![]u8 {
    if (try userAvatarUrlFor(allocator, user, options)) |avatar_url| return avatar_url;
    return defaultUserAvatarUrlFor(allocator, user);
}

pub fn userBannerUrl(
    allocator: std.mem.Allocator,
    user_id: Snowflake,
    banner_hash: []const u8,
    options: ImageOptions,
) ![]u8 {
    return assetUrl(
        allocator,
        "/banners/{d}/{s}.{s}",
        .{ user_id.value, banner_hash, resolveFormat(banner_hash, options).extension() },
        options,
    );
}

pub fn userBannerUrlFor(allocator: std.mem.Allocator, user: Types.User, options: ImageOptions) !?[]u8 {
    const banner_hash = user.banner orelse return null;
    return try userBannerUrl(allocator, user.id, banner_hash, options);
}

pub fn applicationIconUrl(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    icon_hash: []const u8,
    options: ImageOptions,
) ![]u8 {
    return assetUrl(
        allocator,
        "/app-icons/{d}/{s}.{s}",
        .{ application_id.value, icon_hash, resolveFormat(icon_hash, options).extension() },
        options,
    );
}

pub fn applicationIconUrlFor(allocator: std.mem.Allocator, application: Types.Application, options: ImageOptions) !?[]u8 {
    const icon_hash = application.icon orelse return null;
    return try applicationIconUrl(allocator, application.id, icon_hash, options);
}

pub fn applicationCoverUrl(
    allocator: std.mem.Allocator,
    application_id: Snowflake,
    cover_hash: []const u8,
    options: ImageOptions,
) ![]u8 {
    return assetUrl(
        allocator,
        "/app-icons/{d}/{s}.{s}",
        .{ application_id.value, cover_hash, resolveFormat(cover_hash, options).extension() },
        options,
    );
}

pub fn applicationCoverUrlFor(allocator: std.mem.Allocator, application: Types.Application, options: ImageOptions) !?[]u8 {
    const cover_hash = application.cover_image orelse return null;
    return try applicationCoverUrl(allocator, application.id, cover_hash, options);
}

pub fn guildIconUrl(
    allocator: std.mem.Allocator,
    guild_id: Snowflake,
    icon_hash: []const u8,
    options: ImageOptions,
) ![]u8 {
    return assetUrl(
        allocator,
        "/icons/{d}/{s}.{s}",
        .{ guild_id.value, icon_hash, resolveFormat(icon_hash, options).extension() },
        options,
    );
}

pub fn guildIconUrlFor(allocator: std.mem.Allocator, guild: Types.Guild, options: ImageOptions) !?[]u8 {
    const icon_hash = guild.icon orelse return null;
    return try guildIconUrl(allocator, guild.id, icon_hash, options);
}

pub fn guildBannerUrl(
    allocator: std.mem.Allocator,
    guild_id: Snowflake,
    banner_hash: []const u8,
    options: ImageOptions,
) ![]u8 {
    return assetUrl(
        allocator,
        "/banners/{d}/{s}.{s}",
        .{ guild_id.value, banner_hash, resolveFormat(banner_hash, options).extension() },
        options,
    );
}

pub fn guildBannerUrlFor(allocator: std.mem.Allocator, guild: Types.Guild, options: ImageOptions) !?[]u8 {
    const banner_hash = guild.banner orelse return null;
    return try guildBannerUrl(allocator, guild.id, banner_hash, options);
}

pub fn guildSplashUrl(
    allocator: std.mem.Allocator,
    guild_id: Snowflake,
    splash_hash: []const u8,
    options: ImageOptions,
) ![]u8 {
    return assetUrl(
        allocator,
        "/splashes/{d}/{s}.{s}",
        .{ guild_id.value, splash_hash, resolveFormat(splash_hash, options).extension() },
        options,
    );
}

pub fn guildSplashUrlFor(allocator: std.mem.Allocator, guild: Types.Guild, options: ImageOptions) !?[]u8 {
    const splash_hash = guild.splash orelse return null;
    return try guildSplashUrl(allocator, guild.id, splash_hash, options);
}

pub fn guildDiscoverySplashUrl(
    allocator: std.mem.Allocator,
    guild_id: Snowflake,
    splash_hash: []const u8,
    options: ImageOptions,
) ![]u8 {
    return assetUrl(
        allocator,
        "/discovery-splashes/{d}/{s}.{s}",
        .{ guild_id.value, splash_hash, resolveFormat(splash_hash, options).extension() },
        options,
    );
}

pub fn guildDiscoverySplashUrlFor(allocator: std.mem.Allocator, guild: Types.Guild, options: ImageOptions) !?[]u8 {
    const splash_hash = guild.discovery_splash orelse return null;
    return try guildDiscoverySplashUrl(allocator, guild.id, splash_hash, options);
}

pub fn guildMemberAvatarUrl(
    allocator: std.mem.Allocator,
    guild_id: Snowflake,
    user_id: Snowflake,
    avatar_hash: []const u8,
    options: ImageOptions,
) ![]u8 {
    return assetUrl(
        allocator,
        "/guilds/{d}/users/{d}/avatars/{s}.{s}",
        .{ guild_id.value, user_id.value, avatar_hash, resolveFormat(avatar_hash, options).extension() },
        options,
    );
}

pub fn guildMemberAvatarUrlFor(
    allocator: std.mem.Allocator,
    guild_id: Snowflake,
    member: Types.GuildMember,
    options: ImageOptions,
) !?[]u8 {
    const avatar_hash = member.avatar orelse return null;
    const user = member.user orelse return null;
    return try guildMemberAvatarUrl(allocator, guild_id, user.id, avatar_hash, options);
}

pub fn roleIconUrl(
    allocator: std.mem.Allocator,
    role_id: Snowflake,
    icon_hash: []const u8,
    options: ImageOptions,
) ![]u8 {
    return assetUrl(
        allocator,
        "/role-icons/{d}/{s}.{s}",
        .{ role_id.value, icon_hash, resolveFormat(icon_hash, options).extension() },
        options,
    );
}

pub fn roleIconUrlFor(allocator: std.mem.Allocator, role: Types.Role, options: ImageOptions) !?[]u8 {
    const icon_hash = role.icon orelse return null;
    return try roleIconUrl(allocator, role.id, icon_hash, options);
}

pub fn teamIconUrl(
    allocator: std.mem.Allocator,
    team_id: Snowflake,
    icon_hash: []const u8,
    options: ImageOptions,
) ![]u8 {
    return assetUrl(
        allocator,
        "/team-icons/{d}/{s}.{s}",
        .{ team_id.value, icon_hash, resolveFormat(icon_hash, options).extension() },
        options,
    );
}

pub fn teamIconUrlFor(allocator: std.mem.Allocator, team: Types.Team, options: ImageOptions) !?[]u8 {
    const icon_hash = team.icon orelse return null;
    return try teamIconUrl(allocator, team.id, icon_hash, options);
}

pub fn emojiUrl(
    allocator: std.mem.Allocator,
    emoji_id: Snowflake,
    options: ImageOptions,
) ![]u8 {
    const format = options.format orelse .png;
    return assetUrl(
        allocator,
        "/emojis/{d}.{s}",
        .{ emoji_id.value, format.extension() },
        options,
    );
}

pub fn stickerUrl(allocator: std.mem.Allocator, sticker_id: Snowflake, format: ImageFormat) ![]u8 {
    return std.fmt.allocPrint(allocator, "{s}/stickers/{d}.{s}", .{
        cdn_base,
        sticker_id.value,
        format.extension(),
    });
}

fn resolveFormat(hash: []const u8, options: ImageOptions) ImageFormat {
    return dynamicFormat(hash, options.format);
}

fn assetUrl(allocator: std.mem.Allocator, comptime path_format: []const u8, args: anytype, options: ImageOptions) ![]u8 {
    if (options.size) |size| try validateSize(size);

    var path = std.Io.Writer.Allocating.init(allocator);
    defer path.deinit();
    try path.writer.writeAll(cdn_base);
    try path.writer.print(path_format, args);
    if (options.size) |size| try path.writer.print("?size={d}", .{size});
    return path.toOwnedSlice();
}

fn validateSize(size: u16) !void {
    if (!isValidSize(size)) return error.InvalidAssetSize;
}

test "asset urls use expected cdn paths formats and sizes" {
    const avatar = try userAvatarUrl(std.testing.allocator, Snowflake.init(10), "hash", .{ .size = 128 });
    defer std.testing.allocator.free(avatar);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/avatars/10/hash.png?size=128", avatar);

    const animated = try userAvatarUrl(std.testing.allocator, Snowflake.init(10), "a_hash", .{});
    defer std.testing.allocator.free(animated);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/avatars/10/a_hash.gif", animated);

    const icon = try guildIconUrl(std.testing.allocator, Snowflake.init(20), "icon", .{ .format = .webp });
    defer std.testing.allocator.free(icon);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/icons/20/icon.webp", icon);

    const banner = try guildBannerUrl(std.testing.allocator, Snowflake.init(20), "banner", .{ .size = 1024 });
    defer std.testing.allocator.free(banner);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/banners/20/banner.png?size=1024", banner);

    const splash = try guildSplashUrl(std.testing.allocator, Snowflake.init(20), "splash", .{});
    defer std.testing.allocator.free(splash);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/splashes/20/splash.png", splash);

    const discovery_splash = try guildDiscoverySplashUrl(std.testing.allocator, Snowflake.init(20), "a_discovery", .{});
    defer std.testing.allocator.free(discovery_splash);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/discovery-splashes/20/a_discovery.gif", discovery_splash);

    const user_banner = try userBannerUrl(std.testing.allocator, Snowflake.init(10), "a_banner", .{});
    defer std.testing.allocator.free(user_banner);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/banners/10/a_banner.gif", user_banner);

    const app_icon = try applicationIconUrl(std.testing.allocator, Snowflake.init(30), "app_icon", .{ .size = 512 });
    defer std.testing.allocator.free(app_icon);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/app-icons/30/app_icon.png?size=512", app_icon);

    const app_cover = try applicationCoverUrl(std.testing.allocator, Snowflake.init(30), "cover", .{});
    defer std.testing.allocator.free(app_cover);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/app-icons/30/cover.png", app_cover);

    const member_avatar = try guildMemberAvatarUrl(std.testing.allocator, Snowflake.init(40), Snowflake.init(50), "a_member", .{});
    defer std.testing.allocator.free(member_avatar);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/guilds/40/users/50/avatars/a_member.gif", member_avatar);

    const role_icon = try roleIconUrl(std.testing.allocator, Snowflake.init(60), "role_icon", .{ .format = .webp });
    defer std.testing.allocator.free(role_icon);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/role-icons/60/role_icon.webp", role_icon);

    const team_icon = try teamIconUrl(std.testing.allocator, Snowflake.init(80), "a_team", .{});
    defer std.testing.allocator.free(team_icon);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/team-icons/80/a_team.gif", team_icon);
}

test "asset urls support default avatars emoji stickers and validation" {
    const default_avatar = try defaultUserAvatarUrl(std.testing.allocator, 3);
    defer std.testing.allocator.free(default_avatar);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/embed/avatars/3.png", default_avatar);

    const legacy_user = Types.User{ .id = Snowflake.init(10), .username = "legacy", .discriminator = "1337" };
    try std.testing.expectEqual(@as(u8, 2), defaultUserAvatarIndexFor(legacy_user));
    const legacy_default = try defaultUserAvatarUrlFor(std.testing.allocator, legacy_user);
    defer std.testing.allocator.free(legacy_default);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/embed/avatars/2.png", legacy_default);

    const migrated_user = Types.User{ .id = Snowflake.init(25_165_824), .username = "migrated", .discriminator = "0" };
    try std.testing.expectEqual(@as(u8, 0), defaultUserAvatarIndexFor(migrated_user));
    const migrated_default = try defaultUserAvatarUrlFor(std.testing.allocator, migrated_user);
    defer std.testing.allocator.free(migrated_default);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/embed/avatars/0.png", migrated_default);

    const custom_display = try userDisplayAvatarUrlFor(
        std.testing.allocator,
        .{ .id = Snowflake.init(10), .username = "custom", .avatar = "a_hash" },
        .{},
    );
    defer std.testing.allocator.free(custom_display);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/avatars/10/a_hash.gif", custom_display);

    const default_display = try userDisplayAvatarUrlFor(std.testing.allocator, legacy_user, .{ .size = 128 });
    defer std.testing.allocator.free(default_display);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/embed/avatars/2.png", default_display);

    const emoji = try emojiUrl(std.testing.allocator, Snowflake.init(30), .{ .format = .gif, .size = 64 });
    defer std.testing.allocator.free(emoji);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/emojis/30.gif?size=64", emoji);

    const sticker = try stickerUrl(std.testing.allocator, Snowflake.init(40), .png);
    defer std.testing.allocator.free(sticker);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/stickers/40.png", sticker);

    try std.testing.expectError(error.InvalidAssetSize, emojiUrl(std.testing.allocator, Snowflake.init(30), .{ .size = 15 }));
    try std.testing.expectError(error.InvalidAssetIndex, defaultUserAvatarUrl(std.testing.allocator, 6));
}

test "asset urls support user and guild model helpers" {
    const user = Types.User{
        .id = Snowflake.init(10),
        .username = "zig",
        .avatar = "avatar",
        .banner = "banner",
    };
    const avatar = (try userAvatarUrlFor(std.testing.allocator, user, .{ .size = 256 })).?;
    defer std.testing.allocator.free(avatar);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/avatars/10/avatar.png?size=256", avatar);

    const user_banner = (try userBannerUrlFor(std.testing.allocator, user, .{})).?;
    defer std.testing.allocator.free(user_banner);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/banners/10/banner.png", user_banner);

    const guild = Types.Guild{
        .id = Snowflake.init(20),
        .name = "guild",
        .icon = "icon",
        .splash = "splash",
        .discovery_splash = "discovery",
        .banner = "a_banner",
    };
    const icon = (try guildIconUrlFor(std.testing.allocator, guild, .{ .format = .webp })).?;
    defer std.testing.allocator.free(icon);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/icons/20/icon.webp", icon);

    const guild_splash = (try guildSplashUrlFor(std.testing.allocator, guild, .{})).?;
    defer std.testing.allocator.free(guild_splash);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/splashes/20/splash.png", guild_splash);

    const discovery_splash = (try guildDiscoverySplashUrlFor(std.testing.allocator, guild, .{})).?;
    defer std.testing.allocator.free(discovery_splash);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/discovery-splashes/20/discovery.png", discovery_splash);

    const guild_banner = (try guildBannerUrlFor(std.testing.allocator, guild, .{})).?;
    defer std.testing.allocator.free(guild_banner);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/banners/20/a_banner.gif", guild_banner);

    const application = Types.Application{
        .id = Snowflake.init(50),
        .name = "app",
        .icon = "app_icon",
        .cover_image = "cover",
    };
    const app_icon = (try applicationIconUrlFor(std.testing.allocator, application, .{ .size = 128 })).?;
    defer std.testing.allocator.free(app_icon);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/app-icons/50/app_icon.png?size=128", app_icon);

    const app_cover = (try applicationCoverUrlFor(std.testing.allocator, application, .{})).?;
    defer std.testing.allocator.free(app_cover);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/app-icons/50/cover.png", app_cover);

    const member = Types.GuildMember{
        .user = .{ .id = Snowflake.init(60), .username = "member" },
        .avatar = "member_avatar",
    };
    const member_avatar = (try guildMemberAvatarUrlFor(std.testing.allocator, Snowflake.init(20), member, .{})).?;
    defer std.testing.allocator.free(member_avatar);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/guilds/20/users/60/avatars/member_avatar.png", member_avatar);

    const role = Types.Role{ .id = Snowflake.init(70), .name = "role", .icon = "a_role" };
    const role_icon = (try roleIconUrlFor(std.testing.allocator, role, .{})).?;
    defer std.testing.allocator.free(role_icon);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/role-icons/70/a_role.gif", role_icon);

    const team = Types.Team{
        .id = Snowflake.init(75),
        .name = "team",
        .icon = "team_icon",
        .owner_user_id = Snowflake.init(10),
    };
    const team_icon = (try teamIconUrlFor(std.testing.allocator, team, .{})).?;
    defer std.testing.allocator.free(team_icon);
    try std.testing.expectEqualStrings("https://cdn.discordapp.com/team-icons/75/team_icon.png", team_icon);

    try std.testing.expect(try userAvatarUrlFor(std.testing.allocator, .{ .id = Snowflake.init(30), .username = "plain" }, .{}) == null);
    try std.testing.expect(try guildIconUrlFor(std.testing.allocator, .{ .id = Snowflake.init(40), .name = "plain" }, .{}) == null);
    try std.testing.expect(try guildSplashUrlFor(std.testing.allocator, .{ .id = Snowflake.init(41), .name = "plain" }, .{}) == null);
    try std.testing.expect(try guildDiscoverySplashUrlFor(std.testing.allocator, .{ .id = Snowflake.init(42), .name = "plain" }, .{}) == null);
    try std.testing.expect(try applicationIconUrlFor(std.testing.allocator, .{ .id = Snowflake.init(80), .name = "plain" }, .{}) == null);
    try std.testing.expect(try applicationCoverUrlFor(std.testing.allocator, .{ .id = Snowflake.init(81), .name = "plain" }, .{}) == null);
    try std.testing.expect(try guildMemberAvatarUrlFor(std.testing.allocator, Snowflake.init(20), .{}, .{}) == null);
    try std.testing.expect(try roleIconUrlFor(std.testing.allocator, .{ .id = Snowflake.init(90), .name = "plain" }, .{}) == null);
    try std.testing.expect(try teamIconUrlFor(std.testing.allocator, .{ .id = Snowflake.init(91), .name = "plain", .owner_user_id = Snowflake.init(1) }, .{}) == null);
}

test "asset format and size validation helpers" {
    try std.testing.expect(isValidSize(16));
    try std.testing.expect(isValidSize(4096));
    try std.testing.expect(isValidSize(128));
    try std.testing.expect(!isValidSize(100));
    try std.testing.expect(!isValidSize(8));
    try std.testing.expect(!isValidSize(8192));

    try std.testing.expectEqual(@as(u16, 16), nearestValidSize(1));
    try std.testing.expectEqual(@as(u16, 128), nearestValidSize(100));
    try std.testing.expectEqual(@as(u16, 128), nearestValidSize(128));
    try std.testing.expectEqual(@as(u16, 4096), nearestValidSize(9000));

    try std.testing.expect(isAnimatedHash("a_abc"));
    try std.testing.expect(!isAnimatedHash("abc"));

    try std.testing.expectEqual(ImageFormat.gif, dynamicFormat("a_abc", null));
    try std.testing.expectEqual(ImageFormat.png, dynamicFormat("abc", null));
    try std.testing.expectEqual(ImageFormat.webp, dynamicFormat("a_abc", .webp));

    try std.testing.expectEqual(ImageFormat.png, ImageFormat.fromExtension("png").?);
    try std.testing.expect(ImageFormat.fromExtension("bmp") == null);
    try std.testing.expect(ImageFormat.gif.isAnimatedCapable());
    try std.testing.expect(!ImageFormat.png.isAnimatedCapable());
}
