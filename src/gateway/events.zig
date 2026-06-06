const std = @import("std");
const Gateway = @import("protocol.zig");

const raw_handler = @import("events/raw-handler.zig");
const dispatcher = @import("events/dispatcher.zig");
const message_interaction_handlers = @import("events/message-handlers.zig");

test {
    _ = @import("events/runtime-handlers.zig");
}

pub const ApplicationCommandPermissionsUpdate = Gateway.EventName.APPLICATION_COMMAND_PERMISSIONS_UPDATE;
pub const AutoModerationActionExecution = Gateway.EventName.AUTO_MODERATION_ACTION_EXECUTION;
pub const AutoModerationRuleCreate = Gateway.EventName.AUTO_MODERATION_RULE_CREATE;
pub const AutoModerationRuleDelete = Gateway.EventName.AUTO_MODERATION_RULE_DELETE;
pub const AutoModerationRuleUpdate = Gateway.EventName.AUTO_MODERATION_RULE_UPDATE;
pub const ChannelCreate = Gateway.EventName.CHANNEL_CREATE;
pub const ChannelDelete = Gateway.EventName.CHANNEL_DELETE;
pub const ChannelPinsUpdate = Gateway.EventName.CHANNEL_PINS_UPDATE;
pub const ChannelUpdate = Gateway.EventName.CHANNEL_UPDATE;
pub const ClientReady = Gateway.EventName.READY;
pub const EntitlementCreate = Gateway.EventName.ENTITLEMENT_CREATE;
pub const EntitlementDelete = Gateway.EventName.ENTITLEMENT_DELETE;
pub const EntitlementUpdate = Gateway.EventName.ENTITLEMENT_UPDATE;
pub const GuildAuditLogEntryCreate = Gateway.EventName.GUILD_AUDIT_LOG_ENTRY_CREATE;
pub const GuildBanAdd = Gateway.EventName.GUILD_BAN_ADD;
pub const GuildBanRemove = Gateway.EventName.GUILD_BAN_REMOVE;
pub const GuildCreate = Gateway.EventName.GUILD_CREATE;
pub const GuildDelete = Gateway.EventName.GUILD_DELETE;
pub const GuildIntegrationsUpdate = Gateway.EventName.GUILD_INTEGRATIONS_UPDATE;
pub const GuildMemberAdd = Gateway.EventName.GUILD_MEMBER_ADD;
pub const GuildMemberRemove = Gateway.EventName.GUILD_MEMBER_REMOVE;
pub const GuildMembersChunk = Gateway.EventName.GUILD_MEMBERS_CHUNK;
pub const GuildMemberUpdate = Gateway.EventName.GUILD_MEMBER_UPDATE;
pub const GuildRoleCreate = Gateway.EventName.GUILD_ROLE_CREATE;
pub const GuildRoleDelete = Gateway.EventName.GUILD_ROLE_DELETE;
pub const GuildRoleUpdate = Gateway.EventName.GUILD_ROLE_UPDATE;
pub const GuildScheduledEventCreate = Gateway.EventName.GUILD_SCHEDULED_EVENT_CREATE;
pub const GuildScheduledEventDelete = Gateway.EventName.GUILD_SCHEDULED_EVENT_DELETE;
pub const GuildScheduledEventUpdate = Gateway.EventName.GUILD_SCHEDULED_EVENT_UPDATE;
pub const GuildScheduledEventUserAdd = Gateway.EventName.GUILD_SCHEDULED_EVENT_USER_ADD;
pub const GuildScheduledEventUserRemove = Gateway.EventName.GUILD_SCHEDULED_EVENT_USER_REMOVE;
pub const GuildSoundboardSoundCreate = Gateway.EventName.GUILD_SOUNDBOARD_SOUND_CREATE;
pub const GuildSoundboardSoundDelete = Gateway.EventName.GUILD_SOUNDBOARD_SOUND_DELETE;
pub const GuildSoundboardSoundsUpdate = Gateway.EventName.GUILD_SOUNDBOARD_SOUNDS_UPDATE;
pub const GuildSoundboardSoundUpdate = Gateway.EventName.GUILD_SOUNDBOARD_SOUND_UPDATE;
pub const GuildUpdate = Gateway.EventName.GUILD_UPDATE;
pub const InteractionCreate = Gateway.EventName.INTERACTION_CREATE;
pub const InviteCreate = Gateway.EventName.INVITE_CREATE;
pub const InviteDelete = Gateway.EventName.INVITE_DELETE;
pub const MessageBulkDelete = Gateway.EventName.MESSAGE_DELETE_BULK;
pub const MessageCreate = Gateway.EventName.MESSAGE_CREATE;
pub const MessageDelete = Gateway.EventName.MESSAGE_DELETE;
pub const MessagePollVoteAdd = Gateway.EventName.MESSAGE_POLL_VOTE_ADD;
pub const MessagePollVoteRemove = Gateway.EventName.MESSAGE_POLL_VOTE_REMOVE;
pub const MessageReactionAdd = Gateway.EventName.MESSAGE_REACTION_ADD;
pub const MessageReactionRemove = Gateway.EventName.MESSAGE_REACTION_REMOVE;
pub const MessageReactionRemoveAll = Gateway.EventName.MESSAGE_REACTION_REMOVE_ALL;
pub const MessageReactionRemoveEmoji = Gateway.EventName.MESSAGE_REACTION_REMOVE_EMOJI;
pub const MessageUpdate = Gateway.EventName.MESSAGE_UPDATE;
pub const PresenceUpdate = Gateway.EventName.PRESENCE_UPDATE;
pub const SoundboardSounds = Gateway.EventName.SOUNDBOARD_SOUNDS;
pub const StageInstanceCreate = Gateway.EventName.STAGE_INSTANCE_CREATE;
pub const StageInstanceDelete = Gateway.EventName.STAGE_INSTANCE_DELETE;
pub const StageInstanceUpdate = Gateway.EventName.STAGE_INSTANCE_UPDATE;
pub const SubscriptionCreate = Gateway.EventName.SUBSCRIPTION_CREATE;
pub const SubscriptionDelete = Gateway.EventName.SUBSCRIPTION_DELETE;
pub const SubscriptionUpdate = Gateway.EventName.SUBSCRIPTION_UPDATE;
pub const ThreadCreate = Gateway.EventName.THREAD_CREATE;
pub const ThreadDelete = Gateway.EventName.THREAD_DELETE;
pub const ThreadListSync = Gateway.EventName.THREAD_LIST_SYNC;
pub const ThreadMembersUpdate = Gateway.EventName.THREAD_MEMBERS_UPDATE;
pub const ThreadMemberUpdate = Gateway.EventName.THREAD_MEMBER_UPDATE;
pub const ThreadUpdate = Gateway.EventName.THREAD_UPDATE;
pub const TypingStart = Gateway.EventName.TYPING_START;
pub const UserUpdate = Gateway.EventName.USER_UPDATE;
pub const VoiceChannelEffectSend = Gateway.EventName.VOICE_CHANNEL_EFFECT_SEND;
pub const VoiceServerUpdate = Gateway.EventName.VOICE_SERVER_UPDATE;
pub const VoiceStateUpdate = Gateway.EventName.VOICE_STATE_UPDATE;
pub const WebhooksUpdate = Gateway.EventName.WEBHOOKS_UPDATE;

