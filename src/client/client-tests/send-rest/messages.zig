const std = @import("std");
const Rest = @import("../../../rest/client.zig");
const Types = @import("../../../models/types.zig");
const Snowflake = @import("../../../core/snowflake.zig").Snowflake;
const Root = @import("../../client.zig");
const Client = Root.Client;

test "client send and edit message conveniences hit REST routes" {
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

    _ = try client.sendMessage(Snowflake.init(10), Types.CreateMessage.init("hello"));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"hello\"}", memory.last_request.?.body.?);

    _ = try client.sendMessageWithContent(Snowflake.init(10), "hello shortcut");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"hello shortcut\"}", memory.last_request.?.body.?);

    _ = try client.sendContent(Snowflake.init(10), "content alias");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"content alias\"}", memory.last_request.?.body.?);

    _ = try client.sendText(Snowflake.init(10), "text alias");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"text alias\"}", memory.last_request.?.body.?);

    _ = try client.send(Snowflake.init(10), Types.CreateMessage.init("alias"));
    try std.testing.expectEqualStrings("{\"content\":\"alias\"}", memory.last_request.?.body.?);

    _ = try client.reply(Snowflake.init(10), Snowflake.init(20), Types.CreateMessage.init("reply"));
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"message_reference\"") != null);

    _ = try client.replyMessage(Snowflake.init(10), Snowflake.init(20), Types.CreateMessage.init("reply alias"));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages", memory.last_request.?.url);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"message_reference\"") != null);

    _ = try client.replyWithContent(Snowflake.init(10), Snowflake.init(20), "reply shortcut");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages", memory.last_request.?.url);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"content\":\"reply shortcut\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"message_reference\"") != null);

    _ = try client.replyMessageWithContent(Snowflake.init(10), Snowflake.init(20), "reply message shortcut");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages", memory.last_request.?.url);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"content\":\"reply message shortcut\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"message_reference\"") != null);

    _ = try client.replyText(Snowflake.init(10), Snowflake.init(20), "reply text shortcut");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages", memory.last_request.?.url);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"content\":\"reply text shortcut\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"message_reference\"") != null);

    _ = try client.forwardMessage(Snowflake.init(11), Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/11/messages", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"message_reference\":{\"type\":1,\"message_id\":\"20\",\"channel_id\":\"10\"}}",
        memory.last_request.?.body.?,
    );

    _ = try client.forward(Snowflake.init(11), Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/11/messages", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"message_reference\":{\"type\":1,\"message_id\":\"20\",\"channel_id\":\"10\"}}",
        memory.last_request.?.body.?,
    );

    _ = try client.getMessage(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20", memory.last_request.?.url);

    _ = try client.fetchMessage(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20", memory.last_request.?.url);

    _ = try client.edit(Snowflake.init(10), Snowflake.init(20), Types.EditMessage.init().withContent("edited alias"));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"edited alias\"}", memory.last_request.?.body.?);

    _ = try client.editMessageWithContent(Snowflake.init(10), Snowflake.init(20), "edited shortcut");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"edited shortcut\"}", memory.last_request.?.body.?);

    _ = try client.editWithContent(Snowflake.init(10), Snowflake.init(20), "edited content alias");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"edited content alias\"}", memory.last_request.?.body.?);

    _ = try client.editText(Snowflake.init(10), Snowflake.init(20), "edited text alias");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"edited text alias\"}", memory.last_request.?.body.?);

    _ = try client.setEmbedsSuppressed(Snowflake.init(10), Snowflake.init(20), true);
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"flags\":4}", memory.last_request.?.body.?);

    _ = try client.suppressEmbeds(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("{\"flags\":4}", memory.last_request.?.body.?);

    _ = try client.unsuppressEmbeds(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("{\"flags\":0}", memory.last_request.?.body.?);

    _ = try client.deleteMessage(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20", memory.last_request.?.url);

    _ = try client.delete(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20", memory.last_request.?.url);

    _ = try client.crosspostMessage(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20/crosspost", memory.last_request.?.url);

    _ = try client.crosspost(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20/crosspost", memory.last_request.?.url);

    _ = try client.publishMessage(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20/crosspost", memory.last_request.?.url);

    _ = try client.publish(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/20/crosspost", memory.last_request.?.url);

    _ = try client.listMessagesWithOptions(
        Snowflake.init(10),
        Types.ListMessages.beforeMessage(Snowflake.init(20)).withLimit(10),
    );
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages?before=20&limit=10",
        memory.last_request.?.url,
    );

    _ = try client.fetchMessages(
        Snowflake.init(10),
        Types.ListMessages.beforeMessage(Snowflake.init(20)).withLimit(10),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages?before=20&limit=10",
        memory.last_request.?.url,
    );

    const messages = [_]Snowflake{ Snowflake.init(20), Snowflake.init(30) };
    _ = try client.bulkDeleteMessages(Snowflake.init(10), &messages);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/bulk-delete",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"messages\":[\"20\",\"30\"]}", memory.last_request.?.body.?);

    _ = try client.bulkDelete(Snowflake.init(10), &messages);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/bulk-delete",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"messages\":[\"20\",\"30\"]}", memory.last_request.?.body.?);

    _ = try client.sendTyping(Snowflake.init(10));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/typing", memory.last_request.?.url);
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.triggerTyping(Snowflake.init(10));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/typing", memory.last_request.?.url);
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.listChannelPins(Snowflake.init(10), Types.ListChannelPins.init().withLimit(10));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/pins?limit=10", memory.last_request.?.url);

    _ = try client.fetchPinnedMessages(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/pins", memory.last_request.?.url);

    _ = try client.fetchPins(Snowflake.init(10), Types.ListChannelPins.init().withLimit(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/pins?limit=10", memory.last_request.?.url);

    _ = try client.pinMessage(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/pins/20", memory.last_request.?.url);

    _ = try client.pin(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/pins/20", memory.last_request.?.url);

    _ = try client.unpinMessage(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);

    _ = try client.unpin(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages/pins/20", memory.last_request.?.url);

    _ = try client.fetchGateway();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/gateway", memory.last_request.?.url);

    _ = try client.fetchGatewayBot();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bot test", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/gateway/bot", memory.last_request.?.url);

    _ = try client.fetchCurrentApplication();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/@me", memory.last_request.?.url);

    _ = try client.fetchCurrentBotApplication();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bot test", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/oauth2/applications/@me", memory.last_request.?.url);

    _ = try client.editCurrentApplication(Types.EditCurrentApplication.init()
        .withDescription("Fast Zig bot")
        .withEventWebhooksStatus(.disabled));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"description\":\"Fast Zig bot\",\"event_webhooks_status\":1}",
        memory.last_request.?.body.?,
    );

    _ = try client.setCurrentApplicationDescription("Fast Zig bot");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"description\":\"Fast Zig bot\"}", memory.last_request.?.body.?);

    _ = try client.setCurrentApplicationIcon("data:image/png;base64,AAAA");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"icon\":\"data:image/png;base64,AAAA\"}", memory.last_request.?.body.?);

    _ = try client.clearCurrentApplicationIcon();
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"icon\":null}", memory.last_request.?.body.?);

    _ = try client.setCurrentApplicationCoverImage("data:image/png;base64,CCCC");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"cover_image\":\"data:image/png;base64,CCCC\"}", memory.last_request.?.body.?);

    _ = try client.clearCurrentApplicationCoverImage();
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"cover_image\":null}", memory.last_request.?.body.?);

    _ = try client.getCurrentUser();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);

    _ = try client.fetchCurrentUser();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);

    _ = try client.getMe();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);

    _ = try client.fetchMe();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);

    _ = try client.getUser(Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/20", memory.last_request.?.url);

    _ = try client.fetchUser(Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/20", memory.last_request.?.url);

    _ = try client.editCurrentUser(
        Types.EditCurrentUser.init()
            .withUsername("zigbot")
            .clearAvatar(),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"username\":\"zigbot\",\"avatar\":null}", memory.last_request.?.body.?);

    _ = try client.setCurrentUsername("zigbot");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"username\":\"zigbot\"}", memory.last_request.?.body.?);

    _ = try client.setCurrentUserAvatar("data:image/png;base64,BBBB");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"avatar\":\"data:image/png;base64,BBBB\"}", memory.last_request.?.body.?);

    _ = try client.clearCurrentUserAvatar();
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"avatar\":null}", memory.last_request.?.body.?);
}
