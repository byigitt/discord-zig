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

test "REST soundboard helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.listDefaultSoundboardSounds();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/soundboard-default-sounds",
        memory.last_request.?.url,
    );

    _ = try client.listGuildSoundboardSounds(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/soundboard-sounds",
        memory.last_request.?.url,
    );

    _ = try client.getGuildSoundboardSound(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/soundboard-sounds/20",
        memory.last_request.?.url,
    );

    _ = try client.createGuildSoundboardSound(
        Snowflake.init(10),
        Types.CreateGuildSoundboardSound.init("launch", "data:audio/ogg;base64,T0dH")
            .withVolume(0.5)
            .withEmojiId(Snowflake.init(30)),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/soundboard-sounds",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"launch\",\"sound\":\"data:audio/ogg;base64,T0dH\",\"volume\":0.5,\"emoji_id\":\"30\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.editGuildSoundboardSound(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.EditGuildSoundboardSound.init().withName("ship").clearEmojiName(),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/soundboard-sounds/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"ship\",\"emoji_name\":null}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteGuildSoundboardSound(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/soundboard-sounds/20",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);
}

test "REST member role helpers use expected routes" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 204,
        .body = "",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.addGuildMemberRole(Snowflake.init(10), Snowflake.init(20), Snowflake.init(30));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/members/20/roles/30",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.removeGuildMemberRole(Snowflake.init(10), Snowflake.init(20), Snowflake.init(30));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/members/20/roles/30",
        memory.last_request.?.url,
    );
}

test "REST member moderation helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 204,
        .body = "",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.listGuildMembers(
        Snowflake.init(10),
        Types.ListGuildMembers.init().withLimit(100).afterMember(Snowflake.init(20)),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/members?limit=100&after=20",
        memory.last_request.?.url,
    );

    _ = try client.searchGuildMembers(Snowflake.init(10), Types.SearchGuildMembers.init("baris dev").withLimit(25));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/members/search?query=baris%20dev&limit=25",
        memory.last_request.?.url,
    );

    const roles = [_]Snowflake{Snowflake.init(30)};
    _ = try client.addGuildMember(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.AddGuildMember.init("oauth-access")
            .withNick("helper")
            .withRoles(&roles)
            .muteState(false),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/members/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"access_token\":\"oauth-access\",\"nick\":\"helper\",\"roles\":[\"30\"],\"mute\":false}",
        memory.last_request.?.body.?,
    );

    _ = try client.editGuildMember(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.EditGuildMember.init()
            .withRoles(&roles)
            .muteState(false),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/members/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"roles\":[\"30\"],\"mute\":false}",
        memory.last_request.?.body.?,
    );

    _ = try client.editCurrentGuildMember(
        Snowflake.init(10),
        Types.EditCurrentGuildMember.init()
            .withNick("ziggy")
            .clearAvatar(),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"nick\":\"ziggy\",\"avatar\":null}", memory.last_request.?.body.?);

    _ = try client.editCurrentUserNick(Snowflake.init(10), Types.EditCurrentUserNick.init().clearNick());
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me/nick", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"nick\":null}", memory.last_request.?.body.?);

    _ = try client.removeGuildMember(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/members/20",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.listGuildBans(
        Snowflake.init(10),
        Types.ListGuildBans.init().beforeUser(Snowflake.init(30)).withLimit(25),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/bans?before=30&limit=25",
        memory.last_request.?.url,
    );

    _ = try client.getGuildBan(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/bans/20",
        memory.last_request.?.url,
    );

    _ = try client.getGuildPruneCount(
        Snowflake.init(10),
        Types.GetGuildPruneCount.init()
            .withDays(14)
            .withRoles(&.{ Snowflake.init(30), Snowflake.init(40) }),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/prune?days=14&include_roles=30,40",
        memory.last_request.?.url,
    );

    _ = try client.beginGuildPrune(
        Snowflake.init(10),
        Types.BeginGuildPrune.init()
            .withDays(14)
            .computeCount(false)
            .withRoles(&.{Snowflake.init(30)}),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/prune",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"days\":14,\"compute_prune_count\":false,\"include_roles\":[\"30\"]}",
        memory.last_request.?.body.?,
    );

    _ = try client.createGuildBan(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.CreateGuildBan.init().deleteMessagesFor(60),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/bans/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"delete_message_seconds\":60}",
        memory.last_request.?.body.?,
    );

    const bulk_user_ids = [_]Snowflake{ Snowflake.init(20), Snowflake.init(30) };
    _ = try client.bulkGuildBan(Snowflake.init(10), Types.BulkGuildBan.init(&bulk_user_ids).deleteMessagesFor(120));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/bulk-ban",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"user_ids\":[\"20\",\"30\"],\"delete_message_seconds\":120}",
        memory.last_request.?.body.?,
    );

    _ = try client.removeGuildBan(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/bans/20",
        memory.last_request.?.url,
    );
}

test "REST bulkOverwriteGlobalApplicationCommands serializes command array" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "[]",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.bulkOverwriteGlobalApplicationCommands(Snowflake.init(987), &.{
        Interactions.ApplicationCommand.chatInput("ping", "Replies with pong"),
    });

    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/987/commands",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "[{\"name\":\"ping\",\"description\":\"Replies with pong\",\"type\":1}]",
        memory.last_request.?.body.?,
    );
}

test "REST guild application command helpers use expected routes" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "[]",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.listGuildApplicationCommands(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/guilds/20/commands",
        memory.last_request.?.url,
    );

    _ = try client.createGuildApplicationCommand(
        Snowflake.init(10),
        Snowflake.init(20),
        Interactions.ApplicationCommand.chatInput("ping", "Replies with pong"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "{\"name\":\"ping\",\"description\":\"Replies with pong\",\"type\":1}",
        memory.last_request.?.body.?,
    );

    _ = try client.bulkOverwriteGuildApplicationCommands(Snowflake.init(10), Snowflake.init(20), &.{
        Interactions.ApplicationCommand.chatInput("echo", "Echoes text"),
    });
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "[{\"name\":\"echo\",\"description\":\"Echoes text\",\"type\":1}]",
        memory.last_request.?.body.?,
    );

    _ = try client.getGuildApplicationCommand(Snowflake.init(10), Snowflake.init(20), Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/guilds/20/commands/30",
        memory.last_request.?.url,
    );

    _ = try client.deleteGuildApplicationCommand(Snowflake.init(10), Snowflake.init(20), Snowflake.init(30));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
}