pub const RawHandler = raw_handler.RawHandler;
pub const Dispatcher = dispatcher.Dispatcher;
pub const interactionType = message_interaction_handlers.interactionType;
pub const rawHandler = message_interaction_handlers.rawHandler;

pub const DiscordJsEvent = struct {
    event: Gateway.EventName,
    name: []const u8,
};

pub const discord_js_events = [_]DiscordJsEvent{
    .{ .event = ApplicationCommandPermissionsUpdate, .name = "applicationCommandPermissionsUpdate" },
    .{ .event = AutoModerationActionExecution, .name = "autoModerationActionExecution" },
    .{ .event = AutoModerationRuleCreate, .name = "autoModerationRuleCreate" },
    .{ .event = AutoModerationRuleDelete, .name = "autoModerationRuleDelete" },
    .{ .event = AutoModerationRuleUpdate, .name = "autoModerationRuleUpdate" },
    .{ .event = ChannelCreate, .name = "channelCreate" },
    .{ .event = ChannelDelete, .name = "channelDelete" },
    .{ .event = ChannelPinsUpdate, .name = "channelPinsUpdate" },
    .{ .event = ChannelUpdate, .name = "channelUpdate" },
    .{ .event = ClientReady, .name = "clientReady" },
    .{ .event = EntitlementCreate, .name = "entitlementCreate" },
    .{ .event = EntitlementDelete, .name = "entitlementDelete" },
    .{ .event = EntitlementUpdate, .name = "entitlementUpdate" },
    .{ .event = GuildAuditLogEntryCreate, .name = "guildAuditLogEntryCreate" },
    .{ .event = GuildBanAdd, .name = "guildBanAdd" },
    .{ .event = GuildBanRemove, .name = "guildBanRemove" },
    .{ .event = GuildCreate, .name = "guildCreate" },
    .{ .event = GuildDelete, .name = "guildDelete" },
    .{ .event = GuildIntegrationsUpdate, .name = "guildIntegrationsUpdate" },
    .{ .event = GuildMemberAdd, .name = "guildMemberAdd" },
    .{ .event = GuildMemberRemove, .name = "guildMemberRemove" },
    .{ .event = GuildMembersChunk, .name = "guildMembersChunk" },
    .{ .event = GuildMemberUpdate, .name = "guildMemberUpdate" },
    .{ .event = GuildRoleCreate, .name = "roleCreate" },
    .{ .event = GuildRoleDelete, .name = "roleDelete" },
    .{ .event = GuildRoleUpdate, .name = "roleUpdate" },
    .{ .event = GuildScheduledEventCreate, .name = "guildScheduledEventCreate" },
    .{ .event = GuildScheduledEventDelete, .name = "guildScheduledEventDelete" },
    .{ .event = GuildScheduledEventUpdate, .name = "guildScheduledEventUpdate" },
    .{ .event = GuildScheduledEventUserAdd, .name = "guildScheduledEventUserAdd" },
    .{ .event = GuildScheduledEventUserRemove, .name = "guildScheduledEventUserRemove" },
    .{ .event = GuildSoundboardSoundCreate, .name = "guildSoundboardSoundCreate" },
    .{ .event = GuildSoundboardSoundDelete, .name = "guildSoundboardSoundDelete" },
    .{ .event = GuildSoundboardSoundsUpdate, .name = "guildSoundboardSoundsUpdate" },
    .{ .event = GuildSoundboardSoundUpdate, .name = "guildSoundboardSoundUpdate" },
    .{ .event = GuildUpdate, .name = "guildUpdate" },
    .{ .event = InteractionCreate, .name = "interactionCreate" },
    .{ .event = InviteCreate, .name = "inviteCreate" },
    .{ .event = InviteDelete, .name = "inviteDelete" },
    .{ .event = MessageBulkDelete, .name = "messageDeleteBulk" },
    .{ .event = MessageCreate, .name = "messageCreate" },
    .{ .event = MessageDelete, .name = "messageDelete" },
    .{ .event = MessagePollVoteAdd, .name = "messagePollVoteAdd" },
    .{ .event = MessagePollVoteRemove, .name = "messagePollVoteRemove" },
    .{ .event = MessageReactionAdd, .name = "messageReactionAdd" },
    .{ .event = MessageReactionRemove, .name = "messageReactionRemove" },
    .{ .event = MessageReactionRemoveAll, .name = "messageReactionRemoveAll" },
    .{ .event = MessageReactionRemoveEmoji, .name = "messageReactionRemoveEmoji" },
    .{ .event = MessageUpdate, .name = "messageUpdate" },
    .{ .event = PresenceUpdate, .name = "presenceUpdate" },
    .{ .event = SoundboardSounds, .name = "soundboardSounds" },
    .{ .event = StageInstanceCreate, .name = "stageInstanceCreate" },
    .{ .event = StageInstanceDelete, .name = "stageInstanceDelete" },
    .{ .event = StageInstanceUpdate, .name = "stageInstanceUpdate" },
    .{ .event = SubscriptionCreate, .name = "subscriptionCreate" },
    .{ .event = SubscriptionDelete, .name = "subscriptionDelete" },
    .{ .event = SubscriptionUpdate, .name = "subscriptionUpdate" },
    .{ .event = ThreadCreate, .name = "threadCreate" },
    .{ .event = ThreadDelete, .name = "threadDelete" },
    .{ .event = ThreadListSync, .name = "threadListSync" },
    .{ .event = ThreadMembersUpdate, .name = "threadMembersUpdate" },
    .{ .event = ThreadMemberUpdate, .name = "threadMemberUpdate" },
    .{ .event = ThreadUpdate, .name = "threadUpdate" },
    .{ .event = TypingStart, .name = "typingStart" },
    .{ .event = UserUpdate, .name = "userUpdate" },
    .{ .event = VoiceChannelEffectSend, .name = "voiceChannelEffectSend" },
    .{ .event = VoiceServerUpdate, .name = "voiceServerUpdate" },
    .{ .event = VoiceStateUpdate, .name = "voiceStateUpdate" },
    .{ .event = WebhooksUpdate, .name = "webhooksUpdate" },
};

