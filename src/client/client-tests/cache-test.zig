const std = @import("std");
const Intents = @import("../../core/intents.zig");
const Partials = @import("../../core/partials.zig");
const Rest = @import("../../rest/client.zig");
const HttpTransport = @import("../../rest/http-transport.zig").HttpTransport;
const Events = @import("../../gateway/events.zig");
const Gateway = @import("../../gateway/protocol.zig");
const GatewaySession = @import("../../gateway/session.zig");
const CacheModule = @import("../cache.zig");
const Interactions = @import("../../interactions/mod.zig");
const Types = @import("../../models/types.zig");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Root = @import("../client.zig");
const Cache = Root.Cache;
const ClientOptions = Root.ClientOptions;
const SetActivityOptions = Root.SetActivityOptions;
const Client = Root.Client;
const GatewayStep = Root.GatewayStep;
const GatewayStartMode = Root.GatewayStartMode;
const ReconnectBackoff = Root.ReconnectBackoff;
const GatewayRunner = Root.GatewayRunner;
const noTransportValue = Root.noTransportValue;
const noTransportSend = Root.noTransportSend;

test "client stores Discord.js-style partial options" {
    var default_client = Client.init(std.testing.allocator, .{ .token = "Bot test" });
    defer default_client.deinit();
    try std.testing.expectEqual(Partials.none, default_client.partials);
    try std.testing.expect(!default_client.hasPartial(Partials.Message));

    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
        .partials = Partials.Message | Partials.Channel | Partials.GuildMember | Partials.PollAnswer,
    });
    defer client.deinit();

    try std.testing.expect(client.hasPartial(Partials.message));
    try std.testing.expect(client.hasPartial(Partials.Channel));
    try std.testing.expect(client.hasPartials(Partials.Message | Partials.GuildMember));
    try std.testing.expect(!client.hasPartial(Partials.SoundboardSound));
    try std.testing.expectEqual(Partials.soundboard_sound, Partials.missing(client.partials, Partials.SoundboardSound | Partials.Message));
}

test "client exposes current cached user from gateway ready" {
    var client = Client.init(std.testing.allocator, .{ .token = "Bot test" });
    defer client.deinit();

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":1,\"t\":\"READY\",\"d\":{\"session_id\":\"abc\",\"resume_gateway_url\":\"wss://gateway.discord.gg\",\"user\":{\"id\":\"40\",\"username\":\"zigbot\",\"global_name\":\"Zig Bot\",\"bot\":true}}}",
    );
    try std.testing.expectEqualStrings("zigbot", client.getCurrentCachedUser().?.username);
    try std.testing.expectEqual(@as(u64, 40), client.getCurrentCachedUser().?.id.value);
    try std.testing.expectEqualStrings("zigbot", client.currentUser().?.username);
    try std.testing.expectEqualStrings("zigbot", client.me().?.username);
    try std.testing.expectEqualStrings("zigbot", client.cachedUser(Snowflake.init(40)).?.username);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":2,\"t\":\"USER_UPDATE\",\"d\":{\"id\":\"40\",\"username\":\"renamed\",\"global_name\":\"Renamed Bot\",\"bot\":true}}",
    );
    try std.testing.expectEqualStrings("renamed", client.getCurrentCachedUser().?.username);
    try std.testing.expectEqualStrings("Renamed Bot", client.getCurrentCachedUser().?.global_name.?);
}

test "client exposes current cached application from gateway ready" {
    var client = Client.init(std.testing.allocator, .{ .token = "Bot test" });
    defer client.deinit();

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":1,\"t\":\"READY\",\"d\":{\"session_id\":\"abc\",\"resume_gateway_url\":\"wss://gateway.discord.gg\",\"application\":{\"id\":\"80\",\"name\":\"discord.zig\",\"description\":\"Fast Zig bot\",\"flags\":64}}}",
    );

    try std.testing.expectEqual(@as(u64, 80), client.getCurrentCachedApplication().?.id.value);
    try std.testing.expectEqualStrings("discord.zig", client.getCurrentCachedApplication().?.name);
    try std.testing.expectEqualStrings("discord.zig", client.currentApplication().?.name);
    try std.testing.expectEqualStrings("Fast Zig bot", client.getCurrentCachedApplication().?.description);
    try std.testing.expectEqual(@as(u32, 64), client.getCurrentCachedApplication().?.flags.?);
}

