const std = @import("std");
const Gateway = @import("../protocol.zig");
const Interactions = @import("../../interactions/mod.zig");

const Root = @import("../events.zig");
const RawHandler = Root.RawHandler;
const Dispatcher = Root.Dispatcher;

pub fn interactionType(event: Gateway.ParsedDispatch) !Interactions.InteractionType {
    const object = switch (event.data) {
        .object => |object| object,
        else => return error.InvalidInteractionPayload,
    };
    const type_value = object.get("type") orelse return error.InvalidInteractionPayload;
    const raw_type: u8 = @intCast(type_value.integer);
    return switch (raw_type) {
        1 => .ping,
        2 => .application_command,
        3 => .message_component,
        4 => .application_command_autocomplete,
        5 => .modal_submit,
        else => error.InvalidInteractionPayload,
    };
}

pub fn rawHandler(ptr: anytype, comptime function: anytype) RawHandler {
    const Ptr = @TypeOf(ptr);
    const wrapper = struct {
        pub fn call(raw: *anyopaque, dispatch: Gateway.ParsedDispatch) anyerror!void {
            const typed: Ptr = @ptrCast(@alignCast(raw));
            try function(typed, dispatch);
        }
    };

    return .{ .ptr = ptr, .callFn = wrapper.call };
}

test "dispatcher calls typed message handler" {
    const State = struct {
        called: bool = false,

        pub fn onMessage(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            _ = dispatch;
            self.called = true;
        }
    };

    var state = State{};
    var dispatcher = Dispatcher{};
    dispatcher.onMessageCreate(rawHandler(&state, State.onMessage));

    var parsed = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"MESSAGE_CREATE\",\"d\":{}}",
    );
    defer parsed.deinit();

    try std.testing.expect(try dispatcher.dispatch(parsed));
    try std.testing.expect(state.called);
}

test "dispatcher supports generic once and clear listeners" {
    const State = struct {
        messages: usize = 0,

        pub fn onMessage(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_CREATE, dispatch.event);
            self.messages += 1;
        }
    };

    var state = State{};
    var dispatcher = Dispatcher{};
    try std.testing.expect(!dispatcher.hasListener(.MESSAGE_CREATE));
    try std.testing.expectEqual(@as(usize, 0), dispatcher.listenerCount(.MESSAGE_CREATE));

    dispatcher.once(.MESSAGE_CREATE, rawHandler(&state, State.onMessage));
    try std.testing.expect(dispatcher.hasListener(.MESSAGE_CREATE));
    try std.testing.expectEqual(@as(usize, 1), dispatcher.listenerCount(.MESSAGE_CREATE));

    var first = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"MESSAGE_CREATE\",\"d\":{}}",
    );
    defer first.deinit();
    try std.testing.expect(try dispatcher.dispatch(first));
    try std.testing.expectEqual(@as(usize, 1), state.messages);
    try std.testing.expect(!dispatcher.hasListener(.MESSAGE_CREATE));
    try std.testing.expectEqual(@as(usize, 0), dispatcher.listenerCount(.MESSAGE_CREATE));

    var second = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"MESSAGE_CREATE\",\"d\":{}}",
    );
    defer second.deinit();
    try std.testing.expect(!try dispatcher.dispatch(second));
    try std.testing.expectEqual(@as(usize, 1), state.messages);

    dispatcher.on(.MESSAGE_CREATE, rawHandler(&state, State.onMessage));
    try std.testing.expectEqual(@as(usize, 1), dispatcher.listenerCount(.MESSAGE_CREATE));
    dispatcher.clear(.MESSAGE_CREATE);
    try std.testing.expect(!dispatcher.hasListener(.MESSAGE_CREATE));
    try std.testing.expect(!try dispatcher.dispatch(second));

    dispatcher.on(.MESSAGE_CREATE, rawHandler(&state, State.onMessage));
    dispatcher.on(.READY, rawHandler(&state, State.onMessage));
    try std.testing.expectEqual(@as(usize, 1), dispatcher.listenerCount(.MESSAGE_CREATE));
    try std.testing.expectEqual(@as(usize, 1), dispatcher.listenerCount(.READY));
    const names = try dispatcher.eventNames(std.testing.allocator);
    defer std.testing.allocator.free(names);
    try std.testing.expectEqual(@as(usize, 2), names.len);
    try std.testing.expect(std.mem.indexOfScalar(Gateway.EventName, names, .READY) != null);
    try std.testing.expect(std.mem.indexOfScalar(Gateway.EventName, names, .MESSAGE_CREATE) != null);

    dispatcher.clearAll();
    try std.testing.expectEqual(@as(usize, 0), dispatcher.listenerCount(.MESSAGE_CREATE));
    try std.testing.expectEqual(@as(usize, 0), dispatcher.listenerCount(.READY));
    const empty_names = try dispatcher.eventNames(std.testing.allocator);
    defer std.testing.allocator.free(empty_names);
    try std.testing.expectEqual(@as(usize, 0), empty_names.len);
    try std.testing.expect(!try dispatcher.dispatch(second));
}

