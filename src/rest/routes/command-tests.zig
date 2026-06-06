const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;

const Root = @import("../routes.zig");
const guild = Root.guild;
const guildMembers = Root.guildMembers;
const searchGuildMembers = Root.searchGuildMembers;
const editCurrentGuildMember = Root.editCurrentGuildMember;
const editCurrentUserNick = Root.editCurrentUserNick;
const addGuildMember = Root.addGuildMember;
const editGuildMember = Root.editGuildMember;
const guildBans = Root.guildBans;
const guildBan = Root.guildBan;
const guildPruneCount = Root.guildPruneCount;
const beginGuildPrune = Root.beginGuildPrune;
const createGuildBan = Root.createGuildBan;
const bulkGuildBan = Root.bulkGuildBan;
const webhook = Root.webhook;
const executeWebhookWithOptions = Root.executeWebhookWithOptions;
const editGlobalApplicationCommand = Root.editGlobalApplicationCommand;
const bulkOverwriteGuildApplicationCommands = Root.bulkOverwriteGuildApplicationCommands;
const editGuildApplicationCommand = Root.editGuildApplicationCommand;
const editApplicationCommandPermissions = Root.editApplicationCommandPermissions;
const bucketKey = Root.bucketKey;

test "member moderation routes use guild as major parameter" {
    const members_route = try guildMembers(std.testing.allocator, Snowflake.init(10), .{
        .limit = 100,
        .after = Snowflake.init(20),
    });
    defer members_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, members_route.method);
    try std.testing.expectEqualStrings("/guilds/10/members?limit=100&after=20", members_route.path);

    const members_key = try bucketKey(std.testing.allocator, members_route);
    defer std.testing.allocator.free(members_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/members:10", members_key);

    const search_route = try searchGuildMembers(std.testing.allocator, Snowflake.init(10), .{
        .query = "baris dev",
        .limit = 25,
    });
    defer search_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, search_route.method);
    try std.testing.expectEqualStrings("/guilds/10/members/search?query=baris%20dev&limit=25", search_route.path);

    const search_key = try bucketKey(std.testing.allocator, search_route);
    defer std.testing.allocator.free(search_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/members/search:10", search_key);

    const edit_route = try editGuildMember(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/guilds/10/members/20", edit_route.path);

    const edit_key = try bucketKey(std.testing.allocator, edit_route);
    defer std.testing.allocator.free(edit_key);
    try std.testing.expectEqualStrings("PATCH:/guilds/{guild_id}/members/{user_id}:10", edit_key);

    const add_route = try addGuildMember(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer add_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, add_route.method);
    try std.testing.expectEqualStrings("/guilds/10/members/20", add_route.path);

    const add_key = try bucketKey(std.testing.allocator, add_route);
    defer std.testing.allocator.free(add_key);
    try std.testing.expectEqualStrings("PUT:/guilds/{guild_id}/members/{user_id}:10", add_key);

    const edit_current_route = try editCurrentGuildMember(std.testing.allocator, Snowflake.init(10));
    defer edit_current_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_current_route.method);
    try std.testing.expectEqualStrings("/guilds/10/members/@me", edit_current_route.path);

    const edit_current_key = try bucketKey(std.testing.allocator, edit_current_route);
    defer std.testing.allocator.free(edit_current_key);
    try std.testing.expectEqualStrings("PATCH:/guilds/{guild_id}/members/@me:10", edit_current_key);

    const edit_current_nick_route = try editCurrentUserNick(std.testing.allocator, Snowflake.init(10));
    defer edit_current_nick_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_current_nick_route.method);
    try std.testing.expectEqualStrings("/guilds/10/members/@me/nick", edit_current_nick_route.path);

    const edit_current_nick_key = try bucketKey(std.testing.allocator, edit_current_nick_route);
    defer std.testing.allocator.free(edit_current_nick_key);
    try std.testing.expectEqualStrings("PATCH:/guilds/{guild_id}/members/@me/nick:10", edit_current_nick_key);

    const bans_route = try guildBans(std.testing.allocator, Snowflake.init(10), .{
        .after = Snowflake.init(15),
        .limit = 50,
    });
    defer bans_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, bans_route.method);
    try std.testing.expectEqualStrings("/guilds/10/bans?after=15&limit=50", bans_route.path);

    const bans_key = try bucketKey(std.testing.allocator, bans_route);
    defer std.testing.allocator.free(bans_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/bans:10", bans_key);

    const get_ban_route = try guildBan(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer get_ban_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, get_ban_route.method);
    try std.testing.expectEqualStrings("/guilds/10/bans/20", get_ban_route.path);

    const prune_count_route = try guildPruneCount(std.testing.allocator, Snowflake.init(10), .{
        .days = 14,
        .include_roles = &.{ Snowflake.init(30), Snowflake.init(40) },
    });
    defer prune_count_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, prune_count_route.method);
    try std.testing.expectEqualStrings("/guilds/10/prune?days=14&include_roles=30,40", prune_count_route.path);

    const prune_count_key = try bucketKey(std.testing.allocator, prune_count_route);
    defer std.testing.allocator.free(prune_count_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/prune:10", prune_count_key);

    const begin_prune_route = try beginGuildPrune(std.testing.allocator, Snowflake.init(10));
    defer begin_prune_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, begin_prune_route.method);
    try std.testing.expectEqualStrings("/guilds/10/prune", begin_prune_route.path);

    const ban_route = try createGuildBan(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer ban_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, ban_route.method);
    try std.testing.expectEqualStrings("/guilds/10/bans/20", ban_route.path);

    const ban_key = try bucketKey(std.testing.allocator, ban_route);
    defer std.testing.allocator.free(ban_key);
    try std.testing.expectEqualStrings("PUT:/guilds/{guild_id}/bans/{user_id}:10", ban_key);

    const bulk_ban_route = try bulkGuildBan(std.testing.allocator, Snowflake.init(10));
    defer bulk_ban_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, bulk_ban_route.method);
    try std.testing.expectEqualStrings("/guilds/10/bulk-ban", bulk_ban_route.path);

    const bulk_ban_key = try bucketKey(std.testing.allocator, bulk_ban_route);
    defer std.testing.allocator.free(bulk_ban_key);
    try std.testing.expectEqualStrings("POST:/guilds/{guild_id}/bulk-ban:10", bulk_ban_key);
}

