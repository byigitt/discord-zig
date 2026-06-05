const std = @import("std");
const Api = @import("../../core/api.zig");
const Routes = @import("../routes.zig");
const Types = @import("../../models/types.zig");
const Interactions = @import("../../interactions/mod.zig");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;

const Root = @import("../client.zig");
const Header = Root.Header;
const Request = Root.Request;
const BodyStream = Root.BodyStream;
const Response = Root.Response;
const Transport = Root.Transport;
const RateLimitState = Root.RateLimitState;
const Client = Root.Client;
const MultipartFilePathStream = Root.MultipartFilePathStream;
const writeMessageMultipart = Root.writeMessageMultipart;
const writeExecuteWebhookMultipart = Root.writeExecuteWebhookMultipart;
const writeGuildStickerMultipart = Root.writeGuildStickerMultipart;
const writeInviteTargetUsersMultipart = Root.writeInviteTargetUsersMultipart;
const writeMessageMultipartFilePaths = Root.writeMessageMultipartFilePaths;
const writeMessageMultipartFilePathMetadata = Root.writeMessageMultipartFilePathMetadata;
const writeMultipartPayloadJson = Root.writeMultipartPayloadJson;
const writeMultipartTextField = Root.writeMultipartTextField;
const writeMultipartFileHeader = Root.writeMultipartFileHeader;
const writeMultipartQuoted = Root.writeMultipartQuoted;
const MemoryTransport = Root.MemoryTransport;

test "REST createMessage serializes payload and records rate limit headers" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{\"id\":\"1\"}",
        .headers = &.{
            .{ .name = "X-RateLimit-Remaining", .value = "4" },
            .{ .name = "X-RateLimit-Reset-After", .value = "0.250" },
            .{ .name = "X-RateLimit-Bucket", .value = "bucket-a" },
        },
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    const result = try client.createMessage(Snowflake.init(123), Types.CreateMessage.init("pong"));
    try std.testing.expectEqual(@as(u16, 200), result.status);
    try std.testing.expect(memory.last_request != null);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/123/messages", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"pong\"}", memory.last_request.?.body.?);

    const state = client.rate_limits.get("POST:/channels/{channel_id}/messages:123").?;
    try std.testing.expectEqual(@as(u32, 4), state.remaining.?);
    try std.testing.expectEqual(@as(u64, 250), state.reset_after_ms.?);
    try std.testing.expectEqualStrings("bucket-a", state.bucket.?);
    try std.testing.expect(state.bucket.?.ptr != memory.response.headers[2].value.ptr);
}

test "REST createInteractionResponse serializes callback payload" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 204,
        .body = "",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    const result = try client.createInteractionResponse(
        Snowflake.init(99),
        "interaction-token",
        Interactions.InteractionResponse.message("pong"),
    );
    try std.testing.expectEqual(@as(u16, 204), result.status);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/interactions/99/interaction-token/callback",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"type\":4,\"data\":{\"content\":\"pong\"}}",
        memory.last_request.?.body.?,
    );

    const choices = [_]Interactions.CommandChoice{
        Interactions.CommandChoice.string("Public", "public"),
    };
    _ = try client.createInteractionResponse(
        Snowflake.init(99),
        "interaction-token",
        Interactions.InteractionResponse.autocomplete(&choices),
    );
    try std.testing.expectEqualStrings(
        "{\"type\":8,\"data\":{\"choices\":[{\"name\":\"Public\",\"value\":\"public\"}]}}",
        memory.last_request.?.body.?,
    );
}

