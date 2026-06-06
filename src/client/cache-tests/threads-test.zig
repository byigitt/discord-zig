const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Types = @import("../../models/types.zig");
const Gateway = @import("../../gateway/protocol.zig");
const Interactions = @import("../../interactions/mod.zig");
const Permissions = @import("../../core/permissions.zig");
const Collection = @import("../../core/collection.zig").Collection;

const Root = @import("../cache.zig");
const Cache = Root.Cache;

test "cache updates voice channel info dispatches" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    try cache.putChannel(.{
        .id = Snowflake.init(20),
        .type = .guild_voice,
        .guild_id = Snowflake.init(10),
        .name = "voice",
    });
    try cache.putChannel(.{
        .id = Snowflake.init(21),
        .type = .guild_voice,
        .guild_id = Snowflake.init(10),
        .name = "voice-2",
    });

    var info = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"CHANNEL_INFO\",\"d\":{\"guild_id\":\"10\",\"channels\":[{\"id\":\"20\",\"status\":\"Planning\",\"voice_start_time\":1780000000},{\"id\":\"21\",\"voice_start_time\":1780000100},{\"id\":\"22\",\"status\":\"Unknown\"}]}}",
    );
    defer info.deinit();
    try cache.applyDispatch(info);

    const first = cache.getChannel(Snowflake.init(20)).?;
    try std.testing.expectEqualStrings("Planning", first.status.?);
    try std.testing.expectEqual(@as(i64, 1780000000), first.voice_start_time.?);

    const second = cache.getChannel(Snowflake.init(21)).?;
    try std.testing.expect(second.status == null);
    try std.testing.expectEqual(@as(i64, 1780000100), second.voice_start_time.?);
    try std.testing.expect(cache.getChannel(Snowflake.init(22)) == null);

    var status_update = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"VOICE_CHANNEL_STATUS_UPDATE\",\"d\":{\"id\":\"20\",\"guild_id\":\"10\",\"status\":null}}",
    );
    defer status_update.deinit();
    try cache.applyDispatch(status_update);
    try std.testing.expect(cache.getChannel(Snowflake.init(20)).?.status == null);
    try std.testing.expectEqual(@as(i64, 1780000000), cache.getChannel(Snowflake.init(20)).?.voice_start_time.?);

    var start_time_update = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"VOICE_CHANNEL_START_TIME_UPDATE\",\"d\":{\"id\":\"20\",\"guild_id\":\"10\",\"voice_start_time\":null}}",
    );
    defer start_time_update.deinit();
    try cache.applyDispatch(start_time_update);
    try std.testing.expect(cache.getChannel(Snowflake.init(20)).?.voice_start_time == null);

    var unknown = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":4,\"t\":\"VOICE_CHANNEL_STATUS_UPDATE\",\"d\":{\"id\":\"22\",\"guild_id\":\"10\",\"status\":\"Ignored\"}}",
    );
    defer unknown.deinit();
    try cache.applyDispatch(unknown);
    try std.testing.expect(cache.getChannel(Snowflake.init(22)) == null);
}

