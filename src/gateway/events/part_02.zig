const std = @import("std");
const Gateway = @import("../protocol.zig");
const Interactions = @import("../../interactions/mod.zig");

const Root = @import("../events.zig");
const RawHandler = Root.RawHandler;
const interactionType = Root.interactionType;
const rawHandler = Root.rawHandler;

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

    pub fn dispatchInteraction(self: *Dispatcher, event: Gateway.ParsedDispatch) !bool {
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

    pub fn completeDispatch(self: *Dispatcher, event: Gateway.EventName) void {
        if (self.once_events.contains(event)) {
            self.clear(event);
        }
    }

    pub fn completeFilteredInteraction(self: *Dispatcher, interaction_type: Interactions.InteractionType) void {
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

    pub fn handlerSlot(self: *Dispatcher, event: Gateway.EventName) *?RawHandler {
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