test "typed persistent listener replaces one-shot state for same event" {
    const State = struct {
        messages: usize = 0,

        pub fn onMessage(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_CREATE, dispatch.event);
            self.messages += 1;
        }
    };

    var state = State{};
    var dispatcher = Dispatcher{};
    dispatcher.once(.MESSAGE_CREATE, rawHandler(&state, State.onMessage));
    dispatcher.onMessageCreate(rawHandler(&state, State.onMessage));

    var first = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"MESSAGE_CREATE\",\"d\":{}}",
    );
    defer first.deinit();
    try std.testing.expect(try dispatcher.dispatch(first));

    var second = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"MESSAGE_CREATE\",\"d\":{}}",
    );
    defer second.deinit();
    try std.testing.expect(try dispatcher.dispatch(second));
    try std.testing.expectEqual(@as(usize, 2), state.messages);
}

test "dispatcher clears one-shot raw interaction after filtered handlers run" {
    const State = struct {
        raw: usize = 0,
        component: usize = 0,

        pub fn onRaw(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTERACTION_CREATE, dispatch.event);
            self.raw += 1;
        }

        pub fn onComponent(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTERACTION_CREATE, dispatch.event);
            self.component += 1;
        }
    };

    var state = State{};
    var dispatcher = Dispatcher{};
    dispatcher.once(.INTERACTION_CREATE, rawHandler(&state, State.onRaw));
    dispatcher.onMessageComponent(rawHandler(&state, State.onComponent));

    var first = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"1\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"data\":{\"custom_id\":\"ok\",\"component_type\":2}}}",
    );
    defer first.deinit();
    try std.testing.expect(try dispatcher.dispatch(first));

    var second = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"2\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"data\":{\"custom_id\":\"again\",\"component_type\":2}}}",
    );
    defer second.deinit();
    try std.testing.expect(try dispatcher.dispatch(second));

    try std.testing.expectEqual(@as(usize, 1), state.raw);
    try std.testing.expectEqual(@as(usize, 2), state.component);
}