test "REST interaction webhook helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot token", memory.transport());
    defer client.deinit();

    _ = try client.getOriginalInteractionResponse(Snowflake.init(77), "tok en");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/77/tok%20en/messages/@original",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.editOriginalInteractionResponse(
        Snowflake.init(77),
        "tok en",
        Types.EditMessage.init().withContent("done"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/77/tok%20en/messages/@original",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"content\":\"done\"}", memory.last_request.?.body.?);

    _ = try client.createFollowupMessage(
        Snowflake.init(77),
        "tok en",
        Types.ExecuteWebhook.init("follow up"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/77/tok%20en",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"content\":\"follow up\"}", memory.last_request.?.body.?);

    _ = try client.getFollowupMessage(Snowflake.init(77), "tok en", Snowflake.init(99));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/77/tok%20en/messages/99",
        memory.last_request.?.url,
    );

    _ = try client.editFollowupMessage(
        Snowflake.init(77),
        "tok en",
        Snowflake.init(99),
        Types.EditMessage.init().withContent("updated"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/77/tok%20en/messages/99",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"content\":\"updated\"}", memory.last_request.?.body.?);

    _ = try client.deleteFollowupMessage(Snowflake.init(77), "tok en", Snowflake.init(99));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/77/tok%20en/messages/99",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.deleteOriginalInteractionResponse(Snowflake.init(77), "tok en");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/77/tok%20en/messages/@original",
        memory.last_request.?.url,
    );
}

test "REST get and delete message use expected routes" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.getMessage(Snowflake.init(123), Snowflake.init(456));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/456",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.listMessagesWithOptions(
        Snowflake.init(123),
        Types.ListMessages.afterMessage(Snowflake.init(111)).withLimit(25),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages?after=111&limit=25",
        memory.last_request.?.url,
    );

    const messages = [_]Snowflake{ Snowflake.init(111), Snowflake.init(222) };
    _ = try client.bulkDeleteMessages(Snowflake.init(123), &messages);
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/bulk-delete",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"messages\":[\"111\",\"222\"]}",
        memory.last_request.?.body.?,
    );

    _ = try client.triggerTyping(Snowflake.init(123));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/typing",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.deleteMessage(Snowflake.init(123), Snowflake.init(456));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/456",
        memory.last_request.?.url,
    );
}

test "REST pin message helpers use expected routes" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.listPinnedMessages(Snowflake.init(123));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/pins",
        memory.last_request.?.url,
    );

    _ = try client.listChannelPins(
        Snowflake.init(123),
        Types.ListChannelPins.beforeTimestamp("2026-06-02T10:00:00.000Z").withLimit(25),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/pins?before=2026-06-02T10%3A00%3A00.000Z&limit=25",
        memory.last_request.?.url,
    );

    _ = try client.pinMessage(Snowflake.init(123), Snowflake.init(456));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/pins/456",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.unpinMessage(Snowflake.init(123), Snowflake.init(456));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/pins/456",
        memory.last_request.?.url,
    );
}

test "REST thread creation helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.createThread(
        Snowflake.init(10),
        Types.CreateThread.init("private")
            .withType(.private_thread)
            .invitableState(false),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/threads",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"private\",\"type\":12,\"invitable\":false}",
        memory.last_request.?.body.?,
    );

    _ = try client.createThreadFromMessage(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.CreateThreadFromMessage.init("debug").withAutoArchiveDuration(1440),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/threads",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"debug\",\"auto_archive_duration\":1440}",
        memory.last_request.?.body.?,
    );
}

test "REST guild lifecycle and group DM helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();
    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.createGuild(Types.CreateGuild.init("zig"));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"zig\"}", memory.last_request.?.body.?);

    _ = try client.createGuildFromTemplate("starter pack", Types.CreateGuildFromTemplate.init("templated"));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/templates/starter%20pack",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"name\":\"templated\"}", memory.last_request.?.body.?);

    _ = try client.deleteGuild(Snowflake.init(99));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/99", memory.last_request.?.url);

    _ = try client.addGroupDmRecipient(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.AddGroupDmRecipient.init("oauth").withNick("zig"),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/recipients/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"access_token\":\"oauth\",\"nick\":\"zig\"}", memory.last_request.?.body.?);

    _ = try client.removeGroupDmRecipient(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/recipients/20",
        memory.last_request.?.url,
    );
}

test "REST forum thread helper serializes initial message" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();
    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    const tags = [_]Snowflake{Snowflake.init(55)};
    _ = try client.createForumThread(
        Snowflake.init(10),
        Types.CreateForumThread.init("help", Types.ForumThreadMessage.init("first")).withAppliedTags(&tags),
    );

    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/threads", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"help\",\"message\":{\"content\":\"first\"},\"applied_tags\":[\"55\"]}",
        memory.last_request.?.body.?,
    );
}
