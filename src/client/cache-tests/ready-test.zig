const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Gateway = @import("../../gateway/protocol.zig");

const Root = @import("../cache.zig");
const Cache = Root.Cache;

test "cache hydrates current user from ready and updates it" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var ready = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"READY\",\"d\":{\"session_id\":\"abc\",\"user\":{\"id\":\"40\",\"username\":\"zigbot\",\"global_name\":\"Zig Bot\",\"bot\":true}}}",
    );
    defer ready.deinit();
    try cache.applyDispatch(ready);

    try std.testing.expectEqual(@as(u64, 40), cache.current_user_id.?.value);
    try std.testing.expectEqualStrings("zigbot", cache.getCurrentUser().?.username);
    try std.testing.expect(cache.getCurrentUser().?.bot);

    var update = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"USER_UPDATE\",\"d\":{\"id\":\"40\",\"username\":\"renamed\",\"global_name\":\"Renamed Bot\",\"bot\":true}}",
    );
    defer update.deinit();
    try cache.applyDispatch(update);

    try std.testing.expectEqualStrings("renamed", cache.getCurrentUser().?.username);
    try std.testing.expectEqualStrings("Renamed Bot", cache.getCurrentUser().?.global_name.?);
}

test "cache hydrates current application from ready" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var ready = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"READY\",\"d\":{\"session_id\":\"abc\",\"application\":{\"id\":\"80\",\"name\":\"discord.zig\",\"flags\":64}}}",
    );
    defer ready.deinit();
    try cache.applyDispatch(ready);

    try std.testing.expectEqual(@as(u64, 80), cache.getCurrentApplication().?.id.value);
    try std.testing.expectEqualStrings("discord.zig", cache.getCurrentApplication().?.name);
    try std.testing.expectEqual(@as(u32, 64), cache.getCurrentApplication().?.flags.?);

    var replacement = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"READY\",\"d\":{\"session_id\":\"def\",\"application\":{\"id\":\"81\",\"name\":\"renamed app\",\"description\":\"Updated\",\"event_webhooks_types\":[\"APPLICATION_AUTHORIZED\"]}}}",
    );
    defer replacement.deinit();
    try cache.applyDispatch(replacement);

    try std.testing.expectEqual(@as(u64, 81), cache.getCurrentApplication().?.id.value);
    try std.testing.expectEqualStrings("renamed app", cache.getCurrentApplication().?.name);
    try std.testing.expectEqualStrings("Updated", cache.getCurrentApplication().?.description);
    try std.testing.expectEqualStrings("APPLICATION_AUTHORIZED", cache.getCurrentApplication().?.event_webhooks_types[0]);
}

