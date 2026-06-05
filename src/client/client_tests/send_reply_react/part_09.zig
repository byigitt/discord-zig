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

test "client convenience send reply and react delegate to REST part 9" {
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
    _ = try client.deleteAllReactionsForEmoji(Snowflake.init(10), Snowflake.init(20), "👍");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/messages/20/reactions/%F0%9F%91%8D",
        memory.last_request.?.url,
    );

    _ = try client.listPollAnswerVoters(
        Snowflake.init(10),
        Snowflake.init(20),
        1,
        Types.ListPollAnswerVoters.init().withLimit(10),
    );
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/polls/20/answers/1?limit=10",
        memory.last_request.?.url,
    );

    _ = try client.fetchPollAnswerVoters(
        Snowflake.init(10),
        Snowflake.init(20),
        1,
        Types.ListPollAnswerVoters.init().withLimit(10),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/polls/20/answers/1?limit=10",
        memory.last_request.?.url,
    );

    _ = try client.endPoll(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/polls/20/expire",
        memory.last_request.?.url,
    );
}