test "cache handles thread create update and delete dispatches" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var create = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"THREAD_CREATE\",\"d\":{\"id\":\"30\",\"type\":11,\"guild_id\":\"10\",\"name\":\"debug\",\"parent_id\":\"20\",\"rate_limit_per_user\":10,\"thread_metadata\":{\"archived\":false,\"auto_archive_duration\":1440,\"archive_timestamp\":\"2026-06-02T00:00:00.000Z\",\"locked\":false,\"invitable\":true,\"create_timestamp\":\"2026-06-01T00:00:00.000Z\"},\"applied_tags\":[\"40\",\"50\"]}}",
    );
    defer create.deinit();
    try cache.applyDispatch(create);

    const created = cache.getChannel(Snowflake.init(30)).?;
    try std.testing.expectEqual(Types.ChannelType.public_thread, created.type);
    try std.testing.expectEqualStrings("debug", created.name.?);
    try std.testing.expectEqual(@as(u64, 20), created.parent_id.?.value);
    try std.testing.expectEqual(@as(u16, 10), created.rate_limit_per_user.?);
    try std.testing.expect(!created.thread_metadata.?.archived);
    try std.testing.expectEqual(@as(u16, 1440), created.thread_metadata.?.auto_archive_duration);
    try std.testing.expectEqualStrings("2026-06-02T00:00:00.000Z", created.thread_metadata.?.archive_timestamp.?);
    try std.testing.expect(!created.thread_metadata.?.locked);
    try std.testing.expect(created.thread_metadata.?.invitable.?);
    try std.testing.expectEqualStrings("2026-06-01T00:00:00.000Z", created.thread_metadata.?.create_timestamp.?);
    try std.testing.expectEqual(@as(usize, 2), created.applied_tags.len);
    try std.testing.expectEqual(@as(u64, 40), created.applied_tags[0].value);
    try std.testing.expectEqual(@as(u64, 50), created.applied_tags[1].value);

    var update = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"THREAD_UPDATE\",\"d\":{\"id\":\"30\",\"type\":11,\"guild_id\":\"10\",\"name\":\"debug-renamed\",\"thread_metadata\":{\"archived\":true,\"auto_archive_duration\":60,\"archive_timestamp\":\"2026-06-02T01:00:00.000Z\",\"locked\":true},\"applied_tags\":[]}}",
    );
    defer update.deinit();
    try cache.applyDispatch(update);

    const updated_thread = cache.getChannel(Snowflake.init(30)).?;
    try std.testing.expectEqualStrings("debug-renamed", updated_thread.name.?);
    try std.testing.expect(updated_thread.thread_metadata.?.archived);
    try std.testing.expectEqual(@as(u16, 60), updated_thread.thread_metadata.?.auto_archive_duration);
    try std.testing.expectEqualStrings("2026-06-02T01:00:00.000Z", updated_thread.thread_metadata.?.archive_timestamp.?);
    try std.testing.expect(updated_thread.thread_metadata.?.locked);
    try std.testing.expect(updated_thread.thread_metadata.?.invitable == null);
    try std.testing.expectEqual(@as(usize, 0), updated_thread.applied_tags.len);

    var delete = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"THREAD_DELETE\",\"d\":{\"id\":\"30\",\"type\":11,\"guild_id\":\"10\",\"name\":\"debug-renamed\"}}",
    );
    defer delete.deinit();
    try cache.applyDispatch(delete);

    try std.testing.expect(cache.getChannel(Snowflake.init(30)) == null);
}

test "cache applies thread list sync scope" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    try cache.putChannel(.{ .id = Snowflake.init(30), .type = .public_thread, .guild_id = Snowflake.init(10), .parent_id = Snowflake.init(20), .name = "stale" });
    try cache.putChannel(.{ .id = Snowflake.init(31), .type = .private_thread, .guild_id = Snowflake.init(10), .parent_id = Snowflake.init(21), .name = "keep-other-parent" });
    try cache.putChannel(.{ .id = Snowflake.init(32), .type = .announcement_thread, .guild_id = Snowflake.init(11), .parent_id = Snowflake.init(20), .name = "keep-other-guild" });

    var sync = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"THREAD_LIST_SYNC\",\"d\":{\"guild_id\":\"10\",\"channel_ids\":[\"20\"],\"threads\":[{\"id\":\"33\",\"type\":11,\"parent_id\":\"20\",\"name\":\"fresh\",\"thread_metadata\":{\"archived\":false,\"auto_archive_duration\":1440,\"archive_timestamp\":\"2026-06-02T00:00:00.000Z\",\"locked\":false}}],\"members\":[]}}",
    );
    defer sync.deinit();
    try cache.applyDispatch(sync);

    try std.testing.expect(cache.getChannel(Snowflake.init(30)) == null);
    try std.testing.expect(cache.getChannel(Snowflake.init(31)) != null);
    try std.testing.expect(cache.getChannel(Snowflake.init(32)) != null);

    const fresh = cache.getChannel(Snowflake.init(33)).?;
    try std.testing.expectEqual(Types.ChannelType.public_thread, fresh.type);
    try std.testing.expectEqual(@as(u64, 10), fresh.guild_id.?.value);
    try std.testing.expectEqual(@as(u64, 20), fresh.parent_id.?.value);
    try std.testing.expectEqualStrings("fresh", fresh.name.?);

    const parent_threads = try cache.listChannelThreads(std.testing.allocator, Snowflake.init(20));
    defer std.testing.allocator.free(parent_threads);
    try std.testing.expectEqual(@as(usize, 2), parent_threads.len);
}

