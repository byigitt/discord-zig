const std = @import("std");
const Rest = @import("../../rest/client.zig");
const Events = @import("../../gateway/events.zig");
const Gateway = @import("../../gateway/protocol.zig");
const Types = @import("../../models/types.zig");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Root = @import("../client.zig");
const Client = Root.Client;

test "client event convenience registers handler" {
    const State = struct {
        called: bool = false,
        deleted: bool = false,
        reaction_added: bool = false,
        poll_vote_added: bool = false,
        poll_vote_removed: bool = false,
        user_updated: bool = false,
        presence_updated: bool = false,
        voice_state_updated: bool = false,
        typing_started: bool = false,
        webhooks_updated: bool = false,
        invite_created: bool = false,
        invite_deleted: bool = false,
        guild_ban_added: bool = false,
        guild_ban_removed: bool = false,
        guild_integrations_updated: bool = false,
        integration_created: bool = false,
        integration_updated: bool = false,
        integration_deleted: bool = false,
        channel_pins_updated: bool = false,
        thread_created: bool = false,
        guild_emojis_updated: bool = false,
        guild_stickers_updated: bool = false,
        guild_scheduled_event_created: bool = false,
        stage_instance_created: bool = false,
        application_command: bool = false,
        guild_created: bool = false,

        fn onMessage(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            _ = dispatch;
            self.called = true;
        }

        fn onMessageDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_DELETE, dispatch.event);
            self.deleted = true;
        }

        fn onMessageReactionAdd(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_REACTION_ADD, dispatch.event);
            self.reaction_added = true;
        }

        fn onMessagePollVoteAdd(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_POLL_VOTE_ADD, dispatch.event);
            self.poll_vote_added = true;
        }

        fn onMessagePollVoteRemove(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_POLL_VOTE_REMOVE, dispatch.event);
            self.poll_vote_removed = true;
        }

        fn onUserUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.USER_UPDATE, dispatch.event);
            self.user_updated = true;
        }

        fn onPresenceUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.PRESENCE_UPDATE, dispatch.event);
            self.presence_updated = true;
        }

        fn onVoiceStateUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.VOICE_STATE_UPDATE, dispatch.event);
            self.voice_state_updated = true;
        }

        fn onTypingStart(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.TYPING_START, dispatch.event);
            self.typing_started = true;
        }

        fn onWebhooksUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.WEBHOOKS_UPDATE, dispatch.event);
            self.webhooks_updated = true;
        }

        fn onInviteCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INVITE_CREATE, dispatch.event);
            self.invite_created = true;
        }

        fn onInviteDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INVITE_DELETE, dispatch.event);
            self.invite_deleted = true;
        }

        fn onGuildBanAdd(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_BAN_ADD, dispatch.event);
            self.guild_ban_added = true;
        }

        fn onGuildCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_CREATE, dispatch.event);
            self.guild_created = true;
        }

        fn onGuildBanRemove(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_BAN_REMOVE, dispatch.event);
            self.guild_ban_removed = true;
        }

        fn onGuildIntegrationsUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_INTEGRATIONS_UPDATE, dispatch.event);
            self.guild_integrations_updated = true;
        }

        fn onIntegrationCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTEGRATION_CREATE, dispatch.event);
            self.integration_created = true;
        }

        fn onIntegrationUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTEGRATION_UPDATE, dispatch.event);
            self.integration_updated = true;
        }

        fn onIntegrationDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTEGRATION_DELETE, dispatch.event);
            self.integration_deleted = true;
        }

        fn onChannelPinsUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.CHANNEL_PINS_UPDATE, dispatch.event);
            self.channel_pins_updated = true;
        }

        fn onThreadCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.THREAD_CREATE, dispatch.event);
            self.thread_created = true;
        }

        fn onGuildEmojisUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_EMOJIS_UPDATE, dispatch.event);
            self.guild_emojis_updated = true;
        }

        fn onGuildStickersUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_STICKERS_UPDATE, dispatch.event);
            self.guild_stickers_updated = true;
        }

        fn onGuildScheduledEventCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_SCHEDULED_EVENT_CREATE, dispatch.event);
            self.guild_scheduled_event_created = true;
        }

        fn onStageInstanceCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.STAGE_INSTANCE_CREATE, dispatch.event);
            self.stage_instance_created = true;
        }

        fn onApplicationCommand(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTERACTION_CREATE, dispatch.event);
            self.application_command = true;
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

    client.onMessageCreate(Events.rawHandler(&state, State.onMessage));
    client.onMessageDelete(Events.rawHandler(&state, State.onMessageDelete));
    client.onMessageReactionAdd(Events.rawHandler(&state, State.onMessageReactionAdd));
    client.onMessagePollVoteAdd(Events.rawHandler(&state, State.onMessagePollVoteAdd));
    client.onMessagePollVoteRemove(Events.rawHandler(&state, State.onMessagePollVoteRemove));
    client.onUserUpdate(Events.rawHandler(&state, State.onUserUpdate));
    client.onPresenceUpdate(Events.rawHandler(&state, State.onPresenceUpdate));
    client.onVoiceStateUpdate(Events.rawHandler(&state, State.onVoiceStateUpdate));
    client.onTypingStart(Events.rawHandler(&state, State.onTypingStart));
    client.onWebhooksUpdate(Events.rawHandler(&state, State.onWebhooksUpdate));
    client.onInviteCreate(Events.rawHandler(&state, State.onInviteCreate));
    client.onInviteDelete(Events.rawHandler(&state, State.onInviteDelete));
    client.onGuildCreate(Events.rawHandler(&state, State.onGuildCreate));
    client.onGuildBanAdd(Events.rawHandler(&state, State.onGuildBanAdd));
    client.onGuildBanRemove(Events.rawHandler(&state, State.onGuildBanRemove));
    client.onGuildIntegrationsUpdate(Events.rawHandler(&state, State.onGuildIntegrationsUpdate));
    client.onIntegrationCreate(Events.rawHandler(&state, State.onIntegrationCreate));
    client.onIntegrationUpdate(Events.rawHandler(&state, State.onIntegrationUpdate));
    client.onIntegrationDelete(Events.rawHandler(&state, State.onIntegrationDelete));
    client.onChannelPinsUpdate(Events.rawHandler(&state, State.onChannelPinsUpdate));
    client.onThreadCreate(Events.rawHandler(&state, State.onThreadCreate));
    client.onGuildEmojisUpdate(Events.rawHandler(&state, State.onGuildEmojisUpdate));
    client.onGuildStickersUpdate(Events.rawHandler(&state, State.onGuildStickersUpdate));
    client.onGuildScheduledEventCreate(Events.rawHandler(&state, State.onGuildScheduledEventCreate));
    client.onStageInstanceCreate(Events.rawHandler(&state, State.onStageInstanceCreate));
    client.onApplicationCommand(Events.rawHandler(&state, State.onApplicationCommand));
    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":1,\"t\":\"MESSAGE_CREATE\",\"d\":{\"id\":\"10\",\"channel_id\":\"20\",\"guild_id\":\"40\",\"content\":\"pong\",\"author\":{\"id\":\"30\",\"username\":\"bot\"}}}",
    );

    try std.testing.expect(state.called);
    try std.testing.expect(client.getCachedMessage(Snowflake.init(10)) != null);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":2,\"t\":\"MESSAGE_CREATE\",\"d\":{\"id\":\"11\",\"channel_id\":\"21\",\"content\":\"dm\",\"author\":{\"id\":\"31\",\"username\":\"friend\"}}}",
    );

    const channel_messages = try client.listCachedChannelMessages(std.testing.allocator, Snowflake.init(20));
    defer std.testing.allocator.free(channel_messages);
    try std.testing.expectEqual(@as(usize, 1), channel_messages.len);
    try std.testing.expectEqualStrings("pong", channel_messages[0].content);
    const channel_messages_alias = try client.cachedChannelMessages(std.testing.allocator, Snowflake.init(20));
    defer std.testing.allocator.free(channel_messages_alias);
    try std.testing.expectEqual(@as(usize, 1), channel_messages_alias.len);

    const all_messages = try client.listCachedMessages(std.testing.allocator);
    defer std.testing.allocator.free(all_messages);
    try std.testing.expectEqual(@as(usize, 2), all_messages.len);
    try std.testing.expectEqualStrings("pong", all_messages[0].content);
    try std.testing.expectEqualStrings("dm", all_messages[1].content);
    const all_messages_alias = try client.cachedMessages(std.testing.allocator);
    defer std.testing.allocator.free(all_messages_alias);
    try std.testing.expectEqual(@as(usize, 2), all_messages_alias.len);

    const guild_messages = try client.listCachedGuildMessages(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(guild_messages);
    try std.testing.expectEqual(@as(usize, 1), guild_messages.len);
    try std.testing.expectEqualStrings("pong", guild_messages[0].content);
    const guild_messages_alias = try client.cachedGuildMessages(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(guild_messages_alias);
    try std.testing.expectEqual(@as(usize, 1), guild_messages_alias.len);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":3,\"t\":\"MESSAGE_DELETE\",\"d\":{\"id\":\"10\",\"channel_id\":\"20\"}}",
    );

    try std.testing.expect(state.deleted);
    try std.testing.expect(client.getCachedMessage(Snowflake.init(10)) == null);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":4,\"t\":\"MESSAGE_REACTION_ADD\",\"d\":{\"user_id\":\"30\",\"channel_id\":\"20\",\"message_id\":\"10\",\"emoji\":{\"name\":\"👍\"}}}",
    );

    try std.testing.expect(state.reaction_added);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":4,\"t\":\"MESSAGE_POLL_VOTE_ADD\",\"d\":{\"user_id\":\"30\",\"channel_id\":\"20\",\"message_id\":\"10\",\"answer_id\":1}}",
    );

    try std.testing.expect(state.poll_vote_added);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":5,\"t\":\"MESSAGE_POLL_VOTE_REMOVE\",\"d\":{\"user_id\":\"30\",\"channel_id\":\"20\",\"message_id\":\"10\",\"answer_id\":1}}",
    );

    try std.testing.expect(state.poll_vote_removed);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":6,\"t\":\"USER_UPDATE\",\"d\":{\"id\":\"30\",\"username\":\"renamed\",\"global_name\":\"Renamed Bot\"}}",
    );

    try std.testing.expect(state.user_updated);
    try std.testing.expectEqualStrings("renamed", client.getCachedUser(Snowflake.init(30)).?.username);
    const cached_users = try client.listCachedUsers(std.testing.allocator);
    defer std.testing.allocator.free(cached_users);
    try std.testing.expectEqual(@as(usize, 2), cached_users.len);
    const cached_users_alias = try client.cachedUsers(std.testing.allocator);
    defer std.testing.allocator.free(cached_users_alias);
    try std.testing.expectEqual(@as(usize, 2), cached_users_alias.len);
    var saw_renamed_user = false;
    var saw_friend_user = false;
    for (cached_users) |user| {
        if (user.id.value == 30 and std.mem.eql(u8, user.username, "renamed")) saw_renamed_user = true;
        if (user.id.value == 31 and std.mem.eql(u8, user.username, "friend")) saw_friend_user = true;
    }
    try std.testing.expect(saw_renamed_user);
    try std.testing.expect(saw_friend_user);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":7,\"t\":\"PRESENCE_UPDATE\",\"d\":{\"guild_id\":\"40\",\"user\":{\"id\":\"30\"},\"status\":\"dnd\",\"activities\":[{\"name\":\"debug\",\"type\":0}]}}",
    );

    try std.testing.expect(state.presence_updated);
    try std.testing.expectEqualStrings("dnd", client.getCachedPresence(Snowflake.init(40), Snowflake.init(30)).?.status);
    try std.testing.expectEqualStrings("dnd", client.cachedPresence(Snowflake.init(40), Snowflake.init(30)).?.status);
    const all_cached_presences = try client.listCachedPresences(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_presences);
    try std.testing.expectEqual(@as(usize, 1), all_cached_presences.len);
    try std.testing.expectEqualStrings("dnd", all_cached_presences[0].status);
    const all_cached_presences_alias = try client.cachedPresences(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_presences_alias);
    try std.testing.expectEqual(@as(usize, 1), all_cached_presences_alias.len);
    const cached_presences = try client.listCachedGuildPresences(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_presences);
    try std.testing.expectEqual(@as(usize, 1), cached_presences.len);
    try std.testing.expectEqualStrings("dnd", cached_presences[0].status);
    const cached_presences_alias = try client.cachedGuildPresences(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_presences_alias);
    try std.testing.expectEqual(@as(usize, 1), cached_presences_alias.len);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":8,\"t\":\"VOICE_STATE_UPDATE\",\"d\":{\"guild_id\":\"40\",\"channel_id\":\"80\",\"user_id\":\"30\",\"session_id\":\"voice-session\",\"deaf\":false,\"mute\":false,\"self_deaf\":false,\"self_mute\":true,\"self_video\":false,\"suppress\":false}}",
    );

    try std.testing.expect(state.voice_state_updated);
    try std.testing.expectEqual(@as(u64, 80), client.getCachedVoiceState(Snowflake.init(40), Snowflake.init(30)).?.channel_id.?.value);
    try std.testing.expectEqualStrings("voice-session", client.cachedVoiceState(Snowflake.init(40), Snowflake.init(30)).?.session_id);
    const all_cached_voice_states = try client.listCachedVoiceStates(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_voice_states);
    try std.testing.expectEqual(@as(usize, 1), all_cached_voice_states.len);
    try std.testing.expectEqualStrings("voice-session", all_cached_voice_states[0].session_id);
    const all_cached_voice_states_alias = try client.cachedVoiceStates(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_voice_states_alias);
    try std.testing.expectEqual(@as(usize, 1), all_cached_voice_states_alias.len);
    const cached_voice_states = try client.listCachedGuildVoiceStates(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_voice_states);
    try std.testing.expectEqual(@as(usize, 1), cached_voice_states.len);
    try std.testing.expectEqualStrings("voice-session", cached_voice_states[0].session_id);
    const cached_voice_states_alias = try client.cachedGuildVoiceStates(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_voice_states_alias);
    try std.testing.expectEqual(@as(usize, 1), cached_voice_states_alias.len);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":9,\"t\":\"CHANNEL_PINS_UPDATE\",\"d\":{\"guild_id\":\"40\",\"channel_id\":\"20\",\"last_pin_timestamp\":\"2026-06-02T10:00:00.000Z\"}}",
    );

    try std.testing.expect(state.channel_pins_updated);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":10,\"t\":\"TYPING_START\",\"d\":{\"channel_id\":\"20\",\"guild_id\":\"40\",\"user_id\":\"30\",\"timestamp\":1717350000}}",
    );

    try std.testing.expect(state.typing_started);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":11,\"t\":\"WEBHOOKS_UPDATE\",\"d\":{\"guild_id\":\"40\",\"channel_id\":\"20\"}}",
    );

    try std.testing.expect(state.webhooks_updated);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":12,\"t\":\"GUILD_CREATE\",\"d\":{\"id\":\"40\",\"name\":\"Guild\"}}",
    );

    try std.testing.expect(state.guild_created);
    try std.testing.expectEqualStrings("Guild", client.getCachedGuild(Snowflake.init(40)).?.name);
    const cached_guilds = try client.listCachedGuilds(std.testing.allocator);
    defer std.testing.allocator.free(cached_guilds);
    try std.testing.expectEqual(@as(usize, 1), cached_guilds.len);
    try std.testing.expectEqualStrings("Guild", cached_guilds[0].name);
    const cached_guilds_alias = try client.cachedGuilds(std.testing.allocator);
    defer std.testing.allocator.free(cached_guilds_alias);
    try std.testing.expectEqual(@as(usize, 1), cached_guilds_alias.len);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":13,\"t\":\"INVITE_CREATE\",\"d\":{\"code\":\"abc123\",\"guild_id\":\"40\",\"channel_id\":\"20\"}}",
    );

    try std.testing.expect(state.invite_created);
    try std.testing.expectEqualStrings("abc123", client.getCachedInvite("abc123").?.code);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":14,\"t\":\"INVITE_DELETE\",\"d\":{\"code\":\"abc123\",\"guild_id\":\"40\",\"channel_id\":\"20\"}}",
    );

    try std.testing.expect(state.invite_deleted);
    try std.testing.expect(client.getCachedInvite("abc123") == null);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":15,\"t\":\"GUILD_BAN_ADD\",\"d\":{\"guild_id\":\"40\",\"user\":{\"id\":\"60\",\"username\":\"spammer\"}}}",
    );

    try std.testing.expect(state.guild_ban_added);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":16,\"t\":\"GUILD_BAN_REMOVE\",\"d\":{\"guild_id\":\"40\",\"user\":{\"id\":\"60\",\"username\":\"spammer\"}}}",
    );

    try std.testing.expect(state.guild_ban_removed);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":17,\"t\":\"GUILD_INTEGRATIONS_UPDATE\",\"d\":{\"guild_id\":\"40\"}}",
    );

    try std.testing.expect(state.guild_integrations_updated);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":18,\"t\":\"INTEGRATION_CREATE\",\"d\":{\"id\":\"100\",\"guild_id\":\"40\",\"name\":\"Twitch\"}}",
    );

    try std.testing.expect(state.integration_created);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":19,\"t\":\"INTEGRATION_UPDATE\",\"d\":{\"id\":\"100\",\"guild_id\":\"40\",\"name\":\"Twitch\"}}",
    );

    try std.testing.expect(state.integration_updated);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":20,\"t\":\"INTEGRATION_DELETE\",\"d\":{\"id\":\"100\",\"guild_id\":\"40\",\"application_id\":null}}",
    );

    try std.testing.expect(state.integration_deleted);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":21,\"t\":\"GUILD_MEMBER_ADD\",\"d\":{\"guild_id\":\"40\",\"user\":{\"id\":\"50\",\"username\":\"helper\"},\"nick\":\"ziggy\",\"roles\":[\"60\"]}}",
    );

    const member = client.getCachedMember(Snowflake.init(40), Snowflake.init(50)).?;
    try std.testing.expectEqualStrings("ziggy", member.nick.?);
    try std.testing.expectEqual(@as(u64, 60), member.roles[0].value);
    const cached_members = try client.listCachedGuildMembers(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_members);
    try std.testing.expectEqual(@as(usize, 1), cached_members.len);
    try std.testing.expectEqualStrings("helper", cached_members[0].user.?.username);
    try std.testing.expectEqualStrings("helper", client.cachedMember(Snowflake.init(40), Snowflake.init(50)).?.user.?.username);
    const cached_members_alias = try client.cachedGuildMembers(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_members_alias);
    try std.testing.expectEqual(@as(usize, 1), cached_members_alias.len);
    const all_cached_members = try client.listCachedMembers(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_members);
    try std.testing.expectEqual(@as(usize, 1), all_cached_members.len);
    try std.testing.expectEqual(@as(u64, 40), all_cached_members[0].guild_id.value);
    try std.testing.expectEqualStrings("helper", all_cached_members[0].member.user.?.username);
    const all_cached_members_alias = try client.cachedMembers(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_members_alias);
    try std.testing.expectEqual(@as(usize, 1), all_cached_members_alias.len);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":22,\"t\":\"GUILD_ROLE_CREATE\",\"d\":{\"guild_id\":\"40\",\"role\":{\"id\":\"70\",\"name\":\"Helper\",\"permissions\":\"8\"}}}",
    );

    const role = client.getCachedRole(Snowflake.init(40), Snowflake.init(70)).?;
    try std.testing.expectEqualStrings("Helper", role.name);
    try std.testing.expectEqual(@as(u64, 8), role.permissions);
    try std.testing.expectEqualStrings("Helper", client.cachedRole(Snowflake.init(40), Snowflake.init(70)).?.name);
    const cached_roles = try client.listCachedGuildRoles(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_roles);
    try std.testing.expectEqual(@as(usize, 1), cached_roles.len);
    try std.testing.expectEqualStrings("Helper", cached_roles[0].name);
    const cached_roles_alias = try client.cachedGuildRoles(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_roles_alias);
    try std.testing.expectEqual(@as(usize, 1), cached_roles_alias.len);
    const all_cached_roles = try client.listCachedRoles(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_roles);
    try std.testing.expectEqual(@as(usize, 1), all_cached_roles.len);
    try std.testing.expectEqualStrings("Helper", all_cached_roles[0].name);
    const all_cached_roles_alias = try client.cachedRoles(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_roles_alias);
    try std.testing.expectEqual(@as(usize, 1), all_cached_roles_alias.len);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":23,\"t\":\"THREAD_CREATE\",\"d\":{\"id\":\"90\",\"type\":11,\"guild_id\":\"40\",\"parent_id\":\"80\",\"name\":\"debug\"}}",
    );

    try std.testing.expect(state.thread_created);
    try std.testing.expectEqual(Types.ChannelType.public_thread, client.getCachedChannel(Snowflake.init(90)).?.type);
    const all_cached_channels = try client.listCachedChannels(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_channels);
    try std.testing.expectEqual(@as(usize, 1), all_cached_channels.len);
    try std.testing.expectEqual(@as(u64, 90), all_cached_channels[0].id.value);
    const all_cached_channels_alias = try client.cachedChannels(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_channels_alias);
    try std.testing.expectEqual(@as(usize, 1), all_cached_channels_alias.len);
    const top_level_cached_channels = try client.listCachedTopLevelChannels(std.testing.allocator);
    defer std.testing.allocator.free(top_level_cached_channels);
    try std.testing.expectEqual(@as(usize, 0), top_level_cached_channels.len);
    const top_level_cached_channels_alias = try client.cachedTopLevelChannels(std.testing.allocator);
    defer std.testing.allocator.free(top_level_cached_channels_alias);
    try std.testing.expectEqual(@as(usize, 0), top_level_cached_channels_alias.len);
    const cached_channels = try client.listCachedGuildChannels(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_channels);
    try std.testing.expectEqual(@as(usize, 0), cached_channels.len);
    const cached_threads = try client.listCachedChannelThreads(std.testing.allocator, Snowflake.init(80));
    defer std.testing.allocator.free(cached_threads);
    try std.testing.expectEqual(@as(usize, 1), cached_threads.len);
    try std.testing.expectEqualStrings("debug", cached_threads[0].name.?);

    const cached_guild_threads = try client.listCachedGuildThreads(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_guild_threads);
    try std.testing.expectEqual(@as(usize, 1), cached_guild_threads.len);
    try std.testing.expectEqualStrings("debug", cached_guild_threads[0].name.?);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":24,\"t\":\"GUILD_EMOJIS_UPDATE\",\"d\":{\"guild_id\":\"40\",\"emojis\":[{\"id\":\"91\",\"name\":\"zig\",\"roles\":[\"70\"],\"user\":{\"id\":\"30\",\"username\":\"renamed\"},\"animated\":true}]}}",
    );

    try std.testing.expect(state.guild_emojis_updated);
    const emoji = client.getCachedEmoji(Snowflake.init(40), Snowflake.init(91)).?;
    try std.testing.expectEqualStrings("zig", emoji.name.?);
    try std.testing.expectEqual(@as(u64, 70), emoji.roles[0].value);
    try std.testing.expect(emoji.animated);
    try std.testing.expectEqualStrings("zig", client.cachedEmoji(Snowflake.init(40), Snowflake.init(91)).?.name.?);
    const cached_emojis = try client.listCachedGuildEmojis(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_emojis);
    try std.testing.expectEqual(@as(usize, 1), cached_emojis.len);
    try std.testing.expectEqualStrings("zig", cached_emojis[0].name.?);
    const all_cached_emojis = try client.listCachedEmojis(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_emojis);
    try std.testing.expectEqual(@as(usize, 1), all_cached_emojis.len);
    try std.testing.expectEqualStrings("zig", all_cached_emojis[0].name.?);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":25,\"t\":\"GUILD_STICKERS_UPDATE\",\"d\":{\"guild_id\":\"40\",\"stickers\":[{\"id\":\"92\",\"name\":\"ziggy\",\"description\":\"mascot\",\"tags\":\"zig\",\"type\":2,\"format_type\":1,\"guild_id\":\"40\",\"user\":{\"id\":\"30\",\"username\":\"renamed\"}}]}}",
    );

    try std.testing.expect(state.guild_stickers_updated);
    const sticker = client.getCachedSticker(Snowflake.init(40), Snowflake.init(92)).?;
    try std.testing.expectEqualStrings("ziggy", sticker.name);
    try std.testing.expectEqualStrings("mascot", sticker.description.?);
    try std.testing.expectEqual(Types.StickerFormatType.png, sticker.format_type);
    try std.testing.expectEqualStrings("ziggy", client.cachedSticker(Snowflake.init(40), Snowflake.init(92)).?.name);
    const cached_stickers = try client.listCachedGuildStickers(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_stickers);
    try std.testing.expectEqual(@as(usize, 1), cached_stickers.len);
    try std.testing.expectEqualStrings("ziggy", cached_stickers[0].name);
    const all_cached_stickers = try client.listCachedStickers(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_stickers);
    try std.testing.expectEqual(@as(usize, 1), all_cached_stickers.len);
    try std.testing.expectEqualStrings("ziggy", all_cached_stickers[0].name);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":26,\"t\":\"GUILD_SCHEDULED_EVENT_CREATE\",\"d\":{\"id\":\"93\",\"guild_id\":\"40\",\"channel_id\":\"80\",\"name\":\"Launch\",\"description\":\"Ship\",\"scheduled_start_time\":\"2026-06-02T10:00:00.000Z\",\"privacy_level\":2,\"status\":1,\"entity_type\":2,\"user_count\":3}}",
    );

    try std.testing.expect(state.guild_scheduled_event_created);
    const scheduled_event = client.getCachedScheduledEvent(Snowflake.init(40), Snowflake.init(93)).?;
    try std.testing.expectEqualStrings("Launch", scheduled_event.name);
    try std.testing.expectEqualStrings("Ship", scheduled_event.description.?);
    try std.testing.expectEqual(Types.GuildScheduledEventStatus.scheduled, scheduled_event.status);
    try std.testing.expectEqualStrings("Launch", client.cachedScheduledEvent(Snowflake.init(40), Snowflake.init(93)).?.name);
    const cached_scheduled_events = try client.listCachedGuildScheduledEvents(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_scheduled_events);
    try std.testing.expectEqual(@as(usize, 1), cached_scheduled_events.len);
    try std.testing.expectEqualStrings("Launch", cached_scheduled_events[0].name);
    const all_cached_scheduled_events = try client.listCachedScheduledEvents(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_scheduled_events);
    try std.testing.expectEqual(@as(usize, 1), all_cached_scheduled_events.len);
    try std.testing.expectEqualStrings("Launch", all_cached_scheduled_events[0].name);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":27,\"t\":\"STAGE_INSTANCE_CREATE\",\"d\":{\"id\":\"94\",\"guild_id\":\"40\",\"channel_id\":\"80\",\"topic\":\"Live Q&A\",\"privacy_level\":2,\"discoverable_disabled\":false,\"guild_scheduled_event_id\":\"93\"}}",
    );

    try std.testing.expect(state.stage_instance_created);
    const stage_instance = client.getCachedStageInstance(Snowflake.init(40), Snowflake.init(94)).?;
    try std.testing.expectEqualStrings("Live Q&A", stage_instance.topic);
    try std.testing.expectEqual(@as(u64, 93), stage_instance.guild_scheduled_event_id.?.value);
    try std.testing.expectEqualStrings("Live Q&A", client.cachedStageInstance(Snowflake.init(40), Snowflake.init(94)).?.topic);
    const cached_stage_instances = try client.listCachedGuildStageInstances(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_stage_instances);
    try std.testing.expectEqual(@as(usize, 1), cached_stage_instances.len);
    try std.testing.expectEqualStrings("Live Q&A", cached_stage_instances[0].topic);
    const all_cached_stage_instances = try client.listCachedStageInstances(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_stage_instances);
    try std.testing.expectEqual(@as(usize, 1), all_cached_stage_instances.len);
    try std.testing.expectEqualStrings("Live Q&A", all_cached_stage_instances[0].topic);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":28,\"t\":\"INVITE_CREATE\",\"d\":{\"code\":\"xyz789\",\"guild_id\":\"40\",\"channel_id\":\"80\"}}",
    );

    const all_cached_invites = try client.listCachedInvites(std.testing.allocator);
    defer std.testing.allocator.free(all_cached_invites);
    try std.testing.expectEqual(@as(usize, 1), all_cached_invites.len);
    try std.testing.expectEqualStrings("xyz789", all_cached_invites[0].code);
    try std.testing.expectEqualStrings("xyz789", client.cachedInvite("xyz789").?.code);
    const cached_guild_invites = try client.listCachedGuildInvites(std.testing.allocator, Snowflake.init(40));
    defer std.testing.allocator.free(cached_guild_invites);
    try std.testing.expectEqual(@as(usize, 1), cached_guild_invites.len);
    try std.testing.expectEqualStrings("xyz789", cached_guild_invites[0].code);
    const cached_channel_invites = try client.listCachedChannelInvites(std.testing.allocator, Snowflake.init(80));
    defer std.testing.allocator.free(cached_channel_invites);
    try std.testing.expectEqual(@as(usize, 1), cached_channel_invites.len);
    try std.testing.expectEqualStrings("xyz789", cached_channel_invites[0].code);

    _ = try client.dispatchGatewayPayload(
        "{\"op\":0,\"s\":29,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"3\",\"name\":\"ping\",\"type\":1}}}",
    );

    try std.testing.expect(state.application_command);
}
