const std = @import("std");
const Rest = @import("../../rest/client.zig");
const Events = @import("../../gateway/events.zig");
const Gateway = @import("../../gateway/protocol.zig");
const Root = @import("../client.zig");
const Client = Root.Client;

test "client auto moderation event convenience registers handlers" {
    const State = struct {
        rule_created: bool = false,
        action_executed: bool = false,

        fn onAutoModerationRuleCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.AUTO_MODERATION_RULE_CREATE, dispatch.event);
            self.rule_created = true;
        }

        fn onAutoModerationActionExecution(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.AUTO_MODERATION_ACTION_EXECUTION, dispatch.event);
            self.action_executed = true;
        }
    };

    var memory = Rest.MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var state = State{};
    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
        .transport = memory.transport(),
    });
    defer client.deinit();

    client.onAutoModerationRuleCreate(Events.rawHandler(&state, State.onAutoModerationRuleCreate));
    client.onAutoModerationActionExecution(Events.rawHandler(&state, State.onAutoModerationActionExecution));

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":1,\"t\":\"AUTO_MODERATION_RULE_CREATE\",\"d\":{\"id\":\"20\",\"guild_id\":\"10\",\"name\":\"keyword guard\"}}",
    );
    try std.testing.expect(state.rule_created);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":2,\"t\":\"AUTO_MODERATION_ACTION_EXECUTION\",\"d\":{\"guild_id\":\"10\",\"rule_id\":\"20\",\"rule_trigger_type\":1,\"user_id\":\"30\",\"action\":{\"type\":1}}}",
    );
    try std.testing.expect(state.action_executed);
}

test "client entitlement and subscription event convenience registers handlers" {
    const State = struct {
        created: bool = false,
        deleted: bool = false,
        subscription_created: bool = false,
        subscription_updated: bool = false,
        subscription_deleted: bool = false,

        fn onEntitlementCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.ENTITLEMENT_CREATE, dispatch.event);
            self.created = true;
        }

        fn onEntitlementDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.ENTITLEMENT_DELETE, dispatch.event);
            self.deleted = true;
        }

        fn onSubscriptionCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.SUBSCRIPTION_CREATE, dispatch.event);
            self.subscription_created = true;
        }

        fn onSubscriptionUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.SUBSCRIPTION_UPDATE, dispatch.event);
            self.subscription_updated = true;
        }

        fn onSubscriptionDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.SUBSCRIPTION_DELETE, dispatch.event);
            self.subscription_deleted = true;
        }
    };

    var memory = Rest.MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var state = State{};
    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
        .transport = memory.transport(),
    });
    defer client.deinit();

    client.onEntitlementCreate(Events.rawHandler(&state, State.onEntitlementCreate));
    client.onEntitlementDelete(Events.rawHandler(&state, State.onEntitlementDelete));
    client.onSubscriptionCreate(Events.rawHandler(&state, State.onSubscriptionCreate));
    client.onSubscriptionUpdate(Events.rawHandler(&state, State.onSubscriptionUpdate));
    client.onSubscriptionDelete(Events.rawHandler(&state, State.onSubscriptionDelete));

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":1,\"t\":\"ENTITLEMENT_CREATE\",\"d\":{\"id\":\"10\",\"sku_id\":\"20\",\"application_id\":\"30\",\"type\":8,\"deleted\":false}}",
    );
    try std.testing.expect(state.created);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":2,\"t\":\"ENTITLEMENT_DELETE\",\"d\":{\"id\":\"10\",\"sku_id\":\"20\",\"application_id\":\"30\",\"type\":8,\"deleted\":true}}",
    );
    try std.testing.expect(state.deleted);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":3,\"t\":\"SUBSCRIPTION_CREATE\",\"d\":{\"id\":\"40\",\"user_id\":\"50\",\"sku_ids\":[\"20\"],\"entitlement_ids\":[\"10\"],\"current_period_start\":\"2026-01-01T00:00:00.000000+00:00\",\"current_period_end\":\"2026-02-01T00:00:00.000000+00:00\",\"status\":0}}",
    );
    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":4,\"t\":\"SUBSCRIPTION_UPDATE\",\"d\":{\"id\":\"40\",\"user_id\":\"50\",\"sku_ids\":[\"20\"],\"entitlement_ids\":[\"10\"],\"current_period_start\":\"2026-01-01T00:00:00.000000+00:00\",\"current_period_end\":\"2026-02-01T00:00:00.000000+00:00\",\"status\":1}}",
    );
    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":5,\"t\":\"SUBSCRIPTION_DELETE\",\"d\":{\"id\":\"40\",\"user_id\":\"50\",\"sku_ids\":[\"20\"],\"entitlement_ids\":[\"10\"],\"current_period_start\":\"2026-01-01T00:00:00.000000+00:00\",\"current_period_end\":\"2026-02-01T00:00:00.000000+00:00\",\"status\":2}}",
    );
    try std.testing.expect(state.subscription_created);
    try std.testing.expect(state.subscription_updated);
    try std.testing.expect(state.subscription_deleted);
}

