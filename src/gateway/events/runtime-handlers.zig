const std = @import("std");
const Gateway = @import("../protocol.zig");
const Interactions = @import("../../interactions/mod.zig");

const Root = @import("../events.zig");
const Dispatcher = Root.Dispatcher;
const rawHandler = Root.rawHandler;

test "dispatcher routes common message guild member and channel events" {
    const State = struct {
        message_update: bool = false,
        message_delete: bool = false,
        message_reaction_add: bool = false,
        message_poll_vote_add: bool = false,
        message_poll_vote_remove: bool = false,
        user_update: bool = false,
        presence_update: bool = false,
        voice_state_update: bool = false,
        guild_ban_add: bool = false,
        guild_ban_remove: bool = false,
        guild_integrations_update: bool = false,
        integration_create: bool = false,
        integration_update: bool = false,
        integration_delete: bool = false,
        guild_member_add: bool = false,
        guild_role_update: bool = false,
        guild_emojis_update: bool = false,
        guild_stickers_update: bool = false,
        guild_scheduled_event_create: bool = false,
        guild_scheduled_event_update: bool = false,
        guild_scheduled_event_delete: bool = false,
        guild_scheduled_event_user_add: bool = false,
        guild_scheduled_event_user_remove: bool = false,
        stage_instance_create: bool = false,
        stage_instance_update: bool = false,
        stage_instance_delete: bool = false,
        channel_delete: bool = false,
        channel_pins_update: bool = false,
        typing_start: bool = false,
        webhooks_update: bool = false,
        invite_create: bool = false,
        invite_delete: bool = false,
        thread_create: bool = false,

        pub fn onMessageUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_UPDATE, dispatch.event);
            self.message_update = true;
        }

        pub fn onMessageDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_DELETE, dispatch.event);
            self.message_delete = true;
        }

        pub fn onMessageReactionAdd(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_REACTION_ADD, dispatch.event);
            self.message_reaction_add = true;
        }

        pub fn onMessagePollVoteAdd(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_POLL_VOTE_ADD, dispatch.event);
            self.message_poll_vote_add = true;
        }

        pub fn onMessagePollVoteRemove(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_POLL_VOTE_REMOVE, dispatch.event);
            self.message_poll_vote_remove = true;
        }

        pub fn onUserUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.USER_UPDATE, dispatch.event);
            self.user_update = true;
        }

        pub fn onPresenceUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.PRESENCE_UPDATE, dispatch.event);
            self.presence_update = true;
        }

        pub fn onVoiceStateUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.VOICE_STATE_UPDATE, dispatch.event);
            self.voice_state_update = true;
        }

        pub fn onGuildBanAdd(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_BAN_ADD, dispatch.event);
            self.guild_ban_add = true;
        }

        pub fn onGuildBanRemove(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_BAN_REMOVE, dispatch.event);
            self.guild_ban_remove = true;
        }

        pub fn onGuildIntegrationsUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_INTEGRATIONS_UPDATE, dispatch.event);
            self.guild_integrations_update = true;
        }

        pub fn onIntegrationCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTEGRATION_CREATE, dispatch.event);
            self.integration_create = true;
        }

        pub fn onIntegrationUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTEGRATION_UPDATE, dispatch.event);
            self.integration_update = true;
        }

        pub fn onIntegrationDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTEGRATION_DELETE, dispatch.event);
            self.integration_delete = true;
        }

        pub fn onGuildMemberAdd(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_MEMBER_ADD, dispatch.event);
            self.guild_member_add = true;
        }

        pub fn onGuildRoleUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_ROLE_UPDATE, dispatch.event);
            self.guild_role_update = true;
        }

        pub fn onGuildEmojisUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_EMOJIS_UPDATE, dispatch.event);
            self.guild_emojis_update = true;
        }

        pub fn onGuildStickersUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_STICKERS_UPDATE, dispatch.event);
            self.guild_stickers_update = true;
        }

        pub fn onGuildScheduledEventCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_SCHEDULED_EVENT_CREATE, dispatch.event);
            self.guild_scheduled_event_create = true;
        }

        pub fn onGuildScheduledEventUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_SCHEDULED_EVENT_UPDATE, dispatch.event);
            self.guild_scheduled_event_update = true;
        }

        pub fn onGuildScheduledEventDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_SCHEDULED_EVENT_DELETE, dispatch.event);
            self.guild_scheduled_event_delete = true;
        }

        pub fn onGuildScheduledEventUserAdd(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_SCHEDULED_EVENT_USER_ADD, dispatch.event);
            self.guild_scheduled_event_user_add = true;
        }

        pub fn onGuildScheduledEventUserRemove(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_SCHEDULED_EVENT_USER_REMOVE, dispatch.event);
            self.guild_scheduled_event_user_remove = true;
        }

        pub fn onStageInstanceCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.STAGE_INSTANCE_CREATE, dispatch.event);
            self.stage_instance_create = true;
        }

        pub fn onStageInstanceUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.STAGE_INSTANCE_UPDATE, dispatch.event);
            self.stage_instance_update = true;
        }

        pub fn onStageInstanceDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.STAGE_INSTANCE_DELETE, dispatch.event);
            self.stage_instance_delete = true;
        }

        pub fn onChannelDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.CHANNEL_DELETE, dispatch.event);
            self.channel_delete = true;
        }

        pub fn onChannelPinsUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.CHANNEL_PINS_UPDATE, dispatch.event);
            self.channel_pins_update = true;
        }

        pub fn onTypingStart(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.TYPING_START, dispatch.event);
            self.typing_start = true;
        }

        pub fn onWebhooksUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.WEBHOOKS_UPDATE, dispatch.event);
            self.webhooks_update = true;
        }

        pub fn onInviteCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INVITE_CREATE, dispatch.event);
            self.invite_create = true;
        }

        pub fn onInviteDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INVITE_DELETE, dispatch.event);
            self.invite_delete = true;
        }

        pub fn onThreadCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.THREAD_CREATE, dispatch.event);
            self.thread_create = true;
        }
    };

    var state = State{};
    var dispatcher = Dispatcher{};
    dispatcher.onMessageUpdate(rawHandler(&state, State.onMessageUpdate));
    dispatcher.onMessageDelete(rawHandler(&state, State.onMessageDelete));
    dispatcher.onMessageReactionAdd(rawHandler(&state, State.onMessageReactionAdd));
    dispatcher.onMessagePollVoteAdd(rawHandler(&state, State.onMessagePollVoteAdd));
    dispatcher.onMessagePollVoteRemove(rawHandler(&state, State.onMessagePollVoteRemove));
    dispatcher.onUserUpdate(rawHandler(&state, State.onUserUpdate));
    dispatcher.onPresenceUpdate(rawHandler(&state, State.onPresenceUpdate));
    dispatcher.onVoiceStateUpdate(rawHandler(&state, State.onVoiceStateUpdate));
    dispatcher.onGuildBanAdd(rawHandler(&state, State.onGuildBanAdd));
    dispatcher.onGuildBanRemove(rawHandler(&state, State.onGuildBanRemove));
    dispatcher.onGuildIntegrationsUpdate(rawHandler(&state, State.onGuildIntegrationsUpdate));
    dispatcher.onIntegrationCreate(rawHandler(&state, State.onIntegrationCreate));
    dispatcher.onIntegrationUpdate(rawHandler(&state, State.onIntegrationUpdate));
    dispatcher.onIntegrationDelete(rawHandler(&state, State.onIntegrationDelete));
    dispatcher.onGuildMemberAdd(rawHandler(&state, State.onGuildMemberAdd));
    dispatcher.onGuildRoleUpdate(rawHandler(&state, State.onGuildRoleUpdate));
    dispatcher.onGuildEmojisUpdate(rawHandler(&state, State.onGuildEmojisUpdate));
    dispatcher.onGuildStickersUpdate(rawHandler(&state, State.onGuildStickersUpdate));
    dispatcher.onGuildScheduledEventCreate(rawHandler(&state, State.onGuildScheduledEventCreate));
    dispatcher.onGuildScheduledEventUpdate(rawHandler(&state, State.onGuildScheduledEventUpdate));
    dispatcher.onGuildScheduledEventDelete(rawHandler(&state, State.onGuildScheduledEventDelete));
    dispatcher.onGuildScheduledEventUserAdd(rawHandler(&state, State.onGuildScheduledEventUserAdd));
    dispatcher.onGuildScheduledEventUserRemove(rawHandler(&state, State.onGuildScheduledEventUserRemove));
    dispatcher.onStageInstanceCreate(rawHandler(&state, State.onStageInstanceCreate));
    dispatcher.onStageInstanceUpdate(rawHandler(&state, State.onStageInstanceUpdate));
    dispatcher.onStageInstanceDelete(rawHandler(&state, State.onStageInstanceDelete));
    dispatcher.onChannelDelete(rawHandler(&state, State.onChannelDelete));
    dispatcher.onChannelPinsUpdate(rawHandler(&state, State.onChannelPinsUpdate));
    dispatcher.onTypingStart(rawHandler(&state, State.onTypingStart));
    dispatcher.onWebhooksUpdate(rawHandler(&state, State.onWebhooksUpdate));
    dispatcher.onInviteCreate(rawHandler(&state, State.onInviteCreate));
    dispatcher.onInviteDelete(rawHandler(&state, State.onInviteDelete));
    dispatcher.onThreadCreate(rawHandler(&state, State.onThreadCreate));

    var message_update = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":1,\"t\":\"MESSAGE_UPDATE\",\"d\":{}}");
    defer message_update.deinit();
    try std.testing.expect(try dispatcher.dispatch(message_update));

    var message_delete = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":2,\"t\":\"MESSAGE_DELETE\",\"d\":{}}");
    defer message_delete.deinit();
    try std.testing.expect(try dispatcher.dispatch(message_delete));

    var reaction_add = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":3,\"t\":\"MESSAGE_REACTION_ADD\",\"d\":{}}");
    defer reaction_add.deinit();
    try std.testing.expect(try dispatcher.dispatch(reaction_add));

    var poll_vote_add = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":4,\"t\":\"MESSAGE_POLL_VOTE_ADD\",\"d\":{}}");
    defer poll_vote_add.deinit();
    try std.testing.expect(try dispatcher.dispatch(poll_vote_add));

    var poll_vote_remove = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":5,\"t\":\"MESSAGE_POLL_VOTE_REMOVE\",\"d\":{}}");
    defer poll_vote_remove.deinit();
    try std.testing.expect(try dispatcher.dispatch(poll_vote_remove));

    var user_update = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":6,\"t\":\"USER_UPDATE\",\"d\":{}}");
    defer user_update.deinit();
    try std.testing.expect(try dispatcher.dispatch(user_update));

    var presence_update = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":7,\"t\":\"PRESENCE_UPDATE\",\"d\":{}}");
    defer presence_update.deinit();
    try std.testing.expect(try dispatcher.dispatch(presence_update));

    var voice_state_update = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":8,\"t\":\"VOICE_STATE_UPDATE\",\"d\":{}}");
    defer voice_state_update.deinit();
    try std.testing.expect(try dispatcher.dispatch(voice_state_update));

    var guild_ban_add = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":9,\"t\":\"GUILD_BAN_ADD\",\"d\":{}}");
    defer guild_ban_add.deinit();
    try std.testing.expect(try dispatcher.dispatch(guild_ban_add));

    var guild_ban_remove = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":10,\"t\":\"GUILD_BAN_REMOVE\",\"d\":{}}");
    defer guild_ban_remove.deinit();
    try std.testing.expect(try dispatcher.dispatch(guild_ban_remove));

    var guild_integrations_update = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":11,\"t\":\"GUILD_INTEGRATIONS_UPDATE\",\"d\":{}}");
    defer guild_integrations_update.deinit();
    try std.testing.expect(try dispatcher.dispatch(guild_integrations_update));

    var integration_create = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":12,\"t\":\"INTEGRATION_CREATE\",\"d\":{}}");
    defer integration_create.deinit();
    try std.testing.expect(try dispatcher.dispatch(integration_create));

    var integration_update = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":13,\"t\":\"INTEGRATION_UPDATE\",\"d\":{}}");
    defer integration_update.deinit();
    try std.testing.expect(try dispatcher.dispatch(integration_update));

    var integration_delete = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":14,\"t\":\"INTEGRATION_DELETE\",\"d\":{}}");
    defer integration_delete.deinit();
    try std.testing.expect(try dispatcher.dispatch(integration_delete));

    var guild_member_add = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":15,\"t\":\"GUILD_MEMBER_ADD\",\"d\":{}}");
    defer guild_member_add.deinit();
    try std.testing.expect(try dispatcher.dispatch(guild_member_add));

    var guild_role_update = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":16,\"t\":\"GUILD_ROLE_UPDATE\",\"d\":{}}");
    defer guild_role_update.deinit();
    try std.testing.expect(try dispatcher.dispatch(guild_role_update));

    var guild_emojis_update = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":17,\"t\":\"GUILD_EMOJIS_UPDATE\",\"d\":{}}");
    defer guild_emojis_update.deinit();
    try std.testing.expect(try dispatcher.dispatch(guild_emojis_update));

    var guild_stickers_update = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":18,\"t\":\"GUILD_STICKERS_UPDATE\",\"d\":{}}");
    defer guild_stickers_update.deinit();
    try std.testing.expect(try dispatcher.dispatch(guild_stickers_update));

    var guild_scheduled_event_create = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":19,\"t\":\"GUILD_SCHEDULED_EVENT_CREATE\",\"d\":{}}");
    defer guild_scheduled_event_create.deinit();
    try std.testing.expect(try dispatcher.dispatch(guild_scheduled_event_create));

    var guild_scheduled_event_update = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":20,\"t\":\"GUILD_SCHEDULED_EVENT_UPDATE\",\"d\":{}}");
    defer guild_scheduled_event_update.deinit();
    try std.testing.expect(try dispatcher.dispatch(guild_scheduled_event_update));

    var guild_scheduled_event_delete = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":21,\"t\":\"GUILD_SCHEDULED_EVENT_DELETE\",\"d\":{}}");
    defer guild_scheduled_event_delete.deinit();
    try std.testing.expect(try dispatcher.dispatch(guild_scheduled_event_delete));

    var guild_scheduled_event_user_add = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":22,\"t\":\"GUILD_SCHEDULED_EVENT_USER_ADD\",\"d\":{}}");
    defer guild_scheduled_event_user_add.deinit();
    try std.testing.expect(try dispatcher.dispatch(guild_scheduled_event_user_add));

    var guild_scheduled_event_user_remove = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":23,\"t\":\"GUILD_SCHEDULED_EVENT_USER_REMOVE\",\"d\":{}}");
    defer guild_scheduled_event_user_remove.deinit();
    try std.testing.expect(try dispatcher.dispatch(guild_scheduled_event_user_remove));

    var stage_instance_create = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":24,\"t\":\"STAGE_INSTANCE_CREATE\",\"d\":{}}");
    defer stage_instance_create.deinit();
    try std.testing.expect(try dispatcher.dispatch(stage_instance_create));

    var stage_instance_update = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":25,\"t\":\"STAGE_INSTANCE_UPDATE\",\"d\":{}}");
    defer stage_instance_update.deinit();
    try std.testing.expect(try dispatcher.dispatch(stage_instance_update));

    var stage_instance_delete = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":26,\"t\":\"STAGE_INSTANCE_DELETE\",\"d\":{}}");
    defer stage_instance_delete.deinit();
    try std.testing.expect(try dispatcher.dispatch(stage_instance_delete));

    var channel_delete = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":27,\"t\":\"CHANNEL_DELETE\",\"d\":{}}");
    defer channel_delete.deinit();
    try std.testing.expect(try dispatcher.dispatch(channel_delete));

    var channel_pins_update = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":28,\"t\":\"CHANNEL_PINS_UPDATE\",\"d\":{}}");
    defer channel_pins_update.deinit();
    try std.testing.expect(try dispatcher.dispatch(channel_pins_update));

    var typing_start = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":29,\"t\":\"TYPING_START\",\"d\":{}}");
    defer typing_start.deinit();
    try std.testing.expect(try dispatcher.dispatch(typing_start));

    var webhooks_update = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":30,\"t\":\"WEBHOOKS_UPDATE\",\"d\":{}}");
    defer webhooks_update.deinit();
    try std.testing.expect(try dispatcher.dispatch(webhooks_update));

    var invite_create = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":31,\"t\":\"INVITE_CREATE\",\"d\":{}}");
    defer invite_create.deinit();
    try std.testing.expect(try dispatcher.dispatch(invite_create));

    var invite_delete = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":32,\"t\":\"INVITE_DELETE\",\"d\":{}}");
    defer invite_delete.deinit();
    try std.testing.expect(try dispatcher.dispatch(invite_delete));

    var thread_create = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":33,\"t\":\"THREAD_CREATE\",\"d\":{}}");
    defer thread_create.deinit();
    try std.testing.expect(try dispatcher.dispatch(thread_create));

    try std.testing.expect(state.message_update);
    try std.testing.expect(state.message_delete);
    try std.testing.expect(state.message_reaction_add);
    try std.testing.expect(state.message_poll_vote_add);
    try std.testing.expect(state.message_poll_vote_remove);
    try std.testing.expect(state.user_update);
    try std.testing.expect(state.presence_update);
    try std.testing.expect(state.voice_state_update);
    try std.testing.expect(state.guild_ban_add);
    try std.testing.expect(state.guild_ban_remove);
    try std.testing.expect(state.guild_integrations_update);
    try std.testing.expect(state.integration_create);
    try std.testing.expect(state.integration_update);
    try std.testing.expect(state.integration_delete);
    try std.testing.expect(state.guild_member_add);
    try std.testing.expect(state.guild_role_update);
    try std.testing.expect(state.guild_emojis_update);
    try std.testing.expect(state.guild_stickers_update);
    try std.testing.expect(state.guild_scheduled_event_create);
    try std.testing.expect(state.guild_scheduled_event_update);
    try std.testing.expect(state.guild_scheduled_event_delete);
    try std.testing.expect(state.guild_scheduled_event_user_add);
    try std.testing.expect(state.guild_scheduled_event_user_remove);
    try std.testing.expect(state.stage_instance_create);
    try std.testing.expect(state.stage_instance_update);
    try std.testing.expect(state.stage_instance_delete);
    try std.testing.expect(state.channel_delete);
    try std.testing.expect(state.channel_pins_update);
    try std.testing.expect(state.typing_start);
    try std.testing.expect(state.webhooks_update);
    try std.testing.expect(state.invite_create);
    try std.testing.expect(state.invite_delete);
    try std.testing.expect(state.thread_create);
}