test "cache updates thread member count dispatch" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    try cache.putChannel(.{ .id = Snowflake.init(30), .type = .public_thread, .guild_id = Snowflake.init(10), .parent_id = Snowflake.init(20), .name = "thread", .member_count = 2 });
    try cache.putChannel(.{ .id = Snowflake.init(40), .type = .guild_text, .guild_id = Snowflake.init(10), .name = "text", .member_count = 7 });

    var update = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"THREAD_MEMBERS_UPDATE\",\"d\":{\"id\":\"30\",\"guild_id\":\"10\",\"member_count\":5,\"added_members\":[],\"removed_member_ids\":[]}}",
    );
    defer update.deinit();
    try cache.applyDispatch(update);

    try std.testing.expectEqual(@as(u32, 5), cache.getChannel(Snowflake.init(30)).?.member_count.?);

    var non_thread_update = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"THREAD_MEMBERS_UPDATE\",\"d\":{\"id\":\"40\",\"guild_id\":\"10\",\"member_count\":1,\"added_members\":[],\"removed_member_ids\":[]}}",
    );
    defer non_thread_update.deinit();
    try cache.applyDispatch(non_thread_update);

    try std.testing.expectEqual(@as(u32, 7), cache.getChannel(Snowflake.init(40)).?.member_count.?);
}

test "cache evicts oldest messages by policy" {
    var cache = Cache.initWithPolicy(std.testing.allocator, .{ .max_messages = 2 });
    defer cache.deinit();

    const author = Types.User{ .id = Snowflake.init(99), .username = "bot" };
    try cache.putMessage(.{ .id = Snowflake.init(1), .channel_id = Snowflake.init(10), .author = author, .content = "one" });
    try cache.putMessage(.{ .id = Snowflake.init(2), .channel_id = Snowflake.init(10), .author = author, .content = "two" });
    try cache.putMessage(.{ .id = Snowflake.init(3), .channel_id = Snowflake.init(10), .author = author, .content = "three" });

    try std.testing.expectEqual(@as(usize, 2), cache.messageCount());
    try std.testing.expect(cache.getMessage(Snowflake.init(1)) == null);
    try std.testing.expect(cache.getMessage(Snowflake.init(2)) != null);
    try std.testing.expect(cache.getMessage(Snowflake.init(3)) != null);
}

test "cache can disable message storage while keeping users" {
    var cache = Cache.initWithPolicy(std.testing.allocator, .noMessages());
    defer cache.deinit();

    const author = Types.User{ .id = Snowflake.init(99), .username = "bot" };
    try cache.putMessage(.{ .id = Snowflake.init(1), .channel_id = Snowflake.init(10), .author = author, .content = "one" });

    try std.testing.expectEqual(@as(usize, 0), cache.messageCount());
    try std.testing.expect(cache.getMessage(Snowflake.init(1)) == null);
    try std.testing.expect(cache.getUser(Snowflake.init(99)) != null);
}

test "cache sweeps messages older than the configured max age" {
    var cache = Cache.initWithPolicy(std.testing.allocator, .{ .message_sweep_max_age_ms = 60_000 });
    defer cache.deinit();

    const author = Types.User{ .id = Snowflake.init(99), .username = "bot" };
    const now: u64 = 1_700_000_000_000;
    const stale_id = (try Snowflake.fromTimestampMillis(now - 120_000)).value;
    const fresh_id = (try Snowflake.fromTimestampMillis(now - 10_000)).value;

    try cache.putMessage(.{ .id = Snowflake.init(stale_id), .channel_id = Snowflake.init(10), .author = author, .content = "old" });
    try cache.putMessage(.{ .id = Snowflake.init(fresh_id), .channel_id = Snowflake.init(10), .author = author, .content = "new" });
    try std.testing.expectEqual(@as(usize, 2), cache.messageCount());

    try std.testing.expectEqual(@as(usize, 1), cache.sweep(now));
    try std.testing.expectEqual(@as(usize, 1), cache.messageCount());
    try std.testing.expect(cache.getMessage(Snowflake.init(stale_id)) == null);
    try std.testing.expect(cache.getMessage(Snowflake.init(fresh_id)) != null);

    // Direct cutoff sweep removes everything created before the cutoff.
    try std.testing.expectEqual(@as(usize, 1), cache.sweepMessagesBefore(now));
    try std.testing.expectEqual(@as(usize, 0), cache.messageCount());

    // Without a configured sweeper, sweep is a no-op.
    var unconfigured = Cache.init(std.testing.allocator);
    defer unconfigured.deinit();
    try unconfigured.putMessage(.{ .id = Snowflake.init(stale_id), .channel_id = Snowflake.init(10), .author = author, .content = "old" });
    try std.testing.expectEqual(@as(usize, 0), unconfigured.sweep(now));
    try std.testing.expectEqual(@as(usize, 1), unconfigured.messageCount());
}

