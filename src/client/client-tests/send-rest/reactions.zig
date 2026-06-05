const std = @import("std");
const Intents = @import("../../../core/intents.zig");
const Rest = @import("../../../rest/client.zig");
const HttpTransport = @import("../../../rest/http-transport.zig").HttpTransport;
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

test "client reaction conveniences hit REST routes" {
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
    _ = try client.fetchGuildScheduledEventUsers(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.ListGuildScheduledEventUsers.init().withLimit(10),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/scheduled-events/20/users?limit=10",
        memory.last_request.?.url,
    );

    _ = try client.listGuildAuditLog(Snowflake.init(10), Types.ListAuditLog.init().withLimit(5));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/audit-logs?limit=5",
        memory.last_request.?.url,
    );

    _ = try client.fetchAuditLog(Snowflake.init(10), Types.ListAuditLog.init().withLimit(5));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/audit-logs?limit=5",
        memory.last_request.?.url,
    );

    _ = try client.listGuildIntegrations(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/integrations", memory.last_request.?.url);

    _ = try client.fetchGuildIntegrations(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/integrations", memory.last_request.?.url);

    _ = try client.deleteGuildIntegration(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/integrations/20", memory.last_request.?.url);

    _ = try client.fetchApplicationSkus(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/skus", memory.last_request.?.url);

    _ = try client.fetchApplicationRoleConnectionMetadataRecords(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/role-connections/metadata",
        memory.last_request.?.url,
    );

    const metadata_records = [_]Types.ApplicationRoleConnectionMetadata{
        Types.ApplicationRoleConnectionMetadata.init(.boolean_equal, "verified", "Verified", "Account verified"),
    };
    _ = try client.setApplicationRoleConnectionMetadataRecords(
        Snowflake.init(10),
        Types.UpdateApplicationRoleConnectionMetadataRecords.init(&metadata_records),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/role-connections/metadata",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "[{\"type\":7,\"key\":\"verified\",\"name\":\"Verified\",\"description\":\"Account verified\"}]",
        memory.last_request.?.body.?,
    );

    _ = try client.fetchApplicationEmojis(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/emojis", memory.last_request.?.url);

    _ = try client.fetchApplicationEmoji(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/emojis/20", memory.last_request.?.url);

    _ = try client.createApplicationEmoji(
        Snowflake.init(10),
        Types.CreateApplicationEmoji.init("zig", "data:image/webp;base64,abc"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/emojis", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"zig\",\"image\":\"data:image/webp;base64,abc\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.createApplicationEmojiWithImage(Snowflake.init(10), "zig-shortcut", "data:image/webp;base64,def");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/emojis", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"zig-shortcut\",\"image\":\"data:image/webp;base64,def\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.editApplicationEmoji(Snowflake.init(10), Snowflake.init(20), Types.EditApplicationEmoji.init("ziggy"));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/emojis/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"ziggy\"}", memory.last_request.?.body.?);

    _ = try client.renameApplicationEmoji(Snowflake.init(10), Snowflake.init(20), "zig-app-renamed");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/emojis/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"zig-app-renamed\"}", memory.last_request.?.body.?);

    _ = try client.deleteApplicationEmoji(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/emojis/20", memory.last_request.?.url);

    _ = try client.getApplicationActivityInstance(Snowflake.init(10), "abc:def 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/activity-instances/abc%3Adef%20123",
        memory.last_request.?.url,
    );

    _ = try client.fetchApplicationActivityInstance(Snowflake.init(10), "abc:def 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/activity-instances/abc%3Adef%20123",
        memory.last_request.?.url,
    );

    const lobby_metadata = [_]Types.StringPair{.{ .key = "mode", .value = "duo" }};

    _ = try client.createLobby(Types.CreateLobby.init().withMetadata(&lobby_metadata).withIdleTimeout(60));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies", memory.last_request.?.url);

    _ = try client.fetchLobby(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10", memory.last_request.?.url);

    _ = try client.editLobby(Snowflake.init(10), Types.EditLobby.init().clearMetadata());
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("{\"metadata\":null}", memory.last_request.?.body.?);

    _ = try client.setLobbyMember(Snowflake.init(10), Snowflake.init(20), Types.UpdateLobbyMember.init().withMetadata(&lobby_metadata).withFlags(1));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10/members/20", memory.last_request.?.url);

    const lobby_members = [_]Types.LobbyMember{Types.LobbyMember.init(Snowflake.init(20)).removeState(true)};
    _ = try client.bulkUpdateLobbyMembers(Snowflake.init(10), Types.BulkUpdateLobbyMembers.init(&lobby_members));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10/members/bulk", memory.last_request.?.url);

    _ = try client.removeLobbyMember(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10/members/20", memory.last_request.?.url);

    _ = try client.leaveLobby("Bearer user-token", Snowflake.init(10));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10/members/@me", memory.last_request.?.url);

    _ = try client.linkLobbyChannel("Bearer user-token", Snowflake.init(10), Types.LinkLobbyChannel.init(Snowflake.init(30)));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10/channel-linking", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"channel_id\":\"30\"}", memory.last_request.?.body.?);

    _ = try client.unlinkLobbyChannel("Bearer user-token", Snowflake.init(10));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("{\"channel_id\":null}", memory.last_request.?.body.?);

    const moderation_metadata = [_]Types.StringPair{
        .{ .key = "action", .value = "replace" },
        .{ .key = "replacement", .value = "Be kind" },
    };
    _ = try client.updateLobbyMessageModerationMetadata(
        Snowflake.init(10),
        Snowflake.init(30),
        Types.UpdateLobbyMessageModerationMetadata.init(&moderation_metadata),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/lobbies/10/messages/30/moderation-metadata",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"action\":\"replace\",\"replacement\":\"Be kind\"}", memory.last_request.?.body.?);

    _ = try client.setLobbyMessageModerationMetadata(
        Snowflake.init(10),
        Snowflake.init(30),
        Types.UpdateLobbyMessageModerationMetadata.init(&moderation_metadata),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/lobbies/10/messages/30/moderation-metadata",
        memory.last_request.?.url,
    );

    _ = try client.deleteLobby(Snowflake.init(10));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10", memory.last_request.?.url);

    _ = try client.fetchEntitlements(
        Snowflake.init(10),
        Types.ListEntitlements.init().withLimit(10).forGuild(Snowflake.init(20)),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/entitlements?limit=10&guild_id=20",
        memory.last_request.?.url,
    );

    _ = try client.fetchEntitlement(Snowflake.init(10), Snowflake.init(40));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/entitlements/40", memory.last_request.?.url);

    _ = try client.consumeEntitlement(Snowflake.init(10), Snowflake.init(40));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/entitlements/40/consume", memory.last_request.?.url);

    _ = try client.markEntitlementConsumed(Snowflake.init(10), Snowflake.init(40));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/entitlements/40/consume", memory.last_request.?.url);

    _ = try client.createTestEntitlement(
        Snowflake.init(10),
        Types.CreateTestEntitlement.init(Snowflake.init(30), Snowflake.init(20), .guild),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "{\"sku_id\":\"30\",\"owner_id\":\"20\",\"owner_type\":1}",
        memory.last_request.?.body.?,
    );

    _ = try client.fetchSkuSubscriptions(
        Snowflake.init(30),
        Types.ListSkuSubscriptions.init().forUser(Snowflake.init(20)),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/skus/30/subscriptions?user_id=20",
        memory.last_request.?.url,
    );

    _ = try client.fetchSkuSubscription(Snowflake.init(30), Snowflake.init(60));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/skus/30/subscriptions/60", memory.last_request.?.url);

    _ = try client.listGuildBans(
        Snowflake.init(10),
        Types.ListGuildBans.init().afterUser(Snowflake.init(20)).withLimit(10),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/bans?after=20&limit=10",
        memory.last_request.?.url,
    );

    _ = try client.fetchBans(
        Snowflake.init(10),
        Types.ListGuildBans.init().afterUser(Snowflake.init(20)).withLimit(10),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/bans?after=20&limit=10",
        memory.last_request.?.url,
    );

    _ = try client.getGuildBan(Snowflake.init(10), Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bans/30", memory.last_request.?.url);

    _ = try client.fetchBan(Snowflake.init(10), Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bans/30", memory.last_request.?.url);

    _ = try client.getGuildPruneCount(Snowflake.init(10), Types.GetGuildPruneCount.init().withDays(14));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/prune?days=14", memory.last_request.?.url);

    _ = try client.fetchPruneCount(Snowflake.init(10), Types.GetGuildPruneCount.init().withDays(14));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/prune?days=14", memory.last_request.?.url);

    _ = try client.beginGuildPrune(Snowflake.init(10), Types.BeginGuildPrune.init().computeCount(false));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/prune", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"compute_prune_count\":false}", memory.last_request.?.body.?);

    _ = try client.prune(Snowflake.init(10), Types.BeginGuildPrune.init().computeCount(false));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/prune", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"compute_prune_count\":false}", memory.last_request.?.body.?);

    _ = try client.pruneMembers(Snowflake.init(10));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/prune", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{}", memory.last_request.?.body.?);

    _ = try client.pruneMembersWithDays(Snowflake.init(10), 14);
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/prune", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"days\":14}", memory.last_request.?.body.?);

    _ = try client.pruneMembersWithDaysAndCount(Snowflake.init(10), 14, false);
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/prune", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"days\":14,\"compute_prune_count\":false}", memory.last_request.?.body.?);
}