test "cache stats report collection sizes without list allocation" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var ready = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"READY\",\"d\":{\"session_id\":\"abc\",\"user\":{\"id\":\"1\",\"username\":\"bot\"},\"application\":{\"id\":\"2\",\"name\":\"app\"}}}",
    );
    defer ready.deinit();
    try cache.applyDispatch(ready);

    var guild = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"GUILD_CREATE\",\"d\":{\"id\":\"10\",\"name\":\"Guild\",\"channels\":[{\"id\":\"20\",\"type\":0,\"name\":\"general\"}],\"threads\":[{\"id\":\"21\",\"type\":11,\"parent_id\":\"20\",\"name\":\"thread\"}],\"members\":[{\"user\":{\"id\":\"30\",\"username\":\"member\"},\"roles\":[]}],\"roles\":[{\"id\":\"40\",\"name\":\"Role\",\"permissions\":\"0\"}],\"emojis\":[{\"id\":\"50\",\"name\":\"zig\"}],\"stickers\":[{\"id\":\"60\",\"name\":\"sticker\",\"description\":null,\"tags\":\"zig\",\"type\":2,\"format_type\":1}],\"guild_scheduled_events\":[{\"id\":\"70\",\"guild_id\":\"10\",\"name\":\"Launch\",\"scheduled_start_time\":\"2026-06-02T10:00:00.000Z\",\"privacy_level\":2,\"status\":1,\"entity_type\":3}],\"stage_instances\":[{\"id\":\"80\",\"guild_id\":\"10\",\"channel_id\":\"20\",\"topic\":\"Stage\",\"privacy_level\":2}],\"presences\":[{\"guild_id\":\"10\",\"user\":{\"id\":\"30\"},\"status\":\"online\",\"activities\":[]}],\"voice_states\":[{\"guild_id\":\"10\",\"channel_id\":\"20\",\"user_id\":\"30\",\"session_id\":\"voice\",\"deaf\":false,\"mute\":false,\"self_deaf\":false,\"self_mute\":false,\"self_video\":false,\"suppress\":false}]}}",
    );
    defer guild.deinit();
    try cache.applyDispatch(guild);

    var message = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"MESSAGE_CREATE\",\"d\":{\"id\":\"90\",\"channel_id\":\"20\",\"guild_id\":\"10\",\"content\":\"pong\",\"author\":{\"id\":\"1\",\"username\":\"bot\"}}}",
    );
    defer message.deinit();
    try cache.applyDispatch(message);

    var invite = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":4,\"t\":\"INVITE_CREATE\",\"d\":{\"code\":\"abc\",\"guild_id\":\"10\",\"channel_id\":\"20\"}}",
    );
    defer invite.deinit();
    try cache.applyDispatch(invite);

    const stats = cache.stats();
    try std.testing.expect(stats.current_user);
    try std.testing.expect(stats.current_application);
    try std.testing.expectEqual(@as(usize, 2), stats.users);
    try std.testing.expectEqual(@as(usize, 1), stats.guilds);
    try std.testing.expectEqual(@as(usize, 2), stats.channels);
    try std.testing.expectEqual(@as(usize, 1), stats.members);
    try std.testing.expectEqual(@as(usize, 1), stats.roles);
    try std.testing.expectEqual(@as(usize, 1), stats.emojis);
    try std.testing.expectEqual(@as(usize, 1), stats.stickers);
    try std.testing.expectEqual(@as(usize, 1), stats.scheduled_events);
    try std.testing.expectEqual(@as(usize, 1), stats.stage_instances);
    try std.testing.expectEqual(@as(usize, 1), stats.presences);
    try std.testing.expectEqual(@as(usize, 1), stats.voice_states);
    try std.testing.expectEqual(@as(usize, 1), stats.messages);
    try std.testing.expectEqual(@as(usize, 1), stats.invites);

    const guild_stats = cache.guildStats(Snowflake.init(10));
    try std.testing.expectEqual(@as(usize, 1), guild_stats.channels);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.threads);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.members);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.roles);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.emojis);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.stickers);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.scheduled_events);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.stage_instances);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.presences);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.voice_states);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.messages);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.invites);

    const channel_stats = cache.channelStats(Snowflake.init(20));
    try std.testing.expectEqual(@as(usize, 1), channel_stats.threads);
    try std.testing.expectEqual(@as(usize, 1), channel_stats.invites);
    try std.testing.expectEqual(@as(usize, 1), channel_stats.voice_states);
    try std.testing.expectEqual(@as(usize, 1), channel_stats.messages);

    try std.testing.expect(cache.hasCurrentUser());
    try std.testing.expect(cache.hasCurrentApplication());
    try std.testing.expectEqual(@as(u64, 1), cache.currentUserId().?.value);
    try std.testing.expectEqual(@as(u64, 2), cache.currentApplicationId().?.value);
    try std.testing.expect(cache.hasUser(Snowflake.init(1)));
    try std.testing.expect(cache.hasGuild(Snowflake.init(10)));
    try std.testing.expect(cache.hasChannel(Snowflake.init(20)));
    try std.testing.expect(cache.hasChannel(Snowflake.init(21)));
    try std.testing.expect(cache.hasMember(Snowflake.init(10), Snowflake.init(30)));
    try std.testing.expect(cache.hasRole(Snowflake.init(10), Snowflake.init(40)));
    try std.testing.expect(cache.hasEmoji(Snowflake.init(10), Snowflake.init(50)));
    try std.testing.expect(cache.hasSticker(Snowflake.init(10), Snowflake.init(60)));
    try std.testing.expect(cache.hasScheduledEvent(Snowflake.init(10), Snowflake.init(70)));
    try std.testing.expect(cache.hasStageInstance(Snowflake.init(10), Snowflake.init(80)));
    try std.testing.expect(cache.hasPresence(Snowflake.init(10), Snowflake.init(30)));
    try std.testing.expect(cache.hasVoiceState(Snowflake.init(10), Snowflake.init(30)));
    try std.testing.expect(cache.hasMessage(Snowflake.init(90)));
    try std.testing.expect(cache.hasInvite("abc"));
    try std.testing.expect(!cache.hasMessage(Snowflake.init(91)));
    try std.testing.expect(!cache.hasInvite("missing"));

    cache.removeMessage(Snowflake.init(90));
    try std.testing.expect(!cache.hasMessage(Snowflake.init(90)));
    try std.testing.expectEqual(@as(usize, 0), cache.stats().messages);

    cache.removeInvite("abc");
    try std.testing.expect(!cache.hasInvite("abc"));
    try std.testing.expectEqual(@as(usize, 0), cache.stats().invites);

    cache.removeUser(Snowflake.init(1));
    try std.testing.expect(!cache.hasUser(Snowflake.init(1)));
    try std.testing.expect(!cache.hasCurrentUser());
    try std.testing.expect(cache.currentUserId() == null);

    cache.removeCurrentApplication();
    try std.testing.expect(!cache.hasCurrentApplication());
    try std.testing.expect(cache.currentApplicationId() == null);

    cache.clear();
    const cleared_stats = cache.stats();
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.users);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.guilds);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.channels);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.members);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.roles);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.emojis);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.stickers);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.scheduled_events);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.stage_instances);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.presences);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.voice_states);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.messages);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.invites);
}