pub fn discordJsName(event: Gateway.EventName) ?[]const u8 {
    for (discord_js_events) |entry| {
        if (entry.event == event) return entry.name;
    }
    return null;
}

pub fn fromDiscordJsName(name: []const u8) ?Gateway.EventName {
    for (discord_js_events) |entry| {
        if (std.mem.eql(u8, entry.name, name)) return entry.event;
    }
    return null;
}

test "Discord.js event aliases map to gateway events" {
    try std.testing.expectEqual(Gateway.EventName.READY, ClientReady);
    try std.testing.expectEqual(Gateway.EventName.MESSAGE_CREATE, MessageCreate);
    try std.testing.expectEqual(Gateway.EventName.MESSAGE_DELETE_BULK, MessageBulkDelete);
    try std.testing.expectEqual(Gateway.EventName.GUILD_ROLE_CREATE, GuildRoleCreate);
    try std.testing.expectEqual(Gateway.EventName.GUILD_SOUNDBOARD_SOUNDS_UPDATE, GuildSoundboardSoundsUpdate);

    try std.testing.expectEqualStrings("clientReady", discordJsName(ClientReady).?);
    try std.testing.expectEqualStrings("messageCreate", discordJsName(MessageCreate).?);
    try std.testing.expectEqualStrings("messageDeleteBulk", discordJsName(MessageBulkDelete).?);
    try std.testing.expectEqualStrings("roleCreate", discordJsName(GuildRoleCreate).?);

    try std.testing.expectEqual(Gateway.EventName.READY, fromDiscordJsName("clientReady").?);
    try std.testing.expectEqual(Gateway.EventName.MESSAGE_CREATE, fromDiscordJsName("messageCreate").?);
    try std.testing.expectEqual(Gateway.EventName.GUILD_ROLE_CREATE, fromDiscordJsName("roleCreate").?);
    try std.testing.expectEqual(@as(?Gateway.EventName, null), fromDiscordJsName("resumed"));
    try std.testing.expectEqual(@as(?[]const u8, null), discordJsName(.RESUMED));
}