test "cache parses extended invite metadata" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var dispatch = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"INVITE_CREATE\",\"d\":{\"code\":\"abc123\",\"type\":0,\"guild_id\":\"30\",\"channel_id\":\"20\",\"inviter\":{\"id\":\"40\",\"username\":\"host\"},\"target_type\":2,\"target_application\":{\"id\":\"50\"},\"approximate_member_count\":120,\"expires_at\":\"2026-07-01T00:00:00.000Z\",\"uses\":3,\"max_uses\":10,\"max_age\":3600,\"temporary\":true,\"created_at\":\"2026-06-01T00:00:00.000Z\"}}",
    );
    defer dispatch.deinit();
    try cache.applyDispatch(dispatch);

    const invite = cache.getInvite("abc123").?;
    try std.testing.expectEqual(@as(?u8, 0), invite.type);
    try std.testing.expectEqual(@as(u64, 30), invite.guild_id.?.value);
    try std.testing.expectEqual(@as(u64, 40), invite.inviter_id.?.value);
    try std.testing.expectEqual(@as(?u8, 2), invite.target_type);
    try std.testing.expectEqual(@as(u64, 50), invite.target_application_id.?.value);
    try std.testing.expectEqual(@as(?u32, 120), invite.approximate_member_count);
    try std.testing.expectEqualStrings("2026-07-01T00:00:00.000Z", invite.expires_at.?);
    try std.testing.expectEqual(@as(?u32, 3), invite.uses);
    try std.testing.expectEqual(@as(?u32, 10), invite.max_uses);
    try std.testing.expectEqual(@as(?u32, 3600), invite.max_age);
    try std.testing.expectEqual(@as(?bool, true), invite.temporary);
    try std.testing.expectEqualStrings("2026-06-01T00:00:00.000Z", invite.created_at.?);
}

test "cache parses application team from ready" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var ready = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"READY\",\"d\":{\"session_id\":\"abc\",\"application\":{\"id\":\"80\",\"name\":\"app\",\"team\":{\"id\":\"500\",\"name\":\"Core Team\",\"icon\":\"teamicon\",\"owner_user_id\":\"40\",\"members\":[{\"membership_state\":2,\"team_id\":\"500\",\"role\":\"admin\",\"user\":{\"id\":\"40\",\"username\":\"ada\"}}]}}}}",
    );
    defer ready.deinit();
    try cache.applyDispatch(ready);

    const team = cache.getCurrentApplication().?.team.?;
    try std.testing.expectEqual(@as(u64, 500), team.id.value);
    try std.testing.expectEqualStrings("Core Team", team.name);
    try std.testing.expectEqualStrings("teamicon", team.icon.?);
    try std.testing.expectEqual(@as(u64, 40), team.owner_user_id.value);
    try std.testing.expectEqual(@as(usize, 1), team.members.len);
    try std.testing.expectEqual(Types.MembershipState.accepted, team.members[0].membership_state);
    try std.testing.expectEqualStrings("admin", team.members[0].role.?);
    try std.testing.expectEqualStrings("ada", team.members[0].user.username);
}

test "cache exposes discord.js-style collections" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    try cache.putGuild(.{ .id = Snowflake.init(1), .name = "Alpha" });
    try cache.putGuild(.{ .id = Snowflake.init(2), .name = "Beta" });

    var guilds = try cache.collectGuilds(std.testing.allocator);
    defer guilds.deinit();
    try std.testing.expectEqual(@as(usize, 2), guilds.size());
    try std.testing.expect(guilds.has(1));
    try std.testing.expect(guilds.has(2));
    try std.testing.expectEqualStrings("Alpha", guilds.get(1).?.name);

    const Finder = struct {
        fn isBeta(_: void, _: u64, guild: Types.Guild) bool {
            return std.mem.eql(u8, guild.name, "Beta");
        }
    };
    try std.testing.expectEqual(@as(u64, 2), guilds.findKey({}, Finder.isBeta).?);

    var channels = try cache.collectChannels(std.testing.allocator);
    defer channels.deinit();
    try std.testing.expect(channels.isEmpty());
}

test "cache collects users and roles into collections" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    try cache.putUser(.{ .id = Snowflake.init(10), .username = "ada" });
    try cache.putUser(.{ .id = Snowflake.init(11), .username = "linus" });
    try cache.putRole(Snowflake.init(1), .{ .id = Snowflake.init(100), .name = "Admin" });
    try cache.putRole(Snowflake.init(1), .{ .id = Snowflake.init(101), .name = "Mod" });

    var users = try cache.collectUsers(std.testing.allocator);
    defer users.deinit();
    try std.testing.expectEqual(@as(usize, 2), users.size());
    try std.testing.expectEqualStrings("ada", users.get(10).?.username);

    var roles = try cache.collectRoles(std.testing.allocator);
    defer roles.deinit();
    try std.testing.expectEqual(@as(usize, 2), roles.size());
    try std.testing.expectEqualStrings("Admin", roles.get(100).?.name);
}
