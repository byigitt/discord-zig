const std = @import("std");
const Gateway = @import("protocol.zig");
const Interactions = @import("../interactions/mod.zig");

pub const RawHandler = struct {
    ptr: *anyopaque,
    callFn: *const fn (ptr: *anyopaque, dispatch: Gateway.ParsedDispatch) anyerror!void,

    pub fn call(self: RawHandler, dispatch: Gateway.ParsedDispatch) !void {
        try self.callFn(self.ptr, dispatch);
    }
};

pub const Dispatcher = struct {
    ready: ?RawHandler = null,
    resumed: ?RawHandler = null,
    message_create: ?RawHandler = null,
    message_update: ?RawHandler = null,
    message_delete: ?RawHandler = null,
    message_delete_bulk: ?RawHandler = null,
    message_reaction_add: ?RawHandler = null,
    message_reaction_remove: ?RawHandler = null,
    message_reaction_remove_all: ?RawHandler = null,
    message_reaction_remove_emoji: ?RawHandler = null,
    message_poll_vote_add: ?RawHandler = null,
    message_poll_vote_remove: ?RawHandler = null,
    user_update: ?RawHandler = null,
    presence_update: ?RawHandler = null,
    voice_state_update: ?RawHandler = null,
    interaction_create: ?RawHandler = null,
    application_command_permissions_update: ?RawHandler = null,
    application_command: ?RawHandler = null,
    message_component: ?RawHandler = null,
    application_command_autocomplete: ?RawHandler = null,
    modal_submit: ?RawHandler = null,
    once_application_command: bool = false,
    once_message_component: bool = false,
    once_application_command_autocomplete: bool = false,
    once_modal_submit: bool = false,
    auto_moderation_rule_create: ?RawHandler = null,
    auto_moderation_rule_update: ?RawHandler = null,
    auto_moderation_rule_delete: ?RawHandler = null,
    auto_moderation_action_execution: ?RawHandler = null,
    entitlement_create: ?RawHandler = null,
    entitlement_update: ?RawHandler = null,
    entitlement_delete: ?RawHandler = null,
    subscription_create: ?RawHandler = null,
    subscription_update: ?RawHandler = null,
    subscription_delete: ?RawHandler = null,
    guild_create: ?RawHandler = null,
    guild_update: ?RawHandler = null,
    guild_delete: ?RawHandler = null,
    guild_audit_log_entry_create: ?RawHandler = null,
    guild_ban_add: ?RawHandler = null,
    guild_ban_remove: ?RawHandler = null,
    guild_integrations_update: ?RawHandler = null,
    integration_create: ?RawHandler = null,
    integration_update: ?RawHandler = null,
    integration_delete: ?RawHandler = null,
    guild_member_add: ?RawHandler = null,
    guild_member_update: ?RawHandler = null,
    guild_member_remove: ?RawHandler = null,
    guild_members_chunk: ?RawHandler = null,
    guild_role_create: ?RawHandler = null,
    guild_role_update: ?RawHandler = null,
    guild_role_delete: ?RawHandler = null,
    guild_emojis_update: ?RawHandler = null,
    guild_stickers_update: ?RawHandler = null,
    guild_scheduled_event_create: ?RawHandler = null,
    guild_scheduled_event_update: ?RawHandler = null,
    guild_scheduled_event_delete: ?RawHandler = null,
    guild_scheduled_event_user_add: ?RawHandler = null,
    guild_scheduled_event_user_remove: ?RawHandler = null,
    guild_soundboard_sound_create: ?RawHandler = null,
    guild_soundboard_sound_update: ?RawHandler = null,
    guild_soundboard_sound_delete: ?RawHandler = null,
    guild_soundboard_sounds_update: ?RawHandler = null,
    soundboard_sounds: ?RawHandler = null,
    stage_instance_create: ?RawHandler = null,
    stage_instance_update: ?RawHandler = null,
    stage_instance_delete: ?RawHandler = null,
    voice_channel_effect_send: ?RawHandler = null,
    voice_server_update: ?RawHandler = null,
    channel_create: ?RawHandler = null,
    channel_update: ?RawHandler = null,
    channel_delete: ?RawHandler = null,
    channel_info: ?RawHandler = null,
    voice_channel_status_update: ?RawHandler = null,
    voice_channel_start_time_update: ?RawHandler = null,
    channel_pins_update: ?RawHandler = null,
    typing_start: ?RawHandler = null,
    webhooks_update: ?RawHandler = null,
    invite_create: ?RawHandler = null,
    invite_delete: ?RawHandler = null,
    thread_create: ?RawHandler = null,
    thread_update: ?RawHandler = null,
    thread_delete: ?RawHandler = null,
    thread_list_sync: ?RawHandler = null,
    thread_member_update: ?RawHandler = null,
    thread_members_update: ?RawHandler = null,
    rate_limited: ?RawHandler = null,
    unknown: ?RawHandler = null,
    once_events: std.EnumSet(Gateway.EventName) = .initEmpty(),

    pub fn on(self: *Dispatcher, event: Gateway.EventName, handler: RawHandler) void {
        self.handlerSlot(event).* = handler;
        self.once_events.remove(event);
    }

    pub fn once(self: *Dispatcher, event: Gateway.EventName, handler: RawHandler) void {
        self.handlerSlot(event).* = handler;
        self.once_events.insert(event);
    }

    pub fn clear(self: *Dispatcher, event: Gateway.EventName) void {
        self.handlerSlot(event).* = null;
        self.once_events.remove(event);
    }

    pub fn hasListener(self: *Dispatcher, event: Gateway.EventName) bool {
        return self.handlerSlot(event).* != null;
    }

    pub fn listenerCount(self: *Dispatcher, event: Gateway.EventName) usize {
        return if (self.hasListener(event)) 1 else 0;
    }

    pub fn eventNames(self: *Dispatcher, allocator: std.mem.Allocator) ![]Gateway.EventName {
        var names = std.array_list.Managed(Gateway.EventName).init(allocator);
        errdefer names.deinit();

        inline for (@typeInfo(Gateway.EventName).@"enum".fields) |field| {
            const event = @field(Gateway.EventName, field.name);
            if (self.hasListener(event)) try names.append(event);
        }

        return names.toOwnedSlice();
    }

    pub fn clearAll(self: *Dispatcher) void {
        self.* = .{};
    }

    pub fn onReady(self: *Dispatcher, handler: RawHandler) void {
        self.on(.READY, handler);
    }

    pub fn onResumed(self: *Dispatcher, handler: RawHandler) void {
        self.on(.RESUMED, handler);
    }

    pub fn onMessageCreate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.MESSAGE_CREATE, handler);
    }

    pub fn onMessageUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.MESSAGE_UPDATE, handler);
    }

    pub fn onMessageDelete(self: *Dispatcher, handler: RawHandler) void {
        self.on(.MESSAGE_DELETE, handler);
    }

    pub fn onMessageDeleteBulk(self: *Dispatcher, handler: RawHandler) void {
        self.on(.MESSAGE_DELETE_BULK, handler);
    }

    pub fn onMessageReactionAdd(self: *Dispatcher, handler: RawHandler) void {
        self.on(.MESSAGE_REACTION_ADD, handler);
    }

    pub fn onMessageReactionRemove(self: *Dispatcher, handler: RawHandler) void {
        self.on(.MESSAGE_REACTION_REMOVE, handler);
    }

    pub fn onMessageReactionRemoveAll(self: *Dispatcher, handler: RawHandler) void {
        self.on(.MESSAGE_REACTION_REMOVE_ALL, handler);
    }

    pub fn onMessageReactionRemoveEmoji(self: *Dispatcher, handler: RawHandler) void {
        self.on(.MESSAGE_REACTION_REMOVE_EMOJI, handler);
    }

    pub fn onMessagePollVoteAdd(self: *Dispatcher, handler: RawHandler) void {
        self.on(.MESSAGE_POLL_VOTE_ADD, handler);
    }

    pub fn onMessagePollVoteRemove(self: *Dispatcher, handler: RawHandler) void {
        self.on(.MESSAGE_POLL_VOTE_REMOVE, handler);
    }

    pub fn onUserUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.USER_UPDATE, handler);
    }

    pub fn onPresenceUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.PRESENCE_UPDATE, handler);
    }

    pub fn onVoiceStateUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.VOICE_STATE_UPDATE, handler);
    }

    pub fn onInteractionCreate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.INTERACTION_CREATE, handler);
    }

    pub fn onApplicationCommandPermissionsUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.APPLICATION_COMMAND_PERMISSIONS_UPDATE, handler);
    }

    pub fn onApplicationCommand(self: *Dispatcher, handler: RawHandler) void {
        self.application_command = handler;
        self.once_application_command = false;
    }

    pub fn onceApplicationCommand(self: *Dispatcher, handler: RawHandler) void {
        self.application_command = handler;
        self.once_application_command = true;
    }

    pub fn onMessageComponent(self: *Dispatcher, handler: RawHandler) void {
        self.message_component = handler;
        self.once_message_component = false;
    }

    pub fn onceMessageComponent(self: *Dispatcher, handler: RawHandler) void {
        self.message_component = handler;
        self.once_message_component = true;
    }

    pub fn onApplicationCommandAutocomplete(self: *Dispatcher, handler: RawHandler) void {
        self.application_command_autocomplete = handler;
        self.once_application_command_autocomplete = false;
    }

    pub fn onceApplicationCommandAutocomplete(self: *Dispatcher, handler: RawHandler) void {
        self.application_command_autocomplete = handler;
        self.once_application_command_autocomplete = true;
    }

    pub fn onModalSubmit(self: *Dispatcher, handler: RawHandler) void {
        self.modal_submit = handler;
        self.once_modal_submit = false;
    }

    pub fn onceModalSubmit(self: *Dispatcher, handler: RawHandler) void {
        self.modal_submit = handler;
        self.once_modal_submit = true;
    }

    pub fn onAutoModerationRuleCreate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.AUTO_MODERATION_RULE_CREATE, handler);
    }

    pub fn onAutoModerationRuleUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.AUTO_MODERATION_RULE_UPDATE, handler);
    }

    pub fn onAutoModerationRuleDelete(self: *Dispatcher, handler: RawHandler) void {
        self.on(.AUTO_MODERATION_RULE_DELETE, handler);
    }

    pub fn onAutoModerationActionExecution(self: *Dispatcher, handler: RawHandler) void {
        self.on(.AUTO_MODERATION_ACTION_EXECUTION, handler);
    }

    pub fn onEntitlementCreate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.ENTITLEMENT_CREATE, handler);
    }

    pub fn onEntitlementUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.ENTITLEMENT_UPDATE, handler);
    }

    pub fn onEntitlementDelete(self: *Dispatcher, handler: RawHandler) void {
        self.on(.ENTITLEMENT_DELETE, handler);
    }

    pub fn onSubscriptionCreate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.SUBSCRIPTION_CREATE, handler);
    }

    pub fn onSubscriptionUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.SUBSCRIPTION_UPDATE, handler);
    }

    pub fn onSubscriptionDelete(self: *Dispatcher, handler: RawHandler) void {
        self.on(.SUBSCRIPTION_DELETE, handler);
    }

    pub fn onGuildCreate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_CREATE, handler);
    }

    pub fn onGuildUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_UPDATE, handler);
    }

    pub fn onGuildDelete(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_DELETE, handler);
    }

    pub fn onGuildAuditLogEntryCreate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_AUDIT_LOG_ENTRY_CREATE, handler);
    }

    pub fn onGuildBanAdd(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_BAN_ADD, handler);
    }

    pub fn onGuildBanRemove(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_BAN_REMOVE, handler);
    }

    pub fn onGuildIntegrationsUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_INTEGRATIONS_UPDATE, handler);
    }

    pub fn onIntegrationCreate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.INTEGRATION_CREATE, handler);
    }

    pub fn onIntegrationUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.INTEGRATION_UPDATE, handler);
    }

    pub fn onIntegrationDelete(self: *Dispatcher, handler: RawHandler) void {
        self.on(.INTEGRATION_DELETE, handler);
    }

    pub fn onGuildMemberAdd(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_MEMBER_ADD, handler);
    }

    pub fn onGuildMemberUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_MEMBER_UPDATE, handler);
    }

    pub fn onGuildMemberRemove(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_MEMBER_REMOVE, handler);
    }

    pub fn onGuildMembersChunk(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_MEMBERS_CHUNK, handler);
    }

    pub fn onGuildRoleCreate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_ROLE_CREATE, handler);
    }

    pub fn onGuildRoleUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_ROLE_UPDATE, handler);
    }

    pub fn onGuildRoleDelete(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_ROLE_DELETE, handler);
    }

    pub fn onGuildEmojisUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_EMOJIS_UPDATE, handler);
    }

    pub fn onGuildStickersUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_STICKERS_UPDATE, handler);
    }

    pub fn onGuildScheduledEventCreate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_SCHEDULED_EVENT_CREATE, handler);
    }

    pub fn onGuildScheduledEventUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_SCHEDULED_EVENT_UPDATE, handler);
    }

    pub fn onGuildScheduledEventDelete(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_SCHEDULED_EVENT_DELETE, handler);
    }

    pub fn onGuildScheduledEventUserAdd(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_SCHEDULED_EVENT_USER_ADD, handler);
    }

    pub fn onGuildScheduledEventUserRemove(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_SCHEDULED_EVENT_USER_REMOVE, handler);
    }

    pub fn onGuildSoundboardSoundCreate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_SOUNDBOARD_SOUND_CREATE, handler);
    }

    pub fn onGuildSoundboardSoundUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_SOUNDBOARD_SOUND_UPDATE, handler);
    }

    pub fn onGuildSoundboardSoundDelete(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_SOUNDBOARD_SOUND_DELETE, handler);
    }

    pub fn onGuildSoundboardSoundsUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.GUILD_SOUNDBOARD_SOUNDS_UPDATE, handler);
    }

    pub fn onSoundboardSounds(self: *Dispatcher, handler: RawHandler) void {
        self.on(.SOUNDBOARD_SOUNDS, handler);
    }

    pub fn onStageInstanceCreate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.STAGE_INSTANCE_CREATE, handler);
    }

    pub fn onStageInstanceUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.STAGE_INSTANCE_UPDATE, handler);
    }

    pub fn onStageInstanceDelete(self: *Dispatcher, handler: RawHandler) void {
        self.on(.STAGE_INSTANCE_DELETE, handler);
    }

    pub fn onVoiceChannelEffectSend(self: *Dispatcher, handler: RawHandler) void {
        self.on(.VOICE_CHANNEL_EFFECT_SEND, handler);
    }

    pub fn onVoiceServerUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.VOICE_SERVER_UPDATE, handler);
    }

    pub fn onChannelCreate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.CHANNEL_CREATE, handler);
    }

    pub fn onChannelUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.CHANNEL_UPDATE, handler);
    }

    pub fn onChannelDelete(self: *Dispatcher, handler: RawHandler) void {
        self.on(.CHANNEL_DELETE, handler);
    }

    pub fn onChannelInfo(self: *Dispatcher, handler: RawHandler) void {
        self.on(.CHANNEL_INFO, handler);
    }

    pub fn onVoiceChannelStatusUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.VOICE_CHANNEL_STATUS_UPDATE, handler);
    }

    pub fn onVoiceChannelStartTimeUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.VOICE_CHANNEL_START_TIME_UPDATE, handler);
    }

    pub fn onChannelPinsUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.CHANNEL_PINS_UPDATE, handler);
    }

    pub fn onTypingStart(self: *Dispatcher, handler: RawHandler) void {
        self.on(.TYPING_START, handler);
    }

    pub fn onWebhooksUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.WEBHOOKS_UPDATE, handler);
    }

    pub fn onInviteCreate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.INVITE_CREATE, handler);
    }

    pub fn onInviteDelete(self: *Dispatcher, handler: RawHandler) void {
        self.on(.INVITE_DELETE, handler);
    }

    pub fn onThreadCreate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.THREAD_CREATE, handler);
    }

    pub fn onThreadUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.THREAD_UPDATE, handler);
    }

    pub fn onThreadDelete(self: *Dispatcher, handler: RawHandler) void {
        self.on(.THREAD_DELETE, handler);
    }

    pub fn onThreadListSync(self: *Dispatcher, handler: RawHandler) void {
        self.on(.THREAD_LIST_SYNC, handler);
    }

    pub fn onThreadMemberUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.THREAD_MEMBER_UPDATE, handler);
    }

    pub fn onThreadMembersUpdate(self: *Dispatcher, handler: RawHandler) void {
        self.on(.THREAD_MEMBERS_UPDATE, handler);
    }

    pub fn onRateLimited(self: *Dispatcher, handler: RawHandler) void {
        self.on(.RATE_LIMITED, handler);
    }

    pub fn onUnknown(self: *Dispatcher, handler: RawHandler) void {
        self.on(.unknown, handler);
    }

    pub fn dispatch(self: *Dispatcher, event: Gateway.ParsedDispatch) !bool {
        if (event.event == .INTERACTION_CREATE) return try self.dispatchInteraction(event);

        const slot = self.handlerSlot(event.event);
        if (slot.*) |registered| {
            try registered.call(event);
            self.completeDispatch(event.event);
            return true;
        }

        return false;
    }

    fn dispatchInteraction(self: *Dispatcher, event: Gateway.ParsedDispatch) !bool {
        var handled = false;
        if (self.interaction_create) |handler| {
            try handler.call(event);
            self.completeDispatch(.INTERACTION_CREATE);
            handled = true;
        }

        if (interactionType(event)) |interaction_type| {
            const filtered = switch (interaction_type) {
                .application_command => self.application_command,
                .message_component => self.message_component,
                .application_command_autocomplete => self.application_command_autocomplete,
                .modal_submit => self.modal_submit,
                else => null,
            };
            if (filtered) |handler| {
                try handler.call(event);
                self.completeFilteredInteraction(interaction_type);
                handled = true;
            }
        } else |_| {}

        return handled;
    }

    fn completeDispatch(self: *Dispatcher, event: Gateway.EventName) void {
        if (self.once_events.contains(event)) {
            self.clear(event);
        }
    }

    fn completeFilteredInteraction(self: *Dispatcher, interaction_type: Interactions.InteractionType) void {
        switch (interaction_type) {
            .application_command => if (self.once_application_command) {
                self.application_command = null;
                self.once_application_command = false;
            },
            .message_component => if (self.once_message_component) {
                self.message_component = null;
                self.once_message_component = false;
            },
            .application_command_autocomplete => if (self.once_application_command_autocomplete) {
                self.application_command_autocomplete = null;
                self.once_application_command_autocomplete = false;
            },
            .modal_submit => if (self.once_modal_submit) {
                self.modal_submit = null;
                self.once_modal_submit = false;
            },
            else => {},
        }
    }

    fn handlerSlot(self: *Dispatcher, event: Gateway.EventName) *?RawHandler {
        return switch (event) {
            .READY => &self.ready,
            .RESUMED => &self.resumed,
            .MESSAGE_CREATE => &self.message_create,
            .MESSAGE_UPDATE => &self.message_update,
            .MESSAGE_DELETE => &self.message_delete,
            .MESSAGE_DELETE_BULK => &self.message_delete_bulk,
            .MESSAGE_REACTION_ADD => &self.message_reaction_add,
            .MESSAGE_REACTION_REMOVE => &self.message_reaction_remove,
            .MESSAGE_REACTION_REMOVE_ALL => &self.message_reaction_remove_all,
            .MESSAGE_REACTION_REMOVE_EMOJI => &self.message_reaction_remove_emoji,
            .MESSAGE_POLL_VOTE_ADD => &self.message_poll_vote_add,
            .MESSAGE_POLL_VOTE_REMOVE => &self.message_poll_vote_remove,
            .USER_UPDATE => &self.user_update,
            .PRESENCE_UPDATE => &self.presence_update,
            .VOICE_STATE_UPDATE => &self.voice_state_update,
            .INTERACTION_CREATE => &self.interaction_create,
            .APPLICATION_COMMAND_PERMISSIONS_UPDATE => &self.application_command_permissions_update,
            .AUTO_MODERATION_RULE_CREATE => &self.auto_moderation_rule_create,
            .AUTO_MODERATION_RULE_UPDATE => &self.auto_moderation_rule_update,
            .AUTO_MODERATION_RULE_DELETE => &self.auto_moderation_rule_delete,
            .AUTO_MODERATION_ACTION_EXECUTION => &self.auto_moderation_action_execution,
            .ENTITLEMENT_CREATE => &self.entitlement_create,
            .ENTITLEMENT_UPDATE => &self.entitlement_update,
            .ENTITLEMENT_DELETE => &self.entitlement_delete,
            .SUBSCRIPTION_CREATE => &self.subscription_create,
            .SUBSCRIPTION_UPDATE => &self.subscription_update,
            .SUBSCRIPTION_DELETE => &self.subscription_delete,
            .GUILD_CREATE => &self.guild_create,
            .GUILD_UPDATE => &self.guild_update,
            .GUILD_DELETE => &self.guild_delete,
            .GUILD_AUDIT_LOG_ENTRY_CREATE => &self.guild_audit_log_entry_create,
            .GUILD_BAN_ADD => &self.guild_ban_add,
            .GUILD_BAN_REMOVE => &self.guild_ban_remove,
            .GUILD_INTEGRATIONS_UPDATE => &self.guild_integrations_update,
            .INTEGRATION_CREATE => &self.integration_create,
            .INTEGRATION_UPDATE => &self.integration_update,
            .INTEGRATION_DELETE => &self.integration_delete,
            .GUILD_MEMBER_ADD => &self.guild_member_add,
            .GUILD_MEMBER_UPDATE => &self.guild_member_update,
            .GUILD_MEMBER_REMOVE => &self.guild_member_remove,
            .GUILD_MEMBERS_CHUNK => &self.guild_members_chunk,
            .GUILD_ROLE_CREATE => &self.guild_role_create,
            .GUILD_ROLE_UPDATE => &self.guild_role_update,
            .GUILD_ROLE_DELETE => &self.guild_role_delete,
            .GUILD_EMOJIS_UPDATE => &self.guild_emojis_update,
            .GUILD_STICKERS_UPDATE => &self.guild_stickers_update,
            .GUILD_SCHEDULED_EVENT_CREATE => &self.guild_scheduled_event_create,
            .GUILD_SCHEDULED_EVENT_UPDATE => &self.guild_scheduled_event_update,
            .GUILD_SCHEDULED_EVENT_DELETE => &self.guild_scheduled_event_delete,
            .GUILD_SCHEDULED_EVENT_USER_ADD => &self.guild_scheduled_event_user_add,
            .GUILD_SCHEDULED_EVENT_USER_REMOVE => &self.guild_scheduled_event_user_remove,
            .GUILD_SOUNDBOARD_SOUND_CREATE => &self.guild_soundboard_sound_create,
            .GUILD_SOUNDBOARD_SOUND_UPDATE => &self.guild_soundboard_sound_update,
            .GUILD_SOUNDBOARD_SOUND_DELETE => &self.guild_soundboard_sound_delete,
            .GUILD_SOUNDBOARD_SOUNDS_UPDATE => &self.guild_soundboard_sounds_update,
            .SOUNDBOARD_SOUNDS => &self.soundboard_sounds,
            .STAGE_INSTANCE_CREATE => &self.stage_instance_create,
            .STAGE_INSTANCE_UPDATE => &self.stage_instance_update,
            .STAGE_INSTANCE_DELETE => &self.stage_instance_delete,
            .VOICE_CHANNEL_EFFECT_SEND => &self.voice_channel_effect_send,
            .VOICE_SERVER_UPDATE => &self.voice_server_update,
            .CHANNEL_CREATE => &self.channel_create,
            .CHANNEL_UPDATE => &self.channel_update,
            .CHANNEL_DELETE => &self.channel_delete,
            .CHANNEL_INFO => &self.channel_info,
            .VOICE_CHANNEL_STATUS_UPDATE => &self.voice_channel_status_update,
            .VOICE_CHANNEL_START_TIME_UPDATE => &self.voice_channel_start_time_update,
            .CHANNEL_PINS_UPDATE => &self.channel_pins_update,
            .TYPING_START => &self.typing_start,
            .WEBHOOKS_UPDATE => &self.webhooks_update,
            .INVITE_CREATE => &self.invite_create,
            .INVITE_DELETE => &self.invite_delete,
            .THREAD_CREATE => &self.thread_create,
            .THREAD_UPDATE => &self.thread_update,
            .THREAD_DELETE => &self.thread_delete,
            .THREAD_LIST_SYNC => &self.thread_list_sync,
            .THREAD_MEMBER_UPDATE => &self.thread_member_update,
            .THREAD_MEMBERS_UPDATE => &self.thread_members_update,
            .RATE_LIMITED => &self.rate_limited,
            .unknown => &self.unknown,
        };
    }
};

