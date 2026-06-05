const std = @import("std");
const Intents = @import("../../core/intents.zig");
const Rest = @import("../../rest/client.zig");
const HttpTransport = @import("../../rest/http-transport.zig").HttpTransport;
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

test "client supports generic one-shot event listeners" {
    const State = struct {
        ready_count: usize = 0,
        resumed_count: usize = 0,
        message_count: usize = 0,
        message_update_count: usize = 0,
        message_delete_count: usize = 0,
        message_delete_bulk_count: usize = 0,
        reaction_add_count: usize = 0,
        reaction_remove_count: usize = 0,
        reaction_remove_all_count: usize = 0,
        reaction_remove_emoji_count: usize = 0,
        poll_vote_add_count: usize = 0,
        poll_vote_remove_count: usize = 0,
        interaction_count: usize = 0,
        application_command_count: usize = 0,
        component_count: usize = 0,
        autocomplete_count: usize = 0,
        modal_count: usize = 0,
        permissions_count: usize = 0,
        unknown_count: usize = 0,

        fn onReady(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.READY, dispatch.event);
            self.ready_count += 1;
        }

        fn onResumed(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.RESUMED, dispatch.event);
            self.resumed_count += 1;
        }

        fn onMessage(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_CREATE, dispatch.event);
            self.message_count += 1;
        }

        fn onMessageUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_UPDATE, dispatch.event);
            self.message_update_count += 1;
        }

        fn onMessageDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_DELETE, dispatch.event);
            self.message_delete_count += 1;
        }

        fn onMessageDeleteBulk(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_DELETE_BULK, dispatch.event);
            self.message_delete_bulk_count += 1;
        }

        fn onReactionAdd(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_REACTION_ADD, dispatch.event);
            self.reaction_add_count += 1;
        }

        fn onReactionRemove(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_REACTION_REMOVE, dispatch.event);
            self.reaction_remove_count += 1;
        }

        fn onReactionRemoveAll(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_REACTION_REMOVE_ALL, dispatch.event);
            self.reaction_remove_all_count += 1;
        }

        fn onReactionRemoveEmoji(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_REACTION_REMOVE_EMOJI, dispatch.event);
            self.reaction_remove_emoji_count += 1;
        }

        fn onPollVoteAdd(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_POLL_VOTE_ADD, dispatch.event);
            self.poll_vote_add_count += 1;
        }

        fn onPollVoteRemove(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_POLL_VOTE_REMOVE, dispatch.event);
            self.poll_vote_remove_count += 1;
        }

        fn onInteraction(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTERACTION_CREATE, dispatch.event);
            self.interaction_count += 1;
        }

        fn onApplicationCommand(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTERACTION_CREATE, dispatch.event);
            self.application_command_count += 1;
        }

        fn onComponent(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTERACTION_CREATE, dispatch.event);
            self.component_count += 1;
        }

        fn onAutocomplete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTERACTION_CREATE, dispatch.event);
            self.autocomplete_count += 1;
        }

        fn onModal(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTERACTION_CREATE, dispatch.event);
            self.modal_count += 1;
        }

        fn onPermissions(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.APPLICATION_COMMAND_PERMISSIONS_UPDATE, dispatch.event);
            self.permissions_count += 1;
        }

        fn onUnknown(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.unknown, dispatch.event);
            self.unknown_count += 1;
        }
    };

    var state = State{};
    var client = Client.init(std.testing.allocator, .{ .token = "Bot test" });
    defer client.deinit();

    try std.testing.expect(!client.hasListener(.READY));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.READY));

    client.onceReady(Events.rawHandler(&state, State.onReady));
    try std.testing.expect(client.hasListener(.READY));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.READY));
    try std.testing.expect(!client.isReady());
    try std.testing.expect(client.readyTimestampMs() == null);
    try std.testing.expect(client.uptimeMs(100) == null);
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":1,\"t\":\"READY\",\"d\":{\"session_id\":\"abc\",\"resume_gateway_url\":\"wss://gateway.discord.gg\"}}"));
    try std.testing.expect(client.isReady());
    try std.testing.expect(client.readyTimestampMs() == null);
    try std.testing.expect(client.uptimeMs(100) == null);
    try std.testing.expectEqual(@as(?u64, 1), client.lastGatewaySequence());
    try std.testing.expectEqual(@as(?Gateway.EventName, .READY), client.lastGatewayEvent());
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":2,\"t\":\"READY\",\"d\":{\"session_id\":\"def\",\"resume_gateway_url\":\"wss://gateway.discord.gg\"}}"));
    try std.testing.expectEqual(@as(?u64, 2), client.lastGatewaySequence());
    try std.testing.expectEqual(@as(usize, 1), state.ready_count);
    try std.testing.expect(!client.hasListener(.READY));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.READY));

    client.on(.READY, Events.rawHandler(&state, State.onReady));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.READY));
    client.clearListener(.READY);
    try std.testing.expect(!client.hasListener(.READY));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":3,\"t\":\"READY\",\"d\":{\"session_id\":\"ghi\",\"resume_gateway_url\":\"wss://gateway.discord.gg\"}}"));
    try std.testing.expectEqual(@as(usize, 1), state.ready_count);

    client.on(.READY, Events.rawHandler(&state, State.onReady));
    client.off(.READY);
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":4,\"t\":\"READY\",\"d\":{\"session_id\":\"jkl\",\"resume_gateway_url\":\"wss://gateway.discord.gg\"}}"));
    try std.testing.expectEqual(@as(usize, 1), state.ready_count);

    client.on(.READY, Events.rawHandler(&state, State.onReady));
    client.removeListener(.READY);
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":5,\"t\":\"READY\",\"d\":{\"session_id\":\"mno\",\"resume_gateway_url\":\"wss://gateway.discord.gg\"}}"));
    try std.testing.expectEqual(@as(usize, 1), state.ready_count);

    client.on(.READY, Events.rawHandler(&state, State.onReady));
    client.onceResumed(Events.rawHandler(&state, State.onResumed));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.READY));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.RESUMED));
    const names = try client.eventNames(std.testing.allocator);
    defer std.testing.allocator.free(names);
    try std.testing.expectEqual(@as(usize, 2), names.len);
    try std.testing.expect(std.mem.indexOfScalar(Gateway.EventName, names, .READY) != null);
    try std.testing.expect(std.mem.indexOfScalar(Gateway.EventName, names, .RESUMED) != null);

    client.removeAllListeners();
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.READY));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.RESUMED));
    const empty_names = try client.eventNames(std.testing.allocator);
    defer std.testing.allocator.free(empty_names);
    try std.testing.expectEqual(@as(usize, 0), empty_names.len);
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":6,\"t\":\"READY\",\"d\":{\"session_id\":\"pqr\",\"resume_gateway_url\":\"wss://gateway.discord.gg\"}}"));
    try std.testing.expectEqual(@as(usize, 1), state.ready_count);

    client.on(.READY, Events.rawHandler(&state, State.onReady));
    client.clearListeners();
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":7,\"t\":\"READY\",\"d\":{\"session_id\":\"stu\",\"resume_gateway_url\":\"wss://gateway.discord.gg\"}}"));
    try std.testing.expectEqual(@as(usize, 1), state.ready_count);

    client.resetGatewayState();
    try std.testing.expect(!client.isReady());
    try std.testing.expect(client.readyTimestampMs() == null);
    try std.testing.expect(client.uptimeMs(100) == null);
    try std.testing.expectEqual(@as(?u64, null), client.lastGatewaySequence());
    try std.testing.expectEqual(@as(?Gateway.EventName, null), client.lastGatewayEvent());
    try std.testing.expectEqual(@as(?u64, null), client.gatewayPingMs());

    client.onceResumed(Events.rawHandler(&state, State.onResumed));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":8,\"t\":\"RESUMED\",\"d\":{}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":9,\"t\":\"RESUMED\",\"d\":{}}"));
    try std.testing.expect(client.isReady());
    try std.testing.expectEqual(@as(?u64, 9), client.lastGatewaySequence());
    try std.testing.expectEqual(@as(?Gateway.EventName, .RESUMED), client.lastGatewayEvent());
    try std.testing.expectEqual(@as(usize, 1), state.resumed_count);

    client.onceMessageCreate(Events.rawHandler(&state, State.onMessage));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":10,\"t\":\"MESSAGE_CREATE\",\"d\":{\"id\":\"10\",\"channel_id\":\"20\",\"content\":\"hello\",\"author\":{\"id\":\"30\",\"username\":\"bot\"}}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":11,\"t\":\"MESSAGE_CREATE\",\"d\":{\"id\":\"11\",\"channel_id\":\"20\",\"content\":\"again\",\"author\":{\"id\":\"30\",\"username\":\"bot\"}}}"));
    try std.testing.expectEqual(@as(usize, 1), state.message_count);

    client.onceMessageUpdate(Events.rawHandler(&state, State.onMessageUpdate));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":12,\"t\":\"MESSAGE_UPDATE\",\"d\":{\"id\":\"10\",\"channel_id\":\"20\",\"content\":\"edited\",\"author\":{\"id\":\"30\",\"username\":\"bot\"}}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":13,\"t\":\"MESSAGE_UPDATE\",\"d\":{\"id\":\"10\",\"channel_id\":\"20\",\"content\":\"edited again\",\"author\":{\"id\":\"30\",\"username\":\"bot\"}}}"));
    try std.testing.expectEqual(@as(usize, 1), state.message_update_count);

    client.onceMessageDelete(Events.rawHandler(&state, State.onMessageDelete));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":14,\"t\":\"MESSAGE_DELETE\",\"d\":{\"id\":\"10\",\"channel_id\":\"20\"}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":15,\"t\":\"MESSAGE_DELETE\",\"d\":{\"id\":\"11\",\"channel_id\":\"20\"}}"));
    try std.testing.expectEqual(@as(usize, 1), state.message_delete_count);

    client.onceMessageDeleteBulk(Events.rawHandler(&state, State.onMessageDeleteBulk));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":16,\"t\":\"MESSAGE_DELETE_BULK\",\"d\":{\"ids\":[\"10\",\"11\"],\"channel_id\":\"20\"}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":17,\"t\":\"MESSAGE_DELETE_BULK\",\"d\":{\"ids\":[\"12\"],\"channel_id\":\"20\"}}"));
    try std.testing.expectEqual(@as(usize, 1), state.message_delete_bulk_count);

    client.onceMessageReactionAdd(Events.rawHandler(&state, State.onReactionAdd));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":18,\"t\":\"MESSAGE_REACTION_ADD\",\"d\":{\"user_id\":\"30\",\"channel_id\":\"20\",\"message_id\":\"10\",\"emoji\":{\"name\":\"👍\"}}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":19,\"t\":\"MESSAGE_REACTION_ADD\",\"d\":{\"user_id\":\"30\",\"channel_id\":\"20\",\"message_id\":\"10\",\"emoji\":{\"name\":\"👍\"}}}"));
    try std.testing.expectEqual(@as(usize, 1), state.reaction_add_count);

    client.onceMessageReactionRemove(Events.rawHandler(&state, State.onReactionRemove));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":20,\"t\":\"MESSAGE_REACTION_REMOVE\",\"d\":{\"user_id\":\"30\",\"channel_id\":\"20\",\"message_id\":\"10\",\"emoji\":{\"name\":\"👍\"}}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":21,\"t\":\"MESSAGE_REACTION_REMOVE\",\"d\":{\"user_id\":\"30\",\"channel_id\":\"20\",\"message_id\":\"10\",\"emoji\":{\"name\":\"👍\"}}}"));
    try std.testing.expectEqual(@as(usize, 1), state.reaction_remove_count);

    client.onceMessageReactionRemoveAll(Events.rawHandler(&state, State.onReactionRemoveAll));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":22,\"t\":\"MESSAGE_REACTION_REMOVE_ALL\",\"d\":{\"channel_id\":\"20\",\"message_id\":\"10\"}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":23,\"t\":\"MESSAGE_REACTION_REMOVE_ALL\",\"d\":{\"channel_id\":\"20\",\"message_id\":\"11\"}}"));
    try std.testing.expectEqual(@as(usize, 1), state.reaction_remove_all_count);

    client.onceMessageReactionRemoveEmoji(Events.rawHandler(&state, State.onReactionRemoveEmoji));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":24,\"t\":\"MESSAGE_REACTION_REMOVE_EMOJI\",\"d\":{\"channel_id\":\"20\",\"message_id\":\"10\",\"emoji\":{\"name\":\"👍\"}}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":25,\"t\":\"MESSAGE_REACTION_REMOVE_EMOJI\",\"d\":{\"channel_id\":\"20\",\"message_id\":\"11\",\"emoji\":{\"name\":\"👍\"}}}"));
    try std.testing.expectEqual(@as(usize, 1), state.reaction_remove_emoji_count);

    client.onceMessagePollVoteAdd(Events.rawHandler(&state, State.onPollVoteAdd));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":26,\"t\":\"MESSAGE_POLL_VOTE_ADD\",\"d\":{\"user_id\":\"30\",\"channel_id\":\"20\",\"message_id\":\"10\",\"answer_id\":1}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":27,\"t\":\"MESSAGE_POLL_VOTE_ADD\",\"d\":{\"user_id\":\"30\",\"channel_id\":\"20\",\"message_id\":\"10\",\"answer_id\":2}}"));
    try std.testing.expectEqual(@as(usize, 1), state.poll_vote_add_count);

    client.onceMessagePollVoteRemove(Events.rawHandler(&state, State.onPollVoteRemove));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":28,\"t\":\"MESSAGE_POLL_VOTE_REMOVE\",\"d\":{\"user_id\":\"30\",\"channel_id\":\"20\",\"message_id\":\"10\",\"answer_id\":1}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":29,\"t\":\"MESSAGE_POLL_VOTE_REMOVE\",\"d\":{\"user_id\":\"30\",\"channel_id\":\"20\",\"message_id\":\"10\",\"answer_id\":2}}"));
    try std.testing.expectEqual(@as(usize, 1), state.poll_vote_remove_count);

    client.onceInteractionCreate(Events.rawHandler(&state, State.onInteraction));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":30,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"3\",\"name\":\"ping\",\"type\":1}}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":31,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"4\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"ping\",\"type\":1}}}"));
    try std.testing.expectEqual(@as(usize, 1), state.interaction_count);

    client.onceApplicationCommand(Events.rawHandler(&state, State.onApplicationCommand));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":32,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"6\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"7\",\"name\":\"ping\",\"type\":1}}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":33,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"8\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"9\",\"name\":\"ping\",\"type\":1}}}"));
    try std.testing.expectEqual(@as(usize, 1), state.application_command_count);

    client.onceMessageComponent(Events.rawHandler(&state, State.onComponent));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":34,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"10\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"data\":{\"custom_id\":\"ok\",\"component_type\":2}}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":35,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"11\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"data\":{\"custom_id\":\"again\",\"component_type\":2}}}"));
    try std.testing.expectEqual(@as(usize, 1), state.component_count);

    client.onceApplicationCommandAutocomplete(Events.rawHandler(&state, State.onAutocomplete));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":36,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"12\",\"application_id\":\"2\",\"type\":4,\"token\":\"tok\",\"data\":{\"id\":\"13\",\"name\":\"ping\",\"type\":1}}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":37,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"14\",\"application_id\":\"2\",\"type\":4,\"token\":\"tok\",\"data\":{\"id\":\"15\",\"name\":\"ping\",\"type\":1}}}"));
    try std.testing.expectEqual(@as(usize, 1), state.autocomplete_count);

    client.onceModalSubmit(Events.rawHandler(&state, State.onModal));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":38,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"16\",\"application_id\":\"2\",\"type\":5,\"token\":\"tok\",\"data\":{\"custom_id\":\"modal\"}}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":39,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"17\",\"application_id\":\"2\",\"type\":5,\"token\":\"tok\",\"data\":{\"custom_id\":\"modal-again\"}}}"));
    try std.testing.expectEqual(@as(usize, 1), state.modal_count);

    client.onceApplicationCommandPermissionsUpdate(Events.rawHandler(&state, State.onPermissions));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":40,\"t\":\"APPLICATION_COMMAND_PERMISSIONS_UPDATE\",\"d\":{}}"));
    try std.testing.expect(!try client.dispatchGatewayPayload("{\"op\":0,\"s\":41,\"t\":\"APPLICATION_COMMAND_PERMISSIONS_UPDATE\",\"d\":{}}"));
    try std.testing.expectEqual(@as(usize, 1), state.permissions_count);

    client.onUnknown(Events.rawHandler(&state, State.onUnknown));
    try std.testing.expect(try client.dispatchGatewayPayload("{\"op\":0,\"s\":42,\"t\":\"NEW_GATEWAY_EVENT\",\"d\":{}}"));
    try std.testing.expectEqual(@as(?u64, 42), client.lastGatewaySequence());
    try std.testing.expectEqual(@as(?Gateway.EventName, .unknown), client.lastGatewayEvent());
    try std.testing.expectEqual(@as(usize, 1), state.unknown_count);

    client.onceGuildCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildDelete(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildMemberAdd(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildMemberUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildMemberRemove(Events.rawHandler(&state, State.onUnknown));
    client.onceChannelCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceChannelUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceChannelDelete(Events.rawHandler(&state, State.onUnknown));
    client.onceUserUpdate(Events.rawHandler(&state, State.onUnknown));
    client.oncePresenceUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceVoiceStateUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceTypingStart(Events.rawHandler(&state, State.onUnknown));
    client.onceWebhooksUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceInviteCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceInviteDelete(Events.rawHandler(&state, State.onUnknown));
    client.onceAutoModerationRuleCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceAutoModerationRuleUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceAutoModerationRuleDelete(Events.rawHandler(&state, State.onUnknown));
    client.onceAutoModerationActionExecution(Events.rawHandler(&state, State.onUnknown));
    client.onceEntitlementCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceEntitlementUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceEntitlementDelete(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildSoundboardSoundCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildSoundboardSoundUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildSoundboardSoundDelete(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildSoundboardSoundsUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceSoundboardSounds(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildRoleCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildRoleUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildRoleDelete(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildEmojisUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildStickersUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildScheduledEventCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildScheduledEventUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildScheduledEventDelete(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildScheduledEventUserAdd(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildScheduledEventUserRemove(Events.rawHandler(&state, State.onUnknown));
    client.onceStageInstanceCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceStageInstanceUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceStageInstanceDelete(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildAuditLogEntryCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildBanAdd(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildBanRemove(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildIntegrationsUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceIntegrationCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceIntegrationUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceIntegrationDelete(Events.rawHandler(&state, State.onUnknown));
    client.onceGuildMembersChunk(Events.rawHandler(&state, State.onUnknown));
    client.onceVoiceChannelEffectSend(Events.rawHandler(&state, State.onUnknown));
    client.onceVoiceServerUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceChannelInfo(Events.rawHandler(&state, State.onUnknown));
    client.onceVoiceChannelStatusUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceVoiceChannelStartTimeUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceChannelPinsUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceThreadCreate(Events.rawHandler(&state, State.onUnknown));
    client.onceThreadUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceThreadDelete(Events.rawHandler(&state, State.onUnknown));
    client.onceThreadListSync(Events.rawHandler(&state, State.onUnknown));
    client.onceThreadMemberUpdate(Events.rawHandler(&state, State.onUnknown));
    client.onceThreadMembersUpdate(Events.rawHandler(&state, State.onUnknown));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_DELETE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_MEMBER_ADD));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_MEMBER_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_MEMBER_REMOVE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.CHANNEL_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.CHANNEL_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.CHANNEL_DELETE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.USER_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.PRESENCE_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.VOICE_STATE_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.TYPING_START));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.WEBHOOKS_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.INVITE_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.INVITE_DELETE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.AUTO_MODERATION_RULE_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.AUTO_MODERATION_RULE_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.AUTO_MODERATION_RULE_DELETE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.AUTO_MODERATION_ACTION_EXECUTION));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.ENTITLEMENT_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.ENTITLEMENT_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.ENTITLEMENT_DELETE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_SOUNDBOARD_SOUND_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_SOUNDBOARD_SOUND_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_SOUNDBOARD_SOUND_DELETE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_SOUNDBOARD_SOUNDS_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.SOUNDBOARD_SOUNDS));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_ROLE_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_ROLE_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_ROLE_DELETE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_EMOJIS_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_STICKERS_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_SCHEDULED_EVENT_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_SCHEDULED_EVENT_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_SCHEDULED_EVENT_DELETE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_SCHEDULED_EVENT_USER_ADD));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_SCHEDULED_EVENT_USER_REMOVE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.STAGE_INSTANCE_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.STAGE_INSTANCE_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.STAGE_INSTANCE_DELETE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_AUDIT_LOG_ENTRY_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_BAN_ADD));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_BAN_REMOVE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_INTEGRATIONS_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.INTEGRATION_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.INTEGRATION_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.INTEGRATION_DELETE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.GUILD_MEMBERS_CHUNK));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.VOICE_CHANNEL_EFFECT_SEND));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.VOICE_SERVER_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.CHANNEL_INFO));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.VOICE_CHANNEL_STATUS_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.VOICE_CHANNEL_START_TIME_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.CHANNEL_PINS_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.THREAD_CREATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.THREAD_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.THREAD_DELETE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.THREAD_LIST_SYNC));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.THREAD_MEMBER_UPDATE));
    try std.testing.expectEqual(@as(usize, 1), client.listenerCount(.THREAD_MEMBERS_UPDATE));
    client.clearListeners();
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_DELETE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_MEMBER_ADD));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_MEMBER_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_MEMBER_REMOVE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.CHANNEL_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.CHANNEL_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.CHANNEL_DELETE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.USER_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.PRESENCE_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.VOICE_STATE_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.TYPING_START));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.WEBHOOKS_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.INVITE_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.INVITE_DELETE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.AUTO_MODERATION_RULE_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.AUTO_MODERATION_RULE_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.AUTO_MODERATION_RULE_DELETE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.AUTO_MODERATION_ACTION_EXECUTION));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.ENTITLEMENT_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.ENTITLEMENT_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.ENTITLEMENT_DELETE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_SOUNDBOARD_SOUND_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_SOUNDBOARD_SOUND_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_SOUNDBOARD_SOUND_DELETE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_SOUNDBOARD_SOUNDS_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.SOUNDBOARD_SOUNDS));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_ROLE_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_ROLE_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_ROLE_DELETE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_EMOJIS_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_STICKERS_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_SCHEDULED_EVENT_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_SCHEDULED_EVENT_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_SCHEDULED_EVENT_DELETE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_SCHEDULED_EVENT_USER_ADD));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_SCHEDULED_EVENT_USER_REMOVE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.STAGE_INSTANCE_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.STAGE_INSTANCE_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.STAGE_INSTANCE_DELETE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_AUDIT_LOG_ENTRY_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_BAN_ADD));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_BAN_REMOVE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_INTEGRATIONS_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.INTEGRATION_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.INTEGRATION_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.INTEGRATION_DELETE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.GUILD_MEMBERS_CHUNK));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.VOICE_CHANNEL_EFFECT_SEND));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.VOICE_SERVER_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.CHANNEL_INFO));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.VOICE_CHANNEL_STATUS_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.VOICE_CHANNEL_START_TIME_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.CHANNEL_PINS_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.THREAD_CREATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.THREAD_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.THREAD_DELETE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.THREAD_LIST_SYNC));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.THREAD_MEMBER_UPDATE));
    try std.testing.expectEqual(@as(usize, 0), client.listenerCount(.THREAD_MEMBERS_UPDATE));
}