test "dispatcher routes filtered interaction handlers" {
    const State = struct {
        raw: usize = 0,
        component: bool = false,
        modal: bool = false,

        pub fn onRaw(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTERACTION_CREATE, dispatch.event);
            self.raw += 1;
        }

        pub fn onComponent(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTERACTION_CREATE, dispatch.event);
            self.component = true;
        }

        pub fn onModal(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTERACTION_CREATE, dispatch.event);
            self.modal = true;
        }
    };

    var state = State{};
    var dispatcher = Dispatcher{};
    dispatcher.onInteractionCreate(rawHandler(&state, State.onRaw));
    dispatcher.onMessageComponent(rawHandler(&state, State.onComponent));
    dispatcher.onModalSubmit(rawHandler(&state, State.onModal));

    var component = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"1\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"data\":{\"custom_id\":\"ok\",\"component_type\":2}}}",
    );
    defer component.deinit();
    try std.testing.expect(try dispatcher.dispatch(component));

    var modal = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"3\",\"application_id\":\"2\",\"type\":5,\"token\":\"tok\",\"data\":{\"custom_id\":\"modal\"}}}",
    );
    defer modal.deinit();
    try std.testing.expect(try dispatcher.dispatch(modal));

    try std.testing.expectEqual(@as(usize, 2), state.raw);
    try std.testing.expect(state.component);
    try std.testing.expect(state.modal);
}
