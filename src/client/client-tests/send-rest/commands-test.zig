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
const Client = Root.Client;

test "client command and upload conveniences hit REST routes" {
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
    _ = try client.updateInviteTargetUsers(
        "abc 123",
        Types.UploadFile.init("targets.csv", "user_id\n42\n").withContentType("text/csv"),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123/target-users",
        memory.last_request.?.url,
    );
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "name=\"target_users_file\"; filename=\"targets.csv\"") != null);

    _ = try client.setInviteTargetUsers(
        "abc 123",
        Types.UploadFile.init("targets.csv", "user_id\n42\n").withContentType("text/csv"),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123/target-users",
        memory.last_request.?.url,
    );
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "name=\"target_users_file\"; filename=\"targets.csv\"") != null);

    _ = try client.getInviteTargetUsersJobStatus("abc 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123/target-users/job-status",
        memory.last_request.?.url,
    );

    _ = try client.fetchInviteTargetUsersJobStatus("abc 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/invites/abc%20123/target-users/job-status",
        memory.last_request.?.url,
    );

    _ = try client.listChannelWebhooks(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/webhooks", memory.last_request.?.url);

    _ = try client.fetchChannelWebhooks(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/webhooks", memory.last_request.?.url);

    _ = try client.createWebhook(Snowflake.init(10), Types.CreateWebhook.init("deploys"));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/webhooks", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"deploys\"}", memory.last_request.?.body.?);

    _ = try client.createWebhookWithName(Snowflake.init(10), "alerts");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/webhooks", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"alerts\"}", memory.last_request.?.body.?);

    _ = try client.createWebhookWithAvatar(Snowflake.init(10), "alerts", "data:image/png;base64,AAAA");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/webhooks", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"alerts\",\"avatar\":\"data:image/png;base64,AAAA\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.listGuildWebhooks(Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/20/webhooks", memory.last_request.?.url);

    _ = try client.fetchGuildWebhooks(Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/20/webhooks", memory.last_request.?.url);

    _ = try client.getWebhook(Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30", memory.last_request.?.url);

    _ = try client.fetchWebhook(Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30", memory.last_request.?.url);

    _ = try client.editWebhook(Snowflake.init(30), Types.EditWebhook.init().withName("deploys-updated"));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"deploys-updated\"}", memory.last_request.?.body.?);

    _ = try client.deleteWebhook(Snowflake.init(30));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30", memory.last_request.?.url);

    _ = try client.getWebhookWithToken(Snowflake.init(30), "tok en");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30/tok%20en", memory.last_request.?.url);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);

    _ = try client.fetchWebhookWithToken(Snowflake.init(30), "tok en");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30/tok%20en", memory.last_request.?.url);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);

    _ = try client.editWebhookWithToken(
        Snowflake.init(30),
        "tok en",
        Types.EditWebhookWithToken.init().withName("token-deploys"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30/tok%20en", memory.last_request.?.url);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings("{\"name\":\"token-deploys\"}", memory.last_request.?.body.?);

    _ = try client.deleteWebhookWithToken(Snowflake.init(30), "tok en");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30/tok%20en", memory.last_request.?.url);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);

    _ = try client.executeWebhook(Snowflake.init(30), "tok en", Types.ExecuteWebhook.init("deploy complete"));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30/tok%20en", memory.last_request.?.url);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);

    _ = try client.executeWebhookWithContent(Snowflake.init(30), "tok en", "deploy shortcut");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30/tok%20en", memory.last_request.?.url);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings("{\"content\":\"deploy shortcut\"}", memory.last_request.?.body.?);

    const webhook_files = [_]Types.UploadFile{
        Types.UploadFile.init("deploy.txt", "ship").withContentType("text/plain"),
    };
    _ = try client.executeWebhookWithFiles(
        Snowflake.init(30),
        "tok en",
        Types.ExecuteWebhook.init("deploy with file"),
        &webhook_files,
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30/tok%20en", memory.last_request.?.url);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "multipart/form-data; boundary=discord-zig-boundary",
        memory.last_request.?.content_type.?,
    );
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"content\":\"deploy with file\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "name=\"files[0]\"; filename=\"deploy.txt\"") != null);

    _ = try client.getWebhookMessage(Snowflake.init(30), "tok en", Snowflake.init(50));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30/tok%20en/messages/50", memory.last_request.?.url);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);

    _ = try client.fetchWebhookMessage(Snowflake.init(30), "tok en", Snowflake.init(50));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30/tok%20en/messages/50", memory.last_request.?.url);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);

    _ = try client.editWebhookMessage(
        Snowflake.init(30),
        "tok en",
        Snowflake.init(50),
        Types.EditMessage.init().withContent("edited webhook"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30/tok%20en/messages/50", memory.last_request.?.url);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings("{\"content\":\"edited webhook\"}", memory.last_request.?.body.?);

    _ = try client.deleteWebhookMessage(Snowflake.init(30), "tok en", Snowflake.init(50));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/30/tok%20en/messages/50", memory.last_request.?.url);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);

    _ = try client.fetchGlobalApplicationCommands(Snowflake.init(40));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/commands", memory.last_request.?.url);

    _ = try client.registerGlobalApplicationCommand(
        Snowflake.init(40),
        Interactions.ApplicationCommand.chatInput("ping", "Replies with pong"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/commands", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"ping\",\"description\":\"Replies with pong\",\"type\":1}",
        memory.last_request.?.body.?,
    );

    _ = try client.bulkOverwriteGlobalApplicationCommands(Snowflake.init(40), &.{
        Interactions.ApplicationCommand.chatInput("ping", "Replies with pong"),
    });
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/commands", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "[{\"name\":\"ping\",\"description\":\"Replies with pong\",\"type\":1}]",
        memory.last_request.?.body.?,
    );

    _ = try client.setGlobalApplicationCommands(Snowflake.init(40), &.{
        Interactions.ApplicationCommand.chatInput("ping", "Replies with pong"),
    });
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/commands", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "[{\"name\":\"ping\",\"description\":\"Replies with pong\",\"type\":1}]",
        memory.last_request.?.body.?,
    );

    _ = try client.fetchGlobalApplicationCommand(Snowflake.init(40), Snowflake.init(60));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/commands/60", memory.last_request.?.url);

    _ = try client.updateGlobalApplicationCommand(
        Snowflake.init(40),
        Snowflake.init(60),
        Interactions.EditApplicationCommand.init().withDescription("Updated global"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/commands/60", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"description\":\"Updated global\"}", memory.last_request.?.body.?);

    _ = try client.renameGlobalApplicationCommand(Snowflake.init(40), Snowflake.init(60), "pong");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/commands/60", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"pong\"}", memory.last_request.?.body.?);

    _ = try client.setGlobalApplicationCommandDescription(Snowflake.init(40), Snowflake.init(60), "Replies with pong");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/commands/60", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"description\":\"Replies with pong\"}", memory.last_request.?.body.?);

    _ = try client.removeGlobalApplicationCommand(Snowflake.init(40), Snowflake.init(60));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/commands/60", memory.last_request.?.url);

    _ = try client.fetchGuildApplicationCommands(Snowflake.init(40), Snowflake.init(50));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/guilds/50/commands", memory.last_request.?.url);

    _ = try client.registerGuildApplicationCommand(
        Snowflake.init(40),
        Snowflake.init(50),
        Interactions.ApplicationCommand.chatInput("echo", "Echoes text"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/guilds/50/commands", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"echo\",\"description\":\"Echoes text\",\"type\":1}",
        memory.last_request.?.body.?,
    );

    _ = try client.bulkOverwriteGuildApplicationCommands(Snowflake.init(40), Snowflake.init(50), &.{
        Interactions.ApplicationCommand.chatInput("echo", "Echoes text"),
    });
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/guilds/50/commands", memory.last_request.?.url);

    _ = try client.setGuildApplicationCommands(Snowflake.init(40), Snowflake.init(50), &.{
        Interactions.ApplicationCommand.chatInput("echo", "Echoes text"),
    });
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/guilds/50/commands", memory.last_request.?.url);

    _ = try client.fetchGuildApplicationCommand(Snowflake.init(40), Snowflake.init(50), Snowflake.init(60));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/guilds/50/commands/60", memory.last_request.?.url);

    _ = try client.editGuildApplicationCommand(
        Snowflake.init(40),
        Snowflake.init(50),
        Snowflake.init(60),
        Interactions.EditApplicationCommand.init().withDescription("Updated"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/guilds/50/commands/60", memory.last_request.?.url);

    _ = try client.updateGuildApplicationCommand(
        Snowflake.init(40),
        Snowflake.init(50),
        Snowflake.init(60),
        Interactions.EditApplicationCommand.init().withDescription("Updated guild"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/guilds/50/commands/60", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"description\":\"Updated guild\"}", memory.last_request.?.body.?);

    _ = try client.renameGuildApplicationCommand(Snowflake.init(40), Snowflake.init(50), Snowflake.init(60), "guild-pong");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/guilds/50/commands/60", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"guild-pong\"}", memory.last_request.?.body.?);

    _ = try client.setGuildApplicationCommandDescription(
        Snowflake.init(40),
        Snowflake.init(50),
        Snowflake.init(60),
        "Guild command",
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/guilds/50/commands/60", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"description\":\"Guild command\"}", memory.last_request.?.body.?);
}