fn interactionType(event: Gateway.ParsedDispatch) !Interactions.InteractionType {
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
        fn call(raw: *anyopaque, dispatch: Gateway.ParsedDispatch) anyerror!void {
            const typed: Ptr = @ptrCast(@alignCast(raw));
            try function(typed, dispatch);
        }
    };

    return .{ .ptr = ptr, .callFn = wrapper.call };
}

test "dispatcher calls typed message handler" {
    const State = struct {
        called: bool = false,

        fn onMessage(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
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

        fn onMessage(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
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

        fn onMessage(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
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

        fn onRaw(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTERACTION_CREATE, dispatch.event);
            self.raw += 1;
        }

        fn onComponent(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
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

        fn onAutoModerationRuleCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.AUTO_MODERATION_RULE_CREATE, dispatch.event);
            self.rule_created = true;
        }

        fn onAutoModerationRuleUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.AUTO_MODERATION_RULE_UPDATE, dispatch.event);
            self.rule_updated = true;
        }

        fn onAutoModerationRuleDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.AUTO_MODERATION_RULE_DELETE, dispatch.event);
            self.rule_deleted = true;
        }

        fn onAutoModerationActionExecution(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
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

        fn onEntitlementCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.ENTITLEMENT_CREATE, dispatch.event);
            self.created = true;
        }

        fn onEntitlementUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.ENTITLEMENT_UPDATE, dispatch.event);
            self.updated = true;
        }

        fn onEntitlementDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
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

        fn onGuildSoundboardSoundCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_SOUNDBOARD_SOUND_CREATE, dispatch.event);
            self.sound_created = true;
        }

        fn onGuildSoundboardSoundUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_SOUNDBOARD_SOUND_UPDATE, dispatch.event);
            self.sound_updated = true;
        }

        fn onGuildSoundboardSoundDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_SOUNDBOARD_SOUND_DELETE, dispatch.event);
            self.sound_deleted = true;
        }

        fn onGuildSoundboardSoundsUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_SOUNDBOARD_SOUNDS_UPDATE, dispatch.event);
            self.sounds_updated = true;
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

        fn onMessageUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_UPDATE, dispatch.event);
            self.message_update = true;
        }

        fn onMessageDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_DELETE, dispatch.event);
            self.message_delete = true;
        }

        fn onMessageReactionAdd(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_REACTION_ADD, dispatch.event);
            self.message_reaction_add = true;
        }

        fn onMessagePollVoteAdd(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_POLL_VOTE_ADD, dispatch.event);
            self.message_poll_vote_add = true;
        }

        fn onMessagePollVoteRemove(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.MESSAGE_POLL_VOTE_REMOVE, dispatch.event);
            self.message_poll_vote_remove = true;
        }

        fn onUserUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.USER_UPDATE, dispatch.event);
            self.user_update = true;
        }

        fn onPresenceUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.PRESENCE_UPDATE, dispatch.event);
            self.presence_update = true;
        }

        fn onVoiceStateUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.VOICE_STATE_UPDATE, dispatch.event);
            self.voice_state_update = true;
        }

        fn onGuildBanAdd(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_BAN_ADD, dispatch.event);
            self.guild_ban_add = true;
        }

        fn onGuildBanRemove(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_BAN_REMOVE, dispatch.event);
            self.guild_ban_remove = true;
        }

        fn onGuildIntegrationsUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_INTEGRATIONS_UPDATE, dispatch.event);
            self.guild_integrations_update = true;
        }

        fn onIntegrationCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTEGRATION_CREATE, dispatch.event);
            self.integration_create = true;
        }

        fn onIntegrationUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTEGRATION_UPDATE, dispatch.event);
            self.integration_update = true;
        }

        fn onIntegrationDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTEGRATION_DELETE, dispatch.event);
            self.integration_delete = true;
        }

        fn onGuildMemberAdd(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_MEMBER_ADD, dispatch.event);
            self.guild_member_add = true;
        }

        fn onGuildRoleUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_ROLE_UPDATE, dispatch.event);
            self.guild_role_update = true;
        }

        fn onGuildEmojisUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_EMOJIS_UPDATE, dispatch.event);
            self.guild_emojis_update = true;
        }

        fn onGuildStickersUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_STICKERS_UPDATE, dispatch.event);
            self.guild_stickers_update = true;
        }

        fn onGuildScheduledEventCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_SCHEDULED_EVENT_CREATE, dispatch.event);
            self.guild_scheduled_event_create = true;
        }

        fn onGuildScheduledEventUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_SCHEDULED_EVENT_UPDATE, dispatch.event);
            self.guild_scheduled_event_update = true;
        }

        fn onGuildScheduledEventDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_SCHEDULED_EVENT_DELETE, dispatch.event);
            self.guild_scheduled_event_delete = true;
        }

        fn onGuildScheduledEventUserAdd(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_SCHEDULED_EVENT_USER_ADD, dispatch.event);
            self.guild_scheduled_event_user_add = true;
        }

        fn onGuildScheduledEventUserRemove(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.GUILD_SCHEDULED_EVENT_USER_REMOVE, dispatch.event);
            self.guild_scheduled_event_user_remove = true;
        }

        fn onStageInstanceCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.STAGE_INSTANCE_CREATE, dispatch.event);
            self.stage_instance_create = true;
        }

        fn onStageInstanceUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.STAGE_INSTANCE_UPDATE, dispatch.event);
            self.stage_instance_update = true;
        }

        fn onStageInstanceDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.STAGE_INSTANCE_DELETE, dispatch.event);
            self.stage_instance_delete = true;
        }

        fn onChannelDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.CHANNEL_DELETE, dispatch.event);
            self.channel_delete = true;
        }

        fn onChannelPinsUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.CHANNEL_PINS_UPDATE, dispatch.event);
            self.channel_pins_update = true;
        }

        fn onTypingStart(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.TYPING_START, dispatch.event);
            self.typing_start = true;
        }

        fn onWebhooksUpdate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.WEBHOOKS_UPDATE, dispatch.event);
            self.webhooks_update = true;
        }

        fn onInviteCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INVITE_CREATE, dispatch.event);
            self.invite_create = true;
        }

        fn onInviteDelete(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INVITE_DELETE, dispatch.event);
            self.invite_delete = true;
        }

        fn onThreadCreate(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
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

        fn onRaw(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTERACTION_CREATE, dispatch.event);
            self.raw += 1;
        }

        fn onComponent(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
            try std.testing.expectEqual(Gateway.EventName.INTERACTION_CREATE, dispatch.event);
            self.component = true;
        }

        fn onModal(self: *@This(), dispatch: Gateway.ParsedDispatch) !void {
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
