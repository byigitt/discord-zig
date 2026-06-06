const std = @import("std");
const Api = @import("../../core/api.zig");
const Routes = @import("../routes.zig");
const Types = @import("../../models/types.zig");
const Interactions = @import("../../interactions/mod.zig");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;

const Root = @import("../client.zig");
const Client = Root.Client;
const writeGuildStickerMultipart = Root.writeGuildStickerMultipart;
const writeInviteTargetUsersMultipart = Root.writeInviteTargetUsersMultipart;
const MemoryTransport = Root.MemoryTransport;

test "REST guild emoji helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.listGuildEmojis(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/emojis",
        memory.last_request.?.url,
    );

    _ = try client.getGuildEmoji(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/emojis/20",
        memory.last_request.?.url,
    );

    const roles = [_]Snowflake{Snowflake.init(30)};
    _ = try client.createGuildEmoji(
        Snowflake.init(10),
        Types.CreateGuildEmoji.init("zig", "data:image/webp;base64,abc").withRoles(&roles),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/emojis",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"zig\",\"image\":\"data:image/webp;base64,abc\",\"roles\":[\"30\"]}",
        memory.last_request.?.body.?,
    );

    _ = try client.editGuildEmoji(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.EditGuildEmoji.init().withName("ziggy").withRoles(&.{}),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/emojis/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"ziggy\",\"roles\":[]}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteGuildEmoji(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/emojis/20",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);
}

test "REST application emoji helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.listApplicationEmojis(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/emojis",
        memory.last_request.?.url,
    );

    _ = try client.getApplicationEmoji(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/emojis/20",
        memory.last_request.?.url,
    );

    _ = try client.createApplicationEmoji(
        Snowflake.init(10),
        Types.CreateApplicationEmoji.init("zig", "data:image/webp;base64,abc"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/emojis",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"zig\",\"image\":\"data:image/webp;base64,abc\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.editApplicationEmoji(Snowflake.init(10), Snowflake.init(20), Types.EditApplicationEmoji.init("ziggy"));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/emojis/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"name\":\"ziggy\"}", memory.last_request.?.body.?);

    _ = try client.deleteApplicationEmoji(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/emojis/20",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.getApplicationActivityInstance(Snowflake.init(10), "abc:def 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/activity-instances/abc%3Adef%20123",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);
}

test "REST lobby helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    const metadata = [_]Types.StringPair{.{ .key = "mode", .value = "duo" }};

    _ = try client.createLobby(Types.CreateLobby.init().withMetadata(&metadata).withIdleTimeout(60));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"metadata\":{\"mode\":\"duo\"},\"idle_timeout_seconds\":60}", memory.last_request.?.body.?);

    _ = try client.getLobby(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10", memory.last_request.?.url);

    _ = try client.editLobby(Snowflake.init(10), Types.EditLobby.init().clearMetadata());
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"metadata\":null}", memory.last_request.?.body.?);

    _ = try client.addLobbyMember(Snowflake.init(10), Snowflake.init(20), Types.UpdateLobbyMember.init().withMetadata(&metadata).withFlags(1));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10/members/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"metadata\":{\"mode\":\"duo\"},\"flags\":1}", memory.last_request.?.body.?);

    const bulk_members = [_]Types.LobbyMember{Types.LobbyMember.init(Snowflake.init(20)).removeState(true)};
    _ = try client.bulkUpdateLobbyMembers(Snowflake.init(10), Types.BulkUpdateLobbyMembers.init(&bulk_members));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10/members/bulk", memory.last_request.?.url);
    try std.testing.expectEqualStrings("[{\"id\":\"20\",\"remove_member\":true}]", memory.last_request.?.body.?);

    _ = try client.removeLobbyMember(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10/members/20", memory.last_request.?.url);

    _ = try client.leaveLobby("Bearer user-token", Snowflake.init(10));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10/members/@me", memory.last_request.?.url);

    _ = try client.linkLobbyChannel("Bearer user-token", Snowflake.init(10), Types.LinkLobbyChannel.init(Snowflake.init(30)));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
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
    try std.testing.expectEqualStrings("Bot test", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/lobbies/10/messages/30/moderation-metadata",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"action\":\"replace\",\"replacement\":\"Be kind\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteLobby(Snowflake.init(10));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/lobbies/10", memory.last_request.?.url);
}

test "writeGuildStickerMultipart emits text fields and file" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try writeGuildStickerMultipart(
        "test-boundary",
        Types.CreateGuildSticker.init("zig", "zap").withDescription("Zig mascot"),
        .{ .filename = "zig.png", .content = "PNG", .content_type = "image/png" },
        &out.writer,
    );

    try std.testing.expect(std.mem.indexOf(u8, out.written(), "name=\"name\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "zig\r\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "name=\"description\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "name=\"tags\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "name=\"file\"; filename=\"zig.png\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "Content-Type: image/png") != null);
    try std.testing.expect(std.mem.endsWith(u8, out.written(), "--test-boundary--\r\n"));
}

test "writeInviteTargetUsersMultipart emits csv file field" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try writeInviteTargetUsersMultipart(
        "test-boundary",
        .{ .filename = "targets.csv", .content = "user_id\n42\n", .content_type = "text/csv" },
        &out.writer,
    );

    try std.testing.expect(std.mem.indexOf(u8, out.written(), "--test-boundary\r\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "name=\"target_users_file\"; filename=\"targets.csv\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "Content-Type: text/csv") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "user_id\n42\n") != null);
    try std.testing.expect(std.mem.endsWith(u8, out.written(), "--test-boundary--\r\n"));
}

test "REST guild sticker helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.getSticker(Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/stickers/20",
        memory.last_request.?.url,
    );

    _ = try client.listStickerPacks();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/sticker-packs",
        memory.last_request.?.url,
    );

    _ = try client.listGuildStickers(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/stickers",
        memory.last_request.?.url,
    );

    _ = try client.getGuildSticker(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/stickers/20",
        memory.last_request.?.url,
    );

    _ = try client.createGuildSticker(
        Snowflake.init(10),
        .{ .name = "zig", .description = "Zig mascot", .tags = "zap" },
        .{ .filename = "zig.png", .content = "PNG", .content_type = "image/png" },
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/stickers",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "multipart/form-data; boundary=discord-zig-boundary",
        memory.last_request.?.content_type.?,
    );
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "name=\"file\"; filename=\"zig.png\"") != null);

    _ = try client.editGuildSticker(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.EditGuildSticker.init().withName("ziggy").withTags("spark"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/stickers/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"ziggy\",\"tags\":\"spark\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteGuildSticker(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/stickers/20",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);
}
