const std = @import("std");
const Api = @import("../../core/api.zig");
const Routes = @import("../routes.zig");
const Types = @import("../../models/types.zig");
const Interactions = @import("../../interactions/mod.zig");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;

const Root = @import("../client.zig");
const Client = Root.Client;
const MemoryTransport = Root.MemoryTransport;

test "REST thread member helpers use expected routes" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.joinThread(Snowflake.init(10));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members/@me",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.leaveThread(Snowflake.init(10));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members/@me",
        memory.last_request.?.url,
    );

    _ = try client.addThreadMember(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members/20",
        memory.last_request.?.url,
    );

    _ = try client.getThreadMember(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members/20",
        memory.last_request.?.url,
    );

    _ = try client.removeThreadMember(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members/20",
        memory.last_request.?.url,
    );

    _ = try client.listThreadMembers(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members",
        memory.last_request.?.url,
    );

    _ = try client.listThreadMembersWithOptions(
        Snowflake.init(10),
        Types.ListThreadMembers.init()
            .withMemberExpansion(true)
            .afterMember(Snowflake.init(20))
            .withLimit(100),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/thread-members?with_member=true&after=20&limit=100",
        memory.last_request.?.url,
    );

    _ = try client.listActiveGuildThreads(Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/30/threads/active",
        memory.last_request.?.url,
    );

    _ = try client.listPublicArchivedThreads(
        Snowflake.init(10),
        Types.ListArchivedThreads.beforeTimestamp("2026-06-02T10:00:00.000Z").withLimit(25),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/threads/archived/public?before=2026-06-02T10%3A00%3A00.000Z&limit=25",
        memory.last_request.?.url,
    );

    _ = try client.listPrivateArchivedThreads(
        Snowflake.init(10),
        Types.ListArchivedThreads.beforeTimestamp("2026-06-02T10:00:00.000Z").withLimit(25),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/threads/archived/private?before=2026-06-02T10%3A00%3A00.000Z&limit=25",
        memory.last_request.?.url,
    );

    _ = try client.listJoinedPrivateArchivedThreads(
        Snowflake.init(10),
        Types.ListArchivedThreads.beforeTimestamp("2026-06-02T10:00:00.000Z").withLimit(25),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/users/@me/threads/archived/private?before=2026-06-02T10%3A00%3A00.000Z&limit=25",
        memory.last_request.?.url,
    );
}

test "REST invite helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.listChannelInvites(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/invites",
        memory.last_request.?.url,
    );

    _ = try client.createChannelInvite(
        Snowflake.init(10),
        Types.CreateChannelInvite.init()
            .withMaxAge(3600)
            .temporaryState(false)
            .uniqueState(true),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "{\"max_age\":3600,\"temporary\":false,\"unique\":true}",
        memory.last_request.?.body.?,
    );

    _ = try client.listGuildInvites(Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/20/invites",
        memory.last_request.?.url,
    );

    _ = try client.getInvite("abc 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123",
        memory.last_request.?.url,
    );

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

    _ = try client.deleteInvite("abc 123");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123",
        memory.last_request.?.url,
    );

    _ = try client.getInviteTargetUsers("abc 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123/target-users",
        memory.last_request.?.url,
    );

    _ = try client.updateInviteTargetUsers(
        "abc 123",
        Types.UploadFile.init("targets.csv", "user_id\n42\n").withContentType("text/csv"),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123/target-users",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "multipart/form-data; boundary=discord-zig-boundary",
        memory.last_request.?.content_type.?,
    );
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "name=\"target_users_file\"; filename=\"targets.csv\"") != null);

    _ = try client.getInviteTargetUsersJobStatus("abc 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123/target-users/job-status",
        memory.last_request.?.url,
    );
}

test "REST webhook helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.listChannelWebhooks(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/webhooks",
        memory.last_request.?.url,
    );

    _ = try client.createWebhook(Snowflake.init(10), Types.CreateWebhook.init("deploys"));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "{\"name\":\"deploys\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.listGuildWebhooks(Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/20/webhooks",
        memory.last_request.?.url,
    );

    _ = try client.getWebhook(Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/30",
        memory.last_request.?.url,
    );

    _ = try client.editWebhook(
        Snowflake.init(30),
        Types.EditWebhook.init()
            .withName("alerts")
            .withChannel(Snowflake.init(40)),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "{\"name\":\"alerts\",\"channel_id\":\"40\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteWebhook(Snowflake.init(30));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/30",
        memory.last_request.?.url,
    );

    _ = try client.getWebhookWithToken(Snowflake.init(30), "tok en");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/30/tok%20en",
        memory.last_request.?.url,
    );

    _ = try client.editWebhookWithToken(
        Snowflake.init(30),
        "tok en",
        Types.EditWebhookWithToken.init().withName("token-alerts"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/30/tok%20en",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"name\":\"token-alerts\"}", memory.last_request.?.body.?);

    _ = try client.deleteWebhookWithToken(Snowflake.init(30), "tok en");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/30/tok%20en",
        memory.last_request.?.url,
    );

    _ = try client.executeWebhook(Snowflake.init(30), "tok en", Types.ExecuteWebhook.init("deploy complete"));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/30/tok%20en",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"content\":\"deploy complete\"}",
        memory.last_request.?.body.?,
    );

    const webhook_files = [_]Types.UploadFile{
        Types.UploadFile.init("deploy.txt", "ok").withContentType("text/plain"),
    };
    _ = try client.executeWebhookWithFiles(
        Snowflake.init(30),
        "tok en",
        Types.ExecuteWebhook.init("deploy with file"),
        &webhook_files,
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/30/tok%20en",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "multipart/form-data; boundary=discord-zig-boundary",
        memory.last_request.?.content_type.?,
    );
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"content\":\"deploy with file\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "name=\"files[0]\"; filename=\"deploy.txt\"") != null);

    _ = try client.getWebhookMessage(Snowflake.init(30), "tok en", Snowflake.init(40));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/30/tok%20en/messages/40",
        memory.last_request.?.url,
    );

    _ = try client.editWebhookMessage(
        Snowflake.init(30),
        "tok en",
        Snowflake.init(40),
        Types.EditMessage.init().withContent("edited"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/30/tok%20en/messages/40",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"content\":\"edited\"}", memory.last_request.?.body.?);

    _ = try client.deleteWebhookMessage(Snowflake.init(30), "tok en", Snowflake.init(40));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/30/tok%20en/messages/40",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);
}