test "client exposes cache stats" {
    var client = Client.init(std.testing.allocator, .{ .token = "Bot test" });
    defer client.deinit();

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":1,\"t\":\"READY\",\"d\":{\"session_id\":\"abc\",\"user\":{\"id\":\"1\",\"username\":\"bot\"},\"application\":{\"id\":\"2\",\"name\":\"app\"}}}",
    );
    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":2,\"t\":\"MESSAGE_CREATE\",\"d\":{\"id\":\"10\",\"channel_id\":\"20\",\"content\":\"pong\",\"author\":{\"id\":\"1\",\"username\":\"bot\"}}}",
    );
    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":3,\"t\":\"GUILD_CREATE\",\"d\":{\"id\":\"40\",\"name\":\"Guild\",\"channels\":[{\"id\":\"50\",\"type\":0,\"name\":\"general\"}],\"threads\":[{\"id\":\"51\",\"type\":11,\"parent_id\":\"50\",\"name\":\"thread\"}]}}",
    );

    const stats = client.cacheStats();
    try std.testing.expect(stats.current_user);
    try std.testing.expect(stats.current_application);
    try std.testing.expectEqual(@as(usize, 1), stats.users);
    try std.testing.expectEqual(@as(usize, 1), stats.messages);
    try std.testing.expectEqual(@as(usize, 1), client.cachedUserCount());
    try std.testing.expectEqual(@as(usize, 1), client.cachedGuildCount());
    try std.testing.expectEqual(@as(usize, 2), client.cachedChannelCount());
    try std.testing.expectEqual(@as(usize, 0), client.cachedMemberCount());
    try std.testing.expectEqual(@as(usize, 0), client.cachedRoleCount());
    try std.testing.expectEqual(@as(usize, 0), client.cachedEmojiCount());
    try std.testing.expectEqual(@as(usize, 0), client.cachedStickerCount());
    try std.testing.expectEqual(@as(usize, 1), client.cachedMessageCount());

    const guild_stats = client.guildCacheStats(Snowflake.init(40));
    try std.testing.expectEqual(@as(usize, 1), guild_stats.channels);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.threads);

    const channel_stats = client.channelCacheStats(Snowflake.init(50));
    try std.testing.expectEqual(@as(usize, 1), channel_stats.threads);

    try std.testing.expect(client.hasCurrentCachedUser());
    try std.testing.expect(client.hasCurrentCachedApplication());
    try std.testing.expectEqual(@as(u64, 1), client.currentUserId().?.value);
    try std.testing.expectEqual(@as(u64, 2), client.currentApplicationId().?.value);
    try std.testing.expect(client.hasCachedUser(Snowflake.init(1)));
    try std.testing.expect(client.hasCachedGuild(Snowflake.init(40)));
    try std.testing.expect(client.hasCachedChannel(Snowflake.init(50)));
    try std.testing.expect(client.hasCachedChannel(Snowflake.init(51)));
    try std.testing.expect(client.hasCachedMessage(Snowflake.init(10)));
    try std.testing.expect(!client.hasCachedMessage(Snowflake.init(11)));
    try std.testing.expectEqualStrings("bot", client.cachedUser(Snowflake.init(1)).?.username);
    try std.testing.expectEqualStrings("Guild", client.cachedGuild(Snowflake.init(40)).?.name);
    try std.testing.expectEqualStrings("general", client.cachedChannel(Snowflake.init(50)).?.name.?);
    try std.testing.expectEqualStrings("pong", client.cachedMessage(Snowflake.init(10)).?.content);

    client.evictCachedMessage(Snowflake.init(10));
    try std.testing.expect(!client.hasCachedMessage(Snowflake.init(10)));

    client.evictCachedChannel(Snowflake.init(50));
    try std.testing.expect(!client.hasCachedChannel(Snowflake.init(50)));
    try std.testing.expect(!client.hasCachedChannel(Snowflake.init(51)));

    client.evictCachedUser(Snowflake.init(1));
    try std.testing.expect(!client.hasCachedUser(Snowflake.init(1)));
    try std.testing.expect(!client.hasCurrentCachedUser());
    try std.testing.expect(client.currentUserId() == null);

    client.evictCurrentCachedApplication();
    try std.testing.expect(!client.hasCurrentCachedApplication());
    try std.testing.expect(client.currentApplicationId() == null);

    client.clearCache();
    const cleared_stats = client.cacheStats();
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.users);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.guilds);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.channels);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.messages);
    try std.testing.expectEqual(@as(usize, 0), client.cachedUserCount());
    try std.testing.expectEqual(@as(usize, 0), client.cachedGuildCount());
    try std.testing.expectEqual(@as(usize, 0), client.cachedChannelCount());
    try std.testing.expectEqual(@as(usize, 0), client.cachedMemberCount());
    try std.testing.expectEqual(@as(usize, 0), client.cachedRoleCount());
    try std.testing.expectEqual(@as(usize, 0), client.cachedEmojiCount());
    try std.testing.expectEqual(@as(usize, 0), client.cachedStickerCount());
    try std.testing.expectEqual(@as(usize, 0), client.cachedMessageCount());
}
