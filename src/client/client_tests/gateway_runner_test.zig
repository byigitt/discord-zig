const std = @import("std");
const Intents = @import("../../core/intents.zig");
const Rest = @import("../../rest/client.zig");
const HttpTransport = @import("../../rest/http_transport.zig").HttpTransport;
const Events = @import("../../gateway/events.zig");
const Gateway = @import("../../gateway/protocol.zig");
const GatewaySession = @import("../../gateway/session.zig");
const CacheModule = @import("../cache.zig");
const Interactions = @import("../../interactions/mod.zig");
const Types = @import("../../models/types.zig");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Root = @import("../client.zig");
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

test "client initHttp owns live REST transport" {
    var client = try Client.initHttp(std.testing.allocator, .{
        .token = "Bot test",
    });
    defer client.destroy();

    try std.testing.expect(client.owned_http_transport != null);
}

test "gateway runner identifies after hello and schedules heartbeat" {
    var gateway_memory = GatewaySession.MemoryTransport.init(std.testing.allocator);
    defer gateway_memory.deinit();
    try gateway_memory.pushIncoming("{\"op\":10,\"d\":{\"heartbeat_interval\":50}}");

    const startup_activities = [_]Gateway.Activity{Gateway.Activity.init("discord.zig", .watching)};
    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
        .presence = Gateway.Presence.init(.idle).withActivities(&startup_activities),
    });
    defer client.deinit();

    var runner = client.createGatewayRunner(gateway_memory.transport());
    defer runner.deinit();

    try std.testing.expectEqual(GatewayStep.identified, try runner.step(100));
    try std.testing.expectEqual(@as(usize, 1), gateway_memory.sent.items.len);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[0], "\"op\":2") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[0], "\"presence\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[0], "\"status\":\"idle\"") != null);
    try std.testing.expectEqual(@as(?u64, 150), runner.next_heartbeat_ms);
    try std.testing.expectEqual(@as(?u64, 150), runner.nextHeartbeatMs());
    try std.testing.expectEqual(@as(?u64, 50), runner.heartbeatIntervalMs());
    try std.testing.expect(!runner.canResume());

    try std.testing.expectEqual(GatewayStep.heartbeat_sent, try runner.step(150));
    try std.testing.expect(runner.awaitingHeartbeatAck());
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[1], "\"op\":1") != null);
    try std.testing.expectEqual(@as(?u64, null), client.gatewayPingMs());

    try gateway_memory.pushIncoming("{\"op\":11,\"d\":null}");
    try std.testing.expectEqual(GatewayStep.heartbeat_ack, try runner.step(175));
    try std.testing.expect(!runner.awaitingHeartbeatAck());
    try std.testing.expectEqual(@as(?u64, 25), client.gatewayPingMs());
}