test "dispatcher routes auto moderation events" {
    const State = struct {
        rule_created: bool = false,
        rule_updated: bool = false,
        rule_deleted: bool = false,
        action_executed: bool = false,

        pub fn onAutoModerationRuleCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.AUTO_MODERATION_RULE_CREATE, dispatch.event);
            self.rule_created = true;
        }

        pub fn onAutoModerationRuleUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.AUTO_MODERATION_RULE_UPDATE, dispatch.event);
            self.rule_updated = true;
        }

        pub fn onAutoModerationRuleDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.AUTO_MODERATION_RULE_DELETE, dispatch.event);
            self.rule_deleted = true;
        }

        pub fn onAutoModerationActionExecution(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.AUTO_MODERATION_ACTION_EXECUTION, dispatch.event);
            self.action_executed = true;
        }
    };

    var state = State{};
    var dispatcher = Dispatcher{};
    dispatcher.onAutoModerationRuleCreate(rawHandler(&state, State.onAutoModerationRuleCreate));
    dispatcher.onAutoModerationRuleUpdate(rawHandler(&state, State.onAutoModerationRuleUpdate));
    dispatcher.onAutoModerationRuleDelete(rawHandler(&state, State.onAutoModerationRuleDelete));
    dispatcher.onAutoModerationActionExecution(rawHandler(&state, State.onAutoModerationActionExecution));

    var rule_create = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":1,\"t\":\"AUTO_MODERATION_RULE_CREATE\",\"d\":{}}");
    defer rule_create.deinit();
    try std.testing.expect(try dispatcher.dispatch(rule_create));

    var rule_update = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":2,\"t\":\"AUTO_MODERATION_RULE_UPDATE\",\"d\":{}}");
    defer rule_update.deinit();
    try std.testing.expect(try dispatcher.dispatch(rule_update));

    var rule_delete = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":3,\"t\":\"AUTO_MODERATION_RULE_DELETE\",\"d\":{}}");
    defer rule_delete.deinit();
    try std.testing.expect(try dispatcher.dispatch(rule_delete));

    var action_execution = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":4,\"t\":\"AUTO_MODERATION_ACTION_EXECUTION\",\"d\":{}}");
    defer action_execution.deinit();
    try std.testing.expect(try dispatcher.dispatch(action_execution));

    try std.testing.expect(state.rule_created);
    try std.testing.expect(state.rule_updated);
    try std.testing.expect(state.rule_deleted);
    try std.testing.expect(state.action_executed);
}

test "dispatcher routes entitlement events" {
    const State = struct {
        created: bool = false,
        updated: bool = false,
        deleted: bool = false,

        pub fn onEntitlementCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.ENTITLEMENT_CREATE, dispatch.event);
            self.created = true;
        }

        pub fn onEntitlementUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.ENTITLEMENT_UPDATE, dispatch.event);
            self.updated = true;
        }

        pub fn onEntitlementDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.ENTITLEMENT_DELETE, dispatch.event);
            self.deleted = true;
        }
    };

    var state = State{};
    var dispatcher = Dispatcher{};
    dispatcher.onEntitlementCreate(rawHandler(&state, State.onEntitlementCreate));
    dispatcher.onEntitlementUpdate(rawHandler(&state, State.onEntitlementUpdate));
    dispatcher.onEntitlementDelete(rawHandler(&state, State.onEntitlementDelete));

    var create = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":1,\"t\":\"ENTITLEMENT_CREATE\",\"d\":{}}");
    defer create.deinit();
    try std.testing.expect(try dispatcher.dispatch(create));

    var update = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":2,\"t\":\"ENTITLEMENT_UPDATE\",\"d\":{}}");
    defer update.deinit();
    try std.testing.expect(try dispatcher.dispatch(update));

    var delete = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":3,\"t\":\"ENTITLEMENT_DELETE\",\"d\":{}}");
    defer delete.deinit();
    try std.testing.expect(try dispatcher.dispatch(delete));

    try std.testing.expect(state.created);
    try std.testing.expect(state.updated);
    try std.testing.expect(state.deleted);
}

