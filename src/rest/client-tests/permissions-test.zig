const std = @import("std");
const Api = @import("../../core/api.zig");
const Routes = @import("../routes.zig");
const Types = @import("../../models/types.zig");
const Interactions = @import("../../interactions/mod.zig");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;

const Root = @import("../client.zig");
const Client = Root.Client;
const writeMessageMultipart = Root.writeMessageMultipart;
const MemoryTransport = Root.MemoryTransport;

test "REST application command edit helpers serialize patch payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.editGlobalApplicationCommand(
        Snowflake.init(10),
        Snowflake.init(30),
        Interactions.EditApplicationCommand.init().withDescription("Updated description"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/commands/30",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"description\":\"Updated description\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.editGuildApplicationCommand(
        Snowflake.init(10),
        Snowflake.init(20),
        Snowflake.init(30),
        Interactions.EditApplicationCommand.init().withName("echo"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/guilds/20/commands/30",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"echo\"}",
        memory.last_request.?.body.?,
    );
}

test "REST application command permission helpers use bearer token" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot bot-token", memory.transport());
    defer client.deinit();

    _ = try client.listGuildApplicationCommandPermissions(
        "Bearer user-token",
        Snowflake.init(10),
        Snowflake.init(20),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/guilds/20/commands/permissions",
        memory.last_request.?.url,
    );

    _ = try client.getApplicationCommandPermissions(
        "Bearer user-token",
        Snowflake.init(10),
        Snowflake.init(20),
        Snowflake.init(30),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/guilds/20/commands/30/permissions",
        memory.last_request.?.url,
    );

    const permissions = [_]Interactions.ApplicationCommandPermission{
        Interactions.ApplicationCommandPermission.user(Snowflake.init(40), true),
    };
    _ = try client.editApplicationCommandPermissions(
        "Bearer user-token",
        Snowflake.init(10),
        Snowflake.init(20),
        Snowflake.init(30),
        &permissions,
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "{\"permissions\":[{\"id\":\"40\",\"type\":2,\"permission\":true}]}",
        memory.last_request.?.body.?,
    );
}

test "REST editMessage serializes patch payload" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.editMessage(
        Snowflake.init(123),
        Snowflake.init(456),
        Types.EditMessage.init()
            .withContent("edited")
            .withFlags(Types.MessageFlags.suppress_embeds),
    );

    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/456",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"content\":\"edited\",\"flags\":4}", memory.last_request.?.body.?);
}

test "REST reaction routes use expected methods" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 204,
        .body = "",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.createReaction(Snowflake.init(123), Snowflake.init(456), "👍");
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/456/reactions/%F0%9F%91%8D/@me",
        memory.last_request.?.url,
    );

    _ = try client.deleteOwnReaction(Snowflake.init(123), Snowflake.init(456), "👍");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);

    _ = try client.listReactions(
        Snowflake.init(123),
        Snowflake.init(456),
        "👍",
        Types.ListReactions.afterUser(Snowflake.init(99))
            .withLimit(25)
            .withType(.burst),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/456/reactions/%F0%9F%91%8D?after=99&limit=25&type=1",
        memory.last_request.?.url,
    );

    _ = try client.deleteUserReaction(Snowflake.init(123), Snowflake.init(456), "👍", Snowflake.init(789));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/456/reactions/%F0%9F%91%8D/789",
        memory.last_request.?.url,
    );

    _ = try client.deleteAllReactions(Snowflake.init(123), Snowflake.init(456));
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/456/reactions",
        memory.last_request.?.url,
    );

    _ = try client.deleteAllReactionsForEmoji(Snowflake.init(123), Snowflake.init(456), "👍");
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages/456/reactions/%F0%9F%91%8D",
        memory.last_request.?.url,
    );
}

test "REST poll routes use expected methods" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.listPollAnswerVoters(
        Snowflake.init(123),
        Snowflake.init(456),
        2,
        Types.ListPollAnswerVoters.afterUser(Snowflake.init(789)).withLimit(25),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/polls/456/answers/2?after=789&limit=25",
        memory.last_request.?.url,
    );

    _ = try client.endPoll(Snowflake.init(123), Snowflake.init(456));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/polls/456/expire",
        memory.last_request.?.url,
    );
}

test "writeMessageMultipart emits payload_json and files" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const files = [_]Types.UploadFile{
        Types.UploadFile.init("hello.txt", "hello").withContentType("text/plain"),
    };

    try writeMessageMultipart("test-boundary", Types.CreateMessage.init("with file"), &files, &out.writer);

    try std.testing.expect(std.mem.indexOf(u8, out.written(), "--test-boundary\r\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "name=\"payload_json\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "\"attachments\":[{\"id\":\"0\",\"filename\":\"hello.txt\"}]") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "name=\"files[0]\"; filename=\"hello.txt\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "Content-Type: text/plain\r\n\r\nhello\r\n") != null);
    try std.testing.expect(std.mem.endsWith(u8, out.written(), "--test-boundary--\r\n"));
}

test "REST createMessageWithFiles sends multipart body" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    const files = [_]Types.UploadFile{
        Types.UploadFile.init("hello.txt", "hello").withContentType("text/plain"),
    };

    _ = try client.createMessageWithFiles(Snowflake.init(123), Types.CreateMessage.init("with file"), &files);

    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/123/messages",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "multipart/form-data; boundary=discord-zig-boundary",
        memory.last_request.?.content_type.?,
    );
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "name=\"files[0]\"; filename=\"hello.txt\"") != null);
}

test "REST executeWebhookWithFiles sends multipart body" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    const files = [_]Types.UploadFile{
        Types.UploadFile.init("deploy.txt", "ship").withContentType("text/plain"),
    };

    _ = try client.executeWebhookWithOptionsAndFiles(
        Snowflake.init(123),
        "tok en",
        .{ .wait = true, .thread_id = Snowflake.init(555) },
        Types.ExecuteWebhook.init("with file"),
        &files,
    );

    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/123/tok%20en?wait=true&thread_id=555",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "multipart/form-data; boundary=discord-zig-boundary",
        memory.last_request.?.content_type.?,
    );
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"attachments\":[{\"id\":\"0\",\"filename\":\"deploy.txt\"}]") != null);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "name=\"files[0]\"; filename=\"deploy.txt\"") != null);
}

test "REST createMessageWithFilePaths streams multipart body" {
    const io = std.Io.Threaded.global_single_threaded.io();
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(io, .{ .sub_path = "hello.txt", .data = "hello from disk" });

    var path_buffer: [128]u8 = .{0} ** 128;
    const path = try std.fmt.bufPrint(&path_buffer, ".zig-cache/tmp/{s}/hello.txt", .{tmp.sub_path});

    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    const files = [_]Types.UploadFilePath{
        Types.UploadFilePath.init("hello.txt", path).withContentType("text/plain"),
    };

    _ = try client.createMessageWithFilePaths(Snowflake.init(123), Types.CreateMessage.init("with file"), &files);

    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "multipart/form-data; boundary=discord-zig-boundary",
        memory.last_request.?.content_type.?,
    );
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"attachments\":[{\"id\":\"0\",\"filename\":\"hello.txt\"}]") != null);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "hello from disk\r\n") != null);
}
