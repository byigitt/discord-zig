const std = @import("std");
const Intents = @import("../../../core/intents.zig");
const Rest = @import("../../../rest/client.zig");
const HttpTransport = @import("../../../rest/http_transport.zig").HttpTransport;
const Events = @import("../../../gateway/events.zig");
const Gateway = @import("../../../gateway/protocol.zig");
const GatewaySession = @import("../../../gateway/session.zig");
const CacheModule = @import("../../cache.zig");
const Interactions = @import("../../../interactions/mod.zig");
const Types = @import("../../../models/types.zig");
const Snowflake = @import("../../../core/snowflake.zig").Snowflake;
const Root = @import("../../client.zig");
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

test "client convenience send reply and react delegate to REST part 6" {
    var memory = Rest.MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
        .transport = memory.transport(),
    });
    defer client.deinit();
    _ = try client.createGuildSoundboardSound(
        Snowflake.init(10),
        Types.CreateGuildSoundboardSound.init("launch", "data:audio/ogg;base64,T0dH"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/soundboard-sounds", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"launch\",\"sound\":\"data:audio/ogg;base64,T0dH\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.createSoundboardSoundWithData(Snowflake.init(10), "launch-2", "data:audio/ogg;base64,QUJD");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/soundboard-sounds", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"launch-2\",\"sound\":\"data:audio/ogg;base64,QUJD\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.renameSoundboardSound(Snowflake.init(10), Snowflake.init(20), "launch-renamed");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/soundboard-sounds/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"launch-renamed\"}", memory.last_request.?.body.?);

    _ = try client.deleteGuildSoundboardSound(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/soundboard-sounds/20", memory.last_request.?.url);

    _ = try client.fetchAutoModerationRules(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/auto-moderation/rules",
        memory.last_request.?.url,
    );

    _ = try client.fetchAutoModerationRule(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/auto-moderation/rules/20",
        memory.last_request.?.url,
    );

    _ = try client.createAutoModerationRule(Snowflake.init(10), Types.CreateAutoModerationRule.init(
        "spam guard",
        .spam,
        &.{Types.AutoModerationAction.blockMessage(null)},
    ));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/auto-moderation/rules",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"spam guard\",\"event_type\":1,\"trigger_type\":3,\"actions\":[{\"type\":1}]}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteAutoModerationRule(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/auto-moderation/rules/20",
        memory.last_request.?.url,
    );

    _ = try client.createThreadWithName(Snowflake.init(10), "standalone");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/threads", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"standalone\",\"type\":11}", memory.last_request.?.body.?);

    _ = try client.createThreadFromMessage(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.CreateThreadFromMessage.init("debug"),
    );
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/threads",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"name\":\"debug\"}", memory.last_request.?.body.?);

    _ = try client.startThreadFromMessage(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.CreateThreadFromMessage.init("debug"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/threads",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"name\":\"debug\"}", memory.last_request.?.body.?);

    _ = try client.startThreadFromMessageWithName(Snowflake.init(10), Snowflake.init(20), "debug shortcut");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/threads",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"name\":\"debug shortcut\"}", memory.last_request.?.body.?);

    _ = try client.joinThread(Snowflake.init(10));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members/@me",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.getThreadMember(Snowflake.init(10), Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members/30",
        memory.last_request.?.url,
    );

    _ = try client.fetchThreadMember(Snowflake.init(10), Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members/30",
        memory.last_request.?.url,
    );

    _ = try client.fetchThreadMembers(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members",
        memory.last_request.?.url,
    );

    _ = try client.listThreadMembersWithOptions(
        Snowflake.init(10),
        Types.ListThreadMembers.init()
            .withMemberExpansion(true)
            .afterMember(Snowflake.init(30))
            .withLimit(100),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members?with_member=true&after=30&limit=100",
        memory.last_request.?.url,
    );

    _ = try client.fetchThreadMembersWithOptions(
        Snowflake.init(10),
        Types.ListThreadMembers.init()
            .withMemberExpansion(false)
            .withLimit(25),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members?with_member=false&limit=25",
        memory.last_request.?.url,
    );

    _ = try client.listActiveGuildThreads(Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/30/threads/active",
        memory.last_request.?.url,
    );

    _ = try client.fetchActiveThreads(Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/30/threads/active",
        memory.last_request.?.url,
    );

    _ = try client.listPublicArchivedThreads(Snowflake.init(10), Types.ListArchivedThreads.init().withLimit(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/threads/archived/public?limit=10",
        memory.last_request.?.url,
    );

    _ = try client.fetchPublicArchivedThreads(Snowflake.init(10), Types.ListArchivedThreads.init().withLimit(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/threads/archived/public?limit=10",
        memory.last_request.?.url,
    );

    _ = try client.listPrivateArchivedThreads(Snowflake.init(10), Types.ListArchivedThreads.init().withLimit(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/threads/archived/private?limit=10",
        memory.last_request.?.url,
    );

    _ = try client.fetchPrivateArchivedThreads(Snowflake.init(10), Types.ListArchivedThreads.init().withLimit(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/threads/archived/private?limit=10",
        memory.last_request.?.url,
    );

    _ = try client.listJoinedPrivateArchivedThreads(Snowflake.init(10), Types.ListArchivedThreads.init().withLimit(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/users/@me/threads/archived/private?limit=10",
        memory.last_request.?.url,
    );

    _ = try client.fetchJoinedPrivateArchivedThreads(Snowflake.init(10), Types.ListArchivedThreads.init().withLimit(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/users/@me/threads/archived/private?limit=10",
        memory.last_request.?.url,
    );

    _ = try client.createInvite(Snowflake.init(10), Types.CreateChannelInvite.init().withMaxUses(1));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/invites", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"max_uses\":1}", memory.last_request.?.body.?);

    _ = try client.createDefaultInvite(Snowflake.init(10));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/invites", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{}", memory.last_request.?.body.?);

    _ = try client.createInviteWithMaxUses(Snowflake.init(10), 2);
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/invites", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"max_uses\":2}", memory.last_request.?.body.?);

    _ = try client.createInviteWithMaxAge(Snowflake.init(10), 3600);
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/invites", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"max_age\":3600}", memory.last_request.?.body.?);

    _ = try client.createUniqueInvite(Snowflake.init(10));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/invites", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"unique\":true}", memory.last_request.?.body.?);

    _ = try client.listChannelInvites(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/invites", memory.last_request.?.url);

    _ = try client.fetchChannelInvites(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/invites", memory.last_request.?.url);

    _ = try client.listGuildInvites(Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/20/invites", memory.last_request.?.url);

    _ = try client.fetchGuildInvites(Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/20/invites", memory.last_request.?.url);

    _ = try client.getInvite("abc 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/invites/abc%20123", memory.last_request.?.url);

    _ = try client.fetchInvite("abc 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/invites/abc%20123", memory.last_request.?.url);

    _ = try client.getInviteWithOptions(
        "abc 123",
        Types.GetInvite.init()
            .withCounts(true)
            .withScheduledEvent(Snowflake.init(77)),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123?with_counts=true&guild_scheduled_event_id=77",
        memory.last_request.?.url,
    );

    _ = try client.fetchInviteWithOptions("abc 123", Types.GetInvite.init().withCounts(true));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123?with_counts=true",
        memory.last_request.?.url,
    );

    _ = try client.deleteInvite("abc 123");
    try std.testing.expectEqualStrings("https://discord.com/api/v10/invites/abc%20123", memory.last_request.?.url);

    _ = try client.getInviteTargetUsers("abc 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123/target-users",
        memory.last_request.?.url,
    );

    _ = try client.fetchInviteTargetUsers("abc 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123/target-users",
        memory.last_request.?.url,
    );
}