test "guild command routes use guild as major parameter" {
    const route = try bulkOverwriteGuildApplicationCommands(
        std.testing.allocator,
        Snowflake.init(10),
        Snowflake.init(20),
    );
    defer route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, route.method);
    try std.testing.expectEqualStrings("/applications/10/guilds/20/commands", route.path);

    const key = try bucketKey(std.testing.allocator, route);
    defer std.testing.allocator.free(key);
    try std.testing.expectEqualStrings(
        "PUT:/applications/{application_id}/guilds/{guild_id}/commands:20",
        key,
    );
}

test "application command edit routes use expected methods and major parameters" {
    const global_route = try editGlobalApplicationCommand(
        std.testing.allocator,
        Snowflake.init(10),
        Snowflake.init(30),
    );
    defer global_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, global_route.method);
    try std.testing.expectEqualStrings("/applications/10/commands/30", global_route.path);

    const global_key = try bucketKey(std.testing.allocator, global_route);
    defer std.testing.allocator.free(global_key);
    try std.testing.expectEqualStrings(
        "PATCH:/applications/{application_id}/commands/{command_id}:10",
        global_key,
    );

    const guild_route = try editGuildApplicationCommand(
        std.testing.allocator,
        Snowflake.init(10),
        Snowflake.init(20),
        Snowflake.init(30),
    );
    defer guild_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, guild_route.method);
    try std.testing.expectEqualStrings("/applications/10/guilds/20/commands/30", guild_route.path);

    const guild_key = try bucketKey(std.testing.allocator, guild_route);
    defer std.testing.allocator.free(guild_key);
    try std.testing.expectEqualStrings(
        "PATCH:/applications/{application_id}/guilds/{guild_id}/commands/{command_id}:20",
        guild_key,
    );
}

test "application command permission routes use guild as major parameter" {
    const route = try editApplicationCommandPermissions(
        std.testing.allocator,
        Snowflake.init(10),
        Snowflake.init(20),
        Snowflake.init(30),
    );
    defer route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, route.method);
    try std.testing.expectEqualStrings("/applications/10/guilds/20/commands/30/permissions", route.path);

    const key = try bucketKey(std.testing.allocator, route);
    defer std.testing.allocator.free(key);
    try std.testing.expectEqualStrings(
        "PUT:/applications/{application_id}/guilds/{guild_id}/commands/{command_id}/permissions:20",
        key,
    );
}

test "execute webhook with options appends query without changing bucket" {
    const route = try executeWebhookWithOptions(
        std.testing.allocator,
        Snowflake.init(77),
        "tok en",
        .{ .wait = true, .thread_id = Snowflake.init(55) },
    );
    defer route.deinit(std.testing.allocator);
    try std.testing.expectEqual(.POST, route.method);
    try std.testing.expectEqualStrings("/webhooks/77/tok%20en?wait=true&thread_id=55", route.path);

    const key = try bucketKey(std.testing.allocator, route);
    defer std.testing.allocator.free(key);
    try std.testing.expectEqualStrings("POST:/webhooks/{webhook_id}/{webhook_token}:77", key);

    const plain = try executeWebhookWithOptions(std.testing.allocator, Snowflake.init(77), "tok", .{});
    defer plain.deinit(std.testing.allocator);
    try std.testing.expectEqualStrings("/webhooks/77/tok", plain.path);
}