test "client soundboard event convenience registers handlers" {
    const State = struct {
        sound_created: bool = false,
        sounds_response: bool = false,
        voice_effect: bool = false,

        fn onGuildSoundboardSoundCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_SOUNDBOARD_SOUND_CREATE, dispatch.event);
            self.sound_created = true;
        }

        fn onSoundboardSounds(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.SOUNDBOARD_SOUNDS, dispatch.event);
            self.sounds_response = true;
        }

        fn onVoiceChannelEffectSend(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.VOICE_CHANNEL_EFFECT_SEND, dispatch.event);
            self.voice_effect = true;
        }
    };

    var memory = Rest.MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var state = State{};
    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
        .transport = memory.transport(),
    });
    defer client.deinit();

    client.onGuildSoundboardSoundCreate(Events.rawHandler(&state, State.onGuildSoundboardSoundCreate));
    client.onSoundboardSounds(Events.rawHandler(&state, State.onSoundboardSounds));
    client.onVoiceChannelEffectSend(Events.rawHandler(&state, State.onVoiceChannelEffectSend));

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":1,\"t\":\"GUILD_SOUNDBOARD_SOUND_CREATE\",\"d\":{\"sound_id\":\"20\",\"guild_id\":\"10\",\"name\":\"launch\"}}",
    );
    try std.testing.expect(state.sound_created);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":2,\"t\":\"SOUNDBOARD_SOUNDS\",\"d\":{\"guild_id\":\"10\",\"soundboard_sounds\":[]}}",
    );
    try std.testing.expect(state.sounds_response);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":3,\"t\":\"VOICE_CHANNEL_EFFECT_SEND\",\"d\":{\"channel_id\":\"30\",\"guild_id\":\"10\",\"user_id\":\"40\",\"sound_id\":\"20\"}}",
    );
    try std.testing.expect(state.voice_effect);
}

test "client runtime event convenience registers handlers" {
    const State = struct {
        permissions_updated: bool = false,
        audit_log_entry_created: bool = false,
        members_chunked: bool = false,
        voice_server_updated: bool = false,
        channel_info: bool = false,
        voice_status_updated: bool = false,
        voice_start_time_updated: bool = false,
        rate_limited: bool = false,

        fn onApplicationCommandPermissionsUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.APPLICATION_COMMAND_PERMISSIONS_UPDATE, dispatch.event);
            self.permissions_updated = true;
        }

        fn onGuildAuditLogEntryCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_AUDIT_LOG_ENTRY_CREATE, dispatch.event);
            self.audit_log_entry_created = true;
        }

        fn onGuildMembersChunk(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_MEMBERS_CHUNK, dispatch.event);
            self.members_chunked = true;
        }

        fn onVoiceServerUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.VOICE_SERVER_UPDATE, dispatch.event);
            self.voice_server_updated = true;
        }

        fn onChannelInfo(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.CHANNEL_INFO, dispatch.event);
            self.channel_info = true;
        }

        fn onVoiceChannelStatusUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.VOICE_CHANNEL_STATUS_UPDATE, dispatch.event);
            self.voice_status_updated = true;
        }

        fn onVoiceChannelStartTimeUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.VOICE_CHANNEL_START_TIME_UPDATE, dispatch.event);
            self.voice_start_time_updated = true;
        }

        fn onRateLimited(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.RATE_LIMITED, dispatch.event);
            self.rate_limited = true;
        }
    };

    var memory = Rest.MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var state = State{};
    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
        .transport = memory.transport(),
    });
    defer client.deinit();

    client.onApplicationCommandPermissionsUpdate(Events.rawHandler(&state, State.onApplicationCommandPermissionsUpdate));
    client.onGuildAuditLogEntryCreate(Events.rawHandler(&state, State.onGuildAuditLogEntryCreate));
    client.onGuildMembersChunk(Events.rawHandler(&state, State.onGuildMembersChunk));
    client.onVoiceServerUpdate(Events.rawHandler(&state, State.onVoiceServerUpdate));
    client.onChannelInfo(Events.rawHandler(&state, State.onChannelInfo));
    client.onVoiceChannelStatusUpdate(Events.rawHandler(&state, State.onVoiceChannelStatusUpdate));
    client.onVoiceChannelStartTimeUpdate(Events.rawHandler(&state, State.onVoiceChannelStartTimeUpdate));
    client.onRateLimited(Events.rawHandler(&state, State.onRateLimited));

    _ = try client.dispatchGatewayPayload("{\"op\":0,\"s\":1,\"t\":\"APPLICATION_COMMAND_PERMISSIONS_UPDATE\",\"d\":{}}");
    _ = try client.dispatchGatewayPayload("{\"op\":0,\"s\":2,\"t\":\"GUILD_AUDIT_LOG_ENTRY_CREATE\",\"d\":{}}");
    _ = try client.dispatchGatewayPayload("{\"op\":0,\"s\":3,\"t\":\"GUILD_MEMBERS_CHUNK\",\"d\":{}}");
    _ = try client.dispatchGatewayPayload("{\"op\":0,\"s\":4,\"t\":\"VOICE_SERVER_UPDATE\",\"d\":{}}");
    _ = try client.dispatchGatewayPayload("{\"op\":0,\"s\":5,\"t\":\"CHANNEL_INFO\",\"d\":{}}");
    _ = try client.dispatchGatewayPayload("{\"op\":0,\"s\":6,\"t\":\"VOICE_CHANNEL_STATUS_UPDATE\",\"d\":{}}");
    _ = try client.dispatchGatewayPayload("{\"op\":0,\"s\":7,\"t\":\"VOICE_CHANNEL_START_TIME_UPDATE\",\"d\":{}}");
    _ = try client.dispatchGatewayPayload("{\"op\":0,\"s\":8,\"t\":\"RATE_LIMITED\",\"d\":{\"retry_after\":1,\"limit\":1,\"method\":\"GET\",\"route\":\"/test\"}}");

    try std.testing.expect(state.permissions_updated);
    try std.testing.expect(state.audit_log_entry_created);
    try std.testing.expect(state.members_chunked);
    try std.testing.expect(state.voice_server_updated);
    try std.testing.expect(state.channel_info);
    try std.testing.expect(state.voice_status_updated);
    try std.testing.expect(state.voice_start_time_updated);
    try std.testing.expect(state.rate_limited);
}
