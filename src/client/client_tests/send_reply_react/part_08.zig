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

test "client convenience send reply and react delegate to REST part 8" {
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
    _ = try client.removeGuildApplicationCommand(Snowflake.init(40), Snowflake.init(50), Snowflake.init(60));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/40/guilds/50/commands/60", memory.last_request.?.url);

    const command_permissions = [_]Interactions.ApplicationCommandPermission{
        Interactions.ApplicationCommandPermission.role(Snowflake.init(70), true),
    };

    _ = try client.fetchGuildApplicationCommandPermissions(
        "Bearer user-token",
        Snowflake.init(40),
        Snowflake.init(50),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/40/guilds/50/commands/permissions",
        memory.last_request.?.url,
    );

    _ = try client.fetchApplicationCommandPermissions(
        "Bearer user-token",
        Snowflake.init(40),
        Snowflake.init(50),
        Snowflake.init(60),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/40/guilds/50/commands/60/permissions",
        memory.last_request.?.url,
    );

    _ = try client.editApplicationCommandPermissions(
        "Bearer user-token",
        Snowflake.init(40),
        Snowflake.init(50),
        Snowflake.init(60),
        &command_permissions,
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/40/guilds/50/commands/60/permissions",
        memory.last_request.?.url,
    );

    _ = try client.createInteractionResponse(
        Snowflake.init(80),
        "tok en",
        Interactions.InteractionResponse.message("ack"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/interactions/80/tok%20en/callback", memory.last_request.?.url);

    _ = try client.replyInteraction(
        Snowflake.init(80),
        "tok en",
        Interactions.InteractionResponse.message("reply").ephemeralState(true),
    );
    try std.testing.expectEqualStrings("{\"type\":4,\"data\":{\"content\":\"reply\",\"flags\":64}}", memory.last_request.?.body.?);

    _ = try client.deferInteractionReply(Snowflake.init(80), "tok en", true);
    try std.testing.expectEqualStrings("{\"type\":5,\"data\":{\"flags\":64}}", memory.last_request.?.body.?);

    _ = try client.deferInteractionUpdate(Snowflake.init(80), "tok en");
    try std.testing.expectEqualStrings("{\"type\":6}", memory.last_request.?.body.?);

    _ = try client.updateInteractionMessage(
        Snowflake.init(80),
        "tok en",
        Interactions.InteractionResponse.updateMessage("updated"),
    );
    try std.testing.expectEqualStrings("{\"type\":7,\"data\":{\"content\":\"updated\"}}", memory.last_request.?.body.?);

    const autocomplete_choices = [_]Interactions.CommandChoice{
        Interactions.CommandChoice.string("Public", "public"),
    };
    _ = try client.autocompleteInteraction(Snowflake.init(80), "tok en", &autocomplete_choices);
    try std.testing.expectEqualStrings(
        "{\"type\":8,\"data\":{\"choices\":[{\"name\":\"Public\",\"value\":\"public\"}]}}",
        memory.last_request.?.body.?,
    );

    const modal_inputs = [_]Interactions.Component{
        .{ .text_input = Interactions.TextInput.short("name", "Name") },
    };
    const modal_rows = [_]Interactions.Component{
        Interactions.Component.actionRow(&modal_inputs),
    };
    _ = try client.showModal(
        Snowflake.init(80),
        "tok en",
        Interactions.InteractionResponse.modal("profile", "Profile", &modal_rows),
    );
    try std.testing.expectEqualStrings(
        "{\"type\":9,\"data\":{\"custom_id\":\"profile\",\"title\":\"Profile\",\"components\":[{\"type\":1,\"components\":[{\"type\":4,\"custom_id\":\"name\",\"label\":\"Name\",\"style\":1}]}]}}",
        memory.last_request.?.body.?,
    );

    _ = try client.editOriginalInteractionResponse(
        Snowflake.init(40),
        "tok en",
        Types.EditMessage.init().withContent("done"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/40/tok%20en/messages/@original",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"content\":\"done\"}", memory.last_request.?.body.?);

    _ = try client.fetchOriginalInteractionResponse(Snowflake.init(40), "tok en");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/40/tok%20en/messages/@original",
        memory.last_request.?.url,
    );

    try std.testing.expectError(error.MissingCurrentApplication, client.fetchInteractionReply("tok en"));
    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":30,\"t\":\"READY\",\"d\":{\"session_id\":\"abc\",\"application\":{\"id\":\"40\",\"name\":\"app\"}}}",
    );

    _ = try client.fetchInteractionReply("tok en");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/40/tok%20en/messages/@original",
        memory.last_request.?.url,
    );

    _ = try client.editInteractionReply("tok en", Types.EditMessage.init().withContent("edited reply"));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("{\"content\":\"edited reply\"}", memory.last_request.?.body.?);

    _ = try client.deleteInteractionReply("tok en");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/40/tok%20en/messages/@original",
        memory.last_request.?.url,
    );

    _ = try client.createFollowupMessage(
        Snowflake.init(40),
        "tok en",
        Types.ExecuteWebhook.init("follow up"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/40/tok%20en", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"follow up\"}", memory.last_request.?.body.?);

    _ = try client.createFollowupMessageWithContent(Snowflake.init(40), "tok en", "follow up shortcut");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/40/tok%20en", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"follow up shortcut\"}", memory.last_request.?.body.?);

    _ = try client.fetchFollowupMessage(Snowflake.init(40), "tok en", Snowflake.init(50));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/40/tok%20en/messages/50",
        memory.last_request.?.url,
    );

    _ = try client.followUpInteraction("tok en", Types.ExecuteWebhook.init("follow up alias"));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/40/tok%20en", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"follow up alias\"}", memory.last_request.?.body.?);

    _ = try client.followUpInteractionWithContent("tok en", "follow up content alias");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/webhooks/40/tok%20en", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"content\":\"follow up content alias\"}", memory.last_request.?.body.?);

    _ = try client.fetchFollowUpInteraction("tok en", Snowflake.init(50));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/40/tok%20en/messages/50",
        memory.last_request.?.url,
    );

    _ = try client.editFollowUpInteraction(
        "tok en",
        Snowflake.init(50),
        Types.EditMessage.init().withContent("edited follow up"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/40/tok%20en/messages/50",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"content\":\"edited follow up\"}", memory.last_request.?.body.?);

    _ = try client.deleteFollowUpInteraction("tok en", Snowflake.init(50));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/40/tok%20en/messages/50",
        memory.last_request.?.url,
    );

    _ = try client.deleteFollowupMessage(Snowflake.init(40), "tok en", Snowflake.init(50));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/webhooks/40/tok%20en/messages/50",
        memory.last_request.?.url,
    );

    _ = try client.react(Snowflake.init(10), Snowflake.init(20), "👍");
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions/%F0%9F%91%8D/@me",
        memory.last_request.?.url,
    );

    _ = try client.addReaction(Snowflake.init(10), Snowflake.init(20), "👍");
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions/%F0%9F%91%8D/@me",
        memory.last_request.?.url,
    );

    _ = try client.unreact(Snowflake.init(10), Snowflake.init(20), "👍");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions/%F0%9F%91%8D/@me",
        memory.last_request.?.url,
    );

    _ = try client.deleteOwnReaction(Snowflake.init(10), Snowflake.init(20), "👍");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions/%F0%9F%91%8D/@me",
        memory.last_request.?.url,
    );

    _ = try client.removeUserReaction(Snowflake.init(10), Snowflake.init(20), "👍", Snowflake.init(30));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions/%F0%9F%91%8D/30",
        memory.last_request.?.url,
    );

    _ = try client.removeReaction(Snowflake.init(10), Snowflake.init(20), "👍", Snowflake.init(30));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions/%F0%9F%91%8D/30",
        memory.last_request.?.url,
    );

    _ = try client.listReactions(
        Snowflake.init(10),
        Snowflake.init(20),
        "👍",
        Types.ListReactions.init().withLimit(10).withType(.normal),
    );
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions/%F0%9F%91%8D?limit=10&type=0",
        memory.last_request.?.url,
    );

    _ = try client.fetchReactions(
        Snowflake.init(10),
        Snowflake.init(20),
        "👍",
        Types.ListReactions.init().withLimit(10).withType(.normal),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions/%F0%9F%91%8D?limit=10&type=0",
        memory.last_request.?.url,
    );

    _ = try client.clearReactions(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions",
        memory.last_request.?.url,
    );

    _ = try client.deleteAllReactions(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions",
        memory.last_request.?.url,
    );

    _ = try client.removeAllReactions(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions",
        memory.last_request.?.url,
    );

    _ = try client.clearReactionsForEmoji(Snowflake.init(10), Snowflake.init(20), "👍");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions/%F0%9F%91%8D",
        memory.last_request.?.url,
    );
}