test "client updates presence through gateway session" {
    var gateway_memory = GatewaySession.MemoryTransport.init(std.testing.allocator);
    defer gateway_memory.deinit();

    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
    });
    defer client.deinit();

    var session = client.createGatewaySession(gateway_memory.transport());
    defer session.deinit();

    const activities = [_]Gateway.Activity{Gateway.Activity.init("discord.zig", .playing)};
    try client.updatePresence(
        &session,
        Gateway.Presence.init(.online).withActivities(&activities),
    );

    try std.testing.expectEqual(@as(usize, 1), gateway_memory.sent.items.len);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[0], "\"op\":3") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[0], "\"status\":\"online\"") != null);

    try client.setPresence(&session, Gateway.Presence.init(.idle));

    try std.testing.expectEqual(@as(usize, 2), gateway_memory.sent.items.len);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[1], "\"op\":3") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[1], "\"status\":\"idle\"") != null);

    try client.setActivity(
        &session,
        "Zig bots",
        SetActivityOptions.init(.watching)
            .withStatus(.dnd)
            .withSince(123)
            .afkState(true),
    );

    try std.testing.expectEqual(@as(usize, 3), gateway_memory.sent.items.len);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[2], "\"op\":3") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[2], "\"name\":\"Zig bots\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[2], "\"type\":3") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[2], "\"since\":123") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[2], "\"status\":\"dnd\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[2], "\"afk\":true") != null);

    try client.requestGuildMembers(
        &session,
        Gateway.RequestGuildMembers.init(Snowflake.init(10))
            .withQuery("zig")
            .withLimit(10)
            .withNonce("members-1"),
    );

    try std.testing.expectEqual(@as(usize, 4), gateway_memory.sent.items.len);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[3], "\"op\":8") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[3], "\"query\":\"zig\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[3], "\"nonce\":\"members-1\"") != null);

    try client.requestChannelInfo(
        &session,
        Gateway.RequestChannelInfo.init(Snowflake.init(10), &.{ .status, .voice_start_time }),
    );

    try std.testing.expectEqual(@as(usize, 5), gateway_memory.sent.items.len);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[4], "\"op\":43") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[4], "\"fields\":[\"status\",\"voice_start_time\"]") != null);

    try client.updateVoiceState(
        &session,
        Gateway.VoiceStateUpdate.init(Snowflake.init(10))
            .withChannel(Snowflake.init(20))
            .deafState(true),
    );

    try std.testing.expectEqual(@as(usize, 6), gateway_memory.sent.items.len);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[5], "\"op\":4") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[5], "\"self_deaf\":true") != null);

    try client.joinVoiceChannel(
        &session,
        Snowflake.init(10),
        Snowflake.init(30),
        true,
        false,
    );
    try std.testing.expectEqual(@as(usize, 7), gateway_memory.sent.items.len);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[6], "\"channel_id\":\"30\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[6], "\"self_mute\":true") != null);

    try client.leaveVoiceChannel(&session, Snowflake.init(10));
    try std.testing.expectEqual(@as(usize, 8), gateway_memory.sent.items.len);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[7], "\"channel_id\":null") != null);
}

test "gateway runner dispatches through cache and event handlers" {
    const State = struct {
        called: bool = false,

        fn onMessage(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            _ = dispatch;
            self.called = true;
        }
    };

    var gateway_memory = GatewaySession.MemoryTransport.init(std.testing.allocator);
    defer gateway_memory.deinit();
    try gateway_memory.pushIncoming(
        "{\"op\":0,\"s\":0,\"t\":\"READY\",\"d\":{\"session_id\":\"abc\",\"resume_gateway_url\":\"wss://gateway.discord.gg\"}}",
    );
    try gateway_memory.pushIncoming(
        "{\"op\":0,\"s\":1,\"t\":\"MESSAGE_CREATE\",\"d\":{\"id\":\"10\",\"channel_id\":\"20\",\"content\":\"pong\",\"author\":{\"id\":\"30\",\"username\":\"bot\"}}}",
    );

    var state = State{};
    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
    });
    defer client.deinit();
    client.onMessageCreate(Events.rawHandler(&state, State.onMessage));

    var runner = client.createGatewayRunner(gateway_memory.transport());
    defer runner.deinit();

    try std.testing.expectEqual(GatewayStep.dispatched, try runner.step(0));
    try std.testing.expect(client.isReady());
    try std.testing.expectEqual(@as(?u64, 0), client.readyTimestampMs());
    try std.testing.expectEqual(@as(?u64, 25), client.uptimeMs(25));
    try std.testing.expectEqual(@as(?u64, 0), client.lastGatewaySequence());
    try std.testing.expectEqual(@as(?Gateway.EventName, .READY), client.lastGatewayEvent());
    try std.testing.expect(runner.canResume());
    try std.testing.expectEqualStrings("abc", runner.sessionId().?);
    try std.testing.expectEqual(@as(?u64, 0), runner.sequence());

    try std.testing.expectEqual(GatewayStep.dispatched, try runner.step(0));
    try std.testing.expect(state.called);
    try std.testing.expect(client.isReady());
    try std.testing.expectEqual(@as(?u64, 0), client.readyTimestampMs());
    try std.testing.expectEqual(@as(?u64, 1), client.lastGatewaySequence());
    try std.testing.expectEqual(@as(?Gateway.EventName, .MESSAGE_CREATE), client.lastGatewayEvent());
    try std.testing.expect(client.getCachedMessage(Snowflake.init(10)) != null);
}

