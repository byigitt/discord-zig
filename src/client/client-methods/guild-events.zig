const std = @import("std");
const Intents = @import("../../core/intents.zig");
const Rest = @import("../../rest/client.zig");
const HttpTransport = @import("../../rest/http-transport.zig").HttpTransport;
const Events = @import("../../gateway/events.zig");
const Gateway = @import("../../gateway/protocol.zig");
const GatewaySession = @import("../../gateway/session.zig");
const CacheModule = @import("../cache.zig");
const Interactions = @import("../../interactions/mod.zig");
const Cache = CacheModule.Cache;
const Types = @import("../../models/types.zig");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Root = @import("../client.zig");

pub fn Methods(comptime Client: type) type {
    return struct {
        pub fn onceGuildMemberUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_MEMBER_UPDATE, handler);
        }

        pub fn onGuildMemberRemove(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildMemberRemove(handler);
        }

        pub fn onceGuildMemberRemove(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_MEMBER_REMOVE, handler);
        }

        pub fn onGuildMembersChunk(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildMembersChunk(handler);
        }

        pub fn onceGuildMembersChunk(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_MEMBERS_CHUNK, handler);
        }

        pub fn onGuildRoleCreate(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildRoleCreate(handler);
        }

        pub fn onceGuildRoleCreate(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_ROLE_CREATE, handler);
        }

        pub fn onGuildRoleUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildRoleUpdate(handler);
        }

        pub fn onceGuildRoleUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_ROLE_UPDATE, handler);
        }

        pub fn onGuildRoleDelete(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildRoleDelete(handler);
        }

        pub fn onceGuildRoleDelete(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_ROLE_DELETE, handler);
        }

        pub fn onGuildEmojisUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildEmojisUpdate(handler);
        }

        pub fn onceGuildEmojisUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_EMOJIS_UPDATE, handler);
        }

        pub fn onGuildStickersUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildStickersUpdate(handler);
        }

        pub fn onceGuildStickersUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_STICKERS_UPDATE, handler);
        }

        pub fn onGuildScheduledEventCreate(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildScheduledEventCreate(handler);
        }

        pub fn onceGuildScheduledEventCreate(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_SCHEDULED_EVENT_CREATE, handler);
        }

        pub fn onGuildScheduledEventUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildScheduledEventUpdate(handler);
        }

        pub fn onceGuildScheduledEventUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_SCHEDULED_EVENT_UPDATE, handler);
        }

        pub fn onGuildScheduledEventDelete(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildScheduledEventDelete(handler);
        }

        pub fn onceGuildScheduledEventDelete(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_SCHEDULED_EVENT_DELETE, handler);
        }

        pub fn onGuildScheduledEventUserAdd(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildScheduledEventUserAdd(handler);
        }

        pub fn onceGuildScheduledEventUserAdd(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_SCHEDULED_EVENT_USER_ADD, handler);
        }

        pub fn onGuildScheduledEventUserRemove(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildScheduledEventUserRemove(handler);
        }

        pub fn onceGuildScheduledEventUserRemove(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_SCHEDULED_EVENT_USER_REMOVE, handler);
        }

        pub fn onGuildSoundboardSoundCreate(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildSoundboardSoundCreate(handler);
        }

        pub fn onceGuildSoundboardSoundCreate(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_SOUNDBOARD_SOUND_CREATE, handler);
        }

        pub fn onGuildSoundboardSoundUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildSoundboardSoundUpdate(handler);
        }

        pub fn onceGuildSoundboardSoundUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_SOUNDBOARD_SOUND_UPDATE, handler);
        }

        pub fn onGuildSoundboardSoundDelete(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildSoundboardSoundDelete(handler);
        }

        pub fn onceGuildSoundboardSoundDelete(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_SOUNDBOARD_SOUND_DELETE, handler);
        }

        pub fn onGuildSoundboardSoundsUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onGuildSoundboardSoundsUpdate(handler);
        }

        pub fn onceGuildSoundboardSoundsUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.GUILD_SOUNDBOARD_SOUNDS_UPDATE, handler);
        }

        pub fn onSoundboardSounds(self: *Client, handler: Events.RawHandler) void {
            self.events.onSoundboardSounds(handler);
        }

        pub fn onceSoundboardSounds(self: *Client, handler: Events.RawHandler) void {
            self.once(.SOUNDBOARD_SOUNDS, handler);
        }

        pub fn onStageInstanceCreate(self: *Client, handler: Events.RawHandler) void {
            self.events.onStageInstanceCreate(handler);
        }

        pub fn onceStageInstanceCreate(self: *Client, handler: Events.RawHandler) void {
            self.once(.STAGE_INSTANCE_CREATE, handler);
        }

        pub fn onStageInstanceUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onStageInstanceUpdate(handler);
        }

        pub fn onceStageInstanceUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.STAGE_INSTANCE_UPDATE, handler);
        }

        pub fn onStageInstanceDelete(self: *Client, handler: Events.RawHandler) void {
            self.events.onStageInstanceDelete(handler);
        }

        pub fn onceStageInstanceDelete(self: *Client, handler: Events.RawHandler) void {
            self.once(.STAGE_INSTANCE_DELETE, handler);
        }

        pub fn onVoiceChannelEffectSend(self: *Client, handler: Events.RawHandler) void {
            self.events.onVoiceChannelEffectSend(handler);
        }

        pub fn onceVoiceChannelEffectSend(self: *Client, handler: Events.RawHandler) void {
            self.once(.VOICE_CHANNEL_EFFECT_SEND, handler);
        }

        pub fn onVoiceServerUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onVoiceServerUpdate(handler);
        }

        pub fn onceVoiceServerUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.VOICE_SERVER_UPDATE, handler);
        }

        pub fn onChannelCreate(self: *Client, handler: Events.RawHandler) void {
            self.events.onChannelCreate(handler);
        }

        pub fn onceChannelCreate(self: *Client, handler: Events.RawHandler) void {
            self.once(.CHANNEL_CREATE, handler);
        }

        pub fn onChannelUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onChannelUpdate(handler);
        }

        pub fn onceChannelUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.CHANNEL_UPDATE, handler);
        }

        pub fn onChannelDelete(self: *Client, handler: Events.RawHandler) void {
            self.events.onChannelDelete(handler);
        }

        pub fn onceChannelDelete(self: *Client, handler: Events.RawHandler) void {
            self.once(.CHANNEL_DELETE, handler);
        }

        pub fn onChannelInfo(self: *Client, handler: Events.RawHandler) void {
            self.events.onChannelInfo(handler);
        }

        pub fn onceChannelInfo(self: *Client, handler: Events.RawHandler) void {
            self.once(.CHANNEL_INFO, handler);
        }

        pub fn onVoiceChannelStatusUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onVoiceChannelStatusUpdate(handler);
        }

        pub fn onceVoiceChannelStatusUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.VOICE_CHANNEL_STATUS_UPDATE, handler);
        }

        pub fn onVoiceChannelStartTimeUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onVoiceChannelStartTimeUpdate(handler);
        }

        pub fn onceVoiceChannelStartTimeUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.VOICE_CHANNEL_START_TIME_UPDATE, handler);
        }

        pub fn onChannelPinsUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onChannelPinsUpdate(handler);
        }

        pub fn onceChannelPinsUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.CHANNEL_PINS_UPDATE, handler);
        }

        pub fn onTypingStart(self: *Client, handler: Events.RawHandler) void {
            self.events.onTypingStart(handler);
        }

        pub fn onceTypingStart(self: *Client, handler: Events.RawHandler) void {
            self.once(.TYPING_START, handler);
        }

        pub fn onWebhooksUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onWebhooksUpdate(handler);
        }

        pub fn onceWebhooksUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.WEBHOOKS_UPDATE, handler);
        }

        pub fn onInviteCreate(self: *Client, handler: Events.RawHandler) void {
            self.events.onInviteCreate(handler);
        }

        pub fn onceInviteCreate(self: *Client, handler: Events.RawHandler) void {
            self.once(.INVITE_CREATE, handler);
        }

        pub fn onInviteDelete(self: *Client, handler: Events.RawHandler) void {
            self.events.onInviteDelete(handler);
        }

        pub fn onceInviteDelete(self: *Client, handler: Events.RawHandler) void {
            self.once(.INVITE_DELETE, handler);
        }

        pub fn onThreadCreate(self: *Client, handler: Events.RawHandler) void {
            self.events.onThreadCreate(handler);
        }

        pub fn onceThreadCreate(self: *Client, handler: Events.RawHandler) void {
            self.once(.THREAD_CREATE, handler);
        }

        pub fn onThreadUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onThreadUpdate(handler);
        }

        pub fn onceThreadUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.THREAD_UPDATE, handler);
        }

        pub fn onThreadDelete(self: *Client, handler: Events.RawHandler) void {
            self.events.onThreadDelete(handler);
        }

        pub fn onceThreadDelete(self: *Client, handler: Events.RawHandler) void {
            self.once(.THREAD_DELETE, handler);
        }

        pub fn onThreadListSync(self: *Client, handler: Events.RawHandler) void {
            self.events.onThreadListSync(handler);
        }

        pub fn onceThreadListSync(self: *Client, handler: Events.RawHandler) void {
            self.once(.THREAD_LIST_SYNC, handler);
        }

        pub fn onThreadMemberUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onThreadMemberUpdate(handler);
        }

        pub fn onceThreadMemberUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.THREAD_MEMBER_UPDATE, handler);
        }

        pub fn onThreadMembersUpdate(self: *Client, handler: Events.RawHandler) void {
            self.events.onThreadMembersUpdate(handler);
        }

        pub fn onceThreadMembersUpdate(self: *Client, handler: Events.RawHandler) void {
            self.once(.THREAD_MEMBERS_UPDATE, handler);
        }

        pub fn onRateLimited(self: *Client, handler: Events.RawHandler) void {
            self.events.onRateLimited(handler);
        }

        pub fn onceRateLimited(self: *Client, handler: Events.RawHandler) void {
            self.once(.RATE_LIMITED, handler);
        }

        pub fn onUnknown(self: *Client, handler: Events.RawHandler) void {
            self.events.onUnknown(handler);
        }

        pub fn sendMessage(self: *Client, channel_id: Snowflake, payload: Types.CreateMessage) !Rest.Response {
            return self.rest.createMessage(channel_id, payload);
        }

        pub fn sendMessageWithContent(self: *Client, channel_id: Snowflake, content: []const u8) !Rest.Response {
            return self.sendMessage(channel_id, Types.CreateMessage.init(content));
        }

        pub fn sendContent(self: *Client, channel_id: Snowflake, content: []const u8) !Rest.Response {
            return self.sendMessageWithContent(channel_id, content);
        }

        pub fn sendText(self: *Client, channel_id: Snowflake, content: []const u8) !Rest.Response {
            return self.sendMessageWithContent(channel_id, content);
        }

        pub fn send(self: *Client, channel_id: Snowflake, payload: Types.CreateMessage) !Rest.Response {
            return self.sendMessage(channel_id, payload);
        }

        pub fn getGateway(self: *Client) !Rest.Response {
            return self.rest.getGateway();
        }

        pub fn fetchGateway(self: *Client) !Rest.Response {
            return self.getGateway();
        }

        pub fn getGatewayBot(self: *Client) !Rest.Response {
            return self.rest.getGatewayBot();
        }

        pub fn fetchGatewayBot(self: *Client) !Rest.Response {
            return self.getGatewayBot();
        }

        pub fn getCurrentApplication(self: *Client) !Rest.Response {
            return self.rest.getCurrentApplication();
        }

        pub fn fetchCurrentApplication(self: *Client) !Rest.Response {
            return self.getCurrentApplication();
        }

        pub fn getCurrentBotApplication(self: *Client) !Rest.Response {
            return self.rest.getCurrentBotApplication();
        }

        pub fn fetchCurrentBotApplication(self: *Client) !Rest.Response {
            return self.getCurrentBotApplication();
        }

        pub fn editCurrentApplication(self: *Client, payload: Types.EditCurrentApplication) !Rest.Response {
            return self.rest.editCurrentApplication(payload);
        }

        pub fn setCurrentApplicationDescription(self: *Client, description: []const u8) !Rest.Response {
            return self.editCurrentApplication(Types.EditCurrentApplication.init().withDescription(description));
        }

        pub fn setCurrentApplicationIcon(self: *Client, icon: []const u8) !Rest.Response {
            return self.editCurrentApplication(Types.EditCurrentApplication.init().withIcon(icon));
        }

        pub fn clearCurrentApplicationIcon(self: *Client) !Rest.Response {
            return self.editCurrentApplication(Types.EditCurrentApplication.init().clearIcon());
        }

        pub fn setCurrentApplicationCoverImage(self: *Client, cover_image: []const u8) !Rest.Response {
            return self.editCurrentApplication(Types.EditCurrentApplication.init().withCoverImage(cover_image));
        }

        pub fn clearCurrentApplicationCoverImage(self: *Client) !Rest.Response {
            return self.editCurrentApplication(Types.EditCurrentApplication.init().clearCoverImage());
        }

        pub fn listApplicationSkus(self: *Client, application_id: Snowflake) !Rest.Response {
            return self.rest.listApplicationSkus(application_id);
        }

        pub fn fetchApplicationSkus(self: *Client, application_id: Snowflake) !Rest.Response {
            return self.listApplicationSkus(application_id);
        }

        pub fn listApplicationRoleConnectionMetadataRecords(
            self: *Client,
            application_id: Snowflake,
        ) !Rest.Response {
            return self.rest.listApplicationRoleConnectionMetadataRecords(application_id);
        }

        pub fn fetchApplicationRoleConnectionMetadataRecords(
            self: *Client,
            application_id: Snowflake,
        ) !Rest.Response {
            return self.listApplicationRoleConnectionMetadataRecords(application_id);
        }

        pub fn updateApplicationRoleConnectionMetadataRecords(
            self: *Client,
            application_id: Snowflake,
            payload: Types.UpdateApplicationRoleConnectionMetadataRecords,
        ) !Rest.Response {
            return self.rest.updateApplicationRoleConnectionMetadataRecords(application_id, payload);
        }

        pub fn setApplicationRoleConnectionMetadataRecords(
            self: *Client,
            application_id: Snowflake,
            payload: Types.UpdateApplicationRoleConnectionMetadataRecords,
        ) !Rest.Response {
            return self.updateApplicationRoleConnectionMetadataRecords(application_id, payload);
        }

        pub fn listApplicationEmojis(self: *Client, application_id: Snowflake) !Rest.Response {
            return self.rest.listApplicationEmojis(application_id);
        }

        pub fn fetchApplicationEmojis(self: *Client, application_id: Snowflake) !Rest.Response {
            return self.listApplicationEmojis(application_id);
        }

        pub fn getApplicationEmoji(self: *Client, application_id: Snowflake, emoji_id: Snowflake) !Rest.Response {
            return self.rest.getApplicationEmoji(application_id, emoji_id);
        }

        pub fn fetchApplicationEmoji(self: *Client, application_id: Snowflake, emoji_id: Snowflake) !Rest.Response {
            return self.getApplicationEmoji(application_id, emoji_id);
        }

        pub fn createApplicationEmoji(
            self: *Client,
            application_id: Snowflake,
            payload: Types.CreateApplicationEmoji,
        ) !Rest.Response {
            return self.rest.createApplicationEmoji(application_id, payload);
        }

        pub fn createApplicationEmojiWithImage(
            self: *Client,
            application_id: Snowflake,
            name: []const u8,
            image: []const u8,
        ) !Rest.Response {
            return self.createApplicationEmoji(application_id, Types.CreateApplicationEmoji.init(name, image));
        }

        pub fn editApplicationEmoji(
            self: *Client,
            application_id: Snowflake,
            emoji_id: Snowflake,
            payload: Types.EditApplicationEmoji,
        ) !Rest.Response {
            return self.rest.editApplicationEmoji(application_id, emoji_id, payload);
        }

        pub fn renameApplicationEmoji(
            self: *Client,
            application_id: Snowflake,
            emoji_id: Snowflake,
            name: []const u8,
        ) !Rest.Response {
            return self.editApplicationEmoji(application_id, emoji_id, Types.EditApplicationEmoji.init(name));
        }

        pub fn deleteApplicationEmoji(self: *Client, application_id: Snowflake, emoji_id: Snowflake) !Rest.Response {
            return self.rest.deleteApplicationEmoji(application_id, emoji_id);
        }

        pub fn getApplicationActivityInstance(
            self: *Client,
            application_id: Snowflake,
            instance_id: []const u8,
        ) !Rest.Response {
            return self.rest.getApplicationActivityInstance(application_id, instance_id);
        }

        pub fn fetchApplicationActivityInstance(
            self: *Client,
            application_id: Snowflake,
            instance_id: []const u8,
        ) !Rest.Response {
            return self.getApplicationActivityInstance(application_id, instance_id);
        }

        pub fn createLobby(self: *Client, payload: Types.CreateLobby) !Rest.Response {
            return self.rest.createLobby(payload);
        }

        pub fn getLobby(self: *Client, lobby_id: Snowflake) !Rest.Response {
            return self.rest.getLobby(lobby_id);
        }

        pub fn fetchLobby(self: *Client, lobby_id: Snowflake) !Rest.Response {
            return self.getLobby(lobby_id);
        }

        pub fn editLobby(self: *Client, lobby_id: Snowflake, payload: Types.EditLobby) !Rest.Response {
            return self.rest.editLobby(lobby_id, payload);
        }

        pub fn deleteLobby(self: *Client, lobby_id: Snowflake) !Rest.Response {
            return self.rest.deleteLobby(lobby_id);
        }

        pub fn addLobbyMember(self: *Client, lobby_id: Snowflake, user_id: Snowflake, payload: Types.UpdateLobbyMember) !Rest.Response {
            return self.rest.addLobbyMember(lobby_id, user_id, payload);
        }

        pub fn setLobbyMember(self: *Client, lobby_id: Snowflake, user_id: Snowflake, payload: Types.UpdateLobbyMember) !Rest.Response {
            return self.addLobbyMember(lobby_id, user_id, payload);
        }

        pub fn bulkUpdateLobbyMembers(self: *Client, lobby_id: Snowflake, payload: Types.BulkUpdateLobbyMembers) !Rest.Response {
            return self.rest.bulkUpdateLobbyMembers(lobby_id, payload);
        }

        pub fn removeLobbyMember(self: *Client, lobby_id: Snowflake, user_id: Snowflake) !Rest.Response {
            return self.rest.removeLobbyMember(lobby_id, user_id);
        }

        pub fn leaveLobby(self: *Client, bearer_token: []const u8, lobby_id: Snowflake) !Rest.Response {
            return self.rest.leaveLobby(bearer_token, lobby_id);
        }

        pub fn linkLobbyChannel(self: *Client, bearer_token: []const u8, lobby_id: Snowflake, payload: Types.LinkLobbyChannel) !Rest.Response {
            return self.rest.linkLobbyChannel(bearer_token, lobby_id, payload);
        }

        pub fn unlinkLobbyChannel(self: *Client, bearer_token: []const u8, lobby_id: Snowflake) !Rest.Response {
            return self.rest.unlinkLobbyChannel(bearer_token, lobby_id);
        }

        pub fn updateLobbyMessageModerationMetadata(
            self: *Client,
            lobby_id: Snowflake,
            message_id: Snowflake,
            payload: Types.UpdateLobbyMessageModerationMetadata,
        ) !Rest.Response {
            return self.rest.updateLobbyMessageModerationMetadata(lobby_id, message_id, payload);
        }

        pub fn setLobbyMessageModerationMetadata(
            self: *Client,
            lobby_id: Snowflake,
            message_id: Snowflake,
            payload: Types.UpdateLobbyMessageModerationMetadata,
        ) !Rest.Response {
            return self.updateLobbyMessageModerationMetadata(lobby_id, message_id, payload);
        }

        pub fn listEntitlements(self: *Client, application_id: Snowflake, options: Types.ListEntitlements) !Rest.Response {
            return self.rest.listEntitlements(application_id, options);
        }
    };
}