test "dispatcher routes soundboard events" {
    const State = struct {
        sound_created: bool = false,
        sound_updated: bool = false,
        sound_deleted: bool = false,
        sounds_updated: bool = false,
        sounds_response: bool = false,
        voice_effect: bool = false,

        pub fn onGuildSoundboardSoundCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_SOUNDBOARD_SOUND_CREATE, dispatch.event);
            self.sound_created = true;
        }

        pub fn onGuildSoundboardSoundUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_SOUNDBOARD_SOUND_UPDATE, dispatch.event);
            self.sound_updated = true;
        }

        pub fn onGuildSoundboardSoundDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_SOUNDBOARD_SOUND_DELETE, dispatch.event);
            self.sound_deleted = true;
        }

        pub fn onGuildSoundboardSoundsUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_SOUNDBOARD_SOUNDS_UPDATE, dispatch.event);
            self.sounds_updated = true;
        }

        pub fn onSoundboardSounds(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.SOUNDBOARD_SOUNDS, dispatch.event);
            self.sounds_response = true;
        }

        pub fn onVoiceChannelEffectSend(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.VOICE_CHANNEL_EFFECT_SEND, dispatch.event);
            self.voice_effect = true;
        }
    };

    var state = State{};
    var dispatcher = Dispatcher{};
    dispatcher.onGuildSoundboardSoundCreate(rawHandler(&state, State.onGuildSoundboardSoundCreate));
    dispatcher.onGuildSoundboardSoundUpdate(rawHandler(&state, State.onGuildSoundboardSoundUpdate));
    dispatcher.onGuildSoundboardSoundDelete(rawHandler(&state, State.onGuildSoundboardSoundDelete));
    dispatcher.onGuildSoundboardSoundsUpdate(rawHandler(&state, State.onGuildSoundboardSoundsUpdate));
    dispatcher.onSoundboardSounds(rawHandler(&state, State.onSoundboardSounds));
    dispatcher.onVoiceChannelEffectSend(rawHandler(&state, State.onVoiceChannelEffectSend));

    var sound_create = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":1,\"t\":\"GUILD_SOUNDBOARD_SOUND_CREATE\",\"d\":{}}");
    defer sound_create.deinit();
    try std.testing.expect(try dispatcher.dispatch(sound_create));

    var sound_update = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":2,\"t\":\"GUILD_SOUNDBOARD_SOUND_UPDATE\",\"d\":{}}");
    defer sound_update.deinit();
    try std.testing.expect(try dispatcher.dispatch(sound_update));

    var sound_delete = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":3,\"t\":\"GUILD_SOUNDBOARD_SOUND_DELETE\",\"d\":{}}");
    defer sound_delete.deinit();
    try std.testing.expect(try dispatcher.dispatch(sound_delete));

    var sounds_update = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":4,\"t\":\"GUILD_SOUNDBOARD_SOUNDS_UPDATE\",\"d\":{}}");
    defer sounds_update.deinit();
    try std.testing.expect(try dispatcher.dispatch(sounds_update));

    var sounds_response = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":5,\"t\":\"SOUNDBOARD_SOUNDS\",\"d\":{}}");
    defer sounds_response.deinit();
    try std.testing.expect(try dispatcher.dispatch(sounds_response));

    var voice_effect = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":6,\"t\":\"VOICE_CHANNEL_EFFECT_SEND\",\"d\":{}}");
    defer voice_effect.deinit();
    try std.testing.expect(try dispatcher.dispatch(voice_effect));

    try std.testing.expect(state.sound_created);
    try std.testing.expect(state.sound_updated);
    try std.testing.expect(state.sound_deleted);
    try std.testing.expect(state.sounds_updated);
    try std.testing.expect(state.sounds_response);
    try std.testing.expect(state.voice_effect);
}