test "gateway runner reports reconnect and invalid session signals" {
    var gateway_memory = GatewaySession.MemoryTransport.init(std.testing.allocator);
    defer gateway_memory.deinit();
    try gateway_memory.pushIncoming("{\"op\":7,\"d\":null}");
    try gateway_memory.pushIncoming("{\"op\":9,\"d\":false}");

    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
    });
    defer client.deinit();

    var runner = client.createGatewayRunner(gateway_memory.transport());
    defer runner.deinit();

    client.ready = true;
    try std.testing.expectEqual(GatewayStep.reconnect, try runner.step(0));
    try std.testing.expect(!client.isReady());
    try std.testing.expectEqual(@as(?u64, 1000), runner.reconnect_after_ms);
    try std.testing.expect(runner.isReconnectPending());
    try std.testing.expectEqual(@as(?u64, 1000), runner.reconnectAfterMs());
    try std.testing.expectEqual(GatewayStartMode.resume_session, runner.pendingStartMode());
    try std.testing.expect(!runner.reconnectReady(999));
    client.ready = true;
    try std.testing.expectEqual(GatewayStep.invalid_session, try runner.step(1000));
    try std.testing.expect(!client.isReady());
    try std.testing.expectEqual(GatewayStartMode.identify, runner.pending_start);
    try std.testing.expectEqual(GatewayStartMode.identify, runner.pendingStartMode());
    try std.testing.expectEqual(@as(?u64, 3000), runner.reconnect_after_ms);
}

test "gateway runner resumes after reconnect when session is resumable" {
    var gateway_memory = GatewaySession.MemoryTransport.init(std.testing.allocator);
    defer gateway_memory.deinit();
    try gateway_memory.pushIncoming("{\"op\":0,\"s\":42,\"t\":\"READY\",\"d\":{\"session_id\":\"session-a\"}}");
    try gateway_memory.pushIncoming("{\"op\":7,\"d\":null}");
    try gateway_memory.pushIncoming("{\"op\":10,\"d\":{\"heartbeat_interval\":50}}");

    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
    });
    defer client.deinit();

    var runner = client.createGatewayRunner(gateway_memory.transport());
    defer runner.deinit();

    try std.testing.expectEqual(GatewayStep.dispatched, try runner.step(0));
    try std.testing.expect(runner.session.canResume());
    try std.testing.expect(client.isReady());
    try std.testing.expectEqual(GatewayStep.reconnect, try runner.step(0));
    try std.testing.expect(!client.isReady());
    try std.testing.expectEqual(GatewayStartMode.resume_session, runner.pending_start);
    try std.testing.expectEqual(GatewayStep.idle, try runner.step(999));

    try std.testing.expectEqual(GatewayStep.resumed, try runner.step(1000));
    try std.testing.expect(!client.isReady());
    try std.testing.expectEqual(@as(usize, 1), gateway_memory.sent.items.len);
    try std.testing.expect(std.mem.indexOf(u8, gateway_memory.sent.items[0], "\"op\":6") != null);
    try std.testing.expectEqual(@as(?u64, 1050), runner.next_heartbeat_ms);
    try std.testing.expectEqual(@as(?u64, null), runner.reconnect_after_ms);
}

test "gateway runner keeps resumable invalid session state" {
    var gateway_memory = GatewaySession.MemoryTransport.init(std.testing.allocator);
    defer gateway_memory.deinit();
    try gateway_memory.pushIncoming("{\"op\":0,\"s\":7,\"t\":\"READY\",\"d\":{\"session_id\":\"session-b\"}}");
    try gateway_memory.pushIncoming("{\"op\":9,\"d\":true}");

    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
    });
    defer client.deinit();

    var runner = client.createGatewayRunner(gateway_memory.transport());
    defer runner.deinit();

    try std.testing.expectEqual(GatewayStep.dispatched, try runner.step(0));
    try std.testing.expectEqual(GatewayStep.invalid_session, try runner.step(0));
    try std.testing.expect(runner.session.canResume());
    try std.testing.expectEqual(GatewayStartMode.resume_session, runner.pending_start);
}