test "dispatcher routes runtime guild voice and channel events" {
    const State = struct {
        permissions_updated: bool = false,
        audit_log_entry_created: bool = false,
        members_chunked: bool = false,
        voice_server_updated: bool = false,
        channel_info: bool = false,
        voice_status_updated: bool = false,
        voice_start_time_updated: bool = false,

        pub fn onApplicationCommandPermissionsUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.APPLICATION_COMMAND_PERMISSIONS_UPDATE, dispatch.event);
            self.permissions_updated = true;
        }

        pub fn onGuildAuditLogEntryCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_AUDIT_LOG_ENTRY_CREATE, dispatch.event);
            self.audit_log_entry_created = true;
        }

        pub fn onGuildMembersChunk(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_MEMBERS_CHUNK, dispatch.event);
            self.members_chunked = true;
        }

        pub fn onVoiceServerUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.VOICE_SERVER_UPDATE, dispatch.event);
            self.voice_server_updated = true;
        }

        pub fn onChannelInfo(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.CHANNEL_INFO, dispatch.event);
            self.channel_info = true;
        }

        pub fn onVoiceChannelStatusUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.VOICE_CHANNEL_STATUS_UPDATE, dispatch.event);
            self.voice_status_updated = true;
        }

        pub fn onVoiceChannelStartTimeUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.VOICE_CHANNEL_START_TIME_UPDATE, dispatch.event);
            self.voice_start_time_updated = true;
        }
    };

    var state = State{};
    var dispatcher = Dispatcher{};
    dispatcher.onApplicationCommandPermissionsUpdate(rawHandler(&state, State.onApplicationCommandPermissionsUpdate));
    dispatcher.onGuildAuditLogEntryCreate(rawHandler(&state, State.onGuildAuditLogEntryCreate));
    dispatcher.onGuildMembersChunk(rawHandler(&state, State.onGuildMembersChunk));
    dispatcher.onVoiceServerUpdate(rawHandler(&state, State.onVoiceServerUpdate));
    dispatcher.onChannelInfo(rawHandler(&state, State.onChannelInfo));
    dispatcher.onVoiceChannelStatusUpdate(rawHandler(&state, State.onVoiceChannelStatusUpdate));
    dispatcher.onVoiceChannelStartTimeUpdate(rawHandler(&state, State.onVoiceChannelStartTimeUpdate));

    var permissions = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":1,\"t\":\"APPLICATION_COMMAND_PERMISSIONS_UPDATE\",\"d\":{}}");
    defer permissions.deinit();
    try std.testing.expect(try dispatcher.dispatch(permissions));

    var audit_entry = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":2,\"t\":\"GUILD_AUDIT_LOG_ENTRY_CREATE\",\"d\":{}}");
    defer audit_entry.deinit();
    try std.testing.expect(try dispatcher.dispatch(audit_entry));

    var members_chunk = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":3,\"t\":\"GUILD_MEMBERS_CHUNK\",\"d\":{}}");
    defer members_chunk.deinit();
    try std.testing.expect(try dispatcher.dispatch(members_chunk));

    var voice_server = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":4,\"t\":\"VOICE_SERVER_UPDATE\",\"d\":{}}");
    defer voice_server.deinit();
    try std.testing.expect(try dispatcher.dispatch(voice_server));

    var channel_info = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":5,\"t\":\"CHANNEL_INFO\",\"d\":{}}");
    defer channel_info.deinit();
    try std.testing.expect(try dispatcher.dispatch(channel_info));

    var voice_status = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":6,\"t\":\"VOICE_CHANNEL_STATUS_UPDATE\",\"d\":{}}");
    defer voice_status.deinit();
    try std.testing.expect(try dispatcher.dispatch(voice_status));

    var voice_start_time = try Gateway.parseDispatch(std.testing.allocator, "{\"op\":0,\"s\":7,\"t\":\"VOICE_CHANNEL_START_TIME_UPDATE\",\"d\":{}}");
    defer voice_start_time.deinit();
    try std.testing.expect(try dispatcher.dispatch(voice_start_time));

    try std.testing.expect(state.permissions_updated);
    try std.testing.expect(state.audit_log_entry_created);
    try std.testing.expect(state.members_chunked);
    try std.testing.expect(state.voice_server_updated);
    try std.testing.expect(state.channel_info);
    try std.testing.expect(state.voice_status_updated);
    try std.testing.expect(state.voice_start_time_updated);
}
